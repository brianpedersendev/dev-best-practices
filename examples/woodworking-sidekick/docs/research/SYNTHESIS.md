# Research Synthesis: AI Woodworking Sidekick

> Date: 2026-03-19
> Research files: [SCOPE.md](SCOPE.md) | [landscape.md](landscape.md) | [technical.md](technical.md) | [domain.md](domain.md)

## Executive Summary

The AI Woodworking Sidekick targets a genuine gap in a large, growing hobbyist market. No direct AI competitor exists. The technical path is feasible with known challenges around plan accuracy. The biggest risk is not competition — it's building something that generates plans accurate enough to earn trust in a community that values craftsmanship.

---

## Key Findings

### 1. The Market is Real and Growing
The US hobbyist woodworking community is 15-20M strong and expanding, with post-COVID growth sticking. Hobbyists spend $500-2,000/year and are increasingly digital-native (younger demographics entering). The market has proven willingness to pay for plans ($5-25 each) and subscriptions ($10-15/month).

### 2. No Direct AI Competitor Exists
Despite AI being used for everything, no one has built a dedicated AI woodworking plan generator. This is genuine whitespace. The closest alternatives are general AI assistants (ChatGPT/Claude) which produce unreliable plans, and static plan marketplaces which can't customize.

### 3. Existing Solutions Are All Static and Un-customizable
Every current woodworking plan source — from Ana White to Woodsmith to Etsy — delivers fixed PDFs. No customization for your tools, your dimensions, or your skill level. This is the core frustration the Sidekick solves.

### 4. AI Plan Accuracy is the Critical Technical Challenge
LLMs hallucinate 5-20% of the time on complex reasoning tasks. For woodworking plans, wrong dimensions mean wasted wood and lost trust. The solution is a multi-layer validation approach: structured JSON output → programmatic validation rules → re-generation on failure. This is solvable but requires careful engineering.

### 5. Gemini is a Good Starting Choice, But Design for Swappability
Gemini offers the best price/performance ratio with a generous free tier and strong multimodal capabilities for the future image feature. However, the LLM layer should be abstracted (via Vercel AI SDK) to enable model switching and multi-model validation.

### 6. System Prompts Are Enough for MVP, RAG for Growth
The core woodworking knowledge needed for plan generation (joinery rules, material dimensions, tool assumptions) fits comfortably in a system prompt for v1. As the knowledge base grows and user-specific context matters more, a structured reference database and eventually RAG should be layered in.

### 7. Founder-Market Fit is a Real Advantage
Brian being a hobbyist woodworker himself is a significant edge. Product decisions will be grounded in real experience, not guesses. This is especially important for getting domain knowledge right — joinery choices, tool assumptions, and "hobbyist-friendly" plans require understanding the user deeply.

### 8. The Biggest Indirect Competitor is "Just Ask ChatGPT"
Users can prompt ChatGPT/Claude for a rough plan for free. The moat must come from: (1) domain-specific knowledge producing better plans, (2) plan validation ensuring accuracy, (3) persistent project context, (4) purpose-built UX, and (5) community/SEO flywheel.

### 9. Monetization Should Start Freemium
$12-20/month (or $99-149/year) with a generous free tier is the right model. Woodworkers understand paying for plans and tools. The free tier drives word-of-mouth; the paid tier captures serious users. Marketplace is a Phase 3+ monetization play.

### 10. Distribution Strategy is Clear
Reddit, YouTube, and SEO are the primary channels. Each generated plan can become a blog post (SEO). "I let AI plan my next project" is compelling YouTube content. Reddit is where the target users already discuss planning frustrations.

---

## Risk Assessment

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| AI-generated dimensions are wrong | **High** | High | Multi-layer validation: structured output + programmatic checks + re-generation |
| "Just use ChatGPT" cannibalizes demand | **Medium** | Medium | Domain depth, validation, UX, persistence — things raw ChatGPT can't do |
| Solo developer scope creep | **Medium** | High | Ruthless MVP scoping — plan gen + chat + accounts, nothing else |
| Small addressable market willing to pay for SaaS | **Medium** | Medium | Freemium + content marketing to maximize reach before monetizing |
| Safety/liability from bad plans | **High** | Low-Medium | Clear disclaimers, confidence indicators, never recommend unsafe operations |
| Gemini API pricing/quality changes | **Low** | Low | Vercel AI SDK abstraction enables model swapping |
| Timing — someone else ships first | **Medium** | Low-Medium | Whitespace won't last forever. Ship a focused MVP fast (8 weeks) rather than a perfect product slowly. Speed > polish for v1 |

---

## Go / No-Go Recommendation

### Recommendation: **GO**

### Rationale
This project has strong fundamentals: a real problem experienced by millions of hobbyists, no direct competition, a technically feasible solution path, and genuine founder-market fit. The biggest risk (AI accuracy) is mitigable through structured output and validation — it's an engineering challenge, not a showstopper.

The market is large enough to support a solo SaaS (15-20M US hobbyists), the willingness to pay exists (woodworkers already buy $5-25 plans and $10-15/month subscriptions), and the distribution channels are clear (Reddit, YouTube, SEO). Brian being the target user means the product will be built with authentic understanding of the problem.

The timing is right: AI capabilities are good enough to generate useful plans (with validation), the hobbyist woodworking community is digitally active and growing, and no one has built this yet.

### If GO:
- **Key advantages:** First mover in genuine whitespace; founder IS the user; technically feasible with known stack; clear distribution channels
- **Biggest risks:** Plan accuracy (mitigate with validation layers); "just use ChatGPT" threat (mitigate with domain depth + UX); solo developer scope (mitigate with ruthless MVP focus)
- **Suggested approach:** Next.js + Supabase + Gemini via Vercel AI SDK. Start with rich system prompts for woodworking knowledge. Build structured JSON output for plans with programmatic validation. Ship MVP with plan generation + AI chat + user accounts. Launch on Reddit + Product Hunt.

### Critical Success Factor
**The first generated plan a user sees must be impressive and accurate.** If the first plan has wrong dimensions or suggests impossible joinery, the user will never come back. Invest heavily in the system prompt, validation rules, and a few "golden path" project types (simple bookshelf, end table, cutting board, workbench) that are thoroughly tested before launch.

---

## Recommended Next Steps
1. Write a detailed implementation plan (Phase 3 of this skill)
2. Design the plan output schema (structured JSON format)
3. Prototype the system prompt with 3-5 test projects
4. Build validation rules for dimensional consistency
5. Ship MVP and test with 10 woodworkers from Reddit

## Sources
See individual research files for complete source lists:
- [landscape.md](landscape.md) — competitive analysis sources
- [technical.md](technical.md) — technical feasibility sources
- [domain.md](domain.md) — market and domain sources
