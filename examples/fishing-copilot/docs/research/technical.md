# Technical Feasibility: Fishing Copilot App

## Research Date: 2026-03-19

---

## Free Public APIs — Confirmed Working

### Water Conditions

#### USGS Water Services (PRIMARY — verified working)
- **URL**: `https://waterservices.usgs.gov/nwis/iv/`
- **Docs**: https://waterservices.usgs.gov/docs/instantaneous-values/instantaneous-values-details/
- **Auth**: None required
- **Format**: JSON (`format=json`) or WaterML
- **Rate Limits**: No hard limit. Cache-Control returns `max-age=900` (15 min).

**Geographic query methods:**
- By state: `stateCd=WY` (or MT, CO, ID)
- By HUC code: `huc=10080001` (Wind/Bighorn basin)
- By bounding box: `bBox=-111,43,-108,45` (NW Wyoming)
- By site ID: `sites=06186500` (Yellowstone at Lake Outlet)

**Parameters relevant to fishing (verified active site counts in WY):**

| Code | Parameter | WY Sites |
|------|-----------|----------|
| 00060 | Streamflow (cfs) | 105 |
| 00065 | Gage height (ft) | 107 |
| 00010 | Water temperature (C) | 36 |
| 00095 | Specific conductance | 11 |
| 00300 | Dissolved oxygen (mg/L) | 5 |
| 00400 | pH | 5 |
| 63680 | Turbidity (NTU) | 2 |

**Surrounding state coverage**: MT=225, CO=368, ID=223 streamflow sites.

**Example call:**
```
https://waterservices.usgs.gov/nwis/iv/?format=json&stateCd=WY&parameterCd=00060,00010,00065&siteType=ST&siteStatus=active
```

#### Bureau of Reclamation — GP Region Hydromet (verified working)
- **URL**: `https://www.usbr.gov/gp-bin/arcread.pl`
- **Auth**: None
- **Format**: JSON (`json=1` parameter)

**Verified Wyoming reservoir site codes:**

| Code | Reservoir |
|------|-----------|
| BOYR | Boysen |
| BFAL | Buffalo Bill |
| PATH | Pathfinder |
| SEMI | Seminoe |
| ALCK | Alcova |
| GLDO | Glendo |
| KEHO | Keyhole |
| BIGH | Bighorn |
| GURC | Guernsey |

**Available parameters**: af (storage acre-feet), el (elevation), fb (forebay elevation), in (inflow cfs), qd (total discharge cfs), se (spillway releases)

**Note**: Flaming Gorge (FLGR) returns bad data on GP endpoint. Use USGS site `09235000` (Green River below Flaming Gorge Dam) instead.

#### Colorado DWR (verified working, excellent API)
- **URL**: `https://dwr.state.co.us/rest/get/api/v2/`
- **Docs**: `https://dwr.state.co.us/rest/get/help`
- **Auth**: None
- **Format**: Clean paginated JSON
- **Key endpoints**: `surfacewater/surfacewaterstations`, `surfacewater/surfacewatertsday`, `climatedata/climatestations`

---

### Weather

#### NWS API (PRIMARY — verified working)
- **URL**: `https://api.weather.gov/`
- **Auth**: None required. Recommends `User-Agent` header with app name + contact email.
- **Format**: GeoJSON/JSON
- **Rate Limits**: No hard throttle documented.

**Key endpoints:**

| Endpoint | Returns |
|----------|---------|
| `/points/{lat},{lon}` | Grid coordinates, links to forecast/stations |
| `/gridpoints/{office}/{X},{Y}/forecast` | 7-day forecast (14 periods) |
| `/gridpoints/{office}/{X},{Y}/forecast/hourly` | 156 hourly periods |
| `/gridpoints/{office}/{X},{Y}` | Raw gridded data (60+ parameters) |
| `/stations/{id}/observations/latest` | Latest observation (includes barometric pressure) |
| `/alerts/active?area=WY` | Active weather alerts |

#### Open-Meteo (BEST for barometric pressure + historical data)
- **URL**: `https://api.open-meteo.com/v1/forecast`
- **Historical**: `https://archive-api.open-meteo.com/v1/archive`
- **Auth**: None required
- **Format**: JSON
- **Rate Limits**: 10,000 requests/day free tier (non-commercial)

**Fishing-relevant hourly parameters:** temperature_2m, relative_humidity_2m, pressure_msl, surface_pressure, windspeed_10m, winddirection_10m, windgusts_10m, cloudcover, precipitation, precipitation_probability, visibility, uv_index, rain, snowfall

**Daily parameters:** sunrise/sunset, temperature extremes, precipitation_sum, windspeed_max

---

### Moon Phase / Solunar Data

#### US Naval Observatory (USNO — verified working)
- **Moon data**: `https://aa.usno.navy.mil/api/rstt/oneday?date=2026-03-19&coords=43,-108`
- **Moon phases**: `https://aa.usno.navy.mil/api/moon/phases/date?date=2026-03-19&nump=4`
- **Auth**: None
- **Format**: JSON

**Returns**: Moon rise/set times, phase name, illumination percentage, sun rise/set, civil twilight, upper transit times (for solunar major period calculations).

**Solunar period calculation from this data:**
- Major periods: ~2 hours centered on moon overhead (upper transit) and moon underfoot
- Minor periods: ~1 hour centered on moonrise and moonset

---

### Hatch Charts / Insect Emergence Data
- **No free structured API exists.** This is a gap in public data.
- Best approach: Build a curated lookup table keyed on region + month + water temperature range.
- Water temperature from USGS (param 00010) is the strongest predictor of hatch timing.

---

## Recommended API Stack

| Data Need | Primary API | Backup |
|-----------|------------|--------|
| Stream flow & gage height | USGS IV | Colorado DWR (for CO waters) |
| Water temperature | USGS IV (param 00010, 36 WY sites) | — |
| Reservoir levels & releases | USBR GP Hydromet | USGS for Flaming Gorge area |
| Weather forecast | NWS API | Open-Meteo |
| Barometric pressure | Open-Meteo (pressure_msl hourly) | NWS station observations |
| Moon phase / solunar | USNO | Calculate from USNO data |
| Sunrise/sunset | Open-Meteo or USNO | NWS |
| Weather alerts | NWS (/alerts/active?area=WY) | — |
| Hatch timing | Custom lookup + USGS water temp | — |

**All recommended APIs are free, require no API keys, and return JSON.**

---

## Scraping / Ingestion

### Recommended Tools
- **Static HTML pages** (most state agency sites): Python `requests` + `BeautifulSoup4`
- **JS-rendered pages**: Python `Playwright` as fallback
- **Scrapy** is overkill for 4-5 sites
- **Prior art**: `nmfishingreport` on PyPI/GitHub (NM fishing report scraper with Pushover notifications)

### Resilience Strategies
1. **Hash/date-based change detection**: Store last-scraped content hash. Only re-process when content changes.
2. **Structural assertions**: Assert expected CSS selectors exist before parsing. Alert on failure.
3. **LLM-based extraction as resilience layer**: Feed raw HTML to Haiku for extraction. Remarkably resilient to redesigns since the LLM understands semantic content regardless of markup.
4. **Monitoring/alerting**: Send alert when scraper fails or returns empty content.

### Estimated Development Time
- 2-4 weeks for 4-5 state sites (2-4 days per site)
- Budget extra time for 1-2 sites that will be harder than expected

---

## LLM Costs

### Claude API Pricing

| Model | Input (per MTok) | Output (per MTok) | Batch Input | Batch Output |
|-------|------|--------|-------------|--------------|
| Haiku 4.5 | $1.00 | $5.00 | $0.50 | $2.50 |
| Sonnet 4.6 | $3.00 | $15.00 | $1.50 | $7.50 |
| Opus 4.6 | $5.00 | $25.00 | $2.50 | $12.50 |

### Model Recommendation: Haiku 4.5
Summarizing fishing reports is straightforward text comprehension. Haiku 4.5 is 90% as capable as Sonnet for this task at 1/3 the cost. Batch API cuts that in half again.

### Token Estimates
- Typical fishing report: 300-800 words (~400-1,100 input tokens)
- System prompt: ~500 tokens
- Output summary per report: ~200-400 tokens

### Daily Cost (50 reports, Haiku Batch)
- Input: ~65,000 tokens = $0.03
- Output: ~15,000 tokens = $0.04
- Synthesis pass: ~$0.003
- **Total daily: ~$0.07**
- **Total monthly: ~$2.10**

Standard (non-batch) Haiku: ~$0.14/day, ~$4.20/month.

---

## SMS Delivery

### Twilio
- Outbound SMS (US): **$0.0083/message**
- Phone number rental: **$1.15/month** (local)
- 1 SMS/day to 1 user: **~$1.40/month total**
- 100 users, 1 SMS/day each: **~$41/month** (~$0.41/user/month)

### Alternatives
- **AWS SNS**: First 100 SMS/month free, but 10DLC registration is complex
- **Telnyx/Plivo**: ~Half the cost of Twilio at scale
- **Email (Resend)**: Free tier = 3,000 emails/month — **$0/month** if users accept email instead of SMS

---

## Hosting / Infrastructure

### Cron Pipeline (daily scraping + LLM)

| Platform | Free Tier | Cost for Daily 5-10 Min Job |
|----------|-----------|----------------------------|
| **GitHub Actions** | 2,000 min/month (private) | **$0** (300 min/month) |
| **AWS Lambda** | 1M requests + 400K GB-sec/month | **$0** |
| **Vercel Cron** | Available on free plan | **$0** |

**Recommendation: GitHub Actions** — zero cost, battle-tested cron, built-in secrets management.

### Web Dashboard

| Platform | Free Tier |
|----------|-----------|
| **Cloudflare Pages** | Unlimited bandwidth, 500 builds/month |
| **Vercel** | 100GB bandwidth, 100K serverless invocations |

### Database

| Option | Free Tier | Best For |
|--------|-----------|----------|
| **SQLite file** | Free | Simplest. Fine for <1000 reports. |
| **Turso** | 9GB, 500M row reads/month | SQLite at the edge |
| **Supabase** | 500MB, 50K MAU | If you want auth + REST API |

**Recommendation**: Start with SQLite. Upgrade to Turso or Supabase when adding users.

---

## Recommended Stack

| Component | Choice | Why |
|-----------|--------|-----|
| **Scraping** | Python + requests/BeautifulSoup + Playwright fallback | Covers static + JS-rendered pages |
| **Weather/Water** | USGS + USBR + NWS + Open-Meteo | All free, comprehensive, JSON |
| **LLM** | Claude Haiku 4.5 via Batch API | Cheapest high-quality option |
| **SMS** | Twilio (or email via Resend for $0) | Simplest DX |
| **Cron/Pipeline** | GitHub Actions (scheduled workflow) | Free, reliable |
| **Dashboard** | Static site on Cloudflare Pages | Free, fast |
| **Database** | SQLite → Turso when scaling | Free, simple |

---

## Monthly Cost Estimates

### Personal Scale (1 user)

| Item | Monthly Cost |
|------|-------------|
| Claude API (Haiku Batch) | ~$2.10 |
| Twilio SMS (1 msg/day) | ~$1.40 |
| GitHub Actions | $0 |
| Cloudflare Pages | $0 |
| Weather/Water APIs | $0 |
| Database | $0 |
| **Total** | **~$3.50/month** |

With email instead of SMS: **~$2.10/month**

### Small Scale (100 users)

| Item | Monthly Cost |
|------|-------------|
| Claude API (same — process once, deliver to many) | ~$2.10 |
| Twilio SMS (3,000 msgs/month) | ~$41 |
| Everything else | $0 |
| **Total** | **~$43/month** (~$0.43/user) |

---

## Build Difficulty

| Component | Difficulty | Solo Dev Time | Maintenance |
|-----------|-----------|---------------|------------|
| Scraping 4-5 state sites | 3/5 | 2-4 weeks | Medium (sites change) |
| Weather/water API integration | 1/5 | 1-2 days | Low (stable gov APIs) |
| LLM summarization pipeline | 2/5 | 2-3 days | Low |
| SMS delivery | 1/5 | 1 day | Low |
| GitHub Actions cron | 1/5 | 1 day | Low |
| Web dashboard | 2/5 | 1-2 weeks | Low |
| **Total MVP (1 user)** | — | **3-5 weeks** | — |
| **Total with dashboard + multi-user** | — | **6-8 weeks** | — |

The scraping is the hardest part both to build and maintain. The LLM-as-resilience-layer strategy (feeding raw HTML to Haiku) significantly reduces scraping maintenance.
