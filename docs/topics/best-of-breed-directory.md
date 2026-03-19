# Best of Breed Directory: AI Dev Tools

**Last Updated:** 2026-03-18
**Research Scope:** Production-ready, actively maintained, measurably impactful tools for AI-augmented development
**Audience:** Developers integrating Claude Code, Cursor, Gemini, and agentic workflows into their stack

---

## How This Directory Works

This is a **ruthlessly selective directory** of essential AI dev tools, not a comprehensive list. Every entry meets three criteria:
1. **Active maintenance** — commits in 2025-2026
2. **Real adoption** — GitHub stars, enterprise backing, or FastMCP usage metrics
3. **Measurable impact** — solves a specific pain point that developers report

**Tier System:**
- **Tier 1: Essential Foundation** — Set up first regardless of tech stack (the base 10 tools)
- **Tier 2: Stack-Specific** — High-impact additions based on your role/domain
- **Tier 3: Specialized** — Add when you need them for specific tasks

For each entry: Name, repo URL, stars/activity, one-line what-it-does, setup command, and one-sentence why-it-matters.

---

## Tier 1: Essential Foundation (Set Up First)

These 10 tools form the base layer every developer should have. They're foundational for any AI-augmented workflow.

### MCP Servers (The Big 4)

| Name | Repo | Stars | Last Active | Setup | What It Does | Why It Matters |
|------|------|-------|-------------|-------|-------------|----------------|
| **Filesystem** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) | Official | 2026 | `npx -y @modelcontextprotocol/server-filesystem /path` | Read, write, edit, search local directories securely | Foundation for local dev work — Claude/Cursor can manipulate your codebase |
| **Git** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/git) | Official | 2026 | `npx -y @modelcontextprotocol/server-git /path/to/repo` | Diff, log, commit, branch, tag operations | Essential for autonomous git workflows; patched Jan 2026 (CVE-2025-68143/4/5) |
| **Sequential Thinking** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking) | Official | 2026 | `npx -y @modelcontextprotocol/server-sequential-thinking` | Multi-step problem decomposition and reflective reasoning | Transforms Claude from code generator to thoughtful partner on complex tasks |
| **Context7** | [upstash/context7](https://github.com/upstash/context7) | Official | 2026 | Via npm/Docker | Injects version-specific API docs into context; dominates FastMCP #1 by 2x margin | 11,000+ views on FastMCP because docs are always current — solves the "stale docs" problem |

### Database Access (Pick 1)

| Name | Repo | Setup | What It Does | Why It Matters |
|------|------|-------|-------------|----------------|
| **PostgreSQL** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/postgres) | `npx -y @modelcontextprotocol/server-postgres` | Query, schema management, migrations | Production standard; replaces manual DB interactions |
| **SQLite** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/sqlite) | `npx -y @modelcontextprotocol/server-sqlite /path/to/db.sqlite` | Local database access | Fast local dev; zero external dependencies |
| **Supabase** | [supabase-community/supabase-mcp](https://github.com/supabase-community/supabase-mcp) | Docker or npm | 20+ tools for end-to-end Postgres management | Official support; 9+ community variants show ecosystem maturity |

### Code & GitHub Integration

| Name | Repo | Setup | What It Does | Why It Matters |
|------|------|-------|-------------|----------------|
| **GitHub MCP** | [github-mcp-server](https://github.blog/changelog/2025-04-04-github-mcp-server-public-preview/) | Via GitHub Marketplace | Read/search repos, list PRs, issues, review code, automate workflows | GitHub's official Go rewrite (April 2025) — preferred over Anthropic's original |

### Browser Automation

| Name | Repo | Stars | Setup | What It Does | Why It Matters |
|------|------|-------|-------|-------------|----------------|
| **Playwright MCP** | [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) | 2.4K | Via npm | Browser automation, UI testing, accessibility checks | #2 on FastMCP (6,000+ views); 83% accuracy, 7 sec/run; deterministic interactions |

### Essential Claude Code Skills

| Name | Repo | Installation | What It Does | Why It Matters |
|------|------|--------------|-------------|----------------|
| **Official Skills** | [anthropics/skills](https://github.com/anthropics/skills) | `/plugin marketplace add anthropics/skills` | Official, Anthropic-managed skills directory | Source of truth; skills are model-invoked, auto-discovered |
| **Frontend Design** | [anthropics/skills](https://github.com/anthropics/skills) | Via official marketplace | Design system + philosophy before code | 277,000+ installs (Mar 2026); ensures aesthetic intent, not default AI choices |
| **Superpowers** | [obra/superpowers](https://github.com/obra/superpowers) | Via Cursor Marketplace (Feb 2026+) | TDD, debugging, collaboration patterns | Accepted into Anthropic marketplace Jan 2026; enforces Red-Green-Refactor cycle |

### Cursor Integration

| Name | Where to Get | What It Does | Why It Matters |
|------|--------------|-------------|----------------|
| **Cursor Marketplace Plugins** | [cursor.com/marketplace](https://cursor.com/marketplace) | Bundles of MCP servers, skills, subagents, hooks, rules | Simplifies setup; featured partners include Amplitude, AWS, Figma, Linear, Stripe |
| **.mdc Rules Format** | [sanjeed5/awesome-cursor-rules-mdc](https://github.com/sanjeed5/awesome-cursor-rules-mdc) | Project-scoped coding standards (replaces legacy .cursorrules) | Cursor 2026+ format; 879+ community rules available; better scoping than root files |

---

## Tier 2: Stack-Specific High Impact

### Full-Stack Web Developer

| Category | Tool | Repo | Why It Matters |
|----------|------|------|----------------|
| **Testing** | Playwright MCP | [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) | AI-orchestrated testing; deterministic browser interactions; 7 sec/run @ 83% accuracy |
| **Database** | PostgreSQL MCP | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/postgres) | Full-stack Postgres management; migrations, schema, queries |
| **Design Handoff** | Figma MCP | [figma/mcp-server-guide](https://github.com/figma/mcp-server-guide) | Read design tokens, component structures, layout data; design → code without translation |
| **Skills** | TDD + Git + Testing | [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) | 50+ verified skills for web dev workflows |
| **.mdc Rules** | Next.js/React/TypeScript | [awesome-cursor-rules-mdc](https://github.com/sanjeed5/awesome-cursor-rules-mdc) | Framework-specific rules for your stack |

### Backend / API Developer

| Category | Tool | Repo | Setup | Why It Matters |
|----------|------|------|-------|----------------|
| **Database Ops** | DBHub Multi-DB | MCP Registry | Via Docker | Single MCP for Postgres, MySQL, SQLite, DuckDB; token-efficient (2 tools) |
| **API Documentation** | Context7 | [upstash/context7](https://github.com/upstash/context7) | Via npm | Version-specific API docs always current; #1 on FastMCP |
| **Testing** | Test Runner MCP | MCP Registry | Via npm | Unified interface: Pytest, Jest, Go, Flutter; multi-framework consistency |
| **Git Automation** | Git MCP | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/git) | npx command | Autonomous git workflows; critical for CI/CD agents |
| **Skills** | SQL Optimization + Testing | [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | 192+ verified skills covering engineering workflows |

### Frontend Developer

| Category | Tool | Repo | Why It Matters |
|----------|------|------|----------------|
| **Design System** | Figma MCP | [figma/mcp-server-guide](https://github.com/figma/mcp-server-guide) | Extract tokens, component structures, exact CSS variable names |
| **Browser Testing** | Playwright MCP | [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) | AI-orchestrated accessibility checks, visual testing, UI interactions |
| **Semantic Design** | Figma Console MCP | [southleft/figma-console-mcp](https://github.com/southleft/figma-console-mcp) | Best for enterprise design systems with 100+ components |
| **Skills** | Design Handoff + Component Generation | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | Productivity-focused skills for design-to-code workflows |

### DevOps / Platform Engineer

| Category | Tool | Repo | Why It Matters |
|----------|------|------|----------------|
| **Kubernetes** | AWS EKS MCP | [awslabs/mcp-servers](https://awslabs.github.io/mcp/servers/) | Natural language K8s cluster management; resource operations, troubleshooting |
| **Container Deployment** | Docker MCP Catalog | [Docker Hub](https://hub.docker.com/mcp) | 100+ discoverable MCP servers; integrates Grafana, Kong, Neo4j, Pulumi, Heroku |
| **Infrastructure Docs** | AWS Documentation MCP | [awslabs/mcp](https://awslabs.github.io/mcp/servers/aws-documentation-mcp-server) | Real-time AWS API docs injection; always up-to-date examples |
| **IaC** | Terraform MCP (tfmcp) | FastMCP | Rust-based; read configs, analyze plans, apply, manage state |
| **Skills** | Infrastructure-as-Code + K8s | [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | Verified skills for infrastructure engineering |

### Mobile Developer

| Category | Tool | Repo | Why It Matters |
|----------|------|------|----------------|
| **Mobile Automation** | Appium MCP | [mcp-appium-gestures](https://github.com/mcp-appium-gestures) | Mobile gesture automation; complex interaction orchestration without manual scripting |
| **Testing** | Test Runner MCP | MCP Registry | Unified interface: Flutter, Go test, and platform-specific runners |

### Data Engineer

| Category | Tool | Repo | Why It Matters |
|----------|------|------|----------------|
| **Multi-DB Access** | DBHub | MCP Registry | Single MCP for Postgres, MySQL, SQLite, DuckDB; query execution, schema management |
| **Vector Search** | MongoDB MCP | MCP Registry | Vector index support (2026 update); essential for RAG agents |
| **Persistent Memory** | Rag Memory MCP | MCP Registry | Knowledge graph + vector search, event-sourced, git-based versioning |
| **Local Semantics** | RAG Context MCP | MCP Registry | Local vector storage, semantic search, persistent memory for agents |

---

## Tier 3: Specialized Tools

### Testing & QA

| Name | Repo | What It Does | When to Use |
|------|------|-------------|------------|
| **Playwright MCP** | [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) | Browser automation with accessibility snapshots | End-to-end testing, UI validation |
| **Test Runner MCP** | MCP Registry | Unified Pytest, Jest, Go, Flutter runners | Multi-framework consistency |
| **Appium MCP** | [mcp-appium-gestures](https://github.com/mcp-appium-gestures) | Mobile gesture automation | Mobile app testing |

### Code Review & Security

| Name | Repo | What It Does | Why It Matters |
|------|------|-------------|----------------|
| **GitHub MCP** | [github-mcp-server](https://github.blog/changelog/2025-04-04-github-mcp-server-public-preview/) | PR review, issue automation, code search | Integrate code review into AI workflows |
| **Git MCP** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/git) | Diff analysis, commit history inspection | Autonomous security-focused analysis |

### Documentation & Knowledge

| Name | Repo | Stars | What It Does | Why It Matters |
|------|------|-------|-------------|----------------|
| **Context7** | [upstash/context7](https://github.com/upstash/context7) | Official | Version-specific code docs injection | Prevents hallucination from outdated docs |
| **Firecrawl MCP** | [firecrawl/firecrawl-mcp-server](https://github.com/firecrawl/firecrawl-mcp-server) | 2.4K | Web scraping with real Chrome; 83% accuracy, 7 sec avg | Production web access for AI; handles JS, anti-bot, dynamic content |
| **Web Scraping MCP** | [MaitreyaM/WEB-SCRAPING-MCP](https://github.com/MaitreyaM/WEB-SCRAPING-MCP) | Community | crawl4ai integration, LLM-based extraction | Lower cost; local-first alternative to Firecrawl |

### Communication & Productivity

| Name | Repo | Tools | Why It Matters |
|------|------|-------|----------------|
| **Slack MCP** | [Slack Platform](https://slack.com/blog/news/powering-agentic-collaboration) | 47 workspace tools | Native MCP support; agents can post, read reactions, list channels |
| **Linear MCP** | [KlavisAI](https://www.klavis.ai/mcp-server-connections/linear--notion--slack) | Issue creation, status updates, PR linking | Link discussions to work items; update tickets from chat |
| **Notion MCP** | Community ecosystem | Page/database reads | Knowledge base access for agents |
| **Google Workspace MCP** | [Google Platform](https://workspace.google.com/blog/product-announcements/ai) | 200+ tools via Discovery Service (Mar 2026) | Full Workspace access; dynamically discovers all APIs |

### Agent Orchestration & Multi-Agent

| Name | Repo | Type | When to Use | Key Features |
|------|------|------|------------|--------------|
| **Ruflo** | [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | Claude-focused | Deploy 60+ Claude agents in coordinated swarms | Self-learning, fault-tolerant consensus, MCP-native, Claude Code integration |
| **Swarms** | [kyegomez/swarms](https://github.com/kyegomez/swarms) | Enterprise | Production multi-agent systems | Hierarchical swarms, parallel pipelines, graph-based networks, dynamic composition |
| **Agency Swarm** | [VRSEN/agency-swarm](https://github.com/VRSEN/agency-swarm) | OpenAI-based | Multi-agent collaboration | Built on OpenAI Agents SDK; orchestrates specialized agent teams |
| **LangGraph** | [langchain-ai/langgraph](https://github.com/langchain-ai/langgraph) | Framework agnostic | Complex agent workflows | State graphs, interruption, streaming; works with Claude, OpenAI, Gemini |
| **CrewAI** | [joaomdmoura/crewai](https://github.com/joaomdmoura/crewai) | Agent framework | Rapid prototyping | Task-focused agents, delegable workflows, memory integration |

**Important Note:** OpenAI deprecated Swarm (Feb 2026) in favor of OpenAI Agents SDK. For Claude-native stacks, prefer Ruflo or LangGraph.

### Observability & Monitoring

| Name | Repo | What It Does | Why It Matters |
|------|------|-------------|----------------|
| **Datadog MCP** | Cursor Marketplace | Query logs, metrics, traces, dashboards | Monitor AI agent execution in production |
| **OpenTelemetry (Agent Conventions)** | [open-telemetry/semantic-conventions](https://github.com/open-telemetry/semantic-conventions) | Standardized agent metrics | Agent-scale observability standards in development |

---

## Quick Setup Guides

### Add MCP to Claude Desktop

Edit `~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/codebase"]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git", "/path/to/repo"]
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7"]
    }
  }
}
```

Restart Claude Desktop after editing.

### Add Skills to Claude Code

```bash
# Add official marketplace
claude code /plugin marketplace add anthropics/skills

# Or install specific skills
claude code /skill add github:ComposioHQ/awesome-claude-skills
```

### Add Plugins to Cursor (Feb 2026+)

Cursor menu → Plugins → Browse Marketplace → Search & Install:
- Superpowers (TDD, debugging, collaboration)
- AWS (infrastructure)
- Figma (design tokens)
- Linear (issue tracking)
- Datadog (observability)

Or in Cursor settings, edit plugins JSON:

```json
{
  "plugins": [
    "cursor/superpowers",
    "aws/developer-tools",
    "figma/design-tokens"
  ]
}
```

### Add .mdc Rules to Project

Create `.cursor/.mdc` in your project root:

```markdown
# Cursor Rules for [Project Name]

## Language & Framework
- Use TypeScript strict mode
- Follow Next.js App Router patterns
- Use React 19+ hooks

## Code Style
- 2-space indentation
- ESLint + Prettier (configured in .eslintrc.json)
- No single-letter variable names except for loops

## Testing
- Write tests before implementation (TDD)
- Use Vitest for unit tests
- Use Playwright for E2E tests

## Architecture
- Feature-based directory structure
- Separate concerns: components, hooks, utils
- No circular dependencies

## AI-Specific
- Always prefer explicit types over `any`
- Comment WHY, not WHAT (AI can read code)
- Use skills: [tdd, debugging, git-workflows]
```

---

## Awesome Lists & Discovery

Use these to find and stay updated on new tools:

### Official Registries (Primary Sources)

| Name | URL | Coverage | Updated | Notes |
|------|-----|----------|---------|-------|
| **MCP Registry** | [modelcontextprotocol.info/registry](https://modelcontextprotocol.info/tools/registry/) | Official MCP servers | 2026 | Community-owned, Linux Foundation backed |
| **Docker MCP Catalog** | [hub.docker.com/mcp](https://hub.docker.com/mcp) | 100+ discoverable MCPs | 2026 | Integrates Grafana, Kong, Neo4j, Pulumi, Heroku |
| **Anthropic Skills** | [anthropics/skills](https://github.com/anthropics/skills) | Official skills | 2026 | Source of truth for Claude skills |
| **Cursor Marketplace** | [cursor.com/marketplace](https://cursor.com/marketplace) | Cursor plugins | 2026 | Plugins, integrations, rules |

### Awesome Lists (Community Curated)

| Name | Repo | Coverage | Stars | Notes |
|------|------|----------|-------|-------|
| **awesome-mcp-servers** | [punkpeye/awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers) | Comprehensive MCP list | 83K+ | Primary reference; actively maintained |
| **awesome-mcp-servers** | [wong2/awesome-mcp-servers](https://github.com/wong2/awesome-mcp-servers) | Curated MCP protocols | Active | Community contributions |
| **awesome-cursorrules** | [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) | 50+ framework rules | Growing | Primary Cursor rules reference |
| **awesome-cursor-rules-mdc** | [sanjeed5/awesome-cursor-rules-mdc](https://github.com/sanjeed5/awesome-cursor-rules-mdc) | 879+ .mdc files | Active | Modern Cursor 2026+ format |
| **awesome-claude-skills** | [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) | 50+ verified skills | Active | TDD, debugging, git workflows |
| **awesome-claude-code** | [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | Skills, hooks, commands | Meta-focused | Comprehensive tooling ecosystem |
| **awesome-agent-skills** | [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | 500+ skills | Largest | Works with Codex, Antigravity, Gemini CLI |

### Performance Benchmarks

| Name | URL | Metric | Updated |
|------|-----|--------|---------|
| **FastMCP Leaderboard** | [fastmcp.me/blog](https://fastmcp.me/blog/top-10-most-popular-mcp-servers) | Real usage data, views, installs | Weekly |
| **MCP Market** | [mcpmarket.com/leaderboards](https://mcpmarket.com/leaderboards) | Top 100 MCP servers | Daily |

---

## Maintenance & Staleness Indicators

### Quarterly Review Checklist

- [ ] Check GitHub stars for top entries — trending up or down?
- [ ] Verify last commit date — is it recent (< 3 months)?
- [ ] Search FastMCP/MCP Market — usage metrics changed?
- [ ] Read GitHub issues/PRs — active development or stalled?
- [ ] Check official registries (MCP Registry, Cursor Marketplace) — tools still listed?
- [ ] Look for CVEs — any security updates required?

### Red Flags (Deprecation Indicators)

| Signal | Action |
|--------|--------|
| **No commits in 3+ months** | Move to "watch" list; verify there's an active fork/replacement |
| **GitHub issues pile up (50+)** | Tool may be in maintenance mode; check for alternatives |
| **Security CVE without fix** | Remove from Tier 1; add deprecation note |
| **Official deprecation notice** | Remove immediately; document replacement |
| **Community consensus shifts** | Update based on adoption metrics (FastMCP, stars, forks) |

### Tools Removed in 2026

- **OpenAI Swarm (Feb 2026)** → Replaced with OpenAI Agents SDK
- **Legacy .cursorrules format** → Migrated to .mdc
- **Unpatched Git MCP** → Requires update to 2025-12-18+ versions (CVE-2025-68143/4/5)

---

## What NOT to Use in 2026

| What | Why | Use Instead |
|------|-----|-------------|
| **OpenAI Swarm** | Deprecated Feb 2026 | OpenAI Agents SDK, Agency Swarm, Ruflo for Claude |
| **Legacy .cursorrules** | Replaced by .mdc format | Migrate to `.cursor/.mdc` |
| **Unpatched Git MCP** | CVEs in prod (Jan 2026) | Update to mcp-server-git 1.0.0-rc.1+ |
| **Context dumping in MCP responses** | 98% token waste | Use filesystem routing instead |
| **RAG without semantic search** | Inaccurate retrieval | Rag Memory MCP, Qdrant, or vector databases |

---

## Last Updated

**Date:** 2026-03-18
**Methodology:** GitHub stars, FastMCP usage metrics, commit activity, enterprise adoption, developer testimonials
**Next Review:** 2026-06-18

---

## Sources

### Official Repositories & Registries
- [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) — Official MCP reference implementations
- [anthropics/skills](https://github.com/anthropics/skills) — Official Claude Code skills
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — Official Claude plugins marketplace
- [modelcontextprotocol.info/registry](https://modelcontextprotocol.info/tools/registry/) — Official MCP servers registry
- [hub.docker.com/mcp](https://hub.docker.com/mcp) — 100+ discoverable MCP servers
- [cursor.com/marketplace](https://cursor.com/marketplace) — Cursor plugins marketplace

### Awesome Collections & Discovery
- [punkpeye/awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers) — Comprehensive MCP list (83K+ stars)
- [wong2/awesome-mcp-servers](https://github.com/wong2/awesome-mcp-servers) — Curated MCP protocols
- [sanjeed5/awesome-cursor-rules-mdc](https://github.com/sanjeed5/awesome-cursor-rules-mdc) — 879+ .mdc cursor rules
- [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) — 50+ framework cursor rules
- [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) — 50+ verified Claude skills
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — Skills, hooks, commands ecosystem
- [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) — Productivity-focused skills
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) — 500+ verified agent skills
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) — 192+ multi-role skills

### Key Blog Posts & Research
- [FastMCP — Top 10 Most Popular MCP Servers (2026)](https://fastmcp.me/blog/top-10-most-popular-mcp-servers)
- [FastMCP — Most Popular MCP Tools in 2026](https://fastmcp.me/blog/most-popular-mcp-tools-2026)
- [Firecrawl — Best MCP Servers for Developers](https://www.firecrawl.dev/blog/best-mcp-servers-for-developers)
- [Cursor Blog — Marketplace Launch & Plugins (Feb 2026)](https://cursor.com/blog/marketplace)
- [Cursor Blog — New Plugins (March 2026)](https://cursor.com/changelog/03-11-26)
- [Anthropic — Donating MCP to Linux Foundation (Dec 2025)](https://www.anthropic.com/news/donating-the-model-context-protocol-and-establishing-of-the-agentic-ai-foundation)
- [GitHub Blog — MCP Joins Linux Foundation (2026)](https://github.blog/open-source/maintainers/mcp-joins-the-linux-foundation-what-this-means-for-developers-building-the-next-era-of-ai-tools-and-agents/)
- [GitHub Changelog — GitHub MCP Server Public Preview (April 2025)](https://github.blog/changelog/2025-04-04-github-mcp-server-public-preview/)

### Performance & Metrics
- [MCP Market — Top 100 MCP Servers Leaderboard](https://mcpmarket.com/leaderboards)
- [Fast MCP Performance Benchmarks (March 2026)](https://fastmcp.me/blog/most-popular-mcp-tools-2026)

### Workflows & Best Practices
- [FlorianBruniaux/claude-code-ultimate-guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) — Beginner to power user, production templates
- [shinpr/claude-code-workflows](https://github.com/shinpr/claude-code-workflows) — Production-ready workflows
- [Medium — 10 Must-Have Skills for Claude (Mar 2026)](https://medium.com/@unicodeveloper/10-must-have-skills-for-claude-and-any-coding-agent-in-2026-b5451b013051)
- [Superpowers for Claude Code: Complete Guide 2026](https://www.pasqualepillitteri.it/en/news/215/superpowers-claude-code-complete-guide)

### Framework Documentation
- [Model Context Protocol Official Docs](https://modelcontextprotocol.io/)
- [Figma MCP Guide](https://github.com/figma/mcp-server-guide)
- [Supabase MCP Docs](https://supabase.com/docs/guides/getting-started/mcp)
- [Cursor Docs — Plugins](https://cursor.com/docs/plugins)
