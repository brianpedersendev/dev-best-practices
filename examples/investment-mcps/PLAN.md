# Investment MCP Server — Implementation Plan

**Date:** 2026-03-22 | **Revised:** 2026-03-22

---

## Why MCP (and Why Not Something Else)

Before diving into the plan, it's worth documenting the architecture decision since MCP is one of several valid approaches.

### Alternatives Considered

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| **Python library** | Simplest, no protocol overhead, works in scripts/notebooks | No AI tool discovery, must manually call functions | Personal scripting, Jupyter workflows |
| **CLI tool** | Claude can call via bash, also usable standalone | Less structured than MCP, no schema negotiation | Quick one-off queries, shell pipelines |
| **REST API + web UI** | Visual dashboard, sharable with non-AI users | More infrastructure (server, hosting, auth) | Team/public-facing product |
| **MCP server** | AI-first, tool discovery, composable, growing ecosystem | Protocol overhead, newer ecosystem | AI assistant is the primary interface |

### Why MCP Wins for This Use Case

1. **The primary interface is conversational.** You ask Claude "screen for quality value stocks in tech" — Claude discovers the tool, calls it, and presents results. MCP's self-describing tool schemas make this seamless.
2. **Composability.** Claude can chain screening → detail lookup → comparison → portfolio analysis in a single conversation without you orchestrating the calls.
3. **Multi-client support.** Same server works in Claude Desktop, Claude Code, and any MCP-compatible client. No code changes.
4. **Ecosystem momentum.** MCP is Linux Foundation-backed, 21K+ servers, with multiple finance MCP servers already proving the pattern works.
5. **Distribution story.** `uvx investment-tools` is a one-liner install. Users add a JSON block to Claude Desktop config and they're done.

### When MCP Would Be Wrong

- If you wanted a visual dashboard with charts → build a web app instead
- If you only used this in Jupyter notebooks → build a Python library
- If you needed real-time streaming alerts → build an event-driven system
- If non-AI users needed access → build a REST API (or add one later alongside MCP)

### The Escape Hatch

The analysis logic (scoring, screening, portfolio metrics) lives in plain Python modules. MCP is just the transport layer on top. If MCP doesn't work out, you can:
- Import the same modules as a Python library
- Wrap them in a CLI with `click` or `typer`
- Expose them via FastAPI as a REST service

The MCP server is a thin layer (~100 lines) over the real logic. You're not locked in.

---

## Architecture Overview (Single Server)

The previous plan split this into two servers (screener + evaluator). That's premature — **start with one server, split later only if it gets unwieldy.**

```
┌───────────────────────────────────────────────────────────────┐
│                     Claude Desktop / AI Client                 │
│                                                               │
│  "Find me quality value stocks"    "Evaluate my portfolio"    │
└──────────────────────────────┬────────────────────────────────┘
                               │ MCP (stdio)
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                    investment-tools                            │
│                    MCP Server (FastMCP)                        │
│                                                              │
│  Screening Tools:              Portfolio Tools:               │
│  ├─ screen_stocks              ├─ evaluate_portfolio          │
│  ├─ screen_funds               ├─ analyze_holding             │
│  ├─ get_stock_detail           ├─ risk_report                 │
│  ├─ compare_stocks             ├─ sector_breakdown            │
│  └─ list_strategies            └─ suggest_rebalance           │
│                                                              │
│  Resources:                    Prompts:                       │
│  ├─ strategies://list          ├─ stock-analysis              │
│  ├─ sectors://list             └─ portfolio-review            │
│  ├─ metrics://guide                                          │
│  └─ benchmarks://list                                        │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────┴───────────────────────────────┐
│                       Core Library                            │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐    │
│  │  yfinance    │  │  FMP API    │  │  Cache (SQLite)  │    │
│  │  (free,      │  │  (optional, │  │  24hr TTL for    │    │
│  │  no key)     │  │  $19/mo)    │  │  fundamentals    │    │
│  └─────────────┘  └─────────────┘  └──────────────────┘    │
│                                                              │
│  ┌─────────────┐  ┌──────────────────┐                      │
│  │ quantstats  │  │  pandas/numpy    │                      │
│  │ (portfolio  │  │  (data wrangling)│                      │
│  │  analytics) │  │                  │                      │
│  └─────────────┘  └──────────────────┘                      │
└──────────────────────────────────────────────────────────────┘
```

**Why one server:** The screener and portfolio evaluator share the same data layer, models, and caching. They're conceptually related (investment analysis). A single server means one install, one config block, one package to maintain. Split when (if) the tool count exceeds ~15 or the domains genuinely diverge.

---

## Tech Stack

| Component | Choice | Why |
|-----------|--------|-----|
| **MCP Framework** | FastMCP 2.x (Python) | Decorator-based, auto-schema, same ecosystem as yfinance |
| **Primary Data** | yfinance | Free, no API key, covers stocks + ETFs + mutual funds |
| **Enhanced Data** | Financial Modeling Prep | $19/mo, 30+ years fundamentals, optional upgrade |
| **Portfolio Analytics** | QuantStats | 30+ risk/performance metrics, HTML tear sheets, actively maintained |
| **Data Processing** | pandas + numpy | Standard quant stack |
| **Caching** | SQLite + diskcache | Zero-config, file-based, survives restarts |
| **Package Manager** | uv | Fast, modern Python packaging |
| **Transport** | Stdio (local) → HTTP/SSE (remote) | Stdio for Claude Desktop, HTTP for future deployment |

---

## Project Structure

```
investment-tools/
├── pyproject.toml              # Single package
├── README.md
├── src/
│   └── investment_tools/
│       ├── __init__.py
│       ├── server.py           # FastMCP server definition — all tools registered here
│       │
│       ├── data/
│       │   ├── __init__.py
│       │   ├── fetcher.py      # Unified data fetching (yfinance + FMP)
│       │   ├── cache.py        # SQLite caching layer (24hr TTL)
│       │   └── models.py       # Pydantic models for stock data, holdings
│       │
│       ├── screening/
│       │   ├── __init__.py
│       │   ├── scoring.py      # Composite scoring engine
│       │   ├── strategies.py   # Preset strategies (Buffett, quality, dividend, etc.)
│       │   └── filters.py      # Metric filters and thresholds
│       │
│       ├── portfolio/
│       │   ├── __init__.py
│       │   ├── analysis.py     # Portfolio construction + QuantStats wrapper
│       │   ├── risk.py         # Risk metrics (Sharpe, Sortino, VaR, drawdown)
│       │   └── rebalance.py    # Rebalancing suggestions
│       │
│       ├── formatters.py       # Output formatting (tables, summaries)
│       └── disclaimer.py       # Standard disclaimer text appended to outputs
│
├── tests/
│   ├── test_screening.py
│   ├── test_portfolio.py
│   ├── test_data.py
│   └── fixtures/               # Cached API responses for testing
│
└── claude_desktop_config.json  # Example Claude Desktop configuration
```

Key difference from previous plan: flat single-package structure. The MCP server (`server.py`) is a thin layer that imports from `screening/` and `portfolio/` — the real logic is in plain Python modules that could be used without MCP.

---

## Data Models

```python
# Core models (src/investment_tools/data/models.py)

class StockFundamentals(BaseModel):
    ticker: str
    name: str
    sector: str
    industry: str
    market_cap: float
    price: float

    # Valuation
    pe_ratio: float | None
    pb_ratio: float | None
    peg_ratio: float | None
    ev_ebitda: float | None
    fcf_yield: float | None

    # Quality
    roe: float | None              # Return on equity
    roce: float | None             # Return on capital employed
    operating_margin: float | None
    gross_margin: float | None
    piotroski_score: int | None    # 0-9

    # Growth
    revenue_growth_yoy: float | None
    earnings_growth_yoy: float | None
    dividend_growth_5yr: float | None

    # Financial Health
    debt_to_equity: float | None
    interest_coverage: float | None
    current_ratio: float | None

    # Dividend
    dividend_yield: float | None
    payout_ratio: float | None


class ScreeningResult(BaseModel):
    ticker: str
    name: str
    composite_score: float         # 0-100
    strategy_match: str            # Which strategy matched
    key_strengths: list[str]       # Top 3 reasons
    key_risks: list[str]           # Top 3 concerns
    fundamentals: StockFundamentals


class Holding(BaseModel):
    ticker: str
    shares: float | None = None
    weight: float | None = None    # Portfolio weight (0-1)


class PortfolioAnalysis(BaseModel):
    total_value: float | None
    period: str                    # e.g., "1Y", "3Y", "5Y"

    # Performance
    total_return: float
    cagr: float
    benchmark_return: float        # SPY by default
    alpha: float

    # Risk
    sharpe_ratio: float
    sortino_ratio: float
    max_drawdown: float
    beta: float
    volatility: float
    var_95: float                  # Value at Risk (95%)

    # Diversification
    sector_weights: dict[str, float]
    top_concentration: float       # Weight of top 5 holdings
    correlation_to_benchmark: float

    # Per-holding
    holdings_analysis: list[HoldingAnalysis]
```

---

## Tool Definitions

All tools live in a single FastMCP server instance.

### Screening Tools

```python
@mcp.tool()
async def screen_stocks(
    strategy: str = "quality_value",  # quality_value | buffett | dividend_growth | momentum_quality | custom
    min_market_cap: float = 2_000_000_000,  # $2B default (large cap)
    sectors: list[str] | None = None,  # Filter by sector
    max_results: int = 10,
    # Custom thresholds (used when strategy="custom")
    min_roe: float | None = None,
    max_pe: float | None = None,
    min_dividend_yield: float | None = None,
    max_debt_to_equity: float | None = None,
) -> str:
    """Screen stocks using proven long-term investment strategies.
    Returns ranked candidates with composite scores and reasoning."""

@mcp.tool()
async def screen_funds(
    fund_type: str = "etf",  # etf | mutual_fund
    category: str | None = None,  # e.g., "large_blend", "dividend", "growth"
    min_assets: float = 100_000_000,  # $100M minimum AUM
    max_expense_ratio: float = 0.50,  # 50 bps max
    max_results: int = 10,
) -> str:
    """Screen ETFs and mutual funds by category, expense ratio, performance, and assets."""

@mcp.tool()
async def get_stock_detail(
    ticker: str,
    include_history: bool = True,  # 5-year price history
) -> str:
    """Get comprehensive analysis of a single stock: fundamentals, quality score,
    valuation assessment, and 5-year performance context."""

@mcp.tool()
async def compare_stocks(
    tickers: list[str],  # 2-5 tickers
) -> str:
    """Side-by-side comparison of stocks across all fundamental metrics,
    with relative scoring and recommendation."""

@mcp.tool()
async def list_strategies() -> str:
    """List all available screening strategies with descriptions and the metrics each uses."""
```

### Portfolio Tools

```python
@mcp.tool()
async def evaluate_portfolio(
    holdings: list[dict],  # [{"ticker": "AAPL", "shares": 50}, ...]
    benchmark: str = "SPY",
    period: str = "1Y",  # 1M, 3M, 6M, 1Y, 3Y, 5Y, max
) -> str:
    """Full portfolio evaluation: performance, risk metrics, diversification,
    and comparison to benchmark. Returns a structured tear sheet summary."""

@mcp.tool()
async def analyze_holding(
    ticker: str,
    portfolio_context: list[dict] | None = None,  # Other holdings for context
) -> str:
    """Deep analysis of a single holding: performance attribution, risk contribution,
    and whether it's still worth holding based on current fundamentals."""

@mcp.tool()
async def risk_report(
    holdings: list[dict],
    period: str = "1Y",
) -> str:
    """Detailed risk analysis: VaR, drawdown history, volatility regime,
    correlation matrix, and stress test scenarios."""

@mcp.tool()
async def sector_breakdown(
    holdings: list[dict],
) -> str:
    """Sector/industry allocation analysis with concentration warnings
    and diversification score."""

@mcp.tool()
async def suggest_rebalance(
    holdings: list[dict],
    target_strategy: str = "balanced",  # balanced | growth | income | conservative
    max_changes: int = 5,
) -> str:
    """Suggest specific rebalancing moves to improve diversification,
    reduce risk, or align with target strategy."""
```

---

## Screening Strategy Presets

### Quality + Value (Default)

```python
QUALITY_VALUE = Strategy(
    name="quality_value",
    description="High-quality companies at reasonable prices. Blends profitability, financial health, and valuation.",
    weights={
        "roe": 0.15,           # Profitability
        "roce": 0.15,
        "operating_margin": 0.10,
        "piotroski_score": 0.15,  # Financial strength
        "debt_to_equity_inv": 0.10,  # Lower is better (inverted)
        "pe_ratio_inv": 0.10,  # Lower is better (inverted)
        "fcf_yield": 0.15,    # Valuation
        "revenue_growth": 0.10,  # Growth
    },
    hard_filters={
        "piotroski_score": (">=", 6),
        "debt_to_equity": ("<=", 1.5),
        "market_cap": (">=", 2_000_000_000),
    }
)
```

### Buffett Style
- ROE > 15%, operating margin > 15%, debt/equity < 0.5
- Consistent 5yr earnings growth, competitive moat indicators
- Reasonable P/E relative to growth (PEG < 2)

### Dividend Growth
- 5+ year dividend growth streak, yield > 2%
- Payout ratio < 60%, positive FCF, growing earnings

### Momentum + Quality
- Strong 6-12 month price momentum
- Combined with Novy-Marx quality (gross profits / total assets)
- Avoids "momentum traps" by requiring quality floor

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
- [ ] Set up project with `uv` and `pyproject.toml`
- [ ] Implement data fetching layer (`yfinance` wrapper with caching)
- [ ] Build Pydantic models for stock fundamentals
- [ ] Implement SQLite cache with 24hr TTL
- [ ] Add disclaimer module
- [ ] Wire up basic FastMCP server with one working tool (`get_stock_detail`)

### Phase 2: Screening (Week 2)
- [ ] Build composite scoring engine
- [ ] Implement `screen_stocks` with quality_value strategy
- [ ] Add all 4 strategy presets
- [ ] Implement `compare_stocks`
- [ ] Add `screen_funds` for ETFs
- [ ] Test with Claude Desktop

### Phase 3: Portfolio Analysis (Week 3)
- [ ] Implement `evaluate_portfolio` using QuantStats
- [ ] Build `risk_report` with Sharpe, Sortino, drawdown, VaR
- [ ] Add `sector_breakdown` with concentration warnings
- [ ] Implement `suggest_rebalance` logic
- [ ] Test with Claude Desktop

### Phase 4: Polish & Ship (Week 4)
- [ ] Add FMP integration as optional enhanced data source
- [ ] Comprehensive error handling (network failures, missing data, delisted stocks)
- [ ] Add `list_strategies` and resource endpoints
- [ ] Write README with installation and Claude Desktop config
- [ ] Add tests with fixture data (no live API calls in CI)
- [ ] Publish to PyPI (installable via `uvx`)

---

## Claude Desktop Configuration

```json
{
  "mcpServers": {
    "investment-tools": {
      "command": "uvx",
      "args": ["investment-tools"],
      "env": {
        "FMP_API_KEY": ""
      }
    }
  }
}
```

---

## Key Technical Decisions

| Decision | Choice | Alternative Considered | Why |
|----------|--------|----------------------|-----|
| MCP vs other architecture | MCP server | Python lib, CLI, REST API | AI-first interface, tool discovery, composability (see rationale above) |
| One server vs two | Single server | Separate screener + evaluator | Shared data layer, simpler install, split later if needed |
| yfinance vs FMP-only | yfinance default, FMP optional | FMP as sole source | Zero-config MVP; no API key barrier |
| SQLite cache vs Redis | SQLite | Redis, in-memory | Zero dependencies, persists across restarts |
| QuantStats vs pyfolio | QuantStats | pyfolio, custom math | More actively maintained, same author as yfinance |
| Piotroski as quality signal | Include | Altman Z-score, custom quality | Well-known, easy to compute, proven |
| Logic in plain modules | Core logic is importable Python | Logic inside MCP handlers | No lock-in — reusable as library, CLI, or API |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| yfinance API breaks | Medium | High | FMP fallback, defensive error handling, cache serves stale data |
| Slow screening (500 stocks) | High | Medium | Aggressive caching, async batch fetching, progress notifications |
| Incorrect financial data | Low | High | Cross-validate with multiple sources, display data timestamps |
| Scope creep | High | Medium | Strict MVP checklist, resist adding features before shipping |
| User trusts outputs as financial advice | Medium | High | Prominent disclaimers on every tool response |
| MCP ecosystem changes | Low | Medium | Core logic in plain Python modules; MCP is just the transport layer |

---

## First Week Milestones

1. **Day 1-2:** Project setup, data layer with yfinance, caching
2. **Day 3-4:** Scoring engine + quality_value strategy working
3. **Day 5:** `screen_stocks` and `get_stock_detail` callable from Claude Desktop
4. **Day 6-7:** Remaining strategies + `compare_stocks`

After Week 1, you should be able to ask Claude: *"Screen for quality value stocks in the tech sector"* and get a scored, ranked table.
