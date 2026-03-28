# Tasks

## Phase 1: Foundation
- [ ] config.py + models.py + providers/protocols.py — Core types and config
- [ ] providers/search.py + tool_impl.py — Search and page reading (with tests)
- [ ] agent.py — ReAct loop with safeguards (with tests for loop detection, cost ceiling)
- [ ] streaming.py + cli.py + session.py + report.py — Wire it all together

**Done when:** `python -m src.cli "What are the top AI agent frameworks?"` produces a sourced report. Fast tests pass.

## Phase 2: RAG
- [ ] providers/embeddings.py + providers/vectordb.py — Local embeddings + ChromaDB (with tests)
- [ ] rag.py + store/retrieve tools — Domain-aware retrieval, batch embeddings

**Done when:** Sequential queries build on past research. Corruption degrades gracefully.

## Phase 3: Structured Outputs
- [ ] output_config.format + prompt caching + polished Markdown export

## Phase 4: Advanced Evals
- [ ] DeepEval metrics (hallucination, faithfulness) — mark `@pytest.mark.slow`

## Phase 5: Finance Domain
- [ ] domains/finance.py + SEC EDGAR + yfinance + earnings tools (with evals)

## Phase 6: Polish + MCP
- [ ] Output formats, history browser, MCP servers, Agent SDK evaluation

## Done
- [x] Brief, research, plan, review, scaffold (2026-03-28)

## Notes
- Write tests alongside each module — hooks auto-run them after every edit
- Build order within Phase 1: config → models → protocols → search → tools → agent → streaming → CLI
- `output_config.format` not `output_format` | `effort` not `budget_tokens`
