---
name: feature-workflow
description: TDD workflow for developing features in the Agentic Research App. MUST be used for every new feature, bug fix, or enhancement. Enforces test-first development.
---

# Feature Development Workflow (TDD)

**Every feature follows this exact sequence. No exceptions. Do not skip step 2.**

## 1. Plan (Use Plan Mode)
- Read the feature requirements or task description
- Use Plan Mode (do NOT start coding yet) to:
  - Outline the approach and identify affected modules
  - List the test cases you'll write (happy path, error cases, edge cases)
  - Identify what to mock (Tavily API, Claude API, httpx responses) and what to test with real implementations (Pydantic validation, tool registry, domain config)
  - Check if this touches a provider protocol — if so, verify the Protocol interface first
  - Estimate scope — if more than ~200 lines of changes, break into smaller tasks
- Get approval before proceeding

## 2. Write Failing Tests FIRST (This Is The Critical Step)
- Create or update test files in `evals/` BEFORE touching any implementation code
- Write tests that define the expected behavior:
  - Happy path: the main success case
  - Error cases: API failures, malformed responses, timeouts
  - Edge cases: empty results, very long content, rate limit hit
  - Security: prompt injection in web content handled correctly
- Run the tests: `python -m pytest evals/ --tb=short -q`
- **They MUST fail.** If they pass, your tests aren't testing the new behavior.

**If you find yourself writing implementation code without failing tests, STOP. Go back to this step.**

## 3. Implement (Minimum Code to Pass Tests)
- Write the simplest code that makes the failing tests pass
- Follow patterns in CLAUDE.md:
  - Use Protocol for external deps
  - Wrap API calls with retry + backoff
  - Return structured errors on tool failures
  - Sandbox web content in `<retrieved_content>` tags
- The PostToolUse hook auto-runs tests after every edit — watch the feedback
- Keep going until all tests pass

## 4. Verify
- Run the FULL test suite: `python -m pytest evals/ --tb=short -q`
- Check for regressions in other modules
- Review against original requirements
- If any test fails, fix before proceeding

## 5. Refactor (Tests Must Stay Green)
- Clean up while tests continue passing
- Extract functions, improve naming, remove duplication
- Run formatter: `black . --quiet`
- Run full test suite one final time

## Why This Order Matters
AI-generated code has 45% security flaw rate. TDD catches these because:
- Tests define expected behavior BEFORE the AI generates code
- The AI generates code to match YOUR specification (tests), not its assumptions
- Regressions are caught immediately by the auto-test hook
- Teams using TDD + AI see 40-90% fewer defects vs. AI-only development
