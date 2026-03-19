# Cursor IDE Power User Guide 2026

**Date:** 2026-03-18
**Status:** Current (March 2026 – Cursor 2.6)
**Audience:** Experienced developers seeking to maximize Cursor IDE workflows

---

## Quick Reference: Core Keyboard Shortcuts

| Action | Mac | Windows/Linux | When to Use |
|--------|-----|---------------|------------|
| Inline edit (surgical) | Cmd+K | Ctrl+K | Single line/block fix, preserve context |
| Chat panel | Cmd+L | Ctrl+L | Conversational questions, debugging |
| Composer (multi-file) | Cmd+I | Ctrl+I | Feature building, coordinated multi-file changes |
| Full Composer | Cmd+Shift+I | Ctrl+Shift+I | Large-scale refactoring, entire modules |
| Open settings | Cmd+, | Ctrl+, | Access models, API keys, preferences |
| View keyboard shortcuts | Cmd+R → Cmd+S | - | Discover all keybindings |

**Golden Rule:** Cmd+K for surgical fixes; Cmd+I for architectural work.

---

## 1. Cursor Core Workflow – When to Use Each Feature

### Cmd+K: Inline Editing (Surgical Changes)

**Purpose:** Modify code where your cursor sits, without broader context shifts.

**Workflow:**
1. Click or position cursor in the code block you want to change
2. Press Cmd+K
3. Type your instruction: "rename this variable to reflect its purpose" or "add error handling"
4. Preview the diff (appears inline)
5. Accept with Cmd+Enter or reject with Cmd+Backspace

**Best for:**
- Single-line fixes
- Renaming variables within a function
- Adding/removing imports
- Fixing linting errors
- Tests that verify specific behaviors

**Pro tip:** Cmd+K uses only local code context (the block you selected), so it's faster than full codebase reasoning. For 3-line fixes, Cmd+K beats Cmd+I by response time.

---

### Cmd+L: Chat Panel (Conversational)

**Purpose:** Ask questions, discuss design, debug issues with full codebase context.

**Workflow:**
1. Press Cmd+L to open the chat sidebar
2. Ask naturally: "Why is this function slow?" or "What patterns are we using for error handling?"
3. Reference code with `@file` (specific files), `@codebase` (semantic search), or `@Docs` (framework docs)
4. Read responses, iterate

**Best for:**
- Understanding codebase architecture
- Asking "why" questions
- Design discussions before coding
- Debugging complex issues
- Asking about best practices

**Pro tip:** Use `@codebase` to let Cursor find relevant files automatically. Don't manually @mention 20 files if only 3 matter—semantic search is faster and cleaner.

---

### Cmd+I: Composer (Multi-File Agent)

**Purpose:** Coordinate changes across multiple files. Cursor reasons about dependencies and applies diffs everywhere needed.

**Workflow:**
1. Press Cmd+I
2. Describe the change: "Refactor the billing module to use Stripe Elements instead of the old API"
3. Composer analyzes your codebase, identifies relevant files (automatically)
4. Shows a plan and a diff preview
5. Review the changes across all files
6. Click "Save" to apply all changes at once

**Capabilities:**
- Automatically identifies affected files
- Generates diffs across the entire change
- Handles imports, exports, and cross-file references
- Runs linting automatically; fixes lint errors if enabled
- Shows dependencies and risk in the plan

**When to use:**
- Adding a new feature spanning multiple files
- Refactoring: renaming a component, changing an API surface
- Dependency upgrades affecting multiple files
- Moving code between modules

**Multi-file example:**
```
Cmd+I → "Add a new middleware that logs all API requests. Update
the app router to use it, create the middleware file, and add tests."
```

Cursor will:
- Create `middleware/logging.ts`
- Update `routes/app.ts` to import and apply the middleware
- Update `types/middleware.ts` if needed
- Create `tests/middleware.test.ts`

All in one operation.

---

### Tab Completion (Passive Assistance)

**What it does:** As you type, Cursor suggests multi-line completions based on context.

**Characteristics:**
- ~320ms response time (speculative decoding)
- Predicts not just the next token, but full blocks
- Understands that if you rename a function parameter, all uses should update
- Triggered automatically as you code

**When it shines:**
- Boilerplate: writing test files, component scaffolds
- Repeating patterns: if you've written one API endpoint, Tab completes the next
- Variable renaming: rename one instance; Tab suggests cascading changes

**Pro tip:** Tab completion is fastest for code patterns already in your codebase. If you have 5 similar functions, the 6th will auto-complete.

---

## 2. Background Agents & Autonomous Task Execution

Cursor 2.0 introduced autonomous agents that run without constant human intervention.

### Setup

**Enable background agents:**
1. Settings → General → Enable "Background Agents"
2. Cloud Agents (new in 2026): Can run on Cursor's infrastructure or locally
3. Set agent concurrency: Pro+ = 3 agents, Ultra = up to 8 agents

### Local Agents vs. Cloud Agents

| Feature | Local Agent | Cloud Agent |
|---------|-------------|------------|
| Runs on | Your machine | Cursor servers |
| Start from | Cursor IDE | Browser, phone, Slack |
| Network cost | Low | Higher |
| Control | Full (it's your machine) | Less (remote execution) |
| Best for | Background fixes, tests | Long-running tasks, CI/CD |

### Workflow: Using Background Agents

**Example: Auto-run tests in background**

1. Open Cmd+I (Composer)
2. Instruct: "Implement the user authentication feature using JWT tokens"
3. Instead of "Save," click "Run in Background"
4. Cursor spawns an agent that:
   - Generates code across all files
   - Runs your test suite
   - If tests fail, the agent tries to fix the code
   - Continues until tests pass or max iterations hit
5. You get a notification when done; review the merge-ready branch

**Example: Cursor Automations (always-on agents)**

```yaml
# .cursor/automations/test-on-commit.yaml
trigger: on-commit
agent:
  task: "Run the test suite and report failures"
  model: claude-sonnet-4.5

notification: email
```

Hundreds of automations run per hour in production systems. At scale, teams use agents for:
- Incident response (PagerDuty incident → agent queries logs via MCP)
- Code review automation
- Daily linting and formatting
- Detecting performance regressions

### Limitations

- Agents can't modify security settings or access credentials
- No access to system-level operations outside your codebase
- Max execution time varies by plan (Pro = 10 min, Ultra = 30 min)
- Agents ask clarifying questions if the task is ambiguous

---

## 3. Cursor Rules: The .cursorrules & .mdc Format

Cursor rules are persistent instructions that inject context into every AI request. They act as a system prompt for your entire project.

### Legacy Format: .cursorrules (deprecated but still works)

Create a file named `.cursorrules` in your project root:

```markdown
# Project Coding Standards

## Code Style
- Use TypeScript with strict mode enabled
- Prefer functional components with hooks in React
- Use async/await over .then() chains

## Architecture
- All API calls go through the `services/` directory
- Data fetching uses React Query (TanStack Query)
- No direct API calls in components

## Testing
- Every feature must have unit tests
- Use Vitest for unit tests, Playwright for e2e
- Minimum 80% code coverage required

## Git & Commits
- Branch naming: feature/*, bugfix/*, refactor/*
- Commits should be atomic and descriptive
- Include issue number in commit messages: "Fix #123: description"

## Security
- No API keys or secrets in code or .env files
- Use environment variables with VITE_PUBLIC_ prefix for public vars
- All user input must be validated and sanitized

## Performance
- Lazy load components over 50KB
- Use memoization for expensive computations
- Prefer CSS Grid over absolute positioning for layouts
```

### Modern Format: .mdc (2025-2026)

Create `.cursor/rules/` directory with individual .mdc files:

```
project/
├── .cursor/
│   ├── rules/
│   │   ├── code-style.mdc
│   │   ├── testing.mdc
│   │   └── security.mdc
│   └── index.mdc
```

**Example: code-style.mdc**

```markdown
---
description: "Enforce TypeScript strict mode and modern syntax patterns"
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: true
---

# TypeScript Code Style

## Configuration
- Always enable `strict: true` in tsconfig.json
- Use TypeScript 5.x or newer

## Patterns
- Prefer type over interface for new code
- Use discriminated unions for complex type hierarchies
- Avoid `any`; use `unknown` with type guards

## Error Handling
- Use custom error classes extending Error
- Include error context: `throw new ValidationError('Invalid email', { email })`

## Async Code
- Always use async/await; never mix with .then()
- Wrap async operations in try/catch
```

**Example: testing.mdc**

```markdown
---
description: "Testing standards for all packages"
globs: ["**/*.test.ts", "**/*.spec.ts"]
alwaysApply: false
---

# Testing Standards

## Unit Tests
- Test behavior, not implementation
- Use describe/test (Vitest syntax)
- Mock external dependencies (APIs, databases)

## Integration Tests
- Use real database in test containers
- Test full request → response cycle

## E2E Tests
- Playwright for browser automation
- Test user journeys, not UI details
```

### Applying Rules

1. **In Cursor IDE:** Create `.cursor/rules/*.mdc` files; Cursor auto-detects them
2. **In Claude Code:** Add Markdown file references in the UI or CLI
3. **Verify:** Cmd+Shift+P → "Show Project Rules" to see all active rules

### Rule Precedence

Cursor evaluates rules in this order:
1. Always-apply rules (`alwaysApply: true`) – run on every request
2. Glob-matched rules – only apply when editing files matching the glob
3. User-selected rules – only if explicitly activated

---

## 4. MCP (Model Context Protocol) in Cursor

MCPs extend Cursor's capabilities by connecting to external tools, APIs, and data sources. In March 2026, Cursor launched a plugin marketplace bundling MCPs with rules, skills, and hooks.

### Setup

**Option A: Cursor Marketplace (one-click)**

1. In Cursor: Cmd+Shift+P → "Add Plugin"
2. Browse or search the marketplace
3. Click "Install" – done. Plugins like Linear, Figma, Stripe, Amplitude install together with their MCPs

**Option B: Manual MCP Configuration**

Create `.cursor/mcp.json`:

```json
{
  "servers": {
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "stripe": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-stripe"],
      "env": {
        "STRIPE_API_KEY": "${STRIPE_SECRET_KEY}"
      }
    },
    "postgresql": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

Then set environment variables in `.env` (not in version control):

```bash
GITHUB_TOKEN=ghp_xxx...
STRIPE_SECRET_KEY=sk_test_xxx...
DATABASE_URL=postgresql://user:pass@localhost/dbname
```

### Popular MCPs & Use Cases

| MCP | Provider | Use Case | Released |
|-----|----------|----------|----------|
| GitHub | Anthropic | Query issues, PRs, repos | Built-in |
| PostgreSQL | Anthropic | Direct database queries from editor | 2025 |
| Stripe | Stripe | Query charges, customers, invoices | 2026-03 |
| Linear | Linear | View and manage tasks, tickets | 2026-03 |
| Figma | Figma | Reference design files, get color palettes | 2026-03 |
| Amplitude | Amplitude | Analyze user events, cohorts | 2026-03 |
| AWS | AWS | Query EC2, S3, CloudWatch | 2026-03 |
| Playwright | Anthropic | Run browser tests, generate screenshots | 2025 |

### MCP Apps (Interactive UIs)

New in Cursor 2.6: MCPs can return interactive UIs rendered directly in the agent chat:

```
Agent: "Based on Figma, the primary color is..."
       [Color swatch: #007AFF]

Agent: "Here's your Amplitude user cohort:"
       [Chart: Last 7 days signup trend]
```

These interactive UIs help agents reason about visual designs, analytics, and complex data.

### Example: Using Stripe MCP

**Scenario:** Build a billing dashboard that queries customer invoices.

```typescript
// In your agent chat:
// "Using the Stripe MCP, fetch all invoices for customer cus_xxx and list them by amount"

// Cursor invokes the Stripe MCP:
// 1. MCP authenticates with STRIPE_SECRET_KEY
// 2. Queries the Stripe API for invoices
// 3. Returns structured data to the agent
// 4. Agent generates code:

async function fetchCustomerInvoices(customerId: string) {
  // This would be generated by the agent using MCP data
  const invoices = [
    { id: "in_123", amount: 9900, status: "paid" },
    { id: "in_124", amount: 4900, status: "draft" }
  ];
  return invoices;
}
```

---

## 5. Multi-File Editing & Large Refactors

### Approach: Plan → Review → Execute

**Example: Refactor authentication from session-based to JWT**

**Step 1: Create a Plan**

```
Cmd+I → "Create a plan to refactor authentication from Express sessions
to JWT tokens. List all files that need changes, current approach,
new approach, and risk factors."
```

Cursor responds with a markdown plan:

```markdown
## Refactoring Plan: Session → JWT

### Current Architecture
- `middleware/session.ts` – session middleware
- `routes/auth.ts` – login/logout endpoints using sessions
- `controllers/user.ts` – user data loaded from session

### Files to Modify
1. `middleware/jwt.ts` (create)
2. `config/env.ts` (add JWT_SECRET)
3. `routes/auth.ts` (rewrite login/logout)
4. `controllers/user.ts` (read JWT instead of session)
5. `tests/auth.test.ts` (rewrite tests)

### Risk Factors
- Existing users with session cookies won't auto-convert
- Session cleanup code can be removed (after migration period)
- Tests must pass before deploy
```

**Step 2: Execute with Composer**

```
Cmd+I → "Execute the refactoring plan above. Create JWT middleware,
update routes and controllers, write tests. Ensure tests pass."
```

Composer:
- Creates `middleware/jwt.ts` with JWT verification logic
- Rewrites `routes/auth.ts` to issue JWTs on login
- Updates `controllers/user.ts` to extract user from JWT
- Generates `tests/auth.test.ts` with JWT test cases
- Runs tests; if they fail, fixes the code

**Step 3: Review & Merge**

1. Cursor shows diffs for all changed files
2. You review once (or iterate with "This is wrong, fix it")
3. Click "Save" to write all changes
4. Push to a branch, create a PR

---

### Shadow Virtual File System (SVFS) – Parallel Multi-Agent Changes

When running multiple agents simultaneously (Cursor 2.0+), each agent writes to a virtual tree:

```
Codebase (real)
├── Main Branch
│   └── Agent 1's view (virtual)
│   └── Agent 2's view (virtual)
│   └── Agent 3's view (virtual)
```

Each agent sees the same starting state, makes changes independently, then Cursor merges the virtual changes into a single diff for you to review. This eliminates race conditions.

**Use case:** Three agents refactoring different features in parallel:
- Agent 1: Refactors the payment module
- Agent 2: Updates the UI components
- Agent 3: Writes tests for both

All three write independently; conflicts are resolved before presenting the final diff.

---

## 6. Test-Driven Development (TDD) in Cursor

Cursor enhances TDD by automating test generation and implementation.

### TDD Cycle with Cursor

**Step 1: Write a Test (You)**

```typescript
// tests/palindrome.test.ts
describe('isPalindrome', () => {
  it('should return true for palindromic strings', () => {
    expect(isPalindrome('racecar')).toBe(true);
    expect(isPalindrome('a')).toBe(true);
  });

  it('should return false for non-palindromic strings', () => {
    expect(isPalindrome('hello')).toBe(false);
  });

  it('should ignore spaces and punctuation', () => {
    expect(isPalindrome('race car')).toBe(true);
    expect(isPalindrome('A man, a plan, a canal: Panama')).toBe(true);
  });
});
```

**Step 2: Implement with Cursor**

```
Cmd+I → "Implement the isPalindrome function in src/utils.ts
to make the tests pass."
```

Cursor:
1. Reads the test file
2. Understands the function signature and behavior expected
3. Generates an implementation that passes all tests
4. Optionally runs tests to verify

```typescript
// src/utils.ts
export function isPalindrome(str: string): boolean {
  const cleaned = str.toLowerCase().replace(/[^a-z0-9]/g, '');
  return cleaned === cleaned.split('').reverse().join('');
}
```

**Step 3: Run Tests**

Cursor integrates with your test runner (Vitest, Jest, pytest):

```bash
npm test  // Or Cmd+Shift+T in Cursor to run tests
```

**Step 4: Refactor (Optional)**

If tests still pass, use Cmd+K to improve the implementation for readability or performance—tests keep you safe.

### Background Agent Testing

For larger features, use background agents:

```
Cmd+I → "Run in Background" → "Implement user authentication.
Write tests first, then implementation. Ensure all tests pass."
```

Cursor's agent:
1. Generates test file with comprehensive cases (login, logout, errors)
2. Implements auth logic
3. Runs tests automatically
4. If tests fail, attempts fixes
5. Notifies you when complete

---

## 7. Spec-Driven Development (SDD) in Cursor

Spec-driven development separates specification from implementation. Cursor integrates with spec workflows.

### Cursor Rules as Pseudo-Specs

Use `.cursor/rules/*.mdc` files to encode architectural requirements:

```markdown
---
description: "API response format specification"
globs: ["**/*.ts"]
alwaysApply: true
---

# API Response Specification

## All API endpoints must return this structure:

```json
{
  "success": true,
  "data": { /* payload */ },
  "error": null,
  "meta": {
    "timestamp": "2026-03-18T10:00:00Z",
    "version": "v1"
  }
}
```

## Error responses:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": { "field": "email" }
  },
  "meta": { "timestamp": "...", "version": "v1" }
}
```

## Implementation:
- Use `ApiResponse<T>` type for all endpoints
- Never return raw objects; wrap in ApiResponse
- Include error code (VALIDATION_ERROR, NOT_FOUND, UNAUTHORIZED, etc.)
```

### Using PRD/Spec Documents

**Store specs in markdown:**

```
docs/
├── specs/
│   ├── authentication.md
│   ├── billing.md
│   └── analytics.md
```

**Reference in Composer:**

```
Cmd+I → "Implement the billing API according to docs/specs/billing.md.
Use the API response format from .cursor/rules/api-response.mdc."
```

Cursor reads both the spec and the rules, ensuring implementation matches requirements.

### Plan Mode (Specification → Implementation)

Cursor Plan Mode auto-generates an editable plan before execution:

```
Cmd+I → Select "Plan" instead of "Agent"
Instruction: "Build a user dashboard showing profile, recent activity, and settings"

Output: (Markdown plan)
## Implementation Plan

### Files to Create
- `components/UserDashboard.tsx`
- `pages/dashboard.tsx`
- `services/user.ts` (fetch user data)

### Files to Modify
- `routes/app.tsx` (add dashboard route)
- `types/user.ts` (add dashboard-specific types)

### Steps
1. Create `services/user.ts` with fetchUserProfile()
2. Create `components/UserDashboard.tsx` with sections: profile, activity, settings
3. Create `pages/dashboard.tsx` with layout
4. Update routes
5. Write tests

### Dependencies
- Dashboard depends on UserService
- UserService depends on API endpoint (must exist)

### Risk
- If API endpoint doesn't exist, implementation will fail
```

You can edit the plan before execution, then click "Execute" to implement.

---

## 8. Model Selection & Cost Management

Cursor 2026 supports multiple models. Choose based on task type and cost.

### Available Models

| Model | Provider | Speed | Accuracy | Cost (relative) | Best For |
|-------|----------|-------|----------|-----------------|----------|
| Claude Sonnet 4.5 | Anthropic | Fast | High | ~1x | Default for most tasks, TDD, testing |
| Claude Opus 4.6 | Anthropic | Slow | Highest | ~8x | Complex refactoring, architecture |
| GPT-5.3 | OpenAI | Medium | High | ~0.5x | Large files, numerical code |
| Gemini 3 Pro | Google | Fast | Medium | ~0.4x | Quick fixes, completions |
| Composer | Cursor | Fast | High | Built-in | Multi-file edits (proprietary) |

### Pricing Breakdown

**Cursor Plans:**
- Hobby: Free, 50 premium requests/month + 500 free requests
- Pro: $20/month, 500 requests
- Pro+: $60/month, 1,500 requests (3x Pro)
- Ultra: $200/month, 10,000 requests (20x Pro)

**Credit Usage per Request:**
- Claude Sonnet 4.5: ~2 credits per request
- Claude Opus 4.6: ~15 credits per request
- GPT-5.3: ~1 credit per request
- Gemini 3 Pro: ~0.8 credits per request

**Example Math:**
```
Pro plan: 500 requests/month

Option A: All Claude Sonnet 4.5
- 500 × 2 = 1000 credits used
- Covers: Standard coding, testing, debugging

Option B: Mix (Claude Sonnet for day-to-day, Opus for architecture)
- 400 Sonnet requests = 800 credits
- 20 Opus requests = 300 credits
- 80 Gemini requests = 64 credits
- Total = ~1164 credits (exceeds plan)

Option C: Optimize with Gemini for quick fixes
- 250 Sonnet (refactoring) = 500 credits
- 20 Opus (architecture) = 300 credits
- 230 Gemini (quick fixes, tab completion) = 184 credits
- Total = ~984 credits (fits in plan)
```

### Switching Models in Cursor

**In Chat (Cmd+L):**
1. Open chat
2. Look for "Model" dropdown (top-right of chat)
3. Select Claude Sonnet 4.5, Opus 4.6, GPT-5.3, or Gemini 3 Pro

**In Composer (Cmd+I):**
1. Open Composer
2. Click the model name (shown in top bar)
3. Choose model

**Default Tab Completion:**
- Always uses Cursor's Composer model (fast, built-in credits)
- Cannot be changed; optimized for low latency

### When to Use Each Model

**Claude Sonnet 4.5 (Recommended Default)**
- Writing tests, implementing features
- Debugging, error analysis
- Multi-file refactoring
- Cost-effective for 80% of tasks

**Claude Opus 4.6 (Use Sparingly)**
- Architectural decisions
- Complex system redesigns
- Understanding legacy code
- When Sonnet fails and you need raw power

**GPT-5.3 (Cost-Conscious)**
- Large file edits (good with long context)
- Numerical/mathematical code
- When you need 3-5x cost savings

**Gemini 3 Pro (Quick Fixes)**
- Renaming variables
- Adding comments
- Linting fixes
- Quick "show me an example" queries

---

## 9. Context Management: @Mentions, .cursorignore, Indexing

Cursor indexes your entire codebase on first open to enable fast semantic search. Managing context prevents noise and speeds up AI reasoning.

### Codebase Indexing

**How it works:**
1. Cursor scans all files (respecting `.gitignore` and `.cursorignore`)
2. Parses ASTs to understand code structure (functions, classes, variables)
3. Builds a semantic graph of symbols and their relationships
4. Uses this graph to retrieve relevant code when you ask a question

**Indexing performance:**
- Small project (<10K LOC): ~30 seconds
- Medium project (100K LOC): ~2-5 minutes
- Large project (1M LOC): ~10+ minutes if unoptimized

**Optimization: .cursorignore**

Create `.cursorignore` in your project root:

```
# Dependencies (always exclude)
node_modules/
venv/
.venv/
vendor/

# Build outputs
dist/
build/
*.o
*.so

# Large non-code files
*.iso
*.zip
media/
videos/

# Third-party libraries
lib/external/
third-party/

# Temporary files
.cache/
tmp/
*.tmp
```

With this, indexing time drops from 8 minutes to 2 minutes on a 100K-line project.

### .cursorindexingignore (Finer Control)

New in Cursor 0.46: Separate indexing control from AI access.

```
# Files here won't be indexed for search, but can still be referenced
*.log
coverage/
.git/
```

Files in `.cursorindexingignore`:
- Won't appear in @codebase search results
- Can still be manually @-mentioned (`@file coverage/report.json`)
- AI can access them if you explicitly reference them

---

### @-Mentions: Explicit Context Injection

**@file** – Reference a specific file:
```
Cmd+L → "@file src/api/users.ts How do we validate email addresses?"
```

**@codebase** – Let Cursor find relevant files:
```
Cmd+L → "@codebase What's our pattern for error handling?"
```
Cursor searches the semantic index and includes the top 3-5 matching files.

**@Docs** – Reference external documentation:
```
Cmd+L → "@Docs What's the recommended way to handle async operations?"
```
Works for framework docs (React, Vue, Next.js) stored locally or linked.

**@Problems** – Reference current errors:
```
Cmd+L → "@Problems Why is the build failing?"
```
Cursor includes error messages and stack traces in context.

**Pro Tips:**
- Prefer `@codebase` over manually selecting files (faster, cleaner)
- Use `@file` for small, specific questions
- Avoid @-mentioning 20 files when 3 are relevant (dilutes AI focus)
- @Docs works best when documentation is in your `.cursor/docs/` or referenced in `.cursordocs`

---

### Workspace Index Quality

Cursor's index powers fast semantic search. Quality depends on:

1. **File structure clarity** – Well-organized code indexes faster
2. **Naming conventions** – Clear function/variable names improve search
3. **Comments & docstrings** – Cursor indexes these; helps find relevant code
4. **Reducing noise** – More irrelevant files = slower search, worse results

**Check index quality:**
1. Cmd+L → Type a question: "Show me all authentication functions"
2. Look at the files Cursor includes in context
3. If it's pulling unrelated files, create `.cursorignore` entries or rename for clarity

---

## 10. Cursor + Claude Code: When to Use Each

### Positioning: IDE-First vs. Agent-First

**Cursor IDE** – You drive, AI assists with completions, inline edits, suggestions.

**Claude Code** – You describe, AI drives, you review the results.

### Hybrid Workflow Pattern (Recommended for Power Users)

**Use Cursor for:**
- Day-to-day editing, typing
- Quick fixes with Cmd+K
- Exploring codebase (Cmd+L chat)
- Iterative refinement: write → test → tweak

**Use Claude Code for:**
- Large discrete tasks ("Implement user authentication")
- Full feature builds (runs locally or on cloud agents)
- Test-first workflows (Claude Code integrates with test runners)
- Multi-hour background work (cloud agents)

### Example Hybrid Session

```
1. Open Cursor IDE
2. Cmd+L → Chat with Claude Code: "What's our current user auth approach?"
3. Claude Code: "Session-based with Express. Uses `express-session` and `bcrypt`."
4. Back in Cursor, Cmd+I → "Add JWT support alongside sessions for API clients"
5. Composer generates the code across multiple files
6. Switch to Claude Code terminal → `npm test` (integrated test runner)
7. Claude Code agent sees test failures, auto-fixes the implementation
8. Notifications: tests pass, ready to merge
9. Back in Cursor → Review final code, push to branch
```

### Feature Comparison

| Aspect | Cursor | Claude Code |
|--------|--------|------------|
| Interface | IDE (file tree, editor) | Terminal + browser |
| Control style | IDE-first | Agent-first |
| Multi-file edits | Composer (fast, visual) | Agent (thorough, test-aware) |
| Test integration | Manual (run tests yourself) | Native (agent watches test runner) |
| Background work | Cloud agents | Yes, fully integrated |
| Cost | Cursor credits ($20-200/mo) | Claude API (pay per use) |
| Best for | Iterative coding | Autonomous task execution |

---

## 11. Performance & Optimization Tips

### Hardware Recommendations

- **CPU:** 6+ cores (8+ preferred)
- **RAM:** 16GB minimum (32GB for large codebases)
- **Storage:** SSD (NVMe preferred); HDD = slow indexing
- **Network:** Stable connection (agents may sync to cloud)

### Software Optimization

1. **Configure .cursorignore aggressively**
   ```
   # Fast indexing = faster context retrieval
   node_modules/
   dist/
   build/
   .git/
   coverage/
   ```

2. **Enable caching in Cursor settings**
   - Settings → General → Enable "Cache completions"
   - Reduces redundant AI calls for similar code patterns

3. **Use lightweight models for quick fixes**
   - Gemini 3 Pro for renaming, formatting
   - Claude Sonnet for complex logic
   - Opus only for architecture decisions

4. **Limit context window manually**
   - For large files (>5KB), use Cmd+K (inline) instead of Cmd+I
   - Cursor+K uses local context only (faster)

5. **MCPs as context bridges**
   - Instead of pasting entire database schema in chat, use PostgreSQL MCP
   - Instead of copying Stripe docs, use Stripe MCP
   - MCPs provide real-time data without inflating context

### Workflow Optimization

1. **Write .cursorrules once; reuse everywhere**
   - Invest 30 min upfront to document your patterns
   - Every AI request then respects your standards automatically

2. **Use Plan Mode before executing large changes**
   - Cursor Plan → Review plan → Execute
   - Saves iteration time on failed attempts

3. **TDD keeps refactoring fast**
   - Write tests first; AI implements to spec
   - Tests catch regressions automatically

4. **Parallel agents for multi-feature work**
   - Run 3-4 agents in background on different features
   - Merge once all agents complete

---

## 12. Practical Examples & Recipes

### Recipe 1: Add a Feature End-to-End (30 min)

```
Goal: Add a "favorite" button to products

1. Cmd+I → "Create a test for the favorite button feature"
   - Cursor generates tests/product.favorite.test.ts

2. Cmd+I → "Implement the favorite button in ProductCard component
             and database schema to make tests pass"
   - Cursor creates migration, model, component, API endpoint

3. Terminal: npm test
   - All tests pass

4. Cmd+L → "Does this implement everything in the spec?"
   - Review against requirements

5. Commit & push
```

### Recipe 2: Refactor with Parallel Agents

```
Goal: Migrate from Redux to Zustand state management

1. Cmd+I (Plan mode) → "Plan a Redux-to-Zustand migration"
   - Review generated plan

2. Start 3 agents:
   - Agent 1: Refactor auth store
   - Agent 2: Refactor UI store
   - Agent 3: Update components to use new stores

3. All run in background; get notified when done

4. Review each agent's changes in Composer

5. Merge all changes, run tests
```

### Recipe 3: Debug with Background Agent

```
Goal: Fix a memory leak in the app

1. Cmd+I → "Run in Background"
   Instruction: "Analyze the memory leak described in issue #234.
   Use the browser DevTools MCP to capture heap snapshots.
   Identify the leaked objects, fix the code, and write a test to prevent regression."

2. Agent:
   - Reads issue description
   - Runs heap snapshot via browser MCP
   - Identifies leak source
   - Fixes the code
   - Writes a test

3. Notification: "Memory leak fixed. Tests pass."

4. Review & merge
```

---

## 13. Keyboard Shortcuts Cheat Sheet (Extended)

| Shortcut | Action |
|----------|--------|
| Cmd+K (Ctrl+K) | Inline edit at cursor |
| Cmd+L (Ctrl+L) | Open chat panel |
| Cmd+I (Ctrl+I) | Open Composer (multi-file) |
| Cmd+Shift+I | Full Composer (larger scope) |
| Cmd+Shift+P | Command palette (search commands) |
| Cmd+/ | Toggle comment |
| Cmd+Shift+F | Find in files |
| Cmd+J | Toggle terminal |
| Cmd+B | Toggle sidebar |
| Cmd+, | Open settings |
| Cmd+Enter | Accept inline edit (Cmd+K) |
| Cmd+Backspace | Reject inline edit (Cmd+K) |
| Cmd+R Cmd+S | View all keyboard shortcuts |
| Cmd+Shift+V | Paste without formatting |
| Cmd+P | Quick file open |
| Tab | Accept autocomplete suggestion |
| Esc | Dismiss popup/suggestion |

---

## 14. Troubleshooting & Common Issues

### Issue: Cursor generating incorrect code for my project

**Cause:** Insufficient context or missing rules

**Solutions:**
1. Create `.cursor/rules/architecture.mdc` documenting your patterns
2. Use Cmd+L to chat about what you're building
3. Use `@codebase` to prime the AI with relevant files

### Issue: Indexing is slow

**Cause:** Large node_modules, build artifacts

**Solution:**
```bash
# Create .cursorignore
node_modules/
dist/
build/
coverage/
.git/
```

### Issue: Tab completion is slow

**Cause:** Large file or network latency

**Solution:**
1. Split large files into smaller modules
2. Enable Cursor's offline mode for completions (Settings → General)
3. Use Cmd+K for explicit edits instead of waiting for Tab

### Issue: Agent ran out of iterations

**Cause:** Task too complex or goal ambiguous

**Solution:**
1. Break task into smaller steps
2. Provide more context in the prompt
3. Use Claude Opus for harder tasks

### Issue: Agents running concurrently have merge conflicts

**Cause:** Multiple agents editing the same files

**Solution:**
1. Use descriptive agent names/tasks (they see each other's goals)
2. Use SVFS (Shadow Virtual File System) for intelligent merging
3. Divide work by file/module, not feature

---

## 15. Staying Current: Cursor Roadmap & What's Next

**March 2026 (Cursor 2.6)**
- MCP plugin marketplace with 30+ partners (Linear, Stripe, Figma, AWS, etc.)
- Team plugin marketplaces (share internal plugins)
- Interactive MCP UIs in agent chat

**Emerging (Q2-Q3 2026)**
- JetBrains IDE plugin (IntelliJ, PyCharm, GoLand support)
- Improved async subagent coordination (tree of agents)
- Larger context windows for complex codebases
- Spec versioning and validation

**Monitor:**
- `cursor.com/changelog` for monthly updates
- `forum.cursor.com` for community discussions
- GitHub issues in Cursor guide repos for workarounds

---

## Summary: Power-User Mental Model

1. **Cmd+K** for quick surgical fixes (fast)
2. **Cmd+I** for multi-file features and refactoring (coordinated)
3. **Cmd+L** for questions, debugging, design (exploratory)
4. **.cursorrules** to encode your project's patterns (persistent context)
5. **MCPs** to pull real data without copying/pasting
6. **Background agents** for long-running tasks (test generation, refactoring)
7. **Plan Mode** before large changes (review before execution)
8. **TDD** to keep refactoring safe (tests as contract)
9. **Parallel agents** to work on multiple features simultaneously
10. **Cursor + Claude Code** together for hybrid workflows (IDE + agents)

---

## Sources

- [Cursor Docs: Composer](https://docs.cursor.com/composer)
- [GitHub: slava-kudzinau/cursor-guide](https://github.com/slava-kudzinau/cursor-guide)
- [GitHub: murataslan1/cursor-ai-tips](https://github.com/murataslan1/cursor-ai-tips)
- [Cursor Features](https://cursor.com/features)
- [Cursor Changelog](https://cursor.com/changelog)
- [Cursor Marketplace](https://cursor.com/marketplace)
- [Cursor Docs: Keyboard Shortcuts](https://docs.cursor.com/kbd)
- [Cursor Docs: API Keys](https://cursor.com/docs/settings/api-keys)
- [Cursor Docs: Ignore Files](https://cursor.com/docs/context/ignore-files)
- [Cursor Docs: Parallel Agents](https://cursor.com/docs/configuration/worktrees)
- [GitHub: awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules)
- [cursorrules.org](https://cursorrules.org/)
- [Medium: Cursor Plan Mode](https://dibishks.medium.com/cursor-plan-mode-the-future-of-code-planning-with-ai-powered-precision-e38637b8d481)
- [Medium: Cursor Parallel Agents](https://medium.com/towards-data-engineering/parallel-ai-agents-in-cursor-2-0-a-practical-guide-e808f89cffb9)
- [Medium: Mastering Cursor IDE](https://medium.com/@roberto.g.infante/mastering-cursor-ide-10-best-practices-building-a-daily-task-manager-app-0b26524411c1)
- [Builder.io: Claude Code vs Cursor](https://www.builder.io/blog/cursor-vs-claude-code)
- [TechCrunch: Cursor Background Agents](https://techcrunch.com/2026/03/05/cursor-is-rolling-out-a-new-system-for-agentic-coding/)
- [ameany.io: Cursor Background Agents Guide](https://ameany.io/blog/cursor-background-agents/)
- [Medium: Cursor Rules Deep Dive](https://mer.vin/2025/12/cursor-ide-rules-deep-dive/)
- [DataLakeHouse: Context Management Strategies](https://datalakehousehub.com/blog/2026-03-context-management-cursor/)
- [Medium: TDD with Cursor](https://medium.com/@arun-gupta/test-driven-development-tdd-with-cursor-writing-a-palindrome-function-in-typescript-2cad37f8997f)
- [Cursor Docs: Models & Pricing](https://cursor.com/docs/models)
- [Medium: A Year with Cursor](https://subramanya.ai/2026/01/04/a-year-with-cursor-how-my-workflow-evolved-from-agent-to-architect/)

---

## Related Topics

- [Claude Code Power User](claude-code-power-user.md) — Comparing Cursor's patterns with Claude Code's approach
- [Tool Comparison Guide](tool-comparison-when-to-use.md) — Understanding Cursor's strengths and when to use it vs. alternatives
- [Hooks Enforcement Patterns](hooks-enforcement-patterns.md) — Using .cursorrules and background agents for consistency
