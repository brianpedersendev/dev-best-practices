# Claude Code Power User Guide 2026

A practical deep-dive on using Claude Code like a power user. This guide covers actionable techniques, exact commands, and configurations for advanced workflows.

**Last updated:** March 18, 2026
**Target:** Developers building with Claude Code in 2026 (1M context window, Opus 4.6, latest features)

---

## 1. TDD-First Workflow

Test-Driven Development with Claude requires **explicit instructions**. Claude naturally writes implementation first, then tests. You must reverse this.

### Core Workflow

```text
Step 1: Write a FAILING test (explicit)
claude> Write a FAILING test for the UserService.authenticate() method.
Do NOT write implementation yet. The test should cover:
- Valid credentials return user object
- Invalid password throws AuthError
- Missing user throws NotFoundError

Step 2: Verify test fails
claude> Run the test suite and confirm these tests fail.

Step 3: Minimal implementation
claude> Implement UserService.authenticate() to make tests pass.
Use an in-memory store for now.

Step 4: Refactor if needed
claude> Refactor to improve code quality while keeping tests passing.
```

### CLAUDE.md Configuration for TDD

```markdown
# Testing Standards
- Write tests FIRST using [test framework: jest/pytest/etc]
- Use `npm test` / `pytest` to verify immediately
- Name test files: `*.test.ts`, `*.spec.py`
- Each test should test ONE behavior
- Mock external dependencies (databases, APIs, etc)

# Key Workflow
- Always run tests after implementation
- If tests fail: fix implementation, not tests
- Keep test coverage above 80%
```

### Enforce TDD with Hooks

Use a `PostToolUse` hook to automatically run tests after any file edit:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -f 'jest.config.js' ] || [ -f 'package.json' ]; then npm test -- --passWithNoTests; fi"
          }
        ]
      }
    ]
  }
}
```

Save to `.claude/settings.json` in your project root. This hook runs tests automatically after Claude modifies any file, forcing immediate feedback on whether your implementation works.

### Prompt Pattern

```text
I want to build [feature]. Interview me first about edge cases and requirements.
Once we have a spec, I'll write FAILING tests, then you implement to make them pass.

The workflow is:
1. Me: "Write tests for X"
2. You: [test code, runs tests, confirms failure]
3. Me: "Implement X to pass tests"
4. You: [implementation, runs tests, confirms pass]
5. Me: [review code, suggest refactors]
6. You: [refactor while keeping tests green]

Ready to start?
```

---

## 2. Plan Mode Mastery

Plan Mode separates exploration from execution, preventing wasted effort on complex changes.

### Entering Plan Mode

**Option 1: Keyboard shortcut**
- **Mac:** `Shift + Tab` (press twice: once to enter Auto mode, once more for Plan mode)
- **Windows:** `Alt + M` (cycles through modes)
- **Or type directly:** `/plan` in your prompt

**Option 2: Check mode status**
Press `?` to see current mode and available shortcuts.

### Core Workflow

```text
claude (Normal Mode)> /plan

claude (Plan Mode)> Read the authentication module and understand
how we currently handle sessions, tokens, and user context.

[Claude reads files without making changes]

claude (Plan Mode)> Now I want to add OAuth2. Create a detailed
implementation plan covering:
- Which files change
- Architecture changes needed
- Session flow modifications
- Testing strategy

[Claude generates a plan]

[You review, press Ctrl+G to edit the plan in your editor]

claude> Implement the plan from Step 2. Write tests first,
then implementation. Run the test suite and fix any failures.

[Claude exits Plan Mode and implements against the plan]
```

### When to Use Plan Mode

**Use Plan Mode when:**
- The change affects multiple files (5+)
- You're unfamiliar with the codebase
- There are multiple valid approaches to choose from
- You want to review the strategy before Claude codes

**Skip Plan Mode when:**
- Fix is small (rename, add log line, typo)
- Task scope is crystal clear
- Could describe the diff in one sentence

### Editing Plans

1. Claude presents a plan
2. Press `Ctrl+G` to open in your default text editor
3. Edit, refine, add details
4. Save and close the editor
5. Claude reads the updated plan and implements it

### Pro Tips

- Plans that touch 7+ files start to lose quality. Break into smaller plans.
- Don't accept the first plan. Refine it. Ask edge case questions.
- Prime Claude with key files before planning: use `@file1 @file2` to include them in context.
- If you drift during implementation, press `Shift+Tab` back to Plan Mode. Claude creates a revised plan for remaining steps.

---

## 3. Spec-Driven Development

Structure specs to give Claude a complete picture upfront instead of iterating mid-implementation.

### Folder Structure

```
project/
├── specs/
│   ├── REQUIREMENTS.md      # What you're building
│   ├── DESIGN.md            # How you'll build it
│   ├── TASKS.md             # Discrete tasks with success criteria
│   └── interfaces.ts        # Type contracts, API schemas
├── src/
└── CLAUDE.md
```

### REQUIREMENTS.md Format

```markdown
# Feature: User Authentication Refresh

## User Story
As a user, I want my session to persist when my access token expires,
so I don't get logged out unexpectedly.

## Acceptance Criteria
- [ ] Refresh token stored in httpOnly cookie
- [ ] Automatic token refresh on 401 response
- [ ] Graceful logout when refresh fails (no valid refresh token)
- [ ] Works with existing OAuth providers

## Non-Functional Requirements
- Token refresh must complete in <200ms
- No race conditions on concurrent API calls
- Works offline (cached until refresh attempt)

## Out of Scope
- Multi-device session management
- Token revocation webhooks
```

### DESIGN.md Format

```markdown
# Architecture: Token Refresh Flow

## Overview
Implement transparent token refresh using an axios interceptor
that retries failed requests with a fresh access token.

## Components
- **RefreshTokenClient**: Handles token refresh API calls
- **AuthInterceptor**: Catches 401, queues requests, refreshes, retries
- **TokenStore**: Manages access/refresh tokens in memory + cookie

## Data Flow
1. API call fails with 401
2. Interceptor detects 401
3. Check if already refreshing (prevent race condition)
4. Call /auth/refresh with refresh token
5. Store new access token
6. Retry original request
7. Return response

## Error Handling
- If refresh fails: clear tokens, redirect to login
- If offline: queue requests, retry on reconnect
- If concurrent requests: wait for first refresh, reuse result

## Testing Strategy
- Mock API responses (401, success, refresh failure)
- Test race conditions (multiple simultaneous requests)
- Test offline scenario
```

### TASKS.md Format

```markdown
# Tasks for Token Refresh Feature

## Task 1: Create RefreshTokenClient
**File:** `src/auth/RefreshTokenClient.ts`

**Acceptance Criteria:**
- [ ] Constructor accepts baseURL and endpoints
- [ ] refresh() method calls POST /auth/refresh
- [ ] Returns { accessToken, refreshToken }
- [ ] Throws on network error
- [ ] Throws on 401/403 from refresh endpoint

**Test File:** `src/auth/RefreshTokenClient.test.ts`

## Task 2: Implement AuthInterceptor
**File:** `src/auth/AuthInterceptor.ts`

**Acceptance Criteria:**
- [ ] Exports request interceptor (adds auth header)
- [ ] Exports response interceptor (handles 401)
- [ ] Queues requests during token refresh
- [ ] Retries queued requests after refresh
- [ ] Clears tokens and logs out on permanent failure
- [ ] No race conditions on concurrent failures

**Test File:** `src/auth/AuthInterceptor.test.ts`
**Test Cases:**
- Normal 401 with successful refresh
- Refresh fails (no valid token)
- Multiple concurrent 401s (should only refresh once)

## Task 3: Integration Tests
**File:** `src/auth/integration.test.ts`

**Acceptance Criteria:**
- [ ] Full flow: 401 → refresh → retry → success
- [ ] Token stored in httpOnly cookie
- [ ] Offline scenario works
```

### Execution Pattern

**Session 1: Spec Creation (Your work)**
- Write REQUIREMENTS.md (user's perspective)
- Create DESIGN.md with architecture decisions
- Break down TASKS.md with specific success criteria
- Define interfaces in TypeScript

**Session 2: Implementation (Claude's work)**
- Fresh session, starts with CLAUDE.md + specs
- Claude reads specs, creates detailed plan
- You review plan against DESIGN.md
- Claude implements each task in TASKS.md order
- Each task has isolated tests
- Final integration tests verify the full flow

**Benefits:**
- One detailed upfront review (DESIGN.md) beats eight iterations
- Each task is self-contained and testable
- New team members understand intent without asking questions
- Specs become documentation

---

## 4. Multi-Agent Patterns

Use subagents and agent teams to parallelize work without losing main conversation context.

### Subagents vs. Agent Teams

| Feature | Subagents | Agent Teams |
|---------|-----------|------------|
| **Context** | Single session, shared context | Separate sessions, isolated context |
| **Communication** | Report back to main agent | Message each other + central lead |
| **Parallelism** | Sequential or concurrent within one context | True parallel work |
| **Use case** | Isolated tasks (testing, research) | Complex multi-phase work |

### Creating a Subagent

**Option 1: Interactive setup (recommended)**
```bash
claude
/agents
# Choose "Create new agent" → "Personal" → "Generate with Claude"
# Describe what you want:
# "A code reviewer that analyzes code for quality, security, and best practices"
```

**Option 2: Manual file creation**
Create `~/.claude/agents/code-reviewer.md`:

```yaml
---
name: code-reviewer
description: Reviews code for quality, security, and best practices. Proactively suggests improvements.
tools: Read, Grep, Glob, Bash
model: sonnet
memory: user
---

You are a senior code reviewer. Your job is to:
1. Analyze code for bugs, performance issues, security flaws
2. Check adherence to best practices
3. Suggest concrete improvements

When invoked:
- Run `git diff` to see recent changes
- Review only modified files
- Provide feedback organized by: Critical → Warnings → Suggestions

Each finding should include:
- Specific file and line number
- Why this is an issue
- Suggested fix with code example
```

### Invoking Subagents

**Natural language (Claude decides):**
```text
Have the code-reviewer look at my recent changes
```

**Force a specific subagent (@-mention):**
```text
@code-reviewer (agent) analyze the auth module for security issues
```

**Run entire session as subagent:**
```bash
claude --agent code-reviewer
# Now the whole session uses that subagent's prompt, tools, and model
```

### Multi-Subagent Workflow (Writer/Reviewer)

**Session A (Writer):**
```text
Implement a rate limiter for API endpoints. Tests first, then implementation.
```

**Session B (Reviewer) - parallel:**
```text
Review the rate limiter implementation at @src/middleware/rateLimiter.ts
Look for edge cases, race conditions, and performance issues.
```

**Back to Session A:**
```text
Here's the review feedback: [paste Session B output]
Address these issues.
```

### Agent Teams (Complex Coordination)

Use when you need multiple agents working in parallel with their own full context windows and inter-agent communication.

**Setup:**
```bash
claude --agent-teams
# Launches team coordinator mode
```

**Typical team composition:**
- **Team Lead:** Coordinates work, assigns tasks, synthesizes results
- **Frontend Developer:** Builds UI, tests UI components
- **Backend Developer:** Implements APIs, database schemas
- **Test Engineer:** Writes tests, verifies quality

Each teammate gets its own context (200K tokens each), so a 4-person team has 800K total parallel context.

---

## 5. Skills, Plugins, and MCPs

Extend Claude Code with reusable knowledge, integrations, and external tools.

### Skills (Reusable Prompts)

Skills are markdown files that provide domain-specific knowledge Claude applies automatically.

**Create a skill:**
Create `~/.claude/skills/api-conventions/SKILL.md`:

```yaml
---
name: api-conventions
description: REST API design patterns for our services
---

# API Design Standards

## URL Structure
- Use kebab-case for paths: `/user-profiles`, not `/userProfiles`
- Include version in path: `/v1/`, `/v2/`
- Use plural resource names: `/users`, not `/user`

## Request/Response
- Request body: camelCase properties
- Response body: camelCase properties
- Always include `_links` for HATEOAS navigation
- Timestamp format: ISO 8601 with timezone

## Error Responses
- 400: Bad request (validation failed)
- 401: Unauthorized (not authenticated)
- 403: Forbidden (authenticated but not authorized)
- 409: Conflict (duplicate, outdated version)
- 500: Server error (log and alert)

Use this standard across all new endpoints.
```

**Claude automatically applies skills when relevant.** Or invoke directly:

```text
/api-conventions design a new endpoint for user profiles
```

### MCP Servers (External Integrations)

MCP servers connect Claude to external tools: GitHub, Slack, databases, Figma, etc.

**Add an MCP server:**

```bash
# HTTP remote server (recommended for cloud services)
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Authenticate if needed
claude
/mcp
# [Follow browser auth flow]

# Local stdio server (for tools on your machine)
claude mcp add --transport stdio airtable --env AIRTABLE_API_KEY=YOUR_KEY \
  -- npx -y airtable-mcp-server

# Check configuration
claude mcp list
claude mcp get github
```

**Common MCP servers (2026):**

| Server | Command | Use |
|--------|---------|-----|
| GitHub | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` | Manage PRs, issues, repos |
| Sentry | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` | Monitor errors |
| PostgreSQL | `claude mcp add --transport stdio postgres -- npx @modelcontextprotocol/server-postgres` | Query databases |
| Slack | `claude mcp add --transport http slack https://mcp.slack.com/mcp` | Read/send messages |
| Figma | `claude mcp add --transport http figma https://mcp.figma.com/mcp` | Access designs |

**Use MCP tools in prompts:**
```text
Review PR #456 on GitHub and check recent Sentry errors related to this feature
```

### Plugins (Bundled Extensions)

Plugins package skills, MCP servers, hooks, and subagents into shareable units.

**Install a plugin:**
```bash
claude
/plugin search python
# Browse results, select one to install
```

**Create a plugin (advanced):**
```
~my-plugin/
├── plugin.json
├── agents/
│   └── code-reviewer.md
├── skills/
│   └── my-skill.md
├── hooks/
│   └── hooks.json
└── mcpServers/
    └── my-server.json
```

See [Sources](#sources) for plugin reference.

---

## 6. Session Discipline and CLAUDE.md

CLAUDE.md is your project's persistent memory across sessions.

### Essential CLAUDE.md Structure

```markdown
# Project: [Name]

## Tech Stack
- Language: TypeScript
- Framework: Next.js 14
- Test framework: Jest
- Package manager: npm

## Key Commands
- `npm run dev` - Start dev server
- `npm run test` - Run tests
- `npm run build` - Build for production
- `npm run lint` - Run ESLint
- `npm run format` - Format with Prettier

## Code Style
- Use `import` / `export` syntax (not CommonJS)
- Destructure imports: `import { foo, bar } from 'module'`
- Prefer const over let, never use var
- Use arrow functions for callbacks
- Components: PascalCase, functions: camelCase, constants: UPPER_SNAKE_CASE

## Architecture
- `/src/components` - React components
- `/src/hooks` - Custom hooks (organized by feature)
- `/src/utils` - Utility functions
- `/src/types` - TypeScript interfaces/types
- `/src/api` - API client, server actions

## Testing Standards
- Use Jest for unit tests
- File naming: `*.test.ts`
- Always test happy path + error cases
- Mock external dependencies
- Target 80%+ coverage

## Common Gotchas
- Environment variables: Use `.env.local` (not checked in)
- Async: Always await promises, use try/catch
- TypeScript: Strict mode enabled, no implicit any
- Browser APIs: Not available in server components

## Project-Specific Rules
- Branch naming: `feature/`, `fix/`, `chore/`
- Commits must pass linting and tests
- PRs require one approval before merge
- No credentials in code or config files
```

### CLAUDE.md Best Practices

**Concise:** Max 200 lines. Ask: "Would Claude make mistakes without this line?" If not, delete it.

**Progressive disclosure:** Don't explain everything. Point Claude to docs:
```markdown
See @README.md for project overview.
See @./docs/ARCHITECTURE.md for system design.
Database schema: @./migrations/
```

**Check into git:** So your team shares the same instructions.

**Update over time:** When Claude struggles with something, add it to CLAUDE.md.

### Context Management

**Track context usage:**
```text
/cost
# Shows current session tokens and cost
```

**Clear between unrelated tasks:**
```text
/clear
# Resets conversation history, preserves code state
```

**Compact manually:**
```text
/compact Focus on the recent API changes and test failures
# Compresses old conversation while preserving what you specify
```

**Use subagents for verbose tasks:**
```text
Use a subagent to run the full test suite and report only failures
# Test output stays in subagent context, summary returns to you
```

**Session scope matters:**
- **One goal per session:** If switching from "implement feature" to "debug issue", `/clear` first
- **Split long projects:** Session A: architecture + interfaces. Session B: feature A. Session C: feature B. Session D: integration.
- **Resume for continuity:** `claude --resume` brings back old sessions with full context

---

## 7. Hooks System (Deterministic Automation)

Hooks run shell commands automatically at specific points in Claude's workflow. Unlike CLAUDE.md instructions (which Claude can ignore), hooks **always execute**.

### Hook Lifecycle Events

| Event | When | Use |
|-------|------|-----|
| `SessionStart` | Session begins or resumes | Inject context, set env vars |
| `PreToolUse` | Before a tool runs | Validate, block dangerous commands |
| `PermissionRequest` | Permission prompt appears | Auto-approve safe tools |
| `PostToolUse` | After a tool succeeds | Run linters, formatters, tests |
| `Stop` | Claude finishes responding | Verify work before returning |
| `PreCompact` / `PostCompact` | Before/after context compaction | Preserve critical context |
| `SubagentStart` / `SubagentStop` | Subagent begins/ends | Setup/cleanup for agent |

### Hook Configuration Location

Scope determines where the hook applies:

```
~/.claude/settings.json          # All your projects (global)
.claude/settings.json            # This project (shared via git)
.claude/settings.local.json      # This project (not in git)
```

### Common Hooks

**1. Auto-format after edits (Prettier)**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

**2. Block edits to sensitive files**

```bash
# Create .claude/hooks/protect-files.sh
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED=(".env" "package-lock.json" ".git/" ".claude/")
for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH is protected" >&2
    exit 2
  fi
done
exit 0
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

**3. Run tests automatically (TDD enforcement)**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --passWithNoTests 2>&1 | tail -20"
          }
        ]
      }
    ]
  }
}
```

**4. Re-inject context after compaction**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: Always run tests before committing. Use TDD: tests first, then implementation.'"
          }
        ]
      }
    ]
  }
}
```

### Hook Exit Codes

| Exit Code | Behavior |
|-----------|----------|
| 0 | Action proceeds. Stdout is added to Claude's context (for `SessionStart`/`UserPromptSubmit`) |
| 2 | Action is blocked. Stderr is shown to Claude as feedback |
| Other | Action proceeds. Stderr logged but not shown (use `Ctrl+O` verbose mode to see) |

### JSON Output for Advanced Control

Exit 0 and print JSON for structured decisions:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use rg instead of grep for better performance"
  }
}
```

**Other decision options:**
- `"allow"` - Skip interactive prompt
- `"deny"` - Cancel the tool call
- `"ask"` - Show the permission dialog

### Browse Configured Hooks

```bash
claude
/hooks
# Shows all configured hooks grouped by event
# Read-only view; edit settings.json directly
```

---

## 8. Keyboard Shortcuts & Mode Switching

### Mode Navigation

| Key(s) | Action |
|--------|--------|
| `Shift+Tab` (Mac) | Cycle through Normal → Auto-Accept → Plan Mode |
| `Alt+M` (Windows) | Same as above |
| `/plan` | Enter Plan Mode directly in prompt |
| `Ctrl+G` | Edit plan in text editor (while in Plan Mode) |

### Workflow Control

| Key(s) | Action |
|--------|--------|
| `Escape` | Stop Claude mid-action (preserves context) |
| `Escape` twice | Open rewind menu (restore code/conversation/both) |
| `/rewind` | Same as Escape twice |
| `/clear` | Reset context between tasks |
| `/compact` | Manually compact context |
| `Ctrl+O` | Toggle verbose mode (see hidden logs) |
| `?` | Show available shortcuts |

### Session Control

| Command | Action |
|---------|--------|
| `claude --continue` | Resume most recent session |
| `claude --resume` | Choose from recent sessions |
| `/rename` | Rename current session |
| `/cost` | Show token usage and cost |

### Interactive Features

| Action | Shortcut |
|--------|----------|
| Toggle extended thinking | `Alt+T` |
| Voice input (if enabled) | `/voice` then spacebar to talk |
| Use subagent for task | `@agent-name` or `Ctrl+B` |
| File @ mention | Type `@` to reference files |
| Ask a side question | `/btw your question` (no tool access, answer discarded) |

---

## 9. Real-World Power User Workflows

### Workflow 1: Bug Fix with Review

```text
# Session A: Fix the bug
claude (Normal Mode)>
Use plan mode to analyze this 500ms slowdown in profile loading.
Research the code, identify bottlenecks, create a fix plan.

[Plan Mode research]
[You review plan via Ctrl+G]

claude> Implement the fix from your plan. Write tests first.
Run tests to verify the fix works.

[Implementation, tests pass]

# Session B: Code review (parallel)
claude --agent code-reviewer
Review the performance fix in @src/ProfileLoader.ts
Check for: correctness, edge cases, race conditions, caching.

# Back to Session A: Address feedback
Here's review feedback from the code-reviewer: [paste feedback]
Address these issues.

[Fix issues]
claude> Commit the changes
```

### Workflow 2: Spec-Driven Feature Development

```text
# Upfront: Create specs (your work, not Claude)
Write specs/REQUIREMENTS.md, specs/DESIGN.md, specs/TASKS.md
Test these specs against your team's consensus

# Session 1: Plan & Architecture
claude --agent code-reviewer
Review the DESIGN.md and identify any flaws before we code.
Are there edge cases we've missed? Architectural concerns?

[Review feedback]
Update DESIGN.md based on feedback

# Session 2: Implementation
claude> I've created REQUIREMENTS.md, DESIGN.md, and TASKS.md.
Start with Task 1 from TASKS.md. Write tests first, then implement.
Run tests after each task to verify.

[Claude implements Task 1, shows test results]
[You review, ask for fixes]

# Repeat for remaining tasks
claude> Move to Task 2...
claude> Move to Task 3...

# Session 3: Integration & Cleanup
claude> Integrate all tasks. Run full test suite.
Create a PR with description from DESIGN.md.
```

### Workflow 3: Large Migration (Parallel Execution)

```text
# List all files that need migrating
claude -p "List all 200 Python files that need migration from Python 2 to 3"
# Saves list to files.txt

# Create migration script
cat << 'EOF' > migrate.sh
#!/bin/bash
while read file; do
  echo "Migrating: $file"
  claude -p "Migrate $file from Python 2 to Python 3. \
    Fix imports, print statements, string/unicode handling. \
    Run tests. Return OK or FAIL."
done < files.txt
EOF

# Run a few files to test, then scale
chmod +x migrate.sh
./migrate.sh | head -10  # Test first 10
./migrate.sh              # Run all 200
```

### Workflow 4: Complex Debugging

```text
# Main session: Coordinate investigation
claude> There's a race condition in the payment system.
Multiple users reporting duplicate charges.
Use subagents to investigate three hypotheses in parallel:

1. Database constraint failure allowing duplicate inserts
2. API retry logic causing double-processing
3. Job queue processing messages twice

Each subagent: investigate the module, check logs, find the culprit.

[3 subagents run in parallel, report findings]

# Synthesize results
claude> Based on the three findings, it looks like [root cause].
Use the debugger subagent to implement a fix and verify it works.

[Debugger subagent fixes and verifies]
```

---

## 10. Advanced Configuration Examples

### Full Power-User Settings

Save to `.claude/settings.json`:

```json
{
  "model": "claude-opus-4-6",
  "permissions": {
    "allow": ["Bash(git .*)", "Bash(npm .*)", "Bash(npm test)"],
    "deny": ["Bash(rm .*)", "Bash(sudo)"]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint -- --fix 2>&1 | grep -E '(error|warning|✓)'"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Session started. Run: npm run dev'"
          }
        ]
      }
    ]
  },
  "env": {
    "npm_token": "${NPM_TOKEN}",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"
  }
}
```

### CLI Flags for Advanced Sessions

```bash
# Custom model + aggressive permissions
claude --model opus-4-6 --dangerously-skip-permissions

# Run as specific subagent
claude --agent code-reviewer

# Define inline subagents for this session
claude --agents '{
  "architect": {
    "description": "System design expert",
    "prompt": "You are an architect...",
    "tools": ["Read", "Grep", "Glob"]
  }
}'

# Verbose mode for debugging hooks
claude --debug

# Non-interactive mode (for CI)
claude -p "Run tests" --output-format json
```

---

## 11. Common Pitfalls & Solutions

| Problem | Cause | Solution |
|---------|-------|----------|
| Claude ignores CLAUDE.md rules | File too long (>200 lines) | Prune ruthlessly. Delete rules Claude already follows |
| Context fills too fast | Kitchen-sink session (unrelated tasks) | `/clear` between unrelated work. One goal per session |
| Correcting Claude repeatedly | Vague initial prompt | Provide specific files/constraints upfront or `/clear` and reprompt precisely |
| Tests keep failing | Missing test framework setup | Add `npm test` command to CLAUDE.md with exact syntax |
| Hooks not firing | Matcher pattern mismatch | Check matcher regex is exact (matchers are case-sensitive). Run `/hooks` to verify |
| MCP tools won't start | Timeout or permission error | Check `MCP_TIMEOUT=10000 claude` or verify env vars with `claude mcp get <name>` |
| Subagent outputs too verbose | Subagent exploring too much | Ask it to report concisely: "Run the tests and report ONLY failures" |

---

## 12. March 2026 Feature Updates

### 1 Million Token Context Window

- Available by default with Opus 4.6
- Change workflow: Longer sessions viable, context discipline still matters
- Use case: Entire small projects in one session
- Caution: 1M tokens is not "dump everything"—organize by task

### Voice Mode (`/voice`)

- Push-to-talk: Hold spacebar and speak
- Replies with synthesized audio
- Useful for: Hands-free navigation, quick questions
- Not ideal for: Complex code discussions

### Recurring Tasks with `/loop`

Schedule Claude Code to run automatically:

```bash
claude /loop "npm test && npm run build" --every 1h
# Runs every hour, reports results in Slack if configured
```

### Improved MCP Tool Search

- Dynamically loads MCP tools on demand
- Saves ~55,000 tokens with 5 MCP servers
- Automatic when MCP tools exceed 10% of context
- Configure: `ENABLE_TOOL_SEARCH=auto:5` (5% threshold)

### Agent Teams (Experimental)

Orchestrate multiple Claude Code sessions with shared task queue and inter-agent messaging.

```bash
claude --agent-teams
# One session acts as coordinator
# Teammates work in parallel with full context windows
```

---

## Quick Reference: Command Cheatsheet

```bash
# Session management
claude                              # Start new session
claude --continue                   # Resume last session
claude --resume                     # Choose from recent sessions
claude --rename "my-session"        # Rename session

# Mode control
claude /plan                        # Enter plan mode
claude /clear                       # Reset context
claude /compact "focus on X"        # Manually compact
claude /cost                        # Show token usage
claude /hooks                       # Browse configured hooks

# Subagents & Teams
claude /agents                      # Manage agents
claude --agent code-reviewer        # Run as subagent
claude --agent-teams               # Coordinate teams
claude --agents '{"name": {...}}'  # Define inline agent

# MCP Management
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
claude mcp list                     # List servers
claude mcp get github               # Get server details
claude mcp remove github            # Remove server
claude /mcp                         # Auth / status (in session)

# Configuration
claude --model opus-4-6             # Use specific model
claude --dangerously-skip-permissions  # Skip prompts
claude --debug                      # Verbose logging
claude -p "prompt"                  # Non-interactive mode

# Skills & Plugins
claude /skill-name arg1 arg2        # Run a skill
claude /plugin search keyword       # Find plugins
claude /reload-plugins              # Reconnect plugin MCPs
```

---

## Sources

- [Claude Code Official Documentation](https://code.claude.com/docs)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Plan Mode Guide](https://code.claude.com/docs/en/common-workflows)
- [Hooks System Reference](https://code.claude.com/docs/en/hooks-guide)
- [MCP Configuration](https://code.claude.com/docs/en/mcp)
- [Subagents Reference](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Interactive Mode & Shortcuts](https://code.claude.com/docs/en/interactive-mode)
- [Ultimate Claude Code Guide (GitHub)](https://github.com/FlorianBruniaux/claude-code-ultimate-guide)
- [Awesome Claude Code (GitHub)](https://github.com/hesreallyhim/awesome-claude-code)
- [TDD with Claude Code](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/workflows/tdd-with-claude.md)
- [Spec-Driven Development](https://github.com/Pimzino/claude-code-spec-workflow)
- [Claude Code Hooks Mastery (GitHub)](https://github.com/disler/claude-code-hooks-mastery)
- [MCP Registry](https://api.anthropic.com/mcp-registry/docs)
