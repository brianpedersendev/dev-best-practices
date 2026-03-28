# Research Synthesis: Agentic Research App

**Date:** 2026-03-28
**Project:** Agentic Research App
**Brief:** [PROJECT-BRIEF.md](../PROJECT-BRIEF.md)

---

## Key Findings

### 1. The Market is Real but Crowded at the Top
AI research agents are a proven category. ChatGPT Deep Research, Perplexity, and Gemini Deep Research are all actively investing in this space with $20-250/mo pricing. However, **all major players are general-purpose** — none go deep in specific verticals. The gap is in domain depth, not general capability.

### 2. Current Tools Have Serious Quality Problems
Even the best tools suffer from:
- **37% hallucination rate** on citations (Perplexity, Columbia Journalism Review study)
- **Overconfidence** — tools report wrong answers instead of flagging uncertainty
- **Poor source selection** — unreliable and AI-generated sources mixed with authoritative ones
- **No persistent memory** — every query starts from scratch

These are addressable problems. A research agent that prioritizes source verification, confidence scoring, and persistent knowledge could meaningfully differentiate.

### 3. Technical Stack is Fully Mature
Every component needed is production-ready:
- **Claude tool use** — GA, well-documented, Pydantic integration for structured outputs
- **Tavily** — Purpose-built search API for agents, free tier for dev, 1,000 credits/mo
- **trafilatura** — Best open-source content extraction
- **ChromaDB + nomic-embed-text-v2** — Solid local RAG stack, no API cost for embeddings
- **DeepEval** — pytest-native eval framework with agent-specific metrics

**No technical blockers.** The riskiest piece is web scraping reliability (mitigated by Tavily's Extract API as fallback).

### 4. Stock/Finance is the Best Niche
Of three candidates evaluated:
- **Stocks/Finance (8/10)** — Best data availability (SEC EDGAR, Yahoo Finance free), clear gap between $24K Bloomberg and $30/mo consumer tools, high willingness to pay
- **Real Estate (7/10)** — Good market, but MLS data access is a barrier
- **AI Development (5/10)** — Great for learning, hard to monetize (free info is abundant)

### 5. The Learning Objective is Fully Achievable
Building this project exercises every target pattern:

| Pattern | How It's Used |
|---------|--------------|
| Tool calling | Web search, page reader, vector store/retrieve, financial data APIs |
| RAG | Store past research chunks, retrieve relevant context for new queries |
| Multi-step reasoning (ReAct) | Plan → search → read → evaluate → iterate loop |
| Structured outputs | Pydantic models for findings, sources, reports |
| Streaming | Real-time agent thinking and progress display |
| Evals | DeepEval + pytest for tools, RAG quality, agent behavior, output quality |

### 6. Open-Source Prior Art is a Strength
GPT Researcher (planner → executor → publisher) and LangChain's Open Deep Research provide proven architectural patterns. Building on raw Anthropic SDK (no framework) means you learn the primitives while borrowing architectural insights from these projects.

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Competing with well-funded incumbents | Medium | Don't compete on general research — specialize in finance vertical |
| Web scraping fragility | Medium | Tavily Extract API as fallback, graceful degradation |
| API costs during development | Low | Tavily free tier (1K/mo), Claude Sonnet for iteration, Opus for final quality |
| "Research quality" is hard to eval | Medium | Start with structural evals (has sources, is structured), add human eval later |
| Financial data accuracy liability | Medium | Clear disclaimers, focus on synthesis not predictions, cite all sources |
| Scope creep (trying to build everything) | Medium | Strict MVP scope, defer web UI and multi-agent to v2 |

---

## Go / No-Go Recommendation

### Recommendation: **GO**

### Rationale

This project hits the sweet spot of learning and potential value:

1. **Learning ROI is exceptional.** Every major AI-native pattern is exercised in a single project. Building with raw SDK (no framework) means you understand the primitives, which transfers to any future framework or project.

2. **The market gap is real.** No one is doing deep, domain-specialized AI research with persistent memory, source verification, and structured outputs at an accessible price point. The gap between Bloomberg ($24K/yr) and Perplexity ($20/mo) is enormous.

3. **Technical risk is low.** Every component is mature, well-documented, and has a free or cheap development tier. You won't get stuck on infrastructure — you can focus on the research agent logic.

4. **The build order is clear.** Start general (domain-agnostic research agent), add financial tools (SEC EDGAR, earnings, financial APIs), then evaluate commercialization. Each phase is independently useful.

### If GO:
- **Key advantages:** All patterns in one project, real market gap in finance niche, excellent data availability, low technical risk
- **Biggest risks:** Scope creep, research quality evaluation, competing with incumbents on general queries
- **Suggested approach:** Build general research agent first (MVP), add finance tools second, evaluate real estate third

### Architecture Direction
```
User Query → Agent Loop (ReAct)
                ├── Search Tool (Tavily API)
                ├── Page Reader (httpx + trafilatura)
                ├── Vector Store (ChromaDB — store findings)
                ├── Vector Retrieve (ChromaDB — get past research)
                └── Report Generator (structured Pydantic output)
            → Streaming CLI Output
            → Markdown Report File
```

---

## Next Step

Proceed to **Phase 3: Implementation Plan** to define:
- Detailed architecture and module structure
- MVP feature list with build order
- Data models (Pydantic schemas)
- Tool definitions
- Eval strategy
- Phase breakdown (what to build first, second, third)
