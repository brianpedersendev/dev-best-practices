# Getting Started: AI-Augmented Development

> Ship top-of-the-line apps faster using AI tools, agents, and modern dev patterns.
> Last updated: 2026-03-18

---

## Top Takeaways

**1. Write tests before asking AI to code.** TDD + AI reduces defects 40-90%. This is the single highest-leverage practice — agents thrive with clear test contracts.

**2. Plan first, execute second.** Use Plan Mode (Claude) or Composer planning (Cursor) before auto-executing. Cuts token waste in half and prevents solving the wrong problem.

**3. Write specs, not vague prompts.** Specification-driven development (spec → phased tasks → incremental prompts → verify) reduces iteration cycles 30-50% vs. open-ended requests.

**4. Use the right tool for the task.** Claude Code for complex/autonomous work, Cursor for daily editing speed, Gemini for huge context and cost-sensitive tasks. No single tool wins everything.

**5. Layer your extensions: Skills → Plugins → MCPs.** Skills = reusable instructions. Plugins = bundled packages. MCPs = protocol-level tool access. Start simple, scale up.

**6. Verify everything.** AI hallucinates in ~1 of 6 queries. Triangulate across sources, check dates, and never trust confident tone as a proxy for correctness.

**7. Enforce rules with hooks, not text.** CLAUDE.md rules fade after context compression. Hooks run every time and can block dangerous actions deterministically.

---

## Guides

### How to Use Each Tool

- **[Claude Code Power User Guide](docs/topics/claude-code-power-user.md)** — TDD workflows, Plan Mode, spec-driven dev, subagents, hooks, session discipline, and keyboard shortcuts. The playbook for getting the most out of Claude Code.

- **[Cursor IDE Power User Guide](docs/topics/cursor-power-user.md)** — Cmd+K/L/I workflows, Composer for multi-file edits, background agents, .mdc rules, MCP setup, and model selection. How to work fast in Cursor.

- **[Gemini Dev Power User Guide](docs/topics/gemini-dev-power-user.md)** — Gemini CLI, 2M token context window, Google ADK for multi-agent, Firebase Genkit, and MCP support. When and why to reach for Gemini.

- **[Tool Comparison: When to Use Each](docs/topics/tool-comparison-when-to-use.md)** — Side-by-side decision matrix for 20 common tasks, head-to-head strengths/weaknesses, hybrid workflow patterns, and cost optimization strategies.

### What to Install

- **[Best of Breed Directory](docs/topics/best-of-breed-directory.md)** — Curated, tiered directory of the most impactful MCP servers, skills, plugins, and tools. Tier 1 (essential for everyone), Tier 2 (stack-specific), Tier 3 (specialized). Includes setup commands.

- **[Best GitHub Repos for Skills, Plugins, MCPs](docs/topics/best-repos-skills-plugins-mcps.md)** — 50+ production-ready repos with star counts, activity status, and what each does. The raw source list behind the curated directory.

### Building Custom Tools

- **[Building Custom MCP Servers](docs/topics/building-custom-mcp-servers.md)** — Complete guide to building your own MCP servers from scratch. Covers architecture, step-by-step tutorials for Python (FastMCP) and TypeScript, the three primitives (tools, resources, prompts), wrapping existing APIs, production security patterns, Docker deployment, testing, and real-world examples. Start here if you need custom integrations or internal tool access.

- **[Building OpenClaw Skills](docs/topics/openclaw-skill-development.md)** — Complete practical guide to building, testing, and publishing OpenClaw skills from basics to production. Covers skill architecture, the Agent Communication Protocol (ACP), 5 skill types with examples, the critical "65% pattern" (wrapping MCP servers as skills), ClawHub publishing and security, testing workflows, 5 real-world examples with complete code (CI/CD monitor, email triage, competitor monitor, database queries, meeting→tasks), and production readiness. Start here if you're building automation agents or want to publish to ClawHub.

### Prompt Engineering

- **[Prompt Engineering Patterns for AI-Augmented Development](docs/topics/prompt-engineering-patterns.md)** — Complete guide to writing and managing prompts that produce better AI outputs. Covers: why prompts matter (76% error reduction), CLAUDE.md as system prompts, 5 core patterns (specification-driven, chain-of-thought, few-shot, constraint-based, role-based), phase-specific prompts for each stage of development, evaluation frameworks (LLM-as-judge), 15 production-ready templates for common tasks (feature implementation, bug fix, testing, code review, security audit, etc.), and prompt versioning/maintenance. Start here to systematize your prompts and reduce iteration cycles 30-50%.

### How to Optimize Context & Memory

- **[Context Management & Memory Systems Guide](docs/topics/context-memory-systems.md)** — Practical techniques to reduce token usage by 29-84% through context editing, persistent memory, hierarchical memory architecture, and observation masking. Includes tool-specific strategies for Claude Code, Cursor, and Gemini, with implementation checklist and production benchmarks. Start here to make your AI tools faster and cheaper.

### How to Research Before Building

- **[AI Research Strategies Guide](docs/topics/ai-research-strategies.md)** — How to use AI tools for accurate, up-to-date research. Covers hallucination detection, triangulation, tool-specific techniques, research workflows, and staying current.

### AI-Native Application Architecture

- **[AI-Native Architecture Guide](docs/topics/ai-native-architecture.md)** — How to design and build applications where AI is the core, not a feature. Covers the distinction between AI-native and AI-augmented apps, agent-backend patterns, data architecture (RAG, vector storage, memory hierarchy), the 2026 tech stack (LangGraph vs CrewAI vs Claude Agent SDK), production patterns (evaluation, observability, cost, security), 4 real-world architecture examples, and decision trees. Start here if you're building a system around agents, not just adding an agent to an existing system.

### Multi-Agent & Swarm Patterns

- **[Swarm Patterns by Development Stage](docs/topics/swarm-patterns-by-dev-stage.md)** — The right multi-agent pattern for each phase of development: research, planning, coding, testing, review, debugging, docs, deployment, and maintenance. Includes agent team compositions, implementation guides for LangGraph/CrewAI/Claude SDK, code snippets, and cost analysis.

### Hooks & Enforcement

- **[Hooks & Enforcement Patterns](docs/topics/hooks-enforcement-patterns.md)** — The definitive guide to using hooks to enforce coding standards, security, testing, and workflow discipline. Covers why hooks (97-99% compliance) beat text rules (58-73%), hook architecture and exit codes, 18 production-ready patterns organized by purpose (testing, security, code quality, context, workflow), 5 complete recipes (TypeScript, FastAPI, Go, monorepo, security-first), advanced composition, testing and debugging, decision framework, and anti-patterns. Every pattern is copy-paste ready with complete settings.json examples.

### Project Bootstrapping

- **[Project Research Skill](project-research.skill)** — End-to-end skill for going from "I have an idea" to a validated, actionable plan. Runs a thorough idea interview, orchestrates multi-agent domain research, then produces an implementation plan with go/no-go checkpoints between each phase.

- **[Project Scaffold Skill](project-scaffold.skill)** — Generates a complete AI tooling scaffold from a plan doc or description. Creates CLAUDE.md, hooks, MCP configs, Cursor rules, agent team definitions, and dev workflow skills — all tailored to your stack. Use after the research skill produces a plan.

### Full Research

- **[Research Synthesis](docs/research/SYNTHESIS.md)** — The master document: 12 key insights, framework comparisons, opportunity rankings, risk analysis, and concrete recommendations. Start here for the full picture.

---

## Quick Start Checklist

1. Read the [Tool Comparison](docs/topics/tool-comparison-when-to-use.md) to pick your primary workflow
2. Set up Tier 1 tools from the [Best of Breed Directory](docs/topics/best-of-breed-directory.md)
3. Skim your tool's power user guide ([Claude](docs/topics/claude-code-power-user.md) / [Cursor](docs/topics/cursor-power-user.md) / [Gemini](docs/topics/gemini-dev-power-user.md))
4. Adopt the plan → test → implement → verify loop
5. Before your next build, use the [Research Strategies](docs/topics/ai-research-strategies.md) to scope what exists first
