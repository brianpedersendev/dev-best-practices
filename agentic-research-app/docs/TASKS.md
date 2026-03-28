# Tasks

## Phase 1: Foundation (Core Agent Loop + Safeguards)

### In Progress
- [ ] Set up project — pyproject.toml, .env.example, .gitignore

### Up Next
- [ ] config.py — Settings via pydantic-settings (model, max iterations, cost ceiling, context budget)
- [ ] models.py — Pydantic models (SearchResult, PageContent, Finding, ResearchReport, DomainConfig, RunMetrics)
- [ ] providers/protocols.py — SearchProvider, EmbeddingProvider, VectorStore protocols
- [ ] providers/search.py — Tavily (primary) + Brave (fallback) implementations
- [ ] tools.py — Tool schema definitions + registry
- [ ] tool_impl.py — web_search + read_page with error handling, rate limiting, content sandboxing
- [ ] agent.py — ReAct loop with ContextManager, LoopGuard, retry/backoff, stop_reason handling
- [ ] streaming.py — Rich console output (thinking, tool calls, progress, running cost)
- [ ] session.py — Lifecycle: parse query → resolve domain → run agent → save report → write log
- [ ] cli.py — Entry point: `python -m src.cli "your question"`
- [ ] report.py — Markdown report from ResearchContext (not raw messages)

## Phase 2: RAG Layer
- [ ] providers/embeddings.py — nomic-embed-text-v2 via sentence-transformers
- [ ] providers/vectordb.py — ChromaDB implementation of VectorStore protocol
- [ ] rag.py — RAG orchestration with metadata filters and domain config
- [ ] store_finding + retrieve_context tools
- [ ] Post-processing: auto-extract findings agent didn't explicitly save

## Phase 3: Structured Outputs + Report Quality
- [ ] output_config.format integration with ResearchReport model
- [ ] Confidence scoring and source credibility assessment
- [ ] Prompt caching for system prompt + tool definitions
- [ ] Polished Markdown export with tables, citations, confidence levels

## Phase 4: Evals
- [ ] test_tools.py — Tool execution, error handling, search fallback
- [ ] test_rag.py — Store/retrieve, metadata filters, corruption recovery
- [ ] test_agent.py — Loop detection, cost ceiling, context summarization
- [ ] test_report.py — Structure, sources, confidence
- [ ] DeepEval metrics — hallucination, faithfulness, answer relevancy

## Phase 5: Finance Domain
- [ ] domains/finance.py — DomainConfig with finance prompt, tools, RAG config
- [ ] search_sec_filings tool (SEC EDGAR)
- [ ] get_financial_data tool (yfinance)
- [ ] search_earnings tool
- [ ] Finance-specific report model and evals

## Done
- [x] Project brief — docs/PROJECT-BRIEF.md (2026-03-28)
- [x] Domain research — docs/research/agentic-research-app/ (2026-03-28)
- [x] Implementation plan — docs/plan/PLAN.md (2026-03-28)
- [x] Architecture review — docs/plan/REVIEW.md (2026-03-28)
- [x] Project scaffold — CLAUDE.md, settings.json, agents.md, skills (2026-03-28)

## Notes
- Finance niche first, then repurpose for real estate and AI dev via DomainConfig swap
- All safeguards (context mgmt, loop detection, cost tracking, prompt injection) are Phase 1 requirements
- Use `output_config.format` (NOT deprecated `output_format`), `effort` param (NOT `budget_tokens`)
