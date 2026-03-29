# A2A Protocol for Internal Developer Tooling: Domain Research

**Date**: March 2026
**Researcher**: Domain Analyst

---

## Key Findings (Most Important First)

1. **Production usage exists but is limited to specific verticals**: Gordon Food Service and Tyson Foods have moved from pilot to planning production deployment for cross-organization supply chain collaboration using A2A. This is the strongest documented "real production" example found. Most other examples are either POCs, sample implementations, or conceptual architectures. Enterprise adoption is occurring, but not yet widespread for internal-only tooling.

2. **AWS Bedrock AgentCore is the primary production-ready platform**: AWS offers the most mature, production-grade deployment path with built-in support for A2A. The incident response & operations multi-agent example (with Strands + OpenAI agents) shows concrete real-world usage patterns with hub-and-spoke architecture. Microsoft Azure AI Foundry and Google Cloud Agent Engine follow as mature alternatives.

3. **No proven internal-only tooling examples found**: We found zero documented examples of teams using A2A purely for internal developer tooling (DB agents, deploy agents, code review agents, monitoring agents). All production/serious examples involve cross-organization or external-facing use cases, or are reference implementations and tutorials.

4. **Multi-agent A2A replaces single-agent-with-MCP only in specific contexts**: MCP (Model Context Protocol) is further along in adoption for single-agent scenarios. A2A is chosen when: (a) domain-specific expertise and distributed coordination are essential, (b) permission scoping per agent is required, (c) agents need to be "black boxes" (hide internal memory and tools), or (d) cross-organization boundaries exist. For internal tooling where all systems trust each other, single agent + MCP may be simpler.

5. **CrewAI and LangGraph both support A2A but lack internal-specific examples**: Both frameworks provide A2A adapters and can expose agents as A2A servers. CrewAI treats A2A as a delegation primitive. LangGraph examples focus on orchestrator + specialist patterns but don't show internal tooling-specific use cases.

6. **Agent discovery is unsolved for internal setups**: The A2A specification does not prescribe a standard API for agent registries. Teams choose between: well-known path convention (hardcoded domain + /.well-known/agent-card.json), curated registry services (requires a registry server), or direct configuration (hardcoded in env/config). No clear winner for internal tooling emerges from research.

7. **Agent Cards are standardized but adoption is inconsistent**: Agent Cards (JSON metadata at /.well-known/agent-card.json) describe capabilities, authentication, input/output modes, and skills. They enable discovery but teams don't consistently publish them for internal agents.

8. **Minimum viable setup unclear; timeline estimates unavailable**: No sources documented minimum team size or setup time for A2A internal tooling. Google's ADK samples and AWS examples show single-agent implementations work quickly, but scaling to multi-agent systems requires "disciplined engineering across architecture, communication, and tool access."

9. **Latency and debugging are documented concerns but not fully solved**: OpenTelemetry-powered tracing and A2A Inspector tool exist for debugging, but agent-to-agent chains introduce unpredictable latency. Caching, batching, and circuit-breaking are recommended but add complexity.

10. **Permission scoping and the "confused deputy" problem are architectural concerns**: When agent A delegates to agent B, agent B operates with its own credentials—not the original user's. Each agent must have minimal permissions. This is solved by design but requires careful setup; no automated permission management tools found.

---

## Details

### Production Examples (Not Demos)

#### Gordon Food Service + Tyson Foods (Supply Chain Collaboration)
- **Status**: Pilot completed, planning production deployment via Gemini Enterprise
- **Architecture**: Cross-organization agent collaboration using A2A protocol
- **Details**: Gordon Food Service (major distributor) built agents to search Tyson Foods' (supplier) product catalog and track sales. Agents communicate securely without exposing internal tools, memory, or logic. Used Google Cloud ADK and Agent2Agent protocol.
- **Outcome**: Plans to scale across more vendors—indicates real business value recognized
- **Evidence**: Official Google Cloud case study and customer reference

#### AWS Bedrock AgentCore Incident Response & Operations
- **Status**: Production-ready reference implementation
- **Architecture**: Hub-and-spoke with three specialized agents
- **Agents**:
  - Monitoring agent (Strands SDK) analyzes CloudWatch logs, metrics, dashboards
  - Operations orchestrator (OpenAI agents) triages incidents, coordinates ChatOps, generates tickets
  - Additional coordination agents as needed
- **Platform Features**: AgentCore Memory (context), AgentCore Identity (authentication via Cognito), AgentCore Gateway (tool access), observability/tracing
- **Deployment**: Stateless HTTP servers on port 9000; Agent Cards at /.well-known/agent-card.json; X-Amzn-Bedrock-AgentCore-Runtime-Session-Id for session isolation
- **Evidence**: AWS blog, Medium article, GitHub repo with working code

#### Azure AI Foundry (Multi-Tenant A2A Support)
- **Status**: Production platform support
- **Adoption**: Over 70,000 enterprises use Azure AI Foundry; 10,000+ organizations adopted Agent Service in 4 months
- **Details**: Enables building complex multi-agent workflows spanning internal copilots, partner tools, and production infrastructure with governance/SLAs
- **Evidence**: Microsoft Cloud Blog, official platform documentation

### Frameworks and Platforms Supporting A2A

| Framework/Platform | Status | Use Case | Evidence |
|---|---|---|---|
| **AWS Bedrock AgentCore** | Production-ready | Mature A2A orchestration with built-in observability | AWS docs, blog, samples |
| **Google Cloud (Agent Engine)** | Production-ready | Managed agent deployment; three paths: Agent Engine, Cloud Run, GKE | Google Cloud blog, ADK docs |
| **Azure AI Foundry** | Production-ready | Multi-agent workflows with governance | Microsoft blog, platform docs |
| **CrewAI** | Full support | A2A delegation as first-class primitive; examples exist | CrewAI docs, Medium tutorials |
| **LangGraph** | Full support | Multi-agent orchestration; supervisor/specialist patterns | LangGraph docs, A2A protocol tutorials |
| **IBM watsonx.ai** | Supported | Integrations with A2A agents | Niklas Heidloff blog |

### Types of Agents Being Built (From Examples)

**Cross-Organization/External-Facing:**
- Supply chain agents (product search, lead tracking)
- ChatOps/incident response orchestrators
- Monitoring and alerting agents
- Workflow automation agents

**Internal (Reference/Tutorial Only):**
- Currency conversion agents (tutorial)
- Code analysis agents (tutorial)
- Various "hello world" and sample implementations

**Not Found in Production:**
- Database query agents
- Deploy/CI-CD agents
- Code review agents
- Internal monitoring agents
- Slack integration agents (only external deployment, not internal tooling)

### Agent Card Examples

**Standard Structure (from spec):**
```json
{
  "name": "agent-name",
  "description": "What the agent does",
  "version": "1.0.0",
  "icon_url": "https://...",
  "service_endpoint": "https://...",
  "authentication": {...},
  "capabilities": ["streaming", ...],
  "default_input_mime_type": "text/plain",
  "default_output_mime_type": "text/plain",
  "skills": [
    {
      "name": "skill-name",
      "description": "What this skill does"
    }
  ]
}
```

**Hosting Convention:**
- Served at `https://<agent-base-url>/.well-known/agent-card.json`
- Must be publicly accessible to clients/other agents
- Auto-generated in-memory via ADK `to_a2a()` function

**No published internal-only Agent Card examples found.**

### Agent Discovery Patterns

**Three approaches documented:**

1. **Well-Known Path Convention**
   - Clients send HTTP GET to `https://<known-domain>/.well-known/agent-card.json`
   - Works for known/discoverable domains via DNS
   - Simplest for internal setups but requires knowing agent URLs upfront

2. **Curated Registry Service**
   - Intermediary registry maintains collection of Agent Cards
   - Agents publish their cards to registry
   - Clients query registry API by criteria (skills, tags, provider, capabilities)
   - Examples: Python A2A package provides `AgentRegistry` and `run_registry()`; A2ARegistry implementation on GitHub uses OAuth 2.0 Client Credentials for auth
   - Pros: Scalable, supports complex queries
   - Cons: Adds infrastructure, registry becomes bottleneck

3. **Direct Configuration**
   - Hardcoded agent URLs in config files, environment variables, or code
   - Works for tightly coupled systems, private agents, development
   - Most common for internal tooling in practice (though not documented in research)

**No clear winner for internal setups.** Well-known path is simplest; registry is most flexible; direct config is most pragmatic.

### Frameworks and Their A2A Implementations

#### CrewAI
- **A2A Support**: A2AClientConfig for consuming remote agents; A2AServerConfig for exposing crews
- **Pattern**: Delegation primitive—agents delegate tasks and request information from remote agents
- **Example**: End-to-end example uses OpenRouter + CrewAI + A2A (available at http://localhost:10011)
- **Server Implementation**: Wrap CrewAI crew behind HTTP interface, implement task handlers translating A2A requests to CrewAI logic
- **Task Endpoints**: /tasks/send and /tasks/get
- **Status**: Documented but limited real-world internal tooling examples

#### LangGraph
- **A2A Support**: Full A2A endpoint in Agent Server; supervisor-specialist patterns documented
- **Adapter Pattern**: Custom implementation converts LangGraph messages to A2A Task format
- **Orchestration**: Supervisor agent coordinates sub-agents via A2A
- **Example**: Currency conversion agent (Gemini + LangGraph + A2A)
- **MCP Integration**: A2A for agent-to-agent; MCP for agent-to-tools
- **Status**: Production-ready; few internal tooling specific examples

#### AWS Bedrock Agents
- **A2A Integration**: Native A2A support in AgentCore Runtime
- **Deployment**: Stateless HTTP servers on port 9000
- **Session Management**: Automatic X-Amzn-Bedrock-AgentCore-Runtime-Session-Id header
- **Agent Cards**: Must provide at /.well-known/agent-card.json
- **Patterns**: Hub-and-spoke, hierarchical task delegation
- **Status**: Production-ready; real examples exist

### Open-Source Starter Kits and References

| Repository | Language | Purpose | Evidence |
|---|---|---|---|
| [a2aproject/A2A](https://github.com/a2aproject/A2A) | Multiple | Official A2A protocol repo (Linux Foundation) | GitHub |
| [a2aproject/a2a-samples](https://github.com/a2aproject/a2a-samples) | Python, Java | Official reference implementations | GitHub |
| [a2aproject/a2a-python](https://github.com/a2aproject/a2a-python) | Python | Official Python SDK | GitHub |
| [a2aproject/a2a-java](https://github.com/a2aproject/a2a-java) | Java | Official Java SDK (Quarkus) | GitHub |
| [madhurprash/A2A-Multi-Agents-AgentCore](https://github.com/madhurprash/A2A-Multi-Agents-AgentCore) | Python | Incident response multi-agent example (OpenAI + Strands + AgentCore) | GitHub |
| [awslabs/amazon-bedrock-agentcore-samples](https://github.com/awslabs/amazon-bedrock-agentcore-samples) | Python | AWS Bedrock AgentCore samples including A2A incident response | GitHub |
| [5enxia/langgraph-multiagent-with-a2a](https://github.com/5enxia/langgraph-multiagent-with-a2a) | Python | LangGraph supervisor-specialist pattern with A2A | GitHub |
| [ai-boost/awesome-a2a](https://github.com/ai-boost/awesome-a2a) | Various | Curated list of A2A agents, tools, servers | GitHub |

**Quick Start**: Clone a2a-samples, run Python hello world example to get first A2A server running in ~10 minutes.

### Latency, Debugging, and Operational Concerns

**Latency:**
- Agent-to-agent chains introduce unpredictable latency
- Root-cause analysis difficult without tracing
- Recommendations: Caching, batching, circuit-breaking for resilience
- Tools: OpenTelemetry-powered tracing, A2A Inspector web tool for debugging

**State Management:**
- A2A defines six-state task lifecycle for granular progress tracking
- Designed for both instantaneous responses and long-running autonomous work
- Handles interruptions and failure recovery without custom implementation

**Debugging:**
- A2A Inspector: Web-based tool to connect to agents, inspect cards, validate protocol compliance, debug JSON-RPC messages
- OpenTelemetry integration: Unified span tracing across agent interactions
- Status: Tools exist but not fully mature compared to traditional microservices observability

**Permission Scoping ("Confused Deputy" Problem):**
- When agent A delegates to agent B, agent B operates with B's own credentials—not A's or the original user's
- Each agent must have minimal required permissions for its role
- Servers must not reveal existence of unauthorized resources
- Architecture requires careful per-agent permission design; no automated tooling found

### MCP vs. A2A for Internal Tooling

**Key Trade-Off:**
- **Single Agent + MCP**: One agent with many tools; simpler, but agent must handle all contexts; agent is single point of complexity
- **Multi-Agent + A2A**: Many focused agents; distributed complexity; requires coordination overhead but better permission scoping and "black box" isolation

**When to Use A2A for Internal Tooling:**
1. Need clear permission boundaries between systems (DB agent runs with DB creds only, deploy agent with deploy creds, etc.)
2. Different teams own different agents and want them isolated
3. Agents need to be replaceable/upgradeable independently
4. Complex orchestration scenarios where one agent needs to delegate to many specialists
5. You want agents to hide internal tools/logic from each other

**When to Stick with Single Agent + MCP:**
1. All internal systems trust each other equally
2. Simpler to debug and reason about (one agent, many tools)
3. Fewer operational systems to manage
4. Team is small or tightly integrated
5. Agents don't need to communicate with external agents

**Current Reality**: MCP is further along in adoption for internal tooling. A2A adoption is growing but skews toward cross-organization and external-facing use cases.

---

## Sources

### Official A2A Documentation and Specifications
- [A2A Protocol Specification (Overview)](https://a2a-protocol.org/latest/specification/)
- [A2A Protocol Official Repository](https://github.com/a2aproject/A2A)
- [Agent2Agent Protocol Community Docs](https://agent2agent.info/)
- [Google ADK (Agent Development Kit) A2A Docs](https://google.github.io/adk-docs/a2a/intro/)
- [Agent Card Specification](https://agent2agent.info/docs/concepts/agentcard/)

### Production Examples and Case Studies
- [Gordon Food Service + Tyson Foods Case Study](https://cloud.google.com/customers/gordonfoodservice)
- [Google Cloud Blog: A2A Protocol Announcement](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)
- [AWS Bedrock AgentCore A2A Protocol Contract](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-a2a-protocol-contract.html)
- [AWS ML Blog: A2A Support in Bedrock AgentCore](https://aws.amazon.com/blogs/machine-learning/introducing-agent-to-agent-protocol-support-in-amazon-bedrock-agentcore-runtime/)
- [A2A Enterprise Implementation Case Study](https://agent2agent.info/blog/implementing-a2a-in-enterprise/)

### Real-World Examples and Implementations
- [Incident Response & Operations Multi-Agent System (Madhur Prashant)](https://medium.com/@madhur.prashant7/incident-response-operations-multi-agent-a2a-system-with-bedrock-agentcore-primitives-openai-7a0ccb991d5d)
- [AWS Bedrock AgentCore A2A Incident Response Sample](https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/02-use-cases/A2A-multi-agent-incident-response)
- [A2A Multi-Agents with AgentCore (GitHub)](https://github.com/madhurprash/A2A-Multi-Agents-AgentCore)

### Framework Integrations and Examples
- [CrewAI A2A Protocol Documentation](https://docs.crewai.com/en/learn/a2a-agent-delegation)
- [LangGraph + A2A Tutorial](https://a2aprotocol.ai/blog/a2a-langraph-tutorial-20250513)
- [Building A2A Agents with LangGraph and watsonx.ai](https://heidloff.net/article/a2a-langgraph-watsonx-ai/)
- [LangGraph Supervisor Multi-Agent with A2A](https://github.com/5enxia/langgraph-multiagent-with-a2a)
- [Playing Around with A2A — LangGraph & CrewAI](https://heemeng.medium.com/playing-around-with-a2a-langgraph-crewai-0f47d9414eb6)

### Agent Discovery and Registry
- [A2A Agent Discovery Specification](https://a2a-protocol.org/latest/topics/agent-discovery/)
- [A2A Registry GitHub (gRPC-based)](https://github.com/allenday/a2a-registry)
- [A2A Agent Registry Proposal (Discussion)](https://github.com/a2aproject/A2A/discussions/741)
- [Building an AI Agent Registry Server with FastAPI](https://dev.to/sreeni5018/building-an-ai-agent-registry-server-with-fastapi-enabling-seamless-agent-discovery-via-a2a-15dj)

### Architecture and Best Practices
- [Microsoft Cloud Blog: A2A Protocol Support](https://www.microsoft.com/en-us/microsoft-cloud/blog/2025/05/07/empowering-multi-agent-apps-with-the-open-agent2agent-a2a-protocol/)
- [IBM: What Is Agent2Agent Protocol?](https://www.ibm.com/think/topics/agent2agent-protocol)
- [AWS Open Source Blog: Inter-Agent Communication on A2A](https://aws.amazon.com/blogs/opensource/open-protocols-for-agent-interoperability-part-4-inter-agent-communication-on-a2a/)
- [InfoQ: Architecting Agentic MLOps with A2A and MCP](https://www.infoq.com/articles/architecting-agentic-mlops-a2a-mcp/)
- [HiveMQ: A2A for Enterprise-Scale AI Agent Communication](https://www.hivemq.com/blog/a2a-enterprise-scale-agentic-ai-collaboration-part-1/)
- [Solo.io: Agent Discovery, Naming, and Resolution](https://www.solo.io/blog/agent-discovery-naming-and-resolution---the-missing-pieces-to-a2a)

### MCP vs. A2A Comparisons
- [C-Data: When to Choose Single Agent + MCP or Multi-Agent + A2A](https://www.cdata.com/blog/choosing-single-agent-with-mcp-vs-multi-agent-with-a2a)
- [KDnuggets: Building AI Agents - A2A vs. MCP Explained](https://www.kdnuggets.com/building-ai-agents-a2a-vs-mcp-explained-simply)
- [Auth0: MCP vs A2A - A Guide to AI Agent Communication Protocols](https://auth0.com/blog/mcp-vs-a2a/)
- [Leanware: A2A vs MCP Protocol Comparison](https://www.leanware.co/insights/a2a-vs-mcp-protocol-comparison)
- [TrueFoundry: MCP vs A2A Key Differences](https://www.truefoundry.com/blog/mcp-vs-a2a)
- [Agent2Agent Protocol Community: A2A and MCP](https://agent2agent.info/docs/topics/a2a-and-mcp/)

### Official Samples and SDKs
- [A2A Samples Repository](https://github.com/a2aproject/a2a-samples)
- [Official Python SDK](https://github.com/a2aproject/a2a-python)
- [Official Java SDK](https://github.com/a2aproject/a2a-java)
- [Google ADK QuickStart: Exposing Agents](https://google.github.io/adk-docs/a2a/quickstart-exposing/)
- [Google Codelabs: Purchasing Concierge Multi-Agent Example](https://codelabs.developers.google.com/intro-a2a-purchasing-concierge)

### Operational Concerns and Debugging
- [liteLLM: Agent Permission Management](https://docs.litellm.ai/docs/a2a_agent_permissions)
- [A2A Inspector Documentation](https://a2aprotocol.ai/docs/guide/a2a-inspector)
- [AWS Bedrock AgentCore Best Practices](https://aws.amazon.com/blogs/machine-learning/ai-agents-in-enterprises-best-practices-with-amazon-bedrock-agentcore/)

---

## Confidence Levels

### High Confidence Findings

| Finding | Why |
|---|---|
| **A2A has production usage in supply chain (Gordon/Tyson)** | Official Google Cloud case study, public customer reference, moving to production deployment |
| **AWS Bedrock AgentCore is production-ready for A2A** | Official AWS documentation, real GitHub examples, AWS blog announcement |
| **Multi-agent A2A complements single-agent MCP** | Consistent across multiple framework docs (CrewAI, LangGraph, official A2A) and architectural comparisons |
| **Agent Cards are the standardized discovery mechanism** | Specified in A2A protocol, implemented in all major frameworks |
| **Permission scoping per agent is a real architectural need** | Mentioned in AWS docs, multiple architecture guides, and is a core design intent of A2A |

### Medium Confidence Findings

| Finding | Why |
|---|---|
| **CrewAI and LangGraph both support A2A fully** | Documentation exists, examples available, but adoption/usage unclear |
| **Well-known path is the simplest discovery for internal tooling** | Logical inference from protocol design; no explicit internal tooling docs |
| **A2A is further behind MCP in adoption** | Multiple sources state this, but hard to quantify; based on documentation maturity and example availability |
| **Latency can be unpredictable in agent chains** | Documented in AWS best practices and architecture guides; mitigation strategies suggested but not deeply analyzed |
| **Hub-and-spoke is the common architecture pattern** | Seen in Bedrock example, incident response example, but limited sample size |

### Low Confidence Findings

| Finding | Why |
|---|---|
| **Minimum viable team size for A2A internal tooling** | No sources provide this data; pure inference from sample complexity |
| **Setup time for A2A internal systems** | No explicit timelines found; ADK samples are fast (minutes) but scaling unclear |
| **Most teams choose direct configuration for agent discovery internally** | Logical inference but not explicitly documented; well-known path and registries are more "correct" |
| **Debugging and latency monitoring are "not fully mature"** | A2A Inspector and OpenTelemetry exist, but no comparison to mature observability tools |
| **Internal-only tooling reasons for choosing A2A over single agent** | Extrapolated from architectural principles, not from documented internal tooling examples |

---

## Open Questions

1. **Are there production internal developer tooling examples we missed?** We found none via web search. It's possible companies are building this privately and not publishing case studies. Check: internal Slack channels of dev-tools companies, paid research reports (Gartner, Forrester), private GitHub repos if accessible.

2. **What does actual setup timeline look like for internal-only A2A?** How long to: scaffold 3-5 agents, set up agent discovery, deploy, make first inter-agent call? This would be crucial for deciding MCP vs. A2A. No sources provided concrete data.

3. **How do teams actually manage agent discovery internally?** The spec leaves this open. Are teams using well-known paths (what DNS does lookup use?), deploying a registry server, or just hardcoding URLs? What works best in practice?

4. **What's the operational overhead of A2A vs. single agent + MCP?** How much more operational burden (debugging, tracing, permission management)? This is a decision point but not documented in sources.

5. **Has anyone published permission scoping patterns/policies?** The "confused deputy" problem is named but no reusable patterns or policy templates found. Is this something teams discover through pain?

6. **Which frameworks are production-safe?** AWS Bedrock AgentCore is clearly mature. What about CrewAI and LangGraph for critical internal tooling? No SLA/support guarantees documented.

7. **Are there reference implementations of database, deploy, or code review agents using A2A?** These would be directly applicable to Brian's use case. None found; only tutorials and supply chain examples.

8. **What's the actual failure mode when A2A chains break?** How do errors cascade? How easy to debug? Observability tools exist but no documented debugging war stories.

---

## Summary for Decision-Making

**For Internal Developer Tooling (like Brian's use case):**

1. **A2A is not yet the default choice for pure internal tooling.** MCP + single agent is simpler and further along in adoption. A2A becomes valuable when you need per-agent permission scoping, multi-team ownership, or agent isolation.

2. **If you go A2A, AWS Bedrock AgentCore is the safest bet** for production. It has the most mature implementation, real examples, and operational support.

3. **Agent discovery is a design choice you make—no standard solution** for internal setups. Simplest is well-known paths; most scalable is a registry; most pragmatic is config files.

4. **Permission scoping per agent is valuable** if you have a DB agent, deploy agent, and monitoring agent that need different access levels. This is a genuine architectural win.

5. **No documented examples exist for internal dev tooling agents** (DB, deploy, code review). You'd be building somewhat in the dark on this use case.

6. **Setup timeline and minimum team size are unknowns.** Plan conservatively.

7. **Latency and debugging are knowable but require investment** in observability tooling beyond what comes out of the box.

---

**Last Updated**: March 28, 2026
