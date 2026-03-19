# Agent Team: Life Assistant (LifeOS)

## Development Agents

### Lead Agent
- **Role:** Coordinates work, reviews plans, ensures consistency across MCP servers and the host app
- **When to use:** Feature planning, architecture decisions, cross-domain wiring, complex debugging
- **Mode:** Plan Mode → approval → execution

### MCP Server Agent (Subagent)
- **Role:** Implements domain-specific MCP servers (tools, resources, prompts, database)
- **When to use:** Building or modifying any MCP server package
- **Scope:** One domain at a time (e.g., `mcp-career`, `mcp-finance`)
- **Key rule:** Always implement tools first, write tests, then wire to UI
- **Files:** `packages/mcp-{domain}/`

### UI Agent (Subagent)
- **Role:** Builds Next.js pages, components, and API routes
- **When to use:** Dashboard views, chat interface, settings pages, responsive design
- **Scope:** Everything in `apps/web/`
- **Key rule:** UI always calls MCP tools through the host orchestration layer — never direct database access
- **Files:** `apps/web/app/`, `apps/web/components/`

### AI Orchestration Agent (Subagent)
- **Role:** Builds the LLM orchestration layer — model routing, prompt assembly, cross-domain context, memory
- **When to use:** Setting up chat API routes, implementing cross-domain reasoning, configuring model routing, memory system
- **Scope:** `apps/web/lib/` (mcp-host.ts, orchestrator.ts, memory.ts, nudge-engine.ts)
- **Key rule:** Always use Haiku for tool calls, Sonnet for coaching. Test model routing decisions.

### Reviewer Agent (Subagent)
- **Role:** Reviews code independently of the implementing agent
- **When to use:** After any MCP server or major feature is complete
- **Scope:** Security (no raw SQL injection, no leaked secrets), performance (batched queries, efficient prompts), style (CLAUDE.md conformance)
- **Key rule:** Reviewer has NO knowledge of coder's decisions — adversarial by design

## Parallel Work Opportunities

These tasks can be parallelized across agents:
- **MCP servers are independent:** Career, Finance, Fitness, and Hobbies servers have no code dependencies on each other
- **Server vs. UI:** MCP server tools and UI components for a domain can be built in parallel once the tool contract is defined
- **Prompt engineering vs. implementation:** Coaching prompt refinement can happen in parallel with CRUD tool implementation
- **Testing vs. features:** Test fixtures and mocks can be prepared while features are built

## Context Management Rules
- **Session splitting:** Separate sessions for: planning, MCP server work, UI work, testing
- **Handoff via files:** Agents share context through `docs/` directory and the MCP tool interface definitions — not conversation history
- **Monitor usage:** Compact at 60% context capacity
- **Subagent scoping:** Each subagent gets only the files it needs. The MCP Server Agent doesn't need UI code, and vice versa.
- **Domain isolation:** When building `mcp-finance`, the agent should not need to read `mcp-career` source code — only `packages/shared/` types
