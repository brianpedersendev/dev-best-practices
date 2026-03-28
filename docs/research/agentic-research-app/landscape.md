# Competitive Landscape: AI Research Agents

**Date:** 2026-03-28

## Major Players

### ChatGPT Deep Research (OpenAI)
- **What:** AI agent that autonomously browses the web for 5-30 minutes to generate cited reports
- **Model:** GPT-5.2-based (Feb 2026 overhaul)
- **Pricing:** $20/mo (Plus, limited queries), $200/mo (Pro, more queries)
- **Key Feb 2026 updates:** MCP server connections, restrict searches to trusted sites, real-time progress tracking, fullscreen document viewer with export (Markdown, Word, PDF)
- **Strengths:** Most polished UX, strong report formatting, OpenAI ecosystem
- **Weaknesses:** Overconfident (reports wrong answers instead of admitting uncertainty), unreliable source selection (prioritizes unreliable sources over authoritative ones), expensive at $200/mo, closed ecosystem
- **Sources:** [OpenAI](https://openai.com/index/introducing-deep-research/), [Wikipedia](https://en.wikipedia.org/wiki/ChatGPT_Deep_Research), [FutureSearch analysis](https://futuresearch.ai/oaidr-feb-2025/)

### Perplexity AI
- **What:** AI-powered search engine with Research mode for multi-step, citation-backed reports
- **Pricing:** Free (limited), Pro $20/mo (unlimited Pro + 20 research/day), Max $200/mo (frontier models, Labs access)
- **Strengths:** Fast, good UX, inline source citations, developer-friendly
- **Weaknesses:** 37% hallucination rate on news citations (Columbia Journalism Review study). Cites real sources with fabricated claims. GPTZero found users encounter AI-generated sources within 3 queries on average
- **Key concern:** "Second-hand hallucinations" — sources themselves may be AI-generated
- **Sources:** [Perplexity Pricing](https://www.perplexity.ai/help-center/en/articles/11187416), [GPTZero investigation](https://gptzero.me/news/gptzero-perplexity-investigation/), [Oreate AI](https://www.oreateai.com/blog/understanding-perplexitys-hallucination-rate-in-deep-research-models/6dbf8101a24f731ff4d2e67e733a35ee)

### Google Gemini Deep Research
- **What:** Agentic feature that browses hundreds of websites and your Gmail/Drive/Chat, produces multi-page reports
- **Pricing:** Free (limited access), AI Pro $19.99/mo, AI Ultra $249.99/mo
- **Strengths:** 2M token context window (largest), integrates with Google Workspace data, research plan review before execution
- **Weaknesses:** Higher cost at Ultra tier, Google ecosystem lock-in
- **Sources:** [Gemini Deep Research](https://gemini.google/overview/deep-research/), [9to5Google features list](https://9to5google.com/2026/03/17/google-ai-pro-ultra-features/)

### Elicit
- **What:** AI research assistant for academic literature — search, summarize, extract data from 138M+ papers + 545K clinical trials
- **Pricing:** Free (5,000 credits/mo), Plus from $12/mo
- **Strengths:** Purpose-built for scientific research, reduces lit review time by 80%, high accuracy
- **Weaknesses:** Academic-only, not general web research
- **Sources:** [Elicit](https://elicit.com/), [CompareGen comparison](https://www.comparegen.ai/blog/best-ai-research-tools-academics-2026)

### Consensus
- **What:** AI academic search engine for peer-reviewed literature
- **Strengths:** Scientific credibility, peer-reviewed sources only
- **Weaknesses:** Academic niche only
- **Sources:** [Consensus](https://consensus.app/)

## Open-Source Alternatives

### GPT Researcher
- **What:** Mature open-source deep-research agent. Plans, searches, reads, writes long-form reports with citations
- **Architecture:** Planner → concurrent executor agents → publisher pipeline. Planner generates sub-questions, executors crawl 20+ sources per task, publisher aggregates into structured report
- **Built on:** LangGraph for multi-agent orchestration
- **Stars:** Actively maintained, well-documented
- **Strengths:** Closest to our concept, proven architecture, customizable
- **Weaknesses:** Tied to OpenAI by default, framework-heavy (LangGraph dependency)
- **Sources:** [GPT Researcher](https://gptr.dev/), [GitHub](https://github.com/assafelovic/gpt-researcher), [Tavily docs](https://docs.tavily.com/examples/open-sources/gpt-researcher)

### LangChain Open Deep Research
- **What:** Open-source deep researcher built on LangGraph. Simple, configurable — bring your own models, search tools, MCP servers
- **Architecture:** Scoping (user clarification + brief generation) → sub-agent research → supervisor evaluation
- **Key feature:** Sub-agents research independently, supervisor checks if findings address the brief
- **Sources:** [LangChain blog](https://blog.langchain.com/open-deep-research/)

### AutoGPT
- **What:** Open-source autonomous agent with visual Agent Builder, persistent server, plugin system (2026 version)
- **Research flow:** Goal → sub-tasks → web browsing + file management → vector DB storage → self-evaluation → iterate
- **Stars:** 46K+ GitHub stars
- **Weaknesses:** Susceptible to error compounding (relies on own feedback), tendency to hallucinate, no human correction loop
- **Sources:** [AutoGPT](https://agpt.co/), [Wikipedia](https://en.wikipedia.org/wiki/AutoGPT)

### CrewAI
- **What:** Multi-agent framework at 46K GitHub stars (v1.10.1, March 2026). Think in roles: researcher, writer, reviewer
- **Strengths:** Fastest prototyping (2-4 hours), marketplace of pre-built crews, native MCP + A2A support
- **Sources:** [CrewAI](https://openagents.org/blog/posts/2026-02-23-open-source-ai-agent-frameworks-compared)

### LangGraph
- **What:** Graph-based agent orchestration at 26.3K stars
- **Strengths:** Fine-grained control, streaming, persistence, checkpointing
- **Weaknesses:** Steeper learning curve than CrewAI
- **Sources:** [Framework comparison](https://dev.to/linou518/the-2026-ai-agent-framework-decision-guide-langgraph-vs-crewai-vs-pydantic-ai-b2h)

## Known Gaps & User Complaints

### Universal Problems (all tools)
1. **Hallucinations remain unsolved** — Even the best tools (Perplexity) have 37% hallucination rates on citations
2. **Overconfidence** — Tools report wrong answers confidently instead of flagging uncertainty
3. **Poor source selection** — Prioritize unreliable/AI-generated sources over authoritative ones
4. **No domain depth** — All general-purpose tools are shallow in specialized domains
5. **Can't question own assumptions** — AI summarizes but doesn't think critically

### Reddit/HN Sentiment
- "Impressive demo, genuinely useful for specific tasks, too expensive at $200" — common r/ChatGPT view
- 80-90% of AI agent projects fail in production (RAND study cited in Reddit threads)
- Many products labeled "AI agents" are just automation workflows with chatbot interfaces
- Heavy users run both ChatGPT Deep Research (better prose) and Gemini (better source recall for technical topics)
- **Sources:** [HN: Less capability, more reliability](https://news.ycombinator.com/item?id=43535653), [Reddit AI tools](https://www.aitooldiscovery.com/guides/best-ai-agents-reddit)

## Opportunity Analysis

### Where Current Tools Fall Short
1. **No vertical depth** — All tools are general-purpose. A real estate researcher needs different sources, data formats, and analysis than a stock researcher
2. **No persistent memory** — Each query starts fresh. No building on previous research
3. **No customizable sourcing** — Can't tell the agent "only use SEC filings and earnings transcripts" or "focus on MLS data and census records"
4. **No structured deliverables** — Reports are prose blobs, not structured data you can feed into spreadsheets or dashboards
5. **No eval/verification layer** — No confidence scoring, no cross-source validation, no uncertainty flagging

### Our Differentiators
- **Raw SDK = full control** — No framework abstractions hiding the patterns
- **Persistent RAG** — Build knowledge over time, not just per-query
- **Domain specialization** — Configurable for specific verticals
- **Structured outputs** — Pydantic models, not just prose
- **Eval suite** — Built-in quality measurement from day one
