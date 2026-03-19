# Unified Decision Trees: Resolving Cross-Document Conflicts

**Last Updated:** 2026-03-19
**Status:** Synthesis document resolving contradictions across knowledge base
**Confidence Level:** High (direct contradiction resolution with unified frameworks)

---

## Executive Summary

The knowledge base contains four apparent contradictions that stem from different scopes, metrics, and mechanisms. This document unifies them into actionable decision trees. Key insight: **contradictions often reflect different layers of the same system**, not conflicting advice.

---

## 1. When to Use Agents vs. Simple Functions

### The Contradiction

- **ai-native-architecture.md** warns: "Using agents when a simple function call suffices" is an antipattern. Simple tasks (classification, extraction) run faster and cheaper with function calling.
- **swarm-patterns-by-dev-stage.md** recommends multi-agent patterns for every development stage, implying agents are broadly applicable.

### The Resolution

These apply to **different task dimensions**:

- **Function calls** excel at: deterministic, single-step operations with clear inputs/outputs
- **Agents** excel at: multi-step reasoning, tool orchestration, adaptive decision-making

### Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│ Does the task require multi-step reasoning or adaptation?   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
├─ YES (task branches, loops back, uses multiple tools)       │
│   └─> Use Agent (LangGraph, CrewAI, or Claude with tools)   │
│       • Cost: Higher per task                               │
│       • Value: Better reasoning, fewer errors on complex    │
│       • Example: code review, architecture decision         │
│                                                              │
└─ NO (single-step, deterministic, clear input→output)        │
    └─> Use Simple Function Call                              │
        • Cost: 5-10x cheaper                                 │
        • Latency: 30-50% faster                              │
        • Example: classify ticket type, extract metadata     │
```

### When Each Wins

| Task Type | Tool | Reasoning |
|-----------|------|-----------|
| Classify ticket from email | Function | Single decision, no branching |
| Extract metadata | Function | Known schema, deterministic |
| Debug failing test | Agent | Multi-step (reproduce → analyze → suggest fix) |
| Code review | Agent | Multi-step (read code → apply patterns → check edge cases) |
| Quick rename | Function | No reasoning needed |
| Architecture decision | Agent | Requires context gathering, tradeoff analysis |

---

## 2. Optimization Sequencing: What to Do First

### The Contradiction

- **ai-native-architecture.md** says: Start with prompt engineering → add RAG
- **cost-optimization-playbook.md** says: Start with model routing → caching
- **prompt-engineering-patterns.md** says: Structured prompts as default

All are correct. The question is: **in what order for ROI?**

### The Resolution

Optimize in this sequence. Earlier steps are **prerequisites** for later ones:

```
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: Structured Prompts                                  │
├──────────────────────────────────────────────────────────────┤
│ • Effort: 15 minutes                                         │
│ • ROI: 25-35% token savings, free                            │
│ • Why first: Baseline for all later optimizations            │
│ • Do: Replace vague requests with specifications             │
│ • Pattern: task description → context → format → criteria    │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│ STEP 2: Model Routing (Haiku → Sonnet → Opus)               │
├──────────────────────────────────────────────────────────────┤
│ • Effort: 30 minutes                                         │
│ • ROI: 50-60% cost savings (biggest ROI/effort ratio)        │
│ • Why second: Requires structured prompts to work well       │
│ • Do: Classify task → pick model → route                     │
│ • Pattern: simple tasks → Haiku, complex → Sonnet/Opus      │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│ STEP 3: Prompt Caching                                      │
├──────────────────────────────────────────────────────────────┤
│ • Effort: 1 hour                                             │
│ • ROI: 80-90% discount on cached token reads                 │
│ • Why third: Only works if you have repeated requests        │
│ • Do: Identify stable context → cache → read for 90% off    │
│ • Pattern: system context + tools + examples (cache) +       │
│           user query (fresh)                                 │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│ STEP 4: Semantic Caching (Application-Level)                │
├──────────────────────────────────────────────────────────────┤
│ • Effort: 2-3 hours (embeddings + Redis/local DB)           │
│ • ROI: 40-70% hit rate on **similar** queries                │
│ • Why fourth: Requires Step 1-3 working first; adds          │
│             infrastructure complexity                       │
│ • Do: Embed queries → find similar cached results            │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│ STEP 5: RAG (Retrieval-Augmented Generation)                │
├──────────────────────────────────────────────────────────────┤
│ • Effort: 4-6 hours (embeddings + vector DB setup)          │
│ • ROI: Only if accuracy plateaus without it                  │
│ • Why last: Expensive to implement; rarely needed after      │
│           Steps 1-4 if your prompt is well-structured       │
│ • Do: Only add if structured prompt + context cannot find    │
│       the information needed                                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Practical Example

**Scenario:** Building a codebase Q&A system

1. **Structured prompt** (15 min): "Answer this question about our codebase. Context: [files]. Question: [user query]. Format: [clear steps]. Criteria: [accuracy requirements]."
   → Result: 35% fewer hallucinations, 40% fewer follow-up requests

2. **Model routing** (30 min): Classification → simple questions (Haiku) vs. complex analysis (Sonnet)
   → Result: 55% cost reduction

3. **Prompt caching** (1 hour): Cache codebase context + system instructions. User queries are fresh.
   → Result: 90% discount on cached tokens (especially for repeated queries within a session)

4. **Semantic caching** (optional): Cache past Q&A pairs. If new query is similar (>0.85 cosine), return cached answer.
   → Result: 60% hit rate on typical corporate Q&A patterns

5. **RAG** (skip if Steps 1-4 work): Only if users ask about files outside your cached context window.

---

## 3. Cache Effectiveness: Understanding Different Mechanisms

### The Contradiction

- One file says "90% discount"
- Another says "20-50% savings"
- Another says "40-70% hit rate"

### The Resolution

These describe **three different mechanisms** operating at different layers:

```
┌────────────────────────────────────────────────────────────────┐
│ MECHANISM 1: Prompt Caching (Anthropic API Feature)            │
├────────────────────────────────────────────────────────────────┤
│ • What: API-level caching of input tokens                      │
│ • Discount: 90% on cached token reads (0.1x base rate)         │
│ • When: Same system context used 2+ times in 5 min window      │
│ • Cost example:                                                │
│   - Write 10K tokens (system + examples): 1.25x base = 12,500$ │
│   - Read same 10K 5x (user varies): 10K × 0.1x × 5 = $5,000   │
│   - Total: $17,500 vs $75,000 without cache = 77% savings      │
│ • Hit rate: Close to 100% if tasks are similar                 │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│ MECHANISM 2: Semantic Caching (Application-Level)              │
├────────────────────────────────────────────────────────────────┤
│ • What: App-level caching of responses for similar queries     │
│ • Hit rate: 40-70% on real-world corporate queries             │
│ • Cost savings: (hit_rate × cost_avoided) - (embedding_cost)   │
│   - Hit rate 60% + embedding cost overhead = 20-50% net savings│
│ • When: Same domain, many similar queries (support tickets)    │
│ • Cost example:                                                │
│   - Miss (call API): $0.10                                     │
│   - Hit (return cached): $0.001 embedding lookup               │
│   - 60% hit rate: (0.4 × 0.10) + (0.6 × 0.001) = $0.041       │
│   - Savings: $0.059 per query = 59% reduction                  │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│ MECHANISM 3: Combined System Savings (Real-World)              │
├────────────────────────────────────────────────────────────────┤
│ • What: (1) + (2) + structured prompts + model routing         │
│ • Savings: 20-50% of total bill (after accounting for overhead)│
│ • When: You're doing Steps 1-3 correctly                       │
│ • Cost example (monthly):                                      │
│   - Naive (all Sonnet, vague prompts): $2,000                  │
│   - After Step 1-3 optimization: $400-1,000 = 50-80% savings   │
│   - Individual mechanism gains compound (not linear)           │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Quick Reference

| Mechanism | Savings | When to Use | Complexity |
|-----------|---------|------------|------------|
| Prompt caching | 90% on reads | Same context, 2+ queries in 5 min | Low |
| Semantic caching | 40-70% hit rate, 20-50% net savings | Similar queries over time | Medium |
| Combined system | 50-80% total bill reduction | All mechanisms + routing | High |

---

## 4. Evaluation Thresholds: Statistical Significance for Accuracy Gates

### The Contradiction

- One file says "gate if accuracy drops >3%"
- Another says "measure on 100+ examples" without a threshold
- Implication: What's the real threshold for statistical significance?

### The Resolution

The 3% threshold is **valid only with 200+ samples**. With 100 samples, use **5%** threshold instead.

#### Statistical Significance Table

```
┌──────────────┬──────────────┬──────────────┬──────────────────┐
│ Sample Size  │ 3% Threshold │ 5% Threshold │ Interpretation   │
├──────────────┼──────────────┼──────────────┼──────────────────┤
│ 50 samples   │ ✗ TOO SMALL  │ ✗ TOO SMALL  │ ~1-2 failures    │
│              │              │              │ = noise          │
│              │              │              │                  │
│ 100 samples  │ ✗ RISKY      │ ✓ OK         │ 3 failures = 3%  │
│              │ (3 failures) │ (5 failures) │ borderline; use  │
│              │              │              │ 5% threshold     │
│              │              │              │                  │
│ 200 samples  │ ✓ OK         │ ✓ OK         │ 6 failures = 3%  │
│              │ (6 failures) │ (10 failures)│ confidence ~95%  │
│              │              │              │                  │
│ 500 samples  │ ✓ EXCELLENT  │ ✓ EXCELLENT  │ 15 failures = 3% │
│              │ (15 failures)│ (25 failures)│ confidence ~99%  │
│              │              │              │                  │
│ 1000+ samples│ ✓ DEFINITIVE │ ✓ DEFINITIVE │ <1% error margin │
│              │ (30+ failures)│(50+ failures)│ on both metrics  │
└──────────────┴──────────────┴──────────────┴──────────────────┘
```

### Decision Tree for Evaluation Gates

```
┌────────────────────────────────────────────────────────┐
│ How many test examples can you create?                 │
├────────────────────────────────────────────────────────┤
│                                                         │
├─ < 100                                                 │
│  └─> Manual review only (not statistical)              │
│      → Skip automated threshold gates                   │
│      → Use human judgment                              │
│                                                         │
├─ 100-199 examples                                      │
│  └─> Use 5% threshold for gating                        │
│      → If accuracy drops 5%: investigate               │
│      → If drops 3%: retest with more samples           │
│                                                         │
├─ 200-500 examples                                      │
│  └─> Use 3% threshold                                  │
│      → 95% confidence in the result                     │
│      → Gate failures: review for regression            │
│                                                         │
└─ 500+ examples                                          │
   └─> Use 2% threshold (optional; 99% confidence)       │
       → Tight control; good for safety-critical code    │
```

### Practical Implementation

```python
def evaluate_with_threshold(test_samples, baseline_accuracy, threshold=0.03):
    """
    Args:
        test_samples: list of (input, expected_output)
        baseline_accuracy: accuracy % from previous version
        threshold: 0.03 (3%) for 200+ samples, 0.05 (5%) for 100-199

    Returns:
        (current_accuracy, passed_gate, sample_size_sufficient)
    """
    n = len(test_samples)

    # Check sample size
    if n < 100:
        return accuracy, None, False  # "Too small for gating"

    # Compute accuracy
    correct = sum(1 for inp, exp in test_samples if model(inp) == exp)
    current_accuracy = correct / n

    # Compute threshold
    if n < 200:
        effective_threshold = 0.05  # Use 5%
    else:
        effective_threshold = threshold  # Use 3% (or tighter)

    accuracy_drop = baseline_accuracy - current_accuracy

    # Gate decision
    if accuracy_drop > effective_threshold:
        passed_gate = False
        print(f"❌ Accuracy dropped {accuracy_drop:.1%} (threshold: {effective_threshold:.0%})")
    else:
        passed_gate = True
        print(f"✅ Accuracy within threshold (dropped {accuracy_drop:.1%})")

    return current_accuracy, passed_gate, True
```

---

## Related Documents

- **ai-native-architecture.md** — Section 7 on avoiding agent overuse
- **swarm-patterns-by-dev-stage.md** — Multi-agent decision criteria by stage
- **cost-optimization-playbook.md** — Sections 3-4 on model routing and caching strategies
- **prompt-engineering-patterns.md** — Structured prompt baseline techniques
- **testing-ai-generated-code.md** — Coverage and quality gate thresholds

---

## How to Use This Document

1. **Choosing agents vs. functions?** → Jump to Section 1 decision tree
2. **Building cost optimization roadmap?** → Follow Section 2 sequence
3. **Interpreting cache discount numbers?** → Check Section 3 mechanism table
4. **Setting up evaluation gates?** → Use Section 4 sample size table + code

---

## Version History

- **2026-03-19:** Initial synthesis resolving four core contradictions

---

## Related Topics

- [AI-Native Architecture](ai-native-architecture.md) — Architectural patterns that support decision gating and model selection
- [Cost Optimization Playbook](cost-optimization-playbook.md) — Using decision trees to optimize costs across models
- [Swarm Patterns by Dev Stage](swarm-patterns-by-dev-stage.md) — Deciding when to use multi-agent patterns at different stages
