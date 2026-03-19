# Research Index

> Master directory of all research in this knowledge base. Check here before adding anything new.
> Last updated: 2026-03-18

## Research Outputs
| Date | File | Description |
|------|------|-------------|
| 2026-03-18 | [docs/research/SYNTHESIS.md](docs/research/SYNTHESIS.md) | **Main synthesis** — 12 key insights, recommendations, source index |
| 2026-03-18 | [docs/research/SCOPE.md](docs/research/SCOPE.md) | Research scope — AI-augmented dev productivity |
| 2026-03-18 | [docs/research/domain.md](docs/research/domain.md) | AI-assisted dev workflows — tools, patterns, anti-patterns |
| 2026-03-18 | [docs/research/landscape.md](docs/research/landscape.md) | Multi-agent/swarm architectures — 5 frameworks compared, orchestration patterns |
| 2026-03-18 | [docs/research/technical.md](docs/research/technical.md) | MCPs, plugins, skills — protocol details, servers, security, building patterns |
| 2026-03-18 | [docs/research/emerging.md](docs/research/emerging.md) | Cutting-edge 2025-2026 — AI-native backends, context management, SLMs, observability |

## Key Topics Covered
- **Dev tools**: Claude Code, Cursor, Copilot, Aider, Windsurf, Devin
- **Agent frameworks**: LangGraph, CrewAI, AG2, Claude Agent SDK, Mastra
- **Orchestration patterns**: Sequential, parallel, hierarchical, swarm, debate/consensus
- **MCP ecosystem**: Protocol spec, 10K+ servers, security concerns, building servers
- **Skills/Plugins/MCPs layering**: When to use each, how they compose
- **Workflow patterns**: TDD-first, spec-driven dev, plan-execute-verify, session discipline
- **Emerging**: AI-native backends, context management, SLMs, adversarial code review, observability

## Topics
| Date | File | Description |
|------|------|-------------|
| 2026-03-18 | [docs/topics/ai-native-architecture.md](docs/topics/ai-native-architecture.md) | **AI-Native Application Architecture** — Comprehensive guide to designing and building applications with AI at the core. Covers: the distinction between AI-native vs. AI features, agent-backend architecture patterns, RAG architectures and vector database selection (PostgreSQL pgvector benchmark: 471 QPS vs. Qdrant 41 QPS), agentic systems design, memory hierarchy (working/episodic/semantic), hybrid retrieval patterns, tech stack decisions (LangGraph vs. CrewAI vs. Claude Agent SDK), production patterns (evaluation/observability/cost management/security), 4 real-world examples (document analysis, internal tools, code review, learning platform), migration guidance, and implementation checklist. Includes decision trees, cost optimization strategies, security baselines, and architecture mistake patterns. |
| 2026-03-18 | [docs/topics/building-custom-mcp-servers.md](docs/topics/building-custom-mcp-servers.md) | **Building Custom MCP Servers: From Basics to Production** — Complete step-by-step guide covering MCP architecture, protocol details, three primitives (tools, resources, prompts), building servers in Python (FastMCP) and TypeScript, wrapping REST APIs, production security (OAuth 2.1, input validation, path sanitization), Docker deployment, testing with MCP Inspector, 3 real-world examples (internal API, database explorer, docs server), advanced patterns, debugging, and production readiness checklist. Includes full working code examples. |
| 2026-03-18 | [docs/topics/context-memory-systems.md](docs/topics/context-memory-systems.md) | **Context Management & Memory Systems** — Comprehensive practical guide to context and memory techniques for AI agents. Covers context editing (29% token reduction), persistent memory patterns (84% with memory files), hierarchical memory (short/medium/long-term), observation masking (52% cost reduction), MCP-based context enhancement, and tool-specific strategies for Claude Code, Cursor, and Gemini. Includes implementation checklist and production benchmarks. |
| 2026-03-18 | [docs/topics/openclaw-deep-dive.md](docs/topics/openclaw-deep-dive.md) | **OpenClaw Deep Dive** — Growth (100K stars in 6 weeks, Jensen Huang "next ChatGPT"), architecture (local agent, LLM reasoning, MCP integration), use cases (CI/CD, ops, automation), ecosystem (13.7K ClawHub skills), security (CVE-2026-25253 CVSS 8.8 one-click RCE, 820+ malicious skills, MS/Belgium CERT warnings), NemoClaw enterprise push (Adobe, Salesforce, SAP, CrowdStrike, Dell), fit with Claude Code/Cursor, recommendations |
| 2026-03-18 | [docs/topics/openclaw-skill-development.md](docs/topics/openclaw-skill-development.md) | **Building OpenClaw Skills: Comprehensive Guide** — Complete practical guide to building, testing, and publishing OpenClaw skills. Covers: skill architecture and ACP protocol, 5 skill types (tool, trigger, scheduled, workflow, multi-agent), step-by-step walkthrough of daily-digest skill, MCP server wrapping pattern (the 65% case), API integration patterns, trigger and scheduled skill examples, ClawHub ecosystem and publishing, security (input validation, credential handling, permission scoping, 36% of skills have flaws), NemoClaw hardening, testing workflows, 5 real-world examples (CI/CD monitor, email triage, competitor monitor, database queries, meeting→tasks), production checklist. Includes complete working code for every pattern. |
| 2026-03-18 | [docs/topics/swarm-patterns-by-dev-stage.md](docs/topics/swarm-patterns-by-dev-stage.md) | **Multi-Agent & Swarm Patterns by Development Stage** — Production-ready patterns for each dev stage (research, planning, coding, testing, review, debugging, docs, deployment, maintenance); includes pattern comparison matrix, implementation guides for LangGraph/CrewAI/Claude SDK, 9 detailed stage workflows with examples, code snippets, and anti-patterns |
| 2026-03-18 | [docs/topics/ai-research-strategies.md](docs/topics/ai-research-strategies.md) | **AI-Augmented Research Strategies** — Comprehensive guide for using AI tools (Claude, Gemini, Cursor, Perplexity) for high-quality pre-build research; covers hallucination detection, triangulation verification, tool-specific techniques, research workflows, staying current, verification patterns, anti-patterns, and recommended research stacks |
| 2026-03-18 | [docs/topics/best-of-breed-directory.md](docs/topics/best-of-breed-directory.md) | **Best of Breed Directory: AI Dev Tools** — Curated Tier 1/2/3 of essential tools (MCP servers, Claude skills, Cursor plugins, agent orchestration); 4 MCP essentials, 6 stack-specific guides, 30+ specialized tools; verified adoption via GitHub stars, FastMCP metrics, enterprise backing |
| 2026-03-18 | [docs/topics/best-repos-skills-plugins-mcps.md](docs/topics/best-repos-skills-plugins-mcps.md) | **Best GitHub Repos for Skills, Plugins, MCPs (2025-2026)** — 50+ production-ready repos: MCP servers (GitHub, Figma, Supabase, Playwright, Context7), Claude skills (1000+ battle-tested), Cursor .mdc rules, agent orchestration (Swarms, Ruflo), prompt libraries, security CVEs, token efficiency breakthrough |
| 2026-03-18 | [docs/topics/tool-comparison-when-to-use.md](docs/topics/tool-comparison-when-to-use.md) | **Claude Code vs Gemini vs Cursor — When to Use Each** — Decision matrix (20 tasks), head-to-head comparison (strengths/weaknesses/costs), 6 workflow scenarios, hybrid multi-tool setup, cost optimization strategies, feature matrix, developer survey data |
| 2026-03-18 | [docs/topics/claude-code-power-user.md](docs/topics/claude-code-power-user.md) | **Claude Code Power User Guide 2026** — TDD workflows, Plan Mode, spec-driven dev, subagents, MCPs, hooks, session discipline, keyboard shortcuts, real workflows |
| 2026-03-18 | [docs/topics/cursor-power-user.md](docs/topics/cursor-power-user.md) | **Cursor IDE Power User Guide 2026** — Cmd+K/L/I workflows, Composer, background agents, .mdc rules, MCP, TDD, model selection, Cursor+Claude Code hybrid |
| 2026-03-18 | [docs/topics/gemini-dev-power-user.md](docs/topics/gemini-dev-power-user.md) | **Gemini Dev Power User Guide 2026** — Gemini CLI, IDE integration, Google ADK, 2M context, Firebase Genkit, MCP support, Gemini vs Claude comparison |
| 2026-03-18 | [docs/topics/hooks-enforcement-patterns.md](docs/topics/hooks-enforcement-patterns.md) | **Hooks & Enforcement Patterns** — Comprehensive guide to using hooks for enforcing coding standards, security, testing, and workflow discipline. Covers: why hooks beat text rules (97-99% compliance vs 58-73%), hook architecture (4 types, exit codes, matchers), 18 production-ready patterns (testing, security, code quality, context, workflow, AI-specific), 5 complete production recipes (TypeScript, FastAPI, Go, monorepo, security-first), advanced hook composition, testing/debugging, decision framework, anti-patterns, and implementation checklist. Includes copy-paste-ready settings.json examples for every pattern. |
| 2026-03-18 | [docs/topics/prompt-engineering-patterns.md](docs/topics/prompt-engineering-patterns.md) | **Prompt Engineering Patterns for AI-Augmented Development** — Complete guide to systematic prompt engineering for coding. Covers: why prompts matter (76% error reduction with structure), CLAUDE.md as system prompt (best practices, real examples), 5 core patterns (specification-driven, chain-of-thought, few-shot, constraint-based, role-based), phase-specific prompts (research→planning→implementation→testing→review→debugging→docs), building prompt libraries, LLM-as-judge evaluation, testing prompts at scale (100 not 1), tool-specific patterns (Claude Code Plan Mode, Cursor @-mentions, Gemini long context), 15 production-ready templates (feature implementation, bug fix, refactoring, tests, code review, security audit, database migrations, API design, documentation, debugging, performance, etc.), anti-patterns to avoid, and prompt maintenance/versioning strategies. Tested patterns from 2025-2026 research. |

## Skills & Tools
| Date | File | Description |
|------|------|-------------|
| 2026-03-18 | [project-scaffold.skill](project-scaffold.skill) | **Project Scaffold Skill** — Generates complete AI tooling scaffold (CLAUDE.md, hooks, MCP configs, Cursor rules, agents.md, skills) from a plan doc or project description |
| 2026-03-18 | [project-research.skill](project-research.skill) | **Project Research Skill** — End-to-end idea vetting → domain research → implementation plan. Orchestrates agent-research and agent-plan with interview phase and checkpoints |

## Other
| Date | File | Description |
|------|------|-------------|
| 2026-03-18 | [DailyBriefing/](DailyBriefing/) | Auto-generated daily briefings on AI dev trends |

## Watching
| Date Added | Topic | Why |
|------------|-------|-----|
| 2026-03-18 | Adversarial autonomous code review | Pattern proven, industrial tooling expected Q3-Q4 2026 |
| 2026-03-18 | Multi-agent consensus/disagreement handling | No standardized patterns yet |
| 2026-03-18 | Enterprise MCP governance (auth, audit, SSO) | Promised for 2026, limited visibility |
| 2026-03-18 | Contextual memory replacing RAG | Research clear, production adoption unclear |
| 2026-03-18 | SLM + Claude hybrid routing | Architecturally sound, few production examples |
| 2026-03-18 | Planner-coder gap resolution | 7.9-83.3% robustness loss, unsolved |
| 2026-03-18 | Agent-scale observability standards | OpenTelemetry working on conventions |
| 2026-03-18 | OpenClaw + NemoClaw enterprise maturity | Security hardening in progress; NVIDIA partnership signals enterprise push but CVEs still emerging |
| 2026-03-18 | Semantic caching for AI apps | 40-70% hit rate reported, but production patterns still crystallizing |
| 2026-03-18 | Model routing (SLM/LLM hybrid) in production | 60% cost reduction potential, few verified production examples |
| 2026-03-18 | AI-generated code security scanning | 87% of AI PRs introduce vulnerabilities (DryRun Security); OpenAI Codex Security, CrowdStrike patterns emerging |
| 2026-03-18 | Google A2A protocol + MCP convergence | Peer-to-peer agent collaboration standard complementing MCP; adoption accelerating |
