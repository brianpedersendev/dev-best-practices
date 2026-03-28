# Project Brief: Agentic Research App

## One-Line Description
A CLI-based AI research agent that takes a question, autonomously searches the web, reads and extracts information from pages, and synthesizes findings into structured reports.

## Problem Statement
General-purpose AI search tools (Perplexity, ChatGPT search, Google AI Overviews) are broad but shallow — they give surface-level answers without deep investigation, source verification, or structured deliverables. Professionals in domains like real estate, stock analysis, and AI development need research that goes deeper: multi-source synthesis, fact-checking across sources, and formatted reports they can act on. Today they do this manually, spending hours clicking through tabs and copying notes.

## Target Users
- **Primary (learning context):** The developer building this — learning tool-calling, RAG, ReAct, structured outputs, streaming, and evals hands-on.
- **Potential commercial users:** Solo professionals and small teams who need domain-specific research reports — real estate investors evaluating markets, traders doing stock due diligence, developers tracking AI tooling changes.

## Core Value Proposition
Depth over breadth. Unlike general AI search, this agent:
1. Runs multi-step research loops (search → read → evaluate → search again)
2. Stores and retrieves past research via vector DB (builds knowledge over time)
3. Produces structured, sourced reports — not just chat responses
4. Can be specialized to a vertical domain for higher-quality results

## MVP Scope

### In v1
- CLI interface: `research "What are the best emerging AI agent frameworks in 2026?"`
- ReAct agent loop: plan → search → read pages → evaluate → iterate (max N steps)
- Tool use: web search (Brave/Tavily API), page reader (httpx + BeautifulSoup), vector store/retrieve
- RAG: ChromaDB for storing and retrieving past research chunks
- Structured outputs: Pydantic models for search results, extracted facts, final reports
- Streaming: Real-time display of agent thinking and progress
- Report generation: Markdown report with sources, confidence levels, key findings
- Eval suite: Automated tests for tool accuracy, agent behavior, and output quality

### Explicitly NOT in v1
- Web UI or API server
- User accounts or multi-tenancy
- Paid search APIs beyond basic tier
- Fine-tuned models
- Production deployment / hosting
- Real-time monitoring dashboards

## Known Competitors / Alternatives
- **Perplexity AI** — Fast, good for quick answers, shallow on depth
- **ChatGPT Deep Research** — Multi-step but closed ecosystem, no customization
- **Google Deep Research (Gemini)** — Similar to ChatGPT approach
- **Tavily + LangGraph examples** — Open-source agent research demos, but toy-level
- **GPT Researcher** — Open-source, closest to this concept, uses multi-agent approach

## Technical Constraints
- **Stack:** Python 3.11+, Anthropic Claude API (raw SDK), ChromaDB, httpx
- **Developer:** Solo, comfortable with Python
- **Timeline:** Learning pace — build it right, understand every layer
- **Budget:** Small spend OK (API calls, basic search API tier)
- **Framework:** Raw Anthropic SDK with tool use — no LangChain/LangGraph (learning the primitives is the goal)

## Architecture Direction
- **AI-native** — AI is the core, not a feature bolted onto a traditional app
- **Needs RAG:** Yes — store past research, retrieve relevant context for new queries
- **Agentic backend:** Yes — ReAct loop with tool calling is the central pattern
- **Streaming:** Yes — real-time token display during research for good CLI UX
- **Multi-agent:** Not in v1, but architecture should allow adding specialized sub-agents later (e.g., fact-checker, source evaluator)

## Domains of Interest (for niche exploration)
1. **Real estate** — Market analysis, property evaluation, neighborhood research
2. **Stocks / finance** — Company due diligence, sector analysis, earnings research
3. **AI development** — Latest tools, frameworks, techniques, breaking changes

## Success Criteria
1. **Learning:** Builder can explain and implement all 6 patterns (tool use, RAG, ReAct, structured outputs, streaming, evals) from scratch
2. **Functional:** Agent can take a research question and produce a useful, sourced report in under 5 minutes
3. **Quality:** Eval suite passes — tools return valid data, agent completes research loops, reports are structured and sourced
4. **Stretch:** Identify a profitable niche angle validated by research

## Open Questions
1. Which niche (real estate, stocks, AI dev) has the best intersection of "research depth is valuable" and "people will pay for it"?
2. What search API to use? (Brave Search, Tavily, SerpAPI — cost vs quality tradeoffs)
3. How to handle anti-scraping measures when reading web pages?
4. What embedding model for ChromaDB? (Anthropic doesn't offer embeddings — use open-source?)
5. How to evaluate "research quality" in evals? (Factual accuracy, source diversity, relevance)
6. What does GPT Researcher do well/poorly that we can learn from?

## Risk Factors
- **Web scraping fragility** — Pages block bots, change structure, return garbage. Need robust fallbacks.
- **API costs could add up** — Each research run hits search API + multiple Claude calls. Need to monitor and optimize.
- **"Research quality" is subjective** — Hard to eval automatically. May need human-in-the-loop evals.
- **Competing with well-funded tools** — Differentiation must come from depth, customization, or niche focus, not general capability.
