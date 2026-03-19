# AI Development Reference Guides

Quick links to research and best practices that inform how this project is set up.

## Most Relevant to This Project

### Workflow & Tools
- **Claude Code Power User Guide** — TDD workflows, Plan Mode, hooks, session discipline. Explains CLAUDE.md structure and hook configurations.
- **Tool Comparison: When to Use Each** — Decision matrix for choosing between Claude Code, Cursor, Gemini for different tasks.

### Architecture & Patterns
- **AI-Native Architecture** — Architecture patterns for apps built around AI. Covers agent backends, RAG, evaluation, cost management. Directly relevant to the two-pass LLM pipeline design.
- **Swarm Patterns by Development Stage** — Why agents.md defines the team it does. Multi-agent patterns for research, coding, testing, review.

### Context & Performance
- **Context Management & Memory Systems** — PreCompact hooks, token budgets, session splitting. Explains the hooks in .claude/settings.json.
- **Hooks & Enforcement Patterns** — The complete hook pattern library. 97-99% compliance vs 58-73% for text rules alone. Reference when adding/modifying hooks.
- **Cost Optimization Playbook** — Model routing (Haiku for extraction), batch API savings, caching strategies.

### Quality
- **Testing AI-Generated Code** — TDD workflows, property-based testing for edge cases, mutation testing, multi-model code review.
- **Prompt Engineering Patterns** — Spec-driven prompting, few-shot patterns. Relevant to the extraction and synthesis prompt design in `llm/prompts.py`.

### Tooling
- **Building Custom MCP Servers** — FastMCP (Python) for building custom integrations. Useful if we need to wrap state agency endpoints as MCP tools.
- **Best of Breed Directory** — Why specific MCP servers and tools were chosen.

## Key Principles Applied
1. **TDD-first** — Tests before implementation. Hooks auto-run tests after every edit.
2. **Plan Mode before execution** — Cuts token waste 50%.
3. **Positive rules only** — CLAUDE.md uses "do X" not "don't do Y".
4. **Hooks over text rules** — Critical rules enforced by hooks, not just CLAUDE.md text.
5. **Lean CLAUDE.md** — Under 120 lines. Every rule must change how AI writes code for THIS project.
6. **Context preservation** — PreCompact hooks re-inject critical context during compression.
