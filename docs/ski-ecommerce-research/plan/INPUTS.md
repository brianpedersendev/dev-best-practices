# Planning Inputs

## Source Documents
- **Project Brief:** `docs/PROJECT-BRIEF.md` — validated idea from Phase 1 interview
- **Research Synthesis:** `docs/ski-ecommerce-research/SYNTHESIS.md` — GO recommendation with 4 prioritized features
- **Competitive Landscape:** `docs/ski-ecommerce-research/landscape.md`
- **Technical Feasibility:** `docs/ski-ecommerce-research/technical.md`
- **Domain Analysis:** `docs/ski-ecommerce-research/domain.md`

## Key Decisions from Research
1. **4 features selected:** Agentic readiness, chatbot, group coordinator, dynamic pricing
2. **Architecture:** AI-augmented (NopCommerce core + AI services layered on)
3. **AI service:** Claude API (Sonnet) for LLM features, XGBoost for pricing model
4. **Data strategy:** Synthetic data for pricing/demand; real weather APIs; NopCommerce catalog as source of truth
5. **Scope:** POC for personal learning, not production deployment

## User Constraints
- Solo developer
- Familiar with NopCommerce APIs
- Open to any AI services
- No hard timeline
- Learning-focused
