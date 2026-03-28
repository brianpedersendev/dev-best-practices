# Getting Started: AI-Augmented Development

> Ship top-of-the-line apps faster using AI tools, agents, and modern dev patterns.
> Last updated: 2026-03-22

---

## Top Takeaways

**1. Write tests before asking AI to code.** TDD + AI reduces defects 40-90%. This is the single highest-leverage practice — agents thrive with clear test contracts.

**2. Plan first, execute second.** Use Plan Mode (Claude) or Composer planning (Cursor) before auto-executing. Cuts token waste in half and prevents solving the wrong problem.

**3. Write specs, not vague prompts.** Specification-driven development (spec → phased tasks → incremental prompts → verify) reduces iteration cycles 30-50% vs. open-ended requests.

**4. Use the right tool for the task.** Claude Code for complex/autonomous work, Cursor for daily editing speed, Gemini for huge context and cost-sensitive tasks. No single tool wins everything.

**5. Layer your extensions: Skills → Plugins → MCPs.** Skills = reusable instructions. Plugins = bundled packages. MCPs = protocol-level tool access. Start simple, scale up.

**6. Verify everything.** AI hallucinates in ~1 of 6 queries. Triangulate across sources, check dates, and never trust confident tone as a proxy for correctness.

**7. Enforce rules with hooks, not text.** CLAUDE.md rules fade after context compression. Hooks run every time and can block dangerous actions deterministically.

---

## Guides

### How to Use Each Tool

- **[Claude Code Power User Guide](docs/topics/claude-code-power-user.md)** — TDD workflows, Plan Mode, spec-driven dev, subagents, hooks, session discipline, and keyboard shortcuts. The playbook for getting the most out of Claude Code.

- **[Cursor IDE Power User Guide](docs/topics/cursor-power-user.md)** — Cmd+K/L/I workflows, Composer for multi-file edits, background agents, .mdc rules, MCP setup, and model selection. How to work fast in Cursor.

- **[Gemini Dev Power User Guide](docs/topics/gemini-dev-power-user.md)** — Gemini CLI, 2M token context window, Google ADK for multi-agent, Firebase Genkit, and MCP support. When and why to reach for Gemini.

- **[Tool Comparison: When to Use Each](docs/topics/tool-comparison-when-to-use.md)** — Side-by-side decision matrix for 20 common tasks, head-to-head strengths/weaknesses, hybrid workflow patterns, and cost optimization strategies.

### Remote Dev Environment & Secrets

- **[Remote Dev Environment Setup](docs/topics/remote-dev-environment-setup.md)** — How to run Claude Code in remote sessions (SSH, Codespaces, devcontainers, cloud VMs) with secure secrets and full app access. The #1 problem is secrets: Claude auto-loads `.env` files without asking. This guide covers 4 patterns to prevent secret exposure (1Password/Doppler wrappers, SSH agent forwarding, deny rules, PreToolUse hooks), running your full stack via Docker Compose, and complete step-by-step setup walkthroughs. Start here if you're using Claude Code remotely or worried about secret leakage.

### What to Install

- **[Best of Breed Directory](docs/topics/best-of-breed-directory.md)** — Curated, tiered directory of the most impactful MCP servers, skills, plugins, and tools. Tier 1 (essential for everyone), Tier 2 (stack-specific), Tier 3 (specialized). Includes setup commands.

- **[Best GitHub Repos for Skills, Plugins, MCPs](docs/topics/best-repos-skills-plugins-mcps.md)** — 50+ production-ready repos with star counts, activity status, and what each does. The raw source list behind the curated directory.

### Building Custom Tools

- **[AI-Assisted API Design Guide](docs/topics/ai-assisted-api-design.md)** — Complete guide to designing, building, testing, and documenting APIs faster with AI. Covers: contract-first development (spec → code → test), OpenAPI spec generation from natural language, server stub generation (FastAPI/Express/Go from specs), REST/GraphQL/gRPC design patterns with AI, contract testing (Specmatic/Pact), property-based and fuzz testing, security testing (OWASP API Top 10), auto-generating docs and SDKs, MCP server design (exposing APIs as tools for agents), end-to-end workflow with real examples, and anti-patterns to avoid. Start here to build APIs 3-4x faster using specification-driven development.

- **[Building Custom MCP Servers](docs/topics/building-custom-mcp-servers.md)** — Complete guide to building your own MCP servers from scratch. Covers architecture, step-by-step tutorials for Python (FastMCP) and TypeScript, the three primitives (tools, resources, prompts), wrapping existing APIs, production security patterns, Docker deployment, testing, and real-world examples. Start here if you need custom integrations or internal tool access.

- **[Building OpenClaw Skills](docs/topics/openclaw-skill-development.md)** — Complete practical guide to building, testing, and publishing OpenClaw skills from basics to production. Covers skill architecture, the Agent Communication Protocol (ACP), 5 skill types with examples, the critical "65% pattern" (wrapping MCP servers as skills), ClawHub publishing and security, testing workflows, 5 real-world examples with complete code (CI/CD monitor, email triage, competitor monitor, database queries, meeting→tasks), and production readiness. Start here if you're building automation agents or want to publish to ClawHub.

### Prompt Engineering

- **[Prompt Engineering Patterns for AI-Augmented Development](docs/topics/prompt-engineering-patterns.md)** — Complete guide to writing and managing prompts that produce better AI outputs. Covers: why prompts matter (76% error reduction), CLAUDE.md as system prompts, 5 core patterns (specification-driven, chain-of-thought, few-shot, constraint-based, role-based), phase-specific prompts for each stage of development, evaluation frameworks (LLM-as-judge), 15 production-ready templates for common tasks (feature implementation, bug fix, testing, code review, security audit, etc.), and prompt versioning/maintenance. Start here to systematize your prompts and reduce iteration cycles 30-50%.

### How to Optimize Context & Memory

- **[Context Management & Memory Systems Guide](docs/topics/context-memory-systems.md)** — Practical techniques to reduce token usage by 29-84% through context editing, persistent memory, hierarchical memory architecture, and observation masking. Includes tool-specific strategies for Claude Code, Cursor, and Gemini, with implementation checklist and production benchmarks. Start here to make your AI tools faster and cheaper.

### Working Effectively on Large Codebases

- **[Using AI Development Tools on Large Codebases](docs/topics/ai-on-large-codebases.md)** — Complete guide for 100K+ line projects. Covers: codebase onboarding (hierarchical CLAUDE.md, module-level instructions, indexing strategies), context strategies at scale (targeted loading, progressive disclosure), Gemini's 2M token advantage for whole-codebase analysis, multi-agent patterns for parallel work, monorepo strategies (tool separation, package-level config), large refactoring patterns (phased approach, test gates, feature flags), performance optimization (.cursorignore for 8min→2min indexing), team coordination (shared CLAUDE.md, file locking, code review standards), and 3 production case studies (Goldman Sachs, Salesforce, Stripe). Start here if you're working with a large enterprise codebase or leading a team on distributed AI development.

### How to Cut AI Tool Costs 50-70%

- **[Cost Optimization Playbook](docs/topics/cost-optimization-playbook.md)** — Comprehensive strategy guide to reduce AI spending dramatically while maintaining quality. Covers: where money goes (pricing breakdown, activity costs, monthly budgets by developer profile), context management savings (29-84%), model routing (60% reduction via intelligent distribution), caching strategies (90% off with prompt caching, 40-70% hit rate with semantic caching), tool selection optimization (when Cursor beats Claude, when Gemini wins), subscription strategies (Pro vs Max vs API), team cost management (2-5 person teams to 50+ developers), the hybrid multi-tool approach, token budgeting and monitoring, real team examples, and implementation checklist. Start here to make intelligent cost/quality trade-offs.

### How to Research Before Building

- **[AI Research Strategies Guide](docs/topics/ai-research-strategies.md)** — How to use AI tools for accurate, up-to-date research. Covers hallucination detection, triangulation, tool-specific techniques, research workflows, and staying current.

### Bringing AI to Legacy Codebases

- **[AI in Legacy Codebases Guide](docs/topics/ai-in-legacy-codebases.md)** — Strategic guide to integrating AI tools into complex, underdocumented, or inconsistent codebases. Covers: AI-readiness assessment scorecard, 5-step onboarding with CLAUDE.md, test-first migration (characterization tests, approval testing, test harness), incremental modernization (strangler fig, extract-and-replace, adapter layers), handling common scenarios (no tests, outdated frameworks like jQuery/AngularJS/Python 2, monoliths, spaghetti code, mixed styles), tool-specific strategies (Claude Code, Cursor, Gemini), risk management (feature flags, canary testing, rollback), and a 3-month migration roadmap with success metrics. Start here if you're working with legacy systems that need modernization.

### AI-Native Application Architecture

- **[AI-Native Architecture Guide](docs/topics/ai-native-architecture.md)** — How to design and build applications where AI is the core, not a feature. Covers the distinction between AI-native and AI-augmented apps, agent-backend patterns, data architecture (RAG, vector storage, memory hierarchy), the 2026 tech stack (LangGraph vs CrewAI vs Claude Agent SDK), production patterns (evaluation, observability, cost, security), 4 real-world architecture examples, and decision trees. Start here if you're building a system around agents, not just adding an agent to an existing system.

### RAG and Knowledge Management

- **[RAG Staleness Detection Guide](docs/topics/rag-staleness-detection.md)** — How to detect when RAG knowledge is stale, version embeddings, and prevent confident answers from outdated sources. Essential for fast-moving domains (legal, medical, tech docs, pricing). Covers: staleness detection strategies (timestamp-based freshness scoring with exponential decay, source URL change detection, document hash comparison, semantic drift detection via re-embedding); knowledge versioning with full provenance chains and rollback strategies; freshness-aware retrieval (boosting recent documents, time-decay scoring); automated refresh pipelines (scheduled re-crawling, incremental re-indexing); monitoring and alerting (document age, embedding drift, unreachable sources); anti-patterns; and a 3-week implementation checklist. Includes 8 Python code examples (FreshnessScorer, SourceMonitor, DocumentVersioning, EmbeddingDriftMonitor) and production benchmarks showing 38% of RAG queries retrieve docs >30 days old. Start here before deploying RAG systems in production.

### Deployment and DevOps for AI Apps

- **[Deployment & DevOps Guide](docs/topics/ai-app-deployment-devops.md)** — How to ship, scale, and operate AI-powered applications in production. Covers: what's fundamentally different about AI deployments (non-deterministic outputs, cost scaling, production evaluation), CI/CD patterns (prompt regression testing, LLM-as-a-judge, eval gates, GitHub Actions examples), containerization (Docker multi-stage builds, MCP servers, agents, Docker Compose), infrastructure choices (serverless vs containers vs VMs, GPU scaling, cold start mitigation), observability (Langfuse/LangSmith, OpenTelemetry for agents, quality dashboards, cost tracking), cost controls (token budgets, rate limiting, semantic caching, model fallback), security (prompt injection defense, PII handling, API key rotation, audit logging), rollback strategies (model versioning, blue-green/canary deployments), platform-specific deployment (Vercel, AWS Bedrock, GCP Vertex AI, Railway, Fly.io), and production readiness checklist with 50+ copy-paste examples. Start here before shipping any AI feature to production.

### Multi-Agent & Swarm Patterns

- **[Swarm Patterns by Development Stage](docs/topics/swarm-patterns-by-dev-stage.md)** — The right multi-agent pattern for each phase of development: research, planning, coding, testing, review, debugging, docs, deployment, and maintenance. Includes agent team compositions, implementation guides for LangGraph/CrewAI/Claude SDK, code snippets, and cost analysis.

### Debugging Your Code Faster with AI

- **[AI-Assisted Debugging Guide](docs/topics/ai-assisted-debugging.md)** — How to use Claude Code, Cursor, and Gemini to find and fix bugs 3-4x faster than traditional debugging. Covers: why AI changes debugging (hypothesis generation, codebase-wide analysis, parallel investigation), tool-specific workflows (Claude Plan Mode to understand before fixing, Cursor in-editor debugging, Gemini for 100K+ LOC analysis), the multi-agent hypothesis-generating swarm pattern (11 min vs 45+ min traditional), production incident debugging (log analysis, root cause reconstruction, Meta/DoorDash case studies), debugging AI-generated code (hallucinated APIs, missing edge cases, security vulnerabilities), rubber duck debugging with AI, what AI catches well (off-by-one, null handling, race conditions) vs misses (business logic, timing-dependent bugs), 15 copy-paste debugging prompts for common scenarios (crash analysis, memory leaks, race conditions, performance issues), complete 6-phase debugging workflow, MCP observability servers (Datadog, Splunk), and anti-patterns to avoid. Start here to debug faster and smarter.

### Testing AI-Generated Code

- **[Testing AI-Generated Code](docs/topics/testing-ai-generated-code.md)** — Comprehensive guide to testing strategies for AI code. Covers: the AI code quality problem (1.7x more issues, 45% security flaws, 87% of devs worried about accuracy), TDD as foundation (40-90% defect reduction), testing by type (unit, integration, E2E, property-based, mutation, contract testing), security testing (OWASP Top 10 for AI, SAST with Semgrep, security checklists), AI-assisted test generation (where AI excels and fails), the verification workflow (explain-it test, boundary testing, manual verification), code review for AI code (multi-model, adversarial pattern, what humans should focus on), tool-specific patterns (Claude Code, Cursor, CI/CD), hooks for automatic testing, metrics and monitoring, and production-ready checklists. Includes 25+ code examples and complete CI/CD pipeline examples.

### Hooks & Enforcement

- **[Hooks & Enforcement Patterns](docs/topics/hooks-enforcement-patterns.md)** — The definitive guide to using hooks to enforce coding standards, security, testing, and workflow discipline. Covers why hooks (97-99% compliance) beat text rules (58-73%), hook architecture and exit codes, 18 production-ready patterns organized by purpose (testing, security, code quality, context, workflow), 5 complete recipes (TypeScript, FastAPI, Go, monorepo, security-first), advanced composition, testing and debugging, decision framework, and anti-patterns. Every pattern is copy-paste ready with complete settings.json examples.

### Design & Frontend

- **[AI-Powered Frontend Features](docs/topics/ai-powered-frontend-features.md)** — Complete guide to building AI features that users interact with directly: streaming chat, semantic search, recommendations, content generation, conversational interfaces. Covers: the AI frontend landscape (what users now expect); streaming UI implementation (Vercel AI SDK useChat/useCompletion/useObject, React Server Components + Suspense, skeleton loaders); AI-powered search (semantic search, hybrid ranking, vector databases); recommendations & personalization (collaborative/content-based/hybrid, cold-start solving, real-time personalization); in-app content generation (writing assistants, smart forms, document summarization); conversational interfaces (chat patterns, tool use rendering, message history); real-time AI (transcription, translation, voice); performance optimization (edge functions <50ms, semantic caching, prompt caching); state management (useOptimistic, streaming responses); security (prompt injection defense, XSS protection, API key safety, rate limiting); testing non-deterministic AI output; 5 copy-paste recipes (chat, semantic search, writing assistant, smart form, NL dashboard). TypeScript/React/Next.js code examples, 50+ sources, 2025-2026 research, production checklist. Start here to build AI features users will love.

- **[AI-Assisted Design and Design-to-Code Workflows](docs/topics/ai-design-workflow.md)** — Comprehensive practical guide to AI-powered design, design-to-code pipelines, and component generation. Covers: the 2025-2026 design landscape (Figma Make, v0, Galileo/Stitch, Cursor, Claude), what designers actually use AI for vs hype; design-to-code pipelines with Figma MCP (reading design context, generating code with tokens), v0 screenshot-to-React, Cursor in-editor UI generation; AI component generation (shadcn/ui patterns, production quality matrix, when AI code is good enough); design systems with AI (AI-readable tokens, variant generation, design system enforcement); prototyping workflows (text→interactive in 1 hour); image/asset generation (DALL-E, Flux, Midjourney, MCP servers); responsive design with AI; designer-developer handoff with AI assistance; frontend code quality issues in AI-generated code (accessibility gaps, CSS problems, performance); tools comparison (v0 vs Cursor vs Claude vs Figma AI vs Stitch, pricing, when to use each); 4 end-to-end workflow templates (landing page 2-4 hours, admin dashboard 1 week, mobile screen, design system component). Includes real case studies, anti-patterns, and implementation checklists. 50+ sources, 2025-2026 research.

- **[AI-First UX Design Patterns](docs/topics/ai-first-ux-patterns.md)** — Complete guide to designing user experiences where AI is the core interaction model. Covers: why standard UX patterns break with non-deterministic AI, the trust calibration problem (users develop inappropriate 2-3x trust without guidance), 8 core interaction patterns (chat, inline AI cmd+k, ambient suggestions, structured input→output, hybrid interfaces), streaming & progressive disclosure (skeleton loaders, token-by-token rendering, thinking indicators), confidence & uncertainty visualization (badges, colors, ranges, probabilistic language), human-in-the-loop workflows (approval gates, edit-before-send, smart undo), AI error handling (hallucination detection, graceful degradation, retry patterns), personalization UX (showing AI learning, onboarding, progressive disclosure), multimodal design (text+images+voice+video seamlessly), 6 anti-patterns to avoid (chatbot-for-everything, hiding limitations, no control, uncanny valley), real-world analysis of Cursor, Linear, Notion, Perplexity, v0, ChatGPT (what each does well and why), accessibility patterns (screen readers, keyboard nav), and measuring AI UX quality (task completion, time-to-value, trust calibration, user satisfaction). With wireframe descriptions, component patterns, and 100+ sources from 2025-2026 research.

### Scaling AI Adoption Across Teams

- **[Team AI Onboarding](docs/topics/team-ai-onboarding.md)** — How to get development teams aligned on AI tooling, productive quickly, and maintaining quality standards. The 85% adoption but 52% skepticism reality; 3-month phased rollout with specific Week 1-2 foundations, Weeks 3-4 workflow alignment, Month 2 advanced patterns. Includes: shared CLAUDE.md governance (who owns it, change process, versioning), code review standards for AI code (what to focus on, red flags checklist, multi-model review), training program (TDD, specs, Plan Mode, hands-on exercises, pairing), quality gates (pre-commit + CI/CD + AI-specific), cost management (per-dev budgeting, model selection, monitoring), security policies (tiered classification from AI-safe to human-only, escalation), measuring success (10 key metrics, NOT vanity metrics), 10 common pitfalls with prevention strategies, 5 production templates (team CLAUDE.md, TDD workflow, code review rubric, new hire checklist, weekly retro). 2025-2026 enterprise adoption research.

- **[Multi-Model AI Governance](docs/topics/multi-model-governance.md)** — How to keep codebases consistent when multiple AI tools (Claude Code + Cursor + Gemini, etc.) are working on the same code. Solves the "tool divergence" problem: different tools give conflicting advice, use different conventions, pull code in different directions. Covers: configuration versioning (CLAUDE.md as single source of truth, rulesync tool to keep .cursorrules and GEMINI.md in sync), shared enforcement (pre-commit hooks, linting rules that all tools respect), detecting when tools diverge (code review flags, automated scripts), team coordination (who owns tool configs, change process, disagreement resolution), output reconciliation (choosing between conflicting suggestions), practical 2-hour setup for 2-3 tools, step-by-step training script, and implementation checklist. Includes anti-patterns (configs not version controlled, too-strict rules, conflicting configs) and sources on governance frameworks and rule management tools. Start here if your team uses multiple AI coding tools simultaneously.

### Project Bootstrapping

- **[Project Research Skill](project-research.skill)** — End-to-end skill for going from "I have an idea" to a validated, actionable plan. Runs a thorough idea interview, orchestrates multi-agent domain research, then produces an implementation plan with go/no-go checkpoints between each phase.

- **[Project Scaffold Skill](project-scaffold.skill)** — Generates a complete AI tooling scaffold from a plan doc or description. Creates CLAUDE.md, hooks, MCP configs, Cursor rules, agent team definitions, and dev workflow skills — all tailored to your stack. Use after the research skill produces a plan.

### Example: Agentic Research App (Learn All AI-Native Patterns)

- **[Agentic Research App](agentic-research-app/)** — A fully scaffolded CLI-based AI research agent built with Python + Claude SDK + ChromaDB. Produced by running the project-research skill (idea → research → plan) followed by the project-scaffold skill. Exercises all 6 key AI-native patterns in one project: tool calling, RAG, ReAct, structured outputs, streaming, and evals. Targets finance research as the first vertical, repurposable to real estate and AI dev. Includes [project brief](docs/PROJECT-BRIEF.md), [competitive research](docs/research/agentic-research-app/SYNTHESIS.md), [implementation plan](docs/plan/PLAN.md) (revised after architecture + future-proofing review), and complete dev tooling scaffold.

### Knowledge Base Maintenance

- **[Daily Briefing Skill](daily-briefing.skill)** — Generates daily AI dev briefings by scanning for news across tools, security advisories, benchmarks, and ecosystem shifts. Produces structured briefings in `DailyBriefing/` and automatically cross-references findings against existing knowledge base entries, updating topic files when guidance materially changes. Use daily or whenever you want to catch up on what's new.

- **[Knowledge Review Skill](knowledge-review.skill)** — Systematic 5-phase quality audit of the entire knowledge base: structural integrity, content freshness, source integrity, cross-document consistency, and gap analysis. Produces an actionable review report and optionally fixes issues found. Run every 2 weeks or after bulk additions to catch staleness, broken links, unsourced claims, and contradictions.

- **[Topic Deep Dive Skill](topic-deep-dive.skill)** — Research and write a new comprehensive topic guide following the knowledge base's quality standards. Includes mandatory duplicate checking against INDEX.md, structured 4-step research process with source triangulation, two user checkpoints (scope approval + research review), and automatic integration (INDEX.md, GETTING-STARTED.md, cross-references). Use whenever a new topic needs covering — whether identified by the knowledge-review skill, a daily briefing finding, or a direct request.

### Error Recovery & Production Resilience

- **[Error Recovery & Fallback Patterns](docs/topics/error-recovery-patterns.md)** — What to do when your AI features fail in production. Covers: model API failures (timeouts, rate limits, 5xx), cascading fallback chains (Opus → Sonnet → Haiku), circuit breaker patterns for agents, retry with exponential backoff, token limit recovery, agent failure modes (infinite loops, stuck agents, hallucinated tools), graceful degradation (cached/stale responses, non-AI fallbacks), and production monitoring (error budgets, SLOs for non-deterministic systems). Includes Python/TypeScript code examples and a decision tree. Start here before shipping any AI feature to production.

### When NOT to Use AI

- **[When NOT to Use AI](docs/topics/when-not-to-use-ai.md)** — The critical counterbalance to everything else in this knowledge base. Identifies where traditional code, domain expertise, or formal methods beat AI: deterministic computations, security-critical paths, regulatory compliance, safety-critical systems. Includes a decision framework flowchart, red flags for AI misuse, the "good enough" trap, and cost-benefit reality checks. Read this to avoid force-fitting AI where it doesn't belong.

### CI/CD Integration Safety

- **[CI/CD AI Integration Safety](docs/topics/cicd-ai-integration-safety.md)** — How to safely add AI steps to existing CI/CD pipelines without breaking tests or introducing flaky builds. Covers safe entry points, flaky test prevention, cost control per pipeline run, rollback gates, security scanning, and complete GitHub Actions/GitLab CI examples. Start here if your team is hesitant to automate AI in CI.

### Evaluation Beyond LLM-as-Judge

- **[Evaluation Beyond LLM-as-Judge](docs/topics/evaluation-beyond-llm-judge.md)** — The full evaluation toolkit: statistical significance for small samples, domain-expert rubrics, automated metrics (pass@k, BERTScore), non-deterministic output testing, A/B testing for AI features, composite evaluation pipelines. Includes sample size tables and Python code. Start here if you need rigorous evaluation beyond "ask an LLM if the output is good."

### RAG Knowledge Management

- **[RAG Staleness Detection](docs/topics/rag-staleness-detection.md)** — How to detect when your RAG knowledge base is serving outdated information. Covers freshness scoring, embedding drift detection, knowledge versioning, automated refresh pipelines, and monitoring. Start here if you have a RAG system in production.

### Surviving the AI Adoption Valley

- **[The Death Valley of AI Integration](docs/topics/ai-integration-death-valley.md)** — The painful middle phase between "AI demos work great" and "AI delivers consistent value." Covers why productivity temporarily drops, typical timelines (4-40 weeks), warning signs, survival strategies, when to abandon, and what the other side looks like. Read this before your team loses faith.

### Resolving Conflicting Advice

- **[Unified Decision Trees](docs/topics/decision-trees.md)** — When different guides in this knowledge base give seemingly conflicting advice, this doc resolves it. Covers: when to use agents vs. simple functions, the correct optimization sequence, how three different caching mechanisms relate, and evaluation threshold statistical significance. Start here if you're confused by contradictions across guides.

### Example Projects (Built with the Research Skill)

- **[Fishing Copilot](examples/fishing-copilot/)** — AI-powered daily fishing briefing app. Python pipeline that scrapes state fish & game reports, pulls weather/water data, synthesizes through Claude Haiku, and delivers via SMS. Full project-research pipeline output: brief, competitive research, implementation plan with data model and API details.

- **[Life Assistant (LifeOS)](examples/life-assistant/)** — Modular AI life assistant with plug-and-play domain modules for career coaching, personal finance, fitness, and hobbies. MCP server per domain, Next.js + Vercel AI SDK, 3-tier memory, cross-domain intelligence. Full project-research pipeline output: 3-round interview brief, 4-domain competitive analysis, architecture research, GO recommendation, phased implementation plan.

### Full Research

- **[Research Synthesis](docs/research/SYNTHESIS.md)** — The master document: 12 key insights, framework comparisons, opportunity rankings, risk analysis, and concrete recommendations. Start here for the full picture.

- **[Knowledge Base Review](docs/research/REVIEW-2026-03-19.md)** — Full audit of the knowledge base: unsourced claims, contradictions, overconfident recommendations, missing topics, structural issues. All 7 recommended actions have been completed.

---

## Quick Start Checklist

1. Read the [Tool Comparison](docs/topics/tool-comparison-when-to-use.md) to pick your primary workflow
2. Set up Tier 1 tools from the [Best of Breed Directory](docs/topics/best-of-breed-directory.md)
3. Skim your tool's power user guide ([Claude](docs/topics/claude-code-power-user.md) / [Cursor](docs/topics/cursor-power-user.md) / [Gemini](docs/topics/gemini-dev-power-user.md))
4. Adopt the plan → test → implement → verify loop
5. Before your next build, use the [Research Strategies](docs/topics/ai-research-strategies.md) to scope what exists first
