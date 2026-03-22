---
name: topic-deep-dive
description: >
  Research and write a comprehensive topic guide for the AI-augmented development knowledge base. Use whenever someone wants to add a new topic, says 'research [topic]', 'write a guide on [topic]', 'deep dive into [topic]', 'add [topic] to the knowledge base', 'I need a guide for [topic]', or when the knowledge-review skill identifies a missing topic that should be covered. Produces a thoroughly sourced, actionable guide following the knowledge base's established format and quality standards. Always checks INDEX.md first to avoid duplicates.
---

# Topic Deep Dive

Research a topic thoroughly and produce a comprehensive, actionable guide that meets the knowledge base's quality bar. Every guide produced by this skill should pass the test: "Would this change how I build something?"

## Before Starting

### Duplicate Check (Mandatory)

Before researching anything:

1. Read INDEX.md completely
2. Search for the topic in existing files (check topics/, research/, and references/)
3. If the topic already exists:
   - **If it needs updating:** Use the knowledge-review skill instead, or update the existing file directly
   - **If it partially overlaps:** Narrow the new topic's scope to avoid duplication, and plan cross-references to the existing file
4. If the topic is in the "Watching" section of INDEX.md, note this — the guide may need to acknowledge that the space is still maturing

### Scope Definition

Before researching, define what the guide will and won't cover. Write a brief scope statement:

```
Topic: [name]
Scope: [what this guide covers]
Not in scope: [what's explicitly excluded — usually covered by other guides]
Target reader: [who benefits from this — solo dev, team lead, architect?]
Existing related guides: [list 2-3 related files this connects to]
```

Present this to the user and get confirmation before proceeding. Scope drift wastes research time.

**Output location:** Save the guide to `docs/topics/[topic-name].md` using kebab-case for the filename (e.g., `docs/topics/agent-memory-patterns.md`).

**If triggered by another skill:** When the daily-briefing or knowledge-review skill identifies a missing topic, reference the specific briefing entry or review finding that prompted this deep dive in the scope definition.

## Research Process

### Research Strategy

Use a structured multi-source approach. The goal is triangulated, verifiable findings — not a summary of the first few search results.

**Step 1: Landscape Survey (breadth)**
Run 5-8 broad web searches to understand the current state of the topic:
- `[topic] best practices 2026`
- `[topic] guide tutorial`
- `[topic] comparison [alternative approaches]`
- `[topic] production experience`
- `[topic] common mistakes pitfalls`

Skim results to identify key themes, tools, patterns, and debates.

**Step 2: Deep Research (depth)**
For each key theme identified, run targeted searches:
- Official documentation for tools/frameworks mentioned
- GitHub repos with high star counts
- Conference talks and technical blog posts from practitioners
- Academic papers or industry reports with data
- Community discussions (Stack Overflow, Reddit, HN) for real-world pain points

**Step 3: Verification (rigor)**
For every quantitative claim or strong recommendation:
- Find at least 2 independent sources that agree
- Check the date — is this from 2025 or later?
- Look for counter-evidence — what do critics say?
- If only one source exists, mark the claim as "reported by [source], unverified independently"

**Step 4: Practical Validation**
- Are there working code examples or repos demonstrating this?
- Have real teams used this in production? What were their results?
- What are the common failure modes?

### Source Requirements

Every guide must have:
- **Minimum 15 unique sources for mature topics, minimum 8 for emerging topics** — URLs to docs, repos, papers, articles. For emerging topics, explicitly acknowledge limited evidence.
- **At least 3 primary sources** (official docs, original research, first-party data)
- **No claims without attribution** — if you can't source it, either cut it or mark it "unverified"
- **Dated sources** — prefer 2025-2026; flag anything older as potentially stale

### Checkpoint 2: Research Review

After completing research but before writing the full guide, present the key findings and proposed guide outline to the user:

- "Here's what I found. The main themes are [X, Y, Z]."
- "I'm planning to structure the guide as: [section outline]."
- "Any areas you want me to dig deeper on, or should I proceed with the write-up?"

Do NOT write a full guide without confirming the research direction is right. A 2000-line guide built on the wrong research is waste.

## Guide Structure

Follow this template. Adapt section names to the topic, but maintain the structural pattern.

**Required sections:** Why This Matters, core content sections (2-8), Common Mistakes & Anti-Patterns, Related Topics, Sources. **Optional sections** (include when relevant): Production Patterns, Decision Framework, Implementation Checklist.

**Target length:** Most guides are 800-2000 lines. If you're over 3000 lines, consider splitting into multiple guides. Under 500 likely means insufficient depth.

```markdown
# [Topic Title]: [Subtitle That Explains the Value]

> [One-line summary of what this guide covers and who it's for]
> Last updated: YYYY-MM-DD

---

## Why This Matters

[2-3 paragraphs: the problem this topic addresses, why it's relevant now, what's at stake.
Include at least one specific data point or example. Connect to the broader knowledge base
context — how does this relate to TDD, session discipline, or other core practices?]

## [Core Content Section 1]

[The meat of the guide. This varies by topic but should follow these principles:]

### Structure principles:
- **Lead with the practical.** What do I do? Then why.
- **Include code when relevant.** Real snippets, not pseudocode. Specify language, framework, and version.
- **Use tables for comparisons.** Tool X vs Y, approach A vs B — tables are faster to scan than prose.
- **Call out decision points.** "If you're building X, use approach A. If Y, use approach B."
- **Quantify where possible.** "Reduces latency by 40%" beats "significantly faster."

## [Core Content Section 2]

[Continue with the main content. Break into logical sections.
Each section should be independently useful — someone should be able to
read just one section and take action.]

## [Core Content Section 3+]

[As many sections as the topic requires. Most guides have 4-8 major sections.]

## Production Patterns

[If the topic involves building or configuring something, include production-ready examples.
These should be copy-paste ready, not simplified demos.]

## Common Mistakes & Anti-Patterns

[What goes wrong. Every guide should have this section. Be specific:
"Don't do X because Y happens" with a concrete example.]

## Decision Framework

[If the topic involves choices (which tool, which approach, when to use this),
provide a clear decision tree or matrix.]

## Implementation Checklist

[Actionable steps to apply the guide. Ordered by priority.
Each item should be specific enough to complete without re-reading the guide.]

- [ ] [Step 1 — the first thing to do]
- [ ] [Step 2]
- [ ] [Step N]

## Related Topics

- **[Related Guide 1](../relative/path.md)** — [one-line description of how it connects]
- **[Related Guide 2](../relative/path.md)** — [one-line description]
- **[Related Guide 3](../relative/path.md)** — [one-line description]

## Sources

[Numbered list of all sources cited in the guide]

1. [Source name](URL) — [brief description of what this source provides]
2. [Source name](URL) — [brief description]
...
```

## Quality Bar (MANDATORY — Verify Before Integration)

Run through this checklist before updating INDEX.md or presenting to the user. If any check fails, fix it first.

### Content Quality
- [ ] **Actionable** — Every section answers "what do I do?" not just "what exists?"
- [ ] **Specific** — Uses "Use X with Y to achieve Z" not "X is useful"
- [ ] **Sourced** — Every quantitative claim has a citation. Minimum 15 unique sources.
- [ ] **Current** — No primary recommendations based on pre-2025 data without noting it
- [ ] **Balanced** — Includes limitations, tradeoffs, and when NOT to use the recommended approach
- [ ] **No filler** — Every paragraph changes how someone would build something. Cut anything that doesn't.

### Structural Quality
- [ ] **Standalone** — Someone can read just this guide and take action, without reading others first
- [ ] **Scannable** — Uses headings, tables, bullet points, and code blocks. Long prose paragraphs are broken up.
- [ ] **Cross-referenced** — Links to 2-3 related guides in the knowledge base
- [ ] **Decision support** — Includes a decision framework or matrix if the topic involves choices
- [ ] **Anti-patterns** — Documents common mistakes, not just best practices

### Knowledge Base Integration
- [ ] **Checked INDEX.md** — No duplicate entry exists
- [ ] **Consistent terminology** — Uses the same terms as other guides (e.g., "MCP server" not "MCP plugin")
- [ ] **Doesn't contradict** — Cross-checked recommendations against related guides
- [ ] **Dated** — File has a "Last updated" date

## After Writing

1. **Update INDEX.md** — Add an entry in the Topics table with the date, file path, and a comprehensive one-line description
2. **Update GETTING-STARTED.md** — If this guide would help someone getting started, add a link with a clear description under the appropriate section
3. **Add cross-references** — In the 2-3 most related existing guides, add a link back to this new guide in their "Related Topics" section
4. **Present to user** — Summarize what the guide covers, highlight the most actionable findings, and note any surprises or contradictions discovered during research

## Adapting to Topic Complexity

**For mature, well-documented topics** (e.g., a popular framework):
- Focus on practical patterns and production gotchas that aren't in official docs
- Include benchmark comparisons and real-world performance data
- The guide's value is curation and decision support, not basic documentation

**For emerging topics** (in the "Watching" section of INDEX.md):
- Be explicit about maturity level: "This is emerging. Production adoption is limited."
- Focus on what's proven vs. what's promising
- Include a "Watch for" section noting what would make this production-ready
- Set a re-review date (1-2 months)

**For broad topics** (e.g., "security"):
- Narrow the scope aggressively. "Security" is a topic for a book, not a guide.
- Focus on the intersection with AI-augmented development specifically
- Link to authoritative external resources for the broader topic

## Integration with Other Skills

- **knowledge-review:** If this topic was identified as a gap during a knowledge-review audit, reference the review report date and finding number. After the guide is written, the gap should be marked as resolved in the next review.
- **daily-briefing:** If a daily briefing finding triggered this deep dive, cite the specific briefing date and finding in the "Why This Matters" section.
- **project-scaffold / project-research:** If the new topic covers patterns that should inform project scaffolding (e.g., a new testing framework, a new MCP server pattern), note this so future scaffold runs can incorporate it.

## Anti-Patterns

- **Writing before researching** — Always complete the research phase before drafting. Drafting first then backfilling sources produces biased guides.
- **Summarizing docs** — The guide should add value beyond official documentation. If everything in the guide is in the docs, link to the docs instead.
- **Skipping the duplicate check** — Duplicate entries are the worst knowledge base problem. Always check INDEX.md first.
- **Scope creep during writing** — If you discover a subtopic that deserves its own guide, note it for later. Don't expand the current guide beyond its defined scope.
- **Unreferenced code** — Code examples should specify language, framework version, and any dependencies. Code without context is dangerous — it might work with v1 but break with v2.
- **Copying the template verbatim** — The template is a structural guide, not a fill-in-the-blank form. Adapt section names and structure to fit the topic naturally.
