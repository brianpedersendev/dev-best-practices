# Google A2A Protocol + MCP Convergence: A Practical Guide

**Date:** 2026-03-28
**Status:** Production-ready
**Version:** A2A v0.3.0

## Overview

The **Agent-to-Agent (A2A) Protocol** is an open standard for secure, stateful communication between AI agents across organizational boundaries. Released by Google in April 2025 and donated to the Linux Foundation, A2A complements the Model Context Protocol (MCP) to create a complete agent communication stack:

- **A2A**: Agent-to-agent collaboration (peer-to-peer, stateful, long-running tasks)
- **MCP**: Agent-to-tool integration (vertical, stateless, function calls)

Together, they enable multi-agent systems where agents discover capabilities, delegate tasks, access tools, and collaborate on complex workflows. This guide covers both protocols, their relationship, and how to implement them in production.

---

## Part 1: What Is A2A?

### Core Concept

A2A is a JSON-RPC 2.0-based protocol built on HTTP/gRPC that enables agents to:

1. **Discover each other** via Agent Cards (JSON metadata)
2. **Send and stream messages** with task lifecycle tracking
3. **Collaborate asynchronously** with state management and webhook notifications
4. **Verify authenticity** via signed Agent Cards and cryptographic trust

Unlike direct API calls or MCP tool calls, A2A treats agents as intelligent peers capable of reasoning, planning, and negotiation—not just function providers.

### A2A vs MCP at a Glance

| Aspect | A2A | MCP |
|--------|-----|-----|
| **Purpose** | Agent-to-agent collaboration | Agent-to-tool integration |
| **Direction** | Horizontal (peer-to-peer) | Vertical (agent → tools) |
| **State** | Stateful, long-running tasks | Stateless function calls |
| **Discovery** | Agent Cards (JSON) | Static tool definitions |
| **Transport** | HTTP/SSE, gRPC, JSON-RPC 2.0 | stdio, SSE, JSON-RPC 2.0 |
| **Authentication** | HTTP headers, OAuth2, mTLS, API keys | No built-in auth (host-managed) |
| **Task Lifecycle** | Tracked: pending → running → completed/failed | No task tracking |
| **Long-Running Tasks** | Yes (webhooks, streaming) | No |
| **Best For** | Cross-org agent orchestration | Single agent's tool access |

**Key distinction:** Use A2A when agents cross organizational boundaries or need complex reasoning together. Use MCP when a single agent needs tool access within a team's infrastructure.

### Why Both Protocols Exist

- **MCP** (Anthropic, 2024) emerged first to solve the "how does an agent access tools?" problem
- **A2A** (Google, 2025) solved "how do multiple agents collaborate?" when MCP-alone hit architectural limits
- They're not competing; they're complementary layers

---

## Part 2: A2A Architecture & Concepts

### Agent Card (Agent Metadata)

Every A2A-compliant agent publishes a JSON Agent Card at `/.well-known/agent-card.json`:

```json
{
  "name": "PaymentAgent",
  "description": "Processes payments and invoices",
  "version": "1.0.0",
  "serverUrl": "https://payments.example.com",
  "modalities": ["text"],
  "skills": [
    {
      "id": "process_payment",
      "name": "Process Payment",
      "description": "Process a payment via credit card or bank transfer",
      "inputSchema": {
        "type": "object",
        "properties": {
          "amount": { "type": "number" },
          "currency": { "type": "string" }
        }
      }
    }
  ],
  "authentication": {
    "type": "oauth2",
    "oauth2Endpoint": "https://payments.example.com/oauth/authorize"
  },
  "signatures": [
    {
      "keyId": "2025-03-28-v1",
      "algorithm": "RS256",
      "value": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  ]
}
```

**Agent Card contains:**
- Name, version, description
- Server endpoint URL
- Supported input modalities (text, image, audio, etc.)
- Skills and capabilities with input schemas
- Supported authentication methods
- Cryptographic signatures (optional, for trust)

**Discovery:** Clients fetch an agent's card directly or via a registry to understand what it can do and how to connect.

### Core Message Flow

#### Synchronous Request/Response (message/send)

```
Client Agent                    Server Agent
    |                               |
    |-- POST /a2a ----------------->|
    |   method: "message/send"       |
    |   params: {                    |
    |     message: "Process payment" |
    |   }                            |
    |                               |
    |<-- HTTP 200 -------------------|
    |    result: {                   |
    |      task: {...},             |
    |      status: "completed"       |
    |    }                           |
```

#### Streaming Response (message/stream with SSE)

```
Client Agent                    Server Agent
    |                               |
    |-- POST /a2a ----------------->|
    |   method: "message/stream"     |
    |                               |
    |<-- HTTP 200 + text/event-stream
    |    data: {...Task...}          |
    |    data: {...Update...}        |
    |    data: {...Artifact...}      |
    |    data: [...Final Result...]  |
```

#### Long-Running with Webhooks

```
Client Agent                    Server Agent
    |                               |
    |-- POST /a2a ----------------->|
    |   method: "message/send"       |
    |   pushNotificationConfig: {    |
    |     url: "https://client/webhook"
    |   }                            |
    |                               |
    |<-- HTTP 200 -------------------|
    |    taskId: "12345"             |
    |    status: "pending"           |
    |                               |
    |                    [hours later]
    |                               |
    |<-- POST /webhook <-------------|
    |    taskId: "12345"             |
    |    status: "completed"         |
    |    artifacts: [...]            |
```

### Task Lifecycle

A task progresses through states:

```
Created → Accepted → Running → (Updates)* → Completed/Failed/Canceled/Rejected
```

- **Created**: Task received, awaiting acceptance
- **Accepted**: Server acknowledged, about to execute
- **Running**: Actively processing
- **Completed**: Success with artifacts
- **Failed**: Error occurred
- **Canceled**: Client canceled
- **Rejected**: Server rejected execution

Each state transition is communicated via:
- Direct response (synchronous)
- Server-Sent Events (streaming)
- Webhook POST (async long-running)

### Message Format (JSON-RPC 2.0)

All A2A messages follow JSON-RPC 2.0:

```json
{
  "jsonrpc": "2.0",
  "id": "req-123",
  "method": "message/send",
  "params": {
    "message": {
      "role": "user",
      "parts": [
        {
          "kind": "text",
          "text": "Please process a $150 payment"
        }
      ]
    }
  }
}
```

**Response (success):**
```json
{
  "jsonrpc": "2.0",
  "id": "req-123",
  "result": {
    "taskId": "task-456",
    "contextId": "ctx-789",
    "status": "completed",
    "artifacts": [
      {
        "kind": "text",
        "text": "Payment processed. Invoice: #INV-001"
      }
    ]
  }
}
```

**Response (error with HTTP 200):**
```json
{
  "jsonrpc": "2.0",
  "id": "req-123",
  "error": {
    "code": -32052,
    "message": "Validation error - Invalid payment amount"
  }
}
```

**Critical detail:** A2A always returns HTTP 200 OK, even for errors. Errors are in the JSON-RPC `error` field, not the HTTP status code.

---

## Part 3: A2A + MCP Architecture

### The Complete Stack

```
┌─────────────────────────────────────────┐
│  User / External System                 │
└─────────────────────────────┬───────────┘
                              │
┌─────────────────────────────▼───────────┐
│  Orchestrator Agent                     │
│  (Claude, LangGraph, CrewAI, etc.)      │
├─────────────────────────────────────────┤
│  Agent-to-Agent (A2A)                   │
│  ├─ Discovers payment-processor agent   │
│  ├─ Discovers inventory agent           │
│  └─ Delegates tasks across org boundary │
└────────┬────────────┬────────────┬──────┘
         │            │            │
    ┌────▼──┐    ┌───▼──┐    ┌───▼──┐
    │Payment│    │Invent│    │Audit │
    │Agent  │    │ory   │    │Agent │
    │(A2A)  │    │(A2A) │    │(A2A) │
    └────┬──┘    └───┬──┘    └───┬──┘
         │            │           │
    ┌────▼──────────────────┐    │
    │  MCP (Tool Layer)     │    │
    ├────────────────────────┤    │
    │ • Stripe API          │    │
    │ • Database queries     │    │
    │ • Email service        │    │
    │ • Inventory DB         │    │
    └─────────────────────────    │
                                 │
                          ┌──────▼──┐
                          │External  │
                          │Ledger    │
                          └──────────┘
```

**Flow example:**
1. **User** asks: "Process a $150 payment and log it"
2. **Orchestrator (A2A client)** fetches Agent Cards for payment & audit agents
3. **Orchestrator** delegates to **PaymentAgent** via A2A → message/send
4. **PaymentAgent** uses **MCP** to call Stripe API
5. **PaymentAgent** streams progress back via A2A
6. **Orchestrator** delegates to **AuditAgent** via A2A
7. **AuditAgent** uses **MCP** to write to ledger DB
8. Results aggregated and returned to user

### When to Use Each Layer

| Scenario | Protocol | Reason |
|----------|----------|--------|
| Single agent needs to call an API | MCP | Direct tool access, no delegation |
| Multiple agents, same team, same infra | Direct function calls or message queue | Lower latency, no discovery overhead |
| Agent needs to delegate to cross-org agent | A2A | Trust boundaries, agent autonomy, dynamic discovery |
| Agent streaming real-time results | A2A (SSE) | Built-in support, task tracking |
| Task taking days, client may disconnect | A2A (webhooks) | Durable state, async updates |

---

## Part 4: Protocol Details

### Authentication & Security

A2A agents declare supported auth in their Agent Card:

```json
"authentication": [
  {
    "type": "oauth2",
    "oauth2Endpoint": "https://agent.example.com/oauth/authorize",
    "scopes": ["payment:process", "payment:read"]
  },
  {
    "type": "apiKey",
    "apiKeyHeader": "X-API-Key"
  },
  {
    "type": "mtls"
  }
]
```

**Implementation:**
- Client reads the card
- Client selects auth method and obtains credentials
- Client includes credentials in HTTP headers of each A2A request

```
POST /a2a HTTP/1.1
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...
X-API-Key: sk-abc123
Content-Type: application/json

{ "jsonrpc": "2.0", ... }
```

### Agent Card Signing (JWT)

A2A v0.3+ supports signing Agent Cards with JWT to prevent tampering:

```json
{
  "name": "PaymentAgent",
  "version": "1.0.0",
  ...,
  "signatures": [
    {
      "keyId": "2025-03-28-v1",
      "algorithm": "RS256",
      "value": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiUGF5bWVudEFnZW50In0.signature..."
    }
  ]
}
```

**Verification:**
1. Extract the signature's algorithm and keyId
2. Fetch the public key from the agent's key server
3. Verify the JWT signature
4. Confirm card hasn't been tampered with

### gRPC Support (v0.3+)

A2A agents may optionally expose a gRPC endpoint:

```protobuf
service A2AService {
  rpc SendTask(TaskRequest) returns (stream TaskResponse);
  rpc GetTask(GetTaskRequest) returns (Task);
  rpc CancelTask(CancelTaskRequest) returns (Empty);
}
```

**Benefits:**
- Binary serialization (smaller payloads)
- Multiplexed streams (HTTP/2)
- Bidirectional streaming
- Better for high-volume agent clusters

**Common approach:** Support both JSON-RPC over HTTP/SSE and gRPC depending on client preference.

### Streaming with Server-Sent Events (SSE)

For real-time updates, clients use `message/stream`:

```bash
curl -X POST https://agent.example.com/a2a \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer token" \
  -d '{
    "jsonrpc": "2.0",
    "id": "req-123",
    "method": "message/stream",
    "params": { "message": {...} }
  }'
```

Server responds with SSE:

```
HTTP/1.1 200 OK
Content-Type: text/event-stream
Connection: keep-alive

data: {"jsonrpc":"2.0","id":"req-123","result":{"taskId":"task-456","status":"created"}}

data: {"jsonrpc":"2.0","id":"req-123","result":{"status":"running","progress":0.33}}

data: {"jsonrpc":"2.0","id":"req-123","result":{"status":"running","progress":0.66}}

data: {"jsonrpc":"2.0","id":"req-123","result":{"status":"completed","artifacts":[{"kind":"text","text":"Done"}]}}
```

### Webhook Callbacks for Long-Running Tasks

For tasks that last hours or days:

```json
{
  "jsonrpc": "2.0",
  "method": "message/send",
  "params": {
    "message": { ... },
    "pushNotificationConfig": {
      "url": "https://client.example.com/webhooks/a2a",
      "token": "webhook-secret-token",
      "authentication": {
        "type": "apiKey",
        "apiKeyHeader": "X-Webhook-Auth",
        "apiKey": "secret123"
      }
    }
  }
}
```

When the task completes, the server POSTs:

```json
{
  "taskId": "task-456",
  "status": "completed",
  "artifacts": [
    {
      "kind": "text",
      "text": "Batch job processed 50,000 records"
    }
  ]
}
```

---

## Part 5: Implementation Guide

### Python SDK (Official)

**Install:**
```bash
pip install a2a-sdk
```

**Build an A2A Server:**

```python
from a2a_sdk import Agent, Skill, AgentCard, Message

# Define a skill
@Agent.skill()
async def process_payment(amount: float, currency: str = "USD") -> str:
    """Process a payment."""
    # Call Stripe or payment provider
    return f"Processed {currency} {amount}"

# Create the agent
agent = Agent(
    name="PaymentAgent",
    version="1.0.0",
    description="Handles payment processing",
)

# Register the skill
agent.register_skill(process_payment)

# Publish the Agent Card and serve A2A requests
if __name__ == "__main__":
    agent.serve(port=8000)
```

**Call an A2A Server (as a client):**

```python
from a2a_sdk import A2AClient

client = A2AClient()

# Send a synchronous message
response = await client.send_message(
    agent_url="https://payment-agent.example.com",
    message="Process a $150 payment for order #12345",
    auth_token="oauth2_token_here"
)
print(response["artifacts"])  # [{"kind": "text", "text": "Payment processed..."}]

# Stream responses for long operations
async for event in client.stream_message(
    agent_url="https://batch-agent.example.com",
    message="Process 100,000 records",
    auth_token="oauth2_token_here"
):
    if event["status"] == "running":
        print(f"Progress: {event.get('progress', 'unknown')}")
    elif event["status"] == "completed":
        print(f"Done! Result: {event['artifacts']}")
```

### TypeScript/Node.js SDK

**Install:**
```bash
npm install @a2a-js/sdk
```

**Build an A2A Server:**

```typescript
import { Agent, AgentServer } from "@a2a-js/sdk";

const agent = new Agent({
  name: "PaymentAgent",
  version: "1.0.0",
  description: "Process payments",
  serverUrl: "https://payment.example.com",
});

agent.defineSkill({
  id: "process_payment",
  name: "Process Payment",
  description: "Process a payment",
  inputSchema: {
    type: "object",
    properties: {
      amount: { type: "number" },
      currency: { type: "string", default: "USD" },
    },
    required: ["amount"],
  },
  handler: async (params: { amount: number; currency: string }) => {
    // Call payment provider
    return { success: true, transactionId: "txn-123" };
  },
});

const server = new AgentServer(agent);
server.listen(8000);
```

**Call an A2A Server:**

```typescript
import { A2AClient } from "@a2a-js/sdk";

const client = new A2AClient();

// Synchronous request
const response = await client.sendMessage(
  "https://payment-agent.example.com",
  {
    role: "user",
    parts: [{ kind: "text", text: "Process $150 payment" }],
  },
  { authorization: "Bearer oauth2_token" }
);

console.log(response.artifacts);

// Streaming request
const stream = await client.streamMessage(
  "https://batch-agent.example.com",
  { role: "user", parts: [{ kind: "text", text: "Process batch" }] },
  { authorization: "Bearer token" }
);

for await (const event of stream) {
  if (event.status === "completed") {
    console.log("Task done:", event.artifacts);
  }
}
```

### Creating an Agent Card Manually

```json
{
  "name": "OrderFullfillmentAgent",
  "version": "2.0.0",
  "description": "Manages order fulfillment and shipping",
  "serverUrl": "https://fulfillment.acme.com",
  "modalities": ["text"],
  "skills": [
    {
      "id": "check_inventory",
      "name": "Check Inventory",
      "description": "Check available stock for a product",
      "inputSchema": {
        "type": "object",
        "properties": {
          "product_id": {
            "type": "string",
            "description": "Product SKU"
          },
          "quantity": {
            "type": "integer",
            "description": "Quantity needed"
          }
        },
        "required": ["product_id"]
      }
    },
    {
      "id": "create_shipment",
      "name": "Create Shipment",
      "description": "Create a shipment for an order",
      "inputSchema": {
        "type": "object",
        "properties": {
          "order_id": { "type": "string" },
          "carrier": { "type": "string", "enum": ["UPS", "FedEx", "DHL"] }
        },
        "required": ["order_id"]
      }
    }
  ],
  "authentication": [
    {
      "type": "oauth2",
      "oauth2Endpoint": "https://fulfillment.acme.com/oauth/authorize",
      "scopes": ["orders:read", "shipments:write"]
    }
  ]
}
```

Save to `/.well-known/agent-card.json` on your agent's server.

---

## Part 6: Framework Integration

### CrewAI

CrewAI has native A2A support as of v0.x (2025):

```python
from crewai import Agent, Task, Crew
from crewai.tools import a2a_tool

# Create an agent that calls another A2A agent
payment_agent = Agent(
    name="Payment Processor",
    role="Handles payments via A2A",
    tools=[
        a2a_tool(
            agent_url="https://payment.example.com",
            auth_token="oauth2_token"
        )
    ],
)

task = Task(
    description="Process a $500 payment",
    agent=payment_agent,
)

crew = Crew(agents=[payment_agent], tasks=[task])
result = crew.kickoff()
```

**Note:** CrewAI agents themselves can be made A2A-compliant by wrapping them with the A2A SDK.

### LangGraph

LangGraph supports A2A via custom nodes:

```python
from langgraph.graph import StateGraph
from a2a_sdk import A2AClient

async def call_payment_agent(state):
    client = A2AClient()
    result = await client.send_message(
        agent_url="https://payment.example.com",
        message=f"Process {state['amount']}",
        auth_token=state["token"],
    )
    state["payment_result"] = result
    return state

graph = StateGraph()
graph.add_node("call_payment_agent", call_payment_agent)
graph.set_entry_point("call_payment_agent")
```

### AWS Bedrock AgentCore

AWS Bedrock AgentCore added native A2A support (Nov 2025):

```python
import boto3

bedrock = boto3.client("bedrock-agentcore")

# Deploy an A2A agent
response = bedrock.create_agent(
    agentName="PaymentProcessor",
    agentA2AConfig={
        "serverUrl": "https://payment.example.com",
        "agentCardUrl": "https://payment.example.com/.well-known/agent-card.json",
        "authentication": {
            "type": "oauth2",
            "tokenEndpoint": "https://auth.example.com/token",
        },
    },
)

# Invoke other A2A agents
response = bedrock.invoke_agent(
    agentId="agent-123",
    sessionId="session-456",
    inputText="Delegate to payment agent",
)
```

### Microsoft Copilot Studio

Connect A2A agents directly in the UI:

1. Go to **Copilot Studio** → **Agents** → **+ Add Agent**
2. Select **Agent-to-Agent (A2A) Protocol**
3. Enter agent endpoint: `https://your-agent.example.com`
4. Copilot Studio auto-fetches the Agent Card and shows skills
5. Create nodes that call the agent's skills

**Programmatically (via Custom Connector):**
```yaml
openapi: 3.0.0
info:
  title: A2A Agent Connector
  version: 1.0.0
servers:
  - url: https://your-agent.example.com
paths:
  /a2a:
    post:
      summary: Send message to A2A agent
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/A2ARequest"
      responses:
        "200":
          description: Task created or completed
```

---

## Part 7: Agent Discovery & Registries

### Direct Discovery

The simplest approach: directly fetch an agent's card:

```bash
curl https://payment-agent.example.com/.well-known/agent-card.json
```

**Pros:** No registry needed, real-time card
**Cons:** Must know the agent's URL in advance

### Registry-Based Discovery

For dynamic discovery, use an intermediary registry (not yet standardized, but emerging):

**Example registry API (community standard, not official A2A):**

```bash
GET /registry/agents?skill=payment&tag=production

[
  {
    "name": "PaymentAgent",
    "serverUrl": "https://payment.example.com",
    "tags": ["payment", "stripe"],
    "rating": 4.8,
    "cardUrl": "https://payment.example.com/.well-known/agent-card.json"
  }
]
```

**Implementation in Python:**

```python
import httpx

async def discover_agents(registry_url, skill: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{registry_url}/agents",
            params={"skill": skill, "tag": "production"}
        )
        agents = response.json()

        # Fetch and verify each agent's card
        verified = []
        for agent in agents:
            card = await client.get(agent["cardUrl"])
            verified.append(card.json())

        return verified

# Usage
agents = await discover_agents(
    "https://registry.example.com",
    skill="payment"
)
for agent in agents:
    print(f"Found: {agent['name']} at {agent['serverUrl']}")
```

---

## Part 8: Real-World Patterns

### Pattern 1: Cross-Org Purchasing Workflow

**Scenario:** Retailer needs to coordinate with payment processor and shipping partner.

```
Retailer Agent (orchestrator)
├─ [A2A] Call PaymentProcessor Agent
│  └─ [MCP] Stripe API
├─ [A2A] Call ShippingAgent
│  └─ [MCP] FedEx API
└─ Return order confirmation
```

**Implementation:**

```python
from a2a_sdk import Agent, A2AClient

async def orchestrate_order(order_data):
    client = A2AClient()

    # 1. Process payment via A2A
    payment_result = await client.send_message(
        agent_url="https://payments.partner.com",
        message=f"Process ${order_data['amount']} for order {order_data['id']}",
        auth_token=payment_token
    )

    if payment_result["status"] != "completed":
        raise Exception("Payment failed")

    # 2. Create shipment via A2A
    shipping_result = await client.send_message(
        agent_url="https://shipping.partner.com",
        message=f"Ship order {order_data['id']} to {order_data['address']}",
        auth_token=shipping_token
    )

    return {
        "order_id": order_data["id"],
        "payment": payment_result,
        "shipment": shipping_result
    }
```

### Pattern 2: Multi-Agent Task Delegation

**Scenario:** Legal review agent needs to delegate to specialized agents (contract, compliance, risk).

```
LegalReviewAgent
├─ [A2A] Delegate to ContractAnalysisAgent
│  └─ Stream contract review
├─ [A2A] Delegate to ComplianceAgent
│  └─ Stream regulatory check
├─ [A2A] Delegate to RiskAgent
│  └─ Stream risk assessment
└─ Aggregate results
```

**Implementation with streaming:**

```python
async def legal_review(document):
    client = A2AClient()
    tasks = []

    # Launch all agents in parallel
    for agent_url, agent_name in [
        ("https://contract.legal.com", "Contract"),
        ("https://compliance.legal.com", "Compliance"),
        ("https://risk.legal.com", "Risk"),
    ]:
        stream = client.stream_message(
            agent_url=agent_url,
            message=f"Review document for {agent_name}",
            auth_token=token
        )
        tasks.append((agent_name, stream))

    # Collect results
    results = {}
    for agent_name, stream in tasks:
        async for event in stream:
            if event["status"] == "completed":
                results[agent_name] = event["artifacts"]

    return results
```

### Pattern 3: Long-Running Batch Processing with Webhooks

**Scenario:** Client initiates a large batch job and wants async updates.

```
DataProcessingAgent receives task
  → Acknowledges immediately (return task ID)
  → Processes 1M records over 4 hours
  → POSTs progress updates to webhook
  → POSTs final result when done
```

**Server-side (A2A agent):**

```python
from a2a_sdk import Agent
import asyncio

@Agent.skill()
async def process_batch(file_url: str, webhook_config: dict) -> dict:
    """Process a batch and send updates to webhook."""
    task_id = generate_task_id()
    webhook_url = webhook_config["url"]
    webhook_token = webhook_config["token"]

    # Start background task
    asyncio.create_task(
        _process_in_background(task_id, file_url, webhook_url, webhook_token)
    )

    return {"task_id": task_id, "status": "processing"}

async def _process_in_background(task_id, file_url, webhook_url, webhook_token):
    total_records = count_records(file_url)
    processed = 0

    for record in stream_records(file_url):
        process_record(record)
        processed += 1

        # Send progress update every 10k records
        if processed % 10000 == 0:
            await post_webhook(
                webhook_url,
                webhook_token,
                {
                    "taskId": task_id,
                    "status": "running",
                    "progress": processed / total_records,
                }
            )

    # Send completion
    await post_webhook(
        webhook_url,
        webhook_token,
        {
            "taskId": task_id,
            "status": "completed",
            "artifacts": [{"kind": "text", "text": f"Processed {processed} records"}]
        }
    )
```

**Client-side:**

```python
from a2a_sdk import A2AClient

client = A2AClient()

# Initiate task with webhook
response = await client.send_message(
    agent_url="https://batch.example.com",
    message="Process records from s3://my-bucket/data.parquet",
    push_notification_config={
        "url": "https://myapp.example.com/webhooks/batch",
        "token": "webhook-secret-123"
    },
    auth_token=token
)

task_id = response["taskId"]
print(f"Batch processing started: {task_id}")
# App receives updates at /webhooks/batch when agent posts
```

---

## Part 9: When to Use A2A vs MCP vs Both

### Decision Framework

**Use MCP if:**
- A single agent needs access to tools (APIs, databases, web search)
- All systems are within your organization's infrastructure
- Low-latency function calls needed
- No long-running or async patterns required
- Example: Claude agent using MCP to query company database

**Use A2A if:**
- Multiple agents from different teams/orgs need to collaborate
- Agents must discover each other's capabilities dynamically
- Long-running, multi-step workflows with state management
- Agents need to reason about and negotiate with each other
- Example: Retailer's agent coordinating with payment processor's agent across organizational boundary

**Use Both (A2A + MCP) if:**
- Your agent orchestrates other agents (via A2A)
- Each agent uses tools internally (via MCP)
- You're building a heterogeneous multi-agent system
- Example: Orchestrator coordinates with 3 A2A agents, each using MCP for their own tool access

### Comparison Matrix

| Requirement | MCP | A2A | A2A+MCP |
|-------------|-----|-----|---------|
| Single agent + tools | ✓ | ✗ | ✓ (overkill) |
| Multi-agent same org | ✓ | ✓ | ✓ (simpler direct calls) |
| Multi-agent cross-org | ✗ | ✓ | ✓ |
| Long-running tasks | ✗ | ✓ | ✓ |
| Real-time streaming | ✓ | ✓ | ✓ |
| Agent autonomy | ✗ | ✓ | ✓ |
| Dynamic discovery | ✗ | ✓ | ✓ |

---

## Part 10: Security Considerations

### Authentication Checklist

- [ ] Agent Card published at `/.well-known/agent-card.json`
- [ ] Agent Card signed with JWT (v0.3+)
- [ ] Credentials not hardcoded; use env vars or secrets manager
- [ ] Support OAuth2 or mTLS (not basic auth over HTTP)
- [ ] Validate JWT signatures before trusting cards
- [ ] Use HTTPS for all A2A communications
- [ ] Implement rate limiting on A2A endpoints

### Authorization Checklist

- [ ] A2A agents validate incoming task requests (who can call what?)
- [ ] Agents check caller's token scopes (e.g., "payment:process")
- [ ] Agents implement role-based access (admin vs. user)
- [ ] Audit logging for all A2A calls (request, response, timestamp, caller)
- [ ] MCP tools called by agents are also authenticated
- [ ] Webhook URLs validated (HTTPS, signed tokens)

### Example: Validating JWT Agent Cards

```python
import jwt
import httpx

async def verify_agent_card(agent_url: str):
    """Fetch and verify agent's signed card."""
    async with httpx.AsyncClient() as client:
        card_response = await client.get(f"{agent_url}/.well-known/agent-card.json")
        card = card_response.json()

        if not card.get("signatures"):
            raise ValueError("Card not signed")

        sig = card["signatures"][0]

        # Fetch public key from agent's key server
        key_response = await client.get(
            f"{agent_url}/.well-known/keys/{sig['keyId']}"
        )
        public_key = key_response.text

        # Verify JWT
        try:
            jwt.decode(
                sig["value"],
                public_key,
                algorithms=[sig["algorithm"]]
            )
            return card
        except jwt.InvalidSignatureError:
            raise ValueError("Card signature invalid")
```

---

## Part 11: Limitations & Gotchas

### Architectural Limitations

**N-Squared Connectivity Problem:** In a system with N agents, direct peer-to-peer communication creates N² connections. At 100 agents, that's 10,000 potential connections.

*Solution:* Use a message broker or orchestrator pattern instead of pure peer-to-peer for large agent networks.

**HTTP Connection Timeouts:** Long-running tasks over HTTP can timeout if connections are idle.

*Solution:* Use SSE for streaming or webhooks for tasks > 30 minutes.

**No Built-In Consensus or Voting:** If 3 agents must agree on an action, A2A doesn't provide consensus mechanisms.

*Solution:* Implement consensus logic in the orchestrator agent.

### Protocol Limitations

**No Standard Registry:** A2A itself doesn't define a registry API; registries are community-driven.

*Solution:* Expect to build or integrate your own registry service.

**No Built-In Rate Limiting:** Rate limits must be implemented per-agent.

*Solution:* Use API gateway (Kong, Nginx, AWS API Gateway) in front of A2A agents.

**Error Semantics:** A2A returns HTTP 200 even for errors (JSON-RPC style). Clients must parse the JSON response carefully.

*Solution:* Always check `response["error"]` as well as `response["result"]`.

### Implementation Gotchas

**Agent Card Caching:** If you cache an agent's card, you may miss updates to its capabilities.

*Solution:* Implement card refresh TTL (e.g., re-fetch every 24 hours or on error).

**Webhook Security:** Webhooks are HTTP POSTs to your infrastructure; validate the source.

*Solution:* Use signed JWT tokens in webhook payloads.

**Circular Dependencies:** Agent A calling Agent B calling Agent A.

*Solution:* Implement cycle detection and timeouts in orchestrator.

**Handling Partial Failures:** In multi-agent workflows, one agent's failure may leave others halfway done.

*Solution:* Implement compensating transactions or rollback handlers.

---

## Part 12: Ecosystem Status (2026)

### Supported Platforms

| Platform | A2A Support | Status |
|----------|-------------|--------|
| **Google Cloud (Agent Engine)** | Native (v0.3+) | Production |
| **AWS Bedrock AgentCore** | Native (v0.3+) | Production |
| **Microsoft Copilot Studio** | Native (preview) | GA planned Q2 2026 |
| **CrewAI** | Native | Production |
| **LangGraph** | Via custom nodes | Production |
| **Claude Agent SDK** | Via MCP + custom code | Early adoption |
| **OpenAI Agents SDK** | Roadmap | Not yet |

### SDKs Available (2026)

- **Python**: Official a2a-sdk (pypi), Dexwox a2a-node, community SDKs
- **TypeScript/Node.js**: Official a2a-js (@a2a-js/sdk), Dexwox a2a-node
- **Go**: Official a2a-go
- **Java**: Official a2a-java
- **.NET**: Official a2a-dotnet

All hosted at [github.com/a2aproject](https://github.com/a2aproject).

### Backing Organizations (150+)

Google, AWS, Microsoft, Salesforce, SAP, IBM, Stripe, PayPal, Anthropic, OpenAI (observer), Red Hat, Databricks, and many more.

---

## Part 13: Migration Path

### Existing MCP-Based Agents

If you have agents using MCP for tool access:

**Step 1: Add A2A Server capability**
```python
from a2a_sdk import Agent, A2AClient

# Create A2A agent wrapping your existing MCP-using agent
a2a_agent = Agent(
    name="MyMCPAgent",
    description="Existing agent with MCP tool access",
    mcp_tools=[...],  # Your existing MCP tool definitions
)

a2a_agent.serve(port=8000)
```

**Step 2: Publish Agent Card**
```json
{
  "name": "MyMCPAgent",
  "serverUrl": "https://myagent.example.com",
  "skills": [
    {
      "id": "search_knowledge_base",
      "name": "Search Knowledge Base",
      "inputSchema": { ... }
    }
  ]
}
```

**Step 3: Use as A2A server in multi-agent systems**
```python
orchestrator = Agent(...)

# Now orchestrator can call MyMCPAgent via A2A
result = await orchestrator.delegate_to_a2a(
    agent_url="https://myagent.example.com",
    message="Search for Q4 budget docs"
)
```

**No need to rewrite MCP integration; layer A2A on top.**

---

## Sources

### Official A2A Documentation
- [A2A Protocol Official Site](https://a2a-protocol.org/latest/)
- [GitHub: a2aproject/A2A](https://github.com/a2aproject/A2A)
- [Linux Foundation Announcement](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents)
- [Google Developers Blog: A2A Announcement](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)
- [Google Cloud Blog: A2A Upgrade (v0.3)](https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade)

### Platform Integration
- [AWS Bedrock AgentCore A2A Support](https://aws.amazon.com/blogs/machine-learning/introducing-agent-to-agent-protocol-support-in-amazon-bedrock-agentcore-runtime/)
- [Microsoft Copilot Studio A2A Integration](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-agent-to-agent)
- [CrewAI A2A Support](https://docs.crewai.com/en/learn/a2a-agent-delegation)
- [Google Codelabs: A2A Protocol (Purchasing Concierge)](https://codelabs.developers.google.com/intro-a2a-purchasing-concierge)

### A2A vs MCP
- [Stride: A2A vs MCP Comparison](https://www.stride.build/blog/agent-to-agent-a2a-vs-model-context-protocol-mcp-when-to-use-which)
- [TrueFoundry: MCP vs A2A](https://www.truefoundry.com/blog/mcp-vs-a2a)
- [Auth0: MCP vs A2A Guide](https://auth0.com/blog/mcp-vs-a2a/)
- [A2A Protocol Docs: A2A and MCP](https://a2a-protocol.org/latest/topics/a2a-and-mcp/)

### SDKs & Implementation
- [A2A Python SDK (PyPI)](https://pypi.org/project/a2a-sdk/)
- [a2a-python GitHub](https://github.com/a2aproject/a2a-python)
- [a2a-js GitHub](https://github.com/a2aproject/a2a-js)
- [Dexwox A2A Node SDK](https://github.com/Dexwox-Innovations-Org/a2a-node-sdk)

### Security & Architecture
- [Red Hat Developer: A2A Security](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security)
- [Semgrep: A2A Security Guide](https://semgrep.dev/blog/2025/a-security-engineers-guide-to-the-a2a-protocol)
- [InfoWorld: A2A Multi-Agent Autonomy](https://www.infoworld.com/article/4088217/what-is-a2a-how-the-agent-to-agent-protocol-enables-autonomous-collaboration.html)

### Real-World Use Cases
- [Fractal: Multi-Agent Orchestration with A2A](https://fractal.ai/blog/orchestrating-heterogeneous-and-distributed-multi-agent-systems-using-agent-to-agent-a2a-protocol/)
- [Microsoft Cloud Blog: A2A for Multi-Agent Apps](https://www.microsoft.com/en-us/microsoft-cloud/blog/2025/05/07/empowering-multi-agent-apps-with-the-open-agent2agent-a2a-protocol/)
- [PayPal A2A Use Case (via Microsoft)](https://www.microsoft.com/en-us/microsoft-cloud/blog/2025/05/07/empowering-multi-agent-apps-with-the-open-agent2agent-a2a-protocol/)

---

## Quick Reference

### A2A Workflow in 30 seconds

1. Agent publishes itself at `/.well-known/agent-card.json`
2. Orchestrator fetches the card to see capabilities
3. Orchestrator sends JSON-RPC 2.0 request over HTTP
4. Server responds with streaming updates (SSE) or synchronously
5. For long tasks, server POSTs to client's webhook
6. All messages signed, authenticated, and audited

### MCP Workflow in 30 seconds

1. Agent loads MCP tools (via client-server or stdio)
2. LLM sees tool definitions and calls them when relevant
3. Tool returns result
4. No inter-agent coordination; single agent using tools

### Together

- **MCP**: Agent ← → Tools (vertical)
- **A2A**: Agent ← → Agent (horizontal)
- **A2A + MCP**: Agent ← A2A → Agent ← MCP → Tools (full stack)

---

## Next Steps

1. **Evaluate:** Does your use case require multi-agent collaboration? If so, A2A.
2. **Prototype:** Deploy a simple A2A agent using Python SDK with a single skill.
3. **Test discovery:** Publish agent card, verify orchestrator can fetch and parse it.
4. **Add authentication:** Implement OAuth2 or mTLS on your agent endpoint.
5. **Integrate with platform:** Deploy to Bedrock, Agent Engine, or Copilot Studio.
6. **Monitor & audit:** Log all A2A calls for governance and debugging.

---

**Document Version:** 1.0
**Last Updated:** 2026-03-28
**Maintainer:** Brian (AIResearch)

