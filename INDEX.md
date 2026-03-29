# Research Index

> Master directory of all research in this knowledge base. Check here before adding anything new.
> Last updated: 2026-03-29

## Key Topics Covered
- **Dev tools**: Claude Code, Cursor, Copilot, Aider, Windsurf, Devin
- **Agent frameworks**: LangGraph, CrewAI, AG2, Claude Agent SDK, Mastra
- **Orchestration patterns**: Sequential, parallel, hierarchical, swarm, debate/consensus
- **MCP ecosystem**: Protocol spec, 21K+ servers, security concerns, building servers
- **Skills/Plugins/MCPs layering**: When to use each, how they compose
- **Workflow patterns**: TDD-first, spec-driven dev, plan-execute-verify, session discipline
- **Emerging**: AI-native backends, context management, SLMs, adversarial code review, observability
- **Production ops**: Error recovery/fallback, deployment/DevOps, cost optimization
- **Decision support**: When NOT to use AI, unified decision trees resolving cross-doc conflicts

## Topics

| Date | File | Description |
|------|------|-------------|
| 2026-03-28 | [agent-observability-otel.md](docs/topics/agent-observability-otel.md) | OTel GenAI instrumentation for production agents — spans, cost tracking, quality monitoring, platform comparison |
| 2026-03-28 | [a2a-protocol-mcp-convergence.md](docs/topics/a2a-protocol-mcp-convergence.md) | Google A2A + MCP — when to use each, protocol details, SDK examples, framework integration |
| 2026-03-28 | [adversarial-code-review.md](docs/topics/adversarial-code-review.md) | Independent AI reviewers catching bugs the builder misses — 5 implementation patterns, CI/CD integration |
| 2026-03-28 | [ai-code-security-scanning.md](docs/topics/ai-code-security-scanning.md) | 9 security scanning tools, AI-specific vulnerabilities, pipeline setup by team size |
| 2026-03-19 | [ai-app-deployment-devops.md](docs/topics/ai-app-deployment-devops.md) | CI/CD, containers, observability, cost controls, security for AI apps in production |
| 2026-03-19 | [ai-assisted-api-design.md](docs/topics/ai-assisted-api-design.md) | Contract-first API dev — spec generation, stub generation, contract testing, MCP server design |
| 2026-03-19 | [ai-assisted-debugging.md](docs/topics/ai-assisted-debugging.md) | Multi-agent hypothesis swarm for debugging, 15 copy-paste prompts, tool-specific workflows |
| 2026-03-19 | [ai-design-workflow.md](docs/topics/ai-design-workflow.md) | Design-to-code pipelines — Figma MCP, v0, Cursor UI generation, component patterns |
| 2026-03-19 | [ai-first-ux-patterns.md](docs/topics/ai-first-ux-patterns.md) | UX for non-deterministic AI — trust calibration, 8 interaction patterns, confidence visualization |
| 2026-03-19 | [ai-in-legacy-codebases.md](docs/topics/ai-in-legacy-codebases.md) | Bringing AI to underdocumented code — assessment scorecard, test-first migration, 3-month roadmap |
| 2026-03-19 | [ai-integration-death-valley.md](docs/topics/ai-integration-death-valley.md) | Surviving the 4-12 week productivity trough after AI adoption |
| 2026-03-18 | [ai-native-architecture.md](docs/topics/ai-native-architecture.md) | Agent-backend patterns, RAG, memory hierarchy, tech stack decisions, 4 real-world examples |
| 2026-03-19 | [ai-on-large-codebases.md](docs/topics/ai-on-large-codebases.md) | Strategies for 100K+ LOC — onboarding, context at scale, monorepos, team coordination |
| 2026-03-19 | [ai-powered-frontend-features.md](docs/topics/ai-powered-frontend-features.md) | Streaming chat, semantic search, recommendations, content generation — 5 copy-paste recipes |
| 2026-03-19 | [ai-research-strategies.md](docs/topics/ai-research-strategies.md) | Hallucination detection, triangulation, tool-specific research techniques |
| 2026-03-19 | [best-of-breed-directory.md](docs/topics/best-of-breed-directory.md) | Tiered directory of MCPs, skills, plugins, tools — Tier 1/2/3 with setup commands |
| 2026-03-19 | [best-repos-skills-plugins-mcps.md](docs/topics/best-repos-skills-plugins-mcps.md) | 50+ production-ready repos with star counts and activity status |
| 2026-03-18 | [building-custom-mcp-servers.md](docs/topics/building-custom-mcp-servers.md) | Step-by-step MCP server building — Python/TypeScript, API wrapping, security, Docker |
| 2026-03-19 | [cicd-ai-integration-safety.md](docs/topics/cicd-ai-integration-safety.md) | Safe CI/CD entry points, flaky test prevention, cost control, GitHub Actions/GitLab examples |
| 2026-03-18 | [claude-code-power-user.md](docs/topics/claude-code-power-user.md) | TDD, Plan Mode, spec-driven dev, subagents, hooks, session discipline, keyboard shortcuts |
| 2026-03-18 | [context-memory-systems.md](docs/topics/context-memory-systems.md) | Token reduction 29-84% — context editing, persistent memory, observation masking |
| 2026-03-19 | [cost-optimization-playbook.md](docs/topics/cost-optimization-playbook.md) | Cut AI spending 50-70% — model routing, caching, tool selection, team budgeting |
| 2026-03-18 | [cursor-power-user.md](docs/topics/cursor-power-user.md) | Cmd+K/L/I, Composer, background agents, .mdc rules, MCP setup, model selection |
| 2026-03-19 | [decision-trees.md](docs/topics/decision-trees.md) | Resolves 4 cross-document conflicts — agents vs functions, optimization sequence, caching, eval thresholds |
| 2026-03-19 | [error-recovery-patterns.md](docs/topics/error-recovery-patterns.md) | Cascading fallbacks, circuit breakers, graceful degradation, SLOs for non-deterministic systems |
| 2026-03-19 | [evaluation-beyond-llm-judge.md](docs/topics/evaluation-beyond-llm-judge.md) | Statistical rigor, domain-expert rubrics, automated metrics, A/B testing, composite pipelines |
| 2026-03-18 | [gemini-dev-power-user.md](docs/topics/gemini-dev-power-user.md) | Gemini CLI, 2M context, ADK multi-agent, Firebase Genkit, MCP support |
| 2026-03-19 | [hooks-enforcement-patterns.md](docs/topics/hooks-enforcement-patterns.md) | 18 copy-paste hook patterns — testing, security, code quality, workflow enforcement |
| 2026-03-19 | [multi-model-governance.md](docs/topics/multi-model-governance.md) | Keeping codebases consistent across Claude/Cursor/Gemini — rulesync, shared enforcement |
| 2026-03-18 | [openclaw-deep-dive.md](docs/topics/openclaw-deep-dive.md) | OpenClaw architecture, ecosystem, security (CVE-2026-25253), NemoClaw enterprise |
| 2026-03-19 | [openclaw-skill-development.md](docs/topics/openclaw-skill-development.md) | Building/publishing OpenClaw skills — 5 types, ACP protocol, ClawHub, 5 real-world examples |
| 2026-03-19 | [prompt-engineering-patterns.md](docs/topics/prompt-engineering-patterns.md) | 5 core patterns, 15 production templates, prompt versioning and evaluation |
| 2026-03-19 | [rag-staleness-detection.md](docs/topics/rag-staleness-detection.md) | Freshness scoring, embedding drift, knowledge versioning, automated refresh pipelines |
| 2026-03-19 | [remote-dev-environment-setup.md](docs/topics/remote-dev-environment-setup.md) | Secrets management for remote Claude Code — 4 patterns, SSH, Codespaces, devcontainers |
| 2026-03-19 | [swarm-patterns-by-dev-stage.md](docs/topics/swarm-patterns-by-dev-stage.md) | Right multi-agent pattern per dev phase — agent teams, LangGraph/CrewAI/Claude SDK |
| 2026-03-19 | [team-ai-onboarding.md](docs/topics/team-ai-onboarding.md) | 3-month phased rollout, shared CLAUDE.md governance, quality gates, 5 templates |
| 2026-03-19 | [testing-ai-generated-code.md](docs/topics/testing-ai-generated-code.md) | TDD foundation, security testing, verification workflow, 25+ code examples |
| 2026-03-19 | [tool-comparison-when-to-use.md](docs/topics/tool-comparison-when-to-use.md) | Decision matrix for 20 tasks, head-to-head strengths, hybrid workflows, cost optimization |
| 2026-03-19 | [when-not-to-use-ai.md](docs/topics/when-not-to-use-ai.md) | Where traditional code beats AI — decision framework, red flags, cost-benefit checks |

## Research Outputs

| Date | File | Description |
|------|------|-------------|
| 2026-03-18 | [docs/research/SYNTHESIS.md](docs/research/SYNTHESIS.md) | Main synthesis — 12 key insights, recommendations, source index |
| 2026-03-18 | [docs/research/SCOPE.md](docs/research/SCOPE.md) | Research scope — AI-augmented dev productivity |
| 2026-03-18 | [docs/research/domain.md](docs/research/domain.md) | AI-assisted dev workflows — tools, patterns, anti-patterns |
| 2026-03-18 | [docs/research/landscape.md](docs/research/landscape.md) | Multi-agent/swarm architectures — 5 frameworks compared |
| 2026-03-18 | [docs/research/technical.md](docs/research/technical.md) | MCPs, plugins, skills — protocol details, security, building patterns |
| 2026-03-18 | [docs/research/emerging.md](docs/research/emerging.md) | Cutting-edge 2025-2026 — AI-native backends, context, SLMs, observability |
| 2026-03-28 | [docs/research/a2a-internal-tooling/](docs/research/a2a-internal-tooling/) | A2A for internal dev tooling — domain, technical pitfalls, minimum viable setup |
| 2026-03-19 | [docs/research/REVIEW-2026-03-19.md](docs/research/REVIEW-2026-03-19.md) | Knowledge base audit — all 7 recommended actions completed |

## References

| Date | File | Description |
|------|------|-------------|
| 2026-03-19 | [references/tools-and-frameworks.md](references/tools-and-frameworks.md) | Links to AI dev tools, agent frameworks, MCP ecosystem |
| 2026-03-19 | [references/research-and-reports.md](references/research-and-reports.md) | Research papers, industry reports, benchmarks |
| 2026-03-19 | [references/tutorials-and-guides.md](references/tutorials-and-guides.md) | How-to guides, blog posts, tutorials |

## Example Projects

| Date | File | Description |
|------|------|-------------|
| 2026-03-21 | [docs/stock-mcp-plan/](docs/stock-mcp-plan/) | Stock Analyst MCP — FastMCP 3.0, yfinance+Finnhub, personal investment KB |
| 2026-03-19 | [examples/fishing-copilot/](examples/fishing-copilot/) | Fishing Copilot — daily briefing app, Claude Haiku, Twilio SMS |
| 2026-03-19 | [examples/life-assistant/](examples/life-assistant/) | Life Assistant (LifeOS) — modular AI life assistant, MCP-per-domain |
| 2026-03-19 | [examples/woodworking-sidekick/](examples/woodworking-sidekick/) | AI Woodworking Sidekick — plan generation, wood movement validation |

## Other

| Date | File | Description |
|------|------|-------------|
| 2026-03-18 | [DailyBriefing/](DailyBriefing/) | Auto-generated daily briefings on AI dev trends |

## Watching

| Date Added | Topic | Status |
|------------|-------|--------|
| 2026-03-18 | Multi-agent consensus/disagreement handling | No standardized patterns yet |
| 2026-03-18 | Enterprise MCP governance (auth, audit, SSO) | Promised for 2026, limited visibility |
| 2026-03-18 | Contextual memory replacing RAG | Production patterns still crystallizing. Claude Opus 4.6 contextual memory cutting costs 10x. |
| 2026-03-18 | SLM + Claude hybrid routing | Router pattern now standard — 80/20 split, 75% cost reduction. Approaching ready for deep-dive. |
| 2026-03-18 | Planner-coder gap resolution | 7.9-83.3% robustness loss, unsolved |
| 2026-03-18 | OpenClaw + NemoClaw enterprise maturity | 210K+ stars. 1,184 malicious ClawHub skills confirmed. NemoClaw launched with enterprise partners. |
| 2026-03-18 | Semantic caching for AI apps | Production-ready tools emerging (Bifrost, GPTCache). 40-68% cost reduction. Near ready for deep-dive. |
| 2026-03-18 | Model routing (SLM/LLM hybrid) in production | 60% cost reduction potential, few verified production examples |
| 2026-03-22 | OpenAI acquires Astral (Ruff/uv) | Signals deeper toolchain ownership for Codex. Watch for lock-in. |
| 2026-03-22 | Multi-model selection as standard | Table stakes, not differentiator. Watch for model-agnostic workflow patterns. |
