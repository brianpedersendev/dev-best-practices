# Architecture Decisions

## Overview
Woodworking Sidekick is an AI-native web app where the LLM is the core product — it generates structured woodworking plans from natural language descriptions, adapted to the user's tools and skill level. Supabase handles auth and persistence, Vercel AI SDK abstracts the LLM provider, and Next.js App Router renders plans as interactive, server-rendered pages with a streaming chat assistant.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Plan output format | Structured JSON (WoodworkingPlan schema) | Enables programmatic validation, interactive UI (sortable tables, collapsible sections), future features (3D viz, cut optimization). Free text can't be validated. |
| Validation strategy | Multi-layer: Zod schema → woodworking rules → LLM re-generation | LLMs hallucinate 5-20% on complex reasoning. Wrong dimensions = wasted wood and lost trust. Programmatic checks catch what the LLM misses. |
| Primary LLM | Gemini 2.0 Flash/Pro via Vercel AI SDK | Best price/performance ratio, generous free tier, multimodal for future image input. AI SDK enables one-line model swap to Claude or GPT-4. |
| Knowledge architecture | Rich system prompts for MVP | Core woodworking knowledge (lumber dimensions, joinery rules, tool capabilities) fits in a system prompt. Migrate to structured DB + RAG as knowledge grows. |
| Auth + database | Supabase (Postgres + Auth + RLS) | Zero-config auth (email + OAuth), Row-Level Security for data isolation, JSONB for plan storage, generous free tier, built-in pgvector for future RAG. |
| Framework | Next.js 15 App Router | Server Components for plan rendering (SEO-friendly), streaming support for chat, Vercel deployment, Server Actions for mutations. |
| Chat context | Full plan JSON in system prompt | Keeps answers project-specific without RAG/embeddings. Token cost acceptable — plans are ~2-4K tokens. |
| Styling | Tailwind + shadcn/ui | Fast UI development, consistent accessible design system, easy print styling for plan export. |

## System Diagram

```
User describes project ("Build me a bookshelf, 4ft tall, I have a table saw and router")
                │
                ▼
┌─────────────────────────────────────────────────────────┐
│              Next.js App Router (Vercel)                  │
│                                                          │
│  ┌──────────┐  ┌───────────────┐  ┌──────────────────┐  │
│  │ Landing  │  │ Plan Builder  │  │ AI Chat Panel    │  │
│  │ Page     │  │ (input form + │  │ (per project,    │  │
│  │          │  │  plan display)│  │  streaming)      │  │
│  └──────────┘  └───────┬───────┘  └────────┬─────────┘  │
│                        │                    │            │
│  ┌─────────────────────┴────────────────────┴─────────┐  │
│  │        Server Actions / Route Handlers              │  │
│  │  generate-plan: description + tools → plan JSON     │  │
│  │  chat: message + plan context → streaming response  │  │
│  └─────────────────────┬──────────────────────────────┘  │
│                        │                                 │
│  ┌─────────────────────┴──────────────────────────────┐  │
│  │              Vercel AI SDK (ai package)              │  │
│  │  streamText → parse → Zod validate → store          │  │
│  └──────┬──────────────────────────────────────────────┘  │
└─────────┼────────────────────────────────────────────────┘
          │
    ┌─────┴──────┐        ┌───────────────────────────────┐
    │  Gemini    │        │         Supabase               │
    │  API       │        │  ┌─────────────────────────┐   │
    │ (primary)  │        │  │ Auth (email + Google)    │   │
    │            │        │  ├─────────────────────────┤   │
    │  [swap via │        │  │ Postgres                 │   │
    │   AI SDK]  │        │  │  - projects (JSONB plan) │   │
    │            │        │  │  - plan_versions         │   │
    └────────────┘        │  │  - messages (chat)       │   │
                          │  ├─────────────────────────┤   │
          ┌───────────┐   │  │ Row-Level Security       │   │
          │ Validation│   │  │ (users see own data only)│   │
          │ Layer     │   │  └─────────────────────────┘   │
          │ Zod +     │   └───────────────────────────────┘
          │ woodwork  │
          │ rules     │
          └───────────┘
```

## Data Flow

### Plan Generation
1. User fills input form: project description + tool profile + optional preferences
2. Server Action calls Gemini via `streamText` with woodworking system prompt
3. Streaming response displayed to user as progress
4. Completed response parsed into WoodworkingPlan Zod schema
5. Validation layer checks: dimensional consistency, board feet math, joinery-tool compatibility, wood movement
6. If validation fails → error feedback sent to Gemini → re-generation (max 2 retries)
7. Validated plan stored as JSONB in Supabase `projects` table
8. Plan rendered as interactive UI (sortable cut list, collapsible sections)

### Chat
1. User types question in chat panel
2. Server Action loads project's plan JSON + recent messages (last 20)
3. Plan JSON injected as system context (not message history — saves tokens)
4. Gemini responds via `streamText` with project-aware answer
5. Message saved to Supabase `messages` table

### Plan Adjustment
1. User requests change ("make it wider", "use pocket holes instead")
2. Original plan + feedback sent as context to Gemini
3. New plan generated, validated, stored as new version in `plan_versions` table
4. `projects.plan` updated to latest version, `plan_version` incremented

## Failure Modes & Mitigation

| Failure | Impact | Mitigation |
|---------|--------|------------|
| Gemini returns invalid JSON | Plan can't be displayed | Zod validation catches it → retry with error feedback (max 2x) |
| Plan has wrong dimensions | User wastes wood, loses trust | Multi-layer validation: board feet math, cut-from-material check, nominal vs actual size check |
| Gemini API down | No plan generation or chat | Graceful error state, suggest retrying later. Future: fallback to Claude via AI SDK swap. |
| Supabase down | No auth, no saved plans | Error boundary, guest mode still works if plan gen is up (plan just won't save) |
| Plan recommends unsafe joinery for user's tools | User could get hurt | Joinery-tool compatibility check in validation. Safety flags for small-piece cuts. |
| Chat hallucinates contradicting the plan | Confusing advice during build | Chat system prompt explicitly says "reference the plan" — guardrails reduce but don't eliminate this |
