# Implementation Plan: Agentic Research App

**Date:** 2026-03-28
**Project:** Agentic Research App
**Status:** Ready to build

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                    CLI (main.py)                 │
│         User query → Streaming output           │
├─────────────────────────────────────────────────┤
│                Agent Loop (agent.py)             │
│        ReAct: Think → Act → Observe → Repeat    │
│                                                  │
│  ┌─────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Planner │ │ Executor │ │   Synthesizer    │  │
│  │(system  │ │(tool     │ │(report generator)│  │
│  │ prompt) │ │ calls)   │ │                  │  │
│  └─────────┘ └──────────┘ └──────────────────┘  │
├─────────────────────────────────────────────────┤
│                  Tools (tools.py)                 │
│                                                  │
│  ┌──────────┐ ┌───────────┐ ┌────────────────┐  │
│  │  Search  │ │   Read    │ │  Vector Store  │  │
│  │ (Tavily) │ │  (httpx + │ │  (ChromaDB)    │  │
│  │          │ │trafilatura│ │  store/retrieve │  │
│  └──────────┘ └───────────┘ └────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │     Domain Tools (domain_finance.py)     │    │
│  │  SEC EDGAR │ Yahoo Finance │ Earnings    │    │
│  └──────────────────────────────────────────┘    │
├─────────────────────────────────────────────────┤
│              Models (models.py)                   │
│   SearchResult │ PageContent │ Finding │ Report  │
├─────────────────────────────────────────────────┤
│               RAG Layer (rag.py)                 │
│        ChromaDB + nomic-embed-text-v2            │
│        Store chunks │ Retrieve context           │
├─────────────────────────────────────────────────┤
│              Streaming (streaming.py)             │
│     Rich console │ Live progress │ Token stream  │
└─────────────────────────────────────────────────┘
```

---

## Project Structure

```
agentic-research-app/
├── pyproject.toml          # Dependencies and project config
├── .env.example            # Required env vars template
├── .gitignore
├── README.md               # Setup, usage, architecture docs
│
├── src/
│   ├── __init__.py
│   ├── cli.py              # CLI entry point (argparse + Rich)
│   ├── agent.py            # Core ReAct agent loop
│   ├── tools.py            # Tool definitions + registry
│   ├── tool_impl.py        # Tool execution implementations
│   ├── models.py           # Pydantic models (structured outputs)
│   ├── rag.py              # ChromaDB vector store operations
│   ├── streaming.py        # Streaming display handler
│   ├── report.py           # Report generation + formatting
│   ├── config.py           # Settings from env vars
│   └── domains/
│       ├── __init__.py
│       ├── base.py         # Base domain (general research)
│       └── finance.py      # Finance-specific tools + prompts
│
├── evals/
│   ├── __init__.py
│   ├── conftest.py         # Shared fixtures
│   ├── test_tools.py       # Tool execution correctness
│   ├── test_rag.py         # RAG retrieval quality
│   ├── test_agent.py       # Agent loop behavior
│   └── test_report.py      # Output structure + quality
│
├── reports/                # Generated reports (gitignored)
└── chroma_data/            # ChromaDB persistence (gitignored)
```

---

## Data Models (Pydantic)

```python
# models.py — Core structured outputs

class SearchResult(BaseModel):
    """Single search result from Tavily."""
    title: str
    url: str
    snippet: str
    relevance_score: float

class PageContent(BaseModel):
    """Extracted content from a web page."""
    url: str
    title: str
    content: str
    word_count: int
    extraction_method: str  # "trafilatura" | "tavily_extract" | "fallback"

class Finding(BaseModel):
    """A single research finding extracted from a source."""
    claim: str
    source_url: str
    source_title: str
    supporting_quote: str
    confidence: float       # 0.0-1.0, agent's assessment
    category: str           # "fact" | "opinion" | "statistic" | "prediction"

class ResearchReport(BaseModel):
    """Final structured research report."""
    query: str
    summary: str
    key_findings: list[Finding]
    sources: list[Source]
    methodology: str        # What the agent did
    confidence_assessment: str
    limitations: list[str]
    generated_at: str
    total_sources_consulted: int
    agent_steps_taken: int

class Source(BaseModel):
    """A source consulted during research."""
    url: str
    title: str
    credibility: str        # "high" | "medium" | "low" | "unknown"
    relevance: float        # 0.0-1.0
    accessed_at: str
```

---

## Tool Definitions

### Core Tools (all domains)

#### 1. `web_search`
- **Purpose:** Search the web for information on a topic
- **API:** Tavily Search API
- **Input:** `{ query: str, max_results: int, search_depth: "basic" | "advanced" }`
- **Output:** List of `SearchResult`
- **Learning pattern:** Tool calling, function definition

#### 2. `read_page`
- **Purpose:** Read and extract content from a web page URL
- **API:** httpx GET → trafilatura extraction, fallback to Tavily Extract
- **Input:** `{ url: str }`
- **Output:** `PageContent`
- **Learning pattern:** Tool calling, error handling

#### 3. `store_finding`
- **Purpose:** Save a research finding to the vector store for future retrieval
- **API:** ChromaDB add
- **Input:** `{ finding: str, source_url: str, metadata: dict }`
- **Output:** Confirmation with chunk ID
- **Learning pattern:** RAG (write side)

#### 4. `retrieve_context`
- **Purpose:** Search past research findings relevant to a query
- **API:** ChromaDB query
- **Input:** `{ query: str, max_results: int }`
- **Output:** List of relevant past findings with metadata
- **Learning pattern:** RAG (read side)

### Finance Domain Tools (Phase 2)

#### 5. `search_sec_filings`
- **Purpose:** Search SEC EDGAR for company filings (10-K, 10-Q, 8-K, etc.)
- **API:** SEC EDGAR full-text search API (free, no key required)
- **Input:** `{ company: str, filing_type: str, date_range: str }`
- **Output:** List of filing results with links

#### 6. `get_financial_data`
- **Purpose:** Get stock price, financials, and key metrics for a company
- **API:** Yahoo Finance (yfinance library)
- **Input:** `{ ticker: str, data_type: "quote" | "financials" | "history" }`
- **Output:** Structured financial data

#### 7. `search_earnings`
- **Purpose:** Search for and summarize earnings call transcripts
- **API:** Web search scoped to earnings transcript sites
- **Input:** `{ company: str, quarter: str }`
- **Output:** Earnings highlights and key quotes

---

## Agent Loop Design (ReAct Pattern)

```python
# agent.py — Simplified flow

SYSTEM_PROMPT = """You are a research agent. For each query:
1. PLAN: Break the question into 2-4 sub-questions
2. SEARCH: Use web_search to find relevant sources
3. READ: Use read_page to extract detailed content from promising results
4. EVALUATE: Assess source credibility and relevance
5. STORE: Save key findings to vector store for future reference
6. ITERATE: If you need more info, search again with refined queries
7. SYNTHESIZE: When you have enough evidence, compile your findings

Always cite sources. Flag uncertainty. Prefer authoritative sources.
Stop after {max_iterations} iterations or when you have sufficient evidence.
"""

async def run_agent(query: str, config: Config) -> ResearchReport:
    messages = [{"role": "user", "content": query}]
    iteration = 0

    while iteration < config.max_iterations:
        # Stream the response
        response = await stream_response(
            model=config.model,
            system=SYSTEM_PROMPT,
            tools=get_tools(config.domain),
            messages=messages,
        )

        # Check if agent is done
        if response.stop_reason == "end_turn":
            break

        # Execute tool calls
        tool_results = await execute_tools(response)

        # Append to conversation
        messages.append({"role": "assistant", "content": response.content})
        messages.append({"role": "user", "content": tool_results})
        iteration += 1

    # Generate structured report
    return await generate_report(messages, config)
```

---

## Build Phases

### Phase 1: Foundation (Core Agent Loop)
**Goal:** Working CLI that takes a question and produces a basic report
**Patterns learned:** Tool calling, ReAct loop, streaming

Build order:
1. `config.py` — Environment variables, settings
2. `models.py` — Pydantic models for all structured outputs
3. `tools.py` — Tool schema definitions (JSON Schema for Claude)
4. `tool_impl.py` — `web_search` (Tavily) and `read_page` (httpx + trafilatura)
5. `agent.py` — ReAct loop with tool execution
6. `streaming.py` — Rich console output (agent thinking, tool calls, progress)
7. `cli.py` — `research "your question here"` entry point
8. `report.py` — Markdown report generation from agent findings

**Exit criteria:** Can run `python -m src.cli "What are the top AI agent frameworks in 2026?"` and get a sourced markdown report.

### Phase 2: RAG Layer
**Goal:** Agent remembers past research and uses it for new queries
**Patterns learned:** RAG (store + retrieve), embeddings, vector search

Build order:
1. `rag.py` — ChromaDB setup, embedding function (nomic), add/query operations
2. Add `store_finding` and `retrieve_context` tools to registry
3. Update system prompt to instruct agent to store important findings and check past research first
4. Test with sequential queries that build on each other

**Exit criteria:** Query about "Claude API pricing" stores findings → later query about "best LLM API for agents" retrieves those findings as context.

### Phase 3: Structured Outputs + Report Quality
**Goal:** Reports are well-structured, typed, and export-ready
**Patterns learned:** Pydantic structured outputs via `client.messages.parse()`

Build order:
1. Use `client.messages.parse()` with `ResearchReport` model for final report generation
2. Add confidence scoring to findings
3. Add source credibility assessment
4. Export reports as formatted Markdown with tables, citations, confidence levels
5. Save reports to `reports/` directory with timestamps

**Exit criteria:** Reports are valid `ResearchReport` Pydantic objects with all fields populated, exported as polished Markdown.

### Phase 4: Evals
**Goal:** Automated quality measurement for tools, RAG, agent behavior, and outputs
**Patterns learned:** AI evaluation, pytest-based testing, quality metrics

Build order:
1. `conftest.py` — Shared fixtures (mock Tavily responses, test ChromaDB instance)
2. `test_tools.py` — Does web_search return results? Does read_page extract content? Error handling?
3. `test_rag.py` — Does store/retrieve round-trip correctly? Is retrieval relevant?
4. `test_agent.py` — Does agent complete in reasonable steps? Does it use tools appropriately?
5. `test_report.py` — Are reports structured? Are sources cited? Is confidence reasonable?
6. Add DeepEval metrics (hallucination, faithfulness, answer relevancy) for LLM output quality

**Exit criteria:** `pytest evals/` passes. Agent behavior is measurably consistent.

### Phase 5: Finance Domain
**Goal:** Finance-specialized research with SEC, earnings, and financial data tools
**Patterns learned:** Domain specialization, tool composition, real-world API integration

Build order:
1. `domains/finance.py` — Finance system prompt + tool definitions
2. `search_sec_filings` tool (SEC EDGAR API)
3. `get_financial_data` tool (yfinance)
4. `search_earnings` tool (scoped web search)
5. Finance-specific evals (financial data accuracy, source appropriateness)

**Exit criteria:** Can run `research --domain finance "Analyze NVIDIA's competitive position in AI chips"` and get a report that cites SEC filings, financial data, and earnings transcripts.

### Phase 6 (Stretch): Polish + Commercialization Prep
- Multiple output formats (Markdown, JSON, PDF)
- Cost tracking per research run (token usage, API calls)
- Research history browser (list past reports)
- Domain switching via config (`--domain general|finance|realestate`)
- Rate limiting and error recovery

---

## Dependencies

```toml
[project]
dependencies = [
    "anthropic>=0.43.0",     # Claude API + tool use + structured outputs
    "chromadb>=0.5.0",       # Vector store
    "httpx>=0.27.0",         # Async HTTP client
    "pydantic>=2.0",         # Structured outputs / data models
    "trafilatura>=2.0.0",    # Web content extraction
    "rich>=13.0",            # CLI streaming display
    "python-dotenv>=1.0.0",  # Env var loading
    "tavily-python>=0.5.0",  # Search API client
    "sentence-transformers", # Embedding model (nomic)
    "yfinance>=0.2.0",       # Yahoo Finance data (Phase 5)
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24.0",
    "deepeval>=1.0",         # LLM evaluation metrics
    "respx>=0.22.0",         # HTTP mocking for tests
]
```

---

## Key Architecture Decisions

### 1. Raw SDK, No Framework
**Decision:** Use Anthropic Python SDK directly, not LangChain/LangGraph/CrewAI
**Rationale:** The goal is to learn the primitives. Frameworks hide the patterns you're trying to learn. You can always add a framework later once you understand what it abstracts.

### 2. Domain Specialization via Tools + Prompts
**Decision:** Same agent core, different tool sets and system prompts per domain
**Rationale:** Avoids building separate agents for each domain. Adding a new domain = new tools file + system prompt. The ReAct loop, RAG layer, streaming, and report generation are shared.

### 3. Sync-First, Async-Optional
**Decision:** Start with synchronous code, add async when needed for concurrent page reads
**Rationale:** Simpler to debug and understand. The agent loop is inherently sequential (wait for Claude → execute tool → send result). Async benefits mainly come from reading multiple pages in parallel within a single tool call.

### 4. Local Embeddings, Not API
**Decision:** nomic-embed-text-v2 via sentence-transformers, running locally
**Rationale:** No per-embedding API cost, no rate limits, works offline. First-run downloads the model (~300MB), then it's instant.

### 5. ChromaDB In-Process
**Decision:** ChromaDB with local file persistence, no server
**Rationale:** Simplest setup for solo dev. If you need to scale later, migrate to hosted Chroma or Qdrant.

### 6. Eval from Day One
**Decision:** Build eval suite in Phase 4, before adding finance domain
**Rationale:** Having evals before adding domain complexity means you can measure whether domain tools actually improve output quality. Evals also catch regressions as you iterate.

---

## Traceability

### Original Problem
Professionals need deep, domain-specific research synthesis — current tools are either too expensive (Bloomberg at $24K/yr) or too shallow (Perplexity at $20/mo). Developers need a project that teaches all major AI-native patterns hands-on.

### How This Plan Addresses It
| Brief Requirement | Plan Feature | Phase |
|---|---|---|
| Learn tool calling | Build tool registry + Claude tool use from scratch | 1 |
| Learn RAG | ChromaDB + nomic embeddings, store/retrieve tools | 2 |
| Learn ReAct | Manual agent loop with think → act → observe cycle | 1 |
| Learn structured outputs | Pydantic models + `client.messages.parse()` | 3 |
| Learn streaming | Rich console streaming during agent loop | 1 |
| Learn evals | DeepEval + pytest suite | 4 |
| Finance niche | SEC EDGAR, yfinance, earnings tools | 5 |
| Repurposable | Domain = tools + prompt, not core architecture | 5 |

### What's Deferred to Later
- **Web UI** — Build as CLI first, add web frontend in a future version
- **Multi-agent** — Single agent is sufficient for MVP. Could add fact-checker + synthesizer sub-agents later
- **Authentication / multi-tenancy** — Solo tool first
- **Production deployment** — Run locally for now
- **PDF export** — Markdown is sufficient for v1
- **Real-time monitoring** — Cost tracking in Phase 6, full observability later
