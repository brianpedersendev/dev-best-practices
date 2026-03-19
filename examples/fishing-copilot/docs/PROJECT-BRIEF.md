# Project Brief: Fishing Copilot

## One-Line Description
A daily AI-powered briefing app that aggregates public fishing reports, weather, and conditions across Wyoming and surrounding states to recommend where to fish and what to use.

## Problem Statement
Recreational anglers in Wyoming and surrounding states (Montana, Colorado, Idaho, Utah) must manually check multiple state fish & game websites, forums, and weather sources to decide where to fish on any given day. These reports are scattered across different sites, published on inconsistent schedules, use varying formats, and are often hard to parse quickly. The result: anglers either spend too much time researching or just go to the same familiar spots and miss better opportunities nearby.

## Target Users
- **Primary (v1):** Brian — solo angler in Wyoming who wants a quick morning decision tool
- **Expansion:** Recreational anglers in the Rocky Mountain region who fish 1-4 times per week and want to maximize their outings without becoming full-time fishing report analysts

## Core Value Proposition
An AI that reads and synthesizes all the scattered, inconsistently formatted fishing reports you'd have to check manually — and delivers a single, actionable morning briefing with spot recommendations, technique guidance, and weather context. The differentiator is **curation + synthesis**, not just aggregation.

## MVP Scope

### In (v1)
- Ingest fishing reports from state fish & game agencies (WY, MT, CO, ID — start with 2)
- Weather integration (current conditions + forecast) for each fishing area
- AI-generated daily morning briefing summarizing:
  - Active fishing reports within a configurable radius
  - Recommended spots ranked by recent report quality
  - What's working: fishing type (fly, spin, bait), specific lures/flies/bait
  - Weather conditions and how they affect fishing
  - Water conditions (flows, temps, clarity) when available
- Delivery via SMS/text or web dashboard
- Configurable home location and radius
- Configurable fish species preferences (trout, walleye, bass, etc.)

### Out (v1)
- Native mobile app (web-first, mobile-responsive)
- Social features / community reports
- Trip logging or catch tracking
- Real-time alerts (e.g., "the hatch is on!")
- Paid/premium features
- Detailed mapping or GPS navigation
- Tackle shop integration or gear recommendations beyond what reports mention

## Known Competitors / Alternatives
- **Fishbrain** — Social fishing app with catch logging, maps, species info. Heavy on community data, less on synthesized recommendations. Freemium model.
- **FishAngler** — Similar to Fishbrain, community-driven spots and catches.
- **State agency websites** — The raw source. Free but scattered and inconsistent.
- **Local tackle shop reports** — Great info, but only covers their area, usually weekly.
- **Fishing forums / Reddit** — Anecdotal, unstructured, varies wildly in quality.
- **OnX Hunt/Fish** — Maps and access points, not report synthesis.
- **No direct competitor** doing AI-powered daily briefing synthesis from public reports — this is the gap.

## Technical Constraints
- **Solo developer** — must be simple to build and maintain
- **Cheap to run** — low/no infrastructure costs at personal scale; costs should scale linearly if expanded
- **Best-of-breed stack** — use the best tools for each job, not a monolithic framework
- **Public data only (v1)** — no paid data subscriptions or APIs requiring commercial licenses
- **Monetization potential** — architecture should allow adding a paid tier later without major rework

## Architecture Direction
- **AI-native** — AI summarization/reasoning is the core product, not a bolt-on feature
- **Scraping + ingestion pipeline** — scheduled jobs to pull reports from state agency sites
- **LLM-powered synthesis** — use Claude or similar to read raw reports and generate structured briefings
- **Weather API integration** — free tier weather API (Open-Meteo, NWS API) for conditions/forecast
- **SMS delivery** — Twilio or similar for text message briefings
- **Web dashboard** — lightweight web UI for configuring preferences and viewing full briefings
- **Cron/scheduled execution** — daily briefing generation on a schedule, not a persistent server
- Potential RAG for historical report context (what worked last year this week at this spot)

## Success Criteria
1. **Personal utility:** Brian uses it and it improves fishing decisions (fewer wasted trips, discovers new spots)
2. **Build feasibility:** Can be built solo in a reasonable timeframe with available tools
3. **Cost efficiency:** Runs for <$20/month at personal scale
4. **Monetization signal:** Other anglers express interest when shown the briefing output

## Open Questions
1. How structured are the state agency fishing reports? (Determines scraping complexity)
2. What's the rate limiting / ToS situation for scraping state fish & game sites?
3. Is there an RSS feed or API for any of these agencies, or is it all HTML scraping?
4. How often are reports updated? (Daily, weekly, seasonal — affects briefing freshness)
5. What water condition data is freely available? (USGS stream gauges, reservoir levels)
6. What's the right LLM cost model? (Per-briefing cost with Claude API vs. batch processing)
7. Can SMS delivery stay within free/cheap tiers for a single user?
8. What fishing types does Brian do most? (Fly, spin, bait — all of the above?)

## Risk Factors
- **Data fragility:** Scraping state websites is brittle — site redesigns break scrapers. Mitigated if agencies offer RSS/API.
- **Report inconsistency:** Each state formats reports differently. The LLM needs to handle highly variable input.
- **Freshness gap:** If agency reports are only weekly, the daily briefing may repeat stale info. Weather + water data can fill some gaps.
- **Scope creep:** The "wouldn't it be cool if..." list for a fishing app is endless. Strict MVP discipline required.
- **Monetization uncertainty:** The addressable market for "AI fishing briefings" is unproven. Build for personal use first, validate interest second.
