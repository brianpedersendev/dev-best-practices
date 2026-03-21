# Telegram Calorie-Tracking Bot: Technical Architecture Guide

> **Date:** 2026-03-21
> **Purpose:** Best-of-breed architecture for a single-user Telegram bot that receives food photos, calls an AI vision API, logs meals, and sends daily summaries.

---

## 1. Telegram Bot Framework

### The Contenders

| Framework | GitHub Stars | Latest Release | Python Version | Async Model |
|-----------|-------------|----------------|----------------|-------------|
| [python-telegram-bot (PTB)](https://github.com/python-telegram-bot/python-telegram-bot) | ~29K | v22.7 (Mar 2026) | 3.10+ | Async (v20+) |
| [aiogram](https://github.com/aiogram/aiogram) | ~5K | v3.26.0 (Mar 2026) | 3.10+ | Async-first |
| [pyTelegramBotAPI](https://github.com/eternnoir/pyTelegramBotAPI) | ~8K | Active | 3.8+ | Sync + async |
| [Telethon](https://github.com/LonamiWebs/Telethon) | ~10K | Active | 3.8+ | Async (MTProto client, not Bot API) |

### Analysis

**python-telegram-bot (PTB)** is the recommendation for this project:

- **Best documented.** PTB has the largest English-language community, the most comprehensive wiki, and extensive examples covering every Bot API feature. The [official wiki](https://github.com/python-telegram-bot/python-telegram-bot/wiki) is a standout resource. ([Source](https://github.com/python-telegram-bot/python-telegram-bot))
- **Best maintained.** 29K GitHub stars, 6K forks, active releases through v22.7 (March 2026), supports Bot API 9.5. ([Source](https://github.com/python-telegram-bot/python-telegram-bot/releases))
- **Built-in job scheduling.** PTB's `JobQueue` wraps APScheduler, giving you `run_daily()` out of the box — perfect for daily summaries without adding a separate scheduling library. ([Source](https://docs.python-telegram-bot.org/en/stable/telegram.ext.jobqueue.html))
- **Fully async since v20.** PTB moved to asyncio in v20, so the old "sync-only" criticism no longer applies. Performance is excellent for single-user and multi-user bots alike. ([Source](https://valebyte.com/blog/en/top-5-python-libraries-for-building-telegram-bots-on-your-vpsvds-in-2025/))
- **Easiest onboarding.** For a personal project where you want to ship fast, PTB's beginner-friendly docs and massive StackOverflow/community coverage minimize time debugging framework issues.

**Why not the others?**

- **aiogram** is excellent and arguably more "Pythonic" in its async design, but its community is strongest in the Russian-speaking world and its docs, while good, are less comprehensive in English. It also lacks a built-in scheduler — you'd need to add APScheduler yourself. For a personal bot, this extra setup has no payoff. ([Source](https://github.com/aiogram/aiogram/issues/1195))
- **Telethon** is an MTProto client library (user accounts), not a Bot API wrapper. It's the wrong tool for a bot. ([Source](https://github.com/LonamiWebs/Telethon))
- **pyTelegramBotAPI** is fine but has a smaller ecosystem than PTB and fewer advanced features.

### Webhook vs. Polling

**Use long polling** for this personal bot.

| Factor | Long Polling | Webhooks |
|--------|-------------|----------|
| Setup complexity | Trivial — `app.run_polling()` | Requires public URL + HTTPS cert |
| Firewall/NAT | Works behind any firewall | Must accept inbound connections |
| Latency | ~1-2s (fine for calorie logging) | Near-instant |
| Serverless compatible | No | Yes (required for Lambda/CF) |
| Resource usage | Slightly higher (open connection) | Lower (event-driven) |

For a single-user bot, long polling is simpler and "there are no major drawbacks to long polling, and—according to our experience—you will spend much less time fixing things." ([Source — grammY docs, applies to all Bot API libraries](https://grammy.dev/guide/deployment-types))

Only consider webhooks if you deploy to a serverless platform (Lambda, Cloud Functions), which requires them.

---

## 2. Persistence Layer

### Recommendation: SQLite

For a single-user calorie-tracking bot, **SQLite is the clear winner**.

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **SQLite** | Zero config, ships with Python, single file, full SQL, reliable | Single-writer (irrelevant for 1 user) | **Best fit** |
| JSON file | Dead simple | No querying, corruption risk on crash, no schema | Too fragile |
| PostgreSQL | Full-featured RDBMS | Requires a running server, overkill | Over-engineered |
| TinyDB | Python-native document store | Small community, no SQL | Unnecessary abstraction |

**Why SQLite specifically:**
- Ships with Python (`import sqlite3`) — zero dependencies. ([Source](https://docs.python.org/3/library/sqlite3.html))
- The entire database is a single file — trivial to back up (`cp meals.db meals.db.bak`).
- SQLite's single-writer limitation is a non-issue for a single-user bot. ([Source](https://hexshift.medium.com/integrating-sqlite-for-data-persistence-in-a-minimal-python-web-framework-4073e55cd54e))
- Full SQL means you can run aggregation queries for daily summaries: `SELECT SUM(calories) FROM meals WHERE date = ?`
- Battle-tested — SQLite handles more concurrent reads/writes than a personal bot will ever generate.

### Suggested Schema

```sql
CREATE TABLE meals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    photo_file_id TEXT,            -- Telegram file_id for the photo
    food_description TEXT,          -- What the AI identified
    calories INTEGER,               -- Estimated calories
    protein_g REAL,                 -- Optional macros
    carbs_g REAL,
    fat_g REAL,
    confidence TEXT,                -- AI confidence level (high/medium/low)
    raw_ai_response TEXT            -- Full AI response for debugging
);

CREATE TABLE daily_targets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    calorie_target INTEGER DEFAULT 2000,
    protein_target_g REAL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- Example rows: ('timezone', 'America/New_York'), ('summary_hour', '21'), ('chat_id', '123456789')
```

**Key design decisions:**
- Store `photo_file_id` (Telegram's reference), not the actual image binary. Telegram hosts the file; you can re-download it anytime via the Bot API.
- Store `raw_ai_response` for debugging — vision APIs sometimes return surprising results and you'll want to inspect them.
- Use a key-value `user_settings` table for flexibility without schema migrations.
- Keep macros (protein, carbs, fat) as optional columns — the vision API may or may not return them, and you might want to add them later.

### Database Access Pattern

Use `aiosqlite` for async compatibility with PTB v20+:

```python
import aiosqlite

async def log_meal(photo_file_id: str, description: str, calories: int, **macros):
    async with aiosqlite.connect("meals.db") as db:
        await db.execute(
            "INSERT INTO meals (photo_file_id, food_description, calories, protein_g, carbs_g, fat_g) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (photo_file_id, description, calories, macros.get("protein"), macros.get("carbs"), macros.get("fat"))
        )
        await db.commit()
```

---

## 3. Hosting Options

### Comparison Matrix

| Platform | Monthly Cost | Always-On | Scheduling | Deployment Ease | Persistent Storage | Best For |
|----------|-------------|-----------|------------|-----------------|-------------------|----------|
| **Hetzner CX22** | ~€3.80 | Yes | cron / systemd | SSH + systemd | Local disk | **Best value VPS** |
| **DigitalOcean** | $6 | Yes | cron / systemd | SSH + systemd | Local disk | Easy VPS |
| **Railway** | ~$5 | Yes | Built-in cron | Git push deploy | Ephemeral (need volume) | Easiest PaaS |
| **Fly.io** | ~$5+ | Yes | fly-cron | CLI deploy | Volumes | Global edge |
| **Render** | $0 (free) / $7 (paid) | No (free sleeps) | Cron jobs (paid) | Git push deploy | Ephemeral | Free tier testing |
| **AWS Lambda** | ~$0 (free tier) | No (cold starts) | EventBridge | Complex setup | No (need DynamoDB) | Serverless |
| **Google Cloud Functions** | ~$0 (free tier) | No (cold starts) | Cloud Scheduler | Moderate setup | No (need Firestore) | Serverless |
| **Raspberry Pi** | $0 (after hardware) | Yes | cron | Manual | Local disk | Already own one |

### Detailed Analysis

#### VPS (Recommended)

**Hetzner CX22** (~€3.80/month) is the best value:
- 2 vCPUs, 4 GB RAM, 40 GB disk — massive overkill for a bot, but that's the entry price. ([Source](https://costgoat.com/pricing/hetzner))
- Includes IPv4, traffic, DDoS protection at no extra charge.
- Run the bot with `systemd` for auto-restart, use `cron` or PTB's built-in `JobQueue` for daily summaries.
- SQLite file lives on local disk — no external database needed.
- One guide shows running an AI agent 24/7 on a €4/month Hetzner VPS with Telegram integration. ([Source](https://hostadvice.com/vps/telegram-bot/))

**DigitalOcean** ($6/month basic droplet) is a fine alternative if you prefer their UI/docs.

#### Serverless (Not Recommended for This Project)

Serverless (Lambda, Cloud Functions) has a compelling $0 price tag but introduces significant complexity:
- **Requires webhooks** — no long polling on serverless. ([Source](https://grammy.dev/hosting/comparison))
- **No local filesystem** — you'd need an external database (DynamoDB, Firestore) instead of SQLite, adding complexity and potential cost.
- **Cold starts** cause 1-5 second delays on first message after inactivity.
- **Scheduling requires a separate service** (EventBridge, Cloud Scheduler) rather than a simple `run_daily()` call.
- The "free" tier is genuinely free for low-traffic bots, but the architecture tax makes it worse for this use case.

#### PaaS (Viable Alternative)

**Railway** (~$5/month) is the simplest PaaS option:
- Git push to deploy — no SSH, no systemd configuration.
- But you lose local SQLite (ephemeral filesystem) — you'd need to attach a Railway volume or use their PostgreSQL addon, adding complexity. ([Source](https://docs.railway.com/platform/compare-to-fly))

**Render** free tier sleeps after inactivity, which means your bot goes offline and misses messages. Not suitable. Paid tier ($7/month) works but costs more than a VPS with less control. ([Source](https://cybersnowden.com/render-vs-railway-vs-fly-io/))

#### Self-Hosted (Raspberry Pi)

If you already have a Pi or home server running 24/7, this costs $0/month in hosting. But you're responsible for uptime, dynamic DNS, power outages, and SD card reliability. Fine as a learning exercise; less reliable than a $4 VPS.

---

## 4. Scheduling the Daily Summary

### Recommendation: PTB's Built-in `JobQueue.run_daily()`

Since we're recommending python-telegram-bot, the best approach is its **built-in `JobQueue`**, which wraps APScheduler under the hood:

```python
from telegram.ext import Application
from datetime import time

async def daily_summary(context):
    # Query today's meals from SQLite
    async with aiosqlite.connect("meals.db") as db:
        cursor = await db.execute(
            "SELECT SUM(calories), COUNT(*) FROM meals WHERE date(timestamp) = date('now')"
        )
        total_cal, meal_count = await cursor.fetchone()

    chat_id = "YOUR_CHAT_ID"
    text = f"📊 Daily Summary\nMeals: {meal_count}\nTotal: {total_cal or 0} kcal"
    await context.bot.send_message(chat_id=chat_id, text=text)

app = Application.builder().token("YOUR_TOKEN").build()

# Schedule daily at 9 PM in your timezone
app.job_queue.run_daily(
    daily_summary,
    time=time(hour=21, minute=0, tzinfo=your_timezone),
    name="daily_summary"
)
```

**Why this over alternatives:**
- **Zero additional dependencies** — PTB's `JobQueue` is included with `pip install "python-telegram-bot[job-queue]"`. ([Source](https://docs.python-telegram-bot.org/en/stable/telegram.ext.jobqueue.html))
- **Runs in-process** — no separate cron job, no external scheduler service, no infrastructure to manage.
- **Timezone-aware** — pass a `tzinfo` object directly.
- **Survives within the bot process** — if the bot is running (via systemd), the scheduler is running.

### Alternative Approaches

| Approach | When to Use |
|----------|------------|
| **System cron** | If you decouple the scheduler from the bot (e.g., a separate script that calls the Bot API directly) |
| **APScheduler standalone** | If using aiogram (which has no built-in scheduler) ([Source](https://github.com/aiogram/aiogram/issues/1195)) |
| **Cloud Scheduler / EventBridge** | If on serverless — triggers a Lambda/Cloud Function on schedule |
| **Celery + Redis** | Massive overkill for a single-user bot |

For this project, PTB's `JobQueue` is the simplest correct answer.

---

## 5. Recommended Stack

### The Stack

| Layer | Choice | Why |
|-------|--------|-----|
| **Framework** | python-telegram-bot v22+ | Best docs, largest community, built-in scheduler, fully async |
| **Persistence** | SQLite via `aiosqlite` | Zero-config, single file, ships with Python, async-compatible |
| **Hosting** | Hetzner CX22 VPS (~€3.80/mo) | Cheapest reliable VPS, local disk for SQLite, systemd for process management |
| **Scheduling** | PTB `JobQueue.run_daily()` | Built-in, zero extra deps, timezone-aware |
| **Process management** | systemd | Auto-restart on crash, start on boot, logs via `journalctl` |
| **Vision API** | OpenAI GPT-4o / Claude with vision | Both handle food identification well; pick based on your existing API access |
| **Language** | Python 3.11+ | PTB + aiosqlite + httpx for API calls |

### Project Structure

```
calorie-bot/
├── bot.py              # Entry point, handlers, job queue setup
├── vision.py           # AI vision API integration (photo → food + calories)
├── db.py               # SQLite schema init + query helpers
├── config.py           # Token, chat_id, API keys, timezone, targets
├── meals.db            # SQLite database (auto-created)
├── requirements.txt    # python-telegram-bot[job-queue], aiosqlite, httpx
└── calorie-bot.service # systemd unit file
```

### Core Flow

```
User sends food photo
  → bot.py receives photo via update handler
  → Downloads photo from Telegram
  → vision.py sends to GPT-4o/Claude vision API
  → AI returns: food description, estimated calories, macros
  → db.py logs meal to SQLite
  → Bot replies: "Logged: Grilled chicken salad — ~450 kcal (protein: 35g, carbs: 20g, fat: 22g)"

9 PM daily (via JobQueue):
  → db.py queries day's totals
  → Bot sends summary: meals logged, total calories, vs. target, macros breakdown
```

### Deployment (One-Time Setup)

```bash
# On Hetzner VPS
sudo apt update && sudo apt install python3.11 python3.11-venv
python3.11 -m venv /opt/calorie-bot/venv
source /opt/calorie-bot/venv/bin/activate
pip install "python-telegram-bot[job-queue]" aiosqlite httpx

# Create systemd service
sudo tee /etc/systemd/system/calorie-bot.service << 'EOF'
[Unit]
Description=Calorie Tracking Telegram Bot
After=network.target

[Service]
Type=simple
User=botuser
WorkingDirectory=/opt/calorie-bot
ExecStart=/opt/calorie-bot/venv/bin/python bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now calorie-bot
```

### Cost Summary

| Item | Monthly Cost |
|------|-------------|
| Hetzner CX22 VPS | €3.80 (~$4.10) |
| Telegram Bot API | Free |
| OpenAI GPT-4o vision (est. ~5 photos/day) | ~$1-3 |
| SQLite | Free |
| **Total** | **~$5-7/month** |

---

## Sources

- [python-telegram-bot GitHub](https://github.com/python-telegram-bot/python-telegram-bot) — 29K stars, v22.7, Bot API 9.5
- [aiogram GitHub](https://github.com/aiogram/aiogram) — v3.26.0, async-first framework
- [PTB JobQueue docs](https://docs.python-telegram-bot.org/en/stable/telegram.ext.jobqueue.html) — `run_daily()` API reference
- [aiogram scheduler issue #1195](https://github.com/aiogram/aiogram/issues/1195) — no built-in scheduler; use APScheduler
- [grammY: Long Polling vs Webhooks](https://grammy.dev/guide/deployment-types) — polling simpler, fewer things to fix
- [grammY: Hosting Comparison](https://grammy.dev/hosting/comparison) — serverless requires webhooks
- [Hetzner Cloud Pricing](https://costgoat.com/pricing/hetzner) — CX22 at €3.79/month
- [Best VPS for Telegram Bot](https://hostadvice.com/vps/telegram-bot/) — VPS recommendations for bots
- [Railway vs Fly.io vs Render](https://medium.com/ai-disruption/railway-vs-fly-io-vs-render-which-cloud-gives-you-the-best-roi-2e3305399e5b) — PaaS cost comparison
- [Render vs Railway vs Fly.io](https://cybersnowden.com/render-vs-railway-vs-fly-io/) — feature comparison
- [Railway docs: Compare to Fly](https://docs.railway.com/platform/compare-to-fly)
- [Serverless Telegram Bot](https://sampo.website/blog/en/2025/serverless-tg-bot/) — serverless architecture walkthrough
- [PTB vs aiogram comparison](https://www.restack.io/p/best-telegram-bot-frameworks-ai-answer-python-telegram-bot-vs-aiogram-cat-ai)
- [Top 5 Python Libraries for Telegram Bots 2025](https://valebyte.com/blog/en/top-5-python-libraries-for-building-telegram-bots-on-your-vpsvds-in-2025/)
- [SQLite for bot persistence](https://hexshift.medium.com/integrating-sqlite-for-data-persistence-in-a-minimal-python-web-framework-4073e55cd54e)
- [Telegram Bot Cost Breakdown 2026](https://www.botract.com/blog/telegram-bot-cost-pricing-guide)
- [piptrends: PTB vs aiogram download comparison](https://piptrends.com/compare/python-telegram-bot-vs-aiogram)
