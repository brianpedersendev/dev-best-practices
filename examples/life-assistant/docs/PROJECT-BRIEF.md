# Project Brief: Life Assistant (LifeOS)

## One-Line Description
A modular AI-powered personal life assistant with plug-and-play domain modules (career, finance, fitness, hobbies) that provides cross-domain insights, proactive coaching, and a unified dashboard + chat + nudge interface.

## Problem Statement
People juggle 10+ apps across life domains — budgeting tools, fitness trackers, career planning platforms, goal-setting apps, hobby project managers. No single tool connects these areas, so cross-domain insights like "your woodworking hobby spending is 3x your monthly budget" or "you haven't exercised in a week and have 3 high-stress career deadlines" are invisible. Users either context-switch constantly across siloed apps or give up on tracking entirely.

Existing "all-in-one" assistants fail because they go too broad (shallow in every domain) or stay siloed (great at finance, nothing else). The market is full of apps that solve one piece well but can't reason across the full picture of someone's life.

## Target Users
- **Primary (v1):** Brian — solo professional who wants a personal tool built to his exact needs
- **Expansion (v2):** 5-10 friends/family — organized, multi-app-fatigued professionals
- **Eventually:** Productivity-oriented professionals who want AI coaching across life areas
- **Design principle:** Build for one, design for many (plug-and-play architecture from day 1)

## Core Value Proposition
1. **Cross-domain intelligence** — AI connects the dots between life areas that siloed apps can't (budget impacts hobbies, career stress impacts health, goals influence everything)
2. **Plug-and-play domains** — Each life domain is a self-contained module. Add career, then finance, then fitness — each works standalone but gets smarter together
3. **Three interaction modes** — Dashboard for overview, chat for deep dives, proactive nudges for important things
4. **Customizable integrations** — Users choose which apps/services to connect from a list, working together securely
5. **Your data, your control** — Privacy-first architecture with transparent data handling

## MVP Scope

### Domain-by-Domain Rollout (explicitly methodical — one domain at a time)

**MVP 1: Career + Goals** (build first)
- Goal-setting and tracking engine (shared foundation for all domains)
- Career trajectory planning (current role → target role mapping)
- Skill development tracking and learning path suggestions
- AI career coaching (resume feedback, interview prep, career path suggestions)
- Notes and journaling for career reflections
- Proactive nudges: "You haven't logged a skill development activity in 2 weeks"

**MVP 2: Finance + Goals** (build second)
- Personal finance tracking (spending categories, income, budgets)
- Investment portfolio monitoring (holdings overview, performance)
- AI financial insights ("You're trending 15% over budget in dining this month")
- Cross-domain: salary benchmarking tied to career trajectory goals
- Proactive nudges: "Your discretionary spending is on pace to exceed your monthly target"

**MVP 3: Fitness + Diet** (build third)
- Workout logging and tracking
- Diet and meal tracking (manual input initially)
- AI health coaching (habit formation, pattern detection)
- Cross-domain: stress/health correlation with career workload
- Proactive nudges: "You haven't logged a workout in 4 days"

**MVP 4: Hobbies** (build fourth)
- Woodworking (and other hobby) project idea generator
- Project notes, documentation, and photo storage
- Cross-domain: hobby budget tracking tied to finance module
- Proactive nudges: "You haven't worked on a hobby project this month"

### Explicitly NOT in v1
- Native mobile app (start with responsive web, add mobile later)
- Social features / multi-user collaboration
- Direct wearable device integration (Apple Health, Garmin — manual input first)
- Complex financial integrations (banking APIs via Plaid — manual input first)
- Real-time market data or trading features
- Voice interface

## Known Competitors / Alternatives

### All-in-one attempts (none dominant)
- **Notion AI** — Flexible workspace with AI, but requires users to build everything. No proactive intelligence, no domain-specific coaching.
- **Zapier Agents** — 8,000+ integrations but no domain-specific intelligence or coaching. Automation-focused, not insight-focused.
- **Motion** — Calendar + project management with AI scheduling. Narrow scope (time management only).
- **Ohai** — Family logistics assistant (calendars, school updates). Not personal growth/coaching.
- **Luzia** — Broad AI assistant. Shallow in every domain — no persistent memory or long-term tracking.
- **Leon (open source)** — Local personal assistant on Node.js. Early stage, developer-focused.
- **Pi (Inflection)** — Conversational AI companion. Good at empathy, no structured tracking or integrations.

### Domain-specific leaders
- **Finance:** Copilot Money (best AI, iOS-only, ~$10/mo), Monarch Money ($14.99/mo, couples-friendly), YNAB ($14.99/mo, zero-based budgeting)
- **Fitness:** Noom (behavior change + AI coaching), MyFitnessPal (logging), Fitbod (AI workout generation)
- **Career:** LinkedIn (passive network), various AI resume builders (narrow), no AI career coaching at scale
- **Goals:** Todoist, Notion, various goal apps (no AI coaching or cross-domain awareness)
- **Hobbies:** Nothing meaningful exists for AI-powered hobby project management

### Why no one has won "all-in-one" yet
1. **Too broad = shallow** — Trying to be everything at once produces a mediocre experience in every domain
2. **Integration complexity** — Banking APIs, health APIs, and calendar APIs are each hard problems
3. **Privacy concerns** — Users are uncomfortable centralizing finance + health + career data
4. **No clear business model** — Hard to monetize "a little bit of everything"
5. **No modular architecture** — Most attempts are monolithic, so adding domains requires rebuilding

### Differentiation opportunity
The modular, domain-by-domain approach solves the "too broad" problem — each domain is deep and useful standalone, but domains connect when ready. An MCP-based plugin architecture makes this technically novel and extensible. Starting with manual data entry (not integrations) reduces complexity while still delivering value.

## Technical Constraints
- **Solo developer** — architecture must be simple to build and maintain
- **Tech stack:** Open to recommendations (web-first likely, let research determine)
- **Budget:** Moderate — willing to pay for good AI APIs, not enterprise infrastructure
- **Timeline:** 6 months to "shareable with friends" quality
- **Privacy:** Critical design decision — needs research on cloud vs. local vs. hybrid before committing

## Architecture Direction
- **AI-native** — AI is the core of the product, not a bolt-on feature
- **Modular domain system** — Each life domain as a pluggable module (MCP servers per domain is a strong candidate)
- **Persistent user memory** — The AI must "know" the user deeply over time (3-tier memory: working/episodic/semantic)
- **Hybrid UI** — Dashboard for at-a-glance overview, chat for deep exploration, proactive nudges for timely alerts
- **Model routing** — Haiku for quick checks/classifications, Sonnet for reasoning/coaching, to optimize cost
- **Cross-domain reasoning engine** — The core differentiator: connecting insights across domains

## Success Criteria
1. **3 months:** MVP 1 (Career + Goals) is genuinely useful — Brian uses it daily
2. **6 months:** MVP 1 + MVP 2 working, 5-10 friends actively using it
3. **Quality bar:** Each domain module must be independently useful (would use it even without other domains)
4. **Architecture bar:** Adding a new domain takes <1 week of development

## Open Questions
1. What's the best technical architecture for a modular, domain-pluggable AI assistant?
2. MCP servers per domain vs. simpler plugin approach — which is right for a solo dev?
3. Privacy: cloud AI vs. local-first vs. hybrid — what's realistic for personal finance/health data?
4. What integrations are feasible for a solo dev? (Plaid for banking? Apple Health? Calendar APIs?)
5. Web-first or mobile-first? What does the hybrid interaction model demand?
6. What's the right AI memory architecture for a "knows me deeply" personal assistant?
7. Cost projections — how much would daily personal AI coaching cost per user?
8. How should cross-domain reasoning work technically? (Shared context? Event bus? Agent orchestration?)

## Risk Factors
- **Scope creep** — Brian self-identifies this tendency. Mitigation: strict domain-by-domain MVPs with "play with it before adding on" discipline. Each MVP must be independently useful before starting the next.
- **Integration complexity** — Banking/health APIs are hard. Mitigation: start with 100% manual input. Integrations are a v2+ feature.
- **"Too broad" trap** — Could end up shallow in everything like other all-in-one attempts. Mitigation: each domain must pass the "would I use this standalone?" test.
- **Privacy sensitivity** — Centralizing finance + health + career data raises real privacy concerns. Mitigation: research privacy architecture thoroughly before building. Be transparent about data handling.
- **Solo dev capacity** — 4 domains in 6 months is ambitious. Mitigation: domain-by-domain rollout means value is delivered incrementally. If only MVP 1 ships, that's still useful.
- **AI memory complexity** — Building a "knows me deeply" persistent AI is technically challenging. Mitigation: start simple (conversation history + structured data), add sophisticated memory later.
