# Stock MCP Domain Research: Free Financial Data APIs & Investment Analysis

**Research Date:** 2026-03-21
**Scope:** Free financial data APIs, Python libraries, fundamental analysis metrics, and investment frameworks for beginner long-term investors.

---

## Key Findings

1. **yfinance is the safest choice for basic stock data** — 3-4x faster than pandas-datareader, actively maintained, simple API, but Yahoo Finance API breaks unpredictably. Pair with Finnhub (60 calls/min free) or Financial Modeling Prep (250 calls/day free) for fundamentals to reduce single-point-of-failure risk.

2. **Finnhub offers the best free fundamentals API** — 60 API calls/minute on free tier with real-time US quotes, company news, and basic fundamentals. Generous compared to Alpha Vantage (25 calls/day) and simpler than FMP integration, though limited to US stocks on free tier.

3. **Financial Modeling Prep (FMP) provides SEC-linked fundamentals** — 250 requests/day free, 500MB/30-day bandwidth limit. Covers financial statements, ratios, and company data without needing to parse SEC filings yourself. Better for structured fundamental analysis than raw EDGAR.

4. **SEC EDGAR has zero-cost official APIs with no rate limits** — EdgarTools (Python library) and SEC's data.sec.gov REST APIs are completely free with no authentication. However, parsing raw XBRL is complex; use EdgarTools or FMP for pre-parsed statements.

5. **OpenBB is emerging as the unified data layer** — Single interface to yfinance, FMP, Intrinio, Tiingo, and others. Reduces vendor lock-in and allows data validation across sources. GitHub's most popular open-source finance project. Consider for v2 when standardizing multi-source data.

6. **Alpha Vantage is too limited for v1** — Only 25 API calls per day on free tier. Reliable but constraining for a tool that might screen multiple stocks. Better as a backup than primary source.

7. **Twelve Data is viable but paid-focused** — Free tier: 8 calls/min, 800 calls/day. Covers 100k+ instruments but real value is in paid tiers ($29–$329/month). Less generous than Finnhub for free users.

8. **P/E ratio, ROE, and debt/equity ratio are the starter trio for beginner fundamental analysis** — These three metrics capture valuation, profitability, and financial health with minimal complexity. Dividend yield matters only if building dividend-focused screening. EPS growth rate matters more than absolute dividend yield for long-term investors.

9. **Value investing frameworks (Buffett-style) are most beginner-friendly** — "Understand what you own, invest in quality at fair prices, hold long-term" is actionable and requires fundamentals: intrinsic value (DCF or multiples), competitive moat indicators (ROE 15%+ consistently), and management capital allocation (debt levels, buyback vs dividend patterns).

10. **"Not financial advice" disclaimers alone provide zero legal protection** — Substance matters more than labels. Disclaimers help only when information is free and you're not in a quasi-advisory relationship. For an MCP tool, structure as "educational analysis tools, not investment recommendations" and avoid actionable language like "you should buy/sell."

11. **IEX Cloud (previously popular MCP source) shut down in August 2024** — This is a critical gotcha: Popular API providers can disappear overnight. This argues for building MCP to support multiple data sources, not a single vendor.

12. **yfinance + Finnhub combination covers 80% of beginner needs** — yfinance for price/OHLCV data, Finnhub for fundamentals (P/E, ROE, etc.) and news. Combined: free, reliable, 60+ calls/min, and covers essential long-term investing metrics. Only gaps are detailed SEC filing data (use EdgarTools if needed) and international stocks (Finnhub requires paid tier).

---

## Details

### Free Financial Data APIs: Feature Matrix & Rate Limits

#### **yfinance (Unofficial Yahoo Finance)**
- **Data Available:** OHLCV, market cap, P/E, dividend yield, beta, 52-week high/low, options data
- **Rate Limits:** No official rate limit, but Yahoo blocks aggressively. Roughly 1-2 calls/sec before hitting 429 errors
- **Cost:** Free
- **Gotchas:**
  - Breaks unpredictably when Yahoo changes their structure
  - Silent failures (returns empty DataFrames for invalid tickers or date ranges outside trading history)
  - Not suitable for high-frequency screeners without caching/retry logic
- **Best For:** Simple price data, backtesting, portfolio tracking
- **Python Library:** `yfinance` (pip install yfinance)
- **Reliability:** Medium (depends on Yahoo's cooperation)

**Source:** [yfinance vs pandas-datareader: Python Stock Data in 2026](https://tildalice.io/stock-price-analysis-python-yfinance/) | [Yahoo Finance API: Free Guide + Python Code Examples](https://marketxls.com/blog/yahoo-finance-api-the-ultimate-guide-for-2024/)

---

#### **Finnhub API (Free Tier)**
- **Data Available:** Real-time US stock quotes, company fundamentals (P/E, ROE, dividend yield, earnings, revenue), company news, SEC filings, WebSocket streaming
- **Rate Limits:** 60 API calls/minute (generous free tier)
- **Cost:** Free; Premium tiers start at $11.99/month
- **Coverage:** US equities only on free tier; international requires paid plan
- **Gotchas:**
  - Free tier limited to US stocks (LSE, TSX, etc. require Premium)
  - WebSocket limited to 50 symbols on free plan
  - One year of historical data per API call on free tier
- **Best For:** Fundamental analysis, real-time US stock screening, news aggregation
- **Python Library:** Official `finnhub-python` (pip install finnhub-client)
- **Reliability:** High (enterprise-grade infrastructure)

**Source:** [API Documentation | Finnhub](https://finnhub.io/docs/api/rate-limit) | [Exploring the finnhub.io API](https://www.interactivebrokers.com/campus/ibkr-quant-news/exploring-the-finnhub-io-api/)

---

#### **Financial Modeling Prep (FMP) Free Tier**
- **Data Available:** Income statements, balance sheets, cash flow statements, financial ratios, company profile, earnings calendar, sector/industry performance
- **Rate Limits:** 250 API requests per day; 500MB bandwidth per 30 days
- **Cost:** Free; paid plans $15–$249/month
- **Gotchas:**
  - 250 calls/day is tight if screening large portfolios daily
  - Bandwidth cap means high-volume data pulls (> 500MB/month) hit a wall
  - Free tier covers US only (international requires paid upgrade)
- **Best For:** Structured fundamental analysis, financial statement parsing, screening by financial ratios
- **Python Library:** Community libraries like `fmp-api` or direct REST calls
- **Reliability:** High (used by professional analysts)

**Source:** [Financial Modeling Prep | Free Tier Documentation](https://site.financialmodelingprep.com/developer/docs) | [FMP Pricing & Free Tier](https://site.financialmodelingprep.com/pricing-plans)

---

#### **Alpha Vantage Free Tier**
- **Data Available:** OHLCV data, technical indicators (SMA, EMA, RSI, MACD, Bollinger Bands, etc.), 50+ indicators, 20+ years historical data
- **Rate Limits:** 25 API calls per day; 5 calls per minute
- **Cost:** Free; Premium $20/month
- **Gotchas:**
  - Severely rate-limited for building screening tools
  - No fundamentals (P/E, ROE, etc.) — only price and technical indicators
  - Day limit resets daily, not per-minute, so limited use
- **Best For:** Learning technical analysis, small backtesting projects
- **Reliability:** Medium (slow API response times reported)

**Source:** [Alpha Vantage API: The Complete 2026 Guide](https://alphalog.ai/blog/alphavantage-api-complete-guide) | [AlphaVantage API Documentation](https://www.alphavantage.co/documentation/)

---

#### **SEC EDGAR (Official U.S. Securities & Exchange Commission)**
- **Data Available:** All SEC filings (10-K, 10-Q, 8-K, etc.), XBRL-formatted financial statements, raw filing documents
- **Rate Limits:** No official rate limit; SEC asks for User-Agent headers (company name + email)
- **Cost:** Free and provided by U.S. government
- **Gotchas:**
  - XBRL parsing is complex; requires domain knowledge or a library
  - Data is structured but not easily consumable without preprocessing
  - Latency: filings appear after market close on filing day
- **Best For:** Official financial statements, 10-K/10-Q research, audit trail
- **Python Library:** `EdgarTools` (open source, no rate limits, parses XBRL into Python objects)
- **Reliability:** Very High (official government source)

**Source:** [SEC EDGAR Application Programming Interfaces](https://www.sec.gov/search-filings/edgar-application-programming-interfaces) | [EdgarTools: Python Library for SEC Data Analysis](https://edgartools.readthedocs.io/) | [GitHub: EdgarTools](https://github.com/dgunning/edgartools)

---

#### **Twelve Data Free Tier**
- **Data Available:** Stock prices, forex, crypto, ETFs, fundamentals, technical indicators
- **Rate Limits:** 8 API calls/minute; 800 calls/day
- **Cost:** Free; Premium starts at $29/month
- **Coverage:** 100,000+ instruments globally
- **Gotchas:**
  - 800 calls/day is moderate for screening large portfolios
  - Fundamentals may require paid tier for full depth
- **Best For:** Diversified data access (stocks, forex, crypto) at low cost
- **Python Library:** Official `twelvedata-python` (pip install twelvedata)
- **Reliability:** Medium-High (newer, less battle-tested than Finnhub/FMP)

**Source:** [Twelve Data Pricing & Documentation](https://twelvedata.com/docs) | [Twelve Data Free API Overview](https://twelvedata.com/pricing)

---

### Python Libraries for Financial Data

#### **yfinance**
- **Pros:** Simple API, fast, OHLCV + fundamentals, actively maintained (as of Jan 2026), handles batch requests efficiently
- **Cons:** Yahoo Finance breaks unpredictably, silent failures on bad input, no error handling for invalid tickers
- **Speed:** 3-4x faster than pandas-datareader
- **When to Use:** Primary source for price data, portfolio tracking, quick lookups

**Source:** [yfinance vs pandas-datareader Comparison](https://tildalice.io/stock-price-analysis-python-yfinance/) | [Python for Algorithmic Trading Cookbook](https://subscription.packtpub.com/book/data/9781835084700/1/ch01lvl1sec03/)

---

#### **pandas-datareader**
- **Pros:** Historical integration with Pandas DataFrames, supports FRED (Federal Reserve) and World Bank data
- **Cons:** 3-4x slower than yfinance, less actively maintained (last commit 6+ months ago), deprecated Yahoo Finance backend
- **When to Use:** Only if you need FRED or World Bank data; otherwise, use yfinance

**Source:** [Comparing pandas-datareader with yfinance](https://www.slingacademy.com/article/comparing-pandas-datareader-with-yfinance-for-stock-data-retrieval/)

---

#### **OpenBB SDK**
- **Pros:** Single interface to multiple data providers (yfinance, FMP, Intrinio, Tiingo, Polygon). Data validation across sources. Most popular open-source finance GitHub project. Future-proofs against single-vendor failure.
- **Cons:** Higher abstraction layer (slower for simple queries), steeper learning curve, newer ecosystem (less StackOverflow support)
- **Recommendation:** Use for v2+ when building multi-source architecture and standardizing fundamentals across providers.

**Source:** [Getting Started with OpenBB SDK](https://autonomousecon.substack.com/p/this-little-known-python-package) | [OpenBB GitHub](https://github.com/OpenBB-finance/OpenBB) | [OpenBB for Financial Analysis: A Complete Guide](https://dasroot.net/posts/2026/02/openbb-financial-analysis-python-data-retrieval/)

---

#### **EdgarTools**
- **Pros:** Parse SEC filings (10-K, 10-Q, 8-K) into structured Python objects. Zero cost, no API key, no rate limits. Highly Pythonic.
- **Cons:** Only useful if you need SEC filing data; steep learning curve for financial statement parsing
- **When to Use:** When you need official financial statements or want to validate FMP/Finnhub fundamentals against SEC filings

**Source:** [EdgarTools: Python Library for SEC Data](https://edgartools.readthedocs.io/) | [GitHub: EdgarTools](https://github.com/dgunning/edgartools)

---

### Recommended Tech Stack for v1 MCP

**Primary Stack:**
- **Price/OHLCV:** yfinance (free, simple, fast)
- **Fundamentals & News:** Finnhub (60 calls/min free tier, covers P/E, ROE, dividend yield, earnings, news)
- **Fallback for Fundamentals:** Financial Modeling Prep (250 calls/day, if Finnhub rate-limited)
- **SEC Filings:** EdgarTools (free, no limits, for detailed research)

**Why This Works:**
- Covers beginner needs: stock prices, key ratios (P/E, ROE, D/E, dividend yield), company news, and SEC filings
- All free
- 60+ API calls/min combined capacity is sufficient for screening 10–100 stocks daily
- Single-vendor failure risk mitigated (yfinance backup to Finnhub, FMP backup for fundamentals)

**v2 Upgrade Path:**
- Add OpenBB SDK as data aggregation layer
- Expand to international stocks (Finnhub Premium or Alpha Vantage)
- Add technical analysis if needed (Alpha Vantage or Twelve Data)

---

### Fundamental Analysis Metrics for Beginner Long-Term Investors

#### **Essential Metrics (The Starter Trio)**

**1. P/E Ratio (Price-to-Earnings)**
- **Formula:** Stock Price / Earnings Per Share (EPS)
- **What It Means:** How many dollars investors pay for each dollar of company earnings
- **Example:** Stock at $50/share with $5 EPS = P/E of 10
- **Interpretation:**
  - Low P/E (5–10): Potentially undervalued or low-growth company
  - Moderate P/E (15–25): Fair valuation for stable companies
  - High P/E (>25): High growth expectations or overvalued
- **Gotcha:** P/E alone doesn't tell if a company is actually cheap; compare to industry peers and company growth rate
- **Beginner Action:** Compare a stock's P/E to its historical average and industry median to spot outliers

**Source:** [Five Key Financial Ratios for Stock Analysis](https://www.schwab.com/learn/story/five-key-financial-ratios-stock-analysis) | [Understanding the P/E Ratio](https://www.abacademies.org/articles/understanding-the-pricetoearnings-ratio-a-key-metric-for-stock-valuation-17257.html)

---

**2. Return on Equity (ROE)**
- **Formula:** Net Income / Shareholders' Equity (expressed as %)
- **What It Means:** How efficiently a company generates profit from shareholders' capital
- **Example:** Net income $100M on $1B equity = 10% ROE
- **Interpretation:**
  - ROE > 15% consistently: Excellent capital efficiency (Buffett looks for this)
  - ROE 10–15%: Healthy
  - ROE < 10%: Weak returns on equity; company may struggle to grow
- **Gotcha:** High ROE can be artificially inflated by excessive debt (which reduces equity). Always check debt/equity ratio alongside ROE.
- **Beginner Action:** Look for companies with ROE consistently above 15% for the past 5 years; avoid one-time spikes

**Source:** [Return on Equity: Definition, Calculation & Examples](https://www.bill.com/learning/return-on-equity) | [Return on Equity (ROE) Ratio Explained](https://www.bajajamc.com/knowledge-centre/return-on-equity-ratio)

---

**3. Debt-to-Equity Ratio (D/E)**
- **Formula:** Total Debt / Total Shareholders' Equity
- **What It Means:** How much debt a company uses relative to shareholder capital; a leverage metric
- **Example:** $500M debt on $1B equity = D/E of 0.5
- **Interpretation:**
  - D/E < 1.0: Conservative, lower financial risk
  - D/E 1.0–2.0: Moderate leverage; acceptable for stable cash-flow businesses
  - D/E > 2.0: High debt; risky if cash flow dips
- **Gotcha:** Different industries have different norms (utilities can handle higher D/E than tech); always compare to peers
- **Beginner Action:** Avoid companies with D/E > 2.0 unless they have very predictable cash flows (utilities, telecom)

**Source:** [Five Key Financial Ratios for Stock Analysis](https://www.schwab.com/learn/story/five-key-financial-ratios-stock-analysis)

---

#### **Secondary Metrics (Use If Screening by Style)**

**4. Dividend Yield**
- **Formula:** Annual Dividend Per Share / Stock Price
- **Example:** $2 annual dividend on $100 stock = 2% yield
- **When It Matters:** For dividend growth investing or income-focused portfolios
- **Gotcha:** High yield can signal distress (stock fell, making old dividend unsustainably high); always check dividend history
- **Beginner Action:** For income portfolios, look for dividend aristocrats (25+ consecutive years of increases)

**Source:** [Top 8 Fundamental Indicators for Stock Analysis in 2025](https://www.equentis.com/blog/8-fundamental-indicators-for-stocks-in-2025/)

---

**5. Revenue Growth Rate & EPS Growth Rate**
- **What It Means:** Year-over-year (YoY) growth in sales and earnings
- **Interpretation:**
  - Revenue growth > 10% YoY: Strong demand
  - EPS growth > Revenue growth: Improving margins (profitable)
  - Negative or declining growth: Red flag unless in cyclical downturn
- **Beginner Action:** Look for companies with consistent 10%+ EPS growth over 3–5 years

**Source:** [Top 8 Fundamental Indicators for Stock Analysis in 2025](https://www.equentis.com/blog/8-fundamental-indicators-for-stocks-in-2025/)

---

**6. Price-to-Book Ratio (P/B)**
- **Formula:** Stock Price / Book Value Per Share
- **Interpretation:**
  - P/B < 1.0: Trading below net asset value; potentially undervalued
  - P/B > 1.0: Trading above assets; investors expect growth
  - P/B 1.0–3.0: Normal range for healthy companies
- **When It Matters:** For value investing and capital-intensive businesses (manufacturing, banks)
- **Gotcha:** Low P/B doesn't guarantee value if company is in structural decline

**Source:** [How to Value Company Stocks: P/E, PEG, and P/B Ratios](https://www.schwab.com/learn/story/how-to-value-company-stocks-pe-peg-and-pb-ratios)

---

#### **Metrics NOT Recommended for Beginners**
- **PEG Ratio (P/E to Growth):** Useful for comparing growth vs. value, but too abstract for beginners
- **Free Cash Flow (FCF):** Gold standard for valuation, but requires 10-Q/10-K parsing; skip until v2
- **ROIC (Return on Invested Capital):** Advanced metric; stick with ROE first
- **Enterprise Value:** Too complex; focus on P/E first

---

### Investment Frameworks for Beginner Long-Term Investors

#### **Value Investing (Buffett-Style)**

**Core Principles:**
1. **Understand What You Own:** Only invest in companies whose business you can explain simply. "Circle of Competence" — Buffett famously avoided tech for decades not because tech was bad, but because he couldn't predict winners.
2. **Intrinsic Value + Margin of Safety:** Calculate a fair value for the company based on assets, earnings, and future cash flow. Buy only if market price is significantly below that value (margin of safety).
3. **Quality Over Price:** "It's far better to buy a wonderful company at a fair price than a fair company at a wonderful price." Quality companies have:
   - Durable competitive advantages (moats): brand loyalty, switching costs, network effects
   - Honest, capable management
   - Predictable, growing earnings (ROE > 15% consistently)
4. **Long-Term Holding:** "If you aren't willing to hold a stock for ten years, don't own it for ten minutes." This mindset filters out noise and lets compounding work.
5. **Patience and Discipline:** Wait for prices to fall below intrinsic value, then act decisively. Avoid FOMO.

**Actionable Metrics to Screen By:**
- P/E < industry average (cheaper than peers, not absolute)
- ROE > 15% for past 5 years (consistent profitability)
- D/E < 1.0 (financial strength)
- Management's capital allocation: Do they reinvest in business, buy back stock, or over-leverage? (Check 10-K)
- Earnings consistency: Revenue and EPS growth within ±5% of long-term average (predictable)

**When to Use:** Best for stable, profitable companies (Apple, Berkshire Hathaway, Johnson & Johnson). Worst for high-growth startups or unprofitable tech.

**Source:** [Warren Buffett's Investment Strategy](https://www.investing.com/academy/trading/warren-buffett-investment-strategy-rules-fortune/) | [Mastering Warren Buffett's Investing Principles](https://www.heygotrade.com/en/blog/warren-buffetts-investing-principles) | [Warren Buffett's 7 Value Investing Guidelines](https://www.cabotwealth.com/daily/value-stocks/warren-buffett-value-investing-guidelines)

---

#### **Dividend Growth Investing**

**Core Idea:** Invest in companies that increase dividends every year, creating a compounding income stream.

**Actionable Metrics:**
- **Dividend Aristocrats:** Companies with 25+ consecutive years of dividend increases (e.g., Procter & Gamble, 3M)
- **Dividend Yield:** 2–4% is sweet spot; >4% may signal distress
- **Payout Ratio:** (Dividends Paid / Net Income). Below 60% is sustainable; above 75% is risky
- **Dividend Growth Rate:** Historical 5-10% annual increases indicate healthy companies

**When to Use:** For retirement portfolios or investors prioritizing steady income over capital appreciation. Less suitable for growth investors or those early in their careers.

**Tools:** ETFs like ProShares S&P 500 Dividend Aristocrats (NOBL) simplify this strategy.

**Source:** [Dividend Growth Investor](https://www.dividendgrowthinvestor.com/) | [8 Powerful Dividend Investing Strategies for 2025](https://finzer.io/en/blog/dividend-investing-strategies) | [How to Develop a Dividend Investing Strategy](https://www.vaneck.com/us/en/blogs/income-investing/how-to-develop-a-dividend-investing-strategy-a-comprehensive-guide/)

---

#### **Growth Investing (Brief Overview)**

**Core Idea:** Buy companies growing earnings/revenue faster than the market, accept higher valuations.

**When to Use:** For younger investors with higher risk tolerance and longer time horizon. Requires ability to identify which high-growth companies will survive and maintain growth (hard).

**Warning for Beginners:** Most beginners can't consistently pick growth winners. Start with Value Investing, add dividend stocks, then try growth if confident.

---

### Liability & Disclaimer Strategy for AI Financial Analysis Tools

#### **Core Legal Principle**
"Not financial advice" disclaimers provide **zero protection if the substance of your tool constitutes actionable investment guidance.** Courts and regulators evaluate what you actually do, not what you say you do.

**Key Cases & Rules:**
- **Investment Advisers Act (IAA):** If you offer "advice" about securities in exchange for compensation, the IAA applies. No disclaimer exception exists for "not financial advice."
- **Rule of Substance Over Form:** Courts look at whether a reasonable person would rely on your guidance to make investment decisions, not your disclaimer language.
- **Quasi-Advisory Relationships:** If your tool creates a relationship where users believe they're receiving personalized financial guidance, disclaimers won't shield you.

**Source:** [Are You Illegally Giving Financial Advice?](https://www.givnerlawpc.com/fintwit-law/are-you-illegally-giving-financial-advice/) | [Financial Disclaimers - Free Privacy Policy](https://www.freeprivacypolicy.com/blog/financial-disclaimers/)

---

#### **Recommended Disclaimer Structure for Free AI Stock Analysis MCP**

**What You MUST Do:**
1. **Prominent Placement:** Disclaimer must appear at the top of every analysis output, not buried in fine print
2. **Clear Language:** Use plain English, not legal jargon that users will ignore
3. **Narrow Scope:** Explicitly state what your tool does and does NOT do
4. **Avoid Actionable Language:** Never say "you should buy X" or "avoid Y"; say "X has a high P/E ratio relative to peers" (factual, not prescriptive)
5. **Disclose Data Sources:** State which APIs/data sources you use so users can verify independently

**Template for MCP Tool:**

```
⚠️  EDUCATIONAL ANALYSIS TOOL — NOT INVESTMENT ADVICE

This tool provides factual financial data and metrics for educational purposes only.
It is NOT:
- Investment advice or a recommendation to buy/sell
- Personalized financial guidance
- A substitute for professional financial advice
- Guaranteed to be accurate or complete (always verify data independently)

What this tool DOES:
- Display public financial metrics (P/E, ROE, dividends, etc.) from [list your data sources]
- Compare metrics to industry peers
- Highlight patterns in historical data
- Provide educational frameworks (Value Investing 101, etc.)

ALWAYS:
- Do your own research; never rely on this tool alone
- Consult a licensed financial advisor before making investment decisions
- Verify data against official sources (SEC EDGAR, company websites)
- Consider your personal risk tolerance, time horizon, and financial situation

This tool is provided as-is with no warranty. The creators assume no liability for losses or damages from its use.
```

---

#### **Implementation Dos & Don'ts**

**DO:**
- Present data neutrally ("Stock X has P/E of 25" vs. "Stock X is expensive")
- Provide multiple perspectives ("Growth investors might view this high P/E as justified; value investors might avoid it")
- Cite sources explicitly ("Data from Finnhub as of [date]")
- Build in "data freshness" warnings ("This data is 15 minutes delayed")
- Allow users to export raw data for independent verification

**DON'T:**
- Use language like "I recommend," "You should buy," "This is a steal"
- Create a relationship where users feel you're their personal advisor
- Hide disclaimers or make them opt-in (users must see them without clicking)
- Make promises about returns or risk mitigation
- Allow the tool to run in "autonomous" mode where it suggests trades without user confirmation

---

#### **Safe Disclaimer Examples**

✅ **Good:** "Berkshire Hathaway has a P/E of 28 vs. S&P 500 average of 22. [Data source: Finnhub, 2026-03-21]"

✅ **Good:** "This company's ROE has declined 5% YoY. Possible concerns: [list factors]. More research needed."

❌ **Avoid:** "Berkshire Hathaway is undervalued—buy now!"

❌ **Avoid:** "I analyzed your portfolio and recommend selling XYZ stock."

❌ **Avoid:** Relying on tiny print disclaimers; if you can't say it prominently, don't say it.

---

## Sources

### APIs & Libraries
- [yfinance vs pandas-datareader: Python Stock Data in 2026](https://tildalice.io/stock-price-analysis-python-yfinance/)
- [Comparing pandas-datareader with yfinance for Stock Data Retrieval](https://www.slingacademy.com/article/comparing-pandas-datareader-with-yfinance-for-stock-data-retrieval/)
- [Financial Data APIs Compared: Polygon vs IEX Cloud vs Alpha Vantage (2026)](https://www.ksred.com/the-complete-guide-to-financial-data-apis-building-your-own-stock-market-data-pipeline-in-2025/)
- [Best Free Finance APIs (2025)](https://noteapiconnector.com/best-free-finance-apis)
- [Alpha Vantage API: The Complete 2026 Guide for Investors & Developers](https://alphalog.ai/blog/alphavantage-api-complete-guide)
- [Yahoo Finance API: Free Guide + Python Code Examples (2025)](https://marketxls.com/blog/yahoo-finance-api-the-ultimate-guide-for-2024/)
- [Real-Time Financial Data with Alpha Vantage & Yahoo Finance](https://www.pyquantnews.com/free-python-resources/real-time-financial-data-with-alpha-vantage-yahoo-finance)
- [Finnhub API Documentation](https://finnhub.io/docs/api/rate-limit)
- [Best Financial Data APIs in 2026](https://www.nb-data.com/p/best-financial-data-apis-in-2026)
- [Financial Modeling Prep: Developer Documentation](https://site.financialmodelingprep.com/developer/docs)
- [Financial Modeling Prep Pricing Plans](https://site.financialmodelingprep.com/pricing-plans)
- [Twelve Data API Documentation](https://twelvedata.com/docs)
- [Twelve Data Pricing](https://twelvedata.com/pricing)
- [Getting Started with OpenBB: The Ultimate Python Toolkit for Financial and Economic Data](https://autonomousecon.substack.com/p/this-little-known-python-package)
- [OpenBB GitHub Repository](https://github.com/OpenBB-finance/OpenBB)
- [OpenBB for Financial Analysis: A Complete Guide](https://dasroot.net/posts/2026/02/openbb-financial-analysis-python-data-retrieval/)
- [Chapter 1: Acquire Free Financial Market Data with Cutting-Edge Python Libraries](https://subscription.packtpub.com/book/data/9781835084700/1/ch01lvl1sec03/)
- [SEC EDGAR Application Programming Interfaces](https://www.sec.gov/search-filings/edgar-application-programming-interfaces)
- [EdgarTools: Python Library for SEC Data Analysis](https://edgartools.readthedocs.io/)
- [EdgarTools GitHub](https://github.com/dgunning/edgartools)
- [Download SEC Filings With Python](https://sec-api.io/docs/sec-filings-render-api/python-example)

### Fundamental Analysis Metrics
- [Five Key Financial Ratios for Stock Analysis](https://www.schwab.com/learn/story/five-key-financial-ratios-stock-analysis)
- [Top 8 Fundamental Indicators for Stock Analysis in 2025](https://www.equentis.com/blog/8-fundamental-indicators-for-stocks-in-2025/)
- [Understanding the Price-to-Earnings Ratio: A Key Metric for Stock Valuation](https://www.abacademies.org/articles/understanding-the-pricetoearnings-ratio-a-key-metric-for-stock-valuation-17257.html)
- [How to Value Company Stocks: P/E, PEG, and P/B Ratios](https://www.schwab.com/learn/story/how-to-value-company-stocks-pe-peg-and-pb-ratios)
- [Return on Equity: Definition, Calculation & Examples](https://www.bill.com/learning/return-on-equity)
- [Return on Equity (ROE) Ratio Explained](https://www.bajajamc.com/knowledge-centre/return-on-equity-ratio)
- [Return on Equity (ROE) | Formula + Calculator](https://www.wallstreetprep.com/knowledge/return-on-equity-roe/)
- [Fundamentals: Basics Explained](https://eodhd.medium.com/fundamentals-basics-explained-725bc9f1adf7)

### Investment Frameworks
- [Warren Buffett's Investment Strategy](https://www.investing.com/academy/trading/warren-buffett-investment-strategy-rules-fortune/)
- [Mastering Warren Buffett's Investing Principles](https://www.heygotrade.com/en/blog/warren-buffetts-investing-principles)
- [Warren Buffett's 7 Value Investing Guidelines](https://www.cabotwealth.com/daily/value-stocks/warren-buffett-value-investing-guidelines)
- [A Beginner's Guide to Value Investing](https://fooletfs.com/insights/a-beginners-guide-to-value-investing)
- [Dividend Growth Investor](https://www.dividendgrowthinvestor.com/)
- [How to Develop a Dividend Investing Strategy](https://www.vaneck.com/us/en/blogs/income-investing/how-to-develop-a-dividend-investing-strategy-a-comprehensive-guide/)
- [8 Powerful Dividend Investing Strategies for 2025](https://finzer.io/en/blog/dividend-investing-strategies)

### Disclaimers & Legal
- [Are You Illegally Giving Financial Advice?](https://www.givnerlawpc.com/fintwit-law/are-you-illegally-giving-financial-advice/)
- [Financial Disclaimers - Free Privacy Policy](https://www.freeprivacypolicy.com/blog/financial-disclaimers/)
- [Should I say "This is not financial advice" in my YouTube videos?](https://www.avvo.com/legal-answers/should-i-say-this-is-not-financial-advice-in-my-yo-4416706.html)

### MCP Stock Analysis Tools
- [Alpha Vantage MCP Server](https://mcp.alphavantage.co/)
- [MaverickMCP: Personal Stock Analysis MCP Server](https://github.com/wshobson/maverick-mcp)
- [LSEG Financial MCP Integration](https://www.lseg.com/en/insights/supercharge-claudes-financial-skills-with-lseg-data)
- [Stockflow: Stock Market Data MCP](https://github.com/twolven/mcp-stockflow)
- [Financial Datasets MCP Server](https://github.com/financial-datasets/mcp-server)
- [How to Fetch Stock Pricing Data Into Claude Using MCP](https://marketxls.com/blog/fetch-stock-pricing-data-into-claude-using-mcp)
- [finnhub-mcp: Real-Time Financial Data Streaming with MCP](https://github.com/SalZaki/finnhub-mcp)

---

## Confidence Levels

| Finding | Confidence | Reasoning |
|---------|------------|-----------|
| yfinance is actively maintained and 3-4x faster than pandas-datareader | **High** | Multiple 2025-2026 sources confirm; GitHub activity verifiable; performance benchmarks consistent |
| Finnhub free tier offers 60 calls/min with US stock fundamentals | **High** | Official documentation + multiple corroborating sources; Finnhub is enterprise-grade |
| FMP free tier: 250 calls/day, 500MB/30-day bandwidth | **High** | Official FMP pricing page; widely cited in comparisons |
| Alpha Vantage free tier: 25 calls/day only | **High** | Official documentation; consistent across sources |
| "Not financial advice" disclaimers provide zero legal protection without substance backing | **High** | Legal sources explicit; IAA text clear; no exceptions for disclaimers |
| IEX Cloud shut down August 2024 | **High** | Widely reported in fintech community; affects multiple MCP projects |
| EdgarTools is free with no rate limits | **High** | Official GitHub, open source; zero cost verified |
| Value investing framework (Buffett principles) remains timeless | **Medium-High** | Buffett's 2025 Annual Meeting statements affirm principles; academic consensus on framework |
| Dividend growth investing (25+ year dividend increases) is actionable for income portfolios | **High** | Dividend Aristocrats exist and are well-documented; historical data available |
| ROE 15%+ and D/E < 1.0 are reliable beginner screening criteria | **Medium** | Broadly accepted but not universally applicable; depends on industry, stage, economics |
| OpenBB as multi-source data layer is emerging best practice | **Medium** | Strong GitHub activity and community adoption; but v1 may not need this complexity |

---

## Open Questions

1. **IEX Cloud Alternative:** Multiple existing MCPs (mcp-stockflow, MaverickMCP) relied on IEX Cloud before its shutdown. Are their current data sources documented? Should we track this as a case study in MCP vendor risk?

2. **Finnhub International Expansion:** Does Finnhub free tier have any path to international stocks without upgrading to $12+/month? Or should v1 explicitly exclude non-US?

3. **Real-Time vs. Delayed Data Trade-off:** Free APIs (yfinance, Finnhub) have 15-min to 1-hour delays. Is this acceptable for a beginner long-term tool, or should we note it prominently?

4. **FMP vs. Finnhub Head-to-Head:** Both offer fundamentals at different rate limits. Should we test both to see which returns more complete data (e.g., dividend payout ratio, ROIC) for typical screening queries?

5. **Disclaimer Enforceability for MCPs:** How have existing finance MCPs (Alpha Vantage, MarketXLS) structured their disclaimers? Is there a "gold standard" for MCP-based financial tools?

6. **Tax Efficiency Metrics:** Should v1 include tax-loss harvesting or dividend tax implications for US investors? Or defer to v2?

7. **Backtesting Integration:** Should the MCP support historical performance testing (e.g., "How would a 10-year P/E < 15 screener have performed?")? Or keep scope to current analysis only?

---

## Recommendations for MCP Implementation (v1)

1. **Primary Data Sources:** yfinance (prices) + Finnhub (fundamentals/news). Fallback to FMP for fundamentals if Finnhub rate-limited.
2. **Essential Metrics:** Build tools for P/E, ROE, D/E ratio, dividend yield, revenue/EPS growth rate.
3. **Framework:** Default to Value Investing (Buffett-style) with optional Dividend Growth screening.
4. **Disclaimer:** Use the template above; place prominently in every MCP response.
5. **Validation:** Cache data, log API calls, alert on data freshness > 30 min old.
6. **Testing:** Verify yfinance and Finnhub behavior on 20–50 real stock tickers; note any edge cases (delisted stocks, ticker conflicts, etc.).
7. **v2 Path:** Add OpenBB, expand to international stocks, support SEC filing analysis via EdgarTools.

---

**Document Version:** 1.0
**Last Updated:** 2026-03-21
**Next Review:** 2026-06-21 (3 months — API stability, library updates, new free sources)
