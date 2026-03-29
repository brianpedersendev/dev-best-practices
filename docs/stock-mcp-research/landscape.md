# Stock MCP Landscape Research

**Date:** March 2026
**Research Focus:** Existing finance/stock MCPs, competitive landscape, gaps, and trust assessment

---

## Key Findings

1. **10+ finance MCPs already exist**, with 5-6 actively maintained and production-ready. This is a crowded space, NOT a blue ocean.
2. **No single "dominant" MCP** — ecosystem is fragmented. Different servers optimize for different needs (analysis vs. trading vs. screening).
3. **Yahoo Finance MCPs are most common** (at least 4 independent implementations) due to free data, suggesting a good design pattern to follow.
4. **Two enterprise-grade options stand out:**
   - **MaverickMCP** (wshobson): Local, 29 tools, S&P 500 pre-seeded, portfolio tracking, technical analysis
   - **Financial Modeling Prep MCP** (FMP): Paid API ($0-$49/mo), 253+ tools, most comprehensive fundamental data
5. **Stock screener capability is widely implemented** but with shallow strategies. Long-term investors want deeper fundamental filtering.
6. **Critical gap: Personal investment knowledge base integration** — None of the existing MCPs meaningfully integrate with a knowledge base for annotating research, tracking thesis evolution, or maintaining investment rationale.
7. **Trust/security concerns are real** — MCP ecosystem has known vulnerabilities (prompt injection, supply chain risks, OAuth exploits). Financial data amplifies the risk surface.
8. **Liability/disclaimer problem is mostly unsolved** — Existing AI tools use generic "not investment advice" disclaimers, but there's no standard framework for how MCPs should handle this.
9. **Best-in-class retail screeners (Stock Rover, Simply Wall St) outmatch all MCPs on UX and filtering depth** — Any MCP that aspires to replace them needs ~650+ filters, not 20-30.
10. **Opportunity: The beginner long-term investor niche is underserved** — Existing MCPs are either trader-focused (technical indicators, alerts) or too generic (just data fetch). No MCP is built around "long-term fundamental thesis research + knowledge base."

---

## Details

### 1. Market Saturation and No Clear Winner

The MCP ecosystem for finance has exploded since mid-2025. As of March 2026, there are **at least 15+ public GitHub repositories** implementing stock/finance MCPs:

- Finance/stock data focus: ~10 active repos
- Brokerage integration (trading): ~3-4 repos (Alpaca, etc.)
- Supporting projects: Multiple registries (PulseMCP, LobeHub, Smithery.ai)

**Why so many?** Building a basic stock data MCP is easy (fetch from yfinance, wrap in tools). The barrier to entry is low, creating a "crowded marketplace" effect. Most are side projects by individual developers.

**No clear winner:** There is no dominant "go-to" finance MCP used by the majority. The closest are:
- **MaverickMCP** — most feature-rich for *analysis*, but requires running locally
- **Financial Datasets MCP** — most trusted source API, minimal but reliable
- **Yahoo Finance variants** — easiest to deploy, but data quality varies by implementation

**Implication for build-vs-extend decision:** Building custom would give you **differentiation in UX and thesis tracking**, but you'd be implementing 80% of existing functionality. Extending is tempting to avoid reinventing wheels, but most MCPs are brittle, single-developer projects.

---

### 2. Existing Finance MCPs - Detailed Assessment

| Name | Language | Data Source | Features | Maintenance | Stars | Last Commit | Trust Score |
|------|----------|-------------|----------|-------------|-------|-------------|------------|
| **MaverickMCP** | Python | yfinance, TA-Lib | 29 tools, technical indicators, portfolio P&L, backtests, S&P 500 pre-seeded | Very Good (active discussions) | ~50-100 (est.) | Dec 2024 - Jan 2025 | HIGH |
| **Financial Modeling Prep MCP** | JS/Node (imbenrabi) | FMP API (paid) | 253+ tools, full fundamentals, 24 categories, financials, analyst ratings | Good | ~30-50 (est.) | Recent | HIGH* |
| **Yahoo Finance MCP** (Alex2Yang97) | Python | yfinance | Stock data, financials, options, news, historical prices | Good (recent activity) | ~20-30 (est.) | 2024-2025 | MEDIUM |
| **Financial Datasets MCP** | Python | Financial Datasets API | Income/balance/cash flow, stock prices, news | Mixed (PulseMCP interim mgmt) | ~309-1.7k (conflicting reports) | 2024 | MEDIUM-HIGH |
| **Yahoo Finance Server** (AgentX-ai) | Python | yfinance | Stock data, news, financials, price history, options | Basic | ~10-20 (est.) | 2024 | MEDIUM |
| **InvestMCP** (arrpitk) | Python | Multiple (yfinance, etc.) | Stock data, technical indicators, news sentiment, screening, advice | Minimal (appears dormant) | ~5-15 (est.) | Unknown | LOW-MEDIUM |
| **Alpaca MCP Server** | Python/JS | Alpaca API (trading) | Trading, portfolio mgmt, market data, options — **for active traders only** | Good (Alpaca-backed) | ~100+ (est.) | Recent | HIGH* |
| **Stock Market MCP** (sverze, Finnhub) | Python | Finnhub API | Stock quotes, fundamentals, news | Minimal | ~5-10 (est.) | 2024 | MEDIUM |
| **Stockflow / Stockscreen** (twolven) | Python | yfinance | Stock screening, watchlist, technical filtering | Good (recently updated) | ~20 (est.) | Recent (2024-2025) | MEDIUM-HIGH |
| **Massive.com MCP** | Python | Massive.com API | Stocks, options, forex, crypto, futures aggregates | Unknown | ~5-10 (est.) | Unknown | UNKNOWN |

**Notes:**
- *HIGH trust indicators: Official/backed projects (Alpaca), enterprise APIs (FMP), actively maintained, clear liability practices*
- *Stars/commits are estimates from search results; GitHub search didn't return exact metrics for most*
- All except Alpaca are analysis-only (no trading permission required), which is safer

---

### 3. Competitive Tools Analysis

Existing consumer tools that the MCP space competes with (or should learn from):

| Tool | Type | Strengths | Weaknesses | Pricing | Relevance to Project |
|------|------|-----------|-----------|---------|----------------------|
| **Stock Rover** | Desktop screener | 650+ filters, backtesting, research depth, best for long-term investors, excellent UX | Desktop-only, $189/yr | $189/yr | HIGH — this is what a "proper" screener feels like. MCPs don't come close. |
| **Simply Wall St** | Web screener | Visual fundamentals, 120k stocks, beginner-friendly, beautiful UI | Shallow analysis, limited filters | Free + $12/mo | HIGH — better onboarding for beginners than any MCP. Emphasizes simplicity. |
| **Finviz** | Web screener | 60+ filters, fast, visual heatmaps, great for swing traders | Overwhelming UI, outdated feel | Free + $40/mo | MEDIUM — used by many, but traders focus not long-term investors |
| **Morningstar Investor** | Web/research platform | Deep fundamental research, analyst ratings, ETF research, professional-grade data | Expensive, bloated, steep learning curve | $200+/yr | MEDIUM — reference for what deep research looks like. Too much for beginners. |
| **Wealthfolio** (open source) | Desktop tracker | Private, offline, beautiful portfolio visualization | Minimal screening, local-only | Free (open source) | MEDIUM — shows what privacy-first looks like. No synthesis/recommendations. |
| **Ghostfolio** (open source) | Web tracker | Multi-asset, performance analytics, benchmarking, web-based | No screening, analytics are basic | Free (open source) | MEDIUM — decent portfolio tracking reference. Could integrate with MCP. |
| **Yahoo Finance** (built-in) | Web screener | Free, integrated with yfinance API, accessible | Very basic screeners, limited fundamentals | Free | MEDIUM — baseline. Most MCPs wrap this. Shows why you need more. |

**Key takeaway:** All existing MCPs fall short of consumer tools like Stock Rover on depth and UX. The trade-off is that MCPs integrate with Claude, which enables natural language research. This is genuinely useful IF the MCP has:
1. Enough data depth to support thesis research
2. Ability to annotate and save findings
3. Screening that feels like something a human would use

---

### 4. Open-Source Stock Analysis Projects on GitHub

Several Python projects worth studying for architecture/patterns:

| Repo | Focus | Stars | Language | Maintenance | Relevant For |
|------|-------|-------|----------|-------------|--------------|
| **faizancodes/Automated-Fundamental-Analysis** | Fundamental scoring (100-point rating) | ~100+ | Python | Basic | Shows how to score stocks on fundamentals. Useful pattern. |
| **hjones20/fundamental-analysis** | Intrinsic value calculation, DCF | ~200+ | Python | Minimal | DCF/valuation methods. Good reference for analysis logic. |
| **LastAncientOne/SimpleStockAnalysisPython** | Educational: technical + fundamental | ~300+ | Python | Ongoing | Teaching tool. Shows pattern for multi-analysis approach. |
| **stefmolin/stock-analysis** | Technical analysis package | ~200+ | Python | Dormant | Technical indicators library. Clean abstraction. |
| **jcwill415/Stock_Market_Data_Analysis** | Full pipeline: fetch, analyze, ML | ~50-100 | Python | Working | End-to-end example. Shows how to wire data → analysis. |

**Pattern observed:** Most focus on *calculation* (fundamentals, technicals, ML), not on *organization* (knowledge base, thesis tracking). This is the gap.

---

### 5. Data API Landscape (Free Tier Reality)

Since the MCP will need to fetch data somewhere, here's what's realistically available:

| API | Cost (Free Tier) | Best For | Limitations | Notes |
|-----|-----------------|----------|-------------|-------|
| **yfinance** | Free | Quick prototyping, price/basic data | 5-min delayed quotes, unreliable, not official, limited fundamentals | **Most used by MCPs.** Good for MVP. Not for production. |
| **Alpha Vantage** | 25 calls/day free tier | Technical indicators, options | Severely rate-limited, expensive paid ($50+/mo) | Has official MCP server. Good if indicators are your focus. |
| **Finnhub** | 60 calls/min free | Real-time data, news, company info | Includes crypto (less relevant), limited historical | Most generous free tier. Good balance. |
| **Financial Modeling Prep (FMP)** | Limited free tier | Fundamentals, statements, ratios | Requires API key, free tier is restrictive | Enterprise choice. Excellent data. Worth paying for ($25-49/mo). |
| **EODHD** | Limited free tier | Global stocks, EOD data, fundamentals | Requires subscription for most features | Emerging option. Better than YF for reliability. |
| **IEX Cloud** | Limited free tier | Real-time quotes, historical data | Requires subscription | Professional-grade. High cost. |
| **Yahoo Finance Direct** | Free (unofficial) | All public data | Not supported, unreliable, may break | Fallback option. Don't build on this. |

**Implication:** For a V1 free-tier MCP targeting long-term investors:
- **yfinance** is acceptable for MVP (prices, basic fundamentals)
- **Alpha Vantage** or **Finnhub** for richer data
- **FMP** if you can ask users to provide their own free-tier API key
- Avoid building on yfinance alone if you want credibility

---

### 6. The Knowledge Base Gap

**This is the biggest opportunity.**

None of the existing MCPs meaningfully integrate with a personal investment knowledge base. What exists:

- **MaverickMCP** — Can track portfolio P&L, but no thesis tracking
- **Financial Datasets MCP** — Pure data fetch, no persistence
- **Yahoo Finance variants** — Just return data to Claude; conversation ends
- **Stock Rover, Simply Wall St** — Have note-taking, but *not* integrated with research tools and *not* accessible via MCP

**What's missing:**
1. A way to save and recall your investment thesis for a stock
2. Integration of your personal notes with live data (e.g., "when XYZ hits $50, check my thesis on it")
3. Ability to ask Claude: "Compare how this stock has performed vs. my original thesis"
4. Knowledge base that survives Claude conversations (persistent storage)

**Why this matters for beginners:**
- Beginners benefit most from *documenting* why they own a stock (thesis)
- They need to *revisit* that thesis when data changes
- They need to *learn* from past decisions (which predictions came true?)

**Existing solutions to avoid duplicating:**
- **Wealthfolio, Ghostfolio** — Decent trackers but no thesis layer
- **Notion, Obsidian** — Great for notes but no finance integration

**The build-vs-extend question:** Most existing MCPs can be extended to *talk about* a knowledge base, but none were architected for it. Building custom gives you this from day one.

---

### 7. Security & Trust Assessment

**MCP Security Landscape (March 2026):**

Known vulnerabilities affecting stock MCPs:

1. **Prompt Injection Attacks**
   - Risk: Claude could be tricked into querying sensitive financial data from a malicious source
   - Mitigation: Financial MCPs should validate/sanitize all queries before hitting APIs
   - Status: Most MCPs don't have explicit safeguards; they assume Claude is trustworthy

2. **OAuth/Token Exposure**
   - Risk: API keys (FMP, Finnhub, etc.) stored in configuration could be leaked
   - Reality: Users must provide their own API keys. If compromised, attacker has access.
   - Mitigation: Recommend OAuth2 flow if available; educate users on key rotation
   - Status: Most MCPs use static API key auth

3. **Supply Chain Risk**
   - Risk: A popular MCP dependency (e.g., yfinance) gets compromised
   - Example: CVE-2025-6514 (OAuth metadata injection via MCP clients)
   - Mitigation: Audit dependencies, vendor lock-in is actually safer here
   - Status: Most stock MCPs have minimal dependencies (good)

4. **Data Accuracy/Manipulation**
   - Risk: MCP returns outdated or corrupted financial data
   - Reality: If using yfinance or free APIs, data quality is not guaranteed
   - Mitigation: Use trusted sources (FMP, Finnhub, official exchanges)
   - Status: Varies by MCP

**Trust Scorecard for This Project:**

| Risk | Existing MCPs | Custom MCP | Mitigation |
|------|--------------|-----------|-----------|
| Prompt injection | Medium | Medium | Input validation, audit Claude prompts |
| Token leakage | Medium-High | Medium-High | Recommend OAuth, document key rotation |
| Data accuracy | Medium | Low (with good API selection) | Choose FMP/Finnhub over yfinance |
| Maintenance/abandonment | High (90% of MCPs) | Low (you own it) | Commit to upkeep |
| Compliance/liability | Medium | Medium | Explicit "not investment advice" disclaimer |

**Verdict:** Building custom lets you control security from day one. Existing MCPs range from solid (MaverickMCP, FMP) to risky (abandoned projects, single developers).

---

### 8. Liability and "Not Investment Advice" Problem

**Current landscape:**

- **Stock Rover, Simply Wall St, Morningstar** — All use standard disclaimers ("data is informational only"), buried in ToS
- **Alpaca MCP** — Explicitly designed for *trading*, not recommendations. Clearer intent.
- **AI-powered tools (ChatGPT plugins, Cursor, etc.)** — Use generic disclaimers, often insufficient
- **Existing stock MCPs** — Most have *zero* formal disclaimer in the code or docs

**Why this matters for your MCP:**

If your MCP provides tools like "screen stocks" or "analyze bull case," Claude might output something that *sounds* like a recommendation. A beginner might act on it. If they lose money, liability questions arise:
- Did your MCP implicitly recommend a stock?
- Were disclaimers clear enough?
- Who's liable: you, Anthropic, Claude, the user?

**Best practice (inferred from legal-forward tools):**

1. **Code-level guardrails:**
   - Every stock-related tool returns analysis only, never recommendations
   - Include explicit "this is not financial advice" in all outputs
   - Avoid phrases like "you should buy," "strong buy," etc.

2. **Documentation:**
   - Clear README section: "This tool is for research only. It is not investment advice."
   - Link to disclaimers and terms of use

3. **UX pattern:**
   - Claude should be trained to say: "This is analysis, not a recommendation. Consult a financial advisor before deciding."
   - (MCP can't enforce this directly; relies on system prompt)

**Existing MCPs' approach:** Mostly ignore this. MaverickMCP at least uses neutral language (no recommendations). FMP's API ToS covers them. Yahoo Finance MCPs inherit Yahoo's ToS.

**Your opportunity:** Build this in from day one. Make it a feature, not an afterthought.

---

### 9. Why Build vs. Extend?

**Reasons to EXTEND an existing MCP:**

- **MaverickMCP:** Most feature-complete, actively maintained, good code quality
  - Pros: Portfolio tracking, backtests, 29 tools, S&P 500 pre-seeded
  - Cons: Already does most of what you'd add; hard to add knowledge base without major refactor; depends on author's vision

- **Financial Modeling Prep MCP:** Deepest fundamental data
  - Pros: Enterprise-grade API, 253+ tools, clear separation of concerns
  - Cons: Requires paid API key; UI is just tools, no synthesis; no portfolio tracking

- **Yahoo Finance MCPs (various):** Easiest to extend
  - Pros: Many implementations, simple code, free data
  - Cons: Shallow feature set, varying quality, no standardization

**Reasons to BUILD custom:**

- **Knowledge base integration** — No existing MCP designed for this. Adding it would require invasive changes.
- **Beginner-focused thesis research** — Existing MCPs are either generic (data fetch) or trader-focused (technical indicators).
- **Custom screening logic** — You want to implement unique filters based on beginner frameworks (dividend yield, ROE, free cash flow stability). Existing MCPs have shallow screening.
- **Control/ownership** — Solo developer, this is for real use. You want to know every line of code.
- **Liability management** — Build disclaimers and safeguards in from day one, not bolted on.
- **Data source flexibility** — Choose your API (yfinance for MVP, FMP if you upgrade). Not locked to MCP author's choices.

**Recommendation:** **BUILD custom with architecture that can *optionally consume* existing tools** (e.g., via HTTP calls to MaverickMCP if user runs it). Don't fork or heavily extend. You'll ship faster and cleaner.

---

### 10. What No Tool Does Well (The Real Gaps)

Based on research, here's what's *actually missing* from the market:

**For long-term beginner investors:**

1. **"Thesis Research + Tracker" integration**
   - Screeners find candidates (✓ many tools do this)
   - You research and write thesis (✓ Notion, Google Docs, etc. do this)
   - **Missing:** Integrated workspace where you can research *and* track the thesis over time
   - Example gap: "Show me all stocks in my watchlist where my thesis assumption (e.g., 'revenue growth >10%') is violated"

2. **Framework-specific screening**
   - Tools offer 50-650 filters, but no guidance on which matter for *your* investing style
   - **Missing:** Pre-built filters for beginner frameworks (value investing, dividend investing, growth investing)
   - Example gap: A "beginner value investor" filter that pre-selects for P/E, debt-to-equity, free cash flow stability, but ignores technical indicators

3. **Conviction tracking**
   - You buy a stock. You think it'll do X. Did it?
   - **Missing:** A way to ask Claude "Here's my original thesis from Jan 2024. Compare it to Q4 2025 fundamentals. How much has changed?"
   - Example gap: "I bought MSFT thinking cloud growth would drive earnings. Did it? Check my thesis."

4. **Beginner-safe output**
   - Advanced traders want technical indicators and backtests (MaverickMCP does this)
   - **Missing:** Tools that give *beginners* just enough data to make a decision, without overwhelming them
   - Example gap: A "one-page research summary" tool that condensed a company into 5-7 key metrics, with context on what they mean

5. **Educational integration**
   - Beginners don't know *how* to analyze a stock
   - **Missing:** Tools that teach as they go
   - Example gap: When Claude calls the "P/E ratio" tool, it returns not just the number, but what it means, what's typical for the industry, and what it implies

**Which of these can the MCP address directly?** 1, 2, 4, 5 — maybe partially with good prompting. (3 requires persistent storage, which is separate.)

---

## Sources

### MCP Servers & Registries
- [MaverickMCP - GitHub](https://github.com/wshobson/maverick-mcp)
- [Financial Modeling Prep MCP Server - GitHub](https://github.com/imbenrabi/Financial-Modeling-Prep-MCP-Server)
- [Yahoo Finance MCP (Alex2Yang97) - GitHub](https://github.com/Alex2Yang97/yahoo-finance-mcp)
- [Financial Datasets MCP Server - GitHub](https://github.com/financial-datasets/mcp-server)
- [Alpaca MCP Server - GitHub](https://github.com/alpacahq/alpaca-mcp-server)
- [InvestMCP - GitHub](https://github.com/arrpitk/InvestMCP)
- [Stockflow/Stockscreen MCP - GitHub](https://github.com/twolven/mcp-stockflow)
- [PulseMCP Registry](https://www.pulsemcp.com/)
- [LobeHub MCP Directory](https://lobehub.com/mcp)
- [Awesome MCP Servers](https://mcpservers.org/)

### Competitive Analysis
- [Stock Rover vs Finviz - Liberated Stock Trader](https://www.liberatedstocktrader.com/stock-rover-vs-finviz/)
- [Stock Rover Review - Liberated Stock Trader](https://www.liberatedstocktrader.com/stock-rover-review-screener-value-investors/)
- [Best Stock Screeners 2025 - Liberated Stock Trader](https://www.liberatedstocktrader.com/best-stock-screeners/)
- [Simply Wall St](https://simplywall.st/)
- [Best Stock Screeners 2026 - Gainify](https://www.gainify.io/blog/best-stock-screeners)

### Data APIs
- [Alpha Vantage API](https://www.alphavantage.co/)
- [Alpha Vantage API Documentation](https://www.alphavantage.co/documentation/)
- [Alpha Vantage MCP Server](https://mcp.alphavantage.co/)
- [Financial Data APIs Compared 2026 - KSRed](https://www.ksred.com/the-complete-guide-to-financial-data-apis-building-your-own-stock-market-data-pipeline-in-2025/)
- [Best Stock Data APIs 2026 - Medium](https://medium.com/coinmonks/the-7-best-real-time-stock-data-apis-for-investors-and-developers-in-2026-in-depth-analysis-61614dc9bf6c/)
- [FMP MCP Server Documentation](https://site.financialmodelingprep.com/developer/docs/mcp-server)
- [Best Free Finance APIs 2025](https://noteapiconnector.com/best-free-finance-apis)

### Open-Source Projects
- [Automated Fundamental Analysis - GitHub](https://github.com/faizancodes/Automated-Fundamental-Analysis)
- [Fundamental Analysis Repository - GitHub](https://github.com/hjones20/fundamental-analysis)
- [SimpleStockAnalysisPython - GitHub](https://github.com/LastAncientOne/SimpleStockAnalysisPython)
- [Stock Analysis Package - GitHub](https://github.com/stefmolin/stock-analysis)
- [Stock Market Data Analysis - GitHub](https://github.com/jcwill415/Stock_Market_Data_Analysis)

### Open-Source Portfolio Tools
- [Wealthfolio](https://wealthfolio.app/)
- [Ghostfolio - GitHub](https://github.com/ghostfolio/ghostfolio)
- [Portfolio Performance](https://www.portfolio-performance.info/en/)
- [Open Source Portfolio Analysis - Privacy Guides](https://www.privacytools.io/guides/open-source-portfolio-manager-privacy)

### MCP Security
- [MCP Security Vulnerabilities 2026 - Practical DevSecOps](https://www.practical-devsecops.com/mcp-security-vulnerabilities/)
- [MCP Vulnerabilities - Composio](https://composio.dev/content/mcp-vulnerabilities-every-developer-should-know)
- [State of MCP Security 2025 - Data Science Dojo](https://datasciencedojo.com/blog/mcp-security-risks-and-challenges/)
- [MCP Security - Adversa AI](https://adversa.ai/mcp-security-top-25-mcp-vulnerabilities/)
- [State of MCP Security 2025 Report - Astrix](https://astrix.security/learn/blog/state-of-mcp-server-security-2025/)

### Reference Articles
- [How to Build an MCP Stock Analysis Server - Seth Hobson](https://sethhobson.com/2025/08/how-to-build-an-mcp-stock-analysis-server/)
- [Best MCP Servers for Stock Market Data - Medium](https://medium.com/data-science-collective/best-mcp-servers-for-stock-market-data-and-algorithmic-trading-ca51e89cd0a1/)
- [AI Trading Copilot: MCP Servers 2025](https://blog.pickmytrade.trade/ai-trading-copilot-mcp-servers-stock-analysis-2025/)
- [Beginner's Guide to Stock Investing - AAII](https://www.aaii.com/education/article/14310-beginners-guide-to-stock-investing/16503-what-is-a-stock-screener)

---

## Confidence Levels

### High Confidence (Primary research, multiple sources)
- **At least 10-15 finance MCPs exist** — Verified across GitHub, PulseMCP, LobeHub, Smithery
- **MaverickMCP is well-maintained and feature-rich** — GitHub activity, recent commits, positive mentions
- **Stock Rover/Simply Wall St dominate retail screener market** — Multiple sources, consistent rankings
- **Yahoo Finance MCPs are most common design pattern** — At least 4 independent implementations found
- **No MCP meaningfully integrates a knowledge base** — Searched all major projects, none have thesis tracking

### Medium Confidence (Multiple sources but incomplete detail)
- **Exact star counts and maintenance status** — GitHub doesn't expose this in search results; estimates based on mentions
- **Security vulnerabilities affecting financial MCPs specifically** — General MCP security is well-documented, but financial-specific vectors are inference-based
- **FMP MCP reliability and adoption** — Fewer public mentions than others, but official backing suggests quality
- **Liability/disclaimer standards for MCPs** — Not yet standardized; inference from existing tools (Stock Rover, Alpaca)

### Low Confidence (Gaps in research)
- **Which specific MCP has the largest user base** — No public metrics available
- **Performance benchmarks (speed, accuracy) between MCPs** — Not systematically tested in available sources
- **Long-term maintenance prospects for single-developer MCPs** — Impossible to predict; depends on author motivation
- **Exact API rate limits and cost-of-scale** — Documented in each API's docs, but not aggregated

---

## Open Questions

1. **What's the licensing situation for each MCP?** Most on GitHub use MIT or Apache 2.0, but not all confirm. Should verify before extending.

2. **Do any existing MCPs have formal security audits?** MaverickMCP and FMP likely, but no public security reports found.

3. **How do existing MCPs handle timezone and market hours?** Not mentioned in any documentation. Important for real-world use.

4. **Are there legal frameworks for MCP liability?** The "not investment advice" problem is unresolved. No case law yet (MCP is new).

5. **What's the actual data latency for yfinance vs. FMP vs. Finnhub?** Documented in docs, but not tested end-to-end in an MCP context.

6. **How many users actually use each MCP in production?** No metrics available. GitHub stars are a poor proxy.

7. **Are there any MCPs focused specifically on ESG, dividend growth, or other beginner-friendly filters?** Not found in this research. Potential niche.

8. **How does Claude's own knowledge cutoff (Feb 2025) interact with MCPs providing live data?** Claude should defer to MCP tools, but not all system prompts encourage this.

---

## Summary & Recommendation

**The landscape is crowded but fragmented.** 10+ MCPs exist, but none dominate. Most are competent data-fetch tools. None are built around the thesis-research workflow beginners need.

**Best existing option to extend:** MaverickMCP (if you want portfolio tracking + indicators) or Financial Modeling Prep MCP (if you want deepest data).

**Recommendation:** **BUILD custom.** Reasons:
- Knowledge base integration is your unique angle (no existing MCP does this)
- Beginner-focused thesis research is a niche none currently serve well
- You control security/liability from day one
- You'll ship faster by starting clean than untangling existing projects
- You can optionally *integrate* with existing MCPs (e.g., call MaverickMCP for technical analysis) without forking

**V1 approach:** Start with yfinance (free, simple), pre-built thesis framework (3-5 filters for value investing), and a lightweight local knowledge base. Then optionally integrate FMP API and more advanced screening as V2.

**Critical path for the decision:**
1. **Week 1:** Verify MaverickMCP's codebase is worth extending (read `server.py`, check test coverage, review issues)
2. **If yes:** Fork it, add knowledge base layer, build around that
3. **If no:** Build custom. Aim for 20-30 tools that matter to long-term investors, not 253 generic ones

