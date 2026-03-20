# Agent Team: Woodworking Sidekick

## Development Agents

### Lead Agent
- **Role:** Coordinates work, reviews plans, ensures consistency across plan generation, chat, and UI
- **When to use:** Feature planning, architecture decisions, complex debugging, validation logic design
- **Mode:** Plan Mode → approval → execution

### Coder Agent (Subagent)
- **Role:** Implements features following TDD
- **When to use:** Spawned by lead for focused implementation tasks
- **Scope:** One module at a time (e.g., plan generation API, chat route, validation layer), includes tests
- **Key rule:** Always write tests first, then implementation

### Reviewer Agent (Subagent)
- **Role:** Reviews code independently of the coder
- **When to use:** After implementation, before committing
- **Scope:** Security (no secrets, RLS enforcement, input validation), performance (streaming, query efficiency), style (CLAUDE.md conformance)
- **Key rule:** Reviewer has NO knowledge of coder's decisions — adversarial by design

### Frontend Agent (Subagent)
- **Role:** UI implementation, component design, accessibility
- **When to use:** New pages/components, plan display UI, chat interface, responsive design
- **Scope:** Everything in `app/`, `components/`, Tailwind + shadcn/ui work
- **MCP:** Playwright for visual testing and e2e flows

### Database Agent (Subagent)
- **Role:** Schema design, RLS policies, migration writing, query optimization
- **When to use:** Data model changes, Supabase configuration, RLS policy updates
- **MCP:** Supabase MCP for direct database access and schema inspection

### LLM Pipeline Agent (Subagent)
- **Role:** Prompt engineering, plan generation quality, validation rule tuning, chat behavior
- **When to use:** Writing or refining system prompts, evaluating plan accuracy, tuning validation rules, chat guardrails
- **Scope:** Everything in `lib/prompts/`, `lib/validation/`, plan generation API, chat API
- **Key rule:** Always test prompts against golden path projects (bookshelf, end table, cutting board, workbench) before deploying

## Parallel Work Opportunities

These tasks can be parallelized across agents:
- **Frontend and backend:** Plan display UI can be built alongside plan generation API
- **Validation rules are independent:** Dimensional checks, board feet math, joinery compatibility can be built simultaneously
- **Auth and AI:** Supabase auth setup has no dependencies on Gemini integration
- **Chat and plan gen:** Chat API and plan generation API share prompts/ but are otherwise independent
- **Golden path testing:** Multiple test projects can be evaluated in parallel

## Context Management Rules
- **Session splitting:** Use separate sessions for planning, implementation, and testing. Clear context between phases.
- **Handoff via files:** Agents pass knowledge through docs/TASKS.md and docs/ARCHITECTURE.md, not conversation history.
- **Monitor usage:** Compact at 60% context capacity. PreCompact hook preserves critical project context.
- **Subagent scoping:** Each subagent gets only the files it needs. The Frontend Agent doesn't need validation logic, the LLM Agent doesn't need UI components.
- **Memory persistence:** Store key decisions, learnings, and architectural choices in docs/ so future sessions can pick up without re-deriving context.
