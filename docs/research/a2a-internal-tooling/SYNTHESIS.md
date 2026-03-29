# Research Synthesis: A2A Protocol for Internal Developer Tooling

## Date: 2026-03-28
## Researchers: Domain (real-world examples), Landscape (alternatives comparison), Technical (pitfalls & MVP)

---

## Problem Statement

Development teams building AI-assisted internal tooling face a choice: one powerful agent with many MCP tools, or multiple specialized agents that coordinate via A2A. The question is whether A2A-based decomposition delivers enough benefit (permission isolation, maintainability, team ownership) to justify the added complexity (debugging, latency, state management) — and whether the ecosystem is mature enough to build on today.

## Key Insights

1. **No one is doing this for internal dev tooling yet.** Zero documented production examples of A2A for internal developer tools (DB, deploy, monitoring agents). All real A2A usage is cross-org (Gordon Food Service ↔ Tyson Foods) or platform-level (AWS Bedrock AgentCore incident response). This is a critical finding — you'd be pioneering, not following. — *Source: Domain research, exhaustive web search*

2. **Single agent + MCP works until ~15-20 tools.** Each MCP tool costs 550-1,400 tokens in context. At 3-4 MCP servers, you can burn 55K+ tokens before the agent processes any input. Cursor enforces a 40-tool hard limit. Below that threshold, decomposition adds complexity without proportional benefit. — *Source: Apideck, Junia.ai, DEV Community*

3. **Multi-agent only helps for parallelizable tasks.** Performance improves 80.9% on tasks that can run in parallel (DB query + metrics check + deploy status simultaneously). But sequential tasks degrade 39-70% due to communication overhead. Internal dev tooling is often naturally parallel, which is a point in A2A's favor. — *Source: Taskade, Google Research*

4. **A2A authorization is a footgun.** The spec handles authentication but explicitly does NOT standardize authorization. Each agent rolls its own permission logic, leading to inconsistent enforcement and potential escalation. You must build a shared token/scope model yourself. — *Source: A2A spec, Red Hat, Microsoft, Auth0*

5. **Debugging is opaque without LangSmith/Langfuse from day one.** A2A has zero built-in observability. Tracing a request through 3-4 agents requires external tooling. Graph visualization (LangSmith) is 60% faster for debugging than text logs. This is non-negotiable infrastructure, not a nice-to-have. — *Source: LangSmith docs, LangGraph observability research*

6. **Python SDK is usable; TypeScript is not ready.** Python A2A SDK is at v1.0.0a0 (alpha but functional). Google ADK includes `to_a2a()` wrappers and auto-generates Agent Cards. TypeScript A2A was still in design phase as of January 2026. If you're building in TypeScript, A2A is premature. — *Source: PyPI, GitHub adk-python, a2a-python*

7. **O(n²) connection scaling is real.** 5 agents = 10 connections. 10 agents = 45. 20 agents = 190. Point-to-point A2A fights the "loosely coupled" goal. You need an orchestrator pattern or service mesh to manage this — which means your "simple decomposition" adds infrastructure. — *Source: HiveMQ, distributed systems fundamentals*

8. **A2A and MCP are complementary, not competing.** MCP = agent talks to tools (vertical). A2A = agent talks to agents (horizontal). The mature pattern uses both: each specialist agent uses MCP for its tools, and agents coordinate via A2A. This isn't "A2A vs MCP" — it's "MCP alone vs MCP + A2A." — *Source: CData, Auth0, AWS*

9. **Cascading failures have no built-in protection.** A2A provides error codes and Retry-After headers but no circuit breakers, bulkheads, or compensation logic. Semantic errors (silently wrong data) propagate through agent chains. You must build all resilience patterns yourself. — *Source: OWASP ASI08, HiveMQ, Solo.io*

10. **MVP is ~64 hours: orchestrator + one specialist.** A 2-agent system (orchestrator + DB or deploy worker) using Google ADK + LangSmith is the smallest useful A2A setup. Includes error handling, observability, tests, and agent discovery. — *Source: Technical research estimate based on ADK complexity*

## Existing Solutions

| Approach | Strengths | Weaknesses | Best For |
|----------|-----------|------------|----------|
| **Single agent + MCP tools** | Simplest to build and debug. No inter-agent coordination. Works now. | Context window limit at ~15-20 tools. All permissions in one agent. Hard to split team ownership. | <15 tools, solo dev or small team, quick iteration |
| **A2A multi-agent** | Permission isolation per agent. Team ownership. Parallel execution. Standard protocol. | No production examples for internal tooling. Auth is DIY. Debugging requires external tools. O(n²) connections. | Cross-org agents, >20 tools, strict permission requirements, parallel workflows |
| **Framework-native multi-agent (LangGraph/CrewAI)** | Simpler than A2A for single-app multi-agent. LangGraph is intra-process (fast). CrewAI has role-based teams. | Tied to one framework. Can't cross org/vendor boundaries. Less formal protocol. | Multi-agent within one application, rapid prototyping |
| **Microservices + REST** | Mature, well-understood. Existing tooling for auth, monitoring, deployment. | No agent discovery. No streaming results. No task lifecycle. Manual integration. | When you already have microservices and just need to call them |

## Opportunities

1. **Start with single agent + MCP, design for future A2A migration** — Impact: H, Feasibility: H. Build with MCP today (proven, simple), but structure your tools as separate MCP servers that could become A2A agents later. This avoids premature complexity while keeping the door open.

2. **Build a 2-agent POC to validate the pattern** — Impact: M, Feasibility: M. The 64-hour MVP would answer the key question: does A2A decomposition actually improve your workflow enough to justify the overhead? Build orchestrator + one specialist (DB agent is simplest), measure debugging experience and latency.

3. **Contribute to the ecosystem** — Impact: M, Feasibility: L. Since no one has published internal dev tooling patterns with A2A, you'd be defining the pattern. High learning value but also high risk of hitting uncharted problems.

## Technical Constraints

- **Python only for A2A** — TypeScript SDK is not ready. If your stack is TypeScript, A2A is premature.
- **LangSmith or Langfuse required** — Budget for observability infrastructure from day one. Free tiers exist but may not scale.
- **Authorization is DIY** — You must design and implement a shared permission model (OAuth scopes, short-lived tokens). No standard library or framework for this.
- **No standard testing framework** — Multi-agent integration testing with A2A is ad-hoc. Expect to build custom test infrastructure.

## Risks

- **Premature complexity**: A2A adds significant infrastructure (discovery, auth, observability, error handling) that single-agent + MCP doesn't need. Risk of over-engineering for a solo developer. Likelihood: High for small teams.
- **Ecosystem immaturity**: Python SDK is alpha. Agent discovery isn't standardized. No circuit breaker libraries. You'll hit rough edges. Likelihood: High.
- **Debug difficulty**: When something goes wrong in an agent chain, root-causing is harder than in a single agent. Likelihood: Medium (mitigated with LangSmith from day one).
- **Latency overhead**: Each A2A hop adds network round-trip. For latency-sensitive workflows (deploy status checks), this matters. Likelihood: Medium (mitigated by co-locating agents).

## Open Questions

- **Is the permission isolation benefit real for a solo dev?** — The main A2A advantage (per-agent least-privilege) matters most for teams. For one developer, it might be overhead without payoff.
- **What's the actual latency overhead?** — No published benchmarks for A2A agent call vs direct MCP tool call. Would need to measure empirically.
- **Will the TypeScript SDK catch up in 2026?** — If Brian's projects are TypeScript-heavy, this is a blocker. No timeline published.
- **How does CrewAI's native A2A compare to raw SDK?** — CrewAI v1.10+ has A2A built in. Might be faster to start than raw Google ADK. Untested for internal tooling.

## Recommendations

**For Brian specifically:**

1. **Don't build with A2A today for internal tooling.** The ecosystem isn't ready, there are no proven examples to learn from, and single-agent + MCP covers your current needs. The risk/reward ratio is unfavorable.

2. **Do structure your MCP servers as future A2A candidates.** Build each MCP server as an independent service with clear capabilities, scoped permissions, and its own deployment. This is good architecture regardless, and makes A2A migration straightforward later.

3. **Revisit in Q3 2026.** By then: Python SDK should be stable (not alpha), TypeScript SDK should exist, agent discovery may be standardized, and there should be real internal tooling examples to learn from. The watching items in INDEX.md already track this.

4. **If you want to experiment now,** build the 2-agent POC (orchestrator + DB agent) as a weekend learning project using Google ADK. ~64 hours. Don't ship it — use it to build intuition for when A2A becomes practical.

## Source Index

### Domain Research (Real-World Examples)
- [Gordon Food Service + Tyson Foods A2A pilot](https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade/)
- [AWS Bedrock AgentCore incident response](https://aws.amazon.com/blogs/machine-learning/building-multi-agent-systems-with-a2a-protocol-on-amazon-bedrock/)
- [Azure AI Foundry A2A support](https://learn.microsoft.com/en-us/azure/foundry/)
- [CrewAI A2A integration](https://docs.crewai.com/concepts/a2a)
- [LangGraph A2A adapter](https://langchain-ai.github.io/langgraph/)

### Landscape Research (Alternatives)
- [CData: single vs multi-agent](https://www.cdata.com/blog/choosing-single-agent-with-mcp-vs-multi-agent-with-a2a)
- [Auth0: MCP vs A2A](https://auth0.com/blog/mcp-vs-a2a/)
- [Apideck: MCP context window problem](https://www.apideck.com/blog/mcp-server-eating-context-window-cli-alternative)
- [Google: scaling agent systems](https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work)
- [Kai Waehner: A2A + Kafka](https://www.kai-waehner.de/blog/2025/05/26/agentic-ai-with-the-agent2agent-protocol-a2a-and-mcp-using-apache-kafka-as-event-broker/)

### Technical Research (Pitfalls & MVP)
- [A2A Protocol spec](https://a2a-protocol.org/latest/specification/)
- [HiveMQ: A2A enterprise limitations](https://www.hivemq.com/blog/a2a-enterprise-scale-agentic-ai-collaboration-part-1/)
- [OWASP ASI08: cascading failures](https://adversa.ai/blog/cascading-failures-in-agentic-ai-complete-owasp-asi08-security-guide-2026/)
- [Red Hat: A2A security](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security/)
- [A2A Python SDK](https://pypi.org/project/a2a-sdk/)
- [Google ADK](https://pypi.org/project/google-adk/)
- [LangSmith observability](https://www.langchain.com/langsmith/observability)
- [Solo.io: MCP/A2A attack vectors](https://www.solo.io/blog/deep-dive-mcp-and-a2a-attack-vectors-for-ai-agents/)
