# Using AI Development Tools Effectively on Large Codebases

A practical guide to context management, architecture patterns, and team workflows when working with 100K+ line projects using Claude Code, Cursor, Gemini, and enterprise AI coding tools.

**Last Updated:** 2026-03-18
**Status:** Ready to implement
**Scope:** Large codebases (100K+ LOC), enterprise teams, complex architectures

---

## Table of Contents

1. The Challenge at Scale
2. Codebase Onboarding for AI
3. Context Strategies at Scale
4. Gemini's 2M Token Advantage
5. Multi-Agent Patterns
6. Monorepo Strategies
7. Large Refactoring Patterns
8. Performance and Indexing
9. Team Coordination
10. Case Studies
11. Checklist & Resources

---

## 1. The Challenge at Scale: The Reality of 100K+ Line Codebases

### The Core Problem

When working with large codebases, AI development tools face interconnected challenges that simple context expansion doesn't solve:

- **Context windows can't hold entire codebases:** Even Gemini's 2M token window (~500K lines) represents only 15-30% of enterprise-scale systems. A typical large codebase has 50+ interdependencies you need to understand.

- **AI suggests incompatible patterns:** Research shows 45% of AI suggestions violate existing architecture or introduce inconsistent patterns. AI doesn't "understand" your system's conventions because they're buried in 100K+ lines it hasn't seen.

- **Navigation and discovery failures:** Finding the "right place to edit" requires understanding call graphs, module boundaries, and architectural constraints. AI struggles to navigate this without explicit guidance.

- **The "onboarding problem":** A new developer takes 2-3 weeks to understand a large codebase. AI needs equivalent grounding or it produces code that "looks right" but breaks in subtle ways.

- **Test coverage gaps:** With partial context, AI generates code that passes its mental model but fails integration tests. 87% of AI-generated code in enterprise settings introduces bugs that only surface during integration testing.

### Numbers That Matter

| Challenge | Impact | Solution |
|-----------|--------|----------|
| **50-file context only** | Misses 80% of architecture | Hierarchical CLAUDE.md + indexed code navigation |
| **45% incompatible suggestions** | Churn in code review | .cursorrules/.mdc enforcement + AI-specific hooks |
| **Indexing time (naive)** | 15-20 minutes for monorepos | .cursorignore reduces to 2-4 minutes |
| **Context bloat after 50 turns** | 60% of tokens wasted on history | /compact + modular context loading |
| **Refactoring 50+ files safely** | Manual verification takes weeks | Incremental phases + test gates |

---

## 2. Codebase Onboarding for AI: Creating System Memory

The difference between AI that "helps" and AI that "understands" is a well-designed knowledge base that captures your codebase's core patterns, constraints, and architecture.

### The Onboarding Ladder

```
Level 1 (Basic):   Generic CLAUDE.md (tech stack, commands)
Level 2 (Smart):   Architecture overview + module map + patterns
Level 3 (Expert):  Hierarchical CLAUDE.md + .cursorrules + indexed docs
Level 4 (Master):  Module-level CLAUDE.md + MCP servers + automated indexing
```

Most teams start at Level 1 and get 60-70% benefit. Scaling to Level 3 unlocks 85-90% of AI effectiveness.

### CLAUDE.md for Large Projects

Standard CLAUDE.md (from Claude Code Power User Guide) works for small-to-medium projects (10K-50K LOC). Large codebases need more structure:

**Root CLAUDE.md** (~150-200 lines) should include:

```markdown
# Project: [Name]

## Tech Stack
- Language: [primary language]
- Framework: [primary framework]
- Package Manager: [npm/cargo/etc]
- Build System: [if applicable]
- Database: [PostgreSQL/DynamoDB/etc]

## Architecture Overview

### System Layers (From High-Level to Implementation)
1. **Client Layer** — SPA/mobile apps (files: `/apps/web`, `/apps/mobile`)
2. **API Gateway** — Request routing, auth, rate limiting (`/services/gateway`)
3. **Business Logic Services** — Core functionality (`/services/[business domain]`)
4. **Data Layer** — Database access, caching (`/packages/db`, `/packages/cache`)
5. **Infrastructure** — Terraform, K8s, observability (`/infra`)

### Key Architectural Constraints
- Strict service boundaries (imports only via interfaces in `/contracts`)
- No circular dependencies across service layers
- All external integrations wrapped in `/packages/integrations`
- Feature flags mandatory for any cross-service changes

## Critical Files (Never Edit Without Plan)
- `package.json`, `pom.xml`, `Cargo.toml` — Dependency manifest (coordinate changes)
- `src/index.ts`, `main.go` — Application entry point
- Database schema migrations (in `/migrations`) — Must include rollback + tests
- Configuration files (`.env*`, Kubernetes manifests) — Sensitive data patterns

## Code Conventions

### File Organization
```
/services/payments/
  ├── src/
  │   ├── __tests__/          — Tests live in same directory as code
  │   ├── handlers/           — HTTP endpoint handlers
  │   ├── services/           — Business logic (ONLY imports from this dir)
  │   ├── repositories/       — Data access layer
  │   └── index.ts            — Exports public API
  ├── package.json
  └── README.md
```

### Naming Conventions
- Services: kebab-case (`payment-processor`, not `PaymentProcessor`)
- Files: snake_case for data files, PascalCase for classes/components
- Functions: camelCase
- Constants: UPPER_SNAKE_CASE
- Type/Interface names: PascalCase with `I` prefix (e.g., `IPaymentGateway`)

### Import Rules
- Absolute imports from service root: `import { PaymentService } from 'src/services/payment'`
- Never use relative paths beyond 2 levels: `import { x } from '../../../utils'` is forbidden
- Services import only from `/contracts`, never directly from other services

### Error Handling
- Custom error classes inherit from `BaseError` (in `/packages/errors`)
- All errors logged with context: `logger.error('Payment failed', { orderId, paymentId, error })`
- Recovery strategy explicit in error message or comment

### Testing Standards
- File naming: `*.test.ts`, `*.spec.ts`
- Test organization: Describe block per class/function, one assertion per test
- Coverage target: 80%+ per service
- Mock external dependencies (databases, APIs) — use provided test helpers

## Common Gotchas
1. **Monorepo dependency paths** — If adding a service, update `/packages/service-registry` to allow imports
2. **Database migrations** — Always test rollback; changes block other developers if broken
3. **Feature flags** — Check `/contracts/feature-flags.ts` before adding new flags
4. **Async race conditions** — Use provided `mutex` from `/packages/concurrency` for distributed locking
5. **Type safety** — No `any` types unless explicitly approved; use discriminated unions for complex types

## Commands
- `npm run dev` — Start dev server with hot reload
- `npm run test` — Run all tests
- `npm run test:watch` — Watch mode for TDD
- `npm run test:coverage` — Coverage report (must exceed 80%)
- `npm run build` — Production build
- `npm run lint` — Run ESLint (fixes auto-fixable issues: `npm run lint:fix`)
- `npm run type-check` — TypeScript strict mode validation

## Deployment & Infrastructure
- **Staging:** Deploy to `staging` branch automatically
- **Production:** Requires tag (`v1.2.3`); manual approval on GitHub
- **Rollback:** `npm run rollback:prod [timestamp]`
- **Status:** See deployment dashboard at `https://deploy.internal/`

## Module Ownership & Contacts
| Module | Owner | Slack |
|--------|-------|-------|
| `/services/payments` | @payments-team | #team-payments |
| `/services/auth` | @security-team | #team-security |
| `/packages/db` | @platform-team | #team-platform |

## When You're Unsure
1. Check the `/docs/architecture` directory for design decisions
2. Ask in Slack before large changes (5+ files)
3. Create an ADR (Architecture Decision Record) for patterns that are new or system-wide
4. When stuck: pairing with module owner is the fastest path
```

**Rationale:**
- **Layer overview:** AI needs to understand the dependency flow (client → gateway → services → data)
- **Critical files:** Prevents AI from making unsafe edits
- **Import rules:** Specific enough that AI can validate its own suggestions
- **Gotchas section:** Captures repeated mistakes (this is where hallucinations cluster)
- **Ownership:** Tells AI who to consult, preventing siloed changes

### Module-Level CLAUDE.md

For large services (each 5K+ LOC), create `.claude/CLAUDE.md` alongside the module:

```markdown
# Module: Payment Processing Service

## Purpose
Handles payment authorizations, captures, refunds, and reconciliation against upstream payment gateways.

## Public API
- `PaymentService.authorize()` — Check if payment can be charged
- `PaymentService.capture()` — Charge the customer
- `PaymentService.refund()` — Return money to customer

See `src/index.ts` for full exported API.

## Internal Architecture
This service uses a state machine:
- `pending` → `authorized` → `captured` (→ `refunded`)

Each state transition is atomic. See `src/state-machine.ts` for implementation.

## Dependencies
- **Incoming:** Called by `/services/orders` when order is placed
- **Outgoing:** Calls upstream gateways (Stripe, PayPal) via `/packages/payment-gateways`
- **Data:** Writes to `payments` table via `/packages/db`

## Where to Edit

### Adding a new payment method (e.g., Apple Pay)
1. Add handler in `src/handlers/apple-pay.ts`
2. Register in `src/index.ts` exports
3. Add tests in `src/__tests__/apple-pay.test.ts`
4. Update `README.md` to document the new method

### Adding a new field to payment record
1. Create database migration in `/migrations/payments/[date]-add-[field].sql`
2. Update type in `src/types/Payment.ts`
3. Update serialization in `src/repositories/payment-repository.ts`
4. NO other service should read this field directly — expose via `PaymentService` API

### Debugging payment failures
1. Find transaction in dashboard or logs
2. Check `src/gateways/[provider].ts` for the specific gateway
3. Most failures are auth/rate limit — see error codes in `src/types/GatewayError.ts`

## Testing Checklist
- [ ] Happy path: successful charge
- [ ] Error cases: gateway timeout, insufficient funds, rate limit
- [ ] Idempotency: calling authorize twice with same order should deduplicate
- [ ] Refund: full and partial refunds
- [ ] State transitions: only allowed transitions work, invalid ones throw

## Common Issues & Fixes
| Issue | Cause | Fix |
|-------|-------|-----|
| Duplicate charges | Idempotency key not passed | Ensure `idempotencyKey` is stable across retries |
| Webhook failures | Service unreachable | Update `PAYMENT_WEBHOOK_URL` in `.env` |
| Rate limits | Too many req/sec | Use backoff in `src/gateways/stripe.ts` — already implemented |
```

**Key benefit:** Each developer working on a module has a reference guide that AI can use to understand its boundaries and responsibilities.

### Codebase Indexing Strategies

#### Strategy 1: Semantic Index + Keyword Index (Cursor/Augment Code)

**Cursor** maintains a dual index:
- Semantic index (embeddings): Finds conceptually related code
- Keyword index: Fast lookup for exact names, APIs

**Setup:**
```bash
# Create .cursorignore at project root
# Exclude: dependencies, build artifacts, large data files

node_modules/**
dist/**
build/**
.next/**
**/*.log
**/migrations/**  # Unless actively working on DB changes
**/vendor/**
**/target/**
```

**For monorepos, be more surgical:**
```bash
# Only index the package you're working on
node_modules/**
dist/**
build/**
apps/*/node_modules/**
apps/mobile/**           # If you're working on backend, skip frontend
apps/admin/**
packages/*/dist/**
**/*.log
```

**Benefit:** Reduces indexing from 15-20 minutes to 2-4 minutes. Reindexing is automatic on file saves.

#### Strategy 2: Graph-Based Navigation (GitHub Copilot + Claude Code)

For understanding cross-module dependencies:

```bash
# Create .indexconfig.json at project root
{
  "indexing": {
    "rootPaths": ["src", "packages", "services"],
    "ignorePaths": ["node_modules", "dist", ".git"],
    "maxFileSize": 100000,  # Skip very large generated files
    "priorityPaths": {
      "src/core": 1.0,       # Core business logic (full index)
      "src/utils": 0.5,      # Utils (light index)
      "src/tests": 0.2       # Tests (minimal index)
    }
  }
}
```

This tells indexers to prioritize core business logic (100% indexed) vs. utilities (50% context sampling) vs. tests (minimal).

#### Strategy 3: Modular Documentation Index

Create `ARCHITECTURE.md` at root with a file registry:

```markdown
# Architecture & File Index

## Quick Module Lookup
- **Auth System** → `/services/auth` (1,200 LOC, critical path)
  - Entry: `src/index.ts`
  - Tests: `src/__tests__/`
  - Dependencies: `/packages/jwt`, `/packages/db`

- **Payment Processing** → `/services/payments` (3,400 LOC)
  - Entry: `src/payment-service.ts`
  - Gateway integrations: `src/gateways/`
  - Tests: `src/__tests__/`
  - Dependencies: `/packages/payment-gateways`, stripe SDK

## Cross-Module Dependencies
```
client → gateway → [auth, orders, payments, notifications] → [db, cache, integrations]
```

## Largest Files (Worth Knowing)
- `src/payment-service.ts` (420 LOC) — Main orchestration
- `src/gateways/stripe.ts` (310 LOC) — Stripe implementation
- `src/__tests__/integration.test.ts` (280 LOC) — End-to-end tests
```

This gives AI a "map" without dumping the entire codebase.

---

## 3. Context Strategies at Scale

Once codebase onboarding is solid, the next challenge is context efficiency. A typical large-codebase session includes:

- 50 file references
- 100K+ tokens of conversation history
- Multiple CI/CD logs
- Complex error traces

Without discipline, you hit context limits within 30 turns.

### Strategy 1: Targeted Context (Load Only What's Relevant)

**Claude Code pattern:**

```text
claude> Implement the payment refund feature. Read these first:
  @services/payments/src/payment-service.ts
  @services/payments/src/gateways/stripe.ts
  @services/orders/src/order-repository.ts
  @CLAUDE.md

Then plan the changes. What files will you modify?
```

This pre-loads 5-6 key files (~15K tokens) instead of making Claude discover them.

**Cursor pattern:**

```text
# In .cursorrules or @-mention:
When implementing features, always:
1. Start in /services/[module]/src/index.ts (public API)
2. Follow the call chain to find implementation
3. Never jump to a file without understanding why
```

**Benefit:** Reduces tokens spent on "exploration" by 40-50%.

### Strategy 2: Hierarchical CLAUDE.md (Root + Module Level)

**Root CLAUDE.md** (100 lines) — Project-wide conventions and overview.

**Module-level .claude/CLAUDE.md** (100 lines per module) — Load on demand when working in `/services/payments`.

**Pattern:**
```
project-root/
├── CLAUDE.md                    # Org-wide (always loaded)
├── docs/
│   └── ARCHITECTURE.md          # Referenced by CLAUDE.md, not loaded by default
└── services/
    └── payments/
        ├── .claude/
        │   └── CLAUDE.md        # Loaded only when working in /services/payments
        └── src/
```

**Claude Code behavior:** When you mention `@services/payments`, it automatically loads that module's `.claude/CLAUDE.md`.

**Benefit:** Each module contributes only 50-100 tokens when active, instead of all modules adding to context at all times.

### Strategy 3: Progressive Disclosure

Instead of long CLAUDE.md files, point to specific documentation:

```markdown
# Project: Payments System

## Quick Start
See @GETTING-STARTED.md

## Architecture
See @docs/ARCHITECTURE.md for system design, layer overview, and module dependencies.

## Payment Service
Working on /services/payments? See @services/payments/.claude/CLAUDE.md

## Database
Schema and migrations → @docs/DATABASE.md
Query patterns → @docs/QUERY-PATTERNS.md

## Testing
Test standards → @docs/TESTING.md
Running tests → See CLAUDE.md under "Commands"
```

This keeps the root CLAUDE.md at 80-100 lines while making deeper knowledge accessible.

### Strategy 4: Codebase-Aware Prompting

**Use @-mentions strategically:**

```text
claude> Implement subscription renewal. First, check how payment refunds are structured.
@services/payments/src/refund-handler.ts

How do they handle async state? Should subscription renewal follow the same pattern?
```

Instead of:
```text
claude> Implement subscription renewal. Make it async and handle failures gracefully.
```

**Why:** Named file references are 10-15x more effective than vague instructions at scale. AI uses the actual code as the pattern source.

### Strategy 5: Session Scope Management

Large codebases require session discipline:

**One goal per session:**
- Session A: Plan architecture + create interfaces
- Session B: Implement service A + tests
- Session C: Implement service B + tests
- Session D: Integration tests + deployment

**Between sessions, use `/clear`:**
```text
/clear
Focus on implementing service B. Review CLAUDE.md and the interfaces from Session A.
```

**Benefit:** Each session uses 100-200K tokens focused on one goal, instead of 400K tokens scattered across 4 goals.

---

## 4. Gemini's 2M Token Advantage: When and How to Use It

Gemini 1.5 Pro and Gemini 2.0 (available 2026) offer 2 million tokens (~500K lines of code). This changes the game for certain tasks.

### Use Gemini When You Need Whole-Codebase Analysis

**Ideal Gemini tasks:**

1. **Architecture review** — Understand entire system design before major changes
   - Load entire codebase (if <500K lines)
   - Identify architectural violations, anti-patterns, tech debt clusters
   - Generate refactoring roadmap

2. **Large refactoring** — 50+ file changes with confidence
   - See all call sites, dependencies, tests
   - Detect impact before implementation
   - Prevent breakage through full context visibility

3. **Security audit** — Find vulnerabilities across the whole system
   - All auth paths visible
   - Data flow analysis across services
   - Credential/secret handling verification

4. **Legacy code resurrection** — Understand undocumented systems
   - Load entire system to infer architecture
   - Generate documentation + cleanup plan

### Gemini vs. Claude Code Trade-offs

| Task | Gemini | Claude Code |
|------|--------|-------------|
| **Whole-codebase understanding** | ✅ Load all 300K lines, analyze patterns | ❌ 100K token limit, sample-based understanding |
| **Daily incremental work** | ❌ Overkill, slower, expensive | ✅ Fast, cost-efficient, good enough |
| **Finding root cause across 50 files** | ✅ All files in context, perfect trace | ⚠️ Plan Mode helps, but manual exploration needed |
| **Writing tests** | ⚠️ Good, but slower | ✅ Faster, incremental test writing |
| **Large refactoring** | ✅ See all impact, prevent breakage | ⚠️ Phase it, use multiple sessions |
| **Code review** | ✅ Understands full impact of changes | ⚠️ Can miss cross-file issues |

### Practical Workflow: Dump + Analyze + Implement

**Phase 1: Gemini Analysis (Day 1)**
```text
[Load entire codebase into Gemini context]

Analyze this codebase for:
1. Architectural patterns (layers, services, dependencies)
2. Tech debt hotspots (high complexity, poor testing, mixed concerns)
3. Security vulnerabilities (auth, data validation, credential handling)
4. Migration opportunities (e.g., upgrade TypeScript, modernize patterns)

Produce a report with:
- Top 5 architectural issues
- Top 5 security vulnerabilities (with locations)
- Recommended refactoring order
- Effort estimates (hours per task)
```

**Output:** A structured analysis that becomes your refactoring roadmap.

**Phase 2: Claude Code Implementation (Days 2-5)**
```text
Based on this analysis from Gemini:
[Paste Gemini's output]

Let's start with issue #1. Create a plan and then implement it.
Run tests after each change. Are there any breakages?
```

**Phase 3: Gemini Verification (Day 6)**
```text
[Reload refactored codebase]

Verify that these issues are resolved:
[Paste original issues from Phase 1]

Check for:
- Regressions (did we break anything?)
- Incomplete fixes
- New issues introduced during refactoring
```

**Cost math:**
- Gemini 2M token analysis: ~$0.50-$1.00 (input-heavy)
- Claude Code implementation: ~$10-$20 (multiple turns, edits)
- Gemini verification: ~$0.50 (read-heavy)
- **Total: ~$11-$21 for large refactoring**

vs.

- Manual review/testing: 40+ hours of developer time ($2000+)

### Important Caveat: Context Degradation

Research shows that **large contexts cause accuracy degradation:**

- LLMs "forget" information buried in long contexts
- Accuracy degradation isn't gradual—it's catastrophic
- Adding more context beyond 30-40% coverage actually hurts accuracy

**Real example:** Feeding a 300-file Python project to Gemini resulted in:
- Changed 31 files at once (not incremental)
- Introduced 260+ type errors
- Created circular dependencies

**Best practice:** Even with 2M tokens, **use Gemini for analysis, not implementation**. Use it to understand the system, then have Claude Code implement incrementally.

### Gemini Implementation Constraints

If you do use Gemini for implementation, enforce guardrails:

```text
When implementing changes:
1. Modify ONLY files I explicitly list
2. Never refactor more than 5 files per response
3. Run tests after each change
4. Ask permission before making changes outside the 5-file limit
5. Stop if tests fail—fix before continuing
```

This prevents the "simultaneous refactoring explosion" that breaks builds.

---

## 5. Multi-Agent Patterns for Large Codebases

Large projects often have parallel work: one developer building features, another refactoring, a third debugging. AI agents can parallelize this work.

### Pattern 1: Module-Scoped Agents

Each service/module gets its own agent with domain-specific instructions:

```markdown
# Agent: PaymentServiceDeveloper

You are a specialist in the payment processing service.

## Responsibilities
- Implement features in /services/payments
- Write tests
- Coordinate with upstream gateways (Stripe, PayPal)
- Never modify /services/orders or /services/notifications without consultation

## Always Reference
- @services/payments/.claude/CLAUDE.md
- @docs/PAYMENT-ARCHITECTURE.md
- Run `npm test` in /services/payments/ after changes

## Ask Before:
- Modifying database schema (touch /migrations/)
- Adding dependencies (touch package.json)
- Creating new API endpoints (needs /services/gateway coordination)
```

**Usage:**
```bash
claude --agent payment-developer
# This session is now focused on /services/payments with specialized context
```

**Benefit:** Each agent's context is optimized for its domain. No wasted tokens on irrelevant code.

### Pattern 2: Parallel Agents with Coordination

Team of agents working on different parts simultaneously:

```
Main Session (Coordinator)
├── Agent 1: Implement Service A (parallel)
├── Agent 2: Implement Service B (parallel)
├── Agent 3: Write integration tests (parallel)
└── [Wait for all to finish, check for conflicts]
```

**Setup:**
```bash
claude --agent-teams
# Launches team coordinator mode

# Main prompt:
We need to implement feature X, which touches 3 services.
- Agent-ServiceA: Implement new payment gateway integration
- Agent-ServiceB: Update order processing to use new gateway
- Agent-ServiceC: Write integration tests
- Coordinator: Track progress, resolve conflicts, merge when ready
```

**Coordination rules:**
- Each agent owns specific files (no overlaps)
- Agents run in parallel, reducing wall-clock time
- Coordinator monitors for merge conflicts

**Cost:** ~15x more tokens than single session (each agent has full context window), but 3-4x faster wall-clock time.

**Use when:**
- Work can be clearly divided into independent modules
- Wall-clock time matters (shipping deadline)
- You can afford the token cost

### Pattern 3: Sequential Agents with Handoff

For tightly-coupled work, use sequential handoff:

```text
Agent 1 (Research): Investigate the codebase
  → Produces: Architecture analysis + refactoring plan

Agent 2 (Architect): Review plan + refine architecture
  → Produces: Detailed design document + file-by-file changes

Agent 3 (Implementer): Execute the design
  → Produces: Code changes + tests

Agent 4 (Reviewer): Code review + identify issues
  → Produces: Review feedback + blockers

Agent 1 (Fix): Address feedback
  → Produces: Final, merged code
```

**Example workflow:**

**Agent 1 (Research):**
```
Analyze /services/auth and identify:
1. Current architecture
2. Security issues
3. Refactoring opportunities
Produce a report with findings and recommendations.
```

**Agent 2 (Architect):**
```
[Receive Agent 1's report]

Create a detailed implementation plan:
- Which files change
- New abstractions needed
- Testing strategy
- Risk assessment

Format: Can be executed step-by-step.
```

**Agent 3 (Implementer):**
```
[Receive Agent 2's plan]

Execute the plan step-by-step. Use the TDD pattern:
- Write tests first
- Implement to pass tests
- Verify no regressions
```

**Benefit:** Each agent does what it's best at. Research agent explores broadly; implementer executes precisely.

### Conflict Prevention Strategies

When multiple agents touch the same codebase:

**1. File Ownership (Strict)**
```markdown
# FILE_OWNERSHIP.md

/services/payments/*    → Agent-PaymentDev
/services/orders/*      → Agent-OrdersDev
/packages/db/*          → Agent-Platform
/docs/*                 → Agent-Docs
```

Each agent works ONLY in its area. Changes to shared code require explicit coordination.

**2. Interface Stability**
```markdown
# CONTRACTS.md

Public API contracts (never change without approval):
- `PaymentService.authorize()` signature + behavior
- `OrderRepository.findById()` signature + behavior

Implementation details can change. Contracts cannot.
```

**3. Async Testing**
```bash
# Before merging agent changes, run full test suite in each affected module
npm run test:all --changed-only
```

---

## 6. Monorepo Strategies: Managing Multiple Projects with AI

Monorepos (multiple projects in one repo) create unique challenges for AI tools. A single context can't efficiently cover both web app and backend API.

### Strategy 1: Tool Separation by Package

Use different tools for different packages:

| Package | Tool | Why |
|---------|------|-----|
| `/apps/web` (React, 15K LOC) | Cursor | Fast iteration, component editing |
| `/services/api` (Node, 40K LOC) | Claude Code | Complex logic, multi-file refactoring |
| `/packages/common` (Shared types, 5K LOC) | Claude Code | Affects multiple packages, needs coordination |
| `/infrastructure` (Terraform, 10K LOC) | Gemini | One-time reviews, infrastructure analysis |

**Rationale:**
- **Cursor** excels at UI work (components, styling, quick fixes) with its fast indexing
- **Claude Code** better for complex backend logic, cross-module changes, refactoring
- **Gemini** for analytical work, architecture reviews, one-time infrastructure setup

### Strategy 2: Package-Level .cursorrules and CLAUDE.md

Create configuration at the package level:

```
monorepo/
├── CLAUDE.md                # Root (monorepo conventions)
├── .cursorrules             # Root (shared across packages)
├── apps/
│   └── web/
│       ├── .cursorrules     # Web-specific rules (overrides root)
│       ├── .claude/
│       │   └── CLAUDE.md    # Web context (loads when working in /apps/web)
│       └── src/
├── services/
│   └── api/
│       ├── .cursorrules     # API-specific rules
│       ├── .claude/
│       │   └── CLAUDE.md    # API context
│       └── src/
└── packages/
    └── common/
        ├── .cursorrules
        ├── .claude/
        │   └── CLAUDE.md
        └── src/
```

**Root .cursorrules** (shared):
```yaml
rules:
  - Never import from /apps/ in /packages/ or /services/
  - All types in /packages/common/types are source of truth
  - Package.json changes require checking dependents
```

**Web-specific .cursorrules** (/apps/web/.cursorrules):
```yaml
rules:
  - Use React hooks (functional components only)
  - Components live in src/components/, organized by feature
  - Use the Button component from @common/ui
```

**API-specific .cursorrules** (/services/api/.cursorrules):
```yaml
rules:
  - All handlers export `Router` type
  - Database queries in repository layer only
  - Middleware in /src/middleware/
```

### Strategy 3: Monorepo CLAUDE.md Structure

**Root CLAUDE.md** (150 lines):

```markdown
# Monorepo: [Company Name] Products

## Structure
- `/apps/` — User-facing applications
- `/services/` — Backend services
- `/packages/` — Shared code
- `/infrastructure/` — IaC, deployment

## Cross-Project Rules

### Dependency Flow (Strict)
```
apps/web → services/api ← packages/common
          ↓
        packages/db
        packages/auth
        packages/cache
```

- **No cycles:** apps cannot depend on services
- **Common is shared:** /packages/* can be imported by anyone
- **Services are independent:** /services/a should not import /services/b

### Shared Types Location
All types used across packages → `/packages/common/types/`

When you see an import error about a type:
1. Check if it exists in `/packages/common/types/`
2. If not, move it there (not in multiple places)
3. Update imports in all files

### Database Migrations
- Location: `/migrations/`
- Format: `[date]-[description].sql`
- When working on DB: Check what other teams changed recently

## Package-Specific Context
When working in a specific package, read its context:
- `/apps/web/.claude/CLAUDE.md` — Web app conventions
- `/services/api/.claude/CLAUDE.md` — API conventions
- `/packages/common/.claude/CLAUDE.md` — Shared code

## Commands (Monorepo Level)
- `npm run dev` — Start all services (web + api + watchers)
- `npm run test` — Test all packages
- `npm run test --workspace=@company/api` — Test just API
- `npm run build` — Build all for production

## Integration Points
| Feature | Web | API | Database |
|---------|-----|-----|----------|
| User registration | Forms + UI | User creation endpoint | users table |
| Login | Form + redirect | JWT issuance | sessions table |
| Payment | Checkout UI | Payment gateway integration | payments table |

When touching integration points, ping the owners in Slack (see below).

## Owners by Package
- `/apps/web` → @frontend-team
- `/services/api` → @backend-team
- `/packages/common` → @platform-team
```

**Per-package CLAUDE.md** (/services/api/.claude/CLAUDE.md):

```markdown
# Service: API

## Purpose
REST API serving /apps/web and /apps/mobile

## Architecture
```
Request → Middleware (auth, validation) → Handler (routing) → Service (business logic) → Repository (data)
```

## Key Files
- `src/index.ts` — Express app setup
- `src/handlers/` — Endpoint implementations
- `src/services/` — Business logic
- `src/repositories/` — Database queries

## Imports from Other Packages
- ✅ `/packages/common/types` — Shared types
- ✅ `/packages/auth` — Auth helpers
- ✅ `/packages/db` — Database client
- ❌ `/apps/web` — NEVER (circular)
- ❌ `/services/other-service` — NEVER (independent services)

## Running Locally
```bash
npm run dev  # Starts on port 3000
# Test: curl http://localhost:3000/health
```
```

### Strategy 4: Shared vs. Package-Level Dependencies

Monorepos force a choice: shared dependencies vs. isolated dependencies.

**Shared (in root package.json):**
```json
{
  "dependencies": {
    "express": "^4.18.0",
    "pg": "^8.8.0",
    "@company/common": "workspace:*",
    "zod": "^3.20.0"
  }
}
```

- One version across all packages
- Forces compatibility (good for security, bad for experimentation)
- Simplifies CLAUDE.md (don't need per-package dependency rules)

**Isolated (in /services/api/package.json):**
```json
{
  "dependencies": {
    "express": "^4.18.0",
    "pg": "^8.8.0",
    "stripe": "^11.0.0"
  }
}
```

- /apps/web can use React 18, /services/api can stay on React 16 (if needed for some reason)
- Services can be independent, run different Node versions
- Adds complexity (need per-package CLAUDE.md)

**Recommendation:** Start with shared (simpler), move to isolated only if you have a specific reason (e.g., different deployment strategies, different teams with different standards).

### Strategy 5: MCP Server Per Service

For large monorepos, create a custom MCP server that exposes service metadata:

```python
# monorepo-mcp-server.py
from mcp.server import Server
from typing import Any

app = Server("monorepo-navigator")

@app.tool()
def get_service_info(service_name: str) -> dict:
    """Get metadata for a service (owner, dependencies, entry point)"""
    services = {
        "api": {
            "owner": "@backend-team",
            "entry": "services/api/src/index.ts",
            "dependencies": ["@company/common", "pg", "express"],
            "test_command": "npm run test --workspace=@company/api",
        },
        "web": {
            "owner": "@frontend-team",
            "entry": "apps/web/src/App.tsx",
            "dependencies": ["react", "@company/common"],
            "test_command": "npm run test --workspace=@company/web",
        }
    }
    return services.get(service_name, {})

@app.tool()
def find_dependents(package: str) -> list[str]:
    """Find which services depend on a package"""
    # Parses package.json files, builds dependency graph
    # Returns: ["@company/web", "@company/api", ...]
    pass

@app.tool()
def get_file_ownership(file_path: str) -> str:
    """Get the owner (team) for a file"""
    # Uses FILE_OWNERSHIP.md or git blame
    return "@backend-team"  # example
```

**Usage in Claude Code:**
```text
Before making changes to /packages/common, check who depends on it:
@find_dependents("@company/common")

Should return: web, api, notifications — need to test all three.
```

This reduces the manual "check what breaks" work.

---

## 7. Large Refactoring Patterns: 50+ File Changes Safely

Refactoring a large codebase (50+ files) with AI is high-risk. One wrong change breaks everything. Here's how to do it safely.

### The Phased Approach

Instead of one massive refactor, break into phases:

**Phase 1: Analysis (Gemini, 1 day)**
```text
[Load codebase]

Analyze our payment system for refactoring opportunities:
1. What's the current structure?
2. Where's the complexity?
3. What's the plan to improve it?

Produce a phased refactoring plan:
- Phase A: Introduce abstractions (10 files, 1 day)
- Phase B: Migrate code (20 files, 2 days)
- Phase C: Delete old code (5 files, 1 day)
- Phase D: Test & verify (2 days)
```

**Phase 2a: Introduce Abstractions (Claude Code, 1 day)**
```text
Based on this plan:
[Paste analysis from Phase 1]

Implement Phase A. Create new abstractions without changing existing code.
Write tests for new code.
Can existing code coexist with new code without breaking?
```

**Phase 2b: Migrate Code (Claude Code, 2 days)**
```text
Now migrate old code to use new abstractions.
One file at a time. Test after each file.
If migration breaks anything, stop and fix.
```

**Phase 2c: Cleanup (Claude Code, 1 day)**
```text
Delete old code (it's been replaced).
Run full test suite.
```

**Phase 3: Verification (Gemini, 1 day)**
```text
[Load refactored codebase]

Verify the refactoring:
1. Did we fix the original issues?
2. Did we introduce any regressions?
3. Is the code clearer than before?
```

**Timeline: ~5 days, with 4 distinct gates where things can go wrong.**

### Incremental, Test-Gated Changes

Never refactor in a way that could break the build. Use this pattern:

```text
claude> Refactor PaymentService to use dependency injection.

Before you start, write tests that verify:
1. New code (DI-based) works correctly
2. Old code (non-DI) still works
3. Both can coexist

Then, one file at a time:
1. Test file
2. Migrate it to DI
3. Run tests — must pass before moving on
4. If tests fail, stop and diagnose

Stop if more than 3 consecutive tests fail.
```

**Why step-by-step:**
- Each change is reversible (git revert one commit)
- Failure is caught early, not after 50 files changed
- Easier to diagnose what broke

### Feature Flags for AI-Driven Changes

When refactoring core features, use feature flags:

```typescript
// src/payment-service.ts
export class PaymentService {
  async charge(order: Order): Promise<Result> {
    if (featureFlags.useNewPaymentEngine) {
      // New refactored code (AI wrote this)
      return this.chargeWithNewEngine(order);
    } else {
      // Old code (stable, tested, known to work)
      return this.chargeWithOldEngine(order);
    }
  }
}
```

**Deployment:**
1. Deploy code with flag OFF (new code hidden)
2. Run full test suite — flag OFF must still work
3. Gradually enable flag for 1% of users
4. Monitor for failures
5. Ramp up to 100% over 24 hours

**If something breaks:**
- Disable flag instantly
- Users fall back to old code
- No emergency rollback needed

### Test Coverage Gates

Before large refactors, ensure you have good test coverage:

```bash
# Before refactoring
npm run test:coverage

# Must have:
# - Statements: 80%+
# - Branches: 75%+
# - Functions: 80%+
# - Lines: 80%+
```

If coverage is low, write tests first (before refactoring):

```text
claude> Current test coverage is 65%. Before refactoring, let's increase it to 80%.

Write tests for these untested functions:
- PaymentService.authorize()
- PaymentService.capture()
- PaymentService.refund()

Don't change the implementation. Only write tests.
Run tests to verify they all pass.
```

Once coverage is high, the refactoring is safer.

### Documentation of Changes

For large refactors, maintain a changelog:

```markdown
# Refactoring Log: Payment Service

## Phase A: Introduce Abstractions (2026-03-15 to 2026-03-16)

**Goal:** Decouple payment gateways from business logic.

**Changes:**
- Created PaymentGateway interface (`src/gateways/gateway.interface.ts`)
- Implemented Stripe gateway (`src/gateways/stripe.ts`)
- Implemented PayPal gateway (`src/gateways/paypal.ts`)
- Updated PaymentService to use interface

**Tests Added:** 12 new tests, 4 new fixtures
**Files Changed:** 8
**Lines Added:** 420, Removed: 0

**Status:** ✅ All tests passing

## Phase B: Migrate Existing Code (2026-03-17 to 2026-03-19)

**Goal:** Update existing code to use gateway interface.

**Changes:**
- Updated `src/handlers/charge.ts` to use PaymentService.charge()
- Updated `src/handlers/refund.ts` to use PaymentService.refund()
- Removed direct gateway calls (old pattern)

**Tests Added:** 8 new tests
**Files Changed:** 6
**Lines Added:** 200, Removed: 150

**Status:** ✅ All tests passing, 0 regressions

## Phase C: Cleanup (2026-03-20)

**Goal:** Delete old, unused code.

**Changes:**
- Removed `src/old-gateway.ts` (replaced by interface)
- Removed `src/old-payment-logic.ts` (replaced by service)

**Files Deleted:** 2
**Lines Removed:** 380

**Status:** ✅ All tests passing, codebase cleaner

**Pre vs. Post Metrics:**
- Payment service LOC: 450 → 380 (15% reduction)
- Test coverage: 72% → 86% (14% improvement)
- Cyclomatic complexity: 12 → 7 (more testable)
```

This log helps future developers understand what changed and why.

---

## 8. Performance and Indexing: Keeping AI Tools Fast at Scale

Large codebases can slow down AI tools dramatically. Indexing can take 15-20 minutes; context searches become slow.

### .cursorignore Optimization

**Without .cursorignore:**
```
Indexing time: 15-20 minutes
Index size: 2.5 GB
Context search latency: 3-5 seconds
```

**With strategic .cursorignore:**
```
Indexing time: 2-4 minutes
Index size: 300 MB
Context search latency: 200-500 ms
```

**Recipe:**

```bash
# .cursorignore at project root

# Dependencies (huge, unnecessary)
node_modules/**
target/**
venv/**
vendor/**

# Build artifacts (large, generated)
dist/**
build/**
.next/**
out/**
__pycache__/**
*.pyc

# Large data files
**/*.csv
**/*.xlsx
**/*.json.bak

# Logs
**/*.log
logs/**

# Environment files (secrets)
.env*
!.env.example

# Version control
.git/**
.github/**

# IDE files
.vscode/**
.idea/**
.DS_Store

# For monorepos, be selective:
# Keep only the service you're working on

apps/mobile/**           # Skip mobile if working on backend
apps/desktop/**          # Skip desktop
services/analytics/**    # Skip analytics

packages/*/dist/**       # Skip build artifacts per package
packages/*/node_modules/**
```

**Monorepo optimization:**

```bash
# .cursorignore for backend developers

# Skip everything except backend
apps/web/**
apps/mobile/**
infrastructure/**

# Keep packages but not build artifacts
packages/*/dist/**
packages/*/build/**
packages/*/node_modules/**

# Keep only:
# - services/api/src
# - packages/common/src
# - packages/db/src
```

**Result:** 15-minute indexing becomes 3 minutes.

### .gitignore Alignment

Your `.cursorignore` should be a superset of `.gitignore`:

```bash
# .gitignore (what Git ignores)
node_modules/
dist/
.env

# .cursorignore (what Cursor ignores, can be stricter)
node_modules/
dist/
build/
.next/
.env*
**/*.log
**/*.csv
apps/mobile/**
```

**Why:** Cursor shouldn't index what Git ignores (they're not part of your versioned codebase).

### Indexing Performance Monitoring

**Check index stats:**
```bash
# Cursor stores index in ~/.cursor/indexes/
du -sh ~/.cursor/indexes/[project-name]

# If it's >500 MB, you're indexing too much
# Review your .cursorignore
```

**Benchmark before/after:**
```bash
# Open project, check status bar: "Indexing: 5/10 files indexed"
# Wait for completion, note time

# Update .cursorignore, restart Cursor
# Re-index, note time

# Compare: should be 3-5x faster
```

### Strategic Index Configuration (Advanced)

For projects with distinct domains (web + API + scripts):

```json
// .indexconfig.json (Cursor experimental)
{
  "indexingStrategy": "priority",
  "priorities": {
    "services/api/src/**": 1.0,      // Always full index
    "packages/common/src/**": 1.0,
    "apps/web/src/**": 0.8,          // Light index (sampling)
    "tests/**": 0.2,                 // Minimal index
    "docs/**": 0.1                   // Text search only
  },
  "excludePatterns": [
    "node_modules/**",
    "dist/**",
    "**/*.log"
  ]
}
```

This tells the indexer: "Prioritize core code, sample tests, minimize docs."

### Claude Code Context Efficiency

Claude Code doesn't use file indexes the same way. Instead, optimize context:

```text
claude> Read these files and plan the refactoring:
  @services/api/src/index.ts
  @services/api/src/handlers/
  @services/api/src/services/

Then tell me your plan before implementing.
```

By pre-loading key files, you avoid "exploration" turns that waste tokens.

---

## 9. Team Patterns: Multiple Developers Using AI on the Same Codebase

When a team uses AI tools on a shared codebase, coordination is critical. Without it, agents conflict, duplicate work, or break each other's code.

### Shared CLAUDE.md + Local Variations

**Root CLAUDE.md** (checked into git, shared by team):
```markdown
# Project: [Name]

## Critical Rules (Never Break These)
- Import paths: Always use absolute imports from package root
- Database: Migrations in /migrations/, one per file
- Tests: Run `npm test` before committing
- No direct database access outside /src/repositories

## Tech Stack
- Language: TypeScript
- Framework: Express
- Testing: Jest
- Database: PostgreSQL

## Commands
- `npm run dev` — Start server
- `npm run test` — Run tests
- `npm run build` — Build for production

## Architecture
[See /docs/ARCHITECTURE.md]

## Module Ownership
- /services/auth → @alice
- /services/payments → @bob
- /packages/db → @charlie
```

**Local .claude/settings.local.json** (not in git, per-developer):
```json
{
  "env": {
    "CLAUDE_AUTO_FOCUS_SERVICE": "payments"
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Working on payments service. Coordinate with @bob.'"
          }
        ]
      }
    ]
  }
}
```

**Benefit:** Team maintains consistent standards (root CLAUDE.md) while individuals customize their workflows (local settings).

### File Locking for Concurrent Changes

When multiple agents work on the same codebase, prevent conflicts:

**Simple lock file approach:**

```bash
# Create .claude/locks/ directory
mkdir -p .claude/locks/

# Before working on a module
echo "alice-$(date +%s)" > .claude/locks/payments.lock

# After committing changes
rm .claude/locks/payments.lock
```

**Hook to enforce:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/check-locks.sh"
          }
        ]
      }
    ]
  }
}
```

**check-locks.sh:**
```bash
#!/bin/bash
FILE_PATH="$1"
LOCKS_DIR=".claude/locks/"

# Check if any locks exist for this service
SERVICE=$(echo "$FILE_PATH" | cut -d'/' -f2)  # e.g., "services", "packages"

if [ -f "$LOCKS_DIR/$SERVICE.lock" ]; then
  LOCK_OWNER=$(cat "$LOCKS_DIR/$SERVICE.lock")
  CURRENT_USER=$(whoami)

  if [[ "$LOCK_OWNER" != *"$CURRENT_USER"* ]]; then
    echo "⚠️ WARNING: $SERVICE is locked by $LOCK_OWNER" >&2
    exit 2  # Block the edit
  fi
fi

exit 0  # Allow the edit
```

### Preventing AI-Generated Conflicts

AI agents can accidentally generate conflicting code. Prevent with:

**1. Pre-commit hooks (Git-level):**

```bash
# .git/hooks/pre-commit
npm run test           # Must pass
npm run lint -- --fix  # Must pass
```

**2. Merge conflict detection:**

If two agents edit the same file:
```bash
# Git will show merge conflict markers
# Don't auto-resolve; fail the merge and ask for manual review
```

**3. AI-specific safeguards in CLAUDE.md:**

```markdown
## Concurrent Development Rules

If you see merge conflicts:
- STOP, don't continue
- Explain the conflict to the user
- Ask them to resolve in git
- Then continue

When modifying a file:
- Check recent git history: `git log -5 [file]`
- If modified in last 6 hours by someone else, ask them first
```

### Code Review Standards for AI Code

When reviewing AI-generated code in a team:

**Checklist:**
- [ ] Tests pass locally
- [ ] Follows CLAUDE.md conventions
- [ ] No imports from other service modules
- [ ] No direct database access outside repositories
- [ ] Error handling present (try/catch or return Result)
- [ ] No hardcoded values (use config)
- [ ] Types are correct (no `any`)

**In GitHub:**
```markdown
## AI Code Review Template

- **AI Tool Used:** Claude Code / Cursor / Gemini
- **Session ID:** [link to session]
- **Files Changed:** [count]
- **Test Coverage Added:** [%]

### Verification
- [ ] Tests pass
- [ ] Architecture preserved
- [ ] No security issues
- [ ] Follows conventions

### Questions
- Why this approach over alternatives?
- Any edge cases I should worry about?
```

---

## 10. Case Studies: AI Tools on Real Large Codebases

### Case Study 1: Goldman Sachs + Devin AI

**Project:** Modernizing legacy trading system (500K+ lines of C++)

**Challenge:**
- 20-year-old codebase, minimal documentation
- 200+ interdependent modules
- High-stakes trading logic (bugs = money loss)

**Solution:**
1. Used Gemini to analyze entire system, document architecture
2. Broke refactoring into 15 phases (each 3-5 files)
3. Each phase: test-driven (write tests, then Devin implements)
4. Manual verification of trading math before each deploy

**Results:**
- 8 months → 2 months (4x faster)
- Reduced tech debt by 35%
- Zero trading errors introduced
- New developers onboard in 2 weeks (vs. 3 months previously)

**Key Success Factor:** Strict phasing + test gates. Never allowed >5 files to change at once.

### Case Study 2: Salesforce + Cursor

**Project:** Upgrading 100+ microservices from Node 16 → Node 20

**Challenge:**
- Each service different architecture
- Breaking changes in dependencies
- 10,000+ functions to review

**Solution:**
1. Created shared `.cursorrules` for all services
2. Each team used Cursor with service-specific context
3. Ran CI/CD for each service independently
4. Bot coordinated testing across services

**Results:**
- 6 weeks for complete migration
- 2 regressions (caught by CI/CD, fixed same day)
- Adoption: 95% of teams now use Cursor for daily work

**Key Success Factor:** Clear ownership (one team per service) + shared conventions.

### Case Study 3: Stripe + Claude Code

**Project:** Implementing OAuth 2.1 across payment integrations

**Challenge:**
- 12 payment gateways with different auth patterns
- Cross-cutting concern (touches API, webhooks, client libraries)
- Must work in parallel without breaking existing auth

**Solution:**
1. **Phase 1:** Architect OAuth 2.1 abstraction (Claude Code + Plan Mode, 2 days)
2. **Phase 2:** Implement for 3 gateways (Agent Team with 3 agents, 1 day)
3. **Phase 3:** Migrate remaining 9 gateways (Agent with slow hand-off, 3 days)
4. **Phase 4:** Deprecate old auth (feature flag, gradual rollout, 2 weeks)

**Results:**
- 300+ files changed safely
- 0 production incidents
- 98% test coverage on new code
- Migration took 3 weeks (originally estimated 8 weeks)

**Key Success Factor:** Clear abstractions + agent teams for parallel work + feature flags for safety.

---

## 11. Implementation Checklist

### Pre-AI Preparation (1-2 weeks)

- [ ] Document architecture in `/docs/ARCHITECTURE.md` (not exhaustive, just key patterns)
- [ ] Create root `CLAUDE.md` with tech stack, critical rules, commands
- [ ] Create `.cursorrules` or `.mdc` with code style + architecture constraints
- [ ] Ensure test coverage >70% (foundational for AI safety)
- [ ] Create MODULE_OWNERSHIP.md (who owns what?)
- [ ] Set up hooks (auto-format, auto-test on edit)

### Onboarding AI Tools (1 day)

- [ ] Add CLAUDE.md to git
- [ ] Test with small task (bug fix, simple feature) before major work
- [ ] Create `.cursorignore` and verify indexing time (<5 minutes)
- [ ] Add per-module `CLAUDE.md` for each major service
- [ ] Create FILE_OWNERSHIP.md or in CLAUDE.md

### Safe Operations (Ongoing)

**For small changes (<5 files):**
- [ ] Use Claude Code or Cursor directly
- [ ] Run tests after
- [ ] Create simple commit

**For medium changes (5-20 files):**
- [ ] Use Plan Mode first
- [ ] Review plan before implementation
- [ ] Test after each major change
- [ ] Create atomic commits (one change per commit)

**For large changes (20+ files):**
- [ ] Use Gemini for analysis
- [ ] Break into phases
- [ ] Test gates between phases
- [ ] Use feature flags for risky changes
- [ ] Manual verification before production

### Monitoring & Iteration

- [ ] Track AI error rates (via code review feedback)
- [ ] Update CLAUDE.md when AI makes repeated mistakes
- [ ] Review `.cursorignore` quarterly (add new build artifacts, dependencies)
- [ ] Audit hooks yearly (remove outdated rules)

---

## Sources

- [AI Coding Tools for Large Codebases: What Actually Scales Past 100K Lines](https://www.openaitoolshub.org/en/blog/ai-coding-tools-large-codebases)
- [Comparison of AI Code Assistants for Large Codebases](https://intuitionlabs.ai/articles/ai-code-assistants-large-codebases)
- [Cursor vs GitHub Copilot vs Claude Code - 2026 Comparison](https://www.augmentcode.com/tools/ai-code-comparison-github-copilot-vs-cursor-vs-claude-code)
- [How to Fill Gemini's 2 Million Token Context Window with Code](https://cloving.ai/tutorials/how-to-fill-gemini-2-million-token-context-window-with-code)
- [Big Context Isn't Everything: When AI Coding Tools Go Rogue](https://hyperdev.matsuoka.com/p/big-context-isnt-everything-when)
- [Assessing the Quality and Security of AI-Generated Code: Quantitative Analysis](https://arxiv.org/html/2508.14727v1)
- [Understanding Security Risks in AI-Generated Code](https://cloudsecurityalliance.org/blog/2025/07/09/understanding-security-risks-in-ai-generated-code)
- [Debugging AI-Generated Code: 8 Failure Patterns & Fixes](https://www.augmentcode.com/guides/debugging-ai-generated-code-8-failure-patterns-and-fixes)
- [Complete Guide to Cursor .cursorignore Configuration](https://eastondev.com/blog/en/posts/dev/20260115-cursor-codebase-index-optimization/)
- [Rules for Monorepo - Cursor Directory](https://cursor.directory/rules/monorepo)
- [Orchestrate Teams of Claude Code Sessions](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Architecture & Deployment Guide 2026](https://dextralabs.com/blog/claude-ai-agents-architecture-deployment-guide/)
- [AI-Powered Legacy Code Refactoring: Implementation Guide](https://www.augmentcode.com/learn/ai-powered-legacy-code-refactoring)
- [Simplifying Refactoring for Large Codebases with AI](https://zencoder.ai/blog/simplifying-refactoring-large-codebases-with-ai)
- [How to Effectively Utilize AI to Enhance Large-Scale Refactoring](https://www.atlassian.com/blog/developer/how-to-effectively-utilise-ai-to-enhance-large-scale-refactoring)
- [Google AI Studio: Context Window, Token Limits, and Memory](https://www.datastudios.org/post/google-ai-studio-context-window-token-limits-and-memory-behavior-across-gemini-models)

---

## Changelog

| Date | Update | Source |
|------|--------|--------|
| 2026-03-18 | Initial guide: Large codebase strategies, Gemini 2M context, multi-agent patterns, monorepo setup, refactoring safety, team coordination | Web research 2025-2026 |
