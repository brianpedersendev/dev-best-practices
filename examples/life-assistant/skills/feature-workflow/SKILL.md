---
name: feature-workflow
description: TDD workflow for developing features in Life Assistant (LifeOS). MUST be used for every new feature, bug fix, or enhancement. Enforces test-first development.
---

# Feature Development Workflow (TDD)

**Every feature follows this exact sequence. No exceptions. Do not skip step 2.**

## 1. Plan (Use Plan Mode)
- Read the feature requirements or task description
- Use Plan Mode (do NOT start coding yet) to:
  - Outline the approach and identify affected packages (apps/web, packages/mcp-*, packages/shared)
  - List the test cases you'll write (happy path, error cases, edge cases, boundary conditions)
  - Identify what to mock (MCP server responses in UI tests, external APIs)
  - Decide model routing: Haiku for tools/CRUD, Sonnet for coaching/reasoning
- Get approval before proceeding

## 2. Write Failing Tests FIRST (This Is The Critical Step)
- Create or update test files BEFORE touching any implementation code
- For MCP server tools: write tests that exercise the tool against in-memory SQLite
- For UI components: write tests with React Testing Library mocking MCP responses
- Run tests: `npx vitest run`. **They MUST fail.** If they pass, your tests aren't testing new behavior.

**If you find yourself writing implementation code without failing tests, STOP. Go back to this step.**

## 3. Implement (MCP Server First, Then UI)
- For features touching MCP servers: build and test server tools FIRST
- Only build UI after the MCP layer is tested and passing
- Write the simplest code that makes failing tests pass
- Follow patterns in CLAUDE.md (Zod validation, nanoid keys, parameterized SQL, structured logging)
- The PostToolUse hook auto-runs vitest after every edit — watch the feedback

## 4. Verify
- Run the FULL test suite: `npx vitest run`
- Check for regressions across packages (Turborepo runs all)
- Review against original requirements
- Verify model routing: Haiku for data ops, Sonnet for reasoning

## 5. Refactor (Tests Must Stay Green)
- Clean up while tests pass
- Extract shared types to packages/shared if reused across domains
- Run prettier: `npx prettier --write .`
- Run full test suite one final time

## Why This Order Matters
- MCP-first development ensures the data layer works before building UI on top
- TDD catches the 45% security flaw rate in AI-generated code
- Auto-test hooks give immediate regression feedback
- Each domain server must be independently testable
