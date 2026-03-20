---
name: review-checklist
description: Code review checklist for Woodworking Sidekick. Use when reviewing code changes, before committing, or after implementing a feature.
---

# Code Review Checklist

## Correctness
- [ ] Logic handles edge cases (empty tool profiles, missing dimensions, LLM returning partial JSON)
- [ ] Plan validation catches dimensional errors (board feet math, cut-from-material check, nominal vs actual)
- [ ] Joinery recommendations match user's tool profile — no mortise & tenon without drill press
- [ ] Wood movement noted for solid panels wider than 6 inches
- [ ] Error boundaries handle LLM failures gracefully (timeouts, invalid responses, rate limits)
- [ ] Chat responses reference the user's specific plan, not generic advice

## Security
- [ ] No secrets or credentials in code (API keys, Supabase service keys)
- [ ] Input validation on all API routes (Zod schemas for request bodies)
- [ ] Supabase RLS policies enforced — users can only access their own projects/messages
- [ ] No raw user input passed to LLM system prompts without sanitization
- [ ] Auth middleware on all protected routes

## Plan Quality
- [ ] Generated plans use actual lumber dimensions, not nominal (1x6 = 3/4" × 5-1/2")
- [ ] Cut list parts are extractable from specified material pieces
- [ ] Waste factor applied (15% hardwood, 10% plywood)
- [ ] Safety warnings included for small-piece table saw cuts (push sticks/sleds)
- [ ] Validation passes on all golden path projects before deploying

## Testing
- [ ] Tests exist for new/changed behavior
- [ ] Tests cover error cases (LLM timeout, invalid JSON, validation failure, auth errors)
- [ ] Gemini API calls mocked in unit tests — no real API calls
- [ ] Validation logic tested with real dimension math (not mocked)
- [ ] All tests pass: `npm test`
- [ ] Coverage 80%+ on changed modules

## Style
- [ ] Follows CLAUDE.md conventions (Server Components, Zod, prompts in lib/prompts/)
- [ ] Components under 150 lines
- [ ] TypeScript strict mode — no `any` without justification
- [ ] Prompt templates stored as constants, not inline strings
- [ ] Prettier + ESLint pass

## Performance
- [ ] Plan generation uses streaming for real-time UX feedback
- [ ] Chat loads only last 20 messages as conversation history
- [ ] Plan JSON in chat system prompt, not duplicated in message history
- [ ] Server Components used for plan rendering (no client-side data fetching for static content)
- [ ] Images use next/image for optimization
