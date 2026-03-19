# Technical Feasibility: Life Assistant App

**Research Date:** 2026-03-19

---

## 1. Architecture: MCP Servers Per Domain

### Why MCP is the right approach

The Model Context Protocol provides exactly the modular, plug-and-play architecture this app needs. Each life domain becomes an independent MCP server exposing tools and resources to the AI host.

**How it maps:**

```
┌─────────────────────────────────────────────────────┐
│                   AI HOST (Next.js App)               │
│                                                       │
│  ┌─────────────┐  ┌──────────┐  ┌───────────────┐   │
│  │  Dashboard   │  │  Chat UI │  │  Nudge Engine │   │
│  │  (React)     │  │  (Stream)│  │  (Cron/Push)  │   │
│  └──────┬───────┘  └────┬─────┘  └───────┬───────┘   │
│         │               │                │            │
│  ┌──────┴───────────────┴────────────────┴──────┐    │
│  │           LLM Orchestration Layer             │    │
│  │  (Claude Sonnet/Haiku via Vercel AI SDK)      │    │
│  │  - Model routing (Haiku for quick, Sonnet     │    │
│  │    for coaching)                                │    │
│  │  - Cross-domain context assembly               │    │
│  │  - Memory management (3-tier)                  │    │
│  └──────┬───────────────┬────────────────┬──────┘    │
└─────────┼───────────────┼────────────────┼───────────┘
          │               │                │
    MCP Protocol    MCP Protocol     MCP Protocol
          │               │                │
┌─────────┴──┐  ┌────────┴───┐  ┌────────┴───┐
│  Career    │  │  Finance   │  │  Fitness   │  ...
│  MCP Server│  │  MCP Server│  │  MCP Server│
│            │  │            │  │            │
│ Tools:     │  │ Tools:     │  │ Tools:     │
│ -get_goals │  │ -add_txn   │  │ -log_wkout │
│ -add_skill │  │ -get_budget│  │ -get_streak│
│ -career_map│  │ -portfolio │  │ -log_meal  │
│            │  │            │  │            │
│ Resources: │  │ Resources: │  │ Resources: │
│ -goals://  │  │ -budget:// │  │ -habits:// │
│ -skills:// │  │ -invest:// │  │ -metrics://│
└────────────┘  └────────────┘  └────────────┘
      │               │                │
   SQLite          SQLite           SQLite
   (career.db)     (finance.db)     (fitness.db)
```

### MCP Server per Domain — Implementation

Each domain server exposes 3 MCP primitives:

1. **Tools** — Actions the AI can take (add a goal, log a transaction, generate a workout plan)
2. **Resources** — Data the AI can read (current goals, budget summary, fitness streaks)
3. **Prompts** — Pre-built prompt templates for common interactions (career coaching session, budget review)

**Example: Career MCP Server tools:**

```typescript
// Tools
- create_goal(title, description, deadline, parent_goal_id?)
- update_goal_progress(goal_id, progress_pct, notes?)
- add_skill(name, proficiency_level, evidence?)
- log_career_event(type: "win"|"learning"|"reflection", description)
- get_career_trajectory(current_role, target_role)
- generate_resume_feedback(resume_text)

// Resources
- goals://active — All active goals with progress
- goals://completed — Completed goals (last 90 days)
- skills://current — Current skill inventory
- career://trajectory — Career path with milestones
- journal://recent — Last 10 journal entries

// Prompts
- career-coaching — "Let's review your career progress and plan next steps"
- goal-review — "Let's review your goals for this quarter"
- skill-assessment — "Let's evaluate your current skills against your target role"
```

### Why not a monolith?

| Factor | Monolith | MCP Per Domain |
|--------|----------|---------------|
| **Adding a domain** | Modify core app, risk regressions | Add new server, zero impact on existing |
| **Testing** | Full app test suite for any change | Test domain in isolation |
| **Data isolation** | Shared database, privacy harder | Separate databases, privacy by default |
| **Complexity** | Simpler initially, harder at scale | More setup initially, scales cleanly |
| **Community extensibility** | Fork and modify | Third parties can build domain servers |

**Verdict:** MCP per domain adds ~2 days of setup overhead but pays back immediately in clean separation, easier testing, and the plug-and-play architecture Brian wants.

---

## 2. Memory Architecture

### 3-Tier Memory System

For a "knows me deeply" personal assistant, the AI needs persistent memory that evolves over time.

```
┌─────────────────────────────────────────────────┐
│              TIER 1: Working Memory               │
│  (Current session context)                        │
│  - Active conversation thread                     │
│  - Current task/goal being discussed              │
│  - Recent tool call results                       │
│  Storage: In-memory (conversation context)        │
│  Lifetime: Single session                         │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│              TIER 2: Episodic Memory              │
│  (Interaction history)                            │
│  - Past conversation summaries                    │
│  - Decisions made and why                         │
│  - Coaching sessions and outcomes                 │
│  - User preferences discovered through use        │
│  Storage: SQLite + embeddings (vector search)     │
│  Lifetime: Rolling window (6-12 months)           │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│              TIER 3: Semantic Memory              │
│  (Long-term user profile)                         │
│  - Core facts: name, career, family, values       │
│  - Personality traits and communication style     │
│  - Long-term goals and aspirations                │
│  - Recurring patterns (always overspends in Dec)  │
│  - Preferences (prefers morning workouts, etc.)   │
│  Storage: Structured JSON + SQLite                │
│  Lifetime: Persistent (updated, never deleted)    │
└─────────────────────────────────────────────────┘
```

### Implementation approach

**Phase 1 (MVP):** Simple structured memory
- Store user profile as JSON in SQLite
- Conversation history stored and summarized weekly
- AI reads profile + recent history at start of each session
- Manual profile updates via settings page

**Phase 2:** Add episodic memory with embeddings
- Use SQLite + `sqlite-vec` extension for vector search
- Embed conversation summaries for semantic retrieval
- "Remember when I mentioned..." → vector search past conversations

**Phase 3:** Full 3-tier with mem0 or custom implementation
- Automatic memory extraction from conversations
- Memory consolidation (daily → weekly → monthly summaries)
- Forgetting: auto-deprecate stale memories

### Memory framework options

| Framework | Approach | Solo Dev Fit | Maturity |
|-----------|----------|-------------|----------|
| **mem0** | Managed memory layer, API-based | Good — abstracts complexity | Production-ready |
| **LangGraph memory** | Built into LangGraph state management | Good if using LangGraph | Mature |
| **Custom (SQLite + embeddings)** | Full control, no dependencies | Best for understanding, more work | DIY |
| **Zep** | Open-source memory server | Good but another service to run | Maturing |

**Recommendation:** Start with custom structured memory in SQLite (Phase 1 — 1 day of work). Evaluate mem0 for Phase 2 when episodic memory is needed.

---

## 3. Privacy Architecture

### Option A: Full Cloud (Simplest)
- All data sent to Claude API for processing
- **Pros:** Simplest to build, best AI quality
- **Cons:** Financial data and health data go through Anthropic's servers
- **Risk:** User trust, regulatory gray area

### Option B: Local-First (Most Private)
- Run a local LLM (Llama 3.3, Mistral) for all processing
- **Pros:** Data never leaves device
- **Cons:** Worse quality, can't run on phone, needs beefy hardware
- **Risk:** Poor coaching quality defeats the purpose

### Option C: Hybrid (Recommended)
```
User Data → Local Processing → Anonymized Summary → Cloud AI → Insight
                                                              ↓
                                                        User sees result
```

- **Tier 1 data** (raw transactions, health metrics): Stays local. Processed into summaries.
- **Tier 2 data** (category summaries, aggregates): Sent to cloud AI for analysis.
- **Tier 3 data** (goals, coaching conversations): Full cloud access — user explicitly consents.

**Implementation:**
1. Local summary engine: Simple rules + Haiku to produce "You spent $X in Y categories this month"
2. Cloud AI only sees summaries: "User is over budget in dining by 15%"
3. User controls tier settings per domain via privacy settings page

### Privacy architecture for the MVP

**Pragmatic approach for a personal tool:**
- Phase 1: Full cloud (Brian trusts himself, this is a personal tool)
- Phase 2: Add privacy tiers when sharing with friends
- Phase 3: Full hybrid architecture for broader release

**Why this is OK for MVP:** This is Brian's personal tool. He controls the data. Adding privacy infrastructure before it's needed is premature optimization. Design the architecture to support tiers later (clean data abstraction layer), but don't build the tiers yet.

---

## 4. Tech Stack Recommendation

### Frontend + Backend: Next.js 15 + Vercel AI SDK

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Framework** | Next.js 15 (App Router) | Full-stack React. Server components for dashboard. API routes for MCP host. Streaming for chat. |
| **AI SDK** | Vercel AI SDK 4.x | Best-in-class streaming UI, tool calling, multi-step agents. Built for exactly this use case. |
| **Styling** | Tailwind CSS + shadcn/ui | Rapid UI development. Pre-built components for dashboard, chat, forms. |
| **Database** | SQLite (via better-sqlite3) → Turso migration path | Zero cost. One file per domain. Familiar pattern from fishing-copilot. |
| **Auth** | NextAuth.js (Auth.js v5) | Simple for MVP (email magic link). Extensible for multi-user. |
| **Hosting** | Vercel (free tier) | Zero-config deployment. Edge functions for nudge cron. |
| **MCP Host** | `@modelcontextprotocol/sdk` | Official TypeScript SDK for building MCP hosts and servers. |

### Why Next.js over alternatives

| Alternative | Why Not (for this project) |
|-------------|--------------------------|
| **Python (Flask/FastAPI)** | Brian's fishing-copilot is Python, but Next.js is better for the hybrid dashboard+chat UI. Python lacks good streaming UI primitives. |
| **SvelteKit** | Smaller ecosystem, fewer AI SDK integrations. |
| **React Native** | Mobile-first is premature. Web-first with responsive design covers MVP. |
| **Plain React + Express** | Next.js provides SSR, API routes, and edge functions out of the box. |

### MCP Server Implementation

Each domain MCP server is a TypeScript process using `@modelcontextprotocol/server-node`:

```
life-assistant/
├── apps/
│   └── web/                    # Next.js app (MCP host + UI)
│       ├── app/
│       │   ├── page.tsx        # Dashboard
│       │   ├── chat/           # Chat interface
│       │   ├── goals/          # Goals management
│       │   ├── career/         # Career domain views
│       │   └── api/            # API routes
│       ├── lib/
│       │   ├── mcp-host.ts     # MCP client manager
│       │   ├── memory.ts       # Memory management
│       │   └── ai/             # AI orchestration
│       └── ...
├── packages/
│   ├── mcp-career/             # Career + Goals MCP server
│   │   ├── src/
│   │   │   ├── server.ts       # MCP server entry
│   │   │   ├── tools.ts        # Tool definitions
│   │   │   ├── resources.ts    # Resource definitions
│   │   │   └── db.ts           # SQLite operations
│   │   └── package.json
│   ├── mcp-finance/            # Finance MCP server
│   ├── mcp-fitness/            # Fitness MCP server
│   ├── mcp-hobbies/            # Hobbies MCP server
│   └── shared/                 # Shared types, utilities
│       ├── src/
│       │   ├── types.ts        # Cross-domain types
│       │   ├── memory.ts       # Memory utilities
│       │   └── privacy.ts      # Privacy tier helpers
│       └── package.json
├── turbo.json                  # Turborepo config
└── package.json                # Workspace root
```

### Package management: Turborepo monorepo

- Each MCP server is an independent package
- Shared types/utilities in `packages/shared`
- `turbo dev` runs all servers + web app
- `turbo build` builds everything
- `turbo test` tests everything

---

## 5. Cost Modeling

### AI API Costs (per user, daily active)

| Interaction | Model | Input Tokens | Output Tokens | Daily Cost |
|-------------|-------|-------------|---------------|------------|
| Morning dashboard insight | Haiku 4.5 | ~2,000 | ~500 | $0.002 |
| 3 chat coaching interactions | Sonnet 4.6 | ~6,000 | ~3,000 | $0.045 |
| 5 quick tool calls (logging) | Haiku 4.5 | ~1,000 | ~200 | $0.001 |
| Proactive nudge generation | Haiku 4.5 | ~3,000 | ~500 | $0.003 |
| Cross-domain weekly review | Sonnet 4.6 | ~8,000 | ~2,000 | $0.030 |
| Memory summarization | Haiku 4.5 | ~2,000 | ~500 | $0.002 |
| **Daily total** | | | | **~$0.08** |
| **Monthly total** | | | | **~$2.50** |

### Infrastructure Costs

| Service | Free Tier | Paid Tier | Notes |
|---------|-----------|-----------|-------|
| Vercel | 100GB bandwidth, serverless | $20/mo (Pro) | Free tier likely sufficient for <20 users |
| Turso (SQLite) | 500 databases, 9GB storage | $29/mo | Free tier covers MVP easily |
| Vercel KV/Blob | 256MB | $5/mo | For session storage and file uploads |
| Domain | — | $12/year | Optional |
| **Total (personal)** | **$0** | | Free tier covers personal use |
| **Total (10 users)** | **~$25/mo** | | AI costs + minimal infra |

### Cost optimization strategies

1. **Model routing**: Haiku for all tool calls, logging, and simple queries. Sonnet only for coaching conversations and complex reasoning. Saves ~60% vs. Sonnet-for-everything.
2. **Caching**: Cache common insights ("your budget status") for 1 hour. Semantic caching for similar questions.
3. **Batch processing**: Generate daily insights and nudges in a single batch call, not per-interaction.
4. **Prompt caching**: Anthropic's prompt caching for the user profile prefix (same across all calls). 90% discount on cached tokens.

---

## 6. Integration Feasibility (For Future Phases)

| Integration | API Quality | Solo Dev Effort | MVP Priority | Notes |
|-------------|------------|-----------------|--------------|-------|
| **Plaid (Banking)** | Excellent | 2-3 days | v2+ | $0 for personal use. Requires Plaid dashboard approval. |
| **Apple Health** | iOS-only, HealthKit | 1-2 weeks (needs native bridge) | v3+ | Requires React Native or native app |
| **Google Calendar** | Good REST API | 1-2 days | v2 | OAuth flow. Read events for workload analysis. |
| **Google Fit** | REST API | 2-3 days | v3+ | OAuth. Steps, sleep, workouts. |
| **Strava** | Good API, OAuth | 1-2 days | v3+ | Workout data import |
| **USDA FoodData Central** | Free, no auth | 1 day | v2 | Food/calorie lookup for meal logging |
| **CSV Import** | N/A | 1 day | v1 | Universal data import (bank exports, etc.) |

**MVP approach:** 100% manual input for all domains. CSV import as a convenience. Integrations are v2+ features that enhance but don't define the product.

---

## 7. Notification/Nudge Architecture

### How proactive nudges work

```
┌────────────────────────────────────────┐
│         Nudge Engine (Cron Job)         │
│  Runs: Every 4 hours via Vercel Cron   │
│                                        │
│  1. Query each MCP server for status   │
│     - Goals: overdue? streak at risk?  │
│     - Finance: over budget?            │
│     - Fitness: inactivity detected?    │
│  2. Assemble cross-domain context      │
│  3. Send to Haiku: "Generate nudges"   │
│  4. Filter: max 3 nudges per day       │
│  5. Deliver via:                       │
│     - Web push notification            │
│     - Email (Resend)                   │
│     - Dashboard notification center    │
│     (SMS in v2 via Twilio)             │
└────────────────────────────────────────┘
```

### Nudge fatigue prevention

- Max 3 nudges per day
- Cooldown per topic (don't nag about the same thing twice in 48 hours)
- User can snooze or dismiss nudge types
- Priority ranking: urgent (over budget) > streak-at-risk > informational

---

## Sources
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [Vercel AI SDK Documentation](https://sdk.vercel.ai/docs)
- [PulseMCP: 531 MCP Clients](https://www.pulsemcp.com/clients)
- [InfoQ: MCP Universal Connector](https://www.infoq.com/articles/mcp-connector-for-building-smarter-modular-ai-agents/)
- [MCP Apps Official Release (Jan 2026)](https://technyanai.com/articles/en/20260126/mcp-apps-official-extension)
- [Companion Intelligence: On-Premises AI Privacy](https://ci.computer/blog/2025/12/4/privacy-in-healthcare-and-wellness)
- [Anthropic: Prompt Caching Documentation](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- [mem0: Production Memory Layer](https://github.com/mem0ai/mem0)
- [Plaid API Documentation](https://plaid.com/docs/)
- [Turso: SQLite for Production](https://turso.tech/)
