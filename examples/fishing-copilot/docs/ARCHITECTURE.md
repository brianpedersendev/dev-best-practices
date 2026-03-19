# Architecture Decisions

## Overview
Fishing Copilot is a cron-triggered batch pipeline that collects fishing reports and environmental data from free public APIs, uses Claude Haiku to extract structure from unstructured reports and synthesize daily briefings, and delivers via SMS. AI is the core product — the LLM is both the extraction resilience layer and the synthesis engine.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Pipeline architecture | Cron-triggered batch (not server) | No persistent server needed. Cheaper ($0/mo hosting), simpler, matches daily-briefing use case. |
| LLM model | Claude Haiku 4.5 Batch API | 90% Sonnet quality at 1/6th the cost. Report summarization is comprehension, not reasoning. |
| Extraction strategy | LLM-based, not CSS selectors | Resilient to site redesigns. Semantic extraction degrades gracefully. CSS selectors break on any HTML change. |
| Two-pass LLM pipeline | Extract → Synthesize (separate steps) | Structured data cached independently. Re-synthesis with different user prefs doesn't re-extract. |
| Database | SQLite (single file) | Zero-cost, zero-config. Migration to Turso preserves all queries (wire-compatible). |
| Delivery | SMS via Twilio | 98% open rate vs 20% for email. Morning fishing decisions need immediacy. |
| Cron | GitHub Actions | Free tier covers 300 min/month easily. Built-in secrets, artifact storage, failure alerts. |
| Language | Python | Best scraping ecosystem (BS4, Playwright). First-class Anthropic SDK. Best for data processing. |

## System Diagram

```
4:00 AM MT — GitHub Actions triggers daily-pipeline.yml

┌─ COLLECT ────────────────────────────────────────────────┐
│  USGS (streamflow, temp) → water_conditions table        │
│  USBR (reservoir levels) → water_conditions table        │
│  NWS (7-day forecast)    → weather_data table            │
│  Open-Meteo (pressure)   → weather_data table            │
│  USNO (moon/solunar)     → moon_solunar table            │
└──────────────────────────────────────────────────────────┘
              ↓
┌─ SCRAPE ─────────────────────────────────────────────────┐
│  WY WGFD (HTML articles, GovDelivery) → raw_reports      │
│  ID IDFG (JSON API + HTML reports)    → raw_reports      │
│  Content hash dedup — skip unchanged reports             │
└──────────────────────────────────────────────────────────┘
              ↓
┌─ EXTRACT (Claude Haiku Batch) ───────────────────────────┐
│  raw_reports → Haiku → structured_reports (JSON)         │
│  Species, techniques, flies/lures, conditions, rating    │
└──────────────────────────────────────────────────────────┘
              ↓
┌─ SYNTHESIZE (Claude Haiku Batch) ────────────────────────┐
│  structured_reports + water + weather + moon + hatch     │
│  + user_preferences → Haiku → daily briefing text        │
└──────────────────────────────────────────────────────────┘
              ↓
┌─ DELIVER ────────────────────────────────────────────────┐
│  Format briefing for SMS (≤1400 chars)                   │
│  Send via Twilio → Brian's phone by 5:30 AM MT          │
│  Log delivery status in briefings table                  │
└──────────────────────────────────────────────────────────┘
```

## Data Flow
1. **Cron trigger** (4:00 AM MT): GitHub Actions starts the pipeline
2. **Parallel collection**: All API collectors run concurrently (USGS, USBR, NWS, Open-Meteo, USNO)
3. **Sequential scraping**: State scrapers run with rate-limiting delays
4. **Dedup check**: Content hash compared to stored reports — skip unchanged
5. **Batch extraction**: New raw reports submitted to Claude Batch API
6. **Batch synthesis**: All structured data assembled, submitted for briefing generation
7. **Delivery**: Briefing formatted for SMS, sent via Twilio
8. **Logging**: Pipeline run status recorded for monitoring

## Failure Modes & Mitigation

| Failure | Impact | Mitigation |
|---------|--------|------------|
| State website down | Missing reports for that state | Pipeline continues. Briefing notes unavailable sources. |
| USGS/NWS API down | Missing water/weather data | Fallback to Open-Meteo for weather. Stale water data from last successful fetch. |
| Claude API down | No extraction or synthesis | Template-based fallback briefing from structured data only. |
| Twilio down | SMS not delivered | Retry 3x with backoff. Alert via GitHub Actions notification. |
| Scraper broken (HTML changed) | Raw content captured but extraction may degrade | LLM extraction handles semantic content regardless of markup. Alert after 3 consecutive failures. |
