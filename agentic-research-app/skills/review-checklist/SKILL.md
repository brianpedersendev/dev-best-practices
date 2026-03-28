---
name: review-checklist
description: Code review checklist for the Agentic Research App. Use when reviewing any code changes, PRs, or before committing.
---

# Code Review Checklist

## Correctness
- [ ] Logic handles edge cases (empty results, timeouts, malformed data)
- [ ] Error paths return structured errors to Claude (keep the loop running)
- [ ] All stop_reason values handled: `end_turn`, `tool_use`, `max_tokens`
- [ ] No hardcoded model names — use config.model
- [ ] No hardcoded API keys — use pydantic-settings

## Security
- [ ] No secrets or credentials in code (PreToolUse hook blocks these)
- [ ] Web content wrapped in `<retrieved_content>` tags (prompt injection protection)
- [ ] No user-controlled strings interpolated into system prompts
- [ ] Financial research output includes "Not financial advice" disclaimer

## Agent Safeguards
- [ ] Context manager counts tokens and summarizes when over budget
- [ ] Loop guard detects repeated tool calls and enforces cost ceiling
- [ ] All external API calls have retry + exponential backoff
- [ ] Tool failures return `is_error: True` results (not exceptions)
- [ ] Page reads rate-limited: 1 req/sec/domain, max 5 concurrent
- [ ] ChromaDB operations wrapped in try/except with graceful degradation

## Provider Protocol Compliance
- [ ] New providers implement the correct Protocol (SearchProvider, EmbeddingProvider, VectorStore)
- [ ] Provider implementations are injected via config, not hardcoded
- [ ] Fallback chain works when primary provider fails

## Testing
- [ ] Tests exist for new/changed behavior (in evals/)
- [ ] Tests cover error cases and edge cases
- [ ] All tests pass: `python -m pytest evals/ --tb=short -q`
- [ ] Mocks are used for external APIs, not for Pydantic validation
- [ ] Expensive tests (DeepEval, real API calls) marked with `@pytest.mark.slow`

## API Patterns
- [ ] Uses `output_config.format` (NOT deprecated `output_format`)
- [ ] Uses `effort` parameter (NOT deprecated `budget_tokens`)
- [ ] Prompt caching enabled for system prompt + tool definitions

## Style
- [ ] Type hints on all function signatures
- [ ] Pydantic BaseModel for data crossing module boundaries
- [ ] Functions under 50 lines
- [ ] Imports ordered: stdlib → third-party → local
- [ ] Formatted with black
