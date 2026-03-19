# Agent Team: Fishing Copilot

## Development Agents

### Lead Agent
- **Role:** Coordinates work, reviews plans, ensures consistency across the pipeline
- **When to use:** Feature planning, architecture decisions, complex debugging, pipeline design changes
- **Mode:** Plan Mode → approval → execution

### Coder Agent (Subagent)
- **Role:** Implements features, writes code following TDD
- **When to use:** Spawned by lead for focused implementation tasks
- **Scope:** One module at a time (e.g., a single collector, scraper, or LLM pipeline step), includes tests
- **Key rule:** Always write tests first, then implementation

### Reviewer Agent (Subagent)
- **Role:** Reviews code independently of the coder
- **When to use:** After implementation, before committing
- **Scope:** Security (no secrets, parameterized SQL), performance (API rate limits, batch efficiency), style (CLAUDE.md conformance)
- **Key rule:** Reviewer has NO knowledge of coder's decisions — adversarial by design

### Data Pipeline Agent (Subagent)
- **Role:** Specializes in API integration, scraping, and data quality
- **When to use:** Building or debugging collectors and scrapers, data validation issues, API response handling
- **Scope:** Everything in `collectors/` and `scrapers/`, data model changes
- **MCP:** SQLite MCP for direct database inspection

### LLM Pipeline Agent (Subagent)
- **Role:** Specializes in prompt engineering, extraction quality, synthesis tuning
- **When to use:** Writing or refining prompts, evaluating extraction accuracy, tuning briefing quality
- **Scope:** Everything in `llm/`, prompt templates, output validation
- **Key rule:** Always test prompts against saved fixtures before deploying

## Parallel Work Opportunities

These tasks can be parallelized across agents:
- **Collectors are independent:** USGS, USBR, NWS, Open-Meteo, USNO collectors can be built simultaneously
- **Scrapers are independent:** Wyoming and Idaho scrapers have no dependencies on each other
- **Extraction vs. synthesis:** Extraction prompt engineering can happen in parallel with synthesis prompt engineering
- **Tests vs. implementation:** Test fixtures can be prepared while implementation is in progress

## Context Management Rules
- **Session splitting:** Use separate sessions for planning, implementation, and testing. Clear context between phases.
- **Handoff via files:** Agents pass knowledge through docs/TASKS.md and docs/ARCHITECTURE.md, not conversation history.
- **Monitor usage:** Compact at 60% context capacity. PreCompact hook preserves critical project context.
- **Subagent scoping:** Each subagent gets only the files it needs. The Data Pipeline Agent doesn't need LLM code, and vice versa.
- **Fixture management:** Save real API responses and HTML pages as test fixtures in `tests/fixtures/`. These serve as documentation AND test data.
