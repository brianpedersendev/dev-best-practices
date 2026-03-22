---
name: knowledge-review
description: >
  Perform a quality audit of the AI-augmented development knowledge base. Use whenever someone says 'review the knowledge base', 'audit topics', 'check for staleness', 'quality check', 'what needs updating', 'review research', 'find stale content', 'knowledge base health', or when the knowledge base hasn't been reviewed in more than 2 weeks. Systematically checks every topic file for unsourced claims, stale data, broken links, contradictions, missing cross-references, and structural issues. Produces an actionable review report and optionally fixes issues found.
---

# Knowledge Base Review

Perform a systematic quality audit of the entire knowledge base. This skill catches problems that accumulate over time: claims that lost their sources during editing, data that's gone stale, contradictions introduced by new topics, and structural inconsistencies.

## When to Run This

- **Scheduled:** Every 2 weeks minimum. The knowledge base quality degrades over time as the AI dev landscape shifts.
- **After bulk additions:** When 3+ new topic files are added in a session, run a review to catch cross-document issues.
- **Before sharing:** If someone is about to reference the knowledge base for a decision, verify the relevant sections are current.
- **On request:** Whenever the user asks for a review, audit, or health check.

## Before Starting

1. **Find the last review.** Check `docs/research/` for `REVIEW-*.md` files. Read the most recent one to understand what was found last time and what actions were taken.
2. **Estimate scope.** Count files in `docs/topics/`, `docs/research/`, `references/`, `DailyBriefing/`, and root `.skill` files. A full review of 35+ topic files typically requires 20-30 web searches.
3. **Choose review depth:**
   - **Full review** (default): All 5 phases. Best for scheduled reviews or pre-sharing audits.
   - **Quick review**: Phase 1 (structural) + Phase 2 (freshness) on files updated more than 3 months ago only. Best when time is short or after minor additions.

## Review Process

### Phase 1: Structural Integrity

Check the scaffolding of the knowledge base before reviewing content.

**INDEX.md Accuracy**
- Every file in `docs/topics/`, `docs/research/`, `references/`, `DailyBriefing/`, and root `.skill` files has a corresponding INDEX.md entry
- No INDEX.md entries point to files that don't exist (broken links)
- Descriptions in INDEX.md accurately summarize the actual file content
- Dates in INDEX.md match the last meaningful update date of each file

**GETTING-STARTED.md Coverage**
- Every topic guide that would help someone getting started has a link in GETTING-STARTED.md
- Links in GETTING-STARTED.md are not broken
- Descriptions are current (not describing a v1 of a file that's been significantly updated)

**Cross-References**
- Each topic file has a "Related Topics" section (or equivalent) linking to 2-3 related guides
- Cross-references are bidirectional (if A links to B, B should link to A where relevant)
- No circular-only references (A→B→A with no external connections)

**File Structure**
- No orphaned files (files that exist but aren't in INDEX.md)
- No empty files or stub files that were never completed
- Consistent formatting across topic files (headings, source sections, etc.)

### Phase 2: Content Freshness

Check every topic file for staleness. This is the most important phase.

**Staleness Detection Rules**
Per CLAUDE.md: anything older than 3 months should be flagged for re-verification.

For each topic file, check:

1. **Date check** — Is the file's last update date more than 3 months old? If yes, flag it.
2. **Specific version numbers** — Does the file reference specific tool versions, star counts, install counts, benchmark scores, or pricing? These go stale fastest. Search the web to verify current numbers.
3. **Tool/framework status** — Has any tool mentioned in the file been deprecated, acquired, renamed, or had a major version change?
4. **Benchmark data** — Are SWE-bench scores, HumanEval results, or other benchmarks still current?
5. **Pricing data** — Are subscription costs, API pricing, and token costs still accurate?
6. **Security data** — Have CVE statuses changed? Are vulnerability counts still accurate?
7. **Ecosystem counts** — MCP server counts, GitHub stars, ClawHub skill counts, etc.

**How to Verify**
- Run targeted web searches for each stale data point
- Check official documentation and changelogs
- Cross-reference multiple sources when updating numbers
- When a specific number can't be verified, mark it as "unverified as of [date]"

### Phase 3: Source Integrity

Check that claims are properly sourced.

**Prioritize source-checking by file importance.** Start with files that have the most quantitative claims or are most frequently cross-referenced by other guides (typically: SYNTHESIS.md, cost-optimization-playbook.md, testing-ai-generated-code.md, tool-comparison-when-to-use.md, ai-native-architecture.md). Then spot-check remaining files.

**For each topic file:**

1. **Quantitative claims** — Every specific number (percentages, benchmarks, costs, counts) must have a source. Flag any that don't.
2. **Source freshness** — Are sources from 2025 or later? Sources from 2024 or earlier may be outdated for rapidly evolving topics.
3. **Source availability** — Spot-check 3-5 source URLs per file for high-priority files; 1-2 per file for others. Flag any that return 404 or have been taken down.
4. **Attribution accuracy** — Do sources actually say what the text claims they say? Flag any misattributions found during spot-checks.
5. **Overconfident language** — Look for definitive statements ("always," "never," "the best") that should be hedged with conditions or ranges.

### Phase 4: Cross-Document Consistency

Check that different files don't contradict each other.

**Common contradiction areas:**
- Tool recommendations (does one file recommend X while another warns against it?)
- Benchmark numbers (are the same benchmarks cited consistently across files?)
- Best practices (do workflow recommendations conflict between guides?)
- Framework comparisons (are framework strengths/weaknesses consistent?)
- Cost figures (are pricing numbers consistent across cost playbook, tool comparison, and architecture guides?)

**For each contradiction found:**
1. Identify both files and the specific conflicting claims
2. Determine which is correct (via web search if needed)
3. Classify as: needs update (one is wrong), needs reconciliation (both are partially right), or needs decision tree (context-dependent)

### Phase 5: Gap Analysis

Identify topics that should exist but don't.

**Check for gaps by:**
1. Reading the "Watching" section of INDEX.md — has any watching item matured enough to warrant a full topic guide?
2. Reviewing recent DailyBriefing entries — have recurring themes emerged that aren't covered by any topic?
3. Checking the example projects — do they reference patterns or tools not covered in the knowledge base?
4. Scanning for frequently-mentioned concepts in topic files that don't have their own dedicated guide

For any gap identified, note it in the report and suggest using the **topic-deep-dive** skill to fill it.

## Review Report Format

Write to `docs/research/REVIEW-YYYY-MM-DD.md`:

```markdown
# Knowledge Base Review Report

**Date:** YYYY-MM-DD
**Scope:** Full audit of /home/user/dev-best-practices — [N] topic guides, [N] research docs, [N] daily briefings, [N] skill files
**Previous Review:** [date of last review, or "None" if first]

---

## Overall Assessment: [One-line summary]

[2-3 sentence overview of knowledge base health. Include: total file count, source count, major issues found, overall quality trend since last review.]

---

## 1. Structural Issues

| Issue | Detail | Severity |
|-------|--------|----------|
| [description] | [specifics] | Critical/High/Medium/Low |

[Or "No structural issues found." if clean.]

## 2. Stale Content

| File | Stale Data Point | Current Value | Source |
|------|-----------------|---------------|--------|
| [file] | [what's stale] | [updated value] | [URL] |

[Or "All content is current." if nothing is stale.]

## 3. Unsourced or Poorly Sourced Claims

| Claim | File | Issue |
|-------|------|-------|
| [claim text] | [file] | [missing source / broken link / misattributed] |

## 4. Contradictions Between Files

### 4a. [Contradiction title]
- **File A** says: [claim]
- **File B** says: [conflicting claim]
- **Resolution:** [which is correct, or how to reconcile]

## 5. Missing Topics

| Topic | Priority | Rationale |
|-------|----------|-----------|
| [topic] | High/Medium/Low | [why it should exist] |

## 6. Overconfident or Misleading Claims

| Claim | File | Recommended Fix |
|-------|------|----------------|
| [claim] | [file] | [how to hedge it] |

## 7. Strengths Worth Preserving

[List 3-5 things the knowledge base does well. This anchors the review in what's working, not just what's broken.]

---

## Recommended Action Plan

[Numbered list of specific actions, ordered by priority. Each action should be specific enough to execute without further research.]

1. **[Action]** — [details]
2. **[Action]** — [details]
...
```

## Executing Fixes

After presenting the review report, ask the user whether to:

1. **Fix all issues** — Systematically work through the action plan
2. **Fix critical/high only** — Address only the most impactful issues
3. **Report only** — Just produce the review, don't change anything
4. **Fix specific items** — Let the user pick which actions to execute

When fixing issues:
- Update the topic file with the corrected information
- Add a datestamp comment near the change
- Update INDEX.md if descriptions change
- Update GETTING-STARTED.md if relevant
- Log all changes at the bottom of the review report
- **Add the review report to INDEX.md** — Add an entry in the Research Outputs table with the date, file path, and a brief description

## Integration with Other Skills

- **daily-briefing:** Review recent `DailyBriefing/` entries as input to Phase 2 (freshness) and Phase 5 (gap analysis). If the daily-briefing skill has been surfacing recurring themes, that's a signal for a gap.
- **topic-deep-dive:** When Phase 5 identifies missing topics, recommend using topic-deep-dive to create them. Include the topic name and priority in the handoff.
- **project-scaffold:** If the review finds that recommended tooling patterns have changed (new MCP servers, deprecated hooks), note that existing scaffolds may need regeneration.

## Quality Checks for the Review Itself

Before presenting the review, verify:

- [ ] Every issue has specific file paths and line-level detail
- [ ] Stale data points include the current correct value (verified via search)
- [ ] Contradictions cite both files and the specific conflicting text
- [ ] The action plan is ordered by impact, not by category
- [ ] You didn't flag stylistic preferences as "issues" — focus on accuracy and completeness
- [ ] The overall assessment is honest, not hedged into meaninglessness

## Anti-Patterns

- **Surface-level review** — Checking only INDEX.md without reading topic files. Every topic file needs at least a skim for obvious staleness.
- **Reviewing without searching** — Staleness detection requires web searches. You can't know if a benchmark score is current without checking.
- **Fixing without reporting** — Always produce the review report first. The user should see what was found before changes are made.
- **Scope creep** — A review audits and fixes existing content. It doesn't write new topic guides (use the topic-deep-dive skill for that).
- **Flagging everything** — Not every slightly-old number needs updating. Focus on data points that drive decisions. A star count being off by 500 matters less than a security advisory being missed.
