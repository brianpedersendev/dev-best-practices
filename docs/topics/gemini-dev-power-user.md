# Google Gemini as a Power-User Developer Tool (2026)

**Date:** 2026-03-18
**Status:** Production-Ready Reference
**Audience:** Developers, AI engineers, technical architects

---

## Executive Summary

Google Gemini in 2026 is a mature, multi-faceted platform for AI-augmented development. Key strengths: native multimodal support (text, image, audio, video), industry-leading 2M context window, deeply integrated Google ecosystem tooling, and significant cost advantages over competitors. Weakness: tool ecosystem maturity lags Claude/OpenAI in some areas, but MCP support and ADK framework are rapidly closing the gap.

**Best for:**
- Multimodal analysis (video, audio transcription, image understanding)
- Large-context code analysis (2M tokens default on Gemini 1.5 Pro)
- Projects tightly integrated with Google Cloud/Firebase/Workspace
- Cost-sensitive teams needing powerful models at 7x lower API cost than Claude Opus
- Spec-driven and test-driven development workflows

---

## 1. Gemini CLI: Terminal-First Development Agent

### Overview
The Gemini CLI is a production-ready, open-source agent that runs in your terminal with native support for Model Context Protocol (MCP), built-in tools, and project-level configuration.

**Latest Version:** v0.32.1 (March 2026)
**Repository:** [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)
**Status:** Generally Available

### Installation

#### Via NPM (Recommended)
```bash
# Requires Node.js 20+
npm install -g @google/gemini-cli

# Verify installation
gemini --version
```

#### Via Conda
```bash
conda create -y -n gemini_env -c conda-forge nodejs
conda activate gemini_env
npm install -g @google/gemini-cli
```

#### Quick Start (No Installation)
```bash
npx @google/gemini-cli chat
```

### Authentication
```bash
# First run triggers automatic browser OAuth flow
gemini chat

# No manual API key management needed
# OAuth token stored locally and auto-refreshed
# 60 requests/min, 1,000 requests/day (free tier)
```

### Project Configuration

Create `.gemini/config.yaml` or `GEMINI.md` in your project root:

```yaml
# .gemini/config.yaml
context:
  techStack: ["TypeScript", "Next.js", "PostgreSQL"]
  codeStandards:
    - "Use async/await, not callbacks"
    - "Enforce ESLint strict mode"
    - "Write JSDoc for all exports"
  projectRules:
    - "All functions must have unit tests"
    - "No console.log in production"

tools:
  # MCP servers to load
  - type: mcp
    uri: "stdio://go"
    name: "filesystem"
```

Or as Markdown in `GEMINI.md`:

```markdown
# Project Context for Gemini CLI

## Tech Stack
- TypeScript 5.x, React 19
- Vitest + Testing Library
- Tailwind CSS

## Coding Standards
- All public APIs require JSDoc comments
- Maximum function length: 50 lines
- All async operations must include timeout handling

## Build & Test
Run tests: `npm test`
Build: `npm run build`
```

### Core Commands & Workflows

#### Agentic Code Generation
```bash
# Ask Gemini to implement a feature, run tests, open PR
gemini chat "Implement user authentication with OAuth2. Create tests. Open a PR."
```

The CLI will:
1. Generate code based on project context
2. Run tests automatically (using build config)
3. Open a pull request if git is configured

#### Bug Fix Workflow
```bash
gemini chat "Fix the failing test in src/auth.test.ts. Explain the root cause."
```

#### Code Review & Refactor
```bash
gemini chat "Review src/components/Form.tsx for performance and accessibility."
```

#### Documentation Generation
```bash
gemini chat "Generate API documentation for all exports in src/api/"
```

### MCP Server Integration

Gemini CLI seamlessly integrates with FastMCP-based servers:

```bash
# Add an MCP server to your project
gemini config add-mcp stdio://python ./my_mcp_server.py

# List connected MCP servers
gemini config list-mcp
```

**Available Managed MCP Servers (via Google Cloud):**
- BigQuery (data analysis)
- Cloud Storage (file operations)
- Cloud Run (deployment management)
- Google Maps (location grounding)
- Cloud Resource Manager
- Coming soon: Compute Engine, Cloud SQL, AlloyDB, Looker, Pub/Sub

### Using Built-in Tools

```bash
# The CLI automatically uses available tools in ReAct loops
gemini chat "Generate a CSV report from the data in my Cloud Storage bucket"
```

The agent will:
1. Recognize the need for Cloud Storage tool
2. Call the MCP server to list/read files
3. Process and format data
4. Return results

### Policy Engine for Tool Governance

Create custom policies to control what tools the agent can use:

```toml
# ~/.gemini/policies/dev-policy.toml
[allow]
tools = ["filesystem", "code_execution"]

[deny]
tools = ["delete_production_data"]

[require_approval]
tools = ["external_api_calls"]

[rate_limit]
tools = { "web_search" = "10/hour" }
```

### Comparison: Gemini CLI vs Claude Code

| Feature | Gemini CLI | Claude Code |
|---------|-----------|------------|
| **MCP Support** | ✓ Full, native | ✓ Full, native |
| **Cost** | Free tier (1K req/day) | CLI only via subscriptions |
| **Tool Ecosystem** | Google services + FastMCP | Anthropic + fastMCP |
| **Terminal-First** | ✓ Primary interface | ✓ Native |
| **IDE Integration** | IDE extensions available | Native in VS Code |
| **Context Window** | 1M (free), 2M (paid) | 200K standard, 1M beta |
| **Multimodal** | ✓ Video, audio, images | ✓ Images only |
| **Learning Curve** | Moderate | Moderate |

---

## 2. Gemini Code Assist in IDEs

### Overview
Code Assist brings Gemini directly into your IDE with real-time completions, generation, transformation, and agentic workflows.

### IDE Support Matrix (2026)

**VS Code:**
- Extension: [Gemini Code Assist](https://marketplace.visualstudio.com/items?itemName=Google.genai)
- Features: Inline completions, chat, commit message generation
- Tiers: Free, Standard (pay-as-you-go), Enterprise

**JetBrains IDEs** (IntelliJ IDEA, PyCharm, WebStorm, CLion, etc.):
- Plugin: [Gemini Code Assist](https://plugins.jetbrains.com/plugin/24198-gemini-code-assist)
- Features: All of VS Code + IDE-native features
- Integrated into native Commit dialog

**Android Studio:**
- Native integration with Agent mode
- MCP support for external tools
- Testing and Logcat integration

### Installation & Setup

#### VS Code
```bash
# 1. Install extension
# Search "Gemini Code Assist" in Extensions panel

# 2. Sign in with Google account
# Click "Sign In" in extension panel

# 3. Enable features in settings
# Inline completions: Editor > Inlinecompletion Enabled
```

#### JetBrains IDEs
```
# 1. Settings > Plugins > Marketplace
# 2. Search "Gemini Code Assist"
# 3. Install and restart IDE
# 4. Authenticate via Google OAuth
```

### Key Features & Workflows

#### 1. Inline Code Completions

```python
# Type a comment, Gemini predicts the next code block
# def calculate_fibonacci(n: int) -> list[int]:
#     """Generate first n Fibonacci numbers"""

# Gemini suggests:
def calculate_fibonacci(n: int) -> list[int]:
    """Generate first n Fibonacci numbers"""
    if n <= 0:
        return []
    elif n == 1:
        return [0]

    fib = [0, 1]
    for i in range(2, n):
        fib.append(fib[i-1] + fib[i-2])
    return fib[:n]
```

Press `Tab` to accept, or `Esc` to reject.

#### 2. Generate Functions from Comments

```typescript
// Convert natural language comment to full function
// Helper function that takes a filename and returns the extension

// Gemini generates:
function getFileExtension(filename: string): string {
    const lastDotIndex = filename.lastIndexOf('.');
    return lastDotIndex === -1 ? '' : filename.substring(lastDotIndex + 1);
}
```

#### 3. Code Transformation Commands

Open the command palette (`Cmd+Shift+P` / `Ctrl+Shift+P`):

```
Gemini: Fix
# Analyzes errors and applies fixes automatically

Gemini: Generate
# Generates code from natural language intent

Gemini: Document
# Adds JSDoc/docstrings to functions and classes

Gemini: Refactor
# Suggests and applies refactorings
```

#### 4. Next Edit Predictions (Preview)

Gemini predicts your next edit based on code patterns:
- After you complete a function, it suggests the next one
- After one test, it scaffolds similar tests
- Available in both IntelliJ and VS Code (preview)

#### 5. Chat Interface

Open Chat panel (`Cmd+I` / `Ctrl+I`):

```
User: Add comprehensive error handling to this function
Gemini: [Rewrites function with try-catch, proper logging, and specific error types]

User: Generate unit tests for this component
Gemini: [Creates full test suite with edge cases]

User: Review this code for security issues
Gemini: [Identifies XSS, SQL injection, CSRF vulnerabilities]
```

#### 6. Commit Message Generation

**JetBrains:**
In the Commit dialog, click "Generate with Gemini" button.

```
Staged changes: Modified auth.ts, added oauth.ts
↓ (Gemini analyzes diffs)
Generated: "feat: implement OAuth2 authentication flow with Google provider"
```

### Repository Indexing for Agentic Workflows

**Standard & Enterprise Tiers:**

Enable full repository indexing to give Gemini context of your entire codebase:

```yaml
# .gemini/code-assist.yaml
indexing:
  enabled: true
  includePatterns:
    - "src/**/*.{ts,tsx,js}"
    - "lib/**/*.{ts,tsx,js}"
  excludePatterns:
    - "node_modules"
    - "dist"
    - "*.test.ts"

integrations:
  - type: bigquery
    projectId: my-gcp-project
  - type: github
    repo: org/repo
```

With indexing, you can ask:

```
"Implement a new feature to export reports as CSV.
 Use the same pattern as the existing PDF export in ReportService.
 Run all tests and open a pull request."
```

Gemini will:
1. Index the entire `src/` directory
2. Find the PDF export pattern
3. Implement CSV export consistently
4. Generate tests matching your test patterns
5. Run the full test suite
6. Create and push a PR

---

## 3. Google Agent Development Kit (ADK)

### Overview
ADK is a production-ready, open-source framework for building multi-agent systems with tool use, MCP integration, and enterprise governance.

**Latest:** Python & TypeScript versions GA, Java in development
**Repository:** [google/adk-python](https://github.com/google/adk-python)
**Status:** 7M+ downloads (2026)

### Quick Start: Single Agent

```python
# pip install google-ai-agents

from google_ai_agents import Agent
from google_ai_agents.tools import web_search, code_execution
import google.genai as genai

genai.configure(api_key="YOUR_API_KEY")

# Create a single agent
agent = Agent(
    model="gemini-3-pro",
    tools=[web_search, code_execution],
    instructions="You are a helpful coding assistant."
)

# Run the agent
response = agent.run("Fix the bug in this React component")
print(response)
```

### Multi-Agent Architecture

```python
from google_ai_agents import Agent, Router
from google_ai_agents.tools import web_search, code_execution, bigquery_tool

# Define specialized agents
research_agent = Agent(
    name="researcher",
    model="gemini-3-pro",
    tools=[web_search],
    instructions="Research technical topics and summarize findings."
)

engineer_agent = Agent(
    name="engineer",
    model="gemini-3-pro",
    tools=[code_execution],
    instructions="Implement solutions based on research."
)

documentation_agent = Agent(
    name="documentarian",
    model="gemini-3-pro",
    instructions="Write clear documentation."
)

# Create a router to orchestrate agents
router = Router(
    agents=[research_agent, engineer_agent, documentation_agent],
    model="gemini-3-pro",
    instructions="""
    You are the orchestrator. Route tasks to appropriate agents:
    - Research and learning → researcher
    - Code implementation → engineer
    - Documentation → documentarian
    """
)

# Run multi-agent workflow
result = router.run(
    "Create a blog post about building AI agents. "
    "Research the topic, implement an example, and document it."
)
```

### Tool Integration: Custom Tools + MCP

```python
from google_ai_agents import Agent, MCPServerTool
from google_ai_agents.tools import web_search

# Define a custom tool
def calculate_metrics(data: list[float]) -> dict:
    """Calculate statistics on numeric data."""
    return {
        "mean": sum(data) / len(data),
        "max": max(data),
        "min": min(data)
    }

# Add MCP server for external tools
mcp_tool = MCPServerTool(
    uri="stdio://python",
    module_path="./custom_mcp_server.py"
)

agent = Agent(
    model="gemini-3-pro",
    tools=[
        web_search,
        custom_tool(calculate_metrics),
        mcp_tool
    ]
)

response = agent.run("Analyze this data and create a report")
```

### Structured Output with Pydantic

```python
from google_ai_agents import Agent
from pydantic import BaseModel

class CodeReview(BaseModel):
    issues: list[str]
    severity: list[str]  # "critical", "warning", "info"
    suggestions: list[str]
    overall_score: float  # 0-100

agent = Agent(
    model="gemini-3-pro",
    output_schema=CodeReview,
    instructions="Review code and return structured findings."
)

review = agent.run("Review this function for bugs and performance issues")
# Returns CodeReview object with type safety
```

### Agent Evaluation & Testing

```python
from google_ai_agents import Agent, Evaluator

agent = Agent(
    model="gemini-3-pro",
    tools=[web_search, code_execution]
)

evaluator = Evaluator(
    agent=agent,
    metric="code_correctness"
)

test_cases = [
    {
        "input": "Implement a binary search function",
        "expected_output": "A correct, efficient binary search implementation"
    },
    {
        "input": "Debug this: function always returns undefined",
        "expected_output": "Root cause identified and fix provided"
    }
]

results = evaluator.run(test_cases)
print(f"Success rate: {results.success_rate}%")
print(f"Average latency: {results.avg_latency}ms")
```

### Deployment: Cloud Run

```bash
# ADK apps deploy easily to Cloud Run
gcloud run deploy my-agent \
    --source . \
    --platform managed \
    --region us-central1 \
    --set-env-vars GEMINI_API_KEY=$GEMINI_API_KEY
```

Your agent becomes an HTTP endpoint:
```bash
curl -X POST https://my-agent-xxx.run.app \
    -H "Content-Type: application/json" \
    -d '{"input": "Implement a feature"}'
```

---

## 4. Gemini API: Advanced Development Patterns

### Core Capabilities (2026)

| Feature | Details |
|---------|---------|
| **Context Window** | Gemini 1.5 Pro: 2M tokens (largest), Gemini 3 Pro: 1M, Gemini 3 Flash: 200K |
| **Output Length** | Gemini 3 Pro: 65K tokens, Claude Opus 4.6: 128K (2x larger) |
| **Structured Outputs** | JSON Schema support, Pydantic integration |
| **Function Calling** | OpenAPI-like schemas, multi-tool combos |
| **Grounding** | Google Search, Google Maps, URL context, Custom Search |
| **Multimodal Input** | Text, images, video, audio (all natively) |
| **Pricing** | $2/$12 per 1M tokens (vs Claude Opus: $15/$75) |

### Installation & Authentication

```bash
# Install Python SDK
pip install google-generativeai

# Or Node.js
npm install @google/generative-ai
```

```python
import google.generativeai as genai
genai.configure(api_key="YOUR_API_KEY")
```

### Pattern 1: Structured Output with JSON Schema

```python
import google.generativeai as genai
from pydantic import BaseModel, Field

class BlogPost(BaseModel):
    title: str = Field(description="Post title")
    sections: list[str] = Field(description="Section headings")
    summary: str = Field(description="100-word summary")
    tags: list[str] = Field(description="Relevant tags")

model = genai.GenerativeModel("gemini-3-pro")

response = model.generate_content(
    "Write a blog post about agent architectures",
    generation_config=genai.types.GenerationConfig(
        response_schema=BlogPost,
        response_mime_type="application/json"
    )
)

# Parse automatically
blog = BlogPost.model_validate_json(response.text)
print(blog.title)
print(blog.sections)
```

### Pattern 2: Function Calling with Tool Combos

```python
import json

# Define tools
tools = {
    "search_docs": {
        "type": "function",
        "function": {
            "name": "search_documentation",
            "description": "Search technical documentation",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string"},
                    "language": {"type": "string", "enum": ["python", "typescript", "go"]}
                },
                "required": ["query"]
            }
        }
    },
    "execute_code": {
        "type": "function",
        "function": {
            "name": "run_python_code",
            "description": "Execute Python code and return output",
            "parameters": {
                "type": "object",
                "properties": {
                    "code": {"type": "string"}
                },
                "required": ["code"]
            }
        }
    }
}

# Mock implementations
def search_documentation(query: str, language: str = None) -> str:
    return f"Found docs for {query} in {language}"

def run_python_code(code: str) -> str:
    import subprocess
    result = subprocess.run(["python", "-c", code], capture_output=True, text=True)
    return result.stdout or result.stderr

# Create model with tools
model = genai.GenerativeModel("gemini-3-pro")

# Initial request
response = model.generate_content(
    "How do I implement async/await in Python? Show me a working example.",
    tools=tools
)

# Process tool calls
while response.candidates[0].content.parts[-1].function_call:
    tool_call = response.candidates[0].content.parts[-1].function_call

    if tool_call.name == "search_documentation":
        result = search_documentation(**tool_call.args)
    elif tool_call.name == "run_python_code":
        result = run_python_code(**tool_call.args)

    # Continue conversation with tool results
    response = model.generate_content([
        *response.candidates[0].content.parts,
        {"function_response": {"name": tool_call.name, "response": result}}
    ])

print(response.text)
```

### Pattern 3: Grounding with Google Search

```python
# Enable grounding with Google Search
tools = [
    genai.Tool(
        google_search_retrieval=genai.types.GoogleSearchRetrieval()
    )
]

model = genai.GenerativeModel(
    "gemini-3-pro",
    tools=tools
)

response = model.generate_content(
    "What are the latest developments in AI safety regulations in 2026?"
)

# Response includes citations
for citation in response.candidates[0].grounding_metadata.retrieval_queries:
    print(f"Source: {citation}")

print(response.text)
```

### Pattern 4: Large Context Analysis (2M Tokens)

```python
# Use Gemini 1.5 Pro for massive files
import base64

# Load a large codebase or document (up to 2M tokens)
with open("large_codebase.zip", "rb") as f:
    file_data = base64.standard_b64encode(f.read()).decode("utf-8")

model = genai.GenerativeModel("gemini-1-5-pro")

response = model.generate_content([
    "Analyze this entire codebase and identify:",
    "1. Architecture patterns used",
    "2. Code quality issues",
    "3. Security vulnerabilities",
    "4. Refactoring opportunities",
    {
        "mime_type": "application/zip",
        "data": file_data
    }
])

print(response.text)
```

### Pattern 5: Video Analysis (Multimodal)

```python
import google.generativeai as genai

# Gemini can analyze video natively
video_file = genai.upload_file(path="demo_video.mp4")

model = genai.GenerativeModel("gemini-3-pro")

response = model.generate_content([
    "Analyze this demo video:",
    "1. What's the main product/feature being demonstrated?",
    "2. What problems does it solve?",
    "3. Generate a script for narration",
    "4. Create social media captions",
    video_file
])

print(response.text)
```

### Cost Optimization: Token Counting

```python
model = genai.GenerativeModel("gemini-3-pro")

# Count tokens before sending
prompt = "Generate a 5000-word essay on AI ethics"
count = model.count_tokens(prompt)
print(f"Input tokens: {count.total_tokens}")
print(f"Estimated cost: ${count.total_tokens * 2 / 1_000_000:.4f}")

# Only generate if cost is acceptable
if count.total_tokens < 100000:
    response = model.generate_content(prompt)
```

---

## 5. Firebase Genkit: Building AI-Powered Apps

### Overview
Genkit is Google's production framework for building, deploying, and monitoring AI features with observability built in.

**Languages:** JavaScript/TypeScript, Go, Python (alpha)
**Repository:** [firebase/genkit](https://github.com/firebase/genkit)
**License:** Apache 2.0
**Status:** Production ready, actively maintained

### Installation & Setup

```bash
npm install -g @genkit/cli
npm install @genkit/ai

# Or create a new Genkit project
genkit init my-ai-app
cd my-ai-app
npm install
```

### Basic Flow: Text Generation

```typescript
import { genkit, z } from "genkit";
import { gemini15Pro } from "@genkit/ai/gemini";

const ai = genkit({
  plugins: [gemini15Pro()],
  model: "gemini-3-pro"  // Set default model
});

export const summarizeText = ai.defineFlow(
  {
    name: "summarizeText",
    inputSchema: z.object({
      text: z.string().describe("Text to summarize"),
      length: z.enum(["short", "medium", "long"]).default("medium")
    }),
    outputSchema: z.string()
  },
  async (input) => {
    const response = await ai.generate({
      prompt: `Summarize this text in ${input.length} format:\n\n${input.text}`,
      config: { temperature: 0.7 }
    });
    return response.text;
  }
);

// Test it
const result = await summarizeText({
  text: "Long article text here...",
  length: "short"
});
console.log(result);
```

### Structured Outputs with Schemas

```typescript
import { genkit, z } from "genkit";

const BlogPost = z.object({
  title: z.string(),
  sections: z.array(z.object({
    heading: z.string(),
    content: z.string()
  })),
  seo: z.object({
    keywords: z.array(z.string()),
    metaDescription: z.string()
  })
});

export const generateBlogPost = ai.defineFlow(
  {
    name: "generateBlogPost",
    inputSchema: z.object({
      topic: z.string(),
      audience: z.string()
    }),
    outputSchema: BlogPost
  },
  async (input) => {
    const response = await ai.generate({
      prompt: `Write a blog post about "${input.topic}" for ${input.audience}`,
      output: { schema: BlogPost }
    });
    return response.output;
  }
);
```

### Retrieval-Augmented Generation (RAG)

```typescript
import { genkit, z } from "genkit";
import { Document, Document, googleSearchRetriever } from "@genkit/ai";

const getRelevantDocs = async (query: string): Promise<Document[]> => {
  // Use Google Search for retrieval
  const retriever = googleSearchRetriever();
  return retriever.retrieve(query, { limit: 5 });
};

export const answerQuestion = ai.defineFlow(
  {
    name: "answerQuestion",
    inputSchema: z.object({ question: z.string() }),
    outputSchema: z.object({
      answer: z.string(),
      sources: z.array(z.string())
    })
  },
  async (input) => {
    // Retrieve relevant documents
    const docs = await getRelevantDocs(input.question);
    const context = docs.map(d => d.content).join("\n\n");

    // Generate answer with context
    const response = await ai.generate({
      prompt: `Based on this context:\n${context}\n\nAnswer: ${input.question}`,
      config: { temperature: 0.3 }  // Lower temperature for factuality
    });

    return {
      answer: response.text,
      sources: docs.map(d => d.url || "")
    };
  }
);
```

### Multi-Step Workflows

```typescript
export const createContentPlan = ai.defineFlow(
  {
    name: "createContentPlan",
    inputSchema: z.object({
      goal: z.string(),
      numWeeks: z.number().default(4)
    }),
    outputSchema: z.object({
      weeks: z.array(z.object({
        week: z.number(),
        topics: z.array(z.string()),
        deliverables: z.array(z.string())
      }))
    })
  },
  async (input) => {
    // Step 1: Brainstorm topics
    const brainstorm = await ai.generate({
      prompt: `Brainstorm ${input.numWeeks * 2} content ideas for: ${input.goal}`
    });

    // Step 2: Organize into schedule
    const schedule = await ai.generate({
      prompt: `Create a ${input.numWeeks}-week content calendar. Ideas:\n${brainstorm.text}`,
      output: { schema: z.object({
        weeks: z.array(z.object({
          week: z.number(),
          topics: z.array(z.string()),
          deliverables: z.array(z.string())
        }))
      })}
    });

    return schedule.output;
  }
);
```

### Deployment to Firebase

```bash
# Deploy flow to Firebase Cloud Functions
genkit deploy

# Endpoint created automatically:
# https://region-projectid.cloudfunctions.net/summarizeText
```

### Monitoring in Firebase Console

```typescript
// Genkit logs all invocations automatically
export const aiFeature = ai.defineFlow(
  {
    name: "aiFeature",
    // ... config ...
  },
  async (input) => {
    // Trace and metrics collected automatically:
    // - Latency
    // - Token usage
    // - Error rates
    // - Model used
    // Available in Firebase Console > Genkit
  }
);
```

---

## 6. Vertex AI Agent Builder: Enterprise Production Agents

### Overview
Vertex AI Agent Builder is Google Cloud's suite for building, deploying, and governing agents at scale.

**Components:**
- **Agent Engine:** Fully-managed runtime, evaluation, sessions, memory
- **Agent Development Kit (ADK):** Code-first agent development
- **Agent Builder UI:** Low-code agent creation

**Status:** Generally available, 7M+ ADK downloads

### Agent Engine: Production Runtime

```python
from vertexai.agentic.agents import Agent
from vertexai.agentic.agents import Tool
import vertexai

vertexai.init(project="my-project", location="us-central1")

# Define agent
agent = Agent(
    model="gemini-3-pro",
    agent_name="customer_support_agent",
    instructions="""
    You are a helpful customer support agent.
    Handle inquiries professionally and escalate complex issues.
    """,
    enable_logging=True
)

# Add tools (MCP, custom, built-in)
agent.add_tools([
    Tool.from_google_api("bigquery"),  # Query customer database
    Tool.from_mcp_server(                # Custom tool via MCP
        uri="stdio://python",
        name="ticket_system"
    )
])

# Deploy to Agent Engine
agent.deploy(
    enable_sessions=True,      # Persistent conversation state
    enable_memory_bank=True,   # Long-term memory for customers
    auto_scaling=True
)

# Invoke via REST API
response = agent.call(
    "I have a billing issue with order #12345",
    session_id="customer_abc123"  # Maintains conversation history
)
```

### Governance: Tool Approval Workflow

```python
from vertexai.agentic.agents import PolicyEngine

policy = PolicyEngine(
    agent_id="customer_support_agent",
    policies=[
        {
            "tool": "bigquery",
            "action": "ALLOW_WITH_APPROVAL",
            "approver": "team-leads@company.com",
            "description": "Require approval for customer data queries"
        },
        {
            "tool": "send_email",
            "action": "ALLOW",
            "conditions": {
                "recipients": ["support@customer.com"],  # Whitelist only
                "rate_limit": "100 per hour"
            }
        },
        {
            "tool": "delete_customer_data",
            "action": "DENY",
            "description": "Agents never delete data autonomously"
        }
    ]
)

policy.deploy()
```

### Sessions & Memory Bank

```python
# Maintain conversation state automatically
session = agent.create_session(
    session_id="customer_abc123",
    metadata={
        "customer_id": "cust_123",
        "tier": "premium",
        "language": "es"
    }
)

# Agent remembers context across multiple calls
response1 = agent.call("I want to upgrade my plan", session=session)
response2 = agent.call("Can you show me the features?", session=session)
# Agent context includes previous upgrade request

# Persistent memory for long-term relationships
memory = session.get_memory_bank()
memory.add_fact("Prefers email communication")
memory.add_fact("Has been customer for 5 years")
```

### Evaluation Framework

```python
from vertexai.agentic.agents import AgentEvaluator

evaluator = AgentEvaluator(
    agent=agent,
    metric_definitions=[
        {
            "name": "customer_satisfaction",
            "description": "Rate customer satisfaction 1-5",
            "scoring_function": lambda response: 5 if "thank you" in response.lower() else 3
        },
        {
            "name": "resolution_rate",
            "description": "Percentage of issues resolved without escalation",
            "scoring_function": lambda response: 1.0 if response.escalated == False else 0.0
        }
    ]
)

# Run evaluation suite
test_conversations = [
    {"input": "I can't log in", "expected_outcome": "User can log in again"},
    {"input": "I want to cancel", "expected_outcome": "Cancellation processed or escalated"}
]

results = evaluator.evaluate(test_conversations)
print(f"Avg satisfaction: {results['customer_satisfaction']}")
print(f"Resolution rate: {results['resolution_rate']}")
```

### Comparison: Vertex AI Agent Builder vs Claude Agent SDK vs LangGraph

| Feature | Vertex AI | Claude SDK | LangGraph |
|---------|-----------|-----------|-----------|
| **Code-First** | ✓ ADK | ✓ Native | ✓ Native |
| **Multi-Agent** | ✓ Hierarchical | ✓ Via library | ✓ Via library |
| **Sessions/Memory** | ✓ Built-in | ✗ Manual | ✗ Manual |
| **Tool Governance** | ✓ Policy Engine | ✗ | ✗ |
| **Evaluations** | ✓ Built-in | ✗ | ✗ |
| **Managed Runtime** | ✓ Agent Engine | ✗ | ✗ |
| **Cost** | Pay-per-invocation | Model-dependent | Model-dependent |
| **Learning Curve** | Steep (GCP) | Moderate | Moderate |

---

## 7. MCP Support in Gemini Ecosystem

### Full MCP Integration (2026)

All Gemini tools—CLI, Code Assist, ADK, Vertex AI—support Model Context Protocol natively.

### Setup: Gemini CLI + MCP

```bash
# Add an MCP server to your project
gemini config add-mcp stdio://python ./my_server.py

# Or use a managed Google MCP server
gemini config add-mcp https://mcp.googleapis.com/bigquery \
    --credentials gcp-service-account.json
```

### Google-Managed MCP Servers (2026)

```python
# No setup needed—use via credentials
from google_ai_agents import MCPServerTool

mcp_tools = [
    MCPServerTool.from_google(
        service="bigquery",
        project_id="my-project"
    ),
    MCPServerTool.from_google(
        service="cloud_storage",
        bucket="my-bucket"
    ),
    MCPServerTool.from_google(
        service="cloud_run",
        region="us-central1"
    ),
]

agent = Agent(
    model="gemini-3-pro",
    tools=mcp_tools
)
```

### Custom MCP Servers with FastMCP

```python
# Build an MCP server in minutes with FastMCP
from fastmcp import Tool
from pydantic import BaseModel

class QueryResult(BaseModel):
    rows: list[dict]
    count: int

tool = Tool(
    name="query_postgres",
    description="Query PostgreSQL database",
    input_schema={
        "query": {"type": "string"},
        "limit": {"type": "integer", "default": 100}
    },
    input_type=QueryResult
)

@tool.handler()
def handle_query(query: str, limit: int = 100) -> QueryResult:
    import psycopg2
    conn = psycopg2.connect("dbname=mydb user=postgres")
    cursor = conn.cursor()
    cursor.execute(f"{query} LIMIT {limit}")
    rows = cursor.fetchall()
    return QueryResult(rows=rows, count=len(rows))

# Serve the MCP server
if __name__ == "__main__":
    from fastmcp import run_server
    run_server([tool])
```

### MCP in Android Studio

```
Android Studio > Settings > Tools > Gemini > MCP
Click "Add MCP Server"
Select Protocol: stdio
Command: python ./my_mcp_server.py
Connect
```

Now Gemini Agent mode in Android Studio can use your MCP tools.

---

## 8. Test-Driven & Spec-Driven Development with Gemini

### Spec-Driven Development Workflow

**Definition:** Write a specification document first, then use an AI agent to generate code that adheres to it.

#### Step 1: Write a Specification

Create `SPEC.md`:

```markdown
# User Authentication Feature Specification

## Goals
- Secure user authentication with OAuth2
- Support Google and GitHub providers
- Persist user sessions in PostgreSQL

## API Contract
```
POST /auth/login
{
  "provider": "google" | "github",
  "redirectUri": "https://example.com/callback"
}
→ { code: string, redirectUri: string }

POST /auth/callback
{
  "code": string,
  "provider": "google" | "github"
}
→ { userId: string, sessionToken: string }
```

## Technical Constraints
- Use Express.js for backend
- Store sessions in PostgreSQL with Redis cache
- All endpoints require CORS validation
- Sessions expire after 7 days

## Success Criteria
- All endpoints have 99% uptime SLA
- Session retrieval < 50ms (cached)
- Full test coverage (>90%)
- No secrets in logs
```

#### Step 2: Ask Gemini CLI to Build It

```bash
gemini chat "Implement the specification in SPEC.md.
             Run the test suite.
             Create a PR with the complete implementation."
```

Gemini will:
1. Read `SPEC.md`
2. Generate implementation matching the spec
3. Create tests validating the spec
4. Run tests and report results
5. Create a git commit/PR

#### Step 3: Iterative Refinement

```bash
# Gemini reports test failures
gemini chat "The /auth/callback test is failing.
             Debug and fix it while staying within the SPEC.md constraints."
```

### TDD Workflow with Gemini

#### Phase 1: Write Tests (Red)

```typescript
// auth.test.ts - Write tests first
describe("Authentication", () => {
  it("should authenticate with Google OAuth", async () => {
    const result = await auth.login({ provider: "google" });
    expect(result).toHaveProperty("code");
    expect(result).toHaveProperty("redirectUri");
  });

  it("should retrieve user from callback", async () => {
    const user = await auth.callback({ code: "xyz", provider: "google" });
    expect(user).toHaveProperty("userId");
    expect(user).toHaveProperty("sessionToken");
  });

  it("should validate session token", async () => {
    const token = "valid_token_xyz";
    const isValid = await auth.validateSession(token);
    expect(isValid).toBe(true);
  });
});
```

#### Phase 2: Ask Gemini to Implement (Green)

```bash
gemini chat "Write the minimal implementation to pass all tests in auth.test.ts.
             Don't add extra features—focus only on passing tests."
```

Gemini generates:

```typescript
export const auth = {
  async login({ provider }) {
    return { code: "abc123", redirectUri: "https://oauth.provider.com" };
  },

  async callback({ code, provider }) {
    return { userId: "user_123", sessionToken: "session_xyz" };
  },

  async validateSession(token) {
    return token === "session_xyz";  // Minimal implementation
  }
};
```

#### Phase 3: Ask Gemini to Refactor (Refactor)

```bash
gemini chat "Refactor the auth implementation while keeping all tests passing:
             1. Add proper OAuth2 flow
             2. Use PostgreSQL for session storage
             3. Add Redis caching
             4. Improve error handling
             5. Run all tests to ensure they pass"
```

### Spec Kit Integration (GitHub)

GitHub Spec Kit is a toolkit for Spec-Driven Development that works with Gemini CLI:

```bash
# Initialize Spec Kit
spec-kit init my-project

# Create a spec
spec-kit add-spec "User Authentication" \
    --goals "Secure OAuth2 login" \
    --constraints "Express.js, PostgreSQL, <50ms session lookup"

# Gemini uses the spec
gemini chat "Implement the specs from spec-kit. Run all evaluations."
```

---

## 9. Where Gemini Excels vs Claude (2026)

### Gemini Strengths

#### 1. Multimodal (Video, Audio, Images)
```python
# Gemini analyzes video natively; Claude doesn't
response = gemini.generate_content([
    "Transcribe and summarize this demo video",
    video_file  # Works directly
])
```

#### 2. Large Context (2M Tokens)
Gemini 1.5 Pro has 2M context vs Claude's 1M. Best for:
- Full codebase analysis (100K+ LOC)
- Long research papers
- Full API documentation at once

#### 3. Cost (7x Cheaper)
```
Gemini 3 Pro: $2 / $12 per 1M tokens
Claude Opus 4.6: $15 / $75 per 1M tokens
```

For high-volume development workflows, massive savings.

#### 4. Google Ecosystem Integration
- BigQuery, Cloud Storage, Cloud Run, Google Maps via MCP
- Gmail, Drive, Workspace via MCP (coming 2026)
- Analytics, Search Console, Ads via APIs

#### 5. Grounding with Real-Time Search
Built-in Google Search grounding reduces hallucinations on:
- Recent events
- API changes
- Product updates
- News-driven code (e.g., "implement trending algorithm")

### Claude Strengths

#### 1. Better for Pure Code Generation
Claude's larger output window (128K vs 65K) and architectural reasoning excel at:
- Full app generation (backend + frontend + tests)
- Large refactoring tasks
- Complex system design

#### 2. Superior Tool Ecosystem
Claude Code (IDE) has more mature integrations with:
- GitHub (better PR workflows)
- Linear / Jira (issue tracking)
- Vercel (deployments)

#### 3. Better at Complex Reasoning
Claude consistently scores higher on:
- Scientific problem-solving
- Math/formal reasoning
- Complex multi-step logic

#### 4. Better API Documentation
More mature docs and community libraries for:
- LangChain integration
- LlamaIndex integration
- Custom prompt engineering

### Head-to-Head Comparison Table

| Use Case | Gemini | Claude | Winner |
|----------|--------|--------|--------|
| **Video analysis** | Native | Image only | Gemini |
| **2M context codebase** | ✓ Default | ✗ Paid/Beta | Gemini |
| **Cost/token** | $2-$12 | $15-$75 | Gemini (7x) |
| **Full-stack code gen** | ✓ Good | ✓ Better | Claude |
| **Google ecosystem** | Deep | Shallow | Gemini |
| **Scientific reasoning** | Good | Better | Claude |
| **Math problems** | Competent | Better | Claude |
| **Grounding w/ search** | ✓ Built-in | ✗ | Gemini |
| **IDE integration** | Good | Better | Claude |
| **Learning curve** | Steep | Moderate | Claude |

### Decision Matrix

**Choose Gemini if:**
- You're analyzing multimodal data (video, audio)
- You need 2M token context by default
- You're integrating with Google Cloud
- Cost is critical (budget-conscious)
- You need real-time search grounding

**Choose Claude if:**
- You're doing complex code generation
- You need mature tool ecosystem
- Your team is on GitHub
- You need the best reasoning capabilities
- You value IDE-native experience

---

## 10. Production Patterns & Best Practices (2026)

### Pattern 1: Hybrid Multi-Agent System

```python
# Use Gemini CLI for ideation, Claude Code for implementation
# Gemini (research & planning) → Claude Code (detailed implementation)

# Step 1: Gemini CLI brainstorms architecture
gemini chat "Design a recommendation engine using embeddings and similarity search"

# Step 2: Claude Code implements the detailed component
# (Launched from VS Code with the design doc)

# Step 3: Gemini Code Assist in IDE provides real-time suggestions
```

### Pattern 2: Cost Optimization

```python
import google.generativeai as genai

model = genai.GenerativeModel("gemini-3-pro")

# For simple tasks: use Flash (cheaper, faster)
if task_complexity < 5:
    response = genai.GenerativeModel("gemini-3-flash").generate_content(prompt)
else:
    # For complex reasoning: use Pro
    response = model.generate_content(prompt)

# Use Gemini 1.5 Pro only for 1M+ token contexts
if len(context) > 100000:  # ~25K+ tokens
    response = genai.GenerativeModel("gemini-1-5-pro").generate_content(
        [prompt, large_context_file]
    )
```

### Pattern 3: Spec-Driven + TDD Workflow

```
1. Write SPEC.md (goals, constraints, API contract)
2. Write tests (red)
3. Ask Gemini: "Implement spec and pass tests"
4. Gemini generates code (green)
5. Code review (human)
6. Gemini refactors while keeping tests green (refactor)
7. Deploy
```

### Pattern 4: Observability & Monitoring

```python
from vertexai.agentic.agents import Agent
import logging

logging.basicConfig(level=logging.DEBUG)

agent = Agent(
    model="gemini-3-pro",
    enable_logging=True  # Logs all calls to Cloud Logging
)

# Monitor in Vertex AI > Agents
# Metrics tracked automatically:
# - Token usage (input/output)
# - Latency
# - Error rates
# - Tool calls
# - Model used
```

### Pattern 5: Fallback for Critical Operations

```python
def query_with_fallback(prompt: str, task_type: str) -> str:
    """
    Try Gemini first (faster, cheaper).
    Fall back to Claude if Gemini fails or score is low.
    """
    try:
        # Try Gemini (1M context, cheaper)
        response = gemini_model.generate_content(prompt)
        confidence = evaluate_response_quality(response)

        if confidence > 0.8:
            return response.text

        # Fallback to Claude for high-stakes tasks
        if task_type == "critical_decision":
            response = claude_model.generate_content(prompt)
            return response.text

    except Exception as e:
        logging.error(f"Gemini failed: {e}")
        response = claude_model.generate_content(prompt)
        return response.text
```

---

## 11. Resources & Getting Started Roadmap

### Free Tier Access
- **Gemini CLI:** Free (60 req/min, 1K req/day)
- **Google AI Studio:** Free (all models)
- **Genkit:** Free (pay-per-use for API calls)
- **Vertex AI:** Free tier (300 free requests/month)

### Getting Started (Week 1-2)
1. Install Gemini CLI: `npm install -g @google/gemini-cli`
2. Install VS Code extension: "Gemini Code Assist"
3. Create first agent in Genkit: `genkit init`
4. Run first test-driven task

### Intermediate (Week 3-4)
1. Build multi-agent system with ADK
2. Add custom MCP server (FastMCP)
3. Deploy to Cloud Run
4. Implement Spec-Driven workflow

### Advanced (Month 2)
1. Vertex AI Agent Engine for production
2. Custom policy engine for governance
3. Integration with Google Cloud services
4. Hybrid workflows (Gemini + Claude)

---

## Sources

- [GitHub - google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)
- [Gemini CLI Documentation](https://geminicli.com/docs/)
- [Hands-on with Gemini CLI - Google Codelabs](https://codelabs.developers.google.com/gemini-cli-hands-on)
- [Gemini Code Assist Overview - Google Developers](https://developers.google.com/gemini-code-assist/docs/overview)
- [Gemini Code Assist Release Notes](https://developers.google.com/gemini-code-assist/resources/release-notes)
- [Agent Development Kit (ADK) Documentation](https://google.github.io/adk-docs/)
- [Agent Development Kit - Google Developers Blog](https://developers.googleblog.com/en/agent-development-kit-easy-to-build-multi-agent-applications/)
- [Build a Multi-Agent System with ADK and MCP - Google Cloud Blog](https://cloud.google.com/blog/topics/developers-practitioners/build-a-multi-agent-system-for-expert-content-with-google-adk-mcp-and-cloud-run-part-1)
- [Gemini API Structured Outputs Documentation](https://ai.google.dev/gemini-api/docs/structured-output)
- [Function Calling with Gemini API](https://ai.google.dev/gemini-api/docs/function-calling)
- [Grounding with Google Search - Gemini API](https://ai.google.dev/gemini-api/docs/google-search)
- [Firebase Genkit - GitHub](https://github.com/firebase/genkit)
- [Genkit Documentation](https://firebase.google.com/docs/genkit/overview)
- [Build gen AI features with Genkit and RAG - Firebase Codelabs](https://firebase.google.com/codelabs/ai-genkit-rag)
- [Vertex AI Agent Builder Overview - Google Cloud Documentation](https://docs.cloud.google.com/agent-builder/overview)
- [Vertex AI Agent Engine - Google Cloud Blog](https://cloud.google.com/blog/products/ai-machine-learning/more-ways-to-build-and-scale-ai-agents-with-vertex-ai-agent-builder)
- [Announcing Official MCP Support for Google Services - Google Cloud Blog](https://cloud.google.com/blog/products/ai-machine-learning/announcing-official-mcp-support-for-google-services)
- [MCP Servers with Gemini CLI](https://geminicli.com/docs/tools/mcp-server/)
- [Gemini CLI & FastMCP - Google Developers Blog](https://developers.googleblog.com/gemini-cli-fastmcp-simplifying-mcp-server-development/)
- [Spec-Driven Development with Gemini CLI - Medium](https://medium.com/google-cloud/spec-driven-development-with-gemini-cli-dfb4b88d4880)
- [GitHub Spec Kit](https://github.com/github/spec-kit)
- [Gemini vs Claude 2026 Comparison - Prompt Builder](https://promptbuilder.cc/compare/gemini-vs-claude)
- [Claude vs Gemini Complete Comparison 2026](https://gurusup.com/blog/claude-vs-gemini)
- [Google AI Studio 2026 Guide](https://www.shipai.dev/blog/google-ai-studio-2026-guide)
- [Prompt Design Strategies - Gemini API Documentation](https://ai.google.dev/gemini-api/docs/prompting-strategies)
- [Gemini API Context Windows & Token Limits 2026](https://www.datastudios.org/post/google-gemini-context-window-token-limits-model-comparison-and-workflow-strategies-for-late-2025)

---

## Related Topics

- [Claude Code Power User](claude-code-power-user.md) — Understanding Claude Code's agentic approach vs Gemini's AI Studio
- [Tool Comparison Guide](tool-comparison-when-to-use.md) — Choosing Gemini for 2M context, multimodal, and cost efficiency
- [Context Memory Systems](context-memory-systems.md) — Leveraging Gemini's massive context window for project management

