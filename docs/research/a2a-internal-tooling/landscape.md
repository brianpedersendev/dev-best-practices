# A2A vs Alternatives: Landscape Analysis for Internal Developer Tooling

**Date**: 2026-03-28
**Status**: Complete research synthesis
**Audience**: Decision-makers deciding between A2A, single-agent + MCP, microservices, and framework-native multi-agent approaches

---

## Key Findings (Priority Order)

### 1. **A2A Solves Agent-to-Agent Coordination; MCP + Single Agent Solves Tool Access**
- **MCP** provides "vertical integration" (agent ↔ tools/data sources)
- **A2A** provides "horizontal integration" (agent ↔ agent)
- **They're complementary, not competitors.** Most sophisticated enterprise setups use both: MCP for tool access, A2A for orchestration between specialized agents.
- Single agent + MCP can handle many tasks if tool definitions stay within context window (~40 tool limit in practice before degradation).

**Sources**: [CData blog on choosing single vs multi-agent](https://www.cdata.com/blog/choosing-single-agent-with-mcp-vs-multi-agent-with-a2a); [Auth0 MCP vs A2A guide](https://auth0.com/blog/mcp-vs-a2a/)

---

### 2. **Context Window is the Hard Limit for Single-Agent + MCP**
- **Real problem**: Each MCP tool definition costs 550-1,400 tokens (name, schema, descriptions, enums).
- **Scale**: 3-4 MCP servers can consume 55,000+ tokens *before the agent processes any user input*.
- **Hard limits exist**: Cursor enforces a 40-tool maximum; some teams hit 72% context window burn from tool defs alone (143k of 200k tokens).
- **Implication**: Single agent + MCP works well for <5 specialized tools or <15-20 total tools. Beyond that, decomposition into focused agents becomes necessary.

**Sources**: [Apideck on MCP context window problem](https://www.apideck.com/blog/mcp-server-eating-context-window-cli-alternative); [Junia.ai on context overload](https://www.junia.ai/blog/mcp-context-window-problem); [DEV Community tool overload article](https://dev.to/amzani/your-mcp-server-is-eating-your-context-window-theres-a-simpler-way-3ja2)

---

### 3. **Multi-Agent Performance Depends Entirely on Task Parallelism**
- **Parallelizable tasks** (financial reasoning, data analysis): Multi-agent beats single-agent by 80.9% due to parallel reasoning.
- **Sequential reasoning tasks**: Multi-agent degrades performance by 39-70% due to communication overhead and reasoning fragmentation.
- **Decision rule**: Decompose into multi-agent ONLY if your internal tooling workflows naturally parallelize (e.g., DB queries, deploy checks, monitoring probes running simultaneously).

**Sources**: [Taskade blog on single vs multi-agent](https://www.taskade.com/blog/single-agent-systems-versus-multi-agent-ai-teams); [Google research on scaling agent systems](https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work)

---

### 4. **A2A ≠ Microservices (Different Problems, Not Competing Solutions)**
- **A2A** is agent-to-agent communication (async task delegation, discovery, streaming results).
- **REST microservices** are synchronous request-response for tool/API access.
- **Key difference**: A2A returns immediately with Task objects and processes in background; REST blocks waiting for response.
- **Operational model**: A2A behaves like a service mesh for agents (automatic discovery, delegation, permission scoping). REST requires manual endpoint management.
- **When to replace REST with A2A**: Only when you have already-decomposed microservices AND want agents to discover and coordinate with each other dynamically without hard-coded API contracts.

**Sources**: [Niklas Heidloff on MCP/ACP/A2A comparison](https://heidloff.net/article/mcp-acp-a2a-agent-protocols/); [AWS open protocols blog](https://aws.amazon.com/blogs/opensource/open-protocols-for-agent-interoperability-part-4-inter-agent-communication-on-a2a/); [Kai Waehner on A2A + Kafka](https://www.kai-waehner.de/blog/2025/05/26/agentic-ai-with-the-agent2agent-protocol-a2a-and-mcp-using-apache-kafka-as-event-broker/)

---

### 5. **A2A vs Message Queues (Kafka/NATS): Layering, Not Replacement**
- **Message queues** (Kafka, NATS, RabbitMQ) handle async event streaming at infrastructure level.
- **A2A** is an application-level protocol that can run *on top of* a message queue for reliability and at-scale coordination.
- **Recommended layering** (per Kai Waehner):
  - Kafka (durable long-term event streaming) + A2A (agent discovery, delegation) for enterprise scale.
  - NATS (low-latency pub-sub) works for smaller internal tooling, but Kafka handles backpressure, ordering, and recovery better.
- **A2A overhead**: ~30ms per agent hop in Google's reference implementation. Message queue latency adds on top.

**Sources**: [Confluent blog on A2A + Kafka](https://www.confluent.io/blog/google-agent2agent-protocol-needs-kafka/); [Kai Waehner A2A + Kafka integration](https://www.kai-waehner.de/blog/2025/05/26/agentic-ai-with-the-agent2agent-protocol-a2a-and-mcp-using-apache-kafka-as-event-broker/); [NATS vs Kafka comparison](https://sanj.dev/post/nats-kafka-rabbitmq-messaging-comparison)

---

### 6. **LangGraph (Intra-Process) vs A2A (Inter-Process) Serve Different Scopes**
- **LangGraph**: Single application, DAG-based workflow orchestration, fine-grained state control, debugging-friendly.
- **A2A**: Multi-service/multi-vendor agent networks, inter-agent discovery, async delegation, permission scoping.
- **Trade-off**: LangGraph is simpler for monolithic internal tooling. A2A is needed when agents are distributed across services or built by different teams.
- **Key limitation of LangGraph for this use case**: No agent discovery mechanism, no cross-framework interoperability, hardcoded routing logic.
- **Note**: LangGraph *can* implement A2A-compliant agents, but doesn't provide the protocol layer natively.

**Sources**: [Medium article on LangGraph vs A2A](https://medium.com/@onurpolat711/langgraph-a2a-simulating-multi-agent-ai-collaboration-for-developers-ca4a26f9bbe3); [LangChain forum discussion](https://forum.langchain.com/t/a2a-protocol-using-langchain-and-langgraph/214); [OpenAgents blog comparison](https://openagents.org/blog/posts/2026-02-23-open-source-ai-agent-frameworks-compared)

---

### 7. **CrewAI Leads Framework Adoption of MCP + A2A**
- **CrewAI v1.10**: Added A2A protocol support + native MCP tool loading.
- **AutoGen, LangGraph**: No native MCP/A2A support yet (plan to add).
- **OpenAgents**: Only framework with native support for BOTH MCP and A2A.
- **Implication for internal tooling**: If using a framework, CrewAI or OpenAgents give you the fastest path to A2A-based agent decomposition.

**Sources**: [OpenAgents 2026 framework comparison](https://openagents.org/blog/posts/2026-02-23-open-source-ai-agent-frameworks-compared); [DataCamp CrewAI vs LangGraph vs AutoGen](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen); [Composio framework guide](https://composio.dev/blog/openai-agents-sdk-vs-langgraph-vs-autogen-vs-crewai)

---

### 8. **Operational Complexity: O(n²) Scaling and Debugging Overhead**
- **Request-response A2A chains**: Number of connections scales as O(n²) — 4 agents = 6 connections, 50 agents = 1,200+ connections.
- **Debugging challenges**:
  - Agent-to-agent chains introduce unpredictable latency and "tracing gaps" (hard to correlate logs across agents).
  - Schema drift between agent APIs (agents change their task signatures without coordination).
  - Endpoint sprawl — too many discovery points to maintain.
- **Mitigation strategies**:
  - Use event-driven architecture (Kafka) to flatten communication topology.
  - Implement robust tracing (span correlation across agent boundaries).
  - Enforce schema versioning in A2A Task definitions.
- **Reality check**: By late 2025, better debugging tools, libraries, and test frameworks became available. Early 2026 adoption is now more feasible.

**Sources**: [HiveHQ on enterprise A2A challenges](https://www.hivemq.com/blog/a2a-enterprise-scale-agentic-ai-collaboration-part-1/); [A2A protocol 2025 update](https://agent2agent.info/blog/a2a-protocol-2025-update/); [Semgrep security guide](https://semgrep.dev/blog/2025/a-security-engineers-guide-to-the-a2a-protocol/)

---

### 9. **Permission Scoping is a Genuine A2A Advantage**
- **A2A feature**: Permission tokens propagate through agent chains, and Agent Hosts filter available tools per scope.
- **Single-agent + MCP**: All tools available in a single context; permission boundary is the entire agent.
- **Real value**: For internal tooling with restricted access (e.g., DB agent can only write to specific schemas, deploy agent can only touch staging), A2A enforces boundaries at the protocol layer.
- **Alternative**: Can achieve similar with JWT scopes in REST APIs, but requires manual enforcement in agent code.

**Sources**: [A2A specification on agent discovery](https://a2a-protocol.org/latest/topics/agent-discovery/); [Apono on A2A permissions](https://www.apono.io/blog/what-is-agent2agent-a2a-protocol-and-how-to-adopt-it/)

---

### 10. **Production Readiness is Improving Fast**
- **April 2025**: A2A 0.x released (MVP, still experimental).
- **Expected end of 2025**: A2A 1.0 with official SDKs (didn't happen, but 0.5-0.7 versions have strong library support).
- **Current state (Q1 2026)**: 150+ organizations support the protocol (Salesforce, SAP, ServiceNow, Atlassian, Microsoft, Google). 29% of enterprises running agentic AI in production already.
- **Caveat**: Consumer apps and regulated workloads should wait for mature registries and security standards (mid-2026 target).

**Sources**: [Google Cloud blog A2A upgrade](https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade); [Microsoft Cloud blog on A2A](https://www.microsoft.com/en-us/microsoft-cloud/blog/2025/05/07/empowering-multi-agent-apps-with-the-open-agent2agent-a2a-protocol/); [DEV Community 2025 A2A guide](https://dev.to/czmilo/2025-complete-guide-agent2agent-a2a-protocol-the-new-standard-for-ai-agent-collaboration-1pph)

---

## Comparison Matrix

| Dimension | Single Agent + MCP | Multi-Agent + A2A | Microservices + REST | LangGraph (Intra-Process) | Framework-Native (CrewAI v1.10+) |
|-----------|-------------------|-------------------|----------------------|---------------------------|----------------------------------|
| **Tool Count Limit** | 15-20 before degradation | Unlimited (per agent) | API endpoints as tools | Unlimited | Per-agent tool sets |
| **Context Window Pressure** | High (tool defs eat 25-70% of budget) | Low (each agent has own window) | N/A | Medium | Low |
| **Setup Time** | Hours (add MCP servers) | Days (define agents, deploy) | Weeks (design services) | Hours (write DAG) | 1-2 days (define crews) |
| **Debugging Difficulty** | Easy (single process) | Hard (log correlation, tracing gaps) | Hard (distributed system) | Easy (DAG visualization) | Medium (agent interaction logs) |
| **Communication Overhead** | In-process (negligible) | 30ms/hop + infra latency | REST round-trip (10-100ms) | In-process (negligible) | Variable (depends on deployment) |
| **Permission Scoping** | Coarse (all tools or none) | Fine-grained (per-agent, protocol-enforced) | Manual (API keys, JWT) | Manual (code-based) | Per-agent scoping (if A2A-enabled) |
| **Cross-Framework Interop** | No | Yes (A2A standard) | No (REST is generic but not for agents) | No | Yes (CrewAI, soon others) |
| **Dynamic Agent Discovery** | Not applicable | Yes (Agent Card registry) | Manual (service registry) | Not applicable | Partial (framework-specific) |
| **Parallelization Benefit** | Single agent (N/A) | +80.9% on parallel tasks | +80.9% on parallel tasks | Single process (N/A) | +80.9% on parallel tasks |
| **Best For** | <15 specialized tools, sequential workflows | Parallel internal tools (DB, deploy, monitor), future multi-vendor | Existing microservices, high availability needs | Stateful workflow orchestration, single app | Rapid multi-agent prototyping, A2A migration path |

---

## Details: Decision Framework by Use Case

### Use Case 1: "I Need DB, Deploy, Monitoring Agents Running in Parallel"
**Decision**: Start with **single agent + MCP**, graduate to **A2A multi-agent** if tool count grows >15 or permissions need isolation.

**Why**:
- Sequential reasoning (orchestrator decides: "run DB checks, then deploy, then monitor") fits single agent well.
- Parallelizable parts (DB checks, deploy health check, monitor queries) can run async within a single agent using tool concurrency.
- If tools stay <15, single agent + MCP has zero coordination overhead.
- If you later need <100ms response times and independent permission scopes per tool, switch to A2A: each agent (db-checker, deployer, monitor) gets 5-7 focused tools, much lighter context window.

**Migration path**:
1. Start: Single agent → {MCP db-server, MCP deploy-server, MCP monitor-server}
2. If tool defs exceed 55k tokens or permission isolation needed: Migrate to A2A with 3 agents.
3. Protocol layer costs ~30ms/hop, so if agents are internal (same cloud region), latency impact is <100ms end-to-end.

---

### Use Case 2: "We Have Existing Microservices; Should We Add A2A?"
**Decision**: Add A2A **only if agents need to discover and coordinate with each other dynamically**. Otherwise, stick with REST + single agent.

**Why**:
- If your microservices already have stable REST APIs, adding A2A is an extra integration layer (small overhead for discovery/delegation).
- A2A adds value if:
  - New agents will be added without re-deploying orchestrator (dynamic discovery).
  - Permission scopes need to flow through agent chains (not just API keys).
  - You want agents to negotiate task routing (agent A → agent B → agent C based on capability matching).
- If microservices are stable and changes infrequent, REST + single agent or REST + LangGraph is simpler.

**Real example**: University assessment agent delegates plagiarism check to specialized plagiarism-detection agent via A2A. Without A2A, would hardcode REST call to plagiarism endpoint. With A2A, plagiarism agent can be swapped, updated, or replaced without changing the orchestrator.

---

### Use Case 3: "Should I Use LangGraph or A2A for Internal Automation?"
**Decision**:
- **LangGraph** if agents run in same application, you need fine-grained state control, and all agents built by your team.
- **A2A** if agents are distributed across services, built by different teams, or need dynamic discovery.

**Why**:
- LangGraph is simpler, better debugging, fewer operational concerns (no network latency, log correlation).
- A2A scales to multi-vendor scenarios: Salesforce agent + SAP agent + custom agent all talking together.
- For internal tooling (single team, single org), LangGraph is usually sufficient. A2A becomes valuable at >5-10 agent teams or when integrating with external agentic services.

---

### Use Case 4: "Should I Use Kafka or Just A2A?"
**Decision**:
- **A2A alone** if: Internal tooling, <10 concurrent agent chains, <100 messages/second total throughput.
- **Kafka + A2A** if: High volume (1,000+ msgs/sec), need message history/replay, long-running workflow tracking, or enterprise governance.

**Why**:
- A2A is thin (JSON-RPC 2.0, gRPC, or REST over HTTP/SSE). It doesn't handle durability, replication, or ordering.
- Kafka is heavy but provides at-scale reliability: persistent queues, rebalancing, consumer groups, ordering guarantees.
- Layered approach: Kafka carries A2A messages, agents publish/subscribe through message broker for resilience.

**Cost trade-off**: A2A alone = ~1-2 days setup. Kafka + A2A = ~2-3 weeks (kafka cluster ops, schema registry, monitoring).

---

## Real Tradeoffs: Latency, Complexity, Development Speed

### Latency Overhead
| Layer | Latency | Notes |
|-------|---------|-------|
| Single agent (in-process) | <1ms | Baseline |
| Single agent + MCP | 10-100ms | MCP server startup + serialization |
| A2A agent-to-agent (local) | 30ms/hop | Google reference server (network RTT + orchestration) |
| A2A agent-to-agent (cross-region) | 200-500ms/hop | Network latency dominates |
| REST API | 10-100ms | Depends on endpoint responsiveness |
| A2A + Kafka | 30-50ms/hop + 10-20ms broker | Adds message persistence overhead |

**Rule of thumb**: If <100ms response time is required, keep agent chains ≤2-3 hops.

---

### Operational Complexity
| Approach | Setup Cost | Ongoing Cost | Debugging Difficulty |
|----------|-----------|--------------|----------------------|
| Single agent + MCP | Low (hours) | Low | Low (single process, console logs) |
| A2A multi-agent | Medium (days) | Medium | High (distributed tracing, schema versioning) |
| LangGraph | Low (hours) | Low | Low (DAG visualization, state inspection) |
| Kafka + A2A | High (weeks) | High | Very high (message ordering, broker health, rebalancing) |
| Microservices + REST | Very high (weeks) | High | Very high (service mesh, network policies) |

---

### Development Speed (First Agent to Production)
| Approach | Weeks to MVP | Weeks to Stable |
|----------|-------------|-----------------|
| Single agent + MCP | 0.5-1 | 1-2 |
| A2A multi-agent | 2-3 | 4-6 |
| LangGraph | 0.5-1 | 1-2 |
| Framework-native (CrewAI + A2A) | 1-2 | 3-4 |
| Microservices + REST | 2-4 | 6-12 |

---

## Sources

**A2A Protocol & Overview**:
- [Google Developers Blog: Announcing A2A](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)
- [A2A Protocol Specification](https://a2a-protocol.org/latest/specification/)
- [IBM: What Is Agent2Agent Protocol](https://www.ibm.com/think/topics/agent2agent-protocol)
- [Microsoft Cloud Blog: A2A Protocol](https://www.microsoft.com/en-us/microsoft-cloud/blog/2025/05/07/empowering-multi-agent-apps-with-the-open-agent2agent-a2a-protocol/)

**Comparative Analysis**:
- [Auth0: MCP vs A2A](https://auth0.com/blog/mcp-vs-a2a/)
- [CData: Choosing Single Agent + MCP vs Multi-Agent + A2A](https://www.cdata.com/blog/choosing-single-agent-with-mcp-vs-multi-agent-with-a2a)
- [DigitalOcean: A2A vs MCP](https://www.digitalocean.com/community/tutorials/a2a-vs-mcp-ai-agent-protocols)
- [InfoQ: Architecting Agentic MLOps with A2A and MCP](https://www.infoq.com/articles/architecting-agentic-mlops-a2a-mcp/)

**Multi-Agent vs Single-Agent Research**:
- [Taskade: Single Agent vs Multi-Agent Teams (2026)](https://www.taskade.com/blog/single-agent-systems-versus-multi-agent-ai-teams)
- [Google Research: Towards a Science of Scaling Agent Systems](https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work)
- [Microsoft Learn: Choosing Single-Agent vs Multi-Agent](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ai-agents/single-agent-multiple-agents)
- [LangChain Blog: Choosing Multi-Agent Architecture](https://blog.langchain.com/choosing-the-right-multi-agent-architecture/)

**MCP Context Window & Tool Limits**:
- [Apideck: MCP Server Eating Context Window](https://www.apideck.com/blog/mcp-server-eating-context-window-cli-alternative)
- [Junia.ai: MCP Context Window Problem](https://www.junia.ai/blog/mcp-context-window-problem)
- [DEV Community: Your MCP Server Is Eating Your Context Window](https://dev.to/amzani/your-mcp-server-is-eating-your-context-window-theres-a-simpler-way-3ja2)
- [Eclipse Source: MCP and Context Overload](https://eclipsesource.com/blogs/2026/01/22/mcp-context-overload/)

**Messaging & Infrastructure**:
- [Confluent: Why A2A Needs Kafka](https://www.confluent.io/blog/google-agent2agent-protocol-needs-kafka/)
- [Kai Waehner: A2A with Kafka and MCP](https://www.kai-waehner.de/blog/2025/05/26/agentic-ai-with-the-agent2agent-protocol-a2a-and-mcp-using-apache-kafka-as-event-broker/)
- [Sanj.dev: NATS vs RabbitMQ vs Kafka Comparison](https://sanj.dev/post/nats-kafka-rabbitmq-messaging-comparison)

**Framework Comparisons**:
- [OpenAgents: CrewAI vs LangGraph vs AutoGen vs OpenAgents (2026)](https://openagents.org/blog/posts/2026-02-23-open-source-ai-agent-frameworks-compared)
- [DataCamp: CrewAI vs LangGraph vs AutoGen](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen)
- [Medium: LangGraph & A2A Simulation](https://medium.com/@onurpolat711/langgraph-a2a-simulating-multi-agent-ai-collaboration-for-developers-ca4a26f9bbe3)
- [Composio: Framework Comparison (2025)](https://composio.dev/blog/openai-agents-sdk-vs-langgraph-vs-autogen-vs-crewai)

**Operational & Production Concerns**:
- [HiveHQ: A2A Enterprise-Scale Challenges](https://www.hivemq.com/blog/a2a-enterprise-scale-agentic-ai-collaboration-part-1/)
- [Semgrep: A2A Security Guide](https://semgrep.dev/blog/2025/a-security-engineers-guide-to-the-a2a-protocol/)
- [A2A Protocol 2025 Update](https://agent2agent.info/blog/a2a-protocol-2025-update/)
- [DEV Community: 2025 Complete A2A Guide](https://dev.to/czmilo/2025-complete-guide-agent2agent-a2a-protocol-the-new-standard-for-ai-agent-collaboration-1pph)

---

## Confidence Levels

| Finding | Confidence | Evidence |
|---------|-----------|----------|
| Context window limits single-agent + MCP to ~15-20 tools | **High** | Concrete token counts (550-1400 per tool), hard limits enforced by Cursor (40 tools), empirical reports (55k-143k token consumption) |
| Multi-agent improves parallel task performance by 80.9%, degrades sequential by 39-70% | **High** | Google peer-reviewed research, confirmed by multiple sources |
| A2A adds ~30ms/hop in local deployment | **Medium** | Single data point from Google reference implementation; real-world variance depends on infrastructure |
| A2A O(n²) scaling and debugging complexity are real concerns | **High** | Reported by multiple enterprise implementations; documented in HiveHQ and Semgrep analyses |
| MCP + A2A are complementary, not competing | **Very High** | Consensus across all major sources (Google, Microsoft, Auth0, Anthropic) |
| CrewAI has better A2A/MCP support than AutoGen/LangGraph | **High** | Confirmed in OpenAgents 2026 comparison; CrewAI v1.10 release notes |
| A2A production-ready for internal tooling by Q1 2026 | **Medium** | 150+ org support, 29% enterprises running agentic AI; but security/governance standards still maturing |
| Permission scoping via A2A is real security advantage | **High** | Specified in A2A protocol; no equivalent in REST APIs without manual code |

---

## Open Questions

1. **Observability maturity**: What's the current state of cross-agent tracing tools (OpenTelemetry support for A2A)? Are they production-ready?
   - *Status*: Actively being built (2025-2026). No definitive answer yet.

2. **Vendor lock-in**: If you adopt A2A, can you switch agent implementations (e.g., Google Vertex AI → Anthropic Claude agents)? How much refactoring?
   - *Status*: A2A is designed for vendor agnostic, but migration case studies are limited.

3. **Security baseline**: What are the minimum security controls for A2A in production (authentication, encryption, audit)?
   - *Status*: Documented in A2A specification; best practices emerging by Q2 2026.

4. **Cost modeling**: What's the infrastructure cost (CPU, memory, latency) of A2A orchestration vs single agent?
   - *Status*: No published benchmarks yet. Depends heavily on agent framework and deployment model.

5. **Regulatory compliance**: How does A2A fit audit/compliance requirements for financial services, healthcare?
   - *Status*: Early guidance from IBM, SAP; full compliance matrix expected by Q3 2026.

---

## Recommendation for Brian

**For internal developer tooling (your use case):**

**Phase 1 (Now - Month 1)**: Start with **single agent + MCP**
- Build one orchestrator agent with MCP servers for: database, deployment, monitoring.
- Target: Each MCP server <15 tools (max 45 tools total across servers).
- Decision gate: If tool definitions exceed 55k tokens or permission scoping becomes critical, move to Phase 2.

**Phase 2 (Month 2-3, if needed)**: Decompose to **A2A multi-agent**
- Migrate to 3-4 focused agents: db-checker, deployer, monitor-coordinator.
- Each agent manages 5-7 tools with own context window.
- Use CrewAI v1.10+ (has A2A + MCP support built-in) to minimize setup complexity.
- Deploy in same region to keep latency <100ms.
- Implement cross-agent tracing (OpenTelemetry exporter for correlation).

**Infrastructure layer**:
- Start without Kafka (single-agent orchestration doesn't need it).
- If message volume grows >100 msgs/sec or need workflow replay, add Kafka later.

**Permission scoping**:
- Phase 1: Use JWT + environment variables (simple).
- Phase 2: Use A2A scoped tokens (protocol-enforced, more robust).

**Migration is low-risk** because MCP and A2A are designed to coexist. Agents built to A2A spec can still use MCP servers.

