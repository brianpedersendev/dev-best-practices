# Implementation Plan: AI-Enhanced Ski Ticket Ecommerce POC
**Date:** 2026-03-29
**Platform:** NopCommerce 4.90 Headless
**Developer:** Solo
**Purpose:** Personal learning — demonstrate 4 high-impact AI features for ski resort ecommerce

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Custom Frontend (Next.js)                 │
│  ┌──────────┐  ┌──────────┐  ┌─────────┐  ┌─────────────┐  │
│  │ Ticket    │  │ Chatbot  │  │ Group   │  │ Schema.org  │  │
│  │ Browser   │  │ Widget   │  │ Planner │  │ + MCP Layer │  │
│  │ (dynamic  │  │ (stream) │  │ (shared │  │ (structured │  │
│  │  pricing) │  │          │  │  links) │  │  data)      │  │
│  └─────┬────┘  └────┬─────┘  └────┬────┘  └──────┬──────┘  │
└────────┼────────────┼─────────────┼───────────────┼─────────┘
         │            │             │               │
    ┌────▼────────────▼─────────────▼───────────────▼─────────┐
    │              AI Middleware (FastAPI / Python)             │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
    │  │ Pricing  │  │ Chat     │  │ Group    │  │ MCP     │ │
    │  │ Engine   │  │ Service  │  │ Optimize │  │ Server  │ │
    │  │ (XGBoost)│  │ (Claude) │  │ (Claude) │  │         │ │
    │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
    └───────┼─────────────┼─────────────┼──────────────┼──────┘
            │             │             │              │
    ┌───────▼─────────────▼─────────────▼──────────────▼──────┐
    │                    Data Layer                             │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
    │  │NopCommerce│  │ Weather  │  │PostgreSQL│  │ Vector  │ │
    │  │  REST API │  │ APIs     │  │(groups,  │  │ Store   │ │
    │  │ (products,│  │(OpenWx,  │  │ sessions)│  │(resort  │ │
    │  │ cart, etc)│  │ NOAA)    │  │          │  │ knowledge│ │
    │  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
    └─────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Frontend** | Next.js 14+ (App Router) | SSR for Schema.org markup, streaming for chatbot, React Server Components |
| **Backend commerce** | NopCommerce 4.90 + NopAdvance REST API | You're familiar with it, 200+ endpoints, headless-ready |
| **AI middleware** | Python FastAPI | Best ML ecosystem (scikit-learn, XGBoost), Claude SDK, easy API development |
| **LLM** | Claude API (Sonnet 4.6) | Best tool use for chatbot, good reasoning for group optimization, cost-efficient |
| **ML model** | XGBoost (Python) | Industry standard for tabular demand forecasting, lightweight |
| **Database** | PostgreSQL | Group session storage, preference data, pricing history |
| **Vector store** | Chroma (embedded) | Simple, local, free — good enough for POC RAG |
| **Weather data** | OpenWeather API (free tier) | 5-day forecast + historical, sufficient for POC |
| **Hosting** | Vercel (frontend) + Railway (middleware + DB) | Easy deployment, free/cheap tiers |

---

## Phase Breakdown

### Phase 1: Foundation & Agentic AI Readiness (Week 1-2)

**Goal:** Set up the project scaffold, NopCommerce product catalog, and make the site discoverable by AI agents.

#### 1.1 Project Setup
- [ ] Initialize Next.js project with TypeScript
- [ ] Set up FastAPI middleware project
- [ ] Configure NopCommerce 4.90 with NopAdvance REST API plugin
- [ ] Set up PostgreSQL on Railway
- [ ] Create development environment (Docker Compose for local)

#### 1.2 Seed Product Catalog in NopCommerce
Create a realistic ski resort product catalog:
- [ ] **Lift tickets:** Adult day, child day, senior day, half-day, multi-day (2,3,5-day). Each with date-based pricing tiers (peak, regular, value).
- [ ] **Season passes:** Full season, midweek-only, student, family bundle
- [ ] **Lessons:** Group beginner, group intermediate, private (1hr, 2hr), kids camp (half-day, full-day)
- [ ] **Rentals:** Ski package, snowboard package, premium package, kids package. Half-day and full-day.
- [ ] **Bundles:** Beginner package (lift + lesson + rental), Family day (2 adult + 2 child lifts + kids lesson), Date night (2 lifts + 2 rentals + dinner voucher)

#### 1.3 Agentic AI Readiness
- [ ] **Schema.org markup on all product pages:**
  - `Product` type for tickets/passes with `Offer` (price, availability, validFrom/validThrough)
  - `Event` type for lessons with `startDate`, `location`, `offers`
  - `Place` type for the resort with `geo`, `address`, `amenityFeature`
  - `AggregateOffer` for bundles with `lowPrice`/`highPrice`
- [ ] **JSON-LD in page headers** — machine-readable product/pricing data on every page
- [ ] **Lightweight inventory API** — `/api/inventory` endpoint returning structured JSON:
  ```json
  {
    "resort": "Summit Peak Resort",
    "date": "2026-03-15",
    "products": [
      {
        "type": "lift_ticket",
        "name": "Adult Day Ticket",
        "price": 149,
        "availability": "in_stock",
        "capacity_remaining": 847
      }
    ],
    "conditions": {
      "snow_depth": 48,
      "new_snow_24h": 6,
      "weather": "partly_cloudy",
      "temperature_high": 28
    }
  }
  ```
- [ ] **MCP Server (stretch goal):** Build a Model Context Protocol server exposing resort tools:
  - `search_tickets(date, ticket_type, quantity)` — search available tickets
  - `get_conditions(date)` — current/forecast conditions
  - `get_pricing(product_id, date)` — real-time pricing
  - `check_availability(date, product_ids)` — bulk availability check

**Deliverable:** A headless storefront with a realistic product catalog that AI agents can discover via Schema.org markup and query via API/MCP.

---

### Phase 2: Conversational Booking Chatbot (Week 3-4)

**Goal:** Build an AI chatbot that helps users find the right ticket/package through natural conversation with real inventory lookups.

#### 2.1 Resort Knowledge Base (RAG)
- [ ] Create resort knowledge documents:
  - Trail map data (runs by difficulty, lifts, terrain parks)
  - Lesson program details (age requirements, skill levels, what's included)
  - Rental equipment info (brands, sizing, what's included)
  - Resort policies (refunds, weather closures, age cutoffs)
  - FAQ content (parking, hours, dining, first-timer tips)
- [ ] Embed documents into Chroma vector store
- [ ] Build retrieval pipeline: query → vector search → context injection

#### 2.2 Chatbot Tool Definitions
Define Claude API tools the chatbot can call:
```python
tools = [
    {
        "name": "search_products",
        "description": "Search ski resort products by type, date, and quantity",
        "input_schema": {
            "type": "object",
            "properties": {
                "date": {"type": "string", "description": "YYYY-MM-DD"},
                "product_type": {"enum": ["lift_ticket", "lesson", "rental", "bundle"]},
                "quantity": {"type": "integer"},
                "skill_level": {"enum": ["beginner", "intermediate", "advanced"]},
                "age_group": {"enum": ["child", "adult", "senior"]}
            }
        }
    },
    {
        "name": "get_pricing",
        "description": "Get current price for a product on a specific date",
        "input_schema": { ... }
    },
    {
        "name": "check_conditions",
        "description": "Get snow conditions and weather forecast for a date",
        "input_schema": { ... }
    },
    {
        "name": "add_to_cart",
        "description": "Add items to the shopping cart",
        "input_schema": { ... }
    },
    {
        "name": "get_resort_info",
        "description": "Look up resort information (trails, policies, FAQ)",
        "input_schema": { ... }
    }
]
```

#### 2.3 Chat UI with Streaming
- [ ] Build chat widget component in Next.js
- [ ] Implement SSE streaming from FastAPI → frontend
- [ ] Show tool use indicators ("Checking availability for March 15...")
- [ ] Render product cards inline in chat when recommending items
- [ ] "Add to cart" button within chat responses

#### 2.4 System Prompt Engineering
- [ ] Craft system prompt with resort persona, product knowledge, and upsell behaviors
- [ ] Include instructions for: understanding group needs, suggesting appropriate skill-level products, recommending bundles over individual items, surfacing conditions when relevant
- [ ] Test with scenarios:
  - "We're a family of 4, two kids ages 8 and 12, never skied before"
  - "Best day to come this week if I want to avoid crowds?"
  - "What's the difference between a group and private lesson?"
  - "I need lift tickets for Saturday for 6 adults"

**Deliverable:** A working chatbot that understands ski-specific queries, looks up real inventory, recommends products, and adds to cart — with streaming responses and inline product cards.

---

### Phase 3: Group Trip Coordinator (Week 5-6)

**Goal:** Build an AI-powered group booking flow that collects preferences from multiple people and generates an optimized group package.

#### 3.1 Group Session Management
- [ ] Database schema:
  ```sql
  CREATE TABLE group_trips (
      id UUID PRIMARY KEY,
      organizer_name TEXT,
      resort_date DATE,
      created_at TIMESTAMP,
      status TEXT -- 'collecting', 'optimizing', 'ready', 'booked'
  );

  CREATE TABLE group_members (
      id UUID PRIMARY KEY,
      trip_id UUID REFERENCES group_trips(id),
      name TEXT,
      skill_level TEXT,    -- beginner, intermediate, advanced
      age_group TEXT,      -- child, teen, adult, senior
      needs_rental BOOLEAN,
      needs_lesson BOOLEAN,
      budget_preference TEXT, -- budget, moderate, premium
      special_requests TEXT,
      submitted_at TIMESTAMP
  );
  ```
- [ ] API endpoints:
  - `POST /api/groups` — organizer creates trip (returns shareable link)
  - `GET /api/groups/{id}` — get trip status and member list
  - `POST /api/groups/{id}/members` — member submits preferences
  - `POST /api/groups/{id}/optimize` — trigger AI optimization
  - `GET /api/groups/{id}/package` — get recommended package

#### 3.2 Member Preference Collection UI
- [ ] Shareable link page (`/group/{trip_id}`)
- [ ] Simple form: name, skill level, age, need rental?, need lesson?, budget preference, special requests
- [ ] Real-time member count display ("4 of 6 members have responded")
- [ ] Mobile-friendly (members will open this from a text message)

#### 3.3 AI Group Optimizer
- [ ] Claude API call with group member data + available products + pricing
- [ ] Optimization prompt:
  ```
  Given these group members and their preferences, recommend the optimal
  combination of tickets, lessons, and rentals that:
  1. Matches each person's skill level and age
  2. Groups beginners together for group lessons where possible
  3. Stays within budget preferences
  4. Bundles products for maximum savings
  5. Handles mixed-ability groups (some ski, some don't)

  Return a structured JSON response with per-person items and group totals.
  ```
- [ ] Handle edge cases: mixed dates, partial attendance, childcare needs, non-skiers in group

#### 3.4 Package Presentation & Checkout
- [ ] Display optimized package with per-person breakdown
- [ ] Show savings vs. buying individually
- [ ] Allow organizer to adjust (swap products, change options)
- [ ] "Book for group" button → adds all items to NopCommerce cart
- [ ] Cost-splitting display (per-person totals)

**Deliverable:** A shareable group planning link where members input preferences, AI generates an optimized group package, and the organizer can book with one click.

---

### Phase 4: Dynamic Pricing Engine (Week 7-8)

**Goal:** Build an ML-powered dynamic pricing model that adjusts ticket prices based on demand signals, weather, and calendar data.

#### 4.1 Synthetic Data Generation
- [ ] Generate 2 years of synthetic historical data:
  ```python
  # Features per day
  - date, day_of_week, month
  - is_holiday, is_school_break, is_weekend
  - temperature_high, temperature_low
  - snowfall_24h, snow_depth, conditions (powder/groomed/icy)
  - days_until (advance purchase lead time)
  - historical_demand (tickets sold, normalized 0-1)
  - competitor_price (simulated)

  # Target
  - optimal_price (base_price * demand_multiplier)
  ```
- [ ] Model demand curves: weekends > weekdays, powder days spike, holidays peak, spring decline
- [ ] Add realistic noise and seasonality

#### 4.2 ML Model Training
- [ ] Train XGBoost regressor on synthetic data
- [ ] Features: weather forecast, calendar signals, lead time, historical demand patterns
- [ ] Target: price multiplier (0.7x to 1.5x of base price)
- [ ] Evaluate with holdout set, tune hyperparameters
- [ ] Export model for serving (joblib/pickle)

#### 4.3 Pricing API
- [ ] `GET /api/pricing/{product_id}?date={date}` — returns ML-adjusted price
- [ ] `GET /api/pricing/calendar?month={month}` — returns price heatmap for a month
- [ ] Integrate OpenWeather API for real forecast data
- [ ] Fallback to base price if model or weather API fails

#### 4.4 Frontend Integration
- [ ] **Calendar heatmap view:** Color-coded calendar showing price by day (green = value, yellow = regular, red = peak)
- [ ] **Price explanation:** "This price reflects: weekend demand (+15%), fresh powder forecast (+10%), Presidents' Day week (+20%)"
- [ ] **"Best value" badge:** Highlight the cheapest upcoming dates
- [ ] **Price trend indicator:** "Prices for this date are likely to increase" (based on model confidence + lead time)

**Deliverable:** A working dynamic pricing engine with a visual calendar heatmap, price explanations, and weather-driven price adjustments.

---

## Data Model (Simplified)

```
NopCommerce (existing):
├── Products (tickets, passes, lessons, rentals, bundles)
├── Categories (lift-tickets, lessons, rentals, bundles)
├── Customers
├── Orders
└── ShoppingCart

PostgreSQL (new, for AI features):
├── group_trips (id, organizer, date, status)
├── group_members (id, trip_id, name, preferences...)
├── pricing_history (date, product_id, base_price, ml_price, demand_score)
├── chat_sessions (id, customer_id, messages_json, created_at)
└── weather_cache (date, location, forecast_json, fetched_at)

Chroma (vector store):
└── resort_knowledge (trail info, policies, FAQ, lesson details)
```

---

## API Surface

### Public APIs (for frontend)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/products` | List products (proxied from NopCommerce) |
| GET | `/api/pricing/{product_id}?date=` | Get ML-adjusted price |
| GET | `/api/pricing/calendar?month=` | Price heatmap data |
| GET | `/api/conditions?date=` | Weather/snow conditions |
| POST | `/api/chat` | Send chat message (SSE stream response) |
| POST | `/api/groups` | Create group trip |
| GET | `/api/groups/{id}` | Get group status |
| POST | `/api/groups/{id}/members` | Submit member preferences |
| POST | `/api/groups/{id}/optimize` | Generate optimized package |

### Machine-Readable APIs (for AI agents)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/inventory` | Structured inventory for AI agents |
| GET | `/.well-known/ai-inventory.json` | Discovery endpoint |
| MCP | `search_tickets` | MCP tool for ticket search |
| MCP | `get_conditions` | MCP tool for conditions |
| MCP | `check_availability` | MCP tool for availability |

---

## Testing Strategy

### Per Feature
- **Agentic readiness:** Validate Schema.org with Google Rich Results Test. Test MCP server with Claude Code. Verify JSON-LD parses correctly.
- **Chatbot:** Scenario-based testing with 10+ common user queries. Verify tool calls return correct data. Test streaming under load. Test edge cases (ambiguous requests, out-of-stock items).
- **Group coordinator:** Test with groups of 2, 5, 10 members. Test mixed skill levels, budget constraints, partial responses. Verify optimization produces valid packages.
- **Dynamic pricing:** Backtest model against synthetic holdout data. Verify prices stay within configured bounds (0.7x-1.5x). Test weather API fallback. Verify calendar heatmap renders correctly.

### Integration Tests
- Full purchase flow: chatbot recommends → add to cart → checkout via NopCommerce
- Group flow: create → share link → collect preferences → optimize → book
- Pricing flow: weather changes → model re-prices → frontend updates

---

## Deployment

### Local Development
```bash
docker-compose up  # NopCommerce + PostgreSQL + Chroma
cd frontend && npm run dev  # Next.js on localhost:3000
cd middleware && uvicorn main:app --reload  # FastAPI on localhost:8000
```

### Production (POC)
- Frontend: Vercel (free tier)
- Middleware: Railway ($5/month)
- PostgreSQL: Railway (included)
- NopCommerce: Existing hosting
- Chroma: Embedded in middleware container

---

## Traceability

### Original Problem
Explore where AI adds the most value for a ski resort operator's online ticket shop.

### How This Plan Addresses It
| Success Criteria | Plan Feature |
|-----------------|--------------|
| Learn about AI in ecommerce | 4 features spanning structured data, LLMs, ML, and optimization |
| Rank AI use cases by value | Research synthesis provides ranking; POC validates top 4 |
| Working POC demos | Each phase produces a functional, demo-able feature |
| Documented findings | Research docs + plan + implementation learnings |

### What's Deferred to Later
| Feature | Why Deferred |
|---------|-------------|
| Payment splitting for groups | Adds complexity, not core to the AI learning |
| Real RFID data integration | Needs resort partnership; synthetic data sufficient for POC |
| Production deployment | Purpose is learning, not production |
| Cart abandonment / behavioral nudges | Lower priority; standard ecommerce AI |
| Season pass renewal predictions | Needs real historical data |
| Mobile app | Web-first is sufficient for POC |

---

## Estimated Timeline

| Phase | Feature | Duration | Cumulative |
|-------|---------|----------|------------|
| 1 | Foundation + Agentic Readiness | 2 weeks | Week 2 |
| 2 | Conversational Chatbot | 2 weeks | Week 4 |
| 3 | Group Trip Coordinator | 2 weeks | Week 6 |
| 4 | Dynamic Pricing Engine | 2 weeks | Week 8 |

Each phase is independently demo-able — you can stop after any phase and have a working showcase.
