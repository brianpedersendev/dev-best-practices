# Technical Feasibility: AI Vision for Food Calorie Estimation

**Date:** 2026-03-21

## Vision Model Comparison for Food Recognition

### Head-to-Head: GPT-4o vs Claude vs Gemini

A [2025 University of Gothenburg study](https://pmc.ncbi.nlm.nih.gov/articles/PMC12513282/) directly compared ChatGPT-4o, Claude 3.5 Sonnet, and Gemini 1.5 Pro on 52 standardized food photographs (individual foods + complete meals, 3 portion sizes each):

| Model | Weight Estimation MAPE | Energy Estimation MAPE | Notes |
|-------|----------------------|----------------------|-------|
| **ChatGPT-4o** | 36.3% | 35.8% | Most consistent (CV < 15%) |
| **Claude 3.5 Sonnet** | 37.3% | ~35.8% | Comparable to GPT-4o |
| **Gemini 1.5 Pro** | 65-70% | 65-70% | Significantly worse |

**Key findings:**
- GPT-4o and Claude perform comparably and **significantly outperform Gemini**
- All models are worse with larger portion sizes
- Occasional catastrophic misidentification (Claude mistook scrambled eggs for pasta once; Gemini confused falafel for meatballs)
- GPT-4o achieves food identification accuracy of ~89.8% with portion size correlation r = 0.81

### GPT-4o Specific Performance

A [separate evaluation](https://www.mdpi.com/2072-6643/17/4/607) found GPT-4V achieves mean absolute errors comparable with **professional dietitians** (46.3g vs 48.5g) even in low-light conditions.

### Specialized Food Recognition APIs

A [comparative study](https://pmc.ncbi.nlm.nih.gov/articles/PMC7752530/) of dedicated food APIs found:

| API | Top-1 Accuracy | Top-5 Accuracy |
|-----|---------------|----------------|
| Calorie Mama | 63% | 88% |
| Bitesnap | 49% | 71% |
| Foodvisor | 46% | 72% |
| Clarifai Food | 38% | 64% |
| LogMeal | Below Clarifai | Below Clarifai |

**Verdict:** General-purpose vision LLMs (GPT-4o, Claude) now **outperform** most specialized food APIs for food identification AND provide calorie estimation in a single call. Specialized APIs only identify food — you still need a separate nutrition database lookup.

## Accuracy: Is ~35% Error Good Enough?

### Context for Weight Loss

- FDA allows **20% variance** on food nutrition labels
- Humans estimate calories with **20-50% error** without any tools
- Research shows **consistency matters more than precision** for weight loss — systematic tracking at even rough accuracy creates awareness that changes behavior
- SnapCalorie (best-in-class dedicated app) reports **16% error** with LiDAR depth sensing — but requires specific hardware

### Practical Assessment

At ~35% MAPE from a general vision LLM:
- A 500-calorie meal could be estimated as 325-675 calories
- Over a full day (5 meals), errors tend to average out somewhat
- For weight loss tracking, **directional accuracy** (high vs low calorie day) is more valuable than precise numbers
- This is comparable to what most people achieve with manual logging (picking "chicken breast" from a database without weighing)

**Conclusion:** 35% MAPE is adequate for a personal weight loss tracking tool. Not clinical-grade, but better than most humans do unaided.

## Recommended Approach: General-Purpose LLM

### Why LLM over Specialized API

1. **Better accuracy** — GPT-4o/Claude outperform Calorie Mama, Clarifai, etc.
2. **Single call** — identifies food AND estimates calories/portions in one request
3. **Natural language output** — can describe what it sees conversationally
4. **Prompt engineering** — can be instructed to ask about portion context, estimate ranges, etc.
5. **No separate nutrition DB needed** — models have extensive nutrition knowledge built in
6. **Improving rapidly** — each model generation gets better; specialized APIs update slower

### Cost Per Call

| Model | ~Cost per food photo | Cost at 5 photos/day | Monthly cost |
|-------|---------------------|---------------------|-------------|
| **GPT-4o** | ~$0.002-0.004 | ~$0.01-0.02/day | **~$0.30-0.60** |
| **Claude Sonnet 4.6** | ~$0.004-0.006 | ~$0.02-0.03/day | **~$0.60-0.90** |
| **Claude Haiku 4.5** | ~$0.001-0.002 | ~$0.005-0.01/day | **~$0.15-0.30** |
| **Gemini 1.5 Flash** | ~$0.001 | ~$0.005/day | **~$0.15** |

All options are extremely affordable for personal use. Even the most expensive option (Claude Sonnet) is under $1/month.

### Recommended Model: GPT-4o or Claude Sonnet

- Best accuracy among general LLMs
- Affordable at personal-use volume
- GPT-4o has a slight edge in consistency (CV < 15%)
- Claude Sonnet is comparable in accuracy
- Either works well — choose based on API preference

### Prompt Engineering Best Practices

Based on [practical testing](https://medium.com/@ceo_44783/do-you-use-llms-to-help-you-track-your-calories-heres-how-to-make-them-more-accurate-e517ddacea01):

1. **Ask the model to identify each food item separately** before estimating totals
2. **Request estimated weight/portion size** — models are better at calories when they reason about mass first
3. **Provide context** — "this is on a standard dinner plate" helps with portion scaling
4. **Request structured output** (JSON) for easy parsing
5. **Include a confidence indicator** — let the model flag when it's uncertain
6. Reference objects (coins, hands) **don't reliably help** — models aren't calibrated for visual size references

### Advanced: DietAI24 Framework

A [Nature study (Nov 2025)](https://www.nature.com/articles/s43856-025-01159-0) showed that combining vision LLMs with RAG (retrieval from nutrition databases like USDA) significantly improves accuracy. This is a potential v2 enhancement but overkill for MVP.

## Known Limitations

1. **Portion estimation is the weakest link** — 2D photos lack depth information
2. **Mixed dishes** (casseroles, stews, stir-fries) are harder than individual items
3. **Sauces, dressings, oils** — often invisible but calorie-dense; models tend to undercount
4. **Lighting and angles** — bad photos degrade accuracy
5. **Cultural/regional foods** — models trained primarily on Western foods may struggle with less common cuisines
6. **No ground truth** — the user won't know when estimates are wildly off

## Sources

- [PMC: Performance Evaluation of 3 LLMs for Nutritional Content Estimation](https://pmc.ncbi.nlm.nih.gov/articles/PMC12513282/)
- [MDPI: Evaluation of ChatGPT for Nutrient Estimation from Meal Photos](https://www.mdpi.com/2072-6643/17/4/607)
- [Nature: DietAI24 Framework](https://www.nature.com/articles/s43856-025-01159-0)
- [PMC: Comparison of Food Image Recognition Platforms](https://pmc.ncbi.nlm.nih.gov/articles/PMC7752530/)
- [Medium: Making LLM Calorie Tracking More Accurate](https://medium.com/@ceo_44783/do-you-use-llms-to-help-you-track-your-calories-heres-how-to-make-them-more-accurate-e517ddacea01)
- [Claude API Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [OpenAI API Pricing](https://openai.com/api/pricing/)
