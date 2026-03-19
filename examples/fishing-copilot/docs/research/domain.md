# Domain Research: Fishing Report Data Sources

## Research Date: 2026-03-19

## State Fish & Game Agency Data

### Summary Matrix

| State | Fishing Conditions Report | Stocking Data | RSS Feed | JSON/REST API | GovDelivery | ArcGIS Open Data | Best Structured Source |
|-------|--------------------------|---------------|----------|---------------|-------------|-------------------|----------------------|
| **WY** | Seasonal forecasts (HTML articles) | Web app (1985-2026) | None | None | Monthly fishing email | Yes (no fishing datasets) | GovDelivery bulletins |
| **MT** | No regular conditions report | CSV export available | None | None (AJAX internal) | General news | Yes (restricted?) | FishMT stocking CSV export |
| **CO** | Twice-monthly (HTML) | Weekly HTML table (Fridays) | None | Socrata dataset (non-tabular) | MailChimp fishing eNews | Yes (sportfish waters) | Stocking report (scrape) |
| **ID** | Weekly steelhead reports (HTML) | Web app + Fishing Planner | General press RSS | **Yes** - Fishing Planner JSON API | General news | Yes (fish distribution, access) | Fishing Planner API + ArcGIS |
| **UT** | Seasonal by region (GovDelivery) | AJAX endpoint (2002-2026) | **Yes** - wildlife news RSS | Stocking AJAX (returns HTML) | Regional fishing reports | None found | Stocking AJAX + RSS feed |

---

## Wyoming — Game & Fish Department (wgfd.wyo.gov)

### Official Fishing Report URLs
- **Fishing News page**: `https://wgfd.wyo.gov/fishing-boating/fishing-news` — aggregates news articles including seasonal fishing forecasts and condition updates. HTML articles, not structured reports.
- **Fish Stocking Report**: `https://wgfapps.wyo.gov/FishStock/FishStock` — interactive web app showing stocking records from 1985-2026, filterable by year, species (38 types), county (23 counties), and water body name. Server-rendered ASP.NET app (Telerik controls).
- **Seasonal Fishing Forecasts**: Published as magazine-style articles on the website. Regional forecasts from each of the 8 regional offices published spring/summer and fall.

### APIs or RSS Feeds
- **No RSS feed** found. Checked `/rss`, `/feed` — both 404.
- **No public API** for fishing reports or stocking data.
- **ArcGIS Open Data Portal**: `https://wyoming-wgfd.opendata.arcgis.com/` — offers geospatial datasets (boundaries, access areas, habitat) downloadable as Shapefile, GeoJSON, CSV, Excel, File GDB, etc. with ArcGIS Feature Service APIs. However, **no fishing report or fish stocking datasets** on this portal.
- **GovDelivery email**: `https://public.govdelivery.com/accounts/WYWGFD/subscriber/new` — subscribers receive monthly fishing updates and weekly news. Bulletins are HTML at `content.govdelivery.com/accounts/WYWGFD/bulletins/{id}`.

### Report Format & Frequency
- Fishing forecasts: **HTML articles**, narrative format organized by region, seasonal (2x/year).
- Fish stocking report: **HTML web application** with dynamic table output. No export/download option visible.
- Monthly fishing email updates via GovDelivery.
- No explicit prohibition on scraping in robots.txt or published policies.

---

## Montana — Fish, Wildlife & Parks (fwp.mt.gov)

### Official Fishing Report URLs
- **FishMT platform**: `https://myfwp.mt.gov/fishMT/explore` — searchable database of Montana waterbodies with species data, fishing access sites, and survey information.
- **Fish Survey & Inventory Reports**: `https://myfwp.mt.gov/fishMT/reports/surveyreport` — searchable by waterbody, species, year, and keyword. Includes raw data download.
- **Fish Stocking Data**: `https://myfwp.mt.gov/fishMT/plants/plantreport` — searchable stocking records. **Has "Export to CSV" button.** Backend AJAX endpoint: `/fishMT/plants/plantsearchgrid`.

### APIs or RSS Feeds
- **No RSS feed** or documented public API.
- **ArcGIS Hub**: `https://gis-mtfwp.hub.arcgis.com/` — includes "Fishing Access Site Locations" dataset. Some data may be restricted (401 errors observed).

### Report Format & Frequency
- Montana does NOT publish regular "fishing condition" reports. Instead provides survey data and stocking data through FishMT database.
- Stocking data: Interactive HTML table with **CSV export**.
- Survey data: Interactive HTML table with raw data download.
- Updated as biologists complete surveys/stocking events — described as "real time."

---

## Colorado — Parks & Wildlife (cpw.state.co.us)

### Official Fishing Report URLs
- **Fishing Conditions Reports**: `https://cpw.state.co.us/thingstodo/Pages/FishingReports.aspx` — **twice-monthly** fishing condition reports. **NOTE: CPW's "Fishing Reporter" position was recently vacant, so reports may be intermittent.**
- **Fish Stocking Report**: `https://cpw.state.co.us/activities/fishing/fishing-awards-and-records/fish-stocking-report` — HTML table listing recently stocked waters. **Updated every Friday during fishing season.**
- **Fishery Surveys**: `https://cpw.state.co.us/activities/fishing/fishery-surveys` — survey summaries for 127+ waters.
- **Colorado Fishing Atlas**: Interactive map tool.

### APIs or RSS Feeds
- **No RSS feed** found.
- **Colorado Information Marketplace (Socrata/SODA API)**: `https://data.colorado.gov/` — has a "Fishing in Colorado State Parks" dataset but it's **non-tabular** and cannot be queried via standard SODA row API.
- **CPW Spatial Data Hub (ArcGIS)**: `https://geodata-cpw.hub.arcgis.com/` — includes "CPW Aquatic Sportfish Management Waters" with ArcGIS Feature Service REST API access.

### Report Format & Frequency
- Fishing condition reports: **HTML pages**, narrative format, twice-monthly.
- Stocking report: **HTML table**, weekly (Fridays).

---

## Idaho — Fish and Game (idfg.idaho.gov)

### Official Fishing Report URLs
- **Fishing Reports**: Published as date-stamped articles. Regular **Upper Salmon River Steelhead Fishing Reports** published weekly during steelhead season with detailed data.
- **Idaho Fishing Planner**: `https://idfg.idaho.gov/ifwis/fishingplanner/` — database of 12,000+ waters with species data, fishing rules, facilities, and stocking history (100,000+ events since 1967).
- **Fish Stocking Schedules**: `https://idfg.idaho.gov/fish/stocking` — regional schedules (7 regions).
- **Data, Maps, and Apps hub**: `https://idfg.idaho.gov/data`

### APIs or RSS Feeds — BEST OF ALL 5 STATES
- **RSS Feed (confirmed)**: General news/press releases RSS feed. Fishing reports appear in the general stream.
- **Fishing Planner API (confirmed working)**: `https://idfg.idaho.gov/ifwis/fishingplanner/api/2.0/autocomplete/` — returns **JSON array** of all Idaho water features (12,000+) with properties: `k` (numeric ID), `v` (water name), `a` (region/drainage metadata).
- **ArcGIS Open Data Portal**: `https://data-idfggis.opendata.arcgis.com/` — datasets include "Generalized Fish Distribution," "IDFG Fishing and Boating Access Sites," "Fishing Planner Map Center." Data downloadable as CSV, KML, SHP, JSON.

### Report Format & Frequency
- Steelhead fishing reports: **HTML articles** with structured data (catch rates, effort hours, water conditions). Published **weekly** during season.
- Fishing Planner: **Web application** with underlying JSON API.
- IDFG is the most data-friendly of all 5 states.

---

## Utah — Division of Wildlife Resources (wildlife.utah.gov)

### Official Fishing Report URLs
- **Regional Fishing Reports/Forecasts**: Published via GovDelivery bulletins. Organized by region (Southern, Northern, Southeastern, Northeastern, Central). **Detailed** — covering 40+ specific waters with species, techniques, water conditions, stocking info, and regulations per water body.
- **Fish Stocking Report**: `https://dwrapps.utah.gov/fishstocking/Fish` — interactive table with historical data back to 2002.

### APIs or RSS Feeds
- **RSS Feed (confirmed working)**: `https://wildlife.utah.gov/news/utah-wildlife-news?format=feed&type=rss` — standard RSS 2.0 XML feed. General DWR news, fishing-related articles appear in the feed.
- **Fish Stocking AJAX endpoint (confirmed working)**: `https://dwrapps.utah.gov/fishstocking/FishAjax?y={year}&sort={column}&sortorder={ASC|DESC}&sortspecific={ALL|value}&whichSpecific={label|watername|county|species}` — returns HTML table rows, queryable with year/sort/filter parameters.

### Report Format & Frequency
- Regional fishing reports: **HTML bulletins** via GovDelivery, narrative but structured by water body. Highly detailed.
- Fish stocking report: **HTML table** with AJAX backend. Updated as stocking events occur.

---

## Federal & Cross-State Aggregators

- **USGS Western Fisheries Research Center**: Research-level data, not real-time fishing reports.
- **NOAA Recreational Fishing Data (MRIP)**: Marine only, not relevant for freshwater.
- **MARIS (Multi-State Aquatic Resources)**: Upper Midwest only, does not cover target states.
- **No multi-state aggregator with API exists** for these 5 states' fishing reports.

---

## Key Takeaways

1. **Idaho is the most data-friendly**: Working JSON API, ArcGIS open data, RSS feed.
2. **Montana has the best exportable data**: FishMT platform offers CSV export of stocking records.
3. **Utah has a working RSS feed and queryable AJAX endpoint**.
4. **Colorado's Socrata dataset is non-tabular** — stocking data must be scraped.
5. **Wyoming has the least accessible data**: No API, no RSS, no CSV export.
6. **All 5 states use GovDelivery** for email distribution, but GovDelivery does not offer public RSS feeds.
7. **Terms of service are generally permissive**: No explicit prohibitions on automated access. Responsible rate-limiting and attribution are prudent.
