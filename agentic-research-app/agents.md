# Agent Team: Agentic Research App

## How You'll Actually Work (Solo Dev)

Most of the time, you're the lead agent — planning, implementing, and testing in one session. Use these specialized modes when they add value:

### Review Mode
After implementing a feature, open a **separate Claude Code session** and ask it to review the changed files. Don't share the implementation conversation — the reviewer should judge the code cold, like a real code review.
- Use Sonnet or Haiku (code review doesn't need Opus)
- Focus: security, error handling, protocol compliance, content sandboxing

### Debug Mode
When something's broken in the agent loop:
1. Write a minimal test that reproduces the bug
2. Use Plan Mode to form hypotheses
3. Fix with TDD (failing test first)

## Context Management
- Use `/clear` between unrelated tasks, `/compact` at 60% context
- Store decisions in docs/ — they survive across sessions
- The PreCompact hook preserves critical project context automatically
