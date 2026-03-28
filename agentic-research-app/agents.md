# Agent Team: Agentic Research App

## Development Agents

### Lead Agent
- **Role:** Coordinates work, reviews plans, ensures consistency across modules
- **When to use:** Feature planning, architecture decisions, complex debugging, cross-module changes
- **Mode:** Plan Mode → approval → execution
- **Key files:** CLAUDE.md, docs/TASKS.md, docs/ARCHITECTURE.md

### Coder Agent (Subagent)
- **Role:** Implements features, writes code following TDD workflow
- **When to use:** Spawned by lead for focused implementation tasks
- **Scope:** One module or feature at a time, includes tests
- **Key rule:** Always follow the feature-workflow skill (test-first, no exceptions)

### Reviewer Agent (Subagent)
- **Role:** Reviews code independently of the coder
- **When to use:** After implementation, before committing
- **Scope:** Security (prompt injection, API key exposure), error handling (tool failures, loop detection), cost efficiency (token usage, unnecessary API calls), architecture conformance (protocols used correctly, domain config pattern followed)
- **Key rule:** Reviewer has NO knowledge of coder's decisions — adversarial by design. Run in a separate Claude Code session, sharing only changed files, not the implementation conversation
- **Model:** Use Sonnet or Haiku (code review doesn't need Opus-level reasoning)

### Integration Agent (Subagent)
- **Role:** External API integrations — Tavily, Brave, SEC EDGAR, Yahoo Finance
- **When to use:** Adding or modifying provider implementations
- **Scope:** Provider protocol compliance, error handling, rate limiting, fallback chains
- **Key rule:** Every provider must implement its Protocol. Every API call must have retry + backoff.

## Context Management Rules
- **Session splitting:** Separate sessions for planning, implementation, and testing. Clear context between phases.
- **Handoff via files:** Agents pass knowledge through docs/ files (TASKS.md, ARCHITECTURE.md), not conversation history.
- **Monitor usage:** Use verbose mode (Ctrl+O) to track context consumption. Compact at 60% capacity.
- **Subagent scoping:** Each subagent gets only the files and context it needs — don't load the entire codebase.
- **Memory persistence:** Store key decisions and learnings in docs/ so future sessions pick up without re-deriving.
- **Cost awareness:** Track token usage per session. The PreCompact hook preserves critical context during compression.
