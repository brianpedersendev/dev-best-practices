# Technical Feasibility: AI Woodworking Sidekick

> Date: 2026-03-19

## 1. LLM Comparison for Structured Plan Generation

### Model Comparison
| Factor | Gemini 2.0+ | Claude (Opus/Sonnet) | GPT-4o |
|--------|-------------|---------------------|--------|
| **Structured output** | Good JSON mode, function calling | Excellent at following complex instructions, strong structured output | Strong JSON mode, reliable function calling |
| **Numerical accuracy** | Moderate — prone to hallucination in precise calculations | Moderate — better with chain-of-thought prompting | Moderate — similar hallucination patterns |
| **Multimodal (images)** | Strong — native multimodal, good at image understanding | Good with vision, improving rapidly | Strong vision capabilities |
| **Streaming** | Supported via Gemini API | Supported via Anthropic API | Supported via OpenAI API |
| **Pricing (input/output per 1M tokens)** | ~$1.25/$5.00 (Flash), ~$2.50/$10.00 (Pro) | ~$3/$15 (Sonnet), ~$15/$75 (Opus) | ~$2.50/$10.00 |
| **Free tier** | Generous free tier via AI Studio | Limited free tier | Limited free tier |
| **Context window** | 1M+ tokens | 200K (Sonnet), 200K (Opus) | 128K |

### Key Findings on Numerical Accuracy
- **All LLMs hallucinate with numerical data.** The hallucination rate for SOTA models is 1.5-5% overall, but **rises to 5-20% for complex reasoning tasks** involving calculations. Source: [Vectara Hallucination Leaderboard](https://github.com/vectara/hallucination-leaderboard), [AI Multiple](https://aimultiple.com/ai-hallucination)
- **Woodworking plans require precise numbers.** A 1/4" error in a mortise can ruin a joint. This means raw LLM output for dimensions CANNOT be trusted without validation.
- **Mitigation approaches:**
  - RAG with verified reference data reduces hallucination by 60-80%. Source: [Master of Code](https://masterofcode.com/blog/hallucinations-in-llms-what-you-need-to-know-before-integration)
  - Chain-of-thought prompting for calculations improves accuracy
  - Post-generation validation rules (e.g., "cut list dimensions must sum to material list quantities")
  - Multi-step generation: generate design first, then compute dimensions programmatically

### Recommendation: Start with Gemini, Design for Swappability
- **Gemini** is the right starting choice because: generous free tier for prototyping, strong multimodal capabilities for future image upload, competitive pricing at scale
- **BUT**: Abstract the LLM layer behind an interface so you can swap models or use multiple models. Use Vercel AI SDK which supports Gemini, Claude, and OpenAI with a unified API.
- **Consider Claude for validation passes** — use a second model to verify critical numbers in generated plans

## 2. Knowledge Architecture: System Prompts vs. RAG

### Option A: System Prompt Engineering
**Approach:** Encode woodworking knowledge directly in system prompts — joinery types, when to use each, material properties, standard dimensions, tool requirements.

**Pros:**
- Simpler to implement (no vector DB needed)
- Lower latency (no retrieval step)
- Easier to debug and iterate on
- Works well for knowledge that fits within context window

**Cons:**
- Limited by context window size
- Knowledge is static (must redeploy to update)
- Can't easily personalize to user's specific tools/materials
- May hit token limits as knowledge base grows

### Option B: RAG with Woodworking Knowledge Base
**Approach:** Build a structured knowledge base of woodworking data (joinery rules, material specs, tool capabilities) and retrieve relevant context at generation time.

**Pros:**
- Scalable — can grow knowledge base indefinitely
- Dynamic — update knowledge without redeploying
- Can include user-specific context (their tools, preferred materials)
- Dramatically reduces hallucination (60-80% reduction)

**Cons:**
- More complex to implement (need vector DB, embeddings, retrieval pipeline)
- Added latency for retrieval step
- Chunk quality matters a lot — bad chunking = bad retrieval
- Overkill for MVP if knowledge base is small

### Recommendation: Hybrid — Start Prompt-Heavy, Add RAG for Specific Data
1. **MVP (Phase 1):** Rich system prompts with core woodworking knowledge. This is enough to generate usable plans for common projects.
2. **Phase 2:** Add a structured reference database (not vector search — more like lookup tables) for:
   - Standard lumber dimensions (nominal vs. actual)
   - Joinery dimension rules (rule of thirds for M&T, dovetail angles, etc.)
   - Common tool capabilities and limitations
   - Material properties (hardwood vs. softwood strength, workability)
3. **Phase 3:** Full RAG with embeddings for the growing knowledge base, user-submitted tips, and community knowledge.

### Critical Woodworking Knowledge to Encode

#### Joinery Rules (from research)
- **Mortise & Tenon Rule of Thirds:** Mortise width = 1/3 stock thickness. Source: [AWI Net](https://awinet.org/types-of-mortise-and-tenon-joints/)
- **Tenon length:** Should not exceed width of receiving piece
- **Dovetail angles:** Typically 1:6 for softwood, 1:8 for hardwood
- **Pocket holes:** Only for face-frame construction, not structural joints
- **Biscuit joints:** Alignment aid only, not structural. Source: [Dimensions.com](https://www.dimensions.com/collection/wood-joinery-wood-connections)

#### Standard Lumber Dimensions
| Nominal | Actual |
|---------|--------|
| 1x4 | 3/4" x 3-1/2" |
| 1x6 | 3/4" x 5-1/2" |
| 1x8 | 3/4" x 7-1/4" |
| 2x4 | 1-1/2" x 3-1/2" |
| 2x6 | 1-1/2" x 5-1/2" |
| 4x4 | 3-1/2" x 3-1/2" |

#### Plywood Sheet Sizes
- Standard: 4' x 8' (48" x 96")
- Half sheet: 4' x 4' (48" x 48")
- Common thicknesses: 1/4", 1/2", 3/4"

#### Garage Hobbyist Tool Assumptions
**Can assume:** Table saw (or circular saw + guide), miter saw, drill/driver, random orbit sander, measuring tape, square, clamps, pocket hole jig
**Cannot assume:** Planer, jointer, bandsaw, CNC, lathe, spindle sander, drum sander, mortiser

## 3. Plan Accuracy and Validation

### The Problem
LLMs generate plausible-sounding but potentially incorrect dimensions. A plan that says "cut a 36-inch board from a 32-inch piece" would destroy user trust immediately.

### Validation Strategy
1. **Dimensional consistency checks:**
   - All cuts must be achievable from specified materials
   - Assembly dimensions must match component dimensions
   - Standard sizes must use actual (not nominal) lumber dimensions
2. **Material quantity validation:**
   - Board feet calculations: (thickness × width × length) / 144
   - Add 15-20% waste factor for hardwood, 10% for plywood
   - Cut list should be optimizable to minimize waste
3. **Joinery validation:**
   - Joint types must be appropriate for the connection type (structural vs. decorative)
   - Joint dimensions must follow established rules (rule of thirds, etc.)
   - Tool requirements for each joint must match assumed tool set
4. **Safety checks:**
   - No structural recommendations for weight-bearing applications without disclaimers
   - Appropriate warnings for table saw operations with small pieces
   - Finish recommendations appropriate for intended use (food-safe, outdoor, etc.)

### Implementation Approach
- **Structured output format:** Have the LLM generate JSON with explicit dimension fields, not free text. This enables programmatic validation.
- **Post-generation validation function:** A deterministic code function that checks dimensional consistency, material math, and joinery rules.
- **Re-generation on failure:** If validation fails, feed errors back to the LLM and ask it to fix specific issues.
- **User-facing confidence indicator:** Show users which parts of the plan have been validated vs. which are AI-generated estimates.

### Available Calculators (No API, Manual Reference Only)
- [Woodworking-Calculators.com Mortise & Tenon Calculator](https://woodworking-calculators.com/mortise-tenon-calculator/) — dimensions, depth, thickness, fit tolerances
- [Dimensions.com Wood Joinery Reference](https://www.dimensions.com/collection/wood-joinery-wood-connections) — dimensional drawings
- No dedicated woodworking joinery API exists — would need to build validation rules from reference data

## 4. Tech Stack Validation

### Next.js App Router + Supabase
- **Proven combination** for AI-native apps. Vercel's AI SDK has first-class support for streaming from multiple LLM providers.
- **Supabase strengths:** Auth (email + OAuth), Postgres (structured plan storage), Row-Level Security, Realtime subscriptions (for future features), generous free tier
- **Gotchas:**
  - Supabase free tier: 500MB database, 1GB file storage, 50K monthly active users — plenty for MVP
  - Edge functions for server-side LLM calls to protect API keys
  - Consider Supabase Vectors for future RAG (built-in pgvector)

### Streaming Architecture
- **Vercel AI SDK** (ai package) provides unified streaming interface for Gemini, Claude, and OpenAI
- `useChat` hook for the chat assistant interface
- `streamText` / `generateObject` for plan generation
- Server Actions or Route Handlers for LLM API calls

### Recommended Schema Design
```sql
-- Users (handled by Supabase Auth)

-- Projects
CREATE TABLE projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  description TEXT,
  plan JSONB,  -- structured plan data
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Chat messages per project
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  role TEXT NOT NULL,  -- 'user' or 'assistant'
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

## 5. Image Input Feasibility (Future Feature)

### Current Capabilities
- **Gemini 2.0 Pro Vision:** Can identify furniture types, materials, joinery from photos. Accuracy varies — good for "this is a dining table with tapered legs" but unreliable for precise measurements from photos.
- **GPT-4V:** Similar capabilities, slightly better at describing construction details in some tests.
- **Limitation:** Photos don't provide dimensions. The AI can identify the type of project and style, but measurements must come from user input or standard proportions.

### Realistic v1.1 Scope for Image Input
- User uploads a photo of something they want to build (or similar to what they want)
- AI identifies: project type, style, material (probably), joinery type (maybe), approximate proportions
- AI asks clarifying questions: "This looks like a farmhouse dining table. What dimensions do you want? How many seats?"
- Then generates a plan as usual, with the image informing style and design choices

## Sources
- [Vectara Hallucination Leaderboard](https://github.com/vectara/hallucination-leaderboard)
- [AI Multiple — AI Hallucination Comparison](https://aimultiple.com/ai-hallucination)
- [Master of Code — LLM Hallucination Mitigation](https://masterofcode.com/blog/hallucinations-in-llms-what-you-need-to-know-before-integration)
- [OpenAI — Why Language Models Hallucinate](https://openai.com/index/why-language-models-hallucinate/)
- [AWI Net — Mortise and Tenon Joint Types](https://awinet.org/types-of-mortise-and-tenon-joints/)
- [Dimensions.com — Wood Joinery Reference](https://www.dimensions.com/collection/wood-joinery-wood-connections)
- [Woodworking-Calculators.com — Mortise & Tenon Calculator](https://woodworking-calculators.com/mortise-tenon-calculator/)
- Vercel AI SDK documentation
- Supabase documentation
- Google Gemini API documentation
