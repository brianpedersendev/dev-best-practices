# Integrating AI Development Tools into Legacy Codebases

> A practical guide to bringing AI to complex, underdocumented, or inconsistent codebases without breaking everything. Strategies, patterns, and proven risk-mitigation approaches for real-world legacy systems.
>
> Last updated: 2026-03-18

---

## Overview: The Legacy Challenge

Legacy codebases are where AI tools hit their hardest limits. Unlike greenfield projects with clear conventions and comprehensive tests, legacy code is characterized by:

- **No test safety net** — 60%+ of legacy systems have test coverage under 20%
- **Implicit business logic** — Rules exist only in tribal knowledge or long-dead comments
- **Inconsistent patterns** — Different eras, developers, and frameworks mixed in one codebase
- **Missing documentation** — Architecture decisions unmade, or made in conversations that are now gone
- **Outdated dependencies** — Frameworks 5+ years old, security issues everywhere, no clear upgrade path
- **Spaghetti code** — Tangled interdependencies, unclear module boundaries, circular imports

**The Problem**: When AI tools encounter legacy code without context or constraints, they produce suggestions that are **45% incompatible with existing patterns**. The confident tone of the suggestion feels authoritative, but the code breaks implicit contracts, introduces new inconsistencies, or silently changes behavior in ways that won't surface until production.

**The Reality**: 62% of U.S. firms still rely on outdated software in 2026, and technical debt has reached 61 billion days of repair time. But organizations that approach legacy modernization with structured AI workflows see **30-50% time reduction** compared to manual refactoring, and **40-90% defect reduction** when paired with strong testing discipline.

---

## 1. Assessment Phase: Evaluating Legacy Codebase AI Readiness

Before bringing AI tools into a legacy system, assess its actual state. Not all legacy code is equally challenging. A clear assessment phase prevents wasting time and prevents the AI tool from confidently breaking things.

### What to Look For: The AI-Readiness Scorecard

| Dimension | Red Flag | Yellow Flag | Green Flag | Score |
|-----------|----------|-------------|-----------|-------|
| **Test Coverage** | <5% | 5-40% | >40% unit tests, 20%+ integration | /10 |
| **Documentation** | None | Scattered comments | README + Architecture doc + CLAUDE.md | /10 |
| **Dependency Age** | 5+ years behind LTS | 2-3 years behind | Current with LTS support | /10 |
| **Code Consistency** | Multiple paradigms mixed | Mostly consistent, some drift | Clear patterns, enforced | /10 |
| **Build Health** | Fragile, manual steps | Works, slow, non-deterministic | Fast, deterministic, CI/CD | /10 |
| **Module Clarity** | No boundaries | Fuzzy boundaries | Clear layers, imports documented | /10 |
| **Type Safety** | No types (dynamic lang) | Partial types or linting | Full types + static analysis | /10 |
| **Deployment Safety** | Manual deploy, risky | Scripted but error-prone | Feature flags, canary, rollback | /10 |

**Scoring**:
- **70-80+**: AI-ready. Can confidently use Claude Code or Cursor for complex tasks.
- **50-69**: Needs onboarding. Establish testing + documentation first (2-4 weeks), then bring in AI.
- **30-49**: High risk. Manual refactoring required first; use AI for specific, well-scoped tasks only.
- **<30**: AI is not a good match yet. Invest in establishing a test harness and documentation before AI engagement.

### Practical Assessment Workflow

1. **Run static analysis** — SonarQube, CodeScene, or similar to quantify complexity, duplication, and dead code
2. **Sample codebase health** — Read 10 random files (not cherry-picked). How clear is the code? Can a new developer understand it?
3. **Test coverage audit** — Run coverage tool. What percentage of critical paths are tested?
4. **Dependency audit** — Check if frameworks/libraries are 5+ years old. Are there known vulnerabilities?
5. **Talk to domain experts** — Who knows the implicit business rules? Are they documented anywhere?

---

## 2. Onboarding AI to Legacy Code: The 5-Step Process

Once you've assessed the codebase, onboarding requires a structured approach. The goal: make implicit patterns explicit so the AI stops generating incompatible suggestions.

### Step 1: Write a Codebase-Specific CLAUDE.md

This is the single most important artifact. CLAUDE.md serves as persistent context across sessions—it tells Claude Code what this codebase actually looks like.

**What it must include** (keep under 200 lines; use `.claude/rules/` for longer rules):

```markdown
# CLAUDE.md
## Project Name: Billing Platform (Legacy)
## Last Updated: 2026-03-18

### Project Overview
- **Language**: Python 3.8 (upgrading to 3.11 in phase 2)
- **Framework**: Django 2.2 (yes, it's old; moving to 3.2 incrementally)
- **Database**: PostgreSQL 11, no ORMs for legacy tables
- **Test Framework**: unittest + pytest (50% coverage)

### Key Directories
```
billing/
├── core/              # Business logic (no touch without approval)
├── api/               # REST endpoints (Django views)
├── models/            # ORM models (mixed Django ORM + raw SQL)
└── migrations/        # Database migrations (sequential, immutable)
tests/
├── unit/             # Fast tests, <100ms each
└── integration/      # Slow tests, against test DB
```

### Critical Patterns (Do This, Not That)

**1. Never use f-strings for SQL**
- ✅ DO: `User.objects.filter(id=user_id)`
- ✗ DON'T: `User.objects.raw(f"SELECT * FROM users WHERE id={user_id}")`
- Reason: This codebase has been hit by SQL injection twice. Always use ORM or parameterized queries.

**2. DateTime handling: Always use UTC**
- ✅ DO: `from django.utils import timezone; timezone.now()`
- ✗ DON'T: `datetime.now()` or `datetime.utcnow()`
- Reason: Timezone bugs have cost $50k in billing disputes. Non-negotiable.

**3. Async/Await is NOT allowed in core billing logic**
- ✅ DO: Celery tasks for long-running work
- ✗ DON'T: `async def` or `await` in billing calculations
- Reason: Debugging async in production is a nightmare; we don't have the instrumentation.

**4. Error handling: Always log context**
- ✅ DO: `logger.error("Payment failed", extra={"order_id": order.id, "error": str(e)})`
- ✗ DON'T: `except: pass`
- Reason: Silent failures caused $100k in undetected payment losses.

**5. Database queries: Always index what you filter**
- Check `core/models.py` for existing indexes before writing queries
- ✗ DON'T: Filter on non-indexed fields in production queries

### Dependencies to Know (And Not Upgrade Without Approval)

- `django==2.2.28` — Stuck here due to old middleware. Upgrade blocked until Q3 2026.
- `psycopg2==2.8.6` — Don't use psycopg3; legacy connection pooling not compatible.
- `celery==4.4.7` — Ancient but stable. Don't upgrade to 5.x; requires infrastructure changes.
- `stripe==5.4.0` — Critical; every upgrade requires re-testing against live billing flow.

### Build & Test Commands

```bash
# Setup
python -m venv venv && source venv/bin/activate
pip install -r requirements-dev.txt
./manage.py migrate

# Test
./manage.py test tests/unit -v 2 --keepdb    # Fast, reuses DB
pytest tests/integration/ -v                  # Slow, ~5 min

# Quality checks
flake8 billing/ --max-line-length=100
black --check billing/
mypy billing/ --ignore-missing-imports

# Common tasks
./manage.py makemigrations  # Generate migrations (review before commit)
./manage.py shell           # Interactive shell for testing
```

### What NOT to Do

- ✗ Don't refactor `core/payment_processor.py` — It's 2,000 lines of poorly-understood state machines. Characterization tests first, then we'll talk.
- ✗ Don't add type hints to `models.py` without talking to Sarah (the domain expert who wrote it in 2015).
- ✗ Don't optimize queries without load testing — Last attempt cost 3 hours of debugging in staging.
- ✗ Don't change the database schema without @ops-review approval (2-3 day turnaround).

### How We Refactor Safely

1. Write characterization tests first (capture current behavior)
2. Small PRs only (one function, one module boundary per PR)
3. All PRs require code review + all tests passing
4. After merge: monitor metrics for 24 hours before next change

### Known Issues (And Why We Haven't Fixed Them)

- `BillingAccount.status` has 7 values but code treats it as 3 — It's a mess, but changing it breaks 12 customer workflows that expect broken behavior.
- `payment_audit_log` table grows 10GB/month — Partition plan exists but requires downtime; scheduled for Q4 2026.
- Dead code in `api/legacy_endpoints.py` — Some customers still call it; can't remove until Q3 sunset notice.

### Contact the Domain Expert

- **Billing logic**: Sarah Chen (sarah@company.com) — She wrote 60% of this codebase.
- **Database**: ops-team@company.com — For any schema changes.
- **API contracts**: api-review@company.com — For backward-compatibility questions.
```

**Why this works**: It's not comprehensive theory. It's practical, specific, and answers the question "what will break if I do X?" The implicit rules become explicit.

### Step 2: Document Architecture Decisions

Many legacy codebases have an unwritten architecture. Document it so AI tools don't second-guess every decision.

Create `docs/architecture.md`:

```markdown
# Architecture

## Why This Codebase Looks Like This

### Why Django 2.2 (Not 3.2)?
Migration blocked on middleware compatibility with upgrade path. See ticket #INFRA-4521.
Planned for Q3 2026 after infrastructure rewrite.

### Why No Type Hints?
Added gradually. `core/models.py` is priority (high-mutation area).
`api/` and `tasks/` are already typed. See .pylintrc for enforcement.

### Why Raw SQL in Migrations?
Django's migration framework was slow for this schema. Raw SQL gives us deterministic control.
All raw SQL in migrations must be reversible.

### Why Celery (Not Async)?
Async debugging is hard; we don't have the observability yet.
Celery gives us reliable retries, task tracking, and dead-letter queues.

### Why This Module Structure?
- `core/` — Business logic (high-value, high-stability)
- `api/` — HTTP endpoints (medium-stability, high-change)
- `tasks/` — Background jobs (medium-stability)
- `legacy/` — Code we're sunsetting (don't refactor; only fix bugs)

This separation lets us control the blast radius of changes.
```

### Step 3: Identify and Document Gotchas and Implicit Conventions

Legacy code has unwritten rules. Write them down.

Create `.claude/gotchas.md`:

```markdown
# Gotchas & Implicit Conventions

## Money Math
**The Rule**: Use Decimal for all currency, never float.

```python
# ✅ DO
from decimal import Decimal
amount = Decimal("19.99")
total = amount + Decimal("10.00")

# ✗ DON'T
amount = 19.99
total = amount + 10.00  # Results in 29.989999999 in binary floats
```

Reason: We've had floating-point rounding errors lose cents on customer invoices.

## Timezone Handling
**The Rule**: Always store as UTC, always convert at the boundary.

```python
# ✅ DO
from django.utils import timezone
created = timezone.now()  # Returns UTC

# ✗ DON'T
import datetime
created = datetime.datetime.now()  # Returns local time; wrong in production
```

## ID Sequences
**The Rule**: IDs must be cryptographically secure for security-sensitive tables.

- `users` table: Use `secrets.token_urlsafe()`
- `orders` table: Integer PK is fine (not user-facing)
- `payment_tokens` table: Use UUID4

Reason: Customers guessed sequential invoice IDs and viewed others' data.

## Error Handling in Payments
**The Rule**: Never catch generic Exception in payment code.

```python
# ✅ DO
try:
    stripe.Charge.create(...)
except stripe.CardError as e:
    # Handle card decline
except stripe.RateLimitError as e:
    # Retry
except stripe.InvalidRequestError as e:
    # Log critical, alert
else:
    payment.mark_successful()

# ✗ DON'T
try:
    stripe.Charge.create(...)
except:
    pass  # Silent failure; we lose money
```

## Database Connections
**The Rule**: Don't use connection pooling in Celery workers (causes deadlocks).

See `settings.py:DATABASES['default']['CONN_MAX_AGE']` — It's 0 for good reason.

## Testing Against Production Data
**The Rule**: Never test against production data, ever.

- Use `management.Command` to load sanitized production snapshots into test DB
- See `tests/fixtures/load_prod_snapshot.py`
```

### Step 4: Set Up Hooks to Enforce Patterns

Text-based rules fade after context compression. Hooks execute every time.

Create `.claude/hooks/pre_tool_use.py`:

```python
#!/usr/bin/env python3
"""Pre-tool-use hook: Catch dangerous patterns before AI executes them."""

import sys
import re

def check_sql_injection():
    """Block f-string SQL queries."""
    with open('.last_claude_action.txt', 'r') as f:
        action = f.read()

    # Check for f-string SQL patterns
    dangerous = re.findall(r'raw\(f["\']SELECT.*{', action)
    if dangerous:
        print("ERROR: F-string SQL detected. Use parameterized queries instead.")
        print(f"Found: {dangerous[0]}")
        sys.exit(2)  # Exit code 2 = block

def check_float_money():
    """Block float arithmetic on money."""
    with open('.last_claude_action.txt', 'r') as f:
        action = f.read()

    if 'amount = ' in action and any(x in action for x in ['19.99', '0.01', 'float']):
        if 'Decimal' not in action:
            print("ERROR: Money math must use Decimal, not float.")
            sys.exit(2)

def check_async_in_billing():
    """Block async/await in billing core logic."""
    with open('.last_claude_action.txt', 'r') as f:
        action = f.read()

    if 'billing/core/' in action and 'async def' in action:
        print("ERROR: No async/await in billing core. Use Celery tasks instead.")
        sys.exit(2)

if __name__ == '__main__':
    check_sql_injection()
    check_float_money()
    check_async_in_billing()
    sys.exit(0)
```

Register in `Claude Code`:

```bash
cd my-codebase
claude code
# Then: Cmd+K > "setup hooks"
# Point to .claude/hooks/
```

### Step 5: Create a Module Map

Document which modules are "safe to refactor" vs. "fragile" vs. "immutable".

Create `docs/module-map.md`:

```markdown
# Module Safety Map

| Module | Safety Level | Reason | Refactor? |
|--------|-------------|--------|-----------|
| `core/models.py` | 🔴 HIGH RISK | 100+ downstream dependencies, poorly tested | Not without characterization tests |
| `core/billing.py` | 🔴 HIGH RISK | Business-critical; one bug = revenue loss | Only bug fixes; no refactoring |
| `api/views.py` | 🟡 MEDIUM RISK | Tested (60%), but customers depend on behavior | Small PRs, backward-compatible changes only |
| `api/serializers.py` | 🟡 MEDIUM RISK | Tested but fragile on edge cases | Can refactor if tests pass |
| `tasks/` | 🟡 MEDIUM RISK | Async, hard to test, but isolated | Refactor incrementally |
| `legacy/` | 🟢 LOW RISK | Being sunset; minimal coverage | Only bug fixes; no refactoring |
| `tests/` | 🟢 LOW RISK | Safe to expand and improve | Add more tests! |
| `settings.py` | 🔴 HIGH RISK | Affects all environments | Changes require ops review |
| `manage.py` | 🟢 LOW RISK | Lightweight entry point | Safe to extend |

Legend:
- 🔴 HIGH RISK: Don't touch without SME review + extended testing
- 🟡 MEDIUM RISK: Refactor incrementally; all tests must pass
- 🟢 LOW RISK: Safe to refactor and improve
```

---

## 3. The Test-First Migration: Building a Safety Net

Before letting AI touch legacy code, establish a test safety net. AI is powerful but can introduce silent behavioral drift. Tests catch that.

### Why Tests Are Non-Negotiable

- **Without tests**: AI suggestions are confidently wrong 40% of the time. You won't know until production.
- **With tests**: AI produces code that passes tests 85%+ of the time. Regressions are caught immediately.
- **With TDD**: AI defect rate drops 40-90% vs. AI-alone.

### Phase 1: Characterization Tests (Capture Current Behavior)

**Characterization tests** document what the code *actually does*, including all the weird edge cases.

**Example: Testing legacy payment processor**

```python
# tests/test_billing_characterization.py
"""
Characterization tests for payment processor.

These tests capture the CURRENT behavior of the legacy payment code,
including edge cases and quirks. Don't change these without SME approval.
These are the golden baseline for safe refactoring.
"""

import unittest
from decimal import Decimal
from billing.core import payment_processor

class TestPaymentProcessorCharacterization(unittest.TestCase):
    """Document what payment_processor.py actually does (not what it should do)."""

    def test_discount_applied_to_subtotal_not_total(self):
        """
        CURRENT BEHAVIOR (QUIRK):
        Discounts are applied to subtotal BEFORE tax, not after.
        This is wrong mathematically but is the current behavior.

        Changing this breaks 12 customer workflows.
        See ticket BILLING-3847.
        """
        subtotal = Decimal("100.00")
        discount = Decimal("10.00")  # 10%
        tax_rate = Decimal("0.08")

        result = payment_processor.calculate_total(
            subtotal=subtotal,
            discount_percent=discount,
            tax_rate=tax_rate
        )

        expected = (subtotal - (subtotal * discount / 100)) + \
                  ((subtotal - (subtotal * discount / 100)) * tax_rate)
        self.assertEqual(result, expected)

    def test_refund_after_90_days_returns_zero(self):
        """
        CURRENT BEHAVIOR:
        Refunds requested after 90 days return $0, not $0.00 (Decimal).
        This causes type confusion in some code paths.
        """
        from datetime import datetime, timedelta

        payment_date = datetime(2025, 1, 1)
        refund_date = datetime(2025, 4, 1)  # 90 days later
        amount = Decimal("50.00")

        refund = payment_processor.calculate_refund(
            amount=amount,
            payment_date=payment_date,
            refund_date=refund_date
        )

        # Current behavior: returns int 0, not Decimal('0.00')
        self.assertEqual(refund, 0)
        self.assertIsInstance(refund, int)

    def test_rounding_rule_banker_rounding(self):
        """
        CURRENT BEHAVIOR:
        Rounding uses banker's rounding (round-half-to-even), not standard rounding.
        """
        amounts = [
            (Decimal("0.125"), Decimal("0.12")),  # Banker's: rounds to even
            (Decimal("0.135"), Decimal("0.14")),  # Banker's: rounds to even
        ]

        for amount, expected in amounts:
            rounded = payment_processor.round_cents(amount)
            self.assertEqual(rounded, expected)
```

**Key points**:
- Document *why* the quirk exists (backwards compatibility, business rule, bug)
- Don't fix these without explicit approval
- These become the regression baseline for refactoring
- AI generates these tests in minutes; manually capturing them takes days

### Phase 2: Approval Testing (Golden File Testing)

For complex behaviors (PDF generation, XML output, complex state machines), approval testing is faster than unit tests.

**Example: Testing invoice generation**

```python
# tests/test_invoice_approval.py
"""
Approval tests for invoice generation.

These tests use 'golden files' (snapshots of expected output).
If the invoice changes, the snapshot changes, and a diff is generated for review.
"""

import unittest
from approvaltests import verify
from billing.invoice_generator import generate_invoice_pdf

class TestInvoiceApproval(unittest.TestCase):
    def test_invoice_layout_and_content(self):
        """Generate an invoice and compare to approved golden file."""
        invoice = generate_invoice_pdf(
            order_id=12345,
            customer_name="Acme Corp",
            items=[
                {"description": "Widget", "qty": 5, "price": "10.00"},
            ],
            discount_percent=10,
            tax_rate=0.08,
        )

        # Approval testing: generates invoice.pdf, compares to invoice.pdf.approved
        # If different, shows diff and requires approval
        verify(invoice)
```

When you run this test:
1. It generates the invoice
2. Compares it to `invoice.pdf.approved` (the golden file)
3. If different, shows a diff and halts
4. You review the diff, and if correct, approve it

### Phase 3: The Test Harness Approach

For *untested* legacy code, build a test harness first, *then* refactor.

```python
# tests/harness/payment_processor_harness.py
"""
Test harness: Wrap legacy code to capture inputs/outputs for characterization.
"""

from billing.core import payment_processor as legacy_processor

class PaymentProcessorHarness:
    """Record all inputs/outputs of the legacy payment processor."""

    def __init__(self, output_file='payment_calls.json'):
        self.output_file = output_file
        self.calls = []

    def process_payment(self, **kwargs):
        """Call legacy processor and log inputs/outputs."""
        result = legacy_processor.process_payment(**kwargs)

        self.calls.append({
            'input': kwargs,
            'output': result,
            'timestamp': datetime.now().isoformat(),
        })

        return result

    def dump_calls(self):
        """Write calls to file for review and replay."""
        import json
        with open(self.output_file, 'w') as f:
            json.dump(self.calls, f, indent=2, default=str)

# Usage in tests:
harness = PaymentProcessorHarness()
# Run against production data snapshots
harness.process_payment(order_id=123, amount="50.00")
# Outputs: payment_calls.json with all recorded calls

# Later: Use this to generate characterization tests
```

### Phase 4: Regression Testing with Feature Flags

When you refactor, use feature flags to A/B test old vs. new code:

```python
# billing/core/payment_processor_v2.py
"""New, refactored version of payment processor."""

def calculate_total_v2(subtotal, discount_percent, tax_rate):
    """New version (mathematically correct)."""
    discounted = subtotal * (1 - discount_percent / 100)
    return discounted * (1 + tax_rate)

# billing/api/views.py
from django.conf import settings
from billing.core import payment_processor, payment_processor_v2

def create_order(request):
    subtotal = request.POST['subtotal']
    discount = request.POST['discount_percent']
    tax_rate = request.POST['tax_rate']

    # Feature flag: use new or old?
    if settings.FEATURE_FLAGS.get('use_payment_processor_v2'):
        total = payment_processor_v2.calculate_total(subtotal, discount, tax_rate)
    else:
        total = payment_processor.calculate_total(subtotal, discount, tax_rate)

    return JsonResponse({'total': str(total)})
```

**In production**: Roll out feature flag to 1% of customers, monitor for divergence. If no issues after 1 week, roll to 10%, then 100%.

---

## 4. Incremental Modernization Patterns

### Pattern 1: Strangler Fig (Gradual Replacement)

Replace modules gradually, with a proxy routing requests between old and new.

```python
# billing/routing.py
"""Routing layer between legacy and modern code."""

from billing.legacy import invoice_generator_old
from billing.modern import invoice_generator_new
from django.conf import settings

class InvoiceGeneratorRouter:
    """Route requests based on feature flag."""

    def generate(self, order_id, **kwargs):
        if settings.FEATURE_FLAGS.get('new_invoice_generator'):
            return invoice_generator_new.generate(order_id, **kwargs)
        else:
            return invoice_generator_old.generate(order_id, **kwargs)

# In views:
router = InvoiceGeneratorRouter()
pdf = router.generate(order_id=123)
```

**Benefits**:
- Old and new run in parallel; easy to compare behavior
- Instant rollback (flip flag, requests route to old code)
- Can control rollout (1% of customers, then 10%, then 100%)

**AI's role**: Claude Code can generate the new implementation, then write tests to verify it produces the same output as the old code.

### Pattern 2: Extract-and-Replace

Identify tight, cohesive modules and extract them into separate, testable units.

**Before**:
```python
# billing/monolith.py (2000 lines)
def create_order():
    # Pricing logic tangled with inventory logic tangled with notification logic
    price = calculate_price(...)  # 50 lines, unclear dependencies
    inventory.check(...)           # Coupled to pricing
    notify_customer(...)           # Coupled to inventory
    return order
```

**After**:
```python
# billing/pricing.py (well-tested, 100 lines)
def calculate_price(order, rules, discounts):
    """Pure function; no side effects."""
    # Clear input/output contract
    return price

# billing/inventory.py (separate service)
def check_availability(product_id, quantity):
    """Decoupled from pricing."""
    return is_available

# billing/notifications.py (separate service)
def notify_order_created(order):
    """Decoupled from pricing and inventory."""
    pass

# billing/orchestration.py (orchestrates the three)
def create_order(order_data):
    price = pricing.calculate_price(...)
    if not inventory.check_availability(...):
        raise OutOfStock()
    order = Order.objects.create(price=price, ...)
    notifications.notify_order_created(order)
    return order
```

**AI's role**:
1. Identify module boundaries (ask Claude: "What parts of this function are cohesive?")
2. Generate extracted code
3. Verify with tests that behavior hasn't changed
4. Gradually move call sites to new functions

### Pattern 3: Adapter Layers

When upgrading a dependency, introduce an adapter layer so the rest of the code doesn't need to change.

**Example: Upgrading from moment.js to date-fns**

```javascript
// legacy/moment_adapter.js (2025 code that still uses moment)
import moment from 'moment';
export const formatDate = (date) => moment(date).format('YYYY-MM-DD');

// new/date_adapter.js (2026 code using date-fns)
import { format } from 'date-fns';
export const formatDate = (date) => format(date, 'yyyy-MM-dd');

// index.js (routes based on feature flag)
import { FEATURE_FLAGS } from './config';
let dateAdapter;
if (FEATURE_FLAGS.newDateLibrary) {
    dateAdapter = require('./new/date_adapter');
} else {
    dateAdapter = require('./legacy/moment_adapter');
}

export const formatDate = dateAdapter.formatDate;

// everywhere else in the app
import { formatDate } from './date_formatter';
// No change needed; just works
```

**AI's role**: Generate the adapter layer and replace call sites.

### Pattern 4: Gradual Type Introduction (for dynamic languages)

Don't migrate to types all at once. Add types incrementally to hot paths.

**Phase 1: Type-check new code** (year 1)
```python
# billing/core/models.py — Already has type hints (priority module)
def calculate_price(order: Order, rules: List[Rule]) -> Decimal:
    """New code is typed."""
    ...
```

**Phase 2: Type-check high-mutation code** (year 2)
```python
# billing/api/views.py — Add types to views (change frequently)
def create_order_view(request: HttpRequest) -> JsonResponse:
    ...
```

**Phase 3: Type-check everything else** (year 3)
```python
# billing/legacy/old_functions.py — Eventually typed
```

**AI's role**: Claude Code can add type hints incrementally, and mypy can verify they're correct.

---

## 5. Technical Debt Reduction with AI

AI excels at identifying and fixing specific categories of technical debt.

### Debt Category 1: Outdated Dependencies

**Detection**: Run `pip outdated` or `npm outdated`

**AI's role**:
1. Identify compatibility constraints (run tests against upgraded version)
2. Generate migration code (API changes)
3. Verify tests pass

**Example workflow**:
```bash
# Run this with Claude Code:
# "Upgrade lodash from 3.10.1 to 4.17.21. Show me all the breaking changes
#  and update the code to use the new API."

# Claude Code:
# 1. Reads lodash 3 docs, lodash 4 migration guide
# 2. Identifies changed functions (_.clone, _.merge, etc.)
# 3. Updates all call sites
# 4. Runs tests to verify
```

### Debt Category 2: Dead Code

**Detection**:
- Static analysis: SonarQube, CodeScene
- Behavioral: Functions that are never called
- Time-based: Code that hasn't been modified in 2+ years

**AI's role**: Verify code is actually dead (not called via reflection or dynamic import)

**Example**:
```python
# payments/old_stripe_handler.py (never called)
def process_stripe_charge_v1():
    """Old Stripe API (pre-2020). Replaced by v2. Safe to delete?"""
    ...

# AI check:
# 1. Search codebase for "process_stripe_charge_v1" — 0 results
# 2. Search git history for last call — last called 2022
# 3. Check if any customers depend on this endpoint — No
# 4. Safe to delete
```

**Use AI to**:
1. Identify dead code candidates
2. Verify they're safe to delete (no external dependencies)
3. Generate a PR with deletions + explanations
4. Monitor metrics post-deletion (should be zero impact)

### Debt Category 3: Code Duplication

**Detection**: SonarQube, Codescene

**AI's role**: Extract common code into functions

```python
# Before
def calculate_invoice_total(invoice):
    subtotal = sum(item.price * item.qty for item in invoice.items)
    discount = subtotal * (invoice.discount_percent / 100)
    return subtotal - discount

def calculate_quote_total(quote):
    subtotal = sum(item.price * item.qty for item in quote.items)
    discount = subtotal * (quote.discount_percent / 100)
    return subtotal - discount

# After (AI generates this)
def calculate_discounted_total(items, discount_percent):
    subtotal = sum(item.price * item.qty for item in items)
    discount = subtotal * (discount_percent / 100)
    return subtotal - discount

def calculate_invoice_total(invoice):
    return calculate_discounted_total(invoice.items, invoice.discount_percent)

def calculate_quote_total(quote):
    return calculate_discounted_total(quote.items, quote.discount_percent)
```

### Debt Category 4: Inconsistent Patterns

**Detection**: Code review + manual sampling

**AI's role**: Standardize patterns across the codebase

```python
# Before (inconsistent error handling)
def handler1():
    try:
        do_something()
    except Exception:
        pass  # Silent failure

def handler2():
    try:
        do_something()
    except SpecificError as e:
        logger.error(f"Error: {e}", extra={'context': 'handler2'})
        raise

def handler3():
    do_something()  # No error handling

# After (AI standardizes all three)
def handler1():
    try:
        do_something()
    except SpecificError as e:
        logger.error(f"Error in handler1", extra={'context': 'handler1', 'error': str(e)})
        raise

def handler2():
    try:
        do_something()
    except SpecificError as e:
        logger.error(f"Error in handler2", extra={'context': 'handler2', 'error': str(e)})
        raise

def handler3():
    try:
        do_something()
    except SpecificError as e:
        logger.error(f"Error in handler3", extra={'context': 'handler3', 'error': str(e)})
        raise
```

---

## 6. Common Legacy Scenarios: Specific Strategies

### Scenario 1: No Tests At All

**The Problem**: 90% of the codebase has zero test coverage.

**The Strategy**:
1. **Identify critical paths** — What code would cause financial loss if it breaks? Start there.
2. **Generate characterization tests** — Ask Claude Code: "Write characterization tests for this function."
3. **Focus on coverage, not perfection** — 50% coverage on critical paths is better than 0%.
4. **Use approval testing** — For complex outputs, use golden files instead of unit tests.

**Example**:
```bash
# With Claude Code:
# "This file has no tests. It processes payment refunds.
#  Write characterization tests that capture current behavior,
#  including edge cases and known quirks."

# Claude Code:
# 1. Reads the refund processing code
# 2. Identifies edge cases (refunds > 90 days, partial refunds, etc.)
# 3. Generates characterization tests for each case
# 4. Tests pass immediately (because they document current behavior)
```

### Scenario 2: Outdated Framework (jQuery, AngularJS, Python 2)

**The Problem**: jQuery UI library hasn't been updated in 8 years. AngularJS 1.x is EOL. Python 2.7 is gone.

**The Strategy**: Strangler fig pattern with risk-limited rollout

**Example: jQuery to React migration**

```javascript
// Step 1: Introduce feature flag (no changes yet)
if (FEATURE_FLAGS.useReactComponents) {
    // render new React component
} else {
    // render old jQuery element
}

// Step 2: Build React components alongside jQuery
// jquery/invoice_editor.js (old)
$("#invoice-form").on("change", function() { ... });

// react/InvoiceEditor.tsx (new)
export const InvoiceEditor = () => { ... };

// Step 3: Gradually migrate call sites
// views.js
if (FEATURE_FLAGS.useReactComponents) {
    ReactDOM.render(<InvoiceEditor />, document.getElementById('editor'));
} else {
    // Old jQuery initialization
    initializeInvoiceEditor();
}

// Step 4: Monitor, then remove old code
// After 6 months with 0% errors, delete jQuery version
```

**AI's role**:
1. Parse jQuery code to understand behavior
2. Generate React components with equivalent behavior
3. Identify data-binding requirements
4. Test both sides in parallel

**Real-world result** (from HeroDevs): AngularJS → Angular migration achieved 50-75% success rate on actual code generation, with 100% of files having at least some issues that required human review. This is realistic and acceptable.

### Scenario 3: Monolithic Architecture

**The Problem**: One codebase, 500K lines, everything depends on everything.

**The Strategy**:
1. Map dependencies (static + dynamic analysis)
2. Identify service boundaries
3. Extract incrementally with strangler fig

```python
# Step 1: Dependency analysis (AI tool generates this)
# "Analyze this monolith and identify modules that could be extracted as services."

# Output: dependency map
{
  'invoice_generation': {
    'depends_on': ['pricing', 'customer_db', 'email'],
    'depended_on_by': ['api', 'cron_jobs'],
    'cohesion_score': 0.92,  # High = good candidate for extraction
    'coupling_score': 0.45,  # Low = loosely coupled
  },
  'payment_processing': {
    'depends_on': ['stripe_api', 'audit_log'],
    'depended_on_by': ['api', 'webhooks'],
    'cohesion_score': 0.88,
    'coupling_score': 0.32,
  },
}

# Step 2: Extract one service at a time
# Start with high cohesion + low coupling

# Step 3: Proxy traffic between monolith and new service
class BillingRouter:
    def create_invoice(self, order_id):
        if FEATURE_FLAGS.useNewInvoiceService:
            return new_invoice_service.create(order_id)
        else:
            return monolith.invoice_generation.create(order_id)
```

### Scenario 4: Spaghetti Code (No Clear Structure)

**The Problem**: Functions are 500 lines. State is global. Dependencies are implicit.

**The Strategy**: Refactor in layers
1. **Layer 1: Extract pure functions** — Take out the business logic
2. **Layer 2: Add tests** — New pure functions are testable
3. **Layer 3: Remove state** — Convert global state to explicit parameters
4. **Layer 4: Rename for clarity** — Variable names should explain intent

```python
# Before: Spaghetti
def process_order():  # 300 lines of mixed concerns
    global customer_db, config, logger
    # ... tangled logic ...
    logger.info("order processed")

# After: Layered (AI generates this)

# Layer 1: Pure function (easy to test, understand, verify)
def calculate_order_price(
    items: List[Item],
    customer: Customer,
    rules: PricingRules,
) -> Decimal:
    """Pure function: no side effects, no globals."""
    subtotal = sum(item.price * item.qty for item in items)
    discount = apply_discount_rules(customer, rules)
    tax = calculate_tax(subtotal, customer.region)
    return subtotal + tax + discount

# Layer 2: State management (tracks side effects)
def persist_order(
    customer_id: str,
    items: List[Item],
    price: Decimal,
) -> Order:
    """Explicitly writes to database."""
    order = Order.create(customer_id=customer_id, total=price)
    order.items.add(*items)
    order.save()
    return order

# Layer 3: Orchestration (coordinates layers)
def process_order(customer_id: str, items: List[Item]) -> Order:
    """Orchestrates pricing, persistence, notifications."""
    customer = Customer.objects.get(id=customer_id)
    price = calculate_order_price(
        items=items,
        customer=customer,
        rules=pricing_rules,
    )
    order = persist_order(customer_id, items, price)
    notify_customer(customer, order)
    return order
```

### Scenario 5: Multiple Coding Styles

**The Problem**: Different developers wrote code in different eras with different styles.

```python
# 1990s style: cryptic names, no comments
def pp(x, y):
    return x + y if x else y

# 2005 style: verbose, over-commented
def process_potentially_partial_payment(amount_received, expected_amount):
    """
    This function processes a payment that may be partial.
    Args:
        amount_received: Amount the customer paid
        expected_amount: Amount we expected
    """
    if amount_received:
        return amount_received + expected_amount
    else:
        return expected_amount

# 2015 style: Pythonic
def reconcile_payment(received: Decimal, expected: Decimal) -> Decimal:
    return received or expected

# 2025 style: Type-safe and well-tested
def reconcile_payment(
    received_amount: Decimal,
    expected_amount: Decimal,
    payment_rule: PaymentRule,
) -> Decimal:
    """Apply business rules to partial payments."""
    if received_amount and payment_rule.allow_partial:
        return received_amount + expected_amount
    return expected_amount
```

**The Strategy**: Standardize incrementally

1. **Enforce style on new code** — Linters, pre-commit hooks
2. **Refactor as you touch old code** — When you fix a bug in old code, modernize it at the same time
3. **Use AI to bulk-refactor** — "Refactor this file to modern Python + type hints"

---

## 7. Tool-Specific Strategies

### Claude Code for Legacy Code

**Strengths**:
- **Longest context window** (200K tokens) — Can ingest entire legacy modules
- **Best multi-file reasoning** — Understands interdependencies across files
- **Hooks + CLAUDE.md** — Can enforce codebase-specific patterns
- **Autonomous task execution** — Can run tests and iterate on failures

**Best for**:
- Complex refactors spanning multiple modules
- Understanding large, tangled codebases
- Automated characterization test generation
- Bulk pattern standardization (e.g., convert all error handling to one style)

**Approach**:
```bash
# 1. Create detailed CLAUDE.md with legacy patterns
# 2. Create .claude/hooks/ with safety checks
# 3. Use Plan Mode to get approval before execution
# 4. Let Claude iterate through test failures

claude code
# > Plan: Refactor payment processing to use consistent error handling
# Review plan, approve
# Claude executes, runs tests, iterates on failures
```

### Cursor for Legacy Code

**Strengths**:
- **IDE integration** — See the changes in real-time
- **Composer for multi-file edits** — Edit multiple files in one view
- **Background agents** — Can run tests/linters asynchronously
- **Fast iteration** — Low latency for back-and-forth
- **`.mdc` rules** — Modern project-based rules system

**Best for**:
- Interactive exploration of legacy code
- Incremental refactoring (small, focused PRs)
- Team workflows (IDE-based, easier to share context)
- Daily coding with legacy systems

**Approach**:
```
1. Create .cursor/rules/ with legacy patterns
2. Use Composer to edit multiple files
3. Toggle rules on/off for different modules
4. Background agents watch tests/linters
```

### Gemini for Legacy Code

**Strengths**:
- **2M context window** — Ingest an entire legacy codebase at once
- **Low cost** — 50-60% cheaper per token than Claude
- **Good at "explain" tasks** — Understanding legacy business logic

**Best for**:
- Initial codebase exploration and understanding
- Bulk analysis (dead code, duplication, patterns)
- Cost-sensitive organizations
- Large monoliths where you need to understand the full picture first

**Approach**:
```
1. Feed entire codebase to Gemini (2M tokens can hold 100K+ lines)
2. Ask: "Map dependencies, identify service boundaries, find dead code"
3. Get a comprehensive analysis
4. Use Claude/Cursor for actual refactoring (better quality on execution)
```

---

## 8. Risk Management: What Can Go Wrong

### Risk 1: Breaking Implicit Contracts

**The Problem**: Legacy code has unwritten rules. "Don't change field X without updating Y." If AI doesn't know about Y, it breaks silently.

**Mitigation**:
- Document all implicit contracts in CLAUDE.md
- Write characterization tests that verify the contract
- Use hooks to catch violations

```python
# CLAUDE.md
# "WARNING: Whenever you update Customer.status, you MUST trigger a sync to Salesforce.
#  See core/integrations/salesforce.py:sync_customer_status()"

# Hook that catches violations
def check_salesforce_sync(action):
    if 'Customer.status =' in action and 'salesforce_sync' not in action:
        print("ERROR: Updated Customer.status but didn't sync to Salesforce")
        sys.exit(2)
```

### Risk 2: Introducing Inconsistent Patterns

**The Problem**: "This codebase has 5 different ways to handle errors. AI chose a 6th."

**Mitigation**:
- CLAUDE.md documents the *one* approved way
- Hooks block non-conforming code
- Linters enforce style

### Risk 3: The "Confident But Wrong" Problem

**The Problem**: AI generates code that looks right but silently fails on edge cases.

**Mitigation**:
- Require tests before AI generates code
- Use approval testing for complex outputs
- Feature-flag all AI changes and monitor metrics

```python
# Before: AI refactors this
def apply_discount(price, discount_percent):
    return price * (1 - discount_percent / 100)

# After: AI generates this (looks right, but edge cases?)
def apply_discount_refactored(price, discount_percent):
    discounted = price * (1 - discount_percent / 100)
    return discounted.quantize(Decimal('0.01'))  # Added rounding

# But what if discount_percent > 100? Or < 0? Or price is negative?

# Mitigation: Write tests FIRST
def test_apply_discount():
    assert apply_discount(100, 10) == 90
    assert apply_discount(100, 0) == 100
    assert apply_discount(100, 100) == 0
    assert apply_discount(100, 150) == -50  # Should this be allowed?

# Then ask AI: "Implement apply_discount() to pass these tests"
# If tests don't cover edge cases, tests fail and AI knows
```

### Risk 4: Regression at Scale

**The Problem**: "We refactored and passed all unit tests, but production is broken."

**Mitigation**:
- Feature flags for all major changes
- Canary rollout (1% → 10% → 100%)
- Monitor key metrics for changes

```python
# settings.py
FEATURE_FLAGS = {
    'new_payment_processor': 0.01,  # 1% of traffic
    'new_invoice_generator': 0.00,  # 0% (not yet)
}

# views.py
if random.random() < settings.FEATURE_FLAGS['new_payment_processor']:
    result = new_payment_processor.process(...)
else:
    result = old_payment_processor.process(...)

# Monitor: Do new_payment_processor errors differ from old?
# If yes at 1%, roll back. If no, increase to 10%, etc.
```

---

## 9. Migration Roadmap: Month-by-Month Plan

### Week 1-2: Assessment & Planning

**Deliverables**:
- AI-readiness scorecard (section 1)
- Initial CLAUDE.md draft
- List of top 5 technical debt items to fix

**Who**: Tech lead + 1-2 senior developers
**Effort**: 40 hours
**Tools**: SonarQube, CodeScene, manual code review

### Week 3-4: Onboarding

**Deliverables**:
- Finalized CLAUDE.md (200 lines max)
- Architecture decision docs (why the code looks like this)
- `.claude/gotchas.md` (implicit rules made explicit)
- `.claude/hooks/` (pre-commit hooks for safety)
- Module safety map

**Who**: Tech lead + knowledge experts
**Effort**: 60 hours (lots of embedded knowledge needs to be written down)
**Tools**: Claude Code for drafting docs

### Week 5-6: Build Test Safety Net

**Deliverables**:
- Characterization tests for critical paths (50%+ coverage on revenue-impacting code)
- Approval tests for complex outputs
- Test infrastructure + CI/CD hooks

**Who**: Test engineer + developers
**Effort**: 80 hours (writing tests is the hard part, but it's the foundation)
**Tools**: Claude Code to generate test boilerplate, then hand-tune

### Week 7-8: Identify & Extract (First Module)

**Deliverables**:
- One module extracted and tested
- Strangler fig proxy in place
- Feature flag wired up
- 1-week monitoring in 1% canary

**Who**: Senior developer + AI tool (Claude Code)
**Effort**: 40 hours (AI does 60% of the work)
**Focus**: Choose a module with high cohesion + low coupling

**Example**: Extract `invoice_generator.py` from monolith

### Week 9-10: Modernize (First Module)

**Deliverables**:
- Old code refactored using new patterns
- Type hints added
- Error handling standardized
- Documentation written

**Who**: Developer + Claude Code
**Effort**: 40 hours
**Tools**: Claude Code with hooks + tests

### Week 11-12: Iterate & Expand

**Deliverables**:
- 2-3 more modules extracted and modernized
- Lessons learned documented
- Team feedback gathered

**Who**: Team
**Effort**: 60 hours
**Feedback**: What's working? What's slowing us down?

### Month 2: Dependency Upgrades

**Deliverables**:
- Top 5 outdated dependencies upgraded
- Zero regressions in canary testing
- Automated dependency update process in place

**Who**: Developers + Claude Code
**Effort**: 40 hours
**Tools**: Claude Code to identify breaking changes, generate migration code

### Month 3: Bulk Improvements

**Deliverables**:
- Dead code removed (5-10% of codebase)
- Duplication consolidated (10-15% code reduction)
- Pattern standardization (error handling, logging, etc.)

**Who**: Developers + Claude Code
**Effort**: 80 hours
**Tools**: Claude Code for bulk refactoring, linters for enforcement

### Success Metrics

- **Test coverage**: 20% → 50% (focus on critical paths)
- **Technical debt**: Quantified (SonarQube) and reduced by 30%
- **Cycle time**: Deployment frequency unchanged or improved (AI shouldn't slow you down)
- **Quality**: Defect rate on refactored code ≤ defect rate on hand-written code
- **Team satisfaction**: "AI tools are helpful, not a hindrance"

---

## 10. Implementation Checklist

Before deploying AI to a legacy codebase, ensure you have:

### Phase 1: Assessment
- [ ] AI-readiness scorecard completed (section 1)
- [ ] Risk assessment done (which modules are most fragile?)
- [ ] Decision made: Greenlight for AI integration? Or more prep needed?

### Phase 2: Onboarding
- [ ] CLAUDE.md written (200 lines, codebase-specific patterns)
- [ ] Architecture doc created (why the code looks like this)
- [ ] Gotchas documented (implicit rules made explicit)
- [ ] Hooks configured (safety checks for dangerous patterns)
- [ ] Module safety map created (which modules can refactor vs. not)

### Phase 3: Testing
- [ ] Characterization tests written for critical paths (50%+ coverage)
- [ ] Approval tests set up for complex outputs
- [ ] Test infrastructure in CI/CD (tests run on every PR)
- [ ] Baseline metrics established (defects, performance, etc.)

### Phase 4: AI Integration
- [ ] Claude Code / Cursor / Gemini set up
- [ ] Team trained on tool usage
- [ ] First refactor done as pilot (small, low-risk module)
- [ ] Code review process updated for AI-generated code (should be same rigor as human code)

### Phase 5: Monitoring
- [ ] Feature flags wired up for all AI changes
- [ ] Metrics dashboard created (defect rates, deploy frequency, etc.)
- [ ] Alert rules set up (spike in errors = rollback)
- [ ] Weekly retrospectives (what's working? what's not?)

### Phase 6: Scale & Automate
- [ ] Hooks fully preventing dangerous patterns
- [ ] Bulk refactoring tools (dead code removal, duplication cleanup)
- [ ] Dependency upgrade pipeline (AI-assisted, automated)
- [ ] Documentation generation (Cursor/Claude Code can write your docs)

---

## Sources

### AI Tools & Legacy Code
- [Top AI Code Refactoring Tools for Tackling Technical Debt in 2026](https://www.byteable.ai/blog/top-ai-code-refactoring-tools-for-tackling-technical-debt-in-2026)
- [Best legacy code modernization tools](https://www.altamira.ai/blog/best-legacy-code-modernization-tools/)
- [AI-Powered Legacy Modernization: Transforming Processes](https://www.fullstack.com/labs/resources/blog/how-ai-is-transforming-legacy-modernization)
- [AI Code Refactoring | Upgrade Legacy Systems Safely](https://dextralabs.com/blog/ai-code-refactoring/)
- [Modernizing Enterprise Legacy Systems With AI: A Zero-Disruption Strategy](https://www.tothenew.com/insights/article/digital-engineering-scalable-ai-transformations)

### Testing & Safety
- [Approval Tests - Change Messy Software Without Breaking It](https://understandlegacycode.com/approval-tests/)
- [Characterization testing - refactoring legacy code with confidence](https://cloudamite.com/characterization-testing/)
- [Best Practices for AI Refactoring Legacy Code: 7 Safe Rules](https://www.codegeeks.solutions/blog/best-practices-for-ai-refactoring-legacy-code)
- [How Generative AI Can Assist in Legacy Code Refactoring](https://modlogix.com/blog/how-generative-ai-can-assist-in-legacy-code-refactoring/)

### Migration Strategies
- [Accelerating code migrations with AI](https://research.google/blog/accelerating-code-migrations-with-ai/)
- [Legacy Code Migration AI Guide: Tools, Strategies & Best Practices](https://www.leanware.co/insights/legacy-code-migration-ai-guide)
- [Strangler fig pattern - AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/modernization-decomposing-monoliths/strangler-fig.html)
- [The Strangler Fig application pattern: incremental modernization to microservices](https://microservices.io/post/refactoring/2023/06/21/strangler-fig-application-pattern-incremental-modernization-to-services.md.html)
- [bliki: Strangler Fig - Martin Fowler](https://martinfowler.com/bliki/StranglerFigApplication.html)

### Specific Framework Migrations
- [AI-Driven Migration: A Strategic Roadmap from AngularJS to Angular 21](https://medium.com/@rictorres.uyu/ai-driven-migration-a-strategic-roadmap-from-angularjs-to-angular-21-7045c6826629)
- [HeroDevs: The Slog is Real: Possibilities and Limitations of AI-Assisted AngularJS Migrations](https://www.herodevs.com/blog-posts/the-slog-is-real-possibilities-and-limitations-of-ai-assisted-angularjs-migrations)
- [jQuery Modernization Guide: Move to React, Angular, Vue](https://www.legacyleap.ai/blog/jquery-migration/)
- [AngularJS to Angular Migration: Gen AI Guide 2026](https://www.legacyleap.ai/blog/angularjs-to-angular-genai-modernization/)

### Technical Debt & Code Analysis
- [Top Technical Debt Measurement Tools for Developers in 2026](https://www.codeant.ai/blogs/tools-measure-technical-debt)
- [Can AI solve your technical debt problem?](https://www.cio.com/article/3966322/can-ai-solve-your-technical-debt-problem)
- [Exposing dead code: strategies for detection and elimination](https://vfunction.com/blog/dead-code/)
- [Managing Technical Debt with AI-Powered Productivity Tools: A Complete Guide](https://www.qodo.ai/blog/managing-technical-debt-ai-powered-productivity-tools-guide/)
- [8 AI Tools for Technical Debt That Actually Reduce It](https://codegen.com/blog/ai-tools-for-technical-debt/)

### Tool-Specific Guidance
- [Claude Code vs Cursor – Codeaholicguy](https://codeaholicguy.com/2026/01/10/claude-code-vs-cursor/)
- [Legacy Code Modernization with Claude Code: Breaking Through Context Window Barriers](https://www.tribe.ai/applied-ai/legacy-code-modernization-with-claude-code-breaking-through-context-window-barriers)
- [Using CLAUDE.MD files: Customizing Claude Code for your codebase](https://claude.com/blog/using-claude-md-files)
- [Cursor – Rules (Project Rules)](https://docs.cursor.com/context/rules)
- [Gemini 1.5 Pro 2M context window](https://developers.googleblog.com/en/new-features-for-the-gemini-api-and-google-ai-studio/)
- [Long context | Gemini API](https://ai.google.dev/gemini-api/docs/long-context)

### Risk Management & Deployment
- [Understanding canary releases and feature flags in software delivery](https://www.harness.io/blog/canary-release-feature-flags)
- [Ship Faster, Safer: A Guide to Feature Flags for Canary Releases & A/B Testing](https://www.meerako.com/blogs/feature-flags-guide-canary-release-ab-testing-launchdarkly)
- [Compliance in the Age of AI: Why Strong CI/CD Foundations Matter](https://devops.com/compliance-in-the-age-of-ai-why-strong-ci-cd-foundations-matter)

### Monolithic Architecture & Decomposition
- [Kinde: AI-Assisted Microservices Decomposition Breaking Down Monoliths Intelligently](https://www.kinde.com/learn/ai-for-software-engineering/ai-devops/ai-assisted-microservices-decomposition-breaking-down-monoliths-intelligently/)
- [Migrate Monolithic to Microservices Using Generative AI in 8 Weeks](https://www.optisolbusiness.com/insight/how-to-migrate-monolithic-to-microservices-using-generative-ai)

---

## Next Steps

1. **Read section 1** (Assessment Phase) and score your codebase
2. **If score > 50**, jump to section 2 (Onboarding) and start with CLAUDE.md
3. **If score < 50**, invest in section 3 (Build a test safety net) before bringing in AI
4. **Use section 4-6** to plan your first refactor (pick a small, well-scoped module)
5. **Reference section 7** to pick your tool (Claude Code for complex work, Cursor for interactive editing, Gemini for initial analysis)
6. **Use section 10** (checklist) as your project tracking sheet

The path to AI-powered legacy modernization is long, but each step reduces risk and increases confidence. Start small, measure everything, and expand gradually.

---

## Related Topics

- [When Not to Use AI](when-not-to-use-ai.md) — Understanding where AI is risky in critical legacy systems
- [Testing AI-Generated Code](testing-ai-generated-code.md) — Comprehensive testing requirements for legacy refactoring
- [AI on Large Codebases](ai-on-large-codebases.md) — Techniques for managing large codebase context
