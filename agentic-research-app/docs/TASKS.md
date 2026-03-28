# Tasks

## Phase 1: Foundation (Core Agent Loop + Safeguards + Tests)

### In Progress
- [ ] Set up project — pyproject.toml, .env.example, .gitignore *(done in scaffold)*

### Up Next
- [ ] config.py — Settings via pydantic-settings (model, max iterations, cost ceiling, context budget)
- [ ] models.py — Pydantic models (SearchResult, PageContent, Finding, ResearchReport, DomainConfig, RunMetrics)
- [ ] providers/protocols.py — SearchProvider, EmbeddingProvider, VectorStore protocols
- [ ] providers/search.py — Tavily (primary) + Brave (fallback) implementations
  - [ ] test: search returns results, fallback triggers when primary fails *(depends: protocols.py)*
- [ ] tools.py — Tool schema definitions + registry *(depends: models.py)*
- [ ] tool_impl.py — web_search + read_page with error handling, rate limiting, content sandboxing *(depends: tools.py, providers/search.py)*
  - [ ] test: tool execution, error handling returns structured errors, rate limiting, content sandboxed in XML tags
- [ ] agent.py — ReAct loop with ContextManager, LoopGuard, retry/backoff, stop_reason handling *(depends: tools.py, tool_impl.py, models.py)*
  - [ ] test: loop completes, loop detection fires on repeated calls, cost ceiling stops agent, max_tokens re-prompts
- [ ] streaming.py — Rich console output (thinking, tool calls, progress, running cost)
- [ ] session.py — Lifecycle: parse query → resolve domain → run agent → save report → write log *(depends: agent.py, streaming.py)*
- [ ] cli.py — Entry point: `python -m src.cli "your question"` *(depends: session.py)*
- [ ] report.py — Markdown report from ResearchContext (not raw messages) *(depends: models.py)*
  - [ ] test: report has all required fields, sources cited, markdown well-formed
- [ ] conftest.py — Mock providers (SearchProvider, Claude client) for fast unit tests

**Exit criteria:** `python -m src.cli "What are the top AI agent frameworks?"` produces a sourced report. `pytest evals/ -m "not slow"` passes. Agent handles tool failures, stops at cost ceiling, detects stuck loops.

## Phase 2: RAG Layer + Tests
- [ ] providers/embeddings.py — nomic-embed-text-v2 via sentence-transformers (configurable model) *(depends: protocols.py)*
- [ ] providers/vectordb.py — ChromaDB implementation of VectorStore protocol, with try/except for corruption recovery *(depends: protocols.py)*
  - [ ] test: store/retrieve round-trip, metadata filters, corruption degrades gracefully
- [ ] rag.py — RAG orchestration with metadata filters and domain config *(depends: embeddings.py, vectordb.py)*
- [ ] store_finding + retrieve_context tools *(depends: rag.py, tools.py)*
  - [ ] test: findings stored and retrieved, retrieval is semantically relevant
- [ ] Post-processing: auto-extract findings agent didn't explicitly save
- [ ] Batch embeddings after agent loop (not one-at-a-time)

**Exit criteria:** Sequential queries build on past research. ChromaDB corruption degrades gracefully. `pytest evals/` passes.

## Phase 3: Structured Outputs + Report Quality
- [ ] output_config.format integration with ResearchReport model
- [ ] Confidence scoring and source credibility assessment
- [ ] Prompt caching for system prompt + tool definitions (90% discount)
- [ ] Polished Markdown export with tables, citations, confidence levels

**Exit criteria:** Reports are valid Pydantic objects, exported as polished Markdown. Prompt caching reduces cost measurably.

## Phase 4: Advanced Evals (DeepEval + Quality Metrics)
- [ ] DeepEval integration — hallucination, faithfulness, answer relevancy metrics (mark as `@pytest.mark.slow`)
- [ ] End-to-end agent eval — full research run produces quality report
- [ ] Eval dashboard — track quality metrics over time

**Exit criteria:** `pytest evals/` passes all tests. Quality metrics baselined for regression detection.

## Phase 5: Finance Domain
- [ ] domains/finance.py — DomainConfig with finance prompt, tools, RAG config (recency boost, 90-day TTL, entity+date metadata)
- [ ] search_sec_filings tool (SEC EDGAR) *(depends: tools.py)*
- [ ] get_financial_data tool (yfinance) *(depends: tools.py)*
- [ ] search_earnings tool *(depends: tools.py, providers/search.py)*
- [ ] Finance-specific report model extending ResearchReport
- [ ] Finance-specific evals (data accuracy, source appropriateness, recency)

**Exit criteria:** `research --domain finance "Analyze NVIDIA's competitive position"` cites SEC filings, financial data, earnings.

## Phase 6: Polish + MCP + Commercialization Prep
- [ ] Multiple output formats (Markdown, JSON)
- [ ] Research history browser (`research --history`, `research --clear-data`)
- [ ] Domain switching via CLI (`--domain general|finance`)
- [ ] Expose core tools as MCP servers
- [ ] `research --rebuild-index` for ChromaDB recovery
- [ ] Evaluate Claude Agent SDK for multi-agent expansion

## Done
- [x] Project brief — docs/PROJECT-BRIEF.md (2026-03-28)
- [x] Domain research — docs/research/agentic-research-app/ (2026-03-28)
- [x] Implementation plan — docs/plan/PLAN.md (2026-03-28)
- [x] Architecture review — docs/plan/REVIEW.md (2026-03-28)
- [x] Project scaffold — CLAUDE.md, settings.json, agents.md, skills (2026-03-28)
- [x] Scaffold review + fixes (2026-03-28)

## Notes
- **TDD is non-negotiable:** Write failing tests alongside each module, not deferred to a later phase
- **Task dependencies** are noted in parentheses — build in the listed order
- Finance niche first, then repurpose for real estate and AI dev via DomainConfig swap
- All safeguards (context mgmt, loop detection, cost tracking, prompt injection) are Phase 1 requirements
- Use `output_config.format` (NOT deprecated `output_format`), `effort` param (NOT `budget_tokens`)
- Mark expensive tests (DeepEval, real API calls) with `@pytest.mark.slow` — the PostToolUse hook skips these
