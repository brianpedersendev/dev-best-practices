---
name: daily-briefing
description: >
  Generate a daily AI development briefing by researching the latest news, updates, and trends in AI-augmented development. Use whenever it's time for a daily briefing, the user says 'daily briefing', 'what's new in AI dev', 'morning briefing', 'catch me up on AI news', 'generate today's briefing', or at the start of a new work day. Scans for breaking news across AI coding tools (Claude Code, Cursor, Gemini, Copilot, Codex), agent frameworks (LangGraph, CrewAI, OpenClaw, Claude SDK), MCP ecosystem updates, security advisories, and emerging techniques. Produces a structured briefing in the DailyBriefing/ folder format and updates the knowledge base when findings warrant it.
---

# Daily Briefing Generator

Produce a concise, actionable daily briefing on AI-augmented development trends. The briefing surfaces what changed overnight that could affect how we build software — new tools, security issues, framework updates, benchmark results, and ecosystem shifts.

## What This Skill Does

1. **Research** — Searches the web for the latest AI dev news across priority categories
2. **Filter** — Applies the knowledge base quality bar: "Would this change how I build something?"
3. **Write** — Produces a structured briefing in `DailyBriefing/MM-DD-YYYY.md`
4. **Cross-reference** — Checks findings against existing knowledge base entries
5. **Update** — When a finding materially changes existing guidance, updates the relevant topic file and INDEX.md

## Before Starting

Before researching, run these pre-flight checks:

1. **Check for existing briefing today.** Look in `DailyBriefing/` for a file matching today's date. If one exists, ask the user: "A briefing already exists for today. Want to update it with new findings, or skip?"
2. **Find the last briefing date.** List files in `DailyBriefing/` sorted by date. Read the most recent briefing to know what was already covered — avoid repeating findings.
3. **Verify folder exists.** If `DailyBriefing/` doesn't exist, create it.

This skill requires no arguments. When triggered, it runs autonomously using today's date and the current knowledge base state.

## Research Strategy

### Priority Search Categories (in order)

Search each category. Spend more time on categories 1-3, which most directly affect day-to-day development.

**1. Tool Updates & Releases**
- Claude Code, Cursor, Windsurf, Copilot, Codex, Gemini CLI — new features, version bumps, pricing changes
- MCP server releases, major updates, install milestones
- OpenClaw / NemoClaw updates, ClawHub ecosystem changes
- Agent framework releases (LangGraph, CrewAI, AG2, Mastra, Claude Agent SDK)

**2. Security Advisories**
- CVEs affecting AI dev tools, MCP servers, agent frameworks
- Supply chain attacks (ClawHub skills, npm packages wrapping AI, malicious MCP servers)
- Prompt injection research, new attack vectors
- Data leakage incidents involving AI coding tools

**3. Benchmarks & Research**
- SWE-bench, HumanEval, and other coding benchmark results
- Academic papers on AI code quality, reliability, security
- Industry reports on AI dev adoption, productivity, defect rates
- New evaluation techniques or metrics

**4. Ecosystem & Business**
- Acquisitions, partnerships, funding rounds affecting AI dev tooling
- Enterprise adoption signals (Fortune 500, government, regulated industries)
- Open-source milestones (star counts, contributor growth, foundation governance)
- Pricing changes, new subscription tiers, API cost updates

**5. Emerging Patterns**
- New development workflows or patterns gaining traction
- Novel multi-agent architectures with production validation
- Context management breakthroughs
- New categories of tools (not just incremental updates)

### Search Queries

Run at least 8-10 web searches covering the categories above. Adapt queries based on what's trending. Example queries:

- `AI coding tools news [today's date]`
- `Claude Code update OR Cursor update OR Copilot update [this week]`
- `MCP server security vulnerability 2026`
- `AI code generation benchmark results [this month]`
- `AI developer tools acquisition funding [this week]`
- `multi-agent framework release [this month]`
- `AI coding reliability security research [this month]`
- `OpenClaw NemoClaw update [this month]`

**Important:** Use today's actual date in searches to get fresh results. Vary queries if initial results are stale or irrelevant. Follow leads — if one result mentions a major announcement, search for that specifically.

### Source Reliability

Prioritize these sources when results conflict:
- **Tier 1 (primary):** Official blogs (Anthropic, OpenAI, Google, GitHub, Cursor), CVE databases, peer-reviewed papers
- **Tier 2 (strong):** Reputable tech press (The Verge, Ars Technica, TechCrunch, Bloomberg), well-sourced blog posts with citations
- **Tier 3 (corroborate):** Developer blogs, Reddit threads, X/Twitter — useful for signals but verify claims before including

Always include source URLs. Never report something without a source.

## Quality Filter

Before including a finding in the briefing, it must pass at least one of these gates:

1. **Actionable today** — Would a developer change their tool setup, workflow, or architecture based on this?
2. **Security-relevant** — Does this affect the security posture of AI-augmented development?
3. **Trend confirmation** — Does this validate or contradict an existing recommendation in the knowledge base?
4. **Significant milestone** — Is this a measurable inflection point (10x growth, major acquisition, new standard)?

**Cut ruthlessly.** A briefing with 3 high-signal findings beats one with 8 mediocre items. Target 3-5 findings per briefing.

## Briefing Format

Write to `DailyBriefing/MM-DD-YYYY.md` using this exact format:

```markdown
# Daily AI Dev Briefing — [Month Day, Year]

## Top [N] Findings

### 1. [Headline — specific and descriptive]
**Impact: [Critical/High/Medium/Low]** | Category: [Tool Ecosystems/Security/Dev Workflows/Agent Architectures/MCP Ecosystem/Emerging]

[2-4 sentences: what happened, with specific numbers and details. No vague summaries.]

**Why it matters:** [1-2 sentences connecting this to practical development decisions. Reference existing knowledge base entries if relevant.]

Sources: [source name](URL), [source name](URL)

---

### 2. [Next finding...]
[Same format]

---

[Repeat for each finding]

## Knowledge Base Updates

| File Updated | What Changed | Why |
|-------------|-------------|-----|
| [file path] | [specific change made] | [which finding triggered it] |

[Or "No updates warranted today." if findings don't change existing guidance.]

### Git Status
Pending commit — see below.
```

### Impact Rating Guide

- **Critical** — Requires immediate action (active security vulnerability, tool breaking change, data breach)
- **High** — Changes recommendations or tool selection within the week
- **Medium** — Worth knowing, may affect decisions in the next month
- **Low** — Informational, confirms existing direction or is early-stage

## Knowledge Base Cross-Reference

After writing the briefing, check each finding against the knowledge base.

**How to cross-reference:** Read INDEX.md to see all existing topics. For each finding, search `docs/topics/` for files covering the relevant area (e.g., a Cursor update → search for `cursor` in topic filenames and content). Open matching files and check whether the finding changes their guidance.

### When to Update Existing Files

Update a topic file when a finding:
- **Contradicts** existing guidance (e.g., a tool's benchmark score changed significantly)
- **Extends** existing data (e.g., MCP server count grew from 21K to 25K)
- **Adds a critical warning** (e.g., new CVE for a recommended tool)
- **Changes a recommendation** (e.g., a previously-recommended framework was abandoned)

### When NOT to Update

Don't update topic files for:
- Minor version bumps that don't change functionality
- Rumors or unconfirmed reports
- Findings that are interesting but don't change any guidance
- News that's already covered adequately

### How to Update

1. Make the specific change in the topic file
2. Add a datestamp comment near the change: `<!-- Updated YYYY-MM-DD: [reason] -->`
3. Log the update in the briefing's "Knowledge Base Updates" table
4. If the change affects INDEX.md descriptions, update INDEX.md too

## After Generating

1. **Present the briefing** to the user with a brief summary
2. **Highlight any Critical or High impact findings** that need immediate attention
3. **List knowledge base updates made** (if any)
4. **Suggest follow-up actions** if warranted (e.g., "The new MCP security advisory means we should audit our MCP server configs")

## Handling Slow News Days

Some days have no significant AI dev news. That's fine. Options:

- **Write a shorter briefing** (1-2 findings) if there's anything worth noting
- **Skip the briefing** and tell the user: "No significant AI dev news today. The last briefing from [date] is still current."
- **Use the time for a mini-review** — pick one "Watching" item from INDEX.md and check for updates

Never pad a briefing with low-quality findings just to fill space.

## Integration with Other Skills

- **topic-deep-dive:** If a finding reveals a topic that should have a full guide (e.g., a new framework reaching production maturity), note it in the briefing's follow-up actions and suggest running the topic-deep-dive skill.
- **knowledge-review:** If the briefing surfaces multiple stale data points across different topic files, suggest running knowledge-review for a systematic audit instead of patching files one at a time.
- **project-scaffold / project-research:** If a finding changes tooling recommendations (new MCP server, deprecated framework), note that existing project scaffolds may need updating.

## Anti-Patterns

- **Reporting hype as news** — "Company X says their tool is revolutionary" is marketing, not a finding. Look for verifiable claims.
- **Stale results** — If search results are all >7 days old for a category, note it and move on. Don't present old news as new.
- **Missing sources** — Every finding needs at least one URL. "I heard that..." is not acceptable.
- **Ignoring the knowledge base** — Always cross-reference. The briefing's value comes from connecting new information to existing guidance.
- **Over-updating** — Not every finding warrants a knowledge base update. Most don't. Only update when guidance materially changes.
- **Burying the lead** — Put the most impactful finding first. If there's a security advisory, it goes at the top regardless of category.
