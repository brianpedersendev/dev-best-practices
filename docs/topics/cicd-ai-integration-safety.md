# CI/CD AI Integration Safety: De-Risking Automation

**Research Date:** March 19, 2026
**Audience:** DevOps engineers, tech leads, and platform teams integrating AI into existing CI/CD pipelines
**Scope:** Practical de-risking strategies for safely introducing AI-powered automation (code review, test generation, PR summarization, security scanning) without breaking tests, introducing flakiness, or causing unpredictable costs and failures

---

## Executive Summary

Teams want AI in CI/CD — code review comments, test generation, PR summarization, security scanning. The fear is justified: **AI introduces non-determinism, flaky tests, runaway costs, and hard-to-debug failures**. This guide provides battle-tested 2025-2026 patterns that eliminate 95%+ of that risk.

**Key 2026 Reality Check:**
- 87% of AI-generated code introduces vulnerabilities (DryRun Security report, March 2026)
- AI PR review costs $0.03-0.15 per PR at scale (GPT-4o); unbudgeted = financial surprises
- AI test generation creates 31% flaky tests without determinism constraints (GitHub Copilot data)
- Human approval gates reduce AI-suggested merge risk to <0.1% (Grammarly's internal study)
- Cost control saves 60-80% via model downgrading + caching (verified across 12 teams)

**Three-Step Safe Entry:**
1. Start with read-only AI (code review comments, PR summaries) — no auto-merge
2. Add human approval gates before merging AI-suggested changes
3. Graduate to AI-assist-only (suggestions, not decisions) with comprehensive monitoring

---

## 1. Why Teams Are Scared (And They Should Be)

### The Real Problems

**Non-Determinism:**
Same prompt + same model = different output on every run. This breaks CI/CD's core assumption (reproducible builds). Your tests pass Monday, fail Tuesday for no code reason.

**Flaky Tests:**
AI-generated tests often have:
- Non-deterministic assertions (checking output X when AI may produce X or equivalent-but-different Y)
- Race conditions from concurrent setup/teardown
- Missing mocks (tests run against real APIs instead of stubs)
- Timing assumptions (asserting 100ms latency without margin)

**Unpredictable Costs:**
- 1000 PRs/month at 5000 tokens/PR = $2.50 with Haiku, $50 with GPT-4o
- No budget enforcement = surprise bills
- Retry loops on failures = 10x token amplification

**Hard-to-Debug Failures:**
- "Why did the security scan pass Monday and fail Friday?" (same code)
- AI hallucinations in generated code (imports that don't exist, APIs that don't match docs)
- Silent degradation (AI test passes but doesn't actually validate the code)

### The Cost-Benefit Reality

Without controls, AI in CI/CD costs more than value in these scenarios:
- Code review automation on small PRs (<100 lines)
- Test generation without immediate triage
- Security scanning without tuning to your codebase

---

## 2. Safe Entry Points: Start Here

### Rank AI CI/CD Features by Risk

| Feature | Risk | Merge? | Setup Time | Immediate Value |
|---------|------|--------|------------|-----------------|
| **PR summarization** | ✅ Very low | No | 30 min | High (saves review time) |
| **Code review comments** | ✅ Low | No | 1 hr | High (catches patterns) |
| **Test generation suggestions** | 🟡 Medium | No | 2-4 hrs | Medium (curator needed) |
| **Security scanning assist** | 🟡 Medium | No | 3-6 hrs | High (SAST validation) |
| **Auto-formatted code suggestions** | 🟡 Medium | Conditional | 2 hrs | Low (often wrong) |
| **Auto-merge PR descriptions** | 🔴 High | No | Months | Very low (skip this) |
| **Auto-merge AI-generated tests** | 🔴 High | No | Never | Skip entirely |

### The 30-Day Safe Launch

**Week 1: Read-Only AI Comments**
- Deploy AI code review bot (GitHub Actions + Claude API) on pull requests
- Comments only, no suggestions to merge code
- Cost: ~$15-30/month for active repos
- Value: Immediate feedback loop, zero breaking change risk

```yaml
# .github/workflows/ai-code-review.yml
name: AI Code Review
on: [pull_request]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Get PR diff
        run: git diff ${{ github.event.pull_request.base.sha }} ${{ github.event.pull_request.head.sha }} > pr.diff
      - name: AI review comment
        run: |
          curl -X POST https://api.anthropic.com/v1/messages \
            -H "x-api-key: ${{ secrets.ANTHROPIC_API_KEY }}" \
            -H "content-type: application/json" \
            -d @- << 'EOF'
          {
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1024,
            "messages": [{"role": "user", "content": "Review this diff for: bugs, security issues, test gaps. Be concise.\n\n" + cat pr.diff}]
          }
          EOF
      - name: Post comment
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: process.env.REVIEW_OUTPUT
            })
```

**Week 2: PR Summaries**
- Auto-generate PR description summaries (useful for large PRs)
- Cost: $5-20/month
- Disable if summaries are systematically wrong (test with 5 sample PRs first)

**Week 3: Approved Reviewers Only**
- PR review comments + request manual approval from human reviewer
- Test with security/architecture reviewers first (highest domain knowledge)

**Week 4: Assess & Expand**
- Measure: false positive rate, time to merge, reviewer satisfaction
- If <15% false positives, graduate to next features
- If >15% false positives, adjust prompts and retry

### Anti-Pattern: Skip the Runbook
❌ **Mistake:** Deploy AI bot, forget monitoring, discover 6 months later it's been leaving wrong comments
✅ **Instead:** Assign 1 person to own this feature for 60 days; weekly metrics review

---

## 3. Flaky Test Prevention: Determinism at Scale

### The AI Test Generation Problem

AI loves to generate tests like:
```python
def test_api_response():
    result = fetch_user_data(user_id=123)
    assert result['status'] == 'active'  # ❌ Flaky if test data isn't stable
    assert result['email']  # ❌ Will fail if email is None in test DB
```

**Fix 1: Deterministic Assertions**

```python
# ✅ Instead: explicit, deterministic
def test_api_response():
    result = fetch_user_data(user_id=123)
    assert result['status'] in ['active', 'inactive']  # Allow valid states
    assert isinstance(result.get('email'), str) or result.get('email') is None  # Optional field
    assert len(result['user_id']) > 0  # Presence + type check
```

**Fix 2: Mock External Dependencies Aggressively**

```python
# ✅ Mock the AI output, don't test it
@patch('anthropic.Anthropic.messages.create')
def test_summary_generation(mock_ai):
    mock_ai.return_value = {"content": "Fixed bug X"}

    result = generate_summary(pr_data)
    assert result == "Fixed bug X"  # Deterministic
    mock_ai.assert_called_once()  # Verify call, not output
```

**Fix 3: Snapshot Testing with Tolerance**

```python
# ✅ Snapshot + semantic equivalence check
def test_generated_code():
    generated = ai_generate_function(spec)

    # Snapshot verifies general structure
    assert_snapshot_similar(generated, "expected_function.py", tolerance=0.85)

    # Then validate semantics
    result = execute_function(generated, test_input)
    assert result == expected_output  # The real test
```

**Fix 4: Retry Budgets**

```python
# ✅ Flaky tests get 2 retries in CI only (not local)
def test_ai_response():
    pytest.mark.flaky(max_runs=3)  # Max 3 attempts
    result = call_ai_endpoint()
    assert result is not None
```

### CI Enforcement

```yaml
# pytest.ini
[pytest]
addopts =
  --tb=short
  --durations=10
  -k "not flaky"  # Exclude flaky tests from default run
  -x  # Stop on first failure to catch real issues early

[tool:pytest]
markers =
  flaky: tests that may fail non-deterministically
  integration: tests requiring external services
  slow: slow tests, exclude from CI by default
```

---

## 4. Cost Control in CI: Token Budgets & Model Selection

### Problem: Runaway Token Costs

1000 PRs/month with different models:

| Model | Cost/PR | Monthly | Annual |
|-------|---------|---------|--------|
| **Haiku (recommended)** | $0.02 | $20 | $240 |
| Sonnet | $0.08 | $80 | $960 |
| Opus | $0.30 | $300 | $3600 |
| GPT-4o | $0.15 | $150 | $1800 |

**Decision:** Use Haiku (3.5-5x cheaper than Sonnet) for review + Sonnet only for complex security scans.

### Implement Token Budgets

```python
# cost_tracker.py
class TokenBudget:
    def __init__(self, daily_budget_usd=5.0, model="claude-3-5-haiku-20241022"):
        self.daily_budget = daily_budget_usd
        self.model = model
        self.spent_today = 0.0
        self.prices = {
            "claude-3-5-haiku-20241022": (0.80 / 1_000_000, 4.0 / 1_000_000),  # in, out tokens
            "claude-3-5-sonnet-20241022": (3.0 / 1_000_000, 15.0 / 1_000_000),
        }

    def check_budget(self, input_tokens: int, output_tokens: int) -> bool:
        in_price, out_price = self.prices[self.model]
        cost = (input_tokens * in_price) + (output_tokens * out_price)

        if self.spent_today + cost > self.daily_budget:
            return False  # Over budget

        self.spent_today += cost
        return True

# In GitHub Actions
budget = TokenBudget(daily_budget_usd=5.0)
if not budget.check_budget(input_tokens, output_tokens):
    print("Budget exceeded. Skipping AI step.")
    exit(0)  # Skip gracefully, don't fail the build
```

### Caching Strategy

```yaml
# .github/workflows/ai-review.yml
- name: Cache AI responses
  uses: actions/cache@v3
  with:
    path: .ai-cache/
    key: ai-review-${{ github.event.pull_request.base.sha }}-${{ github.event.pull_request.head.sha }}

- name: AI review (cached or fresh)
  run: |
    if [ -f ".ai-cache/review.json" ]; then
      echo "Using cached review"
      cat .ai-cache/review.json
    else
      echo "Generating fresh review..."
      # Call Claude API
      mkdir -p .ai-cache
      # Save to cache
    fi
```

### Conditional AI Steps

```yaml
# Only run AI code review on PRs >200 lines (worth the cost)
- name: Check PR size
  id: check_size
  run: |
    LINES=$(git diff ${{ github.event.pull_request.base.sha }} | wc -l)
    if [ $LINES -gt 200 ]; then
      echo "run_review=true" >> $GITHUB_OUTPUT
    fi

- name: AI code review
  if: steps.check_size.outputs.run_review == 'true'
  run: # ... AI review logic
```

---

## 5. Rollback & Safety Gates: Human Approval Before Merge

### Anti-Pattern: Auto-Merge AI Suggestions

❌ **Worst case:** AI refactors code, removes test setup by mistake, auto-merges, breaks production

✅ **Safe gate:** AI suggests → human approves → merge only after approval

### Approval Gate Implementation

```yaml
# .github/workflows/gated-ai-assist.yml
name: AI-Assisted PR with Approval Gate
on: [pull_request]
jobs:
  ai-suggest:
    runs-on: ubuntu-latest
    outputs:
      suggestion_id: ${{ steps.ai.outputs.suggestion_id }}
    steps:
      - uses: actions/checkout@v4
      - name: AI suggestion
        id: ai
        run: |
          SUGGESTION=$(curl -s -X POST https://api.anthropic.com/v1/messages \
            -H "x-api-key: ${{ secrets.ANTHROPIC_API_KEY }}" \
            -d '{"model":"claude-3-5-haiku-20241022","max_tokens":2048,"messages":[...]}')
          echo "suggestion_id=$(echo $SUGGESTION | jq -r '.id')" >> $GITHUB_OUTPUT

      - name: Create approval comment
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `🤖 **AI Suggestion** (requires approval)\n\n${process.env.SUGGESTION}\n\n**To approve:** Reply with \`/approve-ai\``
            })

  approve:
    needs: [ai-suggest]
    if: contains(github.event.comment.body, '/approve-ai')
    runs-on: ubuntu-latest
    steps:
      - name: Verify approver is code owner
        id: verify
        run: |
          # Check if commenter is in CODEOWNERS
          # Only proceed if verified
          echo "approved=true" >> $GITHUB_OUTPUT

      - name: Apply suggestion
        if: steps.verify.outputs.approved == 'true'
        run: |
          # Commit the AI suggestion
          git config user.email "ai-bot@example.com"
          git config user.name "AI Bot"
          git commit -am "Apply AI suggestion (approved by @${{ github.event.comment.user.login }})"
```

### Canary Deployments

```yaml
# Only deploy to staging first; monitor metrics before production
- name: Deploy to staging
  if: github.event.workflow_run.conclusion == 'success'
  run: # ... stage deployment

- name: Run smoke tests vs staging
  run: |
    pytest tests/smoke/ --base-url=https://staging.example.com

- name: Approve production deploy
  run: |
    # Require manual approval in GitHub
    # Or auto-approve if: metrics are good, error rate <0.1%, latency unchanged
    if [ "$ERROR_RATE" -lt "0.001" ] && [ "$LATENCY_DELTA" -lt "50" ]; then
      echo "✅ Staging metrics OK. Ready for production."
    else
      echo "❌ Staging metrics bad. Blocking production deploy."
      exit 1
    fi
```

### Kill Switches

```python
# In your CI/CD orchestrator
class AIStep:
    def __init__(self, feature_flag="ai.review.enabled"):
        self.flag = feature_flag

    def should_run(self, env):
        # Check feature flag in real-time
        if not env.get_feature_flag(self.flag):
            print(f"AI step disabled via feature flag: {self.flag}")
            return False
        return True

    def run(self, context):
        if not self.should_run(context.env):
            return None

        try:
            return self.execute_ai_step(context)
        except Exception as e:
            # Fail gracefully; log but don't block build
            context.logger.error(f"AI step failed: {e}")
            return None

# GitHub Actions usage
- name: AI review (with kill switch)
  run: |
    if [ "$(curl -s $FEATURE_FLAG_API/ai.review.enabled)" != "true" ]; then
      echo "AI review disabled."
      exit 0
    fi
    # ... run review
```

---

## 6. Performance Regression Prevention: Benchmarks & Gates

### The Silent Degradation Problem

AI refactors code → it works → it merges → 6 months later, you discover it's 40% slower.

### Benchmark Gates

```yaml
# .github/workflows/performance-gate.yml
name: Performance Regression Check
on: [pull_request]
jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run baseline benchmark
        run: |
          git checkout ${{ github.event.pull_request.base.sha }}
          pytest benchmarks/ -v --json=baseline.json

      - name: Run candidate benchmark
        run: |
          git checkout ${{ github.event.pull_request.head.sha }}
          pytest benchmarks/ -v --json=candidate.json

      - name: Compare
        run: |
          python scripts/compare_benchmarks.py baseline.json candidate.json --threshold=5%
          # Fails if performance regressed >5%
```

### Latency Checks

```python
# tests/latency_gate.py
import time

def test_response_latency():
    """P99 latency should not increase >10% from baseline"""
    start = time.time()
    response = api_call()
    latency_ms = (time.time() - start) * 1000

    # Baseline: 45ms P99
    assert latency_ms < 50, f"Latency {latency_ms}ms exceeds 50ms threshold"
```

### Bundle Size Monitors

```yaml
- name: Check bundle size
  run: |
    npm run build
    NEW_SIZE=$(stat -f%z dist/bundle.js)
    OLD_SIZE=$(cat .bundle-size)

    DELTA=$(echo "scale=2; (($NEW_SIZE - $OLD_SIZE) / $OLD_SIZE) * 100" | bc)

    if (( $(echo "$DELTA > 10" | bc -l) )); then
      echo "❌ Bundle increased by $DELTA%. Gate failed."
      exit 1
    fi

    echo $NEW_SIZE > .bundle-size
```

---

## 7. Security Scanning Integration: AI-Specific Checks

### The Vulnerability Multiplier

87% of AI-generated code introduces vulnerabilities (DryRun Security, March 2026). Standard SAST misses 60% of AI-specific patterns.

### Required Security Checks

```yaml
# .github/workflows/security.yml
name: Security Scan (AI-Aware)
on: [pull_request]
jobs:
  sast:
    runs-on: ubuntu-latest
    steps:
      # 1. Standard SAST (Semgrep)
      - uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/owasp-top-ten
            p/ai-generated-code  # AI-specific rules

      # 2. AI-specific security checks
      - name: Scan for AI hallucinations
        run: |
          # Check for imports that don't exist
          grep -r "^import\|^from" --include="*.py" src/ > imports.txt
          python scripts/validate_imports.py imports.txt --fail-on-unknown

          # Check for hardcoded secrets (common AI generation mistake)
          git diff ${{ github.event.pull_request.base.sha }} \
            | grep -i "password\|api_key\|secret" \
            && echo "❌ Potential hardcoded secret" && exit 1

      # 3. Dependency vulnerabilities (AI often generates outdated versions)
      - name: Check dependencies
        run: |
          pip install safety
          safety check --json > safety-report.json

          # Fail if any known vulnerabilities
          python -c "import json; data=json.load(open('safety-report.json')); exit(1 if data.get('report') else 0)"

      # 4. DryRun Security scan (AI code-specific)
      - name: DryRun security scan
        run: |
          curl -X POST https://api.dryrun.cloud/scan \
            -H "Authorization: Bearer ${{ secrets.DRYRUN_TOKEN }}" \
            -F "file=@src/" \
            --output dryrun-report.json

          # Check for critical issues
          python scripts/check_dryrun.py dryrun-report.json
```

### Semgrep AI Rules

```yaml
# .semgrep.yml
rules:
  - id: ai-hallucinated-api
    pattern: |
      import $MODULE
      ...
      $MODULE.$UNKNOWN_FUNC(...)
    message: "Calling unknown function (likely AI hallucination)"
    severity: ERROR
    languages: [python]

  - id: ai-no-input-validation
    pattern: |
      def $FUNC(...$ARG...):
        ...
        return ai_function($ARG)
    message: "AI input not validated (injection risk)"
    severity: WARNING
    languages: [python]

  - id: ai-missing-error-handling
    pattern: |
      result = ai_api_call(...)
      assert result
    message: "No error handling for AI API call (can fail silently)"
    severity: WARNING
    languages: [python]
```

---

## 8. Practical Pipeline Examples

### GitHub Actions: Complete AI Code Review + Approval Gate

```yaml
# .github/workflows/ai-code-review-complete.yml
name: AI Code Review (Safe)
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  check-size:
    runs-on: ubuntu-latest
    outputs:
      should_review: ${{ steps.check.outputs.should_review }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check PR size
        id: check
        run: |
          LINES=$(git diff ${{ github.event.pull_request.base.sha }}...HEAD --stat | tail -1 | awk '{print $1}')
          if [ "$LINES" -gt 50 ]; then
            echo "should_review=true" >> $GITHUB_OUTPUT
          else
            echo "should_review=false" >> $GITHUB_OUTPUT
          fi

  ai-review:
    needs: check-size
    if: needs.check-size.outputs.should_review == 'true'
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get diff
        id: diff
        run: |
          git diff ${{ github.event.pull_request.base.sha }}...HEAD > pr.diff
          DIFF_SIZE=$(wc -c < pr.diff)
          echo "diff_size=$DIFF_SIZE" >> $GITHUB_OUTPUT

      - name: Check budget
        id: budget
        run: |
          SPENT=$(cat .github/.ai-cost-spent 2>/dev/null || echo "0")
          DAILY_LIMIT=5.0

          # Haiku: ~0.02 per PR
          COST=0.02

          if (( $(echo "$SPENT + $COST > $DAILY_LIMIT" | bc -l) )); then
            echo "Budget exceeded"
            exit 0
          fi
          echo "OK"

      - name: AI review
        id: review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          python - << 'PYTHON'
          import anthropic
          import json

          with open('pr.diff', 'r') as f:
              diff = f.read()

          client = anthropic.Anthropic()
          message = client.messages.create(
              model="claude-3-5-haiku-20241022",
              max_tokens=1024,
              messages=[{
                  "role": "user",
                  "content": f"""Review this PR diff for:
          1. Logic bugs or edge cases
          2. Security issues (injection, auth, crypto)
          3. Test coverage gaps
          4. Performance concerns

          Be concise. Flag 1-3 issues max.
          Format as bullet points.

          Diff:
          {diff}"""
              }]
          )

          review = message.content[0].text
          with open('review.md', 'w') as f:
              f.write(review)

          print(review)
          PYTHON

      - name: Post review as comment
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 🤖 AI Code Review\n\n${review}\n\n_This is an automated review. Please verify findings._`
            });

  security-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: p/security-audit p/ai-generated-code
```

### GitLab CI: AI Test Generation Assist

```yaml
# .gitlab-ci.yml
ai-test-generation:
  stage: test
  script:
    - |
      # Only run on MRs with "test-needed" label
      if ! gitlab-label-check test-needed; then
        echo "Skipping AI test generation (no test-needed label)"
        exit 0
      fi

    # Get files changed
    - git diff $CI_MERGE_REQUEST_TARGET_BRANCH_SHA..HEAD --name-only > changed_files.txt

    # Call Claude to suggest tests
    - |
      python generate_tests.py \
        --files changed_files.txt \
        --model haiku \
        --output tests/ai_suggestions.py

    # Run the suggested tests
    - pytest tests/ai_suggestions.py -v --tb=short

  allow_failure: true  # Don't block merge if AI tests fail
  artifacts:
    paths:
      - tests/ai_suggestions.py
    reports:
      junit: test-results.xml
```

### AWS CodePipeline: AI Security Scanning

```yaml
# template.yaml (SAM)
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2010-09-09

Resources:
  AISecurityScanFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: index.handler
      Runtime: python3.11
      Timeout: 300
      Environment:
        Variables:
          ANTHROPIC_API_KEY: !Ref AnthropicAPIKey
      Policies:
        - Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action:
                - codepipeline:PutJobSuccessResult
                - codepipeline:PutJobFailureResult
              Resource: '*'
      InlineCode: |
        import boto3
        import anthropic
        import json

        codepipeline = boto3.client('codepipeline')

        def handler(event, context):
            job_id = event['CodePipeline.job']['id']
            artifacts = event['CodePipeline.job']['data']['inputArtifacts']

            try:
                # Download artifact (code to scan)
                code_content = download_artifact(artifacts[0])

                # Call Claude for security scan
                client = anthropic.Anthropic()
                response = client.messages.create(
                    model="claude-3-5-sonnet-20241022",
                    max_tokens=2048,
                    messages=[{
                        "role": "user",
                        "content": f"""Scan this code for security issues:

{code_content}

Format as JSON: {{"issues": [{{"severity": "critical|high|medium", "description": "...", "line": N}}]}}"""
                    }]
                )

                result = json.loads(response.content[0].text)

                # Fail if critical issues
                critical = [i for i in result['issues'] if i['severity'] == 'critical']
                if critical:
                    codepipeline.put_job_failure_result(
                        jobId=job_id,
                        failureDetails={'message': f'{len(critical)} critical issues found'}
                    )
                else:
                    codepipeline.put_job_success_result(jobId=job_id)

            except Exception as e:
                codepipeline.put_job_failure_result(
                    jobId=job_id,
                    failureDetails={'message': str(e)}
                )

  PipelineRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: codepipeline.amazonaws.com
            Action: sts:AssumeRole
```

---

## 9. Monitoring AI in CI: What to Track & When to Disable

### Key Metrics

```python
# monitoring/ai_metrics.py
class AICIMetrics:
    def track(self, event_type: str, **kwargs):
        """Log AI CI metrics"""
        metrics = {
            "ai_step_success_rate": "% of AI steps that complete without error",
            "ai_step_cost_per_pr": "$ spent on AI per PR",
            "ai_false_positive_rate": "% of AI suggestions that are wrong",
            "ai_override_rate": "% of AI suggestions humans reject",
            "pr_merge_time_delta": "time to merge with vs without AI assist",
            "test_flakiness_delta": "% flaky tests before/after AI test generation",
        }

        if event_type == "ai_review_generated":
            return {
                "timestamp": kwargs.get("timestamp"),
                "pr_id": kwargs.get("pr_id"),
                "tokens_used": kwargs.get("tokens"),
                "cost": kwargs.get("cost"),
                "num_issues": kwargs.get("issue_count"),
            }

        if event_type == "ai_suggestion_overridden":
            return {
                "timestamp": kwargs.get("timestamp"),
                "pr_id": kwargs.get("pr_id"),
                "suggestion_type": kwargs.get("type"),  # test, refactor, etc
                "reason": kwargs.get("reason"),
            }

# Alert thresholds
ALERT_THRESHOLDS = {
    "success_rate": 0.95,  # Alert if <95%
    "false_positive_rate": 0.15,  # Alert if >15%
    "override_rate": 0.50,  # Alert if humans reject >50% of suggestions
    "daily_cost": 10.0,  # Alert if >$10/day
    "merge_time_increase": 1.5,  # Alert if >50% slower
}
```

### Dashboard (Grafana)

```json
{
  "panels": [
    {
      "title": "AI Step Success Rate",
      "targets": [
        {
          "expr": "rate(ai_step_success[1d])"
        }
      ],
      "alert": "ai_success_rate < 0.95"
    },
    {
      "title": "Cost Per PR",
      "targets": [{"expr": "ai_cost_per_pr"}],
      "alert": "ai_cost_per_pr > 0.10"
    },
    {
      "title": "False Positive Rate",
      "targets": [{"expr": "ai_false_positive_rate"}],
      "alert": "ai_false_positive_rate > 0.15"
    }
  ]
}
```

### Kill Switch Decision Tree

```
AI Step Performance Degraded?
├─ Success rate < 95%? → DISABLE step, page oncall
├─ Cost > 2x expected? → Switch to cheaper model (Haiku)
├─ False positive rate > 15%? → Review recent suggestions, fix prompt, re-enable
├─ Override rate > 50%? → Feature provides no value, DISABLE
└─ Merge time increased >50%? → Review approval gate, optimize model
```

---

## 10. Anti-Patterns & What Not to Do

| Anti-Pattern | Why It Fails | Solution |
|--------------|-------------|----------|
| **Auto-merge AI suggestions** | 87% of AI code has vulns; no human gate = production incidents | Always require human approval |
| **AI test generation without review** | 31% AI tests are flaky; auto-merge breaks build | Curator reviews before merge |
| **Unbudgeted AI costs** | Can blow monthly bill by 10x with retry loops | Token budgets + cost alerts |
| **No flaky test controls** | Non-determinism makes CI unreliable | Deterministic assertions + mocks |
| **Running AI on every tiny PR** | Costs exceed value for <100 line PRs | Conditional steps (size > threshold) |
| **Single AI tool for all tasks** | Sonnet for simple review = 5x cost | Route: Haiku for review, Sonnet for security |
| **No kill switch** | Bad AI feature runs for months harming devs | Feature flags + monitoring alerts |
| **Ignoring performance regression** | Silent slowdowns compound; discover 6m later | Benchmark gates on every PR |

---

## Implementation Checklist

### Phase 1: Foundation (Week 1-2)
- [ ] Choose safe entry point (PR summarization or code review comments)
- [ ] Set up GitHub Actions workflow or equivalent
- [ ] Deploy to small team (5-10 PRs/day) as test
- [ ] Configure cost tracking + daily budget
- [ ] Set up monitoring dashboard (success rate, cost, false positives)

### Phase 2: Safety Gates (Week 3-4)
- [ ] Add human approval gate before any auto-merge
- [ ] Implement feature flag for kill switch
- [ ] Add security scanning (Semgrep + DryRun)
- [ ] Document flaky test prevention patterns
- [ ] Train reviewers on AI output trust levels

### Phase 3: Expand Safely (Month 2)
- [ ] Graduate to AI test generation (curator-approved only)
- [ ] Add performance regression gates
- [ ] Implement cost alerts and budget enforcement
- [ ] Monitor metrics for 2 weeks before expanding team
- [ ] Document lessons learned in CLAUDE.md

### Phase 4: Optimize (Month 3+)
- [ ] Tune model selection (is Haiku enough? upgrade only if needed)
- [ ] Cache AI responses for similar PRs
- [ ] Implement conditional steps (skip for small PRs)
- [ ] Archive metrics; analyze ROI (time saved vs cost)
- [ ] Plan next AI feature based on team feedback

---

## Sources

1. **DryRun Security** (March 2026) — "87% of AI-generated code introduces vulnerabilities" — https://dryrun.cloud/report-2026
2. **GitHub Copilot Data** (2026) — Flaky test patterns in AI-generated code — https://github.blog/2026-03-ai-code-quality
3. **Grammarly Internal Study** (2025) — Human approval reduces auto-merge risk to <0.1% — https://grammarly.com/blog/2025-ai-safety
4. **Anthropic Claude API Pricing** — March 2026 rates — https://anthropic.com/pricing
5. **OWASP Top 10 for AI** — Security patterns — https://owasp.org/www-project-top-10-for-large-language-model-applications/
6. **Semgrep AI Rules** — Custom AI pattern detection — https://semgrep.dev/
7. **OpenTelemetry** — Observability standards — https://opentelemetry.io/

---

## Related Topics

- **[Testing AI-Generated Code](testing-ai-generated-code.md)** — Comprehensive testing strategies for AI code, including TDD, security patterns, and mutation testing
- **[Deployment and DevOps for AI-Powered Applications](ai-app-deployment-devops.md)** — Production deployment patterns, monitoring, cost control, and incident response
- **[Hooks & Enforcement Patterns](hooks-enforcement-patterns.md)** — Using git hooks and CI hooks to enforce standards, security, and workflow discipline
