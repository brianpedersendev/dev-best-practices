# Getting Started: AI-Augmented Development

> Ship top-of-the-line apps faster using AI tools, agents, and modern dev patterns.
> Last updated: 2026-03-29

---

## Top Takeaways

1. **Write tests before asking AI to code.** TDD + AI reduces defects 40-90%. Agents thrive with clear test contracts.
2. **Plan first, execute second.** Use Plan Mode or Composer planning before auto-executing. Cuts token waste in half.
3. **Write specs, not vague prompts.** Spec-driven development reduces iteration cycles 30-50%.
4. **Use the right tool for the task.** Claude Code for complex/autonomous work, Cursor for daily editing, Gemini for huge context.
5. **Layer your extensions: Skills → Plugins → MCPs.** Start simple, scale up.
6. **Verify everything.** AI hallucinates ~1 in 6 queries. Triangulate across sources.
7. **Enforce rules with hooks, not text.** CLAUDE.md rules fade after context compression. Hooks run every time.

---

## Tool Guides

- **[Claude Code Power User](docs/topics/claude-code-power-user.md)** — TDD workflows, Plan Mode, subagents, hooks, session discipline. The main playbook.
- **[Cursor IDE Power User](docs/topics/cursor-power-user.md)** — Cmd+K/L/I, Composer, background agents, .mdc rules, MCP setup.
- **[Gemini Dev Power User](docs/topics/gemini-dev-power-user.md)** — Gemini CLI, 2M token context, ADK for multi-agent, Firebase Genkit.
- **[Tool Comparison](docs/topics/tool-comparison-when-to-use.md)** — Side-by-side decision matrix for 20 common tasks, hybrid workflow patterns.

## Core Workflow

- **[Hooks & Enforcement Patterns](docs/topics/hooks-enforcement-patterns.md)** — 18 production-ready hook patterns for testing, security, code quality. Copy-paste ready.
- **[Testing AI-Generated Code](docs/topics/testing-ai-generated-code.md)** — TDD as foundation, security testing, AI-assisted test generation, verification workflow.
- **[Prompt Engineering Patterns](docs/topics/prompt-engineering-patterns.md)** — 5 core patterns, 15 production-ready templates, prompt versioning.
- **[AI-Assisted Debugging](docs/topics/ai-assisted-debugging.md)** — Multi-agent hypothesis swarm (11 min vs 45+ min traditional), 15 copy-paste prompts.
- **[Adversarial Code Review](docs/topics/adversarial-code-review.md)** — Independent AI reviewers that catch bugs the builder agent misses.
- **[Context Management & Memory](docs/topics/context-memory-systems.md)** — Reduce token usage 29-84% through context editing, persistent memory, observation masking.

## Architecture & Systems

- **[AI-Native Architecture](docs/topics/ai-native-architecture.md)** — Agent-backend patterns, RAG, memory hierarchy, tech stack decisions (LangGraph vs CrewAI vs Claude SDK).
- **[Building Custom MCP Servers](docs/topics/building-custom-mcp-servers.md)** — Step-by-step for Python (FastMCP) and TypeScript. Wrapping APIs, security, Docker deployment.
- **[Swarm Patterns by Dev Stage](docs/topics/swarm-patterns-by-dev-stage.md)** — The right multi-agent pattern for research, planning, coding, testing, review, and deployment.
- **[Error Recovery & Fallback Patterns](docs/topics/error-recovery-patterns.md)** — Cascading model fallbacks, circuit breakers, graceful degradation. Ship this before going to production.
- **[RAG Staleness Detection](docs/topics/rag-staleness-detection.md)** — Freshness scoring, embedding drift detection, automated refresh pipelines.
- **[A2A Protocol + MCP Convergence](docs/topics/a2a-protocol-mcp-convergence.md)** — Google's A2A for agent-to-agent communication alongside MCP's agent-to-tool access.

## What to Install

- **[Best of Breed Directory](docs/topics/best-of-breed-directory.md)** — Tiered directory: Tier 1 (essential), Tier 2 (stack-specific), Tier 3 (specialized). Includes setup commands.
- **[Best GitHub Repos](docs/topics/best-repos-skills-plugins-mcps.md)** — 50+ production-ready repos for skills, plugins, and MCPs.

---

## More Topics

These are useful but more situational — reference as needed:

- [Cost Optimization Playbook](docs/topics/cost-optimization-playbook.md) — Cut AI spending 50-70%
- [AI on Large Codebases](docs/topics/ai-on-large-codebases.md) — Strategies for 100K+ line projects
- [AI in Legacy Codebases](docs/topics/ai-in-legacy-codebases.md) — Bringing AI to underdocumented/inconsistent code
- [Team AI Onboarding](docs/topics/team-ai-onboarding.md) — 3-month phased rollout, shared CLAUDE.md governance
- [Multi-Model Governance](docs/topics/multi-model-governance.md) — Keeping codebases consistent across Claude/Cursor/Gemini
- [AI Integration Death Valley](docs/topics/ai-integration-death-valley.md) — Surviving the productivity trough
- [Deployment & DevOps](docs/topics/ai-app-deployment-devops.md) — CI/CD, containerization, observability for AI apps
- [CI/CD AI Integration Safety](docs/topics/cicd-ai-integration-safety.md) — Safe entry points, flaky test prevention, cost control
- [Security Scanning](docs/topics/ai-code-security-scanning.md) — 9 tools, AI-specific vulnerabilities, pipeline setup
- [Agent Observability](docs/topics/agent-observability-otel.md) — OTel GenAI instrumentation for production agents
- [Evaluation Beyond LLM-as-Judge](docs/topics/evaluation-beyond-llm-judge.md) — Statistical rigor, domain-expert rubrics, A/B testing
- [When NOT to Use AI](docs/topics/when-not-to-use-ai.md) — Where traditional code beats AI
- [Decision Trees](docs/topics/decision-trees.md) — Resolves conflicting advice across guides

### Design & Frontend
- [AI-Powered Frontend Features](docs/topics/ai-powered-frontend-features.md) — Streaming chat, semantic search, content generation
- [AI Design Workflow](docs/topics/ai-design-workflow.md) — Design-to-code pipelines, Figma MCP, v0, component generation
- [AI-First UX Patterns](docs/topics/ai-first-ux-patterns.md) — UX for non-deterministic AI, trust calibration, interaction patterns

### Building Custom Tools
- [AI-Assisted API Design](docs/topics/ai-assisted-api-design.md) — Contract-first development, spec → code → test
- [OpenClaw Skill Development](docs/topics/openclaw-skill-development.md) — Building and publishing OpenClaw skills
- [AI Research Strategies](docs/topics/ai-research-strategies.md) — Hallucination detection, triangulation, research workflows
- [Remote Dev Environment Setup](docs/topics/remote-dev-environment-setup.md) — Secrets management, SSH, Codespaces, devcontainers

### Skills & Automation
- [Project Research Skill](project-research.skill) — Idea vetting → research → plan pipeline
- [Project Scaffold Skill](project-scaffold.skill) — Generates CLAUDE.md, hooks, MCP configs from a plan
- [Daily Briefing Skill](daily-briefing.skill) — Auto-generated AI dev trend briefings
- [Knowledge Review Skill](knowledge-review.skill) — Quality audit of the knowledge base
- [Topic Deep Dive Skill](topic-deep-dive.skill) — Research and write new topic guides

---

## Quick Start Checklist

1. Read the [Tool Comparison](docs/topics/tool-comparison-when-to-use.md) to pick your primary workflow
2. Set up Tier 1 tools from the [Best of Breed Directory](docs/topics/best-of-breed-directory.md)
3. Skim your tool's power user guide ([Claude](docs/topics/claude-code-power-user.md) / [Cursor](docs/topics/cursor-power-user.md) / [Gemini](docs/topics/gemini-dev-power-user.md))
4. Adopt the plan → test → implement → verify loop
5. Set up [hooks](docs/topics/hooks-enforcement-patterns.md) for your most important rules
