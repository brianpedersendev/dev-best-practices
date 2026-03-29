# Implementation Plan: Stock Analyst MCP

## Date: 2026-03-21
## Based on: docs/stock-mcp-research/SYNTHESIS.md, docs/stock-mcp-plan/product.md, docs/stock-mcp-plan/architecture.md

---

## Problem & Opportunity

A beginner investor with existing stock holdings wants to make better long-term decisions through AI-integrated analysis. No existing MCP combines stock data + personal thesis tracking + beginner-friendly education. The knowledge base layer is the unique differentiator — 10+ finance MCPs exist but none do it.

## Target User

Brian — solo developer, beginner investor with existing holdings. Personal tool only. Interacts via natural conversation with Claude.

---

## Tech Stack

| Layer | Choice | Version | Rationale |
|-------|--------|---------|-----------|
| Framework | FastMCP | 3.0+ | Decorator-based, 5x faster dev, industry standard |
| Runtime | Python | 3.10+ | Required for FastMCP, superior finance libraries |
| Price Data | yfinance | Latest | Free, no API key, fast |
| Fundamentals/News | Finnhub | Free tier | 60 calls/min, fundamentals + news + company info |
| Fallback | Financial Modeling Prep | Free tier | 250 calls/day backup |
| Knowledge Base | SQLite + FTS5 | 3.40+ | Zero deps, full-text search, ships with Python |
| Portfolio | JSON files | Native | Simple, portable, git-friendly |
| Caching | File-based TTL | Custom | ~/.stock_analyst/cache/, no external service |

---

## MVP Features (Implementation Order)

### Wave 1: Foundation (Days 1-2)

**1. Project Scaffold & Data Layer**
- Spec: Create project structure, install deps, init SQLite schema, create config/data dirs
- Technical: `stock_analyst_mcp/` layout with tools/, data/, models/, resources/
- Complexity: Simple
- Key files: main.py, data/db.py, data/cache.py, data/api_clients.py, models/constants.py

**2. get_stock_quote**
- Spec: Returns price, market cap, 52-week range, volume for any ticker
- Acceptance: Valid data for real tickers, clear error for invalid, 5 min cache
- Data source: yfinance primary, Finnhub fallback
- Cache: 5 minutes
- Complexity: Simple

**3. get_fundamentals**
- Spec: Returns P/E, ROE, D/E, dividend yield, EPS, revenue growth, earnings growth
- Acceptance: All metrics or graceful nulls, handles negative earnings, 1 day cache
- Data source: Finnhub primary (richer fundamentals), yfinance fallback
- Cache: 1 day
- Complexity: Medium (multiple data sources, null handling)

**4. get_company_info**
- Spec: Returns name, sector, industry, description, headquarters
- Acceptance: Clear description, handles missing fields
- Data source: yfinance primary
- Cache: 7 days
- Complexity: Simple

### Wave 2: Core Value — Knowledge Base & Portfolio (Days 3-5)

**5. save_investment_note**
- Spec: Save a note with title, content, optional ticker, optional tags to SQLite
- Acceptance: Saves to DB, searchable via FTS5, returns confirmation with ID
- Storage: SQLite notes table + FTS5 index (auto-synced via triggers)
- Complexity: Simple

**6. search_knowledge_base**
- Spec: Full-text search personal notes, filter by ticker, return top 5 matches
- Acceptance: Matches on title/content/tags, ranks by relevance, handles empty results
- Storage: SQLite FTS5 query
- Complexity: Medium (FTS5 query syntax, ranking)

**7. get_investment_frameworks**
- Spec: List all stored frameworks; get full text of a specific framework
- Acceptance: Returns pre-seeded frameworks on first run, supports user-added
- Storage: SQLite frameworks table, pre-seeded with 3-5 core frameworks
- Pre-seeded: Buffett Value Checklist, Key Financial Ratios Guide, Dividend Investing Basics
- Complexity: Simple

**8. get_portfolio / update_portfolio / add_to_watchlist**
- Spec: CRUD for holdings (ticker, shares, cost basis, date) and watchlist
- Acceptance: Reads/writes ~/.stock_analyst/portfolio.json, validates tickers, handles empty portfolio
- Storage: JSON file
- Complexity: Simple (but 3 tools)

### Wave 3: Analysis & News (Days 6-8)

**9. compare_stocks**
- Spec: Compare 2-5 tickers on a chosen metric (P/E, ROE, dividend yield, growth)
- Acceptance: Aligned output, handles missing data for some tickers, uses cached fundamentals
- Technical: Internally calls get_fundamentals for each ticker
- Complexity: Medium (aggregation, formatting)

**10. get_stock_news**
- Spec: Returns 5-10 recent news articles for a ticker from Finnhub
- Acceptance: Returns headline, source, date, summary URL. 1 hour cache. Handles no-news gracefully.
- Data source: Finnhub news API
- Cache: 1 hour
- Complexity: Simple

**11. MCP Resources (portfolio_snapshot, active_frameworks)**
- Spec: Read-only context auto-injected for Claude — current holdings summary + available frameworks
- Technical: @mcp.resource() decorators, read from JSON/SQLite
- Complexity: Simple

### Wave 4: Polish & Testing (Days 9-10)

- Test all tools against real tickers (AAPL, MSFT, NVDA, JNJ, etc.)
- Test error paths (invalid tickers, API failures, empty portfolio)
- Test cache behavior (TTL expiry, stale-on-error fallback)
- Write Claude Desktop config (claude_desktop_config.json)
- Write README with setup instructions
- Pre-seed investment frameworks into SQLite
- End-to-end test: full conversation flow with Claude

---

## Explicitly Out of MVP

| Feature | Why Deferred | When |
|---------|-------------|------|
| Stock screener (filter by criteria) | Needs query DSL, complex logic | v2 |
| SEC filing summaries | EdgarTools integration adds scope | v2 |
| Portfolio performance over time | Needs historical snapshots, dividend tracking | v2 |
| Technical analysis / charting | Anti-pattern for value investing focus | Maybe never |
| International stocks | Finnhub free = US only | v2 (paid tier) |
| Thesis comparison over time | Needs note versioning | v2 |
| OpenBB integration | Multi-source standardization | v2 |
| Options / crypto / forex | Scope narrowing | Out of scope |

---

## Architecture Summary

### Project Structure
```
stock_analyst_mcp/
├── stock_analyst_mcp/
│   ├── main.py                    # FastMCP server entry point
│   ├── tools/
│   │   ├── market_data.py         # quote, fundamentals, company, news
│   │   ├── knowledge_base.py      # notes, frameworks
│   │   ├── portfolio.py           # holdings, watchlist
│   │   └── analysis.py            # compare_stocks
│   ├── data/
│   │   ├── cache.py               # TTL cache decorator
│   │   ├── api_clients.py         # yfinance, Finnhub wrappers
│   │   └── db.py                  # SQLite init, queries
│   ├── models/
│   │   ├── schemas.py             # Pydantic models
│   │   └── constants.py           # Cache TTLs, framework seed data
│   └── resources/
│       └── portfolio.py           # MCP Resources
├── tests/
├── requirements.txt
├── .env.example
└── README.md
```

### Data Storage
- **~/.stock_analyst/knowledge.db** — SQLite (notes + FTS5 index + frameworks)
- **~/.stock_analyst/portfolio.json** — Holdings + watchlist
- **~/.stock_analyst/cache/** — TTL-based JSON cache files
- **~/.stock_analyst/config.json** — Settings (Finnhub API key)

### Key Patterns
- **Cache decorator**: `@cached_tool(ttl_seconds=300)` wraps API calls
- **Rate limiter**: `@rate_limit(calls_per_minute=10)` prevents API abuse
- **Fallback chain**: yfinance → Finnhub → FMP → stale cache → error
- **Atomic tools**: One tool per user intent, not per API endpoint

### Dependencies
```
fastmcp>=3.0.0
yfinance
finnhub-python
pydantic>=2.0
python-dotenv
```

---

## Configuration & Setup

### 1. Install
```bash
git clone <repo>
cd stock_analyst_mcp
pip install -e .
```

### 2. Configure Finnhub API key
```bash
# Get free key at https://finnhub.io/register
echo "FINNHUB_API_KEY=your_key_here" > .env
```

### 3. Add to Claude Desktop config
```json
{
  "mcpServers": {
    "stock-analyst": {
      "command": "python",
      "args": ["-m", "stock_analyst_mcp.main"],
      "env": {
        "FINNHUB_API_KEY": "your_key_here"
      }
    }
  }
}
```

### 4. First run auto-creates
- ~/.stock_analyst/ directory
- knowledge.db with schema + pre-seeded frameworks
- Empty portfolio.json
- cache/ directory

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| yfinance API breaks | Medium | High | Finnhub/FMP fallback, multi-source from day one |
| Scope creep | High | Medium | Strict wave-based implementation, defer to v2 aggressively |
| Free API rate limits hit | Medium | Medium | TTL caching, rate limiting decorators |
| API provider shuts down (IEX Cloud precedent) | Low | High | Abstract data layer, swappable providers |
| Over-trusting AI output | Medium | Medium | Educational framing, frameworks teach critical thinking |
| Domain expertise gap | Medium | Low | Source all frameworks from Schwab/AAII/Buffett, not AI-generated |

---

## Success Criteria

1. **"How's my portfolio?"** → Returns meaningful, data-backed diversification analysis
2. **"Find me good dividend stocks"** → Returns real, current fundamental data for comparison
3. **"What was my thesis on MSFT?"** → Retrieves saved notes accurately
4. **"Compare AAPL vs MSFT"** → Side-by-side metrics in one response
5. **"What's the news on NVDA?"** → Recent headlines with context
6. **Actually used regularly** — Not a one-time novelty, becomes part of investing workflow

---

## Traceability

### Original Problem
Brian has existing stock holdings but lacks confidence they're well-positioned. Wants AI-integrated stock analysis without learning separate financial platforms.

### How This Plan Addresses It
- **Quote + Fundamentals + Company tools** → Instant access to the data needed to evaluate any stock
- **Knowledge base** → Systematic thesis tracking replaces ad-hoc memory
- **Frameworks** → Pre-seeded value investing principles give structure to analysis
- **Portfolio tools** → See holdings, diversification, and risk at a glance
- **News** → Stay informed about relevant events without monitoring financial sites
- **Compare tool** → Objective side-by-side evaluation of candidates

### What's Deferred to Later
- Advanced screening (v2) — useful but complex, manual comparison works for v1
- SEC filings (v2) — nice-to-have depth, not essential for beginner analysis
- Performance tracking (v2) — requires historical data architecture
- International stocks (v2) — requires paid API tier
