# Weekly Knowledge Audit — 2026-03-28

## Staleness Findings

| Guide | Issue | Severity | Action Needed |
|-------|-------|----------|---------------|
| cost-optimization-playbook.md | Cursor pricing table (line 44-49) lists request counts (500, 1,500, 10,000) per plan tier — Cursor moved to a credit-based billing model (June 2025). The table mixes old request counts with the newer credit info below it. Confusing. | **Medium** | Rewrite Cursor pricing section to use credit-based model consistently. Remove request count columns. Note: Pro = $20 credits, Pro+ = $60 credits, Ultra = $200 credits. |
| cursor-power-user.md | Cursor v2.6.21 (Mar 23, 2026) added JetBrains IDE support via Agent Client Protocol (ACP) on Mar 4. Self-hosted cloud agents on Mar 25. Guide doesn't mention either. | **Medium** | Add JetBrains ACP support and self-hosted cloud agents as new capabilities. |
| gemini-dev-power-user.md | Gemini CLI now at v0.35.2 (Mar 26) with subagents enabled by default, vim mode, custom keybindings, Linux sandboxing (bubblewrap/seccomp). Guide may not reflect these. | **Medium** | Verify guide covers subagents-by-default and sandboxing features. |
| claude-code-power-user.md | Claude Code v2.1.86 (Mar 27): new --bare flag for scripted calls, --channels permission relay (phone push), voice mode (20 languages, push-to-talk), /loop scheduled tasks, Computer Use + Remote Control. Guide may not cover recent features. | **Medium** | Check guide for /loop, --bare, --channels, voice mode, Computer Use + Remote Control coverage. |
| building-custom-mcp-servers.md | FastMCP 3.1.1 released (Mar 14) with "Code Mode" — servers that find and execute code on behalf of agents without clients knowing what tools exist. Guide doesn't pin a version but should mention Code Mode as a major new pattern. | **Medium** | Add a section or note about FastMCP 3.1 Code Mode (provider/transform architecture, dynamic tool discovery). |
| ai-native-architecture.md | CrewAI now at v1.10.1 (45.9K stars, native A2A + MCP). LangGraph at v1.0.10 (38M monthly PyPI downloads). Guide references these frameworks — verify versions are current. | **Medium** | Spot-check framework version references and update if stale. |
| openclaw-deep-dive.md | OpenClaw v2026.3.22 released with ClawHub marketplace integration, /btw side conversations, multi-model sub-agents, adjustable sub-agent thinking. NemoClaw still alpha. | **Low** | Minor update to note latest OpenClaw release features. INDEX.md watching entry already up to date. |
| best-repos-skills-plugins-mcps.md | Repos were last verified Mar 18 (10 days ago). All major repos still active. Claude Code at 81.6K stars per recent sources. | **Low** | No urgent changes. Schedule next spot-check for next week. |

## Repository Health

| Repo | Status | Notes |
|------|--------|-------|
| anthropics/claude-code | Active | v2.1.86 (Mar 27). 81.6K+ stars. Very active release cadence. |
| modelcontextprotocol/servers | Active | Still primary reference implementation repo. Actively maintained. |
| PrefectHQ/fastmcp (Python) | Active | v3.1.1 (Mar 14). Major Code Mode release. 100K+ pre-release installs for 3.0. |
| google-gemini/gemini-cli | Active | v0.35.2 stable (Mar 26), v0.36.0-preview.5 (Mar 27). Very active. |
| NVIDIA/NemoClaw | Active (Alpha) | Early preview since Mar 16. Not production-ready. |
| crewAIInc/crewAI | Active | v1.10.1. 45.9K stars. 12M daily agent executions. Native A2A + MCP. |
| langchain-ai/langgraph | Active | v1.0.10. 38M monthly PyPI downloads. Mature and stable. |

## Pricing Changes

| Tool | Old Price | New Price | Impact |
|------|----------|----------|--------|
| Claude API | Same | Opus 4.6: $5/$25, Sonnet 4.6: $3/$15, Haiku 4.5: $1/$5 | No change from guide. Pricing is current. |
| Cursor | Request-based table in guide | Credit-based ($20/$60/$200 monthly credit pools) | **Medium** — cost-optimization-playbook.md table at lines 44-49 uses old request count framing. |
| Gemini API | Same | Same as in guide | No change detected. |

## Watching List Updates

| Topic | Status | Action |
|-------|--------|--------|
| Adversarial autonomous code review | **Matured** | Anthropic launched Code Review in Claude Code (enterprise, multi-agent). ASDLC.io published formal pattern. Adversarial review skills appearing on marketplaces. Autonomous remediation emerging. **Ready for deep-dive.** |
| Multi-agent consensus/disagreement handling | Unchanged | No standardized patterns yet. CrewAI and LangGraph both have custom approaches but no standard. Keep watching. |
| Enterprise MCP governance (auth, audit, SSO) | Unchanged | Still limited visibility. MCP spec continues evolving but no major governance announcement. Keep watching. |
| Contextual memory replacing RAG | **Maturing** | Claude Opus 4.6 contextual memory, "observational memory" cutting costs 10x, VentureBeat predicting RAG decline for agentic use. RAG still useful for static data. Not quite ready for full guide — production patterns still crystallizing. Keep watching, upgrade to "near ready." |
| SLM + Claude hybrid routing | **Maturing** | Router pattern now described as standard in 2026 guides. 80/20 SLM/LLM split common. Multiple production examples now exist. 75% cost reduction documented. **Approaching ready for deep-dive.** |
| Planner-coder gap resolution | Unchanged | Still an open problem. No major breakthroughs found. Keep watching. |
| Agent-scale observability standards | **Maturing** | OTel GenAI Semantic Conventions finalized. 70%+ enterprise agent deployments using OTel. Datadog, Elastic, VictoriaMetrics all supporting. CrewAI, Pydantic AI emit OTel natively. **Ready for deep-dive.** |
| OpenClaw + NemoClaw enterprise maturity | Unchanged | NemoClaw still alpha (Mar 16 launch). OpenClaw v2026.3.22 released with ClawHub integration. INDEX.md already updated through Mar 21. Keep watching. |
| Semantic caching for AI apps | **Maturing** | Production-ready tools: Bifrost, GPTCache, Upstash Semantic Cache. 40-68% cost reduction documented. False positive mitigation patterns emerging. Near ready for deep-dive. |
| Model routing (SLM/LLM hybrid) in production | **Maturing** | See SLM hybrid routing above. Converging topic. |
| AI-generated code security scanning | **Matured** | Claude Code Security (research preview), Snyk Agent Scan (15+ risk types), Snyk AI Security Fabric, GitHub Advanced Security + Copilot Autofix all production-ready. Already flagged as "Ready for deep-dive" in INDEX.md. **Confirm: ready.** |
| Google A2A protocol + MCP convergence | **Matured** | A2A v1.0, donated to Linux Foundation, 50+ partners, gRPC support, Python SDK, native in CrewAI/Copilot Studio/Bedrock AgentCore. Already flagged in INDEX.md. **Confirm: ready.** |
| OpenAI acquires Astral (Ruff/uv) | Unchanged | Added Mar 22. Still early — watch for lock-in concerns with Python toolchain. Keep watching. |
| Multi-model selection as standard | Unchanged | Added Mar 22. Correctly noted as table stakes. Keep watching for model-agnostic workflow patterns. |

## New Topics Emerging

| Topic | Why It Matters | Source |
|-------|---------------|--------|
| Claude Code /loop (scheduled tasks) | Claude Code can now run as a background worker with cron-like scheduling — enables autonomous PR reviews, deployment monitoring, code quality sweeps. Changes how developers think about Claude Code (not just interactive). | Claude Code v2.1.x changelog, March 2026 |
| Claude Code --channels (phone push permissions) | Permission relay to phone for remote approval — research preview. Enables truly headless agent operation with human-in-the-loop via mobile. | Claude Code changelog, March 2026 |
| Cursor JetBrains ACP support | Cursor now works in IntelliJ/PyCharm/WebStorm via Agent Client Protocol. Breaks Cursor out of VS Code lock-in. Significant for Java/multilanguage teams. | cursor.com changelog, March 4 2026 |
| Cursor self-hosted cloud agents | Self-hosted agents keep code and secrets on your infrastructure while using frontier models. Addresses enterprise security concerns. | cursor.com changelog, March 25 2026 |
| FastMCP 3.1 Code Mode | Servers can find and execute code on behalf of agents without clients knowing what tools exist. Major capability expansion for MCP ecosystem. | fastmcp.com, March 2026 |
| Autonomous code remediation | AI proactively scans codebases, identifies issues, generates fixes, opens PRs — moving beyond review to automated fixing. Multiple tools exploring this in early 2026. | TechCrunch, ASDLC.io, March 2026 |

## Summary of Recommended Actions

### HIGH Priority
None this week — no clearly wrong information found.

### MEDIUM Priority (flagged for manual review)
1. **building-custom-mcp-servers.md** — Add FastMCP 3.1 Code Mode as a new pattern/capability
2. **cost-optimization-playbook.md** — Rewrite Cursor pricing table to use credit-based model
3. **cursor-power-user.md** — Add JetBrains ACP support and self-hosted cloud agents
4. **gemini-dev-power-user.md** — Add subagents-by-default, sandboxing features
5. **claude-code-power-user.md** — Add /loop, --bare, --channels, voice mode, Computer Use + Remote Control
6. **ai-native-architecture.md** — Verify CrewAI/LangGraph version references

### Topics Ready for Deep-Dive
7. **AI-generated code security scanning** — Already flagged, confirmed ready
8. **Google A2A protocol + MCP convergence** — Already flagged, confirmed ready
9. **Adversarial autonomous code review** — Newly matured, recommend deep-dive
10. **Agent-scale observability (OTel GenAI)** — OTel conventions finalized, 70%+ adoption, ready

### Topics Approaching Ready
11. **SLM/LLM hybrid routing** — Production patterns solidifying, may be ready in 2-4 weeks
12. **Semantic caching** — Production tools available, patterns crystallizing
13. **Contextual memory vs RAG** — Significant momentum but production patterns still forming
