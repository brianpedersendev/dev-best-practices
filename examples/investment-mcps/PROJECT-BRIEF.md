# Investment Tools MCP Server — Project Brief

> A single MCP server that gives AI assistants professional-grade investment analysis: screening for long-term stock/fund picks AND evaluating existing portfolio holdings.

**Research Date:** 2026-03-22

---

## Problem Statement

Individual investors lack quick, structured access to the kind of screening and portfolio analysis that institutional investors get. Existing tools are either:
- **Too manual** — You have to visit multiple sites, run screeners, copy data into spreadsheets
- **Too expensive** — Bloomberg Terminal, Morningstar Premium, etc.
- **Not AI-integrated** — Even good tools like Finviz or Stock Rover can't be queried conversationally through an AI assistant

By wrapping financial data APIs and analysis logic into MCP servers, you get a personal investment analyst available inside Claude (or any MCP-compatible AI) — ask natural language questions and get data-backed answers.

---

## Target Users

- **Primary:** Individual long-term investors (buy-and-hold, value/quality focus)
- **Secondary:** Anyone using Claude Desktop or Claude Code who wants quick portfolio insights
- **Not for:** Day traders, HFT, or anyone needing sub-second real-time data

---

## Core Value Proposition

1. **"What should I buy?"** — AI screens thousands of stocks/funds using proven quality + value criteria (Piotroski F-Score, ROCE, FCF yield, P/E, debt ratios) and presents ranked candidates with reasoning
2. **"How are my holdings doing?"** — AI evaluates your current portfolio: performance vs benchmarks, risk metrics (Sharpe, Sortino, max drawdown, beta), sector concentration, rebalancing suggestions

---

## MVP Scope

### In Scope (v1)
- **Stock/Fund Screening**
  - Screen S&P 500 + popular ETFs/mutual funds
  - Value metrics: P/E, P/B, PEG, EV/EBITDA, FCF Yield
  - Quality metrics: ROE, ROCE, operating margin, Piotroski F-Score
  - Growth metrics: revenue growth, earnings growth, dividend growth
  - Financial health: debt/equity, interest coverage, current ratio
  - Composite scoring with configurable weights
  - Sector/industry filtering
  - Return top N candidates with explanations

- **Portfolio Evaluation**
  - Accept holdings as ticker + shares (or ticker + weight)
  - Performance: total return, CAGR, vs SPY/benchmark
  - Risk: Sharpe ratio, Sortino ratio, max drawdown, beta, VaR
  - Diversification: sector breakdown, correlation matrix, concentration risk
  - Individual holding analysis: each position's contribution to risk/return
  - Rebalancing suggestions based on target allocation

### Out of Scope (v1)
- Real-time streaming prices
- Options/derivatives analysis
- International markets beyond US-listed securities
- Tax optimization / tax-loss harvesting
- Trading execution (no buy/sell orders)
- Crypto assets
- Backtesting engine

---

## Known Competitors / Existing Work

Several financial MCP servers already exist on GitHub:

| Project | What It Does | Gap We Fill |
|---------|-------------|-------------|
| [yahoo-finance-mcp](https://github.com/Alex2Yang97/yahoo-finance-mcp) | Raw Yahoo Finance data access | No screening logic, no scoring, no portfolio analysis |
| [Financial-Modeling-Prep-MCP-Server](https://github.com/imbenrabi/Financial-Modeling-Prep-MCP-Server) | FMP API wrapper | Data access only, no investment analysis |
| [maverick-mcp](https://github.com/wshobson/maverick-mcp) | Technical analysis + screening | Closest competitor — but focused on trading, not long-term value investing |
| [alpaca-mcp-server](https://github.com/alpacahq/alpaca-mcp-server) | Trading execution | Execution-focused, not analysis |
| [mcp-trader](https://github.com/wshobson/mcp-trader) | Trading tools | Short-term trading focus |

**Key differentiator:** None of these combine (a) opinionated long-term value/quality screening with composite scoring AND (b) portfolio-level risk/performance evaluation. Most are thin API wrappers. We add the *analysis layer*.

---

## Technical Constraints

1. **Data source must have a usable free tier** — yfinance (free) as primary, Financial Modeling Prep ($19/mo) as optional upgrade
2. **Python + FastMCP** — Aligns with knowledge base recommendations, largest ecosystem for financial analysis
3. **No API keys required for basic functionality** — yfinance needs no key; FMP key optional for enhanced data
4. **Must work with Claude Desktop** — Stdio transport for local dev
5. **Stateless between calls** — No database required for MVP (holdings passed per request)

---

## Architecture Direction

Single MCP server with both screening and portfolio analysis tools. Split later only if tool count exceeds ~15 or domains genuinely diverge.

```
┌──────────────────────────────────────────┐
│         investment-tools MCP              │
│                                          │
│  Screening:          Portfolio:          │
│  - screen_stocks     - evaluate_portfolio│
│  - screen_funds      - analyze_holding   │
│  - get_stock_detail  - risk_report       │
│  - compare_stocks    - sector_breakdown  │
│  - list_strategies   - suggest_rebalance │
│                                          │
│  Data: yfinance + FMP (optional)         │
│  Analytics: QuantStats                   │
│  Cache: SQLite (24hr TTL)                │
└──────────────────────────────────────────┘
```

**Why MCP (vs alternatives):** The primary interface is conversational (ask Claude questions, get data-backed answers). MCP's tool discovery and composability make this seamless. The core analysis logic lives in plain Python modules — MCP is just the transport layer, so there's no lock-in. See PLAN.md for the full alternatives analysis.

---

## Success Criteria

1. Can ask Claude "Find me 10 quality value stocks under $100 with strong cash flow" and get a scored, ranked table
2. Can paste portfolio holdings and get a professional-grade tear sheet summary (Sharpe, drawdown, sector breakdown)
3. Server installs and runs with `uvx investment-tools` + simple Claude Desktop config
4. Response time < 30 seconds for a full screen of S&P 500
5. Works with zero API keys (yfinance only mode)

---

## Open Questions

1. **Mutual fund coverage depth** — yfinance has limited mutual fund fundamental data. May need FMP or a dedicated fund data source.
2. **Watchlist/tracking** — Should we add watchlist persistence, or keep the server stateless (holdings passed per request)?
3. **Finnhub alternative data** — Worth adding insider transactions, ESG scores, congressional trading as supplemental data? (Free tier: 60 req/min)
