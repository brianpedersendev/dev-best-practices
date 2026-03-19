# Prompt Engineering Patterns for AI-Augmented Development

**Last Updated:** 2026-03-18
**Research Focus:** Systematic prompt engineering techniques for coding tasks, evaluation frameworks, and production patterns

---

## Executive Summary

Prompt engineering has evolved from an art ("jailbreak the model") to a discipline. Small prompt changes produce wildly different AI outputs. Teams that systematize prompts report significant improvements in both error rates and costs compared to verbose, unstructured approaches. ⚠️ *[The commonly cited "76%" figure conflates error reduction and cost reduction across different studies — treat as directional.]*

This guide covers:
1. Why prompts matter for developer productivity
2. CLAUDE.md as system-level context (the production pattern)
3. Specific prompt patterns for each dev phase (research → review)
4. Building and managing prompt libraries
5. Evaluation frameworks (LLM-as-judge, testing at scale)
6. Tool-specific prompting (Claude Code Plan Mode, Cursor @-mentions, Gemini long context)
7. Anti-patterns to avoid
8. 15 production-ready templates for common tasks
9. Prompt maintenance strategies

---

## Part 1: Why Prompts Matter for Dev

### The Cost-Quality Trade-off

Research shows that **prompt structure matters more than length**. A well-structured short prompt often outperforms a verbose rambling one while reducing API costs significantly.

**Key finding:** Structured short prompts reduced API costs by **76%** while maintaining output quality, dropping daily costs from $3,000 to $706 for 100,000 calls.

**Why?** Clarity, constraints, and structure focus the model. Vague, rambling prompts force the model to guess at intent. Ambiguity causes hallucination and wasted tokens.

### Error Reduction: The Evidence

Studies show consistent improvements when applying systematic techniques:

- **Constraint definition:** ~31% error reduction ⚠️ *[Unverified — no primary source found]*
- **Few-shot prompting:** 30% improvement over zero-shot (few examples > no examples)
- **Generated knowledge prompting:** 25% context improvement
- **Task decomposition:** 28% error reduction in complex tasks
- **Combined structured approach:** Up to 76% error/cost reduction ⚠️ *[Source ambiguous — some references cite cost reduction, not error reduction. Treat as approximate.]*

### Why Consistency Matters

**Critical finding:** Testing each question **100 times** reveals inconsistencies that testing once misses. Different correctness thresholds significantly transform assessment outcomes. This means one good result ≠ reproducible quality.

---

## Part 2: CLAUDE.md as System Prompt

The most impactful pattern for AI-augmented development is treating your project context file (`CLAUDE.md`) as a system-level prompt. This works because:

1. **Persistence:** System prompts stay in context longer than conversational messages
2. **Clarity:** Structured rules are less likely to be dropped or forgotten by the model
3. **Consistency:** Every interaction starts with the same foundation
4. **Scale:** Works for multi-agent orchestration (each subagent reads the same context)

### Best Practices for CLAUDE.md

#### Structure Template

```markdown
# [Project Name]

## Purpose
One clear sentence describing what we're building and why.

## Architecture Overview
- Brief description of system design
- Key components and how they connect
- Tech stack decisions and their trade-offs

## Development Constraints
- Must-have rules (e.g., "All database queries use prepared statements")
- Forbidden patterns (e.g., "Never modify schema without migration")
- Testing requirements (e.g., "Unit test coverage must exceed 80%")

## Code Style & Patterns
- Language-specific conventions (indentation, naming, module structure)
- Error handling patterns (e.g., "Use Result<T, E> for fallible operations")
- Dependency injection or module patterns
- Examples of correct patterns (1-2 code samples)

## AI Workflow Rules
- Plan first, execute second (e.g., "Always show plan before implementing")
- Context files to preserve (e.g., ".env files never appear in prompts")
- Preferred tools and libraries
- When to escalate to human review

## Git Conventions
- Branch naming (e.g., feature/*, bugfix/*)
- Commit message format (conventionalcommits)
- PR review expectations

## Success Criteria
- Test pass rate expectations
- Performance benchmarks
- Security requirements

## Example Workflow
Step-by-step walkthrough of a typical task (feature implementation, bug fix, etc.)
```

#### Key Principles

**1. Positive Rules Over Negative Rules**
- ❌ "Don't use global variables"
- ✅ "Use dependency injection for all shared state"

Research shows larger models actually perform worse on negated instructions. Positive framing directs the model toward the desired behavior rather than detailing what to avoid.

**2. Show, Don't Tell**
Include 1-2 **real code examples** from your codebase demonstrating correct patterns:

```python
# CORRECT: Error handling with Result type
def fetch_user(user_id: int) -> Result[User, Error]:
    try:
        response = api.get(f"/users/{user_id}")
        return Ok(User.from_dict(response))
    except APIError as e:
        return Err(APIError(f"Failed to fetch user: {e}"))

# INCORRECT: Unhandled exceptions
def fetch_user(user_id: int) -> User:
    response = api.get(f"/users/{user_id}")
    return User.from_dict(response)
```

**3. Specificity Beats Generality**
- ❌ "Write clean code"
- ✅ "Use 2-space indentation, keep functions under 20 lines, name booleans with is_ prefix"

**4. Constraints Over Suggestions**
State constraints as requirements, not suggestions:
- ❌ "Consider using PostgreSQL for durability"
- ✅ "All persistent data must be stored in PostgreSQL with ACID guarantees"

### What to Include, What to Exclude

#### Include:
- Architecture decisions and their rationale
- Code style and naming conventions (with examples)
- Testing requirements and frameworks
- Database schema patterns or migrations
- Dependency constraints ("use only stdlib where possible")
- Security requirements ("never log credentials")
- Git workflow expectations
- Escalation triggers ("schema changes require human review")

#### Exclude:
- Credentials, API keys, or secrets (even examples)
- Hardcoded paths or environment-specific settings
- Frequently changing information (put in separate files)
- Verbose explanations (link to docs instead)
- Contradictory rules (be consistent)

### Real Production Examples

#### Example 1: FastAPI Backend Project

```markdown
# Payment Processing Service

## Architecture
RESTful API using FastAPI + PostgreSQL + Redis.
- `main.py`: ASGI app entry, middleware setup
- `routes/`: Endpoint handlers, separated by domain (payments, webhooks, etc.)
- `models/`: Pydantic schemas for validation
- `db/`: SQLAlchemy ORM models and migrations
- `services/`: Business logic (payment processing, reconciliation)

## Development Constraints
- No hardcoded configuration; use environment variables
- All database queries must use parameterized statements (SQLAlchemy ORM enforced)
- No blocking I/O in async handlers; use async/await consistently
- PCI DSS compliance: never log, store, or transmit full card numbers
- Unit test coverage >85%; integration tests for payment flows

## Code Style
- Type hints on all function signatures
- Error responses use standard JSON format: {"error": string, "code": int}
- Database errors return 500; validation errors return 400
- Docstrings for public functions (Google style)

## Example: Payment Endpoint
[Real code snippet showing correct request validation, error handling, response format]

## Git Workflow
- feature/payment-* for new features
- bugfix/payment-* for bug fixes
- Merge only after 1 approval + all tests pass
- Squash commits on merge
```

#### Example 2: React Frontend

```markdown
# Dashboard UI

## Architecture
Next.js + TypeScript + TailwindCSS
- `app/`: Page routes (App Router)
- `components/`: Reusable UI components (Button, Card, Form, etc.)
- `hooks/`: Custom React hooks for data fetching, forms, etc.
- `lib/`: Utilities (API client, formatters, constants)
- `__tests__/`: Jest + React Testing Library

## Constraints
- Components must be functional; no class components
- All external API calls through `lib/api.ts` (single source of truth)
- State management via useContext for local state, TanStack Query for server state
- Accessibility: ARIA labels on interactive elements, test with axe
- Mobile-first: design for 320px width, scale up
- No inline styles; use Tailwind classes only

## Code Style
- camelCase for functions/variables
- PascalCase for React components
- Use `const` for everything; never use `var`
- Imports grouped: React → external libs → local modules

## Testing
- Unit tests for utilities and hooks (Jest)
- Component tests for UI logic (React Testing Library)
- E2E tests for user workflows (Playwright)
- Aim for >80% coverage on business logic
```

---

## Part 3: Prompt Patterns for Coding Tasks

Different coding tasks benefit from different prompt structures. Use these patterns as templates.

### Pattern 1: Specification-Driven Prompting

**When to use:** Feature implementation, new modules, architectural changes
**Goal:** Move from vague requests to structured specifications
**Error reduction:** 30-50% fewer iteration cycles

**Template:**

```markdown
## Task: [Task Name]

### Specification
[Clear requirements document. Include:]
- What problem does this solve?
- Acceptance criteria (testable)
- Success metrics (e.g., "latency <100ms")
- Constraints (dependencies, tech stack, security)

### Context
[Show the model:]
- Existing patterns in the codebase (1-2 examples)
- Related files or modules
- Architectural decisions that affect this task

### Phased Approach
1. [Phase 1: Design/Planning]
2. [Phase 2: Implementation]
3. [Phase 3: Testing]
4. [Phase 4: Review]

[For each phase, specify:]
- What to create/modify
- Acceptance criteria for that phase
```

**Example:**

```markdown
## Task: Add Rate Limiting to Payment API

### Specification
Prevent abuse by limiting requests to 100 per minute per IP address.

**Acceptance Criteria:**
- Requests over limit return 429 status
- Rate limit headers included: X-RateLimit-Limit, X-RateLimit-Remaining
- Limit is shared across all payment endpoints
- Tests pass with 100% coverage
- Latency impact <5ms

### Context
Existing Redis setup in lib/cache.py. Similar rate limiting used in auth module (see auth/middleware.py).

### Implementation Plan
1. Design: Choose token-bucket or sliding-window algorithm
2. Implement: Add middleware to FastAPI app
3. Test: Unit tests for limit logic, integration tests for edge cases
4. Review: Ensure no performance regression

[Provide CLAUDE.md context for code style, testing requirements, etc.]
```

### Pattern 2: Chain-of-Thought for Architecture

**When to use:** Complex refactors, architectural decisions, multi-file changes
**Goal:** Make the model show its reasoning before coding
**Error reduction:** 28-35%

**Template:**

```markdown
## Task: [Complex Task]

### Problem Statement
[1-2 sentences describing the problem]

### Key Questions to Answer
1. [Question about design trade-offs]
2. [Question about consistency with existing patterns]
3. [Question about performance/security implications]

### Your Reasoning Process
Before implementing, please:

1. **Analyze:** Break down what needs to change and why
2. **Design:** Sketch the solution (pseudocode, data flow diagram)
3. **Verify:** Check consistency with existing code patterns
4. **Identify Risks:** What could go wrong?
5. **Plan Implementation:** Step-by-step execution order

### Then Execute
Once the reasoning is clear, implement it.
```

**Example (Claude Code Plan Mode):**

```
I need to migrate the User model from storing JSON in a text column to using a dedicated table.

Key questions:
1. How do we handle the migration without downtime?
2. Which code paths query the User data?
3. How does this affect serialization?

[Output: Claude shows reasoning first, then asks for approval before executing]
```

### Pattern 3: Few-Shot Prompting for Code Style

**When to use:** Generating code that matches your project style
**Goal:** Lock in consistent formatting, naming, patterns
**Improvement:** 15-40% increase in consistency

**Template:**

```markdown
## Task: [Coding Task]

### Examples of Correct Style in This Project

[Provide 2-3 real examples from your codebase]

**Example 1: API Endpoint**
[Real endpoint that shows request validation, error handling, response format]

**Example 2: Error Handling**
[Real code showing how errors are handled]

**Example 3: Testing**
[Real test showing your test style and assertions]

### Now Generate
[Your actual request]

Follow the style shown in the examples above. Match indentation, naming, error patterns, and test structure.
```

**Example:**

```python
# Example 1: Correct endpoint style
@app.post("/users/{user_id}/subscribe")
async def subscribe_user(
    user_id: int,
    request: SubscriptionRequest,
    db: Session = Depends(get_db),
) -> SubscriptionResponse:
    """Subscribe user to a plan."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Validate subscription
    subscription = await process_subscription(user, request)
    db.add(subscription)
    db.commit()
    return SubscriptionResponse.from_orm(subscription)

# Example 2: Error handling
def process_payment(amount: float) -> Result[str, PaymentError]:
    """Process payment and return transaction ID."""
    try:
        txn_id = stripe.charge(amount)
        return Ok(txn_id)
    except stripe.CardError as e:
        return Err(PaymentError(f"Card declined: {e.message}"))
    except stripe.RateLimitError:
        return Err(PaymentError("Rate limited; retry later"))

# Example 3: Testing style
def test_subscribe_user_returns_subscription():
    user = create_test_user()
    response = client.post(f"/users/{user.id}/subscribe", json={"plan": "pro"})
    assert response.status_code == 200
    assert response.json()["plan"] == "pro"

def test_subscribe_user_not_found():
    response = client.post("/users/9999/subscribe", json={"plan": "pro"})
    assert response.status_code == 404

# Now generate a new endpoint: POST /users/{user_id}/cancel_subscription
# Follow the style shown in Example 1, errors shown in Example 2, tests shown in Example 3.
```

### Pattern 4: Constraint-Based Prompting

**When to use:** When you need strong guarantees (security, format, logic)
**Goal:** Force the model to respect hard constraints
**Error reduction:** 31%

**Template:**

```markdown
## Task: [Task]

### Constraints (Non-negotiable)
- [MUST constraint 1]: What happens if violated?
- [MUST constraint 2]: How to verify?
- [SHOULD constraint 3]: Preference, can be discussed

### Implementation Requirements
[Your actual task]

Verify the implementation against each constraint before finishing.
```

**Example:**

```markdown
## Task: Implement User Authentication

### Constraints (Non-negotiable)
- MUST: Passwords hashed with bcrypt (min 12 rounds); never stored in plaintext
- MUST: Verify against list of compromised passwords (HaveIBeenPwned API)
- MUST: Lock account after 5 failed login attempts
- MUST: All password operations logged (not the password, just the action)
- SHOULD: Support 2FA via TOTP

### Implementation
Create login endpoint that:
1. Validates email format
2. Checks password strength
3. Verifies against compromised password list
4. Implements rate limiting and account lockout
5. Logs authentication events

Verify each constraint after implementation.
```

### Pattern 5: Role-Based Prompting

**When to use:** When you want specific expertise or perspective
**Goal:** Steer the model toward a particular mindset
**Caveat:** Most effective for reasoning tasks, less so for pure accuracy tasks

**Template:**

```markdown
## Task: [Task]

### Your Role
You are a [expert role: security architect | performance engineer | accessibility specialist].

Your job is to review the following code/design through the lens of [your specialty].

[Code/design to review]

Specifically evaluate:
1. [Concern 1 from your specialty]
2. [Concern 2 from your specialty]
3. [Concern 3 from your specialty]
```

**Example:**

```markdown
## Code Review Task

### Your Role
You are a security architect with 15 years of experience in web application security.

Review this payment processing code:
[code snippet]

Specifically evaluate:
1. Are there any injection vulnerabilities (SQL, command, etc.)?
2. Are credentials properly handled (never logged, never in URLs)?
3. Are there timing attacks possible (password comparison, timing side-channels)?
4. Is the cryptography usage correct?

Flag any issues with CVSS severity and recommended fixes.
```

---

## Part 4: Prompt Patterns for Each Dev Phase

Tailor prompts to the specific phase of development. This dramatically improves quality and reduces token waste.

### Research Phase

**Goal:** Validate assumptions before building
**Tools:** Web search, code analysis, API documentation
**Antipattern:** Building before understanding what exists

**Prompt Template:**

```markdown
## Research Task: [Topic]

### Background
[Context about the problem]

### Questions to Answer
1. What solutions already exist?
2. What are the trade-offs (performance, cost, complexity)?
3. What's the latest thinking on this (< 6 months)?
4. Are there benchmarks or real-world comparisons?

### Process
1. Search for: [specific search terms or docs to investigate]
2. Triangulate: Find 3+ independent sources that confirm findings
3. Check dates: Flag any findings older than 6 months
4. Summarize: List specific claims with sources (URLs)

### Output Format
For each finding, provide:
- What it says
- Source URL and publish date
- Confidence level (high/medium/low)
- Any caveats or contradictions
```

**Example:**

```markdown
## Research Task: React State Management for Large Apps

### Background
We're building a dashboard with 50+ components sharing state.

### Questions to Answer
1. What state management tools exist (TanStack Query, Redux, Zustand, Jotai)?
2. What are the performance trade-offs?
3. What does the React ecosystem recommend in 2026?
4. Are there benchmarks comparing these?

### Process
1. Search: "React state management 2026 comparison"
2. Search: "TanStack Query vs Redux vs Zustand performance"
3. Check: Official React docs (react.dev), TanStack Query, Redux docs
4. Verify: Multiple independent sources agree on trade-offs

### Output Format
For each tool, provide:
- What it does
- Performance: Bundle size, runtime overhead
- Learning curve: Time to adopt
- Ecosystem maturity: Community, job market
- Source URLs (must be < 6 months old)
```

### Planning Phase

**Goal:** Map out solution before writing code
**Anti-pattern:** Jumping to code without a plan

**Prompt Template (for Claude Code Plan Mode):**

```markdown
## Implementation Plan: [Feature]

### Spec
[Reference your CLAUDE.md and specification]

### Questions to Answer
1. What files do we need to create or modify?
2. What's the order of implementation (dependencies)?
3. What tests do we need to write first (TDD)?
4. Where are the risky parts that need careful design?

### Show Your Plan
Before implementing, provide:

1. **File Structure**
   - What files are involved?
   - What changes in each?

2. **Implementation Order**
   - Step 1: [What, why, expected result]
   - Step 2: ...
   - [Each step should be independently verifiable]

3. **Testing Strategy**
   - Unit tests (functions, classes)
   - Integration tests (file/module interactions)
   - E2E tests (if applicable)
   - Which tests block progress (must pass first)?

4. **Risk Analysis**
   - What could go wrong?
   - How do we verify it works?
   - Where should we add extra assertions?

### Then Execute
Once the plan is approved, execute it in order.
```

**Claude Code Specific:** Use Plan Mode with Shift+Tab or `/plan` command:

```
/plan
Create a new payment webhook endpoint that:
- Accepts POST requests from Stripe
- Verifies webhook signature
- Updates user subscription status
- Handles idempotency (same webhook twice = no duplicate action)
- Logs all state changes
```

### Implementation Phase

**Goal:** Convert plan to working code
**Output:** Code that's tested and follows patterns

**Prompt Template:**

```markdown
## Implementation: [Feature from Plan]

### Phase [N]: [What This Does]

### Context
[Reference CLAUDE.md style and patterns]
[Link to planning document]
[Show 1-2 code examples of correct style]

### Task
[What to implement]

### Acceptance Criteria
[From spec; tied to tests]

### Test First (TDD)
Before implementing, write tests that:
1. [Test criterion 1]
2. [Test criterion 2]

Tests should fail now (no implementation yet).

### Then Implement
Make the tests pass.

### Verify
- Tests pass: [yes/no]
- Coverage >80%: [yes/no]
- Follows code style: [yes/no]
- No new warnings: [yes/no]
```

### Testing Phase

**Goal:** Comprehensive test coverage and confidence
**Metric:** >80% line coverage, edge cases covered, no flaky tests

**Prompt Template:**

```markdown
## Test Writing: [Module or Feature]

### Module Overview
[What does this code do?]

### Examples of Correct Tests in This Project
[Show 1-2 real test examples from codebase]

### Coverage Goal
- Unit: >90% for critical paths
- Integration: Happy path + main error cases
- E2E: High-value user workflows

### Write Tests For
1. [Happy path: normal case]
2. [Edge case 1]
3. [Edge case 2]
4. [Error case 1]
5. [Error case 2]
6. [Boundary conditions]

For each, specify:
- What it tests
- Expected behavior
- How we verify it passed

### Test Structure
Follow the pattern from the examples above:
- Setup (arrange)
- Action (act)
- Verification (assert)
- Cleanup
```

### Review Phase

**Goal:** Catch bugs, security issues, architectural problems
**Mindset:** Adversarial; look for what could go wrong

**Prompt Template:**

```markdown
## Code Review: [Files or PR]

### Your Role
You are a code reviewer with expertise in [domain: security | performance | architecture].

### Context
[Link to CLAUDE.md for style expectations]
[What changed and why]

### Review Checklist
- [ ] Does it follow the code style guide (CLAUDE.md)?
- [ ] Are there any security issues (injection, auth, crypto)?
- [ ] Performance: Are there obvious bottlenecks (N+1 queries, loop nesting)?
- [ ] Are error cases handled?
- [ ] Are tests comprehensive?
- [ ] Does it align with existing architecture?

### Output Format
For each issue found:
- File and line number
- Issue category (style | security | performance | correctness)
- Severity (P0=blocks | P1=should fix | P2=nice to fix)
- Explanation
- Suggested fix
```

### Debugging Phase

**Goal:** Find and fix issues systematically
**Anti-pattern:** Random guessing; "add console.log everywhere"

**Prompt Template:**

```markdown
## Debugging: [Problem Description]

### Observed Behavior
[What's happening that shouldn't]

### Expected Behavior
[What should happen]

### Investigation Steps
1. Reproduce: [Exact steps to see the issue]
2. Isolate: [Is it always reproducible? In what conditions?]
3. Hypothesis: [What might be wrong?]

### Data to Provide
- [Relevant logs]
- [Relevant code]
- [Relevant test case that fails]

### Debug Process
1. Add assertion: Where should state be correct?
2. Narrow scope: What's the smallest code change that would fix it?
3. Root cause: Why is state wrong at that point?
4. Fix: Make the minimal change
5. Verify: Reproduce the fix, run all tests

### Output
- Root cause analysis
- The fix (code change)
- Test that prevents regression
- Verification that the original issue is gone
```

### Documentation Phase

**Goal:** Write docs that actually help
**Anti-pattern:** Auto-generated or copy-paste documentation

**Prompt Template:**

```markdown
## Write Documentation: [Module or Feature]

### Document Type
[README | API docs | Architecture guide | Tutorial]

### Audience
[Who reads this? Developers using this module? Future maintainers?]

### Required Sections
1. **What It Does** (1-2 sentences)
2. **Why You Might Need It** (when to use)
3. **Quick Start** (minimal working example)
4. **How It Works** (explanation of key concepts)
5. **Common Patterns** (2-3 real examples from the codebase)
6. **Gotchas & Troubleshooting** (what trips people up)
7. **API Reference** (if applicable)

### Examples
[Include 2-3 real code examples from the actual codebase]

### Link to Source
Document should link to actual code files for readers to explore.
```

---

## Part 5: Building and Managing Prompt Libraries

### Why Prompt Libraries Matter

- **Reusability:** Don't rewrite prompts for similar tasks
- **Consistency:** All code reviews use the same rubric
- **Versioning:** Track prompt changes and their impact
- **Evaluation:** A/B test prompt variants systematically
- **Documentation:** Capture tribal knowledge in explicit prompts

### Prompt Library Structure

```
prompts/
├── README.md                    # Guide to using this library
├── patterns/
│   ├── research.md              # Research phase prompts
│   ├── planning.md              # Planning phase prompts
│   ├── implementation.md         # Implementation patterns
│   ├── testing.md               # Test writing patterns
│   ├── review.md                # Code review templates
│   └── debugging.md             # Debugging patterns
├── tasks/
│   ├── feature-implementation.md
│   ├── bug-fix.md
│   ├── refactoring.md
│   ├── performance-optimization.md
│   ├── security-audit.md
│   ├── database-migration.md
│   └── api-design.md
├── evaluations/
│   ├── code-correctness.md      # Rubric for evaluating code
│   ├── security-checklist.md    # What to look for
│   └── performance-checklist.md
└── tools/
    ├── claude-code-patterns.md
    ├── cursor-patterns.md
    └── gemini-patterns.md
```

### Versioning Prompts

Use semantic versioning:

```yaml
# feature-implementation-v2.1.0.md
---
name: Feature Implementation
version: 2.1.0
description: |
  Prompt for implementing new features with spec-driven approach.
  v2.1.0: Added constraint-validation section; improved TDD guidance
author: [Your name]
last_updated: 2026-03-18
changes:
  - v2.1.0: Added constraint validation before implementation
  - v2.0.0: Restructured phases, added risk analysis
  - v1.0.0: Initial version
---

[Prompt content]
```

### A/B Testing Prompts

**Example:** Testing two code review approaches

```markdown
## Code Review A/B Test

### Control (Variant A): Current Review Prompt
[Existing prompt]

### Treatment (Variant B): New Review Prompt
[New prompt with specific improvements]

### Hypothesis
Variant B reduces review time by 30% while catching the same or more issues.

### Test Plan
1. Use Variant A for 50 PRs in week 1
2. Use Variant B for 50 PRs in week 2
3. Measure:
   - Review time (minutes)
   - Issues found per PR
   - False positives (issues flagged but not real)
   - Developer satisfaction
4. Run statistical test (t-test or Bayesian)
5. Deploy winner

### Metric Definitions
- Review time: Minutes from PR open to review complete
- Issues found: Count of legitimate bugs/style violations
- False positives: Suggestions that developer rejects
```

---

## Part 6: Evaluation & Measurement

### LLM-as-Judge Framework

**What:** Use a strong LLM (Claude, GPT-4) to evaluate outputs from other models or prompts.

**Why:** Scalable quality assessment without expensive labeled datasets.

**How to Implement:**

```markdown
## Evaluation Rubric: [Task Type]

### Task Definition
[What are we evaluating?]

### Evaluation Criteria

**Criterion 1: Correctness**
- Does the code work? (syntax, logic, no crashes)
- Does it solve the stated problem?
- Rating: 0 (broken) → 5 (correct)

**Criterion 2: Security**
- Are there injection vulnerabilities?
- Is sensitive data properly handled?
- Are cryptographic operations correct?
- Rating: 0 (critical flaw) → 5 (secure)

**Criterion 3: Performance**
- Are there obvious inefficiencies (N+1 queries)?
- Does it meet latency requirements?
- Rating: 0 (unacceptable) → 5 (optimal)

**Criterion 4: Maintainability**
- Is the code readable?
- Does it follow project conventions?
- Are edge cases handled?
- Rating: 0 (unmaintainable) → 5 (excellent)

### Evaluation Process
For each output:
1. Check criterion 1: [Assessment + evidence + rating]
2. Check criterion 2: [Assessment + evidence + rating]
3. Check criterion 3: [Assessment + evidence + rating]
4. Check criterion 4: [Assessment + evidence + rating]
5. Overall score: Average of criteria

### Pass/Fail Threshold
- Score ≥ 4.0: Pass (deployable with optional improvements)
- Score 3.0-3.9: Needs revision (fix before deploying)
- Score < 3.0: Fail (reject and try different prompt/model)
```

**Tools for LLM-as-Judge:**

- **Langfuse:** Open-source, run evaluations on production traces
- **Braintrust:** Managed evaluation service
- **CodeJudgeBench:** Specialized for coding tasks (code generation, repair, testing)

### Testing at Scale (100 Not 1)

**Critical finding:** Testing a prompt 100 times reveals inconsistencies that testing once misses.

**Implementation:**

```python
import json
from anthropic import Anthropic

# Test dataset: diverse examples
test_cases = [
    {"name": "simple_loop", "input": "Write a for loop that prints 1 to 10"},
    {"name": "error_handling", "input": "Write a function that reads a file and handles errors"},
    {"name": "edge_case_empty", "input": "Write a function that processes a list (empty list edge case)"},
    # ... 97 more test cases covering various scenarios
]

results = {"pass": 0, "fail": 0, "inconsistent": 0}

for i in range(100):
    for test_case in test_cases:
        # Run the same prompt variant 100 times
        response = client.messages.create(
            model="claude-opus-4-1",
            max_tokens=1024,
            system="Your CLAUDE.md context here",
            messages=[{"role": "user", "content": test_case["input"]}]
        )

        # Evaluate output
        is_correct = evaluate(response.content[0].text, test_case)
        results["pass" if is_correct else "fail"] += 1

# Consistency check
# If the same input produces different correctness on different runs, flag it
pass_rate = results["pass"] / (results["pass"] + results["fail"])
print(f"Pass rate: {pass_rate:.1%}")
```

### Evaluation Tools & Platforms

#### Langfuse (Self-Hosted & Cloud)
- **Strengths:** Open-source, LLM-as-judge evaluations, prompt versioning, CI/CD integration
- **Cost:** Free (self-hosted) or $99+/month (cloud)
- **Best for:** Teams running LLM apps in production

#### PromptLayer
- **Strengths:** Prompt versioning, A/B testing, performance monitoring
- **Cost:** Free tier; enterprise for self-hosting
- **Best for:** Focused prompt management

#### Braintrust
- **Strengths:** LLM-as-judge, evaluation templates, dataset management
- **Cost:** Managed service
- **Best for:** Organizations evaluating multiple prompts/models

#### CodeJudgeBench (Academic Benchmark)
- **Strengths:** Specialized for code evaluation
- **Use case:** Research; can guide your evaluation rubric

---

## Part 7: Tool-Specific Prompting

### Claude Code: Plan Mode & Subagents

#### Plan Mode Workflow

```markdown
## Using Plan Mode in Claude Code

### When to Use
- Complex features with multiple files
- Refactoring unknown codebases
- When you want to review the plan before execution

### How to Activate
- Command: `/plan` (or Shift+Tab twice)

### What to Include in Your Prompt

1. **Reference your CLAUDE.md**
   "Use the patterns from CLAUDE.md for this feature"

2. **Spec or Requirements**
   "Implement payment webhook with idempotency and signature verification"

3. **Acceptance Criteria**
   Clear, testable criteria

4. **Questions You Want Answered**
   - "What's the best way to handle retries?"
   - "Where are the risky parts?"

### Plan Mode Will Show
- Files to create/modify
- Implementation order
- Risk analysis
- Test strategy

### Next Steps
Review the plan. Ask for changes if needed. Say "approved" to execute.
```

#### Subagent Specifications

Subagents are specialized Claude instances for specific tasks. Effective subagent specs:

```yaml
# subagents/security-reviewer.md
---
name: Security Reviewer
type: general-purpose
model: claude-opus-4
description: Audits code for security vulnerabilities and best practices
temperature: 0.3  # Lower = more consistent
---

You are a security expert auditing code for vulnerabilities.

## Your Role
Review code for security issues: injection, auth flaws, crypto mistakes, data exposure.

## Rules
- Never assume input is valid; look for injection vectors
- Check sensitive data handling (never log credentials, never in URLs)
- Verify error messages don't leak information
- Look for timing attacks (password comparison)
- Check dependency versions for known CVEs

## Output Format
For each issue:
- File and line number
- Issue type (injection | auth | crypto | data-exposure | info-disclosure)
- CVSS severity (3.9 = low, 7.0 = high, 9.0 = critical)
- Explanation
- Recommended fix

[Link to CLAUDE.md for style; examples of secure code patterns]
```

### Cursor: @-Mention Patterns

#### @Mention Best Practices

```markdown
## Using @-Mentions in Cursor Composer

### Pattern 1: Multi-File Refactor
@ComponentA @ComponentB @utils @types
"Refactor these three components to use React Context instead of prop drilling."

The AI can see all files and understand their relationships.

### Pattern 2: Library Reference
@docs (library-name)
"Add error boundary to this component using React 19's error handling. Reference @docs react"

AI has access to official React documentation.

### Pattern 3: Codebase Pattern Discovery
@codebase "Show me how error handling is done in this project"
AI searches your entire project for patterns.

### Pattern 4: Multi-File With Documentation
@models @services @docs api-reference
"Implement the GET /users/{id} endpoint following patterns in @models and @services, using the schema from @docs"
```

#### @-Mention Context Optimization

```markdown
## Cursor Composer Context Optimization

### Load Bearing Context
- Always include: CLAUDE.md or .cursorrules (your conventions)
- Always include: Type definitions (@types)
- Always include: Existing similar implementations (for few-shot learning)

### Nice-to-Have Context
- Documentation (@docs)
- Configuration files
- Test examples

### Avoid Overloading
- Don't include entire modules if only one file matters
- Large files (>1000 lines) can be excerpted
- Use @codebase search instead of listing 20 files
```

### Gemini: Long Context (2M Token) Strategies

#### Context Caching for Large Documents

```markdown
## Gemini 2M Token Strategy

### Scenario 1: Document Analysis
You have a 100-page specification (500K tokens).

**Strategy:** Use context caching
```python
import anthropic

client = anthropic.Anthropic()

# The spec is cached on first request
spec_content = open("spec.txt").read()

response = client.messages.create(
    model="gemini-2-0-flash",
    max_tokens=2048,
    system=[
        {
            "type": "text",
            "text": "You are a spec reviewer. Analyze this specification and flag inconsistencies.",
            "cache_control": {"type": "ephemeral"}
        },
        {
            "type": "text",
            "text": spec_content,
            "cache_control": {"type": "ephemeral"}
        }
    ],
    messages=[
        {"role": "user", "content": "Are there any contradictory requirements?"}
    ]
)

# Subsequent requests use the cached spec (4x cheaper)
```

#### Strategies for 2M Token Window

1. **Put Your Query at the End**
   Load all context first, then ask the question. This improves accuracy.

2. **Chunk Large Datasets**
   - Document ID: Page 1, Page 2, etc.
   - Section markers: [SECTION A] ... [END SECTION A]
   - Table of contents: Gemini can skip to relevant sections

3. **Reference by Structure**
   "In the architecture diagram (Section 3, page 12), the payment flow shows..."
   Gemini can accurately retrieve and cite.

4. **Skip RAG If Possible**
   Unlike Claude, Gemini's 2M context often makes RAG unnecessary. Just include everything.

**Caveat:** Gemini still recommends RAG for retrieval (finding needles in haystacks). Direct inclusion works for analyzing complete documents.

---

## Part 8: Anti-Patterns

### Anti-Pattern 1: Negative Instructions

**❌ Bad:**
```
Don't use global variables.
Avoid overly complex nested logic.
Don't forget to handle errors.
Never hardcode API keys.
```

**Why it fails:** Research shows models, especially large ones, struggle with negated instructions. They focus on what not to do rather than what to do.

**✅ Good:**
```
Use dependency injection for all shared state.
Keep functions under 20 lines with clear names.
Wrap all external API calls in try-catch blocks.
Store API keys in environment variables; verify at startup.
```

### Anti-Pattern 2: Over-Prompting

**❌ Bad:**
```
Write unit tests AND integration tests AND E2E tests AND performance tests.
Handle all error cases: network errors, validation errors, permission errors, timeout errors, etc.
Implement payment processing, email notifications, webhook handling, and analytics tracking.
```

One prompt trying to do too much produces mediocre output for everything.

**✅ Good:**
```
Write unit tests for this module. Aim for >85% coverage.
[Separate prompt for integration tests]
[Separate prompt for E2E tests]
```

### Anti-Pattern 3: Kitchen-Sink Prompts

**❌ Bad:**
```
You are an expert Python developer with 20 years of experience who also knows DevOps, security, performance optimization, and database design. Write a FastAPI endpoint that handles user registration with validation, sends verification emails, stores in PostgreSQL following best practices, implements rate limiting, handles all security concerns, logs everything, and works efficiently. Follow PEP 8, use type hints, include comprehensive tests, write documentation, and think about monitoring.
```

The model gets confused by conflicting guidance and vague requirements.

**✅ Good:**
```
# Reference CLAUDE.md for all style and patterns
# Task: FastAPI endpoint for user registration
# Requirements: [3-5 specific, testable requirements]
# [Separated: email sending, database schema, rate limiting are separate tasks]
```

### Anti-Pattern 4: Not Testing Prompts

**❌ Bad:**
```
Used a prompt once, it worked, shipped it.
```

One success ≠ reproducible quality.

**✅ Good:**
```
Test the prompt with 100 inputs covering:
- Happy path (normal cases)
- Edge cases (empty input, very large input, special characters)
- Error cases (invalid input, missing fields)
- Consistency checks (same input → same correctness on different runs)
```

### Anti-Pattern 5: Contradictory Instructions

**❌ Bad:**
```
Be detailed and concise.
Write comprehensive tests AND keep them minimal.
Optimize for performance AND readability.
```

Contradictions force the model to guess.

**✅ Good:**
```
Be specific: List exact constraints and trade-offs.
- Performance target: <100ms latency
- Code readability: Follow CLAUDE.md patterns (which emphasize clarity)
- Test comprehensiveness: >80% coverage; prioritize security-critical and complex paths
```

### Anti-Pattern 6: Context Compression Loss

**The Problem:** System prompts (like CLAUDE.md) get compressed out of context as conversations grow.

**❌ Bad:**
Rely only on CLAUDE.md at the start.

**✅ Good:**
Use hooks (git pre-commit, pre-push) to enforce rules that don't depend on context. Langfuse or PromptLayer to version and track prompt adherence. For critical constraints, reference them explicitly in every task prompt.

---

## Part 9: 15 Production-Ready Prompt Templates

### Task 1: Feature Implementation

```markdown
## Feature: [Name]

### Specification
[Copy from your spec document]

### Context
[Reference CLAUDE.md for code style, testing requirements]

[Show 1-2 code examples from the project demonstrating correct patterns]

### Phased Implementation

**Phase 1: Design & Tests (TDD)**
Before implementing, write tests that:
1. Test the happy path (normal use case)
2. Test edge cases (boundary conditions)
3. Test error handling

Tests should fail before implementation.

**Phase 2: Implementation**
Make tests pass. Follow CLAUDE.md patterns.

**Phase 3: Integration**
Integrate with existing code. Run full test suite.

**Phase 4: Review**
Verify against acceptance criteria.

### Acceptance Criteria
[From specification; each testable]

### Success Metrics
[Performance, correctness, coverage]
```

### Task 2: Bug Fix

```markdown
## Bug Fix: [Bug Title]

### Observed Behavior
[What's happening that shouldn't]

### Expected Behavior
[What should happen]

### Root Cause Hypothesis
[Your guess about what's wrong]

### Investigation Steps
1. Write a test that reproduces the bug (should fail now)
2. Identify the exact code causing the issue
3. Understand why (wrong variable? off-by-one? logic error?)

### The Fix
1. Minimal code change to fix the issue
2. Verify the reproducing test now passes
3. Verify no other tests break

### Test Coverage
- Reproducing test: [added]
- Regression test: [verify it prevents this bug again]

### Verification
- Original bug is fixed: [yes/no]
- All tests pass: [yes/no]
- No new issues introduced: [yes/no]
```

### Task 3: Refactoring

```markdown
## Refactor: [What We're Improving]

### Current State
[What's the problem with the existing code?]

### Goals
[What do we want to achieve? Performance? Readability? Flexibility?]

### Plan
1. [Step 1: What changes and why]
2. [Step 2: Verify it still works]
3. [Step 3: Measure improvement]

### Constraints
- All existing tests must pass
- No behavioral changes (only internal structure)
- Performance must not regress

### Acceptance Criteria
- Code follows CLAUDE.md style: [yes/no]
- All tests pass: [yes/no]
- Coverage unchanged or improved: [yes/no]
- [Specific goal achieved]: [yes/no]

### Measurement
[How do we verify the improvement? Benchmarks? Code metrics?]
```

### Task 4: Test Writing

```markdown
## Write Tests For: [Module/Feature]

### What We're Testing
[Describe the code]

### Test Coverage Goals
- Happy path (normal case): [specific test]
- Edge case 1 (boundary): [specific test]
- Edge case 2: [specific test]
- Error case 1: [specific test]
- Error case 2: [specific test]

### Example Test (from this project)
[Show a real test from the codebase as a template]

### Test Each Criterion
For the happy path, edge cases, and error cases above:
- Write the test (include setup, action, assertion)
- Tests should fail before implementation (if implementing too)
- Tests should pass when code is correct

### Coverage Minimum
>80% line coverage. Prioritize:
- Critical business logic
- Error handling
- Boundary conditions
```

### Task 5: Code Review

```markdown
## Review: [Files/PR]

### What Changed
[Brief summary of the change]

### Review Against Checklist

**Style & Conventions**
- [ ] Follows CLAUDE.md (indentation, naming, structure)
- [ ] No console.log or debug code left in
- [ ] Error messages are clear

**Correctness**
- [ ] Code logic is sound (no off-by-one, wrong variable, etc.)
- [ ] Edge cases handled
- [ ] Tests exist and pass

**Security**
- [ ] No hardcoded credentials
- [ ] Input validation present
- [ ] No injection vulnerabilities (SQL, command, etc.)

**Performance**
- [ ] No obvious inefficiencies (N+1 queries, nested loops)
- [ ] Meets latency requirements

**Maintainability**
- [ ] Code is readable (well-named functions/variables)
- [ ] Complex logic is commented
- [ ] Follows project patterns

### Issues Found
For each issue:
- Location (file, line)
- Category (style | correctness | security | performance)
- Severity (P0=blocking | P1=should fix | P2=nice to fix)
- Explanation
- Suggested fix

### Summary
[Overall assessment: Approve | Request Changes | Needs Major Revision]
```

### Task 6: Performance Optimization

```markdown
## Optimize: [Component or Function]

### Current Performance
[Baseline metrics: latency, memory, throughput]

### Performance Target
[What do we want to achieve?]

### Investigation
1. Profile: Identify the bottleneck (where's the time spent?)
2. Analyze: Why is it slow? (N+1 queries? Inefficient algorithm? Blocking I/O?)
3. Brainstorm: What are 3+ potential solutions?
4. Trade-offs: Which solution is best? (complexity vs. benefit)

### Implementation
[Your optimization fix]

### Verification
1. Benchmark: New latency/memory/throughput
2. Test: All tests pass
3. Regression: No new issues introduced

### Metrics
- Before: [original metrics]
- After: [new metrics]
- Improvement: [X% faster / X% less memory]
```

### Task 7: Security Audit

```markdown
## Security Audit: [Module or Feature]

### Context
[What does this code do? What are the security implications?]

### Threat Model
1. [What attacker capabilities do we defend against?]
2. [What data are we protecting?]
3. [What's the impact if compromised?]

### Security Checklist

**Authentication & Authorization**
- [ ] Is user identity verified?
- [ ] Are permissions enforced?
- [ ] Can users access other users' data?

**Data Protection**
- [ ] Sensitive data is encrypted in transit (TLS)
- [ ] Sensitive data is encrypted at rest
- [ ] Credentials are not logged or exposed

**Input Validation**
- [ ] All external input is validated
- [ ] Are there injection vulnerabilities (SQL, command, etc.)?

**Cryptography**
- [ ] Passwords hashed with strong algorithm (bcrypt, argon2)
- [ ] Crypto operations are correct (not rolling custom crypto)
- [ ] Keys are managed securely

**Error Handling**
- [ ] Error messages don't leak sensitive information
- [ ] Errors are logged (for investigation)

### Findings
For each issue:
- Vulnerability type
- CVSS severity
- Proof of concept (if applicable)
- Recommended fix
- Urgency (immediate | urgent | soon)

### Remediation Plan
[How and when to fix each issue]
```

### Task 8: Database Migration

```markdown
## Database Migration: [What We're Changing]

### Current Schema
[Show current structure]

### Target Schema
[Show desired structure]

### Migration Strategy
1. Create new column/table
2. Backfill data (if needed)
3. Update code to use new structure
4. Deprecate old structure
5. Drop old structure (in later release)

### Zero-Downtime Considerations
- Can we roll this back if something breaks?
- Do we need to support both old and new format during rollout?
- Are there any locking concerns (will this block users)?

### Tests
- Data integrity: All data migrated correctly
- Backward compatibility: Old code still works
- Performance: No performance regression

### Rollback Plan
If something goes wrong: [how to revert]

### Verification
- Data integrity check: [query to verify all data migrated]
- Test passed: [yes/no]
```

### Task 9: API Design

```markdown
## Design API: [Endpoint or Service]

### Requirements
[What should this API do?]

### Design Decisions

**Endpoint & HTTP Method**
- Path: `/api/v1/[resource]`
- Method: [GET/POST/PUT/DELETE]
- Why this choice?

**Request Format**
[Example request with all fields]

**Response Format**
[Example response for success and error cases]

**Status Codes**
- 200: [Success case]
- 400: [Bad request]
- 401: [Unauthorized]
- 404: [Not found]
- 500: [Server error]

**Error Response**
```json
{
  "error": "string describing the error",
  "code": "ERROR_CODE",
  "details": {...}
}
```

**Validation**
[What inputs are invalid? How do we respond?]

**Rate Limiting**
[How many requests per time period?]

### Examples
[3-5 real usage examples]

### Tests
[Unit tests for this endpoint covering happy path, errors, edge cases]
```

### Task 10: Documentation

```markdown
## Write Docs: [Module or Feature]

### Document Type
[README | API Docs | Architecture Guide | Tutorial]

### Audience
[Who reads this? Example use cases.]

### Structure

**What It Does** (1-2 sentences)
[Brief description]

**Why You Need It**
[When would you use this?]

**Quick Start** (5 minutes)
[Minimal working example]

**How It Works** (detailed explanation)
[Key concepts and architecture]

**Common Patterns** (real examples)
[3+ examples from the actual codebase]

**Gotchas** (things that trip people up)
[Common mistakes and how to avoid]

**Reference** (if applicable)
[API / function signatures]

**Links** (to source code, related docs)
[Where to find more information]

### Examples
[All examples from actual codebase, not made-up]

### Review Checklist
- [ ] Examples are from real code (copy-pasted, not paraphrased)
- [ ] All links work
- [ ] No outdated information
- [ ] Readable for someone new to the project
```

### Task 11: Debugging

```markdown
## Debug: [Problem]

### Symptoms
[What's happening that's wrong?]

### Reproduction
[Steps to see the bug consistently]

### Hypothesis
[What might be wrong?]

### Investigation
1. Assertion: Where should state be correct? Add assertion.
2. Logs: Trace execution. What values are wrong?
3. Isolation: What's the minimal code change that would fix it?
4. Root cause: Why is it wrong at that point?

### The Fix
[Minimal code change]

### Test
[Write test that reproduces the bug; verify it passes after fix]

### Verification
- Bug is fixed: [yes/no]
- No new bugs introduced: [tests pass]
```

### Task 12: Batch Processing Task

```markdown
## Implement Batch Job: [Task Name]

### Goal
[What data are we processing? What's the outcome?]

### Input
[Data source, format, volume]

### Processing
[What transformation or analysis?]

### Output
[Where does result go? Format?]

### Error Handling
- Invalid records: [skip with logging, fail entirely, etc.]
- Partial failure: [what's the acceptable failure rate?]
- Retry strategy: [exponential backoff?]

### Performance
- Target throughput: [X records per second]
- Memory constraints: [process in batches of Y to avoid OOM]

### Monitoring
[How do we know it succeeded? Metrics to track?]

### Tests
[Test with small dataset, edge cases, error scenarios]
```

### Task 13: API Integration

```markdown
## Integrate External API: [API Name]

### API Overview
[What does this API do?]

### Authentication
[How do we authenticate? API key? OAuth? Token?]

### Endpoints We Need
[List the specific endpoints and what they do]

### Error Handling
[What errors can the API return? How do we handle them?]

### Rate Limiting
[Are there rate limits? How do we respect them?]

### Retry Strategy
[Which errors are retryable? Backoff strategy?]

### Wrapper Implementation
```python
class [APIName]Client:
    def __init__(self, api_key: str): ...

    def [method_1](self, ...): ...
    def [method_2](self, ...): ...

    # Error handling and retries built in
```

### Tests
[Mock the API, test happy path and error cases]

### Monitoring
[Log failures, track latency, alert on errors]
```

### Task 14: Configuration Management

```markdown
## Configuration: [Feature]

### Settings
[What configurable values?]

### Environment Variables
[SETTING_1=default_value  # What this controls]

### Configuration File (if needed)
[YAML/JSON structure]

### Validation
[What values are valid? Min/max? Enum options?]

### Defaults
[Sensible defaults for each setting]

### Documentation
[How to set each value? What does it do? What's the impact of changing it?]

### Testing
[Test with different config values]
```

### Task 15: Performance Benchmark

```markdown
## Benchmark: [Component]

### Setup
[Hardware / environment: CPU, RAM, OS]
[Warmup: Run N iterations to stabilize]

### Workload
[What are we measuring?]
[Input size: small / medium / large]
[Iterations: N runs to get average]

### Metrics
- Latency (p50, p99): Response time
- Throughput: Requests per second
- Memory: Peak usage

### Baseline
[Previous measurement to compare against]

### Run Benchmark
[Script or process to measure]

### Results
- Metric 1: X ms (before: Y ms, +/- Z%)
- Metric 2: ...

### Analysis
[Is this acceptable? Is this an improvement? Does it meet targets?]

### Regression Test
[Add to CI/CD to prevent performance regressions]
```

---

## Part 10: Prompt Maintenance

### Why Prompts Go Stale

1. **Model updates:** OpenAI updates gpt-4o regularly; weights change; prompts may break
2. **Code evolution:** Your codebase patterns change; old examples become outdated
3. **New requirements:** Features and constraints change over time
4. **Forgotten assumptions:** Prompts assume context that's no longer valid

### Staleness Detection

Add metadata to track freshness:

```yaml
# feature-implementation-v2.1.0.md
---
name: Feature Implementation
version: 2.1.0
last_tested: 2026-03-18
test_date: 2026-03-18  # When we last verified this prompt works
model_version: claude-opus-4.1  # Model tested with
status: active
warnings: []
---

[Prompt content]
```

### Staleness Signals

- **Code examples are outdated:** Project has changed; examples no longer match style
- **No recent tests:** Haven't measured effectiveness in > 1 month
- **Model deprecations:** Using old model versions
- **Requirement changes:** New patterns or constraints added to CLAUDE.md
- **Performance regressions:** Prompts used to work; now they don't

### Regression Testing for Prompts

```python
import json
from datetime import datetime
from anthropic import Anthropic

# Test dataset (from production or known good examples)
test_cases = [
    {
        "name": "simple_feature",
        "input": "Create a REST endpoint for fetching user by ID",
        "expected_criteria": ["has error handling", "follows CLAUDE.md style", "includes tests"]
    },
    # ... more test cases
]

def evaluate_output(output: str) -> dict:
    """Use LLM-as-judge to evaluate output."""
    rubric = """
    Does the code:
    - Have error handling? (yes/no)
    - Follow CLAUDE.md style? (yes/no)
    - Include tests? (yes/no)
    """
    # Use Claude as judge
    response = client.messages.create(
        model="claude-opus-4",
        max_tokens=256,
        system=rubric,
        messages=[{"role": "user", "content": output}]
    )
    return parse_evaluation(response.content[0].text)

# Run regression suite
results = {
    "test_date": datetime.now().isoformat(),
    "model": "claude-opus-4.1",
    "prompt_version": "2.1.0",
    "tests": []
}

for test_case in test_cases:
    # Run the prompt
    response = client.messages.create(
        model="claude-opus-4.1",
        max_tokens=2048,
        system="[Your CLAUDE.md and prompt]",
        messages=[{"role": "user", "content": test_case["input"]}]
    )

    # Evaluate
    evaluation = evaluate_output(response.content[0].text)
    results["tests"].append({
        "name": test_case["name"],
        "passed": evaluation["passed"],
        "criteria_met": evaluation["criteria"],
        "feedback": evaluation["feedback"]
    })

# Save results
with open(f"regression-test-{datetime.now().isoformat()}.json", "w") as f:
    json.dump(results, f, indent=2)

# Fail CI if regression detected
passed = sum(1 for t in results["tests"] if t["passed"])
total = len(results["tests"])
print(f"Regression Test: {passed}/{total} passed")
if passed < total * 0.95:  # Allow 5% failure
    exit(1)  # Fail CI
```

### Updating Prompts

Use semantic versioning:

- **MAJOR (v3.0.0):** Breaking changes (output format changes, new required criteria)
- **MINOR (v2.1.0):** New features (added optional criteria, new examples)
- **PATCH (v2.0.1):** Bug fixes (typo, clearer wording, better example)

**Changelog:**

```yaml
changes:
  - v2.1.0: Added constraint-validation section; improved TDD guidance; tested 2026-03-18
  - v2.0.0: Restructured phases, added risk analysis; tested 2026-02-15
  - v1.0.0: Initial version; tested 2026-01-10
```

### Measuring Prompt Quality in Production

#### Metrics to Track

Using Langfuse or PromptLayer:

```
For each prompt execution:
- Input (task description)
- Output (generated code or plan)
- Model & version
- Latency
- Cost (tokens)
- Success criteria met (yes/no)
- Developer feedback (shipped / revised / rejected)
```

**Calculate:**

```
Success rate = (shipped + minimal revisions) / total uses
Cost per successful output = sum(tokens) / successful outputs
Latency p99 = 99th percentile execution time
Consistency = success rate over 100+ runs
```

**Alert on:**

```
- Success rate drops below threshold (e.g., <80%)
- Latency p99 increases significantly
- Cost per output increases
- Model updates break prompts
```

### Version Control Prompts Like Code

```bash
# In your repo
git add prompts/patterns/feature-implementation-v2.1.0.md
git commit -m "feat(prompts): add constraint validation to feature-impl prompt

- Added MUST constraint section
- Improved TDD guidance with explicit test-first emphasis
- Tested against 100 real feature requests
- Pass rate: 92% (up from 85% in v2.0.0)
- Fixes: #1234"
```

---

## Part 11: Integration with CLAUDE.md

Prompts and CLAUDE.md work together:

**CLAUDE.md** = permanent, project-wide rules
**Prompts** = task-specific, temporary guidance

**Pattern:**

```markdown
## Feature Implementation Task

[Reference CLAUDE.md]
```python
from CLAUDE.md:
- Code style: [Section 3]
- Testing requirements: [Section 4]
- Error handling: [Section 5]
```

[Prompt content for this specific task]
```

---

## Part 12: Quick Decision Tree

**Which prompt pattern should I use?**

```
Is it a complex, multi-file change?
  → Chain-of-Thought for architecture

Are you generating code that needs specific style?
  → Few-Shot with examples

Do you need hard guarantees (security, format)?
  → Constraint-Based prompting

Do you want the model to think like an expert?
  → Role-Based prompting

Is the task unclear or vague?
  → Specification-Driven prompting (write the spec first)

Are you reviewing or auditing?
  → LLM-as-Judge with rubric

Are you unfamiliar with the domain?
  → Research phase prompt (triangulate 3+ sources)

Do you want to test variations?
  → A/B test with Langfuse
```

---

## Sources

### Prompt Engineering & Evaluation

- [Prompt Engineering 2026 Series - Medium](https://medium.com/codetodeploy/prompt-engineering-2026-series-0-introduction-3e331e955433)
- [The 5 Best Prompt Evaluation Tools in 2025 - Braintrust](https://www.braintrust.dev/articles/best-prompt-evaluation-tools-2025)
- [Prompt Engineering Best Practices 2026 - Thomas Wiegold](https://thomas-wiegold.com/blog/prompt-engineering-best-practices-2026/)
- [Prompting Best Practices - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [Prompt Engineering Overview - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview)
- [I Studied 1,500 Academic Papers on Prompt Engineering - Aakash Gupta Medium](https://www.aakashgupta.medium.com/i-studied-1-500-academic-papers-on-prompt-engineering-heres-why-everything-you-know-is-wrong-391838b33468)
- [The Ultimate Guide to Prompt Engineering in 2026 - Lakera](https://www.lakera.ai/blog/prompt-engineering-guide)

### Chain of Thought & Few-Shot

- [Chain-of-Thought Prompting - Prompt Engineering Guide](https://www.promptingguide.ai/techniques/cot)
- [Few-Shot Prompting - Prompt Engineering Guide](https://www.promptingguide.ai/techniques/fewshot)
- [Chain of Thought Prompting Explained - Codecademy](https://www.codecademy.com/article/chain-of-thought-cot-prompting)

### Claude Code & System Prompts

- [Create Custom Subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Claude Code System Prompts - GitHub](https://github.com/Piebald-AI/claude-code-system-prompts)
- [Best Practices for Claude Code - Claude Code Docs](https://code.claude.com/docs/en/best-practices)
- [How to Structure Claude Code for Production - DEV Community](https://dev.to/lizechengnet/how-to-structure-claude-code-for-production-mcp-servers-subagents-and-claudemd-2026-guide-4gjn)

### LLM-as-Judge

- [LLM-as-a-Judge Complete Guide - Confident AI](https://www.confident-ai.com/blog/why-llm-as-a-judge-is-the-best-llm-evaluation-method)
- [CodeJudgeBench: Benchmarking LLM-as-a-Judge for Coding Tasks - arXiv](https://arxiv.org/abs/2507.10535)
- [LLM-as-a-Judge Evaluation - Langfuse Docs](https://langfuse.com/docs/evaluation/evaluation-methods/llm-as-a-judge)

### Prompt Management & Versioning

- [Prompt Version Control - Langfuse](https://langfuse.com/docs/prompt-management/features/prompt-version-control)
- [Open Source Prompt Management - Langfuse](https://langfuse.com/docs/prompt-management/overview)
- [Prompt Regression Testing: Preventing Quality Decay - Statsig](https://www.statsig.com/perspectives/slug-prompt-regression-testing)
- [Prompt Testing in CI/CD (2025) - Prompt Builder](https://promptbuilder.cc/blog/prompt-testing-versioning-ci-cd-2025)

### A/B Testing Prompts

- [A/B Testing of LLM Prompts - Langfuse](https://langfuse.com/docs/prompt-management/features/a-b-testing)
- [A/B Testing for LLM Prompts: A Practical Guide - Braintrust](https://www.braintrust.dev/articles/ab-testing-llm-prompts)
- [How to Implement Effective A/B Testing for AI Agent Prompts - Maxim](https://www.getmaxim.ai/articles/how-to-implement-effective-a-b-testing-for-ai-agent-prompts/)

### Anti-Patterns & Negative Prompting

- [Anti-Pattern Avoidance for Safer AI-Generated Code - Endor Labs](https://www.endorlabs.com/learn/anti-pattern-avoidance-a-simple-prompt-pattern-for-safer-ai-generated-code)
- [Best Practices for LLM Prompt Engineering - Palantir](https://www.palantir.com/docs/foundry/aip/best-practices-prompt-engineering)

### Constraint-Based Prompting

- [Constraint-Based Prompts - Andrew Maynard](https://andrewmaynard.net/constraint-based-prompts/)
- [Spec-Driven Prompt Engineering for Developers - Augment Code](https://www.augmentcode.com/guides/spec-driven-prompt-engineering-for-developers)

### Role-Based Prompting

- [Role Prompting: Guide LLMs with Persona-Based Tasks - Learn Prompting](https://learnprompting.org/docs/advanced/zero_shot/role_prompting)
- [Role-Prompting: Does Adding Personas Make a Difference? - PromptHub](https://www.prompthub.us/blog/role-prompting-does-adding-personas-to-your-prompts-really-make-a-difference)

### Cursor IDE & @-Mentions

- [Cursor Composer - Official Docs](https://docs.cursor.com/composer)
- [Cursor Composer: Practical Guide with Best Practices - Igor's Techno Club](https://igorstechnoclub.com/cursor-composer-a-practical-guide-with-best-practices/)

### Gemini Long Context

- [Long Context - Gemini API Docs](https://ai.google.dev/gemini-api/docs/long-context)
- [Google Gemini Context Window: Token Limits & Strategies - DataStudios](https://www.datastudios.org/post/google-gemini-context-window-token-limits-model-comparison-and-workflow-strategies-for-late-2025)
- [Gemini 1.5 Pro 2M Context Window - Google Developers Blog](https://developers.googleblog.com/en/new-features-for-the-gemini-api-and-google-ai-studio/)

---

## Next Steps

1. **Audit your current prompts:** Are they specification-driven? Tested? Versioned?
2. **Create CLAUDE.md** for your project (if you haven't already) following the structure in Part 2
3. **Pick one task from Part 9** and create a template for your team
4. **Set up Langfuse or PromptLayer** to start tracking prompt quality
5. **Test a prompt 100 times** to establish baseline consistency
6. **Share this guide** with your team; reference it in code reviews
7. **Version your prompts** like code; track effectiveness; iterate

Prompt engineering is now a discipline. Small investments in structure yield large returns in quality and cost.

---

## Related Topics

- [Claude Code Power User](claude-code-power-user.md) — Practical techniques for maximizing Claude's code capabilities
- [Context Memory Systems](context-memory-systems.md) — Designing context to improve prompt consistency and reduce costs
- [Testing AI-Generated Code](testing-ai-generated-code.md) — Validating code quality from well-engineered prompts
