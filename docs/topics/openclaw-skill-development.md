# Building OpenClaw Skills: Comprehensive Guide from Basics to Production (2026)

**Date researched:** 2026-03-18

**Target audience:** Developers building automation agents, integrations, and operational tools on OpenClaw. Assumes basic familiarity with OpenClaw from the [OpenClaw Deep Dive](openclaw-deep-dive.md).

---

## Table of Contents

1. [OpenClaw Architecture for Skill Developers](#1-openclaw-architecture-for-skill-developers)
2. [Skill Types & Anatomy](#2-skill-types--anatomy)
3. [Building Your First Skill (Step by Step)](#3-building-your-first-skill-step-by-step)
4. [Skill Development Patterns](#4-skill-development-patterns)
5. [The ClawHub Ecosystem](#5-the-clawhub-ecosystem)
6. [Security for Skill Developers](#6-security-for-skill-developers)
7. [OpenClaw + MCP + Claude Code Integration](#7-openclaw--mcp--claude-code-integration)
8. [NemoClaw Considerations](#8-nemoclaw-considerations)
9. [Testing & Debugging Skills](#9-testing--debugging-skills)
10. [Real-World Skill Examples](#10-real-world-skill-examples)
11. [Skill Development Checklist](#11-skill-development-checklist)

---

## 1. OpenClaw Architecture for Skill Developers

### How OpenClaw Works (Internal Architecture)

OpenClaw separates concerns into three clean layers:

```
┌─────────────────────────────────────────────────────────┐
│ User Interface Layer                                     │
│ (WhatsApp, Telegram, Discord, Slack, WebSocket)         │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ Agent Reasoning Layer                                    │
│ (LLM: Claude, GPT-4, DeepSeek, Gemini)                  │
│ - Prompt management                                      │
│ - Tool discovery and routing                             │
│ - Memory management (episodic, semantic, working)        │
│ - Context compression                                    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ Execution Layer                                          │
│ ┌──────────────────────────────────────────────────┐   │
│ │ MCP Servers (65%+ of skills wrap these)          │   │
│ │ - Git, GitHub, Figma, Supabase, Playwright, etc  │   │
│ └──────────────────────────────────────────────────┘   │
│ ┌──────────────────────────────────────────────────┐   │
│ │ Native Integrations                              │   │
│ │ - Email, calendar, file system                   │   │
│ ├──────────────────────────────────────────────────┤   │
│ │ Skills (Instructions + metadata)                 │   │
│ │ - Define workflows, triggers, permissions        │   │
│ └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**Key insight:** The agent doesn't care how a tool is implemented (MCP, REST, native). Skills provide the instructions that teach the agent *when and how* to use tools.

### The Agent Communication Protocol (ACP)

ACP enables **bidirectional communication** between OpenClaw agents and external systems (IDEs, browsers, other agents). Think of it as "how the agent talks back to you and to other tools."

**ACP capabilities:**
- **Stateful sessions:** Multi-turn conversations that survive across invocations
- **Stdio transport:** Works over standard input/output (IDE-compatible, simple)
- **Job model:** Skills can spawn sub-agents and delegate work across multiple agents
- **Agent Wallet:** Each agent has persistent on-chain identity and can buy/sell services
- **Tool discovery:** ACP clients discover available tools without pre-configuration

**For skill developers:** Most of the time you don't explicitly code against ACP. You write a SKILL.md file with instructions; OpenClaw's routing layer handles the ACP details. But if you're building agent-to-agent integrations or custom orchestration, you need ACP familiarity.

**Example ACP flow:**
```
User: "Deploy staging to production"
  ↓
OpenClaw gateway (via Telegram)
  ↓
LLM reasoning: "I need to verify the deployment, run tests, then deploy"
  ↓
ACP dispatch: Create job with sub-tasks
  ↓
MCP tool execution: Call deploy script, monitor logs
  ↓
ACP response back: "Deployment complete, 3 warnings"
  ↓
Telegram response to user
```

### Skill Lifecycle: Discovery → Installation → Invocation → Execution → Response

**1. Discovery:** Skill is listed on ClawHub or a local skill registry.

**2. Installation:** User runs `openclaw install skill-name` or manually places skill in `~/.openclaw/workspace/skills/`.

**3. Registration:** OpenClaw scans SKILL.md metadata (name, version, requirements). Checks dependencies (bins, env vars, config). Creates entry in agent's tool roster.

**4. Invocation:** Agent encounters a task that matches the skill's domain. Includes the full SKILL.md in the prompt to the LLM.

**5. Execution:** LLM reads instructions, calls declared tools (MCP servers, native APIs). OpenClaw manages stdio/HTTP transport.

**6. Response:** Skill returns results. Agent continues reasoning or reports back to user.

**7. Lifecycle cleanup:** On agent shutdown, temporary state is cleaned up (sessions, temp files). Persistent state (memory files, logs) preserved.

### How Skills Differ from MCP Servers (and the 65% Pattern)

| Dimension | Skill | MCP Server |
|-----------|-------|-----------|
| **What it is** | Folder with SKILL.md instructions | Protocol server exposing tools |
| **Where it lives** | `~/.openclaw/workspace/skills/` | Separate process (stdio or HTTP) |
| **What it teaches** | How and when to use tools (workflow) | What tools are available (API) |
| **Who writes it** | Operators, workflow designers | API/integration developers |
| **Configuration** | YAML frontmatter in SKILL.md | MCP manifest or config file |
| **Typical pattern** | "Email triage workflow" | "Gmail API client" |

**The 65% Pattern (critical insight):**

Most skills wrap an MCP server:
```
┌──────────────────────────────────┐
│ Skill: "Email Triage"            │
│ (SKILL.md with instructions)     │
└────────────────┬─────────────────┘
                 │
         ┌───────▼──────────┐
         │ MCP: Gmail       │
         │ (provides tools) │
         └──────────────────┘
```

**Why?** Separation of concerns:
- **MCP server:** "Here are the Gmail tools: send_email, read_inbox, etc."
- **Skill:** "Here's how to triage: read inbox → categorize by urgency → flag important → generate summary."

**Implication for you:** If you've already built an MCP server, wrapping it as a skill takes ~5 minutes. If you haven't, you have a choice:
- Build a simple skill with inline instructions (good for lightweight automation)
- Build an MCP server + skill wrapper (good for reusable integrations)

---

## 2. Skill Types & Anatomy

### The Anatomy of a Skill

A skill is fundamentally simple: **a folder with a SKILL.md file**.

```
~/.openclaw/workspace/skills/
├── email-triage/
│   ├── SKILL.md              # ← The only required file
│   ├── scripts/
│   │   └── process.py        # Optional: helper scripts
│   ├── mcp/                  # Optional: bundled MCP server
│   │   └── package.json
│   └── config/
│       └── defaults.yaml     # Optional: default configuration
```

**Minimum skill (one file):**
```markdown
---
name: Hello World
description: Say hello to the user
version: 1.0.0
---

# Say Hello

When the user asks you to greet them, respond with a friendly hello.
```

That's a valid skill. It doesn't do much, but OpenClaw can load and use it.

### The SKILL.md Format

**Structure:**
```markdown
---
name: <skill-name>
description: <short description>
version: <semver>
author: <author-name>
# Optional metadata:
tags: [tag1, tag2]
category: automation|integration|workflow
requires:
  bins: [python, git]
  env: [GITHUB_TOKEN, API_KEY]
  config: [database.url]
primaryEnv: GITHUB_TOKEN
permissions:
  tools: [exec, web_fetch]
  paths: [~/my-data/, ~/.config/myskill/]
  domains: [api.example.com]
  capabilities: [network, filesystem]
---

# Skill Title (can be different from name in metadata)

**Purpose:** Clear one-line summary of what this skill does.

## What This Skill Does

[2-3 sentences explaining the skill's domain and when to use it.]

## How to Use It

[Step-by-step instructions for the agent, in plain English. Example:]

1. When asked to triage emails, use the Gmail MCP server to:
   - Connect with GMAIL_API_KEY
   - Read the last 10 messages from INBOX
   - For each message, classify as: urgent, normal, or spam
   - If urgent: flag and summarize
   - If spam: delete
   - If normal: archive

2. If any API call fails, retry up to 3 times with exponential backoff.

## Configuration

[Document required environment variables and config options.]

- `GITHUB_TOKEN`: Required. GitHub personal access token (fine-grained recommended)
- `REPO_OWNER`: Optional. Default: current repo owner

## Examples

[Show the agent how to handle common scenarios.]

**Example 1: Triage a specific inbox**
```
User: "Triage my Gmail inbox and send me a summary"
Agent response:
- Connected to Gmail
- Read 12 emails
- Flagged 3 as urgent (meetings, deadline alerts)
- Summary sent to Telegram
```

**Example 2: Error handling**
If API rate limit is hit, wait and retry. If auth fails, ask user to refresh token.

## Limitations

[Be honest about constraints.]

- Works only with Gmail (not Outlook)
- Rate limit: 10 triage sessions per day
- Requires GMAIL_API_KEY with read/modify scopes
```

### Skill Types & When to Use Each

#### 1. **Tool Skills** (Most Common)
Wrap an MCP server or API. Teach the agent how to use it.

**Example:**
```markdown
---
name: GitHub PR Reviewer
description: Review pull requests using GitHub API
version: 1.0.0
requires:
  env: [GITHUB_TOKEN]
---

# GitHub PR Reviewer

When asked to review a PR, use the GitHub MCP server to:
1. Fetch the PR diff
2. Check commit messages for clarity
3. Verify tests pass
4. Leave comments for issues found
```

**Best for:** Integrations with existing APIs/services.

#### 2. **Trigger Skills**
Respond to events (webhook, cron, file change, new message).

**Example:**
```markdown
---
name: Daily Standup Report
description: Generate daily team standup reports
version: 1.0.0
triggers:
  - type: cron
    schedule: "0 9 * * 1-5"  # 9am weekdays
    action: generate_standup_report
---

# Daily Standup Report

Every weekday at 9am:
1. Fetch team's completed tasks from Jira
2. Fetch in-progress work
3. Summarize blockers
4. Send summary to Slack
```

**Best for:** Scheduled reports, monitoring, event-driven automation.

#### 3. **Scheduled Skills**
Run at specific intervals (similar to trigger skills, but simpler).

**Example:**
```markdown
---
name: Competitor Monitoring
description: Track competitor websites for changes
schedule: "0 8 * * *"  # 8am daily
---

# Competitor Monitoring

Daily at 8am:
1. Scrape competitor sites (with respect to robots.txt)
2. Compare against previous snapshot
3. If changes detected, highlight key updates
4. Send digest via email
```

**Best for:** Periodic data gathering, reports, maintenance tasks.

#### 4. **Workflow Skills**
Multi-step processes orchestrating multiple tools.

**Example:**
```markdown
---
name: Customer Onboarding
description: Complete onboarding workflow for new customers
version: 1.0.0
requires:
  env: [STRIPE_API_KEY, SLACK_WEBHOOK, SENDGRID_API_KEY]
---

# Customer Onboarding Workflow

When a new customer signs up:

1. **Verify Payment** (via Stripe)
   - Call Stripe to confirm payment processed
   - If failed, notify customer

2. **Create Account** (internal database)
   - Create user record
   - Generate API keys
   - Set default quotas

3. **Send Welcome Email** (via SendGrid)
   - Template: welcome-customer
   - Include: API key, quickstart guide, support link

4. **Add to Slack Channel**
   - Create private channel
   - Add customer as member
   - Pin onboarding guide

5. **Log to Analytics**
   - Record signup timestamp, plan tier, region
   - Track for cohort analysis
```

**Best for:** Multi-service orchestration, complex business processes.

#### 5. **Multi-Agent Skills** (Advanced)
Skills that spawn sub-agents and coordinate work via ACP.

**Example:**
```markdown
---
name: Multi-team Code Review
description: Route code reviews to specialized agents
version: 1.0.0
acp:
  requires_agents:
    - backend-reviewer (reviews Node.js/Go code)
    - frontend-reviewer (reviews React/Vue code)
    - devops-reviewer (reviews Terraform/K8s)
---

# Multi-Team Code Review

When a PR is submitted:
1. Analyze file types changed
2. Route to appropriate specialist agent:
   - Backend files → backend-reviewer
   - Frontend files → frontend-reviewer
   - Infrastructure files → devops-reviewer
3. Aggregate reviews into single comment
4. Decide approval/request-changes based on specialist consensus
```

**Best for:** Delegating complex work, scaling beyond one agent.

---

## 3. Building Your First Skill (Step by Step)

### 3.1 Complete Walkthrough: A Simple Skill That Does Something Useful

Let's build a **"Daily Digest"** skill that:
- Aggregates GitHub notifications
- Summarizes Slack messages from key channels
- Sends a morning briefing via Telegram

**Step 1: Understand the requirements**
```
Input:
  - GITHUB_TOKEN (GitHub personal access token)
  - SLACK_BOT_TOKEN (Slack bot token)
  - TELEGRAM_CHAT_ID (where to send briefing)

Output:
  - Summary message via Telegram

Tools needed:
  - GitHub API (fetch notifications)
  - Slack API (fetch recent messages)
  - Telegram API (send message)
```

**Step 2: Set up the dev environment**

Create skill folder:
```bash
mkdir -p ~/.openclaw/workspace/skills/daily-digest
cd ~/.openclaw/workspace/skills/daily-digest
touch SKILL.md
```

**Step 3: Write the SKILL.md manifest**

```markdown
---
name: daily-digest
description: Morning briefing aggregating GitHub, Slack, and email activity
version: 1.0.0
author: you@example.com
tags: [automation, reporting, daily]
category: workflow
requires:
  env:
    - GITHUB_TOKEN
    - SLACK_BOT_TOKEN
    - TELEGRAM_CHAT_ID
  bins: []
primaryEnv: GITHUB_TOKEN
permissions:
  tools: [web_fetch]
  paths: []
  domains:
    - api.github.com
    - slack.com
    - api.telegram.org
  capabilities: [network]
---

# Daily Digest

**Purpose:** Generate a morning briefing of GitHub notifications, Slack activity, and work priorities. Sent to Telegram at 8am on weekdays.

**When to use:** Every morning, as part of your startup routine. Skip on days when you're not working.

## How It Works

Every weekday at 8am:

1. **GitHub Notifications** (last 24 hours)
   - Use GitHub API (via web_fetch) to fetch notifications
   - Filter: only unread, only mentions/assigned/reviews
   - Format: "3 PR reviews pending, 1 mention in issue #234"

2. **Slack Activity** (last 24 hours, key channels)
   - Fetch messages from channels: #engineering, #product, #incidents
   - Summarize: key decisions, blockers, announcements
   - Format: bullet list, most recent first

3. **Email Inbox** (if integrated)
   - Count unread messages
   - Highlight flagged/starred
   - Format: "12 unread, 2 flagged"

4. **Priorities** (inferred from above)
   - If PRs pending > 5: note "heavy review load"
   - If incident channel activity: note "ongoing incident"
   - If blocked items in Slack: flag blockers

5. **Telegram Notification**
   - Send formatted digest to TELEGRAM_CHAT_ID
   - If anything urgent, add ⚠️ emoji
   - Include: "Reply with questions"

## Configuration

Set these environment variables in ~/.openclaw/openclaw.json:

```json
{
  "skills": {
    "daily-digest": {
      "enabled": true,
      "env": {
        "GITHUB_TOKEN": "ghp_xxxxxxxxxxxx",
        "SLACK_BOT_TOKEN": "xoxb-xxxxxxxxxxxx",
        "TELEGRAM_CHAT_ID": "123456789"
      }
    }
  }
}
```

### Getting Your Tokens

- **GITHUB_TOKEN:** Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic). Create token with scopes: `notifications`, `read:user`. Copy and save.

- **SLACK_BOT_TOKEN:** In your Slack workspace, go to App Directory → Create New App → From scratch. Name: "OpenClaw Bot". Add these OAuth scopes:
  - `channels:read`
  - `channels:history`
  - `chat:write`

  Install to workspace. Copy Bot User OAuth Token.

- **TELEGRAM_CHAT_ID:** Send a message to your Telegram bot, then visit `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`. Find your chat_id in the response.

## Error Handling

If GitHub API fails:
- Retry up to 3 times with 2-second delay
- If still failing, skip GitHub section and note "GitHub unavailable"

If Slack API fails:
- Skip Slack section, continue with other sources
- Log error for debugging

If Telegram send fails:
- Retry 2 times
- If still failing, log to local file and alert user

## Examples

**Example execution (user perspective):**

```
OpenClaw: Morning briefing ready. Here's your digest:

GitHub: 3 PRs awaiting your review + 1 mention in #backend-design
Slack: 2 incident channel updates (network latency issue being resolved)
Email: 8 unread emails, 1 flagged

Blockers: Waiting on @alice to merge #1234

Would you like details on any of these?
```

**Example error handling:**

```
OpenClaw: GitHub API is rate-limited (60 requests/hour). Skipping detailed review count.

Slack: 2 incident updates
Email: 5 unread

Tip: Authenticated requests get higher GitHub rate limits. Update GITHUB_TOKEN if it's expired.
```

## Limitations

- Only fetches last 24 hours of data (not configurable yet)
- Requires manual token setup (OAuth 2.0 integration pending)
- Slack API has 50 message limit per channel per call
- No support for email integration yet (use Slack as workaround)

## Advanced: Customizing the Digest

You can customize which Slack channels are included. Ask OpenClaw to edit this SKILL.md and change the channel list:

```markdown
**Slack Channels to Monitor**
- #engineering
- #product
- #security  ← Add security channel
- #random    ← Remove this if too noisy
```

---
```

**Step 4: Test locally**

Before publishing, test in your local OpenClaw instance:

```bash
# 1. Set environment variables
export GITHUB_TOKEN="ghp_xxxx"
export SLACK_BOT_TOKEN="xoxb_xxxx"
export TELEGRAM_CHAT_ID="123456"

# 2. Start OpenClaw
openclaw start

# 3. In your Telegram bot, ask:
"Run the daily digest"

# 4. Check output
# Should see: GitHub summary + Slack summary + Telegram sent confirmation
```

**Step 5: Register as a cron job** (optional, for automated scheduling)

```bash
openclaw cron add daily-digest "0 8 * * 1-5"
```

This runs the skill every weekday at 8am.

**Step 6: Publish to ClawHub** (see section 5 for details)

```bash
cd ~/.openclaw/workspace/skills/daily-digest
clawhub publish .
```

---

### 3.2 Setting Up the Dev Environment

**Prerequisites:**
- OpenClaw installed (follow [official docs](https://docs.openclaw.ai))
- A text editor (VS Code, Vim, etc.)
- Git (optional, but recommended)
- Python 3.8+ (if building scripts)

**Directory structure (best practice):**
```
~/projects/my-skills/
├── daily-digest/
│   ├── SKILL.md
│   ├── scripts/
│   │   └── test.sh
│   └── README.md (optional, for GitHub)
├── email-triage/
│   └── SKILL.md
└── .gitignore
```

**Recommended .gitignore:**
```
.env
.env.local
*.pyc
__pycache__/
node_modules/
.vscode/settings.json
```

---

### 3.3 Writing the Skill Manifest

See section 2 for the full format. Key checklist:

- [ ] `name` is lowercase, hyphenated, unique
- [ ] `description` is one line, action-oriented
- [ ] `version` follows semver (1.0.0)
- [ ] `requires.env` lists all required environment variables
- [ ] `requires.bins` lists external binaries needed (git, python, etc.)
- [ ] `permissions` block declares what the skill needs (network, filesystem, etc.)
- [ ] YAML metadata is single-line JSON (not multi-line; common parser failure)

---

### 3.4 Implementing the Handler

"Handler" is a bit misleading here—OpenClaw skills don't have traditional event handlers. Instead, you write **instructions in Markdown** that teach the agent how to handle scenarios.

**Pattern:**

```markdown
---
[metadata]
---

# Skill Title

## When to Use This Skill

[Describe the problem the skill solves and situations when the agent should invoke it.]

## How It Works

[Step-by-step instructions for the agent. This is the core of the skill.]

1. Step one: [Action in plain English]
2. Step two: [Another action]
3. Step three: [Result]

## Error Handling

[How to handle common failures: API errors, network timeouts, auth failures, etc.]

## Configuration

[Document all env vars and config options.]

## Examples

[Show the agent working through 2-3 realistic scenarios.]
```

**For more complex logic, add scripts:**

If your skill needs to do complex computation (not just calling APIs), add helper scripts:

```markdown
---
name: data-processor
requires:
  bins: [python3]
---

# Data Processor

When asked to process large datasets:

1. Use the attached `scripts/process.py` script
2. Call it with: `python3 scripts/process.py --input <file> --output <result>`
3. Wait for completion
4. Validate output format (JSON or CSV)
5. Return results to user
```

**scripts/process.py:**
```python
#!/usr/bin/env python3
"""
Process data files (CSV/JSON) and aggregate statistics.
"""
import argparse
import json
import csv
from pathlib import Path

def process_csv(input_file):
    """Process CSV and return aggregated stats."""
    with open(input_file) as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    return {
        "row_count": len(rows),
        "columns": list(rows[0].keys()) if rows else [],
        "sample": rows[:2] if rows else []
    }

def process_json(input_file):
    """Process JSON and return aggregated stats."""
    with open(input_file) as f:
        data = json.load(f)
    return {
        "type": type(data).__name__,
        "keys": list(data.keys()) if isinstance(data, dict) else None,
        "length": len(data) if hasattr(data, '__len__') else None
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Input file path")
    parser.add_argument("--output", required=True, help="Output file path")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: {args.input} not found")
        exit(1)

    if input_path.suffix == ".csv":
        result = process_csv(input_path)
    elif input_path.suffix == ".json":
        result = process_json(input_path)
    else:
        print(f"Error: unsupported file type {input_path.suffix}")
        exit(1)

    with open(args.output, 'w') as f:
        json.dump(result, f, indent=2)

    print(f"Processed {input_path} → {args.output}")
```

---

### 3.5 Testing Locally

**Test in three phases:**

**Phase 1: Static validation (no execution)**
```bash
# Check SKILL.md syntax
openclaw validate-skill ~/.openclaw/workspace/skills/my-skill/SKILL.md

# Should output: ✓ Valid YAML metadata
```

**Phase 2: Mock testing (fake API responses)**

Set up a local mock server:
```bash
# Start mock API (returns canned responses)
python -m http.server 8888 &

# Update your SKILL.md to point to localhost:8888 for testing
# Then invoke the skill
```

**Phase 3: Live testing (against real APIs with test data)**

```bash
# 1. Set real credentials (test environment, if available)
export GITHUB_TOKEN="ghp_test_xxxx"

# 2. Invoke skill
openclaw run skill daily-digest

# 3. Check output
# Should see: success message or clear error

# 4. Inspect logs
tail -f ~/.openclaw/logs/skill-execution.log
```

**Common testing mistakes:**
- ❌ Not setting required env vars (skill fails silently)
- ❌ Testing against production APIs without test data
- ❌ Not checking rate limits (API keys can get temporarily blocked)
- ❌ Assuming error messages are clear (they often aren't; read the logs)

---

### 3.6 Registering with OpenClaw

Once tested, register the skill:

```bash
# 1. Move skill to OpenClaw's skills directory
cp -r ~/projects/my-skills/daily-digest ~/.openclaw/workspace/skills/

# 2. Reload OpenClaw
openclaw reload

# 3. Verify skill is recognized
openclaw list-skills | grep daily-digest

# 4. Test invocation
# Ask your OpenClaw agent: "Run daily digest"
```

---

## 4. Skill Development Patterns

### 4.1 Wrapping MCP Servers as Skills (The 65% Pattern)

**This is the most common pattern and the easiest to scale.**

#### Step 1: Understand your MCP server

Assume you've already built an MCP server for the Supabase API. It exposes tools like:
- `query_table(table_name, where_clause)`
- `insert_row(table_name, data)`
- `update_row(table_name, id, data)`

#### Step 2: Create the skill folder

```bash
mkdir -p ~/.openclaw/workspace/skills/supabase-queries
cd ~/.openclaw/workspace/skills/supabase-queries
```

#### Step 3: Copy or link the MCP server

Option A: Copy the MCP server into the skill folder:
```bash
cp -r ~/projects/my-mcp-servers/supabase-mcp ./mcp
```

Option B: Reference an external MCP server (if already installed):
```bash
# Update OpenClaw config to load the MCP
```

#### Step 4: Write the SKILL.md wrapper

```markdown
---
name: supabase-queries
description: Query and modify Supabase database tables with natural language
version: 1.0.0
author: you@example.com
requires:
  env:
    - SUPABASE_URL
    - SUPABASE_API_KEY
  bins:
    - node  # If MCP server is Node-based
permissions:
  tools: [exec]
  domains: [supabase.com]
  capabilities: [network]
mcp:
  server: ./mcp/index.js  # Path to MCP server entry point
  language: node
---

# Supabase Queries

**Purpose:** Natural language interface to query and modify Supabase tables.

## How to Use

You can ask me to:

1. **Query data:** "Show me all users from Berlin in the last month"
   - I'll translate to: `SELECT * FROM users WHERE city='Berlin' AND created_at > NOW() - INTERVAL '1 month'`
   - Using the `query_table` tool

2. **Insert data:** "Add a new customer: Jane Doe, jane@example.com"
   - I'll translate to: `INSERT INTO customers (name, email) VALUES ('Jane Doe', 'jane@example.com')`
   - Using the `insert_row` tool

3. **Update data:** "Mark order #123 as shipped"
   - I'll translate to: `UPDATE orders SET status='shipped' WHERE id=123`
   - Using the `update_row` tool

## Configuration

Set these in ~/.openclaw/openclaw.json:

```json
{
  "skills": {
    "supabase-queries": {
      "enabled": true,
      "env": {
        "SUPABASE_URL": "https://xxxxx.supabase.co",
        "SUPABASE_API_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      }
    }
  }
}
```

Get these from your Supabase project dashboard (Settings → API).

## Security Notes

- API keys are scoped to the database (not admin keys)
- All queries are logged for audit
- Write operations require explicit user confirmation
- Never expose API keys in skill code or logs

## Error Handling

If a query fails:
- Show the error message clearly
- Suggest corrected syntax
- Retry automatic query translation if possible

**Example:**
```
User: "Show me all orders where amount > 100"
Agent: "Querying: SELECT * FROM orders WHERE amount > 100"
Result: 5 matching orders
  Order #1001: $250
  Order #1002: $175
  ...
```

---
```

#### Step 5: Configure the MCP server location

In ~/.openclaw/openclaw.json:
```json
{
  "mcp": [
    {
      "name": "supabase",
      "command": "node",
      "args": ["~/.openclaw/workspace/skills/supabase-queries/mcp/index.js"],
      "env": {
        "SUPABASE_URL": "${SUPABASE_URL}",
        "SUPABASE_API_KEY": "${SUPABASE_API_KEY}"
      }
    }
  ],
  "skills": {
    "supabase-queries": {
      "enabled": true,
      "mcp": "supabase"  // Link skill to MCP
    }
  }
}
```

#### Step 6: Test

```bash
# Ask the agent:
"Show me all users from the users table where country = 'USA'"

# Expected flow:
# 1. Agent reads SKILL.md instructions
# 2. Agent calls MCP tool: query_table("users", "country='USA'")
# 3. MCP server executes query
# 4. Results returned to agent
# 5. Agent summarizes for user
```

---

### 4.2 API Integration Skills

For skills that call REST APIs (not MCP-wrapped), use the `web_fetch` tool directly in your instructions.

#### Example: Slack Message Automation

```markdown
---
name: slack-notifier
description: Send formatted messages to Slack channels
version: 1.0.0
requires:
  env: [SLACK_BOT_TOKEN]
permissions:
  domains: [slack.com]
---

# Slack Notifier

## How to Send a Slack Message

When asked to notify a Slack channel:

1. Call the web_fetch tool with:
   - URL: `https://slack.com/api/chat.postMessage`
   - Method: POST
   - Headers:
     ```
     Authorization: Bearer ${SLACK_BOT_TOKEN}
     Content-Type: application/json
     ```
   - Body:
     ```json
     {
       "channel": "#engineering",
       "text": "Your message here",
       "blocks": [
         {
           "type": "section",
           "text": {
             "type": "mrkdwn",
             "text": "*Bold text*"
           }
         }
       ]
     }
     ```

2. Check the response:
   - If `ok: true`: Message sent successfully
   - If error: Show the error to user

## Examples

**Simple text message:**
```
User: "Tell #engineering the build passed"
Body:
{
  "channel": "#engineering",
  "text": "✓ Build passed. All tests green."
}
Response: Message sent to #engineering
```

**Formatted message with blocks:**
```
User: "Send a formatted incident report to #incidents"
Body:
{
  "channel": "#incidents",
  "text": "Incident: API response timeout",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Incident Report*\nSeverity: P1\nService: API\nDuration: 5 minutes"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {"type": "plain_text", "text": "View Logs"},
          "url": "https://logs.example.com"
        }
      ]
    }
  ]
}
Response: Report sent to #incidents
```

## Error Handling

Common errors and recovery:
- **Invalid token:** Request fails with `invalid_auth`. Ask user to verify SLACK_BOT_TOKEN.
- **Channel not found:** Error `channel_not_found`. Verify channel name.
- **Rate limited:** Slack returns 429. Wait 60 seconds and retry.
```

---

### 4.3 Trigger-Based Skills

Skills that respond to events.

#### Example: GitHub PR Notification Trigger

```markdown
---
name: github-pr-monitor
description: Monitor GitHub PRs and notify on activity
version: 1.0.0
requires:
  env: [GITHUB_TOKEN]
triggers:
  - type: webhook
    path: /webhook/github
    event: pull_request.opened
  - type: webhook
    path: /webhook/github
    event: pull_request.review_requested
---

# GitHub PR Monitor

## What Triggers This Skill

This skill is invoked automatically when:
1. A new PR is opened in your repo
2. A review is requested on a PR you're involved with

## What It Does

On PR opened:
1. Fetch PR details (title, description, author, changed files)
2. Check if any files match critical paths (security/, core/, etc.)
3. If critical: send high-priority notification
4. Else: send normal notification

On review requested:
1. Fetch PR summary
2. Show changed lines count
3. Suggest which files to review first (by complexity)
4. Send notification with review link

## Configuration

In ~/.openclaw/openclaw.json:

```json
{
  "triggers": {
    "github-pr-monitor": {
      "enabled": true,
      "webhooks": {
        "github": {
          "secret": "your-webhook-secret",
          "url": "https://your-domain.com/webhook/github"
        }
      }
    }
  }
}
```

To set up the webhook on GitHub:
1. Go to repo Settings → Webhooks → Add webhook
2. Payload URL: `https://your-domain.com/webhook/github`
3. Events: Pull requests
4. Secret: Copy from config above
5. Save

## Example Output

```
PR Opened: Add dark mode support
Author: @alice
Files changed: 12 (+234 -45)
Critical files: src/ui/theme.ts ⚠️

This touches the theme system. Tagged as high-priority for review.
```

```

---

### 4.4 Scheduled Skills

Skills that run on a cron schedule.

#### Example: Daily Competitor Monitor

```markdown
---
name: competitor-monitor
description: Daily scrape of competitor websites for changes
version: 1.0.0
schedule: "0 8 * * *"  # 8am daily
requires:
  env: [TELEGRAM_CHAT_ID]
permissions:
  domains: [competitor1.com, competitor2.com]
  capabilities: [network]
---

# Competitor Monitor

**Schedule:** Every day at 8am

## What It Does

1. Scrapes designated competitor websites
2. Compares current version to previous snapshot
3. Highlights changes (new features, pricing, team, etc.)
4. Sends digest via Telegram

## Configuration

Competitors to monitor (customize in SKILL.md):

```yaml
competitors:
  - name: "Competitor A"
    url: "https://competitor-a.com"
    check_elements:
      - selector: ".pricing-table"
        label: "Pricing"
      - selector: ".features-list"
        label: "Features"
  - name: "Competitor B"
    url: "https://competitor-b.com"
    check_elements:
      - selector: ".blog h2"
        label: "Latest blog posts"
```

Set this in env:
```
TELEGRAM_CHAT_ID=123456789
```

## How It Works

Daily at 8am:

1. For each competitor URL:
   - Fetch current HTML
   - Extract key sections (CSS selectors)
   - Compare against snapshot from yesterday
   - Calculate diff

2. Format results:
   ```
   Competitor A Updates:
   - Pricing: Added "Enterprise" tier ($500/mo)
   - Features: New "Collaboration" feature

   Competitor B Updates:
   - Blog: 2 new posts
     - "Advanced Security in 2026"
     - "Q1 Product Roadmap"
   ```

3. Send to Telegram

## Error Handling

- If website is down: Skip and note "Competitor A: unreachable"
- If layout changed: Note "Unable to find pricing section"
- If no changes: Don't send message (silence is success)

## Respecting robots.txt

Before scraping, check robots.txt for:
- User-agent: * (rules that apply to all bots)
- Disallow: paths not to crawl
- Crawl-delay: how long to wait between requests

Example:
```
User-agent: *
Disallow: /admin/
Crawl-delay: 5
```

This means: wait 5 seconds between requests, don't visit /admin/ paths.

---
```

---

### 4.5 Multi-Step Workflow Skills

Skills orchestrating complex, multi-tool processes.

#### Example: Deployment Pipeline Skill

```markdown
---
name: deployment-pipeline
description: Deploy code to production with automated checks
version: 1.0.0
requires:
  env:
    - GITHUB_TOKEN
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    - SLACK_WEBHOOK_URL
permissions:
  domains: [github.com, aws.amazon.com]
  capabilities: [network, exec]
---

# Deployment Pipeline

**Purpose:** Safe, automated deployment from staging to production.

## When to Use

Request deployment:
```
"Deploy main branch to production"
```

## The Pipeline

This skill implements the "blue-green" deployment pattern:

### Step 1: Pre-flight Checks (3 min)
- [ ] Verify main branch is clean (no uncommitted changes)
- [ ] Run full test suite
- [ ] Check if all PRs are merged
- [ ] Verify staging is currently healthy

If any check fails, **STOP** and report the blocker.

### Step 2: Build & Package (5 min)
- [ ] Trigger GitHub Actions to build
- [ ] Wait for build completion
- [ ] Download artifact (Docker image, bundle, etc.)
- [ ] Run smoke tests on artifact

If build fails, **STOP** and show error logs.

### Step 3: Deploy to Green (Blue-Green Strategy) (10 min)
- [ ] Launch new version on "green" infrastructure
- [ ] Run health checks (200 OK on /health)
- [ ] Run synthetic tests (check key flows)
- [ ] Monitor error rates (should be < 0.1%)

If health checks fail, **ROLLBACK** and alert ops.

### Step 4: Traffic Cutover (2 min)
- [ ] Switch load balancer from blue → green
- [ ] Monitor error rates for 5 minutes
- [ ] Check if any critical metrics spike

If errors spike, **ROLLBACK** to blue.

### Step 5: Cleanup (1 min)
- [ ] Log deployment details (timestamp, version, who triggered)
- [ ] Notify team in #deployments Slack channel
- [ ] Archive old blue infrastructure for 24 hours (safety net)

## Configuration

```json
{
  "skills": {
    "deployment-pipeline": {
      "enabled": true,
      "env": {
        "GITHUB_TOKEN": "ghp_...",
        "AWS_ACCESS_KEY_ID": "AKIA...",
        "AWS_SECRET_ACCESS_KEY": "...",
        "SLACK_WEBHOOK_URL": "https://hooks.slack.com/..."
      }
    }
  }
}
```

## Error Handling & Rollback

| Error | Action |
|-------|--------|
| Test suite fails | Stop, show failing tests, ask for fix |
| Build fails | Stop, show error logs, suggest fix |
| Health checks fail | Rollback to blue, investigate |
| Error rate spikes | Rollback to blue, manual review required |
| Slack notification fails | Continue anyway, log for later |

## Example Execution

```
User: "Deploy main to production"

OpenClaw:
✓ Pre-flight checks passed (tests green, all PRs merged)
⏳ Building... (5 minutes)
✓ Build complete, artifacts downloaded
⏳ Deploying to green... (10 minutes)
✓ Health checks passed
✓ Synthetic tests passed (login flow, checkout flow)
⏳ Cutting over traffic...
✓ Traffic switched to green
✓ Error rate stable (0.05%, baseline 0.04%)

**Deployment successful!**
- Deployed version: v2.3.1
- Timestamp: 2026-03-18 14:32 UTC
- Rollback command: "Rollback to blue"

Posted to #deployments channel.
```

## Rollback Command

If something goes wrong post-deployment:

```
User: "Rollback to blue"

OpenClaw:
✓ Switching traffic back to blue
✓ Verifying error rates normal
✓ Green environment preserved for investigation
```

---
```

---

## 5. The ClawHub Ecosystem

### What ClawHub Is

ClawHub is the official public registry of OpenClaw skills, similar to:
- NPM for Node.js packages
- PyPI for Python packages
- GitHub Actions marketplace

**As of Feb 2026:** 13,729+ community skills published.

**Key stats:**
- ~65% wrap MCP servers
- ~36% contain security flaws (per analysis)
- ~8% are explicitly malicious
- ~5,400 are curated in VoltAgent's "awesome" list (higher quality)

### How to Publish Skills to ClawHub

#### Prerequisites
- A GitHub account (must be at least 1 week old)
- A skill folder with SKILL.md
- OpenClaw CLI installed

#### Step 1: Prepare the skill folder

```bash
cd ~/.openclaw/workspace/skills/my-skill

# Create optional README (not required, but good for discoverability)
cat > README.md << 'EOF'
# My Skill

Brief description of what this skill does.

## Installation

```bash
openclaw install my-skill
```

## Usage

Ask your OpenClaw agent: "..."

## Configuration

Set env vars in ~/.openclaw/openclaw.json

## Author

Your name or handle
EOF

# Verify SKILL.md is valid
openclaw validate-skill SKILL.md
```

#### Step 2: Create a GitHub repo (optional, but recommended)

```bash
git init
git add .
git commit -m "Initial skill release"
git remote add origin https://github.com/yourusername/my-skill
git push -u origin main
```

Having the skill on GitHub helps with:
- Version history and auditing
- User feedback via GitHub issues
- Contributions from others
- Trust (public code is more trustworthy)

#### Step 3: Publish to ClawHub

```bash
clawhub publish ~/.openclaw/workspace/skills/my-skill
```

First time publishing? ClawHub will ask you to authenticate via GitHub.

**Output:**
```
✓ Validating skill...
✓ Uploading to ClawHub...
✓ Published: https://clawhub.ai/skills/yourusername/my-skill

Latest version: 1.0.0
GitHub repo (optional): https://github.com/yourusername/my-skill
```

#### Step 4: Verify on ClawHub

Visit https://clawhub.ai/skills/yourusername/my-skill

You'll see:
- Skill metadata (name, author, version)
- SKILL.md preview
- Installation command
- Security analysis results
- User ratings and reviews

---

### Discoverability & Ranking

**How skills get discovered on ClawHub:**

1. **Search:** Users search by name, keywords, category
2. **Curated lists:** VoltAgent maintains an "awesome" list (5,400+ skills)
3. **Trending:** New and popular skills featured on homepage
4. **User reviews:** Rating system (5 stars) affects ranking

**Tips for discoverability:**

- **Good skill name:** `email-triage` (clear) vs. `e-mail-sorting` (awkward) vs. `ai-email` (too generic)
- **Clear description:** "Automatically categorize and prioritize emails by urgency" (good) vs. "Email tool" (vague)
- **Tags:** Add relevant tags in SKILL.md: `email`, `automation`, `productivity`
- **Documentation:** Write a good README in your GitHub repo
- **Examples:** Show the agent working through realistic scenarios
- **Maintenance:** Keep it updated, fix reported bugs

---

### Monetization Options

As of 2026, OpenClaw doesn't have built-in monetization for skills yet. Options:

1. **Free & open-source:** Most skills today. Build trust and reputation.

2. **Premium version on ClawHub (coming soon):** NVIDIA is exploring paid skills where:
   - Free tier: basic functionality
   - Paid tier: advanced features, priority support
   - Revenue share with developer

3. **Enterprise licensing:** Directly license to companies
   - Custom versions with SLA
   - Priority support
   - Example: "Enterprise email triage with archive search"

4. **Services around the skill:** Build a skill, then offer consulting
   - Custom integrations
   - Deployment support
   - Example: Build "Salesforce sync", offer implementation services

5. **Build in public and get hired:** Create impressive skills, get job offers
   - This is currently the most common "monetization" path

---

### Security: The 820+ Malicious Skills Problem

**Reality check:** As of February 2026, Koi Security analysis found ~820 malicious skills in 10,700+ analyzed ClawHub skills (~7.7%).

**Attack types:**
- **Credential theft:** Skills that exfiltrate API keys or environment variables
- **Coin mining:** Skills that use agent's compute to mine cryptocurrency
- **Botnet recruitment:** Skills that compromise the agent and join a botnet
- **Data exfiltration:** Skills that steal user data and send to attacker infrastructure

**How to protect users:**

When publishing your skill, you want to signal that it's **trustworthy**:

1. **Open source:** Publish your skill repo on GitHub
   - Transparency builds trust
   - Users can audit code before installation
   - Shows you have nothing to hide

2. **Security in SKILL.md:** Document your security practices
   ```markdown
   ## Security

   - API keys are never logged or sent to external servers
   - All data is processed locally
   - Network access is limited to [list of domains]
   - No scripts are executed without user consent
   ```

3. **Sign your skill:** As ClawHub rolls out cryptographic signing, sign your releases
   ```bash
   clawhub sign skill my-skill --key ~/.keys/my-skill.pem
   ```

4. **Enable security analysis:** ClawHub runs automated analysis on every skill
   - Checks for suspicious patterns (credential access, network calls, file writes)
   - Reports in the skill's ClawHub page

5. **Respond to security issues:** If users report security concerns, fix quickly and publish a new version
   ```bash
   # Bump version in SKILL.md from 1.0.0 to 1.0.1
   clawhub publish ~/.openclaw/workspace/skills/my-skill
   ```

6. **Get your skill on the VoltAgent curated list:** If your skill is high-quality and secure:
   - Contact VoltAgent on GitHub
   - They'll review and add to https://github.com/VoltAgent/awesome-openclaw-skills
   - This signals quality to users

---

### Best Practices for Publishing

**Before publishing, verify:**

- [ ] SKILL.md is valid YAML (single-line JSON metadata)
- [ ] `version` follows semver (1.0.0, not 1.0 or 1)
- [ ] `name` is lowercase, hyphenated, globally unique
- [ ] All required env vars are documented
- [ ] Permissions block is complete (domains, paths, capabilities)
- [ ] Examples work end-to-end
- [ ] Error messages are clear
- [ ] No hardcoded secrets (API keys, tokens) in code
- [ ] GitHub repo is public (if using one)
- [ ] README explains how to install and use

**After publishing:**

- [ ] Monitor ClawHub page for reviews/issues
- [ ] Respond to user questions
- [ ] Fix bugs within 48 hours
- [ ] Publish security patches immediately
- [ ] Update skill version with each release

---

## 6. Security for Skill Developers

### The Security Landscape

**OpenClaw's attack surface is large:**
- 100K+ instances running (target for attackers)
- Agent has broad access (can send emails, execute code, access cloud infrastructure)
- Skills are executed by the agent (malicious skill = compromised agent)
- Users often run OpenClaw on same machine with production credentials

**Known vulnerabilities:**
- **CVE-2026-25253:** CVSS 8.8 RCE via WebSocket origin bypass
- **CVE-2026-22175:** CVSS 7.9 path traversal in media downloads
- **CVE-2026-22171:** CVSS 6.5 execution approval bypass
- **Prompt injection:** Crafted inputs extract secrets from agent context
- **Malicious skills:** 820+ skills found with malicious payloads

### How to Build Secure Skills

#### 1. **Input Validation**

Always validate data coming from the agent, user input, or external APIs.

```markdown
---
name: data-importer
---

# Data Importer

When importing data from external sources:

1. **Validate file format**
   - Accept only: CSV, JSON, XML
   - Reject: executables, archives, scripts
   - Check file extension AND magic bytes (first few bytes of file)

2. **Validate file size**
   - Max size: 100 MB
   - If larger: reject and ask user to split

3. **Validate schema**
   - For CSV: check header names match expected columns
   - For JSON: validate structure with a schema
   - If invalid: show which fields are wrong

4. **Sanitize input**
   - If using data in SQL: use prepared statements (parameterized queries)
   - If using data in shell commands: quote arguments, escape special chars
   - If using data in HTML: escape HTML entities

**Example:**

```python
import json
from pathlib import Path

def import_users(file_path, max_size=100*1024*1024):
    path = Path(file_path)

    # Validate extension
    if path.suffix.lower() not in ['.csv', '.json']:
        raise ValueError(f"Invalid file type: {path.suffix}")

    # Validate size
    if path.stat().st_size > max_size:
        raise ValueError(f"File too large: {path.stat().st_size} > {max_size}")

    # Validate content
    with open(path) as f:
        if path.suffix == '.json':
            data = json.load(f)
            # Validate schema
            if not isinstance(data, list):
                raise ValueError("JSON must be an array of users")
            for user in data:
                if 'email' not in user:
                    raise ValueError("Missing 'email' field in user record")
                # Validate email format
                if '@' not in user['email']:
                    raise ValueError(f"Invalid email: {user['email']}")

    return data
```

#### 2. **Credential Handling Best Practices**

Never store or transmit credentials in plaintext.

```markdown
## Credential Security

**DO:**
- ✓ Store API keys in environment variables (set by user)
- ✓ Use API key scopes (least privilege)
- ✓ Rotate keys regularly (user responsibility)
- ✓ Pass credentials only over HTTPS
- ✓ Use OAuth 2.1 for user-facing auth flows

**DON'T:**
- ✗ Log API keys (even in debug mode)
- ✗ Store keys in config files or code
- ✗ Share keys across multiple services
- ✗ Use unlimited-scope keys
- ✗ Send keys in URL parameters
```

**Example: Secure Slack integration**

```markdown
---
name: secure-slack-notifier
requires:
  env: [SLACK_BOT_TOKEN]
---

# Secure Slack Notifier

When sending Slack messages:

1. Load SLACK_BOT_TOKEN from environment (not from files)
2. Pass token only in HTTP Authorization header (not in URL)
3. Don't log the token (even for debugging)
4. If token is exposed:
   - Revoke immediately in Slack workspace
   - User must regenerate in ~/.openclaw/openclaw.json
```

#### 3. **Permission Scoping (Least Privilege)**

Declare exactly what your skill needs. Don't ask for more.

```yaml
permissions:
  tools: [web_fetch]  # Only HTTP requests, not exec
  domains: [api.example.com]  # Only this domain, not *
  paths: [~/.myskill/data/]  # Only this directory, not ~
  capabilities: [network]  # Only network, not filesystem exec
```

**Anti-pattern:**
```yaml
permissions:
  tools: [exec, web_fetch]  # Too broad
  domains: ['*']  # Wildcard = can reach any domain
  paths: [~/]  # Can read entire home directory
  capabilities: [network, filesystem, exec]  # All capabilities
```

#### 4. **Output Validation**

Validate data returned from external APIs before passing to agent.

```python
def fetch_user_data(user_id):
    """Fetch user data from API, validate before returning."""
    import json
    from urllib.error import URLError

    try:
        response = web_fetch(
            f"https://api.example.com/users/{user_id}",
            headers={"Authorization": f"Bearer {os.environ['API_KEY']}"}
        )
        data = json.loads(response.body)
    except URLError as e:
        # Don't leak internal error details to agent
        return {"error": "Failed to fetch user"}
    except json.JSONDecodeError:
        return {"error": "Invalid response format"}

    # Validate schema
    required_fields = ['id', 'name', 'email']
    if not all(field in data for field in required_fields):
        return {"error": "Missing required fields"}

    # Sanitize sensitive fields before returning
    return {
        'id': data['id'],
        'name': data['name'],
        'email': data['email']
        # Don't return: password_hash, api_keys, etc.
    }
```

#### 5. **Error Handling**

Don't leak system details in error messages.

```markdown
## Error Messages

**Good:**
```
"Failed to fetch user. Please check your API key and try again."
```

**Bad:**
```
"SQL error: SELECT * FROM users WHERE id=123: UNIQUE constraint failed
Stack trace: [full stack]
API key in header: ghp_xxxxxxxxxxxx"
```

Why? Bad errors expose internal details that help attackers.
```

#### 6. **Audit Logging**

Log important operations for security review.

```python
import logging
from datetime import datetime

def log_security_event(event_type, details):
    """Log security-relevant events."""
    entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "event_type": event_type,
        "details": details
    }

    # Log to file (not console, might be logged elsewhere)
    with open("~/.openclaw/skills/my-skill/security.log", "a") as f:
        f.write(json.dumps(entry) + "\n")

# Usage
log_security_event("auth_attempt", {"username": "alice", "success": True})
log_security_event("permission_denied", {"action": "delete_user", "reason": "insufficient_scope"})
log_security_event("api_error", {"code": 429, "message": "rate_limited"})
```

### Security Review Checklist

Before publishing to ClawHub, review:

**Input Validation**
- [ ] All user inputs are validated
- [ ] File uploads are scanned for type and size
- [ ] JSON/CSV inputs are schema-validated
- [ ] SQL queries use parameterized statements (no string concatenation)

**Credentials**
- [ ] No API keys hardcoded
- [ ] Tokens loaded from environment variables
- [ ] Tokens never logged or printed
- [ ] Token scope is minimal (read-only if possible)
- [ ] Token rotation is documented

**Permissions**
- [ ] `permissions.tools` only lists tools used
- [ ] `permissions.domains` is specific (not `*`)
- [ ] `permissions.paths` is specific (not `~/`)
- [ ] `permissions.capabilities` is minimal

**Output**
- [ ] API responses validated before returning
- [ ] Sensitive fields redacted (passwords, hashes, secrets)
- [ ] Error messages don't leak system details

**Logging & Debugging**
- [ ] Sensitive data not logged
- [ ] Debug output disabled in production
- [ ] Audit log for security-relevant events
- [ ] Log files not world-readable

**Dependencies**
- [ ] No malicious scripts bundled
- [ ] External scripts are validated
- [ ] MCP servers are from trusted sources
- [ ] No supply chain attacks (e.g., typosquatting)

**Documentation**
- [ ] Security practices documented in SKILL.md
- [ ] Known limitations documented
- [ ] Error handling explained
- [ ] Recovery instructions provided

---

## 7. OpenClaw + MCP + Claude Code Integration

### How They Fit Together

| Tool | Layer | Best Use | Example |
|------|-------|----------|---------|
| **Claude Code** | Development | Write/debug code, design architecture | Build a new feature, refactor module |
| **OpenClaw skill** | Automation | Run code on schedule, respond to events | Daily report, CI/CD monitor |
| **MCP server** | Integration | Expose tools to agents | GitHub API, database client |

**Typical workflow:**

```
1. Use Claude Code to write a new service/API
   ↓
2. Wrap service in an MCP server
   ↓
3. Wrap MCP server as OpenClaw skill
   ↓
4. Users install skill and ask agent for automation
   ↓
5. Agent calls MCP tools via skill instructions
   ↓
6. Service executes, returns results
```

### Using OpenClaw for Operational Automation While Claude Code Handles Coding

**Split your work:**

| Task | Tool | Why |
|------|------|-----|
| Design new API | Claude Code | Complex reasoning, iterative development |
| Write service | Claude Code | IDE integration, testing, debugging |
| Wrap in MCP | Claude Code + manual config | Straightforward, reuse MCP template |
| Build automation workflow | OpenClaw skill | Operational task, declarative |
| Deploy service | OpenClaw (via CI/CD skill) | Automated, no human intervention |
| Monitor service | OpenClaw (via monitoring skill) | Continuous, sends alerts |
| Incident response | OpenClaw (via runbook skill) | Fast human feedback, predefined actions |

**Example: Building a Customer Support Chatbot**

**Step 1: Claude Code – Build the backend**
```python
# Use Claude Code to develop:
# - FastAPI service with /chat endpoint
# - Integration with LLM API
# - Database for conversation history
# - Tests for happy path and errors
```

**Step 2: Claude Code – Wrap in MCP**
```
# Use Claude Code to create:
# - mcp/index.js with MCP server
# - Exposes tools: chat(message), get_history(), reset()
# - Implements stdio transport
```

**Step 3: OpenClaw – Build automation skill**
```markdown
# SKILL.md: Customer Support Chatbot

When user asks to start a chat:
1. Load conversation history from MCP: get_history()
2. Send user message via MCP: chat(message)
3. Return response to user
```

**Step 4: OpenClaw – Build monitoring skill**
```markdown
# SKILL.md: Chatbot Health Monitor

Every 5 minutes:
1. Call /health endpoint
2. If response time > 2s: log warning
3. If service down: notify ops on Slack
```

### Shared MCP Servers Between OpenClaw and Claude Code

You can register the same MCP server in both tools.

**Setup:**

Create a central MCP config that both tools read:

```yaml
# ~/.mcp/servers.yaml
github:
  command: node
  args: [~/.mcp/github-mcp/index.js]
  env:
    GITHUB_TOKEN: ${GITHUB_TOKEN}

database:
  command: python3
  args: [~/.mcp/database-mcp/server.py]
  env:
    DATABASE_URL: ${DATABASE_URL}
```

**In Claude Code:**
```
Settings → MCP Servers → Add
Command: python3 ~/.mcp/database-mcp/server.py
Env: DATABASE_URL=...
```

**In OpenClaw:**
```json
{
  "mcp": [
    {
      "name": "database",
      "command": "python3",
      "args": ["~/.mcp/database-mcp/server.py"],
      "env": { "DATABASE_URL": "..." }
    }
  ]
}
```

**Result:** Both Claude Code and OpenClaw can access the same database tools without duplication.

### Building Skills That Bridge Claude Code and OpenClaw

Some skills are particularly effective at bridging the two tools.

#### Example: Code Review + Deployment Orchestration

**Part 1: Claude Code (Development)**
```python
# Claude Code:
# - Analyze PR (fetch diff, files changed)
# - Use LLM to suggest improvements
# - Generate review comment with fixes
```

**Part 2: OpenClaw Skill (Orchestration)**
```markdown
# SKILL.md: Code Review & Deploy

When PR is opened:
1. Ask Claude Code to review (via ACP agent job)
2. Post review comments to GitHub
3. If approved: merge PR
4. If approved: trigger deployment skill

When PR is merged:
1. Notify #engineering on Slack
2. Monitor CI/CD
3. If tests pass: deploy to staging
4. If staging passes: wait for manual promotion to production
```

**Result:** Code review intelligence from Claude Code, but automation & orchestration from OpenClaw.

---

## 8. NemoClaw Considerations

### What NemoClaw Adds Over OpenClaw

NemoClaw is NVIDIA's enterprise-hardened version, announced at GTC 2026.

| Feature | OpenClaw | NemoClaw |
|---------|----------|----------|
| **Core agent** | Yes | Yes + hardened |
| **Sandboxing** | VM-recommended | Native kernel-level |
| **Access control** | None (agent has all permissions) | Least-privilege (per-resource) |
| **Audit logging** | Basic | Full, compliance export |
| **PII protection** | None | Privacy router (automatic) |
| **Policy guardrails** | None | YAML-declarative policies |
| **RBAC** | None | Full role-based access |
| **Enterprise support** | None | 24/7 SLA |

### Security Hardening: Sandbox & Privacy Router

**Kernel-Level Sandbox:**
```
┌──────────────────────────────┐
│ NemoClaw Agent               │
│ (running in isolated VM)      │
└────────────┬─────────────────┘
             │
    ┌────────▼──────────┐
    │ OpenShell Runtime │
    │ - Kernel-level    │
    │   deny-by-default │
    │ - Policy engine   │
    │ - Privacy router  │
    └────────┬──────────┘
             │
┌────────────▼──────────────────┐
│ External Resources            │
│ - Cloud APIs                  │
│ - Databases                   │
│ - File systems                │
│ (isolated access only)        │
└───────────────────────────────┘
```

**Privacy Router:**
The privacy router intercepts agent communications and:
- Detects when agent is sending sensitive data (PII, secrets)
- Keeps sensitive data on local Nemotron models (private)
- Routes complex reasoning to Claude/GPT-4 (cloud)
- Blocks data exfiltration automatically

**Example:**
```
User message: "Show me the salary for employee 12345"
↓
Agent: "I'll fetch salary data..."
↓
Privacy router: "Salary is PII. Keeping on local model."
↓
Local Nemotron: Performs lookup on local database
↓
Privacy router: "OK to return salary to user, not to external API"
↓
User: sees salary
↓
(Cloud services never see the salary value)
```

### YAML Policies for Skill Constraints

Skills can declare policies limiting what they can do:

```yaml
# ~/.nemoclaw/policies/deployment-skill.yaml
policies:
  deployment:
    # Deployments require manual approval
    production_deploy:
      requires_approval: true
      approval_role: ops-lead

    # Staging deploys run freely
    staging_deploy:
      allowed: true

    # Database access is restricted
    database:
      allowed_operations: [read, select]  # No insert/delete
      allowed_tables: [public.*]  # Not sensitive tables
      rate_limit: 100  # queries per minute

    # Network access is restricted
    network:
      allowed_domains: [api.example.com, github.com]
      blocked_domains: [*]  # Deny by default
      allowed_ports: [443]  # Only HTTPS
```

**Skill enforcement:**
When a skill tries to violate a policy, NemoClaw:
1. Blocks the action
2. Logs the attempt
3. Notifies the security team
4. Returns error to skill

### Enterprise Skill Development Practices

If building skills for NemoClaw:

#### 1. **Assume Sandboxing**
- Don't rely on OS-level resource sharing
- Use explicit APIs for inter-process communication
- Don't assume access to /tmp or home directory

#### 2. **Declare Permissions Explicitly**
```yaml
---
name: enterprise-integration
nemoclaw:
  policies:
    network:
      allowed_domains: [api.company.com]
      allowed_ports: [443]
    storage:
      allowed_paths: [/data/skill-cache]
    execution:
      timeout: 5m
      retries: 3
---
```

#### 3. **Handle PII Carefully**
```markdown
## PII Handling

This skill may encounter:
- Customer names (in database)
- Email addresses (from email system)
- Phone numbers (from CRM)

NemoClaw's privacy router will automatically:
- Prevent logging of PII
- Block exfiltration to external APIs
- Keep PII on local models

**Skill responsibility:**
- Use `@pii_sensitive` decorator on data structures
- Minimize PII in agent context
- Use data minimization (fetch only needed fields)
```

#### 4. **Support Policy Queries**
```python
# In your skill, ask about policies:
import nemoclaw

def deploy_database_changes(changes):
    # Check if policy allows database writes
    policy = nemoclaw.get_policy("database")
    if "insert" not in policy.allowed_operations:
        return {"error": "Database writes blocked by policy"}

    # Proceed with deployment
    return deploy(changes)
```

### When to Target OpenClaw vs NemoClaw

| Scenario | Target | Why |
|----------|--------|-----|
| Personal automation, low stakes | OpenClaw | Simpler, no licensing costs |
| Startup, non-sensitive data | OpenClaw | Flexibility, fast iteration |
| Enterprise, regulated industry | NemoClaw | Compliance, sandboxing, audit |
| Production infrastructure access | NemoClaw | Mandatory sandboxing, approval workflows |
| Sensitive customer data | NemoClaw | PII protection, privacy router |
| Mission-critical operations | NemoClaw | SLA support, incident response |

---

## 9. Testing & Debugging Skills

### Local Testing Workflow

**Phase 1: Static validation (no execution)**
```bash
# Validate SKILL.md syntax
openclaw validate-skill ~/.openclaw/workspace/skills/my-skill/SKILL.md

# Should output:
# ✓ Valid YAML metadata
# ✓ Required fields present
# ✓ Version format correct
```

**Phase 2: Mock testing (fake API responses)**

Create a mock API server:
```python
# mock_api.py
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class MockHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/users":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {"users": [{"id": 1, "name": "Alice"}]}
            self.wfile.write(json.dumps(response).encode())

server = HTTPServer(("localhost", 8888), MockHandler)
print("Mock API running on http://localhost:8888")
server.serve_forever()
```

Update your skill to use `localhost:8888`:
```markdown
---
name: test-skill
# Temporarily override API endpoint for testing
test_api_url: "http://localhost:8888"
---
```

Test:
```bash
python mock_api.py &  # Start mock server
openclaw run skill test-skill
```

**Phase 3: Live testing (against real APIs with test data)**

```bash
# Set up test credentials
export GITHUB_TOKEN="ghp_test_xxxx"  # Test token if available

# For real APIs, use test/sandbox environments
# Example: GitHub test org, Slack test workspace, etc.

# Run skill
openclaw run skill my-skill

# Monitor logs
tail -f ~/.openclaw/logs/skill-execution.log
```

### Debugging Skill Execution

**1. Enable verbose logging**

```bash
openclaw start --log-level=debug
```

This shows:
- Skill loading
- Tool calls
- API responses
- Error traces

**2. Inspect memory files**

OpenClaw stores conversation history and state as files:

```bash
ls -la ~/.openclaw/memory/

# Look at conversation history
cat ~/.openclaw/memory/skills/my-skill/history.md

# Look at long-term memory
cat ~/.openclaw/memory/episodic/my-skill.json
```

**3. Monitor network traffic**

```bash
# Use tcpdump to see HTTP requests
sudo tcpdump -i lo -A 'tcp port 443 or tcp port 80' | grep -A5 "POST"

# Or use a local proxy
mitmproxy --mode reverse http://api.example.com:443 -p 8888
# Point skill to localhost:8888
```

**4. Test individual steps**

Instead of running the full skill, test individual tool calls:

```markdown
# Skill: email-notifier

## Debug: Test Slack API

To test Slack message delivery independently:

```bash
# 1. Get a test message
curl -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -d "channel=#test" \
  -d "text=Test message"
```

Expected response:
```json
{"ok": true, "channel": "C1234567", "ts": "1234567890.000100"}
```

If `ok: false`, check the error.
```

### Logging Best Practices

**Good:**
```python
import logging

logging.basicConfig(filename="~/.openclaw/skills/my-skill/execution.log")
logger = logging.getLogger(__name__)

logger.info("Starting skill execution")
logger.info(f"Fetching data for user: {user_id}")  # OK, no secrets
logger.warning("API response slower than expected: 3000ms")
logger.error("Failed to connect to database", exc_info=True)
```

**Bad:**
```python
# Don't log secrets
logger.info(f"Using API key: {os.environ['API_KEY']}")

# Don't log user data unnecessarily
logger.info(f"User data: {full_user_object}")

# Don't log raw errors with stack traces (might expose paths)
logger.error(f"Failed: {str(exception)}")
```

### Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Skill not found` | SKILL.md not in skill directory | Move SKILL.md to `~/.openclaw/workspace/skills/my-skill/` |
| `Invalid YAML metadata` | Metadata is multi-line JSON | Ensure metadata is single-line JSON |
| `Required env var missing` | User didn't set environment variable | Document clearly in SKILL.md; add helpful error message |
| `API call timeout` | Network slow or API down | Add timeout + retry logic |
| `Permission denied` | Skill missing permission declaration | Add to `permissions` block in SKILL.md |
| `Invalid request body` | Tool expects different format | Log raw request/response; compare to API docs |

### Automated Testing Patterns

For complex skills, write automated tests:

```python
# test_skill.py
import unittest
from unittest.mock import patch, MagicMock

class TestEmailTriageSkill(unittest.TestCase):

    @patch('requests.get')
    def test_fetch_inbox(self, mock_get):
        """Test fetching email inbox."""
        mock_get.return_value.json.return_value = {
            "emails": [
                {"from": "alice@example.com", "subject": "Hello"},
                {"from": "spam@spam.com", "subject": "BUY NOW"}
            ]
        }

        emails = fetch_inbox()
        self.assertEqual(len(emails), 2)
        self.assertEqual(emails[0]["from"], "alice@example.com")

    def test_classify_email_urgent(self):
        """Test email classification."""
        email = {
            "subject": "URGENT: Production Down",
            "from": "ops@company.com"
        }
        classification = classify_email(email)
        self.assertEqual(classification, "urgent")

    def test_error_handling_network_timeout(self):
        """Test graceful error handling."""
        with patch('requests.get', side_effect=TimeoutError):
            result = fetch_inbox()
            self.assertIn("error", result)
            self.assertIn("retry", result.get("message", "").lower())

if __name__ == "__main__":
    unittest.main()
```

Run tests:
```bash
python -m unittest test_skill.py -v
```

---

## 10. Real-World Skill Examples

### Example 1: CI/CD Monitor Skill

**Use case:** Watch GitHub Actions, alert on failures via Telegram.

```markdown
---
name: ci-cd-monitor
description: Monitor CI/CD pipelines and alert on failures
version: 1.0.0
author: your-name
requires:
  env:
    - GITHUB_TOKEN
    - TELEGRAM_CHAT_ID
permissions:
  domains: [api.github.com, api.telegram.org]
  capabilities: [network]
schedule: "*/5 * * * *"  # Every 5 minutes
---

# CI/CD Monitor

**Purpose:** Watch GitHub Actions and send alerts to Telegram when builds fail.

**Schedule:** Every 5 minutes during business hours (8am-6pm).

## How It Works

Every 5 minutes:

1. Fetch latest workflow runs from GitHub
   - Use GitHub API to get last 10 runs
   - Filter: only runs from last 30 minutes
   - Status: completed (failed, success, etc.)

2. Compare to last known state
   - If new failures: alert
   - If previous failure now fixed: send "fixed" message
   - If still failing: skip (already alerted)

3. For each failed run:
   - Get failure reason from logs
   - Summarize: which job failed, error snippet
   - Include link to GitHub Actions

4. Send Telegram notification
   - Format: bold status + job name + error + link
   - Include: ⚠️ emoji for failures, ✓ for fixed

## Configuration

```json
{
  "skills": {
    "ci-cd-monitor": {
      "enabled": true,
      "env": {
        "GITHUB_TOKEN": "ghp_...",
        "TELEGRAM_CHAT_ID": "123456789"
      }
    }
  }
}
```

**Get GITHUB_TOKEN:**
1. GitHub Settings → Developer settings → Personal access tokens
2. Create token with scopes: `repo`, `read:actions`
3. Copy and paste into config

**Get TELEGRAM_CHAT_ID:**
1. Send message to your Telegram bot
2. Run: `curl https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates | jq '.result[0].message.chat.id'`

## Error Handling

- **GitHub API down:** Skip check, log error, resume next interval
- **No runs found:** Don't send message (silence is success)
- **Telegram send fails:** Log locally, try again next interval
- **New failure:** Send alert immediately (don't wait 5 min)

## Examples

**Example: Build failure**
```
⚠️ Build Failed
Repository: mycompany/api
Workflow: Test Suite
Job: unit-tests
Branch: main

Error: AssertionError: Expected 200, got 500
File: tests/api_test.py:45

View: https://github.com/mycompany/api/actions/runs/12345
```

**Example: Fixed**
```
✓ Build Fixed
Repository: mycompany/api
Workflow: Test Suite
Status: All tests passing (12s)

Duration: 5 minutes (was failing for 45 minutes)
```

## Limitations

- Only monitors GitHub Actions (not GitLab CI, Jenkins, etc.)
- Requires personal GitHub token (not OAuth)
- Checks every 5 min (not real-time)
- No custom filtering by branch/workflow

## Extending This Skill

To monitor different CI systems:
- Add GitLab CI: fetch from `https://gitlab.com/api/v4/projects/:id/pipelines`
- Add Jenkins: fetch from `https://jenkins.example.com/api/json`
- Add CircleCI: fetch from `https://circleci.com/api/v2/project/...`

---
```

**Complete implementation script (optional):**

```python
# scripts/check_ci.py
#!/usr/bin/env python3
import os
import json
import requests
from datetime import datetime, timedelta

def get_github_runs(repo_owner, repo_name, token):
    """Fetch recent workflow runs from GitHub."""
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs"
    headers = {"Authorization": f"token {token}"}
    params = {
        "per_page": 10,
        "status": "completed"
    }

    response = requests.get(url, headers=headers, params=params)
    if response.status_code != 200:
        return None

    return response.json().get("workflow_runs", [])

def get_failure_details(run_id, token, repo_owner, repo_name):
    """Get logs for a failed run."""
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs/{run_id}/logs"
    headers = {"Authorization": f"token {token}"}

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        # GitHub returns zip, we'd need to unzip and parse
        # For now, return raw response
        return response.text[:500]  # First 500 chars
    return None

def format_telegram_message(run, details):
    """Format a Telegram message."""
    status = "⚠️ FAILED" if run["conclusion"] == "failure" else "✓ PASSED"

    message = f"""
{status}
Repository: {run["repository"]["full_name"]}
Branch: {run["head_branch"]}
Commit: {run["head_commit"]["message"][:50]}

Time: {run["created_at"]}
Duration: {run["run_number"]} seconds

View: {run["html_url"]}
"""
    return message

def send_telegram_alert(message, chat_id, bot_token):
    """Send message via Telegram."""
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    data = {
        "chat_id": chat_id,
        "text": message
    }
    response = requests.post(url, json=data)
    return response.json().get("ok", False)

if __name__ == "__main__":
    token = os.environ.get("GITHUB_TOKEN")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID")

    runs = get_github_runs("mycompany", "api", token)

    for run in runs:
        if run["conclusion"] == "failure":
            details = get_failure_details(run["id"], token, "mycompany", "api")
            message = format_telegram_message(run, details)
            send_telegram_alert(message, chat_id, os.environ.get("TELEGRAM_BOT_TOKEN"))
```

---

### Example 2: Email Triage Skill

```markdown
---
name: email-triage
description: Categorize and prioritize emails, draft responses
version: 1.0.0
requires:
  env:
    - GMAIL_API_KEY
    - OPENAI_API_KEY
permissions:
  domains: [gmail.googleapis.com, openai.com]
  capabilities: [network]
schedule: "0 9 * * 1-5"  # 9am weekdays
---

# Email Triage

**Purpose:** Automatically categorize and prioritize emails, draft responses for routine emails.

**Schedule:** Every weekday at 9am.

## How It Works

Every weekday morning:

1. **Fetch inbox** (last 24 hours, unread only)
   - Use Gmail API with GMAIL_API_KEY
   - Filter: is:unread after:1d

2. **Classify each email** into categories
   - Important: from boss, mentions deadline, marked with star
   - Actionable: question, request, decision needed
   - Informational: announcement, update, FYI
   - Spam: newsletter, marketing

3. **Prioritize** within each category
   - Important + Actionable = P0 (respond immediately)
   - Important = P1 (respond today)
   - Actionable = P2 (respond soon)
   - Informational/Spam = P3 (skim later)

4. **Draft responses** for routine emails
   - If email is asking common question (FAQ):
     - Use ChatGPT to draft response
     - Get email template from knowledge base
     - Include link to detailed docs
   - If email is requesting information:
     - Draft asking for clarification
   - If email is informational:
     - Mark as read, skip

5. **Send summary to Slack**
   - Format: table of emails by priority
   - Include: sender, subject, classification, suggested action
   - For drafted responses: show draft for approval

6. **Optional: Auto-send responses**
   - If marked in config: GMAIL_AUTO_SEND = true
   - Send drafted responses for low-risk emails
   - Still require manual approval for important responses

## Configuration

```json
{
  "skills": {
    "email-triage": {
      "enabled": true,
      "env": {
        "GMAIL_API_KEY": "...",
        "OPENAI_API_KEY": "sk-...",
        "SLACK_WEBHOOK_URL": "https://hooks.slack.com/...",
        "AUTO_SEND": "false"  # Change to "true" to auto-send drafts
      }
    }
  }
}
```

## Error Handling

- **Gmail API fails:** Skip triage, log error, resume next day
- **ChatGPT fails:** Skip draft generation, still categorize emails
- **Slack fails:** Continue, save summary to local file

## Examples

**Example: Daily triage summary**
```
📧 Email Triage Summary (9 emails)

🔴 P0 (Urgent) - 1 email
- From: boss@company.com
- Subject: Feedback on Q2 proposal
- Classification: Important + Actionable
- Action: Respond same day

🟠 P1 (Today) - 2 emails
- From: alice@company.com
  Subject: Can we sync on architecture?
  Draft: "Yes, let's sync this week. How about Wed 2pm?"

- From: client@acme.com
  Subject: Implementation timeline
  Draft: "We're targeting end of March. Will confirm by EOW."

🟡 P2 (Soon) - 3 emails
- From: bob@company.com: Test results ready
- From: updates@product: Feature launch notification
- From: hr@company.com: Benefits renewal reminder

⚪ P3 (Later) - 3 emails
- Newsletter subscriptions, marketing emails
- Archived automatically
```

---
```

---

### Example 3: Competitor Monitor Skill

See section 4.4 (Scheduled Skills) for complete code.

---

### Example 4: Database Query Agent Skill

```markdown
---
name: database-query-agent
description: Natural language SQL queries to PostgreSQL database
version: 1.0.0
requires:
  env:
    - DATABASE_URL
  bins:
    - psql
mcp:
  server: ./mcp/index.js
permissions:
  domains: []
  capabilities: [network]
---

# Database Query Agent

**Purpose:** Ask questions about your database in natural language. The agent translates to SQL.

## How It Works

When you ask a question:

1. **Parse the question**
   - Example: "Show me orders over $1000 from Q1"
   - Agent understands: query orders, filter amount>1000, filter date range

2. **Translate to SQL**
   - Using the database schema (fetched via MCP)
   - Generate: `SELECT * FROM orders WHERE amount > 1000 AND date >= '2026-01-01' AND date < '2026-03-31'`

3. **Execute safely**
   - Run query via MCP server (with timeout)
   - Use parameterized queries (no SQL injection)

4. **Format results**
   - Show results as table
   - Highlight key insights
   - Suggest follow-up questions

## Safe by Default

- **Read-only:** Only SELECT queries allowed
- **No schema changes:** No ALTER/DROP/CREATE
- **Timeout protection:** 5 second query limit
- **Row limit:** Max 1000 rows returned
- **Rate limiting:** 10 queries per minute

To do write operations (INSERT/UPDATE), you must explicitly request:
- "Add new customer: Jane Doe"
- This requires your approval before executing

## Configuration

```json
{
  "skills": {
    "database-query-agent": {
      "enabled": true,
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/mydb"
      }
    }
  }
}
```

Get DATABASE_URL from your database provider:
- Local: `postgresql://localhost:5432/mydb`
- Heroku: `postgres://...` (shown in Heroku dashboard)
- RDS: `postgresql://user:pass@endpoint:5432/db`

## Examples

**Example 1: Simple query**
```
User: "How many customers do we have?"
Agent: SELECT COUNT(*) FROM customers
Result: 1,250 customers
```

**Example 2: Complex query**
```
User: "Which products had the most revenue in March?"
Agent:
SELECT
  product_name,
  SUM(revenue) as total_revenue
FROM sales
WHERE month(date) = 3
GROUP BY product_name
ORDER BY total_revenue DESC
LIMIT 5

Result:
Product A: $52,000
Product B: $41,000
Product C: $38,000
...
```

**Example 3: Write operation (approval required)**
```
User: "Add new customer: John Smith, john@example.com"
Agent:
I'll insert this into the customers table.
Query: INSERT INTO customers (name, email) VALUES ('John Smith', 'john@example.com')

This will create a new record. Approve? [Yes/No]

User: Yes
Agent: ✓ New customer added (ID: 5841)
```

---
```

---

### Example 5: Meeting Notes → Tasks Skill

```markdown
---
name: meeting-to-tasks
description: Transcribe meeting notes, extract action items, create tasks
version: 1.0.0
requires:
  env:
    - OPENAI_API_KEY
    - JIRA_API_KEY
permissions:
  domains: [api.openai.com, jira.example.com]
  capabilities: [network]
---

# Meeting Notes to Tasks

**Purpose:** Turn meeting notes into structured action items and create Jira tickets.

## How It Works

1. **Input:** Meeting notes (text, markdown, or raw transcript)
   - Example: "Discussion about Q2 roadmap. Alice to scope search feature. Bob to setup monitoring. Deadline: March 31."

2. **Extract action items** using AI
   - Parse: who, what, when (deadline)
   - Example:
     ```
     - Alice: Scope search feature (Due: March 31)
     - Bob: Setup monitoring (Due: March 31)
     ```

3. **Create Jira tickets**
   - For each action item:
     - Title: [Person] <action>
     - Assignee: person name
     - Due date: deadline
     - Description: context from meeting
     - Priority: based on deadline urgency

4. **Confirm with team**
   - Show extracted items
   - Ask: "Create these as Jira tickets?"
   - Wait for approval before creating

5. **Send summary to Slack**
   - List created tickets
   - Mention assignees
   - Include due dates

## Configuration

```json
{
  "skills": {
    "meeting-to-tasks": {
      "enabled": true,
      "env": {
        "OPENAI_API_KEY": "sk-...",
        "JIRA_API_KEY": "...",
        "JIRA_DOMAIN": "mycompany.atlassian.net",
        "JIRA_PROJECT": "PROJ"
      }
    }
  }
}
```

## Examples

**Example: Meeting notes**
```
Subject: Q2 Planning
Attendees: Alice, Bob, Carol

Notes:
- Discussed new search feature (customer request, high priority)
- Alice will scope it out by March 31
- Bob will help with performance testing
- Carol to write technical spec (by March 25)
- Need final approval from leadership team
- Stakeholder meeting scheduled for April 1

Action items identified:
1. Alice scope search feature - March 31
2. Bob performance testing plan - March 31
3. Carol technical spec - March 25
```

**Agent output:**
```
Extracted 3 action items:

1. [Carol] Write technical spec for search feature
   Deadline: March 25
   Priority: High (blocks other work)

2. [Alice] Scope search feature
   Deadline: March 31
   Priority: High (customer request)

3. [Bob] Performance testing plan
   Deadline: March 31
   Priority: Medium

Create tickets in PROJ? [Yes/No]

---

Tickets created:
✓ PROJ-1234: [Carol] Write technical spec for search feature
✓ PROJ-1235: [Alice] Scope search feature
✓ PROJ-1236: [Bob] Performance testing plan

Posted to #engineering on Slack.
```

---
```

---

## 11. Skill Development Checklist

Before publishing to ClawHub, verify all items:

### Security
- [ ] No API keys hardcoded (all from env vars)
- [ ] No secrets logged
- [ ] Input validation on all user inputs
- [ ] Input validation on all API responses
- [ ] Permissions block is complete and minimal
- [ ] SQL queries use parameterized statements
- [ ] External scripts validated before execution
- [ ] Error messages don't leak system details
- [ ] Audit logging for security events
- [ ] Credential handling uses OAuth when possible

### Reliability
- [ ] Timeout handling for API calls (5-10s)
- [ ] Retry logic for transient failures (429, timeout)
- [ ] Graceful degradation if non-critical services fail
- [ ] Error messages are actionable
- [ ] Logs are available for debugging
- [ ] State is cleaned up on exit
- [ ] No infinite loops or hangs
- [ ] Max iteration counts on all loops

### Quality
- [ ] SKILL.md is well-documented
- [ ] Examples work end-to-end
- [ ] Limitations are documented
- [ ] Configuration options are documented
- [ ] Error handling is documented
- [ ] README.md in GitHub repo (if published)
- [ ] Version number follows semver
- [ ] Changelog updated
- [ ] Code is readable (comments on complex logic)

### Testing
- [ ] Tested locally with mock data
- [ ] Tested against live APIs (staging/test environment)
- [ ] Error cases tested (API down, timeout, invalid input)
- [ ] Permission scopes tested
- [ ] Concurrent execution tested (if applicable)
- [ ] Large input sizes tested

### Publishing
- [ ] GitHub repo is public
- [ ] SKILL.md validates (no YAML errors)
- [ ] Metadata is single-line JSON
- [ ] Author name/email correct
- [ ] Tags are relevant
- [ ] ClawHub page is reviewed
- [ ] Security analysis results reviewed
- [ ] Examples are accurate

### Post-Launch
- [ ] Monitor ClawHub page for reviews/issues
- [ ] Respond to user questions
- [ ] Fix reported bugs within 48 hours
- [ ] Publish security patches immediately
- [ ] Update skill if OpenClaw changes
- [ ] Maintain backward compatibility (if possible)

---

## Appendix: Complete Skill Manifest Reference

### Full SKILL.md Template

```markdown
---
name: skill-name
description: One-line description of what this skill does
version: 1.0.0
author: your-name
email: your@email.com
homepage: https://github.com/yourname/skill-name
repository: https://github.com/yourname/skill-name
license: MIT
tags: [tag1, tag2, category]
category: automation|integration|workflow|reporting
icon: https://example.com/icon.png

requires:
  bins: [python3, node]
  env:
    - API_KEY
    - DATABASE_URL
  config:
    - some.config.value

permissions:
  tools: [exec, web_fetch]
  paths: [~/.myskill/data, /tmp/work]
  domains: [api.example.com, *.example.com]
  executables: [scripts/run.sh]
  capabilities: [network, filesystem]

triggers:
  - type: cron
    schedule: "0 9 * * 1-5"
  - type: webhook
    path: /webhook/github
    event: pull_request

mcp:
  server: ./mcp/index.js
  language: node

schedule: "0 8 * * *"

nemoclaw:
  policies:
    database:
      allowed_operations: [select]
      rate_limit: 100
    network:
      allowed_domains: [api.example.com]

---

# Skill Title

**Purpose:** One sentence explaining what this skill does and when to use it.

**Trigger:** [How this skill is invoked: on-demand, scheduled, event-triggered]

## What This Skill Does

[2-3 sentences explaining the problem it solves and the value it provides.]

## How to Use

[Step-by-step instructions, in plain English, that teach the agent how to execute this skill.]

### Step 1: [Action]
[Detailed explanation of what should happen.]

### Step 2: [Action]
[Detailed explanation.]

### Step 3: [Result]
[What the outcome should be.]

## Configuration

[All environment variables, config options, and how to set them up.]

### Required Settings

- `API_KEY`: Your API key from [service]. Get it: [instructions]
- `DATABASE_URL`: Connection string for your database

### Optional Settings

- `RATE_LIMIT`: Max API calls per minute (default: 100)
- `TIMEOUT`: Request timeout in seconds (default: 30)

## Examples

### Example 1: [Scenario]

[Show input, agent reasoning, and output.]

```
User: "..."
Agent: "[Internal thinking]"
Result: "[Output]"
```

### Example 2: [Another scenario]

[Another complete example.]

## Error Handling

[How the skill handles common errors.]

| Error | Cause | Recovery |
|-------|-------|----------|
| `API rate limit` | Too many requests | Wait 60s, retry |
| `Invalid auth` | Bad credentials | Check API_KEY, regenerate |
| `Network timeout` | API is slow | Retry up to 3 times |

## Security

[Document security practices.]

- API keys are stored in env vars (not in code)
- Data is processed locally (never sent to untrusted services)
- Allowed domains are limited to: [list]

## Limitations

[Be honest about constraints.]

- Only works with [service], not [other service]
- Max 1000 records per run
- Requires Python 3.8+

## Troubleshooting

### Skill won't run
- Check that all required env vars are set
- Run: `openclaw validate-skill SKILL.md`

### API calls failing
- Verify API key is correct (doesn't show in logs for security)
- Check if API service is down
- Try with test data first

## Advanced

[Optional: advanced customization, extending, contributing.]

---
```

---

## Sources

- [OpenClaw GitHub ACP Documentation](https://github.com/Virtual-Protocol/openclaw-acp)
- [OpenClaw Skills Documentation](https://docs.openclaw.ai/tools/skills)
- [ClawHub Registry](https://github.com/openclaw/clawhub)
- [Agent Client Protocol Guide](https://docs.openclaw.ai/tools/acp-agents)
- [DigitalOcean: What are OpenClaw Skills?](https://www.digitalocean.com/resources/articles/what-are-openclaw-skills)
- [VoltAgent: Awesome OpenClaw Skills](https://github.com/VoltAgent/awesome-openclaw-skills)
- [Building Custom OpenClaw Skills with MCP](https://rebeccamdeprey.com/blog/build-openclaw-skill-with-mcp)
- [OpenClaw Security Best Practices](https://microsoft.com/en-us/security/blog/2026/02/19/running-openclaw-safely-identity-isolation-runtime-risk/)
- [NVIDIA NemoClaw Announcement](https://nvidianews.nvidia.com/news/nvidia-announces-nemoclaw)
- [OpenClaw Testing Documentation](https://docs.openclaw.ai/help/testing)
- [Retry Policy Documentation](https://docs.openclaw.ai/concepts/retry)
- [ClawHub Security Analysis](https://semgrep.dev/blog/2026/openclaw-security-engineers-cheat-sheet/)
- [Plugin Manifest Format](https://www.learnclawdbot.org/docs/plugins/manifest)
- [OpenClaw Skill Development Guide](https://lumadock.com/tutorials/build-custom-openclaw-skills)

---

## Key Takeaways

1. **Skills are simple:** A SKILL.md file with instructions + optional helper scripts/MCPs
2. **65% of skills wrap MCPs:** If you have an MCP server, wrapping it as a skill takes ~5 minutes
3. **Security is critical:** As of March 2026, **1,184 malicious skills confirmed** on ClawHub in the largest supply chain attack targeting AI agent infrastructure. Over 25% of 30,000+ analyzed skills contained at least one vulnerability. Validate inputs, scope permissions, never log secrets, and vet all third-party skills before installation.
4. **ClawHub is where users find skills:** Publish with clear documentation, examples, and an open GitHub repo. Be aware of the ongoing supply chain risk — pin skill versions and verify publisher identity.
5. **Testing matters:** Test locally with mocks, then against staging APIs before publishing
6. **NemoClaw is coming:** Enterprise hardening with sandboxing and PII protection; design skills that'll work in both environments
7. **Combine with Claude Code:** Use Claude Code for service development, OpenClaw skills for automation orchestration
8. **Start simple:** Your first skill doesn't need webhooks or complex logic; a good SKILL.md + clear examples goes far

---

## Related Topics

- [OpenClaw Deep Dive](openclaw-deep-dive.md) — Understanding OpenClaw's architecture, security model, and NemoClaw roadmap
- [Building Custom MCP Servers](building-custom-mcp-servers.md) — Creating MCPs that can be wrapped as OpenClaw skills
- [Best Repos, Skills, Plugins, MCPs](best-repos-skills-plugins-mcps.md) — Finding and evaluating published skills before building

---

## Changelog
| Date | Change | Source |
|------|--------|--------|
| 2026-03-21 | Updated security section: 1,184 malicious skills confirmed on ClawHub (largest AI agent supply chain attack). Updated vulnerability rate from 36% to 25%+ of 30K analyzed skills. Added supply chain risk warning to ClawHub publishing guidance. | Daily briefing 03-21-2026 (Finding #2) |
