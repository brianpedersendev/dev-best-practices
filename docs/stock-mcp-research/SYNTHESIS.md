# Research Synthesis: Stock Analyst MCP

## Topic: Python MCP server for long-term stock analysis and personal investment knowledge base
## Date: 2026-03-21
## Researchers: Domain (financial APIs & frameworks), Landscape (existing MCPs & tools), Technical (architecture & implementation)

---

## Problem Statement
A beginner investor with existing stock holdings wants to make better long-term investment decisions through an AI-integrated tool. Rather than learning separate financial platforms, he wants to ask Claude questions like "how's my portfolio?" or "find me good dividend stocks" and get data-backed answers. No existing tool combines MCP integration + personal knowledge base + beginner-friendly fundamentals analysis.

---

## Key Insights

1. **The knowledge base is the unique differentiator.** 10+ finance MCPs already exist, but none integrate personal thesis tracking, investment notes, or educational frameworks. This is the feature worth building. — Sources: GitHub survey of 15+ finance MCPs, PulseMCP, LobeHub registries

2. **Build custom, don't extend.** Existing MCPs are mostly single-developer data-fetch wrappers. The knowledge base layer requires ground-up architecture that doesn't fit cleanly into any existing project. Study MaverickMCP's code for patterns, but build fresh. — Sources: MaverickMCP, FMP MCP, Yahoo Finance MCP codebases

3. **yfinance + Finnhub is the optimal free data stack.** yfinance for prices (fast, simple), Finnhub for fundamentals and news (60 calls/min free). FMP as fallback (250 calls/day). Alpha Vantage too limited (25/day). IEX Cloud is dead (shut down Aug 2024). — Sources: API documentation for each provider

4. **FastMCP 3.0 is the framework to use.** Released Jan 2026, powers 70% of MCP servers, 1M downloads/day. Decorator-based tools, automatic schema generation, 5x faster dev than raw SDK. — Sources: FastMCP docs, PyPI, release announcement

5. **P/E, ROE, and Debt/Equity are the starter metrics.** Capture valuation, profitability, and financial health with minimal complexity. Dividend yield for income-focused screening. Revenue/EPS growth for quality. Avoid complex metrics (PEG, ROIC, FCF) for v1. — Sources: Schwab, AAII, Buffett frameworks

6. **SQLite + FTS5 beats vector DB for v1 knowledge base.** Zero dependencies, ships with Python, full-text search handles personal notes at scale. ChromaDB adds complexity without proportional benefit for personal use. Easy migration later. — Sources: SQLite docs, ChromaDB comparison studies

7. **8-10 atomic tools, not 30+ API wrappers.** Design tools around user intents (analyze_fundamentals) not API endpoints (get_income_statement). Reduces token usage, improves Claude's reasoning, stays maintainable for a solo dev. — Sources: Klavis AI, Arcade MCP patterns

8. **"Not financial advice" disclaimers alone are legally meaningless.** Substance matters: present data factually, avoid actionable language ("you should buy"), frame as educational analysis. Build disclaimers into tool output, not just README. — Sources: Legal analysis of advisory disclaimers

9. **Value investing (Buffett-style) is the right beginner framework.** Understand the business, find durable moats (ROE >15% consistently), pay fair prices (P/E vs industry), hold long-term. Actionable and maps directly to available API data. — Sources: Buffett's shareholder letters, AAII education

10. **Cache TTLs prevent rate limit issues.** Quotes: 5 min, fundamentals: 1 day, company info: 7 days, SEC filings: 30 days. File-based cache with TTL decorators. Serve stale data if API is down rather than failing. — Sources: MCP caching best practices

11. **Portfolio persistence via JSON, knowledge base via SQLite.** JSON for holdings/watchlist (simple, portable, git-friendly). SQLite for notes and frameworks (needs full-text search). Both stored locally in ~/.stock_analyst/. — Sources: Technical research, existing MCP patterns

12. **Security is manageable but needs attention.** MCP ecosystem has known prompt injection and supply chain risks. Financial context amplifies these. Validate all inputs, don't store API keys in code, document key rotation. Building custom means you control the surface area. — Sources: MCP security reports (Composio, Adversa AI, Astrix)

---

## Existing Solutions

| Solution | Type | Strengths | Weaknesses | Notes |
|----------|------|-----------|------------|-------|
| MaverickMCP | Finance MCP | 29 tools, portfolio tracking, S&P 500 pre-seeded, active | No knowledge base, trader-focused | Best existing MCP to study |
| FMP MCP Server | Finance MCP | 253+ tools, deep fundamentals | Requires paid API, no thesis tracking | Overkill for beginner use case |
| Yahoo Finance MCPs (4+) | Finance MCP | Free, simple, easy to deploy | Shallow features, no analysis | Good pattern reference |
| Stock Rover | Retail screener | 650+ filters, best for long-term investors | $189/yr, not AI-integrated | Gold standard for screening UX |
| Simply Wall St | Retail screener | Visual, beginner-friendly, 120k stocks | Shallow analysis | Good UX model for beginners |
| Finviz | Retail screener | 60+ filters, heatmaps | Trader-focused, overwhelming | Less relevant for long-term |
| OpenBB SDK | Python library | Multi-source aggregation, popular | Steep learning curve | Consider for v2 |

---

## Opportunities

1. **Thesis tracker + live data integration** — Save investment theses per ticker, then compare against current fundamentals. No tool does this well. Impact: H, Feasibility: H
2. **Beginner-focused value screening** — Pre-built filters based on Buffett-style criteria (P/E < industry, ROE >15%, D/E <1). Impact: H, Feasibility: H
3. **Educational context in tool output** — When returning P/E ratio, include what it means and industry comparison. Teach as you go. Impact: M, Feasibility: H
4. **Conviction tracking over time** — "How has MSFT performed vs. my original thesis?" Requires persistent notes + historical data comparison. Impact: H, Feasibility: M
5. **One-page stock summary** — Condensed research output: 5-7 key metrics with context, bull/bear case, framework alignment. Impact: M, Feasibility: H

---

## Technical Constraints

- **Free API rate limits**: yfinance (~1-2 calls/sec), Finnhub (60/min), FMP (250/day). Caching is essential.
- **yfinance reliability**: Yahoo Finance API breaks unpredictably. Must handle silent failures and have fallback sources.
- **Python 3.10+**: Required for FastMCP 3.0 and modern type hints.
- **Local-only deployment**: Claude Desktop/Cowork MCP, not cloud. Simplifies architecture but limits to single machine.
- **No real-time data**: Free APIs have 5-15 min delays. Fine for long-term investing, but users should know.

---

## Risks

- **yfinance breaks**: Medium likelihood. Mitigation: Finnhub/FMP fallback, multi-source architecture from day one.
- **Scope creep**: High likelihood (user wants "all of these" for MVP). Mitigation: Strict v1 scope — 8-10 tools only, expand after core is stable.
- **"It just works" syndrome**: User may over-trust AI analysis. Mitigation: Clear disclaimers in every tool response, educational framing.
- **API provider changes/shutdowns**: Medium likelihood (IEX Cloud precedent). Mitigation: Abstract data layer so providers are swappable.
- **Beginner building finance tools**: Medium risk — domain expertise gap. Mitigation: Source all frameworks from established investing education (Schwab, AAII, Buffett), not from AI-generated content.

---

## Open Questions

1. **Should investment frameworks be pre-seeded or user-added?** Pre-seeding with Buffett basics makes the tool immediately useful, but user-driven keeps it lightweight. Recommend: pre-seed 3-5 core frameworks, let user add more.
2. **How to handle international stocks?** Finnhub free tier is US-only. If Brian holds international stocks, may need Twelve Data or paid Finnhub. Clarify during planning.
3. **News integration worth it for v1?** Finnhub provides free news, but news analysis adds complexity. Consider v1.5 feature.
4. **Portfolio performance tracking over time?** Requires historical snapshots, dividend tracking, etc. Significantly more complex than snapshot analysis. Recommend v2.

---

## Recommendations

**Build a custom Python MCP server using FastMCP 3.0** with three layers:

1. **Data layer**: yfinance (prices) + Finnhub (fundamentals/news) + FMP fallback, with TTL-based caching
2. **Knowledge layer**: SQLite + FTS5 for personal notes, investment theses, and pre-seeded value investing frameworks
3. **Portfolio layer**: JSON persistence for holdings and watchlist

Start with 8-10 tools focused on the unique value: thesis tracking + fundamentals analysis + beginner-friendly screening. Don't try to compete with Stock Rover on filter count — compete on Claude integration and educational context.

**v1 scope (1-2 weeks for solo dev):**
- Stock lookup (quote + fundamentals + company info)
- Portfolio snapshot and watchlist
- Knowledge base (save/search notes)
- Stock comparison
- Pre-seeded value investing framework

**v2 additions:**
- Stock screener with framework-based filters
- Thesis comparison over time
- News integration
- OpenBB for multi-source data standardization
- SEC filing summaries via EdgarTools

---

## Go / No-Go Recommendation

### Recommendation: GO

### Rationale
The research validates this as a worthwhile project on both axes — it's fun to build AND fills a real gap. The knowledge base + thesis tracking angle is genuinely unique in the MCP ecosystem. The technical path is clear (FastMCP + yfinance + SQLite), the API landscape is navigable on free tiers, and the 1-2 week scope for a useful v1 is realistic for a solo developer.

The main risk (scope creep) is manageable with discipline. The "not financial advice" concern is solvable with proper framing. The beginner-focused angle actually makes the tool simpler, not harder — fewer metrics, simpler frameworks, clearer output.

### If GO:
- Key advantages: Unique knowledge base angle, clear tech stack, manageable scope, fun project with real utility
- Biggest risks: yfinance reliability, scope creep, over-trusting AI output
- Suggested approach: FastMCP 3.0 + yfinance/Finnhub + SQLite, 8-10 tools, 1-2 week build

---

## Source Index

### Financial Data APIs
- [yfinance GitHub](https://github.com/ranaroussi/yfinance)
- [Finnhub API Documentation](https://finnhub.io/docs/api)
- [Financial Modeling Prep API](https://site.financialmodelingprep.com/developer/docs)
- [Alpha Vantage API](https://www.alphavantage.co/documentation/)
- [SEC EDGAR APIs](https://www.sec.gov/search-filings/edgar-application-programming-interfaces)
- [Twelve Data API](https://twelvedata.com/docs)
- [EdgarTools Python Library](https://github.com/dgunning/edgartools)

### MCP Framework & Patterns
- [FastMCP 3.0 Documentation](https://gofastmcp.com/)
- [FastMCP GitHub](https://github.com/PrefectHQ/fastmcp)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [MCP Tool Design Patterns (Klavis AI)](https://www.klavis.ai/blog/less-is-mcp-design-patterns-for-ai-agents)
- [54 MCP Patterns (Arcade)](https://www.arcade.dev/blog/mcp-tool-patterns)

### Existing Finance MCPs
- [MaverickMCP](https://github.com/wshobson/maverick-mcp)
- [FMP MCP Server](https://github.com/imbenrabi/Financial-Modeling-Prep-MCP-Server)
- [Yahoo Finance MCP](https://github.com/Alex2Yang97/yahoo-finance-mcp)
- [Financial Datasets MCP](https://github.com/financial-datasets/mcp-server)
- [Alpaca MCP Server](https://github.com/alpacahq/alpaca-mcp-server)

### Investment Education
- [Schwab: Five Key Financial Ratios](https://www.schwab.com/learn/story/five-key-financial-ratios-stock-analysis)
- [AAII: Beginner's Guide to Stock Investing](https://www.aaii.com/education)
- [OpenBB SDK](https://github.com/OpenBB-finance/OpenBB)

### Security
- [MCP Security Vulnerabilities (Practical DevSecOps)](https://www.practical-devsecops.com/mcp-security-vulnerabilities/)
- [MCP Vulnerabilities (Composio)](https://composio.dev/content/mcp-vulnerabilities-every-developer-should-know)
- [State of MCP Security 2025 (Astrix)](https://astrix.security/learn/blog/state-of-mcp-server-security-2025/)
