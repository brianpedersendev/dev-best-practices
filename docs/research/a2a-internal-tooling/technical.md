# A2A Internal Tooling: Technical Pitfalls, Debugging, and Minimum Viable Setup

**Date**: 2026-03-28
**Research Focus**: Practical blockers, observability, permission models, and smallest viable system

---

## Key Findings (Priority Order)

### 1. **Authorization is NOT Standardized — It's a Footgun**
**Confidence: High**

A2A specifies authentication (verifying agent identity) but explicitly does NOT prescribe a standard authorization model. Once a remote agent authenticates a calling agent, authorization decisions are delegated back to the remote agent — leading to late or implicit authorization checks.

**The Problem**: An agent may accept a task before determining which internal tools it needs, discovering permissions gaps only mid-execution. This creates "authorization creep" where permission logic gets scattered across agents, inconsistent enforcement, and silent capability escalation.

**Impact for Internal Tooling**: If you're decomposing a monolithic agent into DB, Deploy, and Monitoring agents, each gets its own ad-hoc authorization logic unless you build a shared framework. No standard way to scope "this agent can only deploy to staging, not production."

---

### 2. **A2A Introduces Tight Coupling via O(n²) Complexity**
**Confidence: High**

Direct agent-to-agent HTTP/gRPC connections scale badly. As the number of agents grows, the number of required connections grows quadratically. This is the opposite of what "modular tooling" should feel like.

**The Problem**: 5 agents → 10 connections. 10 agents → 45 connections. 20 agents → 190 connections. Managing auth, discovery, and error paths across all of these becomes a coordination nightmare.

**For Internal Tooling**: If your goal is to keep agents simple and loosely coupled, A2A's point-to-point model fights you. You end up needing an orchestrator or service mesh to manage the chaos.

---

### 3. **Debugging Across Agent Boundaries is Opaque Without Tooling**
**Confidence: High**

Agent chains introduce unpredictable latency and tracing gaps. Without explicit observability setup, it's hard to:
- Trace a request through 3-4 agents and know where it failed
- Understand which agent made which decision
- Reproduce errors that only happen in the agent chain

**Current Solutions**:
- **LangSmith** (framework-agnostic): Captures every LLM call, tool invocation, and intermediate reasoning step. Works with LangChain, LangGraph, or custom code via SDK (Python, TypeScript, Go, Java). Single environment variable enables automatic instrumentation.
- **Langfuse** (open-source): Self-hostable alternative; tracks token counts, execution duration, and request parameters via OpenTelemetry-compatible traces.
- **LangTrace**: Tracks cost and latency but less suitable for debugging agent coordination.

**For Internal Tooling**: You'll need to integrate LangSmith or Langfuse from day one. Graph-based visualization (LangGraph) is 60% faster for debugging than text logs.

---

### 4. **State Management Requires Explicit Design**
**Confidence: High**

A2A provides a `contextId` to link tasks across agents and a "Shared Session State" mechanism, but:
- Each agent maintains its own internal state
- Context sharing is limited to "relevant segments" (not full state)
- No built-in persistence for state across agent hops
- Teams typically need a shared database or session store

**Common Pattern**: Orchestrator agent holds task state; worker agents receive scoped context and return results that the orchestrator merges.

**For Internal Tooling**: You'll need to decide:
- Does the DB agent maintain transaction state between calls?
- Does the Deploy agent track intermediate steps (validated → deployed → rolled out)?
- If agents restart, how do they resume partial work?

**Recommendation**: Use a lightweight state machine (stored in a shared database) rather than relying on A2A's context passing alone.

---

### 5. **Permission Scoping Requires Short-Lived Tokens + Explicit Scopes**
**Confidence: High**

A2A's recommended pattern:
- Use short-lived tokens (minutes, not hours)
- Scoped to specific agents and skills
- Each agent enforces user permissions on its own tools

**Known Limitation**: Without a shared permission model (policy server), you end up repeating "is this user allowed to deploy?" logic in every agent.

**For Internal Tooling**: Use scoped service accounts per agent:
- `db-agent`: Can read/write to specific tables only
- `deploy-agent`: Can deploy to staging, read-only on prod configs
- `monitoring-agent`: Can read metrics, query logs, no write permissions

**Implementation**: Use OAuth scopes or OIDC `scope` parameter to pass least-privilege claims from orchestrator → agent.

---

### 6. **SDK Maturity is Uneven; Python is Further Along Than TypeScript**
**Confidence: High**

**Python SDK** (A2A/ADK):
- Version 1.0.0a0 (alpha) released March 17, 2026
- Supports both A2A spec v0.3.0 and v1.0 (1.0-dev branch)
- Core features: async operations, protocol flexibility, in-memory backends for testing

**JavaScript/TypeScript SDK**:
- v0.3.0 available
- A2A multi-agent implementation was still in design phase as of January 2026
- Less mature than Python

**Google ADK (Python)**:
- Includes utilities like `to_a2a()` to wrap existing agents
- Auto-generates agent cards from code
- Provides in-memory services for testing (SessionService, MemoryService, CredentialService)
- Sample: `adk-python/contributing/samples/a2a_human_in_loop/`

**Missing from SDKs**:
- No standard mocking framework for testing agent chains
- No built-in contract testing between agents
- Limited observability hooks (must use LangSmith/Langfuse)

---

### 7. **Latency Overhead is Measurable but Protocol Includes Optimization**
**Confidence: Medium**

**Key Finding**: Direct in-memory sub-agents are very fast; A2A agents introduce network overhead.

- **Local sub-agents**: No serialization/deserialization; direct memory access
- **Remote A2A agents**: HTTP/gRPC round-trip + request/response serialization

**A2A Optimizations**:
- Compressed communication with data compression algorithms
- Asynchronous message routing (non-blocking, event-driven)
- Intelligent routing algorithms to select efficient paths
- gRPC support (more efficient than HTTP REST)

**Latency Awareness**: A2A v0.3 includes a "Latency Extension" where agents broadcast their latency, enabling systems to route to the most responsive agent or adapt gracefully (e.g., play filler prompts for high-latency agents).

**Benchmark Context**: No published benchmark directly comparing A2A agent calls vs direct tool calls, but related work (ProtocolBench) measures latency, throughput, message overhead, and failure robustness across agent protocols.

**For Internal Tooling**: If agents are co-located or in the same cluster, use local sub-agents for hot paths; use A2A for loosely coupled agents (e.g., external deploy service).

---

### 8. **Cascading Failures are a Real Risk Without Explicit Handling**
**Confidence: Medium**

**The Problem**: Inter-agent protocols can carry "poisoned" payloads. Semantic errors (e.g., price as "1000" instead of "100.00") pass validation and propagate silently through agent chains, corrupting downstream agents' work.

**Current State**: A2A provides machine-readable error codes and Retry-After guidance, but higher-level cascading failure patterns (circuit breakers, bulkheads, compensation) are NOT in the spec.

**For Internal Tooling**: You need to build:
- Circuit breakers (stop calling Deploy agent if 3 recent calls failed)
- Timeout enforcement (if DB agent doesn't respond in 10s, fail fast)
- Compensation logic (rollback deployed code if monitoring agent detects errors)
- Validation at agent boundaries (don't accept malformed inputs from other agents)

**Tooling Gap**: No standard circuit breaker library for A2A agents yet.

---

### 9. **Agent Discovery Has No Standard; Teams Build Custom Registries**
**Confidence: Medium**

A2A spec does NOT prescribe how agents discover each other. The community explores solutions:

**Pattern 1: Agent Cards + Curated Registry**
- Each agent publishes an Agent Card (JSON with capabilities, endpoints, auth schemes)
- Central registry stores these cards
- Clients query registry to find agents by skill or tag

**Pattern 2: Agent Naming Service (ANS)**
- Allows discovery by describing what you need ("find an agent that can deploy code")
- More sophisticated than simple catalogs

**Current Implementations**:
- `allenday/a2a-registry`: gRPC-based registry
- `A2ABaseAI/A2ARegistry`: Alternative implementation
- `FastAPI` sample: DEV Community tutorial on building custom registry

**For Internal Tooling**: You'll likely build or adopt a simple registry:
- List all available agents (DB, Deploy, Monitoring) in a config file or small database
- Let orchestrator query it to find the right agent
- Include skill descriptions and auth requirements in Agent Cards

---

### 10. **Testing Multi-Agent A2A Systems Lacks Standardized Practices**
**Confidence: Medium**

**Current Approaches**:
- **Mocking LLM calls**: Enforce reproducible agent behavior by mocking LLM APIs (not A2A protocol itself)
- **Integration tests**: Test agent components together, but mocked interactions assume predictable communication flows
- **Real multi-agent behavior**: Adaptation based on context/load/availability breaks mocked tests

**Known Limitation**: Real multi-agent systems don't follow the predictable paths that unit tests assume.

**For Internal Tooling**: Recommended testing strategy:
1. **Unit tests**: Test each agent's logic with mocked LLM (Claude API)
2. **Integration tests**: Test agent-to-agent happy paths with mocked A2A responses
3. **Contract tests**: Verify Agent Cards match actual capabilities
4. **E2E tests**: Run full chain in staging with real agents

---

## Details (Evidence & Context)

### Debugging & Observability

**LangSmith Integration Example**:
```python
# Set environment variable, tracing just works
os.environ['LANGSMITH_API_KEY'] = '...'

# Every LLM call, tool invocation, and reasoning step is captured
# Accessible via LangSmith UI with latency breakdown
```

**Tracing a Multi-Agent Request**:
1. Request enters orchestrator agent
2. Orchestrator calls Deploy agent via A2A
3. Deploy agent calls Monitoring agent to validate
4. Results flow back up
5. LangSmith trace shows full path, latencies at each hop, and where failures occurred

**What You Get from LangSmith**:
- Latency breakdown per agent
- Token usage per LLM call
- Tool execution times
- Error stack traces with context
- Replay/debugging of failed chains

---

### Permission Scoping in Practice

**Example: DB Agent with Least Privilege**

```python
# Agent card specifies scoped capabilities
agent_card = {
    "name": "db-agent",
    "skills": [
        {
            "name": "query_users",
            "description": "Query user table (read-only)",
            "requires_scopes": ["database:read:users"]
        },
        {
            "name": "write_logs",
            "description": "Write to audit log (append-only)",
            "requires_scopes": ["database:write:logs"]
        }
    ]
}

# Orchestrator passes scoped token
token = create_scoped_token(
    agent='db-agent',
    scopes=['database:read:users', 'database:write:logs'],
    expires_in=300  # 5 minutes
)

# DB agent receives token, enforces scopes on each tool call
# If it needs to write to `users` table → denied
```

**Authentication Flow**:
1. Orchestrator agent has full user context
2. Orchestrator creates scoped token (minutes, not hours)
3. Orchestrator passes token + scoped task to worker agent
4. Worker agent uses token to access resources
5. Token auto-expires; no static secrets

---

### State Sharing Patterns

**Pattern 1: Orchestrator-Managed State**
```python
# Orchestrator holds state
task_state = {
    'id': 'deploy-123',
    'status': 'validated',
    'config': {...},
    'step': 'deploy'
}

# Call next agent with scoped context
result = deploy_agent.execute(task_id='deploy-123', context=task_state)

# Update state with result
task_state['status'] = result['status']
```

**Pattern 2: Shared Session State via A2A contextId**
```python
# A2A provides contextId to link tasks
context_id = 'session-456'

# All agents in the chain share this context
db_result = db_agent.execute(context_id=context_id, query='...')
monitor_result = monitor_agent.execute(context_id=context_id, metric='...')
# Both agents can access shared session state
```

**Limitation**: Shared state is read-only segments; for mutable state, use a database.

---

### Error Handling & Cascading Failures

**What You Need to Build**:

```python
# Circuit breaker
class A2ACircuitBreaker:
    def __init__(self, agent, failure_threshold=3, timeout=60):
        self.agent = agent
        self.failures = 0
        self.last_failure = None

    def call(self, *args, **kwargs):
        if self.failures >= self.failure_threshold:
            if time.time() - self.last_failure < self.timeout:
                raise CircuitBreakerOpen(f'{self.agent} is down')

        try:
            result = self.agent.execute(*args, **kwargs)
            self.failures = 0
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure = time.time()
            raise

# Validation at boundaries
def validate_agent_input(agent_name, input_data):
    schema = AGENT_SCHEMAS[agent_name]
    if not schema.validate(input_data):
        raise ValueError(f'Invalid input for {agent_name}')
    return input_data

# Timeout enforcement
result = asyncio.wait_for(
    deploy_agent.execute(task),
    timeout=30.0  # 30 seconds max
)
```

---

### Agent Discovery via Registry

**Minimal Registry Setup**:

```python
# agents.yaml
agents:
  - name: db-agent
    endpoint: http://localhost:8001
    card_url: http://localhost:8001/.well-known/agent-card
    skills: [query_database, write_logs]
    scopes: [database:read:*, database:write:logs]

  - name: deploy-agent
    endpoint: http://localhost:8002
    card_url: http://localhost:8002/.well-known/agent-card
    skills: [deploy_code, check_status]
    scopes: [deploy:staging, monitor:metrics]

  - name: monitor-agent
    endpoint: http://localhost:8003
    card_url: http://localhost:8003/.well-known/agent-card
    skills: [query_metrics, fetch_logs]
    scopes: [monitor:read]

# Orchestrator uses registry
registry = load_agents('agents.yaml')
deploy_agent = registry.find_agent(skill='deploy_code', scope='deploy:staging')
result = deploy_agent.execute(task)
```

---

## Minimum Viable Setup

### Recommendation: 2-Agent Internal Tooling System

**Why 2 Agents?**
- Simple enough to debug (tracing is clear)
- Complex enough to validate A2A patterns
- Real-world use case (orchestrator + specialist)
- Fits in ~40-80 hours of work

### Architecture

```
Orchestrator Agent (Claude)
    ↓ A2A call
Worker Agent (Claude or simpler LLM)
    ↓ Local tools (DB queries, file writes, etc.)
Results
```

### Concrete Example: Task Processing System

**Agent 1: Task Orchestrator**
- Receives user request
- Decomposes into steps
- Delegates to Worker via A2A
- Aggregates results
- Handles timeouts and retries

**Agent 2: Task Worker**
- Receives task + scoped context
- Executes specialized work (e.g., database query)
- Returns structured result
- Logs errors for orchestrator

### Stack Choice

**Framework**: Google ADK (Python)
```bash
pip install google-adk[a2a]
```

**Observability**: LangSmith (free tier; 1M tokens/month)
```bash
export LANGSMITH_API_KEY=...
```

**Deployment**: Docker + Uvicorn
```dockerfile
FROM python:3.11-slim
RUN pip install google-adk[a2a] uvicorn
COPY agent.py .
CMD ["uvicorn", "agent:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Testing**: Pytest + mocked A2A responses
```bash
pip install pytest pytest-asyncio google-adk[testing]
```

### Estimated Timeline

| Phase | Hours | Deliverable |
|-------|-------|-------------|
| Setup & skeleton | 4 | Two agents running locally |
| Core logic | 16 | Orchestrator + Worker MVP |
| A2A integration | 12 | Agents talking via A2A protocol |
| Observability | 8 | LangSmith tracing working |
| Error handling | 12 | Circuit breakers, timeouts, retries |
| Tests | 8 | Integration + E2E test suite |
| Documentation | 4 | Agent cards, deployment guide |
| **Total** | **64 hours** | Production-ready 2-agent system |

### What You'll Learn

1. **Debugging**: Use LangSmith to trace a request through 2 agents
2. **Error handling**: Hit cascading failure scenarios, build mitigations
3. **State management**: Decide between orchestrator-held state vs shared session state
4. **Permissions**: Scope tokens per agent; enforce least privilege
5. **Discovery**: Build or configure a simple agent registry
6. **Testing**: Write contract tests between agents

### Gotchas to Avoid

1. **Skip observability setup**: You'll regret it after 3 bugs. Integrate LangSmith from day 1.
2. **Assume A2A handles retries**: It doesn't. You build circuit breakers and timeouts.
3. **Share full state between agents**: Only pass what each agent needs.
4. **Forget to expire tokens**: Use short-lived tokens (5-10 minutes).
5. **Build custom permission logic in each agent**: Use a shared token/scope model.

---

## Sources

### A2A Protocol Fundamentals
- [Agent2Agent (A2A) Protocol - Google Developers Blog](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)
- [A2A Protocol Official Specification](https://a2a-protocol.org/latest/specification/)
- [A2A Protocol - Agent Development Kit (ADK)](https://google.github.io/adk-docs/a2a/)
- [IBM: What Is Agent2Agent (A2A) Protocol?](https://www.ibm.com/think/topics/agent2agent-protocol)

### Debugging & Observability
- [LangSmith: AI Agent & LLM Observability Platform](https://www.langchain.com/langsmith/observability)
- [LangSmith for Agent Observability: Tracing LangGraph + Tool-Calling End-to-End](https://ravjot03.medium.com/langsmith-for-agent-observability-tracing-langgraph-tool-calling-end-to-end-2a97d0024dfb)
- [LangGraph Observability and Debugging — LangSmith Tracing in Practice](https://machinelearningplus.com/gen-ai/langgraph-observability-debugging-langsmith-tracing/)
- [15 AI Agent Observability Tools in 2026: AgentOps & Langfuse](https://aimultiple.com/agentic-monitoring/)

### Pitfalls & Challenges
- [A2A for Enterprise-Scale AI Agent Communication: Architectural Needs and Limitations](https://www.hivemq.com/blog/a2a-enterprise-scale-agentic-ai-collaboration-part-1/)
- [Cascading Failures in Agentic AI: Complete OWASP ASI08 Security Guide 2026](https://adversa.ai/blog/cascading-failures-in-agentic-ai-complete-owasp-asi08-security-guide-2026/)
- [Deep Dive MCP and A2A Attack Vectors for AI Agents](https://www.solo.io/blog/deep-dive-mcp-and-a2a-attack-vectors-for-ai-agents/)

### Authentication & Permission Scoping
- [Agent2Agent (A2A) Authentication - Microsoft Foundry](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/agent-to-agent-authentication)
- [How to Enhance Agent2Agent (A2A) Security](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security/)
- [Governance and Security for AI Agents Across the Organization](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ai-agents/governance-security-across-organization/)
- [Access Control in the Era of AI Agents](https://auth0.com/blog/access-control-in-the-era-of-ai-agents/)

### State Management & Context Sharing
- [A2A Protocol: Managing Conversation History in AI Agents](https://www.byteplus.com/en/topic/551296)
- [Recommended Pattern for Propagating User Context via A2A](https://github.com/google/adk-python/discussions/3743)
- [Life of a Task - A2A Protocol](https://a2a-protocol.org/latest/topics/life-of-a-task/)
- [Beyond Context Sharing: A Unified Agent Communication Protocol (ACP)](https://arxiv.org/html/2602.15055)

### Latency & Performance
- [Agent2Agent Protocol (A2A) is Getting an Upgrade - Google Cloud Blog](https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade/)
- [Latency Extension for A2A: Optimizing Agent Routing](https://www.twilio.com/en-us/blog/developers/latency-extension-a2a/)
- [A Survey of Agent Interoperability Protocols (ProtocolBench)](https://arxiv.org/html/2505.02279v1)

### SDK Maturity
- [A2A Python SDK - PyPI](https://pypi.org/project/a2a-sdk/)
- [Google ADK - PyPI](https://pypi.org/project/google-adk/)
- [GitHub: google/adk-python](https://github.com/google/adk-python)
- [GitHub: a2aproject/a2a-python](https://github.com/a2aproject/a2a-python)

### Agent Discovery
- [Agent Discovery - A2A Protocol](https://a2a-protocol.org/latest/topics/agent-discovery/)
- [Agent Registry - A2A Discussion](https://github.com/a2aproject/A2A/discussions/741)
- [GitHub: allenday/a2a-registry](https://github.com/allenday/a2a-registry)
- [Building an AI Agent Registry Server with FastAPI](https://dev.to/sreeni5018/building-an-ai-agent-registry-server-with-fastapi-enabling-seamless-agent-discovery-via-a2a-15dj)

### Testing Multi-Agent Systems
- [Multi-Agent Testing Systems: How Cooperative AI Agents Validate Complex Applications](https://www.virtuosoqa.com/post/multi-agent-testing-systems-cooperative-ai-validate-complex-applications/)
- [An Empirical Study of Testing Practices in Open Source AI Agent Frameworks](https://arxiv.org/html/2509.19185v1)
- [Validating Multi-Agent AI Systems: From Modular Testing to System-Level Governance](https://www.pwc.com/us/en/services/audit-assurance/library/validating-multi-agent-ai-systems.html/)

---

## Confidence Levels

| Finding | Confidence | Reasoning |
|---------|-----------|-----------|
| Authorization is not standardized | **High** | Multiple sources confirm A2A spec leaves auth to remote agent; direct quotes in research |
| O(n²) scaling problem | **High** | Well-known distributed systems issue; confirmed in multiple sources |
| Debugging needs external tooling | **High** | LangSmith/Langfuse required for tracing; no built-in A2A observability |
| State management requires design | **High** | A2A provides mechanism (contextId) but not persistence; teams use shared databases |
| Short-lived token pattern | **High** | Multiple sources recommend; matches OAuth/OIDC best practices |
| SDK Python > TypeScript maturity | **High** | Python has v1.0.0a0; TypeScript A2A still in design (Jan 2026) |
| Latency overhead exists | **High** | Network overhead confirmed; no published A2A vs direct tool benchmarks |
| Cascading failures are a risk | **Medium** | Agentic AI research confirms; A2A protocol does not include mitigation patterns |
| Agent discovery is custom-built | **Medium** | Community exploring solutions; no standard yet; multiple implementations exist |
| Testing lacks standards | **Medium** | Research shows "adaptation breaks mocked tests" but no standard framework exists |
| Minimum viable: 2 agents, 64 hours | **Medium** | Based on ADK complexity + observability + error handling; not from published benchmarks |

---

## Open Questions

1. **Production Deployments**: Are there published case studies of A2A-based internal tooling in production? (Not found in this research)
2. **Benchmarking**: What's the actual latency overhead of A2A calls vs direct tool calls? (No published benchmarks found)
3. **Cascading Failure Patterns**: Has anyone published a standard circuit breaker library for A2A? (Not found)
4. **TypeScript SDK**: What's the timeline for TypeScript A2A to reach parity with Python? (Still in design as of Jan 2026)
5. **Agent Card Schema**: Is there a standardized JSON schema for Agent Cards? (Found references but not a canonical spec)
6. **Rollback Semantics**: How do teams handle rollback when a downstream agent fails partway through? (Not covered in A2A spec)
7. **Multi-Tenancy**: How do you isolate state and permissions for multiple users/organizations via A2A? (Not researched in detail)
