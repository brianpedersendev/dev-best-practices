# Tasks

## In Progress
- [ ] Phase 1 Foundation — Next.js scaffold, Supabase setup, auth, database schema

## Up Next
- [ ] Design WoodworkingPlan Zod schema (types/ + lib/validation/)
- [ ] Build system prompt for plan generation (lib/prompts/)
- [ ] Build project input form (description + tool profile + preferences)
- [ ] Build plan generation API route (app/api/generate-plan/)
- [ ] Build plan validation layer (dimensional checks, board feet, joinery rules)
- [ ] Build plan display UI (sections, cut list table, print view)
- [ ] Build plan regeneration with feedback ("make it wider", "use pocket holes")
- [ ] Build chat API route with plan context (app/api/chat/)
- [ ] Build chat UI (slide-out panel, streaming, suggested questions)
- [ ] Chat message persistence (Supabase messages table)
- [ ] Guest try-before-signup flow (1 plan without account)
- [ ] First-time user onboarding (tool profile setup)
- [ ] Golden path testing (bookshelf, end table, cutting board, workbench, floating shelves)
- [ ] Landing page (hero, demo, CTAs)
- [ ] Dashboard improvements (project cards, sort/filter)
- [ ] Plan UX polish (collapsible sections, export PDF, cost estimates)
- [ ] Error handling and edge cases (rate limiting, LLM failures, loading states)
- [ ] SEO and meta (Open Graph, sitemap, public plan URLs)
- [ ] Launch checklist (ToS, disclaimers, analytics, Sentry, mobile, Lighthouse)

## Done
- [x] Project research — competitive landscape, technical feasibility, domain/market analysis — 2026-03-19
- [x] Implementation plan — full architecture, 5-phase task breakdown, schema design — 2026-03-19
- [x] AI tooling scaffold — CLAUDE.md, hooks, MCP, agents, skills — 2026-03-20

## Notes
- Start with plan generation (Phase 2) — it's the core product. Auth/database (Phase 1) is just plumbing.
- Golden path projects must produce excellent plans before launch — first impression is everything.
- See docs/plan/PLAN.md for full task breakdown with phase estimates and dependencies.
