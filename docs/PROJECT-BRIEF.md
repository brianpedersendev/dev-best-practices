# Project Brief: AI Woodworking Sidekick

## One-Line Description
An AI-powered web app that turns a woodworking project idea into a complete, hobbyist-friendly build plan with an AI chat assistant that stays with you through the entire build.

## Problem Statement
Intermediate hobbyist woodworkers face a frustrating gap between "I want to build X" and "I know exactly how to build X." Today they cobble together YouTube videos, buy plans designed for professional shops, sketch on napkins, and ask Reddit — wasting hours on research, buying wrong materials, and making expensive mistakes. No single tool takes a project idea and produces a complete, actionable plan tailored to a garage hobbyist's tools and skill level.

## Target Users
**Primary: Intermediate hobbyist woodworkers** — people who are comfortable with basic joinery, own a decent garage shop (table saw, miter saw, router, drill/driver, hand tools), and want to tackle more ambitious projects with confidence. They've built shelves and simple furniture, now they want to build a dining table, entertainment center, or workshop storage system without winging it.

**First 10 users:** Woodworking hobbyists active on Reddit (/r/woodworking, /r/BeginnerWoodWorking), YouTube woodworking communities, and local maker spaces. People who already spend time planning projects but lack a streamlined tool.

## Core Value Proposition
**One input, complete output.** Describe what you want to build (or upload an image) and get a full build plan — dimensions, cut list, material estimates, joinery recommendations, and tips — tailored to YOUR tools and skill level. Then keep an AI assistant on call through the entire build for real-time help. No one else does this end-to-end for hobbyists.

## MVP Scope

### In (v1):
- **Project input**: Text description of desired project (image upload can be v1.1)
- **AI plan generation**: Complete build plan with dimensions, cut list, materials list, joinery recommendations, step-by-step instructions, and project-specific tips
- **Tool profile input**: Users specify their tools (presets or custom list) so plans only recommend joinery/cuts they can actually make
- **Plan tailoring**: Plans adapted to the user's specific tool set (not assuming CNC, planer/jointer, etc.)
- **Plan adjustment**: Users can request changes ("make it wider," "use pocket holes instead") and get a re-generated plan
- **AI chat assistant**: Conversational AI that understands the generated plan and answers follow-up questions during the build
- **User accounts**: Sign up, save plans, revisit past projects
- **Guest try-before-signup**: Generate 1 plan without creating an account
- **Basic plan management**: View, organize, and delete saved plans

### Explicitly NOT in v1:
- Image upload / visual project input (v1.1)
- 3D project visualization / renders (future)
- Creator marketplace for selling plans (future)
- Social features (sharing, community) (future)
- Mobile app (responsive web only for v1)
- Offline mode
- Integration with lumber suppliers / pricing APIs
- Video tutorials or step-by-step visual guides

## Known Competitors / Alternatives
- **SketchUp / Fusion 360** — 3D modeling tools, steep learning curve, no AI plan generation
- **Ana White / Woodsmith plans** — Pre-made plans, not customizable, often assume pro tools
- **YouTube creators** (Steve Ramsey, etc.) — Great for learning, but plans aren't personalized
- **ChatGPT / Claude directly** — Can generate rough plans but lacks woodworking-specific context, no persistent project management
- **Etsy plan sellers** — One-size-fits-all PDFs, no interactivity
- **CutList Optimizer** — Solves one piece of the puzzle (cut optimization) but not the whole planning workflow
- **Reddit / forums** — Free advice but slow, inconsistent, and not structured as a build plan

## Technical Constraints
- **Stack**: Next.js, Supabase (auth + database + storage), Gemini API
- **Solo developer** with a soft timeline (want to launch within a few months)
- **Budget-conscious**: Prefer managed services, generous free tiers, pay-as-you-go AI API costs
- **Founder is the target user**: Brian is a hobbyist woodworker himself — deep domain empathy

## Architecture Direction
- **AI-native**: AI is the core product, not a bolted-on feature
- **LLM-powered plan generation**: Gemini API with carefully crafted system prompts encoding woodworking knowledge (joinery types, material properties, tool requirements, common dimensions)
- **Conversational AI chat**: Context-aware assistant that has access to the user's generated plan
- **Supabase for everything backend**: Auth, Postgres for plan storage, real-time for chat if needed
- **Next.js App Router**: Server components for plan rendering, client components for chat UI
- **Streaming responses**: Essential for chat UX — users shouldn't stare at a loading spinner
- **Key architecture question**: How much woodworking knowledge should be baked into system prompts vs. retrieved via RAG from a knowledge base? Research should explore this.

## Success Criteria
- **Learning**: Ship a real product end-to-end, deepening full-stack and AI integration skills
- **Audience**: Attract active users from woodworking communities who return to create multiple plans
- **Revenue potential**: Validate that people would pay for this — even if monetization is post-launch
- **Personal use**: Brian actually uses it for his own projects

## Open Questions
1. **Gemini vs. alternatives**: Is Gemini the right model for this? How does it compare to Claude/GPT-4 for structured woodworking plan output?
2. **Knowledge architecture**: System prompt engineering vs. RAG with a woodworking knowledge base — what's the right approach for plan quality?
3. **Plan accuracy**: How do we ensure generated dimensions and cut lists are actually correct? What validation/guardrails are needed?
4. **Competitive moat**: If someone can just ask ChatGPT for a woodworking plan, what makes this worth paying for?
5. **Monetization model**: Freemium, subscription, or free-with-marketplace — what fits this market?
6. **Image input feasibility**: How well can current vision models interpret "I want something like this" from a photo?
7. **SEO/discovery**: How do woodworkers find tools like this? What's the acquisition strategy?

## Risk Factors
- **AI accuracy risk**: Generated plans with wrong dimensions or unsafe joinery recommendations could cause real-world harm (material waste, structural failure, injury). Needs strong disclaimers and ideally validation.
- **Competitive exposure**: Low barrier for ChatGPT/Claude to do "good enough" plan generation — differentiation must come from UX, domain depth, and persistent project context.
- **Solo developer scope**: Plans + chat + accounts + AI is a lot for one person. Risk of shipping a mediocre version of everything instead of an excellent version of one thing.
- **Gemini API dependency**: Single-provider risk. If Gemini pricing changes or quality degrades, the product is impacted.
- **Content quality floor**: Bad AI-generated plans will kill trust fast in a community that values craftsmanship. Quality bar must be high from day one.
