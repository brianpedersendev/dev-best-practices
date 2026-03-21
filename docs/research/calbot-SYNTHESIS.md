# Research Synthesis: CalBot — Telegram Meal Photo Calorie Tracker

**Date:** 2026-03-21
**Researchers:** Competitive landscape, technical feasibility, architecture, market signals
**Project Brief:** [docs/PROJECT-BRIEF.md](../PROJECT-BRIEF.md)

---

## Executive Summary

CalBot is a personal Telegram bot that logs meals via photos, uses AI vision to estimate calories, and sends daily summaries for weight loss tracking. Research across four areas — competition, technical feasibility, architecture, and market demand — paints a clear picture: **this is a validated, buildable project with strong tailwinds and manageable risks.**

---

## Key Findings

### 1. Market Demand: Strong and Validated

- **80% of calorie trackers quit** due to manual logging friction — the exact problem CalBot solves
- Cal AI (photo-to-calories app) hit **8.3M downloads and $40M revenue** in 12 months, then was **acquired by MyFitnessPal** in March 2026 — proving massive demand for photo-based calorie tracking
- Reddit sentiment overwhelmingly favors AI alternatives to MyFitnessPal's bloated, ad-choked, paywalled experience
- Diet/nutrition app market is **~$6B in 2025**, growing at **14-17% CAGR**
- Telegram has **1B MAUs** and bot development is 60-80% cheaper than native apps

**Source:** [docs/research/telegram-calorie-bot-market-research.md](telegram-calorie-bot-market-research.md)

### 2. Competitive Landscape: Occupied but Beatable

**Standalone AI calorie apps:**
- **Cal AI** — 8.3M downloads but significant accuracy complaints (undercounting by 50%+ on some foods), deceptive pricing
- **SnapCalorie** — Best accuracy (16% error) but requires LiDAR, $89.99/yr
- **FoodVisor** — 87% accuracy claim, $83.99/yr

**Existing Telegram calorie bots:**
- At least **6 active bots** exist (Meals.Chat, CalPal.Pro, FitPlate, Calorica, etc.)
- Plus **5+ open-source GitHub repos** for Telegram + photo + calorie bots
- **None have significant scale or polish** — the gap is in execution quality, not concept novelty

**Key insight:** The idea isn't novel, but no existing Telegram bot matches standalone app quality. CalBot's advantage would be: zero-install friction, free/cheap, and meeting users where they already are.

**Source:** [docs/research/calbot-competitive-landscape.md](calbot-competitive-landscape.md)

### 3. Technical Feasibility: Proven and Affordable

**Vision model accuracy:**
- GPT-4o and Claude achieve **~35-37% MAPE** for calorie estimation from photos — comparable to each other, far better than Gemini (65-70%)
- GPT-4o achieves **89.8% food identification accuracy** with portion correlation r = 0.81
- General-purpose LLMs now **outperform specialized food APIs** (Calorie Mama: 63% top-1, Clarifai: 38%)
- 35% MAPE is adequate for weight loss — FDA allows 20% variance on labels, humans estimate with 20-50% error unaided

**Cost:**
- Vision API calls cost **$0.002-0.006 per photo**
- At 5 photos/day: **$0.30-0.90/month** — negligible
- Total infrastructure: **~$5-7/month** (VPS + API)

**Recommended approach:** Use GPT-4o or Claude Sonnet as a general-purpose vision LLM with structured prompt. Single call identifies food AND estimates calories — no separate nutrition database needed.

**Source:** [docs/research/calbot-technical-feasibility.md](calbot-technical-feasibility.md)

### 4. Technical Architecture: Straightforward

| Component | Recommendation | Rationale |
|-----------|---------------|-----------|
| **Language** | Python | Best Telegram bot ecosystem, AI SDK support |
| **Bot framework** | python-telegram-bot v22+ | 29K stars, built-in scheduler, async, best docs |
| **Persistence** | SQLite via aiosqlite | Zero config, single file, full SQL for aggregation |
| **Vision API** | GPT-4o or Claude Sonnet | Best accuracy, affordable, single-call food+calories |
| **Hosting** | Hetzner CX22 VPS (~$4/mo) | Cheapest reliable option, local disk for SQLite |
| **Scheduling** | PTB's JobQueue.run_daily() | Built-in, no extra dependencies |
| **Polling vs webhooks** | Long polling | Simpler, no public URL/SSL needed |

**Estimated build time:** 2-3 weekends for a working MVP
**Estimated monthly cost:** ~$5-7

**Source:** [docs/topics/telegram-calorie-bot-architecture.md](../topics/telegram-calorie-bot-architecture.md)

---

## Answers to Open Questions

| Question | Answer |
|----------|--------|
| Best vision model for food/calories? | **GPT-4o or Claude Sonnet** — both ~35% MAPE, outperform specialized APIs |
| Best persistence for single-user bot? | **SQLite** — zero config, full SQL, single file backup |
| How accurate are vision models? | **~35% MAPE** — adequate for weight loss, better than unaided human estimation |
| Best hosting approach? | **Hetzner CX22 VPS** at ~$4/mo with systemd process management |
| Should bot ask clarifying questions? | **No for MVP** — estimate silently for minimum friction. Can add optional corrections in v2 |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Calorie estimates too inaccurate | Medium | 35% MAPE is validated as adequate; prompt engineering can improve; errors average out over a day |
| Photo quality issues | Low | Most smartphone cameras are adequate; can add a "photo too dark" detection |
| Competing Telegram bots | Low | None have polish or scale; execution quality is the differentiator |
| API cost escalation | Very Low | Currently $0.30-0.90/mo; even 10x increase is trivial |
| Habit abandonment | Medium | Daily summary creates accountability loop; low friction helps retention |
| Model API changes/deprecation | Low | Easy to swap between GPT-4o and Claude; not locked into one provider |

---

## Go / No-Go Recommendation

### Recommendation: GO

### Rationale

This is a well-validated personal tool project with minimal risk and clear utility. The core technical bet — AI vision models can estimate calories from food photos well enough for weight loss — is supported by peer-reviewed research showing 35% MAPE, which is adequate for the use case. The market signal is unmistakable: Cal AI proved $40M/year demand exists, and 80% of calorie trackers quit because of manual logging friction that CalBot eliminates.

The project is technically straightforward — a Python Telegram bot, a vision API call, SQLite storage, and a daily cron job. Total cost under $7/month. Build time is 2-3 weekends for a working MVP. There are no exotic dependencies, no complex infrastructure, and no scaling concerns for a single user.

The concept isn't novel (6+ Telegram bots exist), but none have meaningful polish or accuracy. This is a "better execution wins" situation, not a "first mover wins" situation. For a personal tool, competition is irrelevant anyway — you're building it for yourself.

### If GO:
- **Key advantages:** Zero-friction UX (Telegram-native), proven AI accuracy adequate for weight loss, extremely low cost (<$7/mo), fast to build (2-3 weekends)
- **Biggest risks:** Calorie accuracy on complex/mixed meals; habit sustainability after initial novelty
- **Suggested approach:** Python + python-telegram-bot + GPT-4o vision + SQLite + Hetzner VPS. Ship the simplest possible version first: photo in → calorie estimate out → daily summary. Add features only after 2 weeks of daily use.

---

## Research Files

| File | Contents |
|------|----------|
| [PROJECT-BRIEF.md](../PROJECT-BRIEF.md) | Validated project brief from idea interview |
| [calbot-competitive-landscape.md](calbot-competitive-landscape.md) | Full competitive analysis — standalone apps + Telegram bots |
| [telegram-calorie-bot-market-research.md](telegram-calorie-bot-market-research.md) | Market demand signals, user sentiment, funding trends |
| [calbot-technical-feasibility.md](calbot-technical-feasibility.md) | Vision model comparison, accuracy analysis, cost breakdown |
| [telegram-calorie-bot-architecture.md](../topics/telegram-calorie-bot-architecture.md) | Recommended tech stack and architecture |
