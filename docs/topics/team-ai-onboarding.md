# Team AI Onboarding: From Individual Productivity to Scaled Adoption

**A practical playbook for getting development teams aligned on AI tooling, productive quickly, and maintaining quality standards across the organization.**

**Last Updated:** 2026-03-19
**Status:** Production-ready playbook with templates and timelines
**Confidence Level:** High (2025-2026 enterprise adoption research, case studies, operational data)

---

## Table of Contents

1. [The Team Adoption Challenge](#1-the-team-adoption-challenge)
2. [Phased Rollout Strategy](#2-phased-rollout-strategy)
3. [Shared Configuration Governance](#3-shared-configuration-governance)
4. [Code Review Standards for AI Code](#4-code-review-standards-for-ai-code)
5. [Training Program](#5-training-program)
6. [Quality Gates](#6-quality-gates)
7. [Cost Management for Teams](#7-cost-management-for-teams)
8. [Security Policies](#8-security-policies)
9. [Measuring Success](#9-measuring-success)
10. [Common Pitfalls](#10-common-pitfalls)
11. [Templates & Checklists](#11-templates--checklists)
12. [Sources](#sources)

---

## 1. The Team Adoption Challenge

### Why Individual Wins Don't Scale to Teams

When individual developers adopt AI coding tools, they see clear wins: faster code generation, fewer typos, accelerated learning. But when scaling across teams, adoption stalls at the exact moment it matters most—when consistent standards become critical.

**The adoption paradox:** 84% of developers report using or planning to use AI tools, yet only 52% express trust in AI-generated code. Even more revealing: when organizations provide AI tool access without structure and training, the result is a team that moves faster *and* accumulates technical debt 3x faster.

### The 85% Adoption / 52% Skepticism Reality

Research from 2025-2026 shows this pattern across enterprise rollouts:

- **85% of developers** adopt AI tools and use them daily (GitHub, METR, Faros data)
- **60% positive sentiment** (down from 70% in 2024 due to experience with edge cases and failures)
- **29% trust the accuracy** of AI-generated code (a sharp decline from 40%)
- **45% frustration** with "almost right" code (the "Uncanny Valley of Code")
- **39% of organizations** cite data privacy as primary adoption barrier
- **18% of developers** report insufficient training

**The fundamental problem:** Access without guidance produces chaos. You need deliberate structure to turn individual productivity gains into team velocity without creating technical debt, security vulnerabilities, or code review bottlenecks.

### Common Failure Modes

#### 1. Inconsistent Usage Patterns
**What happens:** Some developers integrate AI into their workflow; others use it only for "simple" tasks. Code quality varies by developer. Architecture decisions aren't consistent.

**Root cause:** No shared standards, no guidance on *when* to use AI vs when to hand-code. Developers making tool choice ad-hoc.

**Impact:** Code reviews become 30-50% more cognitively demanding (reviewing AI code requires different questions). Architectural consistency erodes.

**Prevention:** Establish team-level guidelines (Section 3) and enforce them via hooks (Section 6).

#### 2. No Shared Standards
**What happens:** Each developer configures their own CLAUDE.md, Cursor rules, or model selection preferences. Onboarding new team members requires them to reverse-engineer best practices by watching others.

**Root cause:** Individual optimization without organizational coordination.

**Impact:** 18% of new developers report feeling lost without structured guidance. Code patterns diverge. Merging becomes harder.

**Prevention:** Shared, versioned CLAUDE.md; centralized hook library; team-wide configuration audits.

#### 3. Security Gaps
**What happens:** Developers generate database migrations, auth logic, or API integrations with AI assistance. Secrets leak into commits. SQL injection vulnerabilities make it past code review.

**Root cause:** No explicit security policies distinguishing "AI-safe" tasks from "human-only" tasks. No automated secret scanning in the pipeline.

**Impact:** 45% of AI-generated code contains security flaws. A Fortune 50 study found a 10× increase in monthly vulnerabilities (1K → 10K) between Dec 2024 and June 2025.

**Prevention:** Security gates in CI/CD (Section 8). Escalation matrix for high-risk changes. Mandatory human review for auth, secrets, infrastructure.

#### 4. Unchecked Technical Debt
**What happens:** Developers ship AI-generated code faster, but the code lacks architectural coherence. Missing edge cases slip through. Test coverage remains shallow because "AI wrote it, so it must be right."

**Root cause:** Throughput optimization without quality discipline. No standards for what "done" means for AI-generated code.

**Impact:** 75% of technology leaders face moderate-to-severe technical debt by 2026 due to AI-accelerated practices. Refactoring debt becomes 2-3x larger than human-written code.

**Prevention:** TDD-first workflows (Section 5). Test coverage gates (Section 6). Multi-model code review (Section 4).

#### 5. Cost Explosion
**What happens:** Developers working on separate costs, token usage grows unchecked, monthly bills surprise finance. No visibility into what's driving costs.

**Root cause:** No per-developer budgeting, no cost monitoring, no model selection discipline.

**Impact:** Teams that don't implement cost controls see 40-60% overspend on token usage within the first 6 months of rollout.

**Prevention:** Token budgeting framework (Section 7). Cost dashboards. Model routing policies.

---

## 2. Phased Rollout Strategy

### The 3-Month Timeline

Successful enterprise rollouts follow a phased approach: start narrow (foundations), widen gradually (workflow alignment), then deepen (advanced patterns). This prevents overwhelming teams while building institutional knowledge.

### **Phase 1: Foundation (Weeks 1-2)**

**Goal:** Every developer has the same starting line. Establish shared configuration, enforcement hooks, and mandatory training.

**Week 1: Onboarding & Configuration**

1. **Kickoff meeting (30 min):** Why AI? What's expected? What's off-limits?
   - Show 2-3 real examples of AI helping with actual project work
   - Be explicit about security boundaries (Section 8)
   - Address fears (job displacement, code quality, security)

2. **Deploy shared CLAUDE.md** (team-specific, checked in to repo)
   - Architecture constraints and patterns the codebase follows
   - Forbidden patterns and antipatterns
   - Module-by-module guidelines (if large codebase)
   - See Template 1 (Section 11) for example

3. **Install mandatory hooks** (checked in, enforced pre-commit)
   - Linter/formatter (prevents style drift)
   - Test runner (blocks code without tests)
   - Secret scanner (blocks commits with API keys)
   - See hooks-enforcement-patterns.md for complete library

4. **Set up model selection policy**
   - Default model by task (Claude 3.5 Sonnet for complex tasks, GPT-4o-mini for routine edits, Gemini for large-context analysis)
   - Cost estimates per task type
   - Document in shared wiki

5. **Onboard tool choice** (1 hr workshop)
   - Claude Code vs Cursor vs Gemini: when and why
   - Each developer tries 2 tools, picks primary + fallback
   - Decide on team default (for consistency in code review expectations)

6. **Create team Slack/Discord channel** for AI questions, tips, gotchas

**Metrics to track:**
- % of developers with shared CLAUDE.md checked out
- Hook pass rate (should be >95% by end of week)
- % developers trained (should be 100%)

---

**Week 2: TDD & Spec-Driven Foundations**

1. **TDD workshop (90 min)**
   - Why TDD + AI works better (test contracts guide AI generation; 40-90% defect reduction)
   - Red-Green-Refactor with AI
   - Hands-on: small kata with TDD + AI pair
   - Handout: TDD with AI template (see Template 2)

2. **Spec-driven dev workshop (60 min)**
   - Write specification first, ask AI to implement
   - Benefits: 30-50% fewer iteration cycles, clearer code review
   - Example: "Write OpenAPI spec first, generate server stubs"
   - Practice: spec → review with team → AI implements → tests pass

3. **Plan Mode intro (Claude Code) / Composer (Cursor)**
   - Why planning before execution reduces token waste 50%
   - When to use: multi-file changes, refactoring, complex features
   - Practice: 20-minute exercise planning a small feature

4. **Code review calibration**
   - What *not* to check (linter issues, basic syntax—hooks handle this)
   - What *to* check (architecture, edge cases, security)
   - Pair review: 2 developers review same AI-generated PR, compare notes
   - See Template 3 (Section 11) for AI Code Review Rubric

5. **First real PR with AI** (optional but encouraged)
   - Pair a junior + senior, or an AI-skeptic + AI-experienced dev
   - Small scope (UI component, utility function, test harness)
   - Full code review, retrospective on process

**Success criteria by end of Week 2:**
- All developers have written ≥1 test in TDD flow
- All developers have reviewed ≥1 spec-driven PR
- Code review standards documented and shared
- 0 secrets in commits (hooks blocked them)
- Team agrees on tool split (80% use X, 20% have access to Y fallback, etc.)

---

### **Phase 2: Workflow Alignment (Weeks 3-4)**

**Goal:** Lock in patterns that work. Move from "we can use AI" to "here's how we use AI for different task types."

**Week 3: Task-Type Patterns**

Establish playbooks for common tasks:

**Type 1: Routine Implementation (Most PRs)**
- Spec exists ✓, Tests written ✓ → AI implements → Code review focuses on architecture
- Expected AI success rate: 85-95%
- Human focus: Does it fit the architecture? Missing edge cases?
- Tools: Claude Code Plan Mode (Claude) or Cursor Composer (Cursor)
- Time budget: 60-90 min per task (with testing)

**Type 2: Complex Refactoring**
- TDD characterization tests first (capture current behavior)
- AI refactors under test contracts
- Human focus: Does it break anything? Does new code improve readability?
- Tools: Gemini for 2M token context (whole codebase analysis), or Claude Code with hierarchical CLAUDE.md
- Time budget: 3-5 hours (with thorough testing)

**Type 3: Security & Infrastructure**
- AI generates *proposal* only
- Human reviews, modifies if needed, approves
- AI only implements *approved* version
- Never: AI writes auth, database migrations, deployment scripts without approval
- Tools: Claude Code with security-policy hooks enabled
- Time budget: 2× normal (extra review layer)

**Type 4: Testing & Documentation**
- AI writes first draft (often 70-90% complete)
- Human reviews, fixes edge cases
- AI regenerates based on feedback
- This is a good "AI is learning your codebase" task
- Tools: Any (Cursor often fastest iteration here)
- Time budget: 30-50% of hand-writing

**Type 5: Bug Investigation & Debugging**
- Use AI for hypothesis generation (often 3-5x faster)
- Plan Mode + multi-agent swarm to explore in parallel
- Human verifies fix, tests it
- Tools: Claude Code Plan Mode excels here; Gemini for large logs
- Time budget: 25-40% of traditional debugging

Document each pattern in a team wiki with:
- When to use it (trigger conditions)
- Step-by-step workflow
- Code example
- Common mistakes
- Expected quality/speed

---

**Week 4: Advanced Workflows & Pairing**

1. **Establish pairing model**
   - Pair AI-experienced with AI-skeptical developers (60% of teams report this accelerates adoption)
   - 2-3 pairing sessions per developer
   - Focus: "What can AI help with that I didn't realize?"
   - Outcome: Skeptics become advocates or identify legitimate concerns

2. **Multi-agent introduction** (optional, for teams working on large features)
   - Show how 3 agents investigating in parallel beat 1 human debugging
   - Setup: Agent 1 analyzes logs, Agent 2 examines code, Agent 3 writes hypothesis
   - Tools: CrewAI or Claude Agent SDK
   - Time saved: 11 min (multi-agent) vs 45+ min (single human)

3. **Spec review process**
   - Who writes specs? (architect or tech lead)
   - How are specs reviewed? (peer review before AI implementation)
   - How are specs versioned? (in CLAUDE.md or shared docs)

4. **First retrospective**
   - What's working well? (usually: test-driven tasks, refactoring, debugging)
   - What's surprising? (usually: AI struggles with unwritten patterns, business logic)
   - What needs policy? (security gaps, cost issues, quality gaps)
   - Update team guidelines based on findings

**End of Phase 1-2 metrics:**
- 60%+ of PRs use AI-assisted workflow
- Code review time stable or declining (hooks handling style checks)
- Test coverage stable or improving
- 0 security incidents related to AI-generated code
- Team consensus on tool usage
- Developer satisfaction >70%

---

### **Phase 3: Advanced Patterns (Month 2)**

**Goal:** Unlock team-wide leverage with multi-agent systems, custom skills, and workflow automation.

**Week 5-6: Custom MCPs & Skills**

- Identify 2-3 custom integration opportunities
  - Internal API wrappers (team MCP server)
  - Database explorer tool (for faster schema queries)
  - Monitoring/alerting integration
- Build with team (see building-custom-mcp-servers.md)
- Deploy to shared tool library
- Impact: Developer context-gathering time drops 30-40%

**Week 7-8: Skill Development**

- Build 1-2 reusable skills for common tasks
  - "Code review assistant" (multi-model review automation)
  - "Test generator" (spec → comprehensive test suite)
  - "Migration planner" (database change → step-by-step plan)
- Publish internally (private skill library)
- Document usage in team wiki

**End of Month 2 metrics:**
- 2-3 custom tools deployed and adopted
- 1-2 skills published, used by >50% of team
- Estimated time saved per developer: 5-10 hours/month
- Team has "force multiplier" workflows established

---

### **Phase 4: Optimization (Month 3+)**

**Goal:** Fine-tune costs, quality, and monitoring. Move from adoption to optimization.

- **Cost management:** Implement token budgeting, cost dashboards, model routing
- **Monitoring:** Set up observability for code quality metrics, AI usage patterns
- **Standards iteration:** Update CLAUDE.md based on 3 months of learnings
- **Advanced training:** Deepen knowledge for developers showing high aptitude
- **Mentorship program:** AI champions train new hires

---

## 3. Shared Configuration Governance

### The CLAUDE.md Problem at Scale

When one developer uses AI, their CLAUDE.md doesn't matter much. When 10 developers use AI with 10 different CLAUDE.md files, you have architectural chaos.

**The governance question:** Who owns the shared guidance? How does it change? How do you prevent one developer's preferences from conflicting with another's?

### Architecture: Centralized Guidance + Local Customization

**Model:** Single shared CLAUDE.md in repo root + optional tool-specific overrides in subdirectories.

```
repo/
├── CLAUDE.md                      # Shared, mandatory (checked in)
│   ├── Architecture constraints
│   ├── Forbidden patterns
│   ├── Module-by-module guidance
│   └── Security boundaries
├── backend/
│   └── .claude.md                 # Optional: Backend-specific constraints
├── frontend/
│   └── .cursor.rules              # Optional: Frontend-specific Cursor rules
└── .cursorrules                   # Optional: Global Cursor rules for IDE
```

### Who Owns It?

**Recommend:** A rotating team role (Architecture Lead + Engineering Manager).

- **Owner:** Responsible for accepting/rejecting proposed changes
- **Rotation:** Every quarter (prevents stagnation, spreads knowledge)
- **Process:** Pull requests to CLAUDE.md, same code review as code

### How Changes Are Proposed & Reviewed

1. **Propose change:** Developer opens PR with rationale
   - New architectural pattern discovered in the wild?
   - Lesson learned from a production issue?
   - New tool or technique to standardize?

2. **Review:** At least 2 approvals required (owner + architect)
   - Is this aligned with project goals?
   - Can we test this claim (e.g., "AI writes better tests with X pattern")?
   - Is the guidance clear and actionable?

3. **Trial period (optional):** For major changes
   - Mark as "experimental" for 2-4 weeks
   - Collect feedback from developers using it
   - Finalize or roll back

4. **Communicate:** Post in team channel with:
   - What changed
   - Why it matters
   - One example of the pattern

5. **Version:** Add date to CLAUDE.md header. Example:
   ```
   # Project CLAUDE.md
   # Last updated: 2026-03-19
   # Version: 2.3
   # Changes: Added "Spec-First Implementation" pattern for features >4hr est.
   ```

### Shared Hooks Library

Hooks should *also* be versioned and shared. Structure:

```
.git/
├── hooks/
│   ├── pre-commit/
│   │   ├── 00-linter.sh           # ESLint, Prettier, Black, etc.
│   │   ├── 10-test-runner.sh      # Run unit tests
│   │   ├── 20-secret-scanner.sh   # Prevent API key commits
│   │   └── 30-commit-msg.sh       # Enforce conventional commits
│   ├── post-merge/
│   │   ├── 01-dependency-check.sh # Check for new vulnerabilities
│   │   └── 02-migration-runner.sh # Run pending migrations
│   └── HOOKS.md                   # Documentation
├── hooks-config.json              # Rule toggles (per-team)
└── INSTALL_HOOKS.sh               # Setup script (in README)
```

**Best practice:** Some hooks are **mandatory** (security, tests); others are **recommended** (style, documentation).

**Example hook config:**
```json
{
  "hooks": {
    "linter": { "enabled": true, "severity": "mandatory" },
    "test-runner": { "enabled": true, "severity": "mandatory" },
    "secret-scanner": { "enabled": true, "severity": "mandatory" },
    "ai-guardrails": {
      "enabled": true,
      "severity": "recommended",
      "rules": ["no-database-migrations", "no-auth-changes"]
    }
  }
}
```

### MCP Server Standardization

If your team uses MCPs (custom integrations), standardize which ones are approved:

**Tier 1 (mandatory, installed for everyone):**
- Internal API wrapper
- Database explorer
- Documentation indexer

**Tier 2 (recommended, opt-in):**
- Monitoring/alerting integration
- Deployment status checker

**Tier 3 (experimental):**
- New integrations being tested

Document in team wiki:
- What each MCP does
- How to install it
- When to use it (per task type)
- Who maintains it

### .cursorrules / .mdc Consistency

If team uses Cursor, standardize .cursorrules across projects:

```
/ Global rules (apply to whole project)
- Always write tests before code
- Use TypeScript strict mode
- Reference architecture docs in CLAUDE.md

/frontend
- Use React hooks, not class components
- Follow component folder structure

/backend
- Use async/await, never promises
- Validate input at API boundary
```

**Governance:** .cursorrules lives in repo, reviewed same as CLAUDE.md.

### Enforcement Strategy

**Month 1:** Voluntary adoption (education phase)
- "Here's the shared CLAUDE.md, we recommend using it"
- 70%+ of developers adopt
- Share wins in team channel

**Month 2:** Hooks enforce (deterministic phase)
- Linter/formatter hooks prevent style divergence
- Test hooks prevent untested code
- Security hooks prevent obvious mistakes
- Optional AI-guardrail hooks warn on risky patterns

**Month 3:** Standards audit (verification phase)
- Spot-check recent PRs for CLAUDE.md compliance
- Identify divergent patterns
- Update guidelines if patterns are legitimate

---

## 4. Code Review Standards for AI Code

### The Review Challenge at Scale

AI code moves fast, but **reviewing AI code is cognitively harder than reviewing human code.** Why?

1. **Unfamiliar patterns:** AI sometimes invents novel approaches that *work* but don't match team style
2. **Edge case blindness:** AI often misses boundary conditions, concurrency issues, or rare paths
3. **Implicit contract violations:** AI doesn't "know" unwritten rules your codebase follows
4. **Scale:** Daily users ship 60% more PRs; reviewers can't keep up with volume

**Fact from 2026 research:** 75% of developers manually review *every* AI-generated snippet before merging. But this manual review isn't systematic—it's ad-hoc. Inconsistent. Slow.

**Solution:** Explicit code review standards for AI code.

### What Reviewers Should Focus On (Not Syntax)

**Stop checking:** Formatting, variable names, obvious syntax errors (linter/formatter handles this)

**Start checking:**

#### 1. Edge Cases & Boundary Conditions
**Question:** Does the code handle the unhappy path?

- Off-by-one errors? (often AI's weakness)
- Null/undefined values? (AI sometimes assumes non-null)
- Empty arrays/objects? (AI may skip these)
- Timeout/retry logic? (AI rarely adds this unprompted)
- Resource cleanup? (File handles, database connections, memory)

**How to check:** Scan for conditional logic. If there's only happy-path code, ask: "What if X is null?" or "What if this times out?"

**Example red flag:**
```javascript
// AI-generated, missing error handling
const data = await fetch(url).then(r => r.json());
processData(data);  // What if fetch fails? What if data is undefined?
```

#### 2. Security & Authorization
**Question:** Could this code leak secrets, accept untrusted input, or bypass auth?

**Common AI mistakes:**
- SQL injection (string concatenation instead of parameterized queries)
- Hardcoded credentials (API keys in config)
- Missing input validation (trusting user input)
- Path traversal (using user input in file paths)
- CORS misconfigurations
- Missing authentication checks

**How to check:** Ask "What if an attacker does X?" Look for:
- User input being used directly in queries, file paths, or shell commands
- Missing `.trim()`, `.toLowerCase()` on comparisons
- Credential validation skipped (AI assumes it's not needed)

#### 3. Architecture Conformance
**Question:** Does this code respect your system's architecture?

- Module dependencies correct? (No circular imports, respects layering)
- Consistent patterns? (Matches error handling, logging, configuration styles)
- Scalability implications? (Does it load the database in a loop? O(n²) algorithms?)
- Observability? (Logs at the right level? Metrics included?)

**How to check:** Compare to 2-3 similar files. If this code looks "alien," it probably violates implicit rules.

#### 4. Testability & Test Quality
**Question:** Are the tests actually testing what the code does?

**Common issues:**
- Tests always pass (no assertions)
- Tests only happy path
- Mocks used incorrectly (testing the mock, not the code)
- Tests don't verify error behavior
- Integration tests where unit tests would be clearer

**How to check:** Run tests locally, remove a line from the implementation, verify tests fail.

#### 5. Performance & Resource Usage
**Question:** Could this code cause performance problems at scale?

- N+1 query problems?
- Large memory allocations in loops?
- Unnecessary iterations or nested loops?
- Blocking operations where async would be better?
- Caching missing where it would help significantly?

#### 6. API Contract Compliance
**Question:** Does this implementation match the spec?

- Correct return types and shapes?
- Error cases handled as specified?
- Timeout/retry behavior correct?
- All required fields present?

### The "AI Code Red Flags" Checklist

Use this during code review:

```
Code Review Checklist for AI-Generated Code

Repository: _________  PR #: _____  File(s): _____________

□ Security
  □ No hardcoded credentials or secrets
  □ All user input validated/sanitized
  □ No SQL injection, path traversal, or command injection vectors
  □ Authentication/authorization checks present
  □ Sensitive operations logged (not passwords, just fact of access)

□ Edge Cases
  □ Null/undefined/empty collection handling
  □ Boundary conditions tested (zero, one, many)
  □ Timeout and error paths handled
  □ Resource cleanup (files, connections, memory)

□ Architecture
  □ Follows module/layering conventions
  □ Error handling matches team style
  □ No circular dependencies
  □ Consistent with similar code in codebase

□ Testing
  □ Tests verify behavior, not mocks
  □ Error cases tested
  □ Happy path tested
  □ Test coverage >80% for new code

□ Performance
  □ No obvious O(n²) or N+1 problems
  □ Appropriate algorithm choice
  □ Caching considered where relevant
  □ No blocking operations in async code

□ Maintainability
  □ Code is readable (variable names, structure)
  □ Complex logic has comments explaining *why*
  □ Follows language idioms
  □ Doesn't reinvent existing libraries

□ Other
  □ PR description explains what and why
  □ All automated checks pass (linter, tests, security scan)
  □ No regressions in related functionality
```

### Multi-Model Review Pattern

For critical code (auth, payment, infrastructure), use **multi-model adversarial review:**

1. **Claude writes** the implementation
2. **GPT-4 reviews** as a security-focused critic
3. **Gemini analyzes** for edge cases across large context
4. **Human reviewer** resolves disagreements

This catches ~15% more issues than single-model review.

**Implementation:**
```bash
# In your PR template or CI
./scripts/multi-model-review.sh PR_NUMBER
# Returns: [PASS / FLAG / FAIL] with specific concerns
```

### When to Require Human-Written vs AI-Generated

**Human-written required for:**
- Authentication & authorization logic
- Payment/billing systems
- Data migrations
- Deployment scripts
- Critical business logic (revenue calculations, compliance rules)

**AI-generated encouraged for:**
- Tests (often 70-90% complete, needs tweaking)
- Documentation & comments
- Boilerplate & scaffold code
- Utility functions
- Refactoring under test contracts
- Debugging investigation

**AI-generated with review for:**
- Feature implementation (spec-driven)
- Bug fixes (with tests)
- Performance optimizations
- Regular refactoring

**Mark in your PR:** Add label `ai-generated` or prefix in title `[AI-ASSIST]` so reviewers know to focus differently.

### Making Review Faster: Automated + Human

**Automate what machines do well:**

1. **Static analysis:** Semgrep (OWASP ruleset) catches security issues
2. **Test running:** Fail PR if tests don't pass
3. **Coverage:** Require ≥80% coverage for new code
4. **Linting:** Format, style, obvious mistakes
5. **Type checking:** TypeScript strict, Mypy strict, etc.
6. **Dependency scanning:** Known vulnerabilities in libraries
7. **Secrets scanning:** API keys, credentials
8. **AI safety checks:** Custom hooks that flag common AI mistakes

**Human focus on:**
- Architecture conformance
- Edge cases & boundary conditions
- Security context (does the attacker model matter?)
- Business logic correctness

This reduces review time 30-40% while catching more bugs.

---

## 5. Training Program

### The Adoption Bottleneck

**Research finding:** Companies implementing formal AI training programs report 40% faster adoption rates. But most teams don't have a formal program—they expect developers to "figure it out."

Result: 18% of developers report insufficient training, and they remain skeptical or under-utilize AI.

### What to Teach First (Weeks 1-2)

#### Module 1: Mindset Shift (30 min, mandatory)
- **Why:** Developers often approach AI as a code generator, not a reasoning partner
- **Content:**
  - AI as navigator/architect assistant, not replacement
  - Why thorough specs beat vague prompts (30-50% faster)
  - The Plan Mode advantage (think before executing)
  - Pair programming model (human = decision maker, AI = implementer)
- **Activity:** Pair exercise: 2 devs use AI to solve a problem; one plans first, one doesn't; compare results

#### Module 2: TDD with AI (90 min, hands-on)
- **Why:** Tests give AI a contract to follow. Defect reduction: 40-90%
- **Content:**
  - Write test → Red → AI implements to green → Refactor
  - Spec-first implementation (write OpenAPI spec, generate code)
  - When TDD is overkill vs. essential
  - Tools: Unit test example (Python/TypeScript/Go)
- **Activity:** Small kata (2-3 hour problem) using TDD + AI pair
- **Deliverable:** 1 tested feature per developer

#### Module 3: Plan Mode / Composer (60 min, hands-on)
- **Why:** Planning before auto-executing reduces token waste 50%, catches mistakes early
- **Content:**
  - When to use Plan Mode (multi-file, complex, refactoring)
  - How to break down a plan
  - Reading and adjusting the plan
  - Cost/speed tradeoff
- **Activity:** Plan a 3-file refactoring, review plan, iterate

#### Module 4: Code Review Calibration (60 min, collaborative)
- **Why:** Reviewing AI code requires different questions than reviewing human code
- **Content:**
  - What *not* to review (linter handles style)
  - Edge cases checklist
  - Security red flags
  - Architecture conformance
- **Activity:** 3-4 devs review same AI-generated PR, discuss differences, agree on standard

**Time commitment:** ~4-5 hours per developer, spread over 2 weeks

---

### What to Teach Later (Weeks 3-4+)

#### Module 5: Task-Type Patterns (90 min per pattern)
- Routine implementation
- Complex refactoring
- Debugging & investigation
- Test generation
- Documentation writing

Each pattern includes:
- When to use
- Step-by-step workflow
- Common mistakes
- Real example from codebase

#### Module 6: Multi-Agent Workflows (60 min, advanced)
- Problem: Debugging a production issue alone = 45+ min
- Solution: 3 agents investigating in parallel = 11 min
- Tools: CrewAI, Claude Agent SDK, or LangGraph
- When to use: Large feature work, parallel investigation, complex design decisions

#### Module 7: Custom MCPs & Skills (varies, optional)
- Build internal tool integrations
- Publish to team library
- See building-custom-mcp-servers.md for complete guide

#### Module 8: Cost Management (45 min)
- Token pricing breakdown
- Model selection heuristics
- Budget tracking
- When to use cheaper models vs. premium

### Hands-On Exercises

**Exercise 1: TDD Kata (Week 1)**
- Problem: Implement a shopping cart with discounts
- Constraint: Write test first, AI fills in implementation
- Success criteria: All tests pass, <100 tokens used
- Debrief: What did testing catch? When did AI struggle?

**Exercise 2: Spec-First (Week 2)**
- Problem: Design a REST API for user management
- Constraint: Write OpenAPI spec, AI generates server stubs
- Success criteria: Spec reviewed, code generated, tests pass
- Debrief: Did the spec prevent misunderstandings? How much faster?

**Exercise 3: Plan Mode (Week 2)**
- Problem: Refactor authentication across 3 files
- Constraint: Plan it first, review plan before executing
- Success criteria: Plan approved, changes follow plan, tests pass
- Debrief: Did planning save time? What did the plan miss?

**Exercise 4: Code Review (Week 2)**
- Problem: 4 developers review same AI-generated feature
- Constraint: Use the checklist (Section 4)
- Success criteria: All 4 find the same 3-4 major issues
- Debrief: What issues did each person miss? Why?

**Exercise 5: Real Feature (Week 3)**
- Scope: Small feature (4-8 hours estimated)
- Process: Spec → test → AI impl → code review → deploy
- Success criteria: Ships with no issues
- Debrief: What worked? What to improve?

### Measuring Adoption & Skill Growth

Track per-developer over time:

| Metric | Target | Timeline |
|--------|--------|----------|
| % using AI daily | 70%+ | End of week 2 |
| Avg. PR size | Stable | Weeks 2-4 |
| Test coverage | ≥80% | Ongoing |
| Code review time | -30% | Month 2 |
| Security findings | Stable | Ongoing |
| Developer satisfaction | >70% | Month 1 |
| Defect rate | ≤ human avg | Month 2 |

**Track in:** Engineering metrics dashboard (Faros, Runway, or custom)

### Pairing Patterns

**Pattern 1: AI-Experienced + AI-New (Recommended)**
- Frequency: 2-3 pairing sessions per new developer
- Duration: 1-2 hours per session
- Tasks: Real features from backlog
- Outcome: New dev learns patterns; experienced dev identifies training gaps

**Pattern 2: Junior + Senior (AI-Assisted Mentoring)**
- Same as above, but senior drives AI usage to unblock junior
- Helps junior develop debugging skills
- Prevents over-reliance on AI

**Pattern 3: Self-Paced with Office Hours**
- Developers work solo on exercises
- 1:1 office hours for questions/blockers
- Group retrospective to share learnings

**Best practice:** Rotate pairing partners to avoid single points of knowledge.

---

## 6. Quality Gates

### The Gate Architecture

Quality gates are *automated checks* that block merging if standards aren't met. Unlike code review (human subjective), gates are deterministic and can't be negotiated around.

```
Developer commits
    ↓
[Hooks: linter, formatter, secrets] ← Blocks locally if violated
    ↓
Developer pushes PR
    ↓
[CI/CD: tests, coverage, security, AI checks] ← Blocks merge if violated
    ↓
[Code review: architecture, edge cases, business logic] ← Manual approval
    ↓
Merge to main
```

### Pre-Commit Hooks (Local)

Run before code even leaves the developer's machine. Make failures immediate and clear.

**Essential hooks:**
1. **Linter/Formatter** (Prettier, Black, rustfmt)
   - Prevents style drift
   - Prevents bikeshedding in code review
   - Failure = exit code 1, blocks commit

2. **Test Runner**
   - Runs unit tests on changed files
   - Prevents shipping untested code
   - Can be slow; make configurable (unit-only vs. all)

3. **Secret Scanner** (git-secrets, Trivy, TruffleHog)
   - Blocks commits with API keys, passwords, credentials
   - High impact: Prevents accidental secret leaks
   - False positives: Tune regex carefully

4. **Commit Message Validator**
   - Enforces conventional commits: `[type](scope): description`
   - Enables automated changelog generation
   - Helps with git bisect and issue tracking

**Example pre-commit config (.husky/pre-commit):**
```bash
#!/bin/bash
set -e

echo "🔍 Linting..."
npm run lint:fix
npm run format

echo "🧪 Running tests..."
npm run test:unit -- --bail

echo "🔐 Scanning for secrets..."
git-secrets --scan

echo "✅ All checks passed!"
```

**Performance consideration:** Fast hooks (linter = 3s) are adopted; slow hooks (full test suite = 2min) are skipped. Keep pre-commit <30 seconds.

### CI/CD Gates (Remote)

Run on every PR. Comprehensive checks.

**Essential gates:**

1. **Test Coverage**
   ```yaml
   # Example GitHub Actions config
   - name: Check test coverage
     run: |
       coverage run -m pytest
       coverage report --fail-under=80
   ```
   - New code requires ≥80% coverage
   - Prevents shipping untested code
   - Especially important for AI-generated code (which often skips tests)

2. **Linting & Format Check**
   ```yaml
   - name: Lint check
     run: |
       npm run lint
       npm run format:check
   ```
   - Catch style issues CI caught locally (failsafe)
   - Format check prevents merge conflicts from formatting

3. **Security Scanning (SAST)**
   ```yaml
   - name: Security scan with Semgrep
     run: |
       semgrep --config="p/owasp-top-ten" --json --error
   ```
   - Static analysis catches SQL injection, XSS, hardcoded secrets
   - Use rulesets: OWASP Top 10, CWE Top 25
   - Block on high-severity issues

4. **Dependency Scanning**
   ```yaml
   - name: Check dependencies
     run: |
       npm audit --production --audit-level=high
   ```
   - Prevents shipping with known CVEs
   - Fail on high/critical issues

5. **Type Checking** (for typed languages)
   ```yaml
   - name: TypeScript strict
     run: |
       npx tsc --noEmit --strict
   ```
   - Prevents entire classes of bugs

6. **API/Contract Testing** (if applicable)
   ```yaml
   - name: Contract tests
     run: |
       npm run test:contracts
   ```
   - Ensures backward compatibility
   - Catches breaking changes

### AI-Specific Gates

#### 7. Test Quality Check
```yaml
- name: Verify test quality
  run: |
    # Run mutation testing: if tests pass with code mutations, tests are weak
    npx stryker run
    # Fail if mutation score <80%
```
- Catches tests that look good but don't actually verify behavior
- Particularly valuable for AI-generated tests (which sometimes don't assert correctly)

#### 8. Security Checklist for AI Code
```bash
#!/bin/bash
# .git/hooks/ci-ai-safety

files_changed=$(git diff --name-only origin/main...HEAD)

if echo "$files_changed" | grep -E "(auth|password|secret|key|token|credential)" | grep -E "\.(ts|js|py|go)$"; then
  echo "⚠️  AI-generated changes to security-sensitive files detected"
  echo "These files require explicit human review:"
  echo "$files_changed"
  exit 1  # Block merge until human reviews
fi
```

#### 9. Edge Case Detection (Optional, Advanced)
```yaml
- name: Edge case coverage
  run: |
    # Use property-based testing to generate edge cases
    npm run test:property-based
```
- Generates 100+ random test cases
- Catches edge cases AI might miss
- Can be slow; run async, comment on PR

#### 10. Architecture Conformance (Advanced)
```bash
#!/bin/bash
# Custom check: Verify module dependencies follow rules

check_dependencies() {
  # Example: Backend should never import from frontend/
  if grep -r "from frontend" backend/src/*.ts; then
    echo "❌ Architecture violation: backend imports from frontend"
    exit 1
  fi
}

check_dependencies
```

### Gate Ordering & Performance

Fast gates first (block immediately), slow gates last (async comment):

```
1. Format check          (1s)  ← Fail immediately
2. Lint check            (5s)  ← Fail immediately
3. Test (unit only)     (10s)  ← Fail immediately
4. Type check            (8s)  ← Fail immediately
5. Secret scan           (3s)  ← Fail immediately
---
6. Coverage report      (20s)  ← Run in parallel, comment result
7. SAST (Semgrep)       (30s)  ← Run in parallel, comment result
8. Dependency audit     (15s)  ← Run in parallel, comment result
9. Test (integration)   (60s)  ← Run in parallel, async
10. Mutation test      (120s)  ← Optional, optional, background
```

**Example GitHub Actions workflow:**
```yaml
name: PR Checks

on: [pull_request]

jobs:
  fast-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Format & lint
        run: npm run lint:fix && npm run format:check
      - name: Unit tests
        run: npm run test:unit
      - name: Type check
        run: npm run type-check

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: SAST scan
        run: npm run security:scan
      - name: Dependency audit
        run: npm audit --production

  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test coverage
        run: npm run test:coverage
      - name: Comment coverage report
        uses: romeovs/lcov-reporter-action@v0.3.1
```

### Blocking vs. Warning

**Blocking gates** (PR cannot merge):
- Tests fail
- Linting/formatting issues
- Security vulnerabilities (OWASP High/Critical)
- Secrets detected
- Type errors

**Warning gates** (PR can merge with approval):
- Coverage dropped >5%
- Mutation test score <80%
- Architecture warnings
- Complexity increased significantly

**Policy:** "Never merge while blocking gates fail. Warnings require approval from architecture lead."

### Enforcing at the Repository Level

```yaml
# branch-protection.yaml (GitHub)
- Require all checks to pass before merging
- Require up-to-date branch before merging
- Require code review approval (min 2 for high-risk)
- Dismiss stale reviews
- Require review from CODEOWNERS (optional)
- Require status checks:
    - Tests pass
    - Coverage ≥80%
    - SAST clear
    - No secrets
```

---

## 7. Cost Management for Teams

### The Cost Problem

**Reality:** Without structure, AI token costs grow 40-60% month-over-month in the first 6 months. A team of 5 developers can spend $10-15K/month on unbounded token usage.

**Common scenarios:**
- Developer A uses Claude Pro ($20/month) but is burning through tokens in Context Window mode (8K token limit)
- Developer B uses Cursor ($20/month) but leaves browser windows open with long contexts
- Developer C switches between 4 tools ad-hoc (Claude + Cursor + Copilot + Gemini)
- No one knows who's spending what

### Cost Breakdown (2026 Pricing)

| Tool | Cost Model | Monthly (1 dev) | Annual (1 dev) |
|------|-----------|-----------------|----------------|
| Claude Pro | Fixed | $20 | $240 |
| Cursor Pro | Fixed | $20 | $240 |
| GitHub Copilot Pro | Fixed | $20 | $240 |
| Gemini 2.0 | Pay-as-you-go | $10-100 | $120-1,200 |
| Claude API | Per-token | $50-500 | $600-6,000 |
| **Recommended mix (team)** | Hybrid | **$30-50/dev** | **$360-600/dev** |

**Per-token costs (as of March 2026):**
- Claude 3.5 Sonnet: $0.003 input / $0.015 output
- GPT-4o: $0.005 input / $0.015 output
- Gemini 2.0: $0.075 input / $0.3 output (higher context)
- Gemini Flash: $0.075 input / $0.3 output (faster, lower quality)

**Key insight:** Output tokens cost 3-8× input tokens. A 2K-token output is 6× more expensive than a 2K-token input.

### Per-Developer Budgeting

**Approach:** Give each developer a monthly budget and make costs transparent.

**Budget by role:**

| Role | Monthly Budget | Justification |
|------|----------------|---------------|
| Junior Developer | $30-50 | Lighter work, learning |
| Mid-Level Developer | $50-80 | Feature work, some complex tasks |
| Senior Developer | $80-150 | Multi-agent work, debugging, architecture |
| DevOps/Infra | $100-200 | Large codebases, complex domains |
| **Team Total (5 devs)** | **$300-500** | **Scales linearly** |

**Tracking implementation:**
```python
# Simple cost tracking
def estimate_tokens(model, input_tokens, output_tokens):
    rates = {
        "claude-3-5-sonnet": {"input": 0.003, "output": 0.015},
        "gpt-4o": {"input": 0.005, "output": 0.015},
        "gemini-flash": {"input": 0.075, "output": 0.3},
    }
    rate = rates[model]
    cost = (input_tokens * rate["input"]) + (output_tokens * rate["output"])
    return cost

# Log every API call with developer ID, model, tokens, cost
# Roll up daily → weekly → monthly per developer
# Alert if developer exceeds 80% of monthly budget
```

### Shared vs. Individual Subscriptions

**Shared approach (recommended for teams 5-50):**
- Organization pays for API access (Claude, OpenAI, Google)
- Each developer on-demand; costs auto-charged to team account
- Transparency: Dashboard shows spend per developer per week
- **Pro:** Cheapest at scale, better rates with volume
- **Con:** Requires billing setup, monitoring overhead

**Individual approach:**
- Each developer buys their own Pro subscription ($20/month)
- Works for small teams (<5) or high-autonomy cultures
- **Pro:** Simple, each developer manages their own
- **Con:** No visibility, hard to enforce standards, inefficient at scale

**Hybrid (recommended for larger teams):**
- Core tools on shared API: Claude (input-heavy tasks), Gemini (large-context tasks)
- Individual Cursor Pro ($20/month): Daily editing, IDE features
- **Cost:** ~$40-60/dev/month, 40% cheaper than all-Pro

### Model Selection Policies

Without guidance, developers pick the largest/newest model for everything. Establish routing heuristics:

**Decision tree:**

```
Is context >200K tokens?
├─ Yes: Use Gemini Flash (cheaper, 2M context)
└─ No: Continue...

Is task time-critical (debugging, blocking)?
├─ Yes: Use Claude 3.5 Sonnet (fastest)
└─ No: Continue...

Is task routine (fix, tests, docs)?
├─ Yes: Use Gemini Flash or GPT-4o-mini (cheapest)
└─ No: Use Claude 3.5 Sonnet

Is developer budget <20%?
├─ Yes: Enforce Flash/mini for next 2 weeks
└─ No: Allow primary model
```

**Implementation:** Add to team CLAUDE.md:

```markdown
## Model Selection Policy

### Default: Claude 3.5 Sonnet
- Complex feature work
- Multi-step reasoning
- Code review and debugging
- Teaching/explanation

### Secondary: Gemini Flash
- Large context analysis (200K+ tokens)
- Multi-file refactoring
- Reading logs/traces

### Budget Option: GPT-4o-mini
- Routine fixes and tests
- Documentation
- Simple API calls
- When over budget for month
```

### Cost Monitoring & Alerts

**Setup dashboard:**
- Real-time token consumption by developer
- Weekly trends (is usage growing?)
- Cost forecasts (will we exceed budget?)
- Alert at 50%, 80%, 100% of budget

**Example Grafana dashboard:**
```
[Token Usage This Month] [Forecast] [Budget Status]
╔════════════════════════════════════════════════════════╗
║ Developer | Tokens (M) | Cost ($) | % Budget | Status  ║
║-----------|------------|----------|----------|---------|
║ Alice     | 1.2M       | $45      | 75%      | ⚠️  OK   ║
║ Bob       | 2.8M       | $112     | 150%     | 🔴 OVER  ║
║ Charlie   | 0.6M       | $24      | 40%      | ✅ Good  ║
║ Diana     | 1.4M       | $56      | 75%      | ⚠️  OK   ║
║ Eve       | 0.8M       | $32      | 53%      | ✅ Good  ║
╚════════════════════════════════════════════════════════╝

Forecast (if current pace continues):
Alice:   $60/month ✅
Bob:     $149/month 🔴 Will exceed budget May 1
Charlie: $36/month ✅
Diana:   $75/month ✅
Eve:     $48/month ✅
```

### The "Who Pays" Question

**Recommendation:** Organizational cost, not individual.

**Why:**
- Removes friction (developers don't hesitate to use AI)
- Enables experimentation (try new models, new approaches)
- Promotes standardization (team adopts efficient practices together)
- Simplifies accounting

**Alternative:** Chargeback to project/product, but requires fine-grained allocation (who pays for multi-project debugging?).

### Cost Optimization Wins

**Quick wins (implement Week 1):**
1. Context compression (.gpt-4-no-context clear): 29% cost reduction
2. Session splitting (clear context every 5 exchanges): 15% reduction
3. Smart model selection (Flash for large context, mini for routine): 30-40% reduction
4. **Total possible: 50-70% reduction** (without quality loss)

**Medium-term (Month 2+):**
1. Prompt caching (cache static context): 90% reduction on context portion
2. Semantic caching (cache similar queries): 40-70% hit rate
3. Batch processing (group requests, run async): 20% reduction
4. Tool-specific optimization (Cursor for IDE tasks, Claude for complex reasoning)

**Example:** Team of 5, $500/month baseline:
- Context compression: -$145 (29%)
- Model routing: -$150 (30%)
- Prompt caching: -$75 (15%)
- **New monthly cost: $130** (74% reduction)

---

## 8. Security Policies

### The Security Challenge

AI-generated code is faster but not safer. Research shows:
- **45% of AI-generated code contains security flaws**
- **Fortune 50 companies saw 10× increase in vulnerabilities** (Dec 2024 - June 2025)
- **87% of developers worry** about security in AI-generated code

**The policy question:** What's allowed? What requires human approval?

### Classification Framework

**Tier 1: AI-Safe Tasks** (AI can do alone)
- Utility functions, helpers
- Tests and test data
- Documentation and comments
- Boilerplate and scaffold
- Styling and formatting
- Simple refactoring (rename, extract method)

**Tier 2: AI-Recommended with Review** (AI + human review)
- Feature implementation (spec-driven)
- Bug fixes
- API endpoints
- Database queries
- Performance optimizations
- Complex refactoring

**Tier 3: Human-Required with AI Input** (human decides, AI suggests)
- Authentication & authorization
- Payment and billing
- Data migrations
- Deployment scripts
- Security fixes (vulnerability patches)
- Compliance-critical code

**Tier 4: Forbidden for AI** (human-only)
- Security policy changes
- Access control configuration
- Dependency updates (security patches)
- Production database changes
- Infrastructure as Code changes affecting security

### Explicit Policy Document

**Create a SECURITY-POLICY.md in your repo:**

```markdown
# AI Security Policy

## Overview
This policy defines what AI tools can and cannot do in our codebase.

## Tier 1: AI-Safe (No review required)
- Utility functions, helpers, and constants
- Tests and test fixtures
- Documentation, comments, docstrings
- Scaffold and boilerplate code
- Formatting and styling changes
- Simple refactoring: rename, extract, reorder

**Implementation:** AI can commit directly.

## Tier 2: AI-Recommended (Code review required)
- Feature implementation (with spec)
- Bug fixes
- API endpoints and routes
- Database queries (not migrations)
- Caching, logging, observability
- Error handling and validation
- Performance optimizations

**Implementation:** Require 1 human code review before merge. Use security checklist.

## Tier 3: Human-Driven with AI Input (Human decides, AI suggests)
- Authentication logic (login, session, token handling)
- Authorization checks (permissions, roles, ACLs)
- Payment and billing code
- Encryption and key management
- Secrets handling and rotation
- CORS and security headers
- Input validation and sanitization

**Implementation:**
1. Architect/Security lead writes spec or approval comment
2. AI implements based on approved spec
3. 2+ code reviews (including architect) before merge
4. Security team may spot-check

## Tier 4: Human-Only (AI forbidden)
- Security vulnerability patches
- Access control changes (add/remove user permissions)
- Database schema migrations
- Production deployment scripts
- Infrastructure-as-code changes (firewall, IAM, etc.)
- Dependency security updates
- Security policy changes
- Cryptographic key generation/rotation

**Implementation:** Human-written only. AI can provide suggestions but not implementation.

## Enforcement

### Pre-commit Hook
```bash
#!/bin/bash
# Blocks commits to Tier 4 files without explicit human authorship
# Check if file is in TIER4_FILES and commit message doesn't have [HUMAN-WRITTEN]
```

### Code Review
- Require human review for all Tier 2+ changes
- Enforce "2 reviewers" for Tier 3
- Require security team review for Tier 4

### CI/CD Gates
- Automated scanning for secrets (SAST)
- Input validation checks
- No hardcoded credentials
- Known vulnerability scanning

## What to Do If Violated

If AI-generated code slips into Tier 3/4:
1. Revert immediately
2. Open issue with security team
3. Review code review process to prevent recurrence
4. No blame; improve process

## Questions?
Contact @security-team in Slack.
```

### Escalation Matrix

**When uncertain, escalate:**

```
Developer finds gray area code
         ↓
"Is this Tier 3 or higher?"
├─ No, Tier 2 → AI-assisted, normal review
└─ Yes, Tier 3+ → Tag @security-team in PR
              ↓
     Security team reviews within 24 hours
              ↓
         ├─ Approve → Proceed
         ├─ Request changes → Developer modifies
         └─ Reject → Rewrite human-only
```

### Secret Handling

**Never AI-generated:**
- API keys, credentials, passwords
- Private keys, certificates
- Database connection strings (with embedded credentials)
- OAuth tokens, refresh tokens

**Enforcement:**
```bash
# .git/hooks/pre-commit

# Scan for common secret patterns
git-secrets --scan --cached

# Scan using Trivy or TruffleHog
truffleHog filesystem . --only-verified

# Fail if secrets found
if [ $? -ne 0 ]; then
  echo "❌ Secrets detected. Use secrets manager instead."
  echo "See docs/SECRETS_MANAGEMENT.md"
  exit 1
fi
```

**Best practice:** Use secrets manager (Vault, 1Password, AWS Secrets Manager, etc.). AI cannot access secrets at all.

### Data Classification for AI Tools

**Public/OSS data:** ✅ Can be analyzed by AI
**Internal but non-sensitive:** ⚠️  Can be analyzed with caution (remove company names, customer identifiers)
**Sensitive (PII, PHI):** ❌ Never send to AI tools

**Enforcement:**
```bash
# Prompt check before AI assistance
# "Does this code/data contain PII/PHI? If yes, get approval from @data-privacy"
```

### Dependency & Supply Chain

**AI-safe:** Updating non-security dependencies
**Human-required:** Security updates to dependencies

Why? AI sometimes introduces incompatibilities that aren't obvious.

```bash
# Require human review for security dependency updates
if git diff HEAD~1 package.json | grep -E "^[\+-].*security"; then
  echo "🔐 Security dependency update detected"
  echo "Requires human review and testing"
  exit 1  # Block automatic merge
fi
```

---

## 9. Measuring Success

### What to Measure (and What NOT To)

**Bad metrics (don't use these):**
- Lines of code written (AI encourages verbose code; more LOC ≠ better)
- AI usage percentage (95% AI ≠ 95% productivity; depends on context)
- PRs merged per day (velocity up, quality down = bad trade)
- Cost per token (costs nothing if AI code ships broken)

**Good metrics (use these):**

#### 1. Deployment Frequency
- **What:** How often does the team ship to production?
- **Target:** 5-10x/week for healthy team
- **Why:** Top signal of team velocity. AI should increase this.
- **Measure:** Count merges to main branch per week

```
Week 1: 8 deploys/week (baseline)
Week 4: 14 deploys/week (+75%)
Month 2: 16 deploys/week (+100%)
```

#### 2. Lead Time for Changes
- **What:** Time from commit to production
- **Target:** <1 hour for healthy teams (some <10 min)
- **Why:** AI should reduce review time and testing time
- **Measure:** Median time from commit to merge to deploy

```
Baseline: 6 hours
Month 1: 4.5 hours
Month 3: 3 hours
```

#### 3. Change Failure Rate
- **What:** % of deployments that cause incidents
- **Target:** <15% (healthy), <5% (excellent)
- **Why:** If AI increases this, it's reducing quality
- **Measure:** Incidents per deployment

```
Baseline: 12%
Month 1: 11%
Month 3: 10%
```

**Important:** This should NOT increase. If it does, rollback AI usage and improve training/processes.

#### 4. Mean Time to Recovery (MTTR)
- **What:** How fast does team fix production issues?
- **Target:** <15 minutes
- **Why:** AI helps investigation and root cause analysis
- **Measure:** Time from incident detection to resolution

```
Baseline: 22 minutes
Month 2: 16 minutes (with AI debugging patterns)
```

#### 5. Code Coverage
- **What:** % of code covered by tests
- **Target:** ≥80% for new code
- **Why:** AI-generated code needs more verification
- **Measure:** Coverage report from CI/CD

```
Baseline: 72%
Month 1: 75% (AI helps write tests)
Month 3: 81%
```

#### 6. Security Issues Density
- **What:** Vulnerabilities per 1K lines of code
- **Target:** <2 per 1K LOC
- **Why:** AI-generated code has higher vulnerability rate (45%)
- **Measure:** SAST scan results per code change

```
Baseline: 1.2 per 1K LOC
Month 1: 1.5 (might increase initially as more code ships)
Month 3: 1.1 (after training/standards improve)
```

**Alert:** If this increases month-over-month, tighten security gates immediately.

#### 7. Defect Density
- **What:** Bugs per 1K lines shipped
- **Target:** ≤ baseline (don't let AI degrade quality)
- **Why:** Measure if AI code is as reliable as human code
- **Measure:** Production bugs attributed to AI-generated code vs. human code

```
Baseline (human code): 2.1 bugs per 1K LOC
Month 1 (AI code): 3.2 bugs per 1K LOC (higher, expected)
Month 3: 1.8 bugs per 1K LOC (lower, after training)
```

#### 8. Developer Satisfaction
- **What:** Do developers like using AI tools?
- **Target:** ≥70% positive sentiment
- **Why:** If sentiment drops, adoption collapses
- **Measure:** Monthly 1-question survey: "How satisfied are you with AI tools? (1-5)"

```
Month 0: Unknown
Month 1: 3.2/5 (learning curve, frustration with "almost right" code)
Month 2: 3.8/5 (patterns emerging, less frustration)
Month 3: 4.1/5 (confident and fast)
```

**Follow up:** If satisfaction drops, ask why in 1:1s or retro. Common reasons:
- Training insufficient
- Tools not working (bugs, slow)
- Standards too strict / not enforced
- Security policies frustrating devs

#### 9. Cost Per Feature
- **What:** Total AI tool cost divided by features shipped
- **Target:** <$200 per feature (varies by team/size)
- **Why:** AI should reduce cost per feature through faster development
- **Measure:** Monthly AI cost / Features deployed

```
Month 1: $400 per feature (learning curve, inefficiency)
Month 2: $320 per feature (patterns solidifying)
Month 3: $180 per feature (optimized)
```

#### 10. Code Review Efficiency
- **What:** Time per code review comment
- **Target:** 20-30% reduction in review time
- **Why:** Hooks handle style; reviewers focus on substance
- **Measure:** Total review time / PR comments

```
Baseline: 8 min per comment
Month 2: 6.5 min per comment (15% faster)
Month 3: 5.5 min per comment (30% faster)
```

### Dashboard Example

**Weekly metrics dashboard (shared with team):**

```
═══════════════════════════════════════════════════════════════
AI ADOPTION DASHBOARD (Week of March 19)
═══════════════════════════════════════════════════════════════

Velocity:
  Deploys this week:         16 ↑ (was 14)
  Lead time (median):        2.8 hrs ↓ (was 3.2)
  PRs merged (avg/dev):      3.2 ↑ (was 2.1)

Quality:
  Test coverage:             82% ✅ (target: ≥80%)
  Change failure rate:       9% ✅ (target: <15%)
  Defect density:            1.4/KLOC ✅ (baseline: 2.1)
  Security findings:         3 new ✅ (within normal range)

Developer Experience:
  Adoption rate:             85% ✅ (target: >70%)
  Satisfaction (avg):        4.0/5.0 ↑ (was 3.6)
  Support requests/week:     3 ↓ (was 8)

Cost:
  AI spending (monthly):     $420 (within budget: $500)
  Cost per feature:          $185 ↓ (was $240)
  Cost trend (forecast):     $420 (flat, good)

═══════════════════════════════════════════════════════════════
```

### What NOT to Measure

❌ **Lines of code:** AI tends to be verbose. More LOC ≠ better.

❌ **AI usage %:** Highest AI % might be worst team (using AI blindly).

❌ **PR velocity alone:** Velocity up + quality down = net negative.

❌ **Token usage:** Costs are irrelevant if code ships broken.

❌ **Developer "productivity":** Hard to measure, risky to incentivize (discourages quality).

---

## 10. Common Pitfalls

### Pitfall 1: Mandating AI Usage

**What happens:** "Everyone must use AI for 50% of PRs" → Developers use AI on unsuitable tasks → Resentment, burnout, quality tanks.

**Why it fails:** AI is a tool, not a religion. Some tasks are genuinely better hand-coded.

**What to do instead:**
- Encourage AI usage for specific task types (testing, refactoring, boilerplate)
- Leave "hard" problem-solving to humans
- Measure velocity + quality, not AI usage %
- Trust developers to use the right tool

---

### Pitfall 2: No Training, Just Access

**What happens:** "Here's Copilot, go" → Developers use AI wrong → Burnout, frustration, 18% report insufficient training.

**Why it fails:** AI requires rethinking. Spec-first, test-first, plan-first are counter-intuitive to developers trained on "code first."

**What to do instead:**
- Invest in training: TDD, specs, Plan Mode, code review standards
- Pair experienced + new developers
- Share real examples from your codebase
- Office hours for questions

---

### Pitfall 3: Inconsistent Standards

**What happens:** Each developer configures their own CLAUDE.md and tools → Code reviews become architectural negotiations → Team velocity stalls.

**Why it fails:** Lack of shared context makes code review cognitive hell.

**What to do instead:**
- Single shared CLAUDE.md in repo
- Team agreement on tools (primary + fallback)
- Hooks enforce standards deterministically
- Standards change via PR review, not individual choice

---

### Pitfall 4: No Security Gates

**What happens:** AI generates database migrations, auth logic → Secrets leak → Security incident.

**Why it fails:** AI doesn't understand security context. "Just implement what the spec says" can be dangerous.

**What to do instead:**
- Tier 3/4 tasks require human approval before AI implementation
- SAST scanning in CI/CD
- Secret scanning in pre-commit hooks
- Security team reviews high-risk code

---

### Pitfall 5: Ignoring Quality Regression

**What happens:** Deployment frequency up, defect rate up → Technical debt accumulates → Team moving slower in 6 months despite AI.

**Why it fails:** Speed ≠ progress. Debt compounds.

**What to do instead:**
- Track defect density, not just PR count
- Quality gates in CI/CD (test coverage, SAST)
- Code review checklist focuses on edge cases + security
- Measure change failure rate; alert if it increases

---

### Pitfall 6: Unbounded Costs

**What happens:** Developers burn through token budgets → Monthly bills surprise finance → AI tool pulled because "too expensive."

**Why it fails:** No visibility, no accountability.

**What to do instead:**
- Per-developer token budgeting
- Cost dashboard visible to team
- Model routing to cheaper models for routine tasks
- Context compression saves 30-50% without quality loss

---

### Pitfall 7: Tool Fragmentation

**What happens:** Team uses 4 different AI tools (Claude, Cursor, Copilot, Gemini) with no coordination → Context fragmentation, duplicate work, context loss.

**Why it fails:** No single source of truth for codebase patterns, architecture, standards.

**What to do instead:**
- Pick primary tool (usually Cursor or Claude Code for dev work)
- Allow secondary tools for specific use cases (Gemini for large context)
- Store all guidance in shared CLAUDE.md
- Centralize architecture docs

---

### Pitfall 8: Losing Developer Judgment

**What happens:** Over-reliance on AI → Junior developers stop thinking critically → Skill erosion → Vulnerability to AI failures.

**Why it fails:** AI is a tool, not a brain. Developer judgment is still essential.

**What to do instead:**
- Train developers to question AI output ("Is this right? Why?")
- Code review checklist: "Did reviewer independently verify?" not "Did AI suggest?"
- Pair junior + senior developers
- Regular retrospectives: "When did AI help? When did it mislead?"

---

### Pitfall 9: Conflicting Standards

**What happens:**
- CLAUDE.md says "TDD-first" but hooks don't enforce tests
- Code review rubric says "check edge cases" but manager rewards speed
- Policy says "Tier 3 code requires approval" but team ignores

**Why it fails:** Policy without enforcement is just suggestions.

**What to do instead:**
- Make standards actionable: hooks enforce, gates block, review checklist is concrete
- Align incentives: reward quality + speed, not speed alone
- Management visible about standards (don't say "write tests" then celebrate code shipped fast)
- Revisit standards quarterly; update if they're wrong

---

### Pitfall 10: Not Iterating on Process

**What happens:** Week 1 standards are locked; team discovers better patterns but can't change → Friction, divergence.

**Why it fails:** Processes are hypotheses, not laws. Reality teaches.

**What to do instead:**
- Monthly retrospectives: "What's working? What's not?"
- Easy-to-change standards (CLAUDE.md is a PR, not a decree)
- Celebrate process improvements ("We cut review time 20% by focusing on edge cases")
- Survey developer satisfaction monthly; adjust if sentiment drops

---

## 11. Templates & Checklists

### Template 1: Team CLAUDE.md

```markdown
# CLAUDE.md: [Project Name] AI Development Standards

**Last updated:** 2026-03-19
**Version:** 1.0
**Maintained by:** Architecture team
**Next review:** 2026-04-19

---

## 1. Architecture Constraints

### Module Structure
- Backend: Express.js, TypeScript, MVC pattern
- Frontend: React 18, TypeScript, hooks-based
- Database: PostgreSQL 15+
- Cache: Redis (session store only, not data cache)

### Naming Conventions
- Files: PascalCase for components, camelCase for utilities
- Functions: camelCase, prefix with verb (get, fetch, handle, validate)
- Constants: UPPERCASE_WITH_UNDERSCORES
- Private: underscore prefix (_internalHelper)

### Layering
- Controllers: Handle HTTP, validate input, call services
- Services: Business logic, data transformation
- Repositories: Database access, queries
- Never: Import controller from service or vice versa

### Error Handling
- Always return structured errors: `{ code: "ERR_CODE", message: "", details: {} }`
- Log errors with context: `logger.error({ error, userId, action })`
- Never log sensitive data (passwords, API keys, SSNs)

---

## 2. What NOT to AI-Generate

### Forbidden Patterns
- Database migrations (always human-reviewed; data is irreversible)
- Authentication logic (login, token handling, session management)
- Authorization checks (permission validation; one mistake = breach)
- Payment/billing code (financial correctness non-negotiable)
- Deployment/infrastructure scripts (irreversible effects)

### Anti-Patterns to Avoid
- String concatenation for SQL (use parameterized queries)
- Hardcoded credentials or environment variables
- Blocking operations in async code (use async/await)
- Direct DOM manipulation in React (use state + render)
- Importing styles globally (use CSS modules or styled-components)
- Silent error swallowing (catch without re-throw or logging)

---

## 3. What AI Should Generate (Opportunistically)

### High-Win Tasks
- Tests and test fixtures (AI writes 70-90%, human tweaks)
- Boilerplate and scaffold (reducers, API stubs, migrations)
- Refactoring under test contracts (rename, extract, reorder)
- Documentation and docstrings
- Performance optimizations (with benchmarking)

---

## 4. Patterns by Task Type

### Routine Implementation (Most PRs)
1. Write test first (or spec first)
2. Ask Claude/Cursor: "Implement to pass this test"
3. AI generates code
4. Code review focuses on: architecture conformance, edge cases, security
5. Merge

Expected success rate: 85-95%

### Complex Refactoring
1. Write characterization tests (capture current behavior)
2. Ask Gemini or Claude: "Refactor under test contracts"
3. Verify: All tests still pass, readability improved
4. Code review focuses on: breaking changes, performance impact
5. Merge

Tool choice: Gemini (2M context for whole-codebase analysis) or Claude Code with context files

### Debugging Production Issues
1. Gather logs/traces
2. Use Claude Plan Mode: "Hypothesize root causes"
3. AI generates 5-10 hypotheses in 5 minutes (instead of 45 min thinking)
4. Verify hypotheses with targeted testing
5. Fix and verify

Expected speedup: 3-5x faster

---

## 5. Model Selection

Default to this decision tree:

```
Is context >200K tokens?
├─ Yes: Gemini Flash (2M context, cost $0.075 input/$0.3 output)
└─ No: Continue...

Is this a high-complexity task (architecture, refactoring, debugging)?
├─ Yes: Claude 3.5 Sonnet (best reasoning)
└─ No: Use cheaper model

Is this routine (tests, simple fix, docs)?
├─ Yes: Gemini Flash or GPT-4o-mini (cost ~$5/day per dev)
└─ No: Claude 3.5 Sonnet

Is developer over monthly budget?
├─ Yes: Use only Flash/mini for 2 weeks
└─ No: Use primary model
```

## 6. Code Review Checklist for AI Code

See SECURITY-POLICY.md for detailed guidance.

Quick checklist:
```
[ ] Handles null/undefined/empty collections
[ ] Error cases tested and logged
[ ] No hardcoded secrets or credentials
[ ] Matches architecture patterns
[ ] No SQL injection, XSS, or authorization bypass
[ ] Tests verify behavior (not mocks)
[ ] Follows module conventions
[ ] Performance reasonable (no O(n²) obvious)
```

---

## 7. Questions?

- **AI tool not working:** #ai-tools Slack channel
- **Architecture question:** Tag @architecture
- **Security concern:** Tag @security-team (24-hour response SLA)
- **Cost or budget question:** Talk to @eng-manager
```

---

### Template 2: TDD with AI Workflow

```markdown
# TDD + AI Workflow

## The Pattern

```
1. Read the feature spec (in JIRA, PRD, or Slack)
2. Write failing test(s)
   - What should the function return?
   - What should it do with bad input?
   - Edge cases?
3. Ask AI to implement to pass the test
4. AI generates code
5. Verify: Test passes
6. Refactor if needed (still under tests)
7. Code review (checklist in CLAUDE.md)
8. Merge
```

## Example: User Registration

**Spec:**
```
Endpoint: POST /users/register
Input: { email, password }
Output: { userId, email, token }
- Email must be valid
- Password must be ≥8 chars
- Email must be unique
- Return 400 if validation fails
```

**Step 1: Write test**
```javascript
describe("POST /users/register", () => {
  it("creates user and returns token", async () => {
    const res = await request(app)
      .post("/users/register")
      .send({ email: "alice@example.com", password: "secure123" });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty("userId");
    expect(res.body).toHaveProperty("token");
  });

  it("rejects invalid email", async () => {
    const res = await request(app)
      .post("/users/register")
      .send({ email: "not-an-email", password: "secure123" });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("INVALID_EMAIL");
  });

  it("rejects short password", async () => {
    const res = await request(app)
      .post("/users/register")
      .send({ email: "alice@example.com", password: "short" });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("PASSWORD_TOO_SHORT");
  });

  it("rejects duplicate email", async () => {
    // Create first user
    await User.create({ email: "alice@example.com", password: "..." });

    // Try to create duplicate
    const res = await request(app)
      .post("/users/register")
      .send({ email: "alice@example.com", password: "secure456" });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("EMAIL_ALREADY_EXISTS");
  });
});
```

**Step 2: Ask AI**
```
"Write Express endpoint POST /users/register that:
- Validates email format
- Validates password length ≥8 chars
- Checks email uniqueness in database
- Creates user and returns token
- Returns 400 with error code on failure
- Returns 201 with userId and token on success

Reference: CLAUDE.md for error format and auth patterns
Use: bcrypt for password hashing, JWT for tokens
Tests are in __tests__/routes/register.test.js"
```

**Step 3: AI generates implementation**
```javascript
// src/routes/registerUser.ts
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import User from "../models/User";

export const registerUser = async (req, res) => {
  const { email, password } = req.body;

  // Validate email
  if (!isValidEmail(email)) {
    return res.status(400).json({ code: "INVALID_EMAIL", message: "Email is not valid" });
  }

  // Validate password
  if (!password || password.length < 8) {
    return res.status(400).json({ code: "PASSWORD_TOO_SHORT", message: "Password must be ≥8 chars" });
  }

  // Check uniqueness
  const existing = await User.findOne({ email });
  if (existing) {
    return res.status(400).json({ code: "EMAIL_ALREADY_EXISTS", message: "Email already in use" });
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10);

  // Create user
  const user = await User.create({ email, password: hashedPassword });

  // Create token
  const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: "7d" });

  res.status(201).json({ userId: user.id, email: user.email, token });
};
```

**Step 4: Run tests**
```bash
npm test -- registerUser.test.js
# ✅ All 4 tests pass
```

**Step 5: Code review**
- Check: Error handling ✅
- Check: No hardcoded secrets ✅
- Check: Password hashed (bcrypt) ✅
- Check: Email validation correct ✅
- Check: All edge cases tested ✅

**Result:** Feature shipped in 30 minutes (vs. ~2 hours hand-coded)
```

---

### Template 3: AI Code Review Rubric

```markdown
# Code Review Rubric for AI-Generated Code

## Quick Scan (2 min)
- [ ] Code compiles/runs without errors
- [ ] All linter/format checks pass
- [ ] Tests included and passing
- [ ] Obvious security issues (hardcoded secrets, SQL injection)

## Edge Cases (5 min)
- [ ] Null/undefined/empty collection handling
- [ ] Boundary conditions (0, 1, many)
- [ ] Error cases tested
- [ ] Resource cleanup (files, connections, memory)

**Questions to ask:**
- What if input is null? Empty? Extremely large?
- What if this timeout/fails? Is it handled?
- What if concurrent requests hit this? Race conditions?

## Architecture (5 min)
- [ ] Follows module/layering conventions
- [ ] Consistent with similar code in codebase
- [ ] Error handling matches team style
- [ ] No circular dependencies
- [ ] Dependencies flow in right direction (not upstream importing downstream)

**Questions to ask:**
- Have I seen code like this before? Does it look the same way?
- Could this break implicit contracts?
- Does this fit the overall system design?

## Security (3 min, skip if Tier 1)
- [ ] No hardcoded credentials
- [ ] User input validated/sanitized
- [ ] No SQL injection vectors (parameterized queries)
- [ ] No path traversal bugs
- [ ] Authorization checks present (if needed)
- [ ] No sensitive data logged (passwords, SSNs, etc.)

**Questions to ask:**
- Could an attacker exploit this?
- Is user input trusted here? Should it be?
- What happens if someone feeds malicious input?

## Test Quality (5 min)
- [ ] Tests verify behavior, not mocks
- [ ] Happy path and error cases both tested
- [ ] Assertions are specific (not generic)
- [ ] No flaky tests (random waits, timing issues)

**Questions to ask:**
- If I remove a line from the implementation, do tests fail?
- Are these tests checking the right things?
- Would these tests catch regressions?

## Performance (2 min, if applicable)
- [ ] No obvious O(n²) or N+1 patterns
- [ ] Appropriate algorithm choice
- [ ] Database queries reasonable
- [ ] No blocking operations in async code

## Readability (2 min, skim)
- [ ] Variable names clear
- [ ] Complex logic has comments (explain *why*, not *what*)
- [ ] No code smells (long functions, deep nesting, duplication)
- [ ] Follows language idioms

## Score

**Red (Don't merge):** >3 concerns in Categories 1-2 (Edge Cases, Security, Architecture)

**Yellow (Approve with requests):** 1-3 concerns; developer can address before merge

**Green (Approve):** 0-1 cosmetic concern; approve as-is

## Comment Template

```
**Review Summary:** [Green/Yellow/Red]

**Good:**
- Clear error handling
- All edge cases covered

**Questions:**
- Line 45: What if `data` is undefined here?
- Line 62: Does this SQL injection risk exist with user input?

**Suggestions:**
- Consider extracting `validateUser` to separate function
- Add test for timeout scenario

**Overall:** Looks good! Address the questions above and it's ready.
```
```

---

### Template 4: New Team Member Onboarding Checklist

```markdown
# New Developer AI Onboarding Checklist

**Developer:** ___________
**Start date:** ___________
**Buddy:** ___________ (AI-experienced dev)

---

## Day 1: Setup & Mindset

- [ ] Access to repo, Slack, tools
- [ ] CLAUDE.md reviewed (read + ask questions)
- [ ] SECURITY-POLICY.md reviewed
- [ ] Installed Claude Code / Cursor / Gemini (pick 2)
- [ ] Added to team AI metrics dashboard
- [ ] Watched "TDD with AI" video (15 min)
- [ ] Understand: AI is a partner, not a replacement (ask buddy to explain)

---

## Day 2-3: Hands-On Practice

- [ ] Complete TDD kata with buddy (2 hours)
  - Buddy drives first, you navigate
  - Then you drive, buddy navigates
  - Debrief: What surprised you?

- [ ] Write spec for simple feature, ask AI to implement
  - Example: Add a utility function, REST endpoint, React component
  - Code review with buddy
  - Merge

- [ ] Try Plan Mode (Claude) or Composer (Cursor)
  - Small refactoring or multi-file change
  - Plan it first
  - Execute
  - Debrief: Did planning help?

---

## Week 1: First Real Feature

- [ ] Pick small feature (4-8 hour estimate)
- [ ] TDD-first: Write tests, AI implements
- [ ] Code review with buddy + 1 senior dev
- [ ] Merge
- [ ] Retrospective with buddy
  - What went well?
  - What was hard?
  - Questions for team?

---

## Week 2: Deepening

- [ ] Pair with senior dev on their PR
- [ ] See how they use AI (mental models, patterns)
- [ ] Ask: "When do you use AI? When do you hand-code?"

- [ ] Try a Tier 2+ task (with approval)
  - Feature with edge cases
  - Debugging production issue
  - Refactoring

- [ ] Office hours with AI coach (30 min)
  - Open questions
  - Blockers

---

## Week 3-4: Independence

- [ ] Lead 3-4 PRs using AI (with normal code review)
- [ ] Identify 1 thing that's confusing, ask to update CLAUDE.md
- [ ] Contribute idea for improving process (team retro)
- [ ] Ready to be buddy for next hire (optional)

---

## Sign-Off

- [ ] Developer: "I'm comfortable with AI tools and team patterns"
- [ ] Buddy: "Onboarding complete, ready for independent work"
- [ ] Manager: "Add to on-call rotation / full team responsibilities"

**Date:** ___________

---

## Resources

- CLAUDE.md: Architecture patterns and guidance
- SECURITY-POLICY.md: What's safe, what requires approval
- TDD+AI video: 15-min intro to test-driven development
- Code review checklist: What to focus on
- Team Slack #ai-tools: Questions and tips
- Office hours: Slack @ai-coach for scheduling
```

---

### Template 5: Weekly Team Retrospective Format

```markdown
# Weekly AI Onboarding Retrospective

**Date:** Week of March 19
**Attendees:** Whole team
**Duration:** 30 min

---

## What Went Well?

*What did AI help with this week?*

- [ ] Developer A: "Debugging production issue in 15 min instead of 45"
- [ ] Developer B: "Tests written by AI, I just fixed edge cases"
- [ ] Developer C: "Refactoring 200 lines of legacy code felt safe with tests"

**Question for team:** "What should we celebrate?"

---

## What Was Hard?

*What didn't work? Where did AI struggle?*

- [ ] Developer A: "AI code had SQL injection vulnerability; code review caught it"
- [ ] Developer B: "Three iterations to get the spec right"
- [ ] Developer C: "Felt weird relying on AI; not sure if I'm learning"

**Question for team:** "What should we improve?"

---

## Process Changes This Week?

*Did we discover better patterns?*

- [ ] Spec-first saves more time than we thought (try for all features?)
- [ ] Code review checklist too long (trim the cosmetic stuff?)
- [ ] Cost tracking helpful; developers noticing budget limits (good!)

**Action items:**
- [ ] (Assign owner, due date)

---

## Metrics Check

*Are numbers moving the right way?*

- Deploys/week: 14 (was 12) ✅
- Lead time: 2.8 hrs (was 3.2) ✅
- Test coverage: 82% (target: ≥80%) ✅
- Dev satisfaction: 3.9/5 (improving!) ↑
- Security findings: 2 (within normal) ✅

**Alert:** If metric is red, discuss root cause and fix.

---

## CLAUDE.md / Policy Changes?

*Does guidance need updating?*

- [ ] Add new pattern discovered this week
- [ ] Clarify confusing part
- [ ] Remove rule that's not helping
- [ ] Change model selection heuristic

**Proposed change:** (describe, owner assigns reviewer)

---

## Training Need?

*What topic did multiple people ask about?*

- [ ] Plan Mode usage
- [ ] Security boundaries
- [ ] How to use Gemini for large context
- [ ] Cost optimization

**Action:** Schedule 1-hour workshop next week

---

## Shout Outs

*Who did great work this week?*

- [ ] Developer A: "Mentored new hire on TDD + AI, super patient"
- [ ] Developer B: "Found security issue in AI code before it shipped"

---

**Wrap-up:** Team health good? Need manager involvement? Plan next week focus.
```

---

## Sources

### Research 2025-2026: Adoption, Training, Governance

- [GitHub Copilot Enterprise Training & Onboarding](https://github.com/resources/whitepapers/training-and-onboarding-developers-on-github-copilot)
- [GitHub Copilot Fundamentals Training Path](https://learn.microsoft.com/en-us/training/paths/copilot/)
- [AI in Coding — Key Statistics & Trends (2026)](https://www.getpanto.ai/blog/ai-coding-assistant-statistics)
- [AI-Generated Code Statistics 2026: Can AI Replace Your Development Team?](https://www.netcorpsoftwaredevelopment.com/blog/ai-generated-code-statistics)
- [Enterprise AI Coding Assistant Adoption: Scaling to Thousands](https://www.faros.ai/blog/enterprise-ai-coding-assistant-adoption-scaling-guide)
- [AI code generation: Best practices for enterprise adoption in 2025](https://getdx.com/blog/ai-code-enterprise-adoption/)
- [How tech companies measure the impact of AI on software development](https://newsletter.pragmaticengineer.com/p/how-tech-companies-measure-the-impact-of-ai)

### Team Dynamics & Training

- [Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity (METR)](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/)
- [How to measure AI's impact on developer productivity (DX)](https://getdx.com/blog/ai-measurement-hub/)
- [How to measure AI developer productivity in 2025 | Nicole Forsgren](https://www.lennysnewsletter.com/p/how-to-measure-ai-developer-productivity)
- [How to Measure AI Productivity in Engineering: The 10 Dimensions That Actually Matter](https://www.faros.ai/blog/ai-productivity-metrics)
- [The AI Revolution in 2026: Top Trends Every Developer Should Know](https://dev.to/jpeggdev/the-ai-revolution-in-2026-top-trends-every-developer-should-know-18eb)
- [AI could truly transform software development in 2026 – developer teams still face challenges](https://www.itpro.com/software/development/ai-software-development-2026-vibe-coding-security)
- [Engineering in the Age of AI: What the 2025 State of Engineering Management Report Reveals](https://jellyfish.co/blog/2025-software-engineering-management-trends/)
- [Mastering the AI Code Revolution in 2026: Unlock Faster, Smarter Software Development](https://www.baytechconsulting.com/blog/mastering-ai-code-revolution-2026)

### Code Review Standards & Governance

- [2025 was the year of AI speed. 2026 will be the year of AI quality.](https://www.coderabbit.ai/blog/2025-was-the-year-of-ai-speed-2026-will-be-the-year-of-ai-quality)
- [Establishing Code Review Standards for AI-Generated Code](https://www.metacto.com/blogs/establishing-code-review-standards-for-ai-generated-code)
- [Why AI Code Governance Matters in 2026](https://anotherdimensioncreativegroup.com/blog/why-governance-matters)
- [AI Code Quality in 2026: Guardrails for AI-Generated Code](https://tfir.io/ai-code-quality-2026-guardrails/)

### Enterprise Governance & Security

- [AI Governance: The Complete Enterprise Guide 2026](https://larridin.com/solutions/ai-governance-the-complete-enterprise-guide-2026/)
- [AI governance in enterprise environments](https://deepxhub.com/2026/03/18/ai-governance-in-enterprise-environments/)
- [Enterprise AI Governance: Complete Implementation Guide (2025)](https://www.liminal.ai/blog/enterprise-ai-governance-guide)
- [The 2025 CISOs' Guide to AI Governance](https://www.trustcloud.ai/the-cisos-guide-to-ai-governance/)
- [AI Governance and Strategy Trends for 2026](https://www.allcovered.com/blog/ai-governance-and-strategy-trends)

### Cost Management

- [AI Pricing: What's the True AI Cost for Businesses in 2026?](https://zylo.com/blog/ai-cost/)
- [Understanding LLM Cost Per Token: A 2026 Practical Guide](https://www.silicondata.com/blog/llm-cost-per-token/)
- [AI Coding Tools ROI Calculator: Cost Analysis 2026](https://www.sitepoint.com/ai-coding-tools-cost-analysis-roi-calculator-2026/)
- [How are engineering leaders approaching 2026 AI tooling budgets?](https://getdx.com/blog/how-are-engineering-leaders-approaching-2026-ai-tooling-budget/)

### Security & Technical Debt

- [AI-Generated Code Creates New Wave of Technical Debt, Report Finds](https://www.infoq.com/news/2025/11/ai-code-technical-debt/)
- [AI Is Creating a New Kind of Tech Debt — And Nobody Is Talking About It](https://dev.to/harsh2644/ai-is-creating-a-new-kind-of-tech-debt-3pm6)
- [AI-Generated Code Poses Security, Bloat Challenges](https://www.darkreading.com/application-security/ai-generated-code-leading-expanded-technical-security-debt)
- [The AI Coding Technical Debt Crisis: What 2026-2027 Holds](https://www.pixelmojo.io/blogs/vibe-coding-technical-debt-crisis-2026-2027)
- [AI-Generated Code Security Risks: What Developers Must Know](https://www.veracode.com/blog/ai-generated-code-security-risks/)

### Pair Programming & Developer Pairing with AI

- [Developers with AI assistants need to follow the pair programming model](https://stackoverflow.blog/2024/04/03/developers-with-ai-assistants-need-to-follow-the-pair-programming-model/)
- [Best practices for pair programming with AI assistants](https://graphite.com/guides/ai-pair-programming-best-practices)
- [Pair Programming with AI Coding Agents: Is It Beneficial?](https://zencoder.ai/blog/best-practices-for-pair-programming-with-ai-coding-agents/)
- [AI Pair Programming: How to Improve Coding Efficiency with AI](https://clickup.com/blog/ai-pair-programming/)
- [AI Agent Best Practices: 12 Lessons from AI Pair Programming for Developers](https://forgecode.dev/blog/ai-agent-best-practices/)

### Enterprise Rollout Case Studies

- [Microsoft Copilot: Case studies of enterprise AI deployments and lessons learned](https://www.datastudios.org/post/microsoft-copilot-case-studies-of-enterprise-ai-deployments-and-lessons-learned)
- [The Enterprise Guide to Microsoft Copilot Adoption](https://www.worklytics.co/blog/the-enterprise-guide-to-microsoft-copilot-adoption)
- [Scaling Success: Bringing Microsoft 365 Copilot to Enterprises](https://www.tcs.com/what-we-do/services/cloud/microsoft/case-study/bringing-microsoft-365-copilot-enterprises)
- [Microsoft 365 Copilot for executives: Sharing our deployment and adoption journey at Microsoft](https://www.microsoft.com/insidetrack/blog/microsoft-365-copilot-for-executives-sharing-our-deployment-and-adoption-journey-at-microsoft)
- [Deploying Microsoft 365 Copilot in five chapters](https://www.microsoft.com/insidetrack/blog/deploying-microsoft-365-copilot-in-five-chapters/)
- [Microsoft 365 Copilot Adoption Playbook](https://www.microsoft.com/en-us/microsoft-365-copilot/copilot-adoption-guide)

### Related Context Guides

- [Hooks & Enforcement Patterns for AI-Augmented Development](docs/topics/hooks-enforcement-patterns.md)
- [Using AI Development Tools Effectively on Large Codebases](docs/topics/ai-on-large-codebases.md)
- [Cost Optimization Playbook](docs/topics/cost-optimization-playbook.md)
- [Testing AI-Generated Code](docs/topics/testing-ai-generated-code.md)
- [Prompt Engineering Patterns](docs/topics/prompt-engineering-patterns.md)

---

## Related Topics

- [Hooks Enforcement Patterns](hooks-enforcement-patterns.md) — Technical mechanisms for enforcing team standards automatically
- [When Not to Use AI](when-not-to-use-ai.md) — Teaching judgment calls about AI tool application
- [Prompt Engineering Patterns](prompt-engineering-patterns.md) — Best practices for prompting that teams should follow
