# Architecture Decisions

## Overview
Single ReAct agent loop with tool calling, backed by provider abstractions for search, embeddings, and vector storage. Domain specialization via swappable DomainConfig (tools + prompt + RAG settings). CLI-first, finance-vertical-first, designed for repurposing to other domains.

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| LLM framework | Raw Anthropic SDK | Learning the primitives; frameworks hide what we're trying to learn |
| Agent pattern | ReAct (manual loop) | Full control over think→act→observe cycle |
| Search API | Tavily (primary) + Brave (fallback) | Tavily purpose-built for agents; Brave as hedge against Tavily/Nebius acquisition risk |
| Content extraction | trafilatura + httpx | Best accuracy for main content, async HTTP |
| Vector store | ChromaDB (in-process) | Simplest for solo dev; VectorStore protocol enables swap to Qdrant |
| Embeddings | nomic-embed-text-v2 (local) | No API cost, configurable, runs offline |
| Structured outputs | Pydantic + output_config.format | Current API pattern, constrained decoding guarantees |
| Evals | DeepEval + pytest | pytest-native, agent-specific metrics, no vendor lock-in |
| Domain system | DomainConfig Pydantic model | New domain = new config, not new agent. Tools + prompt + RAG config per domain |
| External deps | Protocol abstractions | Swap search/embedding/vectordb via config, not rewrite |
| Extended thinking | effort parameter (adaptive) | Replaces deprecated budget_tokens; "medium" default, "high" for synthesis |

## System Diagram
```
User → CLI → Session → Agent Loop ←→ Tools (via registry)
                ↓                        ↓
           Cost tracker            SearchProvider (Tavily/Brave)
           Loop guard              PageReader (httpx/trafilatura)
           Context mgr             VectorStore (ChromaDB)
                ↓                  EmbeddingProvider (nomic/qwen3)
                ↓                  DomainTools (SEC EDGAR, yfinance)
         ResearchContext
                ↓
         Report Generator → Markdown file
                ↓
         Structured log → logs/
```

## Data Flow
1. User provides query via CLI
2. Session resolves domain config, initializes providers
3. Agent loop: Claude receives query + system prompt + tool definitions
4. Claude calls tools (search, read, store, retrieve) — results sandboxed in XML tags
5. Context manager monitors token usage, summarizes when over budget
6. Loop guard monitors for stuck patterns and cost ceiling
7. On completion, extract ResearchContext (findings + sources) from conversation
8. Report generator produces structured Pydantic output via output_config.format
9. Export as Markdown with citations, confidence levels, and limitations
10. Save report + structured log (iteration count, tools used, token usage, cost)
