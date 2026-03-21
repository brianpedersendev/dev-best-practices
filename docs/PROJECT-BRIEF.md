# Project Brief: CalBot

## One-Line Description
A Telegram bot that logs meals via photos, uses AI to estimate calories, and sends daily summaries to support weight loss.

## Problem Statement
Tracking calories is tedious — most apps require manual food entry, searching databases, and estimating portions. This friction causes most people to quit within days. CalBot removes that friction: snap a photo in Telegram, and the bot handles identification and calorie estimation automatically. Built as a personal tool for daily use.

## Target Users
Solo user (Brian) — someone actively pursuing weight loss who wants frictionless daily calorie tracking without switching apps or manually logging food.

## Core Value Proposition
Zero-friction meal logging: take a photo in Telegram (an app already open all day), get instant calorie estimates, and receive a daily summary showing progress against a calorie target. No app to install, no database to search, no portions to weigh.

## MVP Scope

### In (v1)
- Telegram bot that receives meal photos
- AI-powered food identification and calorie estimation from photos
- Per-meal calorie estimate sent back immediately after photo
- Daily calorie target setting (user configurable)
- End-of-day Telegram summary: meals logged, total calories, remaining budget vs. target
- Persistent storage of meal log (photo reference, food identified, calories, timestamp)

### Explicitly Out (v1)
- Macro tracking (protein/carbs/fat) — calories only for MVP
- Web dashboard or UI outside Telegram
- Multi-user support / authentication
- Manual correction of AI estimates
- Meal suggestions or recipe recommendations
- Integration with fitness trackers or health apps
- Historical trends / weekly/monthly reports

## Known Competitors / Alternatives
- **MyFitnessPal** — market leader, huge food database, but requires manual search & entry
- **Lose It!** — similar to MFP, has photo scanning but locked behind premium
- **CalAI / Snap Calorie** — AI photo-based calorie estimation apps (standalone mobile apps)
- **FoodVisor** — AI-powered food recognition with nutrition breakdown
- **Various Telegram food bots** — mostly manual logging or simple calorie lookup, not photo-based AI

Key gap: No existing solution combines Telegram-native UX with AI photo-based calorie estimation. The standalone AI calorie apps exist but require installing yet another app.

## Technical Constraints
- Solo developer
- Best-of-breed stack (choose whatever works best for the job)
- Approximate calorie estimates from AI are acceptable — no need for clinical accuracy
- Must run affordably for a single user (low infra cost)
- Telegram Bot API is the only user interface

## Architecture Direction
- **AI-augmented** — AI is a feature (vision-based food recognition) within a traditional bot architecture
- **Vision model** needed for food identification + calorie estimation (e.g., Claude vision, GPT-4V, or specialized food recognition API)
- No RAG needed — no corpus to search
- No agentic backend needed — simple request/response pattern
- No streaming needed — Telegram messages are discrete
- Key architecture decision: use a general-purpose vision LLM vs. a specialized food recognition API for calorie estimation

## Success Criteria
- Bot is functional and used daily for 2+ weeks
- Calorie estimates are "close enough" to be useful for weight loss tracking (not wildly off)
- Daily summary arrives reliably every evening
- Total friction to log a meal: open Telegram → snap photo → send. Under 10 seconds.

## Open Questions
1. Which vision model/API gives the best food identification + calorie estimation? (Claude vision vs. GPT-4V vs. specialized APIs like FoodVisor/Nutritionix)
2. What's the best persistence layer for a single-user bot? (SQLite? Simple JSON? Hosted DB?)
3. How accurate are current vision models at estimating calories from photos? Is this accurate enough to be useful?
4. Best hosting approach for a personal Telegram bot? (VPS, serverless, always-on process?)
5. Should the bot ask clarifying questions ("Is that a large or small portion?") or just estimate silently?

## Risk Factors
- **Calorie estimation accuracy** — AI vision models may not be accurate enough to be useful for weight loss. If estimates are consistently 30-50% off, the tool defeats its purpose. Research should validate current accuracy levels.
- **Photo quality dependency** — Bad lighting, weird angles, or mixed plates could confuse the model significantly.
- **Sustainability** — Even with low friction, solo tools sometimes get abandoned. The daily summary helps with habit formation, but it's still a risk.
- **API costs** — Vision model API calls per meal (3-5/day) need to be affordable for sustained personal use.
