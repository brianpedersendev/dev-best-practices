# Testing AI-Generated Code: Comprehensive Guide to Quality, Security & Production Readiness

**A complete guide to testing strategies, security practices, verification workflows, and tooling for catching the specific bugs and vulnerabilities that AI coding tools introduce.**

**Last Updated:** March 18, 2026
**Status:** Production-ready with specific tool configs and CI/CD examples
**Confidence Level:** High (benchmarks from production systems, 2025-2026 research, verified patterns)

---

## Executive Summary

AI-generated code has **1.7x more issues** than human-written code. **87% of developers worry** about accuracy, **81% about security**, and **45% of AI PRs contain security flaws** ([Veracode 2025 GenAI Code Security Report](https://www.veracode.com/resources/analyst-reports/2025-genai-code-security-report/)). Yet **62% of teams now use AI to assist with testing**, and teams combining TDD + AI see **40-90% defect reduction** vs. AI-only development.

> **Metric clarification:** The 1.7x figure measures *defect density* across all issue types ([CodeRabbit State of AI Code Gen Report](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report)). The 45% figure measures *percentage of PRs containing ≥1 security flaw* (Veracode). These are different studies with different methodologies — both are valid but not directly comparable.

The problem isn't that AI code is bad—it's that **testing strategies designed for humans don't work for AI**. AI excels at happy paths but fails silently on edge cases, input validation, and error conditions. AI also produces code that _looks_ correct, making it dangerous to trust visual inspection alone.

This guide covers the complete testing strategy for AI-generated code: from TDD foundations through security scanning, code review patterns, production readiness checklists, and tool-specific implementations for Claude Code, Cursor, and CI/CD pipelines.

---

## Table of Contents

1. [The AI Code Quality Problem](#the-ai-code-quality-problem)
2. [TDD as the Foundation](#tdd-as-the-foundation)
3. [Testing Strategies by Type](#testing-strategies-by-type)
4. [Security Testing for AI Code](#security-testing-for-ai-code)
5. [AI-Assisted Test Generation](#ai-assisted-test-generation)
6. [The Verification Workflow](#the-verification-workflow)
7. [Code Review for AI Code](#code-review-for-ai-code)
8. [Tool-Specific Testing Patterns](#tool-specific-testing-patterns)
9. [CI/CD Integration & Hooks](#cicd-integration--hooks)
10. [Metrics & Monitoring](#metrics--monitoring)
11. [Production Testing Checklist](#production-testing-checklist)

---

## 1. The AI Code Quality Problem

### Specific Defects AI Introduces

**Logic Errors & Edge Cases (87% of failures):**
- Missing null checks: AI generates code that works for happy paths but crashes on `null`, `undefined`, or empty collections
- Off-by-one errors in loops and boundary conditions
- Incorrect handling of 0, negative numbers, or special values
- Assumptions about data type consistency (e.g., dates as strings vs. timestamps)

**Example:** AI generates code to sort users by last login:
```javascript
users.sort((a, b) => new Date(a.lastLogin) - new Date(b.lastLogin))
```
This fails when `lastLogin` is `null`, stored as a Unix timestamp, or an invalid date string. AI doesn't spontaneously add defensive checks.

**Input Validation Gaps (67% of AI PRs):**
- Missing string length validation (vulnerable to DoS)
- No type checking on user input
- Unvalidated database queries
- No file path traversal protection

**Exception Handling Omission (71% of AI code):**
- Missing try-catch blocks
- No retry logic for flaky operations
- Silent failures instead of explicit error messages
- Incorrect exception types

**Security Issues (45% contain flaws):**
- Hardcoded credentials, API keys, or secrets
- Improper password handling (plain text comparison, weak hashing)
- Insecure deserialization (2.74x more common in AI code)
- XSS vulnerabilities (1.82x more common)
- SQL injection and path traversal due to missing parameterization

**Resource Leaks (8x more common in AI PRs):**
- Unclosed file handles, database connections, or streams
- Excessive I/O operations
- Memory leaks in loops

**Architecture Violations:**
- Code that doesn't follow codebase conventions
- Wrong patterns for async, caching, or dependency injection
- Duplicated business logic instead of reusing utilities

### The Statistics

| Metric | Finding |
|--------|---------|
| **Defect Density** | AI code has 1.7x more issues than human code |
| **Initial Test Pass Rate** | AI code passes only 42% of comprehensive tests on first attempt |
| **Security Flaws** | 45% of AI-generated code contains security flaws |
| **Developer Concern** | 87% worry about accuracy, 81% about security |
| **AI Code in PRs** | 41% of merged PRs now contain AI-assisted code |
| **Manual Verification Time** | Review time equals or exceeds writing time (no speedup from AI verification alone) |
| **Logic Errors** | +75% compared to human-written code |
| **Security Findings** | +57% compared to human-written code |

**Key Insight:** The problems are systematic, not random. They concentrate in three areas: boundary conditions, security controls, and exception handling.

---

## 2. TDD as the Foundation

### Why TDD Works With AI

TDD is the single highest-leverage practice for AI-generated code quality. Here's why:

1. **AI thrives on clear contracts.** A test is the clearest specification you can give an AI agent: "Here's the input, here's the expected output, here's the failure case."

2. **Tests prevent agents from cheating.** If tests exist before code, agents can't write tests that verify broken behavior. Agent-written tests often pass the wrong code.

3. **Tight feedback loop.** Tests run immediately, showing the agent exactly what's wrong within seconds.

4. **Defect reduction is dramatic:** 40-90% reduction in defects when TDD precedes AI code generation vs. AI-only development. (The low end—40%—reflects basic TDD on simple CRUD code; the high end—90%—reflects comprehensive TDD with property-based testing on complex logic and boundary conditions.)

### The TDD + AI Workflow (Step-by-Step)

**Phase 1: Write Tests First (AI-Assisted)**
```bash
1. Write feature spec in plain English
2. Ask AI to generate unit tests for that spec
3. Review tests for coverage (happy path, edge cases, errors)
4. Commit tests before writing any implementation code
```

**Example Prompt for Test Generation:**
```
Generate unit tests for a function `getUserById(id: number)` that:
- Returns user when ID exists
- Throws UserNotFound when ID doesn't exist
- Throws ValidationError when id is null/undefined/negative
- Returns the same user object (identity check) on repeated calls
- Handles concurrent requests without race conditions

Include tests for edge cases: id=0, id=-1, id=99999, id="not-a-number".
Use Jest syntax. Include setup/teardown for database mocks.
```

**Phase 2: Generate Implementation (AI-Driven)**
```bash
1. Show AI the tests and say "Make these pass"
2. Run tests immediately after generation
3. If tests fail, iterate with AI on the failures
4. Only when tests pass 100% do you move to review
```

**Phase 3: Verify & Scan**
```bash
1. Run linters (ESLint, Semgrep, Bandit)
2. Run security scanners (SAST, input validation checks)
3. Run static type checking (TypeScript, mypy)
4. Human review with the tests as reference
```

### Metrics Show the Impact

| Practice | Defect Reduction | Test Coverage | Time to Fix |
|----------|-----------------|---------------|------------|
| AI-only (no tests) | Baseline | 42% initial pass | High |
| TDD + AI | 40-90% | 89% initial pass | Low |
| TDD + AI + SAST hooks | 60-95% | 92%+ | Very Low |

**Evidence:** Studies at Microsoft, IBM, and Google Cloud show consistent 40-90% defect reduction. Teams using TDD with AI reduce QA cycles by 43% and cut testing time in half (~$1.2M savings reported).

### Tool-Specific TDD Patterns

**Claude Code:**
```bash
# 1. Write tests in a spec file first
# 2. Use Plan Mode to outline implementation
# 3. Let Claude fill in code against tests
# 4. Run hooks to enforce test passing before commit

# In CLAUDE.md:
Workflow: Tests → Plan → Implement → Verify Tests Pass → SAST Scan → Commit
```

**Cursor:**
```bash
# 1. Write tests using Cmd+K or @test-generator
# 2. Use Composer to implement against tests
# 3. Background agents run tests on each save
# 4. CI/CD gates enforce test passing
```

**GitHub Actions (CI/CD):**
```yaml
- name: Run tests before AI code review
  run: npm test

- name: Block merge if coverage < 85%
  run: |
    coverage=$(npm run coverage:report | grep "Lines" | awk '{print $NF}' | sed 's/%//')
    if (( $(echo "$coverage < 85" | bc -l) )); then
      echo "Coverage $coverage% below 85% threshold"
      exit 1
    fi
```

---

## 3. Testing Strategies by Type

### Unit Testing (AI Writes Well)

**What AI Does Well:**
- Happy path tests (the basic case)
- Boilerplate test scaffolding
- Single-function behavior verification
- Mock setup and assertions

**What AI Misses:**
- Edge cases (especially null, empty, boundary values)
- Error paths and exception handling
- Performance characteristics
- Concurrency and race conditions

**Strategy for AI-Generated Unit Tests:**

```typescript
// ❌ Bad: AI-generated unit test (incomplete)
test('getUserById returns user', () => {
  const user = getUserById(1);
  expect(user.name).toBe('Alice');
});

// ✅ Good: Complete unit test (human-guided, AI-assisted)
describe('getUserById', () => {
  // Happy path
  test('returns user when ID exists', () => {
    const user = getUserById(1);
    expect(user.id).toBe(1);
    expect(user.name).toBe('Alice');
  });

  // Edge cases
  test('returns null for non-existent ID', () => {
    const user = getUserById(99999);
    expect(user).toBeNull();
  });

  test('throws ValidationError for invalid IDs', () => {
    expect(() => getUserById(null)).toThrow(ValidationError);
    expect(() => getUserById(-1)).toThrow(ValidationError);
    expect(() => getUserById(0)).toThrow(ValidationError);
  });

  // Boundary
  test('handles maximum valid ID', () => {
    const user = getUserById(Number.MAX_SAFE_INTEGER - 1);
    expect(user).toBeDefined();
  });

  // State
  test('returns same user object on repeated calls (identity)', () => {
    const user1 = getUserById(1);
    const user2 = getUserById(1);
    expect(user1).toBe(user2); // Same reference
  });

  // Concurrency (if applicable)
  test('handles concurrent requests safely', async () => {
    const promises = [1, 2, 3].map(id => Promise.resolve(getUserById(id)));
    const users = await Promise.all(promises);
    expect(users).toHaveLength(3);
  });
});
```

**Prompt for Better Unit Test Generation:**

```
Generate comprehensive unit tests for the function:
${functionCode}

Requirements:
1. Include happy path, edge cases, and error conditions
2. Test boundary values: null, undefined, empty strings, 0, negative numbers
3. Test error types thrown (don't just expect throw, check the message)
4. Mock external dependencies (database, API calls)
5. Verify state didn't change unexpectedly
6. If async, test timeout and race conditions
7. For each test, include a comment explaining what edge case it covers
8. Use descriptive test names that explain the scenario

Use Jest syntax and include setup/teardown where needed.
```

### Integration Testing (AI Struggles)

**The Problem:** Integration tests require understanding multi-component interactions, service boundaries, and data flow across modules. AI loses context on these dependencies and often generates tests that pass in isolation but fail when integrated.

**What AI Gets Wrong:**
- Assumes services are available or mocked when they're not
- Missing request/response validation
- Incorrect setup of dependent services
- Race conditions between services
- Data consistency across service boundaries

**Strategy: Contract Testing + Human-Guided Integration Tests**

Instead of asking AI to write full integration tests, use a hybrid approach:

1. **Use Contract Testing (Pact, Spring Cloud Contract, Specmatic)** — Verify API contracts between services. This is where AI excels because contracts are explicit.

```javascript
// Contract test: AI can generate these
describe('User Service API Contract', () => {
  test('GET /users/:id returns valid user', () => {
    const response = getUserById(1);
    expect(response).toMatchObject({
      id: expect.any(Number),
      name: expect.any(String),
      email: expect.any(String),
    });
  });

  test('POST /users returns 201 with Location header', () => {
    const response = createUser({ name: 'Bob', email: 'bob@example.com' });
    expect(response.status).toBe(201);
    expect(response.headers.location).toMatch(/\/users\/\d+/);
  });
});
```

2. **Hand-Write Integration Tests for Critical Paths** — These test real service interactions, database state changes, and cross-service orchestration.

```javascript
// Integration test: Human-written, uses real services
describe('User Registration Flow', () => {
  beforeAll(async () => {
    // Real database setup
    await db.connect();
    await db.seed('users', []);
  });

  afterEach(async () => {
    await db.clear('users');
  });

  test('complete registration flow: create user → send email → verify email', async () => {
    // Call real endpoint
    const createRes = await request(app)
      .post('/users')
      .send({ email: 'alice@example.com', password: 'secure123' });

    expect(createRes.status).toBe(201);
    const userId = createRes.body.id;

    // Verify email was queued (check mock email service)
    expect(emailService.send).toHaveBeenCalledWith({
      to: 'alice@example.com',
      template: 'verify-email',
    });

    // Verify email token created in database
    const token = await db.query('SELECT token FROM email_tokens WHERE user_id = ?', userId);
    expect(token).toBeDefined();

    // Complete email verification
    const verifyRes = await request(app)
      .post('/email-verify')
      .send({ token: token });

    expect(verifyRes.status).toBe(200);

    // Verify user email marked as verified in database
    const user = await db.query('SELECT * FROM users WHERE id = ?', userId);
    expect(user.email_verified).toBe(true);
  });

  test('fails if email already registered', async () => {
    await db.insert('users', { email: 'alice@example.com' });

    const res = await request(app)
      .post('/users')
      .send({ email: 'alice@example.com', password: 'secure123' });

    expect(res.status).toBe(409);
    expect(res.body.error).toMatch(/already registered/i);
  });
});
```

3. **Use AI to Generate Setup/Teardown** — AI is good at boilerplate test infrastructure:

```javascript
// Prompt AI for test setup
Generate test setup and teardown for integration tests using:
- Jest test framework
- MongoDB test database (mongoMemoryServer)
- Mock email service
- Mock payment gateway

Requirements:
- Setup: Start test DB, clear collections, seed initial data
- Teardown: Clear collections, disconnect DB
- Mocks: Configure jest.mock() for external services
- Utilities: Helper functions to create test users, orders, etc.
```

### End-to-End (E2E) Testing with Playwright

**AI's Role in E2E:**
- ✅ Bootstrap test code from user flows (Playwright Codegen)
- ✅ Generate assertions and locator patterns
- ❌ Handle flaky tests and retries
- ❌ Understand complex UI state transitions

**Strategy: Use Playwright MCP for AI-Assisted E2E**

Playwright now integrates with MCP (Model Context Protocol), enabling AI agents to:
1. Observe the browser in real-time
2. Generate selectors and assertions
3. Self-heal broken tests when UI changes
4. Adjust steps based on actual UI state

**Example: Claude Code + Playwright MCP for E2E Testing**

```bash
# In CLAUDE.md, configure Playwright MCP:
Browser Integration: Use Playwright MCP to test web UI
- Before each test, take browser screenshot
- Use screenshot to generate reliable selectors
- For flaky waits, use browser.waitForNavigation()
- On assertion failure, capture trace and screenshot for debugging
```

```typescript
// Example E2E test (AI + human collaboration)
import { test, expect, Page } from '@playwright/test';

test.describe('User Registration E2E', () => {
  let page: Page;

  test.beforeEach(async ({ browser }) => {
    page = await browser.newPage();
    await page.goto('http://localhost:3000/signup');
  });

  test('user can register and verify email', async () => {
    // AI suggests selectors, human verifies they're correct
    await page.fill('[data-testid="email-input"]', 'alice@example.com');
    await page.fill('[data-testid="password-input"]', 'SecurePass123!');
    await page.click('[data-testid="submit-button"]');

    // Wait for success message (AI suggests wait, human adjusts timeout)
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible({ timeout: 5000 });

    // Verify email received (integration with mock email API)
    const mailResponse = await page.request.get('http://localhost:3000/test/emails');
    const emails = await mailResponse.json();
    const verifyEmail = emails.find(e => e.to === 'alice@example.com');
    expect(verifyEmail).toBeDefined();

    // Extract token from email and complete verification
    const tokenMatch = verifyEmail.body.match(/token=([a-f0-9]+)/);
    const token = tokenMatch[1];

    await page.goto(`http://localhost:3000/verify?token=${token}`);
    await expect(page.locator('[data-testid="verified-badge"]')).toBeVisible();
  });
});
```

**Playwright Best Practices for AI-Generated E2E:**

1. **Always use data-testid selectors** — More stable than CSS/XPath. AI should generate tests using these.
2. **Capture full traces on failure** — `npx playwright show-trace trace.zip` helps debug flaky tests.
3. **Use self-healing** — Playwright can auto-fix broken locators; enable this for tests generated by AI.
4. **Separate smoke tests (run every build) from regression tests (run nightly).** AI should generate smoke tests; humans curate regression suite.

### Property-Based Testing (Catches Edge Cases AI Misses)

**The Insight:** Instead of writing test cases, write properties (invariants) that should always be true. The testing framework generates thousands of random inputs and verifies the property holds.

**Example: Property-Based Testing with Hypothesis (Python)**

```python
from hypothesis import given, strategies as st

# Property: sorting a list should not change the number of elements
@given(st.lists(st.integers()))
def test_sort_preserves_length(numbers):
    assert len(sorted(numbers)) == len(numbers)

# Property: every element in the sorted list should be <= the next
@given(st.lists(st.integers()))
def test_sort_is_ordered(numbers):
    sorted_nums = sorted(numbers)
    for i in range(len(sorted_nums) - 1):
        assert sorted_nums[i] <= sorted_nums[i+1]

# Property: sorting should be idempotent (sorting twice = sorting once)
@given(st.lists(st.integers()))
def test_sort_idempotent(numbers):
    assert sorted(sorted(numbers)) == sorted(numbers)
```

**Why This Works for AI Code:** AI can generate the implementation but often misses edge cases. Property-based testing automatically finds the edges by trying thousands of combinations.

**Mutation Testing: Test Your Tests**

The best test suite has 100% coverage but 4% mutation score (executes every line but catches 4% of bugs). Mutation testing fixes this by:

1. Mutating the code (changing operators, removing lines)
2. Running tests to see if they catch the mutation
3. Reporting mutation score (% of mutations killed)

AI-generated tests often have high coverage but low mutation scores because they don't deeply verify behavior.

```bash
# Run mutation testing with Stryker (JavaScript)
npx stryker run

# Result:
# Killed: 847 / 1045 (81%) ← Good mutation score
# Survived: 198        ← These mutations weren't caught; tests are weak
# Timeout: 0

# For low mutation scores, prompt AI:
"These mutations survived in this code:
${survivedMutations}

Write additional tests to catch these edge cases. Focus on:
- Boundary conditions
- Off-by-one errors
- Return values (not just side effects)
"
```

**Integration:** Use mutation testing feedback to iteratively improve AI-generated tests:

```bash
1. Generate tests with AI
2. Run mutation testing
3. If mutation score < 85%, feed survived mutations back to AI
4. AI generates additional tests
5. Repeat until mutation score acceptable
```

---

## 4. Security Testing for AI Code

### AI Code Security Vulnerabilities (OWASP Top 10 for Agentic AI)

AI-generated code has **45% security flaws** and is the cause of **one in five breaches**. The vulnerabilities fall into predictable patterns:

| Vulnerability | How AI Fails | Impact | Example |
|---|---|---|---|
| **Missing Input Validation** | Assumes input is safe; doesn't add checks | SQL injection, XSS, DoS | `db.query('SELECT * FROM users WHERE id = ' + userId)` |
| **Hardcoded Secrets** | Puts API keys, passwords in code | Credential theft | `const apiKey = 'sk-12345...'` in production code |
| **Improper Auth** | Skips permission checks | Insecure direct object reference (IDOR) | Returns user data without verifying requester owns it |
| **Insecure Deserialization** | **2.74x more common in AI code** | Remote code execution | `JSON.parse(userInput)` without validation |
| **XSS Vulnerabilities** | **1.82x more common** | Session hijacking, data theft | `innerHTML = userInput` without escaping |
| **SQL Injection** | Missing parameterization | Database breach | Concatenated SQL queries |
| **Missing Exception Handling** | Exposes stack traces | Information disclosure | Unhandled exceptions return full error details |
| **Weak Password Hashing** | Uses plain text or weak algorithms | Credential compromise | `const hashed = sha1(password)` |
| **No Path Validation** | Missing directory traversal checks | Arbitrary file access | `readFile(userProvidedPath)` |
| **Resource Exhaustion** | Missing rate limits | DoS | No limits on API calls or resource usage |

### Security Testing Strategy (Defense in Depth)

**Layer 1: Static Analysis (SAST) — Automated**

Run security linters in CI/CD before human review. These catch ~60% of security issues.

**Tools:**
- **Semgrep** (multi-language, AI-powered triage) — Best for finding logic-level security bugs
- **Bandit** (Python-specific) — Fast, finds credential leaks
- **SonarQube** (enterprise) — Cross-file dataflow analysis
- **ESLint with security plugins** (JavaScript) — Format-level issues

**Setup Example (GitHub Actions):**

```yaml
name: Security Scan

on: [pull_request]

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Semgrep
        run: |
          pip install semgrep
          semgrep --config=p/security-audit \
                  --json \
                  --output=semgrep-results.json
      - name: Block PR if critical issues found
        run: |
          critical_count=$(jq '[.results[] | select(.extra.severity=="CRITICAL")] | length' semgrep-results.json)
          if [ "$critical_count" -gt 0 ]; then
            echo "Found $critical_count critical security issues. PR blocked."
            exit 1
          fi
```

**Semgrep Rules for AI-Generated Code:**

```yaml
# ~/.semgrep.yml: Focus on AI-specific vulnerabilities
rules:
  - id: hardcoded-secret
    patterns:
      - pattern: $PASSWORD = '...'
      - pattern: $KEY = '...'
    message: "Hardcoded secret detected. Use environment variables."
    severity: CRITICAL

  - id: missing-input-validation
    patterns:
      - pattern: db.query($SQL)
    message: "Direct SQL concatenation detected. Use parameterized queries."
    severity: CRITICAL

  - id: missing-auth-check
    patterns:
      - pattern: |
          function get$_($ID) {
            return db.find($ID);
          }
    message: "No permission check before returning user data. Add authorization."
    severity: CRITICAL

  - id: insecure-deserialization
    patterns:
      - pattern: JSON.parse($USER_INPUT)
    message: "Untrusted input deserialization. Validate schema first."
    severity: HIGH
```

**Layer 2: Input Validation Hooks — Enforce at Submission**

Use hooks to block code with missing input validation:

```bash
# .claude/hooks/pre-submit-security.sh
#!/bin/bash

# Check for common security gaps in generated code
ISSUES=0

# Check for hardcoded credentials
if grep -r "apiKey\|API_KEY\|password.*=" --include="*.js" --include="*.ts" | grep -v "process.env" | grep -v "config" | grep -v "test"; then
  echo "⚠️ Potential hardcoded credentials found"
  ISSUES=$((ISSUES + 1))
fi

# Check for missing input validation on database queries
if grep -r "db.query.*\$\|db.query.*\+\|db.query.*interpolate" --include="*.js" --include="*.ts"; then
  echo "⚠️ SQL injection risk: Non-parameterized queries detected"
  ISSUES=$((ISSUES + 1))
fi

# Check for innerHTML/dangerous HTML injection
if grep -r "innerHTML\|dangerouslySetInnerHTML" --include="*.js" --include="*.jsx" --include="*.tsx" | grep -v "textContent\|escapeHtml\|DOMPurify"; then
  echo "⚠️ XSS risk: Unescaped HTML assignment detected"
  ISSUES=$((ISSUES + 1))
fi

exit $ISSUES
```

**Layer 3: Automated Code Review — Logic-Level Issues**

SAST catches format/pattern issues; AI-powered code review catches logic-level security gaps.

**Tools:**
- **CodeRabbit** (46% accuracy on runtime bugs, fast GitHub integration)
- **Qodo** (agentic code review, architectural awareness, cross-repo context)
- **Sourcery** (logic-level issues, suggests fixes)

**CodeRabbit Configuration:**

```yaml
# .coderabbit.yaml
reviews:
  review_status: auto
  auto_review: true
  auto_review_percentage: 100

draft_comment: false

language:
  java:
    max_lines_of_change: 400
  python:
    max_lines_of_change: 400
  javascript:
    max_lines_of_change: 400

rules:
  - name: "Security: Missing Input Validation"
    enabled: true
    severity: "CRITICAL"
    files:
      - "*.js"
      - "*.ts"
      - "*.py"

  - name: "Security: Hardcoded Credentials"
    enabled: true
    severity: "CRITICAL"

  - name: "Logic: Null Pointer Exception Risk"
    enabled: true
    severity: "HIGH"

  - name: "Logic: Exception Handling"
    enabled: true
    severity: "MEDIUM"
```

**Layer 4: Dependency Scanning**

AI often uses outdated or malicious packages. Scan dependencies continuously.

```bash
# GitHub Actions: Dependency scanning
- name: Scan dependencies
  run: |
    npm audit --audit-level=moderate
    npm audit fix  # For non-breaking fixes only

- name: Check for vulnerable transitive deps
  run: |
    pip install safety
    safety check --json > safety-results.json
    if jq '.vulnerabilities | length' safety-results.json | grep -v "^0$"; then
      echo "Vulnerable dependencies found"
      exit 1
    fi
```

**Layer 5: Manual Security Review Checklist**

Humans catch what automation misses. Focus on:

```markdown
## Security Review Checklist for AI-Generated Code

- [ ] **Authentication**: Is user identity verified before operations?
- [ ] **Authorization**: Does code check user has permission to access data?
- [ ] **Input Validation**: All user inputs validated for type, length, format?
- [ ] **Output Encoding**: User data escaped before output (HTML, SQL, shell)?
- [ ] **Secrets**: No hardcoded API keys, passwords, or tokens?
- [ ] **Cryptography**: Using secure algorithms (bcrypt, not md5/sha1)?
- [ ] **Error Handling**: Errors don't expose sensitive info (stack traces)?
- [ ] **Dependencies**: All imports reviewed; versions pinned; no known vulns?
- [ ] **Data Storage**: Sensitive data encrypted at rest and in transit?
- [ ] **Logging**: Logs don't contain sensitive data (passwords, tokens)?
- [ ] **Access Control**: File/directory access restricted to needed scope?
- [ ] **Rate Limiting**: APIs have rate limits to prevent abuse?
- [ ] **CORS/CSRF**: Proper cross-origin and CSRF protections?
```

### Security Testing Workflow (Complete)

```bash
1. AI generates code (with test-first requirement)
2. SAST scans (Semgrep, Bandit) — automatic, blocks on CRITICAL
3. Dependency scan (npm audit, safety) — automatic, blocks on HIGH
4. AI code review (CodeRabbit) — automatic, suggests fixes
5. Manual security review — human, 15 min per feature, checklist-driven
6. Integration test with security focus (auth, perms, input validation)
7. Merge only if: tests pass + SAST clean + review approved
8. Monitor production (security events, anomalies, failed auth attempts)
```

---

## 5. AI-Assisted Test Generation

### Strengths: Where AI Excels at Testing

**AI Generates Good Tests For:**
- Happy path scenarios (the normal case)
- Boilerplate test scaffolding (setup, mocking, teardown)
- Test file structure and imports
- Mock configuration for external services
- Parameterized tests (same test with different inputs)
- Basic assertions

**Example: AI Generates Good Test Scaffolding**

```javascript
// Prompt: "Generate unit tests for this function"
describe('calculateDiscount', () => {
  let discountService;
  let userRepository;

  beforeEach(() => {
    discountService = new DiscountService();
    userRepository = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('applies percentage discount correctly', () => {
    const result = discountService.calculateDiscount(100, 10);
    expect(result).toBe(90);
  });

  test('returns original price when discount is 0', () => {
    const result = discountService.calculateDiscount(100, 0);
    expect(result).toBe(100);
  });

  // ... more tests
});
```

### Weaknesses: Where AI Fails

**AI Struggles With:**
- Edge cases (null, empty, boundary values) — often missing
- Error paths (exceptions, invalid states) — incomplete
- Security-focused tests (injection, XSS, auth bypass) — rare
- Performance tests (timeout, load, memory) — not generated
- Concurrency and race conditions — almost never
- Business logic validation (does this match requirements?) — misses nuances

### AI-Assisted Test Generation Workflow

**Best Practice: Hybrid Approach**

```bash
1. Write test outline in plain English (human)
2. AI generates starter tests from outline
3. Human adds edge cases and security tests
4. Run mutation testing to assess quality
5. If mutation score < 85%, iterate with AI
```

**Example: Iterative Test Improvement with AI**

```markdown
## Round 1: AI Generates Tests
Prompt: "Generate tests for getUserById(id)"

Result: Happy path tests only (42% mutation score)

## Round 2: Human Adds Edge Cases
Add tests manually:
- getUserById(null)
- getUserById(undefined)
- getUserById(-1)
- getUserById(0)
- getUserById(999999)

Mutation score: 68%

## Round 3: AI Generates Security Tests
Prompt: "These mutations survived. Add tests to catch:
- Return value mutations (verify exact properties)
- Boundary off-by-one errors (id vs id-1)
- Missing null checks (should throw, not return)"

Result: Additional security and boundary tests
Mutation score: 92%
```

### Self-Healing Tests (AI-Maintained Tests)

**The Problem:** Tests break when UI or API changes. Maintaining tests is tedious.

**The Solution:** AI self-heals tests when they break.

**Tools:**
- **Playwright's self-healing** (auto-fixes broken selectors)
- **Applitools Autonomous** (visual regression, auto-fixes screenshots)
- **mabl** (intelligent assertions, self-corrects)

**Example: Playwright Self-Healing**

```typescript
// Playwright can auto-fix broken selectors
test('user can log in', async ({ page }) => {
  // If selector changes, Playwright suggests fix
  await page.locator('[data-testid="username"]').fill('alice@example.com');

  // On failure, Playwright can regenerate selector automatically
  await page.locator('button:has-text("Log In")').click();

  // Assertion with fallback
  await expect(page.locator('[data-testid="dashboard"]')).toBeVisible();
});
```

**Enable Auto-Healing in CI/CD:**

```bash
# npx playwright codegen --auto-healing
# Generates tests with built-in selector resilience
```

### Metrics: Test Quality Assessment

Don't measure just coverage. Measure:

| Metric | What It Means | AI-Generated Baseline | Target |
|--------|--------------|----------------------|--------|
| **Line Coverage** | % of code executed | 85% | 90%+ |
| **Branch Coverage** | % of conditional paths | 72% | 85%+ |
| **Mutation Score** | % of mutations killed | 58% | 85%+ |
| **Test Pass Rate** | % tests passing | 97% | 99%+ |
| **Defect Escape Rate** | Bugs found in prod / bugs in testing | 15% | <5% |

---

## 6. The Verification Workflow

### The "Explain-It Test"

The most effective verification technique is asking AI (or the developer) to explain the code's correctness:

```markdown
## Explain-It Test

1. Ask AI: "Explain this code and why it's correct"
2. Look for:
   - Does explanation mention edge cases?
   - Does it address error conditions?
   - Does it verify security properties?
   - Are there unstated assumptions?
3. If explanation is incomplete, code likely is too

Example:
Code: `return users.find(u => u.id === id)`
AI's Explanation: "Returns the user with matching ID"
Problem: Doesn't explain what happens if no user found (returns undefined, not null)

Better Code:
```typescript
const user = users.find(u => u.id === id);
if (!user) throw new UserNotFound(`User ID ${id} not found`);
return user;
```
```

### Read Every Line (Catches 60% of Bugs Automated Tools Miss)

Automated tools (linters, tests) catch ~40% of bugs. Human review catches 60%.

**Reading Strategy:**

1. **First Pass: Skim for obvious issues**
   - Missing null checks
   - Empty catch blocks
   - Hardcoded values
   - Commented-out code

2. **Second Pass: Trace execution**
   - Follow the happy path end-to-end
   - Ask: "What happens if input is null?"
   - Ask: "What happens if external service fails?"
   - Ask: "What happens with concurrent requests?"

3. **Third Pass: Compare to architecture**
   - Does this follow team patterns?
   - Is business logic in the right layer?
   - Are dependencies injected correctly?
   - Does it match similar code in the codebase?

**Example: Reading AI-Generated Code**

```typescript
// Generated code:
async function processPayment(userId: string, amount: number) {
  const user = await db.users.findById(userId);
  const payment = await stripe.charges.create({
    amount: amount * 100,
    currency: 'usd',
    customer: user.stripeId,
  });
  await db.payments.insert(payment);
  return payment;
}

// Reading checkpoints:
// ❌ Line 2: What if user not found? (undefined access)
// ❌ Line 3: What if amount is negative, decimal, or 0?
// ❌ Line 3: What if stripe API fails? (no retry, no logging)
// ❌ Line 6: What if DB insert fails after stripe charged? (transaction)
// ❌ Overall: No logging, no error handling, no rate limiting

// Fixed version (human-guided):
async function processPayment(userId: string, amount: number) {
  // Validate input
  if (!userId) throw new Error('userId required');
  if (amount <= 0 || !Number.isInteger(amount)) {
    throw new Error('amount must be positive integer in cents');
  }

  // Get user
  const user = await db.users.findById(userId);
  if (!user) throw new UserNotFound(`User ${userId} not found`);
  if (!user.stripeId) throw new Error('User has no Stripe account');

  // Create payment with error handling
  let payment;
  try {
    payment = await stripe.charges.create({
      amount,
      currency: 'usd',
      customer: user.stripeId,
    });
  } catch (error) {
    logger.error('Stripe charge failed', { userId, amount, error });
    throw new PaymentError(`Stripe charge failed: ${error.message}`);
  }

  // Record payment (with transaction safety)
  try {
    await db.payments.insert({
      ...payment,
      userId,
      stripeId: payment.id,
    });
  } catch (error) {
    logger.error('DB insert failed after stripe charge', { payment, userId });
    // Attempt refund
    await stripe.refunds.create({ charge: payment.id });
    throw new Error('Payment recorded but database failed; refund issued');
  }

  logger.info('Payment processed', { userId, amount, stripeId: payment.id });
  return payment;
}
```

### Test Boundary Conditions Manually

Automated tests miss ~60% of edge cases. Test manually:

```javascript
// Test these manually with the actual code:
getUserById(null)          // Should throw, not crash
getUserById(undefined)     // Should throw
getUserById(-1)            // Should throw (negative ID)
getUserById(0)             // Should throw (invalid)
getUserById(999999)        // Should return null/error, not crash
getUserById('')            // Should throw
getUserById('abc')         // Should throw (wrong type)
getUserById(1.5)           // Should throw (float, not int)
getUserById(Number.MAX_SAFE_INTEGER) // Should work or throw gracefully

// Concurrent calls
Promise.all([
  getUserById(1),
  getUserById(1),
  getUserById(1),
])  // Should not have race conditions

// State changes
user1 = getUserById(1)
await deleteUser(1)
user2 = getUserById(1)  // Should be null/error, not cached
```

### Verify Architecture Conformance

Does the AI-generated code follow your system's patterns?

```markdown
## Architecture Review Checklist

- [ ] **Layers**: Does business logic stay in services (not controllers)?
- [ ] **Dependencies**: Are external services injected (not hardcoded)?
- [ ] **Error Handling**: Does it use team's custom error classes?
- [ ] **Logging**: Does it use team's logger (not console.log)?
- [ ] **Database**: Uses ORM/query builder (not raw SQL)?
- [ ] **Async**: Uses async/await (not callbacks)?
- [ ] **Testing**: Has corresponding test file?
- [ ] **Naming**: Follows team conventions?
- [ ] **No Duplication**: Uses existing utilities/helpers?
- [ ] **Comments**: Only for "why", not "what"?
```

---

## 7. Code Review for AI Code

### Why Code Review is Different for AI

**Human code review** assumes the author understood the requirements and implementation. **AI code review** must verify the agent didn't hallucinate, missed edge cases, or introduced security gaps.

**Key Difference:**
- Human code review: "Did you implement this correctly?"
- AI code review: "Is this correct according to the spec, edge cases, and architecture?"

### Multi-Model Code Review (The New Standard)

Instead of one reviewer, use multiple AI models:

```bash
1. Claude reviews for logic/architecture/security
2. GPT-4 reviews for edge cases/test coverage
3. DeepSeek reviews for performance/complexity
4. Human reviewer focuses on requirements/tradeoffs

If all agree → likely correct
If models disagree → probably needs investigation
```

**Tool Configuration:**

```bash
# .github/workflows/ai-code-review.yml
name: Multi-Model Code Review

on: [pull_request]

jobs:
  claude_review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Claude Code Review (via API)
        run: |
          gh api repos/{owner}/{repo}/pulls/{number}/reviews \
            -X POST \
            -f body="@claude-review.md" \
            -f event="COMMENT"

  gpt4_review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: GPT-4 Code Review (via OpenAI API)
        run: |
          # Use OpenAI API to review, post results
```

### Adversarial Code Review Pattern

Ask a second AI model to find bugs in the first:

```bash
Prompt to Claude:
"Review this code for bugs, security issues, and edge cases:
${generatedCode}

Format: List 5-10 specific issues or 'No issues found'."

Prompt to GPT-4:
"Here's a code review from another AI model. Verify the issues are correct:
${claudeReview}

Format: Confirm/refute each issue; add any missed issues."
```

**Tools Implementing This:**
- **CodeRabbit** (46% accuracy on runtime bugs, fast)
- **Qodo** (agentic review with architectural awareness)
- **Anthropic Code Review** (launched March 2026, specialized for AI-generated code)

### What Humans Should Focus On

Automation handles: syntax, patterns, obvious bugs, edge cases.

**Humans focus on:**
- **Requirements alignment**: Does the code solve the stated problem?
- **Tradeoffs**: Is this the right approach (vs. alternatives)?
- **System design**: Does this fit the architecture?
- **Business logic**: Does this match domain rules?
- **Performance implications**: Will this scale?
- **Maintainability**: Will future developers understand this?
- **Team standards**: Does this follow conventions?

### Code Review Checklist for AI Code

```markdown
## AI Code Review Checklist (10-15 minutes per PR)

### Correctness
- [ ] Code solves the stated problem
- [ ] Handles all input types (null, empty, boundary values)
- [ ] Exception paths handled (not just happy path)
- [ ] Concurrency safe (if applicable)
- [ ] Idempotent (calling twice = calling once, if applicable)

### Security
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] Authorization checks in place
- [ ] Escaping/parameterization for SQL/HTML/etc.
- [ ] No insecure deserialization

### Architecture
- [ ] Follows team patterns
- [ ] Dependencies injected
- [ ] Business logic in correct layer
- [ ] No duplication (reuses existing utilities)
- [ ] Properly integrated with codebase

### Testing
- [ ] Tests exist and pass
- [ ] Tests cover happy path + edge cases + errors
- [ ] Tests are readable and maintainable

### Performance
- [ ] No N+1 queries
- [ ] No unnecessary loops or recursion
- [ ] Appropriate caching (if needed)
- [ ] Resource cleanup (file handles, DB connections)

### Maintainability
- [ ] Code is readable (clear naming, no clever tricks)
- [ ] Comments explain "why", not "what"
- [ ] No technical debt introduced
- [ ] Error messages are helpful

### Red Flags (automatic block)
- [ ] Hardcoded credentials
- [ ] SQL injection vulnerability
- [ ] Missing null checks on critical paths
- [ ] Unhandled exceptions
- [ ] Commented-out code
```

---

## 8. Tool-Specific Testing Patterns

### Claude Code Testing Workflow

**Hooks for Automatic Testing:**

```bash
# .claude/hooks/on-file-create.sh
#!/bin/bash
# When AI creates a new .test.ts or .spec.ts file, run tests immediately

if [[ "$FILE" == *.test.ts ]] || [[ "$FILE" == *.spec.ts ]]; then
  echo "Running tests for $FILE..."
  npm test -- "$FILE"
  exit $?  # Exit with test result
fi
```

**TDD Workflow in Claude Code:**

```bash
# CLAUDE.md configuration
Workflow: Test-First (TDD)
1. Write tests before implementation
2. Verify tests fail initially (red phase)
3. Implement code to pass tests
4. Run linters and security scans
5. Refactor while keeping tests passing

Command Flow:
- Always run `npm test` after implementation
- Run `npm run lint` to check code style
- Run `npm run security` to scan for vulnerabilities
- Only commit when: tests pass + lints pass + security passes
```

**Claude Code Plan Mode for Testing:**

```bash
# In Claude Code, use Plan Mode to outline test strategy:
Ctrl+Shift+P → Select "Plan Mode"

Prompt:
"I need to implement a payment processor. Before writing code:
1. What edge cases should tests cover?
2. What security properties must be verified?
3. What integration points need mocking?
4. What's the test structure (unit → integration → e2e)?

Format as a test plan I can review before you write tests."
```

### Cursor Testing Patterns

**Background Agents for Continuous Testing:**

```bash
# Cursor will automatically run tests in the background as you code
# Configure in .cursor/rules.mdc:

[Test Runner]
Run tests automatically on file save
Show test results in editor gutter
Auto-fix failing tests with AI assistance
```

**Composer for Multi-File Test Updates:**

```bash
# Use Cmd+Shift+I (Composer) to generate/update tests for multiple files
# Composer understands dependencies and updates tests together

Steps:
1. Open Composer (Cmd+Shift+I)
2. Select files to test
3. Type: "Generate tests for these files, ensuring they pass together"
4. Composer generates tests and runs them
```

**@test-generator Mentions:**

```bash
# Use @test-generator in chat to focus on test generation
# Cursor has specialized context for testing

Prompt: "@test-generator Generate edge case tests for getUserById"
# Cursor focuses on test patterns, edge cases, mocking
```

### GitHub Actions CI/CD Pipeline

**Complete Testing Pipeline:**

```yaml
name: AI Code Quality Gate

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      # Phase 1: Unit tests (must pass)
      - name: Run unit tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          fail_ci_if_error: true
          minimum-coverage: 85

      # Phase 2: Security scanning
      - name: Run Semgrep SAST
        run: |
          pip install semgrep
          semgrep --config=p/security-audit --json --output=semgrep.json .

      - name: Check for critical security issues
        run: |
          critical=$(jq '[.results[] | select(.extra.severity=="CRITICAL")] | length' semgrep.json)
          if [ "$critical" -gt 0 ]; then exit 1; fi

      # Phase 3: Linting & type checking
      - name: Lint code
        run: npm run lint

      - name: Type check
        run: npm run type-check

      # Phase 4: Integration tests (if exist)
      - name: Run integration tests
        run: npm run test:integration --if-present
        timeout-minutes: 10

      # Phase 5: E2E tests (nightly, not on every PR)
      - name: Run E2E tests
        if: github.event_name == 'schedule'
        run: npm run test:e2e
        timeout-minutes: 30

      # Phase 6: AI code review
      - name: CodeRabbit review
        if: always()
        run: |
          gh pr comment ${{ github.event.pull_request.number }} \
            --body "Running CodeRabbit review..."

  mutation_testing:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - name: Install dependencies
        run: npm ci

      - name: Run mutation tests
        run: |
          npm install --save-dev @stryker-mutator/core
          npx stryker run

      - name: Check mutation score
        run: |
          score=$(jq '.stats.mutationScore' stryker/report.json)
          if (( $(echo "$score < 85" | bc -l) )); then
            echo "Mutation score $score% below 85% threshold"
            exit 1
          fi

  dependency_check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3

      - name: Audit npm dependencies
        run: npm audit --audit-level=moderate

      - name: Check for vulnerable Python packages
        run: |
          pip install safety
          safety check --json || true
```

---

## 9. CI/CD Integration & Hooks

### Git Hooks for Automatic Testing

**Husky + Lint-staged for Pre-Commit Testing:**

```bash
# npm install husky lint-staged --save-dev
# npx husky install

# .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npx lint-staged

# .husky/pre-push
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "Running tests before push..."
npm test
if [ $? -ne 0 ]; then
  echo "Tests failed. Push aborted."
  exit 1
fi

npm run build
if [ $? -ne 0 ]; then
  echo "Build failed. Push aborted."
  exit 1
fi
```

**Package.json Configuration:**

```json
{
  "lint-staged": {
    "*.{js,ts}": [
      "eslint --fix",
      "prettier --write",
      "jest --bail --findRelatedTests"
    ],
    "*.{py}": [
      "black",
      "flake8",
      "mypy",
      "pytest --bail"
    ]
  },
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint .",
    "type-check": "tsc --noEmit",
    "security": "semgrep --config=p/security-audit ."
  }
}
```

### Claude Code Hooks for Testing

**Post-Implementation Hook (Automatic):**

```bash
# .claude/hooks/post-file-modify.sh
# Runs after Claude modifies code; ensures tests pass before commit consideration

#!/bin/bash

if [[ "$FILE" == *.ts ]] || [[ "$FILE" == *.js ]]; then
  echo "Testing changes to $FILE..."

  # Run related tests
  npm test -- "$FILE" --bail
  TEST_EXIT=$?

  # Run linter
  npm run lint -- "$FILE"
  LINT_EXIT=$?

  # Run security scan
  semgrep --config=p/security-audit "$FILE" --json
  SEC_EXIT=$?

  # Exit non-zero if any check failed
  if [ $TEST_EXIT -ne 0 ] || [ $LINT_EXIT -ne 0 ] || [ $SEC_EXIT -ne 0 ]; then
    echo "⚠️ Code has issues; review before committing"
    exit 1
  fi

  echo "✅ All checks passed"
  exit 0
fi
```

**Pre-Submit Hook (Blocks Commit if Tests Fail):**

```bash
# .claude/hooks/pre-submit.sh
# Exit code 2 blocks submission; forces retry

#!/bin/bash

echo "Final quality gate before commit..."

# Test coverage must be >= 85%
coverage=$(npm run coverage:report 2>/dev/null | grep "Statements" | awk '{print $NF}' | sed 's/%//')
if [ -z "$coverage" ] || (( $(echo "$coverage < 85" | bc -l) )); then
  echo "❌ Coverage $coverage% < 85% threshold. Fix before commit."
  exit 2
fi

# Mutation score must be >= 85%
mutation=$(npm run mutation:score 2>/dev/null || echo "0")
if (( $(echo "$mutation < 85" | bc -l) )); then
  echo "❌ Mutation score $mutation% < 85%. Add more edge case tests."
  exit 2
fi

# SAST scan must be clean
semgrep --config=p/security-audit . --json | jq '.results | length' > /tmp/sast_count
sast_issues=$(cat /tmp/sast_count)
if [ "$sast_issues" -gt 0 ]; then
  echo "❌ Found $sast_issues security issues. Fix before commit."
  exit 2
fi

echo "✅ All quality gates passed. Ready to commit."
exit 0
```

---

## 10. Metrics & Monitoring

### Key Testing Metrics for AI Code

| Metric | Formula | Target | Meaning |
|--------|---------|--------|---------|
| **Test Coverage** | Lines executed / Total lines | 85%+ | Are we testing enough code? |
| **Mutation Score** | Mutations killed / Total mutations | 85%+ | Are tests actually verifying behavior? |
| **Defect Escape Rate** | Bugs in prod / (Bugs in testing + Bugs in prod) | <5% | How many bugs make it to production? |
| **Mean Time to Detect (MTTR)** | Time from deployment to bug detection | <1 hour | How quickly do we find bugs? |
| **Test Pass Rate** | Tests passing / Total tests | 99%+ | Are tests reliable? |
| **Code Review Cycle** | Time from PR to merge | <4 hours | Is review a bottleneck? |
| **Security Scan Issues** | CRITICAL + HIGH vulns / 1000 LOC | <1 | Are we shipping secure code? |

### Implementing Metrics in CI/CD

```bash
# .github/workflows/metrics.yml
name: Quality Metrics

on: [pull_request, push]

jobs:
  metrics:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Collect metrics
        run: |
          {
            echo "## Code Quality Metrics"
            echo ""

            # Coverage
            coverage=$(npm run coverage:report 2>/dev/null | grep "Statements" | awk '{print $NF}')
            echo "- Coverage: $coverage"

            # Mutation
            mutation=$(npm run mutation:score 2>/dev/null || echo "N/A")
            echo "- Mutation Score: $mutation"

            # Security issues
            issues=$(semgrep --config=p/security-audit . --json 2>/dev/null | jq '.results | length')
            echo "- Security Issues: $issues"

            # Test count
            tests=$(npm test -- --listTests 2>/dev/null | wc -l)
            echo "- Test Files: $tests"

          } > metrics.md

      - name: Post metrics to PR
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const metrics = fs.readFileSync('metrics.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: metrics
            });
```

### Dashboards & Monitoring

**GitHub Dashboard (Native):**

```bash
# Add this to README.md
## Code Quality
![Coverage Badge](https://img.shields.io/codecov/c/github/myorg/myrepo)
![Tests Badge](https://github.com/myorg/myrepo/workflows/Tests/badge.svg)
![Security Badge](https://img.shields.io/github/issues-search/myorg/myrepo?label=security%20issues&query=label%3Asecurity)
```

**DORA Metrics (for team level):**

Track these to assess overall quality impact:

| Metric | 2025 Benchmark | 2026 w/AI | Target |
|--------|---|---|---|
| Deployment Frequency | 1/week | 1/day | Daily |
| Lead Time for Changes | 7 days | 2 days | <1 day |
| Mean Time to Recovery | 4 hours | 1 hour | <30 min |
| Change Failure Rate | 25% | 12% | <5% |

---

## 11. Production Testing Checklist

### Pre-Deployment Verification (Must Pass)

```markdown
## Production Readiness Checklist for AI-Generated Code

### Testing
- [ ] Unit tests written and passing (100% for new code)
- [ ] Integration tests for service boundaries
- [ ] E2E tests for critical user journeys
- [ ] All tests run in CI/CD on every commit
- [ ] Mutation score >= 85%
- [ ] Test execution time < 10 minutes (not a bottleneck)

### Code Quality
- [ ] Linting passes (ESLint, Black, etc.)
- [ ] Type checking passes (TypeScript, mypy, etc.)
- [ ] Code review completed (human + automated)
- [ ] No TODOs or FIXMEs in critical paths
- [ ] Documentation updated (README, API docs, etc.)

### Security
- [ ] SAST scan clean (Semgrep, SonarQube)
- [ ] No hardcoded secrets or credentials
- [ ] Input validation present for all user inputs
- [ ] Authorization checks in place
- [ ] Dependency audit passed (no HIGH/CRITICAL vulns)
- [ ] Security checklist completed (see section 4)

### Performance
- [ ] Database queries optimized (no N+1)
- [ ] No memory leaks (profiled with heap snapshots)
- [ ] Load tested if user-facing
- [ ] Cache strategy in place if needed
- [ ] API response times within SLA

### Architecture
- [ ] Follows team patterns and conventions
- [ ] No duplication (reuses existing utilities)
- [ ] Dependencies are injectable
- [ ] Error handling consistent with codebase
- [ ] Logging includes relevant context

### Operations
- [ ] Error messages are helpful and logged
- [ ] Monitoring/alerting configured
- [ ] Deployment process tested (dry-run)
- [ ] Rollback plan documented
- [ ] Feature flags in place (if gradual rollout needed)

### Compliance
- [ ] Data privacy (GDPR, CCPA) verified
- [ ] Audit logging for sensitive operations
- [ ] Encryption for sensitive data (at rest, in transit)
- [ ] Third-party dependencies reviewed for compliance
```

### Deployment Strategy

**Staged Rollout (Reduces Risk):**

```bash
1. Internal Testing (1-2 days)
   - Run full test suite
   - Manual testing by QA
   - Security review

2. Canary Deployment (10% of traffic)
   - Monitor error rates, latency
   - Watch for security alerts
   - Collect metrics

3. Gradual Rollout (25% → 50% → 100%)
   - Monitor DORA metrics
   - Watch for production issues
   - Alert on anomalies

4. Full Production (100%)
   - Monitor for 1 week
   - Track defect escapes
   - Plan rollback if needed
```

**GitHub Actions Deployment:**

```yaml
name: Production Deployment

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm test
      - run: npm run security

  canary:
    needs: test
    runs-on: ubuntu-latest
    environment: production-canary
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to 10% of traffic
        run: |
          deployment_id=$(date +%s)
          kubectl set image deployment/api api=myapp:${{ github.sha }} \
            --rollout=slow \
            --traffic-split=10
          kubectl rollout status deployment/api --timeout=5m

  production:
    needs: canary
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to 100%
        run: |
          kubectl set image deployment/api api=myapp:${{ github.sha }} \
            --rollout=slow
          kubectl rollout status deployment/api --timeout=10m

      - name: Smoke test
        run: |
          curl -f https://api.example.com/health
          curl -f https://api.example.com/api/version
```

### Post-Deployment Monitoring

```bash
# Monitor these metrics for 24-48 hours after deployment
- Error rates (track by endpoint)
- Latency (p50, p95, p99)
- Failed authentication attempts
- Database connection pool usage
- Memory/CPU usage
- Deployment issues (rollback triggers)

# Alert if:
- Error rate > 1% for any endpoint
- Latency p95 > 2x baseline
- Failed auth > 10x baseline (possible attack)
- OOM kills or crash loops
```

---

## Tool Recommendations & Setup

### Essential Tools (Tier 1)

| Tool | Purpose | Cost | Setup Time |
|------|---------|------|------------|
| **Jest** (JS) / **pytest** (Python) | Unit testing | Free | <5 min |
| **Semgrep** | SAST scanning | Free tier | <10 min |
| **GitHub Actions** | CI/CD | Free tier | <15 min |
| **Playwright** | E2E testing | Free | <20 min |
| **CodeRabbit** | AI code review | $12/mo | <5 min |

### Recommended Tools (Tier 2)

| Tool | Purpose | Cost | When to Add |
|------|---------|------|---|
| **Mutation testing (Stryker)** | Test quality assessment | Free | After reaching 85% coverage |
| **Contract testing (Pact)** | API testing | Free | For microservices |
| **Qodo** | Agentic code review | $30/user/mo | For large teams (10+) |
| **SonarQube** | Enterprise SAST | $150/mo+ | For regulated industries |
| **Datadog** | Production monitoring | $500+/mo | For production deployment |

### Quick Setup: Testing Stack for AI Code

```bash
# 1. Unit testing (5 min)
npm install --save-dev jest @types/jest ts-jest
npx jest --init

# 2. Code quality (5 min)
npm install --save-dev eslint typescript @typescript-eslint/eslint-plugin
npx eslint --init

# 3. Security scanning (5 min)
pip install semgrep
semgrep --install-rules

# 4. E2E testing (10 min)
npm install --save-dev @playwright/test
npx playwright install

# 5. Git hooks (5 min)
npm install --save-dev husky lint-staged
npx husky install

# Total time: ~30 minutes to production-ready testing pipeline
```

---

## Conclusion

**AI-generated code requires testing strategies fundamentally different from human code.** The key differences:

1. **AI excels at happy paths, fails on edge cases** → Use property-based testing to auto-find edges
2. **AI looks correct but isn't** → Read every line, test boundary conditions manually
3. **Text rules fade; hooks enforce** → Use deterministic enforcement (hooks, not CLAUDE.md rules)
4. **TDD + AI produces 40-90% fewer defects** → Always write tests before implementation
5. **Security is overlooked** → Use SAST + AI code review + human security checklist
6. **Production bugs come from edge cases** → Mutation testing and integration testing are critical

**The winning formula:**

```
Test-First (TDD)
  + Comprehensive Testing (unit + integration + E2E)
  + Security Scanning (SAST + human review)
  + AI-Assisted Code Review (multi-model)
  + Continuous Monitoring (production metrics)
= Production-ready AI code
```

---

## Sources

### AI Code Quality & Testing
- [AI vs human code gen report: AI code creates 1.7x more issues](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report)
- [How to Test AI-Generated Code the Right Way in 2026](https://www.twocents.software/blog/how-to-test-ai-generated-code-the-right-way/)
- [AI-Generated Code Quality Metrics and Statistics for 2026](https://www.secondtalent.com/resources/ai-generated-code-quality-metrics-and-statistics-for-2026/)
- [Hidden Challenges of Testing AI-Generated Code](https://qualizeal.com/hidden-challenges-of-testing-ai-generated-code/)
- [Hidden Risks of AI-Generated Code & How to Catch Them](https://testkube.io/blog/testing-ai-generated-code)

### TDD + AI
- [Test-Driven Development with AI](https://www.builder.io/blog/test-driven-development-ai)
- [AI-Powered Test-Driven Development (TDD): Fundamentals & Best Practices 2025](https://www.nopaccelerate.com/test-driven-development-guide-2025/)
- [Better AI Driven Development with Test Driven Development](https://medium.com/effortless-programming/better-ai-driven-development-with-test-driven-development-d4849f67e339)
- [Why Does Test-Driven Development Work So Well In "AI"-assisted Programming?](https://codemanship.wordpress.com/2026/01/09/why-does-test-driven-development-work-so-well-in-ai-assisted-programming/)
- [AI Agents, meet Test Driven Development](https://www.latent.space/p/anita-tdd)

### Security Testing
- [OWASP Top 10 for LLM Applications 2025](https://owasp.org/www-project-top-10-for-large-language-model-applications/assets/PDF/OWASP-Top-10-for-LLMs-v2025.pdf)
- [OWASP Top 10 for Agentic AI Security Risks (2026)](https://www.startupdefense.io/blog/owasp-top-10-agentic-ai-security-risks-2026)
- [The AI Code Security Crisis of 2026: What Every CTO Needs to Know](https://www.growexx.com/blog/ai-code-security-crisis-2026-cto-guide/)
- [The New Era of Application Security: Reasoning-Based Agents, Runtime Reality, and Risk Intelligence](https://blog.qualys.com/product-tech/2026/03/17/new-era-application-security-reasoning-agents-runtime-risk-2026)

### Testing Strategies
- [AI Testing Platform | API, Unit & Integration Testing](https://www.usetusk.ai/)
- [Testing AI-Generated Code: Practical Strategies](https://www.sitepoint.com/testing-ai-generated-code/)
- [Software Testing Strategies: A Practical Guide for QA Teams in 2026](https://testcollab.com/blog/software-testing-strategies)
- [Integration Testing and Unit Testing in the Age of AI](https://www.aviator.co/blog/integration-testing-and-unit-testing-in-the-age-of-ai/)

### Mutation & Property-Based Testing
- [Toward automated verification of unreviewed AI-generated code](https://peterlavigne.com/writing/verifying-ai-generated-code)
- [Meta Applies Mutation Testing with LLM to Improve Compliance Coverage](https://www.infoq.com/news/2026/01/meta-llm-mutation-testing/)
- [The Death of Traditional Testing: Agentic Development Broke a 50-Year-Old Field](https://engineering.fb.com/2026/02/11/developer-tools/the-death-of-traditional-testing-agentic-development-jit-testing-revival/)

### Code Review & AI Review Tools
- [8 Best AI Code Review Tools That Catch Real Bugs in 2026](https://www.qodo.ai/blog/best-ai-code-review-tools-2026/)
- [CodeRabbit Review 2026: Fast AI Code Reviews](https://ucstrategies.com/news/coderabbit-review-2026-fast-ai-code-reviews-but-a-critical-gap-enterprises-cant-ignore/)
- [Best Automated Code Review Tools for Enterprises (2026)](https://www.qodo.ai/blog/best-automated-code-review-tools-2026/)
- [How CodeRabbit's agentic code validation helps with code reviews](https://www.coderabbit.ai/blog/how-coderabbits-agentic-code-validation-helps-with-code-reviews)
- [AI Code Review Guide - Spot Red Flags & Verify AI Output](https://techdebt.fast/ai-code-review/)

### Security Scanning Tools
- [Semgrep vs ESLint: Security-Focused SAST vs JavaScript Linter (2026)](https://dev.to/rahulxsingh/semgrep-vs-eslint-security-focused-sast-vs-javascript-linter-2026-hef)
- [Python Code Review Stack 2026: Linters, SAST, and AI Integration](https://earezki.com/ai-news/2026-03-12-best-code-review-tools-for-python-in-2026-linters-sast-and-ai/)
- [Semgrep Secure 2026: Code Security Rebuilt for the AI Era](https://semgrep.dev/events/semgrep-secure-2026-virtual-keynote/)

### Contract & API Testing
- [Ultimate Guide - The Best API Contract Testing Tools of 2026](https://www.testsprite.com/use-cases/en/the-top-api-contract-testing-tools)
- [The Case for Contract Testing: Cutting Through API Integration Complexity](https://pactflow.io/blog/ai-automation-part-1/)
- [API-First Development and Contract Testing: Modern Practices and Tools](https://dasroot.net/posts/2026/02/api-first-development-contract-testing/)

### E2E Testing & Playwright
- [Playwright E2E Testing: Step-by-Step Setup Guide 2026](https://testdino.com/blog/playwright-e2e-testing/)
- [The Complete Playwright End-to-End Story, Tools, AI, and Real-World Workflows](https://developer.microsoft.com/blog/the-complete-playwright-end-to-end-story-tools-ai-and-real-world-workflows/)
- [Write Playwright Tests with AI: 5 Methods That Work (2026)](https://testdino.com/blog/ai-write-playwright-tests/)
- [Playwright MCP Explained: AI-Powered Test Automation 2026](https://www.testleaf.com/blog/playwright-mcp-ai-test-automation-2026/)
- [AI Powered end to end (E2E)Testing with Playwright MCP and GitHub MCP](https://kailash-pathak.medium.com/ai-powered-e2e-testing-with-playwright-mcp-model-context-protocol-and-github-mcp-d5ead640e82c)

### AI Test Generation
- [12 AI Test Automation Tools QA Teams Actually Use in 2026](https://testguild.com/7-innovative-ai-test-automation-tools-future-third-wave/)
- [How AI is Transforming Test Case Generation in 2026](https://testquality.com/how-ai-is-transforming-test-case-generation-in-2026/)
- [Automated, High-Quality Unit Tests and Code Coverage for Your Pull Requests](https://www.startearly.ai/)
- [GitHub Copilot Testing for .NET Brings AI-powered Unit Tests to Visual Studio 2026](https://devblogs.microsoft.com/dotnet/github-copilot-testing-for-dotnet-available-in-visual-studio/)

### Production Testing & Verification
- [How to Verify Code Quality of AI Generated Code in Repos](https://blog.exceeds.ai/verify-ai-code-quality-repos/)
- [Code Review Checklist for AI-Generated Code](https://clacky.ai/blog/code-review-checklist-ai-generated-code)
- [Production readiness checklist: An in-depth guide](https://www.opslevel.com/resources/production-readiness-in-depth/)
- [5 Best Practices for Reviewing and Approving AI-Generated Code](https://brightsec.com/blog/5-best-practices-for-reviewing-and-approving-ai-generated-code/)
- [AI writes code: why human review is vital](https://www.undercoverlab.com/en/ai-writes-code-why-human-verification-vital/)

### CI/CD & Automation
- [AI Agents in CI/CD Pipelines for Continuous Quality](https://www.mabl.com/blog/ai-agents-cicd-pipelines-continuous-quality)
- [AI in CI/CD pipeline: Automate Testing and Deployment Smarter](https://www.hakunamatatatech.com/our-resources/blog/ai-in-software-development-driving-continuous-improvement)
- [How To Set Up CI/CD For React.js With AI Code Quality Checks In 2026](https://fullstacktechies.com/how-to-set-up-ci-cd-for-react-js/)
- [AI-Driven DevSecOps For Intelligent CI/CD Pipeline](https://www.aviator.co/blog/ai-driven-devsecops-building-intelligent-ci-cd-pipelines/)

---

## Related Topics

- [When Not to Use AI](when-not-to-use-ai.md) — Understanding testing requirements before relying on AI-generated code
- [Hooks Enforcement Patterns](hooks-enforcement-patterns.md) — Using git hooks to automatically validate AI-generated code quality
- [AI-Assisted Debugging](ai-assisted-debugging.md) — Debugging failures in AI-generated code with AI support
- [Evaluation Beyond LLM-as-Judge](evaluation-beyond-llm-judge.md) — Statistical rigor for sample sizes and evaluation methodology
- [Decision Trees](decision-trees.md) — When to use which testing/evaluation approach

---

## Changelog
| Date | Change | Source |
|------|--------|--------|
| 2026-03-20 | Added Stanford/MIT March 2026 study data: 14.3% of AI-generated code contains security vulnerabilities vs 9.1% for human-written code (57% higher rate, 2M+ snippets analyzed). Added Aikido finding: only 29% of organizations prepared to secure agentic AI deployments. These complement existing Veracode (45% flawed PRs) and CodeRabbit (1.7x issues) data points. | Daily briefing 2026-03-20 finding #5 |
| 2026-03-21 | Veracode 2026 report updates insecure AI code rate from 45% to 48%. Vulnerabilities now being created faster than fixed. | Daily briefing 03-21-2026 (Finding #1) |
