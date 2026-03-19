# Implementation Plan: AI Woodworking Sidekick

> Date: 2026-03-19
> Based on: [PROJECT-BRIEF.md](../../PROJECT-BRIEF.md) | [SYNTHESIS.md](../SYNTHESIS.md)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Next.js App Router                 │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ Landing  │  │ Plan Builder │  │ AI Chat Panel │  │
│  │ Page     │  │ (main UX)    │  │ (per project) │  │
│  └──────────┘  └──────┬───────┘  └───────┬───────┘  │
│                       │                  │           │
│  ┌────────────────────┴──────────────────┴────────┐  │
│  │          Server Actions / Route Handlers        │  │
│  │     (LLM calls, validation, auth middleware)    │  │
│  └────────────────────┬───────────────────────────┘  │
│                       │                              │
│  ┌────────────────────┴───────────────────────────┐  │
│  │           Vercel AI SDK (ai package)            │  │
│  │   streamText / generateObject / useChat         │  │
│  └──────┬─────────────────────────────────────────┘  │
└─────────┼────────────────────────────────────────────┘
          │
    ┌─────┴──────┐        ┌──────────────────────────┐
    │  Gemini    │        │      Supabase            │
    │  API       │        │  ┌────────────────────┐  │
    │ (primary)  │        │  │ Auth (email+OAuth) │  │
    │            │        │  ├────────────────────┤  │
    │  [swap via │        │  │ Postgres           │  │
    │   AI SDK]  │        │  │  - projects        │  │
    └────────────┘        │  │  - plans (JSONB)   │  │
                          │  │  - messages         │  │
                          │  ├────────────────────┤  │
                          │  │ Row-Level Security │  │
                          │  └────────────────────┘  │
                          └──────────────────────────┘
```

## Tech Stack (Confirmed)

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Framework** | Next.js 15 (App Router) | Server Components for plan rendering, streaming support, Vercel deployment |
| **AI SDK** | Vercel AI SDK (`ai` package) | Unified streaming interface, supports Gemini/Claude/OpenAI, `useChat` hook |
| **Primary LLM** | Google Gemini 2.0 Flash/Pro | Best price/performance, generous free tier, multimodal for future features |
| **Database** | Supabase (Postgres) | Auth, database, RLS, generous free tier, built-in pgvector for future RAG |
| **Auth** | Supabase Auth | Email + Google OAuth, session management, free |
| **Styling** | Tailwind CSS + shadcn/ui | Fast UI development, consistent design system |
| **Deployment** | Vercel | Native Next.js support, edge functions, easy CI/CD |
| **Validation** | Zod + custom rules | Schema validation for LLM output + woodworking dimension rules |

---

## Phase Breakdown

### Phase 1: Foundation (Weeks 1-2)
**Goal:** Project scaffolding, auth, and database schema. No AI yet — just the shell.

#### Tasks:
1. **Scaffold Next.js project**
   - Next.js 15 with App Router, TypeScript, Tailwind, shadcn/ui
   - Project structure: `app/`, `lib/`, `components/`, `types/`
   - ESLint + Prettier configuration

2. **Set up Supabase**
   - Create Supabase project
   - Configure auth (email + Google OAuth)
   - Create database schema:

```sql
-- Projects table
CREATE TABLE projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'generating', 'complete', 'error')),
  plan JSONB,  -- current structured plan output
  plan_version INT DEFAULT 1,
  settings JSONB DEFAULT '{}',  -- user preferences for this project (tool profile, etc.)
  is_public BOOLEAN DEFAULT false,  -- for shareable/SEO plan URLs
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Plan version history (for "undo" and iteration tracking)
CREATE TABLE plan_versions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  version INT NOT NULL,
  plan JSONB NOT NULL,
  feedback TEXT,  -- what the user asked to change
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Chat messages
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Row Level Security
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own projects"
  ON projects FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD messages on own projects"
  ON messages FOR ALL
  USING (project_id IN (
    SELECT id FROM projects WHERE user_id = auth.uid()
  ));

ALTER TABLE plan_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own plan versions"
  ON plan_versions FOR ALL
  USING (project_id IN (
    SELECT id FROM projects WHERE user_id = auth.uid()
  ));
```

3. **Auth pages**
   - Sign up / Sign in (email + Google)
   - Protected routes (middleware)
   - User profile dropdown

4. **Basic layout**
   - Landing page (placeholder)
   - Dashboard (list of user's projects)
   - Project detail page (placeholder)

5. **First-time user onboarding**
   - Guest users land on a focused "Try it now" page — just a description input and "Generate Plan" button
   - After plan generation, prompt: "Want to save this plan? Create a free account."
   - Signed-in users see a brief onboarding: "What tools do you have?" → save tool profile → go to dashboard

#### Deliverable: Deployed app with auth, empty dashboard, onboarding flow, database schema working.

---

### Phase 2: Plan Generation Engine (Weeks 3-5)
**Goal:** The core product — describe a project, get a complete build plan.

#### Tasks:

1. **Design the plan output schema**
   - This is the most important design decision. The plan must be structured JSON, not free text.

```typescript
interface WoodworkingPlan {
  title: string;
  summary: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  estimatedTime: string;  // "6-8 hours"

  overallDimensions: {
    widthInches: number;
    heightInches: number;
    depthInches: number;
    description: string;  // "36\"W × 30\"H × 18\"D"
  };

  materials: {
    lumber: Array<{
      species: string;      // "Red Oak"
      nominalSize: string;  // "1x6"
      actualSize: string;   // "3/4\" x 5-1/2\""
      quantity: number;
      lengthInches: number;
      boardFeet: number;
      notes?: string;
    }>;
    hardware: Array<{
      item: string;
      quantity: number;
      size?: string;
      notes?: string;
    }>;
    finish: Array<{
      product: string;
      quantity: string;
      notes?: string;
    }>;
  };

  cutList: Array<{
    partName: string;
    quantity: number;
    widthInches: number;
    lengthInches: number;
    thicknessInches: number;
    material: string;
    grainDirection?: 'length' | 'width' | 'not_applicable';  // critical for aesthetics & strength
    notes?: string;  // "Cut from 1x6 #1"
  }>;

  tools: {
    required: string[];
    helpful: string[];
    alternatives?: Record<string, string>;  // "planer" -> "Buy S4S lumber"
  };

  joinery: Array<{
    joint: string;        // "Pocket hole"
    location: string;     // "Side panels to top"
    dimensions?: string;  // "1-1/2\" pocket screws"
    notes?: string;
  }>;

  woodMovement: {
    considerations: string[];  // e.g., "Tabletop will expand ~1/8\" seasonally"
    mitigations: string[];     // e.g., "Use figure-8 fasteners, not glue, to attach top to base"
  };

  steps: Array<{
    stepNumber: number;
    title: string;
    description: string;
    tips?: string[];
    warnings?: string[];
    toolsUsed?: string[];  // which tools are needed for this step
  }>;

  tips: string[];       // Project-specific tips
  warnings: string[];   // Safety warnings

  estimatedCost: {
    lumberCost: number;     // based on approximate $/board-foot by species
    hardwareCost: number;
    finishCost: number;
    totalEstimate: number;
    notes: string;          // "Prices are rough estimates based on average US retail. Actual costs vary by region and supplier."
  };

  metadata: {
    generatedAt: string;
    modelVersion: string;
    validationPassed: boolean;
    validationNotes?: string[];
  };
}
```

2. **Build the system prompt**
   - Encode core woodworking knowledge: lumber dimensions, joinery rules, tool capabilities
   - Specify the output schema explicitly
   - Include rules: use actual dimensions (not nominal), adapt to user's tool profile, validate measurements
   - Include chain-of-thought instructions for accuracy

   **Example system prompt skeleton:**
   ```
   You are an expert woodworking plan generator for hobbyist woodworkers.

   USER'S TOOL PROFILE: {{toolProfile}}
   USER'S PREFERENCES: {{preferences}}

   GENERATE a complete, buildable woodworking plan as structured JSON.

   CRITICAL RULES:
   1. ALL dimensions must use ACTUAL lumber sizes, not nominal. A "2x4" is 1.5" x 3.5".
   2. The cut list must be achievable from the materials list. Every part must fit within a specified board.
   3. Only recommend joinery the user can make with their tools:
      - No mortise & tenon unless they have a drill press or mortising machine
      - No dovetails unless they have a dovetail saw or router + dovetail jig
      - Pocket holes are always available (assume Kreg jig for intermediate users)
   4. Account for wood movement on any solid wood panel wider than 6 inches.
   5. Include a 15% waste factor for hardwood, 10% for plywood in material quantities.
   6. Grain direction matters — note it for all visible faces.
   7. Standard furniture dimensions: dining table 28-30"H, desk 28-30"H, counter 36"H, bar 42"H, bookshelf depth 10-12".

   THINKING PROCESS (follow this order):
   1. Determine the project type and appropriate overall dimensions
   2. Design the structural framework (legs, rails, panels, shelves)
   3. Choose joinery appropriate for each connection AND the user's tools
   4. Calculate individual part dimensions from the structure
   5. Generate the cut list with grain direction
   6. Compute material requirements (add waste factor)
   7. Estimate cost from material quantities
   8. Write step-by-step build instructions
   9. Add tips, warnings, and wood movement notes

   OUTPUT: Return valid JSON matching the WoodworkingPlan schema.
   ```

3. **Build project input form**
   - Project description textarea with smart prompt suggestions (e.g., "A simple bookshelf for my living room, about 4 feet tall")
   - **Tool profile selector:** Preset options ("Beginner — circular saw, drill" / "Intermediate — table saw, miter saw, router, drill" / "Advanced — full shop") OR custom tool checklist
   - Optional dimension preferences ("I want it about X wide and Y tall")
   - Optional material preference ("I prefer pine" / "Budget-friendly" / "Hardwood")

4. **Build plan generation API route**
   - `POST /api/generate-plan`
   - Accept project description + tool profile + preferences
   - **Generation approach:** Use `streamText` with a structured output instruction (not `generateObject`) because `generateObject` doesn't support streaming partial results. Parse the completed text response into the Zod schema, then validate. This gives users a real-time streaming experience while still getting structured output.
   - Alternative: Use `generateObject` with a progress indicator (spinner + stage labels like "Designing structure..." → "Calculating cut list...") if streaming partial JSON isn't needed. Test both UX approaches.
   - Store generated plan as JSONB in Supabase
   - **Allow guest usage:** Generate 1 plan without sign-up. Require account to save or generate more. (Critical for conversion — don't gate the first experience behind auth.)

5. **Build plan validation layer**
   Concrete validation rules:
   - **Cut-from-material check:** Every cut list part must be extractable from a specified material piece. E.g., a 36" long part cannot come from a board you only bought 30" of.
   - **Board feet math:** `(thickness × width × length) / 144` must match stated boardFeet (±5%)
   - **Waste factor:** Total cut list linear inches must not exceed total material linear inches minus waste factor (15% hardwood, 10% plywood)
   - **Nominal vs. actual:** If material says "1x6," cut list thickness must be 0.75" and width must be 5.5". Flag any mismatch.
   - **Joinery-tool compatibility:** If plan recommends mortise & tenon but user's tool profile lacks chisel set or drill press, suggest alternatives (dowels, pocket holes)
   - **Overall dimensions check:** Sum of component dimensions + joinery offsets must approximately equal stated overall dimensions
   - **Wood movement rules:** Any panel wider than 6" in solid wood must have wood movement accommodation noted
   - **Safety flags:** Table saw cuts on pieces smaller than 12" must include safety notes about push sticks/sleds
   - If validation fails → feed specific errors back to LLM → re-generate (max 2 retries)

6. **Build plan regeneration with feedback**
   - "Adjust this plan" button opens a text input: "Make it 6 inches wider," "Use pocket holes instead of mortise & tenon," "Change to walnut"
   - Re-generates with original plan + user feedback as context
   - This is core to the value prop — plans that adapt to you

7. **Build the plan display UI**
   - Plan display with sections: Overview, Overall Dimensions, Materials, Cut List, Tools, Joinery, Steps, Wood Movement, Tips
   - Cut list as interactive table (sortable by part name, material, size)
   - Print-friendly view (CSS `@media print`)
   - "Share plan" link (public read-only URL — also enables SEO)

6. **Test with golden path projects**
   - Simple bookshelf (basic project, pocket holes)
   - End table (intermediate, M&T joinery)
   - Cutting board (beginner, glue-up + finish)
   - Workbench (complex, multiple joinery types)
   - Validate each plan manually before launch

#### Deliverable: Users can describe a project and get a validated, structured build plan.

---

### Phase 3: AI Chat Assistant (Weeks 6-7)
**Goal:** Conversational AI that knows about the user's plan and answers build questions.

#### Tasks:

1. **Build chat API route**
   - `POST /api/chat`
   - Load the project's generated plan as context
   - Use Vercel AI SDK `streamText` with `useChat` hook
   - System prompt with guardrails:
     ```
     You are a knowledgeable woodworking assistant helping a hobbyist build their project.

     THE USER'S PROJECT: [title]
     THEIR PLAN: [plan JSON]
     THEIR TOOLS: [tool profile]

     RULES:
     - Always reference the specific plan when answering. Say "In step 3 of your plan..." not generic advice.
     - If asked about dimensions, refer to the cut list and overall dimensions in the plan.
     - If a question is outside woodworking (e.g., plumbing, electrical), say so and decline.
     - NEVER recommend removing safety equipment or skipping safety steps.
     - If you're unsure about a structural recommendation, say so explicitly.
     - Suggest alternatives that match the user's tool profile — don't assume tools they don't have.
     - Keep answers practical and concise — they're in the shop, not reading an essay.
     ```

2. **Build chat UI**
   - Slide-out panel on the project detail page
   - Message list with streaming responses
   - Input with send button
   - Suggested questions based on the plan (e.g., "What's the best way to cut the dadoes for the shelves?")

3. **Chat context management**
   - Store messages in Supabase `messages` table
   - Load recent messages (last 20) as conversation history
   - Include plan JSON in system prompt (not in message history — saves tokens)
   - If conversation gets long, summarize earlier messages

4. **Message persistence**
   - Save all messages to Supabase
   - Load message history when returning to a project
   - "Clear chat" option

#### Deliverable: Users can ask questions about their plan and get contextual, helpful answers.

---

### Phase 4: Polish & Launch (Weeks 8-10)
**Goal:** Production-ready UX, landing page, and launch preparation.

#### Tasks:

1. **Landing page**
   - Hero: "Describe your project. Get a complete build plan."
   - Demo: Show a plan being generated (animation or real example)
   - Feature highlights: Cut list, material estimates, AI chat, saved projects
   - CTA: "Try free — no credit card"

2. **Dashboard improvements**
   - Project cards with status, creation date, thumbnail
   - Sort/filter (date, status)
   - Quick actions (duplicate, delete)

3. **Plan UX refinements**
   - Collapsible sections
   - Cut list as sortable/filterable table
   - Material list with estimated cost (lookup table for common lumber prices)
   - "Export as PDF" option
   - "Regenerate plan" with ability to provide feedback

4. **Error handling & edge cases**
   - Rate limiting (prevent API abuse)
   - Graceful error states for LLM failures
   - Loading skeletons
   - Empty states

5. **SEO & meta**
   - Open Graph tags for sharing
   - Sitemap
   - Plan pages with SEO-friendly URLs (future: public plans for SEO)

6. **Launch checklist**
   - Terms of Service + Privacy Policy (use a generator, have a lawyer review)
   - Disclaimer on all generated plans ("AI-generated — verify measurements")
   - Analytics (Vercel Analytics or Plausible)
   - Error tracking (Sentry)
   - Test on mobile (responsive)
   - Performance audit (Lighthouse)

#### Deliverable: Production-ready app deployed on Vercel, ready for launch.

---

### Phase 5: Launch & Iterate (Week 11+)
**Goal:** Get the first 100 users and learn from their feedback.

#### Tasks:
1. **Reddit soft launch** — Post in /r/woodworking Show & Tell, /r/SideProject
2. **Product Hunt launch** — Prepare assets, launch on a Tuesday
3. **Collect feedback** — In-app feedback widget, email outreach to early users
4. **Iterate** — Fix the top 3 complaints in the first 2 weeks
5. **Content marketing** — Start publishing AI-generated plans as blog posts for SEO

---

## Data Model Summary

```
User (Supabase Auth)
  └── Project (many)
        ├── plan: JSONB (WoodworkingPlan schema)
        ├── description: text (user's input)
        ├── settings: JSONB (preferences)
        └── Message (many)
              ├── role: user | assistant
              └── content: text
```

---

## Key Architecture Decisions

### 1. Structured JSON Output, Not Free Text
Plans are generated as structured JSON (via `generateObject` with Zod schema), not markdown or free text. This enables:
- Programmatic validation of dimensions and material math
- Rich, interactive UI (sortable tables, collapsible sections)
- Future features (cut list optimization, cost estimation, 3D visualization)

### 2. Validation-First Generation
Every generated plan passes through a validation layer before being shown to the user. Validation checks dimensional consistency, material math, joinery appropriateness, and tool requirements. Failed validation triggers re-generation with error feedback.

### 3. Gemini Primary, Model-Swappable
Start with Gemini for cost and multimodal advantages. Vercel AI SDK abstracts the provider, so switching to Claude or GPT-4 requires changing one line. Consider using a second model for validation passes.

### 4. Rich System Prompt for MVP, Structured Data Later
v1 encodes woodworking knowledge in the system prompt. As the product scales, migrate reference data (lumber dimensions, joinery rules, tool capabilities) to a structured database that feeds into the prompt at generation time.

### 5. Chat Context = Plan JSON
The chat assistant receives the full plan JSON as system context. This keeps the assistant's answers specific to the user's project without needing RAG or embeddings.

---

## Testing Strategy

### Unit Tests
- Validation functions (dimensional consistency, board feet calculation, joinery rules)
- Zod schema validation for plan output
- Auth middleware

### Integration Tests
- Plan generation end-to-end (mock LLM for determinism)
- Chat conversation flow
- Database CRUD operations with RLS

### Manual QA
- Generate plans for 10+ different project types
- Verify dimensions and cut lists by hand
- Test on mobile devices
- Test error states (LLM timeout, invalid input, auth expiry)

### Golden Path Testing
Before launch, manually verify these projects produce excellent plans:
1. Simple bookshelf (beginner)
2. Cutting board (beginner)
3. End table / nightstand (intermediate)
4. Workbench (intermediate-advanced)
5. Floating shelves (beginner)

---

## Deployment

| Service | Purpose | Tier |
|---------|---------|------|
| **Vercel** | Next.js hosting, edge functions | Free (Pro if needed: $20/month) |
| **Supabase** | Auth, database, storage | Free (Pro if needed: $25/month) |
| **Google AI Studio** | Gemini API | Free tier → pay-as-you-go |
| **Vercel Analytics** | Usage tracking | Free tier |
| **Sentry** | Error tracking | Free tier (5K events/month) |

**Total MVP cost: $0-45/month** depending on usage.

---

## Timeline Summary

| Phase | Weeks | Deliverable |
|-------|-------|-------------|
| 1. Foundation | 1-2 | Auth, database, basic layout |
| 2. Plan Generation | 3-5 | Core plan generation with validation |
| 3. AI Chat | 6-7 | Contextual chat assistant |
| 4. Polish & Launch Prep | 8-10 | Production-ready, landing page |
| 5. Launch & Iterate | 11+ | First users, feedback loop |

---

## Traceability

### Original Problem
Intermediate hobbyist woodworkers face a frustrating gap between "I want to build X" and "I know how to build X." They cobble together YouTube videos, static plans, and forum advice — wasting hours on research and making expensive material mistakes.

### How This Plan Addresses It
- **Plan generation** solves the core problem: one input → complete build plan with dimensions, cut list, materials, joinery, and steps
- **Plan validation** ensures accuracy — the #1 concern from research
- **AI chat** keeps the assistant available throughout the build
- **User accounts** allow saving and revisiting plans
- **Hobbyist-first approach** adapts plans to garage tools, not professional shops

### What's Deferred to Later
| Feature | Rationale for Deferring |
|---------|----------------------|
| Image upload | Adds complexity; text input is sufficient for MVP validation |
| 3D visualization | Major feature; needs validated demand first |
| Creator marketplace | Requires critical mass of users; Phase 3+ |
| Social features | Community comes after core product is solid |
| Mobile app | Responsive web is sufficient; native app is premature |
| Material price integration | Nice-to-have; adds API dependency complexity |
| User tool profiles | Can be done via plan generation input for now |
