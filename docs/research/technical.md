# Tool Ecosystems for AI Development: MCPs, Plugins, Skills (2026)

**Research Date:** 2026-03-18
**Focus:** MCPs, Plugins, Skills, and Tool Ecosystems for AI-Assisted Development

---

## Key Findings

1. **MCP (Model Context Protocol) is the industry standard for tool integration**, with 97M+ monthly SDK downloads and backing from Anthropic, OpenAI, Google, and Microsoft. It's governed by the Agentic AI Foundation (donated by Anthropic in December 2025) and is now vendor-neutral.

2. **MCP vs. REST APIs: MCP wins for agent workflows.** MCP is stateful, self-describing, and designed for dynamic tool discovery—LLMs discover available tools at runtime. REST APIs require hardcoded integration and are stateless. For multi-step agent tasks, MCP is faster due to session persistence and zero repeated auth handshakes.

3. **Skills, Plugins, and MCPs are complementary, not competing.** Skills are reusable instruction templates (recipes); Plugins bundle skills, subagents, MCP servers, and hooks into distributable units; MCPs are protocol-level tool integrations. Use each for different purposes—don't try to do everything with one.

4. **MCP has three core primitives:** Tools (functions LLMs call), Resources (static/semi-static data), and Prompts (pre-written instruction templates). Most implementations focus on Tools; Resources and Prompts are underutilized.

5. **10,000+ MCP servers exist (as of March 2026).** Official servers from GitHub, Google Cloud, Figma, Supabase, and Perplexity are in production. Community implementations are exploding—mcpservers.org lists thousands, and PulseMCP had 5,500+ as of late 2025.

6. **Production MCP deployments have serious security gaps.** 30+ CVEs filed in January–February 2026. 82% of MCP file operations are vulnerable to path traversal. 53% rely on static API keys. OAuth 2.1 is now the standard for HTTP-based MCP transports; static tokens are deprecated.

7. **Security is actively blocking adoption.** 38% of developers surveyed say security concerns prevent increased MCP adoption. 25% of MCP servers have zero authentication. The "NeighborJack" attack (June 2025) exposed hundreds of unauthenticated MCP servers bound to 0.0.0.0.

8. **Claude Code Agent Teams are the emerging pattern for multi-agent orchestration.** One session acts as lead; teammates coordinate independently. Subagents remain for quick, focused workers. Third-party orchestrators (Gas Town, Multiclaude) available for complex tasks.

9. **Claude Code architecture is now: Projects (context scope) + Custom Instructions (global prefs) + Skills (reusable procedures) + Plugins (bundled packages) + Subagents/Agent Teams (parallelization).** This layered approach is more reliable than ad-hoc development—CodeRabbit analysis of 470 PRs showed 1.7x fewer defects and 2.74x fewer security vulnerabilities.

10. **Building MCP servers is accessible—Python, TypeScript, JavaScript, Rust, .NET, and Java SDKs exist.** FastMCP simplifies Python development. Microsoft's mcp-for-beginners curriculum covers cross-language fundamentals. Deployable examples exist for databases, filesystems, APIs, and specialized integrations (Figma, GitHub, Slack).

11. **MCP ecosystem adoption is transitioning from experimentation to enterprise deployment.** By 2026, 75% of API gateway vendors and 50% of iPaaS vendors will add MCP features. 58% of builders wrap existing APIs rather than building from scratch.

12. **Cursor IDE (VSCode fork) now has native MCP support and a plugin marketplace.** March 2026 additions: Atlassian, Datadog, GitLab, Glean, Hugging Face, monday.com, and PlanetScale plugins with embedded MCPs. Cursor dominates as the AI code editor (trusted by Stripe, NVIDIA, Salesforce, Shopify).

---

## Details

### MCP Protocol: What It Is and Why It Matters

**What is MCP?**
The Model Context Protocol is an open, JSON-RPC 2.0 based protocol that connects LLM clients (Claude Code, Cursor, OpenAI Agents, etc.) to external tools, data sources, and APIs. Unlike REST APIs (stateless, developer-driven), MCP is stateful and agent-oriented—the model discovers available tools at runtime and decides which to call.

**Key Architectural Differences from REST:**
- **Session State:** MCP maintains persistent, authenticated sessions. No repeated auth handshakes between tool calls.
- **Self-Description:** Tools are advertised via `tools/list`, with full JSON Schema describing inputs and outputs. LLMs read this schema before calling.
- **Transport Flexibility:** MCP works over Stdio (local development), SSE (server-sent events), or HTTP. Stdio is common for development; HTTP is standard for production.

**When to Use MCP vs. REST:**
- Use MCP when AI agents need dynamic tool discovery, multi-step workflows, and context preservation across calls.
- Use REST APIs when you need deterministic control from application code, not agent-driven discovery.

**Governance & Maturity:**
Anthropic donated MCP to the Agentic AI Foundation (AAIF) under the Linux Foundation in December 2025. The AAIF is co-founded by Anthropic, Block, and OpenAI, making MCP vendor-neutral. Adoption is accelerating—97M+ SDK downloads, with official implementations from major cloud providers.

---

### MCP Servers: Current Landscape and Production-Ready Examples

**Official/First-Party Servers (Stable & Recommended):**

1. **GitHub MCP Server** (github/github-mcp-server)
   - Read PRs, issues, file contents, repo metadata
   - Command: `claude mcp add github --command "npx" --args "-y @modelcontextprotocol/server-github" --env GITHUB_PERSONAL_ACCESS_TOKEN=ghp_token`
   - Requires: repo, read:org scopes
   - Status: Production-ready

2. **Figma MCP Server** (figma/mcp-server-guide)
   - Extract design information, layer hierarchies, component details
   - Multiple community implementations: TimHolden/figma-mcp-server, grab/cursor-talk-to-figma-mcp
   - New in March 2026: Can generate design layers from VS Code
   - Status: Production-ready with active development

3. **Google Cloud MCP Servers**
   - BigQuery, Vertex AI, Cloud Storage, Cloud Logging
   - Enterprise-ready; OAuth 2.1 authentication
   - Status: Recent releases (2026)

4. **Supabase MCP Server**
   - Database, auth, edge functions, real-time subscriptions
   - Direct integration for Postgres-backed projects
   - Status: Production-ready

5. **Slack MCP Server**
   - Read DMs, channels, threads; search messages
   - No OAuth apps or admin approval required
   - Status: Community implementation, stable

6. **Postgres MCP Server**
   - Query and list_tables tools
   - Read-only SQL execution mid-session
   - Status: Official, stable

**Specialized/Domain-Specific Servers:**

- **mcp-openapi:** Auto-generates MCP tools from OpenAPI/Swagger specs. Point at any spec URL; no code needed.
- **Rube MCP:** Connects 500+ apps (Gmail, Slack, GitHub, Notion, etc.) with single authentication.
- **MindsDB MCP:** Federated query engine for multi-database reasoning.
- **AWS MCP Suite:** DynamoDB, Aurora, Neptune integrations.
- **Redis MCP, SQLite MCP:** For cache and local database interaction.

**Ecosystem Scale:**
- mcpservers.org and mcpmarket.com list thousands of servers
- PulseMCP had 5,500+ servers listed as of late 2025; current count likely exceeds 10,000
- Community-built servers far outnumber official ones

---

### MCPs vs. Skills vs. Plugins: Architecture and Trade-offs

**What Are Skills?**
- Reusable instruction sets (recipes for Claude)
- Stored as folders with SKILL.md file + optional scripts/resources
- Invoked with slash commands (`/skill-name`)
- Scoped to sessions or teams
- Best for: Teaching Claude how to do a specific task

**What Are Plugins?**
- Bundled packages containing skills, slash commands, subagents, MCP servers, hooks, and custom instructions
- Distributable across repos and teams
- Installable from marketplaces (Anthropic's official marketplace, community marketplaces)
- Examples: Linear plugin (with MCP + custom /push, /code-review commands), Code Review plugin (with subagent + hooks)
- Best for: Sharing complete workflows; portability across projects

**What Are MCPs?**
- Protocol-level integrations for tool/data access
- Expose three primitives: Tools, Resources, Prompts
- Operate at the infrastructure layer (can be used by any MCP client: Claude, Cursor, OpenAI Agents, etc.)
- Transport: Stdio (local), HTTP (production)
- Best for: Low-level integrations with external systems (APIs, databases, filesystems)

**Comparison Table:**

| Feature | Skills | Plugins | MCPs |
|---------|--------|---------|------|
| What it does | Teaches Claude instructions | Bundles multiple customizations | Integrates external tools/data |
| Scope | Session or team | Team or public marketplace | Infrastructure-level |
| Reusability | High (within Claude ecosystem) | High (portable, distributable) | Highest (any MCP client) |
| Complexity | Low (just prompts) | Medium (bundles + scripts) | Medium (server implementation) |
| Examples | "code review prompt", "research template" | "Linear plugin" (skill + MCP + commands) | "GitHub server", "Postgres server" |
| When to use | Reusable task instructions | Shareable, polished workflows | External system integration |

**Best Practice:** Start with Skills for personal workflows. Package them into Plugins for team reuse. Use MCPs for production tool integrations.

---

### Building MCP Servers: Patterns and Practical Examples

**SDK Support:**
- Python: Official SDK; FastMCP simplifies development
- TypeScript/JavaScript: Official SDK; widely used for HTTP transports
- Rust, .NET, Java: Official SDKs available
- Cross-language curriculum from Microsoft (mcp-for-beginners)

**Core Capabilities to Implement:**

1. **Tools** (most common)
   - Functions the LLM can call
   - Defined with JSON Schema for inputs/outputs
   - Example: GitHub MCP exposes `read_file`, `list_repos`, `get_issue` tools

2. **Resources** (underutilized)
   - Static or semi-static data (read, not called)
   - Useful for context injection
   - Example: Project documentation, design system specs

3. **Prompts** (emerging)
   - Predefined instruction templates
   - Standardize how models perform common tasks
   - Example: "Code review template", "security audit checklist"

**Minimal Python Server Example:**
```python
import mcp.server.stdio
from mcp.types import Tool, TextContent

server = mcp.server.stdio.StdioServer("my-server")

@server.call_tool()
async def handle_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "get_weather":
        city = arguments["city"]
        # Call your API, return result
        return [TextContent(type="text", text=f"Weather in {city}: 72°F")]
    raise ValueError(f"Unknown tool: {name}")

@server.list_tools()
async def handle_list_tools():
    return [
        Tool(
            name="get_weather",
            description="Get current weather",
            inputSchema={
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "City name"}
                },
                "required": ["city"]
            }
        )
    ]

if __name__ == "__main__":
    server.run()
```

**Deployment Patterns:**
- **Local/Development:** Stdio transport, file-based auth
- **Production (HTTP):** OAuth 2.1 authentication, TLS, request validation, rate limiting
- **Docker:** Standard containerization for remote deployments

**Common Pitfalls:**
- Exposing servers to 0.0.0.0 without auth (NeighborJack vulnerability)
- Path traversal in file operations (82% of servers vulnerable)
- Static API keys instead of OAuth 2.1
- Insufficient input validation

---

### Production Security: Current State and Best Practices

**Current Threat Landscape (as of March 2026):**

- **30+ CVEs filed in 60 days** (Jan–Feb 2026) targeting MCP implementations
- **CVSS 9.6 RCE discovered** in a package with ~500k downloads
- **82% of MCP file operations vulnerable to path traversal**
- **NeighborJack attack (June 2025):** Hundreds of unauthenticated servers bound to 0.0.0.0
- **53% of servers rely on static API keys or PATs** (BAD)
- **25% of MCP servers have zero authentication** (CRITICAL)

**Adoption Blockers:**
- 38% of developers say security concerns prevent MCP adoption
- Enterprise procurement demands compliance and hardening
- Tool chaining increases attack surface (one vulnerable tool compromises the chain)

**Recommended Security Architecture:**

1. **Authentication (Standard: OAuth 2.1)**
   - For HTTP transports: OAuth 2.1 improves token handling, scope enforcement, session security
   - Stdin transports: Environment-based PATs acceptable for local development only
   - Never expose servers bound to 0.0.0.0 without auth

2. **Authorization & Access Control**
   - Enforce strict role-based access control (RBAC)
   - Ensure tools only access explicitly permitted data
   - Audit all tool calls

3. **Input Validation**
   - Validate all tool inputs against JSON Schema
   - Sanitize file paths (prevent traversal attacks)
   - Rate-limit tool calls per session

4. **Session Isolation**
   - Each client session must have isolated state
   - One compromised session must not affect others

5. **Deployment Hardening**
   - Use TLS for HTTP transports
   - Never expose servers directly to public internet; use API gateways or proxies
   - Monitor tool call logs for anomalies
   - Regular security audits (especially for file and database operations)

**Tools & Frameworks:**
- OWASP Gen AI Security Project publishes MCP security guides
- API gateway vendors (Zuplo, etc.) now include MCP-specific hardening
- iPaaS vendors embedding MCP compliance modules

---

### Claude Code Architecture: Layered Extensibility (2026)

**Structural Layers (in order of scope):**

1. **Projects**
   - Define context scope (repository, folder, files)
   - Isolate work across different codebases
   - Each project has own configuration

2. **Custom Instructions**
   - Global preferences applying across sessions
   - System-level behavioral guidance (coding style, tool preferences)
   - Team-wide defaults

3. **Skills** (`/skill-name`)
   - Reusable task procedures
   - Session-invoked slash commands
   - Composable; can call other skills

4. **Plugins**
   - Bundled packages (skills + subagents + MCPs + hooks + commands)
   - Marketplace-distributed
   - Enable portability across teams

5. **Subagents** (and emerging Agent Teams)
   - Dedicated workers for specific tasks
   - Parallel execution capability
   - Subagents: quick, focused, report back to main session
   - Agent Teams: autonomous coordination, teammates challenge each other

6. **MCP Servers**
   - Infrastructure-level integrations
   - Connected via Project configuration (`.claude/config.json`)
   - Provide Tools, Resources, Prompts to any layer above

**Quality Impact (CodeRabbit Study, Dec 2025):**
Analyzing 470 open-source PRs:
- Projects structured with MCP + subagents + custom instructions: **1.7x fewer defects**
- Same structure: **2.74x fewer security vulnerabilities**
- Compared to ad-hoc development

**Typical Multi-Agent Orchestration Pattern:**

```
Main Session (Lead)
  ├─ Subagent: Code Review
  │  └─ MCP: GitHub (read PRs, file diffs)
  ├─ Subagent: Testing
  │  └─ MCP: Test Runner (execute tests)
  └─ Agent Team: Research & Documentation
     ├─ Teammate: API Documentation
     │  └─ MCP: OpenAPI Server
     └─ Teammate: Architecture Review
        └─ MCP: Codebase Analysis
```

**When to Use Each:**
- **Subagents:** Parallel code review, test automation, focused debugging
- **Agent Teams:** Research with competing hypotheses, cross-layer coordination, debugging with multiple strategies
- **MCP Servers:** Any external system (GitHub, Slack, databases, APIs)

---

### Plugin Ecosystem: Marketplace and Integration Status

**Official Marketplaces:**
- Anthropic's official Claude Code marketplace (43+ marketplaces tracked)
- 834+ total plugins available across marketplaces
- 9,000+ plugins across ClaudePluginHub, Claude-Plugins.dev, and others

**Notable Plugins (March 2026):**

| Plugin | Type | Key Capabilities | MCP Integration |
|--------|------|------------------|-----------------|
| Linear | Dev Tools | Issue management, PR sync | Embedded MCP server |
| GitHub Code Review | CI/CD | PR review, lint integration | GitHub MCP |
| Figma Design Import | Design | Layer extraction, component sync | Figma MCP |
| Slack Integration | Communication | Channel search, message context | Slack MCP |
| Code Intelligence | Dev Tools | LSP connection, type hints | Language Server Protocol |
| PagerDuty Incident Mgmt | DevOps | On-call, schedule, incident management | PagerDuty MCP (new March 2026) |

**Cursor IDE Marketplace (March 2026 Additions):**
- Atlassian, Datadog, GitLab, Glean, Hugging Face, monday.com, PlanetScale plugins
- Most include embedded MCP servers for agent automation

**Plugin Development Pattern:**
```
plugin-name/
  ├── PLUGIN.md          # Metadata
  ├── commands/          # Slash commands (/new-feature, etc.)
  ├── agents/            # Subagents (optional)
  ├── mcp/               # MCP server definitions
  ├── hooks/             # Lifecycle hooks (on-startup, on-file-save, etc.)
  └── skills/            # Bundled reusable skills
```

---

### Multi-Agent Orchestration: Emerging Patterns

**Native Claude Code Agent Teams (Experimental):**
- Enable in `.claude/config.json` or environment: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=true`
- One session acts as Lead; teammates work independently
- Teammates communicate directly; lead coordinates
- Best for: Research, debugging with hypotheses, parallel module development

**Comparison: Subagents vs. Agent Teams**

| Feature | Subagents | Agent Teams |
|---------|-----------|-------------|
| Autonomy | Low; report to main | High; self-coordinate |
| When to use | Quick, focused tasks | Complex, collaborative tasks |
| Communication | Call → return pattern | Peer communication |
| Best cases | Code review, testing | Research, design review |

**Third-Party Orchestrators (for complex workflows):**
- **Gas Town:** "Kubernetes for AI agents"—mayor agent spawns specialists
- **Multiclaude:** Multi-session coordination
- **Shipyard:** Multi-agent pipelines for Claude Code
- **Ruflo:** Swarm intelligence, distributed coordination, RAG integration

**Trend:** Industry moving from single-agent to specialist-team models, mirroring monolithic-to-microservices architecture.

---

### Developer Adoption: Current State and Barriers

**Adoption Metrics (as of March 2026):**
- **97M+ SDK downloads** for MCP SDKs
- **58% of MCP builders wrap existing APIs** (integration strategy)
- **42% build MCP servers from scratch** for new capabilities
- **375 GitHub discussions/month** about MCP (growing)

**What's Driving Adoption:**
- LLM agents are now production-ready and cost-effective
- Tool discovery at runtime is a paradigm shift (vs. hardcoding integrations)
- Cursor and Claude Code made agent development mainstream

**Key Adoption Blockers:**
1. **Security concerns (38% of builders)**
   - Path traversal vulnerabilities in file operations
   - Static API key exposure
   - Missing authentication (25% of servers)

2. **Skill gap**
   - Understanding when to use Skills vs. Plugins vs. MCPs
   - Security best practices (OAuth 2.1, input validation)
   - Testing MCP servers in CI/CD

3. **Operational maturity**
   - Logging and observability (tool call auditing)
   - Rate limiting and abuse prevention
   - Production deployment patterns (Docker, Kubernetes)

4. **Standards fragmentation** (improving)
   - Multiple plugin marketplaces (Anthropic, community, custom)
   - No universally agreed on plugin distribution format (improving with AAIF governance)

---

## Sources

### Protocol & Specification
- [Model Context Protocol Specification (Nov 2025)](https://modelcontextprotocol.io/specification/2025-11-25)
- [Model Context Protocol GitHub (Official Org)](https://github.com/modelcontextprotocol)
- [MCP Best Practices Guide](https://modelcontextprotocol.info/docs/best-practices/)
- [OWASP Gen AI Security: MCP Security Guide](https://genai.owasp.org/resource/a-practical-guide-for-secure-mcp-server-development/)

### Server Implementations & Ecosystem
- [Official MCP Servers Repository](https://github.com/modelcontextprotocol/servers)
- [GitHub MCP Server (Official)](https://github.com/github/github-mcp-server)
- [Figma MCP Server Guide](https://github.com/figma/mcp-server-guide)
- [Awesome MCP Servers (Community Directory)](https://github.com/punkpeye/awesome-mcp-servers)
- [MCPServers.org Registry](https://mcpservers.org/)
- [MCP Market (Discovery Platform)](https://mcpmarket.com/)

### Building MCP Servers
- [Build an MCP Server (Official Docs)](https://modelcontextprotocol.io/docs/develop/build-server)
- [MCP Server Step-by-Step Guide (Composio)](https://composio.dev/content/mcp-server-step-by-step-guide-to-building-from-scrtch)
- [How to Build Your Own MCP Server with Python (FreeCodeCamp)](https://www.freecodecamp.org/news/how-to-build-your-own-mcp-server-with-python/)
- [MCP for Beginners (Microsoft Curriculum)](https://github.com/microsoft/mcp-for-beginners)
- [Building MCP Servers (DigitalOcean & Medium Tutorials)](https://www.digitalocean.com/community/tutorials/mcp-server-python)

### Security & Production
- [State of MCP Adoption & Security (Zuplo Report)](https://zuplo.com/mcp-report)
- [MCP Security Vulnerabilities: 30 CVEs in 60 Days (March 2026)](https://www.heyuan110.com/posts/ai/2026-03-10-mcp-security-2026/)
- [MCP Server Security Best Practices](https://www.truefoundry.com/blog/mcp-server-security-best-practices)
- [MCP Security: NeighborJack Attack & Authentication](https://medium.com/data-science-collective/why-your-mcp-server-is-a-security-disaster-waiting-to-happen-660577d8077c)

### Claude Code & Integration
- [Claude Code MCP Integration Docs](https://code.claude.com/docs/en/mcp)
- [Claude Code Plugins & Marketplace Docs](https://code.claude.com/docs/en/discover-plugins)
- [Anthropic Official Plugins Repository](https://github.com/anthropics/claude-plugins-official)
- [Mental Model: Skills, Subagents, and Plugins (Level Up Coding)](https://levelup.gitconnected.com/a-mental-model-for-claude-code-skills-subagents-and-plugins-3dea9924bf05)
- [Claude Code Skills vs. MCP vs. Plugins Comparison (2026 Guides)](https://www.morphllm.com/claude-code-skills-mcp-plugins)

### Multi-Agent Orchestration
- [Orchestrate Teams of Claude Code Sessions (Official Docs)](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Agent Teams: Complete Guide (2026)](https://claudefa.st/blog/guide/agents/agent-teams)
- [Multi-Agent Development for Claude Code](https://www.eesel.ai/blog/claude-code-multiple-agent-systems-complete-2026-guide)
- [Ruflo: Agent Orchestration Platform](https://github.com/ruvnet/ruflo)

### AI Agent Frameworks (Comparison)
- [LangChain: Open Source Agent Framework](https://www.langchain.com/langchain)
- [Top 10 AI Agent Frameworks 2026 (Arsum)](https://arsum.com/blog/posts/ai-agent-frameworks/)
- [Top 5 Open-Source Agentic Frameworks (AI Multiple)](https://aimultiple.com/agentic-frameworks)
- [AI Agent Tools Comparison 2026 (Fast.io)](https://fast.io/resources/ai-agent-tools-comparison/)

### Cursor IDE
- [Cursor: Code with AI](https://cursor.com/)
- [Cursor March 2026 Updates (The Agency Journal)](https://theagencyjournal.com/cursors-march-2026-updates-jetbrains-integration-and-smarter-agents/)
- [Cursor IDE Complete Guide 2026](https://crazyrouter.com/en/blog/cursor-ai-ide-complete-guide-2026-features-pricing-setup)

### MCP vs. REST APIs
- [MCP vs REST API Comparison (2026)](https://mcpplaygroundonline.com/blog/mcp-vs-rest-api-whats-different)
- [MCP vs API: When to Use Each (Atlan)](https://atlan.com/know/when-to-use-mcp-vs-api/)
- [MCP vs REST for AI Agents (RoxyAPI)](https://roxyapi.com/blogs/rest-apis-vs-mcp-agents-when-to-use-which)

### Market Research & Adoption
- [2026: The Year for Enterprise-Ready MCP Adoption (CData)](https://www.cdata.com/blog/2026-year-enterprise-ready-mcp-adoption)
- [A Year of MCP: Internal Experiment to Industry Standard (Pento AI)](https://www.pento.ai/blog/a-year-of-mcp-2025-review)
- [MCP Adoption Statistics 2025](https://mcpmanager.ai/blog/mcp-adoption-statistics/)

---

## Confidence Levels

| Finding | Confidence | Rationale |
|---------|-----------|-----------|
| MCP is industry standard for AI agent tool integration | **High** | Governed by AAIF, 97M+ SDK downloads, backed by Anthropic/OpenAI/Google/Microsoft, widespread adoption in production. |
| MCP superior for agent workflows vs. REST APIs | **High** | Fundamental architectural differences (stateful, self-describing, dynamic discovery) well-documented and validated by multiple sources. |
| Security is major blocker for production adoption | **High** | 30+ CVEs in 60 days, 82% of servers vulnerable to path traversal, 38% of developers cite security concerns; backed by Zuplo report and OWASP guidance. |
| 10,000+ MCP servers exist | **Medium-High** | Multiple registries (mcpservers.org, mcpmarket.com, PulseMCP) report thousands; exact count varies by registry and may include deprecated servers. |
| Skills/Plugins/MCPs are complementary | **High** | Well-documented use cases and architectural patterns; supported by Level Up Coding mental model and multiple implementation guides. |
| Agent Teams emerging as orchestration pattern | **Medium** | Available (experimental) in Claude Code; usage growing but not yet universal; third-party tools (Gas Town, Ruflo) provide alternatives. |
| Claude Code structured development yields 1.7x fewer defects | **Medium** | CodeRabbit December 2025 study of 470 PRs; specific to this methodology; may vary by team/codebase. |
| OAuth 2.1 is security standard for production MCPs | **High** | OWASP guidance, Zuplo report, multiple security sources recommend; static API keys deprecated in production deployments. |
| Cursor is dominant AI IDE | **High** | Named by Stripe, NVIDIA, Salesforce, Shopify; actively adding MCP support and plugins in March 2026. |
| LangChain most popular agentic framework by adoption | **High** | 47M+ PyPI downloads, largest ecosystem; but not universal—CrewAI growing for multi-agent, OpenAI Agents SDK lowest barrier to entry. |

---

## Open Questions

1. **How are enterprises deploying MCP servers at scale?** Most public guidance is development-focused; production patterns (CI/CD, monitoring, disaster recovery) are emerging but not standardized. Zuplo and other gateways are filling gaps.

2. **What are realistic security compliance requirements for MCP in regulated industries?** OWASP guidance exists but HIPAA, PCI-DSS, SOC2 mappings for MCP are still being worked out.

3. **Will Agent Teams (experimental in Claude Code) become standard across other platforms (Cursor, OpenAI Agents)?** Currently unique to Claude Code; adoption rate unknown.

4. **How do MCP servers handle versioning and breaking changes?** Protocol supports capability negotiation, but no standard for semantic versioning across the ecosystem.

5. **What's the actual performance cost of agent-driven tool discovery vs. hardcoded REST calls?** Anecdotal evidence suggests negligible overhead, but no published benchmarks for complex workflows.

6. **Are there emerging security standards beyond OAuth 2.1?** MCP-specific threat modeling is new; we may see specialized authentication/authorization schemes (e.g., agent capability-based access control).

7. **How do teams enforce MCP security policies across distributed implementations?** Enterprise API gateway integration is happening, but centralized compliance tooling is still developing.

8. **What's the long-term viability of the plugin marketplace model?** Currently fragmented (Anthropic, community, custom). Will AAIF governance consolidate them?

---

## Actionable Next Steps for Developers

1. **If building new external integrations:** Use MCP (or REST if you need deterministic app-level control). MCP is now lower-friction than custom REST clients.

2. **If writing reusable Claude workflows:** Package as Skills first (simple), then bundle into Plugins (shareable). Use MCPs for backend integrations.

3. **If deploying to production:** Enforce OAuth 2.1, input validation, path sanitization, and audit logging. Zuplo and similar gateways simplify hardening.

4. **If coordinating multiple agents:** Start with Subagents (quick, focused). Upgrade to Agent Teams (experimental) if you need autonomous coordination. Use third-party orchestrators (Gas Town, Ruflo) for complex swarms.

5. **If choosing a framework:** LangChain + LangGraph for speed and ecosystem; CrewAI if you want multi-agent specialization; OpenAI Agents SDK if you prefer simplicity.

6. **If starting with Cursor:** Native MCP support is built-in; plugins are now marketplace-available. Adoption curve is much faster than 2025.

---

**End of Technical Research Report**
