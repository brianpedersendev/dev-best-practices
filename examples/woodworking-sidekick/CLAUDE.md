# Woodworking Sidekick

## What This Is
An AI-powered web app that turns a woodworking project idea into a complete, hobbyist-friendly build plan with cut lists, material estimates, joinery recommendations, and step-by-step instructions — tailored to the user's tools and skill level. Includes an AI chat assistant that stays with you through the entire build. Built for intermediate hobbyist woodworkers (15-20M in the US) who want to graduate from napkin sketches to real plans.

## Tech Stack
- **Framework:** Next.js 15 (App Router, Server Components)
- **Language:** TypeScript (strict mode)
- **AI SDK:** Vercel AI SDK (`ai` package) — unified streaming, `useChat`, model-swappable
- **Primary LLM:** Google Gemini 2.0 Flash/Pro via Vercel AI SDK
- **Database:** Supabase (Postgres + Auth + RLS)
- **Styling:** Tailwind CSS + shadcn/ui
- **Validation:** Zod (LLM output schemas + API input validation)
- **Deployment:** Vercel
- **Testing:** Vitest + React Testing Library + Playwright (e2e)
- **Formatting:** Prettier + ESLint

## Project Structure
```
app/                    # Next.js App Router pages and layouts
  (auth)/               # Auth pages (sign-in, sign-up)
  dashboard/            # User's project list
  project/[id]/         # Project detail + plan display + chat
  api/                  # Route handlers (generate-plan, chat)
components/             # Reusable UI components (shadcn/ui based)
lib/                    # Utilities, Supabase client, AI config
  prompts/              # System prompt templates for plan gen + chat
  validation/           # Zod schemas + woodworking validation rules
types/                  # Shared TypeScript types (WoodworkingPlan, etc.)
tests/                  # Test files mirroring source structure
```

## Coding Standards
- Use App Router conventions (app/ directory, page.tsx, layout.tsx)
- Prefer Server Components by default; add "use client" only when interactive
- Use TypeScript strict mode — no `any` types without justification
- Use Zod for all external data validation (API inputs, LLM outputs)
- Handle errors with error.tsx boundaries and explicit error states
- Keep components under 150 lines; extract when larger
- Store all LLM prompt templates in `lib/prompts/` as constants
- Use Supabase RLS for all data access — never bypass with service key in client code
- Use `streamText` for plan generation UX; parse completed response into Zod schema
- Validate every generated plan through `lib/validation/` before displaying

## Development Workflow (TDD — Non-Negotiable)
1. **Plan** — Use Plan Mode. Outline approach, identify affected modules, list edge cases. Get approval.
2. **Write failing tests FIRST** — Define expected behavior as tests. Run them. Confirm they fail.
3. **Implement minimum code to pass tests** — Follow patterns in this file.
4. **Verify** — Run full test suite. Check for regressions.
5. **Refactor** — Clean up while tests stay green. Run formatter.

## Testing
- Framework: Vitest + React Testing Library (unit/component), Playwright (e2e)
- Naming: `describe("what it does")` not `describe("functionName")`
- Location: `tests/` mirroring source structure
- Coverage target: 80%+ for new code
- Always mock: Gemini API calls, Supabase queries in unit tests
- Never mock: Zod validation, woodworking dimension validation logic
- Run: `npm test` (unit) / `npx playwright test` (e2e)

## Context Management
- Use /clear between unrelated tasks; /compact at 60% context capacity
- Split sessions by phase: planning → implementation → testing
- Store key decisions in docs/ARCHITECTURE.md
- Track work in docs/TASKS.md

## Key Patterns
- **Structured JSON plans:** LLM generates WoodworkingPlan as structured JSON, not free text. Enables validation, interactive UI, and future features (3D viz, cut optimization).
- **Multi-layer validation:** Zod schema → programmatic woodworking rules (dimension checks, board feet math, joinery-tool compatibility) → re-generation on failure (max 2 retries).
- **Tool profile adaptation:** Plans adapt to user's declared tools — no mortise & tenon without a drill press, pocket holes always available for intermediate users.
- **Wood movement awareness:** Any solid wood panel >6" requires movement notes and mitigation strategies.

## Avoid
- Use Vercel AI SDK instead of raw Gemini API calls (enables model swapping)
- Use Supabase RLS instead of application-level auth checks for data access
- Use Zod schemas instead of manual JSON parsing for LLM output
- Use shadcn/ui instead of custom component library (consistent, accessible)
- Use Server Components instead of client-side fetching for plan display
