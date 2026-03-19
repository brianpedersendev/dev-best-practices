# Life Assistant (LifeOS): Implementation Plan

**Date:** 2026-03-19
**Status:** Ready for Implementation

---

## 1. Architecture Overview

### System Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    NEXT.JS APP (MCP HOST)                     │
│                                                              │
│  ┌──────────┐  ┌───────────┐  ┌────────────┐               │
│  │Dashboard │  │ Chat UI   │  │Nudge Engine│               │
│  │(React    │  │(Vercel AI │  │(Vercel Cron│               │
│  │ Server   │  │ SDK +     │  │ every 4hr) │               │
│  │ Comps)   │  │ Streaming)│  │            │               │
│  └────┬─────┘  └─────┬─────┘  └─────┬──────┘               │
│       └───────────────┼──────────────┘                       │
│                       ▼                                      │
│  ┌────────────────────────────────────────────┐             │
│  │         LLM Orchestration Layer             │             │
│  │  - Model routing (Haiku ↔ Sonnet)          │             │
│  │  - Cross-domain context assembly            │             │
│  │  - 3-tier memory management                 │             │
│  │  - Prompt caching (user profile prefix)     │             │
│  └────────┬──────────┬──────────┬─────────────┘             │
└───────────┼──────────┼──────────┼────────────────────────────┘
            │          │          │
      MCP Protocol     │    MCP Protocol
            │          │          │
┌───────────┴──┐ ┌────┴─────┐ ┌─┴────────────┐
│ Career+Goals │ │ Finance  │ │ Fitness+Diet │  (+ Hobbies later)
│ MCP Server   │ │ MCP Srv  │ │ MCP Server   │
│              │ │          │ │              │
│ Tools:       │ │ Tools:   │ │ Tools:       │
│ -goals CRUD  │ │ -add_txn │ │ -log_workout │
│ -career_map  │ │ -budget  │ │ -log_meal    │
│ -skill_track │ │ -invest  │ │ -get_streaks │
│ -ai_coach    │ │ -insights│ │ -ai_coach    │
│              │ │          │ │              │
│ Resources:   │ │Resources:│ │ Resources:   │
│ -goals://    │ │-budget://│ │ -habits://   │
│ -skills://   │ │-invest://│ │ -metrics://  │
│ -journal://  │ │-txns://  │ │ -meals://    │
└──────┬───────┘ └────┬─────┘ └──────┬───────┘
       │              │              │
    SQLite         SQLite         SQLite
   career.db      finance.db    fitness.db
```

### Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| MCP per domain | Each domain is an independent MCP server | Plug-and-play modularity. Add/remove domains without touching others. Privacy isolation by default. |
| Next.js as host | Next.js 15 App Router + Vercel AI SDK | Full-stack React. Server components for dashboard. Streaming for chat. API routes for MCP host. |
| SQLite per domain | Separate database file per MCP server | Data isolation. Independent testing. Easy backup/migration. Turso migration path. |
| Model routing | Haiku for tool calls/nudges, Sonnet for coaching | ~60% cost savings vs. Sonnet-for-everything. Haiku handles CRUD and classification; Sonnet handles reasoning. |
| Manual input first | No external integrations in MVP | Eliminates integration complexity. Proves value through AI intelligence, not data import convenience. |
| Monorepo | Turborepo workspace with shared packages | One repo, multiple packages. Shared types. Coordinated builds and tests. |

---

## 2. Tech Stack

| Component | Choice | Justification |
|-----------|--------|---------------|
| **Framework** | Next.js 15 (App Router) | Full-stack React. SSR for dashboard. API routes for MCP host. Streaming for chat. |
| **AI SDK** | Vercel AI SDK 4.x | Best streaming UI, tool calling, multi-step agents. `useChat` hook for chat. `streamUI` for dynamic components. |
| **MCP** | `@modelcontextprotocol/sdk` | Official TypeScript SDK. Production-ready. Handles server lifecycle. |
| **LLM** | Claude Sonnet 4.6 (coaching) + Haiku 4.5 (tools) | Sonnet for nuanced career/life coaching. Haiku for CRUD operations and nudge generation. |
| **Database** | SQLite via `better-sqlite3` | Zero cost. One file per domain. WAL mode for concurrent reads. |
| **Styling** | Tailwind CSS + shadcn/ui | Rapid UI dev. Pre-built dashboard components (charts, cards, forms, chat). |
| **Auth** | Auth.js v5 (NextAuth) | Magic link email for MVP. Extensible for OAuth later. |
| **Hosting** | Vercel (free tier) | Zero-config Next.js deployment. Edge functions for cron. |
| **Monorepo** | Turborepo | Manages multi-package workspace. Shared builds/tests. |
| **Testing** | Vitest + React Testing Library | Fast. Compatible with Next.js. Built-in coverage. |
| **Linting** | ESLint + Prettier (via Biome) | Standard. Fast with Biome. |

---

## 3. Project Structure

```
life-assistant/
├── apps/
│   └── web/                          # Next.js app (MCP host + UI)
│       ├── app/
│       │   ├── layout.tsx            # Root layout with sidebar nav
│       │   ├── page.tsx              # Dashboard (overview across domains)
│       │   ├── chat/
│       │   │   └── page.tsx          # Chat interface (Vercel AI SDK useChat)
│       │   ├── goals/
│       │   │   ├── page.tsx          # Goals list + progress
│       │   │   └── [id]/page.tsx     # Goal detail + sub-goals
│       │   ├── career/
│       │   │   ├── page.tsx          # Career trajectory view
│       │   │   └── skills/page.tsx   # Skill inventory
│       │   ├── finance/              # (MVP 2)
│       │   ├── fitness/              # (MVP 3)
│       │   ├── hobbies/             # (MVP 4)
│       │   ├── settings/
│       │   │   └── page.tsx          # User prefs, privacy, nudge config
│       │   └── api/
│       │       ├── chat/route.ts     # Chat API (streaming)
│       │       ├── nudge/route.ts    # Nudge cron endpoint
│       │       └── auth/[...]/       # Auth.js routes
│       ├── lib/
│       │   ├── mcp-host.ts           # MCP client manager (connects to domain servers)
│       │   ├── orchestrator.ts       # Cross-domain reasoning + model routing
│       │   ├── memory.ts             # 3-tier memory management
│       │   └── nudge-engine.ts       # Nudge generation + delivery
│       ├── components/
│       │   ├── dashboard/            # Dashboard widgets
│       │   ├── chat/                 # Chat UI components
│       │   ├── goals/                # Goal cards, progress bars
│       │   └── ui/                   # shadcn/ui components
│       └── package.json
├── packages/
│   ├── mcp-career/                   # Career + Goals MCP server
│   │   ├── src/
│   │   │   ├── server.ts             # MCP server entry point
│   │   │   ├── tools/
│   │   │   │   ├── goals.ts          # Goal CRUD tools
│   │   │   │   ├── career.ts         # Career trajectory tools
│   │   │   │   ├── skills.ts         # Skill tracking tools
│   │   │   │   └── journal.ts        # Journaling tools
│   │   │   ├── resources/
│   │   │   │   ├── goals.ts          # goals:// resource provider
│   │   │   │   ├── skills.ts         # skills:// resource provider
│   │   │   │   └── career.ts         # career:// resource provider
│   │   │   ├── prompts/
│   │   │   │   ├── coaching.ts       # Career coaching prompt templates
│   │   │   │   └── review.ts         # Goal review prompt templates
│   │   │   └── db/
│   │   │       ├── schema.sql        # SQLite schema
│   │   │       ├── connection.ts     # DB connection
│   │   │       └── queries.ts        # Typed query functions
│   │   ├── tests/
│   │   └── package.json
│   ├── mcp-finance/                  # (MVP 2 — same structure)
│   ├── mcp-fitness/                  # (MVP 3 — same structure)
│   ├── mcp-hobbies/                  # (MVP 4 — same structure)
│   └── shared/                       # Shared types + utilities
│       ├── src/
│       │   ├── types.ts              # Cross-domain types (Goal, User, etc.)
│       │   ├── memory.ts             # Memory utilities
│       │   └── privacy.ts            # Privacy tier helpers
│       └── package.json
├── turbo.json
├── package.json
├── CLAUDE.md                         # AI dev instructions
├── agents.md                         # Agent team config
└── docs/                             # Project documentation
```

---

## 4. Data Model (MVP 1: Career + Goals)

### SQLite Schema — `career.db`

```sql
-- ============================================
-- GOALS: Hierarchical goal system (shared foundation)
-- ============================================
CREATE TABLE goals (
    id          TEXT PRIMARY KEY,              -- nanoid
    title       TEXT NOT NULL,
    description TEXT,
    domain      TEXT NOT NULL DEFAULT 'career', -- 'career' | 'finance' | 'fitness' | 'hobby' | 'life'
    status      TEXT NOT NULL DEFAULT 'active', -- 'active' | 'completed' | 'paused' | 'abandoned'
    parent_id   TEXT REFERENCES goals(id),      -- hierarchy: life → annual → quarterly → weekly
    priority    INTEGER DEFAULT 0,              -- 0=normal, 1=high, 2=urgent
    progress    REAL DEFAULT 0.0,               -- 0.0 to 1.0
    target_date TEXT,                           -- ISO 8601 date
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT NOT NULL DEFAULT (datetime('now')),
    completed_at TEXT
);

CREATE INDEX idx_goals_parent ON goals(parent_id);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_goals_domain ON goals(domain);

-- ============================================
-- CAREER PROFILE
-- ============================================
CREATE TABLE career_profile (
    id              TEXT PRIMARY KEY,
    current_role    TEXT NOT NULL,
    current_company TEXT,
    industry        TEXT,
    years_experience INTEGER,
    target_role     TEXT,
    target_timeline TEXT,                     -- "1 year", "2-3 years"
    salary_current  REAL,                     -- stored locally, never sent to AI raw
    salary_target   REAL,
    notes           TEXT,
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================
-- SKILLS: Inventory with proficiency tracking
-- ============================================
CREATE TABLE skills (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    category    TEXT,                         -- 'technical' | 'soft' | 'domain' | 'tool'
    proficiency INTEGER NOT NULL DEFAULT 1,  -- 1-5 scale
    evidence    TEXT,                         -- how you know you're at this level
    target_level INTEGER,                    -- desired proficiency
    last_practiced TEXT,                      -- ISO 8601 date
    learning_resources TEXT,                  -- JSON array of URLs/books
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================
-- JOURNAL: Reflections and coaching notes
-- ============================================
CREATE TABLE journal_entries (
    id          TEXT PRIMARY KEY,
    entry_type  TEXT NOT NULL DEFAULT 'reflection', -- 'reflection' | 'win' | 'learning' | 'decision' | 'coaching'
    content     TEXT NOT NULL,
    tags        TEXT,                         -- JSON array of tags
    mood        INTEGER,                      -- 1-5 scale (optional)
    energy      INTEGER,                      -- 1-5 scale (optional)
    domain      TEXT DEFAULT 'career',
    goal_id     TEXT REFERENCES goals(id),   -- optional link to a goal
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_journal_date ON journal_entries(created_at DESC);
CREATE INDEX idx_journal_type ON journal_entries(entry_type);

-- ============================================
-- MILESTONES: Career achievements timeline
-- ============================================
CREATE TABLE milestones (
    id          TEXT PRIMARY KEY,
    title       TEXT NOT NULL,
    description TEXT,
    date        TEXT NOT NULL,
    category    TEXT,                         -- 'promotion' | 'certification' | 'project' | 'skill' | 'other'
    impact      TEXT,                         -- brief description of impact
    goal_id     TEXT REFERENCES goals(id),
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================
-- NUDGE HISTORY: Track what nudges were sent
-- ============================================
CREATE TABLE nudge_history (
    id          TEXT PRIMARY KEY,
    nudge_type  TEXT NOT NULL,               -- 'goal_reminder' | 'streak' | 'inactivity' | 'insight'
    content     TEXT NOT NULL,
    domain      TEXT NOT NULL,
    delivered_at TEXT NOT NULL DEFAULT (datetime('now')),
    seen_at     TEXT,
    action_taken TEXT                         -- 'dismissed' | 'snoozed' | 'acted'
);

-- ============================================
-- USER MEMORY: Persistent AI memory (Tier 3 — semantic)
-- ============================================
CREATE TABLE user_memory (
    id          TEXT PRIMARY KEY,
    category    TEXT NOT NULL,               -- 'preference' | 'fact' | 'pattern' | 'style'
    key         TEXT NOT NULL,               -- e.g., 'communication_style', 'morning_person'
    value       TEXT NOT NULL,               -- the memory content
    confidence  REAL DEFAULT 1.0,            -- 0.0-1.0, decays over time
    source      TEXT,                        -- which conversation/interaction
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(category, key)
);
```

---

## 5. MVP Feature List (Prioritized)

### Phase 1: Career + Goals (Weeks 1-6)
**Goal:** Brian has a useful daily career coaching + goal tracking tool.

| # | Feature | Priority | Est. Time |
|---|---------|----------|-----------|
| 1.1 | Project setup: Turborepo, Next.js, shared packages | Must | 1 day |
| 1.2 | MCP Career server skeleton: connection, schema, basic tools | Must | 2 days |
| 1.3 | Goal CRUD tools + resources (create, update, list, hierarchy) | Must | 2 days |
| 1.4 | Dashboard: goals overview with progress bars, status cards | Must | 2 days |
| 1.5 | Career profile setup (current role, target role, skills) | Must | 1 day |
| 1.6 | Skill inventory: add, rate, track, suggest learning resources | Must | 2 days |
| 1.7 | Chat interface with Vercel AI SDK (useChat + streaming) | Must | 2 days |
| 1.8 | AI career coaching: resume review, interview prep, career mapping | Must | 3 days |
| 1.9 | Journal/reflection system with tags and goal linking | Should | 1 day |
| 1.10 | Nudge engine: cron job, goal reminders, inactivity alerts | Should | 2 days |
| 1.11 | User memory: structured profile in SQLite, loaded into prompts | Must | 1 day |
| 1.12 | Auth: magic link email login via Auth.js | Must | 1 day |
| 1.13 | Settings page: preferences, nudge frequency, privacy | Should | 1 day |
| 1.14 | Deploy to Vercel | Must | 0.5 days |
| 1.15 | Test suite: MCP server tools, API routes, key components | Must | 2 days |

**Phase 1 Total: ~4-5 weeks**

### Phase 2: Finance Domain (Weeks 7-10)
**Goal:** Financial tracking connected to career goals.

| # | Feature | Priority | Est. Time |
|---|---------|----------|-----------|
| 2.1 | MCP Finance server: schema, tools, resources | Must | 2 days |
| 2.2 | Transaction entry + categorization (manual) | Must | 2 days |
| 2.3 | Budget management (set targets, track against them) | Must | 2 days |
| 2.4 | Investment portfolio overview (manual entry) | Should | 2 days |
| 2.5 | AI financial insights (spending patterns, budget alerts) | Must | 2 days |
| 2.6 | Dashboard: finance widgets (spending chart, budget status) | Must | 2 days |
| 2.7 | Cross-domain: career salary → financial planning connection | Must | 1 day |
| 2.8 | CSV import for bank transactions | Should | 1 day |
| 2.9 | Financial goal tracking (savings targets, debt payoff) | Must | 1 day |

**Phase 2 Total: ~3-4 weeks**

### Phase 3: Fitness + Diet (Weeks 11-14)
**Goal:** Health tracking with cross-domain awareness.

| # | Feature | Priority | Est. Time |
|---|---------|----------|-----------|
| 3.1 | MCP Fitness server: schema, tools, resources | Must | 2 days |
| 3.2 | Workout logging (type, duration, exercises) | Must | 2 days |
| 3.3 | Meal logging (description, estimated calories) | Should | 1 day |
| 3.4 | Habit tracking with streaks | Must | 2 days |
| 3.5 | AI fitness coaching (workout suggestions, pattern detection) | Must | 2 days |
| 3.6 | Dashboard: fitness widgets (streak charts, progress) | Must | 2 days |
| 3.7 | Cross-domain: career stress → fitness correlation | Must | 1 day |
| 3.8 | Cross-domain: finance → gym/meal spending analysis | Should | 1 day |

**Phase 3 Total: ~3 weeks**

### Phase 4: Hobbies (Weeks 15-17)
**Goal:** Hobby project management connected to budget and goals.

| # | Feature | Priority | Est. Time |
|---|---------|----------|-----------|
| 4.1 | MCP Hobbies server: schema, tools, resources | Must | 1 day |
| 4.2 | Project CRUD (name, status, notes, materials, time) | Must | 2 days |
| 4.3 | AI idea generator (based on skill level, tools, budget) | Must | 1 day |
| 4.4 | Project notes with photo upload | Should | 1 day |
| 4.5 | Cross-domain: hobby spending tied to finance budget | Must | 1 day |
| 4.6 | Dashboard: hobby widgets | Should | 1 day |

**Phase 4 Total: ~2 weeks**

### Phase 5: Multi-User + Polish (Weeks 18-24)
**Goal:** Shareable with 5-10 friends.

| # | Feature | Priority | Est. Time |
|---|---------|----------|-----------|
| 5.1 | Multi-user data isolation | Must | 2 days |
| 5.2 | Onboarding flow (guided interview) | Must | 2 days |
| 5.3 | Privacy tiers (per-domain data handling settings) | Should | 2 days |
| 5.4 | Email nudges via Resend | Should | 1 day |
| 5.5 | Weekly AI-generated review emails | Should | 2 days |
| 5.6 | Polish: loading states, error handling, mobile responsive | Must | 3 days |
| 5.7 | Migrate SQLite → Turso (multi-user persistence) | Must | 2 days |

**Phase 5 Total: ~3 weeks**

---

## 6. Cross-Domain Reasoning Implementation

### Phase 1 approach (simple — shared context)

When the user asks a question or the nudge engine runs:
1. Query each active MCP server for a domain summary
2. Assemble summaries into a single prompt context block
3. Send to Sonnet with cross-domain reasoning instructions

```typescript
// Simplified cross-domain context assembly
async function assembleCrossContext(): Promise<string> {
  const summaries = await Promise.all(
    activeDomains.map(domain => domain.getSummary())
  );
  return summaries.join('\n\n');
}

// Career domain summary example:
// "Active goals: 3 (1 on track, 1 behind, 1 new)
//  Current role: Senior Dev at Acme. Target: Staff Engineer (18mo).
//  Skills: TypeScript (4/5), System Design (3/5, target 4).
//  Recent: Completed AWS cert. No journal entries in 7 days."
```

### Phase 2+ approach (event-driven)

Each domain emits events when significant changes occur:
- `goal.completed`, `goal.behind_schedule`
- `budget.exceeded`, `spending.anomaly`
- `streak.broken`, `workout.missed`
- `project.completed`, `project.stalled`

A cross-domain reasoning agent subscribes to all events and generates insights.

---

## 7. Traceability

### Original Problem
People juggle 10+ apps across life domains. No tool connects career, finances, fitness, and hobbies for cross-domain intelligence.

### How This Plan Addresses It
- **Goal engine** (Phase 1) is the shared foundation connecting all domains
- **MCP per domain** enables modular, independent, plug-and-play domain addition
- **Cross-domain context assembly** enables insights no single app can generate
- **Proactive nudge engine** reaches out to the user, not just responding when asked
- **Domain-by-domain rollout** prevents the "too broad, too shallow" failure mode

### What's Deferred to Later
- Native mobile app → responsive web covers MVP
- External integrations (Plaid, Apple Health) → manual input for MVP
- Sophisticated memory (episodic + semantic tiers) → structured JSON for MVP
- Event-driven cross-domain → shared context window for MVP
- Privacy tiers → full cloud for personal use, add tiers for multi-user

---

## 8. First-Week Milestones

1. **Day 1:** Turborepo project created. Next.js app running. `mcp-career` package scaffolded.
2. **Day 3:** Career MCP server running with goal CRUD tools. Can create/list/update goals via MCP.
3. **Day 5:** Dashboard showing goals with progress bars. Chat interface streaming responses.
4. **Day 7:** AI career coaching working (ask a career question, get a thoughtful response with context).
5. **Day 10:** Nudge engine sends first proactive reminder.
6. **Day 14:** Brian is using it daily for goal tracking and career coaching.

If Day 14 produces an app Brian checks every morning, Phase 1 is on track.
