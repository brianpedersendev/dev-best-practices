# Investment MCP Servers — Research Synthesis

**Research Date:** 2026-03-22

---

## Summary of Findings

### 1. The Data Layer Is Solved — Multiple Viable Free/Cheap Options

The financial data API ecosystem is mature and well-suited for this project:

| API | Free Tier | Best For | Reliability |
|-----|-----------|----------|-------------|
| **yfinance** | Unlimited (unofficial) | Prices, basic fundamentals, mutual funds | Good but unofficial — breaks occasionally when Yahoo changes endpoints |
| **Financial Modeling Prep** | 250 req/day | Deep fundamentals, ratios, screening | Excellent — official API, $19/mo unlimited |
| **Alpha Vantage** | 25 req/day | Technical indicators | Too limited on free tier for screening |
| **Polygon.io** | 5 req/min | Real-time prices | Overkill for long-term analysis |
| **Finnhub** | 60 req/min | News, sentiment | Good supplement, not core |

**Recommendation:** yfinance as the zero-config default, FMP as the "premium" data source for users who want deeper fundamentals. This two-tier approach means the MCP works out of the box with no API key, but gets better with one.

**Sources:**
- [yfinance GitHub](https://github.com/ranaroussi/yfinance) — 15k+ stars, actively maintained
- [FMP API](https://site.financialmodelingprep.com/) — $19/mo unlimited, 30+ years historical data
- [Financial Data APIs Compared (2026)](https://www.ksred.com/the-complete-guide-to-financial-data-apis-building-your-own-stock-market-data-pipeline-in-2025/)
- [Best Free Finance APIs (2025)](https://noteapiconnector.com/best-free-finance-apis)

### 2. Portfolio Analysis Libraries Are Production-Ready

Python's quantitative finance ecosystem is excellent:

- **[QuantStats](https://github.com/ranaroussi/quantstats)** — Best option. Same author as yfinance. Calculates Sharpe, Sortino, max drawdown, CAGR, VaR, and 30+ other metrics. Generates HTML tear sheets. Actively maintained (2019-2025).
- **[pyfolio](https://github.com/quantopian/pyfolio)** — Powerful but less actively maintained since Quantopian shut down. Bayesian analysis. Still usable but QuantStats is the safer bet.
- **empyrical** — Low-level returns analysis. Used under the hood by pyfolio. Not needed if using QuantStats.

**Recommendation:** QuantStats as the core analysis engine. It gives us Sharpe ratio, Sortino, max drawdown, CAGR, rolling analysis, benchmark comparison, and Monte Carlo simulation — all the metrics the portfolio evaluator needs.

**Sources:**
- [QuantStats PyPI](https://pypi.org/project/quantstats/)
- [QuantStats Portfolio Analysis Guide](https://medium.com/@elvis.thierry/analyze-risk-and-performance-with-quantstats-a-comprehensive-framework-for-portfolio-evaluation-633fd7e86693)

### 3. Existing MCP Servers Are Thin Wrappers — The Analysis Gap Is Real

Reviewed 9 existing financial MCP servers on GitHub. Key finding: **all are data access layers, none provide investment analysis logic.** They wrap APIs to fetch prices and fundamentals, but don't:
- Score stocks on composite quality/value metrics
- Run portfolio-level risk analysis
- Generate investment recommendations with reasoning
- Compare holdings against benchmarks

The closest competitor is [MaverickMCP](https://github.com/wshobson/maverick-mcp) which does screening, but it's focused on short-term trading signals (technical indicators) rather than long-term value/quality investing.

**This confirms a clear gap:** an MCP that adds an *opinionated analysis layer* on top of data doesn't exist yet.

**Sources:**
- [financial-datasets/mcp-server](https://github.com/financial-datasets/mcp-server)
- [yahoo-finance-mcp](https://github.com/Alex2Yang97/yahoo-finance-mcp)
- [Financial-Modeling-Prep-MCP-Server](https://github.com/imbenrabi/Financial-Modeling-Prep-MCP-Server)
- [maverick-mcp](https://github.com/wshobson/maverick-mcp)
- [alpaca-mcp-server](https://github.com/alpacahq/alpaca-mcp-server)

### 4. Screening Methodology Is Well-Established

Long-term stock screening has decades of academic backing. The most proven approaches:

| Strategy | Key Metrics | Track Record |
|----------|------------|--------------|
| **Piotroski F-Score** | 9 binary criteria (profitability, leverage, efficiency) | Outperformed market by 7.5% annually in original study |
| **Quality + Value (Terry Smith style)** | ROCE > 15%, FCF growth > 5%, reasonable FCF yield | Quality-focused, avoids value traps |
| **Buffett-style** | ROE > 15%, operating margin > 15%, low debt, consistent earnings growth | The classic approach |
| **Dividend Growth** | 5+ year dividend growth streak, payout ratio < 60%, yield > 2% | Income-focused long-term |
| **Novy-Marx Quality** | Gross profits / total assets, momentum, low P/B | Academically validated |

**Recommendation:** Implement these as **preset strategies** the user can choose from, plus allow custom screening with any combination of metrics. Default to a blended quality + value approach.

**Sources:**
- [Buffett-Style Python Screener](https://medium.datadriveninvestor.com/how-to-invest-like-warren-buffett-building-a-stock-screener-with-python-88f9a7ddda4c)
- [Quality Stock Screener (Terry Smith)](https://stockinvestoriq.com/quality-stock-screener/)
- [Quantitative Value Investing in Python](https://blog.quantinsti.com/quantitative-value-investing-strategy-python/)
- [Stock Screening with Fundamental Analysis](https://pythoninvest.com/long-read/stock-screening-using-paid-data)

### 5. Regulatory Considerations Are Manageable

Building a tool that surfaces investment data and scores is **legal and common** — but there are clear boundaries:

- **Not investment advice:** The tool screens and analyzes data. It does NOT tell people to buy or sell specific securities. Every output needs a disclaimer.
- **No fiduciary duty:** As a tool (not an advisor), there's no fiduciary obligation. But disclaimers must be clear.
- **SEC safe harbor:** Educational and informational tools are protected. The line is crossed when you: (a) provide personalized advice for compensation, or (b) hold yourself out as an investment advisor.
- **Required disclaimers:** "For informational and educational purposes only. Not investment advice. Past performance does not guarantee future results. Always do your own research and consult a qualified financial advisor."

**Recommendation:** Include the standard disclaimer in every tool response. Frame outputs as "screening results" and "portfolio analytics" — not "recommendations."

### 6. FastMCP Is the Right Framework

Per this knowledge base's [Building Custom MCP Servers](../../docs/topics/building-custom-mcp-servers.md) guide:
- FastMCP (Python) is the recommended framework for rapid development
- Decorator-based API makes tool definition trivial
- Type hints auto-generate JSON Schema for tool parameters
- Same author ecosystem as yfinance and QuantStats (Ran Aroussi)
- Stdio transport for local Claude Desktop, HTTP/SSE for production

---

## Go/No-Go Recommendation

### **GO** — with high confidence

**Rationale:**
1. **Clear gap:** No existing MCP server combines long-term screening + portfolio analysis
2. **Data is free:** yfinance provides everything needed for MVP at zero cost
3. **Libraries are mature:** QuantStats handles all the hard portfolio math
4. **Framework is proven:** FastMCP is battle-tested for exactly this pattern
5. **Low risk:** No database needed, no user auth, no money movement, no regulatory licensing
6. **High personal value:** This is a tool you'd actually use regularly

**Biggest risks:**
1. **yfinance reliability** — It's unofficial and can break. Mitigation: FMP fallback, defensive error handling
2. **Screening speed** — Fetching fundamentals for 500 stocks takes time. Mitigation: caching layer (daily refresh)
3. **Scope creep** — Easy to keep adding metrics/features. Mitigation: strict MVP, ship two lean servers first

---

## Suggested Approach

1. **Start with the Screener MCP** — Higher immediate value, more interesting technically
2. **Use a monorepo** — Shared data fetching layer between both servers
3. **Ship with yfinance-only first** — Zero API keys needed, lower barrier
4. **Add FMP integration as a follow-up** — For users who want deeper data
5. **Cache aggressively** — Fundamentals don't change intraday; cache for 24 hours minimum

---

## Traceability

| Brief Question | Finding |
|----------------|---------|
| Can we get free financial data? | Yes — yfinance is free and comprehensive |
| Do analysis libraries exist? | Yes — QuantStats is production-ready |
| Is there existing competition? | Thin wrappers only — no analysis layer exists |
| Is it legal to build this? | Yes — with standard disclaimers |
| What screening approach works? | Multiple proven strategies; implement as presets |
| What framework to use? | FastMCP (Python) — recommended by knowledge base |
