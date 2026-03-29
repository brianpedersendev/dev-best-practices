# Stock Analyst MCP — Product Specification

**Date**: 2026-03-21
**Target User**: Brian (solo developer, beginner investor, personal tool only)
**MVP Scope**: 9 MCP tools focused on thesis tracking + fundamentals analysis + beginner screening
**Build Target**: 1-2 weeks (solo developer, free APIs, local deployment)

---

## Target User Profile

**Name**: Brian
**Role**: Solo developer, beginner investor
**Context**: Has existing stock holdings but limited confidence in their long-term positioning
**Goals**:
- Evaluate current portfolio through an AI-integrated lens
- Discover new investment opportunities aligned with long-term value investing principles
- Build and maintain personal investment theses and research notes
- Learn investing fundamentals via Claude conversations (not separate financial platforms)

**How He'll Use It**: Natural language conversations with Claude integrated into his existing workflow. Examples: "How's my portfolio looking?", "Find me good dividend stocks under $50", "What was my thesis on MSFT?", "Compare these two tech stocks"

**Not a Target**: Professional traders, day traders, multi-user teams, or those needing real-time data or technical analysis

---

## User Problems (Ranked)

Each problem is mapped to a research finding. The MVP solves the top 5-6 directly.

### 1. **Can't easily access fundamentals for stocks he owns** ← SYNTHESIS insight #5 (P/E, ROE, D/E are starter metrics)
- **Problem**: Brian checks individual stocks on Yahoo Finance or Google, manually compares key metrics, context-switches away from Claude
- **Why it matters**: Without quick fundamental data, he can't evaluate if holdings are still attractive or if a new opportunity is worth considering
- **How MVP solves it**: Stock quote + fundamentals lookup tool returns price, P/E, ROE, dividend yield, debt ratios in one Claude call

### 2. **No systematic way to track investment theses over time** ← SYNTHESIS insight #1 (knowledge base is unique differentiator)
- **Problem**: He has theories about why he bought certain stocks ("MSFT has a durable moat in enterprise cloud"), but doesn't document or retrieve them later
- **Why it matters**: Without thesis tracking, he can't assess whether his original reasoning still holds, leading to uninformed hold/sell decisions
- **How MVP solves it**: Knowledge base tool saves per-ticker theses, searchable and retrievable ("what was my reasoning on MSFT?")

### 3. **Doesn't have a clear framework for what makes a "good" long-term stock** ← SYNTHESIS insight #5, #9 (Buffett-style value investing)
- **Problem**: He knows "long-term investing" is the goal but lacks a systematic way to evaluate quality, valuation, and risk
- **Why it matters**: Without a framework, analysis feels subjective and ad-hoc, reducing confidence in decisions
- **How MVP solves it**: Pre-seeded investment frameworks (Buffett basics: ROE >15%, P/E vs industry, durable moats) provide a consistent lens

### 4. **Struggles to compare multiple stocks objectively** ← SYNTHESIS insight #8 (8-10 atomic tools, not API wrappers)
- **Problem**: When considering multiple candidates, he has to pull data separately for each and manually compare
- **Why it matters**: Comparison is tedious, error-prone, and makes it hard to narrow down a shortlist
- **How MVP solves it**: Stock comparison tool returns aligned metrics for 2-5 tickers in one call

### 5. **Can't quickly see portfolio health and diversification** ← PROJECT BRIEF success criteria (portfolio analysis)
- **Problem**: Needs to understand if his holdings are over-concentrated, balanced, or skewed toward one sector/size
- **Why it matters**: Poor diversification increases portfolio risk without commensurate upside
- **How MVP solves it**: Portfolio snapshot tool reads JSON holdings and returns diversification analysis + sector breakdown

### 6. **Doesn't integrate recent news with fundamental analysis** ← INPUTS decision (news integration in v1 scope)
- **Problem**: Key news about a stock (earnings miss, product launch, management change) doesn't automatically feed into his analysis
- **Why it matters**: Recent news can invalidate old assumptions; missing it means slow decision-making
- **How MVP solves it**: News tool pulls recent articles per ticker from Finnhub, Claude can synthesize with fundamentals

---

## MVP Feature Set

### 1. Stock Quote Lookup

**User Story**: As a beginner investor, I want to quickly get the current price and basic market data for a stock so that I can check if it's still in a reasonable range and understand its trading volume.

**Why MVP**: Foundational — without current pricing, all other analysis is outdated. Quote is the fastest, most reliable API call.

**Acceptance Criteria**:
- Returns price, market cap, 52-week high/low, and trading volume for any valid ticker
- Handles invalid tickers gracefully (returns clear error message, not crash)
- Cached for 5 minutes to respect API rate limits (Finnhub 60/min)
- Price is real-time or <15 min delayed (acceptable for long-term investor)
- Returns data in structured format Claude can reason about (JSON with units labeled)

**User Flow**:
```
User: "What's Apple trading at right now?"
Claude: [calls get_stock_quote("AAPL")]
MCP Returns: { price: 235.50, volume: 42_500_000, market_cap: "3.12T", 52w_high: 242.84, 52w_low: 178.50 }
Claude: "Apple is trading at $235.50 with a 52-week range of $178.50 - $242.84, suggesting it's near the upper end of recent trading but still below its peak."
```

**Edge Cases**:
- Ticker doesn't exist (e.g., "FAKE"): Return clear error, suggest checking spelling
- Market closed: Return last close with timestamp, note market status
- API down (yfinance fails): Fall back to Finnhub, return cached data if both fail
- Delisted stock: Return error + note that company no longer trades

**Data Source**: yfinance primary, Finnhub fallback

---

### 2. Fundamentals Analysis

**User Story**: As a value investor, I want to see key financial metrics (P/E, ROE, debt ratio, dividend yield, growth rates) for a company so that I can quickly assess whether it fits my investing framework.

**Why MVP**: Core to the value investing angle — these 6-7 metrics are the starter set Buffett recommends. Skipping this makes the tool incomplete.

**Acceptance Criteria**:
- Returns: P/E ratio, ROE (%), debt-to-equity, dividend yield (%), EPS, revenue growth (YoY), and earnings growth (YoY)
- Includes industry/sector comparison context ("P/E 18 vs industry avg 22")
- Handles stocks with no dividend (shows 0% yield, not error)
- Handles negative earnings (shows loss, flags as risky, doesn't try to compute meaningless ratios)
- Cached for 1 day (fundamentals update quarterly for most companies)
- Returns units and explanatory text Claude can use to educate

**User Flow**:
```
User: "Is Microsoft a good value right now?"
Claude: [calls get_fundamentals("MSFT")]
MCP Returns: {
  pe_ratio: 28.5,
  roe: 32.1,
  debt_to_equity: 0.42,
  dividend_yield: 0.8,
  eps: 10.20,
  revenue_growth_yoy: 12.3,
  earnings_growth_yoy: 9.8,
  industry_avg_pe: 24.0,
  notes: "Strong ROE and low debt. P/E above industry but justified by growth."
}
Claude: "Microsoft shows a strong ROE of 32% and conservative debt at 0.42x equity. The P/E of 28.5 is above the tech industry average of 24, but the 12% revenue growth and 10% earnings growth justify a premium valuation."
```

**Edge Cases**:
- Startup with losses: Show 0 for unprofitable ratios, flag "pre-profit company" and note why analysis differs
- Recently public (IPO): Limited historical data, flag "new company" warning
- Dividend suspended: Show historical yield but note suspension date
- Complex capital structure: Document assumptions (e.g., "using diluted EPS")

**Data Source**: Finnhub (most reliable for fundamentals on free tier), FMP fallback for missing data

---

### 3. Company Information

**User Story**: As a beginner investor learning about a company, I want a quick summary of what the company does, its sector, and its industry so that I can understand the competitive context.

**Why MVP**: Frames the analysis — you can't evaluate fundamentals in a vacuum. "Why does Microsoft's P/E justify a premium?" requires knowing it's in high-growth cloud computing, not mature software licensing.

**Acceptance Criteria**:
- Returns: Company name, sector, industry, business description (1-2 sentences), headquarters location
- Cached for 7 days (company info rarely changes)
- Description is clear enough for a beginner (no jargon, or jargon explained)
- Handles all ticker types (large cap, small cap, international where available)

**User Flow**:
```
User: "Tell me about Nvidia."
Claude: [calls get_company_info("NVDA")]
MCP Returns: {
  name: "NVIDIA Corporation",
  sector: "Information Technology",
  industry: "Semiconductors",
  description: "Designs and manufactures GPU chips for data centers, AI, gaming, and automotive applications. Leading supplier of AI accelerators.",
  headquarters: "Santa Clara, CA, USA"
}
Claude: "Nvidia is a semiconductor company focused on GPUs. It's the dominant supplier of AI accelerator chips used in data centers — critical infrastructure for AI training and inference."
```

**Edge Cases**:
- No description available in API: Return what's available (sector, industry, headquarters)
- Holding company with diverse divisions: Note the complexity, provide highest-level description
- Recent acquisition/reorganization: Flag if data might be stale

**Data Source**: Finnhub, fallback to yfinance

---

### 4. Portfolio Snapshot

**User Story**: As a portfolio holder, I want to see my current holdings at a glance — including which sectors I'm over-weighted in and how diversified I am — so that I can spot concentration risk and decide if rebalancing is needed.

**Why MVP**: Directly addresses problem #5. Brian needs to know "is my portfolio balanced?" without manually calculating allocation percentages. This requires persistent storage (JSON) + summarization.

**Acceptance Criteria**:
- Reads holdings from JSON file (~/.stock_analyst/portfolio.json)
- Returns: Total portfolio value, sector breakdown (%), top 3 holdings by weight, portfolio P/E (weighted average), portfolio dividend yield (weighted average)
- Flags concentration risk if single stock >30% of portfolio
- Handles zero-position portfolio gracefully (returns "no holdings recorded" with instructions to add)
- All calculations rounded to 1 decimal place for readability

**User Flow**:
```
User: "How's my portfolio looking?"
Claude: [calls get_portfolio_snapshot()]
MCP Returns: {
  total_value: 125000,
  holdings_count: 8,
  sector_breakdown: { "Technology": 45%, "Healthcare": 25%, "Financials": 20%, "Energy": 10% },
  top_3_holdings: [
    { ticker: "MSFT", value: 35000, weight: 28% },
    { ticker: "JNJ", value: 25000, weight: 20% },
    { ticker: "AAPL", value: 22000, weight: 17.6% }
  ],
  portfolio_pe: 24.3,
  portfolio_dividend_yield: 1.8%,
  concentration_warnings: ["MSFT at 28% exceeds 25% diversification target"]
}
Claude: "Your portfolio is reasonably diversified with 8 holdings, but skewed toward technology at 45%. Microsoft is your largest position at 28% — consider rebalancing if this is above your target. Your portfolio P/E is 24.3, above market average, suggesting growth tilt."
```

**Edge Cases**:
- Stock in portfolio no longer trades (delisted): Flag and warn user to remove
- Holdings file corrupted: Return clear error with recovery instructions
- Portfolio partially entered (1-2 stocks out of many): Return snapshot for what's there, note incompleteness

**Data Source**: Local JSON + live quote data for current prices

---

### 5. Fundamentals Comparison

**User Story**: As an investor evaluating multiple stock candidates, I want to see key metrics side-by-side so that I can quickly identify which is more attractively valued and has better fundamentals.

**Why MVP**: Comparison is a natural investor workflow. Without this, Claude would need to call the fundamentals tool multiple times and manually tabulate. A dedicated comparison tool reduces token usage and improves clarity.

**Acceptance Criteria**:
- Accepts 2-5 tickers
- Returns aligned table: Ticker, Price, P/E, ROE, D/E, Dividend Yield, EPS Growth (YoY), Revenue Growth (YoY)
- Highlights outliers (highest/lowest in each column) so Claude can spot patterns
- Includes note if tickers are in different sectors (apples-to-oranges warning)
- Data is current (same caching rules as fundamentals)

**User Flow**:
```
User: "Compare Microsoft, Google, and Meta. Which has the best value metrics?"
Claude: [calls compare_stocks(["MSFT", "GOOGL", "META"])]
MCP Returns:
| Ticker | Price  | P/E   | ROE  | D/E  | Div Yield | EPS Growth | Rev Growth |
|--------|--------|-------|------|------|-----------|------------|------------|
| MSFT   | 235.50 | 28.5* | 32%  | 0.42 | 0.8%      | 9.8%       | 12.3%      |
| GOOGL  | 178.20 | 21.2  | 16%  | 0.08 | 0%        | 8.2%*      | 11.8%      |
| META   | 524.60 | 32.1* | 22%* | 0.01 | 0%        | 14.2%      | 23.5%*     |
*Note: Different sectors (cloud, advertising, social) - metrics less comparable

Claude: "Google shows the most attractive valuation (lowest P/E), but Microsoft has superior profitability (ROE 32% vs Google's 16%). Meta is growing fastest in revenue and earnings but most expensive on P/E — appropriate for a high-growth platform."
```

**Edge Cases**:
- Mixed sectors: Flag that direct comparison may be misleading
- >5 tickers requested: Politely decline ("too many to compare in one view"), suggest narrowing
- One ticker missing data: Return comparison for those available, flag the missing one
- Tickers in different countries: Note exchange and currency

**Data Source**: Finnhub + yfinance for prices

---

### 6. Portfolio Management (Add/Update Positions)

**User Story**: As a portfolio owner, I want to add new holdings to my portfolio and update existing positions (shares, cost basis) so that my portfolio snapshot is always current.

**Why MVP**: Without the ability to persist holdings, portfolio analysis is pointless. This is the write-side of portfolio management.

**Acceptance Criteria**:
- Accepts ticker, number of shares, and average purchase price (cost basis)
- Adds new position or updates existing one in JSON file
- Returns confirmation: "Added 100 shares of AAPL at $150 average cost ($15,000 total)"
- Handles duplicate entries (update not append)
- Validates inputs (no negative shares, valid tickers)
- Saves to ~/.stock_analyst/portfolio.json

**User Flow**:
```
User: "I just bought 100 shares of Apple at $230 per share."
Claude: [calls add_portfolio_position("AAPL", shares=100, cost_per_share=230)]
MCP Returns: { success: true, message: "Added 100 AAPL @ $230 (total $23,000 to portfolio)" }
Claude: "Got it! I've added 100 Apple shares at $230 to your portfolio. That's a $23,000 position. Want me to show you how that affects your overall allocation?"
```

**Edge Cases**:
- Ticker doesn't exist: Validate against yfinance before accepting
- User enters wrong number/price: Tool doesn't validate logic (that's Claude's job), but asks for confirmation
- Portfolio.json file doesn't exist: Create it automatically
- User adds position they already own at different price: Update to new total cost basis (weighted average)

**Data Source**: Local JSON persistence

---

### 7. Knowledge Base — Save & Search Investment Notes

**User Story**: As an investor, I want to write down my thesis for why I'm holding or considering a stock, and then retrieve my original reasoning later so that I can avoid second-guessing and stay true to my long-term thesis.

**Why MVP**: This is the unique differentiator (SYNTHESIS insight #1). No existing tool does thesis persistence + search. Critical for the value add.

**Acceptance Criteria**:
- Saves per-ticker notes (text up to ~10,000 chars)
- Stores in SQLite with full-text search (FTS5)
- Retrieves notes by ticker ("what's my thesis on MSFT?") or keyword search ("why did I like high-ROE stocks?")
- Timestamped entries (when note was created)
- Returns note + creation date; Claude can assess if it's stale
- Handles ~100 tickers × 10 notes each without performance issues

**User Flow**:
```
User: "Save a thesis on Microsoft. I like it because of its Azure cloud dominance and enterprise switching costs."
Claude: [calls save_note(ticker="MSFT", title="Azure moat", content="Microsoft has a durable moat in enterprise cloud via Azure. Customers are locked in by integration with Office 365, Active Directory, and legacy IT infrastructure. ROE >30% validates pricing power. Risk: competition from AWS and GCP long-term.")]
MCP Returns: { success: true, note_id: 42, created: "2026-03-21T10:30:00Z" }
Claude: "Saved! I've recorded your thesis on Microsoft's Azure moat."

[Later...]

User: "What was my original thesis on Microsoft?"
Claude: [calls search_notes(ticker="MSFT")]
MCP Returns: [
  { id: 42, ticker: "MSFT", title: "Azure moat", content: "Microsoft has a durable moat...", created: "2026-03-21" }
]
Claude: "Here's your original thesis from March 21: You identified Azure's enterprise lock-in as the key value driver, with ROE >30% as validation. Current situation: Azure is still growing 30%+ YoY, ROE now at 32%... your thesis is holding up."
```

**Edge Cases**:
- Note older than 6 months: Claude should suggest revisiting against current fundamentals
- Empty query: Return recent notes (last 5) with instruction to search by ticker or keyword
- Multiple notes per ticker: Return all, sorted by date descending
- Duplicate notes: Allow multiple notes per ticker (user might update thesis over time)

**Data Source**: SQLite local database (~/.stock_analyst/knowledge.db)

---

### 8. Investment Frameworks (Pre-seeded + User-Added)

**User Story**: As a beginner investor, I want access to proven, systematic frameworks for long-term investing (like Buffett's principles) so that I can apply consistent logic to all stock evaluations instead of analyzing ad-hoc.

**Why MVP**: Addresses problem #3. Pre-seeding with 3-5 frameworks (Buffett value investing, dividend growth, quality metrics) makes the tool immediately useful. Frameworks are the structure Claude uses to reason about stocks.

**Acceptance Criteria**:
- Includes 3-5 pre-seeded frameworks (Buffett value investing, dividend growth investing, quality metrics, margin of safety concept, competitive advantage/moat)
- Each framework: name, description, key metrics/thresholds, and example application
- Stored in SQLite or JSON alongside knowledge base
- User can add custom frameworks (for v1, text-based; no schema validation needed)
- Claude can retrieve frameworks by name or keyword ("show me the moat framework")
- Frameworks are educational (include sources, explanations, not just numbers)

**User Flow**:
```
User: "Show me the Buffett value investing framework."
Claude: [calls get_framework(name="Buffett Value Investing")]
MCP Returns: {
  name: "Buffett Value Investing",
  description: "Long-term approach focused on finding wonderful businesses at fair prices.",
  key_metrics: [
    { metric: "Return on Equity (ROE)", threshold: ">15%", reason: "Indicates pricing power and capital efficiency" },
    { metric: "Debt-to-Equity", threshold: "<1.0", reason: "Conservative leverage, financial stability" },
    { metric: "P/E vs industry average", threshold: "<1.1x", reason: "Pay fair price, not premium" },
    { metric: "Durable competitive advantage", threshold: "evident", reason: "Moat protects earnings long-term" }
  ],
  example: "Apple: ROE 32%, D/E 0.42, P/E 28 (vs industry 24) — high P/E justified by moat (ecosystem) and ROE. Would warrant closer look.",
  source: "Berkshire Hathaway shareholder letters, Graham & Dodd 'Security Analysis'"
}
Claude: "Buffett's framework prioritizes three things: (1) Return on Equity >15% as a proxy for pricing power, (2) Low debt to ensure financial health, and (3) Buying at a fair price relative to the industry. Here's how your portfolio stacks up against these criteria..."
```

**Edge Cases**:
- User requests unknown framework: Return closest match or list all available
- Framework has conflicting criteria (e.g., "high growth + low P/E"): Claude handles the interpretation
- User adds framework with unclear metrics: Store as-is; Claude may need to ask clarifying questions

**Data Source**: SQLite or JSON (pre-seeded) + SQLite (user-added)

---

### 9. News Integration

**User Story**: As an investor, I want to see recent news about a stock so that I can understand if recent events (earnings, product announcements, leadership changes) might affect my thesis.

**Why MVP**: INPUTS document confirms "news integration in v1 scope, user specifically requested." Recent news is crucial context for updating investment theses. Finnhub provides free news API (reliable, 60 calls/min).

**Acceptance Criteria**:
- Returns 5-10 most recent news articles for a ticker (headline, source, publish date, brief URL)
- Cached for 1 hour (news changes frequently, but not every minute)
- Includes publish date so Claude can assess timeliness
- Handles stocks with no recent news gracefully ("no recent news found")
- Returns data Claude can summarize and contextualize

**User Flow**:
```
User: "What's been happening with Tesla lately?"
Claude: [calls get_news("TSLA")]
MCP Returns: [
  { headline: "Tesla reports Q1 2026 earnings miss, delays new model", source: "Reuters", published: "2026-03-19", url: "..." },
  { headline: "Elon Musk hints at robotaxi reveal in Q2", source: "Bloomberg", published: "2026-03-18", url: "..." },
  { headline: "Tesla stock falls 8% on margin pressure concerns", source: "MarketWatch", published: "2026-03-17", url: "..." },
  ...
]
Claude: "Recent news suggests pressure: earnings miss, margin concerns, and delayed product launches. But Musk is signaling robotaxi progress. This conflicts with Tesla's growth thesis — you may want to revisit your investment case if you're holding."
```

**Edge Cases**:
- Stock too small to have news coverage: Return empty list, note coverage is limited to larger caps
- News temporarily unavailable (API down): Return cached news if available, note staleness
- Ticker wrong/delisted: Return error, suggest checking ticker spelling
- Breaking news with temporary volatility: Claude should note recent date, caution against overreacting

**Data Source**: Finnhub news API

---

### 10. Stock Summary (Combined View)

**User Story**: As someone evaluating a stock, I want a consolidated 1-page summary that combines price, fundamentals, company info, and recent news so that I can get the full picture in one Claude call without multiple tool invocations.

**Why MVP**: SYNTHESIS insight #8 recommends "one-page stock summary" as high-impact, high-feasibility feature. Reduces token usage, speeds up analysis, and provides better Claude context in a single structure. Also ensures consistent "analysis frame" across all stocks.

**Acceptance Criteria**:
- Accepts single ticker
- Returns: current price + daily change, fundamentals (P/E, ROE, D/E, div yield), company info (sector, description), and 3 most recent news headlines
- All data current (same cache rules as individual tools)
- Formatted for readability (JSON with clear sections or simple text blocks)
- Includes framework-relevant context ("P/E vs industry average")

**User Flow**:
```
User: "Give me a full snapshot of Microsoft."
Claude: [calls get_stock_summary("MSFT")]
MCP Returns: {
  summary_for_ticker: "MSFT",
  price_snapshot: {
    current_price: 235.50,
    daily_change: "+2.1%",
    52w_high: 242.84,
    52w_low: 178.50,
    market_cap: "3.12T"
  },
  fundamentals: {
    pe_ratio: 28.5,
    roe: 32.1,
    debt_to_equity: 0.42,
    dividend_yield: 0.8,
    revenue_growth_yoy: 12.3,
    earnings_growth_yoy: 9.8
  },
  company: {
    name: "Microsoft Corporation",
    sector: "Information Technology",
    industry: "Software - Infrastructure",
    description: "Develops cloud computing, productivity software, gaming, and enterprise solutions."
  },
  recent_news: [
    { headline: "Microsoft Q2 earnings beat estimates on Azure growth", source: "Reuters", date: "2026-03-19" },
    { headline: "GitHub Copilot revenue to double in 2026", source: "TechCrunch", date: "2026-03-18" },
    { headline: "Microsoft announces $10B investment in AI infrastructure", source: "Bloomberg", date: "2026-03-15" }
  ]
}
Claude: "Microsoft is trading at $235.50 with strong momentum (up 2% today). Fundamentals are solid: ROE 32% shows excellent capital efficiency, and the P/E of 28.5 is justified by 12% revenue growth and a dominant position in cloud/AI. Recent news highlights Copilot revenue growth and AI infrastructure investment, aligned with the cloud/AI thesis."
```

**Edge Cases**:
- One component unavailable (e.g., no recent news): Return full summary with missing component noted
- Ticker doesn't exist: Return error, suggest alternatives
- Data age varies (price 5 min fresh, fundamentals 1 day old): Include cache timestamps in output
- Very small cap with partial data: Return what's available, flag data gaps

**Data Source**: Composite of all previous tools (leverages caching)

---

## Explicitly Out of MVP

### Stock Screener / Filter Tool
**Why cut**: Requires complex query logic ("find stocks with P/E <20 AND ROE >15% AND debt <1.0"). For v1, Claude can apply screening logic via existing tools (fundamentals comparison + portfolio snapshot). Dedicated screener tool is v2 when usage patterns clarify what filters matter most.
**Tradeoff**: Users can ask "find me dividend stocks under $50" and Claude manually evaluates 5-10 candidates via comparison tool. Slower but sufficient for personal use.

### SEC Filing Summaries / EdgarTools Integration
**Why cut**: Requires parsing 10-K/10-Q documents, extracting key sections (MD&A, risk factors), and summarizing. EdgarTools exists but adds significant complexity. Suitable for v2 after core tools are stable.
**Tradeoff**: Theses and news provide qualitative context; fundamentals provide quantitative context. SEC filings are overkill for a beginner.

### Portfolio Performance Tracking Over Time
**Why cut**: Requires historical snapshots of holdings, prices, and dividends received. Adds schema complexity, tracking logic, and reconciliation. Current portfolio snapshot covers "how am I diversified NOW?" For performance tracking ("how much have I made?"), need buy-in-to-now P&L calculation and dividend tracking.
**Tradeoff**: Users can ask Claude to calculate P&L manually (current value - cost basis), but not automated trend tracking. Good v2 feature.

### Technical Analysis / Charting
**Why cut**: Long-term investing focus means charting is out of scope. Fundamentals + news provide the decision-making inputs. Moving averages, MACD, RSI are day-trader tools.
**Tradeoff**: Deliberately excluded — this tool is anti-pattern for the value investing thesis.

### International Stocks
**Why cut**: Finnhub free tier is US-only. Adding international coverage requires Twelve Data (paid) or similar. Brian can ask Claude about international stocks manually; MCP focuses on US market where free APIs are comprehensive.
**Tradeoff**: Clarify in docs that tool is US-focused. If Brian wants international coverage, can revisit in v2 with paid APIs or alternative sources.

### Thesis Comparison Over Time ("How has my thesis held up?")
**Why cut**: Requires retrieving historical thesis, comparing it to current fundamentals, and assessing "thesis drift." Adds complexity around thesis versioning and historical fundamentals snapshots.
**Tradeoff**: User can manually ask Claude "my original thesis said ROE would stay >25%; is it?" and Claude answers. Not automated, but achievable.

### Options, Crypto, Forex
**Why cut**: MCP is for long-term stock investing only. Options require volatility data and pricing models. Crypto and forex are out of scope for the target user.
**Tradeoff**: Deliberately narrow focus — makes the tool more cohesive and beginner-friendly.

---

## Success Metrics

### Quantitative
1. **Regular usage**: Brian uses the tool at least 2x per week for 2+ months post-launch (habituation signal)
2. **Portfolio persistence**: At least 5 of his 8 holdings are entered into portfolio.json within first week (adoption barrier cleared)
3. **Knowledge base growth**: 20+ investment notes saved within first month (thesis tracking is valued)
4. **Lookup frequency**: 10+ distinct ticker lookups per week (discovery is happening)

### Qualitative
1. **Thesis tracking is used**: Brian retrieves a saved thesis and uses it to inform a hold/sell decision (core value realized)
2. **Framework adoption**: Brian explicitly references a pre-seeded framework in decision-making ("that meets the moat criterion")
3. **Reduced context-switching**: Brian says "I don't have to switch to Yahoo Finance anymore" (friction reduced)
4. **Learning signal**: Brian asks questions about metrics (P/E, ROE, dividend yield) — tool is teaching (educational value working)
5. **Confidence improvement**: Brian reports feeling more structured/systematic in his investment thinking (subjective win)

### Technical Health
1. **API reliability**: 99%+ uptime on free APIs with graceful degradation (fallbacks work)
2. **Cache hit rate**: 80%+ of quotes served from cache (rate limiting handled)
3. **Zero security incidents**: No API keys leaked, no prompt injection exploits (security baseline)

---

## Implementation Priorities

### Phase 1 (Days 1-3): Core Data Layer
1. Stock quote lookup (#1)
2. Fundamentals analysis (#2)
3. Company info (#3)
- Build: yfinance + Finnhub integration, TTL caching, error handling

### Phase 2 (Days 4-5): Portfolio & Knowledge Base
1. Portfolio management (#6)
2. Knowledge base save/search (#7)
3. Investment frameworks (#8)
- Build: JSON persistence, SQLite schema + FTS5, basic UI for note/framework management

### Phase 3 (Days 6-7): Analysis Tools
1. Fundamentals comparison (#5)
2. News integration (#9)
3. Stock summary (#10)
- Build: Composite tools, Finnhub news API integration

### Testing & Polish (Days 8-10)
- Edge case handling, caching validation, Claude conversation testing
- Documentation and error messages
- Buffer for scope creep or API surprises

---

## Technical Assumptions (Validated in SYNTHESIS)

1. **FastMCP 3.0** is the framework (decorator-based, type-hint schema generation, active development)
2. **yfinance** is reliable enough for prices (with Finnhub fallback)
3. **Finnhub free tier** covers fundamentals, news, and company info for US stocks
4. **SQLite + FTS5** is sufficient for thesis/framework search (no vector DB needed for v1)
5. **Local JSON** is fine for portfolio persistence (user only, no multi-device sync)
6. **5-7 minute build** of a working MCP is realistic (FastMCP + yfinance + Finnhub, not building data pipelines)

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| yfinance API breaks mid-build | Medium | High | Finnhub + FMP fallback; abstract data layer from day 1 |
| Scope creep (user wants screener, SEC filings, etc.) | High | High | Hard "no" on v2+ features; stick to 10-tool limit; weekly scope review |
| "Over-trust AI" syndrome | Medium | High | Disclaimers in tool output, frame as educational analysis, Claude handles framing |
| Finnhub API hits rate limit | Low | Medium | Caching + graceful degradation; document rate-limit handling in README |
| SQLite schema issues at scale | Low | Medium | Pre-plan schema for 100+ tickers × 10 notes; test with sample data |
| Time estimation wrong (>2 weeks) | Medium | High | Buffer days built in (days 8-10); prioritize 6 core tools over 10 if needed |

---

## Glossary of Terms

- **MCP**: Model Context Protocol — protocol for connecting Claude to external tools via JSON-RPC
- **Thesis**: Investment rationale — "why am I holding/considering this stock?"
- **Moat**: Competitive advantage (durable, defensible) — e.g., network effects, brand, switching costs
- **P/E**: Price-to-earnings ratio — valuation metric (lower = cheaper relative to earnings)
- **ROE**: Return on equity — profitability metric (higher = more profitable)
- **D/E**: Debt-to-equity ratio — leverage metric (lower = less risky)
- **Dividend yield**: Annual dividend ÷ stock price — income metric (higher = more income)
- **TTL**: Time-to-live — cache expiration window (e.g., 5 min for quotes)
- **FTS5**: Full-text search 5 — SQLite extension for fast text search

---

**Next Steps**:
1. Validate all APIs during build (yfinance, Finnhub, FMP)
2. Set up local dev environment (Python 3.10+, FastMCP, required libraries)
3. Build Phase 1 tools (Days 1-3), test with sample tickers
4. Iterate on Claude integration (Phase 2-3)
5. User testing with Brian (weekly check-ins)
6. v1 release + gather usage data for v2 planning
