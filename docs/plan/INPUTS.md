# Planning Inputs

**Date:** 2026-03-28
**Project:** Agentic Research App

## From PROJECT-BRIEF.md
- **Primary goal:** Learn all 6 AI-native patterns (tool use, RAG, ReAct, structured outputs, streaming, evals)
- **App:** CLI research agent — question in, sourced markdown report out
- **Stack:** Python 3.11+, Anthropic Claude SDK (raw, no framework), ChromaDB, httpx
- **Solo developer, learning pace**
- **Small budget OK for API costs**

## From Research (SYNTHESIS.md)
- **Recommendation:** GO
- **Niche:** Start with finance (best data, clear market gap), repurpose for other domains later
- **Search API:** Tavily (purpose-built for agents, free tier)
- **Content extraction:** trafilatura + httpx
- **Embeddings:** nomic-embed-text-v2-moe via sentence-transformers (local, no API cost)
- **Vector DB:** ChromaDB (in-process, persistent)
- **Evals:** DeepEval + custom pytest
- **Structured outputs:** Pydantic models via `client.messages.parse()`
- **Architecture insight:** Domain specialization lives in tools + system prompt, not core agent

## User Decisions at Checkpoint 2
- Finance first, then repurpose for real estate and AI dev
- Build general agent core, add finance tools on top
- Confirmed GO
