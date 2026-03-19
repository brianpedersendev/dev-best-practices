# Competitive Landscape: Fishing Copilot App

## Research Date: 2026-03-19

---

## Executive Summary

**No one is doing exactly this.** The specific combination of (1) scraping state agency fishing reports, (2) synthesizing them with weather/water data via LLM, and (3) delivering a daily text message briefing does not exist as a product today. The closest competitors each do parts of this, but none combine all three. This is a genuine gap in a growing market.

---

## Direct Competitors (Closest to the Idea)

### 1. AI Fish Report (aifishreport.com) — CLOSEST MATCH
- **What**: Hyper-personalized, location-specific fishing forecasts via "FinFinder AI." Email delivery.
- **Based in**: Shakopee, MN (Minnesota-focused)
- **Gap**: No SMS. No evidence of scraping official state reports. Minnesota only. Very early-stage (Squarespace site, gmail contact). No WY/Rocky Mountain coverage.

### 2. ReelCaster (GitHub: reelcasterdev/reelcaster-frontend) — MOST TECHNICALLY SIMILAR
- **What**: Next.js app that scrapes fishing reports from FishingVictoria.com, uses GPT-4 to extract structured data. GitHub Actions for daily automation.
- **Tech**: Next.js 15, TypeScript, Supabase, Cheerio + OpenAI, GitHub Actions
- **Cost**: ~$4-5/month for scraping (OpenAI API)
- **Gap**: British Columbia only. No SMS. No weather/water synthesis. Not a consumer product (0 GitHub stars). **Proves the scrape+LLM approach works and is cheap.**

### 3. onWater Fish — Angler Intelligence
- **What**: AI-native fishing with chat-based recommendations. "Angler Intelligence" delivers tailored recommendations. AI fish measuring. "MyWaters" alerts.
- **Funding**: $7M total ($2M raised Dec 2025)
- **Pricing**: Free tier; $50/year Plus; planned $80/year Pro
- **Revenue**: ~$1M in 2025, projecting $2.5M in 2026
- **Users**: 400,000
- **Gap**: No state agency report synthesis. No daily push briefing (must open app). No SMS. Primarily fly fishing focused. $50/year.

### 4. FishNotify (fishnotify.com)
- **What**: Coastal fishing forecast with 7-day predictions and "Fishy-ness" score. SMS/email alerts.
- **Gap**: **Ocean/coastal only** — no freshwater. No fishing report synthesis. No AI analysis.

### 5. Salt Strong / Smart Fishing Spots
- **What**: AI + human intelligence. "AI Game Plan" merges map hotspots with AI tips. Strike Score (1-10). Updates every 15 min.
- **Pricing**: $9.97/month
- **Gap**: **Saltwater/inshore only.** No freshwater. No state agency reports. No SMS. No Wyoming.

---

## Major Fishing Apps (Indirect Competitors)

### Fishbrain — Market Leader
- **Market share**: ~22% global, 20M+ users
- **Funding**: $65.8M total. Acquired by Aspira Nov 2023 at significantly reduced valuation.
- **Pricing**: ~$13/month or $80/year premium
- **Data**: Crowdsourced catches cross-referenced with weather. Garmin Navionics maps.
- **Gap**: Does NOT ingest state agency reports. No report synthesis. No daily briefing. No SMS. Community data unreliable (wrong fish photos, inaccurate locations). Wyoming coverage likely poor.

### FishAngler
- **Features**: GPS maps, weather, solunar, community catches, forecasts
- **Pricing**: Free basic; $7/month or $50/year
- **Gap**: No state agency data. No AI synthesis. Forecast accuracy criticized. No SMS.

### OnX Fish (NEW — launched April 2025)
- **Features**: Lake discovery using state fish & wildlife agency species data, contour lines, feeding times, barometric pressure
- **Pricing**: $34.99/year
- **Coverage**: **Midwest only** (MN, WI, MI, etc.). iOS only.
- **Gap**: No Wyoming. No AI synthesis. No daily briefings. No SMS. Lake-focused (no rivers/streams).

### TroutRoutes
- **Features**: 50,000+ trout streams, 280,000+ access points, real-time stream gauges, regulations
- **Pricing**: $19.99/year single state; $58.99/year PRO
- **Gap**: No AI. No report synthesis. No daily briefings. Stream mapping only. Doesn't tell you what to use.
- **Wyoming coverage**: Good — covers 48 states with strong western focus.

### BassForecast
- **Features**: Proprietary bite forecast (1-10), AI bait recommendations, AccuWeather
- **Pricing**: $5.99/month or $30/year
- **Gap**: Bass only. No state agency data. No report synthesis. No SMS. Reviews note increasing paywall ("money grab" in late 2025).

### LakeMonster
- **Features**: AI forecasts from satellite imagery, bathymetric data. Ice safety maps, thermal maps.
- **Pricing**: $7.99/month or $83.99/year
- **Gap**: No state agency reports. No push briefings. Frequent crashes. Poor reviews (3.9/5).

---

## Gap Analysis — Differentiation

| Capability | Fishing Copilot | Closest Competitor | Gap Size |
|------------|----------------|-------------------|----------|
| Scrapes state agency reports | Yes | OnX Fish (uses agency data for species, not reports) | **LARGE** |
| LLM synthesis of unstructured reports | Yes | ReelCaster (BC only, not a product) | **LARGE** |
| Weather + water flow integration | Yes | onWater, BassForecast (partial) | MEDIUM |
| Daily SMS/text delivery | Yes | FishNotify (coastal only) | **LARGE** for freshwater |
| Wyoming/Rocky Mountain focus | Yes | TroutRoutes (maps only, no AI) | **LARGE** |
| Actionable "where to go + what to use" | Yes | Salt Strong (saltwater only) | **LARGE** for freshwater |

**Core insight**: Every existing app either (a) relies on community-contributed data, or (b) uses weather/solunar algorithms. None systematically scrapes and synthesizes the official state agency reports published by biologists who actually survey the waters. This is the primary untapped data source. SMS push delivery is the secondary differentiator.

---

## User Validation Signals

**Common complaints found across forums and review sites:**
- "Keeping track of where, when, and how fish were being caught has been a giant pain in the ass" (BassResource forums)
- Fishbrain users report inaccurate community data
- FishAngler forecast accuracy criticized ("predictions changing significantly between forecasted and actual days")
- Fishidy users report "entire states have no premium data"
- General theme: **anglers must check multiple sources, cross-reference weather apps, water flow sites, and scattered guide reports to plan a trip**

**Wyoming-specific fragmentation**: An angler wanting to know "where should I fish this Saturday in Wyoming" must currently check WGFD, local fly shops (North Fork Anglers, North Platte Fly Fishing, Crazy Rainbow, Four Seasons Anglers, Wyoming Anglers), Orvis weekly reports, WyomingFishing.net, and various blogs. No single source combines all this.

---

## Open Source Landscape

| Project | Stars | What It Does | Relevance |
|---------|-------|-------------|-----------|
| reelcasterdev/reelcaster-frontend | 0 | GPT-4 fishing report scraper for BC | HIGH — closest technical analog |
| jsldvr/fishing-report | 2 | Science-based bite scores (lunar + weather) | Moderate |
| n8henrie/nmfishingreport | — | NM fishing report scraper + Pushover | HIGH — reference implementation |

---

## Market Signals

- **Fishing app market**: ~$217M in 2026, projected $587M by 2035 (CAGR 11.68%)
- **US anglers**: 57.9 million in 2024 (all-time high, 19% of US population)
- **Annual spending**: ~$100B on equipment, licenses, outings
- **What anglers pay**: $30-60/year sweet spot for premium apps
- **AI segment is nascent**: onWater is the only well-funded player with a true AI strategy (launched Oct 2025)
- **Fishbrain's valuation collapse** after $65.8M raised signals community-data models are hard to monetize

---

## Risks & Lessons

1. **Fishbrain lesson**: Don't try to build a social network. Stay focused on intelligence/briefing value.
2. **Forecast accuracy**: Every prediction app gets criticized. Use language like "conditions suggest" and be transparent about data sources.
3. **Feature creep kills**: Apps that try to be everything struggle. The SMS briefing concept is deliberately simple — protect that simplicity.
4. **ReelCaster proves the tech works**: Scrape HTML → GPT extraction → structured JSON → automated schedule costs ~$4-5/month.

---

## Sources

- [Fishbrain](https://fishbrain.com)
- [FishAngler](https://www.fishangler.com/)
- [OnX Fish](https://www.onxmaps.com/fish/app/features)
- [TroutRoutes](https://troutroutes.com/)
- [AI Fish Report](https://www.aifishreport.com/)
- [onWater Angler Intelligence](https://outdoorindustry.org/press-release/onwater-fish-launches-angler-intelligence/)
- [onWater $2M Funding](https://businessden.com/2025/12/10/fishing-and-paddle-app-nets-2m-in-funding/)
- [SI: AI Fishing App Tested with Bass Pro](https://www.si.com/onsi/fishing/bass-fishing/ai-fishing-app-tested-with-bass-pro)
- [Salt Strong Smart Fishing Spots](https://smartfishingspots.com/)
- [FishNotify](https://fishnotify.com/)
- [BassForecast](https://bassforecast.com/)
- [ReelCaster GitHub](https://github.com/reelcasterdev/reelcaster-frontend)
- [Fishing App Market Size](https://www.industryresearch.biz/market-reports/fishing-app-market-103636)
- [Record Fishing Participation 2024](https://www.nmma.org/press/article/25183)
- [Fishbrain Funding (Crunchbase)](https://www.crunchbase.com/organization/fishbrain)
