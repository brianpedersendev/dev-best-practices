# AI Development Reference Guides

Quick links to research and best practices that inform how this project is set up. These guides explain the reasoning behind the CLAUDE.md rules, hook configurations, and architecture decisions.

All paths are relative to the knowledge base root (`/home/user/dev-best-practices/`).

## Workflow & Tools
- **Claude Code Power User Guide** (`docs/topics/claude-code-power-user.md`) — TDD workflows, Plan Mode, hooks, session discipline. Why CLAUDE.md is structured the way it is.
- **Tool Comparison: When to Use Each** (`docs/topics/tool-comparison-when-to-use.md`) — Decision matrix for 20 common tasks across Claude Code, Cursor, Gemini.
- **Prompt Engineering Patterns** (`docs/topics/prompt-engineering-patterns.md`) — Why CLAUDE.md uses positive rules, structured prompting techniques, 15 production-ready templates.

## Architecture & Patterns
- **AI-Native Architecture** (`docs/topics/ai-native-architecture.md`) — Agent backends, RAG, AI-first UX, vector storage, evaluation, cost management. Core reference for this project's architecture.
- **Swarm Patterns by Development Stage** (`docs/topics/swarm-patterns-by-dev-stage.md`) — Why agents.md defines the team it does.
- **Error Recovery Patterns** (`docs/topics/error-recovery-patterns.md`) — Circuit breakers, retry with backoff, loop detection, context summarization. Source for this project's safeguards.
- **Context Management & Memory Systems** (`docs/topics/context-memory-systems.md`) — Token budgets, three-tier memory, session splitting. Why the ContextManager exists.

## Quality & Testing
- **Testing AI-Generated Code** (`docs/topics/testing-ai-generated-code.md`) — Why TDD + AI reduces defects 40-90%. Security testing, property-based testing, mutation testing.
- **Evaluation Beyond LLM-as-Judge** (`docs/topics/evaluation-beyond-llm-judge.md`) — Statistical rigor, composite frameworks. Informs the DeepEval strategy.
- **Hooks & Enforcement Patterns** (`docs/topics/hooks-enforcement-patterns.md`) — Why hooks achieve 97-99% compliance vs 58-73% for text rules. Every hook in settings.json is explained here.

## Cost & Operations
- **Cost Optimization Playbook** (`docs/topics/cost-optimization-playbook.md`) — Model routing (60% savings), prompt caching (90% discount), context management. Why cost tracking is Phase 1.
- **RAG Staleness Detection** (`docs/topics/rag-staleness-detection.md`) — Embedding versioning, refresh pipelines. Relevant for finance domain where data goes stale quickly.

## Tooling & MCP
- **Building Custom MCP Servers** (`docs/topics/building-custom-mcp-servers.md`) — How to expose tools as MCP servers (Phase 6 goal).
- **Best of Breed Directory** (`docs/topics/best-of-breed-directory.md`) — Why sequential-thinking and context7 MCP servers are included.

## Key Principles Applied
1. **TDD-first** — Tests before implementation. Hooks auto-run tests after every edit.
2. **Plan Mode before execution** — Cuts token waste 50%, prevents solving the wrong problem.
3. **Positive rules only** — CLAUDE.md uses "do X" not "don't do Y."
4. **Hooks over text rules** — Critical rules enforced by hooks, not just text.
5. **Lean CLAUDE.md** — Under 120 lines. Every rule changes how AI writes code for THIS project.
6. **Provider abstractions** — External deps behind Protocols for resilience to vendor changes.
