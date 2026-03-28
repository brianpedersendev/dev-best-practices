---
name: review-checklist
description: Code review checklist for the Agentic Research App. Use when reviewing code changes or before committing.
---

# Code Review Checklist

## This Project's Patterns (the stuff that's easy to miss)
- [ ] Web content wrapped in `<retrieved_content>` tags (prompt injection protection)
- [ ] All stop_reason values handled: `end_turn`, `tool_use`, `max_tokens`
- [ ] New providers implement their Protocol (SearchProvider, EmbeddingProvider, VectorStore)
- [ ] Tool failures return `is_error: True` results (keep the loop running)
- [ ] Page reads rate-limited: 1 req/sec/domain, max 5 concurrent
- [ ] ChromaDB operations wrapped in try/except with graceful degradation
- [ ] Uses `output_config.format` (NOT deprecated `output_format`)
- [ ] Uses `effort` parameter (NOT deprecated `budget_tokens`)
- [ ] No hardcoded model names — use config.model

## Standard Checks
- [ ] Tests exist for new/changed behavior
- [ ] No secrets in code (hook blocks these, but check anyway)
- [ ] All tests pass: `python -m pytest evals/ --tb=short -q`
