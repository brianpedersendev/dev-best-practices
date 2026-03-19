# Life Assistant (LifeOS)

## What This Is
A modular AI-powered personal life assistant with plug-and-play domain modules. Each life domain (career, finance, fitness, hobbies) is an independent MCP server. The Next.js app acts as the MCP host, orchestrating cross-domain reasoning, memory, and a hybrid dashboard + chat + nudge UI.

## Tech Stack
- **Framework:** Next.js 15 (App Router) with Vercel AI SDK 4.x
- **LLM:** Claude Sonnet 4.6 (coaching/reasoning) + Haiku 4.5 (tools/nudges)
- **MCP:** `@modelcontextprotocol/sdk` — one server per domain
- **Database:** SQLite via `better-sqlite3` (one DB per domain)
- **Styling:** Tailwind CSS + shadcn/ui
- **Auth:** Auth.js v5 (magic link)
- **Monorepo:** Turborepo
- **Testing:** Vitest + React Testing Library
- **Hosting:** Vercel (free tier)

## Project Structure
```
apps/web/           # Next.js app (MCP host + UI)
packages/
├── mcp-career/     # Career + Goals MCP server
├── mcp-finance/    # Finance MCP server (MVP 2)
├── mcp-fitness/    # Fitness MCP server (MVP 3)
├── mcp-hobbies/    # Hobbies MCP server (MVP 4)
└── shared/         # Shared types, memory utils, privacy helpers
```

## Coding Standards
- Use TypeScript strict mode everywhere
- Use `nanoid` for all primary keys (not auto-increment integers)
- Use parameterized SQL queries exclusively — never template literal SQL
- Keep functions under 50 lines, files under 300 lines
- Use immutable patterns: return new objects, never mutate arguments
- Store all prompt templates in `prompts/` directories within each MCP server
- Use Zod for all external input validation (API routes, MCP tool inputs)
- Handle errors explicitly — never silently swallow exceptions
- Use structured logging via `pino` — no console.log in production code

## MCP Server Pattern
Each domain MCP server follows the same structure:
```
packages/mcp-{domain}/
├── src/
│   ├── server.ts        # MCP server entry point
│   ├── tools/           # Tool definitions (one file per tool group)
│   ├── resources/       # Resource providers (one file per resource)
│   ├── prompts/         # Prompt templates for domain-specific coaching
│   └── db/
│       ├── schema.sql   # SQLite schema
│       ├── connection.ts # DB connection manager
│       └── queries.ts   # Typed query functions
├── tests/
└── package.json
```

## Model Routing
- **Haiku 4.5:** All MCP tool calls (CRUD), nudge generation, classification, quick queries
- **Sonnet 4.6:** Career coaching conversations, goal decomposition, cross-domain reasoning, weekly reviews
- **Rule:** If the task is "look up data" or "log something," use Haiku. If the task requires "think about this" or "coach me," use Sonnet.

## Testing
- Framework: Vitest with React Testing Library
- Write tests alongside implementation (not TDD-strict, but tests for every MCP tool)
- Mock MCP server responses in UI tests
- Test MCP tools against in-memory SQLite
- Coverage target: 80%+ on MCP servers, 60%+ on UI components
- Tag integration tests: `describe.skip` for tests requiring live API calls

## Workflow
1. Plan in Plan Mode before implementing any feature
2. Implement MCP server tools first, then UI
3. Test MCP tools independently before wiring to UI
4. Run full test suite + lint before committing
5. Deploy to Vercel after each phase milestone

## Context Management
- Use /clear between unrelated tasks
- Use /compact at 60% context
- Split sessions by domain: career server → finance server → etc.
- Store decisions in docs/ directory

## Key Patterns
- **MCP-first development:** Build the MCP server tools, test them, then build UI that calls them. Never build UI without the MCP layer.
- **Cross-domain via context assembly:** When the AI needs to reason across domains, query each MCP server for a summary and include all summaries in the prompt.
- **Privacy by architecture:** Each domain server owns its data. Cross-domain reads go through summary functions that can enforce privacy tiers.
- **Nudge fatigue prevention:** Max 3 nudges/day, 48-hour cooldown per topic, user can snooze/dismiss.

## Avoid
- Don't use an ORM — raw SQL with `better-sqlite3` and typed query functions
- Don't use a component library other than shadcn/ui (no MUI, Chakra, etc.)
- Don't build integrations (Plaid, Apple Health) until the manual-input MVP is validated
- Don't use Opus for any automated calls — cost prohibitive for a personal tool
- Don't add domains ahead of schedule — each must be independently useful first
