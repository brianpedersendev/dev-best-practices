# Best GitHub Repositories for Skills, Plugins, and MCP Servers (2025-2026)

**Research Date:** 2026-03-19
**Focus:** Production-ready repos for AI-augmented development with Claude Code, Cursor, and Gemini
**Scope:** MCP servers, Claude skills, plugins, Cursor rules, agent orchestration, prompt libraries, and related tools

---

## Executive Summary

The MCP ecosystem has exploded to **21,000+ servers** (with the public registry alone doubling to 10K+ in March 2026) and is now standard across Anthropic, OpenAI, and Google. Key findings:

- **MCP officially donated to Linux Foundation** (December 2025) — validates production-readiness
- **Enterprise adoption accelerating** — AWS, Docker, GitHub, MongoDB, Supabase all ship MCP servers
- **Token efficiency breakthrough** (January 2026) — filesystem-based hierarchical routing reduces context by 98%
- **Top performers by installs:** Superpowers MCP (56K+), Playwright (27K+), Context7, GitHub MCP, Supabase, Sequential Thinking
- **Security focus needed** — Anthropic's Git MCP had three patched CVEs (January 2026); OpenClaw supply chain attack (March 2026)

---

## 1. MCP Servers: Official Reference Implementations

These are the foundation servers maintained by Anthropic and adopted as standards.

### Core Infrastructure MCP Servers

| Name | Repository | Stars | Setup | What It Does | Why It Matters |
|------|-----------|-------|-------|-------------|----------------|
| **Filesystem** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) | N/A | `npx -y @modelcontextprotocol/server-filesystem /path` | Read, write, edit, search local directories securely | Foundation for any local dev work — Claude/Cursor can manipulate your codebase |
| **Git** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/git) | N/A | `npx -y @modelcontextprotocol/server-git /path/to/repo` | Diff, log, commit, branch, tag operations | Essential for autonomous git workflows; updated Jan 2026 with CVE patches |
| **PostgreSQL** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/postgres) | N/A | `npx -y @modelcontextprotocol/server-postgres` | Query, schema management, migrations | Replaces manual DB interactions for full-stack development |
| **SQLite** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/sqlite) | N/A | `npx -y @modelcontextprotocol/server-sqlite /path/to/db.sqlite` | Local database access for small to medium projects | Fast local dev; no external dependencies |
| **Sequential Thinking** | [modelcontextprotocol/servers/sequentialthinking](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking) | N/A | `npx -y @modelcontextprotocol/server-sequential-thinking` | Dynamic problem decomposition, reflective multi-step reasoning | Transforms Claude from code generator into thoughtful partner; proven on complex tasks |

---

## 2. MCP Servers: Code & Version Control

The second-most critical category after infrastructure.

### GitHub & Git Integration

| Name | Repository | Setup | What It Does | Why It Matters |
|------|-----------|-------|-------------|----------------|
| **GitHub MCP (Official Anthropic)** | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/github) | `npx -y @modelcontextprotocol/server-github` | Read/search repos, list PRs, issues, review code, automate workflows | 1-click GitHub integration for Claude/Copilot; GitHub released Go rewrite (April 2025) with 100% feature parity + code scanning |
| **GitHub MCP (GitHub Official)** | [github-mcp-server](https://github.blog/changelog/2025-04-04-github-mcp-server-public-preview/) | Available via GitHub Marketplace | Local GitHub operations, PR automation, issue tracking | Modern replacement maintained by GitHub engineering; supports custom tool descriptions |

**Key Discovery:** Anthropic's original Git/GitHub MCPs were rewritten by GitHub in Go in April 2025. Use the official GitHub version for new projects.

---

## 3. MCP Servers: Database & Data Management

Essential for full-stack development.

### Official Database Servers

| Name | Repository | Setup | What It Does | Why It Matters |
|------|-----------|-------|-------------|----------------|
| **Supabase (Official)** | [supabase-community/supabase-mcp](https://github.com/supabase-community/supabase-mcp) | Via Docker or `npm install` | Table design, migrations, SQL queries, TypeScript type generation, auth, storage | 20+ tools for end-to-end Postgres management; official support |
| **MongoDB MCP** | (Official in MCP Registry) | Via npm | Full Atlas support, vector search indexes, CRUD operations | MongoDB 2026 update added vector index support — essential for RAG agents |
| **Supabase Alternative (alexander-zuev)** | [alexander-zuev/supabase-mcp-server](https://github.com/alexander-zuev/supabase-mcp-server) | Via npm | Query execution, management API, automatic migration versioning, logs | More feature-rich than official; auto-versioning migrations |
| **DBHub (Multi-DB)** | (MCP Registry) | Via Docker | PostgreSQL, MySQL, SQLite, DuckDB unified interface | Single MCP tool for multiple databases; token-efficient (2 tools) |

### Community Database Servers

| Name | Repository | When to Use |
|------|-----------|------------|
| **mcp-use/supabase-mcp-server** | [mcp-use/supabase-mcp-server](https://github.com/mcp-use/supabase-mcp-server) | Interactive React widgets for database exploration |
| **Quegenx/supabase-mcp-server** | [Quegenx/supabase-mcp-server](https://github.com/Quegenx/supabase-mcp-server) | Full administrative control; works with Cursor Composer |
| **HenkDz/selfhosted-supabase-mcp** | [HenkDz/selfhosted-supabase-mcp](https://github.com/HenkDz/selfhosted-supabase-mcp) | Self-hosted Supabase instances |

**Adoption Signal:** 9+ community Supabase MCP repos indicates this category is mature and battle-tested.

---

## 4. MCP Servers: Design & Frontend

Closing the design-to-code gap.

| Name | Repository | What It Does | Why It Matters |
|------|-----------|-------------|----------------|
| **Figma MCP (Official)** | [figma/mcp-server-guide](https://github.com/figma/mcp-server-guide) | Read design tokens, component structures, layout data, variant info | Design → code without manual translation; Figma knows exact CSS variable names |
| **Figma Console MCP** | [southleft/figma-console-mcp](https://github.com/southleft/figma-console-mcp) | Design system as API; extract tokens, debug design decisions | Best for enterprise design systems with 100+ components |
| **Figma Context (Tokens Focus)** | [j4ckp0t85/Figma-Context-MCP-tokens](https://github.com/j4ckp0t85/Figma-Context-MCP-tokens) | Figma token generation for AI agents | Experimental but promising for token-first design workflows |

---

## 5. MCP Servers: Testing & Browser Automation

Critical for CI/CD and end-to-end workflows.

| Name | Repository | What It Does | Key Stats | Why It Matters |
|------|-----------|-------------|-----------|----------------|
| **Superpowers MCP** | [superpowers/mcp](https://github.com/superpowers/mcp) | Structured workflow from design → TDD implementation | **56K+ installs** (most-installed MCP, March 2026) | End-to-end dev workflow orchestration; design-to-code pipeline with built-in TDD |
| **Playwright MCP (Microsoft)** | [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) | Browser automation, UI testing, accessibility checks | **27K+ installs** (#2 most-installed MCP) | AI-orchestrated testing; deterministic browser interactions with accessibility snapshots |
| **Selenium MCP** | (MCP Registry) | WebDriver automation | Emerging alternative to Playwright | Mature, enterprise-familiar framework |
| **Appium MCP** | [mcp-appium-gestures](https://github.com/mcp-appium-gestures) | Mobile gesture automation | Specialized for mobile AI | Complex interaction orchestration without manual scripting |
| **Test Runner MCP** | (MCP Registry) | Unified interface for Bats, Pytest, Jest, Flutter, Go | Multi-framework support | Consistent test output across tech stacks |

**Benchmark (FastMCP 2026):** Playwright averages 7 sec/run at 83% accuracy; Bright Data (Selenium-based) averages 30 sec at 90%.

---

## 6. MCP Servers: Infrastructure & DevOps

Platform engineers' essential tools.

| Name | Repository | What It Does | Why It Matters |
|------|-----------|-------------|----------------|
| **AWS EKS MCP** | [awslabs/mcp-servers](https://awslabs.github.io/mcp/servers/) | Kubernetes resource management, cluster operations, troubleshooting | AI can now manage K8s clusters via natural language |
| **AWS ECS MCP** | [awslabs/mcp-servers](https://awslabs.github.io/mcp/servers/) | Container deployment, load balancers, networking, auto-scaling | Reduces manual AWS CloudFormation/CDK boilerplate |
| **Docker MCP Catalog** | [Docker Hub](https://hub.docker.com/mcp) | 100+ MCP servers discoverable in Docker Desktop (Jan 2026) | Centralized MCP server discovery; integrates Grafana, Kong, Neo4j, Pulumi, Heroku |
| **AWS Documentation MCP** | [awslabs/mcp](https://awslabs.github.io/mcp/servers/aws-documentation-mcp-server) | Real-time AWS API docs injection | Always up-to-date AWS examples — solves stale docs problem |

---

## 7. MCP Servers: Communication & Productivity

Slack, Linear, Notion, Gmail integrations.

| Name | Repository | Tools Available | Why It Matters |
|------|-----------|----------------|----------------|
| **Slack MCP (Official)** | [Slack Platform](https://slack.com/blog/news/powering-agentic-collaboration) | 47 workspace tools | Native MCP support; agents can post, read reactions, list channels |
| **Linear + GitHub MCP** | [KlavisAI](https://www.klavis.ai/mcp-server-connections/linear--notion--slack) | Issue creation, status updates, PR linking | Link discussions to work items; update ticket status from chat |
| **Notion MCP** | (Community ecosystem) | Page/database reads, syncs | Knowledge base access for agents |

---

## 8. MCP Servers: Documentation & Knowledge

Essential for RAG and context injection.

| Name | Repository | What It Does | Adoption Signal | Why It Matters |
|------|-----------|-------------|-----------------|----------------|
| **Context7 MCP (Upstash)** | [upstash/context7](https://github.com/upstash/context7) | Injects version-specific code docs into context | **Dominates FastMCP rankings by 2x margin** (#1 server) | Solves "outdated docs" problem; always-current API examples |
| **RAG Context MCP** | (MCP Registry) | Local vector storage, semantic search, indexed retrieval | Growing adoption | Persistent memory for agents; hybrid retrieval |
| **Rag Memory MCP** | (MCP Registry) | Knowledge graph + vector search, semantic search, document processing | Released early 2026 | Event-sourced memory with git-based versioning |

---

## 9. MCP Servers: Web Access & Search

Browser automation and data collection.

| Name | Repository | What It Does | Adoption | Why It Matters |
|------|-----------|-------------|----------|----------------|
| **Firecrawl MCP (Official)** | [firecrawl/firecrawl-mcp-server](https://github.com/firecrawl/firecrawl-mcp-server) | Web scraping, crawling, search with real Chrome | 350K+ developers; $14.5M Series A (Aug 2025) | Fastest (7 sec avg, 83% accuracy); production-grade web access for AI |
| **Web Scraping MCP** | [MaitreyaM/WEB-SCRAPING-MCP](https://github.com/MaitreyaM/WEB-SCRAPING-MCP) | crawl4ai integration, LLM-based extraction | Community alternative | Lower cost; local-first approach |

**2026 Architectural Shift:** MCP traditionally dumps everything into context. New pattern: filesystem-based hierarchical routing achieves 98% token reduction (75K → 1.4K).

---

## 10. MCP Servers: Curated Awesome Lists & Registries

**Meta-resources** — use these to discover new MCPs.

| Name | Repository | Coverage | Active? |
|------|-----------|----------|---------|
| **awesome-mcp-servers (punkpeye)** | [punkpeye/awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers) | Comprehensive, categorized | ✅ Active 2025-2026 |
| **awesome-mcp-servers (wong2)** | [wong2/awesome-mcp-servers](https://github.com/wong2/awesome-mcp-servers) | Curated list, MCP protocol | ✅ Active 2025-2026 |
| **awesome-devops-mcp-servers** | [rohitg00/awesome-devops-mcp-servers](https://github.com/rohitg00/awesome-devops-mcp-servers) | DevOps-focused | ✅ Active 2025-2026 |
| **Awesome-MCP-Servers-directory (habitoai)** | [habitoai/Awesome-MCP-Servers-directory](https://github.com/habitoai/Awesome-MCP-Servers-directory) | 21,000+ servers (March 2026) | ✅ Comprehensive |
| **MCP Servers Official Registry** | [mcpservers.org](https://mcpservers.org) | Official source of truth | ✅ Definitive |

---

## 11. Claude Code Skills: Official & Community Collections

Skills are Anthropic's mechanism for persistent, discoverable Claude behavior.

### Official Anthropic Resources

| Name | Repository | What It Does | How to Use |
|------|-----------|-------------|-----------|
| **anthropics/skills** | [anthropics/skills](https://github.com/anthropics/skills) | Public repository for Agent Skills | Git clone into `~/.claude/skills` or via Claude Code `/skill add` |
| **anthropics/claude-plugins-official** | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | Marketplace of high-quality Claude Code Plugins | Accessible via `/plugin` command in Claude Code |

### Community Awesome Collections

| Name | Repository | Coverage | Stars | Notes |
|------|-----------|----------|-------|-------|
| **awesome-claude-skills (ComposioHQ)** | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | Curated practical skills | Growing | Productivity, code, automation |
| **awesome-claude-skills (travisvn)** | [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) | Comprehensive 50+ skills | Active | TDD, debugging, git, document processing |
| **Awesome-Agent-Skills (VoltAgent)** | [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | 500+ agent skills, multi-platform | High adoption | Works with Codex, Antigravity, Gemini CLI, Cursor |
| **Awesome-MCP-Server (AIAnytime)** | [AIAnytime/Awesome-MCP-Server](https://github.com/AIAnytime/Awesome-MCP-Server) | All MCP server projects | Community curated | Meta-collection of MCP resources |
| **Antigravity-awesome-skills (sickn33)** | [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) | 1000+ battle-tested skills | Largest collection | Official skills from Anthropic, Vercel; performance-tuned |
| **awesome-claude-skills (karanb192)** | [karanb192/awesome-claude-skills](https://github.com/karanb192/awesome-claude-skills) | 50+ verified skills | Active 2026 | TDD, debugging, git workflows, document processing |
| **awesome-claude-code (hesreallyhim)** | [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | Skills, hooks, slash-commands, agent orchestrators | Meta-focused | Comprehensive tooling ecosystem |
| **claude-skills (alirezarezvani)** | [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | 192+ skills, multi-agent | Verified | Engineering, marketing, product, compliance roles |

**Adoption Signal:** 1000+ verified, battle-tested skills available across multiple awesome repos. Skills are the primary extensibility mechanism for Claude Code beyond MCPs.

---

## 12. Cursor Rules & .cursorrules/MDC Files

Configuration-as-code for Cursor IDE.

### Main Awesome Collections

| Name | Repository | Coverage | Notes |
|------|-----------|----------|-------|
| **awesome-cursorrules (PatrickJS)** | [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) | 50+ framework/language rules | ✅ Primary reference |
| **awesome-cursor** | [hao-ji-xing/awesome-cursor](https://github.com/hao-ji-xing/awesome-cursor) | Tools, resources, extensions | Broader than just rules |
| **awesome-cursor-rules-mdc (sanjeed5)** | [sanjeed5/awesome-cursor-rules-mdc](https://github.com/sanjeed5/awesome-cursor-rules-mdc) | .mdc (new format) rules | Modern Cursor 2026+ format |
| **Awesome-Cursor-rules (jsonxu)** | [jsonxu/Awesome-Cursor-rules](https://github.com/jsonxu/Awesome-Cursor-rules) | Definitive open-source collection | 879+ community .mdc files |

### What .cursorrules / .mdc Files Do

- Define project-specific instructions for Cursor AI
- Ensure code generation matches project standards
- Provide architectural context and common patterns
- Support legacy `.cursorrules` (deprecated) and new `.mdc` format (current)

**2026 Migration Note:** Cursor migrated from legacy `.cursorrules` root files to project-based `.mdc` rules for better scoping.

---

## 13. Agent Orchestration Frameworks

Multi-agent systems and swarm orchestration.

| Name | Repository | Type | When to Use | Key Features |
|------|-----------|------|------------|--------------|
| **Swarms** | [kyegomez/swarms](https://github.com/kyegomez/swarms) | Enterprise framework | Production multi-agent systems | Hierarchical swarms, parallel pipelines, graph-based networks, dynamic composition |
| **Ruflo** | [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | Claude-focused | Deploy 60+ Claude agents | Self-learning swarms, fault-tolerant consensus, Claude Code native |
| **Agency Swarm** | [VRSEN/agency-swarm](https://github.com/VRSEN/agency-swarm) | OpenAI-based | Multi-agent collaboration | Built on OpenAI Agents SDK; orchestrates specialized agent teams |
| **OpenSwarm** | [Intrect-io/OpenSwarm](https://github.com/Intrect-io/OpenSwarm) | Claude + CLI focused | Autonomous dev teams | Discord control, Linear integration, cognitive memory, supervisor dashboard |
| **Agent Swarm** | [desplega-ai/agent-swarm](https://github.com/desplega-ai/agent-swarm) | AI coding agents | Coordinated work distribution | Docker-based workers, lead agent delegation |
| **Swarm (Rust)** | [fcn06/swarm](https://github.com/fcn06/swarm) | Low-level orchestration | Complex agent networks | Open standards (MCP, A2A), configuration-driven agents |

**Important Note:** OpenAI deprecated Swarm in favor of the OpenAI Agents SDK (2026). For new projects, use Agency Swarm or Ruflo for Claude-native stacks.

---

## 14. Prompt Libraries & AI Workflow Templates

Reusable, version-controlled prompts and workflows.

| Name | Repository | Type | Notes |
|------|-----------|------|-------|
| **LangChain Templates** | [langchain-ai/langchain](https://github.com/langchain-ai/langchain) | Python/JS library | Industry standard; prompt caching support |
| **LlamaIndex** | [run-llama/llama_index](https://github.com/run-llama/llama_index) | RAG framework | 20+ integrations; SQL query generation |
| **Azure PromptFlow** | [microsoft/promptflow](https://github.com/microsoft/promptflow) | Microsoft visual workflow | YAML-based, CI/CD ready |
| **PromptLayer** | Community ecosystem | Prompt logging/monitoring | Production observability |
| **OpenPrompt** | [thunlp/OpenPrompt](https://github.com/thunlp/OpenPrompt) | Open-source prompt engineering | Template-based, modular |

**Market Signal:** Prompt engineering market projected to grow from $505B (2025) to $6.5T (2034).

---

## 15. Supporting Utilities & Meta-Repos

Tools that enable the above ecosystem.

| Name | Repository | What It Does |
|------|-----------|-------------|
| **claude-code** | [anthropics/claude-code](https://github.com/anthropics/claude-code) | Official Claude Code CLI and plugins |
| **MCP Benchmark** | Various sources (FastMCP, PulseMCP) | Track server performance, adoption, token efficiency |
| **Docker MCP Registry** | [Docker Hub MCP](https://hub.docker.com/mcp) | Centralized MCP discovery (2026 launch) |

---

## 16. Security Considerations

**Critical findings from research:**

### Known Vulnerabilities

1. **Git MCP (Anthropic) — January 2026**
   - CVE-2025-68143, CVE-2025-68144, CVE-2025-68145
   - Severity: 6.5–8.8
   - Impact: File access, code execution via prompt injection
   - Fix: Update to mcp-server-git 1.0.0-rc.1 or later (2025-12-18+)
   - Source: [The Register](https://www.theregister.com/2026/01/20/anthropic_prompt_injection_flaws/)

### OpenClaw Supply Chain Attack — March 2026

2. **OpenClaw Skill Ecosystem — March 2026**
   - Malicious packages discovered in OpenClaw skill registry
   - Impact: Credential exfiltration via compromised skills
   - Fix: Audit all installed OpenClaw skills; verify checksums against official registry
   - Source: [DailyBriefing 2026-03-19](../../DailyBriefing/03-19-2026.md)

### Best Practices

- **Always update MCPs.** Use latest versions; pin in `claude_desktop_config.json`
- **Self-hosted over SaaS MCPs** — credentials stay local; jailbreaks contained
- **MCP donation to Linux Foundation** (Dec 2025) — industry legitimacy; security governance improving
- **Audit agent skills/plugins** — supply chain attacks on skill registries are a real threat (OpenClaw March 2026)

---

## 17. Setup Recommendations by Use Case

### For Full-Stack Web Developers
1. **MCP Servers:** Filesystem, Git, PostgreSQL, GitHub, Playwright, Sequential Thinking
2. **Skills:** TDD, git workflows, testing, debugging
3. **Rules:** Next.js / React / TypeScript specifics (.cursorrules)

### For Data Engineers
1. **MCP Servers:** PostgreSQL, MongoDB, SQLite, Supabase, Context7
2. **Skills:** SQL optimization, data pipeline design, testing
3. **MCPs to add:** DBHub (multi-DB), RAG Context

### For Platform Engineers
1. **MCP Servers:** AWS EKS, Docker, Git, Filesystem
2. **Skills:** Kubernetes manifests, infrastructure-as-code
3. **MCPs:** Infrastructure documentation, CI/CD pipeline tools

### For Product Teams (Design + Code)
1. **MCP Servers:** Figma, Slack, Linear, GitHub, Sequential Thinking
2. **Skills:** Design handoff, spec-driven development
3. **MCPs:** Notion, communication integrations

### For Solo Founders / Rapid Prototyping
1. **MCP Servers:** Supabase, Figma, Playwright, Sequential Thinking, Context7
2. **Skills:** TDD, shipping, deployment automation
3. **Tools:** Ruflo (2-3 agent team)

---

## 18. Token Efficiency Breakthrough (January 2026)

**Key Finding:** Filesystem-based hierarchical routing vs. traditional MCP context injection

**Results:**
- Traditional MCP (dump-all): 75K tokens
- Hierarchical filesystem routing: 1.4K tokens
- **Reduction: 98%**

**Implication:** For latency-sensitive applications, route MCP results to filesystem instead of context. Claude Code can read selectively.

**Example:** Instead of injecting entire API docs via Context7, write them to `docs/.current-api.md` and have Claude read on demand.

---

## 19. Top Adoption Signals (2025-2026)

| Signal | Implication | Examples |
|--------|-----------|----------|
| **Enterprise backing** | Production-ready | AWS EKS MCP, GitHub official MCP, Docker MCP catalog |
| **Multiple community rewrites** | Ecosystem maturity | 9+ Supabase MCP implementations, 7+ awesome-cursor-rules repos |
| **Official marketplace listings** | Legitimacy | Docker Hub MCP catalog, MCP servers registry (mcpservers.org) |
| **Billion-dollar companies shipping MCP** | Standardization | OpenAI Agents SDK, Google Genkit, Microsoft Copilot integration |
| **Linux Foundation donation** | Industry consensus | MCP moved from Anthropic → Linux Foundation (Dec 2025) |
| **21K+ servers (March 2026)** | Ecosystem doubled in 3 months | Up from ~10K in late 2025; Superpowers MCP leads with 56K+ installs |

---

## 20. What NOT to Use in 2026

- **OpenAI Swarm (deprecated)** → Use OpenAI Agents SDK or Agency Swarm instead
- **Legacy `.cursorrules`** → Migrate to `.mdc` format
- **Monolithic MCPs without context management** → Use filesystem routing for large responses
- **Unpatched Git MCP** → Update to 2025-12-18+ versions
- **RAG without semantic search** → Use Qdrant or Rag Memory MCP (2026)
- **Unaudited OpenClaw skills** → Supply chain attack in March 2026; verify all installed skills

---

## Sources

### Official Repositories & Registries
- [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) — Official MCP reference implementations
- [anthropics/skills](https://github.com/anthropics/skills) — Official Claude Code skills
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — Official Claude plugins marketplace
- [mcpservers.org](https://mcpservers.org) — Official MCP servers registry
- [Docker Hub MCP Catalog](https://hub.docker.com/mcp) — 100+ discoverable MCP servers

### Awesome Collections
- [punkpeye/awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers)
- [wong2/awesome-mcp-servers](https://github.com/wong2/awesome-mcp-servers)
- [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules)
- [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills)
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)

### Key Blog Posts & Articles
- [claudefa.st — 50+ Best MCP Servers (2026)](https://claudefa.st/blog/tools/mcp-extensions/best-addons)
- [builder.io — Best MCP Servers (2026)](https://www.builder.io/blog/best-mcp-servers-2026)
- [firecrawl.dev — Best MCP Servers for Developers](https://www.firecrawl.dev/blog/best-mcp-servers-for-developers)
- [FastMCP — Top 10 Most Popular MCP Servers (2026)](https://fastmcp.me/blog/top-10-most-popular-mcp-servers)
- [Upstash — Context7 MCP (Jan 2026)](https://upstash.com/blog/context7-mcp)
- [The Register — Anthropic Git MCP Flaws (Jan 2026)](https://www.theregister.com/2026/01/20/anthropic_prompt_injection_flaws/)
- [GitHub Changelog — GitHub MCP Server Public Preview (April 2025)](https://github.blog/changelog/2025-04-04-github-mcp-server-public-preview/)
- [AWS — EKS MCP Server Release (2025)](https://aws.amazon.com/blogs/containers/accelerating-application-development-with-the-amazon-eks-model-context-protocol-server/)

### Technical Documentation
- [Figma MCP Guide](https://github.com/figma/mcp-server-guide)
- [Supabase MCP Docs](https://supabase.com/docs/guides/getting-started/mcp)
- [Model Context Protocol Official Docs](https://modelcontextprotocol.io/)

### Community & Discussion
- [Medium — 10 Must-Have MCP Servers (March 2026)](https://roobia.medium.com/the-10-must-have-mcp-servers-for-claude-code-2025-developer-edition-43dc3c15c887)
- [DEV Community — 7 MCP Servers Every Claude User Should Know (2026)](https://dev.to/docat0209/7-mcp-servers-every-claude-user-should-know-about-2026-29jl)
- [MCPcat — Best MCP Servers for Claude Code](https://mcpcat.io/guides/best-mcp-servers-for-claude-code/)

---

## Appendix: Installation Quick Reference

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
    }
  }
}
```

### Add Skills to Claude Code
```bash
claude code /skill add github:ComposioHQ/awesome-claude-skills
```

### Add .cursorrules to Cursor Project
Create `.cursorrules` in project root (or `.mdc` for new format):
```
# Your project context and coding rules
- Use TypeScript strict mode
- Follow [your conventions]
- Use Next.js App Router
```

---

**Last Updated:** 2026-03-19

---

## Related Topics

- [Best of Breed Directory](best-of-breed-directory.md) — Curated stacks and top tools by use case
- [Building Custom MCP Servers](building-custom-mcp-servers.md) — Creating custom MCPs when no existing tool fits
- [Claude Code Power User](claude-code-power-user.md) — Integrating skills and plugins into workflows
**Maintenance:** Review quarterly for new MCP servers and security updates

---
## Changelog
| Date | Change | Source |
|------|--------|--------|
| 2026-03-28 | Skills ecosystem explosion: 5 of top 10 trending GitHub repos (week of Mar 25) are skills-related after Anthropic opened the standard. Agent harness race: everything-claude-code (+21,490 stars/week, 100K+ total) and superpowers (+19,621 stars/week, 100K+ total). MCP registry doubled to 10K+ servers. | Daily briefing 03-28-2026 (Findings #3, #4) |
