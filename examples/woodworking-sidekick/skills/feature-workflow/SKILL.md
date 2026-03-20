---
name: feature-workflow
description: TDD workflow for developing features in Woodworking Sidekick. MUST be used for every new feature, bug fix, or enhancement. Enforces test-first development.
---

# Feature Development Workflow

Follow these steps for every new feature in Woodworking Sidekick.

## 1. Plan
- Read the feature requirements (check docs/TASKS.md and docs/plan/PLAN.md)
- Use Plan Mode to outline the approach
- Identify which modules will be affected (app/, lib/, components/, types/)
- List edge cases: invalid LLM output, validation failures, empty tool profiles, auth edge cases
- For plan generation features: identify which golden path projects to test against

## 2. Test First
- Write failing tests in the corresponding `tests/` directory
- For API routes: test request validation, response schema, error states
- For validation: test dimensional checks, board feet math, joinery-tool compatibility, wood movement rules
- For UI components: use React Testing Library for interaction tests
- For LLM integration: mock Gemini responses, test Zod schema validation on outputs
- For e2e: Playwright tests for critical user flows (generate plan, adjust plan, chat)
- Run tests to confirm they fail: `npm test`

**If you find yourself writing implementation code without failing tests, STOP. Go back to this step.**

## 3. Implement
- Write minimum code to pass tests
- Follow patterns in CLAUDE.md: Server Components by default, Zod for validation, prompts in `lib/prompts/`
- For plan generation: use `streamText` via Vercel AI SDK, parse response into WoodworkingPlan schema
- For validation: add rules to `lib/validation/`, ensure re-generation on failure
- For chat: use `useChat` hook, inject plan JSON as system context
- For UI: use shadcn/ui components, keep under 150 lines per component

## 4. Verify
- Run full test suite: `npm test`
- Run type check: `npx tsc --noEmit`
- Run linter: `npx prettier --write . && npx eslint --fix .`
- Check coverage on new module: aim for 80%+
- For plan generation changes: test against all golden path projects (bookshelf, end table, cutting board, workbench, floating shelves)

## 5. Integration Check
- For API routes: test with real Gemini API on a sample input
- For validation: verify against manually checked plan dimensions
- For UI: check responsive design on mobile
- For e2e: run Playwright: `npx playwright test`
- Update docs/TASKS.md to mark the feature complete

## 6. Clean Up
- Refactor while tests stay green
- Ensure no hardcoded values (API URLs, model names should be in config)
- Update docs/ARCHITECTURE.md if this changes data flow

## Why This Order Matters
AI-generated code has 45% security flaw rate. TDD catches these because:
- Tests define expected behavior BEFORE the AI generates code
- The plan validation layer ensures dimensional accuracy — wrong dimensions mean wasted wood
- Regressions are caught immediately by the auto-test hook
- Teams using TDD + AI see 40-90% fewer defects vs. AI-only development
