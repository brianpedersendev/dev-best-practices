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

### How to Research Before Building

- **[AI Research Strategies Guide](docs/topics/ai-research-strategies.md)** — How to use AI tools for accurate, up-to-date research. Covers hallucination detection, triangulation, tool-specific techniques, research workflows, and staying current.

### Full Research

- **[Research Synthesis](docs/research/SYNTHESIS.md)** — The master document: 12 key insights, framework comparisons, opportunity rankings, risk analysis, and concrete recommendations. Start here for the full picture.

---

## Quick Start Checklist

1. Read the [Tool Comparison](docs/topics/tool-comparison-when-to-use.md) to pick your primary workflow
2. Set up Tier 1 tools from the [Best of Breed Directory](docs/topics/best-of-breed-directory.md)
3. Skim your tool's power user guide ([Claude](docs/topics/claude-code-power-user.md) / [Cursor](docs/topics/cursor-power-user.md) / [Gemini](docs/topics/gemini-dev-power-user.md))
4. Adopt the plan → test → implement → verify loop
5. Before your next build, use the [Research Strategies](docs/topics/ai-research-strategies.md) to scope what exists first
