# Agent-Scale Observability with OpenTelemetry GenAI

**Date: 2026-03-28** | **Status: Production-Ready** | **Last Verified: 2026-03-28**

## Why Agent Observability Is Different

Traditional APM (Application Performance Monitoring) assumes deterministic behavior—requests follow predictable paths, code execution is traceable, and outcomes are reproducible. Agent systems break these assumptions.

### Key Differences from Traditional Systems

**Non-determinism & Stochasticity**: The same input produces different outputs. A task might succeed on the first attempt, fail on the second, and partially succeed on the third. Traditional alerting based on success/failure rates becomes meaningless. You need quality metrics that account for variance: hallucination rate, task completion rate, output consistency.

**Variable Costs**: Token usage varies with context length, model reasoning depth, and retry attempts. A single request might cost $0.001 or $1.00 depending on the agent's reasoning path. Traditional latency-based SLOs don't capture cost anomalies—you need per-step token tracking and cost alerts.

**Multi-Step Reasoning**: Agent execution spans unpredictable numbers of steps: reasoning loops, tool calls, retrieval-augmented generation (RAG), verification checks. A single customer request might trigger 2 API calls or 20, depending on complexity. You need distributed tracing across the entire reasoning chain, not just end-to-end latency.

**Tool Call Chains**: Agents don't just call LLMs—they orchestrate sequences of external APIs (search, databases, calculators, file systems). Failures are often downstream (tool timeout, API rate limit, malformed data) not in the model itself. You need visibility into tool execution: what was called, what returned, why it failed.

**Hallucination & Quality Drift**: LLMs can confidently produce false information. Unlike traditional bugs that fail consistently, hallucinations are probabilistic and drift over time. You need evaluators that score output quality, track hallucination rates, and detect quality degradation in production.

**User Feedback as Signal**: Non-deterministic systems require human feedback loops. "Was this answer correct?" becomes a first-class observability signal, feeding back into continuous evaluation and safe rollouts.

### Why Traditional APM Falls Short

- **Error rates alone are insufficient**: A 99% success rate for agents might mean 1% hallucination rate, not 1% broken requests.
- **Latency is incomplete**: P99 latency tells you nothing about cost distribution; a high-latency request with 10K tokens costs 100x more than a fast one.
- **Token counts aren't optional**: You can't observe AI agents without tracking tokens and cost per unit of work.
- **Sampling 100% of traces is costly**: A single agent call might generate 50+ spans (each model invocation, tool call, retrieval). At scale, this is prohibitively expensive without intelligent sampling.
- **Prompts and completions contain sensitive data**: Traditional log redaction doesn't account for semantic PII (names buried in conversation context). You need agent-aware redaction.

---

## OpenTelemetry GenAI Semantic Conventions

OpenTelemetry (OTel) defines standardized attributes and span structures for observing generative AI systems. These conventions are **stable and production-ready** as of Q1 2026 for core GenAI spans, with agent-specific extensions in **experimental status** (but widely adopted by major platforms).

### What Gets Standardized

**Spans**: Structured records of operations with start/end time, attributes, events, and relationships. For AI systems:
- `gen_ai.client.operation` spans: Single model invocation (OpenAI API call, Claude API call, etc.)
- `gen_ai.server.operation` spans: Server-side model execution (for providers implementing OTel)
- Agent-specific spans: Multi-step reasoning, tool calls, agent decision loops

**Metrics**: Time-series measurements aggregating span data:
- `gen_ai.client.token.usage` (counter): Total tokens (input + output)
- `gen_ai.client.request.duration` (histogram): API response time
- Custom metrics: cost, tool success rate, hallucination count

**Events**: Point-in-time markers within spans:
- Tool invocation events: What tool was called, with what parameters
- Retrieval events: Document chunks fetched, relevance scores
- Quality check events: Hallucination detector fired, guardrail violated

**Attributes**: Key-value pairs that annotate spans:
- `gen_ai.request.model`: Model identifier ("gpt-4-turbo", "claude-3-opus")
- `gen_ai.response.stop_reason`: Why generation stopped ("end_turn", "max_tokens", "tool_use")
- `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`: Token counts
- Custom attributes: agent name, task type, user ID (with PII redaction)

### Current Specification Status

| Convention | Status | Adoption |
|---|---|---|
| GenAI Span (model invocations) | Stable | 95%+ of platforms |
| GenAI Metrics (tokens, latency) | Stable | 95%+ of platforms |
| GenAI Events (tool calls, retrieval) | Stable | 90%+ of platforms |
| GenAI Agent Spans (multi-step reasoning) | Experimental | 70%+ of enterprise agents |
| AI Agent Application Spans (orchestration) | Experimental (draft) | Adopted by CrewAI, Pydantic AI, AG2 |

**Key takeaway**: The core observability you need is standardized and stable. Agent-specific extensions are experimental but widely implemented by major frameworks.

### OTel Spec Links

- [GenAI Spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/)
- [GenAI Agent Spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/)
- [GenAI Metrics](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-metrics/)
- [GenAI Events](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-events/)

---

## Agent-Specific OTel Conventions

Agent systems introduce new span types and relationships that don't exist in simple prompt-response systems.

### Agent Span Types

**Agent Execution Span** (`gen_ai.agent.operation`)
- Represents a single agent turn (plan, act, observe cycle)
- Contains multiple child spans: one or more model invocations, tool calls, retrieval steps
- Key attributes:
  - `gen_ai.agent.name`: Agent identifier ("researcher_agent", "planner")
  - `gen_ai.agent.action`: What the agent decided ("call_tool", "continue_reasoning", "final_answer")
  - `gen_ai.agent.step_number`: Which reasoning step (1, 2, 3...)

**Tool Call Span** (child of agent execution)
- One span per tool invocation
- Attributes:
  - `gen_ai.tool.name`: Tool identifier ("search", "database_query", "calculator")
  - `gen_ai.tool.input`: Parameters passed (captured carefully—may contain user data)
  - `gen_ai.tool.output`: Result returned
  - `gen_ai.tool.error`: If the tool failed, error details
  - Duration: Includes the actual tool execution time

**Model Invocation Span** (nested, possibly multiple per agent turn)
- One per LLM API call
- Attributes:
  - `gen_ai.request.model`: Model name
  - `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`
  - `gen_ai.response.stop_reason`: Why it stopped generating
  - `gen_ai.request.temperature`, `gen_ai.request.max_tokens`: Parameters
  - Attributes for provider metadata: version, endpoint, organization

### Trace Hierarchy Example

```
Trace ID: abc123 (overall customer request)
  Span ID: root (request to agent system)
    Span ID: agent_1_turn (first agent turn)
      Span ID: model_call_1 (query retrieval RAG)
        Event: embedding_retrieved (vector store lookup)
      Span ID: tool_call_1 (search_documents)
        Status: success, Duration: 250ms
      Span ID: model_call_2 (reasoning on retrieved context)
    Span ID: agent_1_turn_2 (second agent turn—model decided to refine)
      Span ID: model_call_3
      Span ID: tool_call_2 (follow_up_search)
  Span ID: evaluation_span (post-execution quality check)
    Event: hallucination_check (comparator detected inconsistency)
```

### Multi-Agent Trace Propagation

When multiple agents collaborate:
- Each agent gets its own execution span
- Parent-child relationships are captured via span IDs
- W3C Trace Context headers propagate across process boundaries (HTTP, message queues)
- A single Trace ID ties all agents to the original request

Example: Customer request → Orchestrator Agent → Planner Agent (creates sub-trace) → Executor Agent → Feedback Agent

Each agent's spans share the original Trace ID and are linked via parent span IDs.

---

## The Observability Stack: OTel → Collectors → Backends

### Architecture Overview

```
Your Agent Code
  ↓ (OTel SDK emits spans)
OpenTelemetry Collector
  ↓ (processes, batches, samples)
Backend (Langfuse, Datadog, Elasticsearch, etc.)
  ↓
Dashboards, Alerts, Evaluations
```

### Collectors: Processing Layer

The OpenTelemetry Collector sits between your agent and the backend. It can:
- **Batch traces** (reduce network calls)
- **Sample intelligently** (keep errors, drop normal traffic)
- **Redact PII** (remove email, credit card patterns)
- **Add attributes** (inject environment, version info)
- **Filter** (drop DEBUG-level telemetry)

Typical collector config:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    send_batch_size: 512
    timeout: 5s

  # Sample: keep 100% of errors, 5% of normal traffic
  tail_sampling:
    policies:
      - name: error_traces
        error_status_policy:
          status_code: ERROR
      - name: normal_traffic
        probabilistic_sampler:
          sampling_percentage: 5

  # Redact PII patterns
  redaction:
    allow_all_keys: false
    blocked_values:
      - "\\b\\d{3}-\\d{2}-\\d{4}\\b"  # SSN
      - "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"  # Email
    blocked_keys:
      - "credit_card"
      - "api_key"

exporters:
  otlp:
    endpoint: "langfuse.example.com:4317"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, tail_sampling, redaction]
      exporters: [otlp]
```

### Backend Platforms: Comparison & Pricing

| Platform | Model | OTel Support | Agent Ops | Cost Tracking | Quality Evals | Pricing | Self-Host |
|---|---|---|---|---|---|---|---|
| **Langfuse** | Open-source-first (SaaS optional) | Native OTel + custom protocol | Excellent (multi-agent graphs) | Built-in token tracking | Yes, evals framework | Free tier: 50K events/mo; Pay-as-you-go after | Yes (MIT) |
| **LangSmith** | Closed-source SaaS (Langchain) | Native OTel | Native LangGraph support | Built-in | Yes | Free: 5K traces/mo; then ~$0.10/1K traces | Enterprise only |
| **Datadog LLM Obs** | Closed-source SaaS | Native OTel GenAI semconv (Q1 2026) | Limited (focus on LLM metrics) | Built-in | Limited (3rd party integration) | Enterprise: $20k–100k+/year | No |
| **Elastic Observability** | Closed-source SaaS | Native OTel | Good (APM + logs correlation) | Custom via APM agents | No (external evals) | Based on data ingestion; ~$0.50–2/GB | On-premise option |
| **Grafana Cloud Traces** | Closed-source SaaS | Native OTel | Moderate (needs custom dashboards) | Custom via attributes | No (external evals) | Pay-as-you-go; starts ~$1/GB ingested | Tempo (self-host) |
| **VictoriaMetrics** | Open-source | Native OTel | Good (focus on metrics & cost tracking) | Built-in metric tracking | No | Open-source (free) | Yes |
| **Phoenix/Arize** | Closed-source SaaS | Native OTel | Excellent (AI-focused) | Built-in | Yes, LLM evaluators | Pay-as-you-go; ~$0.01–0.05 per trace | No |

### Platform Selection Guide

**Choose Langfuse if**:
- You want open-source-first with data sovereignty (self-hosting)
- You're building multi-agent systems with complex reasoning chains
- You want transparent, unit-based pricing (pay per trace, not per user)
- You need evals framework built-in
- Cost is a concern: free tier is generous (50K events/month)

**Choose LangSmith if**:
- Your entire stack is LangChain/LangGraph (tight integration)
- You want a managed SaaS with zero ops overhead
- You're already paying for Langchain (includes free credits)
- You need official support from the framework creators

**Choose Datadog if**:
- You have existing Datadog infrastructure (correlation with infra metrics)
- You need unified monitoring (agents + servers + databases)
- Your organization requires enterprise SLAs and compliance
- Budget is not a constraint

**Choose Elastic if**:
- You already use Elastic for logs/APM
- You want to correlate agent traces with infrastructure logs
- You prefer on-premise deployments

**Choose Grafana if**:
- You want to self-host Tempo (no licensing costs)
- You're comfortable building custom dashboards
- You have the ops resources for self-hosted infrastructure

**Choose VictoriaMetrics if**:
- Your focus is cost tracking and metrics (not detailed traces)
- You want open-source with high-scale metrics processing
- You need to minimize trace storage costs

**Choose Phoenix/Arize if**:
- You need built-in LLM evaluators and quality metrics
- You're willing to pay for specialized AI observability
- Your primary concern is output quality, not cost optimization

---

## Implementation Guide: Instrumenting Your Agents

### Python: Auto-Instrumentation (Zero-Code)

The simplest path: auto-instrumentation captures OTel spans without code changes.

**Step 1: Install packages**
```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp opentelemetry-instrumentation-crewai opentelemetry-instrumentation-openai
```

**Step 2: Bootstrap instrumentation**
```bash
opentelemetry-bootstrap -a install
```

**Step 3: Run with auto-instrumentation**
```bash
opentelemetry-instrument \
  --exporter otlp \
  --exporter_otlp_endpoint http://localhost:4317 \
  python your_agent.py
```

This automatically instruments CrewAI, OpenAI, anthropic, LangChain, and 100+ other libraries. No code changes needed.

**Limitations of auto-instrumentation**:
- Doesn't capture custom business logic (agent reasoning step names)
- May miss framework-specific attributes
- Can miss tool results if tools are custom code
- Overhead: typically <5% latency impact

### Python: Manual Instrumentation (Full Control)

When you need to capture agent-specific details, use manual spans.

**CrewAI Example** (with OpenTelemetry)

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from crewai import Agent, Task, Crew
import anthropic

# Set up OTel exporter
otlp_exporter = OTLPSpanExporter(
    endpoint="http://localhost:4317",
    insecure=True
)
trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)
tracer = trace.get_tracer(__name__)

# Define agents with OTel spans
researcher = Agent(
    role="Researcher",
    goal="Research a topic deeply",
    tools=[search_tool, retrieval_tool],
    llm=anthropic.Anthropic()
)

# Wrap crew execution in a span
def run_research_task(topic: str):
    with tracer.start_as_current_span("research_task") as span:
        span.set_attribute("gen_ai.agent.name", "researcher")
        span.set_attribute("task.topic", topic)

        # This creates child spans automatically for each agent step
        crew = Crew(agents=[researcher], tasks=[task])
        result = crew.kickoff(inputs={"topic": topic})

        # Add custom attributes
        span.set_attribute("result.length", len(result))

    return result
```

**LangGraph Example** (with OpenTelemetry)

```python
from opentelemetry import trace
from langgraph.graph import StateGraph
from anthropic import Anthropic

tracer = trace.get_tracer(__name__)

def planning_node(state):
    with tracer.start_as_current_span("planning_step") as span:
        span.set_attribute("gen_ai.agent.action", "plan")
        span.set_attribute("gen_ai.agent.step_number", state["step_count"])

        client = Anthropic()
        response = client.messages.create(
            model="claude-3-opus-20250219",
            max_tokens=1024,
            messages=[{"role": "user", "content": state["query"]}]
        )

        # OTel automatically captures the model call in a child span
        span.set_attribute("gen_ai.usage.output_tokens", response.usage.output_tokens)

        return {
            "plan": response.content[0].text,
            "step_count": state["step_count"] + 1
        }

def execution_node(state):
    with tracer.start_as_current_span("execution_step") as span:
        span.set_attribute("gen_ai.agent.action", "execute")

        # Tool invocation (wrapped in its own span)
        with tracer.start_as_current_span("tool_call") as tool_span:
            tool_span.set_attribute("gen_ai.tool.name", "search")
            tool_span.set_attribute("gen_ai.tool.input", state["plan"])

            result = search_tool(state["plan"])

            tool_span.set_attribute("gen_ai.tool.output", result)
            tool_span.set_attribute("tool.status", "success")

        return {"execution_result": result}

# Build graph
graph = StateGraph(state_schema)
graph.add_node("plan", planning_node)
graph.add_node("execute", execution_node)
graph.add_edge("plan", "execute")
graph.set_entry_point("plan")
compiled = graph.compile()

# Run with traces
with tracer.start_as_current_span("agent_execution") as root_span:
    root_span.set_attribute("gen_ai.agent.name", "langgraph_agent")
    compiled.invoke({"query": "find recent AI research", "step_count": 0})
```

**Claude Agent SDK Example**

```python
from opentelemetry import trace
from anthropic import Anthropic

tracer = trace.get_tracer(__name__)

def run_agent():
    client = Anthropic()

    with tracer.start_as_current_span("agent_loop") as root:
        root.set_attribute("gen_ai.agent.name", "claude_research_agent")

        messages = [{"role": "user", "content": "Research AI observability trends"}]

        while True:
            with tracer.start_as_current_span("model_invocation") as span:
                response = client.messages.create(
                    model="claude-3-opus-20250219",
                    max_tokens=4096,
                    tools=[
                        {
                            "name": "search",
                            "description": "Search for information",
                            "input_schema": {
                                "type": "object",
                                "properties": {
                                    "query": {"type": "string"}
                                }
                            }
                        }
                    ],
                    messages=messages
                )

                # Capture tokens and stop reason
                span.set_attribute("gen_ai.usage.input_tokens", response.usage.input_tokens)
                span.set_attribute("gen_ai.usage.output_tokens", response.usage.output_tokens)
                span.set_attribute("gen_ai.response.stop_reason", response.stop_reason)

            # Process tool use
            tool_uses = [block for block in response.content if block.type == "tool_use"]
            if not tool_uses:
                break

            for tool_use in tool_uses:
                with tracer.start_as_current_span("tool_call") as tool_span:
                    tool_span.set_attribute("gen_ai.tool.name", tool_use.name)
                    tool_span.set_attribute("gen_ai.tool.input", str(tool_use.input))

                    # Execute tool
                    if tool_use.name == "search":
                        result = search(tool_use.input["query"])

                    tool_span.set_attribute("gen_ai.tool.output", result)

            # Continue loop
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user", "content": [
                {"type": "tool_result", "tool_use_id": tu.id, "content": result}
                for tu, result in zip(tool_uses, results)
            ]})
```

### TypeScript/JavaScript Auto-Instrumentation

```bash
npm install @opentelemetry/auto @opentelemetry/sdk-node @opentelemetry/auto @opentelemetry/exporter-trace-otlp-http
```

```typescript
// instrumentation.ts (must be first import in your app)
import { NodeTracerProvider } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";

const tracerProvider = new NodeTracerProvider();
const otlpExporter = new OTLPTraceExporter({
  url: "http://localhost:4318/v1/traces",
});

tracerProvider.addSpanProcessor(
  new BatchSpanProcessor(otlpExporter)
);

tracerProvider.register();
```

```bash
# Run with auto-instrumentation
NODE_OPTIONS="--require ./instrumentation.ts" node app.ts
```

### TypeScript: Manual Instrumentation

```typescript
import { trace } from "@opentelemetry/api";
import Anthropic from "@anthropic-ai/sdk";

const tracer = trace.getTracer("agent-app");

async function runAgent() {
  const client = new Anthropic();

  return tracer.startActiveSpan("agent_execution", async (span) => {
    span.setAttributes({
      "gen_ai.agent.name": "ts_agent",
      "gen_ai.agent.action": "execute"
    });

    const response = await client.messages.create({
      model: "claude-3-opus-20250219",
      max_tokens: 2048,
      messages: [
        {
          role: "user",
          content: "Analyze recent agent observability patterns"
        }
      ]
    });

    // OTel SDK automatically captures this in a child span

    return response;
  });
}
```

### What Gets Captured Automatically

With OTel instrumentation enabled:

**For LLM calls**:
- Model name, version
- Input/output tokens
- Latency (time to first token, total duration)
- Stop reason (max_tokens, end_turn, tool_use)
- Temperature, max_tokens, top_p parameters
- Provider (OpenAI, Anthropic, Azure, etc.)

**For tool calls**:
- Tool name
- Input parameters
- Output/result
- Execution time
- Error if it failed

**For agent steps**:
- Agent name
- Decision made (plan, act, observe)
- Step number
- Tokens used in reasoning

**NOT captured automatically** (requires manual spans):
- Business logic (task name, user ID, domain-specific context)
- Quality metrics (hallucination score, tool success)
- Custom attributes for your domain

---

## Cost Tracking: Token Spend Per Agent, Task, User

Token costs vary dramatically across agents, tasks, and users. Without tracking, cost surprises hit production.

### Cost Calculation Pattern

OTel gives you the building blocks; your backend (or custom code) calculates costs.

**Per-token cost by model**:
```python
MODEL_COSTS = {
    "claude-3-opus-20250219": {"input": 0.015, "output": 0.075},  # per 1K tokens
    "gpt-4-turbo": {"input": 0.01, "output": 0.03},
    "gpt-4o": {"input": 0.005, "output": 0.015},
}

def calculate_span_cost(span):
    model = span.attributes.get("gen_ai.request.model")
    input_tokens = span.attributes.get("gen_ai.usage.input_tokens", 0)
    output_tokens = span.attributes.get("gen_ai.usage.output_tokens", 0)

    costs = MODEL_COSTS.get(model, {})
    input_cost = (input_tokens / 1000) * costs.get("input", 0)
    output_cost = (output_tokens / 1000) * costs.get("output", 0)

    return input_cost + output_cost
```

### Aggregating Costs with OTel Metrics

Define custom metrics to track cost:

```python
from opentelemetry import metrics

meter = metrics.get_meter(__name__)

# Cumulative cost counter
cost_counter = meter.create_counter(
    name="gen_ai.cost.total",
    description="Total cost in USD",
    unit="1"  # USD
)

# Histogram of cost per request
cost_histogram = meter.create_histogram(
    name="gen_ai.cost.per_request",
    description="Cost distribution per request",
    unit="1"
)

# In your agent code
cost = calculate_span_cost(span)
cost_counter.add(cost, {"agent": "researcher", "model": "claude-opus"})
cost_histogram.record(cost, {"task": "research"})
```

### Cost Alerting Patterns

Your backend (Langfuse, Datadog, etc.) watches these metrics:

```yaml
# Alert if daily spend exceeds budget
- name: daily_spend_exceeded
  metric: gen_ai.cost.total
  aggregation: sum
  over: 24h
  threshold: 100  # $100 per day
  severity: critical

# Alert if single request costs >$5
- name: expensive_request
  metric: gen_ai.cost.per_request
  aggregation: max
  threshold: 5
  severity: warning

# Alert if cost per token increases (quality degradation)
- name: cost_per_token_drift
  metric: gen_ai.cost.per_request / gen_ai.usage.total_tokens
  threshold_increase: 20%
  over: 7d
  severity: warning
```

### Cost Breakdown by Dimension

OTel attributes enable cost slicing:

```python
# Log cost with dimensional attributes
cost_counter.add(
    span_cost,
    attributes={
        "agent": span.attributes.get("gen_ai.agent.name"),
        "model": span.attributes.get("gen_ai.request.model"),
        "user": span.attributes.get("user.id"),
        "task": span.attributes.get("task.type"),
        "tool": span.attributes.get("gen_ai.tool.name") or "model_only",
        "status": span.attributes.get("status.code"),
    }
)
```

Then query by dimension:
- **By agent**: Which agents are most expensive?
- **By user**: Are power users driving costs?
- **By model**: Should we switch to a cheaper model?
- **By tool**: Are external APIs expensive?
- **By day**: Is cost trending up or down?

### Typical Cost Ranges

For context (Q1 2026 pricing):
- **Simple query**: Claude 3.5 Sonnet, 1 model call, 100 input + 200 output tokens ≈ $0.002
- **Research task**: Claude 3 Opus, 5 tool calls + 3 model invocations, 5K tokens input ≈ $0.05
- **Complex reasoning**: Multiple agents, 10+ tool calls, 100K tokens ≈ $2.00
- **RAG pipeline**: 10 retrievals + analysis, 50K tokens ≈ $0.50

If you're paying $10/day without cost tracking, you likely have 5-10 expensive requests eating the budget.

---

## Quality Monitoring: Hallucination, Task Completion, User Feedback

Token metrics and cost are operational (you want low cost). Quality metrics are business metrics (you want high quality).

### Hallucination Detection

**Strategy 1: LLM-as-Judge** (most practical)
- Send the model's output + the retrieval context to a hallucination detector
- Detector returns True/False and confidence score
- Capture in a span event

```python
def check_hallucination(output: str, context: str) -> bool:
    with tracer.start_as_current_span("hallucination_check") as span:
        detector_response = anthropic.messages.create(
            model="claude-3-5-sonnet-20241022",  # Use fast model for evaluation
            max_tokens=10,
            messages=[{
                "role": "user",
                "content": f"""Is this claim consistent with the provided context?

Claim: {output}

Context: {context}

Answer with just 'yes' or 'no'."""
            }]
        )

        is_hallucination = "no" in detector_response.content[0].text.lower()

        span.set_attribute("hallucination.detected", is_hallucination)
        span.set_attribute("hallucination.confidence", 0.95)  # From detector confidence

        return is_hallucination

# In agent evaluation
with tracer.start_as_current_span("post_execution_evaluation") as eval_span:
    is_hallucination = check_hallucination(agent_output, retrieval_context)

    eval_span.add_event(
        "hallucination_evaluation_complete",
        attributes={
            "hallucination_detected": is_hallucination,
            "detector_model": "claude-3-5-sonnet"
        }
    )
```

**Strategy 2: Semantic Entropy** (for complex answers)
- Sample multiple completions (n=5)
- Compute embedding of each
- Calculate variance in embeddings
- High variance = model is uncertain = likely hallucinating

```python
from sklearn.metrics.pairwise import cosine_distances
import numpy as np

def semantic_entropy(prompt: str, n_samples: int = 5) -> float:
    """
    Returns entropy of model outputs.
    High entropy (>0.7) indicates uncertainty/hallucination risk.
    """
    responses = [
        client.messages.create(
            model="claude-3-opus-20250219",
            max_tokens=500,
            messages=[{"role": "user", "content": prompt}]
        ).content[0].text
        for _ in range(n_samples)
    ]

    # Get embeddings
    embeddings = [get_embedding(r) for r in responses]
    embeddings = np.array(embeddings)

    # Compute pairwise similarity
    distances = cosine_distances(embeddings)
    similarities = 1 - distances

    # Entropy: average dissimilarity
    entropy = np.mean(distances[np.triu_indices_from(distances, k=1)])

    return entropy

# Track as metric
entropy_value = semantic_entropy(prompt)
entropy_histogram.record(
    entropy_value,
    attributes={"agent": "researcher", "hallucination_risk": "high" if entropy_value > 0.7 else "low"}
)
```

### Task Completion Metrics

Not all tasks have a single clear right answer. Define success operationally:

```python
@dataclass
class TaskOutcome:
    completed: bool          # Did agent finish?
    success: bool            # Did output meet requirements?
    confidence: float        # Agent's own confidence (0-1)
    retries: int            # How many attempts?
    total_cost: float       # Actual spend

def evaluate_task_completion(agent_outcome, requirements) -> TaskOutcome:
    with tracer.start_as_current_span("task_evaluation") as span:

        # Check 1: Did it complete?
        completed = agent_outcome.status == "completed"

        # Check 2: Does output meet requirements?
        success = False
        if "research" in requirements:
            success = len(agent_outcome.sources) > 3
        elif "analysis" in requirements:
            success = contains_key_insights(agent_outcome.output)

        # Check 3: Confidence signal from agent
        confidence = extract_confidence(agent_outcome)

        outcome = TaskOutcome(
            completed=completed,
            success=success,
            confidence=confidence,
            retries=agent_outcome.retry_count,
            total_cost=sum_cost_from_spans()
        )

        # Log as span attributes
        span.set_attributes({
            "task.completed": completed,
            "task.success": success,
            "task.confidence": confidence,
            "task.retries": agent_outcome.retry_count,
            "task.cost": outcome.total_cost,
        })

        return outcome

# Track completion rate as metric
success_counter.add(
    1 if outcome.success else 0,
    attributes={"task_type": "research"}
)

# Track cost per successful task
if outcome.success:
    cost_per_success.record(
        outcome.total_cost,
        attributes={"task_type": "research"}
    )
```

### User Feedback as Observability Signal

Non-deterministic systems require feedback loops. Capture user ratings:

```python
def submit_user_feedback(task_id: str, rating: int, comment: str = ""):
    """
    User rates agent output 1-5 stars.
    This becomes a quality signal linked to the original trace.
    """
    with tracer.start_as_current_span("user_feedback") as span:
        span.set_attributes({
            "feedback.rating": rating,
            "feedback.comment": comment,  # Truncate/redact if needed
            "trace_id": get_current_trace_id(),
        })

    # Store in backend linked to original span
    backend.record_feedback(
        trace_id=task_id,
        rating=rating,
        comment=comment,
        timestamp=now()
    )

# Metric: percentage of highly-rated responses
def track_quality():
    high_rating_ratio = count_ratings(>=4) / total_ratings
    quality_ratio.record(high_rating_ratio)

    # Alert if quality drops
    if high_rating_ratio < 0.80:
        alert("Quality degradation detected")
```

### Dashboard: Quality Over Time

Essential queries for your backend:

```sql
-- 1. Hallucination rate (last 7 days)
SELECT
  DATE(timestamp),
  agent,
  COUNT(*) as total_calls,
  COUNTIF(hallucination_detected) as hallucinations,
  COUNTIF(hallucination_detected) / COUNT(*) as hallucination_rate
FROM spans
WHERE timestamp > NOW() - INTERVAL 7 DAY
  AND span_type = 'agent_execution'
GROUP BY DATE(timestamp), agent;

-- 2. Task completion rate by agent
SELECT
  agent,
  COUNTIF(task_success) / COUNT(*) as success_rate,
  AVG(total_cost) as avg_cost,
  MAX(total_cost) as max_cost
FROM spans
WHERE span_type = 'agent_execution'
  AND timestamp > NOW() - INTERVAL 7 DAY
GROUP BY agent;

-- 3. User satisfaction trend
SELECT
  DATE(timestamp),
  AVG(feedback_rating) as avg_rating,
  COUNTIF(feedback_rating >= 4) / COUNT(*) as satisfaction_rate
FROM user_feedback
WHERE timestamp > NOW() - INTERVAL 30 DAY
GROUP BY DATE(timestamp);

-- 4. Quality vs cost trade-off
SELECT
  agent,
  AVG(total_cost) as avg_cost,
  COUNTIF(hallucination_detected) as hallucinations,
  COUNTIF(task_success) as successes
FROM spans
WHERE timestamp > NOW() - INTERVAL 7 DAY
GROUP BY agent;
```

---

## Distributed Tracing for Multi-Agent Systems

When multiple agents collaborate—orchestrator → planner → executor → feedback agent—distributed tracing shows the full picture.

### Trace Propagation: W3C Trace Context

Each span carries metadata in HTTP headers:

```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
tracestate: vendor_specific_data
```

Your agents extract and propagate these headers:

```python
def agent_to_agent_call(agent_name: str, request_data: dict):
    """
    Call another agent as a service.
    Propagate W3C trace context.
    """
    # Get current trace context
    ctx = trace.get_current_span().get_span_context()

    # Inject into HTTP headers
    headers = {}
    W3CFormat().inject(ctx, headers)

    # Call remote agent with trace context
    response = requests.post(
        f"http://agent-service/{agent_name}",
        json=request_data,
        headers=headers
    )

    return response.json()

# On the receiving agent:
def agent_handler(request):
    # Extract trace context from headers
    ctx = W3CFormat().extract(request.headers)
    with trace.use_span(ctx) as span:
        # All spans in this handler are children of the client span
        agent_logic()
```

### Multi-Agent Trace Example

```
Trace ID: abc-123 (customer request)
  Span: orchestrator_start
    Span: decide_plan (model call)
    Span: call_planner_agent (HTTP)
      Span: planner_reasoning (remote)
        Span: planner_model_1
        Span: planner_model_2
    Span: call_executor_agent (HTTP)
      Span: executor_reasoning (remote)
        Span: executor_tool_1 (search)
        Span: executor_tool_2 (database)
        Span: executor_model_1
    Span: aggregate_results
    Span: call_feedback_agent (HTTP)
      Span: feedback_reasoning (remote)
        Span: quality_check
```

All spans share Trace ID `abc-123`. Parent span IDs link the hierarchy. Your backend correlates all of them into a single causal chain.

### Implementation: AG2 Framework

AG2 (formerly AutoGen) has built-in OTel support:

```python
from ag2 import Agent
import os

# Enable OTel tracing
os.environ["OTEL_ENABLED"] = "true"
os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"] = "http://localhost:4317"

# Define agents
planner = Agent(
    name="planner",
    system_message="You create detailed plans...",
    llm_config={"model": "gpt-4"}
)

executor = Agent(
    name="executor",
    system_message="You execute plans with tools...",
    llm_config={"model": "gpt-4"}
)

feedback = Agent(
    name="feedback",
    system_message="You evaluate results and give feedback...",
    llm_config={"model": "gpt-4"}
)

# AG2 automatically traces agent-to-agent communication
# with W3C Trace Context propagation
user = Agent(name="user", human_input_mode="NEVER")

def solve_task(task: str):
    user.initiate_chat(
        planner,
        message=task,
        summary_method="reflection_with_llm",
        max_consecutive_auto_reply=3
    )
```

AG2 emits OTel spans for:
- Each agent turn
- Each model call
- Each tool invocation
- Inter-agent communication (with trace context)

### Cost Attribution Across Agents

```python
def get_cost_by_agent(trace_id: str) -> dict:
    """
    Break down trace costs by which agent incurred them.
    """
    spans = backend.get_spans(trace_id)

    costs_by_agent = {}
    for span in spans:
        agent = span.attributes.get("gen_ai.agent.name", "unknown")
        cost = calculate_span_cost(span)

        costs_by_agent[agent] = costs_by_agent.get(agent, 0) + cost

    return costs_by_agent

# Example output:
# {
#   "orchestrator": 0.002,
#   "planner": 0.015,
#   "executor": 0.045,
#   "feedback": 0.008,
#   "total": 0.070
# }
```

This reveals which agents are cost bottlenecks.

---

## Alerting and Dashboards

### What to Monitor

**Operational Metrics** (watch continuously):
- Token count per request (P50, P95, P99)
- Cost per request
- Model API response time
- Tool success rate (>95%)
- Error rate

**Quality Metrics** (watch to catch degradation):
- Hallucination rate (target <5%)
- Task completion rate (target >90%)
- User satisfaction (average rating, target >4.0/5.0)
- Timeout rate (agent exceeds time limit)

**Cost Metrics** (watch for runaway costs):
- Daily spend (compare to budget)
- Cost per successful task
- Cost per user
- Cost trending (week-over-week delta)

### SLOs for Non-Deterministic Systems

Traditional SLOs (99.9% uptime) don't make sense for agents. Reframe:

```yaml
SLO_DEFINITIONS:

  # Quality SLO
  - name: task_completion_rate
    indicator: tasks_completed_successfully / total_tasks
    target: 0.90  # 90%
    window: 7d
    error_budget: 10%

  # Cost SLO
  - name: cost_per_task
    indicator: avg(cost_per_successful_task)
    target: 0.50  # $0.50 per task
    window: 7d
    error_budget: 20%  # Allows $0.60/task

  # Speed SLO
  - name: task_latency_p99
    indicator: latency_p99
    target: 30s  # 30 seconds
    window: 7d
    error_budget: 10%

  # Hallucination SLO
  - name: hallucination_rate
    indicator: hallucinations / total_outputs
    target: 0.05  # 5% max
    window: 7d
    error_budget: 1%  # Alert if >5.05%
```

Error budgets work differently with agents:
- You want to **spend** your quality error budget on edge cases (complex, ambiguous tasks)
- You want to **preserve** your cost budget for reliability
- Speed budget is less critical than accuracy

### Alert Examples

```yaml
ALERTS:

  - name: hallucination_rate_spike
    condition: hallucination_rate > 0.08  # Spike above SLO
    duration: 5m
    severity: critical
    action: page_on_call

  - name: daily_cost_threshold
    condition: sum(cost) over 24h > 100  # $100/day budget
    duration: 30m
    severity: warning
    action: slack_notification

  - name: task_success_degradation
    condition: success_rate < 0.80  # Below SLO
    duration: 10m
    severity: critical
    action: page_on_call + rollback_check

  - name: expensive_request
    condition: cost_per_request > 5  # Single request >$5
    duration: 1m
    severity: warning
    action: log_for_review

  - name: tool_failure_increase
    condition: tool_failure_rate > 0.10
    duration: 5m
    severity: warning
    action: slack_notification
```

### Dashboard Queries

**Cost Dashboard**:
```
- Today's spend vs. budget (bar chart)
- Cost per agent (pie chart)
- Cost trend over 30 days (line)
- Cost per successful task (histogram)
- Most expensive requests (table)
```

**Quality Dashboard**:
```
- Hallucination rate over time (line)
- Task success rate by agent (bar)
- User satisfaction trend (line)
- Timeout rate (line)
- Common failure modes (table)
```

**Operational Dashboard**:
```
- Token count distribution (histogram)
- API latency by model (bar)
- Tool success rate (gauge)
- Active agents (gauge)
- Recent errors (log stream)
```

---

## Platform Comparison: Detailed Feature Matrix

| Feature | Langfuse | LangSmith | Datadog | Elastic | Phoenix | VictoriaMetrics |
|---|---|---|---|---|---|---|
| **Core Tracing** | ✅ Native OTel | ✅ Native OTel | ✅ Native OTel | ✅ Native OTel | ✅ Native OTel | ✅ Metrics only |
| **LLM-specific spans** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | N/A |
| **Agent spans** | ✅ Yes | ✅ LangGraph native | ⚠️ Limited | ⚠️ Limited | ✅ Yes | N/A |
| **Auto-instrumentation** | ✅ SDK + custom | ✅ LangChain/LangGraph | ✅ SDK | ✅ SDK | ✅ SDK | N/A |
| **Token tracking** | ✅ Built-in | ✅ Built-in | ✅ Built-in | ✅ Custom | ✅ Built-in | ✅ Built-in |
| **Cost calculation** | ✅ Auto | ✅ Auto | ⚠️ Custom | ⚠️ Custom | ✅ Auto | ✅ Custom |
| **Cost alerting** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Via API | ✅ Yes |
| **Evals framework** | ✅ Built-in | ✅ Built-in | ❌ No | ❌ No | ✅ Built-in | ❌ No |
| **Hallucination detection** | ✅ Via evals | ✅ Via LangSmith evals | ⚠️ 3rd party | ❌ No | ✅ Built-in | ❌ No |
| **User feedback** | ✅ Yes | ✅ Yes | ⚠️ Via APM | ⚠️ Via logs | ✅ Yes | ❌ No |
| **Prompt management** | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |
| **Analytics/Dashboards** | ✅ Built-in | ✅ Built-in | ✅ Custom | ✅ Custom | ✅ Built-in | ⚠️ DIY |
| **Data export** | ✅ API + bulk | ✅ API | ✅ API | ✅ API | ✅ API | ✅ API |
| **PII redaction** | ✅ SDK + collector | ✅ Via SDK | ✅ Via collector | ✅ Via collector | ✅ SDK | N/A |
| **Self-hosting** | ✅ MIT (Docker) | ❌ Enterprise only | ❌ No | ⚠️ On-prem option | ❌ No | ✅ Yes |
| **Data sovereignty** | ✅ Full | ⚠️ SaaS only | ❌ SaaS | ⚠️ Option | ❌ SaaS | ✅ Full |
| **Free tier** | ✅ 50K events/mo | ✅ 5K traces/mo | ❌ Enterprise pricing | ❌ Free tier | ❌ No | ✅ Open-source |
| **Pricing model** | Unit-based | Per-trace | Ingestion-based | Data volume | Per-request | Self-hosted |
| **Setup complexity** | Low | Very low | Medium | High | Low | High |
| **Community strength** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## Production Patterns: Sampling, Redaction, Cost Optimization

### Sampling Strategies

Not all traces are equally valuable. Sample intelligently:

**Head Sampling** (decide at SDK level):
```python
from opentelemetry.sdk.trace.sampler import TraceIdRatioBased

# Sample 5% of normal traffic, 100% of errors
class CustomSampler(Sampler):
    def should_sample(self, trace_id, span_name, attributes):
        # Always sample errors
        if attributes.get("error", False):
            return True

        # Always sample high-cost requests
        if attributes.get("gen_ai.usage.output_tokens", 0) > 5000:
            return True

        # Sample 5% of normal traffic
        return random.random() < 0.05

tracer_provider = TracerProvider(sampler=CustomSampler())
```

**Tail Sampling** (decide at collector level):
```yaml
processors:
  tail_sampling:
    policies:
      # Keep all errors
      - name: error_traces
        error_status_policy:
          status_code: ERROR

      # Keep all expensive requests (>$1)
      - name: expensive_requests
        attribute_processor:
          action: keep
          attribute_key: "gen_ai.cost.total"
          numeric_value: 1

      # Keep 10% of normal traffic
      - name: probabilistic
        probabilistic_sampler:
          sampling_percentage: 10
```

**Cost Impact**: Sampling reduces egress costs, but loses visibility into sampled traces.
- Without sampling: 100% of traces, 100% cost, 100% visibility
- With sampling: 10% of traces, 10% cost, but **no visibility into 90% of requests**

**Recommendation**: Use tail sampling with error + expensive request policies. Keep only 5-10% of normal traffic.

### PII Redaction in Traces

Prompts and completions often contain user data. Redact before sending to backend:

**Option 1: Redaction Processor (Collector)**
```yaml
processors:
  redaction:
    allow_all_keys: false
    blocked_values:
      # Email addresses
      - "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
      # Phone numbers
      - "\\b\\d{3}-\\d{3}-\\d{4}\\b"
      # Social security numbers
      - "\\b\\d{3}-\\d{2}-\\d{4}\\b"
      # Credit card numbers
      - "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b"
    blocked_keys:
      - "credit_card"
      - "ssn"
      - "password"
      - "api_key"
      - "auth_token"
```

**Option 2: SDK-Level Redaction**
```python
import re

def redact_pii(text: str) -> str:
    """Remove common PII patterns."""
    patterns = {
        "email": r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
        "phone": r"\b\d{3}-\d{3}-\d{4}\b",
        "ssn": r"\b\d{3}-\d{2}-\d{4}\b",
        "cc": r"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b",
    }

    for name, pattern in patterns.items():
        text = re.sub(pattern, f"[{name.upper()}]", text)

    return text

# Before sending to backend
prompt_redacted = redact_pii(original_prompt)
span.set_attribute("gen_ai.prompt", prompt_redacted)
```

**Option 3: Semantic Redaction (Advanced)**
```python
# Hash sensitive values instead of removing
import hashlib

def redact_semantic(text: str) -> str:
    """Replace user names with hashes (preserves uniqueness)."""
    names = extract_entities(text)  # NER model

    for name in names:
        hashed = hashlib.sha256(name.encode()).hexdigest()[:8]
        text = text.replace(name, f"[USER_{hashed}]")

    return text
```

**Trade-off**: More redaction = safer but less debuggability. Balance based on your compliance needs.

### Trace Storage Costs

Traces are expensive at scale. Optimize storage:

**Data Tiering**:
```yaml
RETENTION_POLICY:
  hot_tier: 7 days      # Full fidelity, all attributes
  warm_tier: 30 days    # Metrics only, attributes dropped
  cold_tier: 90 days    # Aggregations only (cost/success/latency)
  delete: 1 year        # Compliance retention minimum
```

**Compression**:
```bash
# Raw traces: ~5KB per span
# With compression: ~500 bytes per span
# 1M spans/day: 5GB → 500MB
# Savings: 90% @ 0.10/GB = $0.50/day vs $5/day
```

**Cardinality Control**:
```yaml
# Problem: High-cardinality attributes blow up storage
# Example: user_id = {10M possible values}
#   → Each value creates separate time series
#   → Storage = O(cardinality)

# Solution: Reduce cardinality
- Drop: user_id (not useful for alerts)
- Hash: user_id → first_3_digits (preserves patterns, reduces cardinality)
- Group: user_segment = "heavy_user" | "casual_user" (5 values)
```

**Typical Monthly Costs** (1M agent executions):
- Langfuse Cloud: $0 (50K events free) + $0.002/event beyond = $1,950
- Self-hosted Langfuse: $100–500 (server costs)
- Datadog: $0.05/trace = $50K (prohibitive at scale)
- Elastic: $0.30–1/GB ingested = $50–200
- Self-hosted Tempo (Grafana): $200–500 (ops overhead)

**Recommendation**: Use self-hosted for >100K traces/month. Use SaaS for <100K.

---

## Anti-Patterns: What Not to Do

### 1. Over-Instrumentation

**Anti-pattern**: Capturing every variable, every decision, every intermediate result.

```python
# BAD: Too much data
with tracer.start_as_current_span("agent_reasoning"):
    span.set_attribute("reasoning_step_1", step1_result)
    span.set_attribute("reasoning_step_2", step2_result)
    span.set_attribute("reasoning_step_3", step3_result)
    # ... 50 attributes later
```

**Why it hurts**: Storage costs explode, queries become slow, noise drowns out signal.

**Do this instead**:
```python
# GOOD: Capture only actionable attributes
with tracer.start_as_current_span("agent_reasoning"):
    span.set_attribute("agent.name", "researcher")
    span.set_attribute("reasoning_depth", len(intermediate_results))
    span.set_attribute("confidence", confidence_score)
    # Summary events, not exhaustive details
    span.add_event("reasoning_complete", {
        "final_confidence": confidence_score
    })
```

### 2. Full Prompts in Production

**Anti-pattern**: Logging complete prompts and completions to traces.

```python
# BAD: Full prompt logged
span.set_attribute("gen_ai.prompt", """
You are a research agent. Your task is to find information about {user_query}.
You have access to: search engine, wikipedia, academic databases.
If you find contradictory information, use confidence scoring.
...
"""[200KB of instruction])
```

**Why it hurts**:
- Storage: 200KB × 1M requests = 200GB/month
- Costs: $20–100/month in storage alone
- Latency: Slow serialization
- Privacy: Customer data embedded in logs

**Do this instead**:
```python
# GOOD: Hash the prompt, store metadata only
prompt_hash = hashlib.sha256(prompt.encode()).hexdigest()
span.set_attribute("gen_ai.prompt_hash", prompt_hash)
span.set_attribute("gen_ai.prompt.length", len(prompt))
span.set_attribute("gen_ai.prompt.tokens_estimated", len(prompt) // 4)

# Store full prompt separately in a dedicated prompt store if needed
prompt_store.save(prompt_hash, prompt)  # Deduplicated by hash
```

### 3. Ignoring Cost Metrics

**Anti-pattern**: Tracking latency and errors, but not token costs.

```python
# BAD: No cost tracking
span.set_attribute("duration_ms", elapsed_time)
span.set_attribute("error", False)
# Where's the cost?
```

**Why it hurts**:
- You don't know if agents are running efficiently
- Cost anomalies go undetected until the bill arrives
- No way to optimize

**Do this instead**:
```python
# GOOD: Always track costs
span.set_attribute("gen_ai.usage.input_tokens", input_tokens)
span.set_attribute("gen_ai.usage.output_tokens", output_tokens)
span.set_attribute("gen_ai.cost.total", calculate_cost(model, input_tokens, output_tokens))

# Add cost alert
if calculated_cost > 5:  # Alert on expensive requests
    alert_spike(span_id, calculated_cost)
```

### 4. Sampling Without Strategy

**Anti-pattern**: Random sampling of all traces equally.

```python
# BAD: Sample 1% of everything
sampler = TraceIdRatioBased(0.01)
```

**Why it hurts**:
- You miss 99% of requests
- You lose visibility into edge cases
- Rare errors might not be sampled

**Do this instead**:
```python
# GOOD: Intelligent sampling
class SmartSampler(Sampler):
    def should_sample(self, trace_id, span_name, attributes):
        # Always sample errors
        if attributes.get("error"):
            return True

        # Always sample slow requests
        if attributes.get("duration_ms", 0) > 30000:
            return True

        # Always sample expensive requests
        if attributes.get("gen_ai.cost.total", 0) > 1:
            return True

        # Sample 5% of normal traffic
        return random.random() < 0.05
```

### 5. Alerting on Non-Deterministic Signals

**Anti-pattern**: Creating alerts on single-event spikes (which are normal for agents).

```python
# BAD: Alert on single request failure
alert_rule:
  condition: single_request_failed
  severity: critical
```

**Why it hurts**:
- Agents are non-deterministic; some failures are expected
- False alerts cause alert fatigue
- You miss real problems

**Do this instead**:
```yaml
# GOOD: Alert on trends, not events
alert_rule:
  condition: error_rate > 10%  # Over a window
  window: 5m
  threshold: 0.10
  severity: critical  # Only if it persists
```

### 6. Logging Secrets in Traces

**Anti-pattern**: API keys, auth tokens, credentials in span attributes.

```python
# BAD: Credentials in spans
span.set_attribute("api_key", os.environ["OPENAI_API_KEY"])
span.set_attribute("auth_token", user_token)
```

**Why it hurts**:
- Credential exposure in logs accessible to developers
- Trace backends may replicate data, spreading exposure
- Compliance violations

**Do this instead**:
```python
# GOOD: Never log credentials
# Use environment variables for secrets
# Use managed secrets (Vault, AWS Secrets Manager)
# Log only that an operation succeeded/failed, not how

span.set_attribute("auth.method", "oauth2")
span.set_attribute("auth.success", True)
# NOT: span.set_attribute("auth.token", token)
```

---

## Conclusion & Next Steps

Agent observability with OpenTelemetry is **mature and production-ready**. The semantic conventions are stable, auto-instrumentation is reliable, and multiple platforms support cost tracking and quality metrics.

### Quick Start Checklist

1. **Pick a framework** (CrewAI, LangGraph, Pydantic AI, Claude Agent SDK)
2. **Choose a platform** (Langfuse for flexibility, LangSmith for LangChain, Datadog for enterprise)
3. **Enable OTel auto-instrumentation** (`opentelemetry-instrument` or SDK setup)
4. **Start with token tracking** (capture input/output tokens, calculate cost)
5. **Add quality metrics** (hallucination detection, task completion)
6. **Set up alerts** (cost spikes, quality degradation)
7. **Monitor dashboards** (daily spend, success rate, hallucination rate)

### Sources & References

- [OpenTelemetry GenAI Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/)
- [OpenTelemetry GenAI Agent Spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/)
- [OpenTelemetry Auto-Instrumentation for Python](https://opentelemetry.io/docs/zero-code/python/)
- [Langfuse Documentation](https://langfuse.com/docs)
- [LangSmith OpenTelemetry Integration](https://blog.langchain.com/end-to-end-opentelemetry-langsmith/)
- [Datadog LLM Observability](https://www.datadoghq.com/blog/llm-otel-semantic-convention/)
- [AG2 OpenTelemetry Tracing](https://docs.ag2.ai/latest/docs/blog/2026/02/08/AG2-OpenTelemetry-Tracing/)
- [Elastic OpenTelemetry Integration](https://www.elastic.co/observability-labs/blog/elastic-opentelemetry-langchain-tracing/)
- [VictoriaMetrics AI Agents Observability](https://victoriametrics.com/blog/ai-agents-observability/)
- [OpenTelemetry Sampling](https://opentelemetry.io/docs/concepts/sampling/)
- [PII Redaction in OpenTelemetry](https://oneuptime.com/blog/post/2026-02-06-redact-sensitive-prompts-genai-opentelemetry-traces/view)
- [SigNoz Claude Agent Monitoring](https://signoz.io/docs/claude-agent-monitoring/)
- [Honeycomb Observability & SLOs for AI Agents](https://stytch.com/blog/agent-ready-ep6-honeycomb-observability-slos-ai-agent-workloads/)

---

**Status**: Ready for production use | **Last updated**: 2026-03-28
