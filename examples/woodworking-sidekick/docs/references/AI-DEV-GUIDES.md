# AI Development Reference Guides

Quick links to research and best practices that inform how this project is set up.

## Most Relevant to This Project

### Workflow & Tools
- **Claude Code Power User Guide** — TDD workflows, Plan Mode, hooks, session discipline. Explains CLAUDE.md structure and hook configurations.
- **Cursor IDE Power User Guide** — Cmd+K/L/I workflows, Composer, .mdc rules. Explains the .cursor/rules/ configuration.
- **Tool Comparison: When to Use Each** — Decision matrix for choosing between Claude Code, Cursor, Gemini for different tasks.

### Architecture & Patterns
- **AI-Native Architecture** — Architecture patterns for apps built around AI. Covers agent backends, RAG, evaluation, cost management. Directly relevant to the plan generation pipeline and chat assistant design.
- **Swarm Patterns by Development Stage** — Why agents.md defines the team it does. Multi-agent patterns for research, coding, testing, review.

### Context & Performance
- **Context Management & Memory Systems** — PreCompact hooks, token budgets, session splitting. Explains the hooks in .claude/settings.json.
- **Hooks & Enforcement Patterns** — The complete hook pattern library. 97-99% compliance vs 58-73% for text rules alone. Reference when adding/modifying hooks.
- **Cost Optimization Playbook** — Model routing, caching, context management. Relevant to Gemini pricing and plan generation token optimization.

### Quality
- **Testing AI-Generated Code** — TDD workflows, property-based testing for edge cases. Directly applicable to testing the plan validation layer.
- **Prompt Engineering Patterns** — Spec-driven prompting, few-shot patterns. Relevant to the system prompt design in `lib/prompts/`.

### Frontend & UX
- **AI-First UX Patterns** — Streaming UX, confidence indicators, human-in-the-loop patterns. Directly applicable to plan generation progress and chat interface design.
- **AI-Powered Frontend Features** — Streaming UI with Vercel AI SDK, conversational interfaces. Copy-paste React/Next.js recipes for the chat panel.
- **AI-Assisted Design Workflow** — Design-to-code pipelines, component generation with shadcn/ui.

### Tooling
- **Building Custom MCP Servers** — FastMCP for custom integrations. Useful if we build a woodworking knowledge MCP for RAG in later phases.
- **Best of Breed Directory** — Why specific MCP servers and tools were chosen.

### Debugging & API
- **AI-Assisted Debugging** — Multi-agent debugging patterns. Useful for debugging plan generation issues and validation failures.
- **AI-Assisted API Design** — Contract-first development with Zod schemas. Relevant to the WoodworkingPlan schema design.

## Key Principles Applied
1. **TDD-first** — Tests before implementation. Hooks auto-run tests after every edit.
2. **Plan Mode before execution** — Cuts token waste 50%.
3. **Positive rules only** — CLAUDE.md uses "do X" not "don't do Y".
4. **Hooks over text rules** — Critical rules enforced by hooks, not just CLAUDE.md text.
5. **Lean CLAUDE.md** — Under 120 lines. Every rule must change how AI writes code for THIS project.
6. **Context preservation** — PreCompact hooks re-inject critical context during compression.
