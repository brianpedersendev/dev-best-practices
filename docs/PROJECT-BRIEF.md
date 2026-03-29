# Project Brief: Stock Analyst MCP

## One-Line Description
An MCP server that gives Claude the ability to analyze stocks, screen for long-term investment opportunities, and maintain a personal investment knowledge base.

## Problem Statement
Brian has existing stock holdings but lacks confidence that they're well-positioned for long-term growth. He doesn't use dedicated stock analysis tools today and wants an AI-integrated way to evaluate his current portfolio, discover new opportunities, and learn investing fundamentals — all through natural conversation with Claude rather than learning separate financial platforms.

## Target Users
Brian (solo developer, beginner investor). This is a personal tool — no multi-user considerations needed for v1.

## Core Value Proposition
Instead of context-switching between Claude and financial websites/apps, this MCP brings stock data and analysis directly into the AI conversation. Combined with a knowledge base of investment frameworks and personal research notes, it creates a "personal financial analyst" that can explain its reasoning and teach as it goes — something existing screeners don't do.

## MVP Scope

### In (v1)
- **Stock lookup**: Get current price, key fundamentals (P/E, EPS, dividend yield, market cap, revenue growth, debt ratios) for any ticker
- **Portfolio analysis**: Input current holdings → get an assessment of diversification, risk, and quality
- **Stock screening**: Filter stocks by fundamental criteria (e.g., "low P/E, consistent dividend growth, large cap")
- **Analysis & opinion**: Ask "should I buy X?" and get a structured bull/bear case based on fundamentals
- **Knowledge base — frameworks**: Built-in investment principles (value investing basics, key ratios explained, what makes a good long-term hold)
- **Knowledge base — personal notes**: Save and retrieve personal research notes, watch lists, and investment theses per ticker

### Out (v1)
- Real-time trading / brokerage integration
- Technical analysis / charting (focus is fundamentals for long-term)
- Options, crypto, forex — stocks only
- Social/community features
- Paid data sources (free APIs only for v1)
- Backtesting or portfolio simulation
- Tax optimization advice

## Known Competitors / Alternatives
- **Stock screeners** (Finviz, Stock Rover, Simply Wall St): Powerful but not AI-integrated, steep learning curve for beginners
- **AI finance chatbots** (various): Exist but typically lack MCP integration, persistent knowledge base, or focus on long-term fundamentals
- **Financial APIs with Claude**: Could manually paste data into Claude, but tedious and not systematic
- **Existing finance MCPs**: Need to research what's already built in the MCP ecosystem

## Technical Constraints
- Solo developer (Brian)
- MCP server in **Python** (better finance/data library ecosystem — pandas, yfinance, etc.)
- Free financial data APIs only (Yahoo Finance, Alpha Vantage free tier, SEC EDGAR, etc.)
- Must work with Claude Desktop / Cowork via MCP protocol
- Knowledge base needs persistent local storage (SQLite, JSON files, or markdown)
- Open to leveraging existing finance MCPs if they're trustworthy and well-maintained — but trust/reliability of third-party MCPs is a concern that research should evaluate

## Architecture Direction
- **AI-augmented**: Claude is the reasoning engine; the MCP provides data and persistence tools
- **Not AI-native**: No separate AI model needed — Claude does the analysis using data from the MCP
- **RAG likely useful**: For the knowledge base (searching personal notes, investment frameworks by relevance)
- **No agentic backend needed**: MCP tools are called by Claude directly
- **No streaming needed**: Financial data lookups are request/response

## Success Criteria
- Can ask Claude "how's my portfolio looking?" and get a meaningful, data-backed answer
- Can ask "find me good dividend stocks under $50" and get real, current results
- Can save investment theses and retrieve them later ("what was my thesis on MSFT?")
- Brian feels more confident about his investment decisions
- Actually gets used regularly (not a one-time novelty)

## Open Questions
1. What free financial APIs are reliable and comprehensive enough for this?
2. What existing finance MCPs exist — should we build from scratch or extend?
3. What's the best knowledge base approach (vector DB, SQLite, flat files)?
4. How to handle the "not financial advice" liability aspect?
5. What investment frameworks are most useful for a beginner long-term investor?
6. Is Python or TypeScript better for this MCP given the data science / finance library ecosystem?

## Risk Factors
- **"Fun project" motivation**: Brian sees this as a fun build + useful tool. That's valid — but research should still check if the approach makes sense vs. simpler alternatives, so the fun project also produces something genuinely useful.
- **Data quality on free APIs**: Free financial data can be delayed, incomplete, or unreliable. Need to validate during research.
- **Scope creep**: "All of these" for MVP scope is ambitious for a solo dev. May need to prioritize ruthlessly.
- **Not financial advice**: An MCP that says "buy X" carries implicit responsibility. Need clear disclaimers and framing as educational/informational.
- **Beginner building finance tools**: Domain expertise gap — the knowledge base frameworks need to be well-sourced, not made up.
