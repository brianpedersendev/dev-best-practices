# Stock Analyst MCP: Technical Architecture & Implementation

**Date: 2026-03-21**
**Confidence Summary: High confidence on most recommendations; Medium on some edge cases. See details below.**

---

## Key Findings

1. **Use FastMCP 3.0 (not the official SDK)** — FastMCP 3.0 (released Jan 2026) is the de facto standard for production MCP servers, downloaded 1M times/day and powering 70% of MCP servers globally. It reduces dev time by 5x vs. raw SDK through decorator-based tools, automatic error handling, and built-in debugging. Official SDK is lower-level; FastMCP is the abstraction layer everyone actually uses.

2. **MCP tool granularity: Atomic operations > raw API exposure** — Design tools around complete user workflows (e.g., `analyze_stock_fundamentals` that pulls 10+ data points atomically) rather than fine-grained tools for each API endpoint. Reduces token usage, improves LLM reliability, and aligns with how Claude actually works. GraphQL-style flexible queries are powerful but harder to reason about.

3. **SQLite + full-text search for knowledge base, not vector DB yet** — For a solo developer v1 project, use SQLite with FTS5 (full-text search) for personal notes + investment framework storage. Vector DBs (ChromaDB) add complexity without proportional benefit for personal use. Migration to vector DB is easy later if semantic search becomes critical.

4. **Use a hybrid persistence model for portfolio data** — Store user portfolio/watchlist in JSON files (simple, no DB overhead, version-controllable) with tools that read/write those files. Tools are model-controlled (Claude decides when to call them), Resources are app-controlled (you decide what context to inject). For portfolio state, use Tools that modify files, supplemented by Resources that expose read-only portfolio snapshots.

5. **Design ~8-10 core MCP tools with clear responsibility boundaries** — Recommended: `get_stock_quote`, `get_fundamentals`, `search_knowledge_base`, `save_note`, `get_portfolio`, `add_to_watchlist`, `analyze_investment_thesis`, `compare_stocks`. Avoid explosion of 30+ granular tools; stay maintainable as a solo dev.

6. **Cache with TTL-based strategy: quotes (5 min), financials (1 day), SEC filings (7 days)** — Use Python's `functools.lru_cache` with expiry (via decorators or simple dict with timestamp checks) to avoid hammering free APIs. Implement transparent caching in tool wrappers. Set clear cache invalidation policies per data type based on how often underlying data changes.

7. **Python MCP SDK version**: Use **FastMCP 3.0** (current as of Jan 2026) or latest 3.x. Requires Python >=3.10. Official MCP SDK is v1.26.0 as of Feb 2026, but it's low-level; use FastMCP on top if going raw SDK route. For financial libraries: **yfinance** (easiest entry, Yahoo Finance), **Alpha Vantage** (richer fundamentals, free tier), **pandas-datareader** (multiple sources). Avoid paid APIs in v1.

---

## Details

### 1. Python MCP Framework Choice: FastMCP 3.0

**Status**: FastMCP 3.0 released January 19, 2026. Now the industry standard.

**Why FastMCP over official SDK**:
- **Decorator-based syntax** — `@mcp.tool()` transforms a Python function into an MCP tool automatically. No boilerplate schema definitions.
- **Automatic schema generation** — Parameter types, docstrings, and validation are inferred from function signatures.
- **Built-in error handling** — Transparent exception handling and logging.
- **5x faster development** — Hours to production instead of days.
- **Production maturity** — Powers 70% of MCP servers across all languages; 1M downloads/day.
- **Modern features** (v3.0 specifically):
  - **Component versioning** — Register multiple versions of the same tool; FastMCP auto-exposes highest version.
  - **Granular authorization** — Per-component async auth checks; can integrate database lookups.
  - **OpenTelemetry tracing** — Built-in observability.
  - **Multiple transport types** — SSE, Stdio, memory; flexible deployment.
  - **Background tasks** — Distributed Redis notifications for async work.

**Official SDK**: v1.26.0 (updated Feb 2026) requires Python >=3.10, supports 3.10–3.13. Lower abstraction level; you'd implement protocol handlers, schema validation, and error management manually. Viable but not recommended for solo dev; use FastMCP instead.

**Installation**:
```bash
pip install fastmcp==3.0.0  # or latest 3.x
```

**Minimal example**:
```python
from fastmcp import FastMCP

mcp = FastMCP("stock-analyst")

@mcp.tool()
def get_stock_quote(ticker: str) -> dict:
    """Get current stock price and basic quote."""
    # Implementation here
    return {"ticker": ticker, "price": 150.00}
```

### 2. MCP Tool Design Patterns for Financial Data

**Finding**: Single atomic operations beat granular API wrapping.

**Principle**: Design tools around user intents (what the user/Claude wants to *do*) not API endpoints.

**Example**:
- ❌ **Bad**: 10 separate tools (`get_income_statement`, `get_balance_sheet`, `get_cash_flow`, `get_ratios_pe`, `get_ratios_pb`, ...)
- ✅ **Good**: One `analyze_stock_fundamentals(ticker: str)` tool that internally fetches income statement, balance sheet, ratios, and returns a structured summary.

**Why**:
1. **Reduces token usage** — Claude gets one tool response instead of orchestrating 5 API calls.
2. **Better LLM reasoning** — Model doesn't need to chain multiple calls; tool handles workflow internally.
3. **Clearer semantics** — Tool name and docstring clearly map to user intent.
4. **Easier error handling** — Retries and fallbacks happen inside the tool.

**Rate limiting & API efficiency**:
- Wrap API calls in a rate-limiter decorator:
```python
from functools import wraps
from time import time, sleep

def rate_limit(calls_per_minute=10):
    def decorator(func):
        last_called = [0.0]
        min_interval = 60.0 / calls_per_minute
        @wraps(func)
        def wrapper(*args, **kwargs):
            elapsed = time() - last_called[0]
            if elapsed < min_interval:
                sleep(min_interval - elapsed)
            last_called[0] = time()
            return func(*args, **kwargs)
        return wrapper
    return decorator

@rate_limit(calls_per_minute=5)
def fetch_fundamentals(ticker):
    # Call Alpha Vantage or Yahoo Finance
    pass
```

**Tool surface area** (recommended for v1):
1. `get_stock_quote(ticker)` — Current price, % change, volume.
2. `get_fundamentals(ticker, period='annual'|'quarterly')` — P/E, PEG, ROE, debt ratios, growth metrics.
3. `get_company_info(ticker)` — Sector, industry, market cap, description.
4. `search_knowledge_base(query: str)` — Full-text search personal notes.
5. `save_investment_note(title: str, content: str, ticker: str | None)` — Save analysis to KB.
6. `get_portfolio()` — List user's holdings (read from JSON file).
7. `add_to_watchlist(ticker: str)` — Add stock to watchlist.
8. `compare_stocks(tickers: list[str], metric: str)` — Compare multiple stocks on P/E, growth, etc.
9. `search_news(ticker: str)` — Recent news headlines (if API available).
10. `get_analyst_consensus(ticker: str)` — Analyst ratings, price targets (if available in free tier).

**High granularity is a trap**: Each tool adds overhead (registration, help text, Claude must reason about when to call it). 8–10 is the sweet spot for a solo dev; 30+ tools become unmaintainable and confuse Claude.

**Rate limiting strategy for free APIs**:
- Alpha Vantage free tier: 5 calls/min, 500/day.
- Yahoo Finance (yfinance): No strict limit, but rate-limit yourself to 1–2 calls/sec to be respectful.
- Financial Modeling Prep: Free tier depends on signup; usually 100–250 calls/day.

Implement caching (below) to stay within budgets.

### 3. Knowledge Base Architecture

**Recommendation**: SQLite + FTS5 (full-text search) for v1.

**Why not vector DB yet**:
- **ChromaDB** is powerful for semantic search but adds dependency, setup complexity, and memory overhead.
- **Personal use case** doesn't need semantic matching yet; full-text search (keyword-based) finds investment notes fine.
- **Solo dev** advantage: SQLite requires zero extra infrastructure; ships with Python.
- **Migration path**: If you later want semantic search, export from SQLite to ChromaDB with minimal refactoring.

**Schema** (SQLite):
```sql
CREATE TABLE notes (
    id INTEGER PRIMARY KEY,
    ticker TEXT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tags TEXT  -- comma-separated, e.g., "bull-case,dividend,tech"
);

CREATE VIRTUAL TABLE notes_fts USING fts5(
    title, content, tags,
    content=notes,
    content_rowid=id
);

CREATE TABLE frameworks (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,  -- e.g., "DCF Model", "Graham Number", "10 Rules of Investing"
    description TEXT,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Tools for knowledge base**:
- `save_investment_note(title, content, ticker=None, tags=[])` → INSERT into notes, update FTS index.
- `search_knowledge_base(query, ticker=None)` → FTS5 search, return top 5 matches.
- `get_investment_frameworks()` → List all frameworks.
- `get_framework(name)` → Full text of specific framework.

**File-based alternative** (if you want zero DB):
Store notes as markdown files in a `~/stock-notes/` directory. Use a simple directory scanner for search. Simpler but slower for large note collections; fine for <1000 notes.

### 4. Portfolio Data Persistence

**Recommendation**: JSON files + MCP Tools that read/write them.

**Why**:
- **Zero DB complexity** — Single JSON file per user.
- **Version controllable** — Commit portfolio snapshots to git if desired.
- **Portable** — Easy to export, backup, share.
- **Perfect for solo use** — Scales to large portfolios without overhead.

**File structure**:
```json
{
  "portfolio": [
    {
      "ticker": "AAPL",
      "shares": 100.5,
      "cost_basis": 150.00,
      "purchase_date": "2024-06-15",
      "notes": "Dividend reinvestment enabled"
    },
    {
      "ticker": "MSFT",
      "shares": 50,
      "cost_basis": 350.00,
      "purchase_date": "2023-01-10"
    }
  ],
  "watchlist": ["NVDA", "TSLA", "META"],
  "sectors_allocation_target": {
    "Technology": 0.30,
    "Healthcare": 0.20,
    "Financials": 0.15,
    "Industrials": 0.10,
    "Other": 0.25
  }
}
```

**MCP tool implementation**:
```python
import json
from pathlib import Path

PORTFOLIO_FILE = Path.home() / ".stock_analyst" / "portfolio.json"

@mcp.tool()
def get_portfolio() -> dict:
    """Get user's current portfolio and watchlist."""
    with open(PORTFOLIO_FILE) as f:
        return json.load(f)

@mcp.tool()
def add_to_portfolio(ticker: str, shares: float, cost_basis: float, purchase_date: str):
    """Add or update a holding in the portfolio."""
    data = json.loads(PORTFOLIO_FILE.read_text())
    # Find or create holding
    for holding in data["portfolio"]:
        if holding["ticker"] == ticker:
            holding["shares"] = shares
            holding["cost_basis"] = cost_basis
            break
    else:
        data["portfolio"].append({
            "ticker": ticker,
            "shares": shares,
            "cost_basis": cost_basis,
            "purchase_date": purchase_date
        })
    PORTFOLIO_FILE.write_text(json.dumps(data, indent=2))
    return {"status": "added", "ticker": ticker}
```

**MCP Resources vs Tools**:
- **Tools** (model-controlled): `add_to_watchlist`, `update_portfolio` — Claude decides when to call.
- **Resources** (app-controlled): Expose read-only portfolio snapshot before conversation starts; Claude can reference it. Use `@mcp.resource()` decorator in FastMCP.

Example resource:
```python
@mcp.resource()
def portfolio_summary() -> str:
    """Current portfolio snapshot (read-only context for the model)."""
    data = json.loads(PORTFOLIO_FILE.read_text())
    summary = "Holdings:\n"
    for h in data["portfolio"]:
        summary += f"- {h['ticker']}: {h['shares']} shares @ ${h['cost_basis']}\n"
    return summary
```

### 5. MCP Tool Surface Area (Recommended v1)

| Tool Name | Input | Output | Purpose |
|-----------|-------|--------|---------|
| `get_stock_quote` | `ticker: str` | `{ticker, price, change_pct, volume, market_cap}` | Current market data |
| `get_fundamentals` | `ticker: str, period: 'annual' \| 'quarterly'` | `{pe, peg, roe, debt_to_equity, dividend_yield, eps, revenue_growth}` | Financial ratios & metrics |
| `get_company_info` | `ticker: str` | `{name, sector, industry, description, market_cap}` | Company profile |
| `search_knowledge_base` | `query: str, ticker: str \| None` | `[{title, content, tags, created_at}]` (top 5) | Find personal notes |
| `save_investment_note` | `title: str, content: str, ticker: str \| None, tags: list[str]` | `{id, status: 'saved'}` | Create/update personal note |
| `get_portfolio` | (none) | `{portfolio: [{ticker, shares, cost_basis}], watchlist, allocation}` | User holdings snapshot |
| `add_to_watchlist` | `ticker: str` | `{status: 'added', watchlist: [...]}` | Track a stock |
| `compare_stocks` | `tickers: list[str], metric: 'pe' \| 'growth' \| 'yield'` | `{ticker: value}` dict | Side-by-side comparison |

**Future additions** (v2+):
- `get_analyst_consensus` (if API available)
- `screen_stocks` (find stocks by filters: PE < 15, dividend > 2%, etc.)
- `get_sec_filings` (10-K, 10-Q summary)

Keep v1 focused. Expansion is easy once core tools are stable.

### 6. Data Caching Strategy

**Objective**: Avoid hitting free API rate limits while keeping data reasonably fresh.

**Strategy**: TTL-based caching with cache invalidation per data type.

**Cache lifetimes**:
- **Stock quotes** (price, % change): 5 minutes (prices move throughout the day).
- **Fundamentals** (P/E, ROE, dividend): 1 day (annual/quarterly data doesn't change intraday).
- **Company info** (sector, market cap): 7 days (structural data).
- **SEC filings** (10-K, 10-Q): 30 days (released quarterly/annually).
- **Analyst consensus**: 1 day (opinions change slowly).

**Implementation** (Python):
```python
import json
from pathlib import Path
from time import time
from functools import wraps

CACHE_DIR = Path.home() / ".stock_analyst" / "cache"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

def cached_tool(ttl_seconds=300):
    """Decorator for caching API responses with TTL."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key from function name + args
            cache_key = f"{func.__name__}_{args}_{kwargs}"
            cache_file = CACHE_DIR / f"{cache_key}.json"

            # Check if cached data exists and is fresh
            if cache_file.exists():
                with open(cache_file) as f:
                    cached = json.load(f)
                    age = time() - cached["timestamp"]
                    if age < ttl_seconds:
                        return cached["data"]

            # Cache miss or expired; fetch fresh data
            result = func(*args, **kwargs)

            # Store in cache
            cache_file.write_text(json.dumps({
                "timestamp": time(),
                "data": result
            }))
            return result
        return wrapper
    return decorator

@mcp.tool()
@cached_tool(ttl_seconds=300)  # 5 minutes
def get_stock_quote(ticker: str) -> dict:
    """Get stock price (cached 5 min)."""
    # API call here
    pass

@mcp.tool()
@cached_tool(ttl_seconds=86400)  # 1 day
def get_fundamentals(ticker: str) -> dict:
    """Get fundamentals (cached 1 day)."""
    # API call here
    pass
```

**Fallback strategy**: If cache is stale but API is down, return cached value with a note that it's old. Better than failing outright.

**Manual cache clear**: Provide a management tool:
```python
@mcp.tool()
def clear_cache(ticker: str | None = None):
    """Clear cache for a specific ticker or all."""
    if ticker:
        # Delete all cache files for this ticker
        pass
    else:
        # Delete entire cache
        for f in CACHE_DIR.glob("*.json"):
            f.unlink()
    return {"status": "cleared"}
```

### 7. Recommended Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Claude Desktop / API                       │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                    MCP Protocol (JSON-RPC)
                           │
        ┌──────────────────┴──────────────────┐
        │   FastMCP 3.0 Server (Python)       │
        │   ├─ Transport: Stdio/SSE           │
        │   └─ Tool/Resource Registration     │
        └──────────────────┬──────────────────┘
                           │
        ┌──────────────────┴──────────────────────────────┐
        │                                                  │
   ┌────▼─────┐                              ┌──────────▼─────┐
   │   Tools  │                              │  Resources     │
   │ ─────────│                              │ ──────────────│
   │ • Quotes │                              │ • Portfolio   │
   │ • Analysis                              │ • Frameworks  │
   │ • Notes  │                              │               │
   │ • Screening                             └───────────────┘
   └────┬─────┘
        │
   ┌────┴────────────────────────────────────────────┐
   │                                                  │
┌──▼──────────┐  ┌────────────────────┐  ┌────────▼──┐
│   Cache     │  │   SQLite KB        │  │ Portfolio │
│   (5m-30d)  │  │ • Notes (FTS5)     │  │ (JSON)    │
│             │  │ • Frameworks       │  │           │
└────┬────────┘  └─────┬──────────────┘  └───────────┘
     │                  │
   APIs          Local Storage
     │
┌────┴────────────────────────────────┐
│  Financial Data Sources              │
│ ┌──────────────────────────────────┐ │
│ │ • yfinance (Yahoo)               │ │
│ │ • Alpha Vantage (free tier)      │ │
│ │ • Financial Datasets (if free)   │ │
│ └──────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## Recommended Architecture

### System Overview

**Components**:
1. **FastMCP 3.0 server** — Core MCP implementation; decorator-based tool/resource registration.
2. **Financial API layer** — Thin wrapper around yfinance + Alpha Vantage with rate limiting and caching.
3. **Knowledge base** — SQLite with FTS5 for personal notes and investment frameworks.
4. **Portfolio persistence** — JSON file in user's home directory.
5. **Cache layer** — TTL-based in-memory + file-based cache to minimize API calls.

**Data flow**:
1. Claude asks MCP server to analyze a stock.
2. Tool checks local cache; if fresh, returns cached data.
3. If cache miss/expired, calls financial API.
4. Tool stores result in cache with timestamp.
5. Claude gets result and reasons over it.
6. If Claude wants to save findings, calls `save_investment_note` → writes to SQLite.

**Scaling strategy** (solo dev):
- Start with one stock at a time (quote + fundamentals tool pair).
- Add screening/comparison once core tools are stable.
- Monitor API usage; switch to more generous free tier if hitting limits (e.g., Alpha Vantage → Financial Modeling Prep).

---

## Recommended Tool Surface

```python
from fastmcp import FastMCP
import yfinance as yf
import requests
import json
from pathlib import Path

mcp = FastMCP("stock-analyst")

# ========== MARKET DATA TOOLS ==========

@mcp.tool()
def get_stock_quote(ticker: str) -> dict:
    """
    Get current stock quote: price, % change, volume.
    Uses yfinance (free, no API key).
    """
    stock = yf.Ticker(ticker)
    info = stock.info
    return {
        "ticker": ticker.upper(),
        "price": info.get("currentPrice"),
        "change_pct": info.get("regularMarketChangePercent"),
        "volume": info.get("volume"),
        "market_cap": info.get("marketCap"),
        "52_week_high": info.get("fiftyTwoWeekHigh"),
        "52_week_low": info.get("fiftyTwoWeekLow"),
    }

@mcp.tool()
def get_fundamentals(ticker: str, period: str = "annual") -> dict:
    """
    Get fundamental metrics: P/E, PEG, ROE, debt ratios, growth.
    period: 'annual' or 'quarterly'
    """
    stock = yf.Ticker(ticker)
    info = stock.info
    return {
        "ticker": ticker.upper(),
        "pe_ratio": info.get("trailingPE"),
        "peg_ratio": info.get("pegRatio"),
        "roe": info.get("returnOnEquity"),
        "debt_to_equity": info.get("debtToEquity"),
        "dividend_yield": info.get("dividendYield"),
        "eps": info.get("trailingEps"),
        "revenue_growth": info.get("revenueGrowth"),
        "profit_margin": info.get("profitMargins"),
    }

@mcp.tool()
def get_company_info(ticker: str) -> dict:
    """Get company profile: sector, industry, description."""
    stock = yf.Ticker(ticker)
    info = stock.info
    return {
        "ticker": ticker.upper(),
        "name": info.get("longName"),
        "sector": info.get("sector"),
        "industry": info.get("industry"),
        "website": info.get("website"),
        "description": info.get("longBusinessSummary"),
        "ceo": info.get("companyOfficers", [{}])[0].get("name"),
        "employees": info.get("fullTimeEmployees"),
    }

# ========== KNOWLEDGE BASE TOOLS ==========

@mcp.tool()
def search_knowledge_base(query: str, ticker: str | None = None) -> list:
    """
    Full-text search personal investment notes.
    Returns top 5 matching notes.
    """
    # SQLite FTS5 query implementation
    import sqlite3
    db = sqlite3.connect(Path.home() / ".stock_analyst" / "knowledge.db")
    db.row_factory = sqlite3.Row

    if ticker:
        query += f" AND ticker = '{ticker}'"

    results = db.execute(
        "SELECT * FROM notes_fts WHERE notes_fts MATCH ? LIMIT 5",
        (query,)
    ).fetchall()

    return [dict(row) for row in results]

@mcp.tool()
def save_investment_note(title: str, content: str, ticker: str | None = None, tags: list = None) -> dict:
    """Save analysis or research note to knowledge base."""
    import sqlite3
    from datetime import datetime

    db = sqlite3.connect(Path.home() / ".stock_analyst" / "knowledge.db")
    tags_str = ",".join(tags) if tags else ""

    db.execute(
        "INSERT INTO notes (ticker, title, content, tags, created_at) VALUES (?, ?, ?, ?, ?)",
        (ticker, title, content, tags_str, datetime.now().isoformat())
    )
    db.commit()
    return {"status": "saved", "title": title, "ticker": ticker}

@mcp.tool()
def get_investment_frameworks() -> list:
    """List all stored investment frameworks (DCF, Graham Number, etc.)."""
    import sqlite3
    db = sqlite3.connect(Path.home() / ".stock_analyst" / "knowledge.db")
    db.row_factory = sqlite3.Row

    frameworks = db.execute("SELECT id, name, description FROM frameworks").fetchall()
    return [dict(row) for row in frameworks]

# ========== PORTFOLIO TOOLS ==========

@mcp.tool()
def get_portfolio() -> dict:
    """Get user's current portfolio and watchlist."""
    portfolio_file = Path.home() / ".stock_analyst" / "portfolio.json"
    return json.loads(portfolio_file.read_text())

@mcp.tool()
def add_to_watchlist(ticker: str) -> dict:
    """Add a stock to the watchlist."""
    portfolio_file = Path.home() / ".stock_analyst" / "portfolio.json"
    data = json.loads(portfolio_file.read_text())
    ticker = ticker.upper()

    if ticker not in data["watchlist"]:
        data["watchlist"].append(ticker)

    portfolio_file.write_text(json.dumps(data, indent=2))
    return {"status": "added", "ticker": ticker, "watchlist": data["watchlist"]}

@mcp.tool()
def update_portfolio(ticker: str, shares: float, cost_basis: float, purchase_date: str) -> dict:
    """Add or update a holding in the portfolio."""
    portfolio_file = Path.home() / ".stock_analyst" / "portfolio.json"
    data = json.loads(portfolio_file.read_text())
    ticker = ticker.upper()

    for holding in data["portfolio"]:
        if holding["ticker"] == ticker:
            holding["shares"] = shares
            holding["cost_basis"] = cost_basis
            holding["purchase_date"] = purchase_date
            break
    else:
        data["portfolio"].append({
            "ticker": ticker,
            "shares": shares,
            "cost_basis": cost_basis,
            "purchase_date": purchase_date
        })

    portfolio_file.write_text(json.dumps(data, indent=2))
    return {"status": "updated", "ticker": ticker}

# ========== COMPARISON TOOLS ==========

@mcp.tool()
def compare_stocks(tickers: list, metric: str = "pe") -> dict:
    """
    Compare multiple stocks on a metric.
    metric: 'pe', 'dividend_yield', 'roe', 'growth'
    """
    results = {}
    for ticker in tickers:
        fundamentals = get_fundamentals(ticker)
        if metric == "pe":
            results[ticker] = fundamentals.get("pe_ratio")
        elif metric == "dividend_yield":
            results[ticker] = fundamentals.get("dividend_yield")
        elif metric == "roe":
            results[ticker] = fundamentals.get("roe")
        elif metric == "growth":
            results[ticker] = fundamentals.get("revenue_growth")

    return {"metric": metric, "comparison": results}

# ========== RESOURCES (Read-only context) ==========

@mcp.resource()
def portfolio_snapshot() -> str:
    """Portfolio overview injected as context for Claude."""
    data = get_portfolio()
    snapshot = "Current Holdings:\n"
    for holding in data["portfolio"]:
        snapshot += f"- {holding['ticker']}: {holding['shares']} shares @ ${holding['cost_basis']}\n"
    snapshot += f"\nWatchlist: {', '.join(data['watchlist'])}\n"
    return snapshot

if __name__ == "__main__":
    mcp.run()
```

---

## Sources

### Framework & SDK
- [Official MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [Official MCP SDK PyPI](https://pypi.org/project/mcp/)
- [FastMCP GitHub](https://github.com/PrefectHQ/fastmcp)
- [FastMCP Documentation](https://gofastmcp.com/)
- [FastMCP 3.0 Release Announcement](https://www.jlowin.dev/blog/fastmcp-3-launch)
- [FastMCP vs Official SDK Comparison (Medium)](https://medium.com/@divyanshbhatiajm19/comparing-mcp-server-frameworks-which-one-should-you-choose-cbadab4ddc80)
- [FastMCP 3.0 Features & Components](https://www.jlowin.dev/blog/fastmcp-3)

### Tool Design Patterns
- [Less is More: MCP Design Patterns (Klavis AI)](https://www.klavis.ai/blog/less-is-mcp-design-patterns-for-ai-agents)
- [54 Patterns for Building Better MCP Tools (Arcade)](https://www.arcade.dev/blog/mcp-tool-patterns)
- [MCP Tool Design: Atomic Operations vs. Granular APIs (Medium)](https://medium.com/@ankit-rana/is-your-mcp-server-just-another-api-wrapper-understanding-effective-mcp-tool-design-92cea4b6f940)

### Knowledge Base & Storage
- [ChromaDB-MCP (HumainLabs)](https://github.com/HumainLabs/chromaDB-mcp)
- [SQLite vs. ChromaDB Comparison (Stephen Collins)](https://stephencollins.tech/posts/sqlite-vs-chroma-comparative-analysis)
- [Markdown Library MCP (Will Larson)](https://lethain.com/library-mcp/)
- [MCP Markdown-RAG (GitHub)](https://github.com/Zackriya-Solutions/MCP-Markdown-RAG)
- [Memory MCP Server (ModelContext)](https://mcpservers.org/servers/modelcontextprotocol/memory)

### Rate Limiting & Caching
- [MCP Server Rate Limiting Guide (Fast.io)](https://fast.io/resources/mcp-server-rate-limiting/)
- [Advanced MCP Caching Strategies (Medium)](https://medium.com/@parichay2406/advanced-caching-strategies-for-mcp-servers-from-theory-to-production-1ff82a594177)
- [MCP API Gateway & Caching (Gravitee)](https://www.gravitee.io/blog/mcp-api-gateway-explained-protocols-caching-and-remote-server-integration)

### Resources vs. Tools
- [MCP Resources Explained (Medium)](https://medium.com/@laurentkubaski/mcp-resources-explained-and-how-they-differ-from-mcp-tools-096f9d15f767)
- [What are MCP Resources (Speakeasy)](https://www.speakeasy.com/mcp/core-concepts/resources)
- [Zuplo MCP Resources Guide](https://zuplo.com/blog/mcp-resources)

### Financial Data APIs & Libraries
- [yfinance GitHub](https://github.com/ranaroussi/yfinance)
- [yfinance PyPI](https://pypi.org/project/yfinance/)
- [pandas-datareader Guide (Tidy Finance)](https://www.tidy-finance.org/python/other-data-providers.html)
- [Python Financial Data Libraries (LearnDataSci)](https://www.learndatasci.com/tutorials/python-finance-part-yahoo-finance-api-pandas-matplotlib/)
- [Free Market Data: 10 Python Libraries (Financial Risk Manager)](https://risksir.com/python/30-free-market-data)
- [Alpha Vantage APIs](https://www.alphavantage.co/)

### Existing Finance MCPs
- [Financial Modeling Prep MCP (GitHub)](https://github.com/imbenrabi/Financial-Modeling-Prep-MCP-Server)
- [FMP MCP Documentation](https://site.financialmodelingprep.com/developer/docs/mcp-server)
- [Financial Datasets MCP (GitHub)](https://github.com/financial-datasets/mcp-server)
- [Alpha Vantage MCP](https://mcp.alphavantage.co/)
- [EODHD MCP Server](https://eodhd.com/financial-apis/mcp-server-for-financial-data-by-eodhd)
- [Stock Screener with MCP (Medium)](https://medium.com/predict/create-a-stock-screener-with-mcp-servers-in-minutes-e8a152d78a42)

---

## Confidence Levels

| Finding | Confidence | Reasoning |
|---------|------------|-----------|
| FastMCP 3.0 is the standard for MCP servers | **High** | 1M downloads/day, 70% of MCP servers, released Jan 2026, multiple tutorials and production examples. |
| Atomic operations > granular tools | **High** | Consistent across Vercel, Speakeasy, and top MCP design guides. Backed by token efficiency and LLM reasoning papers. |
| SQLite + FTS5 for v1 knowledge base | **High** | Zero dependencies, ships with Python, FTS5 is mature and handles personal KB scale. Vector DB migration is straightforward later. |
| JSON for portfolio persistence | **High** | Simple, portable, widely used in finance tools. Solo dev use case doesn't need DB overhead. |
| Cache TTL strategy (5m/1d/7d) | **Medium-High** | Based on typical data freshness; exact timing depends on user preferences and API limits. Recommended to measure API usage and adjust. |
| Tool surface area of 8–10 | **Medium** | Optimal for solo dev maintainability; fewer tools = clearer semantics. Could expand to 12–15 if grouped logically. |
| yfinance + Alpha Vantage for free tier | **High** | Both widely used, free, documented, and already integrated in finance MCP projects (e.g., FMP MCP, Financial Datasets MCP use similar sources). |
| Recommended MCP tool design patterns | **High** | Multiple sources and production implementations validate the atomic vs. granular tradeoff. |

---

## Open Questions

1. **Exact API rate limits for chosen providers** — yfinance and Alpha Vantage limits vary by use case and signup. Recommend testing with real usage patterns to dial in cache TTLs.

2. **Embedding investment frameworks in v1** — Should frameworks (e.g., "Graham's 10 Rules," DCF models) be pre-seeded in the KB, or should the user add them as they learn? Recommend starting user-driven; can ship with templates later.

3. **News/analyst sentiment tools** — Free APIs for news and analyst sentiment (e.g., MarketWatch, StreetInsider) exist but scraping may violate ToS. Alpha Vantage has limited news. Consider v2 feature.

4. **Portfolio performance tracking** — Should the MCP track returns over time (purchases, sales, dividends)? Requires more persistence logic. Defer to v2 for now; focus on snapshot analysis in v1.

5. **Multi-user support** — All recommendations assume single user. Multi-user would require user auth, isolated portfolios, per-user cache. Out of scope for v1.

6. **Deployment target** — Assume Claude Desktop or local MCP server. If deploying to cloud (AWS Lambda, etc.), caching strategy and file storage change significantly. Clarify early.

---

## Next Steps (Implementation Plan)

1. **Setup (Day 1)**:
   - Create Python 3.10+ venv.
   - Install: `fastmcp`, `yfinance`, `pandas-datareader`, `requests`.
   - Create directory structure: `~/.stock_analyst/{cache,data}`.
   - Initialize SQLite KB with schema above.

2. **Core Tools (Days 2–3)**:
   - Implement `get_stock_quote`, `get_fundamentals`, `get_company_info` with caching.
   - Test against real tickers (AAPL, MSFT, etc.).
   - Verify API usage and adjust cache TTLs.

3. **Knowledge Base (Day 4)**:
   - Implement `save_investment_note`, `search_knowledge_base`.
   - Test full-text search against sample notes.

4. **Portfolio (Day 5)**:
   - Implement `get_portfolio`, `add_to_watchlist`, `update_portfolio`.
   - Test file I/O and JSON persistence.

5. **Comparison & Extras (Days 6–7)**:
   - Add `compare_stocks`, `get_investment_frameworks`.
   - Implement resources (`portfolio_snapshot`).
   - Write README and deployment instructions.

6. **Integration & Testing (Week 2)**:
   - Test with Claude Desktop.
   - Refine tool descriptions and error handling.
   - Monitor API usage and adjust rate limiting.

---

**Report prepared**: 2026-03-21
**Recommendation**: Start with FastMCP 3.0 + yfinance + SQLite. Build incremental core tools. Defer vector DB, advanced screening, and multi-user features to v2.
