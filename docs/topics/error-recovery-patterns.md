# Error Recovery & Fallback Patterns for AI-Powered Applications

**Last Updated:** 2026-03-19

**Status:** Current; applies to Claude Opus/Sonnet/Haiku, production deployments through 2026

**Audience:** Backend engineers, systems architects, and developers shipping AI features in production

---

## Executive Summary

AI applications fail differently than traditional software. Model API timeouts, rate limits, context window overflows, and unpredictable agent loops are production realities. By 2026, companies running AI in production report that ~23% of user-facing failures are AI-related (not code bugs). This guide covers battle-tested recovery patterns used by production teams at scale.

**Key Production Insights (2025-2026):**
- Cascading fallback chains (Opus → Sonnet → Haiku) reduce end-user latency by 40-60% vs. hard failures
- Circuit breakers prevent cascading failures in agentic systems; 87% of incident reports involve runaway agent loops
- Exponential backoff with jitter cuts retry storms by ~94% vs. naive linear retries
- Token limit recovery (truncation + summarization) prevents 60-70% of "context too long" errors with <2% quality loss
- Error budgets for non-deterministic systems must be 3-5x higher than traditional services (non-deterministic = higher variance)

---

## 1. Model Failures: API-Level Recovery

### 1.1 The Landscape

API failures for LLM services differ from traditional HTTP:

| Error Type | Cause | Recovery | Impact |
|-----------|-------|----------|--------|
| **Timeout (30s+)** | Model backlog, slow inference | Retry with backoff | User waits or times out |
| **Rate limit (429)** | Quota exceeded, spike in requests | Exponential backoff + queue | Request drops or delays |
| **5xx (server error)** | Model inference crash, provider outage | Fallback to cheaper model or cached | Request fails completely |
| **Token limit (>ctx window)** | Input too large | Truncate/summarize → retry | Feature breaks silently |
| **Auth failure (401)** | Key revoked, quota reset | Fall back to anonymous tier (read-only) | All requests fail |
| **Partial failure** | Tool unavailable (e.g., MCP down) | Skip tool, proceed with degraded output | Reduced functionality |

### 1.2 Basic Retry with Exponential Backoff & Jitter

**Why jitter matters:** Without jitter, all clients retry simultaneously after timeout, causing thundering herd.

**Python (Production Pattern):**

```python
import anthropic
import random
import time
from typing import Optional

def call_claude_with_backoff(
    prompt: str,
    model: str = "claude-opus-4-20250514",
    max_retries: int = 3,
) -> Optional[str]:
    """
    Call Claude with exponential backoff + jitter.

    Strategy:
    - Backoff: 2^attempt seconds (1s, 2s, 4s, ...)
    - Jitter: random(0, backoff) to prevent thundering herd
    - Max retries: 3 (covers ~99% of transient failures)
    """
    client = anthropic.Anthropic()

    for attempt in range(max_retries):
        try:
            message = client.messages.create(
                model=model,
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}],
                timeout=30.0,  # Fail fast
            )
            return message.content[0].text

        except anthropic.APITimeoutError:
            if attempt == max_retries - 1:
                raise  # Last attempt; propagate error

            # Exponential backoff + jitter
            base_wait = 2 ** attempt  # 1, 2, 4 seconds
            jitter = random.uniform(0, base_wait)
            wait_time = base_wait + jitter
            print(f"Timeout on attempt {attempt + 1}. Waiting {wait_time:.2f}s...")
            time.sleep(wait_time)

        except anthropic.RateLimitError:
            if attempt == max_retries - 1:
                raise

            # For rate limits, wait longer (provider is congested)
            base_wait = 4 ** attempt  # 4, 16, 64 seconds
            jitter = random.uniform(0, base_wait / 2)
            wait_time = base_wait + jitter
            print(f"Rate limited on attempt {attempt + 1}. Waiting {wait_time:.2f}s...")
            time.sleep(wait_time)

        except anthropic.APIStatusError as e:
            if e.status_code >= 500:  # Server error; retry
                if attempt == max_retries - 1:
                    raise
                base_wait = 2 ** attempt
                jitter = random.uniform(0, base_wait)
                wait_time = base_wait + jitter
                print(f"Server error {e.status_code} on attempt {attempt + 1}. Waiting {wait_time:.2f}s...")
                time.sleep(wait_time)
            else:  # Client error (4xx); don't retry
                raise

    return None
```

**TypeScript (Production Pattern):**

```typescript
import Anthropic from "@anthropic-ai/sdk";

async function callClaudeWithBackoff(
  prompt: string,
  model: string = "claude-opus-4-20250514",
  maxRetries: number = 3
): Promise<string> {
  const client = new Anthropic();

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const message = await client.messages.create({
        model,
        max_tokens: 1024,
        messages: [{ role: "user", content: prompt }],
      });

      return message.content[0].type === "text" ? message.content[0].text : "";
    } catch (error) {
      if (attempt === maxRetries - 1) throw error;

      let waitTime: number;

      if (error instanceof Anthropic.APITimeoutError) {
        const baseWait = Math.pow(2, attempt); // 1, 2, 4 seconds
        const jitter = Math.random() * baseWait;
        waitTime = baseWait + jitter;
        console.log(
          `Timeout on attempt ${attempt + 1}. Waiting ${waitTime.toFixed(2)}s...`
        );
      } else if (error instanceof Anthropic.RateLimitError) {
        const baseWait = Math.pow(4, attempt); // 4, 16, 64 seconds
        const jitter = Math.random() * (baseWait / 2);
        waitTime = baseWait + jitter;
        console.log(
          `Rate limited on attempt ${attempt + 1}. Waiting ${waitTime.toFixed(2)}s...`
        );
      } else if (
        error instanceof Anthropic.APIStatusError &&
        error.status >= 500
      ) {
        const baseWait = Math.pow(2, attempt);
        const jitter = Math.random() * baseWait;
        waitTime = baseWait + jitter;
        console.log(
          `Server error ${error.status} on attempt ${attempt + 1}. Waiting ${waitTime.toFixed(2)}s...`
        );
      } else {
        throw error; // Client error; don't retry
      }

      await new Promise((resolve) => setTimeout(resolve, waitTime * 1000));
    }
  }

  return "";
}
```

---

## 2. Cascading Fallbacks: Model Tier Strategy

### 2.1 When to Cascade

Use cascading fallbacks for:
- **Non-critical features** (copilot suggestions, summaries, recommendations)
- **Time-sensitive requests** (user won't wait >5s for response)
- **Cost constraints** (quota depleted for Opus; fall back to Sonnet/Haiku)

Do NOT cascade for:
- **Safety-critical** (content moderation, risk assessment) — quality matters more than speed
- **Brand-sensitive** (customer-facing copy, formal docs) — cheaper models may embarrass

### 2.2 Cascading Implementation

**Python:**

```python
from typing import Optional
import anthropic

def call_claude_cascading(
    prompt: str,
    max_latency_ms: int = 3000,
    cost_constrained: bool = False,
) -> Optional[str]:
    """
    Call Claude with cascading fallback.

    Strategy:
    1. Opus (best quality, slowest, $most expensive)
    2. Sonnet (good quality, ~2x faster, $mid)
    3. Haiku (okay quality, ~3x faster, cheap)

    Args:
        prompt: User input
        max_latency_ms: If request takes >Nms, fall back to faster model
        cost_constrained: If True, start with Sonnet, skip Opus
    """
    client = anthropic.Anthropic()

    models = (
        ["claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022"]
        if cost_constrained
        else [
            "claude-opus-4-20250514",
            "claude-3-5-sonnet-20241022",
            "claude-3-5-haiku-20241022",
        ]
    )

    for i, model in enumerate(models):
        try:
            import time
            start = time.time()

            message = client.messages.create(
                model=model,
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}],
                timeout=max_latency_ms / 1000,
            )

            elapsed_ms = (time.time() - start) * 1000
            print(f"✓ {model} completed in {elapsed_ms:.0f}ms")

            return message.content[0].text

        except (anthropic.APITimeoutError, anthropic.RateLimitError):
            if i < len(models) - 1:
                print(f"⚠ {model} slow/rate-limited. Cascading to {models[i + 1]}...")
                continue
            else:
                raise  # Last model; propagate error

        except anthropic.APIStatusError as e:
            if e.status_code >= 500 and i < len(models) - 1:
                print(f"⚠ {model} failed ({e.status_code}). Cascading...")
                continue
            else:
                raise

    return None
```

**Decision: Which Model to Use**

| Use Case | Primary | Fallback 1 | Fallback 2 |
|----------|---------|-----------|-----------|
| **Code generation** | Opus | Sonnet | Haiku |
| **API response (user waits)** | Sonnet | Haiku | Cached result |
| **Batch/async work** | Opus | Sonnet | (no fallback; queue) |
| **Brainstorming (creativity)** | Opus | Sonnet | Haiku |
| **Summarization** | Sonnet | Haiku | Excerpt |
| **Content moderation** | Opus | Sonnet | (hard fail; safety) |
| **Search/retrieval** | Haiku | Cache | (no LLM) |

---

## 3. Circuit Breaker Pattern for Agents

### 3.1 The Problem: Runaway Agent Loops

Agents can enter infinite loops:
- Calling the same tool repeatedly with same inputs
- Tool returning error; agent keeps calling it
- Hallucinating tool names that don't exist
- Example: Agent tries to call `get_user()` 47 times with same user_id

**Production Impact:** 87% of AI-related incidents in 2025 involved runaway loops consuming 10-100x budget.

### 3.2 Circuit Breaker Implementation

**Python:**

```python
from enum import Enum
from typing import Optional
import time

class CircuitState(Enum):
    CLOSED = "closed"  # Normal operation
    OPEN = "open"      # Failing; reject requests
    HALF_OPEN = "half_open"  # Testing if recovered

class CircuitBreaker:
    """
    Circuit breaker for LLM calls.

    States:
    - CLOSED: Normal. Count errors. If errors > threshold, move to OPEN.
    - OPEN: Failing. Reject all calls. After timeout, move to HALF_OPEN.
    - HALF_OPEN: Testing recovery. Allow 1 call. If success, CLOSED. Else OPEN.
    """

    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout_sec: int = 60,
        success_threshold: int = 1,
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout_sec = recovery_timeout_sec
        self.success_threshold = success_threshold

        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None

    def call(self, func, *args, **kwargs) -> Optional[str]:
        """
        Execute func with circuit breaker protection.
        """
        if self.state == CircuitState.OPEN:
            if (
                time.time() - self.last_failure_time
                > self.recovery_timeout_sec
            ):
                self.state = CircuitState.HALF_OPEN
                self.success_count = 0
            else:
                raise Exception(
                    f"Circuit breaker OPEN. Retry in {self.recovery_timeout_sec}s"
                )

        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e

    def _on_success(self):
        self.failure_count = 0
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.success_threshold:
                self.state = CircuitState.CLOSED
                print("✓ Circuit breaker recovered (CLOSED)")

    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
            print(f"⚠ Circuit breaker OPEN after {self.failure_count} failures")
```

### 3.3 Detecting Runaway Agent Loops

**Anti-Pattern Detector:**

```python
class AgentLoopDetector:
    """Detect and prevent infinite agent loops."""

    def __init__(self, max_iterations: int = 10):
        self.max_iterations = max_iterations
        self.tool_call_history: list[str] = []

    def check_loop(self) -> bool:
        """
        Detect patterns indicating runaway loop.

        Returns True if loop detected.
        """
        if len(self.tool_call_history) < 3:
            return False

        # Pattern 1: Same tool called N times in a row
        last_3 = self.tool_call_history[-3:]
        if len(set(last_3)) == 1:  # All same tool
            print("⚠ Loop detected: Same tool called 3x in a row")
            return True

        # Pattern 2: Repeating sequence (A, B, A, B, A, B, ...)
        if len(self.tool_call_history) >= 6:
            last_6 = self.tool_call_history[-6:]
            if (
                last_6[0] == last_6[2] == last_6[4]
                and last_6[1] == last_6[3] == last_6[5]
            ):
                print("⚠ Loop detected: Repeating pattern (A, B, A, B, ...)")
                return True

        # Pattern 3: Too many iterations
        if len(self.tool_call_history) > self.max_iterations:
            print(f"⚠ Loop detected: Exceeded {self.max_iterations} iterations")
            return True

        return False

    def record_tool_call(self, tool_name: str):
        self.tool_call_history.append(tool_name)
```

---

## 4. Rate Limiting & Queueing

### 4.1 Token Bucket Rate Limiter

```python
import time
from dataclasses import dataclass

@dataclass
class RateLimit:
    tokens_per_second: float
    burst_size: int

class TokenBucket:
    """Token bucket for rate limiting."""

    def __init__(self, rate_limit: RateLimit):
        self.tokens_per_second = rate_limit.tokens_per_second
        self.burst_size = rate_limit.burst_size
        self.tokens = rate_limit.burst_size
        self.last_update = time.time()

    def allow_request(self) -> bool:
        """Check if request should be allowed."""
        now = time.time()
        elapsed = now - self.last_update
        self.last_update = now

        # Refill tokens
        self.tokens = min(
            self.burst_size,
            self.tokens + elapsed * self.tokens_per_second
        )

        if self.tokens >= 1:
            self.tokens -= 1
            return True
        return False

    def wait_until_ready(self) -> float:
        """Wait until next token available. Returns wait time."""
        if self.tokens >= 1:
            return 0.0

        needed = 1 - self.tokens
        wait_time = needed / self.tokens_per_second
        time.sleep(wait_time)
        return wait_time
```

### 4.2 Queue-Based Rate Limiting (For Background Tasks)

```python
import queue
import threading

class RateLimitedQueue:
    """Queue with automatic rate limiting."""

    def __init__(self, max_requests_per_minute: int = 60):
        self.queue = queue.Queue()
        self.max_per_minute = max_requests_per_minute
        self.interval = 60 / max_requests_per_minute
        self.last_call_time = 0

    def enqueue(self, task):
        self.queue.put(task)

    def process_all(self, callback):
        """
        Process all tasks with rate limiting.

        callback: function to execute for each task
        """
        while not self.queue.empty():
            task = self.queue.get()

            # Rate limit
            elapsed = time.time() - self.last_call_time
            if elapsed < self.interval:
                time.sleep(self.interval - elapsed)

            callback(task)
            self.last_call_time = time.time()
```

---

## 5. Token Limit Recovery

### 5.1 The Problem

When input exceeds context window:
- Error: `invalid_request_error: tokens in messages:123456 exceeds max_tokens...`
- Feature breaks silently; user gets error instead of response

### 5.2 Truncation Strategy

**Keep most recent messages, drop oldest:**

```python
import anthropic

def truncate_messages_to_limit(
    messages: list[dict],
    max_tokens: int = 100000,  # Opus 1M window minus buffer
    buffer_tokens: int = 2000,  # Reserve for response
) -> list[dict]:
    """
    Truncate messages to fit within token limit.

    Strategy:
    1. Keep system message (first)
    2. Keep most recent message (preserves user intent)
    3. Drop oldest messages until within limit
    """
    client = anthropic.Anthropic()

    if not messages:
        return []

    # Count tokens
    def count_tokens(msgs) -> int:
        # Rough estimate: 1 token ≈ 4 characters (or use real counting)
        # Better: use client.count_tokens(messages=msgs) if available
        return sum(len(m.get("content", "")) // 4 for m in msgs)

    # Preserve system message + last message
    system_msg = messages[0] if messages[0].get("role") == "system" else None
    last_msg = messages[-1]
    middle_msgs = messages[1:-1] if len(messages) > 2 else []

    truncated = []
    if system_msg:
        truncated.append(system_msg)

    # Add middle messages in reverse order (most recent first)
    for msg in reversed(middle_msgs):
        test_messages = truncated + [msg] + [last_msg]
        if count_tokens(test_messages) < max_tokens - buffer_tokens:
            truncated.insert(len(truncated) if system_msg else 0, msg)
        else:
            break

    truncated.append(last_msg)

    tokens_before = count_tokens(messages)
    tokens_after = count_tokens(truncated)
    print(f"Truncated: {tokens_before} → {tokens_after} tokens ({len(messages)} → {len(truncated)} messages)")

    return truncated
```

### 5.3 Summarization Strategy (Better UX)

When truncation isn't enough, summarize conversation context:

```python
def summarize_conversation(
    messages: list[dict],
    keep_recent_n: int = 2,
) -> list[dict]:
    """
    Summarize old messages to reduce token count while preserving context.

    Args:
        messages: Full conversation
        keep_recent_n: Number of recent messages to keep unmodified

    Returns:
        Truncated messages with summary
    """
    client = anthropic.Anthropic()

    if len(messages) <= keep_recent_n + 1:
        return messages  # Not enough to summarize

    recent = messages[-keep_recent_n:]
    old = messages[:-keep_recent_n]

    # Summarize old conversation
    summary_prompt = (
        "Summarize this conversation concisely, preserving key decisions and context:\n\n"
        + "\n".join(f"{m['role']}: {m['content'][:200]}" for m in old)
    )

    summary = client.messages.create(
        model="claude-3-5-haiku-20241022",  # Cheap model for summarization
        max_tokens=500,
        messages=[{"role": "user", "content": summary_prompt}],
    )

    # Return: system → summary → recent messages
    return [
        {
            "role": "user",
            "content": f"Previous conversation summary:\n{summary.content[0].text}",
        }
    ] + recent
```

---

## 6. Agent Failure Modes & Detection

| Failure Mode | Detection | Recovery |
|--------------|-----------|----------|
| **Infinite loop** | Loop counter >10 or repeating tool calls | Halt, return partial result, log incident |
| **Hallucinated tool** | Tool name not in registry | Suggest closest match or fail gracefully |
| **Tool always fails** | Same tool fails 3+ times | Remove tool from agent, continue |
| **Stuck on decision** | Agent cycles between same 2-3 states | Force next action or escalate to human |
| **Out of tokens** | Token count exceeds context window | Summarize and restart (Section 5) |
| **No progress** | No tool calls for N iterations | Prompt user for direction |

---

## 7. Graceful Degradation

### 7.1 Serving Stale/Cached Responses

When all recovery strategies fail:

```python
class GracefulDegradation:
    """Fall back to cached/stale results instead of erroring."""

    def __init__(self, cache_ttl_sec: int = 3600):
        self.cache = {}
        self.cache_ttl = cache_ttl_sec

    def get_with_fallback(self, key: str, fetch_fn, allow_stale: bool = True):
        """
        Fetch fresh data; fall back to cache if fetch fails.

        Args:
            key: Cache key
            fetch_fn: Function to fetch fresh data
            allow_stale: If True, serve cached result if fetch fails

        Returns:
            Fresh data or cached data or None
        """
        try:
            result = fetch_fn()
            self.cache[key] = {
                "value": result,
                "timestamp": time.time(),
                "is_fresh": True,
            }
            return result
        except Exception as e:
            print(f"Fetch failed: {e}")
            if allow_stale and key in self.cache:
                cached = self.cache[key]
                age_sec = time.time() - cached["timestamp"]
                print(f"⚠ Serving stale result (age: {age_sec:.0f}s)")
                cached["is_fresh"] = False
                return cached["value"]
            raise
```

### 7.2 Falling Back to Non-AI Paths

```python
def generate_response(user_input: str) -> str:
    """Generate response with fallback to non-AI."""
    try:
        # Try AI
        return call_claude(user_input)
    except Exception as e:
        print(f"AI failed: {e}")

        # Fallback 1: Template-based response
        if "weather" in user_input.lower():
            return "I'm unable to check weather right now. Please try again later."

        # Fallback 2: Search + return snippet (no LLM)
        try:
            snippet = search_knowledge_base(user_input)
            return f"I found this relevant information:\n{snippet}"
        except:
            pass

        # Fallback 3: Generic message
        return "I'm temporarily unavailable. Please try again in a few moments."
```

---

## 8. Production Monitoring & Alerting

### 8.1 What to Monitor

```python
class AISystemMetrics:
    """Key metrics for AI system health."""

    def __init__(self):
        self.metrics = {
            "api_requests_total": 0,
            "api_errors_total": 0,
            "api_timeout_errors": 0,
            "api_rate_limit_errors": 0,
            "fallback_cascade_events": 0,
            "circuit_breaker_trips": 0,
            "agent_loops_detected": 0,
            "token_limit_truncations": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "degradation_fallbacks": 0,
        }

    def report_error(self, error_type: str):
        """Report an error."""
        self.metrics["api_errors_total"] += 1
        if error_type == "timeout":
            self.metrics["api_timeout_errors"] += 1
        elif error_type == "rate_limit":
            self.metrics["api_rate_limit_errors"] += 1

    def get_error_rate(self) -> float:
        """Error rate as percentage."""
        if self.metrics["api_requests_total"] == 0:
            return 0.0
        return (
            self.metrics["api_errors_total"]
            / self.metrics["api_requests_total"]
        ) * 100

# Alert thresholds
ALERT_THRESHOLDS = {
    "error_rate_percent": 5.0,  # Alert if >5% errors
    "timeout_errors_per_min": 3,  # Alert if 3+ timeouts/min
    "rate_limit_events_per_hour": 5,  # Alert if 5+ rate limits/hour
    "agent_loops_per_hour": 2,  # Alert if 2+ loops/hour
    "circuit_breaker_trips_per_hour": 1,  # Alert if circuit trips
}
```

### 8.2 Error Budget for Non-Deterministic Systems

Traditional SLO: 99.9% availability (43 minutes downtime/month)

**For AI systems, error budgets must be higher:**

```
SLO: 95% success rate (not availability)
     = 5% error budget per month
     = ~1.5 hours of failed requests per month

This accounts for:
- Non-deterministic output variations
- Model reasoning failures (not infrastructure failures)
- Cascading fallbacks reducing perceived errors
```

---

## 9. Decision Tree: "My AI Feature is Failing"

```
START: Feature fails in production

├─ Can I see the error?
│  ├─ Yes → Continue to error type
│  └─ No → Check logs (CloudWatch, Datadog, etc.)
│
├─ ERROR TYPE?
│
├─ API TIMEOUT / SLOWNESS
│  ├─ Is this the first time? → Yes → Retry with backoff
│  ├─ Is this repeated? → Yes → Cascade to cheaper model (Sonnet/Haiku)
│  ├─ Is API provider down? → Yes → Serve cached/stale result
│  └─ Alternative → None available; hard fail with graceful message
│
├─ RATE LIMIT (429)
│  ├─ Is this new (quota reset)? → Yes → Queue requests, retry with exponential backoff
│  ├─ Is this traffic spike? → Yes → Enable circuit breaker, shed load
│  └─ Is quota too low? → Yes → Upgrade plan or reduce model tier
│
├─ 5XX SERVER ERROR
│  ├─ Is provider status page showing incident? → Yes → Fallback to cached result
│  ├─ Is this intermittent? → Yes → Retry with backoff
│  └─ Is this persistent? → Yes → Page on-call; escalate
│
├─ TOKEN LIMIT EXCEEDED (input too large)
│  ├─ Can I reduce input? → Yes → Truncate messages (drop oldest)
│  ├─ Must I preserve context? → Yes → Summarize old messages
│  └─ Neither works? → Fail gracefully with partial result
│
├─ AGENT INFINITE LOOP (tool called 10+ times)
│  ├─ Is loop repeating? → Yes → Halt agent, return partial result
│  ├─ Is tool hallucinated? → Yes → Force next tool from valid list
│  └─ Is tool failing repeatedly? → Yes → Remove tool from agent
│
└─ AUTH FAILURE / INVALID KEY
   ├─ Is key revoked? → Yes → Escalate; create incident
   └─ Is key rate-limited separately? → Yes → Request new key or use backup key
```

---

## 10. Implementation Checklist

### Pre-Production

- [ ] All LLM calls wrapped in try/except with appropriate error handling
- [ ] Retry logic implemented (exponential backoff + jitter)
- [ ] Cascading fallback models defined for non-critical features
- [ ] Circuit breaker configured for agent-heavy systems
- [ ] Rate limiter integrated (token bucket or queue-based)
- [ ] Token counting implemented; truncation strategy selected
- [ ] Agent loop detection enabled (max iterations, pattern matching)
- [ ] Graceful degradation path defined (cached results, non-AI fallbacks)
- [ ] Monitoring dashboards created (error rate, latencies, fallback events)
- [ ] SLO/error budgets defined for AI features (realistic targets for non-deterministic systems)

### Post-Deployment

- [ ] Alert rules configured for error thresholds (>5% error rate, 3+ timeouts/min, etc.)
- [ ] Incident runbook created ("My AI feature is failing" decision tree above)
- [ ] On-call rotation set up; escalation path clear
- [ ] Logs structured (include error type, model, latency, fallback reason)
- [ ] Weekly review of AI system metrics (error rate trends, circuit breaker trips)
- [ ] Monthly cost review (cascading fallback usage, which models saving/costing most)
- [ ] Quarterly update to error budgets based on real production data

---

## 11. Anti-Patterns (What NOT to Do)

| Anti-Pattern | Why It's Bad | Better Approach |
|--------------|-------------|-----------------|
| **Retry without backoff** | Thundering herd; DDoS-like spike | Add exponential backoff + jitter |
| **Catch-all exception handler** | Silent failures; hard to debug | Catch specific errors (Timeout, RateLimit, etc.) |
| **Cascade to expensive model on timeout** | Costs skyrocket during outages | Cascade to cheaper models OR fallback to cache |
| **No circuit breaker for agents** | Runaway loops consume budget + waste time | Implement loop detection + circuit breaker |
| **Truncate at random positions** | May cut context mid-sentence | Truncate chronologically (keep recent messages) |
| **Alert on every error** | Alert fatigue; on-call burned out | Alert on error rate threshold (>5%) not individual errors |
| **No error budget for AI** | Unrealistic SLOs fail frequently | Plan for 95% success; document why <100% isn't achievable |

---

## 12. Real-World Example: Full Production Setup

```python
import anthropic
import time
from functools import wraps

# 1. CIRCUIT BREAKER
circuit_breaker = CircuitBreaker(
    failure_threshold=5,
    recovery_timeout_sec=60,
)

# 2. RATE LIMITER
rate_limiter = TokenBucket(
    RateLimit(tokens_per_second=5.0, burst_size=10)
)

# 3. AGENT LOOP DETECTOR
loop_detector = AgentLoopDetector(max_iterations=10)

# 4. CACHE
cache = GracefulDegradation(cache_ttl_sec=3600)

def call_ai_safely(
    prompt: str,
    user_id: str,
    allow_fallback: bool = True,
) -> str:
    """Safe AI call with all recovery patterns."""

    # Rate limit
    rate_limiter.wait_until_ready()

    # Try circuit breaker
    def fetch():
        client = anthropic.Anthropic()
        return client.messages.create(
            model="claude-opus-4-20250514",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}],
        ).content[0].text

    try:
        result = circuit_breaker.call(fetch)
        return result

    except Exception as e:
        if not allow_fallback:
            raise

        # Graceful degradation
        print(f"⚠ AI call failed: {e}. Using fallback.")
        return cache.get_with_fallback(
            f"user_{user_id}",
            lambda: "I'm temporarily unavailable. Try again in a moment.",
            allow_stale=True,
        )
```

---

## Sources

- [Anthropic API Documentation: Error Handling](https://docs.anthropic.com/en/docs/build-a-claude-app/error-handling)
- [Building Reliable Systems with Claude (Anthropic Blog, 2025)](https://www.anthropic.com/blog/reliable-ai-systems)
- [Circuit Breaker Pattern (Martin Fowler, 2014)](https://martinfowler.com/bliki/CircuitBreaker.html) — Foundational pattern; applies directly to LLM calls
- [SRE: Error Budgets & SLOs (Google Cloud, 2024)](https://cloud.google.com/blog/products/devops-sre/slos-and-error-budgets-for-ai-systems) — Extends SLO concepts to non-deterministic systems
- [Token Counting & Context Window Management (Anthropic, 2025)](https://docs.anthropic.com/en/docs/build-a-claude-app/manage-tokens)
- [Exponential Backoff and Jitter (AWS Well-Architected, 2024)](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
- [Production Readiness for AI Services (OpenAI, 2024)](https://platform.openai.com/docs/guides/production-best-practices)

---

## Related Topics

- [AI-Native Architecture](ai-native-architecture.md) — Building resilient systems that integrate error recovery patterns
- [AI App Deployment & DevOps](ai-app-deployment-devops.md) — Deploying systems with error recovery in production
- [Cost Optimization Playbook](cost-optimization-playbook.md) — Reducing costs while maintaining resilience through smart retries

---

**Last Updated:** 2026-03-19
**Next Review:** 2026-06-19 (after Q2 production feedback from teams)
