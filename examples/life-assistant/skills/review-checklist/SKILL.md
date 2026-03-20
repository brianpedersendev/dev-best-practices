---
name: review-checklist
description: Code review checklist for Life Assistant (LifeOS). Use when reviewing any code changes, PRs, or before committing.
---

# Code Review Checklist

## Correctness
- [ ] Logic handles edge cases (empty arrays, null values, missing fields)
- [ ] Error paths return appropriate HTTP status / MCP error codes
- [ ] No hardcoded values that should be configurable
- [ ] Model routing correct: Haiku for CRUD/tools, Sonnet for coaching/reasoning

## Security & Privacy
- [ ] No secrets or credentials in code
- [ ] All external input validated with Zod schemas
- [ ] Parameterized SQL queries only — no template literal SQL
- [ ] Privacy tiers respected: cross-domain reads go through summary functions
- [ ] Auth checks on all protected routes/endpoints

## MCP Server Standards
- [ ] Tools follow the packages/mcp-{domain}/ structure
- [ ] Tool inputs validated with Zod
- [ ] Primary keys use nanoid (not auto-increment)
- [ ] SQLite queries use parameterized statements
- [ ] Resources and prompts follow naming conventions

## Testing
- [ ] Tests exist for new/changed MCP tools
- [ ] Tests cover error cases and edge cases
- [ ] MCP tools tested against in-memory SQLite
- [ ] UI components tested with mocked MCP responses
- [ ] All tests pass: `npx vitest run`

## Style
- [ ] TypeScript strict mode — no `any` types without justification
- [ ] Functions under 50 lines, files under 300 lines
- [ ] Immutable patterns: new objects returned, not mutated
- [ ] Structured logging via pino — no console.log
- [ ] Prettier formatting applied

## Performance
- [ ] No unnecessary re-renders in React components
- [ ] SQLite queries efficient (indexed columns in WHERE clauses)
- [ ] Nudge fatigue limits respected (3/day, 48hr cooldown)
- [ ] Haiku used for all high-frequency operations (not Sonnet)
