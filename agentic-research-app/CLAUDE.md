# Agentic Research App

## What This Is
A CLI-based AI research agent that takes a question, autonomously searches the web, reads pages, and synthesizes findings into structured, sourced reports. Built with raw Anthropic Claude SDK (no framework) to learn tool calling, RAG, ReAct, structured outputs, streaming, and evals. Targets finance research as the first vertical.

## Tech Stack
- Python 3.11+
- Anthropic Claude SDK (raw tool use — no LangChain/CrewAI)
- ChromaDB for vector storage (RAG)
- nomic-embed-text-v2 via sentence-transformers (local embeddings)
- Tavily Search API (primary), Brave Search (fallback)
- httpx + trafilatura for web content extraction
- Pydantic v2 for structured outputs and config
- Rich for CLI streaming display
- DeepEval + pytest for evals

## Project Structure
- `src/` — Application code
  - `cli.py` — Entry point (argparse + Rich)
  - `session.py` — Lifecycle: config → run → save → log
  - `agent.py` — ReAct loop + context manager + loop guard
  - `tools.py` — Tool schema definitions + registry
  - `tool_impl.py` — Tool execution with error handling
  - `models.py` — Pydantic models (structured outputs)
  - `config.py` — Settings via pydantic-settings
  - `streaming.py` — Streaming display + cost tracking
  - `report.py` — Report generation from ResearchContext
  - `rag.py` — RAG orchestration (domain-aware)
  - `providers/` — Abstracted external dependencies
    - `protocols.py` — SearchProvider, EmbeddingProvider, VectorStore
    - `search.py` — Tavily + Brave implementations
    - `embeddings.py` — sentence-transformers wrapper
    - `vectordb.py` — ChromaDB implementation
  - `domains/` — Domain-specific tools + prompts + RAG config
- `evals/` — Test suite (tools, RAG, agent behavior, reports)
- `reports/` — Generated research reports
- `logs/` — Per-run structured logs

## Coding Standards
- Use type hints on all function signatures
- Use Pydantic BaseModel for all data structures crossing module boundaries
- Use Protocol classes for external dependencies (search, embeddings, vector store)
- Use `output_config.format` for structured outputs (not deprecated `output_format`)
- Use `effort` parameter for extended thinking (not deprecated `budget_tokens`)
- Keep model names configurable via env vars — use config.model everywhere
- Wrap all external API calls with retry + exponential backoff + jitter
- Return structured error results to Claude on tool failures (keep the loop running)
- Wrap web content in `<retrieved_content>` XML tags to prevent prompt injection
- Handle all stop_reason values: `end_turn` (done), `tool_use` (process tools), `max_tokens` (re-prompt to continue)
- Rate-limit page reads: 1 request/second/domain, max 5 concurrent requests
- Use async for I/O-bound operations (httpx, API calls)
- Structure imports: stdlib → third-party → local

## Development Workflow (TDD — Non-Negotiable)

Every feature, bug fix, and refactor follows this exact sequence:

1. **Plan** — Use Plan Mode. Outline approach, identify affected modules, list edge cases
2. **Write failing tests FIRST** — Define expected behavior as tests. Run them. Confirm they fail
3. **Implement minimum code to pass tests** — Follow patterns in this file
4. **Verify** — Run full test suite: `python -m pytest evals/ --tb=short -q`
5. **Refactor** — Clean up while tests stay green. Run formatter: `black . --quiet`

## Testing
- Framework: pytest + pytest-asyncio + DeepEval
- Location: `evals/` directory
- Coverage target: 80%+ for new code
- Always mock: Tavily API, Claude API, httpx responses in unit tests
- Never mock: Pydantic validation, the tool registry, domain config resolution
- Run: `python -m pytest evals/ --tb=short -q`
- Eval categories: tool correctness, RAG quality, agent behavior, output structure

## Key Patterns
- **ReAct loop** — Think → Act (tool call) → Observe (tool result) → Repeat until synthesis
- **Provider protocol** — External deps behind Protocol ABCs. Swap Tavily→Brave or ChromaDB→Qdrant via config
- **Domain config** — DomainConfig Pydantic model: system prompt + tools + RAG config. New domain = new config, not new agent
- **Content sandboxing** — All web content in `<retrieved_content source="url">` tags. System prompt treats these as untrusted data
- **Context budget** — Count tokens per iteration. Summarize old tool results via Haiku when over 80% of context window
- **Loop guard** — Track tool+input hashes. Detect repeated calls, enforce cost ceiling, circuit-break on API failures

## Cost Management
- Display running cost in streaming output (input + output tokens × model pricing)
- Default cost ceiling: $1.00 per research run (configurable via MAX_COST_PER_RUN)
- Use prompt caching for system prompt + tool definitions (90% discount on iterations 2-N)
- Use Haiku for context summarization (cheap)
- Batch embeddings after agent loop (not one-at-a-time during)

## Security
- Keep `.env` out of git — config.py warns at startup if `.env` is git-tracked
- Include "Not financial advice" disclaimer in finance domain report output
- `chroma_data/` stores findings as plaintext — avoid storing truly sensitive data
