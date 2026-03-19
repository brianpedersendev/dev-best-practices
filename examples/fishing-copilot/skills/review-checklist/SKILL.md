---
name: review-checklist
description: Code review checklist for Fishing Copilot. Use when reviewing code changes, before committing, or after implementing a feature.
---

# Code Review Checklist

## Correctness
- [ ] API response validation: status codes checked, content types verified, sentinel values handled
- [ ] Edge cases covered: empty responses, timeouts, malformed data, API rate limits
- [ ] Dedup logic: content hashing prevents reprocessing unchanged reports
- [ ] Graceful degradation: pipeline continues when individual data sources fail
- [ ] LLM output validated against expected JSON schema

## Security
- [ ] No secrets or credentials in code (API keys, phone numbers, tokens)
- [ ] All SQL uses parameterized queries — no f-string SQL anywhere
- [ ] External data validated before storage (API responses, scraped HTML)
- [ ] No user input passed to shell commands or SQL without sanitization

## Data Quality
- [ ] Timestamps stored consistently (UTC in database, local time only for display)
- [ ] Nullable fields handled correctly (USGS sites may lack water temp, reservoirs may lack data)
- [ ] Content hash uniqueness constraint prevents duplicate raw reports
- [ ] Stale data detected and flagged (compare fetch time to report date)

## Testing
- [ ] Tests exist for new/changed behavior
- [ ] Tests cover error cases (timeouts, bad responses, API down)
- [ ] HTTP calls mocked with `responses` library — no real API calls in unit tests
- [ ] Scraper tests use saved HTML fixtures
- [ ] LLM tests validate JSON schema conformance
- [ ] All tests pass: `uv run python -m pytest --tb=short -q`
- [ ] Coverage 80%+ on changed modules

## Style
- [ ] Follows CLAUDE.md conventions (frozen dataclasses, type hints, structured logging)
- [ ] Functions under 50 lines, files under 400 lines
- [ ] No print statements — use logging
- [ ] Prompt templates in `llm/prompts.py`, not inline strings
- [ ] Ruff passes: `uv run ruff check . && uv run ruff format --check .`

## Pipeline
- [ ] New data source integrated into `main.py` orchestrator
- [ ] Pipeline run logging covers the new step (pipeline_runs table)
- [ ] Failure of new step doesn't crash the entire pipeline
- [ ] SMS alert configured for repeated failures (3+ consecutive)

## Performance
- [ ] API calls batched where possible (USGS supports multi-site queries)
- [ ] Rate limiting respected (1 req/sec for USBR, reasonable for all others)
- [ ] Content hash check runs BEFORE expensive LLM calls
- [ ] Pipeline completes within GitHub Actions 10-minute window
