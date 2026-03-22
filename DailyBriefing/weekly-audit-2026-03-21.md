# Weekly Knowledge Audit — 2026-03-21

## Staleness Findings

| Guide | Issue | Severity | Action Needed |
|-------|-------|----------|---------------|
| `docs/topics/building-custom-mcp-servers.md` | References FastMCP but doesn't specify version. FastMCP 3.0 went stable Feb 18, 2026 with major provider/transform architecture redesign; 3.1 shipped March 2026 with Code Mode. The `@mcp.tool()` API is unchanged but the architecture story is significantly different. | Medium | Update to reference FastMCP 3.x architecture, note provider/transform system, mention Code Mode for agent-driven tool discovery |
| `docs/topics/cost-optimization-playbook.md` | Anthropic removed long-context pricing surcharge for Opus 4.6 and Sonnet 4.6 (mid-March 2026). 1M token contexts now at standard per-token rates. This is a material cost change not reflected in the guide. | HIGH | Add note about long-context surcharge removal. This changes cost calculations for large-context workloads significantly. |
| `docs/topics/cost-optimization-playbook.md` | Cursor pricing section references "credits" system but doesn't fully explain the June 2025 overhaul from fixed "fast request" allotments to usage-based credit pools. Current tiers: Free, Pro ($20), Pro+ ($60), Ultra ($200), Teams ($40/user), Enterprise (custom). Guide has correct prices but credit pool mechanics could be clearer. | Low | Minor — clarify credit pool mechanics if doing a broader update |
| `docs/topics/ai-native-architecture.md` | References "Claude Agent SDK" — Anthropic has renamed "Claude Code SDK" to "Claude Agent SDK" (v0.1.49 as of March 17, 2026). Multiple guides still reference both names. | Medium | Standardize all references to "Claude Agent SDK" across guides |
| `docs/topics/ai-powered-frontend-features.md` | References "Vercel AI SDK" with `useChat`/`useCompletion` hooks. Vercel AI SDK is now at v6 (6.0.121) with new ToolLoopAgent, human-in-the-loop tool approval, and DevTools. The life-assistant example project still references "AI SDK 4.x". | Medium | Update frontend features guide to note AI SDK 6 capabilities. Example projects are lower priority since they're point-in-time snapshots. |
| `docs/topics/gemini-dev-power-user.md` | Gemini CLI is now at v0.34.0 (stable, March 17) with Plan Mode enabled by default, gVisor sandboxing, and loop detection. Preview v0.35.0 adds subagents and keyboard shortcuts. Guide may not reflect these recent additions. | Medium | Verify guide covers Plan Mode default, sandboxing, and subagent preview |
| `docs/topics/claude-code-power-user.md` | Claude Code now has: voice mode (/voice), /loop command for recurring monitoring, --bare flag, HTTP hooks, --channels (research preview), 128k max output tokens for Opus/Sonnet. Guide dates from March 18. | Medium | Update with /voice, /loop, --bare, HTTP hooks, --channels, 128k output token limit |
| `docs/topics/cursor-power-user.md` | Cursor 2.6 (March 3, 2026) adds MCP Apps (interactive UIs in agent chats), JetBrains IDE integration via ACP, team plugin marketplaces. Guide dates from March 18 but may not cover these. | Medium | Verify coverage of MCP Apps, JetBrains ACP, and team plugin sharing |
| `docs/topics/swarm-patterns-by-dev-stage.md` | CrewAI is now at v1.10.1 with native MCP and A2A support. LangGraph at v1.0.10. Guide should verify version references. | Low | Spot-check version references in framework comparison sections |

## Repository Health

| Repo | Status | Notes |
|------|--------|-------|
| `modelcontextprotocol/servers` | Active | 81.7k stars, 10k forks. Actively maintained by MCP steering group. |
| `PrefectHQ/fastmcp` (jlowin/fastmcp) | Active | ~23k stars. FastMCP 3.1 shipped March 2026. Downloads: ~1M/day. Powers 70% of MCP servers across all languages. Extremely healthy. |
| `anthropics/claude-code` | Active | Regular releases through March 2026. Renamed SDK to "Claude Agent SDK". |
| `google-gemini/gemini-cli` | Active | v0.34.0 stable (March 17), v0.35.0 preview (March 19). Rapid release cadence. |
| `vercel/ai` | Active | v6.0.121 (March 7, 2026). Major v6 release with ToolLoopAgent. |
| `crewAIInc/crewAI` | Active | 45.9k stars. v1.10.1 with native MCP and A2A. 12M daily agent executions. |
| `langchain-ai/langgraph` | Active | v1.0.10. 38M monthly PyPI downloads. Stable post-1.0 GA. |

## Pricing Changes

| Tool | Old Price | New Price | Impact |
|------|----------|----------|--------|
| Claude Opus 4.6 (long context) | Standard + surcharge for >200K tokens | Standard rate for all context lengths (no surcharge) | `cost-optimization-playbook.md` — material savings for large-context workloads. **HIGH priority update.** |
| Gemini 3.1 Pro | Not previously listed | $2/$12 per MTok | `cost-optimization-playbook.md` already has this. No update needed. |
| Gemini 3 Flash | Not previously listed | $0.50/$3 per MTok | Already in playbook. No update needed. |
| Cursor plans | Correct in guide | No change | Pro ($20), Pro+ ($60), Ultra ($200) — all match. |
| Claude API (Opus/Sonnet/Haiku) | Correct | No change | $5/$25, $3/$15, $1/$5 per MTok — all match current pricing. |

## Watching List Updates

| Topic | Status | Action |
|-------|--------|--------|
| Adversarial autonomous code review | **Matured significantly** | Anthropic launched Code Review in Claude Code (multi-agent, auto-flags logic errors). Cursor uses adversarial architecture (different models for gen vs review). Kodus AI 2.0. Cortex reports 23.5% increase in incidents/PR. | **Ready for deep-dive** |
| Multi-agent consensus/disagreement handling | Unchanged | No standardized patterns yet. CrewAI and LangGraph adding more coordination primitives but no consensus standard. | Keep watching |
| Enterprise MCP governance (auth, audit, SSO) | **Matured significantly** | MCP 2026 roadmap includes governance maturation. Multiple gateways now shipping: Lunar.dev MCPX (SOC 2/HIPAA/GDPR audit), MintMCP (SOC 2 Type II), MCP Gateway Registry (OAuth/SSO/audit). OAuth 2.1 in MCP spec since June 2025. | **Ready for deep-dive** |
| Contextual memory replacing RAG | Unchanged | Research progressing but no clear production adoption pattern yet. | Keep watching |
| SLM + Claude hybrid routing | Unchanged | Architecturally sound, still few verified production case studies. | Keep watching |
| Planner-coder gap resolution | Unchanged | Still an unsolved problem. No new major breakthroughs. | Keep watching |
| Agent-scale observability standards | Progressing | OpenTelemetry conventions advancing. Langfuse, LangSmith, Maxim all maturing. Not quite ready for standalone guide. | Keep watching |
| OpenClaw + NemoClaw enterprise maturity | **Major update** | NemoClaw launched at GTC (March 16, 2026). OpenShell runtime with kernel-level sandbox, policy engine, privacy router. Adobe/Salesforce/SAP/CrowdStrike/Dell as launch partners. Still alpha-stage with performance issues. 1,184 malicious ClawHub skills confirmed by Antiy CERT. | Update watching entry — keep watching (alpha stage, performance issues) |
| Semantic caching for AI apps | Progressing | Production patterns now documented: multi-layer caching (exact-match + semantic), 40-70% hit rates confirmed, Redis 8.4 native vector search. But guide already covers the concept well. | Keep watching — approaching deep-dive readiness |
| Model routing (SLM/LLM hybrid) in production | Unchanged | Still limited verified production case studies despite theoretical promise. | Keep watching |
| AI-generated code security scanning | **Matured significantly** | Anthropic launched Claude Code Security (research preview). OpenAI launched Codex Security (formerly Aardvark). Snyk DeepCode AI, GitHub Advanced Security + Copilot Autofix. Checkmarx, Codacy Guardrails. Real production tooling now exists. | **Ready for deep-dive** |
| Google A2A protocol + MCP convergence | **Major progression** | A2A v0.3 released. Donated to Linux Foundation. 150+ org backing (AWS, Google, MS, Salesforce, SAP). Microsoft wired into Copilot Studio, Amazon Bedrock AgentCore has native support. CrewAI has native A2A support. | **Ready for deep-dive** |

## New Topics Emerging

| Topic | Why It Matters | Source |
|-------|---------------|--------|
| Claude Code voice mode & /loop | Voice-driven coding and recurring agent monitoring are new workflow paradigms not covered in any guide | [Claude Code March 2026 changelog](https://code.claude.com/docs/en/changelog) |
| MCP Apps (interactive UIs in agents) | Cursor 2.6 MCP Apps enable charts, diagrams, whiteboards inside agent chats — changes how developers interact with agent output | [Cursor changelog](https://cursor.com/changelog) |
| Cursor JetBrains integration via ACP | Cursor now available in IntelliJ/PyCharm/WebStorm via Agent Client Protocol — expands tool comparison matrix significantly | [Cursor March 2026 updates](https://cursor.com/changelog) |
| MCP Gateways as infrastructure layer | Enterprise MCP gateways (Lunar.dev, MintMCP, MCP Gateway Registry) becoming a distinct infrastructure category with auth, audit, rate limiting | Multiple sources — 2026 MCP roadmap |
| FastMCP 3.x Code Mode | Servers that auto-discover and execute code for agents without pre-registering tools. Changes how MCP servers are architected. | [FastMCP 3.1 release](https://www.jlowin.dev/blog/fastmcp-3) |
| Anthropic long-context surcharge removal | 1M token contexts at standard rates changes cost/benefit for large-codebase analysis and RAG workloads | [Anthropic pricing update](https://platform.claude.com/docs/en/about-claude/pricing) |

## Recommendations Summary

### Ready for Deep-Dive (flag for Brian to initiate)
1. **Adversarial code review** — Anthropic Code Review, Cursor adversarial architecture, Codex Security. Enough tooling now exists for a practical guide.
2. **Enterprise MCP governance** — MCP gateways, OAuth 2.1, SOC 2 audit trails, SSO. Multiple production solutions now shipping.
3. **AI-generated code security scanning** — Claude Code Security, Codex Security, Snyk, GitHub Advanced Security. Ready for a comprehensive tools + workflow guide.
4. **A2A protocol** — v0.3, Linux Foundation governance, 150+ orgs, native support in Copilot Studio and Bedrock. Ready for integration guide with MCP.

### High-Priority Updates (auto-applied below)
1. Cost optimization playbook — long-context surcharge removal

### Medium-Priority Updates (manual review)
1. FastMCP 3.x in MCP server building guide
2. Claude Agent SDK naming standardization
3. Vercel AI SDK 6 in frontend features guide
4. Gemini CLI v0.34 features in Gemini power user guide
5. Claude Code new features (/voice, /loop, HTTP hooks) in Claude Code power user guide
6. Cursor 2.6 features in Cursor power user guide
