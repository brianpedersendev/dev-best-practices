# Building Custom MCP Servers: From Basics to Production (2025-2026)

**Research Date:** 2026-03-18
**Scope:** Complete guide to building, deploying, and securing MCP servers
**Audience:** Developers of all levels building custom Model Context Protocol servers

---

## Table of Contents

1. [MCP Architecture Overview](#1-mcp-architecture-overview)
2. [When to Build vs. Use Existing](#2-when-to-build-vs-use-existing)
3. [Building Your First MCP Server](#3-building-your-first-mcp-server)
4. [The Three Primitives In Depth](#4-the-three-primitives-in-depth)
5. [Wrapping Existing APIs as MCP Servers](#5-wrapping-existing-apis-as-mcp-servers)
6. [Production Patterns](#6-production-patterns)
7. [Advanced Patterns](#7-advanced-patterns)
8. [Real-World Examples](#8-real-world-examples)
9. [Debugging & Troubleshooting](#9-debugging--troubleshooting)
10. [Production Readiness Checklist](#10-production-readiness-checklist)

---

## 1. MCP Architecture Overview

### The Protocol: JSON-RPC 2.0 Over Multiple Transports

The Model Context Protocol is built on **JSON-RPC 2.0**, a stateless remote procedure call protocol. However, MCP adds statefulness through **session management** — each connection maintains an authenticated session that persists across multiple tool calls.

**Core architectural principles:**

- **Session-based:** Unlike REST (stateless), MCP maintains persistent authenticated sessions. No repeated auth handshakes between calls.
- **Self-describing:** Tools are advertised via `tools/list` with full JSON Schema. Models read the schema before calling.
- **Transport-agnostic:** MCP works over Stdio (local dev), HTTP/SSE (production), or WebSocket.
- **Model-driven:** The model discovers available tools and decides when to call them (vs. hardcoding integrations).

### Transport Types

**Stdio (Local Development)**
- Default for development and local debugging
- Spawns server process as subprocess
- No network exposure; no authentication needed
- Perfect for Cursor, Claude Code, local testing

```
Client ←→ [Stdio] ←→ Server Process
```

**HTTP/SSE (Production)**
- Server runs as HTTP endpoint
- Clients connect via HTTP with OAuth 2.1 authentication
- Server-Sent Events for streaming responses
- Standard for cloud deployments

```
Client ←→ [HTTP/SSE with OAuth 2.1] ←→ Server (Cloud)
```

**Streamable HTTP (Emerging, 2026)**
- Bidirectional HTTP streaming
- Better than SSE for large responses
- Reduces latency for long operations
- Requires reverse proxy support

### Session Lifecycle

1. **Initialize**: Client connects, server responds with capabilities (protocol version, tools, resources, prompts)
2. **Capability Negotiation**: Client and server agree on supported features
3. **Tool Discovery**: Client calls `tools/list` to get full schema
4. **Tool Execution**: Client calls tools by name; server processes and returns results
5. **Cleanup**: Client disconnects; server cleans up session state

### Three Core Primitives

**Tools** (Functions the LLM calls)
- Actions: fetch data, modify state, execute computations
- Model-driven: LLM decides when to invoke
- Schema-based: Full JSON Schema for inputs/outputs
- Stateful within session: Can reference previous calls

Example: `get_weather(city: string)` — LLM asks for weather, tool responds

**Resources** (Data the client reads)
- Read-only context injection
- Application or user-driven: Client decides when relevant
- URI-based: `uri://resource-id` identifies each resource
- Best for static/semi-static data

Example: `docs://architecture-guide` — client fetches design docs once, includes in context

**Prompts** (Instruction templates)
- Predefined message sequences
- Standardize model behavior
- Can embed dynamic data
- User-triggered: via slash commands or API

Example: `prompt://code-review` — templates a code review workflow

**Decision Matrix:**

| Need | Use | Why |
|------|-----|-----|
| Model acts autonomously | Tool | LLM-driven, requires invocation |
| Provide context data | Resource | Read-only, persistent in context |
| Standardize instructions | Prompt | Reusable templates |
| Real-time fetch required | Tool | Immediate execution |
| Static reference data | Resource | No computation needed |

---

## 2. When to Build vs. Use Existing

### Decision Framework

**Build a custom MCP server if:**

- You're integrating with internal APIs (internal auth, proprietary data)
- Your API isn't covered by existing servers (check [mcpservers.org](https://mcpservers.org))
- You need custom authentication (pass API keys, handle SSO)
- You need to transform/wrap an API for agent consumption
- You're building domain-specific tools (internal tools, custom workflows)

**Use an existing server if:**

- There's an official or well-maintained server (GitHub, Figma, Supabase, etc.)
- Your API is public and generic (weather, news, generic SaaS APIs)
- You're just wrapping REST (use `mcp-openapi` auto-generation instead)

### Common Use Cases for Custom Servers

**1. Internal API Integration**

```
Your Company
├─ REST API (internal auth)
├─ Proprietary database
└─ Custom business logic
      ↓
    [MCP Wrapper]
      ↓
Claude/Cursor agents
```

**2. Proprietary Data Access**

```
Private Data Sources
├─ Customer database
├─ Internal documentation
├─ Design system tokens
      ↓
    [MCP Server]
      ↓
AI agents with read-only access
```

**3. Custom Workflows**

Tool composition where tools call other tools:
- Approval workflows (tool checks permissions before executing)
- Multi-step operations (search → filter → transform → deliver)
- Custom business logic specific to your domain

**4. Authentication Bridge**

Your company uses non-standard auth:
- SAML-based (enterprise SSO)
- Custom OAuth provider
- Certificate-based authentication

---

## 3. Building Your First MCP Server

### Python with FastMCP (Recommended for Beginners)

**Why FastMCP?**
- Simplest to learn (decorator-based API)
- ~1M downloads/day; powers 70% of MCP servers across all languages
- Automatic schema generation from Python type hints
- Full async/await support
- Built-in testing and debugging

#### Step 1: Install

```bash
pip install fastmcp
```

#### Step 2: Create a Simple Server

**File: `weather_server.py`**

```python
from fastmcp import FastMCP
from typing import Optional

# Create the MCP server
mcp = FastMCP("weather-server")

# Define a tool
@mcp.tool()
def get_weather(city: str) -> str:
    """
    Get the current weather for a city.

    Args:
        city: The name of the city (e.g., "San Francisco")

    Returns:
        A weather description
    """
    # In reality, call a weather API
    weather_data = {
        "San Francisco": "Sunny, 72°F",
        "New York": "Cloudy, 65°F",
        "London": "Rainy, 55°F"
    }

    return weather_data.get(city, f"Weather for {city}: Unknown")

@mcp.tool()
def get_forecast(city: str, days: int = 7) -> str:
    """
    Get a multi-day forecast for a city.

    Args:
        city: The city name
        days: Number of days to forecast (default: 7)

    Returns:
        Forecast summary
    """
    return f"{days}-day forecast for {city}: Generally favorable conditions ahead"

# Optional: Define a resource (read-only data)
@mcp.resource("weather://help")
def weather_help() -> str:
    """Helpful information about the weather server."""
    return """
    # Weather Server Help

    This server provides weather information for major cities.
    Use get_weather() for current conditions.
    Use get_forecast() for future predictions.
    """

if __name__ == "__main__":
    # Run the server on stdio (perfect for local testing)
    mcp.run()
```

#### Step 3: Test with MCP Inspector

```bash
# Install MCP Inspector
npm install -g @modelcontextprotocol/inspector

# Run the server with Inspector
npx @modelcontextprotocol/inspector python weather_server.py
```

The Inspector opens at `http://localhost:6274`. You'll see:
- Available tools and their schemas
- Interactive tool tester
- Real request/response examples

#### Step 4: Register with Claude Code

Add to `~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "weather": {
      "command": "python",
      "args": ["/path/to/weather_server.py"]
    }
  }
}
```

Restart Claude Code, and the weather tools appear automatically.

### TypeScript/JavaScript with Official SDK

**Why TypeScript?**
- Full control over implementation
- Better for HTTP servers and complex logic
- Larger ecosystem of integrations

#### Step 1: Install

```bash
npm init -y
npm install @modelcontextprotocol/sdk zod
npm install -D @types/node typescript
```

#### Step 2: Create a Server

**File: `src/weather.ts`**

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

// Weather data (mock)
const weatherData: Record<string, string> = {
  "San Francisco": "Sunny, 72°F",
  "New York": "Cloudy, 65°F",
  "London": "Rainy, 55°F",
};

// Create server
const server = new Server({
  name: "weather-server",
  version: "1.0.0",
});

// Handler for listing available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "get_weather",
        description: "Get the current weather for a city",
        inputSchema: {
          type: "object" as const,
          properties: {
            city: {
              type: "string",
              description: "The city name (e.g., 'San Francisco')",
            },
          },
          required: ["city"],
        },
      },
      {
        name: "get_forecast",
        description: "Get a multi-day forecast",
        inputSchema: {
          type: "object" as const,
          properties: {
            city: {
              type: "string",
              description: "The city name",
            },
            days: {
              type: "number",
              description: "Number of days to forecast",
              default: 7,
            },
          },
          required: ["city"],
        },
      },
    ],
  };
});

// Handler for calling tools
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "get_weather") {
    const city = (args as Record<string, unknown>).city as string;
    const weather = weatherData[city] || `Weather for ${city}: Unknown`;
    return {
      content: [
        {
          type: "text" as const,
          text: weather,
        },
      ],
    };
  }

  if (name === "get_forecast") {
    const city = (args as Record<string, unknown>).city as string;
    const days = ((args as Record<string, unknown>).days as number) || 7;
    return {
      content: [
        {
          type: "text" as const,
          text: `${days}-day forecast for ${city}: Generally favorable conditions`,
        },
      ],
    };
  }

  return {
    content: [
      {
        type: "text" as const,
        text: `Unknown tool: ${name}`,
      },
    ],
    isError: true,
  };
});

// Connect transport and start
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Weather server running on stdio");
}

main().catch(console.error);
```

#### Step 3: Compile and Test

```bash
npx tsc
node build/index.js  # or test with Inspector
```

#### Step 4: Register with Claude Code

```json
{
  "mcpServers": {
    "weather": {
      "command": "node",
      "args": ["/path/to/build/index.js"]
    }
  }
}
```

---

## 4. The Three Primitives In Depth

### Tools (Actions)

**What they are:** Functions the model can call to take actions or fetch real-time data.

**When to use:**
- Fetching real-time data (weather, stock prices, current time)
- Modifying state (creating files, updating databases)
- Computations that depend on user input
- Actions the model discovers and invokes autonomously

**Schema Design:**

Tools require strict JSON Schema for inputs. Keys to define:

| Key | Purpose | Example |
|-----|---------|---------|
| `type` | Always `"object"` for tool inputs | `"object"` |
| `properties` | Field names and types | `{ "city": { "type": "string" } }` |
| `required` | Mandatory fields | `["city"]` |
| `description` | Human-readable explanation | `"The city name"` |

**Example: GitHub Issue Creator Tool**

```python
@mcp.tool()
def create_github_issue(
    repo: str,
    title: str,
    body: str,
    labels: list[str] = None
) -> dict:
    """
    Create a new GitHub issue in a repository.

    Args:
        repo: Repository in 'owner/repo' format
        title: Issue title (max 256 chars)
        body: Issue description (markdown supported)
        labels: Optional list of label names

    Returns:
        Issue details including ID and URL
    """
    import requests
    import os

    token = os.getenv("GITHUB_TOKEN")
    headers = {"Authorization": f"token {token}"}

    url = f"https://api.github.com/repos/{repo}/issues"
    payload = {
        "title": title,
        "body": body,
        "labels": labels or []
    }

    response = requests.post(url, json=payload, headers=headers)
    response.raise_for_status()

    issue = response.json()
    return {
        "id": issue["id"],
        "number": issue["number"],
        "url": issue["html_url"],
        "title": issue["title"]
    }
```

**Best practices for tool design:**

1. **Clear names:** `get_user_by_id` not `fetch` or `query`
2. **Single responsibility:** One tool does one thing well
3. **Fail gracefully:** Return meaningful error messages, not stack traces
4. **Validate inputs:** Enforce schema; reject invalid inputs early
5. **Rate limit:** Protect backend services from abuse
6. **Timeout:** Set max execution time (10-30 seconds typical)

### Resources (Data)

**What they are:** Static or semi-static data exposed via URI that clients can read and include in context.

**When to use:**
- Reference documentation (API docs, design systems)
- Configuration data (project settings, feature flags)
- Static content (privacy policy, terms of service)
- Data the client proactively fetches, not the model

**Resource lifecycle:**
1. Server lists available resources via `resources/list` (includes URI and description)
2. Client (Claude Code, etc.) fetches resource by URI
3. Client includes resource content in context (like reading a file)
4. Model reasons about the content

**Example: Design System Resource**

```python
from fastmcp import FastMCP

mcp = FastMCP("design-system-server")

@mcp.resource("design://colors")
def get_colors() -> str:
    """
    Design system color palette.
    """
    return """
# Color Palette

## Primary Colors
- Primary Blue: #0066FF
- Primary Teal: #00B8A0

## Semantic Colors
- Success: #00A651
- Warning: #FFA500
- Error: #E74C3C
- Info: #3498DB

## Usage
Use primary blue for CTAs, teal for secondary actions.
"""

@mcp.resource("design://typography")
def get_typography() -> str:
    """
    Typography guidelines and scale.
    """
    return """
# Typography

## Font Stack
- Primary: Inter, sans-serif
- Mono: Inconsolata, monospace

## Scale
- H1: 32px, font-weight 700
- H2: 24px, font-weight 600
- Body: 16px, font-weight 400
- Small: 14px, font-weight 400
"""

@mcp.resource("design://spacing")
def get_spacing() -> str:
    """
    Spacing system and layout guide.
    """
    return """
# Spacing Scale

Base unit: 4px

- xs: 4px (1 unit)
- sm: 8px (2 units)
- md: 16px (4 units)
- lg: 24px (6 units)
- xl: 32px (8 units)
- 2xl: 48px (12 units)

Use md (16px) as default margin/padding.
"""
```

When Claude Code connects to this server, it can fetch `design://colors` once and keep the color palette in context across the entire session.

**Difference from Tools:**

| Aspect | Tools | Resources |
|--------|-------|-----------|
| Invocation | Model-driven (LLM calls when needed) | User/app-driven (fetched proactively) |
| Frequency | Called multiple times in session | Fetched once, cached in context |
| Latency | Lower (real-time) | Higher (I/O-bound) |
| Use case | Actions, real-time data | Context, reference data |

### Prompts (Templates)

**What they are:** Predefined, reusable message sequences that help users and models collaborate consistently.

**When to use:**
- Standardizing common workflows ("code review", "security audit")
- Pre-filling instruction templates
- Guiding users through complex processes
- Reducing token waste from repeated prompts

**Example: Code Review Prompt**

```python
from fastmcp import FastMCP

mcp = FastMCP("code-review-server")

@mcp.prompt("code-review")
def code_review_prompt(file_path: str, focus_areas: str = "security,performance") -> list:
    """
    Structured code review template.

    Args:
        file_path: Path to file being reviewed
        focus_areas: Comma-separated review areas
    """
    return [
        {
            "type": "text",
            "text": f"""You are a senior code reviewer. Review {file_path} with focus on: {focus_areas}

## Review Checklist
- [ ] Does the code follow our style guide?
- [ ] Are there potential security issues?
- [ ] Is performance acceptable?
- [ ] Are error cases handled?
- [ ] Is the code maintainable?
- [ ] Are there unit tests?

Provide constructive feedback with specific examples."""
        }
    ]

@mcp.prompt("security-audit")
def security_audit_prompt(module: str) -> list:
    """
    Security-focused code audit template.
    """
    return [
        {
            "type": "text",
            "text": f"""Perform a security audit of {module}. Check for:

## OWASP Top 10
- Injection attacks (SQL, command)
- Broken auth
- Sensitive data exposure
- XML external entities
- Broken access control
- Security misconfiguration
- XSS
- Insecure deserialization
- Using components with known vulns
- Insufficient logging

List vulnerabilities with CVSS scores and remediation."""
        }
    ]
```

When a user triggers `/code-review`, the prompt template is sent to the model, ensuring consistent structure across reviews.

---

## 5. Wrapping Existing APIs as MCP Servers

### Option 1: Use mcp-openapi (Auto-Generation)

If your API has an OpenAPI/Swagger spec, **mcp-openapi** generates MCP tools automatically.

**Steps:**

1. **Ensure your API has OpenAPI spec:**
   ```yaml
   openapi: 3.0.0
   info:
     title: Internal Employee API
     version: 1.0.0
   servers:
     - url: https://internal-api.company.com/v1
   paths:
     /employees/{id}:
       get:
         parameters:
           - name: id
             in: path
             required: true
             schema:
               type: string
         responses:
           '200':
             description: Employee details
             content:
               application/json:
                 schema:
                   $ref: '#/components/schemas/Employee'
   ```

2. **Generate MCP server:**
   ```bash
   npx mcp-openapi https://internal-api.company.com/openapi.json \
     --output-type stdio \
     --auth-type oauth2 \
     --oauth-client-id your-client-id \
     --oauth-client-secret your-client-secret
   ```

3. **Register with Claude Code:**
   ```json
   {
     "mcpServers": {
       "employees": {
         "command": "npx",
         "args": ["mcp-openapi", "https://internal-api.company.com/openapi.json"],
         "env": {
           "OAUTH_CLIENT_ID": "your-client-id",
           "OAUTH_CLIENT_SECRET": "your-client-secret"
         }
       }
     }
   }
   ```

**Advantages:**
- Zero custom code
- Tools automatically generated from spec
- Schema keeps docs and implementation in sync

### Option 2: Manual Wrapping with FastMCP

For custom authentication, transformation, or business logic:

**Example: Wrapping an Internal REST API**

```python
from fastmcp import FastMCP
import httpx
import os
from typing import Optional

mcp = FastMCP("internal-api-wrapper")

# API client initialization
api_base_url = "https://internal-api.company.com/v1"
api_token = os.getenv("INTERNAL_API_TOKEN")

@mcp.tool()
async def get_employee(employee_id: str) -> dict:
    """
    Get employee information by ID.

    Args:
        employee_id: The employee's ID

    Returns:
        Employee object with name, email, department
    """
    headers = {"Authorization": f"Bearer {api_token}"}

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{api_base_url}/employees/{employee_id}",
            headers=headers,
            timeout=10.0
        )
        response.raise_for_status()
        return response.json()

@mcp.tool()
async def list_employees(department: Optional[str] = None) -> list:
    """
    List all employees, optionally filtered by department.

    Args:
        department: Optional department filter (e.g., 'engineering', 'sales')

    Returns:
        List of employee objects
    """
    headers = {"Authorization": f"Bearer {api_token}"}
    params = {"department": department} if department else {}

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{api_base_url}/employees",
            headers=headers,
            params=params,
            timeout=10.0
        )
        response.raise_for_status()
        return response.json()

@mcp.tool()
async def create_employee(
    name: str,
    email: str,
    department: str,
    salary: Optional[int] = None
) -> dict:
    """
    Create a new employee record.

    Args:
        name: Employee's full name
        email: Company email address
        department: Department (engineering, sales, etc.)
        salary: Optional salary (in cents)

    Returns:
        Created employee object with ID
    """
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    payload = {
        "name": name,
        "email": email,
        "department": department,
    }
    if salary is not None:
        payload["salary"] = salary

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{api_base_url}/employees",
            json=payload,
            headers=headers,
            timeout=10.0
        )
        response.raise_for_status()
        return response.json()

@mcp.resource("api://schema/employee")
def get_employee_schema() -> str:
    """
    Employee object schema for reference.
    """
    return """
# Employee Schema

- id: string (UUID)
- name: string
- email: string (company email)
- department: string enum (engineering, sales, marketing, hr)
- salary: optional integer (in cents)
- created_at: ISO 8601 timestamp
- updated_at: ISO 8601 timestamp
"""

if __name__ == "__main__":
    mcp.run()
```

**Key considerations when wrapping:**

1. **Authentication:** Store secrets in environment variables, never hardcode
2. **Error handling:** Return user-friendly error messages
3. **Rate limiting:** Respect backend limits; add local rate limiting if needed
4. **Timeouts:** Set reasonable timeouts (10-30 seconds) to prevent hanging
5. **Validation:** Validate inputs before hitting the API
6. **Transformation:** Map API responses to cleaner schemas if needed

---

## 6. Production Patterns

### Authentication & Security

#### OAuth 2.1 for HTTP Servers (Required)

OAuth 2.1 is the standard for production HTTP-based MCP servers. It replaces the insecure implicit flow and requires PKCE.

**Setup example (FastMCP with OAuth):**

```python
from fastmcp import FastMCP
from fastmcp.resources import OAuth2Provider
import os

mcp = FastMCP("secure-api-server")

# Configure OAuth 2.1
oauth_provider = OAuth2Provider(
    client_id=os.getenv("OAUTH_CLIENT_ID"),
    client_secret=os.getenv("OAUTH_CLIENT_SECRET"),
    token_url="https://auth.company.com/oauth/token",
    authorize_url="https://auth.company.com/oauth/authorize",
    scopes=["read:data", "write:data"],
    require_pkce=True  # PKCE required
)

@mcp.tool()
async def get_secure_data(resource_id: str) -> dict:
    """
    Get secure data (requires OAuth authentication).
    """
    # FastMCP automatically injects the authenticated token
    # Access via context or request object
    return {"data": "sensitive"}
```

**For Stdio servers (local development):**

Use environment variables for API tokens (acceptable for local-only use):

```bash
export INTERNAL_API_TOKEN="your-api-token"
claude mcp add my-server
```

**Never:**
- Store API keys in code
- Use static bearer tokens in production HTTP servers
- Bind HTTP servers to 0.0.0.0 without authentication (NeighborJack vulnerability)

#### Input Validation

Enforce JSON Schema validation to prevent injection and malformed inputs:

```python
from fastmcp import FastMCP
from pydantic import BaseModel, Field, validator
from typing import Optional

mcp = FastMCP("validated-server")

# Define validation schema
class QueryParameters(BaseModel):
    query: str = Field(min_length=1, max_length=256)
    limit: int = Field(default=10, ge=1, le=100)
    offset: int = Field(default=0, ge=0)

    @validator('query')
    def validate_query(cls, v):
        # Prevent SQL injection patterns
        dangerous_patterns = ["'; DROP", "--", "/*"]
        if any(pattern.lower() in v.lower() for pattern in dangerous_patterns):
            raise ValueError("Suspicious query pattern detected")
        return v

@mcp.tool()
async def search(query: str, limit: int = 10, offset: int = 0) -> list:
    """
    Search resources (validated input).
    """
    params = QueryParameters(query=query, limit=limit, offset=offset)
    # Now params are validated and safe
    return []
```

#### Path Sanitization (Critical for File Operations)

82% of MCP file operations are vulnerable to path traversal. Prevent access outside intended directories:

```python
import os
from pathlib import Path

@mcp.tool()
def read_file(relative_path: str) -> str:
    """
    Read a file from the allowed directory (safe).
    """
    # Define allowed base directory
    allowed_base = Path("/data/documents").resolve()

    # Resolve requested path
    requested_path = (allowed_base / relative_path).resolve()

    # Ensure requested path is within allowed base
    if not str(requested_path).startswith(str(allowed_base)):
        raise ValueError(f"Access denied: path outside allowed directory")

    # Additional checks
    if not requested_path.exists():
        raise FileNotFoundError(f"File not found: {relative_path}")

    if not requested_path.is_file():
        raise ValueError(f"Not a file: {relative_path}")

    with open(requested_path, 'r') as f:
        return f.read()
```

**Never:**
```python
# VULNERABLE: Allows ../../../etc/passwd
open(f"/data/documents/{user_path}", 'r')
```

#### Rate Limiting

Protect backend services from abuse:

```python
from fastmcp import FastMCP
from collections import defaultdict
import time

mcp = FastMCP("rate-limited-server")

# Simple rate limiter (production: use Redis)
rate_limit_store = defaultdict[str, list[float]](list)
MAX_CALLS_PER_MINUTE = 60

def check_rate_limit(client_id: str) -> bool:
    now = time.time()
    cutoff = now - 60

    # Remove old calls
    rate_limit_store[client_id] = [
        call_time for call_time in rate_limit_store[client_id]
        if call_time > cutoff
    ]

    # Check limit
    if len(rate_limit_store[client_id]) >= MAX_CALLS_PER_MINUTE:
        return False

    # Record this call
    rate_limit_store[client_id].append(now)
    return True

@mcp.tool()
async def expensive_operation(client_id: str, data: str) -> str:
    """
    Operation with rate limiting.
    """
    if not check_rate_limit(client_id):
        raise Exception("Rate limit exceeded (60 calls per minute)")

    # Perform operation
    return "success"
```

### Error Handling

Return clear, actionable errors:

```python
@mcp.tool()
async def create_user(email: str, name: str) -> dict:
    """
    Create a new user.
    """
    # Validate input
    if "@" not in email:
        raise ValueError("Invalid email format. Expected format: user@example.com")

    if len(name) < 2:
        raise ValueError("Name must be at least 2 characters")

    try:
        # Create user
        result = await api_client.create_user(email=email, name=name)
        return result
    except Exception as e:
        if "already exists" in str(e):
            raise ValueError(f"User with email {email} already exists")
        if "database" in str(e).lower():
            raise Exception("Database unavailable; please retry in a moment")
        raise

```

### Timeout Handling for Long Operations

Long operations (>30 seconds) can timeout. Use progress notifications to keep connection alive:

```python
from fastmcp import FastMCP, TextContent
import asyncio

mcp = FastMCP("long-op-server")

@mcp.tool()
async def process_large_file(file_id: str) -> dict:
    """
    Process a large file (potentially long operation).
    """
    steps = [
        ("Reading file", 2),
        ("Parsing data", 3),
        ("Transforming", 5),
        ("Validating", 3),
        ("Storing results", 2),
    ]

    total_progress = 0
    for step_name, duration in steps:
        # Send progress notification
        # (MCP clients can reset timeout when receiving progress)
        mcp.send_progress(
            f"{step_name}... ({int(total_progress)}% complete)"
        )

        # Do the work
        await asyncio.sleep(duration)
        total_progress += (duration / 15) * 100

    return {
        "status": "complete",
        "file_id": file_id,
        "processed_rows": 10000
    }
```

### Deployment with Docker

**Dockerfile:**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server code
COPY server.py .

# Security: run as non-root
RUN useradd -m serveruser
USER serveruser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8000/health')" || exit 1

# Expose port (for HTTP servers)
EXPOSE 8000

# Run server with HTTP transport
CMD ["python", "server.py", "--host", "127.0.0.1", "--port", "8000"]
```

**Docker Compose (for multiple MCP servers + gateway):**

```yaml
version: '3.9'

services:
  mcp-gateway:
    image: docker.io/mcp-gateway:latest
    ports:
      - "8080:8080"
    environment:
      MCP_SERVERS: "weather,employees,github"
    depends_on:
      - weather-server
      - employees-server

  weather-server:
    build:
      context: ./services/weather
      dockerfile: Dockerfile
    environment:
      WEATHER_API_KEY: ${WEATHER_API_KEY}
    expose:
      - "8001"

  employees-server:
    build:
      context: ./services/employees
      dockerfile: Dockerfile
    environment:
      INTERNAL_API_TOKEN: ${INTERNAL_API_TOKEN}
      OAUTH_CLIENT_ID: ${OAUTH_CLIENT_ID}
      OAUTH_CLIENT_SECRET: ${OAUTH_CLIENT_SECRET}
    expose:
      - "8002"

  github-server:
    image: python:3.11-slim
    command: python -m pip install -q @modelcontextprotocol/server-github && \
             python -m modelcontextprotocol.server.github
    environment:
      GITHUB_TOKEN: ${GITHUB_TOKEN}
    expose:
      - "8003"
```

**Deploy to Kubernetes:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mcp-server
  template:
    metadata:
      labels:
        app: mcp-server
    spec:
      containers:
      - name: server
        image: company-registry/mcp-server:latest
        ports:
        - containerPort: 8000
        env:
        - name: OAUTH_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: mcp-secrets
              key: client-id
        - name: OAUTH_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: mcp-secrets
              key: client-secret
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 2
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

---

## 7. Advanced Patterns

### Streaming Responses for Large Operations

For operations that return large data, stream in chunks:

```python
from fastmcp import FastMCP
import asyncio

mcp = FastMCP("streaming-server")

@mcp.tool()
async def stream_large_dataset(table: str, batch_size: int = 1000) -> str:
    """
    Stream a large dataset in batches (avoids timeout on huge responses).

    Returns results line-by-line for incremental processing.
    """
    results = []

    for batch_num in range(1, 6):  # 5 batches simulated
        batch_data = [
            f'{{"id": {i}, "value": "record_{i}"}}'
            for i in range(batch_num * batch_size, (batch_num + 1) * batch_size)
        ]

        # Send progress (resets client timeout)
        mcp.send_progress(f"Fetched batch {batch_num}/5")

        results.extend(batch_data)
        await asyncio.sleep(1)  # Simulate work

    return "\n".join(results)
```

### Tool Composition (Tools Calling Tools)

Implement complex workflows by having tools call other tools:

```python
@mcp.tool()
async def approve_and_deploy(
    pull_request_id: str,
    target_environment: str = "staging"
) -> dict:
    """
    Complex workflow: approve PR → run tests → deploy.
    Internally calls other tools.
    """
    # Step 1: Get PR details
    pr_details = await get_pull_request(pull_request_id)

    # Step 2: Check if all required reviews are done
    if not pr_details["approved"]:
        raise ValueError(f"PR {pull_request_id} not approved by maintainers")

    # Step 3: Run tests
    test_result = await run_tests(pr_details["branch"])
    if not test_result["passed"]:
        raise ValueError(f"Tests failed on branch {pr_details['branch']}")

    # Step 4: Deploy
    deployment = await deploy_code(pr_details["branch"], target_environment)

    return {
        "pr_id": pull_request_id,
        "status": "deployed",
        "environment": target_environment,
        "deployment_id": deployment["id"],
        "url": deployment["url"]
    }
```

### Dynamic Tool Registration

Tools that appear/disappear based on context:

```python
@mcp.tool()
async def connect_to_database(db_host: str, db_name: str) -> dict:
    """
    Connect to a database and dynamically register tools for that DB.
    """
    # Connect
    connection = await establish_db_connection(db_host, db_name)

    # Register dynamic tools
    @mcp.tool(name=f"query_{db_name}")
    async def query_db(sql: str) -> list:
        """Execute SQL on the connected database."""
        return await connection.execute(sql)

    return {"status": "connected", "database": db_name}
```

### Caching for Reduced Latency

Cache expensive operations:

```python
from functools import lru_cache
import time

mcp = FastMCP("cached-server")

cache_timestamps = {}
CACHE_TTL = 300  # 5 minutes

@mcp.tool()
async def get_design_tokens() -> dict:
    """
    Get design system tokens (cached).
    """
    cache_key = "design_tokens"
    now = time.time()

    # Check cache validity
    if cache_key in cache_timestamps:
        if now - cache_timestamps[cache_key] < CACHE_TTL:
            return cached_tokens[cache_key]

    # Fetch fresh data
    tokens = await fetch_from_figma_api()

    # Store in cache
    cached_tokens[cache_key] = tokens
    cache_timestamps[cache_key] = now

    return tokens
```

### Connection Pooling for Database Servers

Reuse database connections across tool calls:

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

mcp = FastMCP("db-pool-server")

# Create connection pool
engine = create_async_engine(
    "postgresql+asyncpg://user:pass@host/db",
    pool_size=10,
    max_overflow=5
)

SessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

@mcp.tool()
async def query_database(sql: str) -> list:
    """
    Query database using pooled connection.
    """
    async with SessionLocal() as session:
        result = await session.execute(sql)
        return result.fetchall()
```

---

## 8. Real-World Examples

### Example 1: Internal API Server

**Use case:** Wrap your company's REST API so Claude can query employee data.

**File structure:**
```
internal-api-mcp/
├── server.py                 # Main MCP server
├── requirements.txt
├── Dockerfile
└── tests/
    └── test_server.py
```

**File: `server.py`**

```python
from fastmcp import FastMCP
import httpx
import os
from datetime import datetime

mcp = FastMCP("internal-api-server")

API_BASE = os.getenv("INTERNAL_API_BASE", "https://api.company.com")
API_TOKEN = os.getenv("INTERNAL_API_TOKEN")

headers = {"Authorization": f"Bearer {API_TOKEN}"}

@mcp.tool()
async def get_employee(employee_id: str) -> dict:
    """Get employee information by ID."""
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{API_BASE}/v1/employees/{employee_id}",
            headers=headers
        )
        resp.raise_for_status()
        return resp.json()

@mcp.tool()
async def list_employees_by_department(department: str) -> list:
    """List employees in a specific department."""
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{API_BASE}/v1/employees",
            headers=headers,
            params={"department": department}
        )
        resp.raise_for_status()
        return resp.json()

@mcp.tool()
async def search_employees(query: str) -> list:
    """Full-text search employees by name or email."""
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{API_BASE}/v1/employees/search",
            headers=headers,
            params={"q": query}
        )
        resp.raise_for_status()
        return resp.json()

@mcp.resource("api://departments")
def list_departments() -> str:
    """Available departments in the organization."""
    return "engineering, sales, marketing, human-resources, operations, finance"

@mcp.resource("api://help")
def api_help() -> str:
    """Help for the Internal API server."""
    return """
# Internal API MCP Server

Available tools:
- get_employee(employee_id) - Get details on a specific employee
- list_employees_by_department(department) - List all employees in a department
- search_employees(query) - Search employees by name or email

Available resources:
- api://departments - List of all departments

For more info on a specific employee, use get_employee().
"""

if __name__ == "__main__":
    mcp.run()
```

**Registration:**
```json
{
  "mcpServers": {
    "internal-api": {
      "command": "python",
      "args": ["/path/to/server.py"],
      "env": {
        "INTERNAL_API_BASE": "https://api.company.com",
        "INTERNAL_API_TOKEN": "your-token-here"
      }
    }
  }
}
```

**Usage in Claude Code:**
```
User: "How many engineers do we have in the company?"

Claude: I'll check the engineering department for you.
[calls list_employees_by_department("engineering")]

Claude: Based on the internal API, you have 47 engineers on staff.
```

### Example 2: Database Explorer Server

**Use case:** Give Claude read-only access to a Postgres database with schema awareness.

```python
from fastmcp import FastMCP
import asyncpg
import os
from typing import Optional

mcp = FastMCP("database-explorer")

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "analytics")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

pool = None

async def get_pool():
    global pool
    if pool is None:
        pool = await asyncpg.create_pool(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            min_size=5,
            max_size=10
        )
    return pool

@mcp.tool()
async def list_tables() -> list:
    """List all tables in the database."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        tables = await conn.fetch("""
            SELECT tablename FROM pg_tables
            WHERE schemaname = 'public'
            ORDER BY tablename
        """)
    return [t['tablename'] for t in tables]

@mcp.tool()
async def describe_table(table_name: str) -> dict:
    """Get schema information for a table."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        columns = await conn.fetch(f"""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_name = $1
            ORDER BY ordinal_position
        """, table_name)

    return {
        "table": table_name,
        "columns": [
            {
                "name": c['column_name'],
                "type": c['data_type'],
                "nullable": c['is_nullable'] == 'YES',
                "default": c['column_default']
            }
            for c in columns
        ]
    }

@mcp.tool()
async def query_table(
    table_name: str,
    limit: int = 10,
    where_clause: Optional[str] = None
) -> list:
    """
    Query a table with optional WHERE clause.

    Args:
        table_name: Name of the table to query
        limit: Maximum rows to return (max 1000)
        where_clause: Optional WHERE clause (e.g., "status = 'active'")
    """
    if limit > 1000:
        limit = 1000

    # Validate table name to prevent injection
    valid_tables = await list_tables()
    if table_name not in valid_tables:
        raise ValueError(f"Table {table_name} not found")

    query = f"SELECT * FROM {table_name}"
    if where_clause:
        query += f" WHERE {where_clause}"
    query += f" LIMIT {limit}"

    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(query)

    # Convert to list of dicts
    return [dict(row) for row in rows]

@mcp.tool()
async def run_custom_query(sql: str) -> list:
    """
    Run a custom SELECT query (read-only).

    **Important: Only SELECT queries are allowed.**
    """
    # Safety: only allow SELECT
    if not sql.strip().upper().startswith("SELECT"):
        raise ValueError("Only SELECT queries are allowed")

    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(sql)

    return [dict(row) for row in rows]

@mcp.resource("database://schema")
async def database_schema() -> str:
    """Complete database schema."""
    tables = await list_tables()
    schema_info = "# Database Schema\n\n"

    for table in tables:
        schema = await describe_table(table)
        schema_info += f"## {table}\n"
        for col in schema['columns']:
            schema_info += f"- {col['name']}: {col['type']}"
            if not col['nullable']:
                schema_info += " (NOT NULL)"
            schema_info += "\n"
        schema_info += "\n"

    return schema_info

if __name__ == "__main__":
    mcp.run()
```

**Usage:**
```
User: "What are our monthly revenue trends?"

Claude: Let me explore the database structure first.
[calls list_tables()]

Claude: I see a 'revenue' table. Let me get the schema.
[calls describe_table("revenue")]

Claude: Now I'll query the revenue data:
[calls run_custom_query("SELECT DATE(date), SUM(amount) FROM revenue GROUP BY DATE(date) ORDER BY date DESC LIMIT 12")]

Claude: Based on the data, here are the monthly revenue trends...
```

### Example 3: Custom Documentation Server

**Use case:** Serve project documentation optimized for LLM consumption.

```python
from fastmcp import FastMCP
from pathlib import Path
import os

mcp = FastMCP("docs-server")

DOCS_ROOT = Path(os.getenv("DOCS_ROOT", "./docs"))

@mcp.tool()
def list_docs() -> list:
    """List all available documentation."""
    docs = []
    for doc_file in DOCS_ROOT.glob("**/*.md"):
        relative_path = doc_file.relative_to(DOCS_ROOT)
        docs.append({
            "path": str(relative_path),
            "title": doc_file.stem,
            "size_kb": doc_file.stat().st_size / 1024
        })
    return sorted(docs, key=lambda x: x['path'])

@mcp.tool()
def get_doc(doc_path: str) -> str:
    """Get the full content of a documentation file."""
    # Prevent path traversal
    full_path = (DOCS_ROOT / doc_path).resolve()
    if not str(full_path).startswith(str(DOCS_ROOT.resolve())):
        raise ValueError("Access denied")

    if not full_path.exists():
        raise FileNotFoundError(f"Documentation not found: {doc_path}")

    return full_path.read_text()

@mcp.tool()
def search_docs(query: str) -> list:
    """Search documentation by keyword."""
    query_lower = query.lower()
    results = []

    for doc_file in DOCS_ROOT.glob("**/*.md"):
        content = doc_file.read_text().lower()
        if query_lower in content:
            # Count occurrences and find context
            count = content.count(query_lower)
            results.append({
                "path": str(doc_file.relative_to(DOCS_ROOT)),
                "title": doc_file.stem,
                "matches": count
            })

    return sorted(results, key=lambda x: x['matches'], reverse=True)

@mcp.resource("docs://architecture")
def architecture_overview() -> str:
    """Overview of the system architecture."""
    return (DOCS_ROOT / "architecture" / "overview.md").read_text()

@mcp.resource("docs://api")
def api_reference() -> str:
    """API reference guide."""
    return (DOCS_ROOT / "api" / "reference.md").read_text()

if __name__ == "__main__":
    mcp.run()
```

---

## 9. Debugging & Troubleshooting

### Using MCP Inspector

The MCP Inspector is a visual debugging tool (like Postman for MCP).

**Start Inspector for a local server:**

```bash
# For a Python server
npx @modelcontextprotocol/inspector python server.py

# For a Node.js server
npx @modelcontextprotocol/inspector node build/index.js

# For a server installed via npm
npx @modelcontextprotocol/inspector npx @modelcontextprotocol/server-github
```

This opens a web UI at `http://localhost:6274` showing:
- List of available tools and their schemas
- Interactive tool tester (call tools with parameters)
- Real request/response JSON
- Connection status and errors

**Connect to a remote server:**

```bash
npx @modelcontextprotocol/inspector --connect https://api.example.com/mcp/sse \
  --bearer-token your-oauth-token
```

### Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Request timeout (-32001)` | Tool takes > 60s (TS) or operation too large | Use streaming, pagination, or progress notifications |
| `Tool not found` | Tools not properly registered | Ensure `@mcp.tool()` decorator is used correctly; restart server |
| `Schema validation failed` | Input doesn't match JSON Schema | Check tool definition schema; validate inputs before calling |
| `Authentication failed` | Invalid OAuth token or missing credentials | Verify token is valid; check environment variables |
| `Connection refused` | Server not running or wrong port | Start server first; verify host/port in config |
| `Path traversal detected` | File access outside allowed directory | Use `Path.resolve()` and verify paths are within base |

### Logging Best Practices

```python
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stderr  # Log to stderr, not stdout (which is for JSON-RPC)
)

logger = logging.getLogger(__name__)

@mcp.tool()
async def example_tool(param: str) -> str:
    """Tool with logging."""
    logger.info(f"Tool called with param: {param}")

    try:
        result = await do_work(param)
        logger.info(f"Tool succeeded, returning: {result}")
        return result
    except Exception as e:
        logger.error(f"Tool failed: {e}", exc_info=True)
        raise
```

### Debugging Tool Discovery Issues

If Claude Code doesn't show your tools:

1. **Verify server is running:**
   ```bash
   npx @modelcontextprotocol/inspector python server.py
   ```

2. **Check configuration:**
   - Inspect `~/.claude/claude_desktop_config.json`
   - Ensure command and args are correct
   - Restart Claude Code

3. **Verify tools are registered:**
   ```python
   # In your server, inspect what gets advertised
   @mcp.tool()
   def test_tool() -> str:
       return "If you see this, tool registration works"
   ```

4. **Check for syntax errors:**
   ```bash
   python -m py_compile server.py
   ```

### Performance Debugging

**Slow tools:**

```python
import time
from functools import wraps

def log_performance(f):
    @wraps(f)
    async def wrapper(*args, **kwargs):
        start = time.time()
        result = await f(*args, **kwargs)
        elapsed = time.time() - start
        logger.info(f"{f.__name__} took {elapsed:.2f}s")
        return result
    return wrapper

@mcp.tool()
@log_performance
async def slow_operation():
    # Will log execution time
    pass
```

---

## 10. Production Readiness Checklist

Use this checklist before deploying an MCP server to production:

### Security
- [ ] All API tokens/secrets stored in environment variables (not code)
- [ ] OAuth 2.1 configured for HTTP servers
- [ ] Input validation enforced (JSON Schema + Pydantic)
- [ ] Path sanitization for file operations (no directory traversal)
- [ ] Rate limiting implemented
- [ ] HTTP servers require authentication (never bind to 0.0.0.0 without auth)
- [ ] Error messages don't leak sensitive info
- [ ] Dependencies scanned for vulnerabilities (`pip audit`, `npm audit`)
- [ ] MCP governance policy in place (inventory of servers, security team visibility — Qualys warns of MCP as "shadow IT")
- [ ] Consider MCP Policy Controls (e.g., SurePath AI) for enterprise environments to restrict which servers/tools agents can access

### Reliability
- [ ] Timeouts configured (10-30 seconds typical)
- [ ] Progress notifications for long operations (>5 seconds)
- [ ] Graceful error handling (no unhandled exceptions)
- [ ] Retry logic for external API calls
- [ ] Connection pooling for databases
- [ ] Health check endpoint (/health, /ready)
- [ ] Logging configured (to stderr, not stdout)

### Testing
- [ ] Unit tests for tools (with mocked API calls)
- [ ] Integration tests (tools talking to real dependencies)
- [ ] MCP Inspector tested
- [ ] Tool schema validated against actual responses
- [ ] Error cases tested (timeout, missing auth, invalid input)
- [ ] Load tested (handle concurrent tool calls)

### Deployment
- [ ] Dockerfile created and tested locally
- [ ] Docker image scanned for vulnerabilities
- [ ] Environment variables documented
- [ ] Health checks configured
- [ ] Resource limits set (memory, CPU)
- [ ] Deployment tested in staging
- [ ] Rollback plan documented
- [ ] Monitoring/alerting configured
- [ ] Database migrations ready (if applicable)

### Documentation
- [ ] Tool descriptions clear and accurate
- [ ] Resource URIs documented
- [ ] Prompt templates documented
- [ ] Setup instructions for developers
- [ ] API authentication requirements documented
- [ ] Known limitations documented
- [ ] Troubleshooting guide written

### Performance
- [ ] Response times measured (<5s for typical operations)
- [ ] Context size optimized (use resources, not tools, for static data)
- [ ] Database queries indexed
- [ ] Caching implemented where appropriate
- [ ] Streaming used for large responses
- [ ] Rate limiting tuned

### Operations
- [ ] Logs monitored for errors
- [ ] Version strategy defined (semver, Docker tag strategy)
- [ ] Changelog maintained
- [ ] Deprecation policy documented
- [ ] Support contact/channel documented
- [ ] Incident response plan documented

---

## Sources

### Official Documentation
- [Model Context Protocol Specification (2025-06-18)](https://modelcontextprotocol.io/specification/2025-06-18)
- [Build an MCP Server (Official Docs)](https://modelcontextprotocol.io/docs/develop/build-server)
- [Model Context Protocol GitHub (Official Organization)](https://github.com/modelcontextprotocol)
- [Understanding Authorization in MCP](https://modelcontextprotocol.io/docs/tutorials/security/authorization)
- [MCP Inspector Documentation](https://modelcontextprotocol.io/docs/tools/inspector)

### FastMCP Framework
- [FastMCP GitHub Repository](https://github.com/jlowin/fastmcp)
- [FastMCP: The Pythonic Way to Build MCP Servers (KDnuggets)](https://www.kdnuggets.com/fastmcp-the-pythonic-way-to-build-mcp-servers-and-clients)
- [Build MCP Servers in Python with FastMCP (MCPcat)](https://mcpcat.io/guides/building-mcp-server-python-fastmcp/)
- [FastMCP Tutorial for AI Developers (Firecrawl)](https://www.firecrawl.dev/blog/fastmcp-tutorial-building-mcp-servers-python)
- [How to Build Your First MCP Server using FastMCP (FreeCodeCamp)](https://www.freecodecamp.org/news/how-to-build-your-first-mcp-server-using-fastmcp/)

### TypeScript/JavaScript SDK
- [Model Context Protocol TypeScript SDK (GitHub)](https://github.com/modelcontextprotocol/typescript-sdk)
- [@modelcontextprotocol/sdk (npm)](https://www.npmjs.com/package/@modelcontextprotocol/sdk)
- [How to Build MCP Servers with TypeScript SDK (DEV Community)](https://dev.to/shadid12/how-to-build-mcp-servers-with-typescript-sdk-1c28)
- [Build & Test MCP Server with TypeScript (Hackteam)](https://hackteam.io/blog/build-test-mcp-server-typescript-mcp-inspector/)

### Security & Best Practices
- [OWASP Gen AI Security: MCP Security Guide](https://genai.owasp.org/resource/a-practical-guide-for-secure-mcp-server-development/)
- [MCP Server Security Best Practices (Descope)](https://www.descope.com/blog/post/mcp-server-security-best-practices)
- [MCP OAuth 2.1 Implementation Guide (MCP Server Spot)](https://www.mcpserverspot.com/learn/architecture/mcp-oauth-implementation-guide)
- [MCP Security: NeighborJack Attack & Auth (Medium)](https://medium.com/data-science-collective/why-your-mcp-server-is-a-security-disaster-waiting-to-happen-660577d8077c)
- [Secure MCP Servers with OAuth 2.1 (Scalekit)](https://www.scalekit.com/blog/implement-oauth-for-mcp-servers)
- [Protecting MCP with OAuth 2.1 Using Go & Keycloak (Medium)](https://medium.com/@wadahiro/protecting-mcp-server-with-oauth-2-1-a-practical-guide-using-go-and-keycloak-7544eb5379d3)

### Deployment & Docker
- [How to Build and Deliver MCP Servers for Production (Docker)](https://www.docker.com/blog/build-to-prod-mcp-servers-with-docker/)
- [Docker MCP Toolkit (Docker)](https://www.docker.com/blog/mcp-toolkit-mcp-servers-that-just-work/)
- [Docker MCP Tutorial (GitHub - NetworkChuck)](https://github.com/theNetworkChuck/docker-mcp-tutorial)
- [How to Build and Deploy MCP Server (Northflank)](https://northflank.com/blog/how-to-build-and-deploy-a-model-context-protocol-mcp-server/)
- [Scaling AI Agents with Docker MCP Gateway (dasroot)](https://dasroot.net/posts/2026/03/scaling-ai-agents-docker-mcp-gateway-docker-offload/)

### Wrapping APIs & OpenAPI
- [From REST API to MCP Server (Stainless)](https://www.stainless.com/mcp/from-rest-api-to-mcp-server)
- [Should You Wrap MCP Around Your Existing API? (Scalekit)](https://www.scalekit.com/blog/wrap-mcp-around-existing-api)
- [OpenAPI + FastMCP Integration (FastMCP Docs)](https://gofastmcp.com/integrations/openapi/)
- [Building MCP Servers for ChatGPT (OpenAI Developers)](https://developers.openai.com/api/docs/mcp)
- [Turn Any REST API into MCP Server (Gravitee)](https://www.gravitee.io/blog/turn-any-rest-api-into-mcp-server-inside-gravitee)

### Testing & Debugging
- [MCP Inspector Setup Guide (MCPcat)](https://mcpcat.io/guides/setting-up-mcp-inspector-server-testing/)
- [MCP Inspector — Testing & Debugging (Stainless)](https://www.stainless.com/mcp/mcp-inspector-testing-and-debugging-mcp-servers)
- [Testing & Debugging MCP Servers (Medium, Jan 2026)](https://medium.com/@alessandro.a.pagliaro/hello-mcp-debugging-and-testing-f1da3b0e9288)
- [Testing MCP Servers with Inspector (MyDeveloperPlanet)](https://mydeveloperplanet.com/2025/12/01/testing-mcp-servers-with-mcp-inspector/)

### Primitives & Architecture
- [Exploring MCP Primitives: Tools, Resources, Prompts (CodeSignal)](https://codesignal.com/learn/courses/developing-and-integrating-a-mcp-server-in-python/lessons/exploring-and-exposing-mcp-server-capabilities-tools-resources-and-prompts)
- [MCP Architecture Deep Dive: Tools, Resources, Prompts (Knit)](https://www.getknit.dev/blog/mcp-architecture-deep-dive-tools-resources-and-prompts-explained)
- [How to Effectively Use Prompts, Resources, Tools (Composio)](https://composio.dev/content/how-to-effectively-use-prompts-resources-and-tools-in-mcp)
- [MCP Resources Explained (Medium - Laurent Kubaski)](https://medium.com/@laurentkubaski/mcp-resources-explained-and-how-they-differ-from-mcp-tools-096f9d15f767)
- [Demystifying Resources vs Tools (Medium - ramwert)](https://ramwert.medium.com/mcp-demystifying-mcp-resources-vs-tools-a-practical-guide-for-agentic-automation-cb07fcb82241)

### JSON Schema & Validation
- [MCP JSON Schema Validation: Tools & Best Practices (BytePlus)](https://www.byteplus.com/en/topic/542256)
- [MCP Tool Schema: What It Is, How It Works (Merge.dev)](https://www.merge.dev/blog/mcp-tool-schema)
- [JSON Schema Validator MCP (GitHub - EienWolf)](https://github.com/EienWolf/jsonshema_mcp)

### Timeout & Performance
- [Fix MCP Error -32001: Request Timeout (MCPcat)](https://mcpcat.io/guides/fixing-mcp-error-32001-request-timeout/)
- [Handling Timeouts with Long-Running MCP Connectors (OpenAI Community)](https://community.openai.com/t/handling-timeouts-with-long-running-mcp-connectors-vertex-ai-agent/1369341)
- [MCP Streaming Responses: Guide & Best Practices (BytePlus)](https://www.byteplus.com/en/topic/541918)

### Tutorials & Guides
- [How to Build an MCP Server (Step-by-Step, 2026 - Leanware)](https://www.leanware.co/insights/how-to-build-mcp-server)
- [How to Build an MCP Server in Python (15 Minutes - Medium)](https://medium.com/data-science-collective/build-your-first-mcp-server-in-15-minutes-complete-code-d63f85c0ce79)
- [MCP Server Step-by-Step Guide from Scratch (Composio)](https://composio.dev/content/mcp-server-step-by-step-guide-to-building-from-scrtch)
- [Complete MCP Tutorial for Beginners (Codecademy)](https://www.codecademy.com/article/build-an-mcp-server)
- [How to Build Your Own MCP Server (builder.io)](https://www.builder.io/blog/mcp-server)
- [Build and Deploy Custom MCP Server (Clarifai)](https://www.clarifai.com/blog/build-and-deploy-a-custom-mcp-server-from-scratch)

---

**Last Updated:** 2026-03-18
**Confidence Level:** High (based on official docs, security research, production case studies, and 2025-2026 web research)
**Next Review:** 2026-06-18 (security updates, new patterns, framework changes)

---

## Related Topics

- [Best Repos, Skills, Plugins, MCPs](best-repos-skills-plugins-mcps.md) — Discovering and evaluating existing MCPs before building custom ones
- [AI-Native Architecture](ai-native-architecture.md) — Using MCPs as building blocks in agent systems

---

## Changelog
| Date | Change | Source |
|------|--------|--------|
| 2026-03-20 | Added MCP 2026 roadmap details (Tasks primitive, Streamable HTTP scaling, enterprise readiness with audit trails/SSO, registry metadata format). Added MCP governance note: Qualys TotalAI labels MCP servers as "shadow IT" for AI; SurePath AI launched MCP Policy Controls (March 12) for real-time server/tool access control. Added Perplexity CTO's MCP context consumption critique (40-50% of context window). Updated security checklist with governance policy item. | Daily briefing 2026-03-20 findings #1 and #2 |
- [AI-Assisted API Design](ai-assisted-api-design.md) — Designing APIs that work well with AI agents via MCPs
