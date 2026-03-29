# Stock Analyst MCP: Architecture Design Document

**Date**: 2026-03-21
**Author**: System Design Research
**Status**: Ready for Implementation

---

## Executive Summary

This document provides the complete technical architecture for the Stock Analyst MCP — a Python-based MCP server that brings stock analysis, portfolio tracking, and investment research directly into Claude conversations.

**Key design decisions**:
- **FastMCP 3.0** for the framework (5x faster dev than raw SDK)
- **yfinance + Finnhub** for financial data (free, reliable, fallback coverage)
- **SQLite + FTS5** for the knowledge base (zero dependencies, ships with Python)
- **JSON files** for portfolio persistence (simple, portable)
- **8-10 atomic tools** focused on thesis tracking + fundamentals + screening
- **TTL-based caching** to stay within free API limits

**Build timeline**: 1-2 weeks for solo developer
**Rationale**: See SYNTHESIS.md and technical.md for research backing every decision

---

## Tech Stack

| Layer | Component | Version | Rationale |
|-------|-----------|---------|-----------|
| **Framework** | FastMCP | 3.0+ | Decorator-based tools, automatic schema generation, 5x faster than raw SDK, 70% of MCP servers |
| **Runtime** | Python | 3.10+ | Required for FastMCP 3.0, better finance library ecosystem |
| **Market Data** | yfinance | Latest | Free, no API key, fast, used in 100+ finance tools |
| **Fundamentals** | Finnhub API | Free tier | 60 calls/min free, includes fundamentals, news, company info |
| **Fallback** | Financial Modeling Prep | Free tier (250/day) | Richer fundamentals if Finnhub fails; fallback source |
| **Knowledge Base** | SQLite | 3.40+ | Comes with Python, FTS5 virtual table for search, zero extra dependencies |
| **Portfolio Storage** | JSON | Native | Simple, portable, git-friendly, zero DB overhead |
| **Caching** | File-based TTL | Custom | Local ~/.stock_analyst/cache/, no external cache service |
| **CLI/Testing** | Click (optional) | 8.1+ | If adding interactive CLI for testing; MCP runs via stdio mostly |

---

## Project Structure

Recommended layout for a solo developer (keep it simple):

```
stock_analyst_mcp/
├── README.md                           # Installation, quick start, usage examples
├── requirements.txt                    # Python dependencies (pinned versions)
├── setup.py                            # setuptools config for installation
│
├── stock_analyst_mcp/
│   ├── __init__.py
│   ├── main.py                         # FastMCP server entry point
│   │
│   ├── tools/
│   │   ├── __init__.py
│   │   ├── market_data.py              # get_stock_quote, get_fundamentals, get_company_info
│   │   ├── knowledge_base.py           # search_knowledge_base, save_investment_note, get_frameworks
│   │   ├── portfolio.py                # get_portfolio, update_portfolio, add_to_watchlist
│   │   └── analysis.py                 # compare_stocks, advanced analysis tools
│   │
│   ├── data/
│   │   ├── __init__.py
│   │   ├── cache.py                    # TTL cache decorator and management
│   │   ├── api_clients.py              # yfinance, Finnhub, FMP wrappers
│   │   └── db.py                       # SQLite connection, schema init
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── schemas.py                  # Pydantic models for validation, type hints
│   │   └── constants.py                # API limits, cache TTLs, framework definitions
│   │
│   └── resources/
│       ├── __init__.py
│       └── portfolio.py                # MCP Resources (read-only context)
│
├── tests/
│   ├── test_market_data.py
│   ├── test_knowledge_base.py
│   ├── test_portfolio.py
│   └── conftest.py                     # pytest fixtures
│
├── docs/
│   ├── MCP_TOOL_SPECS.md               # Detailed tool specs (see below)
│   ├── DEPLOYMENT.md                   # Claude Desktop setup, config
│   └── DEVELOPMENT.md                  # Dev workflow, debugging
│
├── .env.example                        # Template for config (Finnhub API key, etc.)
└── ~/.stock_analyst/                   # Runtime data directory (created on first run)
    ├── portfolio.json                  # User's holdings and watchlist
    ├── config.json                     # Settings (API keys, cache preferences)
    ├── knowledge.db                    # SQLite knowledge base
    └── cache/                          # TTL-based cache files
        ├── quote_AAPL.json
        ├── fundamentals_MSFT.json
        └── ...
```

**Rationale for structure**:
- **tools/** — One module per tool category; clear separation of concerns
- **data/** — Data fetching, caching, DB logic isolated from tool definitions
- **models/** — Centralized schemas and constants; easier to maintain and test
- **resources/** — MCP Resources separate from Tools (resources are read-only context)
- **~/.stock_analyst/** — All user data in one place, easy to backup/reset

---

## Data Model

### SQLite Schema (Knowledge Base)

Located at: `~/.stock_analyst/knowledge.db`

Initialize with this schema on first run:

```sql
-- Notes table: stores personal investment research and analysis
CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticker TEXT,                        -- Stock ticker (null for general notes)
    title TEXT NOT NULL,                -- Note title
    content TEXT NOT NULL,              -- Full note content (markdown supported)
    tags TEXT,                          -- Comma-separated tags: "bull-case,dividend,tech"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Full-text search index (FTS5 virtual table)
-- Automatically synced with notes table via triggers
CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
    title, content, tags,
    content=notes,              -- Sync source table
    content_rowid=id            -- Rowid column in source
);

-- Triggers to keep FTS5 index in sync with notes
CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
  INSERT INTO notes_fts(rowid, title, content, tags)
  VALUES (new.id, new.title, new.content, new.tags);
END;

CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
  INSERT INTO notes_fts(notes_fts, rowid, title, content, tags)
  VALUES('delete', old.id, old.title, old.content, old.tags);
END;

CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
  INSERT INTO notes_fts(notes_fts, rowid, title, content, tags)
  VALUES('delete', old.id, old.title, old.content, old.tags);
  INSERT INTO notes_fts(rowid, title, content, tags)
  VALUES (new.id, new.title, new.content, new.tags);
END;

-- Frameworks table: pre-seeded and user-added investment frameworks
CREATE TABLE IF NOT EXISTS frameworks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,          -- "Buffett Value", "Graham Number", etc.
    description TEXT,                   -- One-line summary
    content TEXT NOT NULL,              -- Full framework text (markdown)
    category TEXT,                      -- "valuation", "quality", "screening", "educational"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pre-seed with 3-5 core frameworks (see Python init code below)
```

**Python SQLite initialization code**:

```python
import sqlite3
from pathlib import Path
from datetime import datetime

def init_knowledge_base():
    """Initialize SQLite knowledge base with schema and seed data."""
    db_path = Path.home() / ".stock_analyst" / "knowledge.db"
    db_path.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Create schema (SQL above)
    cursor.executescript("""
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticker TEXT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            tags TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
            title, content, tags,
            content=notes,
            content_rowid=id
        );

        [CREATE TRIGGER statements above]

        CREATE TABLE IF NOT EXISTS frameworks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            content TEXT NOT NULL,
            category TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)

    # Pre-seed frameworks (one-time)
    frameworks = [
        {
            "name": "Buffett's Value Investing",
            "description": "Long-term investing in quality businesses at fair prices.",
            "category": "valuation",
            "content": """
# Buffett's Value Investing Framework

## Principles
1. **Business Quality**: Look for durable competitive advantages (moats)
2. **Fair Price**: P/E ratio compared to industry average; consider intrinsic value
3. **Financial Health**: Strong balance sheet (low debt, high ROE)
4. **Management**: Trusted, owner-oriented leadership
5. **Hold for the Long Term**: 10+ year investment horizon

## Key Metrics
- P/E Ratio: < industry average for fair value
- Return on Equity (ROE): > 15% (sign of strong competitive advantage)
- Debt-to-Equity: < 1.0 (manageable leverage)
- Dividend Yield: 2-5% (if dividend stock)

## How to Use
1. Find a stock you understand
2. Check its financials against criteria above
3. Compare P/E to competitors
4. Ask: "Would I want to own this business for 10 years?"
5. Only buy if answer is clearly yes at a fair price
            """
        },
        {
            "name": "Graham Number (Valuation Floor)",
            "description": "Benjamin Graham's formula to estimate a reasonable price for a stock.",
            "category": "valuation",
            "content": """
# Graham Number: Conservative Valuation Estimate

## Formula
√ (22.5 × EPS × Book Value Per Share)

## Interpretation
- Graham Number = conservative estimate of fair value
- Buy if stock price < Graham Number (margin of safety)
- Good for beginner investors (simple, defensive)

## Limitations
- Assumes historical metrics predict future
- Doesn't account for growth trajectory
- Better for mature, stable companies than growth stocks

## Example
If MSFT has EPS=$10 and Book Value Per Share=$30:
Graham Number = √(22.5 × 10 × 30) = √6750 ≈ $82

If trading at $70, it's potentially undervalued.
            """
        },
        {
            "name": "Dividend Growth Investing",
            "description": "Focus on stable, growing dividend payments over capital appreciation.",
            "category": "quality",
            "content": """
# Dividend Growth Investing for Beginners

## Goal
Build a portfolio that generates steady, rising income over time.

## Key Metrics
- **Dividend Yield**: 2-5% (current annual dividend / stock price)
- **Payout Ratio**: 30-60% (dividend as % of earnings; 0-100% is sustainable)
- **Dividend Growth Rate**: 5-10% annually for past 5-10 years
- **Years of Growth**: > 10 consecutive years (history of reliability)

## Screening Criteria
1. Large-cap, established companies
2. Dividend yield 2.5-5%
3. Payout ratio < 70% (room to grow)
4. 10+ year history of annual increases
5. Strong balance sheet (debt/equity < 1)

## Why It Works
- Dividends provide steady cash flow
- Companies that grow dividends tend to have stable, profitable businesses
- Reinvested dividends create compounding effect
            """
        }
    ]

    for fw in frameworks:
        try:
            cursor.execute(
                """INSERT INTO frameworks (name, description, category, content)
                   VALUES (?, ?, ?, ?)""",
                (fw["name"], fw["description"], fw["category"], fw["content"])
            )
        except sqlite3.IntegrityError:
            pass  # Framework already exists

    conn.commit()
    conn.close()
```

### JSON Schema (Portfolio)

Located at: `~/.stock_analyst/portfolio.json`

Initialize on first run:

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
      "purchase_date": "2023-01-10",
      "notes": ""
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

**Rationale**:
- **portfolio**: List of holdings with cost basis (needed for performance tracking)
- **watchlist**: Stocks to monitor but not yet buy
- **sectors_allocation_target**: Optional goal allocation (can be used for rebalancing analysis)

---

## MCP Tool Specifications

### Overview

**Tool count**: 9 core tools (may expand to 11 in later phases)
**Tool naming**: snake_case (MCP convention)
**Error handling**: Graceful degradation (return cached data if API fails)
**Rate limiting**: Built into each tool via decorators

---

### 1. get_stock_quote

**Purpose**: Fetch current stock price and market data.

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ticker` | string | Yes | Stock ticker symbol (e.g., "AAPL", "MSFT") |

**Return Schema**:
```python
{
    "ticker": "AAPL",
    "price": 150.25,
    "currency": "USD",
    "change": -2.50,                    # Price change (dollars)
    "change_pct": -1.64,                # Percent change
    "volume": 45682300,                 # Shares traded today
    "volume_avg": 46500000,             # 3-month average volume
    "market_cap": 2300000000000,        # Total market value
    "52_week_high": 199.62,
    "52_week_low": 120.50,
    "last_updated": "2026-03-21T15:30:00Z",
    "data_source": "yfinance"
}
```

**Data Source**: yfinance (primary) → Finnhub (fallback)
**Cache TTL**: 5 minutes (prices change throughout trading day)
**Error Handling**:
- Invalid ticker → Return 404 with helpful message
- API timeout → Return most recent cached quote with "stale" flag
- No cached data + API down → Return error

**Rate Limiting**: 1 call/sec per ticker (internally enforced)

**Code Example**:
```python
from fastmcp import FastMCP
from functools import lru_cache
from time import time
import yfinance as yf

mcp = FastMCP("stock-analyst")

@mcp.tool()
@cached_tool(ttl_seconds=300)  # 5 min cache
def get_stock_quote(ticker: str) -> dict:
    """
    Get current stock price and market data.

    Uses yfinance for free, real-time data.
    Updates every 5 minutes (cached to avoid rate limits).
    """
    ticker = ticker.upper()
    try:
        stock = yf.Ticker(ticker)
        info = stock.info

        return {
            "ticker": ticker,
            "price": info.get("currentPrice"),
            "currency": "USD",
            "change": info.get("currentPrice", 0) - info.get("previousClose", 0),
            "change_pct": info.get("regularMarketChangePercent"),
            "volume": info.get("volume"),
            "volume_avg": info.get("averageVolume"),
            "market_cap": info.get("marketCap"),
            "52_week_high": info.get("fiftyTwoWeekHigh"),
            "52_week_low": info.get("fiftyTwoWeekLow"),
            "last_updated": datetime.now().isoformat(),
            "data_source": "yfinance"
        }
    except Exception as e:
        return {"error": f"Could not fetch quote for {ticker}: {str(e)}"}
```

---

### 2. get_fundamentals

**Purpose**: Fetch key financial metrics (P/E, ROE, dividend yield, growth rates).

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ticker` | string | Yes | Stock ticker |
| `period` | string | No | "annual" (default) or "quarterly" |

**Return Schema**:
```python
{
    "ticker": "AAPL",
    "period": "annual",
    "pe_ratio": 28.5,                   # Price-to-earnings
    "peg_ratio": 2.1,                   # P/E to growth (< 1 = undervalued)
    "roe": 0.85,                        # Return on equity (0-1 scale)
    "debt_to_equity": 1.65,
    "current_ratio": 1.08,              # Current assets / liabilities
    "dividend_yield": 0.0045,           # As decimal (0.45%)
    "dividend_per_share": 0.24,
    "eps": 6.05,                        # Earnings per share (trailing)
    "revenue_growth": 0.04,             # YoY growth (4%)
    "earnings_growth": 0.07,            # YoY earnings growth
    "profit_margin": 0.26,              # Net profit margin
    "operating_margin": 0.31,
    "market_cap": 2300000000000,
    "enterprise_value": 2400000000000,  # Market cap + debt - cash
    "book_value": 3.50,                 # Per share
    "last_updated": "2026-03-21",
    "data_source": "yfinance + Finnhub"
}
```

**Data Source**: yfinance (primary) + Finnhub API (fallback for richer metrics)
**Cache TTL**: 1 day (fundamentals don't change intraday)
**Error Handling**:
- Metric not available → Include in response with `null` or omit
- API failure → Return stale cache with "1 day old" warning
- Invalid ticker → 404 with message

**Rate Limiting**: 60 calls/min (Finnhub free tier limit)

---

### 3. get_company_info

**Purpose**: Fetch company profile data (sector, industry, description).

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ticker` | string | Yes | Stock ticker |

**Return Schema**:
```python
{
    "ticker": "AAPL",
    "name": "Apple Inc.",
    "sector": "Technology",
    "industry": "Consumer Electronics",
    "description": "Apple Inc. designs, manufactures, and markets...",
    "website": "https://www.apple.com",
    "headquarters": "Cupertino, California",
    "founded": 1976,
    "ceo": "Tim Cook",
    "employees": 164000,
    "phone": "+1-408-996-1010",
    "last_updated": "2026-03-21",
    "data_source": "yfinance"
}
```

**Data Source**: yfinance
**Cache TTL**: 7 days (company profile doesn't change often)
**Error Handling**: Return available fields; omit missing ones

**Rate Limiting**: 1 call/sec per ticker

---

### 4. get_stock_news

**Purpose**: Fetch recent news headlines and summaries for a stock.

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ticker` | string | Yes | Stock ticker |
| `limit` | int | No | Number of articles (default: 5, max: 20) |

**Return Schema**:
```python
{
    "ticker": "AAPL",
    "articles": [
        {
            "headline": "Apple Q2 Earnings Beat Expectations",
            "source": "Reuters",
            "url": "https://...",
            "published_at": "2026-03-20T14:30:00Z",
            "summary": "Apple reported stronger-than-expected Q2 earnings..."
        }
    ],
    "last_updated": "2026-03-21T10:00:00Z",
    "data_source": "Finnhub"
}
```

**Data Source**: Finnhub API (free tier)
**Cache TTL**: 1 hour (news changes frequently)
**Error Handling**: Return empty array if no news; don't fail

**Rate Limiting**: 60 calls/min (Finnhub free tier)

---

### 5. get_portfolio

**Purpose**: Return user's current holdings, watchlist, and allocation targets (read-only).

**Input**: None

**Return Schema**:
```python
{
    "portfolio": [
        {
            "ticker": "AAPL",
            "shares": 100.5,
            "cost_basis": 150.00,
            "purchase_date": "2024-06-15",
            "notes": "Dividend reinvestment enabled"
        }
    ],
    "watchlist": ["NVDA", "TSLA"],
    "sectors_allocation_target": {
        "Technology": 0.30,
        "Healthcare": 0.20
    }
}
```

**Data Source**: JSON file (`~/.stock_analyst/portfolio.json`)
**Cache TTL**: None (always fresh from disk)
**Error Handling**: Initialize empty portfolio.json on first run

---

### 6. update_portfolio

**Purpose**: Add or update a holding in the portfolio.

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ticker` | string | Yes | Stock ticker |
| `shares` | float | Yes | Number of shares |
| `cost_basis` | float | Yes | Average cost per share |
| `purchase_date` | string | Yes | ISO format (YYYY-MM-DD) |
| `notes` | string | No | Optional purchase notes |

**Return Schema**:
```python
{
    "status": "updated",
    "ticker": "AAPL",
    "action": "updated|added",
    "portfolio_size": 2
}
```

**Data Source**: Modifies JSON file
**Cache TTL**: N/A (write operation)
**Error Handling**: Validate date format; return helpful error if invalid

---

### 7. add_to_watchlist

**Purpose**: Add a stock to the watchlist for monitoring.

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ticker` | string | Yes | Stock ticker |

**Return Schema**:
```python
{
    "status": "added",
    "ticker": "NVDA",
    "watchlist": ["NVDA", "TSLA", "META"]
}
```

**Data Source**: Modifies JSON file
**Cache TTL**: N/A (write operation)
**Error Handling**: Check for duplicates; return success if already present

---

### 8. save_investment_note

**Purpose**: Save personal research notes, theses, or analysis to knowledge base.

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | string | Yes | Note title |
| `content` | string | Yes | Full note (supports markdown) |
| `ticker` | string | No | Associated ticker (null for general notes) |
| `tags` | list[string] | No | Tags (e.g., ["bull-case", "dividend"]) |

**Return Schema**:
```python
{
    "status": "saved",
    "note_id": 42,
    "title": "MSFT Bull Case",
    "ticker": "MSFT",
    "created_at": "2026-03-21T10:30:00Z"
}
```

**Data Source**: SQLite notes table
**Cache TTL**: N/A (write operation)
**Error Handling**: Validate title length; return ID on success

---

### 9. search_knowledge_base

**Purpose**: Full-text search personal investment notes.

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | Yes | Search query (keywords or phrases) |
| `ticker` | string | No | Filter by ticker |
| `limit` | int | No | Max results (default: 5, max: 20) |

**Return Schema**:
```python
{
    "query": "dividend growth",
    "results": [
        {
            "id": 12,
            "ticker": "JNJ",
            "title": "Johnson & Johnson: Dividend Growth Analysis",
            "content": "JNJ has grown dividends for 60+ consecutive years...",
            "tags": ["dividend", "quality"],
            "created_at": "2026-03-15T09:00:00Z",
            "relevance_score": 0.95
        }
    ],
    "count": 1
}
```

**Data Source**: SQLite FTS5 index
**Cache TTL**: None (always queries fresh database)
**Error Handling**: Return empty results if no matches; don't fail

---

### 10. compare_stocks

**Purpose**: Compare multiple stocks on a chosen metric.

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `tickers` | list[string] | Yes | List of tickers to compare |
| `metric` | string | Yes | Metric: "pe", "dividend_yield", "roe", "growth" |

**Return Schema**:
```python
{
    "metric": "pe",
    "comparison": {
        "AAPL": 28.5,
        "MSFT": 35.2,
        "GOOGL": 24.8
    },
    "average": 29.5,
    "industry_average": 25.0,
    "best": "GOOGL",
    "worst": "MSFT"
}
```

**Data Source**: Calls `get_fundamentals` internally for each ticker
**Cache TTL**: 1 day (leverages cached fundamentals)
**Error Handling**: Omit tickers that fail; return partial results

---

### 11. get_investment_frameworks (Bonus)

**Purpose**: List or retrieve pre-seeded investment frameworks and personal educational content.

**Input**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | No | Get specific framework; if omitted, list all |

**Return Schema** (list):
```python
{
    "frameworks": [
        {
            "id": 1,
            "name": "Buffett's Value Investing",
            "description": "Long-term investing in quality businesses...",
            "category": "valuation"
        }
    ]
}
```

**Return Schema** (single):
```python
{
    "id": 1,
    "name": "Buffett's Value Investing",
    "description": "...",
    "category": "valuation",
    "content": "[Full markdown content of framework]"
}
```

**Data Source**: SQLite frameworks table
**Cache TTL**: 1 day
**Error Handling**: Return empty list if no frameworks; return 404 for specific unknown framework

---

## MCP Resources

Resources are **read-only context** injected by the MCP server before Claude reasons over a problem. They're set up once, then Claude can reference them throughout the conversation.

### portfolio_snapshot

**Purpose**: Inject current portfolio summary as context for Claude.

**Content** (plain text):
```
Current Holdings:
- AAPL: 100.5 shares @ $150.00 (total: $15,075)
- MSFT: 50 shares @ $350.00 (total: $17,500)

Watchlist: NVDA, TSLA, META

Allocation Targets:
- Technology: 30%
- Healthcare: 20%
- Financials: 15%
- Industrials: 10%
- Other: 25%
```

**Update frequency**: Called once per conversation (on server start)

**Code**:
```python
@mcp.resource()
def portfolio_snapshot() -> str:
    """Portfolio summary injected as read-only context."""
    data = get_portfolio()
    snapshot = "Current Holdings:\n"
    for h in data["portfolio"]:
        total = h["shares"] * h["cost_basis"]
        snapshot += f"- {h['ticker']}: {h['shares']} shares @ ${h['cost_basis']:.2f} (total: ${total:,.0f})\n"
    snapshot += f"\nWatchlist: {', '.join(data['watchlist'])}\n"
    snapshot += "\nAllocation Targets:\n"
    for sector, pct in data.get("sectors_allocation_target", {}).items():
        snapshot += f"- {sector}: {pct*100:.0f}%\n"
    return snapshot
```

### active_frameworks

**Purpose**: Inject list of available investment frameworks.

**Content** (plain text):
```
Available Investment Frameworks:
1. Buffett's Value Investing - Long-term investing in quality businesses
2. Graham Number (Valuation Floor) - Conservative valuation estimate
3. Dividend Growth Investing - Focus on stable, growing dividends

Use search_knowledge_base() to find personal notes on any framework.
```

**Update frequency**: Called once per conversation

---

## Caching Strategy

### TTL-Based File Cache

All data is cached locally in `~/.stock_analyst/cache/` with timestamp-based expiration.

```python
# cache.py
import json
from pathlib import Path
from time import time
from functools import wraps
from datetime import datetime

CACHE_DIR = Path.home() / ".stock_analyst" / "cache"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

def cached_tool(ttl_seconds=300):
    """
    Decorator for caching API responses with TTL.

    Usage:
        @cached_tool(ttl_seconds=300)  # 5 minutes
        def get_stock_quote(ticker):
            # API call here
            pass
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key: function_name_arg1_arg2...
            cache_key = f"{func.__name__}_{args}_{hash(str(kwargs))}"
            cache_file = CACHE_DIR / f"{cache_key}.json"

            # Check if cached data exists and is fresh
            if cache_file.exists():
                with open(cache_file) as f:
                    cached = json.load(f)
                    age_seconds = time() - cached["timestamp"]

                    if age_seconds < ttl_seconds:
                        cached["data"]["_cached"] = True
                        cached["data"]["_cached_age_seconds"] = int(age_seconds)
                        return cached["data"]

            # Cache miss or expired; fetch fresh data
            try:
                result = func(*args, **kwargs)
                result["_fresh"] = True

                # Store in cache
                cache_file.write_text(json.dumps({
                    "timestamp": time(),
                    "data": result,
                    "ttl_seconds": ttl_seconds
                }))

                return result

            except Exception as e:
                # API failed; try returning stale cache with warning
                if cache_file.exists():
                    with open(cache_file) as f:
                        cached = json.load(f)
                    cached["data"]["_error"] = f"API call failed; returning cached data ({int(time() - cached['timestamp'])} seconds old)"
                    cached["data"]["_cached"] = True
                    return cached["data"]
                else:
                    # No cache available
                    raise Exception(f"API call failed and no cached data: {str(e)}")

        return wrapper
    return decorator


def clear_cache(ticker=None):
    """Clear cache for a specific ticker or all."""
    if ticker:
        ticker = ticker.upper()
        for f in CACHE_DIR.glob(f"*{ticker}*.json"):
            f.unlink()
        return f"Cleared cache for {ticker}"
    else:
        import shutil
        shutil.rmtree(CACHE_DIR)
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        return "Cleared all cache"
```

### Cache TTLs by Data Type

| Data Type | TTL | Rationale |
|-----------|-----|-----------|
| Stock quotes (price, change) | 5 min | Prices change throughout trading day |
| Fundamentals (P/E, ROE, etc.) | 1 day | Fundamentals released quarterly/annually |
| Company info (sector, description) | 7 days | Profile data rarely changes |
| News | 1 hour | News is time-sensitive |
| Investment frameworks | 1 day | Reference data, rarely changes |
| Knowledge base searches | None | Always query fresh DB |

### Stale-on-Error Strategy

If an API call fails but cached data exists, return the cached data with a warning:

```python
{
    "ticker": "AAPL",
    "price": 150.25,  # Stale data
    "_error": "API call failed; returning cached data (3 hours old)",
    "_cached": True,
    "_cached_age_seconds": 10800
}
```

This allows Claude to continue reasoning with slightly stale data rather than failing.

### Manual Cache Management Tool

```python
@mcp.tool()
def clear_cache(ticker: str | None = None) -> dict:
    """Clear cache to force fresh API calls."""
    if ticker:
        from . import cache
        result = cache.clear_cache(ticker=ticker)
    else:
        from . import cache
        result = cache.clear_cache()
    return {"status": "ok", "message": result}
```

---

## Configuration

### Environment Variables

Create `~/.stock_analyst/config.json` on first run (or use env vars):

```json
{
  "finnhub_api_key": "YOUR_FREE_TIER_KEY",
  "cache_ttl_quote_seconds": 300,
  "cache_ttl_fundamentals_seconds": 86400,
  "cache_ttl_company_info_seconds": 604800,
  "api_rate_limit_calls_per_minute": 60,
  "data_dir": "~/.stock_analyst"
}
```

### Python Config Module

```python
# config.py
import os
import json
from pathlib import Path

CONFIG_FILE = Path.home() / ".stock_analyst" / "config.json"
DATA_DIR = Path.home() / ".stock_analyst"

def load_config():
    """Load config from file or environment."""
    config = {
        "finnhub_api_key": os.getenv("FINNHUB_API_KEY", ""),
        "cache_ttl_quote_seconds": 300,
        "cache_ttl_fundamentals_seconds": 86400,
        "cache_ttl_company_info_seconds": 604800,
        "api_rate_limit_calls_per_minute": 60,
    }

    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            file_config = json.load(f)
            config.update(file_config)

    return config

CONFIG = load_config()
```

---

## Error Handling Strategy

### API Failures

| Scenario | Handling |
|----------|----------|
| Timeout (>5 sec) | Return cached data if available; else error |
| Rate limit exceeded | Back off and retry after 60 seconds; return cached data |
| Invalid ticker | Return 404-style error with message |
| Malformed response | Log error; return cached data if available |
| Network unreachable | Return cached data with warning |

### Data Validation

```python
from pydantic import BaseModel, Field

class StockQuote(BaseModel):
    ticker: str
    price: float = Field(gt=0)
    change_pct: float
    volume: int = Field(ge=0)

def validate_quote(data: dict) -> StockQuote:
    """Validate API response against schema."""
    try:
        return StockQuote(**data)
    except ValidationError as e:
        raise ValueError(f"Invalid quote data: {e}")
```

### Graceful Degradation

Always aim to return **something useful** rather than failing:

1. Try fresh API call
2. If fails, try returning cached data (even if stale)
3. If no cache, return helpful error with next steps

---

## Dependencies

**Python version**: 3.10+

| Package | Version | Purpose | License |
|---------|---------|---------|---------|
| `fastmcp` | 3.0+ | MCP server framework | MIT |
| `yfinance` | 0.2.32+ | Stock price and fundamentals | Apache 2.0 |
| `finnhub-python` | 1.3.13+ | Finnals, news, fundamentals | MIT |
| `requests` | 2.31+ | HTTP requests for APIs | Apache 2.0 |
| `pydantic` | 2.5+ | Data validation and schemas | MIT |
| `python-dateutil` | 2.8.2+ | Date parsing | BSD |
| (dev) `pytest` | 7.4+ | Testing framework | MIT |
| (dev) `pytest-cov` | 4.1+ | Coverage reporting | MIT |
| (dev) `black` | 23.12+ | Code formatter | MIT |
| (dev) `ruff` | 0.1+ | Linter | MIT |

**requirements.txt**:
```
fastmcp==3.0.0
yfinance==0.2.32
finnhub-python==1.3.13
requests==2.31.0
pydantic==2.5.0
python-dateutil==2.8.2
```

**requirements-dev.txt**:
```
-r requirements.txt
pytest==7.4.0
pytest-cov==4.1.0
black==23.12.0
ruff==0.1.8
```

---

## Setup & Installation

### Step 1: Clone and Environment Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/stock-analyst-mcp.git
cd stock_analyst_mcp

# Create virtual environment
python3.10 -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Configure API Keys

```bash
# Get a free Finnhub API key from https://finnhub.io/
# (yfinance needs no key)

# Set environment variable:
export FINNHUB_API_KEY="your_key_here"

# Or create ~/.stock_analyst/config.json:
mkdir -p ~/.stock_analyst
cat > ~/.stock_analyst/config.json << EOF
{
  "finnhub_api_key": "your_key_here"
}
EOF
```

### Step 3: Initialize Knowledge Base

```bash
python -m stock_analyst_mcp.data.db init
# This creates ~/.stock_analyst/knowledge.db with schema and seed frameworks
```

### Step 4: Create Initial Portfolio

```bash
# Create empty portfolio.json:
cat > ~/.stock_analyst/portfolio.json << EOF
{
  "portfolio": [],
  "watchlist": [],
  "sectors_allocation_target": {}
}
EOF
```

### Step 5: Test the Server

```bash
# Start MCP server (runs in stdio mode by default)
python -m stock_analyst_mcp.main

# Server should output MCP protocol handshake
# Press Ctrl+C to stop
```

### Step 6: Add to Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or equivalent on Windows/Linux:

```json
{
  "mcpServers": {
    "stock-analyst": {
      "command": "python",
      "args": [
        "-m",
        "stock_analyst_mcp.main"
      ],
      "env": {
        "FINNHUB_API_KEY": "your_key_here"
      }
    }
  }
}
```

Restart Claude Desktop. The Stock Analyst MCP should appear in the Tools panel.

---

## FastMCP Server Entry Point

**stock_analyst_mcp/main.py**:

```python
#!/usr/bin/env python3
"""
Stock Analyst MCP Server Entry Point

Runs as a FastMCP server over stdio, exposing tools and resources for Claude.
"""

from fastmcp import FastMCP
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastMCP server instance
mcp = FastMCP("stock-analyst", "An MCP server for stock analysis and investment research")

# Import and register all tools
from stock_analyst_mcp.tools.market_data import (
    get_stock_quote,
    get_fundamentals,
    get_company_info,
    get_stock_news
)

from stock_analyst_mcp.tools.knowledge_base import (
    save_investment_note,
    search_knowledge_base,
    get_investment_frameworks
)

from stock_analyst_mcp.tools.portfolio import (
    get_portfolio,
    update_portfolio,
    add_to_watchlist
)

from stock_analyst_mcp.tools.analysis import (
    compare_stocks
)

from stock_analyst_mcp.resources.portfolio import (
    portfolio_snapshot,
    active_frameworks
)

# Register tools (FastMCP auto-discovers via decorator, or register explicitly)
mcp.register_tool(get_stock_quote)
mcp.register_tool(get_fundamentals)
mcp.register_tool(get_company_info)
mcp.register_tool(get_stock_news)
mcp.register_tool(save_investment_note)
mcp.register_tool(search_knowledge_base)
mcp.register_tool(get_investment_frameworks)
mcp.register_tool(get_portfolio)
mcp.register_tool(update_portfolio)
mcp.register_tool(add_to_watchlist)
mcp.register_tool(compare_stocks)

# Register resources
mcp.register_resource(portfolio_snapshot)
mcp.register_resource(active_frameworks)

def main():
    """Start the MCP server."""
    logger.info("Starting Stock Analyst MCP server...")
    mcp.run()

if __name__ == "__main__":
    main()
```

Run with:
```bash
python -m stock_analyst_mcp.main
```

Or from the repo root:
```bash
./stock_analyst_mcp/main.py
```

---

## Deployment Checklist

- [ ] Python 3.10+ installed
- [ ] Virtual environment created and activated
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] Finnhub API key obtained (free tier)
- [ ] `~/.stock_analyst/` directory structure created
- [ ] `knowledge.db` initialized with schema
- [ ] `portfolio.json` created with initial structure
- [ ] `config.json` populated with API keys
- [ ] MCP server tested locally (`python -m stock_analyst_mcp.main`)
- [ ] Claude Desktop config updated with MCP server entry
- [ ] Claude Desktop restarted
- [ ] Test tools in Claude (e.g., "What's the P/E ratio of AAPL?")

---

## Summary of Design Decisions

| Decision | Rationale |
|----------|-----------|
| FastMCP 3.0 | Decorator-based, 5x faster dev, industry standard (70% of MCPs) |
| yfinance + Finnhub | Free, reliable, Finnhub has fundamentals/news, yfinance for prices |
| SQLite + FTS5 | Zero dependencies, ships with Python, full-text search for notes |
| JSON for portfolio | Simple, portable, no DB overhead for single-user tool |
| 8-10 tools | Atomic operations (user intents) over 30+ granular API wrappers |
| TTL caching | File-based, local, respects free API rate limits |
| Stale-on-error | Better UX (returns cached data if API down) vs. failing |
| Local-only deployment | Claude Desktop/Cowork MCP, no cloud infrastructure |
| Pre-seeded frameworks | Immediate utility for beginners; user can add more |

---

## Next Steps (Week-by-Week Build Plan)

**Week 1**:
- **Day 1**: Project setup, venv, dependencies, directory structure
- **Day 2-3**: Core market data tools (get_stock_quote, get_fundamentals) + testing
- **Day 4**: Knowledge base tools (save_investment_note, search_knowledge_base)
- **Day 5**: Portfolio tools (get_portfolio, add_to_watchlist, update_portfolio)

**Week 2**:
- **Day 1**: Comparison tool, news integration
- **Day 2**: Resources, caching refinement, error handling
- **Day 3-4**: Integration with Claude Desktop, end-to-end testing
- **Day 5**: Documentation, deployment instructions, cleanup

**Post-launch (v1.5+)**:
- Stock screening with framework-based filters
- Thesis comparison over time
- SEC filing summaries (10-K, 10-Q)
- Backtesting basic strategies

---

**Document prepared**: 2026-03-21
**Status**: Ready for implementation
**Estimated build time**: 1-2 weeks (solo developer)
**Next artifact**: Detailed MCP Tool Specifications (MCP_TOOL_SPECS.md) with exact return codes and edge cases
