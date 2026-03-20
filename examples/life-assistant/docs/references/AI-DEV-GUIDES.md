# AI Development Reference Guides

Quick links to research and best practices that inform how this project is set up.

## Workflow & Tools
- **Claude Code Power User Guide** — TDD workflows, Plan Mode, spec-driven dev, hooks, session discipline
- **Cursor IDE Power User Guide** — Cmd+K/L/I workflows, .mdc rules, MCP setup
- **Tool Comparison: When to Use Each** — Decision matrix for Claude Code vs Cursor vs Gemini

## Architecture & Patterns
- **AI-Native Architecture** — Agent-backend patterns, MCP-first design, memory hierarchy, model routing
- **Swarm Patterns by Development Stage** — Multi-agent patterns for each dev phase
- **Building Custom MCP Servers** — FastMCP guide for building domain-specific MCP servers

## Quality & Testing
- **Testing AI-Generated Code** — TDD with AI, security testing, code review patterns
- **Hooks & Enforcement Patterns** — Why hooks beat text rules (97-99% vs 58-73% compliance)
- **Prompt Engineering Patterns** — Structured prompts, CLAUDE.md best practices

## Operations
- **Cost Optimization Playbook** — Model routing savings, caching, token budgeting
- **Context Management & Memory Systems** — Token reduction, session splitting, PreCompact hooks
- **Error Recovery & Fallback Patterns** — Model failures, circuit breakers, graceful degradation
- **Remote Dev Environment Setup** — Doppler for secrets, Docker Compose, headless Claude Code

## Design & Frontend
- **AI-First UX Patterns** — Chat vs structured UI, confidence indicators, human-in-the-loop
- **AI-Powered Frontend Features** — Streaming UI, Vercel AI SDK patterns, semantic search

## Key Principles Applied
1. **TDD-first** — Tests before implementation. Hooks auto-run vitest after every edit.
2. **MCP-first development** — Build server tools, test them, then build UI.
3. **Hooks over text rules** — Critical rules enforced by hooks in settings.json.
4. **Model routing** — Haiku for data ops, Sonnet for reasoning. Cost scales with routing discipline.
5. **Domain isolation** — Each MCP server owns its data and can be developed/tested independently.
