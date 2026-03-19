# Tasks

## In Progress
- [ ] Phase 1 Foundation — project setup, SQLite schema, config, seed locations

## Up Next
- [ ] USGS Water Services collector
- [ ] USBR Reservoir collector
- [ ] NWS Weather collector
- [ ] Open-Meteo barometric pressure collector
- [ ] USNO Moon/Solunar collector
- [ ] Hatch calendar seed data (WY + ID)
- [ ] Wyoming fishing report scraper (WGFD + GovDelivery)
- [ ] Idaho fishing report scraper (IDFG API + steelhead reports)
- [ ] LLM extraction pipeline (raw HTML → structured JSON)
- [ ] LLM synthesis pipeline (structured data → daily briefing)
- [ ] Twilio SMS delivery module
- [ ] Pipeline orchestrator (main.py)
- [ ] GitHub Actions cron workflow
- [ ] Integration tests for all collectors
- [ ] End-to-end pipeline test
- [ ] Live testing (7 days of real briefings)
- [ ] Prompt tuning based on live feedback

## Done
- [x] Project research — competitive landscape, data source analysis — 2026-03-19
- [x] Implementation plan — full architecture, task breakdown, API specs — 2026-03-19
- [x] AI tooling scaffold — CLAUDE.md, hooks, MCP, agents, skills — 2026-03-19

## Notes
- Start with WY + ID only (best data availability). Add CO, UT, MT in Phase 2-3.
- Idaho has the best structured data (JSON API). Wyoming needs the most scraping work.
- See docs/plan/PLAN.md for full task breakdown with estimates and dependencies.
