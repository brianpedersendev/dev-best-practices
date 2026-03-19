# Fishing Copilot

## What This Is
A cron-triggered Python pipeline that scrapes state fish & game reports, pulls water/weather data from free public APIs, synthesizes everything through Claude Haiku into a daily fishing briefing, and delivers it via SMS. AI is the core product — without the LLM, this is a useless pile of scraped HTML.

## Tech Stack
- **Language:** Python 3.12+ (uv for package management)
- **LLM:** Claude Haiku 4.5 via Batch API (extraction + synthesis)
- **Database:** SQLite (WAL mode, foreign keys enabled)
- **SMS:** Twilio
- **Cron:** GitHub Actions scheduled workflow (4:00 AM MT)
- **Dashboard (Phase 2):** Flask + htmx on Cloudflare Pages
- **Testing:** pytest + responses (HTTP mocking)
- **Linting/Formatting:** ruff

## Project Structure
```
src/fishing_copilot/
├── main.py              # Pipeline orchestrator
├── config.py            # Env vars + constants
├── db/                  # SQLite connection, schema, queries
├── collectors/          # API clients (USGS, USBR, NWS, Open-Meteo, USNO)
├── scrapers/            # State fishing report scrapers (WY, ID)
├── llm/                 # Anthropic client, extraction, synthesis, prompts
├── delivery/            # Twilio SMS + formatting
└── utils/               # Geo, hashing, logging helpers
```

## Coding Standards
- Use immutable patterns: return new objects, never mutate arguments
- Use `dataclass(frozen=True)` or `NamedTuple` for data structures
- Use parameterized SQL queries exclusively — never f-string SQL
- Keep functions under 50 lines, files under 400 lines
- Handle errors explicitly at every level — never silently swallow exceptions
- Use `logging` with structured JSON output — no print statements
- Store all prompt templates in `llm/prompts.py` as constants
- Use content hashing (SHA-256) to dedup raw reports before LLM processing
- Validate all external API responses before storing — check status codes, content types, sentinel values
- Use type hints on all function signatures

## Testing
- Framework: pytest with responses library for HTTP mocking
- Naming: `test_{module}/test_{function}.py`
- Coverage target: 80%+ on all modules
- Write tests FIRST, then implementation (TDD)
- Mock all HTTP calls in unit tests — use saved fixtures for scraper tests
- Integration tests hit real APIs (tagged `@pytest.mark.integration`)
- LLM output validation: assert JSON schema conformance on extraction results

## Workflow
1. Plan in Plan Mode before implementing any feature
2. Write failing tests that define the behavior
3. Implement minimum code to pass tests
4. Run full test suite + ruff check
5. Refactor while tests stay green

## Context Management
- Use /clear between unrelated tasks; /compact at 60% context capacity
- Split sessions by phase: planning → implementation → testing
- Store decisions in docs/ARCHITECTURE.md
- Track work in docs/TASKS.md

## Key Patterns
- **Two-pass LLM pipeline:** Raw HTML → structured JSON (extraction), then structured data → briefing text (synthesis). Never skip extraction — structured data is cached and reusable.
- **LLM-as-resilience-layer:** When scraping breaks, feed raw HTML directly to Haiku for extraction. The LLM understands semantic content regardless of markup changes.
- **Process once, deliver to many:** LLM processes reports once. Delivery fans out to N users. LLM cost does not scale with user count.
- **Graceful degradation:** If any data source fails, pipeline continues with available data. Briefing notes which sources were unavailable.

## Avoid
- Use ruff instead of black/flake8/isort (ruff replaces all three)
- Use uv instead of pip/venv/pip-tools
- Use SQLite JSON functions instead of ORM for JSON array columns
- Use Claude Batch API instead of synchronous calls (50% cost savings)
- Use content hashing instead of date-based dedup (handles mid-day report updates)
