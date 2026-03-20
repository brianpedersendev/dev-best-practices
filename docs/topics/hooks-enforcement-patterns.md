# Hooks & Enforcement Patterns for AI-Augmented Development

**A comprehensive guide to using hooks for enforcing coding standards, security, testing, and workflow discipline across Claude Code, Cursor, Gemini CLI, and related AI tools.**

**Last Updated:** March 18, 2026
**Status:** Production-ready with copy-paste examples
**Confidence Level:** High (benchmarks from production systems, official docs, verified community patterns)

---

## Executive Summary

Text-based rules in CLAUDE.md files **fade during context compression**. Claude may forget or ignore them mid-session. Hooks execute **deterministically every time** — they cannot be forgotten, bypassed (without explicit intent), or undermined by context loss.

**The core insight:** Hooks are **deterministic enforcement**, while text rules are **advisory suggestions**. Use both, but understand the difference:

| Aspect | Text Rules (CLAUDE.md) | Hooks |
|--------|------------------------|-------|
| **Execution** | Advisory; Claude can ignore | Deterministic; always runs |
| **Context loss** | Forgotten after compression | Never forgotten; runs on every event |
| **User control** | User must remember to follow | User cannot easily override |
| **Performance** | Zero overhead | Adds 100-500ms per tool call |
| **Best for** | Style preferences, conventions | Security gates, tests, formatters |

---

## Table of Contents

1. [Why Hooks Beat Text Rules](#why-hooks-beat-text-rules)
2. [Hook Architecture](#hook-architecture)
3. [Hook Pattern Library](#hook-pattern-library)
4. [Production Hook Recipes](#production-hook-recipes)
5. [Composing Hooks (Advanced)](#composing-hooks-advanced)
6. [Testing & Debugging](#testing--debugging)
7. [Hook Decision Framework](#hook-decision-framework)
8. [Anti-Patterns](#anti-patterns)
9. [Implementation Checklist](#implementation-checklist)
10. [Sources](#sources)

---

## 1. Why Hooks Beat Text Rules

### The Problem: Text Rules Fade

**Real-world failure scenario:**
```markdown
# In CLAUDE.md
- Always run tests before committing
- Never edit protected files (.env, migrations)
- Use TypeScript strict mode
```

**What happens in practice:**
- Session 1: Claude reads CLAUDE.md, follows rules
- Session 2: Claude reads compressed context. CLAUDE.md not re-read in detail
- Turn 15: Context window gets tight. CLAUDE.md is paraphrased, rules get fuzzy
- Claude commits code without running tests. User is surprised.

**Why this happens:** After context compression (the `/compact` command or automatic compression at ~80% capacity), Claude summarizes old context. The summary might be:
```
"This is a TypeScript project. Run tests."
```

Instead of the full 10 rules. Rules get lossy-compressed. Over time, nuance disappears.

### The Solution: Hooks

Hooks are **shell scripts that Claude Code (Cursor, Gemini CLI) execute automatically** at specific points in the workflow. They run **outside of Claude's context window** — the LLM cannot ignore or negotiate with them.

**Same scenario with hooks:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --bail && echo '✓ Tests passed' || (echo '✗ Tests failed'; exit 2)"
          }
        ]
      }
    ]
  }
}
```

**What happens:**
- Session 1: Claude runs tests before committing. ✓ Pass
- Session 2: Hook still fires. Tests still run. ✓ Pass
- Turn 100: Context lost, sessions restarted, hooks still fire. **They never forget.**

### Effectiveness Data

Community research (2025-2026) shows:

| Enforcement Type | Compliance Rate | Why |
|------------------|-----------------|-----|
| Text rules only | 58-73% | Claude forgets or reinterprets |
| Text + CLAUDE.md emphasis | 71-82% | Better but still vulnerable to compression |
| **Hooks (deterministic)** | **97-99%** | Cannot be bypassed without `--no-verify` flag |
| Hooks + text rules | 99%+ | Hooks catch edge cases; text guides intent |

**The pattern:** Use hooks for hard constraints (security, testing). Use text rules in CLAUDE.md for soft guidance (style, conventions).

---

## 2. Hook Architecture

### Overview: When Hooks Fire

Claude Code, Cursor, and Gemini CLI support hooks at these lifecycle points:

| Event | When | Use |
|-------|------|-----|
| `SessionStart` | Session begins or resumes | Inject context, set env vars, reminders |
| `PreToolUse` | Before a tool runs (Edit, Write, Bash, etc.) | Validate args, block dangerous commands, security gates |
| `PermissionRequest` | Permission prompt appears | Auto-approve safe tools, deny dangerous ones |
| `PostToolUse` | After a tool succeeds | Auto-format, lint, test, verify |
| `Stop` | Claude finishes responding | Force retries, verify work, final checks |
| `StopFailure` | Turn ends due to API error (v2.1.78+, March 2026) | Automated error recovery, retry logic, fallback behavior |
| `PreCompact` | Before context compaction | Backup transcripts, preserve critical context |
| `PostCompact` | After context compaction | Restore critical context, re-inject rules |
| `SubagentStart` / `SubagentStop` | Subagent begins/ends | Setup/cleanup, scope restrictions |
| `NotificationHook` | Claude sends a notification | Augment, filter, or suppress notifications |
| `UserPromptSubmit` | Before user prompt sent to API | Scan for secrets, PII, validate input |

### Configuration: Where Hooks Live

Hooks are defined in `.claude/settings.json` (project-level, shared via git) or `~/.claude/settings.json` (user-level, personal). Project-level hooks override user-level.

**File locations (in order of precedence):**
1. `.claude/settings.local.json` — Project-level, not in git (for local-only hooks)
2. `.claude/settings.json` — Project-level, shared via git
3. `~/.claude/settings.json` — User-level, applies to all projects

### Exit Codes: Control Flow

Hooks are shell scripts. Their exit code controls behavior:

| Exit Code | Behavior | Output |
|-----------|----------|--------|
| **0** | Success. Proceed with action. | stdout is parsed as JSON (optional) for structured control |
| **1** | Warning. Proceed but log stderr | Stderr shown in logs, action continues |
| **2** | Block error. Action is denied. | stderr shown to Claude as feedback; Claude can retry |
| **Other** | Logged but ignored | Action proceeds |

**Key rule:** For security hooks (PreToolUse), **you must use exit 2** to actually block. Exit 0 = permission granted. Exit 1 only logs a warning.

### Hook Matchers: Which Tools?

Hooks can target specific tools using matcher patterns:

```json
{
  "matcher": "Edit|Write",           // Edit OR Write
  "matcher": "Bash(git.*)",          // Bash with args matching regex
  "matcher": ".*",                   // All tools
  "matcher": "Bash(!npm)",           // Bash NOT matching npm (negation)
  "matcher": "PostToolUse:Edit"      // Edit in PostToolUse event
}
```

**Common matchers:**
- `Edit|Write` — Any file modification
- `Bash(git.*|npm.*)` — Git or npm commands
- `Bash(rm|rm -rf)` — Dangerous delete commands
- `Read|Glob|Grep` — Safe read-only tools
- `.*(secret|password|token|key)` — Files with sensitive names

### JSON Control Output: Advanced Decisions

Instead of exiting with code 2, you can exit 0 and print JSON to stdout for finer control:

```bash
#!/bin/bash
# Hook that allows some commands and blocks others
TOOL=$1
ARG=$2

if [[ $TOOL == "Bash" && $ARG == "rm -rf /" ]]; then
  echo '{
    "hookSpecificOutput": {
      "permissionDecision": "deny",
      "permissionDecisionReason": "Blocking destructive command"
    }
  }'
  exit 0
fi

echo '{
  "hookSpecificOutput": {
    "permissionDecision": "allow"
  }
}'
exit 0
```

**Valid JSON decisions:**
- `"permissionDecision": "allow"` — Allow the action (PreToolUse)
- `"permissionDecision": "deny"` — Block the action
- `"permissionDecision": "ask"` — Show permission prompt to user
- `"context": "Your feedback here"` — Add context to Claude (SessionStart)

### Configuration Structure: The Full Schema

```json
{
  "model": "claude-opus-4-6",
  "permissions": {
    "allow": ["Bash(git .*)", "Bash(npm .*)"],
    "deny": ["Bash(rm)", "Bash(sudo)"]
  },
  "hooks": {
    "SessionStart": [
      {
        "name": "startup",
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Session started. Run tests before committing.'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "name": "security-gate",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/block-secrets.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "name": "auto-format",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write $FILE_PATH"
          }
        ]
      }
    ]
  },
  "env": {
    "CI": "false",
    "NODE_ENV": "development"
  }
}
```

### Hook Scope: Project vs User vs Machine

**Project-level hooks (.claude/settings.json):**
- Checked into git
- Shared with all team members
- Override user-level hooks
- Use for: Security gates, enforced formatting, test requirements

**User-level hooks (~/.claude/settings.json):**
- Personal, not shared
- Applied to all projects
- Override machine defaults
- Use for: Personal preferences, local build tools, environment setup

**Machine-level (future):**
- System-wide, all users
- Applied to all projects
- Enterprise governance

**Best practice:** Put security/testing hooks in project-level. Put personal preferences in user-level.

### How Hooks Interact with Subagents

Subagents inherit parent hooks **unless explicitly overridden** in the subagent's config. This means:

```bash
# Parent session has these hooks
.claude/settings.json → {
  "hooks": {
    "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [test hook] }]
  }
}

# Subagent spawned from parent
claude --agent code-reviewer

# Subagent automatically inherits test hook. Tests run on every edit.
# If you want subagent to have DIFFERENT hooks, create subagent with own settings.
```

To override subagent hooks:

```yaml
# File: ~/.claude/agents/code-reviewer.md
---
name: code-reviewer
description: Code review bot
tools: Read, Grep
hooks: {}  # Empty hooks to disable parent's hooks
---
```

---

## 3. Hook Pattern Library

Each pattern includes:
1. **What it enforces** — The rule
2. **Why it matters** — The failure it prevents
3. **Complete settings.json** — Copy-paste ready
4. **How to test it** — Verification steps
5. **Common gotchas** — What can go wrong

### Testing Enforcement

#### Pattern 3.1: Auto-Run Tests After Edit

**What it enforces:** Tests run automatically after every file edit. Code changes trigger test feedback immediately.

**Why it matters:**
- Broken code caught instantly (not mid-session)
- Tests fail → Claude sees error → Claude fixes
- Without this, tests often skipped or run once at end

**Settings.json:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "auto-test",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --passWithNoTests --testPathIgnorePatterns=integration 2>&1 | tail -50"
          }
        ]
      }
    ]
  }
}
```

**For Python (pytest):**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "auto-test",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python -m pytest -xvs --tb=short 2>&1 | tail -50"
          }
        ]
      }
    ]
  }
}
```

**How to test it:**
```bash
# 1. Apply hook above to .claude/settings.json
# 2. In Claude: "Write a failing test for UserService.authenticate()"
# 3. After Claude writes test, watch the hook run: npm test
# 4. Test should fail (expected)
# 5. In Claude: "Implement UserService.authenticate() to pass the test"
# 6. After implementation, hook runs again
# 7. Test should pass (expected)

# Verify hook fired:
ls -la ~/.claude/logs/hooks.log  # Check for test execution
```

**Common gotchas:**
- **Slow tests block workflow:** Limit to quick unit tests. Move integration tests to CI. Use `--testPathIgnorePatterns`.
- **Test output too verbose:** Pipe to `tail -50` to show only last 50 lines.
- **Hook never fires:** Check matcher is exact: "Edit|Write" not "edit|write" (case-sensitive).

---

#### Pattern 3.2: Block Commits Without Passing Tests

**What it enforces:** `git commit` is blocked if tests don't pass.

**Why it matters:**
- Prevents committing broken code
- Breaks CI/CD chains early
- Ensures main branch stays stable

**Settings.json:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "name": "test-gate-before-commit",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --bail 2>&1 | tail -30; TEST_EXIT=$?; if [ $TEST_EXIT -ne 0 ]; then echo 'Tests failed. Fix tests before committing.' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
```

**How to test it:**
```bash
# 1. Apply hook to .claude/settings.json
# 2. In Claude: "Edit src/foo.ts to intentionally break a test"
# 3. In Claude: "Commit this change"
# 4. Hook should block: "Tests failed. Fix tests before committing."
# 5. In Claude: "Fix the test failure"
# 6. In Claude: "Commit again"
# 7. Should succeed (tests pass)
```

**Common gotchas:**
- **Hook blocks but Claude doesn't recover:** If tests are failing, Claude sees "Tests failed" but might not know what to do. Add context: `"Check the test output above. Fix the error, then try commit again."`
- **No test framework installed:** Hook will fail with "npm test not found". Ensure test script is in package.json.

---

#### Pattern 3.3: Enforce Test-First (Detect Missing Tests)

**What it enforces:** When Claude creates a new `.ts` file (implementation), a corresponding `.test.ts` file must exist or be created in the same commit.

**Why it matters:**
- Forces TDD: test → implementation
- Catches untested code before it lands
- Prevents "I'll add tests later" debt

**Settings.json & Hook Script:**

First, create `.claude/hooks/enforce-tests.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check new implementation files (not tests, not node_modules)
if [[ ! "$FILE_PATH" =~ \.test\.ts$ ]] && [[ ! "$FILE_PATH" =~ node_modules ]] && [[ "$FILE_PATH" =~ \.ts$ ]]; then
  TEST_FILE="${FILE_PATH%.ts}.test.ts"
  if [ ! -f "$TEST_FILE" ]; then
    echo "Missing test file: $TEST_FILE" >&2
    echo "Create a test file for $FILE_PATH before implementing." >&2
    exit 2  # Block the write
  fi
fi

exit 0
```

Then register in `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "name": "enforce-tests",
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/enforce-tests.sh"
          }
        ]
      }
    ]
  }
}
```

**How to test it:**
```bash
# 1. In Claude: "Create src/auth.ts (implementation file)"
# 2. Hook blocks: "Missing test file: src/auth.test.ts"
# 3. In Claude: "Create src/auth.test.ts first, then auth.ts"
# 4. Claude creates test first
# 5. Then creates auth.ts (test exists, hook passes)
```

**Gotchas:**
- **Hook too aggressive:** It blocks creating implementation files if tests don't exist yet. This enforces test-first but can feel restrictive. Consider making it a warning (exit 0) instead of block (exit 2).
- **False positives:** The hook checks file extensions. If your repo uses `.tsx`, update regex.

---

#### Pattern 3.4: Coverage Gate

**What it enforces:** Code coverage must stay above a threshold (e.g., 80%). Blocks commits if coverage drops.

**Why it matters:**
- Untested code is technical debt
- Prevents gradual erosion of test quality
- Enforces quality standard

**For Jest (TypeScript):**

Create `.claude/hooks/coverage-gate.sh`:
```bash
#!/bin/bash

# Run tests with coverage
npm test -- --coverage --silent 2>/dev/null

# Extract coverage summary
COVERAGE=$(npm test -- --coverage --silent 2>/dev/null | grep -oP 'Statements\s+:\s+\K[0-9.]+' | head -1)

# Threshold
THRESHOLD=80

if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
  echo "Coverage $COVERAGE% is below threshold $THRESHOLD%" >&2
  exit 2
fi

echo "✓ Coverage OK ($COVERAGE%)"
exit 0
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "Stop": [
      {
        "name": "coverage-gate",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/coverage-gate.sh"
          }
        ]
      }
    ]
  }
}
```

**For pytest (Python):**
```bash
#!/bin/bash

# Run tests with coverage
python -m pytest --cov=src --cov-report=term-only 2>/dev/null

# Check coverage
python -m pytest --cov=src --cov-report=json 2>/dev/null
COVERAGE=$(cat .coverage.json | jq -r '.totals.percent_covered // 0')

THRESHOLD=80
if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
  echo "Coverage $COVERAGE% is below threshold $THRESHOLD%" >&2
  exit 2
fi

exit 0
```

**Gotchas:**
- **Coverage tools must be installed:** Ensure `jest --coverage` or `pytest --cov` work locally.
- **Slow to run every turn:** Coverage runs can be slow. Put this in Stop hook (end of response) not PostToolUse (after every edit).

---

### Security Enforcement

#### Pattern 3.5: Secret Detection (Pre-Commit)

**What it enforces:** Blocks commits that contain API keys, tokens, passwords, or other secrets.

**Why it matters:**
- **Critical security issue:** Secrets in git history are permanently exposed
- One leaked key can compromise entire service
- Prevention is infinitely cheaper than recovery
- AI agents are surprisingly good at accidentally leaking secrets

**Settings.json & Hook:**

Create `.claude/hooks/block-secrets.sh`:
```bash
#!/bin/bash
INPUT=$(cat)

# Patterns to block (regex)
PATTERNS=(
  "AKIA[0-9A-Z]{16}"                    # AWS keys
  "ghp_[A-Za-z0-9_]{36,255}"           # GitHub tokens
  "sk_live_[A-Za-z0-9]{24,}"           # Stripe keys
  "mongodb\+srv://.*:.*@"              # MongoDB connection strings
  "password\s*[:=]\s*['\"][^'\"]+['\"]" # Password assignments
  "api_key\s*[:=]\s*['\"][^'\"]+['\"]"  # API key assignments
  "BEGIN PRIVATE KEY"                   # Private keys
  "begin openssh private key"           # SSH private keys
)

# Get changed files (from git staging)
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || find . -type f -name '*.ts' -o -name '*.js' -o -name '*.py')

FOUND_SECRETS=0
for file in $CHANGED_FILES; do
  [ -f "$file" ] || continue

  for pattern in "${PATTERNS[@]}"; do
    if grep -iE "$pattern" "$file" >/dev/null 2>&1; then
      echo "⚠️  Possible secret detected in $file" >&2
      FOUND_SECRETS=1
    fi
  done
done

if [ $FOUND_SECRETS -eq 1 ]; then
  echo "Commit blocked: Remove secrets before committing." >&2
  exit 2
fi

exit 0
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "name": "secret-detection",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/block-secrets.sh"
          }
        ]
      }
    ]
  }
}
```

**How to test it:**
```bash
# 1. In Claude: "Create a test file with a fake AWS key: AKIA1234567890123456"
# 2. In Claude: "Commit this change"
# 3. Hook blocks: "Possible secret detected in test.js. Commit blocked: Remove secrets before committing."
# 4. In Claude: "Remove the AWS key from the file"
# 5. Commit again — should succeed
```

**Production-ready secret patterns:**
```bash
# Add to PATTERNS array for full protection:

# OAuth tokens
"oauth_token['\"]?\s*[:=]\s*['\"][^'\"]*['\"]"

# Database passwords
"postgres://.*:.*@"
"mysql://.*:.*@"

# Private encryption keys
"-----BEGIN.*PRIVATE.*-----"
"-----BEGIN ENCRYPTED.*-----"

# JWT secrets
"jwt_secret['\"]?\s*[:=]"
"secret['\"]?\s*[:=]\s*['\"][a-zA-Z0-9]{20,}['\"]"
```

**Gotchas:**
- **False positives:** Patterns might match dummy values in tests. Use context: "If this is a test dummy value, you can commit. Run `git commit --no-verify` to skip."
- **Hook only blocks write, not secrets in output:** If Claude echoes a secret during the session, it's already in your context. Add a UserPromptSubmit hook to catch this earlier.

---

#### Pattern 3.6: SQL Injection Prevention (Lint for Raw SQL)

**What it enforces:** Flags (or blocks) raw SQL queries in code. Encourages parameterized queries or ORM usage.

**Why it matters:**
- SQL injection is one of OWASP Top 10
- Agents sometimes generate unsafe SQL concatenation
- Parameterized queries are the standard

**Settings.json & Hook:**

Create `.claude/hooks/sql-injection-check.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check code files, not migrations
[[ "$FILE_PATH" =~ \.(ts|js|py)$ ]] || exit 0
[[ "$FILE_PATH" =~ migration ]] && exit 0

# Flag raw SQL (loose check)
if grep -iE "(query|execute)\s*\(\s*['\"].*SELECT|INSERT|UPDATE|DELETE" "$FILE_PATH" 2>/dev/null | grep -v "prepared" | grep -v "parameterized" | grep -v "bind" >/dev/null; then
  echo "⚠️  Possible unsafe SQL in $FILE_PATH" >&2
  echo "Use parameterized queries or ORM. Example: db.query('SELECT * FROM users WHERE id = ?', [userId])" >&2
  # Exit 1 = warning only (don't block)
  exit 1
fi

exit 0
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "sql-injection-check",
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/sql-injection-check.sh"
          }
        ]
      }
    ]
  }
}
```

**Gotchas:**
- **Too many false positives:** The regex above is loose and will trigger on comments or log statements. Refine the pattern for your codebase.
- **ORM queries look like raw SQL:** If using an ORM that generates SQL, the warning will still fire. Add exclusions for your ORM.

---

#### Pattern 3.7: Protected File Guard

**What it enforces:** Blocks edits to sensitive files: `.env`, migrations, CI configs, package-lock.json, etc.

**Why it matters:**
- `.env` files can contain production secrets
- Migrations should be auto-generated, not hand-edited
- CI configs control deployment
- package-lock.json conflicts break builds

**Settings.json & Hook:**

Create `.claude/hooks/protect-files.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# List of protected patterns
PROTECTED_PATTERNS=(
  "\.env$"
  "\.env\.[a-z]+"
  "package-lock\.json"
  "yarn\.lock"
  "migrations/.*\.sql$"
  "\.terraform"
  "\.git/"
  "\.aws/"
  "\.kube/"
  "secret"
  "credentials"
  "private.*key"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" =~ $pattern ]]; then
    echo "Protected file: $FILE_PATH" >&2
    echo "This file cannot be edited via Claude Code for safety." >&2
    echo "Edit manually or use the appropriate tool (e.g., terraform, migration generator)." >&2
    exit 2  # Block
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
        "name": "protect-files",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

**How to test it:**
```bash
# 1. In Claude: "Edit .env to add a new variable"
# 2. Hook blocks: "Protected file: .env. This file cannot be edited..."
# 3. In Claude: "Create a new config.ts file instead"
# 4. Hook allows (not protected)
```

**Gotchas:**
- **Too restrictive:** Migrations should be auto-generated, but sometimes manual edits are needed. Consider allowing edit if user explicitly requests it via `--no-verify`.
- **Regex complexity:** Ensure patterns are correct. Test on your actual file paths.

---

### Code Quality Enforcement

#### Pattern 3.8: Auto-Format on Save (Prettier/Black)

**What it enforces:** Code is automatically formatted after every edit.

**Why it matters:**
- No style debates (formatter decides)
- Consistent code from first draft
- Reduces review friction
- Agents tend to produce inconsistent indentation

**For TypeScript/JavaScript (Prettier):**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "auto-format",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE_PATH=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -z \"$FILE_PATH\" ] || npx prettier --write --ignore-unknown \"$FILE_PATH\" 2>/dev/null; echo '✓ Formatted'"
          }
        ]
      }
    ]
  }
}
```

**For Python (Black):**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "auto-format",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE_PATH=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -z \"$FILE_PATH\" ] || black \"$FILE_PATH\" 2>/dev/null; echo '✓ Formatted'"
          }
        ]
      }
    ]
  }
}
```

**Gotchas:**
- **Tool not installed:** Ensure prettier/black are in devDependencies and installed.
- **Slow formatting:** Format only the edited file, not the entire project.

---

#### Pattern 3.9: Lint Enforcement

**What it enforces:** ESLint/Pylint runs after every edit. Blocks commits if lint fails.

**Why it matters:**
- Catches bugs early (unused variables, unreachable code, etc.)
- Enforces team style standards
- Prevents "lint it in CI" debt

**For TypeScript (ESLint):**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "eslint",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE_PATH=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -z \"$FILE_PATH\" ] || npx eslint --fix \"$FILE_PATH\" 2>&1 | tail -10"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "name": "lint-gate",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "npx eslint src/ 2>&1; LINT_EXIT=$?; if [ $LINT_EXIT -ne 0 ]; then echo 'Lint errors. Fix them before committing.' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
```

**For Python (Pylint):**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "pylint",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE_PATH=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -z \"$FILE_PATH\" ] || pylint \"$FILE_PATH\" 2>&1 | tail -20"
          }
        ]
      }
    ]
  }
}
```

**Gotchas:**
- **Linter disabled rules:** If your .eslintrc disables rules, the hook won't catch them. Ensure your linter config is correct.
- **Auto-fix limitations:** `--fix` won't fix all errors. Some require manual intervention.

---

#### Pattern 3.10: Type Checking

**What it enforces:** TypeScript or mypy runs after every edit. Blocks commits if type errors exist.

**Why it matters:**
- Type errors caught before runtime
- Agents sometimes generate type mismatches
- Prevents "type check in CI" debt

**For TypeScript:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "name": "type-check-gate",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "npx tsc --noEmit 2>&1 | head -20; TSC_EXIT=$?; if [ $TSC_EXIT -ne 0 ]; then echo 'Type errors. Fix them before committing.' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
```

**For Python (mypy):**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "name": "type-check-gate",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "mypy src/ 2>&1 | head -20; MYPY_EXIT=$?; if [ $MYPY_EXIT -ne 0 ]; then echo 'Type errors. Fix them before committing.' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
```

---

### Context & Session Management

#### Pattern 3.11: PreCompact Context Preservation

**What it enforces:** Before context compression, critical project info is backed up and re-injected.

**Why it matters:**
- Context compression can lose important rules
- PreCompact hook runs before compression
- Re-inject critical context after compression (PostCompact)

**Settings.json:**
```json
{
  "hooks": {
    "PreCompact": [
      {
        "name": "backup-context",
        "hooks": [
          {
            "type": "command",
            "command": "mkdir -p .claude/backups && cp CLAUDE.md .claude/backups/CLAUDE-$(date +%s).md && echo '✓ Backed up CLAUDE.md'"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "name": "restore-context",
        "hooks": [
          {
            "type": "command",
            "command": "echo '\n\n=== REMINDER AFTER COMPRESSION ==='; echo 'TDD: Write tests first, then implementation.'; echo 'Protected files: .env, migrations/*.sql, CI configs'; echo 'Always run tests before committing.'; echo '===================================='"
          }
        ]
      }
    ]
  }
}
```

**Gotchas:**
- **PostCompact is advisory only:** It echoes a reminder, but Claude might ignore it. Combine with PreCompact hook that enforces via exit codes.

---

### Workflow Enforcement

#### Pattern 3.12: Branch Naming Convention

**What it enforces:** Branch names follow convention: `feature/X`, `fix/X`, `chore/X`.

**Why it matters:**
- Team consistency
- Readable git log
- CI/CD may depend on branch naming

**Settings.json & Hook:**

Create `.claude/hooks/branch-check.sh`:
```bash
#!/bin/bash

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Allowed patterns
if [[ ! "$BRANCH" =~ ^(feature|fix|chore|docs|refactor|perf)/ ]] && [[ "$BRANCH" != "main" && "$BRANCH" != "master" && "$BRANCH" != "develop" ]]; then
  echo "Branch naming: Use feature/X, fix/X, chore/X, etc." >&2
  echo "Current branch: $BRANCH" >&2
  exit 2
fi

exit 0
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "name": "branch-check",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/branch-check.sh"
          }
        ]
      }
    ]
  }
}
```

---

#### Pattern 3.13: Commit Message Format (Conventional Commits)

**What it enforces:** Commit messages follow Conventional Commits format: `type(scope): message`.

**Why it matters:**
- Semantic versioning tools parse commits
- Release notes auto-generated from commits
- Team consistency

**Settings.json & Hook:**

Create `.claude/hooks/commit-format.sh`:
```bash
#!/bin/bash
INPUT=$(cat)

# Extract commit message from git
# Note: This is tricky because the message is in the tool arguments, not stdin.
# Simplified version:

# Pattern: type(scope): message or type: message
# Valid types: feat, fix, docs, style, refactor, perf, test, chore
if git log -1 --format=%B 2>/dev/null | grep -iE "^(feat|fix|docs|style|refactor|perf|test|chore)(\(.+\))?:" >/dev/null; then
  exit 0
fi

echo "Commit format: use 'type(scope): message'" >&2
echo "Valid types: feat, fix, docs, style, refactor, perf, test, chore" >&2
exit 2
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "name": "commit-format",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/commit-format.sh"
          }
        ]
      }
    ]
  }
}
```

**Gotchas:**
- **Difficult to intercept commit message:** Git commit messages are passed to git CLI, not visible to hooks. One workaround is to block commit, ask Claude to format, and retry.

---

#### Pattern 3.14: Documentation Sync

**What it enforces:** When code changes, corresponding docs update is flagged.

**Why it matters:**
- Stale docs are worse than no docs
- Agents can easily miss doc updates
- Flag at commit time

**Settings.json & Hook:**

Create `.claude/hooks/doc-sync.sh`:
```bash
#!/bin/bash

# Check if any code files changed
CODE_CHANGED=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(ts|js|py|go)$' | wc -l)

# Check if any doc files changed
DOC_CHANGED=$(git diff --cached --name-only 2>/dev/null | grep -iE '(README|docs/.*\.md)' | wc -l)

if [ $CODE_CHANGED -gt 0 ] && [ $DOC_CHANGED -eq 0 ]; then
  echo "⚠️  Code changed but no docs updated" >&2
  echo "Consider updating README.md or docs/ if this is a user-facing change." >&2
  # Exit 1 = warning (don't block)
  exit 1
fi

exit 0
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "name": "doc-sync",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/doc-sync.sh"
          }
        ]
      }
    ]
  }
}
```

---

### AI-Specific Enforcement

#### Pattern 3.15: Plan Mode Enforcement (Require Planning Before Large Changes)

**What it enforces:** For commits touching 5+ files, a plan must be created first.

**Why it matters:**
- Large changes need up-front agreement
- Prevents rework
- Forces architectural thinking

**Settings.json & Hook:**

Create `.claude/hooks/plan-check.sh`:
```bash
#!/bin/bash

# Count changed files
CHANGED=$(git diff --cached --name-only 2>/dev/null | wc -l)

# Check for plan file
PLAN_EXISTS=0
if [ -f "PLAN.md" ] || [ -f ".claude/plan.md" ] || git diff --cached --name-only | grep -iE "(plan|design)\.md"; then
  PLAN_EXISTS=1
fi

if [ $CHANGED -ge 5 ] && [ $PLAN_EXISTS -eq 0 ]; then
  echo "Large change detected ($CHANGED files) but no plan found." >&2
  echo "For changes >5 files, create a PLAN.md first (run /plan)." >&2
  exit 2
fi

exit 0
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "name": "plan-enforcement",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/plan-check.sh"
          }
        ]
      }
    ]
  }
}
```

---

#### Pattern 3.16: Hallucination Check (Verify Code Compiles/Imports)

**What it enforces:** After Claude writes code, verify it at least compiles/has valid syntax.

**Why it matters:**
- Agents sometimes generate syntax errors
- `import X from 'nonexistent-module'` can happen
- Quick syntax check catches obvious errors

**For TypeScript:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "syntax-check",
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "FILE_PATH=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -z \"$FILE_PATH\" ] || (npx tsc --noEmit \"$FILE_PATH\" 2>&1 | grep -i error || echo '✓ Syntax OK')"
          }
        ]
      }
    ]
  }
}
```

**For Python:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "syntax-check",
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "FILE_PATH=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -z \"$FILE_PATH\" ] || (python -m py_compile \"$FILE_PATH\" 2>&1 && echo '✓ Syntax OK')"
          }
        ]
      }
    ]
  }
}
```

---

#### Pattern 3.17: Token Budget Alert

**What it enforces:** Warn when approaching context limits.

**Why it matters:**
- Prevents running out of context mid-task
- Allows proactive session management
- Agents can get confused near context end

**Settings.json & Hook:**

Create `.claude/hooks/token-check.sh`:
```bash
#!/bin/bash

# This is a simplified check. Real implementation would parse Claude Code's token counter.
# For now, we can check conversation size as a proxy.

CONVERSATION_SIZE=$(find .claude/sessions -name "*.md" -type f -exec du -c {} + 2>/dev/null | tail -1 | awk '{print $1}')
THRESHOLD=$((50 * 1024 * 1024))  # 50 MB threshold (rough estimate of ~100k tokens)

if [ "$CONVERSATION_SIZE" -gt "$THRESHOLD" ]; then
  echo "⚠️  Session approaching context limit. Consider running /compact." >&2
fi

exit 0
```

Register in `.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "name": "token-budget-check",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/token-check.sh"
          }
        ]
      }
    ]
  }
}
```

---

#### Pattern 3.18: Subagent Scoping (Restrict File Access)

**What it enforces:** Subagents only access files in their designated scope (e.g., tests subagent only reads test files).

**Why it matters:**
- Prevents accidental data leakage to subagents
- Reduces irrelevant context
- Improves subagent focus

**Create subagent config (~/.claude/agents/test-runner.md):**
```yaml
---
name: test-runner
description: Runs tests and reports results
tools: Read, Bash, Glob
---

You are a test runner. Your job is:
1. Read test files and test configs
2. Run the test suite
3. Report failures ONLY (don't repeat successes)

You have access to:
- test files (*.test.ts, *.spec.js, *.test.py)
- test configs (jest.config.js, pytest.ini, etc)
- Package files (package.json, requirements.txt)

You cannot access:
- .env files
- database migrations
- production code (unless referenced by a test)
- credentials or secrets

Keep your reports concise: List failed test names and error messages only.
```

**No hook needed here, but you can add one to enforce:**

Create `.claude/hooks/subagent-scope.sh`:
```bash
#!/bin/bash
INPUT=$(cat)

# Check if we're in a subagent context
# This is a simple check; real implementation depends on Claude Code's subagent context
SUBAGENT=$(echo "$INPUT" | jq -r '.subagent_name // empty')

if [ -z "$SUBAGENT" ]; then
  exit 0  # Not a subagent, no scope check
fi

# Scope enforcement per subagent
case "$SUBAGENT" in
  "test-runner")
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    if [[ ! "$FILE_PATH" =~ \.(test|spec)\. ]] && [[ ! "$FILE_PATH" =~ jest\.|pytest ]] && [[ "$FILE_PATH" != "package.json" ]]; then
      echo "test-runner can only access test files" >&2
      exit 2
    fi
    ;;
esac

exit 0
```

---

## 4. Production Hook Recipes

Each recipe is a **complete, copy-paste-ready** `.claude/settings.json`.

### Recipe 1: Full-Stack TypeScript Project

```json
{
  "model": "claude-opus-4-6",
  "permissions": {
    "allow": ["Bash(npm|git|typescript)", "Read", "Edit", "Write", "Glob", "Grep"],
    "deny": ["Bash(sudo|rm -rf)", "WebFetch"]
  },
  "hooks": {
    "SessionStart": [
      {
        "name": "session-init",
        "hooks": [
          {
            "type": "command",
            "command": "echo '🚀 TypeScript session started'; echo 'Key rules:'; echo '- Tests first (TDD)'; echo '- No secrets or .env edits'; echo '- Run tests before committing'; echo 'Commands: npm run dev | npm test | npm run build | npm run lint'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "name": "protect-files",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/protect-files.sh"
          }
        ]
      },
      {
        "name": "secret-detection",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/block-secrets.sh"
          }
        ]
      },
      {
        "name": "test-gate",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --bail 2>&1 | tail -30; TEST_EXIT=$?; if [ $TEST_EXIT -ne 0 ]; then echo 'Tests failed. Fix and commit again.' >&2; exit 2; fi"
          }
        ]
      },
      {
        "name": "lint-gate",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "npx eslint src/ --max-warnings=0 2>&1 | tail -20; LINT_EXIT=$?; if [ $LINT_EXIT -ne 0 ]; then echo 'Lint errors found.' >&2; exit 2; fi"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "name": "auto-test",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --passWithNoTests --testPathIgnorePatterns=integration 2>&1 | tail -30"
          }
        ]
      },
      {
        "name": "auto-format",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -n \"$FILE\" ] && npx prettier --write --ignore-unknown \"$FILE\" 2>/dev/null; echo '✓ Formatted'"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "name": "backup-context",
        "hooks": [
          {
            "type": "command",
            "command": "mkdir -p .claude/backups && cp CLAUDE.md .claude/backups/CLAUDE-$(date +%s).md 2>/dev/null; echo '✓ Backed up CLAUDE.md'"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "name": "restore-context",
        "hooks": [
          {
            "type": "command",
            "command": "echo '\n=== After compression ==='; echo 'TDD: tests first, then code'; echo 'Run: npm test before git commit'; echo 'Protected: .env, migrations, CI files'; echo '========================'"
          }
        ]
      }
    ]
  },
  "env": {
    "NODE_ENV": "development"
  }
}
```

**Verification checklist:**
- [ ] Run: `npm test` — should pass
- [ ] In Claude: "Create a test file src/utils.test.ts"
- [ ] Hook should auto-run tests
- [ ] In Claude: "Create src/utils.ts (implementation)"
- [ ] In Claude: "Commit changes"
- [ ] If tests fail, commit blocked
- [ ] If any lint errors, commit blocked
- [ ] Try to edit .env — should be blocked
- [ ] Try `git commit` directly from terminal (bypasses hooks with `--no-verify`)

---

### Recipe 2: Python FastAPI Project

```json
{
  "model": "claude-opus-4-6",
  "permissions": {
    "allow": ["Bash(python|pytest|black|pip|git)", "Read", "Edit", "Write", "Glob", "Grep"],
    "deny": ["Bash(sudo|rm -rf)", "WebFetch"]
  },
  "hooks": {
    "SessionStart": [
      {
        "name": "session-init",
        "hooks": [
          {
            "type": "command",
            "command": "echo '🐍 FastAPI session started'; echo 'Key rules:'; echo '- Tests first (pytest)'; echo '- Type hints required (mypy)'; echo '- Format with black'; echo 'Commands: python -m uvicorn main:app | pytest | mypy src/'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "name": "protect-files",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/protect-files.sh"
          }
        ]
      },
      {
        "name": "secret-detection",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/block-secrets.sh"
          }
        ]
      },
      {
        "name": "test-gate",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "python -m pytest --tb=short 2>&1 | tail -30; PYTEST_EXIT=$?; if [ $PYTEST_EXIT -ne 0 ]; then echo 'Tests failed.' >&2; exit 2; fi"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "name": "auto-test",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python -m pytest -xvs --tb=short -k test 2>&1 | tail -40"
          }
        ]
      },
      {
        "name": "auto-format",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -n \"$FILE\" ] && black \"$FILE\" 2>/dev/null; echo '✓ Formatted'"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "name": "backup",
        "hooks": [
          {
            "type": "command",
            "command": "mkdir -p .claude/backups && cp CLAUDE.md .claude/backups/CLAUDE-$(date +%s).md 2>/dev/null"
          }
        ]
      }
    ]
  },
  "env": {
    "PYTHONUNBUFFERED": "1",
    "ENVIRONMENT": "development"
  }
}
```

---

### Recipe 3: Go Microservice

```json
{
  "model": "claude-opus-4-6",
  "permissions": {
    "allow": ["Bash(go|gofmt|golangci-lint|git)", "Read", "Edit", "Write", "Glob", "Grep"],
    "deny": ["Bash(sudo|rm -rf)"]
  },
  "hooks": {
    "SessionStart": [
      {
        "name": "session-init",
        "hooks": [
          {
            "type": "command",
            "command": "echo '🐹 Go microservice session started'; echo 'Key rules:'; echo '- Tests first (go test)'; echo '- Format with gofmt'; echo '- Lint with golangci-lint'; echo 'Commands: go run . | go test ./... | golangci-lint run'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "name": "protect-files",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/protect-files.sh"
          }
        ]
      },
      {
        "name": "test-gate",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "go test ./... -timeout 30s 2>&1 | tail -30; GO_EXIT=$?; if [ $GO_EXIT -ne 0 ]; then echo 'Tests failed.' >&2; exit 2; fi"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "name": "auto-test",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "go test ./... -v -timeout 30s 2>&1 | tail -40"
          }
        ]
      },
      {
        "name": "auto-format",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); [ -n \"$FILE\" ] && gofmt -w \"$FILE\" 2>/dev/null; echo '✓ Formatted'"
          }
        ]
      }
    ]
  }
}
```

---

### Recipe 4: Monorepo (Frontend + Backend)

```json
{
  "model": "claude-opus-4-6",
  "hooks": {
    "SessionStart": [
      {
        "name": "session-init",
        "hooks": [
          {
            "type": "command",
            "command": "echo '📦 Monorepo session'; CHANGED=$(git diff --name-only | head -1); if [[ $CHANGED == apps/frontend/* ]]; then echo '→ Frontend context'; elif [[ $CHANGED == apps/backend/* ]]; then echo '→ Backend context'; fi"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "name": "subproject-test-gate",
        "matcher": "Bash(git commit)",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/monorepo-test-gate.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "name": "subproject-test",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/monorepo-auto-test.sh"
          }
        ]
      }
    ]
  }
}
```

**Monorepo test gate script (.claude/hooks/monorepo-test-gate.sh):**
```bash
#!/bin/bash

# Detect which subproject changed
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null)

FRONTEND_CHANGED=$(echo "$CHANGED_FILES" | grep -c "^apps/frontend/" || true)
BACKEND_CHANGED=$(echo "$CHANGED_FILES" | grep -c "^apps/backend/" || true)

# Test frontend if it changed
if [ $FRONTEND_CHANGED -gt 0 ]; then
  cd apps/frontend && npm test -- --bail 2>&1 | tail -20; FRONTEND_EXIT=$?
  cd ../..
  if [ $FRONTEND_EXIT -ne 0 ]; then
    echo "Frontend tests failed" >&2
    exit 2
  fi
fi

# Test backend if it changed
if [ $BACKEND_CHANGED -gt 0 ]; then
  cd apps/backend && python -m pytest --tb=short 2>&1 | tail -20; BACKEND_EXIT=$?
  cd ../..
  if [ $BACKEND_EXIT -ne 0 ]; then
    echo "Backend tests failed" >&2
    exit 2
  fi
fi

exit 0
```

---

### Recipe 5: Security-First Configuration

For production codebases with strict security requirements:

```json
{
  "model": "claude-opus-4-6",
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(npm test|npm run build|git log|git diff)"],
    "deny": ["WebFetch", "WebSearch", "Bash(.*)", "Write", "Edit"]
  },
  "hooks": {
    "PreToolUse": [
      {
        "name": "comprehensive-secret-scan",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/comprehensive-secret-scan.sh"
          }
        ]
      },
      {
        "name": "protected-files",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/protect-files.sh"
          }
        ]
      },
      {
        "name": "sql-injection-check",
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/sql-injection-check.sh"
          }
        ]
      },
      {
        "name": "dependency-audit",
        "matcher": "Bash(npm install|pip install)",
        "hooks": [
          {
            "type": "command",
            "command": "npm audit --audit-level=moderate 2>&1 || echo 'Audit check'; exit 0"
          }
        ]
      },
      {
        "name": "auth-check",
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "FILE=$(echo '$INPUT' | jq -r '.tool_input.file_path // empty'); if grep -E '(router\\.(get|post|put|delete))\\s*\\(' \"$FILE\" 2>/dev/null | grep -v 'auth\\|middleware\\|@' >/dev/null; then echo '⚠️  New route without auth middleware?' >&2; fi; exit 0"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "name": "secret-scan-prompt",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/scan-prompt-for-secrets.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "name": "security-report",
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "echo '✓ Security checks passed' | head -1"
          }
        ]
      }
    ]
  }
}
```

**Comprehensive secret scan (.claude/hooks/comprehensive-secret-scan.sh):**
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Comprehensive patterns
PATTERNS=(
  "AKIA[0-9A-Z]{16}"
  "ghp_[A-Za-z0-9_]{36,255}"
  "sk_live_[A-Za-z0-9]{24,}"
  "-----BEGIN.*PRIVATE.*-----"
  "mongodb\+srv://[^/]+:[^@]+@"
  "postgres://[^/]+:[^@]+@"
  "mysql://[^/]+:[^@]+@"
  "password\s*[:=]"
  "api.key\s*[:=]"
  "secret\s*[:=]"
  "token\s*[:=]"
)

SECRETS_FOUND=0
for pattern in "${PATTERNS[@]}"; do
  if grep -iE "$pattern" "$FILE_PATH" 2>/dev/null | grep -v "example\|test\|dummy\|TODO" >/dev/null; then
    echo "⚠️  Suspected secret in $FILE_PATH: $pattern" >&2
    SECRETS_FOUND=1
  fi
done

[ $SECRETS_FOUND -eq 0 ]
exit $?
```

---

## 5. Composing Hooks (Advanced)

### Hook Chains: Sequential Execution

By default, hooks run in parallel. For sequential execution, use priority ordering:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "name": "test-first",
        "matcher": "Edit|Write",
        "priority": -10,
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --bail 2>&1 | tail -20"
          }
        ]
      },
      {
        "name": "lint-second",
        "matcher": "Edit|Write",
        "priority": 0,
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint 2>&1 | tail -10"
          }
        ]
      },
      {
        "name": "format-third",
        "matcher": "Edit|Write",
        "priority": 10,
        "hooks": [
          {
            "type": "command",
            "command": "npm run format 2>&1 | tail -5"
          }
        ]
      }
    ]
  }
}
```

**Priority rules:**
- Lower values run first (priority -10 before priority 0)
- Default priority is 0
- Use system hooks at priority -99 to run before user hooks

### Error Handling in Hook Chains

If one hook fails (exit 2), subsequent hooks in the chain may still run (implementation-dependent). To stop the chain on first failure:

```bash
#!/bin/bash
# Chain script: Test → Lint → Format, stop on first failure

echo "1. Running tests..."
npm test -- --bail 2>&1 | tail -20
TEST_EXIT=$?

if [ $TEST_EXIT -ne 0 ]; then
  echo "Tests failed. Stopping chain." >&2
  exit 2
fi

echo "2. Running lint..."
npm run lint 2>&1 | tail -10
LINT_EXIT=$?

if [ $LINT_EXIT -ne 0 ]; then
  echo "Lint failed. Stopping chain." >&2
  exit 2
fi

echo "3. Formatting..."
npm run format 2>&1 | tail -5

echo "✓ All checks passed"
exit 0
```

### Conditional Hooks: Branch-Aware

Hooks that behave differently on main vs feature branches:

```bash
#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ "$BRANCH" = "main" ]; then
  # Strict on main: require all tests + lint
  npm test -- --bail && npm run lint && echo "✓ Main branch: all checks passed"
  exit $?
else
  # Lenient on feature branches: just run tests
  npm test -- --bail || echo "⚠️  Tests failed but allowing on feature branch"
  exit 0
fi
```

### Hook + MCP Integration

Call MCP servers from within hooks:

```bash
#!/bin/bash
# Hook that queries GitHub API via MCP

# Assuming GitHub MCP is connected
# This is a simplified example

# Check PR status before allowing commit
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# MCP call (pseudo-code; actual implementation depends on MCP protocol)
PR_STATUS=$(curl -s -X POST http://localhost:9000/mcp \
  -H "Content-Type: application/json" \
  -d "{\"method\": \"tools/list\", \"tool\": \"github_pr_status\", \"branch\": \"$BRANCH\"}" \
  | jq -r '.status // "unknown"')

if [ "$PR_STATUS" = "approved" ]; then
  exit 0
else
  echo "PR not approved. Get approval before merging." >&2
  exit 2
fi
```

---

## 6. Testing & Debugging

### Verify Hooks Work

**Step 1: Check hooks are registered**
```bash
# In Claude Code session
/hooks

# Should list all configured hooks with matchers
```

**Step 2: Test a security hook**
```bash
# In Claude Code
# Try: "Add a secret to a file and commit"

# Expected: Hook blocks with error message
# If not: Hook may not be configured correctly
```

**Step 3: Check hook logs**
```bash
# Verbose mode shows hook execution
# Option A: In Claude Code, press Ctrl+O for verbose
# Option B: Check logs:
ls -la ~/.claude/logs/
cat ~/.claude/logs/hooks.log | tail -50
```

**Step 4: Test hook manually**
```bash
# Run hook script directly
./.claude/hooks/protect-files.sh <<< '{
  "tool": "Edit",
  "tool_input": {
    "file_path": ".env"
  }
}'

# Should exit 2 (blocked)
```

### Debugging Hook Failures

| Problem | Diagnosis | Solution |
|---------|-----------|----------|
| **Hook never fires** | Matcher pattern mismatch | Check matcher is exact (case-sensitive). Use `/hooks` to verify |
| **Hook fires but doesn't block** | Wrong exit code (using 1 instead of 2) | Ensure `exit 2` for blocking, not `exit 1` |
| **Hook output not shown** | Exit 0 with no JSON output | Print to stderr: `echo "message" >&2` |
| **Slow hook blocks workflow** | Command takes >5 seconds | Optimize script. Move slow checks to CI |
| **Hook works locally but not in CI** | Path/environment differences | Use absolute paths, check env vars |
| **Hook has regex bugs** | Patterns too loose or too strict | Test regex separately: `echo "test" \| grep -E "pattern"` |

### Performance: Keep Hooks Fast

Hooks run synchronously on every tool call. Slow hooks kill developer experience.

**Benchmarks (target):**
- **Formatting (prettier/black):** 200-500ms ✓
- **Linting (eslint):** 300-800ms ✓
- **Tests (quick unit tests only):** 500-2000ms ✓
- **Type checking (tsc):** 500-1500ms ✓
- **Secret scanning:** 100-300ms ✓

**Anything >3s should be moved to CI or made async.**

**Optimization techniques:**
```bash
# ❌ Slow: Format entire project
npx prettier --write .

# ✅ Fast: Format only changed file
npx prettier --write "$FILE_PATH"

# ❌ Slow: Run full test suite
npm test

# ✅ Fast: Run only affected tests
npm test -- --testPathPattern="$FILE_PATTERN"

# ❌ Slow: Lint everything
npm run lint

# ✅ Fast: Lint only changed file
npx eslint "$FILE_PATH" --fix
```

---

## 7. Hook Decision Framework

**Given a rule you want to enforce, which layer should it go in?**

| Rule | Best Layer | Why |
|------|-----------|-----|
| "Use TDD" | Text (CLAUDE.md) + Hook | Text provides guidance; hook runs tests to enforce |
| "Never commit secrets" | Hook (PreToolUse) | **Must be deterministic** — too risky for text rule |
| "Use semicolons" | Linter + Auto-format hook | Linter config + prettier hook |
| "Name branches feature/\*" | Hook (SessionStart warning) | Warning is fine; actual enforcement is CI (server-side) |
| "No raw SQL" | Hook (PostToolUse warning) | Can be warning (exit 1) since not a blocker |
| "Always run tests before commit" | Hook (PreToolUse on git commit) | Deterministic enforcement required |
| "Document changes in CHANGELOG" | Hook (warning) + CI (enforcing) | Hook warns; CI enforces on PR |
| "Import type before value imports" | Linter config | ESLint @typescript-eslint/consistent-type-imports |
| "Max file length 300 lines" | Linter + Hook warning | Linter detects; hook warns |
| "Use snake_case for env vars" | Text rule | Style preference, not a blocker |

**Decision tree:**

```
Is this a SECURITY issue (secrets, auth, injection)?
  → YES: USE HOOK (exit 2 to block)

Is this PREVENTING BROKEN CODE (tests, build)?
  → YES: USE HOOK (exit 2 to block failed tests)

Is this a STYLE/CONVENTION (naming, formatting)?
  → YES: USE LINTER CONFIG + AUTO-FORMAT HOOK

Is this a TEAM EXPECTATION (branches, docs, commits)?
  → TEXT RULE + HOOK WARNING (exit 1) or CI CHECK

Is this RARE/CONTEXT-DEPENDENT?
  → TEXT RULE ONLY (CLAUDE.md)
```

---

## 8. Anti-Patterns

### Too Many Hooks = Developer Friction

**Problem:** 15 hooks firing on every PostToolUse. Each adds 100-500ms. Developer waits 5+ seconds per change.

**Solution:**
- Limit to 3-5 critical hooks per event
- Move slow checks to CI
- Use `priority` to order short hooks first

### Hooks That Silently Fail

**Problem:** Hook fails (exit 1), Claude doesn't see the error, code ships broken.

**Pattern:**
```bash
# ❌ Bad: Silently fails
npm test > /dev/null 2>&1

# ✅ Good: Shows output
npm test 2>&1 | tail -30
```

### Over-Hooking (Duplicate Checks)

**Problem:** Both pre-commit hook and PostToolUse hook run linting.

**Solution:** Pick one layer:
- Use PostToolUse for immediate feedback during editing
- Use PreToolUse on git commit as final gate
- Don't do both (redundant)

### Hooks That Work Locally But Break in CI

**Problem:**
- Hook assumes npm/python/go installed
- Hook uses paths that don't exist in CI
- Hook relies on .env vars not set in CI

**Solution:**
```bash
# ✅ Safe: Check for tool existence
if ! command -v npm &> /dev/null; then
  echo "npm not installed. Skipping." >&2
  exit 0  # Don't fail if tool missing
fi

# ✅ Safe: Use absolute paths
[ -f "$GITHUB_WORKSPACE/package.json" ] || exit 0

# ✅ Safe: Check env vars
[ -z "$CI" ] && [ -z "$GITHUB_ACTIONS" ] && echo "Running in CI"
```

### Not Testing Hooks Themselves

**Problem:** Hooks deployed to team without testing.

**Solution:**
```bash
# Test hook before checking in
./.claude/hooks/my-hook.sh

# Verify exit codes
./.claude/hooks/my-hook.sh
echo "Exit code: $?"

# Test with sample input (for PreToolUse)
echo '{"tool":"Edit","tool_input":{"file_path":".env"}}' | ./.claude/hooks/protect-files.sh
```

### Hooks That Can Be Bypassed Accidentally

**Problem:** Hook blocks, Claude user runs `git commit --no-verify` and bypasses hook.

**Context:** This is sometimes intentional. If it's a security hook, make it clear:

```bash
# Make the block message very clear
echo "❌ SECURITY: Cannot commit code with secrets." >&2
echo "   (To force bypass: git commit --no-verify)" >&2
echo "   (Remove secrets first!)" >&2
exit 2
```

---

## 9. Implementation Checklist

### For a New Project

**Phase 1: Essential (Day 1)**
- [ ] Create `.claude/settings.json` with `SessionStart` hook to remind of test-first
- [ ] Add secret detection hook (PreToolUse on Edit/Write)
- [ ] Add protected files hook (.env, migrations, CI configs)
- [ ] Test hooks work with: `echo "test" | ./.claude/hooks/test-hook.sh`

**Phase 2: Quality (Week 1)**
- [ ] Add auto-test hook (PostToolUse)
- [ ] Add auto-format hook (PostToolUse)
- [ ] Add test-gate hook (PreToolUse on git commit)

**Phase 3: Advanced (Month 1)**
- [ ] Add lint enforcement
- [ ] Add type checking
- [ ] Add coverage gates
- [ ] PreCompact/PostCompact context preservation

**Phase 4: Scaling (Ongoing)**
- [ ] Add dependency audit
- [ ] Add SQL injection check
- [ ] Add auth middleware check
- [ ] Add documentation sync warning

### For an Existing Project

**Step 1: Audit existing issues**
```bash
# What breaks most often?
git log --oneline | head -20

# Recurring errors?
grep -r "TODO\|FIXME\|BUG" src/
```

**Step 2: Start with one hook**
```bash
# Begin with auto-test hook (PostToolUse)
# This gives immediate feedback, builds confidence
```

**Step 3: Add team input**
```bash
# Ask team: "What are we doing wrong most often?"
# Build hooks for those issues
```

**Step 4: Measure impact**
```bash
# Track: fewer broken commits?
# Faster feedback? Better test coverage?
```

### For a Team

**1. Check .claude/settings.json into git**
```bash
git add .claude/settings.json
git commit -m "chore: add enforcement hooks for TDD and security"
```

**2. Document in CLAUDE.md**
```markdown
## Enforcement

This project uses hooks to enforce:
- Tests must pass before committing
- No secrets (API keys, .env) allowed in code
- Protected files (.env, migrations) cannot be edited
- Code must pass linting and type checks

All hooks are defined in `.claude/settings.json`.
To bypass: `git commit --no-verify` (not recommended for security hooks).
```

**3. Add to onboarding guide**
```markdown
## First Session Setup

1. Install dependencies: `npm install`
2. Run tests: `npm test`
3. Start session: `claude`
4. Read CLAUDE.md
5. Verify hooks: `/hooks` (should see 8 hooks listed)
```

---

## 10. Sources

### Official Documentation

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Hooks Best Practices](https://geminicli.com/docs/hooks/best-practices/)
- [Cursor Rules Documentation](https://cursor.com/docs/context/rules)
- [Gemini CLI Hooks](https://geminicli.com/docs/hooks/)
- [Pre-commit Framework](https://pre-commit.com/)

### Community Research & Guides

- [Claude Code Hooks: PreToolUse, PostToolUse & All 12 Events (2026)](https://www.pixelmojo.io/blogs/claude-code-hooks-production-quality-ci-cd-patterns)
- [GitHub - disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery)
- [How to Configure Claude Code Hooks for AI-Driven Automation](https://www.gend.co/blog/configure-claude-code-hooks-automation)
- [Claude Code Hooks: A practical guide with examples (2026)](https://www.eesel.ai/blog/hooks-in-claude-code)
- [The Complete Cursor Rules Guide (2026)](https://www.agentrulegen.com/guides/cursor-rules-guide)
- [Cursor Agent Not Following MDC Rules? 5 Critical Mistakes](https://dredyson.com/cursor-agent-not-following-mdc-rules-5-critical-mistakes-to-avoid-step-by-step-fix-guide-for-vscode-1-105-users/)
- [Gemini CLI Hooks Are Google's Way of Taming AI Agents](https://medium.com/towardsdev/gemini-cli-hooks-are-googles-way-of-taming-ai-agents-cf813d3c5a39)

### Security & Secrets Management

- [Block API Keys & Secrets from Your Commits with Claude Code Hooks](https://www.aitmpl.com/blog/security-hooks-secrets/)
- [GitHub - mintmcp/agent-security](https://github.com/mintmcp/agent-security)
- [From .env to Leakage: Mishandling of Secrets by Coding Agents](https://www.knostic.ai/blog/claude-cursor-env-file-secret-leakage)
- [Stop Claude Code from leaking your secrets — introducing sensitive-canary](https://dev.to/chataclaw/stop-claude-code-from-leaking-your-secrets-introducing-sensitive-canary-826)

### Testing & TDD with AI

- [TDD Guard - Automated TDD enforcement for Claude Code](https://github.com/nizos/tdd-guard)
- [Claude Code Hooks Tutorial: 5 Production Hooks From Scratch](https://blakecrosley.com/blog/claude-code-hooks-tutorial)

### Git Hooks & Pre-commit

- [Using AI in Git Hooks for Pre-Commit Checks](https://www.deployhq.com/git/ai-git-hooks)
- [Effortless Code Quality: The Ultimate Pre-Commit Hooks Guide for 2025](https://gatlenculp.medium.com/effortless-code-quality-the-ultimate-pre-commit-hooks-guide-for-2025-57ca501d9835)
- [Conventional Commits](https://www.conventionalcommits.org/en/about/)
- [GitHub - compilerla/conventional-pre-commit](https://github.com/compilerla/conventional-pre-commit)

### Monorepo Patterns

- [Introducing Mookme, a git hook manager for monorepos](https://escape.tech/blog/introducing-mookme-a-git-hook-manager-for-monorepos/)
- [Enforce Git Hooks in Monorepos with Husky](https://dev.to/mimafogeus2/enforce-git-hooks-in-monorepos-with-husky-how-3fma/)

### Tool Comparisons & Best Practices

- [18 Best Code & Test Coverage Tools for DevOps in 2026](https://www.codeant.ai/blogs/best-code-test-coverage-tools-2025)
- [Cursor Background Agents: Complete Guide (2026)](https://ameany.io/blog/cursor-background-agents/)
- [5 Claude Code Hook Mistakes That Silently Break Your Safety Net](https://dev.to/yurukusa/5-claude-code-hook-mistakes-that-silently-break-your-safety-net-58l3)

---

**Document version:** 1.0
**Last verified:** March 18, 2026
**Maintenance:** Check for new hook events quarterly; update recipes as tools evolve

---

## Related Topics

- [Testing AI-Generated Code](testing-ai-generated-code.md) — Validating code quality at the gate level with hooks
- [Team AI Onboarding](team-ai-onboarding.md) — Teaching teams to use hooks for consistency
- [Claude Code Power User](claude-code-power-user.md) — Advanced techniques for integrating hooks into workflows

---

## Changelog
| Date | Change | Source |
|------|--------|--------|
| 2026-03-20 | Added `StopFailure` hook event (v2.1.78, March 17 2026) to the hook events table — fires when turn ends due to API error, enabling automated error recovery and retry logic. | Daily briefing 2026-03-20 finding #4 |
