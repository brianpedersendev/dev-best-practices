# Planning Inputs

## Source Material
- [x] Research synthesis: docs/stock-mcp-research/SYNTHESIS.md
- [x] Project brief: docs/PROJECT-BRIEF.md
- [x] Technical research: docs/stock-mcp-research/technical.md
- [x] Domain research: docs/stock-mcp-research/domain.md
- [x] Landscape research: docs/stock-mcp-research/landscape.md

## Key Decisions Already Made
- **Language**: Python (better finance library ecosystem)
- **Framework**: FastMCP 3.0 (industry standard, decorator-based, 5x faster dev)
- **Data sources**: yfinance (prices) + Finnhub (fundamentals/news) + FMP fallback
- **Knowledge base**: SQLite + FTS5 (not vector DB for v1)
- **Portfolio storage**: JSON files (simple, portable)
- **Build vs extend**: Build custom (knowledge base layer is unique, no existing MCP does it)
- **Target user**: Brian only (personal tool, no multi-user)
- **Disclaimers**: Not needed for v1 (personal use only). Add if ever shared.
- **Scope**: ~8-10 MCP tools, focused on thesis tracking + fundamentals + beginner screening
- **News integration**: IN v1 scope (user confirmed). Finnhub provides free news API.

## Constraints
- Solo developer, beginner investor
- Free APIs only (no paid tiers)
- Local deployment (Claude Desktop / Cowork MCP)
- 1-2 week build target
- Python 3.10+ required for FastMCP 3.0

## Open Questions — RESOLVED
- "Not financial advice" → Not needed for personal use, skip for v1
- Python vs TypeScript → Python (decided)
- Vector DB vs SQLite → SQLite + FTS5 (decided)
- Existing MCPs → Build custom, study MaverickMCP for patterns
- News in v1? → YES, include news integration via Finnhub
