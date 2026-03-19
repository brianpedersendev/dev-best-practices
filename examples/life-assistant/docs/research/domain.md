# Domain Analysis: Life Assistant App

**Research Date:** 2026-03-19

---

## 1. Domain Breakdown

### What Each Domain Needs

#### Career + Goals (MVP 1 — build first)

**Data Model:**
- User profile: current role, company, years experience, skills, salary
- Target roles: aspirational positions with required skills gap analysis
- Goals: hierarchical (life goals → yearly → quarterly → weekly)
- Skills: inventory with proficiency levels, learning resources, progress tracking
- Journal entries: reflections, wins, challenges, tagged by date and topic
- Milestones: completed achievements with dates

**AI Capabilities Needed:**
- Career path mapping: "Given your current skills and target role, here's a realistic path"
- Skill gap analysis: "You need X, Y, Z skills — here are resources"
- Resume/interview coaching: On-demand feedback on career documents
- Goal decomposition: Break large goals into actionable weekly tasks
- Progress tracking: "You've completed 3/7 quarterly goals, here's what needs attention"
- Proactive nudges: "You haven't logged skill development in 2 weeks"

**Why this domain first:**
- Least competitive domain (no affordable AI career coach exists)
- Goals engine is the shared foundation all other domains need
- Doesn't require any external integrations (all manual input)
- High personal value — career decisions are high-stakes and benefit most from AI reasoning

#### Finance + Goals (MVP 2)

**Data Model:**
- Accounts: bank, credit card, investment, retirement (manual entry initially)
- Transactions: categorized spending with date, amount, category, notes
- Budgets: monthly targets by category
- Investments: holdings with purchase price, current value, allocation
- Financial goals: savings targets, debt payoff, investment milestones

**AI Capabilities Needed:**
- Spending pattern analysis: "You spend 40% more on dining when you have stressful work weeks"
- Budget coaching: "You're trending 15% over in entertainment this month"
- Investment insights: "Your portfolio is 70% tech — consider diversifying"
- Cross-domain: "Your target salary of $X would put your savings rate at Y%"
- Proactive nudges: "Large transaction detected — was this planned?"

**Integration options (v2+):**
- Plaid for bank connections ($0.30/connection + $0.25/mo per account)
- Manual CSV import from bank statements
- Brokerage API connections (varies by provider)

#### Fitness + Diet (MVP 3)

**Data Model:**
- Workouts: type, duration, exercises, sets/reps/weight, notes
- Meals: food items, estimated calories/macros, photos
- Body metrics: weight, measurements, energy levels (1-10)
- Habits: sleep, water intake, supplements
- Fitness goals: strength targets, weight goals, habit streaks

**AI Capabilities Needed:**
- Workout suggestions: "Based on your recovery and schedule, here's today's workout"
- Pattern detection: "You skip workouts after late meetings — try morning sessions"
- Diet coaching: "You're consistently low on protein — here are meal ideas"
- Cross-domain: "Your exercise frequency dropped 50% during your project deadline week"
- Proactive nudges: "You haven't worked out in 4 days"

**Integration options (v2+):**
- Apple Health / Google Fit for automatic workout logging
- Wearable APIs (Garmin, Whoop, Oura) for biometrics
- Food database API for nutrition data

#### Hobbies (MVP 4)

**Data Model:**
- Projects: name, description, status, materials list, estimated time
- Notes: free-form notes with photos, tagged by project
- Ideas: brainstorming space for future projects
- Budget: materials cost tracking (ties to finance domain)
- Time log: hours spent on hobby activities

**AI Capabilities Needed:**
- Idea generation: "Based on your skill level and available tools, here are 5 woodworking project ideas"
- Project planning: "For this bookshelf, you'll need these materials and roughly X hours"
- Note organization: "Here are your notes from the last 3 similar projects"
- Cross-domain: "You've spent $X on woodworking this quarter vs. your hobby budget of $Y"
- Proactive nudges: "You haven't worked on a hobby project this month — want some inspiration?"

---

## 2. Cross-Domain Connections

This is the core differentiator. No competitor does this.

### Connection Map

```
                    ┌──────────┐
                    │  GOALS   │ ← Central hub — every domain feeds goals
                    └────┬─────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
    │ CAREER  │    │ FINANCE │    │ FITNESS │
    └────┬────┘    └────┬────┘    └────┬────┘
         │               │               │
         └───────┬───────┘               │
                 │                       │
            ┌────┴────┐                  │
            │ HOBBIES │──────────────────┘
            └─────────┘
```

### Specific Cross-Domain Insights

| Connection | Example Insight | How It Works |
|-----------|----------------|-------------|
| Career → Finance | "Your target role pays $130K median. At your current savings rate, that's an extra $800/mo toward your house fund." | Career module shares salary data with finance module |
| Career → Fitness | "You have 3 presentations this week. Your workout frequency drops 60% during high-stress weeks. Pre-schedule morning workouts?" | Career module shares schedule intensity; fitness module detects patterns |
| Finance → Hobbies | "You've spent $450 on woodworking materials this quarter vs. your $300 quarterly hobby budget." | Finance module categorizes hobby spending; hobby module tracks projects |
| Fitness → Career | "Your energy ratings are 2 points higher on days you exercise before work. You have an important meeting Thursday — workout Wednesday night?" | Fitness module shares energy data; career module knows schedule |
| Goals → All | "Your Q2 goal was to learn React. You've logged 12 hours of learning. At this pace, you'll hit your 40-hour target by end of Q2." | Goals module tracks progress across all domains |
| Finance → Fitness | "Your gym membership costs $50/mo but you've gone 3 times this month. That's $16.67/visit. A home workout routine would save $600/year." | Finance module tracks gym spending; fitness module tracks attendance |

### Technical Implementation of Cross-Domain Reasoning

**Option A: Shared Context Window**
- When the AI generates insights for any domain, it includes a summary from all other domains in the context
- Pros: Simple, LLM naturally draws connections
- Cons: Token-expensive, context grows with each domain

**Option B: Event Bus**
- Each domain emits events (goal_updated, budget_exceeded, workout_missed, etc.)
- A cross-domain reasoning agent subscribes to all events and generates insights
- Pros: Efficient, decoupled, only processes when something changes
- Cons: More complex to implement, need to define event schema

**Option C: Periodic Summary Agent**
- A scheduled job (daily/weekly) reads summaries from all domains and generates cross-domain insights
- Pros: Simple, predictable cost, easy to debug
- Cons: Not real-time, may miss time-sensitive connections

**Recommendation: Start with Option C (Periodic Summary), evolve to Option B.**
- For MVP 1 (only career+goals), there's nothing to cross-reference
- When MVP 2 ships (finance), add a daily summary agent that reads career + finance data
- As domains grow, the event bus becomes worth the complexity

---

## 3. User Journey

### Daily Interaction Pattern

```
Morning (7:00 AM):
├── Dashboard shows: Today's goals, upcoming career events, budget status
├── Nudge (if applicable): "You have a 1-on-1 with your manager today. Want to prep talking points?"
└── Quick action: Log yesterday's workout (if missed)

Throughout Day:
├── Chat: "Help me prepare for my performance review next week"
├── Quick log: Expense entry, meal photo, workout completion
└── Nudge: "Your lunch spending is trending 20% over this week"

Evening (8:00 PM):
├── Reflection prompt: "How was your energy today? (1-10)"
├── Tomorrow prep: "You have a job interview tomorrow. Here are your notes from last time."
└── Goal check-in: "You've completed 2 of 5 weekly goals. Want to adjust priorities?"

Weekly (Sunday):
├── Weekly review: Performance across all domains
├── Goal recalibration: Adjust targets based on actual progress
├── Cross-domain insight: "Your fitness dropped during your project sprint. Consider..."
└── Next week planning: Key priorities and schedule

Monthly:
├── Deep review: Financial summary, career progress, fitness trends
├── Goal assessment: Are quarterly goals on track?
├── Hobby check-in: Time and money spent on hobbies
└── Cross-domain report: Patterns across all domains
```

### Interaction Mode Selection

| Scenario | Best Mode | Why |
|----------|-----------|-----|
| Morning overview | Dashboard | Quick visual scan, no interaction needed |
| "How much did I spend on eating out?" | Chat | Natural language query into structured data |
| Missed workout alert | Nudge (push notification) | Timely, requires no active engagement |
| Career coaching session | Chat | Deep, multi-turn conversation |
| Weekly review | Dashboard + Chat | Visual overview, then discuss insights |
| Expense logging | Quick input (dashboard widget) | Minimal friction for frequent action |

---

## 4. Data Architecture

### Shared vs. Domain-Specific Data

```
SHARED (Core Platform):
├── users                    # User profiles and preferences
├── goals                    # Hierarchical goal system (shared across all domains)
├── journal_entries           # Free-form reflections (tagged by domain)
├── nudge_history            # All nudges sent and user responses
├── cross_domain_insights    # Generated cross-domain connections
└── user_memory              # AI memory (episodic + semantic)

CAREER DOMAIN:
├── career_profiles          # Current role, target roles
├── skills                   # Skill inventory with levels
├── learning_activities      # Courses, books, projects
└── career_milestones        # Achievements and timeline

FINANCE DOMAIN:
├── accounts                 # Bank, credit, investment accounts
├── transactions             # Categorized spending
├── budgets                  # Monthly category targets
├── investments              # Portfolio holdings
└── financial_goals          # Savings targets, debt payoff

FITNESS DOMAIN:
├── workouts                 # Exercise sessions
├── meals                    # Food logging
├── body_metrics             # Weight, measurements, energy
├── habits                   # Daily habit tracking
└── fitness_goals            # Strength, weight, consistency targets

HOBBY DOMAIN:
├── projects                 # Hobby projects (woodworking, etc.)
├── project_notes            # Notes and photos per project
├── project_ideas            # Brainstorming space
├── hobby_time_log           # Hours tracked
└── materials                # Materials and costs (linked to finance)
```

### Schema Design Principle
Each domain owns its data but exposes read-only summaries to the cross-domain reasoning engine. No domain directly writes to another domain's tables. Cross-domain connections happen through the shared `goals`, `cross_domain_insights`, and `user_memory` tables.

---

## Sources
- [Vercel AI SDK Documentation](https://sdk.vercel.ai/docs)
- [mem0 Documentation](https://docs.mem0.ai/)
- [MCP Specification](https://modelcontextprotocol.io/)
- Knowledge base: `docs/topics/ai-native-architecture.md`
- Knowledge base: `docs/topics/context-memory-systems.md`
- Knowledge base: `docs/topics/ai-first-ux-patterns.md`
