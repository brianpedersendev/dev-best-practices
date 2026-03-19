---
name: feature-workflow
description: Step-by-step workflow for developing a new feature in Fishing Copilot. Use when starting any new collector, scraper, LLM pipeline step, or delivery feature.
---

# Feature Development Workflow

Follow these steps for every new feature in Fishing Copilot.

## 1. Plan
- Read the feature requirements (check docs/TASKS.md and docs/plan/PLAN.md)
- Use Plan Mode to outline the approach
- Identify which modules will be affected
- Check API integration details in PLAN.md Section 6 for exact endpoints and response formats
- List edge cases: API timeouts, empty responses, malformed data, rate limits

## 2. Test First
- Write failing tests in the corresponding `tests/test_{module}/` directory
- Use `responses` library to mock HTTP calls with saved fixtures
- Cover: happy path, error cases (timeouts, 4xx, 5xx), edge cases (empty data, sentinel values)
- For scrapers: save real HTML pages as fixtures in `tests/fixtures/`
- For LLM: mock Anthropic client, test JSON schema validation on outputs
- Run tests to confirm they fail: `uv run python -m pytest tests/test_{module}/ -v`

## 3. Implement
- Write minimum code to pass tests
- Follow patterns in CLAUDE.md: frozen dataclasses, parameterized SQL, structured logging
- For collectors: extend `collectors/base.py` with retry logic and rate limiting
- For scrapers: extend `scrapers/base.py` with content hashing and change detection
- For LLM steps: add prompt templates to `llm/prompts.py` as constants

## 4. Verify
- Run full test suite: `uv run python -m pytest --tb=short -q`
- Run linter: `uv run ruff check --fix . && uv run ruff format .`
- Check coverage on the new module: `uv run python -m pytest --cov=src/fishing_copilot/{module} --cov-report=term-missing`
- Verify 80%+ coverage

## 5. Integration Check
- For collectors: run against real API once (`@pytest.mark.integration` test)
- For scrapers: run against real website once, save fresh fixture
- For LLM: run with real Anthropic API on a sample input, verify output quality
- Update docs/TASKS.md to mark the feature complete

## 6. Clean Up
- Refactor while tests stay green
- Ensure no hardcoded values (URLs, site codes, API params should be in config.py)
- Update docs/ARCHITECTURE.md if this changes data flow
