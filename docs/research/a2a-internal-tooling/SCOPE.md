# Research Scope

## Topic: A2A Protocol for Internal Developer Tooling
## Purpose: Understand real-world patterns, examples, and pitfalls of using A2A to decompose monolithic dev agents into focused, permission-scoped internal tooling agents — to decide whether and how to build this.
## Key Questions:
1. Who is actually doing this today? Are there production examples of A2A-based internal tooling, or is it still conceptual?
2. What are the proven architectural patterns? (orchestrator + specialists, mesh, hierarchical, etc.)
3. What are the real pitfalls teams hit? (latency, debugging, agent discovery, permission management, state management across agents)
4. How does this compare to alternatives? (single agent with MCP tools, microservices with REST, traditional CLI tooling)
5. What's the minimum viable setup — how small can you start?

## Out of Scope:
- A2A protocol internals (already covered in our a2a-protocol-mcp-convergence.md guide)
- Consumer/external-facing agent marketplaces
- General multi-agent theory without internal tooling context

## Prior Knowledge:
- Brian has a comprehensive A2A + MCP guide already in the knowledge base
- Understands MCP well (has a building-custom-mcp-servers guide)
- The use case he's most interested in: decomposing a monolithic agent into small, permission-scoped internal agents (DB, deploy, monitoring, etc.) that communicate via A2A
- Interested in practical patterns, not protocol theory
