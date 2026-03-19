# Fishing Copilot: Implementation Plan

**Date**: 2026-03-19
**Author**: Architecture Plan for Solo Developer
**Status**: Ready for Implementation

---

## 1. Architecture Overview

### System Diagram

```
                         DAILY PIPELINE (GitHub Actions, 4:00 AM MT)
                         ============================================

  ┌─────────────────────────────────────────────────────────────────────┐
  │                        DATA COLLECTION (4:00 AM)                    │
  │                                                                     │
  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
  │  │ WY WGFD  │  │ ID IDFG  │  │ USGS     │  │ USBR     │           │
  │  │ Scraper  │  │ API +    │  │ Water    │  │ Reservoir │           │
  │  │ (HTML)   │  │ Scraper  │  │ Services │  │ Hydromet  │           │
  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
  │       │              │             │              │                  │
  │  ┌────┴──────────────┴─────────────┴──────────────┴──────┐         │
  │  │                  Raw Data Store (SQLite)               │         │
  │  └───────────────────────┬───────────────────────────────┘         │
  │                          │                                          │
  │  ┌──────────┐  ┌────────┴────────┐  ┌───────────┐                 │
  │  │ NWS API  │  │ Open-Meteo API  │  │ USNO API  │                 │
  │  │ Forecast │  │ Pressure/Hist.  │  │ Moon/Sun  │                 │
  │  └────┬─────┘  └────────┬────────┘  └─────┬─────┘                 │
  │       └─────────────────┼──────────────────┘                       │
  │                         ▼                                           │
  │  ┌──────────────────────────────────────────────────┐              │
  │  │           Structured Data Store (SQLite)          │              │
  │  │  fishing_reports | water_conditions | weather     │              │
  │  │  moon_solunar   | hatch_calendar   | locations   │              │
  │  └──────────────────────┬───────────────────────────┘              │
  └─────────────────────────┼──────────────────────────────────────────┘
                            │
  ┌─────────────────────────┼──────────────────────────────────────────┐
  │                  LLM SYNTHESIS (4:30 AM)                            │
  │                                                                     │
  │  Step 1: EXTRACTION                    Step 2: SYNTHESIS            │
  │  ┌─────────────────────────┐          ┌──────────────────────┐     │
  │  │  Raw HTML/JSON reports  │          │  Structured data +   │     │
  │  │  ──► Claude Haiku 4.5   │          │  user prefs          │     │
  │  │  ──► Structured JSON    │          │  ──► Claude Haiku    │     │
  │  │  (Batch API)            │          │  ──► Daily Briefing  │     │
  │  └────────────┬────────────┘          └──────────┬───────────┘     │
  │               │                                   │                 │
  │               ▼                                   ▼                 │
  │  ┌─────────────────────┐          ┌──────────────────────────┐     │
  │  │  structured_reports │          │  briefings table         │     │
  │  │  (SQLite)           │          │  (SQLite)                │     │
  │  └─────────────────────┘          └──────────┬───────────────┘     │
  └──────────────────────────────────────────────┼─────────────────────┘
                                                 │
  ┌──────────────────────────────────────────────┼─────────────────────┐
  │                    DELIVERY (5:30 AM)         │                     │
  │                                               │                     │
  │  ┌──────────────────────┐    ┌───────────────┴──────────────┐      │
  │  │  Twilio SMS Gateway  │◄───│  Delivery Module             │      │
  │  │  ──► Brian's phone   │    │  (format + send)             │      │
  │  └──────────────────────┘    └──────────────────────────────┘      │
  └────────────────────────────────────────────────────────────────────┘

  ┌────────────────────────────────────────────────────────────────────┐
  │                    DASHBOARD (Phase 2)                              │
  │  ┌────────────────────────────────────────────────────────┐        │
  │  │  Cloudflare Pages (Static + API Workers)               │        │
  │  │  - Browse past briefings                               │        │
  │  │  - View water conditions / weather                     │        │
  │  │  - Configure preferences                               │        │
  │  │  - Historical trends                                   │        │
  │  └────────────────────────────────────────────────────────┘        │
  └────────────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Pipeline-first, not server-first | Cron-triggered batch pipeline | No persistent server needed. Cheaper, simpler, matches the daily-briefing use case. |
| LLM as extraction layer | Feed raw HTML to Haiku for parsing | Resilient to site redesigns. The LLM understands semantic content regardless of markup changes. Dramatically reduces scraping maintenance. |
| LLM as core, not bolt-on | AI synthesizes the final product | The briefing IS the product. Every data path feeds into LLM synthesis. Without the LLM, this is just a data aggregator. |
| Batch API over real-time | Claude Batch API for all LLM calls | 50% cost reduction. Acceptable latency since pipeline runs overnight. |
| SQLite-first | Single file database | Zero infra cost, trivially portable, migration to Turso preserves all queries. No ORM — raw SQL with parameterized queries. |
| Process once, deliver to many | Single LLM pass generates briefing, delivered to N users | LLM costs don't scale with user count. Critical for economics at scale. |
| Separation of extraction and synthesis | Two LLM passes: extract structure, then synthesize briefing | Allows caching structured data independently. Can re-synthesize with different user prefs without re-extracting. |

### AI-Native Architecture Principles

1. **AI is the product**: The LLM synthesizes scattered, inconsistent data into a coherent recommendation. Remove the AI and you have a useless pile of scraped HTML.
2. **AI as resilience layer**: Traditional scrapers break when HTML changes. The LLM extraction step degrades gracefully because it understands content semantically.
3. **AI as quality filter**: The LLM identifies stale, conflicting, or low-quality reports and weights them accordingly in the briefing.
4. **Human-in-the-loop validation**: For Phase 1, Brian reads every briefing and can flag bad recommendations, creating a feedback loop.

---

## 2. Tech Stack (Final Decisions)

| Component | Choice | Justification |
|-----------|--------|---------------|
| **Language** | Python 3.12+ | Best scraping ecosystem (requests, BeautifulSoup, Playwright). Best LLM SDK support (anthropic). Best data wrangling (stdlib json, csv). Solo dev already knows it. |
| **Dashboard** | FastAPI + Jinja2 templates on Cloudflare Workers (via Python adapter) OR **htmx + Flask** on Cloudflare Pages with Workers API | **Recommendation: Flask + htmx**. Flask is lighter than FastAPI for a simple dashboard. htmx provides interactivity without a JS framework. Cloudflare Pages hosts the static assets; Cloudflare Workers handle the API. Alternative: just generate static HTML daily and host on Pages — simplest possible. |
| **Database** | SQLite (Phase 1) with Turso migration path | SQLite is zero-cost, zero-config, and handles the data volume easily (thousands of reports). Turso is libSQL (SQLite-compatible wire protocol) so all queries port directly. Migration = point the connection string at Turso instead of a local file. |
| **LLM** | Claude Haiku 4.5 via Batch API | 90% of Sonnet quality at 1/3 the cost. Batch API halves that again. Fishing report summarization is straightforward comprehension — no need for Sonnet/Opus reasoning. ~$2.10/month for 50 reports/day. |
| **SMS** | Twilio | Simplest developer experience. $1.15/month number + $0.0083/message = ~$1.40/month for 1 user. Well-documented Python SDK. |
| **Cron** | GitHub Actions scheduled workflows | Free (2,000 min/month on private repos). Built-in secrets management. Existing CI/CD familiarity. 5-10 min daily job uses <300 min/month. |
| **Hosting** | Cloudflare Pages (dashboard) | Free tier: unlimited bandwidth, 500 builds/month. Global CDN. Workers for API endpoints if needed. |
| **Package Manager** | uv | Fastest Python package manager. Lockfile support. Replaces pip + venv + pip-tools. |
| **Testing** | pytest + responses (HTTP mocking) | Standard Python testing. `responses` library mocks HTTP calls for scraper tests. |
| **Linting** | ruff | Replaces flake8, isort, black in a single tool. Fast. |

### Why Not [Alternatives]

- **Why not Node.js?** Python's scraping ecosystem is unmatched (BeautifulSoup, Playwright, Scrapy). The Anthropic Python SDK is first-class.
- **Why not Supabase?** Adds unnecessary complexity for Phase 1. SQLite is simpler and free. Supabase's value (auth, real-time, REST) matters in Phase 3, not now.
- **Why not Next.js dashboard?** Overkill for a daily briefing display. Flask + htmx is ~100 LOC for the same result.
- **Why not AWS Lambda?** GitHub Actions is simpler for a cron job. Lambda adds IAM, packaging, and deployment complexity.
- **Why not email instead of SMS?** SMS has higher open rates (98% vs 20% for email). For a morning fishing decision, immediacy matters. Email is a good Phase 2 addition.

---

## 3. Data Model

### SQLite Schema

```sql
-- ============================================================
-- LOCATIONS: Canonical list of fishing waters
-- ============================================================
CREATE TABLE locations (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT NOT NULL,                    -- "North Platte River - Grey Reef"
    state           TEXT NOT NULL,                    -- "WY"
    water_type      TEXT NOT NULL,                    -- "river" | "lake" | "reservoir" | "creek" | "pond"
    latitude        REAL,
    longitude       REAL,
    usgs_site_id    TEXT,                             -- USGS gage site ID, nullable
    usbr_site_code  TEXT,                             -- USBR reservoir code, nullable
    nws_grid_id     TEXT,                             -- NWS grid identifier (e.g., "RIW/65,45")
    region          TEXT,                             -- Regional grouping ("SE Wyoming", "Upper Snake")
    elevation_ft    INTEGER,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(name, state)
);

-- ============================================================
-- RAW REPORTS: Verbatim scraped content before LLM processing
-- ============================================================
CREATE TABLE raw_reports (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    source          TEXT NOT NULL,                    -- "wgfd_forecast" | "idfg_planner" | "fly_shop"
    source_url      TEXT NOT NULL,
    fetched_at      TEXT NOT NULL DEFAULT (datetime('now')),
    content_hash    TEXT NOT NULL,                    -- SHA-256 of content for dedup
    raw_content     TEXT NOT NULL,                    -- Full HTML or JSON text
    content_type    TEXT NOT NULL DEFAULT 'html',     -- "html" | "json" | "text"
    state           TEXT NOT NULL,
    is_processed    INTEGER NOT NULL DEFAULT 0,       -- 0=pending, 1=processed, 2=failed
    UNIQUE(content_hash)
);

-- ============================================================
-- STRUCTURED REPORTS: LLM-extracted structured data from raw reports
-- ============================================================
CREATE TABLE structured_reports (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    raw_report_id   INTEGER NOT NULL REFERENCES raw_reports(id),
    location_id     INTEGER REFERENCES locations(id), -- nullable if location can't be matched
    location_name   TEXT NOT NULL,                     -- As extracted by LLM
    state           TEXT NOT NULL,
    report_date     TEXT,                              -- Date the report covers (may differ from fetch date)
    species         TEXT,                              -- JSON array: ["rainbow trout", "brown trout"]
    techniques      TEXT,                              -- JSON array: ["nymph", "streamer", "dry fly"]
    flies_lures     TEXT,                              -- JSON array: ["BWO #18", "Woolly Bugger #8"]
    conditions_text TEXT,                              -- LLM summary of conditions
    rating          TEXT,                              -- "excellent" | "good" | "fair" | "poor" | "unknown"
    water_clarity   TEXT,                              -- "clear" | "slightly_off" | "murky" | "blown_out"
    confidence      REAL,                              -- LLM self-assessed confidence 0.0-1.0
    extracted_at    TEXT NOT NULL DEFAULT (datetime('now')),
    extraction_model TEXT NOT NULL DEFAULT 'haiku-4.5'
);

-- ============================================================
-- WATER CONDITIONS: USGS + USBR real-time data
-- ============================================================
CREATE TABLE water_conditions (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    location_id     INTEGER NOT NULL REFERENCES locations(id),
    measured_at     TEXT NOT NULL,                     -- Timestamp from source
    fetched_at      TEXT NOT NULL DEFAULT (datetime('now')),
    source          TEXT NOT NULL,                     -- "usgs" | "usbr" | "co_dwr"
    streamflow_cfs  REAL,                              -- USGS param 00060
    gage_height_ft  REAL,                              -- USGS param 00065
    water_temp_c    REAL,                              -- USGS param 00010
    water_temp_f    REAL,                              -- Computed: water_temp_c * 9/5 + 32
    reservoir_af    REAL,                              -- USBR storage in acre-feet
    reservoir_elev  REAL,                              -- USBR elevation
    discharge_cfs   REAL,                              -- USBR total discharge
    dissolved_o2    REAL,                              -- USGS param 00300 (mg/L)
    turbidity_ntu   REAL,                              -- USGS param 63680
    ph              REAL                               -- USGS param 00400
);

-- Index for querying latest conditions per location
CREATE INDEX idx_water_conditions_location_time
    ON water_conditions(location_id, measured_at DESC);

-- ============================================================
-- WEATHER DATA: NWS + Open-Meteo
-- ============================================================
CREATE TABLE weather_data (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    location_id     INTEGER NOT NULL REFERENCES locations(id),
    forecast_date   TEXT NOT NULL,                     -- Date this forecast covers
    fetched_at      TEXT NOT NULL DEFAULT (datetime('now')),
    source          TEXT NOT NULL,                     -- "nws" | "open_meteo"
    temp_high_f     REAL,
    temp_low_f      REAL,
    wind_speed_mph  REAL,
    wind_gust_mph   REAL,
    wind_direction  TEXT,                              -- "NW", "SSE", etc.
    precip_chance   REAL,                              -- 0-100%
    precip_amount   REAL,                              -- inches
    cloud_cover     REAL,                              -- 0-100%
    pressure_msl    REAL,                              -- millibars
    pressure_trend  TEXT,                              -- "rising" | "falling" | "steady"
    conditions_text TEXT,                              -- "Partly cloudy with afternoon thunderstorms"
    uv_index        REAL,
    sunrise         TEXT,                              -- HH:MM local
    sunset          TEXT,                              -- HH:MM local
    alerts          TEXT                               -- JSON array of active NWS alerts
);

CREATE INDEX idx_weather_location_date
    ON weather_data(location_id, forecast_date DESC);

-- ============================================================
-- MOON / SOLUNAR DATA
-- ============================================================
CREATE TABLE moon_solunar (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    date            TEXT NOT NULL,                     -- YYYY-MM-DD
    latitude        REAL NOT NULL,
    longitude       REAL NOT NULL,
    moon_phase      TEXT NOT NULL,                     -- "Waxing Crescent", "Full Moon", etc.
    illumination    REAL,                              -- 0-100%
    moonrise        TEXT,                              -- HH:MM local
    moonset         TEXT,                              -- HH:MM local
    major_start_1   TEXT,                              -- HH:MM (moon overhead)
    major_end_1     TEXT,
    major_start_2   TEXT,                              -- HH:MM (moon underfoot)
    major_end_2     TEXT,
    minor_start_1   TEXT,                              -- HH:MM (moonrise)
    minor_end_1     TEXT,
    minor_start_2   TEXT,                              -- HH:MM (moonset)
    minor_end_2     TEXT,
    solunar_rating  TEXT,                              -- "excellent" | "good" | "average" | "poor"
    fetched_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(date, latitude, longitude)
);

-- ============================================================
-- HATCH CALENDAR: Static reference data (seeded, not scraped)
-- ============================================================
CREATE TABLE hatch_calendar (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    region          TEXT NOT NULL,                     -- "SE Wyoming", "Central Idaho"
    month_start     INTEGER NOT NULL,                  -- 1-12
    month_end       INTEGER NOT NULL,                  -- 1-12
    water_temp_min_f REAL,                             -- Water temp range for this hatch
    water_temp_max_f REAL,
    insect_name     TEXT NOT NULL,                     -- "Blue Winged Olive"
    insect_stage    TEXT NOT NULL,                     -- "nymph" | "emerger" | "dun" | "spinner"
    latin_name      TEXT,                              -- "Baetis"
    matching_flies  TEXT NOT NULL,                     -- JSON array: ["BWO #18", "RS2 #20"]
    time_of_day     TEXT,                              -- "morning" | "afternoon" | "evening" | "all_day"
    notes           TEXT
);

-- ============================================================
-- USER PREFERENCES (Phase 1: single user; Phase 3: multi-user)
-- ============================================================
CREATE TABLE user_preferences (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id         TEXT NOT NULL DEFAULT 'brian',     -- Phase 1: hardcoded
    home_latitude   REAL NOT NULL,
    home_longitude  REAL NOT NULL,
    radius_miles    INTEGER NOT NULL DEFAULT 150,
    target_species  TEXT NOT NULL,                     -- JSON array: ["rainbow trout", "brown trout", "cutthroat"]
    fishing_types   TEXT NOT NULL,                     -- JSON array: ["fly", "spin"]
    preferred_water TEXT,                              -- JSON array: ["river", "creek"] or null for all
    sms_phone       TEXT,                              -- E.164 format: "+13075551234"
    sms_enabled     INTEGER NOT NULL DEFAULT 1,
    email           TEXT,
    email_enabled   INTEGER NOT NULL DEFAULT 0,
    briefing_time   TEXT NOT NULL DEFAULT '05:30',     -- Local time to send briefing
    timezone        TEXT NOT NULL DEFAULT 'America/Denver',
    states          TEXT NOT NULL,                     -- JSON array: ["WY", "ID"]
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(user_id)
);

-- ============================================================
-- BRIEFINGS: Generated daily briefings
-- ============================================================
CREATE TABLE briefings (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id         TEXT NOT NULL DEFAULT 'brian',
    briefing_date   TEXT NOT NULL,                     -- YYYY-MM-DD
    briefing_text   TEXT NOT NULL,                     -- Full briefing (SMS-formatted)
    briefing_full   TEXT,                              -- Extended version (dashboard)
    top_spots       TEXT,                              -- JSON array of recommended locations
    data_sources    TEXT,                              -- JSON array of source IDs used
    model           TEXT NOT NULL DEFAULT 'haiku-4.5',
    token_input     INTEGER,
    token_output    INTEGER,
    cost_usd        REAL,
    generated_at    TEXT NOT NULL DEFAULT (datetime('now')),
    delivered_at    TEXT,                              -- When SMS was sent
    delivery_status TEXT,                              -- "sent" | "failed" | "pending"
    delivery_sid    TEXT,                              -- Twilio message SID
    UNIQUE(user_id, briefing_date)
);

-- ============================================================
-- PIPELINE RUNS: Operational logging
-- ============================================================
CREATE TABLE pipeline_runs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    run_date        TEXT NOT NULL,
    started_at      TEXT NOT NULL DEFAULT (datetime('now')),
    completed_at    TEXT,
    status          TEXT NOT NULL DEFAULT 'running',   -- "running" | "completed" | "failed"
    step            TEXT NOT NULL,                     -- "scrape" | "water" | "weather" | "extract" | "synthesize" | "deliver"
    details         TEXT,                              -- JSON with step-specific metadata
    error_message   TEXT,
    UNIQUE(run_date, step)
);
```

### Design Principles

1. **All JSON arrays stored as TEXT**: SQLite has JSON functions (`json_extract`, `json_each`) for querying. Keeps schema flat.
2. **Content hashing for dedup**: `raw_reports.content_hash` prevents reprocessing unchanged content.
3. **Separate raw and structured**: Raw data is immutable; structured data can be re-extracted if the LLM prompt improves.
4. **Timestamps everywhere**: Every record has `fetched_at` or `created_at` for staleness tracking.
5. **Pipeline runs table**: Operational visibility. Know exactly what ran, when, and whether it succeeded.

---

## 4. MVP Feature List (Prioritized)

### Phase 1: Personal Use (Weeks 1-5)
**Goal**: Brian gets a useful daily SMS briefing for WY + ID fishing.

| # | Feature | Priority | Est. Time |
|---|---------|----------|-----------|
| 1.1 | SQLite database setup + seed locations (WY + ID waters) | Must | 0.5 days |
| 1.2 | USGS water conditions collector (streamflow, temp, gage height) | Must | 1 day |
| 1.3 | USBR reservoir data collector (WY reservoirs) | Must | 0.5 days |
| 1.4 | NWS weather forecast collector | Must | 1 day |
| 1.5 | Open-Meteo barometric pressure collector | Must | 0.5 days |
| 1.6 | USNO moon/solunar data collector | Should | 0.5 days |
| 1.7 | Wyoming fishing report scraper (WGFD forecasts + GovDelivery) | Must | 3-4 days |
| 1.8 | Idaho fishing report scraper (IDFG API + steelhead reports) | Must | 2-3 days |
| 1.9 | LLM extraction pipeline (raw HTML -> structured reports) | Must | 2-3 days |
| 1.10 | LLM synthesis pipeline (structured data -> daily briefing) | Must | 2-3 days |
| 1.11 | Twilio SMS delivery module | Must | 1 day |
| 1.12 | GitHub Actions cron workflow | Must | 1 day |
| 1.13 | Hatch calendar seed data (WY + ID) | Should | 1 day |
| 1.14 | User preferences configuration (hardcoded for Brian) | Must | 0.5 days |
| 1.15 | Pipeline orchestrator (ties all steps together) | Must | 1 day |
| 1.16 | Error handling + logging + alerting (SMS on failure) | Must | 1 day |
| 1.17 | Integration tests for all data collectors | Must | 2 days |

**Phase 1 Total**: ~3-4 weeks

### Phase 2: Dashboard + More States (Weeks 6-10)
**Goal**: Web dashboard for browsing briefings + historical data. Add CO and/or UT.

| # | Feature | Priority | Est. Time |
|---|---------|----------|-----------|
| 2.1 | Flask web application skeleton | Must | 1 day |
| 2.2 | Dashboard: today's briefing view | Must | 1 day |
| 2.3 | Dashboard: briefing history/archive | Must | 1 day |
| 2.4 | Dashboard: water conditions charts (sparklines) | Should | 2 days |
| 2.5 | Dashboard: weather overlay per location | Should | 1 day |
| 2.6 | Dashboard: preferences configuration UI | Must | 1 day |
| 2.7 | Colorado fishing report scraper (CPW conditions + stocking) | Must | 3-4 days |
| 2.8 | Utah fishing report scraper (DWR RSS + stocking AJAX) | Should | 2-3 days |
| 2.9 | Email delivery option (Resend) | Should | 1 day |
| 2.10 | Deploy dashboard to Cloudflare Pages | Must | 1 day |
| 2.11 | Migrate SQLite to Turso | Should | 1 day |
| 2.12 | Historical trend analysis (compare this week vs last year) | Nice | 2 days |

**Phase 2 Total**: ~3-4 weeks

### Phase 3: Multi-User + Monetization (Weeks 11-16)
**Goal**: Other anglers can sign up, configure preferences, and receive briefings.

| # | Feature | Priority | Est. Time |
|---|---------|----------|-----------|
| 3.1 | User auth (Cloudflare Access or simple magic link) | Must | 2 days |
| 3.2 | User registration + onboarding flow | Must | 2 days |
| 3.3 | Per-user preferences (location, species, radius, delivery) | Must | 2 days |
| 3.4 | Per-user briefing generation (template + personalization) | Must | 2 days |
| 3.5 | Stripe subscription integration ($5/month) | Must | 2 days |
| 3.6 | Montana fishing report scraper (FishMT CSV + stocking) | Should | 2-3 days |
| 3.7 | Landing page + marketing site | Must | 2 days |
| 3.8 | Usage analytics + cost tracking | Should | 1 day |
| 3.9 | Feedback mechanism (reply to SMS with rating) | Nice | 2 days |
| 3.10 | Admin dashboard (user management, pipeline health) | Should | 2 days |

**Phase 3 Total**: ~4-5 weeks

---

## 5. Module Breakdown (Phase 1)

### Project Structure

```
fishing-copilot/
├── pyproject.toml                  # Project config (uv)
├── .github/
│   └── workflows/
│       └── daily-pipeline.yml      # GitHub Actions cron workflow
├── src/
│   └── fishing_copilot/
│       ├── __init__.py
│       ├── main.py                 # Pipeline entry point / orchestrator
│       ├── config.py               # Configuration + environment variables
│       ├── db/
│       │   ├── __init__.py
│       │   ├── connection.py       # SQLite connection management
│       │   ├── schema.py           # Schema creation + migrations
│       │   └── queries.py          # Reusable query functions
│       ├── collectors/
│       │   ├── __init__.py
│       │   ├── base.py             # Base collector protocol/ABC
│       │   ├── usgs_water.py       # USGS Water Services API
│       │   ├── usbr_reservoir.py   # Bureau of Reclamation Hydromet
│       │   ├── nws_weather.py      # NWS Weather API
│       │   ├── open_meteo.py       # Open-Meteo (pressure, historical)
│       │   ├── usno_moon.py        # US Naval Observatory (moon/solunar)
│       │   └── hatch_calendar.py   # Static hatch data loader
│       ├── scrapers/
│       │   ├── __init__.py
│       │   ├── base.py             # Base scraper protocol/ABC
│       │   ├── wyoming.py          # WGFD fishing reports + GovDelivery
│       │   └── idaho.py            # IDFG Fishing Planner API + reports
│       ├── llm/
│       │   ├── __init__.py
│       │   ├── client.py           # Anthropic API client wrapper
│       │   ├── extraction.py       # Raw report -> structured data
│       │   ├── synthesis.py        # Structured data -> daily briefing
│       │   └── prompts.py          # All prompt templates
│       ├── delivery/
│       │   ├── __init__.py
│       │   ├── sms.py              # Twilio SMS delivery
│       │   └── formatter.py        # Briefing text formatting (SMS length)
│       └── utils/
│           ├── __init__.py
│           ├── geo.py              # Distance calculations, coordinate helpers
│           ├── hashing.py          # Content hashing for dedup
│           └── logging.py          # Structured logging setup
├── data/
│   ├── seed_locations.json         # Initial WY + ID fishing waters
│   ├── hatch_calendar.json         # Hatch chart reference data
│   └── fishing_copilot.db          # SQLite database (gitignored)
├── tests/
│   ├── conftest.py                 # Shared fixtures
│   ├── test_collectors/
│   │   ├── test_usgs_water.py
│   │   ├── test_usbr_reservoir.py
│   │   ├── test_nws_weather.py
│   │   ├── test_open_meteo.py
│   │   └── test_usno_moon.py
│   ├── test_scrapers/
│   │   ├── test_wyoming.py
│   │   └── test_idaho.py
│   ├── test_llm/
│   │   ├── test_extraction.py
│   │   └── test_synthesis.py
│   ├── test_delivery/
│   │   └── test_sms.py
│   └── test_pipeline/
│       └── test_main.py
└── scripts/
    ├── seed_db.py                  # One-time database seed script
    ├── test_apis.py                # Manual API connectivity check
    └── run_pipeline.py             # Local pipeline execution
```

### Module Details

| Module | Description | Dependencies | Est. LOC |
|--------|-------------|--------------|----------|
| `main.py` | Pipeline orchestrator. Runs steps in order: collect -> scrape -> extract -> synthesize -> deliver. Handles step failures gracefully. | All modules | 120 |
| `config.py` | Loads environment variables (API keys, DB path, phone numbers). Validates required config at startup. | None | 60 |
| `db/connection.py` | SQLite connection factory with WAL mode, foreign keys enabled. Context manager for transactions. | sqlite3 | 50 |
| `db/schema.py` | Creates all tables if not exists. Handles schema migrations. | db/connection | 80 |
| `db/queries.py` | Named query functions: insert_raw_report, get_latest_conditions, get_pending_reports, insert_briefing, etc. | db/connection | 150 |
| `collectors/base.py` | Abstract base class with `collect()` method, standard error handling, retry logic. | None | 40 |
| `collectors/usgs_water.py` | Fetches streamflow, water temp, gage height from USGS for configured sites. | requests, base | 100 |
| `collectors/usbr_reservoir.py` | Fetches reservoir levels and releases from USBR Hydromet. | requests, base | 80 |
| `collectors/nws_weather.py` | Fetches 7-day forecast for each location from NWS API. Two-step: points -> forecast. | requests, base | 120 |
| `collectors/open_meteo.py` | Fetches barometric pressure (hourly), historical weather. | requests, base | 80 |
| `collectors/usno_moon.py` | Fetches moon phase, rise/set, illumination. Calculates solunar periods from transit times. | requests, base | 100 |
| `collectors/hatch_calendar.py` | Loads static hatch data from JSON, matches against current water temps. | None | 50 |
| `scrapers/base.py` | Abstract base: fetch page, check content hash for changes, store raw content. | requests, bs4, hashing | 60 |
| `scrapers/wyoming.py` | Scrapes WGFD fishing forecasts, GovDelivery bulletins, stocking app. | requests, bs4, base | 150 |
| `scrapers/idaho.py` | Calls IDFG Fishing Planner API, scrapes steelhead reports. | requests, bs4, base | 120 |
| `llm/client.py` | Anthropic SDK wrapper. Handles batch API submission + result retrieval. Rate limiting and retries. | anthropic | 100 |
| `llm/extraction.py` | Feeds raw reports to Haiku, gets structured JSON back. Validates output schema. | llm/client, prompts | 100 |
| `llm/synthesis.py` | Combines all structured data + user prefs into a final briefing prompt. Formats output. | llm/client, prompts | 120 |
| `llm/prompts.py` | All prompt templates as constants. Extraction prompt, synthesis prompt, fallback prompts. | None | 100 |
| `delivery/sms.py` | Twilio SDK wrapper. Sends SMS, tracks delivery status. | twilio | 60 |
| `delivery/formatter.py` | Formats briefing for SMS (160 char segments), truncation, priority ordering. | None | 80 |
| `utils/geo.py` | Haversine distance calculation, bounding box generation. | math | 30 |
| `utils/hashing.py` | SHA-256 content hashing for dedup. | hashlib | 15 |
| `utils/logging.py` | Structured JSON logging to stdout (GitHub Actions captures it). | logging | 40 |

**Total estimated LOC: ~2,100** (source code, excluding tests)
**Test LOC: ~1,200**
**Total: ~3,300**

---

## 6. API Integration Details

### 6.1 USGS Water Services

**Purpose**: Real-time streamflow, water temperature, gage height for rivers and streams.

**Endpoint**:
```
GET https://waterservices.usgs.gov/nwis/iv/
```

**Request Parameters**:
| Parameter | Value | Notes |
|-----------|-------|-------|
| `format` | `json` | Returns JSON (WaterML is XML) |
| `sites` | `06186500,06235500,...` | Comma-separated USGS site IDs |
| `parameterCd` | `00060,00010,00065` | Streamflow, water temp, gage height |
| `siteStatus` | `active` | Only active gages |
| `period` | `P1D` | Last 24 hours of data |

**Alternative query by state** (for discovery):
```
GET https://waterservices.usgs.gov/nwis/iv/?format=json&stateCd=WY&parameterCd=00060,00010,00065&siteType=ST&siteStatus=active
```

**Response Handling**:
- Response is nested JSON: `value.timeSeries[].values[].value[]`
- Each `timeSeries` entry has a `variable` (parameter) and `sourceInfo` (site)
- Extract the most recent value from `values[0].value[-1]` (last observation)
- Parse `dateTime` as ISO 8601 with timezone
- Convert water temp from Celsius to Fahrenheit for storage

**Error Handling**:
- HTTP 200 with empty `timeSeries`: Site is offline or parameter unavailable. Log and skip.
- HTTP 400: Bad site ID or parameter. Fail loudly, fix config.
- HTTP 503: Service temporarily unavailable. Retry with exponential backoff (3 attempts, 30s/60s/120s).
- Timeout: 30 second timeout per request.

**Rate Limiting**:
- No hard rate limit. USGS returns `Cache-Control: max-age=900` (15 min).
- Batch sites into a single request (up to 100 sites per call) to minimize requests.
- One request per state covers all needed sites. Target: 2-3 requests total.

---

### 6.2 Bureau of Reclamation Hydromet

**Purpose**: Reservoir storage levels, elevation, inflow, and discharge for Wyoming reservoirs.

**Endpoint**:
```
GET https://www.usbr.gov/gp-bin/arcread.pl
```

**Request Parameters**:
| Parameter | Value | Notes |
|-----------|-------|-------|
| `st` | `BOYR` | Site code (e.g., Boysen) |
| `by` | `2026` | Begin year |
| `bm` | `3` | Begin month |
| `bd` | `18` | Begin day |
| `ey` | `2026` | End year |
| `em` | `3` | End month |
| `ed` | `19` | End day |
| `pa` | `af,el,qd` | Parameters: storage, elevation, discharge |
| `json` | `1` | Return JSON |

**Known Site Codes**:
`BOYR` (Boysen), `BFAL` (Buffalo Bill), `PATH` (Pathfinder), `SEMI` (Seminoe), `ALCK` (Alcova), `GLDO` (Glendo), `KEHO` (Keyhole), `BIGH` (Bighorn), `GURC` (Guernsey)

**Note**: Flaming Gorge (`FLGR`) returns bad data on the GP endpoint. Use USGS site `09235000` (Green River below Flaming Gorge Dam) instead.

**Response Handling**:
- JSON structure: object with parameter keys, each containing an array of `[date, value]` pairs.
- Take the most recent non-null value for each parameter.
- Values may be `-999` or similar sentinel for missing data — treat as null.

**Error Handling**:
- The endpoint is old and fragile. May return HTML error page instead of JSON.
- Check `Content-Type` header; if not JSON, log error and skip.
- One request per reservoir (no batch endpoint). Make requests sequentially with 1s delay.
- Timeout: 15 seconds. If a single reservoir fails, continue with the rest.

**Rate Limiting**:
- No documented limits. Be conservative: 1 request per second, max 10 reservoirs.

---

### 6.3 NWS Weather API

**Purpose**: 7-day weather forecasts, hourly data, and active weather alerts.

**Endpoints**:
```
GET https://api.weather.gov/points/{lat},{lon}
GET https://api.weather.gov/gridpoints/{office}/{X},{Y}/forecast
GET https://api.weather.gov/alerts/active?area=WY
```

**Request Flow** (two-step):
1. **Resolve grid**: `GET /points/43.0,-108.0` returns `properties.forecast` URL and `properties.gridId`/`gridX`/`gridY`.
2. **Get forecast**: `GET /gridpoints/RIW/65,45/forecast` returns 14 forecast periods.

**Headers**:
```
User-Agent: FishingCopilot/1.0 (brian@example.com)
Accept: application/geo+json
```

**Response Handling**:
- Forecast: `properties.periods[]` — each period has `name`, `temperature`, `windSpeed`, `windDirection`, `shortForecast`, `detailedForecast`, `probabilityOfPrecipitation`.
- Alerts: `features[]` — each alert has `properties.event`, `properties.headline`, `properties.severity`.
- Cache grid resolution (step 1) — it doesn't change. Only re-fetch forecasts.

**Error Handling**:
- HTTP 500/503: NWS API has occasional outages. Retry 3 times with 30s backoff. If all fail, use Open-Meteo as fallback.
- HTTP 404 on `/points`: Invalid coordinates. Fail loudly.
- `properties.periods` may be empty during server errors — validate array length.

**Rate Limiting**:
- No hard throttle documented, but NWS recommends reasonable use.
- Cache grid coordinates (step 1) indefinitely — they're static for a given lat/lon.
- One forecast request per unique grid point. Group nearby locations sharing the same grid point.
- Target: ~10-15 forecast requests per pipeline run.

---

### 6.4 Open-Meteo

**Purpose**: Barometric pressure (hourly), historical weather data, sunrise/sunset.

**Endpoint**:
```
GET https://api.open-meteo.com/v1/forecast
```

**Request Parameters**:
| Parameter | Value | Notes |
|-----------|-------|-------|
| `latitude` | `43.0` | |
| `longitude` | `-108.0` | |
| `hourly` | `pressure_msl,surface_pressure` | Barometric pressure |
| `daily` | `sunrise,sunset,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max` | Daily summary |
| `timezone` | `America/Denver` | Local time |
| `forecast_days` | `3` | Today + 2 days |

**Response Handling**:
- Hourly: `hourly.pressure_msl[]` aligned with `hourly.time[]`. Extract today's values and compute 3-hour trend (rising/falling/steady).
- Daily: `daily.sunrise[0]`, `daily.sunset[0]`, etc.
- Pressure trend: Compare average of last 3 hours vs previous 3 hours. Difference > 1 mbar = "rising"/"falling", else "steady".

**Error Handling**:
- HTTP 400: Bad coordinates or parameters. Fail loudly.
- HTTP 429: Rate limit exceeded. Wait 60 seconds, retry once.
- API returns `null` for unavailable data points — handle gracefully.

**Rate Limiting**:
- 10,000 requests/day free tier. Pipeline uses ~10-20 requests — well under limit.
- Batch multiple locations into fewer requests where possible (Open-Meteo doesn't support multi-location in one call, but nearby locations can share a forecast).

---

### 6.5 US Naval Observatory (USNO)

**Purpose**: Moon phase, moonrise/moonset, solunar period calculation.

**Endpoints**:
```
GET https://aa.usno.navy.mil/api/rstt/oneday?date=2026-03-19&coords=43,-108
GET https://aa.usno.navy.mil/api/moon/phases/date?date=2026-03-19&nump=4
```

**Request Parameters**:
| Parameter | Value | Notes |
|-----------|-------|-------|
| `date` | `2026-03-19` | Target date |
| `coords` | `43,-108` | Latitude, longitude |
| `nump` | `4` | Number of upcoming phases |

**Response Handling**:
- `rstt/oneday`: Returns `properties.data.moondata[]` with `phen` (Rise/Set/Upper Transit/Lower Transit) and `time` (HH:MM).
- Moon phase from `properties.data.curphase` or compute from illumination.
- Calculate solunar periods:
  - Major: 2 hours centered on Upper Transit and Lower Transit (moon underfoot = transit + 12 hours if not provided)
  - Minor: 1 hour centered on moonrise and moonset

**Error Handling**:
- USNO API occasionally returns HTTP 500. Retry 2 times with 30s delay.
- If fully unavailable, skip solunar data for the day (nice-to-have, not critical).

**Rate Limiting**:
- No documented limits. Use sparingly — 1-2 requests per pipeline run (one set of coords is sufficient for the whole region).

---

### 6.6 State Scrapers

#### Wyoming (WGFD)

**Target Pages**:
1. **Fishing News**: `https://wgfd.wyo.gov/fishing-boating/fishing-news` — List of article links
2. **Individual forecast articles**: Linked from fishing news page. HTML articles.
3. **GovDelivery bulletins**: `https://content.govdelivery.com/accounts/WYWGFD/bulletins/` — Monthly fishing updates (HTML).
4. **Fish Stocking**: `https://wgfapps.wyo.gov/FishStock/FishStock` — ASP.NET app (Telerik controls). May require Playwright for dynamic content.

**Approach**: Since WY data is sparse and unstructured (narrative articles), use the LLM-as-extraction-layer strategy. Scrape the raw HTML and feed it directly to Haiku for structured extraction.

**Selectors (subject to change — LLM extraction reduces dependency on these)**:
- Fishing News article list: `div.article-list a[href*="fishing"]` or similar container
- Article body: `div.article-body` or `div.field-item`
- GovDelivery content: `div.bulletin_body` or `td.bulletin_body`

**Change Detection**: Hash the article list page. If hash changes, fetch new article URLs. Hash each article individually.

#### Idaho (IDFG)

**API Endpoints**:
1. **Fishing Planner autocomplete**: `https://idfg.idaho.gov/ifwis/fishingplanner/api/2.0/autocomplete/` — JSON array of all 12,000+ waters
2. **Fishing Planner water detail**: `https://idfg.idaho.gov/ifwis/fishingplanner/water/{id}` — HTML page with species, regulations, stocking history
3. **Steelhead reports**: `https://idfg.idaho.gov/fish/steelhead-reports` — Weekly HTML articles with structured catch data

**Approach**: Use the JSON API for water discovery and baseline data. Scrape steelhead reports as the most structured fishing condition data. Feed both to Haiku for extraction.

**Selectors for steelhead reports**:
- Article list: Look for date-stamped links in the report page
- Report body: `div.field--name-body` or `article .content`
- Tables within reports: `table` (structured catch data per location)

---

## 7. LLM Pipeline Design

### 7.1 Extraction Prompt (Raw HTML -> Structured Data)

```
System: You are a fishing report data extraction assistant. Your job is to extract
structured fishing information from raw HTML content. Extract ONLY what is explicitly
stated in the report — do not infer or hallucinate information.

Return a JSON array of report entries. Each entry represents one water body mentioned
in the report.

User: Extract structured fishing data from this {state} fishing report.

Source: {source_url}
Fetched: {fetch_date}

<report>
{raw_html_content}
</report>

Return ONLY valid JSON matching this schema:
{
  "entries": [
    {
      "location_name": "string — exact water body name as written",
      "state": "string — two-letter state code",
      "report_date": "string — YYYY-MM-DD if date is mentioned, null otherwise",
      "species": ["string — fish species mentioned"],
      "techniques": ["string — fishing methods: fly, spin, bait, trolling, etc."],
      "flies_lures": ["string — specific flies, lures, or bait mentioned with sizes"],
      "conditions_summary": "string — 1-2 sentence summary of fishing conditions",
      "rating": "excellent | good | fair | poor | unknown",
      "water_clarity": "clear | slightly_off | murky | blown_out | null",
      "water_temp_f": "number or null",
      "flow_description": "string or null — any mention of flow conditions",
      "stocking_info": "string or null — any stocking mentions",
      "access_notes": "string or null — any access/closure mentions",
      "confidence": 0.0-1.0
    }
  ],
  "report_scope": "string — what region/time period this report covers",
  "report_freshness": "string — how recent does this information appear to be"
}
```

**Token Budget**: ~500 tokens system + ~1,000 tokens input (trimmed HTML) + ~400 tokens output = ~1,900 tokens per report.

### 7.2 Synthesis Prompt (Structured Data -> Daily Briefing)

```
System: You are a fishing guide assistant creating a morning briefing for an angler.
Your briefing should be practical, specific, and actionable. Write like a knowledgeable
local guide — direct, opinionated, and focused on what matters TODAY.

Rules:
- Lead with the #1 recommended spot and why
- Rank top 3-5 spots by fishing quality RIGHT NOW
- Include specific technique and fly/lure recommendations
- Factor in weather (wind, pressure, temperature) and water conditions
- Note solunar periods if they align with good fishing windows
- Flag any hazards (high water, storms, closures)
- Keep SMS version under 1400 characters (fits in ~9 SMS segments)
- Use plain language, no jargon that needs explanation

User: Generate today's fishing briefing.

## Angler Profile
- Home: {latitude}, {longitude} ({city, state})
- Max drive: {radius_miles} miles
- Target species: {species_list}
- Fishing types: {fishing_types}
- States covered: {states}

## Today's Date: {date}

## Current Fishing Reports (last 7 days)
{structured_reports_json}

## Water Conditions (real-time)
{water_conditions_json}

## Weather Forecast
{weather_json}

## Barometric Pressure
Current: {pressure_msl} mb, Trend: {pressure_trend}

## Moon/Solunar
Phase: {moon_phase} ({illumination}%)
Major periods: {major_periods}
Minor periods: {minor_periods}

## Active Hatches (based on water temps and season)
{hatch_matches_json}

## Weather Alerts
{alerts_json}

Generate two versions:
1. "sms": Concise briefing under 1400 characters. Lead with top spot. No markdown.
2. "full": Detailed briefing with all spots, conditions breakdown, and reasoning. Use markdown formatting.

Return as JSON:
{
  "sms": "string",
  "full": "string",
  "top_spots": [
    {
      "location": "string",
      "rating": "string",
      "reason": "string — one sentence why"
    }
  ],
  "data_quality_notes": "string — any gaps or stale data the angler should know about"
}
```

**Token Budget**: ~600 tokens system + ~3,000 tokens structured data + ~1,500 tokens output = ~5,100 tokens per synthesis.

### 7.3 Batch API Workflow

```
Timeline:
  4:00 AM MT — Pipeline starts
  4:00-4:15  — Data collection (APIs + scraping)
  4:15-4:20  — Submit Batch API request (extraction)
              Send all raw reports as a single batch
  4:20-5:00  — Poll for batch completion (typically 5-30 min)
  5:00-5:05  — Process extraction results, store structured reports
  5:05-5:10  — Submit synthesis batch (single request)
  5:10-5:25  — Poll for synthesis completion
  5:25-5:30  — Store briefing, send SMS
  5:30 AM    — Brian receives SMS
```

**Batch API Details**:
1. Create a JSONL file with all extraction requests (one per raw report).
2. Submit via `client.batches.create()` with `completion_window="24h"`.
3. Poll `client.batches.retrieve(batch_id)` every 60 seconds until `status == "ended"`.
4. Retrieve results via `client.batches.results(batch_id)`.
5. For synthesis: single request, but still use Batch API for the 50% discount.

**Fallback: If Batch API doesn't complete within 45 minutes**, switch to synchronous Haiku calls. Cost doubles (~$0.14/day instead of $0.07) but the briefing still goes out on time.

### 7.4 Token Budget Summary

| Step | Input Tokens | Output Tokens | Daily Cost (Batch) |
|------|-------------|---------------|-------------------|
| Extraction (50 reports) | ~50,000 | ~20,000 | $0.025 + $0.050 = $0.075 |
| Synthesis (1 briefing) | ~4,000 | ~1,500 | $0.002 + $0.004 = $0.006 |
| **Daily Total** | ~54,000 | ~21,500 | **~$0.08** |
| **Monthly Total** | | | **~$2.40** |

### 7.5 Fallback Strategy

| Failure | Fallback |
|---------|----------|
| Batch API timeout (>45 min) | Switch to synchronous Haiku calls |
| Anthropic API down entirely | Send SMS with raw data summary (no LLM synthesis). Template: "API down — here are today's conditions: {water_temps}, {flows}, {weather}. Check reports manually." |
| Extraction returns invalid JSON | Retry once with stricter prompt. If still invalid, skip that report and note in briefing. |
| Synthesis returns invalid JSON | Retry once. If still invalid, send the `sms` field from last successful briefing with a "data may be stale" warning. |

---

## 8. Scraping Strategy Per State

### 8.1 Wyoming (WGFD)

Wyoming has the least accessible data of all target states. Strategy: cast a wide net and let the LLM sort it out.

**Source 1: Fishing News Page**
- URL: `https://wgfd.wyo.gov/fishing-boating/fishing-news`
- Type: Static HTML
- Frequency: Check daily, new articles appear irregularly (seasonal forecasts 2x/year, news as-it-happens)
- Strategy:
  1. Fetch the news listing page
  2. Extract all article URLs from the page
  3. Hash the URL list. If unchanged from last run, skip.
  4. For new URLs, fetch each article page
  5. Store raw HTML in `raw_reports` with `source='wgfd_news'`
  6. Feed to Haiku for extraction
- Selectors: Use CSS selectors to find article links, but fall back to feeding the entire page to Haiku if selectors break.

**Source 2: GovDelivery Bulletins**
- URL: `https://content.govdelivery.com/accounts/WYWGFD/bulletins/`
- Type: HTML bulletin pages
- Frequency: Monthly fishing updates
- Strategy:
  1. This is harder to scrape programmatically (no public listing).
  2. **Alternative**: Subscribe to GovDelivery with a dedicated email address. Use email-to-webhook (e.g., Cloudflare Email Workers) to capture bulletins.
  3. **Simpler alternative for Phase 1**: Manually forward GovDelivery emails to the pipeline. Auto-ingest later.
  4. If scraping: bulletins follow the URL pattern `content.govdelivery.com/accounts/WYWGFD/bulletins/{id}`. Try incrementing IDs near known recent bulletins.

**Source 3: Fish Stocking App**
- URL: `https://wgfapps.wyo.gov/FishStock/FishStock`
- Type: ASP.NET with Telerik controls (server-rendered, AJAX postbacks)
- Strategy:
  1. This likely requires Playwright for dynamic content.
  2. Use Playwright to: navigate to page -> set year filter to current year -> set county filter -> trigger search -> capture results table HTML.
  3. Feed the results table HTML to Haiku for extraction.
  4. Run for each target county (Natrona, Fremont, Park, etc.).
- Frequency: Weekly (stocking events happen on a schedule).

**Change Detection**:
- Content hash on each raw page. Only re-process when hash changes.
- If main selectors fail (no articles found), send alert SMS and fall back to LLM extraction of full page.
- Log selector failures to `pipeline_runs` table.

### 8.2 Idaho (IDFG)

Idaho has the best data access. Prioritize the API and structured reports.

**Source 1: Fishing Planner API**
- URL: `https://idfg.idaho.gov/ifwis/fishingplanner/api/2.0/autocomplete/`
- Type: JSON API (no auth required)
- Returns: Array of 12,000+ waters with IDs, names, and region metadata
- Strategy:
  1. Fetch the full autocomplete list (cache it — it changes infrequently).
  2. Filter to waters within the user's configured radius.
  3. For each relevant water, fetch the detail page: `https://idfg.idaho.gov/ifwis/fishingplanner/water/{id}`
  4. The detail page contains species present, regulations, stocking history, and sometimes recent survey data.
  5. Feed detail pages to Haiku for extraction.
- Frequency: Water list — weekly. Detail pages — weekly or when stocking data updates.

**Source 2: Steelhead Fishing Reports**
- URL: `https://idfg.idaho.gov/fish/steelhead-reports` (or similar — URL may vary by season)
- Type: HTML articles with embedded data tables
- Frequency: Weekly during steelhead season (Oct-Apr)
- Strategy:
  1. Fetch the reports listing page.
  2. Extract article links.
  3. Fetch each article.
  4. These reports are highly structured: catch rates per section, effort hours, water conditions.
  5. Feed to Haiku for extraction. Expect high-confidence structured output.

**Source 3: Regional Stocking Schedules**
- URL: `https://idfg.idaho.gov/fish/stocking` — links to 7 regional stocking pages
- Type: HTML tables
- Strategy:
  1. Fetch each regional page.
  2. Parse stocking tables (species, water, date, quantity).
  3. These tables are structured enough for BeautifulSoup parsing.
  4. Cross-reference with Fishing Planner water IDs for location matching.

**Change Detection**:
- Fishing Planner API: Compare response hash.
- Steelhead reports: Check for new article URLs.
- Stocking schedules: Hash each regional page.

### 8.3 Handling Site Changes

1. **Structural assertions**: Before parsing, assert that expected elements exist (e.g., "page contains at least 1 article link" or "table has at least 3 rows"). If assertions fail, alert.
2. **LLM fallback**: If CSS selectors fail but we still get HTML, feed the entire page to Haiku with a more general extraction prompt: "Extract any fishing-related information from this page."
3. **Monitoring**: Every scraper run logs: pages fetched, articles found, extraction success/failure counts, and any selector misses to `pipeline_runs`.
4. **Grace period**: If a scraper fails for 3 consecutive days, send an alert SMS. The pipeline continues with cached data from the last successful run.

---

## 9. Daily Briefing Pipeline

### Step-by-Step Workflow

```
4:00 AM MT  ┌─────────────────────────────────────────────────────┐
            │  STEP 1: COLLECT ENVIRONMENTAL DATA                  │
            │                                                       │
            │  Parallel:                                            │
            │  ├── USGS Water Services (WY + ID sites)             │
            │  ├── USBR Reservoir Hydromet (9 WY reservoirs)       │
            │  ├── NWS Weather Forecast (per location grid)        │
            │  ├── Open-Meteo Barometric Pressure                  │
            │  └── USNO Moon/Solunar                               │
            │                                                       │
            │  Store all results in SQLite.                         │
            │  Log success/failure per source in pipeline_runs.     │
            └──────────────────────────┬──────────────────────────┘
                                       │
4:10 AM     ┌──────────────────────────┴──────────────────────────┐
            │  STEP 2: SCRAPE FISHING REPORTS                      │
            │                                                       │
            │  Sequential (respectful of servers):                  │
            │  ├── Wyoming: WGFD fishing news + GovDelivery         │
            │  └── Idaho: IDFG API + steelhead reports              │
            │                                                       │
            │  For each page:                                       │
            │    1. Fetch HTML/JSON                                 │
            │    2. Compute content hash                            │
            │    3. If hash unchanged from last run → skip          │
            │    4. If new → store in raw_reports                   │
            │                                                       │
            │  Log pages fetched, new content found, failures.      │
            └──────────────────────────┬──────────────────────────┘
                                       │
4:15 AM     ┌──────────────────────────┴──────────────────────────┐
            │  STEP 3: LLM EXTRACTION (Batch API)                  │
            │                                                       │
            │  1. Query raw_reports WHERE is_processed = 0          │
            │  2. Build JSONL batch: one extraction request per     │
            │     unprocessed report                                │
            │  3. Submit batch to Claude Haiku 4.5 Batch API       │
            │  4. Poll every 60s until batch completes              │
            │  5. Parse results → store in structured_reports       │
            │  6. Mark raw_reports as processed                     │
            │                                                       │
            │  TIMEOUT: If batch hasn't completed by 4:50 AM,      │
            │  switch to synchronous API calls for remaining.       │
            └──────────────────────────┬──────────────────────────┘
                                       │
5:00 AM     ┌──────────────────────────┴──────────────────────────┐
            │  STEP 4: ASSEMBLE CONTEXT                            │
            │                                                       │
            │  Query from SQLite:                                   │
            │  ├── structured_reports (last 7 days, within radius) │
            │  ├── water_conditions (latest per location)           │
            │  ├── weather_data (today + tomorrow)                  │
            │  ├── moon_solunar (today)                             │
            │  ├── hatch_calendar (matching current temps + month) │
            │  └── user_preferences                                 │
            │                                                       │
            │  Assemble into synthesis prompt context.              │
            └──────────────────────────┬──────────────────────────┘
                                       │
5:05 AM     ┌──────────────────────────┴──────────────────────────┐
            │  STEP 5: LLM SYNTHESIS (Batch or Sync API)           │
            │                                                       │
            │  1. Build synthesis prompt with all assembled data    │
            │  2. Submit to Claude Haiku 4.5                        │
            │  3. Parse JSON response (sms + full versions)         │
            │  4. Validate: sms version < 1400 chars               │
            │  5. Store in briefings table                          │
            │                                                       │
            │  If synthesis fails: retry once. If still fails,      │
            │  generate a template-based fallback briefing from     │
            │  structured data (no LLM).                            │
            └──────────────────────────┬──────────────────────────┘
                                       │
5:15 AM     ┌──────────────────────────┴──────────────────────────┐
            │  STEP 6: DELIVER                                     │
            │                                                       │
            │  1. Retrieve today's briefing from briefings table   │
            │  2. Format SMS (split into segments if needed)        │
            │  3. Send via Twilio                                   │
            │  4. Record delivery_sid and delivery_status           │
            │  5. If Twilio fails: retry once after 60s             │
            │  6. If still fails: log error, try email fallback     │
            │                                                       │
            │  Pipeline complete. Log total run time and status.    │
            └─────────────────────────────────────────────────────┘
```

### Timing Summary

| Step | Start | Duration | Failure Impact |
|------|-------|----------|----------------|
| 1. Collect environmental data | 4:00 AM | ~5 min | Briefing still works with stale data |
| 2. Scrape fishing reports | 4:10 AM | ~5 min | Briefing uses last successful reports |
| 3. LLM extraction | 4:15 AM | 15-40 min | Falls back to sync API at 4:50 AM |
| 4. Assemble context | 5:00 AM | ~1 min | Cannot fail (pure DB queries) |
| 5. LLM synthesis | 5:05 AM | 5-15 min | Falls back to template briefing |
| 6. Deliver SMS | 5:15 AM | ~1 min | Retry once, then email fallback |

**Total pipeline time**: 45-90 minutes.
**Hard deadline**: SMS must be sent by 6:00 AM MT.

### Error Handling at Each Step

| Step | Error | Response |
|------|-------|----------|
| Any collector fails | Log error, continue with remaining collectors | Briefing notes which data sources are unavailable |
| All collectors fail | Send alert SMS: "Pipeline data collection failed" | No briefing generated |
| Scraper gets blocked (403/429) | Log, skip source, use cached data | Note in briefing that report is stale |
| Batch API timeout | Switch to synchronous Haiku calls | Costs 2x but briefing still goes out |
| Anthropic API fully down | Generate template briefing from structured data | Less useful but still delivers conditions |
| Twilio send failure | Retry once after 60s | If still fails, log and send via email if configured |
| GitHub Actions runner issue | Pipeline doesn't start | Manual re-run via GitHub UI. Add monitoring to detect missed runs. |

### Data Source Downtime Handling

If a data source is down:
1. The collector logs the failure to `pipeline_runs`.
2. The synthesis step sees which data was collected today vs. what's stale.
3. The synthesis prompt includes a `data_quality_notes` field where the LLM notes any gaps.
4. Example: "Note: USGS water data unavailable today. Flow conditions are from yesterday."

---

## 10. Testing Strategy

### 10.1 Unit Tests

| Module | What to Test | How |
|--------|-------------|-----|
| `db/queries.py` | All query functions with edge cases | In-memory SQLite, seed test data |
| `utils/geo.py` | Haversine distance, bounding box | Known distance pairs |
| `utils/hashing.py` | Consistent hashing, dedup logic | Deterministic inputs |
| `delivery/formatter.py` | SMS splitting, character limits, truncation | Known input strings |
| `llm/prompts.py` | Prompt template rendering | Check variables are substituted |
| `collectors/hatch_calendar.py` | Matching logic (month + temp range) | Fixture data |

### 10.2 Integration Tests (API Collectors)

Use the `responses` library to mock HTTP responses with recorded API payloads.

| Test | Strategy |
|------|----------|
| USGS Water Services | Record a real JSON response, replay in tests. Verify parsing of nested `timeSeries` structure. Test empty response, missing parameters, and partial data. |
| USBR Hydromet | Record response for BOYR. Test parsing. Test sentinel value handling (-999). Test HTML error response. |
| NWS Weather | Record both `/points` and `/forecast` responses. Test two-step flow. Test empty periods array. |
| Open-Meteo | Record response with hourly pressure data. Test pressure trend calculation. |
| USNO Moon | Record response. Test solunar period calculation from transit times. |
| Wyoming scraper | Save sample WGFD HTML pages as fixtures. Test article URL extraction. Test content hash dedup. |
| Idaho scraper | Save sample IDFG API response and steelhead report HTML. Test JSON parsing and HTML extraction. |

**Test fixture management**: Store recorded API responses in `tests/fixtures/` as JSON/HTML files.

### 10.3 LLM Output Validation

| Test | Strategy |
|------|----------|
| Extraction output schema | Validate JSON structure matches expected schema (all required fields present, correct types). Use `jsonschema` library. |
| Extraction accuracy | Create 5-10 hand-labeled test reports with expected extraction output. Run extraction and compare key fields (location, species, rating). Accept if >80% of fields match. |
| Synthesis output schema | Validate JSON structure (sms, full, top_spots fields present). |
| Synthesis SMS length | Assert `len(sms) <= 1400`. |
| Synthesis content quality | Manual review during Phase 1 (Brian reads every briefing). Track "useful" vs "not useful" over 2 weeks. |

**Note**: LLM tests should be tagged `@pytest.mark.llm` and excluded from CI by default (they cost money and are non-deterministic). Run manually during development.

### 10.4 SMS Delivery Testing

| Test | Strategy |
|------|----------|
| Twilio integration | Use Twilio test credentials (no real SMS sent). Verify API call structure. |
| Message formatting | Unit test that briefing text is split correctly into SMS segments. |
| Delivery status tracking | Mock Twilio response, verify status is recorded in DB. |
| End-to-end delivery | Manual test: send real SMS to Brian's phone. Verify receipt. |

### 10.5 Pipeline Integration Test

One end-to-end test that:
1. Seeds an in-memory SQLite database
2. Mocks all HTTP calls with fixtures
3. Mocks Anthropic API with a canned extraction/synthesis response
4. Mocks Twilio with test credentials
5. Runs the full pipeline from `main.py`
6. Asserts: raw_reports inserted, structured_reports created, briefing generated, delivery attempted

### Test Coverage Target

- **80%+ line coverage** on all modules except `llm/` (LLM tests are expensive/non-deterministic).
- **100% coverage** on `db/`, `utils/`, `delivery/formatter.py`.
- Run `pytest --cov` in CI on every push.

---

## 11. Deployment & Operations

### 11.1 GitHub Actions Workflow

```yaml
# .github/workflows/daily-pipeline.yml
name: Daily Fishing Briefing

on:
  schedule:
    # 4:00 AM Mountain Time (10:00 UTC during MDT, 11:00 UTC during MST)
    - cron: '0 11 * * *'  # 11:00 UTC = 4:00 AM MST (adjust for DST manually or use a timezone-aware approach)
  workflow_dispatch:  # Manual trigger for testing

jobs:
  briefing:
    runs-on: ubuntu-latest
    timeout-minutes: 120  # Hard timeout: 2 hours

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Set up Python
        run: uv python install 3.12

      - name: Install dependencies
        run: uv sync

      - name: Download database artifact
        uses: actions/download-artifact@v4
        with:
          name: fishing-copilot-db
          path: data/
        continue-on-error: true  # First run won't have an artifact

      - name: Initialize database (if new)
        run: uv run python scripts/seed_db.py

      - name: Run pipeline
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          TWILIO_ACCOUNT_SID: ${{ secrets.TWILIO_ACCOUNT_SID }}
          TWILIO_AUTH_TOKEN: ${{ secrets.TWILIO_AUTH_TOKEN }}
          TWILIO_FROM_NUMBER: ${{ secrets.TWILIO_FROM_NUMBER }}
          BRIAN_PHONE_NUMBER: ${{ secrets.BRIAN_PHONE_NUMBER }}
        run: uv run python -m fishing_copilot.main

      - name: Upload database artifact
        uses: actions/upload-artifact@v4
        with:
          name: fishing-copilot-db
          path: data/fishing_copilot.db
          retention-days: 90
        if: always()  # Upload even if pipeline fails (preserve data)

      - name: Alert on failure
        if: failure()
        env:
          TWILIO_ACCOUNT_SID: ${{ secrets.TWILIO_ACCOUNT_SID }}
          TWILIO_AUTH_TOKEN: ${{ secrets.TWILIO_AUTH_TOKEN }}
          TWILIO_FROM_NUMBER: ${{ secrets.TWILIO_FROM_NUMBER }}
          BRIAN_PHONE_NUMBER: ${{ secrets.BRIAN_PHONE_NUMBER }}
        run: uv run python -c "
          from twilio.rest import Client;
          c = Client();
          c.messages.create(
            to='$BRIAN_PHONE_NUMBER',
            from_='$TWILIO_FROM_NUMBER',
            body='Fishing Copilot pipeline FAILED. Check: github.com/brian/fishing-copilot/actions'
          )"
```

**Note on database persistence**: GitHub Actions runners are ephemeral. The SQLite database is uploaded as an artifact after each run and downloaded at the start of the next run. This gives 90 days of data retention. For Phase 2+, migrate to Turso to eliminate this constraint.

### 11.2 Secrets Management

| Secret | Where Stored | Notes |
|--------|-------------|-------|
| `ANTHROPIC_API_KEY` | GitHub Actions Secrets | Claude API key |
| `TWILIO_ACCOUNT_SID` | GitHub Actions Secrets | Twilio account |
| `TWILIO_AUTH_TOKEN` | GitHub Actions Secrets | Twilio auth |
| `TWILIO_FROM_NUMBER` | GitHub Actions Secrets | Twilio phone number (E.164) |
| `BRIAN_PHONE_NUMBER` | GitHub Actions Secrets | Delivery target (E.164) |

**Local development**: Use a `.env` file (gitignored) loaded via `python-dotenv`. Same variable names as GitHub Secrets.

### 11.3 Monitoring and Alerting

| What | How | Alert |
|------|-----|-------|
| Pipeline didn't run | Check `pipeline_runs` table for today's date. If no entry by 7:00 AM, something is wrong. | SMS: "No pipeline run detected for {date}" |
| Pipeline failed | GitHub Actions failure notification | SMS via failure step in workflow |
| Data source down | `pipeline_runs.status = 'failed'` for specific step | Included in briefing's `data_quality_notes` |
| Scraper broken (3+ days) | Count consecutive failures per source in `pipeline_runs` | SMS: "Wyoming scraper has failed 3 days in a row" |
| LLM cost spike | Track `briefings.cost_usd`. Alert if daily cost > $1.00 | SMS alert |
| SMS delivery failed | Check `briefings.delivery_status` | Log only (will catch next day) |

### 11.4 Debugging Playbook

**Briefing didn't arrive**:
1. Check GitHub Actions run log. Did it run? Did it succeed?
2. Check `pipeline_runs` table for today — which step failed?
3. Check `briefings` table — was a briefing generated?
4. Check Twilio dashboard — was the SMS sent? What was the status?

**Briefing was low quality**:
1. Check `structured_reports` for today — which reports were available?
2. Check `raw_reports.is_processed` — were all reports processed?
3. Check `water_conditions` and `weather_data` — was environmental data fresh?
4. Review the extraction output for specific reports — did the LLM extract correctly?
5. Consider: Is the source data itself stale? (WY forecasts are seasonal.)

**Scraper broke**:
1. Check `pipeline_runs` for the scraper step — what's the error message?
2. Manually visit the source URL — has the site changed?
3. If HTML structure changed: Update selectors OR (preferred) let the LLM extraction handle it.
4. If site is blocking: Check for rate limiting (429), add delays, or rotate User-Agent.

**Pipeline is slow**:
1. Check `pipeline_runs` timestamps per step — which step is slow?
2. Batch API taking too long? Consider the synchronous fallback for time-critical reports.
3. Too many scraper requests? Add more aggressive caching.

---

## 12. Task Breakdown

### Implementation Tasks (Build Order)

Tasks are numbered sequentially. Dependencies are noted. Estimated times assume focused solo development.

---

#### Foundation (Week 1)

| # | Task | Depends On | Est. Time | Definition of Done |
|---|------|-----------|-----------|-------------------|
| 1 | **Project setup**: Initialize Python project with `uv`, create directory structure, configure ruff, pytest. Add `.env.example`, `.gitignore`. | — | 2 hours | `uv run pytest` passes with a dummy test. `uv run ruff check .` passes. |
| 2 | **SQLite schema + connection**: Implement `db/connection.py`, `db/schema.py`. Create all tables from the schema above. | 1 | 3 hours | `seed_db.py` creates the database with all tables. Verified with `sqlite3` CLI. |
| 3 | **Database query functions**: Implement `db/queries.py` with all CRUD operations needed by collectors, scrapers, and pipeline. | 2 | 4 hours | Unit tests pass for all query functions using in-memory SQLite. |
| 4 | **Configuration module**: Implement `config.py` — load env vars, validate required secrets, define constants (API URLs, site codes). | 1 | 2 hours | Config loads from `.env` in dev, from environment in CI. Missing required vars raise clear errors. |
| 5 | **Logging + utilities**: Implement `utils/logging.py`, `utils/hashing.py`, `utils/geo.py`. | 1 | 2 hours | Unit tests pass. Logging outputs structured JSON to stdout. |
| 6 | **Seed location data**: Create `data/seed_locations.json` with 30-50 key fishing waters (WY + ID) including coordinates, USGS site IDs, USBR codes. Run `seed_db.py` to populate. | 2 | 4 hours | `locations` table populated with verified coordinates and site IDs. |

---

#### Data Collectors (Week 2)

| # | Task | Depends On | Est. Time | Definition of Done |
|---|------|-----------|-----------|-------------------|
| 7 | **Base collector class**: Implement `collectors/base.py` with retry logic, timeout handling, standard error reporting. | 4, 5 | 2 hours | Base class tested with a mock HTTP endpoint. |
| 8 | **USGS Water Services collector**: Implement `collectors/usgs_water.py`. Fetch streamflow, water temp, gage height for all configured sites. | 6, 7 | 4 hours | Integration test with mocked responses passes. Real API call returns valid data for WY sites. |
| 9 | **USBR Reservoir collector**: Implement `collectors/usbr_reservoir.py`. Fetch storage, elevation, discharge for 9 WY reservoirs. | 6, 7 | 3 hours | Integration test passes. Handles sentinel values and HTML error responses. |
| 10 | **NWS Weather collector**: Implement `collectors/nws_weather.py`. Two-step: resolve grid, fetch forecast. Cache grid coordinates. | 6, 7 | 4 hours | Integration test passes. Grid caching works. Handles NWS outages. |
| 11 | **Open-Meteo collector**: Implement `collectors/open_meteo.py`. Fetch hourly pressure + daily summary. Calculate pressure trend. | 6, 7 | 3 hours | Integration test passes. Pressure trend calculation verified. |
| 12 | **USNO Moon/Solunar collector**: Implement `collectors/usno_moon.py`. Fetch moon data, calculate solunar periods. | 7 | 3 hours | Solunar period calculation matches known-good values for test dates. |
| 13 | **Hatch calendar loader**: Create `data/hatch_calendar.json` and `collectors/hatch_calendar.py`. Seed data for WY + ID hatches. | 2 | 3 hours | Calendar loaded. Matching function returns correct hatches for given month + water temp. |

---

#### Scrapers (Weeks 2-3)

| # | Task | Depends On | Est. Time | Definition of Done |
|---|------|-----------|-----------|-------------------|
| 14 | **Base scraper class**: Implement `scrapers/base.py` with fetch, hash check, store raw, and change detection. | 3, 5, 7 | 2 hours | Base class tested with mock pages. Content hashing dedup works. |
| 15 | **Wyoming scraper**: Implement `scrapers/wyoming.py`. Scrape WGFD fishing news page and individual articles. Handle GovDelivery if accessible. | 14 | 12 hours (3-4 days) | Scraper fetches real WGFD pages. Raw content stored. Handles missing articles gracefully. Content hash dedup prevents reprocessing. |
| 16 | **Idaho scraper**: Implement `scrapers/idaho.py`. Call IDFG Fishing Planner API. Scrape steelhead reports. | 14 | 8 hours (2-3 days) | API returns water list. Steelhead reports scraped. Integration tests with fixtures pass. |

---

#### LLM Pipeline (Week 3)

| # | Task | Depends On | Est. Time | Definition of Done |
|---|------|-----------|-----------|-------------------|
| 17 | **Anthropic client wrapper**: Implement `llm/client.py`. Batch API submission, polling, result retrieval. Synchronous fallback. | 4 | 4 hours | Batch submission and retrieval works with Anthropic API. Synchronous fallback works. Retry logic handles transient errors. |
| 18 | **Prompt templates**: Implement `llm/prompts.py`. Extraction prompt and synthesis prompt as templates. | — | 3 hours | Prompts render correctly with test data. Variables are properly substituted. |
| 19 | **LLM extraction pipeline**: Implement `llm/extraction.py`. Feed raw reports to Haiku, parse structured JSON output, validate schema, store results. | 3, 17, 18 | 6 hours | Given sample raw reports, extraction returns valid structured JSON. Schema validation catches malformed output. |
| 20 | **LLM synthesis pipeline**: Implement `llm/synthesis.py`. Assemble all data, generate briefing, parse SMS + full versions. | 3, 17, 18 | 6 hours | Given assembled context, synthesis returns valid JSON with SMS (<1400 chars) and full briefing. |

---

#### Delivery (Week 4)

| # | Task | Depends On | Est. Time | Definition of Done |
|---|------|-----------|-----------|-------------------|
| 21 | **SMS formatter**: Implement `delivery/formatter.py`. Format briefing for SMS delivery, split into segments, handle truncation. | — | 3 hours | Formatter produces SMS segments under character limits. Truncation preserves the most important content (top spots first). |
| 22 | **Twilio SMS delivery**: Implement `delivery/sms.py`. Send SMS, track SID and delivery status. | 4, 21 | 3 hours | SMS sent via Twilio test credentials. Delivery status recorded. Retry on failure works. |

---

#### Pipeline Orchestration (Week 4)

| # | Task | Depends On | Est. Time | Definition of Done |
|---|------|-----------|-----------|-------------------|
| 23 | **User preferences setup**: Implement `user_preferences` seed data for Brian (hardcoded for Phase 1). | 2, 6 | 1 hour | Brian's preferences stored: home location, radius, species, phone number. |
| 24 | **Pipeline orchestrator**: Implement `main.py`. Wire all steps together: collect -> scrape -> extract -> synthesize -> deliver. Step-level error handling. Pipeline run logging. | 8-16, 19-22, 23 | 6 hours | Full pipeline executes end-to-end with mocked APIs. Each step's success/failure is logged. Pipeline continues on partial failures. |
| 25 | **Fallback briefing generator**: Template-based fallback when LLM is unavailable. Uses structured data directly. | 3, 21 | 3 hours | Fallback produces a readable (if basic) briefing from water conditions + weather data alone. |
| 26 | **GitHub Actions workflow**: Create `.github/workflows/daily-pipeline.yml`. Configure cron schedule, secrets, artifact persistence, failure alerting. | 24 | 3 hours | Manual `workflow_dispatch` trigger runs the pipeline successfully. Artifact upload/download cycle works. Failure alert SMS is sent on error. |

---

#### Testing & Polish (Week 4-5)

| # | Task | Depends On | Est. Time | Definition of Done |
|---|------|-----------|-----------|-------------------|
| 27 | **Integration tests for all collectors**: Mocked HTTP responses, edge cases, error scenarios. | 8-13 | 6 hours | >80% coverage on collectors. All edge cases covered (empty responses, timeouts, malformed data). |
| 28 | **Integration tests for scrapers**: HTML fixture-based tests. Change detection tests. | 15, 16 | 4 hours | >80% coverage on scrapers. Selector failures trigger alerts. |
| 29 | **End-to-end pipeline test**: Full pipeline with all external calls mocked. | 24 | 4 hours | E2E test runs full pipeline in <10 seconds. Asserts data flows through all stages. |
| 30 | **Live testing**: Run real pipeline daily for 1 week. Evaluate briefing quality. Adjust prompts. | 26 | 5 days | 7 consecutive days of briefings received. 5+ rated as "useful" by Brian. Known issues documented. |
| 31 | **Prompt tuning**: Based on live testing feedback, refine extraction and synthesis prompts. | 30 | 4 hours | Improved prompts deployed. Before/after quality comparison documented. |

---

### Task Dependency Graph

```
FOUNDATION          COLLECTORS         SCRAPERS          LLM             DELIVERY         PIPELINE
─────────          ──────────         ────────          ───             ────────         ────────
1 (setup)
├── 2 (schema)
│   ├── 3 (queries)─────────────────── 14 (base scraper)
│   ├── 6 (seed)──── 8 (usgs)         ├── 15 (wyoming)
│   │                9 (usbr)         └── 16 (idaho)
│   └── 13 (hatch)   10 (nws)
│                    11 (meteo)
├── 4 (config)────── 7 (base coll.)── 12 (usno)                        22 (twilio)
│                                     17 (anthropic)────── 19 (extract)
│                                     18 (prompts)──────── 20 (synth)
├── 5 (utils)                                              21 (format)──┘
│                                                                       23 (prefs)
│                                                                       ├── 24 (orchestrator)
│                                                                       │   ├── 25 (fallback)
│                                                                       │   └── 26 (GH Actions)
│                                                                       │       └── 30 (live test)
│                                                                       │           └── 31 (tuning)
│                                                                       ├── 27 (coll tests)
│                                                                       ├── 28 (scraper tests)
│                                                                       └── 29 (e2e test)
```

### Time Summary

| Phase | Tasks | Estimated Time |
|-------|-------|---------------|
| Foundation | 1-6 | 2.5 days |
| Data Collectors | 7-13 | 3 days |
| Scrapers | 14-16 | 5 days |
| LLM Pipeline | 17-20 | 3 days |
| Delivery | 21-22 | 1 day |
| Pipeline Orchestration | 23-26 | 2 days |
| Testing & Polish | 27-31 | 4 days + 5 days live |
| **Total Phase 1** | | **~20.5 dev days + 5 days live testing** |

At ~4-5 productive hours per day for a solo dev with a day job, this is **~4-5 calendar weeks** to a working Phase 1.

---

## Appendix A: Key File Paths for Reference

| File | Purpose |
|------|---------|
| `src/fishing_copilot/main.py` | Pipeline entry point |
| `src/fishing_copilot/config.py` | All configuration |
| `src/fishing_copilot/llm/prompts.py` | All LLM prompts (tune these) |
| `data/seed_locations.json` | Master list of fishing waters |
| `data/hatch_calendar.json` | Hatch timing reference |
| `.github/workflows/daily-pipeline.yml` | Cron schedule and deployment |
| `.env` | Local development secrets (gitignored) |

## Appendix B: Critical First-Week Milestones

1. **Day 1**: Project setup complete. SQLite database created with schema. Can run `uv run pytest`.
2. **Day 3**: USGS + NWS collectors working. Can query real water conditions and weather for WY sites.
3. **Day 5**: Wyoming scraper fetches real fishing news pages and stores raw HTML.
4. **Day 8**: LLM extraction turns raw WGFD HTML into structured JSON.
5. **Day 10**: Full pipeline runs end-to-end (even with incomplete data).
6. **Day 12**: First real SMS briefing received on Brian's phone.

If Day 12 produces a briefing Brian would actually use to decide where to fish, Phase 1 is on track.
