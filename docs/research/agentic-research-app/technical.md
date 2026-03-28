# Technical Feasibility: Agentic Research App

**Date:** 2026-03-28

## 1. Anthropic Claude Tool Use (Raw SDK)

### How It Works
The Anthropic Python SDK provides tool use via the `tools` parameter on `client.messages.create()`. Each tool has a `name`, `description`, and `input_schema` (JSON Schema). When Claude wants to call a tool, the response has `stop_reason: "tool_use"` and a `tool_use` content block with `id`, `name`, and `input`.

### The Agentic Loop
```python
# Simplified ReAct loop
messages = [{"role": "user", "content": query}]
while True:
    response = client.messages.create(
        model="claude-sonnet-4-6",
        tools=tools,
        messages=messages
    )
    if response.stop_reason == "end_turn":
        break  # Agent is done
    # Execute tool calls
    tool_results = []
    for block in response.content:
        if block.type == "tool_use":
            result = execute_tool(block.name, block.input)
            tool_results.append({
                "type": "tool_result",
                "tool_use_id": block.id,
                "content": result
            })
    messages.append({"role": "assistant", "content": response.content})
    messages.append({"role": "user", "content": tool_results})
```

### Tool Runner SDK Abstraction
The SDK also provides a **Tool Runner** that automates the loop. However, for learning purposes, building the loop manually is recommended — then optionally replace with Tool Runner later.

### Model Choice
- **Claude Sonnet 4.6** — Best balance of speed, cost, and tool-use capability for iterative agent work
- **Claude Opus 4.6** — Use for complex reasoning or ambiguous queries. Better at handling multiple tools and seeking clarification
- **Claude Haiku 4.5** — Fastest/cheapest, good for straightforward single-tool calls

### Sources
- [Claude tool use docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/implement-tool-use)
- [Build a tool-using agent tutorial](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview)
- [Agent loop docs](https://platform.claude.com/docs/en/agent-sdk/overview)
- [Advanced tool use](https://www.anthropic.com/engineering/advanced-tool-use)

---

## 2. Structured Outputs

### Pydantic Integration
Claude supports structured outputs via `client.messages.parse()` with Pydantic models:

```python
from pydantic import BaseModel
from anthropic import Anthropic

class ResearchFinding(BaseModel):
    claim: str
    source_url: str
    confidence: float
    supporting_quotes: list[str]

client = Anthropic()
response = client.messages.parse(
    model="claude-sonnet-4-6",
    max_tokens=4096,
    output_format=ResearchFinding,
    messages=[{"role": "user", "content": "Extract the key finding from..."}]
)
finding = response.parsed_output  # Typed ResearchFinding
```

### Key Details
- Uses `output_config.format` (migrated from beta `output_format`)
- Constrained decoding guarantees schema-compliant JSON — no `JSON.parse()` errors
- Works with nested objects, arrays, optional fields
- SDK validates response against original Pydantic constraints
- Available on Claude Opus 4.6, Sonnet 4.6, Sonnet 4.5, Opus 4.5, Haiku 4.5

### Sources
- [Structured outputs docs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- [Anthropic SDK Python](https://github.com/anthropics/anthropic-sdk-python)

---

## 3. Streaming with Tool Use

The SDK supports streaming during tool-use loops. You can stream Claude's thinking/text while it decides which tools to call:

```python
with client.messages.stream(
    model="claude-sonnet-4-6",
    tools=tools,
    messages=messages
) as stream:
    for event in stream:
        if event.type == "content_block_delta":
            if event.delta.type == "text_delta":
                print(event.delta.text, end="", flush=True)
    response = stream.get_final_message()
```

**Key consideration:** Streaming works per-turn. During the agent loop, you stream each individual API call. Between calls (while executing tools), you show custom progress messages.

### Sources
- [Streaming docs](https://platform.claude.com/docs/en/build-with-claude/streaming)
- [SDK helpers](https://github.com/anthropics/anthropic-sdk-python/blob/main/helpers.md)

---

## 4. Search APIs Comparison

| API | Cost | Rate Limits | Best For | Notes |
|-----|------|-------------|----------|-------|
| **Tavily** | Free: 1,000 credits/mo. Starter: $30/mo (3,000). Scale: $150/mo (15,000) | Varies by plan | AI agents & RAG | Purpose-built for AI. Returns clean extracted content, not just URLs. MCP support. SOC 2 certified. `/research` endpoint (GA Jan 2026) does multi-step research in one call |
| **Brave Search** | Free: 2,000 queries/mo. Paid: $5/1,000 queries | 20 req/sec (paid) | Cost efficiency | Good quality, cheapest paid option. Returns snippets, not full content |
| **SerpAPI** | $50/mo (5,000 queries) | Varies | Google-quality results | Scrapes actual Google results. More expensive per query |
| **Exa** | Usage-based, ~$3-5/1,000 queries | Varies | Semantic search | Neural search, finds conceptually similar content |

### Recommendation: **Tavily**
- Purpose-built for AI agents (returns extracted content, not just links)
- Free tier is generous enough for development
- Native integrations with LangChain, LlamaIndex, MCP
- The `/research` endpoint is a bonus — can compare our agent's output against Tavily's built-in research
- Most used search API in the AI agent ecosystem (GPT Researcher uses it by default)

### Sources
- [Tavily pricing](https://docs.tavily.com/documentation/api-credits)
- [Beyond Tavily comparison](https://websearchapi.ai/blog/tavily-alternatives)
- [Brave Search API](https://brave.com/search/api/guides/what-sets-brave-search-api-apart/)
- [Agentic search benchmark](https://aimultiple.com/agentic-search)

---

## 5. Web Page Content Extraction

### Option Comparison

| Library | Approach | Strengths | Weaknesses |
|---------|----------|-----------|------------|
| **trafilatura** | Heuristic + ML | Best accuracy for main content extraction, supports metadata, handles diverse sites | Slower than regex-based |
| **BeautifulSoup** | DOM parsing | Flexible, well-known, manual control | Requires writing extraction logic per site |
| **readability-lxml** | Mozilla's Readability port | Good "reader mode" extraction | Less maintained than trafilatura |
| **newspaper3k** | Article-focused | Good for news sites | Outdated, limited maintenance |

### Recommendation: **trafilatura + httpx**
- trafilatura has the best accuracy for extracting main content from arbitrary web pages
- httpx provides async HTTP with connection pooling
- Fallback chain: trafilatura → BeautifulSoup with basic heuristics
- For JS-rendered pages: most research sources are static content (articles, docs, reports). Skip Playwright/Selenium complexity in v1

### Anti-Bot Considerations
- Use reasonable request headers (User-Agent, Accept)
- Rate-limit requests (1-2 sec between page loads)
- Respect robots.txt
- Tavily's Extract API handles scraping for you (good fallback when direct fetch fails)

### Sources
- [Trafilatura docs](https://trafilatura.readthedocs.io/)
- [Scraping comparison](https://www.justtothepoint.com/code/scrape/)
- [Python scraping libraries 2026](https://www.capsolver.com/blog/web-scraping/best-python-web-scraping-libraries)

---

## 6. ChromaDB + Embeddings for RAG

### ChromaDB Status
- Latest stable release on PyPI, actively maintained
- Lightweight: runs in-process (no server needed for dev)
- Persistent storage via local directory
- Good for prototyping; can migrate to hosted Chroma or another vector DB later

### Embedding Model Choice
Anthropic doesn't offer embeddings. Best open-source options:

| Model | Dimensions | Performance | Notes |
|-------|-----------|-------------|-------|
| **nomic-embed-text-v2-moe** | 768 | Top-tier open source | MoE architecture, multilingual, Apache 2.0 |
| **sentence-transformers/all-MiniLM-L6-v2** | 384 | Good baseline | Fastest, smallest, well-tested |
| **BAAI/bge-large-en-v1.5** | 1024 | Strong English | Larger but more accurate |

### Recommendation: **nomic-embed-text-v2-moe** via sentence-transformers
- Best quality among open-source options
- Runs locally (no API cost for embeddings)
- ChromaDB supports custom embedding functions

### Chunking Strategy
For research documents:
- **Semantic chunking** — Split by paragraphs/sections, not fixed character count
- **Preserve metadata** — Keep source URL, title, date with each chunk
- **Overlap** — 10-20% overlap between chunks to preserve context at boundaries
- **Target size** — 500-1000 tokens per chunk (balances retrieval precision vs context)

### Sources
- [ChromaDB](https://www.trychroma.com/)
- [Nomic Embed v2](https://huggingface.co/nomic-ai/nomic-embed-text-v2-moe)
- [Open source embedding comparison](https://www.bentoml.com/blog/a-guide-to-open-source-embedding-models)
- [Chunking strategies](https://weaviate.io/blog/chunking-strategies-for-rag)

---

## 7. Eval Frameworks

### Options

| Framework | Approach | Best For |
|-----------|----------|----------|
| **DeepEval** | pytest-native, 14+ metrics (hallucination, faithfulness, relevance) | LLM output quality |
| **Pydantic Evals** | Schema-based validation | Structured output correctness |
| **LangSmith** | Platform with tracing + evals | Production monitoring |
| **Custom pytest** | Manual assertions | Tool behavior, integration tests |

### Recommendation: **DeepEval + custom pytest**
- DeepEval integrates with pytest (`deepeval test run`)
- Built-in metrics: hallucination, answer relevancy, faithfulness, contextual precision/recall
- Agent-specific metrics: tool correctness, step necessity
- Custom pytest for: tool execution tests, RAG retrieval quality, end-to-end agent behavior
- No vendor lock-in (unlike LangSmith)

### Eval Categories for This Project
1. **Tool evals** — Does web search return relevant results? Does page reader extract clean content?
2. **RAG evals** — Does retrieval return relevant chunks? Is context sufficient for the question?
3. **Agent evals** — Does the agent complete research in reasonable steps? Does it use tools appropriately?
4. **Output evals** — Are reports well-structured? Are sources cited? Is confidence calibrated?

### Sources
- [DeepEval](https://deepeval.com/docs/getting-started)
- [Pydantic Evals](https://ai.pydantic.dev/evals/)
- [Agent eval metrics](https://deepeval.com/guides/guides-ai-agent-evaluation-metrics)
- [Top eval tools 2026](https://www.goodeyelabs.com/articles/top-ai-agent-evaluation-tools-2026)

---

## Feasibility Verdict

**All components are mature and well-documented.** No technical blockers.

| Component | Maturity | Risk |
|-----------|----------|------|
| Claude tool use | Production-ready | Low |
| Structured outputs | GA, Pydantic support | Low |
| Streaming | Production-ready | Low |
| Tavily search API | Production-ready | Low (free tier for dev) |
| trafilatura extraction | Stable, well-maintained | Medium (some sites block) |
| ChromaDB + nomic embeddings | Stable | Low |
| DeepEval | Active, pytest-native | Low |

The riskiest piece is **web scraping reliability** — some sites will block requests. Mitigation: use Tavily's Extract API as fallback.
