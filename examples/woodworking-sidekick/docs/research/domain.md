# Domain & Market Research: AI Woodworking Sidekick

> Date: 2026-03-19

## 1. Market Size and Trends

### Hobbyist Woodworking Market
- **US hobbyist woodworkers:** Estimated 15-20 million Americans engage in woodworking as a hobby (ranging from occasional to serious). The Woodworking Network and AWFS surveys suggest ~16M hobbyists.
- **Global market:** The global woodworking machinery and tools market was valued at ~$5B in 2024, with hobbyist/consumer segment representing roughly 20-25% ($1-1.25B).
- **Average annual spend per hobbyist:** $500-2,000 on tools, materials, and education. Serious hobbyists can spend $5,000+/year.

### COVID Boom — Did It Stick?
- **Yes, mostly.** The 2020-2021 COVID woodworking surge brought millions of new hobbyists. While some casual interest faded, the serious hobbyist base grew permanently:
  - /r/woodworking grew from ~1M to 2.8M+ members (2020-2026)
  - /r/BeginnerWoodWorking went from ~50K to 400K+
  - YouTube woodworking content continues to grow year-over-year
  - Tool manufacturers (DeWalt, Festool, Makita) report sustained hobbyist demand through 2025-2026
- **Demographics shift:** The COVID wave brought younger woodworkers (25-45 age bracket) and more women into the hobby — both groups are more digitally native and likely to use software tools.

### Demographics
- **Age:** Core hobbyist base is 35-65, but growing younger (25-45 segment expanding fastest)
- **Gender:** Historically 80%+ male, but female participation growing significantly post-COVID
- **Income:** Middle to upper-middle income ($60K-150K household) — they have disposable income for the hobby
- **Education:** Skews college-educated — analytical thinkers who appreciate good tools
- **Digital comfort:** Varies widely. Younger hobbyists are very tech-savvy. Older hobbyists may need a simple, intuitive UX.

## 2. Monetization Models

### How the Woodworking Space Monetizes Today
| Model | Examples | Revenue Range |
|-------|----------|---------------|
| **YouTube ad revenue + sponsors** | Steve Ramsey, Jonathan Katz-Moses, Stumpy Nubs | $50K-500K+/year for top creators |
| **Plan sales** | Woodworkers Journal, Popular Woodworking | $5-25 per plan |
| **Subscription (plans + video)** | Woodworkers Guild of America, Woodsmith | $10-15/month or $100-150/year |
| **Courses** | MT Copeland, MasterClass | $15-200 per course |
| **Affiliate (tools + materials)** | Almost every woodworking creator | 5-10% commission on tool sales |
| **Software licenses** | SketchUp, CutList Plus | $60-350/year |

### Monetization Options for AI Woodworking Sidekick

#### Option 1: Freemium SaaS (Recommended for v1)
- **Free tier:** 1 plan generation (ever) without sign-up (guest). After sign-up: 1 plan/month, 10 chat messages/plan, no saved plans.
- **Pro tier ($15/month or $120/year):** Unlimited plans, unlimited chat, saved projects, plan versioning, custom tool profiles, PDF export.
- **Why:** The guest experience hooks users with zero friction. The free tier keeps them engaged. The limit (1 plan/month) is tight enough that anyone building regularly will upgrade. Key insight: the value is obvious after one good plan — conversion should be high.
- **Comparable:** Canva's freemium model works similarly for designers.
- **Critical metric to track:** Free-to-paid conversion rate. Target 5-10% of signed-up users converting within 30 days.

#### Option 2: Pay-Per-Plan
- **$3-5 per generated plan** with a few free credits to start
- **Why it could work:** Aligns cost with value. Woodworkers understand paying for plans.
- **Why it might not:** Creates friction at the point of exploration. Users won't experiment freely.

#### Option 3: Free + Marketplace (Future)
- **App is free.** Monetize through the creator marketplace (take 15-30% of plan sales by experienced woodworkers).
- **Why it could work:** Builds the largest possible user base. Marketplace creates a flywheel.
- **Why it's not v1:** Need critical mass of users first. Marketplace is a Phase 3+ feature.

### What Woodworkers Would Pay
- Based on existing spending patterns: **$10-20/month is the sweet spot** for a tool that saves significant planning time.
- Key insight: Woodworkers regularly waste $20-50 on wrong materials from bad planning. If the tool saves them one material mistake per month, it pays for itself.
- Price sensitivity is moderate — they're already spending hundreds on tools. Software is a rounding error if it delivers value.

## 3. Acquisition and Distribution

### Where Woodworkers Hang Out Online
| Platform | Audience Size | Engagement | Best For |
|----------|--------------|------------|----------|
| **YouTube** | Millions of viewers | High — woodworkers watch long-form content | Content marketing, tutorials, demos |
| **Reddit** (/r/woodworking, /r/BeginnerWoodWorking) | 3.2M+ combined | Very high — active Q&A community | Community seeding, authentic discussions |
| **Instagram** | Millions follow woodworking accounts | Medium — visual showcase | Brand building, project galleries |
| **Facebook Groups** | Hundreds of active groups (10K-100K members each) | Medium-high | Reaching older demographic |
| **Woodworking forums** (LumberJocks, Woodworking Talk) | 100K-500K | Medium — declining vs. Reddit/YouTube | Reaching serious hobbyists |
| **Pinterest** | High search volume for "woodworking plans" | Medium — discovery-focused | SEO/discovery |
| **TikTok** | Growing woodworking community | High for short content | Reaching younger makers |

### SEO Opportunities
- **High-intent keywords:**
  - "woodworking plans for [project type]" — very high volume
  - "cut list generator" — moderate volume, low competition
  - "woodworking project planner" — moderate volume
  - "how to build a [project]" — extremely high volume
  - "DIY [furniture type] plans" — high volume
- **Content strategy:** Generate and publish free simplified plans for common projects. Each plan is an SEO landing page that demonstrates the product's capability.
- **Long-tail opportunity:** "How to build a [specific project] with [specific tools]" — millions of long-tail queries that a tool-aware AI could serve uniquely.

### Launch Strategy
1. **Week 1-2:** Soft launch on Reddit (/r/woodworking "Show & Tell" thread, /r/SideProject). Be transparent about being the builder. Ask for feedback, not sales.
2. **Week 3-4:** Product Hunt launch. Woodworking is a niche that PH audiences find charming and novel.
3. **Month 2:** YouTube content — show the tool generating plans, then actually building from those plans. "I let AI plan my next woodworking project" is clickbait that works.
4. **Ongoing:** SEO landing pages for common projects. Each generated plan becomes a blog post.
5. **Community building:** Invite early users to a Discord where they share builds from AI-generated plans.

## 4. Domain Knowledge Requirements

### What the AI Needs to Know

#### Material Knowledge
- **Lumber species properties:** Hardness, workability, cost, common uses (oak for furniture, pine for utility, walnut for fine work, cedar for outdoor)
- **Nominal vs. actual dimensions:** CRITICAL — every plan must use actual dimensions. A "2x4" is 1.5" x 3.5".
- **Board feet calculations:** (T × W × L) / 144 — needed for material estimates and cost
- **Plywood grades and types:** MDF, Baltic birch, shop-grade, cabinet-grade, exterior
- **Sheet goods optimization:** How to cut multiple parts from 4x8 sheets efficiently

#### Joinery Knowledge
- **When to use what:**
  - Pocket holes: Quick, strong enough for face frames and light furniture. NOT for fine furniture.
  - Mortise & tenon: Gold standard for table legs, chair joints, frame construction. Rule of thirds for sizing.
  - Dovetails: Drawer construction, box joints. Show-off joint that signals quality.
  - Dowels: Versatile, accessible. Good alternative when user doesn't have M&T tools.
  - Biscuits: Alignment only, not structural. Good for panel glue-ups.
  - Dado/rabbet: Shelves, case construction. Simple and strong.
- **Joinery-tool mapping:** Which joints can be made with which tools. E.g., M&T needs a drill press or chisel set or dedicated mortiser; dovetails need a dovetail saw or router + jig.

#### Construction Knowledge
- **Structural principles:** Wood movement (grain direction matters), load paths, shear vs. tension
- **Standard dimensions:**
  - Table height: 28-30" (dining), 36" (counter), 42" (bar)
  - Shelf depth: 8-12" (books), 16-24" (closet)
  - Chair seat height: 17-19"
  - Drawer depth: varies, but drawer face overlap is typically 1/2"
- **Finish recommendations:** Polyurethane (durable, easy), Danish oil (natural look), spray lacquer (fast), food-safe finishes for cutting boards/utensils

#### Tool Awareness
- **What each tool can do:**
  - Table saw: Rip cuts, cross cuts (with sled), dados, tapers
  - Miter saw: Cross cuts, miters, bevels. NOT rip cuts.
  - Router: Edge profiles, dados, rabbets, template routing, joinery (with jigs)
  - Drill/driver: Holes, pocket holes (with jig), driving fasteners
- **What the AI should NEVER assume the user has:** CNC, planer/jointer, bandsaw, lathe, mortiser, biscuit joiner (unless user specifies)
- **Alternative approaches:** If a plan normally requires a planer, suggest buying pre-surfaced lumber (S4S). If it needs a mortiser, suggest dowel joints or pocket holes as alternatives.

## 5. User Validation Signals

### Demand Indicators
- **Search volume:** "Woodworking plans" gets 100K+ monthly searches. "Free woodworking plans" gets 50K+. "Cut list calculator" gets 5-10K.
- **Reddit signal:** Regular posts asking "how do I plan this project" with hundreds of upvotes
- **YouTube signal:** "I tried using ChatGPT for woodworking" videos getting 50K-200K views — curiosity is high
- **Product gap:** Multiple Reddit threads asking "is there an app that generates woodworking plans?" with no good answers

### Skepticism Signals
- "AI will never replace learning proper woodworking" — sentiment from purist woodworkers
- "ChatGPT gave me a terrible plan" — trust issues from bad early experiences with general AI
- "I'd use it for a starting point but I'd verify everything" — likely power user behavior

### Failed/Stalled Attempts
- No notable failed AI woodworking startups found — the space genuinely appears untouched
- Some SketchUp plugins have tried to automate plan generation but are limited by the SketchUp-first workflow
- A few GitHub repos with "woodworking calculator" projects exist but are simple utilities, not AI-powered

## 6. Risk Analysis

### Safety and Liability
- **Real-world consequences:** Bad AI plans can lead to material waste ($20-100+), structural failure (furniture collapse), and potential injury (kickback from unsafe table saw cuts)
- **Mitigation:** Clear disclaimers ("AI-generated plan — verify measurements before cutting"), confidence indicators, community review features in future versions
- **Legal:** Terms of service should clearly disclaim liability for plans. Consider consulting a lawyer before launch.

### Competitor Risk
- **Google/OpenAI adding woodworking features:** Unlikely to build a dedicated tool, but their general models will keep improving. The moat is domain depth and UX, not just AI capability.
- **Incumbent woodworking brands:** Woodsmith, Popular Woodworking could add AI features. They have domain expertise but are slow to innovate technologically.
- **Other indie developers:** Likely — if this works, others will follow. First-mover advantage matters, but the moat must be built quickly (community, content, SEO, features).

## Sources
- Reddit /r/woodworking community size and engagement data
- Reddit /r/BeginnerWoodWorking growth metrics
- Woodworking Network industry reports
- YouTube woodworking creator analytics
- [AWI Net — Mortise and Tenon Joints](https://awinet.org/types-of-mortise-and-tenon-joints/)
- [MT Copeland — Types of Wood Joints](https://mtcopeland.com/blog/types-of-wood-joints/)
- [Dimensions.com — Wood Joinery Reference](https://www.dimensions.com/collection/wood-joinery-wood-connections)
- Google Trends data for woodworking keywords
- AWFS Fair industry reports
