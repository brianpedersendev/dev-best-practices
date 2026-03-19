# Research Synthesis: Fishing Copilot App

## Research Date: 2026-03-19

---

## Summary of Findings

### The Data Picture Is Strong

The research confirmed that a rich set of **free, public, keyless JSON APIs** exists for the environmental data side of this app:

- **USGS Water Services**: Real-time streamflow, water temperature, and gage height across 100+ Wyoming sites and 800+ across surrounding states. JSON API, no auth.
- **Bureau of Reclamation Hydromet**: Reservoir levels and releases for 11+ Wyoming reservoirs. JSON API, no auth.
- **NWS Weather API**: 7-day forecasts, hourly data, 60+ parameters, weather alerts. JSON, no auth.
- **Open-Meteo**: Barometric pressure (critical for anglers), full weather history. JSON, no auth, 10K requests/day free.
- **US Naval Observatory**: Moon phase, solunar period data. JSON, no auth.
- **Colorado DWR**: Excellent state-level water data API for Colorado waters specifically.

The **fishing report** side is harder but feasible:
- **Idaho** has a working JSON API (Fishing Planner) and structured weekly reports
- **Utah** has a working RSS feed and queryable stocking AJAX endpoint
- **Montana** offers CSV export of stocking data
- **Colorado** publishes twice-monthly condition reports and weekly stocking tables (scraping required)
- **Wyoming** is the least accessible — no API, no RSS, seasonal forecasts only — but GovDelivery bulletins and local fly shop reports fill the gap

No multi-state aggregator exists for fishing reports. Building one is the core of this app's value.

### The Competitive Gap Is Real

Nobody is doing AI-powered synthesis of state agency fishing reports. The landscape breaks down as:

- **Community-data apps** (Fishbrain, FishAngler): Large user bases but inaccurate data, poor coverage in low-population states like Wyoming
- **Weather/solunar algorithm apps** (BassForecast, LakeMonster): Predictions from environmental data only, no fishing report analysis
- **AI-native apps** (onWater): Chat-based but no report ingestion, $50/year, no push delivery
- **Mapping tools** (TroutRoutes, OnX Fish): Great maps, no recommendations or synthesis
- **Coastal/saltwater** (FishNotify, Salt Strong): Have alerts/AI but freshwater doesn't exist

The specific gap — scrape official reports + synthesize with LLM + push via SMS — has zero direct competitors. The closest technical analog (ReelCaster) is an open-source side project in British Columbia that proves the approach works at ~$4-5/month.

### The Economics Work

| Cost Item | Personal (1 user) | 100 Users |
|-----------|-------------------|-----------|
| Claude Haiku Batch API | $2.10/mo | $2.10/mo (process once) |
| Twilio SMS | $1.40/mo | $41/mo |
| Infrastructure | $0 (GitHub Actions + Cloudflare) | $0 |
| Weather/Water APIs | $0 | $0 |
| **Total** | **$3.50/mo** | **$43/mo ($0.43/user)** |

At a $5/month subscription price, 100 users would generate $500/month revenue against $43 in costs — **91% gross margin**. Even at $3/month it's sustainable.

### It's Buildable Solo

- **MVP timeline**: 3-5 weeks for a single-user version
- **Full version with dashboard + multi-user**: 6-8 weeks
- **Hardest part**: Scraping (2-4 weeks). Everything else is 1-2 days each.
- **Key insight**: Using the LLM as a scraping resilience layer (feed raw HTML to Haiku for extraction) dramatically reduces maintenance burden from site redesigns.

---

## Go / No-Go Recommendation

### Recommendation: **GO**

### Rationale

This project hits a rare sweet spot: a genuine unserved need, validated by user complaints across forums, backed by free public data, buildable in weeks with commodity tools, and cheap to run. The core technical risk (scraping state websites) is mitigated by the LLM-as-extraction-layer approach that ReelCaster has already validated.

The $217M fishing app market is growing at 12% annually with 57.9 million US anglers, yet the AI-native segment has exactly one funded player (onWater at $7M) that doesn't even do report synthesis. The Rocky Mountain freshwater niche is particularly underserved — community-data apps like Fishbrain have sparse coverage in low-population states, creating a data quality gap that official agency reports fill.

The project also has a clean build-for-yourself-first path: it's immediately useful to one angler (Brian) at $3.50/month, with a clear upgrade path to a subscription product if it proves valuable.

### If GO — Key Advantages
- **Unique data source**: No competitor scrapes and synthesizes official state agency reports
- **Push delivery**: SMS briefing is the only freshwater fishing app delivering daily via text
- **Cost structure**: LLM costs don't scale with users (process once, deliver to many)
- **Cheap to validate**: <$4/month to run personally, <$50/month at 100 users
- **Solo buildable**: 3-5 week MVP, no infrastructure costs

### If GO — Biggest Risks
1. **Scraper maintenance**: State websites change. Budget ongoing maintenance time. Mitigate with LLM extraction.
2. **Report freshness**: Wyoming only publishes seasonal forecasts. The daily briefing must lean on water/weather data between report cycles to stay useful.
3. **Data quality varies wildly**: Idaho reports are structured and detailed. Wyoming reports are sparse narrative articles. The LLM must handle this variance gracefully.
4. **Monetization is unproven**: The $217M market exists, but "AI fishing briefings" is a new category. Build for personal use first, validate interest second.

### Suggested Approach
1. **Start with 2 states**: Wyoming (home base) + Idaho (best data). Add CO and MT/UT later.
2. **Scraping + weather pipeline first**: Get the data flowing before building the dashboard.
3. **Daily SMS to yourself for 2-4 weeks**: Use it. Does it actually change your fishing decisions? If yes, it's worth productizing.
4. **Add dashboard and multi-user only after personal validation**.

---

## Traceability to Project Brief

### Original Problem
Recreational anglers must manually check multiple state fish & game websites, forums, and weather sources to decide where to fish. Info is scattered and hard to parse.

### How Research Validates It
- Confirmed 5+ separate data sources per state that anglers must check
- Wyoming-specific: WGFD + 5+ fly shops + Orvis + weather + USGS gauges = 10+ sites
- User complaints across forums validate the pain point
- No existing product solves this for freshwater/Rocky Mountain anglers

### What's Still Unknown
- Exact scraping complexity for Wyoming (lowest data accessibility)
- Whether seasonal fishing forecasts are sufficient for daily briefings in WY (or if local fly shop reports are needed to fill gaps)
- User willingness to pay for this specific product (validate with personal use first)

---

## Research Files

| File | Contents |
|------|----------|
| [SCOPE.md](./SCOPE.md) | Research scope and key questions |
| [domain.md](./domain.md) | State-by-state fishing report data sources |
| [technical.md](./technical.md) | APIs, tech stack, costs, build estimates |
| [landscape.md](./landscape.md) | Competitive analysis and market signals |
