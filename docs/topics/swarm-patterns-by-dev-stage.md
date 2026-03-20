# Multi-Agent & Swarm Patterns by Development Stage

**Research Date:** March 18, 2026
**Audience:** Developers building applications with multi-agent orchestration
**Scope:** Production-ready patterns for each development stage with implementation guides

---

## Executive Summary

Multi-agent systems are no longer experimental—they're the foundation of 2026 development workflows. The key insight: **not all stages benefit from the same orchestration pattern**.

> **Important caveat:** Not every stage requires multi-agent orchestration. For simple, well-defined tasks, a single agent or direct function call is more cost-effective and reliable. Use this guide when your task complexity justifies the overhead. See [Decision Trees](decision-trees.md) for when to use agents vs. simpler approaches.

- **Research & Discovery** → Orchestrator-Worker swarm (parallel researchers)
- **Architecture & Planning** → Debate/Consensus (adversarial refinement)
- **Implementation** → Hierarchical with parallel coding agents (director + workers)
- **Testing** → Specialist swarm (unit/integration/e2e agents in parallel)
- **Code Review** → Adversarial mesh (reviewer ≠ coder)
- **Debugging** → Hypothesis-generating swarm (competing theories)
- **Documentation** → Verifier mesh (generator + accuracy checker)
- **Deployment** → Validation pipeline (security + config + dependency checks)
- **Maintenance** → Hierarchical with analysis agents

This guide covers each stage with: **What it needs → Best pattern → Team composition → Implementation → Example workflow → Anti-patterns**.

---

## Part I: Orchestration Patterns Reference

### Pattern Comparison Matrix

| Pattern | Complexity | Resilience | Cost | Latency | When to Use | When NOT to Use |
|---------|-----------|-----------|------|---------|------------|-----------------|
| **Sequential Pipeline** | ⭐ Very Low | ⭐ Low | ⭐ Cheap | 🐢 Slowest | Clear dependencies, linear flow | Parallel work, high resilience |
| **Parallel Fan-Out/Fan-In** | ⭐⭐ Low | ⭐⭐ Medium | ⭐⭐ Moderate | ⚡ Fast | Multiple perspectives, diversity | Heavy coordination, single agent better |
| **Hierarchical (Director-Worker)** | ⭐⭐⭐ Medium | ⭐⭐ Medium | ⭐⭐⭐ Moderate | ⚡ Medium | Complex decomposition, scaling | Simple tasks, small teams |
| **Debate/Consensus** | ⭐⭐⭐ Medium | ⭐⭐⭐ High | ⭐⭐⭐⭐ Expensive (2-3x) | 🐢 Slow | High-stakes decisions, error detection | Quick iterations, cost-sensitive |
| **Adversarial (Red Team vs Blue)** | ⭐⭐⭐⭐ High | ⭐⭐⭐ High | ⭐⭐⭐⭐ Very Expensive (3x) | 🐢 Very Slow | Security review, robustness testing | Normal development, budgets tight |
| **Swarm (Decentralized)** | ⭐⭐⭐⭐ Very High | ⭐⭐⭐⭐ Excellent | ⭐⭐⭐ Moderate | ⚡ Variable | Emergent coordination, no SPOF | Debugging, predictability required |
| **Mesh (Peer-to-Peer)** | ⭐⭐⭐⭐ Very High | ⭐⭐⭐⭐ Excellent | ⭐⭐ Cheap | ⚡ Variable | Agents with equal authority | Central coordination needed |

### Detailed Pattern Descriptions

#### Sequential Pipeline
Linear progression through specialized agents, each stage feeding into the next.

```
Input → Agent1 → Agent2 → Agent3 → Output
```

**Best for:** Code generation (write → test → review → deploy)
**Pros:** Simple to understand, easy to debug, deterministic
**Cons:** Slower agents block the pipeline, no parallelism
**Implementation:** LangGraph `add_edge()` or CrewAI sequential tasks
**Token Cost:** 1x baseline per stage

#### Parallel Fan-Out/Fan-In
Multiple agents work on the same input simultaneously, results aggregated.

```
        ↙ Agent1 ↖
Input →  Agent2 → Aggregator → Output
        ↘ Agent3 ↗
```

**Best for:** Code review (security + performance + style agents), brainstorming
**Pros:** Fast (max N-fold speedup), diverse perspectives, resilient
**Cons:** Aggregation complexity, requires consensus logic
**Implementation:** LangGraph `send()` with fan-out or CrewAI parallel crews
**Token Cost:** 1.5-2x baseline (N agents + 1 aggregation)

#### Hierarchical (Director-Worker)
Coordinator plans and distributes work to specialist agents.

```
Input → Director (plan) → Worker1 ┐
                     ├→ Worker2 ├→ Aggregator → Output
                     └→ Worker3 ┘
```

**Best for:** Complex problem decomposition, AgentCoder pattern
**Pros:** Scales well (director plans, workers execute), central coordination
**Cons:** Planner-coder gap (7.9-83.3% robustness loss on input variance), communication overhead
**Implementation:** LangGraph with explicit planning node or CrewAI hierarchical
**Token Cost:** 1.5-2x baseline (plan call + worker calls)
**⚠️ Critical Risk:** Validate robustness with semantically-equivalent test inputs before production.

#### Debate/Consensus
Agents argue for different positions, judge synthesizes.

```
Pro-Agent → Judge → Con-Agent → Judge → ... → Final Consensus
```

**Best for:** Architecture decisions, high-stakes validation, error detection
**Pros:** Catches errors through argumentation, high robustness
**Cons:** 2-3x token cost, slow (sequential rounds), may not converge
**Implementation:** AG2 GroupChat with debate or custom LangGraph debate loop
**Token Cost:** 2-3x baseline (multiple agents + judge reasoning)
**When to Converge:** After 3-5 rounds or no new arguments after 2 rounds

#### Adversarial (Red Team vs Blue)
Code agent has no knowledge of what verification agent checks. Verification agent can't modify code.

```
Coder (Blue) → Code
             ↓
            Reviewer (Red) [no info about coder intent]
             ↓
            Test Results → Loop back if issues found
```

**Best for:** Security-critical code, robustness validation
**Pros:** Catches non-obvious vulnerabilities, high assurance
**Cons:** 3x token cost, slow, requires independent agents
**Implementation:** Separate sessions/agents with no shared context
**Token Cost:** 3x baseline (coder + independent reviewer + aggregation)

#### Swarm (Decentralized)
Agents coordinate via shared state/signals without central orchestrator.

```
Agent1 ↔ Agent2
 ↕       ↕
Agent3 ↔ Agent4
```

**Best for:** Supply chain logistics, emergent coordination, high resilience
**Pros:** No single point of failure, adapts dynamically
**Cons:** Hard to debug, unpredictable behavior, expensive (10x+ token cost if over-communicate)
**Implementation:** AG2 swarms, Swarms framework, custom peer-to-peer
**Token Cost:** 1x-10x (highly variable depending on coordination overhead)

---

## Part II: Development Stage Patterns

### Stage 1: Research & Discovery

#### What This Stage Needs
- Gather competitive landscape, technical requirements, design patterns
- Discover unknowns, identify assumptions to validate
- Synthesize information from multiple sources
- Speed matters (weeks, not months)

#### Best Swarm Pattern
**Orchestrator-Worker** (lead researcher + parallel specialists)

The lead agent plans research strategy. Specialist agents work in parallel: domain researcher, competitive landscape researcher, technical patterns researcher, market researcher.

#### Agent Team Composition

| Agent | Role | Inputs | Outputs |
|-------|------|--------|---------|
| **Lead Researcher** | Plan research strategy, synthesize findings | Initial research question | Research plan, final synthesis |
| **Domain Researcher** | Deep dive into domain knowledge, competitors | Research brief | Domain overview, competitor matrix |
| **Landscape Researcher** | Market, tools, frameworks, technologies | Tech area | Tool matrix, adoption trends, gaps |
| **Technical Researcher** | Architecture patterns, best practices, code | Design question | Pattern examples, anti-patterns, code links |
| **Synthesis Agent** | Verify claims, consolidate, structure findings | All researcher outputs | Final report with sources |

#### How to Implement It

##### With Claude Code Agent Teams

```bash
claude --agent-teams
# Create team with: lead-researcher, domain-specialist, landscape-analyst, technical-architect
```

Configure in `.claude/agents/lead-researcher.md`:

```yaml
---
name: lead-researcher
description: Orchestrates research across multiple specialists. Plans strategy, delegates, synthesizes findings.
tools: Grep, Glob, Read, WebSearch
model: opus
memory: user
---

You are a research lead. Your job:
1. Read the research question
2. Create a 5-phase research plan (discovery → analysis → synthesis → validation → writeup)
3. Delegate to specialists (use @domain-specialist, @landscape-analyst, @technical-architect)
4. Gather their outputs
5. Synthesize into a structured report with verified sources

Always:
- Include source URLs in findings
- Flag unverified claims
- Cross-reference claims across specialists
- Create summary matrices/tables
```

##### With LangGraph

```python
from langgraph.graph import StateGraph, START, END
from langgraph.types import Command
from typing import TypedDict, Annotated
import operator

class ResearchState(TypedDict):
    question: str
    research_plan: str
    domain_findings: str
    landscape_findings: str
    technical_findings: str
    synthesis: str
    sources: list

def plan_research(state: ResearchState) -> Command[ResearchState]:
    """Lead agent creates plan, dispatches to specialists"""
    plan = f"Research plan for: {state['question']}"
    return Command(
        update={"research_plan": plan},
        goto=["domain_research", "landscape_research", "technical_research"]
    )

def domain_research(state: ResearchState) -> ResearchState:
    """Specialist: domain knowledge"""
    # Use Claude with domain tools
    return {"domain_findings": "Domain overview..."}

def landscape_research(state: ResearchState) -> ResearchState:
    """Specialist: competitive landscape"""
    # Use Claude with web search tools
    return {"landscape_findings": "Market overview..."}

def technical_research(state: ResearchState) -> ResearchState:
    """Specialist: architecture patterns"""
    # Use Claude with code search tools
    return {"technical_findings": "Pattern analysis..."}

def synthesize(state: ResearchState) -> ResearchState:
    """Combine all findings, verify sources"""
    synthesis = f"""
    ## Research Synthesis: {state['question']}

    ### Domain
    {state['domain_findings']}

    ### Landscape
    {state['landscape_findings']}

    ### Technical
    {state['technical_findings']}
    """
    return {"synthesis": synthesis}

# Build graph
builder = StateGraph(ResearchState)
builder.add_node("plan", plan_research)
builder.add_node("domain", domain_research)
builder.add_node("landscape", landscape_research)
builder.add_node("technical", technical_research)
builder.add_node("synthesize", synthesize)

builder.add_edge(START, "plan")
builder.add_edge(["domain", "landscape", "technical"], "synthesize")
builder.add_edge("synthesize", END)

graph = builder.compile()

# Run
result = graph.invoke({
    "question": "How should we architect a real-time collaboration system?"
})
print(result["synthesis"])
```

##### With CrewAI

```python
from crewai import Agent, Crew, Task

domain_agent = Agent(
    role="Domain Researcher",
    goal="Understand competitive landscape and domain patterns",
    tools=[web_search_tool, code_search_tool],
    model="claude-opus"
)

landscape_agent = Agent(
    role="Market & Tech Landscape Analyst",
    goal="Identify tools, frameworks, and market trends",
    tools=[web_search_tool],
    model="claude-opus"
)

technical_agent = Agent(
    role="Technical Architecture Researcher",
    goal="Find design patterns, best practices, code examples",
    tools=[github_search_tool, code_analysis_tool],
    model="claude-opus"
)

lead_agent = Agent(
    role="Research Lead",
    goal="Orchestrate research and synthesize findings",
    tools=[],
    model="claude-opus"
)

# Tasks
domain_task = Task(
    description="Research the domain: competitors, existing solutions, pain points",
    agent=domain_agent,
    expected_output="Markdown report with competitor matrix and domain overview"
)

landscape_task = Task(
    description="Analyze tech landscape: frameworks, tools, adoption trends",
    agent=landscape_agent,
    expected_output="Markdown report with tool matrix and trend analysis"
)

technical_task = Task(
    description="Research architecture patterns and best practices",
    agent=technical_agent,
    expected_output="Markdown report with pattern examples and code links"
)

synthesis_task = Task(
    description="Synthesize all research into a coherent report",
    agent=lead_agent,
    expected_output="Comprehensive markdown research report with sources and recommendations"
)

crew = Crew(
    agents=[domain_agent, landscape_agent, technical_agent, lead_agent],
    tasks=[domain_task, landscape_task, technical_task, synthesis_task],
    process=Process.hierarchical,
    manager_agent=lead_agent
)

result = crew.kickoff()
print(result)
```

#### Example Workflow

**Session 1 (Your work - create research brief):**
```
Write RESEARCH_BRIEF.md with:
1. Question: "Best architecture for a real-time collaboration system?"
2. Success criteria: Competitive matrix, design patterns, cost/performance tradeoffs
3. Scope: 1 week research, max $100 in API costs
```

**Session 2 (Agent teams - parallel research):**
```
claude --agent-teams
# Lead agent reads brief, creates plan
# Specialists work in parallel:
#   - Domain: Figma, Linear, Notion, Google Docs (real-time collab tools)
#   - Landscape: Frameworks (Yjs, OT, CRDT), deployment options
#   - Technical: WebSocket patterns, database strategies, consistency models

# Each specialist generates 500-1000 word report with sources
# Lead synthesizes into RESEARCH_OUTPUT.md with decision matrix
```

**Session 3 (Your review):**
```
Review RESEARCH_OUTPUT.md
Validate key claims (lead agent points to sources)
Extract decisions for architecture design phase
```

#### Anti-Patterns

❌ **Too many specialists (8+)** → Coordination overhead explodes, synthesis becomes hard
❌ **Researchers with no time constraints** → Endless exploration, never reaches synthesis
❌ **Missing source validation** → Hallucinated frameworks and non-existent tools
❌ **Siloed specialists (no feedback)** → Each researcher reinvents context instead of building on others

---

### Stage 2: Planning & Architecture

#### What This Stage Needs
- Multiple design approaches evaluated
- Tradeoffs articulated (cost vs. scalability, simplicity vs. features)
- Architectural risks identified and addressed
- Consensus on design before coding starts

#### Best Swarm Pattern
**Debate/Consensus** (Pro vs. Con agents with Judge synthesizing)

Architects propose solutions. Opponents challenge. Judge breaks ties. Forces rigorous thinking before code.

#### Agent Team Composition

| Agent | Role | Expertise | Decision Authority |
|-------|------|-----------|-------------------|
| **Architect** | Proposes design, defends tradeoffs | System design, patterns | Proposer |
| **Devil's Advocate** | Challenges assumptions, finds risks | Edge cases, failure modes | Critic |
| **Cost Analyst** | Questions budget impact | Infrastructure, scaling costs | Validator |
| **Judge** | Evaluates arguments, synthesizes | Architecture principles | Final decision maker |

#### How to Implement It

##### With AG2 GroupChat Debate

```python
from ag2 import AssistantAgent, UserProxyAgent, GroupChat, GroupChatManager

architect = AssistantAgent(
    name="Architect",
    system_message="""You propose system architectures. Your role:
1. Design a system that solves the problem
2. Explain tradeoffs (cost, complexity, scalability)
3. Defend your design against criticism
4. Adapt based on feedback""",
    model_client=ModelClient(model="claude-opus")
)

devil = AssistantAgent(
    name="Devil's Advocate",
    system_message="""You challenge architecture proposals. Your role:
1. Identify assumptions in the proposal
2. Ask "what if" scenarios (failures, scale)
3. Propose counter-designs
4. Force rigor in thinking
5. Don't be diplomatic—be tough""",
    model_client=ModelClient(model="claude-opus")
)

cost_analyst = AssistantAgent(
    name="Cost Analyst",
    system_message="""You evaluate infrastructure costs. Your role:
1. Estimate AWS/GCP/compute costs at 100K, 1M, 10M users
2. Identify cost-drivers
3. Suggest cheaper alternatives
4. Call out overengineering""",
    model_client=ModelClient(model="claude-opus")
)

judge = AssistantAgent(
    name="Judge",
    system_message="""You synthesize debate and recommend final design. Your role:
1. Listen to all arguments
2. Identify which tradeoffs matter most
3. Make a recommendation
4. Explain reasoning""",
    model_client=ModelClient(model="claude-opus")
)

groupchat = GroupChat(
    agents=[architect, devil, cost_analyst, judge],
    messages=[],
    max_round=5,
    selector_method="auto"
)

manager = GroupChatManager(groupchat=groupchat)

initial_prompt = """
Design a real-time collaboration system for 100K concurrent users.
Requirements:
- Sub-second latency
- Strong consistency
- Cost-efficient

Architect: propose a design.
Devil's Advocate: challenge it.
Cost Analyst: evaluate costs.
Judge: synthesize and recommend.
"""

response = manager.initiate_chat(
    recipient=judge,
    message=initial_prompt,
    max_turns=10
)
```

##### With LangGraph Debate Loop

```python
from langgraph.graph import StateGraph, START, END
from langgraph.types import Command
from typing import TypedDict

class DebateState(TypedDict):
    design_question: str
    pro_argument: str
    con_argument: str
    cost_analysis: str
    judge_response: str
    round: int
    converged: bool

def architect_proposes(state: DebateState) -> DebateState:
    """Architect proposes a design"""
    pro = "Proposal: Microservices with event sourcing..."
    return {"pro_argument": pro}

def devil_challenges(state: DebateState) -> DebateState:
    """Devil's advocate challenges"""
    con = "Counter: This is overengineered. Single monolith with..."
    return {"con_argument": con}

def analyst_evaluates(state: DebateState) -> DebateState:
    """Cost analyst evaluates both approaches"""
    analysis = "Cost at 100K users: Approach A = $50K/mo, Approach B = $5K/mo..."
    return {"cost_analysis": analysis}

def judge_decides(state: DebateState) -> DebateState:
    """Judge synthesizes and decides"""
    if state["round"] >= 3:
        converged = True
    else:
        converged = False

    judgment = """Recommendation: Hybrid approach.
    - Start with monolith (lower cost, faster time-to-market)
    - Plan event sourcing for future scaling
    """
    return {
        "judge_response": judgment,
        "converged": converged,
        "round": state["round"] + 1
    }

# Build graph
builder = StateGraph(DebateState)
builder.add_node("pro", architect_proposes)
builder.add_node("con", devil_challenges)
builder.add_node("cost", analyst_evaluates)
builder.add_node("judge", judge_decides)

builder.add_edge(START, "pro")
builder.add_edge("pro", "con")
builder.add_edge("con", "cost")
builder.add_edge("cost", "judge")

# Loop back if not converged
def should_loop(state: DebateState) -> str:
    if state["converged"]:
        return "END"
    else:
        return "pro"

builder.add_conditional_edges("judge", should_loop, {"END": END})

graph = builder.compile()

result = graph.invoke({
    "design_question": "Microservices or monolith?",
    "pro_argument": "",
    "con_argument": "",
    "cost_analysis": "",
    "judge_response": "",
    "round": 0,
    "converged": False
})

print(f"Final decision: {result['judge_response']}")
```

##### With CrewAI Debate

```python
from crewai import Agent, Crew, Task, Process

architect = Agent(
    role="Systems Architect",
    goal="Propose a system design that solves the problem elegantly",
    model="claude-opus"
)

devil = Agent(
    role="Devil's Advocate",
    goal="Challenge the design, find flaws, propose alternatives",
    model="claude-opus"
)

cost_analyst = Agent(
    role="Cost Analyst",
    goal="Evaluate infrastructure costs of proposed designs",
    model="claude-opus"
)

judge = Agent(
    role="Judge",
    goal="Synthesize debate and recommend final design",
    model="claude-opus"
)

tasks = [
    Task(
        description="""Propose a design for: {design_question}
        Include: architecture diagram, component descriptions, key tradeoffs""",
        agent=architect,
        expected_output="Detailed architecture proposal"
    ),
    Task(
        description="Challenge the architect's proposal. Find flaws, edge cases, overengineering.",
        agent=devil,
        expected_output="Critique with alternative approaches",
        depends_on=[tasks[0]]
    ),
    Task(
        description="Evaluate costs of both approaches at 100K, 1M, 10M users",
        agent=cost_analyst,
        expected_output="Cost analysis with recommendations",
        depends_on=[tasks[0], tasks[1]]
    ),
    Task(
        description="Synthesize the debate and recommend final design",
        agent=judge,
        expected_output="Final recommendation with rationale",
        depends_on=[tasks[2]]
    )
]

crew = Crew(
    agents=[architect, devil, cost_analyst, judge],
    tasks=tasks,
    process=Process.sequential,
    manager_agent=judge
)

result = crew.kickoff(inputs={
    "design_question": "Real-time collaboration system for 100K users"
})
print(result)
```

#### Example Workflow

```
Session 1 (You): Create DESIGN_BRIEF.md
- Problem statement
- Success criteria
- Constraints (timeline, budget, team size)

Session 2 (Agent debate):
- Claude starts as Architect: "I propose microservices with Kubernetes..."
- You (as Devil): "That's overengineered. What if we start simple?"
- Claude (as Devil): "Right, here are the risks..."
- Claude (as Cost): "At 100K users, that's $50K/month..."
- Claude (as Judge): "Recommendation: Hybrid approach..."

Session 3 (You): Review recommendation
- Ask clarifying questions
- Get cost breakdown
- Make final decision
- Document in ARCHITECTURE_DECISION_RECORD.md
```

#### Anti-Patterns

❌ **Single architect deciding alone** → Misses edge cases
❌ **Debate without decision gate** → Endless argument, no closure
❌ **No cost input** → Designs are architecturally pure but financially impossible
❌ **Judge who hasn't heard both sides** → Synthesizes without understanding tradeoffs

---

### Stage 3: Implementation / Coding

#### What This Stage Needs
- Parallel code generation without merge conflicts
- Fast feedback (tests run after each change)
- Quality gates (review before merge)
- TDD discipline (tests written first)

#### Best Swarm Pattern
**Hierarchical Director-Worker + Parallel Implementation**

A director breaks the implementation into tasks. Multiple coders work in parallel on different modules. A reviewer validates each piece. Tasks are coordinated to prevent conflicts.

#### Agent Team Composition

| Agent | Role | Responsibilities |
|-------|------|------------------|
| **Director** | Decomposes work, assigns tasks, coordinates | Plan implementation, task assignment, merge decisions |
| **Coder-A** | Implements features, writes code | Code generation, immediate testing |
| **Coder-B** | Implements features, writes code | Code generation, immediate testing |
| **Test Agent** | Generates tests, validates quality | TDD (tests first), coverage checking |
| **Reviewer** | Reviews for quality, security, style | Code review, security audit |

**Key Constraint:** Each coder works on disjoint modules to avoid merge conflicts.

#### How to Implement It

##### With Claude Code Agent Teams

```bash
# Start team session
claude --agent-teams

# Define agents:
# - director: Plans work breakdown, assigns tasks
# - coder-a: Implements module A
# - coder-b: Implements module B
# - tester: Writes tests for all modules
# - reviewer: Reviews code for quality
```

Create `.claude/agents/director.md`:

```yaml
---
name: director
description: Orchestrates parallel coding. Breaks tasks, assigns to coders, coordinates merging.
tools: Read, Glob, Bash, Edit
model: opus
---

You are the project director. Your role:
1. Read the spec in TASKS.md
2. Decompose into disjoint tasks (no module overlap)
3. Assign Task 1 to @coder-a, Task 2 to @coder-b
4. Monitor progress
5. When both coders report "Ready for review", coordinate merge
6. Send code to @reviewer for quality gates

Always:
- Ensure no two coders modify the same file
- Check that tests pass before merging
- Have reviewers validate before final commit
```

Create `.claude/agents/coder-a.md`:

```yaml
---
name: coder-a
description: Implements assigned features. TDD-first: tests then code.
tools: Read, Glob, Edit, Bash
model: opus
---

You implement Task 1 (assigned by director):
1. Read spec in TASKS.md
2. Write FAILING test first (jest/pytest/mocha)
3. Run test, confirm failure
4. Implement code to pass test
5. Run full test suite
6. Report "Ready for review" to director
```

##### With LangGraph Hierarchical + Parallel

```python
from langgraph.graph import StateGraph, START, END
from langgraph.types import Command
from typing import TypedDict, Annotated
import operator

class ImplementationState(TypedDict):
    tasks: Annotated[list, operator.add]  # Accumulate tasks
    task_1_status: str
    task_2_status: str
    test_results: str
    review_results: str
    merge_ready: bool

def director_decomposes(state: ImplementationState) -> Command[ImplementationState]:
    """Director reads spec, decomposes into parallel tasks"""
    tasks = [
        {"id": 1, "title": "Auth module", "files": ["src/auth.ts"], "tests": "src/auth.test.ts"},
        {"id": 2, "title": "API routes", "files": ["src/routes.ts"], "tests": "src/routes.test.ts"}
    ]
    return Command(
        update={"tasks": tasks},
        goto=["coder_1", "coder_2"]  # Both run in parallel
    )

def coder_1(state: ImplementationState) -> ImplementationState:
    """Implement Task 1"""
    # Claude writes failing test, then implementation
    return {"task_1_status": "Complete"}

def coder_2(state: ImplementationState) -> ImplementationState:
    """Implement Task 2"""
    # Claude writes failing test, then implementation
    return {"task_2_status": "Complete"}

def tester(state: ImplementationState) -> ImplementationState:
    """Run full test suite"""
    # bash: npm test
    return {"test_results": "All tests passed. 85% coverage."}

def reviewer(state: ImplementationState) -> ImplementationState:
    """Review code for quality, security, style"""
    # Check both modules
    return {"review_results": "Code approved. Security audit passed."}

def merge_decision(state: ImplementationState) -> ImplementationState:
    """Decide if safe to merge"""
    if state["test_results"] and state["review_results"]:
        return {"merge_ready": True}
    else:
        return {"merge_ready": False}

# Build graph
builder = StateGraph(ImplementationState)
builder.add_node("director", director_decomposes)
builder.add_node("coder_1", coder_1)
builder.add_node("coder_2", coder_2)
builder.add_node("tester", tester)
builder.add_node("reviewer", reviewer)
builder.add_node("merge", merge_decision)

builder.add_edge(START, "director")
builder.add_edge(["coder_1", "coder_2"], "tester")  # Wait for both coders
builder.add_edge("tester", "reviewer")
builder.add_edge("reviewer", "merge")
builder.add_edge("merge", END)

graph = builder.compile()

result = graph.invoke({
    "tasks": [],
    "task_1_status": "",
    "task_2_status": "",
    "test_results": "",
    "review_results": "",
    "merge_ready": False
})
```

##### With CrewAI Hierarchical

```python
from crewai import Agent, Crew, Task, Process

director = Agent(
    role="Project Director",
    goal="Decompose work and coordinate parallel coding",
    model="claude-opus"
)

coder_a = Agent(
    role="Backend Developer",
    goal="Implement Task 1 (Authentication) with TDD",
    model="claude-opus"
)

coder_b = Agent(
    role="API Developer",
    goal="Implement Task 2 (REST API) with TDD",
    model="claude-opus"
)

tester = Agent(
    role="Test Engineer",
    goal="Generate tests and validate quality",
    model="claude-opus"
)

reviewer = Agent(
    role="Code Reviewer",
    goal="Review code for quality, security, style",
    model="claude-opus"
)

tasks = [
    Task(
        description="Read TASKS.md and decompose into 2 parallel tasks. Ensure no overlap.",
        agent=director,
        expected_output="Task breakdown with assignments"
    ),
    Task(
        description="Implement Task 1: Authentication module. Write tests FIRST.",
        agent=coder_a,
        expected_output="Code files with passing tests",
        depends_on=[tasks[0]]
    ),
    Task(
        description="Implement Task 2: REST API. Write tests FIRST.",
        agent=coder_b,
        expected_output="Code files with passing tests",
        depends_on=[tasks[0]]
    ),
    Task(
        description="Run full test suite. Check coverage >= 80%",
        agent=tester,
        expected_output="Test results and coverage report",
        depends_on=[tasks[1], tasks[2]]
    ),
    Task(
        description="Review both implementations. Check security, style, best practices.",
        agent=reviewer,
        expected_output="Code review with approval/concerns",
        depends_on=[tasks[3]]
    )
]

crew = Crew(
    agents=[director, coder_a, coder_b, tester, reviewer],
    tasks=tasks,
    process=Process.hierarchical,
    manager_agent=director
)

result = crew.kickoff()
print(result)
```

#### Example Workflow

```
TASKS.md (created upfront):
## Task 1: Authentication Module
Files: src/auth.ts, src/auth.test.ts
- Implement sign-in, sign-out, refresh token
- Tests: 5 test cases (valid, invalid, expired)

## Task 2: REST API Routes
Files: src/routes.ts, src/routes.test.ts
- Implement /users, /posts endpoints
- Tests: 8 test cases (CRUD, permissions)

Session 1: Director
- Reads TASKS.md
- Assigns Task 1 to Coder-A
- Assigns Task 2 to Coder-B
- Starts both in parallel

Session 2A (parallel): Coder-A
- Write failing tests for auth
- Run: `npm test` → fail
- Implement auth module
- Run: `npm test` → pass
- Report: "Ready for review"

Session 2B (parallel): Coder-B
- Write failing tests for routes
- Run: `npm test` → fail
- Implement routes
- Run: `npm test` → pass
- Report: "Ready for review"

Session 3: Test Agent
- Run: `npm test && npm run coverage`
- Output: "85% coverage, all tests pass"

Session 4: Reviewer
- Review src/auth.ts for quality
- Review src/routes.ts for security
- Check error handling
- Report: "Approved for merge"

Session 5: Director
- Merge both tasks into main
- Run final test suite
- Commit
```

#### File Organization (Prevent Merge Conflicts)

```
src/
├── auth/
│   ├── auth.ts          ← Coder-A only
│   ├── auth.test.ts
│   └── types.ts
├── api/
│   ├── routes.ts        ← Coder-B only
│   ├── routes.test.ts
│   └── handlers/
│       ├── users.ts
│       └── posts.ts
├── shared/
│   ├── types.ts         ← Shared (no writes, read-only)
│   └── utils.ts         ← Shared (no writes)
```

**Key rule:** Never have two coders write to the same file.

#### Anti-Patterns

❌ **Both coders modify same files** → Merge conflicts, coordination nightmare
❌ **No tests before implementation** → Bugs slip through
❌ **Review after merge** → Too late to catch issues
❌ **Director assigns overlapping tasks** → Conflict resolution becomes bottleneck
❌ **Ignoring planner-coder gap** → Test fragility when inputs change

---

### Stage 4: Testing & QA

#### What This Stage Needs
- Unit tests for all modules
- Integration tests for component interactions
- End-to-end tests for full workflows
- Performance and edge-case testing
- Security validation

#### Best Swarm Pattern
**Parallel Test Generation Swarm** (specialists work on different test types in parallel)

Unit tests, integration tests, e2e tests, security tests run independently. Results aggregated.

#### Agent Team Composition

| Agent | Focus | Outputs | Parallelizable |
|-------|-------|---------|-----------------|
| **Unit Test Agent** | Function-level tests | `src/**/*.test.ts` | Yes |
| **Integration Test Agent** | Component interaction tests | `tests/integration/` | Yes |
| **E2E Test Agent** | Full workflow tests | `tests/e2e/` | Yes |
| **Security Test Agent** | Vulnerability checks, injection tests | `tests/security/` | Yes |
| **Performance Test Agent** | Load, stress, latency tests | `tests/perf/` | Yes |
| **Coverage Agent** | Verify coverage >= threshold | Coverage report | Yes (read-only) |

#### How to Implement It

##### With LangGraph Parallel Fan-Out

```python
from langgraph.graph import StateGraph, START, END
from langgraph.types import Command
from typing import TypedDict

class TestState(TypedDict):
    unit_tests: str
    integration_tests: str
    e2e_tests: str
    security_tests: str
    perf_tests: str
    coverage_report: str
    all_passed: bool

def generate_unit_tests(state: TestState) -> TestState:
    """Generate unit tests for each module"""
    # Claude generates test cases for auth, api, utils, etc.
    return {
        "unit_tests": "Generated 42 unit tests (auth: 8, api: 15, utils: 19)"
    }

def generate_integration_tests(state: TestState) -> TestState:
    """Generate integration tests"""
    # Claude generates tests for module interactions
    return {
        "integration_tests": "Generated 12 integration tests"
    }

def generate_e2e_tests(state: TestState) -> TestState:
    """Generate end-to-end tests"""
    # Claude generates full-workflow tests
    return {
        "e2e_tests": "Generated 6 e2e tests (sign-up, sign-in, post flow)"
    }

def generate_security_tests(state: TestState) -> TestState:
    """Generate security tests"""
    # Claude generates injection, XSS, CSRF tests
    return {
        "security_tests": "Generated 15 security tests (SQL injection, XSS, CSRF, auth bypass)"
    }

def generate_perf_tests(state: TestState) -> TestState:
    """Generate performance tests"""
    # Claude generates load and stress tests
    return {
        "perf_tests": "Generated 8 performance tests (latency, throughput, stress)"
    }

def check_coverage(state: TestState) -> TestState:
    """Verify coverage meets threshold"""
    # Run: npm test && npm run coverage
    # Pass if >= 80%
    return {
        "coverage_report": "Coverage: 85% (exceeds 80% target)"
    }

def aggregate_results(state: TestState) -> TestState:
    """Check if all tests pass"""
    # bash: npm test
    passed = all([
        "passed" in state.get(k, "") or "Generated" in state.get(k, "")
        for k in ["unit_tests", "integration_tests", "e2e_tests", "security_tests", "perf_tests"]
    ])
    return {"all_passed": passed}

# Build graph
builder = StateGraph(TestState)
builder.add_node("unit", generate_unit_tests)
builder.add_node("integration", generate_integration_tests)
builder.add_node("e2e", generate_e2e_tests)
builder.add_node("security", generate_security_tests)
builder.add_node("perf", generate_perf_tests)
builder.add_node("coverage", check_coverage)
builder.add_node("aggregate", aggregate_results)

builder.add_edge(START, "unit")
builder.add_edge(START, "integration")
builder.add_edge(START, "e2e")
builder.add_edge(START, "security")
builder.add_edge(START, "perf")

# All converge before coverage check
builder.add_edge(["unit", "integration", "e2e", "security", "perf"], "coverage")
builder.add_edge("coverage", "aggregate")
builder.add_edge("aggregate", END)

graph = builder.compile()

result = graph.invoke({
    "unit_tests": "",
    "integration_tests": "",
    "e2e_tests": "",
    "security_tests": "",
    "perf_tests": "",
    "coverage_report": "",
    "all_passed": False
})

print(f"All tests passed: {result['all_passed']}")
print(f"Coverage: {result['coverage_report']}")
```

##### With CrewAI Parallel

```python
from crewai import Agent, Crew, Task, Process

unit_agent = Agent(
    role="Unit Test Engineer",
    goal="Generate comprehensive unit tests for all modules",
    model="claude-opus"
)

integration_agent = Agent(
    role="Integration Test Engineer",
    goal="Generate tests for component interactions",
    model="claude-opus"
)

e2e_agent = Agent(
    role="E2E Test Engineer",
    goal="Generate end-to-end workflow tests",
    model="claude-opus"
)

security_agent = Agent(
    role="Security Test Engineer",
    goal="Generate security and vulnerability tests",
    model="claude-opus"
)

perf_agent = Agent(
    role="Performance Test Engineer",
    goal="Generate load, stress, and latency tests",
    model="claude-opus"
)

coverage_agent = Agent(
    role="Coverage Analyzer",
    goal="Verify test coverage meets 80%+ threshold",
    model="claude-opus"
)

tasks = [
    Task(
        description="Generate unit tests for: auth module, api routes, utilities",
        agent=unit_agent,
        expected_output="Test file with passing unit tests"
    ),
    Task(
        description="Generate integration tests for module interactions",
        agent=integration_agent,
        expected_output="Integration test file"
    ),
    Task(
        description="Generate e2e tests for user workflows: sign-up, sign-in, post creation",
        agent=e2e_agent,
        expected_output="E2E test file"
    ),
    Task(
        description="Generate security tests: SQL injection, XSS, CSRF, auth bypass",
        agent=security_agent,
        expected_output="Security test file"
    ),
    Task(
        description="Generate performance tests: load test (100 concurrent users), stress test",
        agent=perf_agent,
        expected_output="Performance test file"
    ),
    Task(
        description="Run all tests and verify coverage >= 80%",
        agent=coverage_agent,
        expected_output="Coverage report and test results",
        depends_on=[tasks[0], tasks[1], tasks[2], tasks[3], tasks[4]]
    )
]

crew = Crew(
    agents=[unit_agent, integration_agent, e2e_agent, security_agent, perf_agent, coverage_agent],
    tasks=tasks,
    process=Process.parallel  # All run in parallel until coverage check
)

result = crew.kickoff()
print(result)
```

#### Example Workflow

```
Session 1: Parallel Test Generation
- Unit Agent generates: auth.test.ts (8 tests), routes.test.ts (15 tests), utils.test.ts (19 tests)
- Integration Agent generates: interaction tests (12 tests)
- E2E Agent generates: workflow tests (6 tests)
- Security Agent generates: vulnerability tests (15 tests)
- Performance Agent generates: load tests (8 tests)

All agents run in parallel. Latency = max(agent latencies), not sum.

Session 2: Aggregation
- Coverage Agent runs: npm test && npm coverage
- Output: "All 83 tests passed. Coverage: 85%"

Session 3: Review
- You review test quality and coverage
- Ask for edge cases or additional tests
- Agents refine tests
```

#### Anti-Patterns

❌ **Tests written after code** → Missing test discipline, low quality
❌ **No security tests** → Vulnerabilities slip to production
❌ **E2E tests flaky** → Developers ignore failures
❌ **Coverage theater** (high coverage, low quality) → False confidence
❌ **No performance tests** → Surprises at scale

---

### Stage 5: Code Review & Quality

#### What This Stage Needs
- Catch bugs, security issues, style violations
- Ensure consistency with team standards
- Provide constructive feedback
- No blocking review bottleneck (automated where possible)

#### Best Swarm Pattern
**Adversarial Mesh** (Multiple reviewers, each with different expertise, no knowledge of coder intent)

Each reviewer is independent. Security reviewer ≠ performance reviewer. Results aggregated. High confidence in quality.

#### Agent Team Composition

| Agent | Focus | Checks | Independence |
|-------|-------|--------|--------------|
| **Security Reviewer** | Auth, data handling, injection | SQL injection, XSS, CSRF, hardcoded secrets | Yes—no code context |
| **Performance Reviewer** | Algorithms, I/O, caching | O(n²) loops, N+1 queries, missing indexes | Yes—no code context |
| **Style Reviewer** | Consistency, readability | Naming, formatting, complexity | Yes—no code context |
| **Architecture Reviewer** | Design patterns, coupling | DRY, SOLID, abstraction levels | Yes—no code context |

**Key:** Each reviewer sees ONLY the code, not the developer's intent. This forces code to speak for itself.

#### How to Implement It

##### With Claude Code Subagents (Parallel Review)

```yaml
# Create .claude/agents/security-reviewer.md
---
name: security-reviewer
description: Reviews code for security vulnerabilities. Works independently (no context of intent).
tools: Read, Grep, Bash
model: sonnet
---

You are a security code reviewer. Your role:
1. Examine all code files (READ ONLY—no modifications)
2. Check for: SQL injection, XSS, CSRF, auth bypass, hardcoded secrets, unsafe deserialization
3. For each issue: file, line number, explanation, fix
4. Output: JSON with severity (critical/high/medium/low)

Never assume intent. Judge code only on what it does.

# Create .claude/agents/performance-reviewer.md
---
name: performance-reviewer
description: Reviews code for performance issues.
tools: Read, Grep, Bash
model: sonnet
---

You are a performance reviewer. Your role:
1. Scan code for: O(n²) algorithms, N+1 query patterns, missing indexes, excessive allocations
2. Profile if needed: benchmark critical paths
3. For each issue: impact (latency, throughput, cost), fix
4. Output: JSON with severity

# Create .claude/agents/style-reviewer.md
---
name: style-reviewer
description: Reviews code for style, readability, consistency.
tools: Read, Grep, Bash
model: sonnet
---

You are a style reviewer. Your role:
1. Check: naming conventions, line length, complexity, comments
2. Verify linter/formatter compliance
3. For each issue: explanation, fix
4. Output: JSON with severity

# Create .claude/agents/architecture-reviewer.md
---
name: architecture-reviewer
description: Reviews code for design patterns and coupling.
tools: Read, Grep, Bash
model: sonnet
---

You are an architecture reviewer. Your role:
1. Check: DRY (don't repeat yourself), SOLID principles, abstraction
2. Identify: tight coupling, circular dependencies, missing abstractions
3. For each issue: impact, refactor suggestion
4. Output: JSON with severity
```

Invoke parallel review:

```bash
claude
# Main session reads code, dispatches to reviewers in parallel
/code-review
# This triggers all reviewers automatically

# Outputs:
# - security-reviewer: [critical] SQL injection in line 42
# - performance-reviewer: [high] N+1 query in getUserPosts()
# - style-reviewer: [medium] Function too long (180 lines)
# - architecture-reviewer: [medium] Tight coupling between auth and db

# Aggregate: 1 critical, 1 high, 2 medium → Fix before merge
```

##### With LangGraph Adversarial Review

```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict, Annotated
import operator

class ReviewState(TypedDict):
    code_files: str
    security_issues: Annotated[list, operator.add]
    performance_issues: Annotated[list, operator.add]
    style_issues: Annotated[list, operator.add]
    architecture_issues: Annotated[list, operator.add]
    review_summary: str
    approved: bool

def security_review(state: ReviewState) -> ReviewState:
    """Independent security review"""
    issues = [
        {
            "file": "src/auth.ts",
            "line": 42,
            "severity": "critical",
            "issue": "SQL injection in login query",
            "fix": "Use parameterized queries"
        }
    ]
    return {"security_issues": issues}

def performance_review(state: ReviewState) -> ReviewState:
    """Independent performance review"""
    issues = [
        {
            "file": "src/api.ts",
            "line": 108,
            "severity": "high",
            "issue": "N+1 query: getUserPosts loops and queries DB per post",
            "fix": "Use JOIN or batch query"
        }
    ]
    return {"performance_issues": issues}

def style_review(state: ReviewState) -> ReviewState:
    """Independent style review"""
    issues = [
        {
            "file": "src/utils.ts",
            "line": 1,
            "severity": "low",
            "issue": "Function getUser() is 180 lines, too complex",
            "fix": "Break into smaller functions"
        }
    ]
    return {"style_issues": issues}

def architecture_review(state: ReviewState) -> ReviewState:
    """Independent architecture review"""
    issues = [
        {
            "file": "src/api.ts",
            "severity": "medium",
            "issue": "Auth and DB tightly coupled",
            "fix": "Extract auth logic to separate module"
        }
    ]
    return {"architecture_issues": issues}

def summarize_review(state: ReviewState) -> ReviewState:
    """Aggregate all reviews"""
    critical = len([x for x in state["security_issues"] if x.get("severity") == "critical"])
    high = len([x for x in state["performance_issues"] if x.get("severity") == "high"])
    medium = len([x for x in state["style_issues"] + state["architecture_issues"] if x.get("severity") == "medium"])

    approved = critical == 0 and high == 0

    summary = f"""
    Code Review Summary:
    - Critical issues: {critical} (must fix)
    - High issues: {high} (should fix)
    - Medium issues: {medium} (nice to fix)

    Status: {'APPROVED' if approved else 'NEEDS FIXES'}
    """

    return {"review_summary": summary, "approved": approved}

# Build graph
builder = StateGraph(ReviewState)
builder.add_node("security", security_review)
builder.add_node("performance", performance_review)
builder.add_node("style", style_review)
builder.add_node("architecture", architecture_review)
builder.add_node("summary", summarize_review)

builder.add_edge(START, ["security", "performance", "style", "architecture"])
builder.add_edge(["security", "performance", "style", "architecture"], "summary")
builder.add_edge("summary", END)

graph = builder.compile()

result = graph.invoke({
    "code_files": "[read from git]",
    "security_issues": [],
    "performance_issues": [],
    "style_issues": [],
    "architecture_issues": [],
    "review_summary": "",
    "approved": False
})

print(result["review_summary"])
if not result["approved"]:
    print("\nFix before merging:")
    for issue in result["security_issues"] + result["performance_issues"]:
        print(f"  - {issue['file']}:{issue['line']} - {issue['issue']}")
```

##### With CrewAI Review Crew

```python
from crewai import Agent, Crew, Task, Process

security_reviewer = Agent(
    role="Security Code Reviewer",
    goal="Find security vulnerabilities in code",
    model="claude-opus"
)

perf_reviewer = Agent(
    role="Performance Code Reviewer",
    goal="Identify performance bottlenecks",
    model="claude-opus"
)

style_reviewer = Agent(
    role="Code Style Reviewer",
    goal="Check for style, readability, consistency",
    model="claude-opus"
)

architecture_reviewer = Agent(
    role="Architecture Code Reviewer",
    goal="Verify SOLID principles and design patterns",
    model="claude-opus"
)

# All tasks are independent (can run in parallel)
tasks = [
    Task(
        description="Review for security: SQL injection, XSS, CSRF, auth bypass, hardcoded secrets",
        agent=security_reviewer,
        expected_output="JSON list of issues: {file, line, severity, issue, fix}"
    ),
    Task(
        description="Review for performance: N+1 queries, O(n²) loops, missing indexes",
        agent=perf_reviewer,
        expected_output="JSON list of issues: {file, line, severity, issue, fix}"
    ),
    Task(
        description="Review for style: naming, length, complexity, comments",
        agent=style_reviewer,
        expected_output="JSON list of issues: {file, line, severity, issue, fix}"
    ),
    Task(
        description="Review for architecture: DRY, SOLID, coupling, abstractions",
        agent=architecture_reviewer,
        expected_output="JSON list of issues: {file, severity, issue, fix}"
    )
]

crew = Crew(
    agents=[security_reviewer, perf_reviewer, style_reviewer, architecture_reviewer],
    tasks=tasks,
    process=Process.parallel  # All run in parallel
)

result = crew.kickoff()
print(result)
```

#### Example Workflow

```
Session 1: Create PR with code changes
- Push branch to GitHub
- Create PR
- Automated review starts

Session 2: Parallel Reviewers (automatic)
- Security Reviewer: Scans code (5 min)
- Performance Reviewer: Analyzes algorithms (5 min)
- Style Reviewer: Runs linter + checks (2 min)
- Architecture Reviewer: Checks design (5 min)

All run in parallel. Total time = max = ~5 min (not 17 min sequential).

Session 3: Results aggregated
- Summary: 1 critical (SQL injection), 1 high (N+1 query), 2 medium (style)
- Status: NEEDS FIXES

Session 4: Developer fixes
- You fix SQL injection and N+1 query
- Push follow-up commit

Session 5: Re-review (automated)
- Reviewers re-scan changes
- Summary: 0 critical, 0 high, 2 medium
- Status: APPROVED (critical/high fixed)

Session 6: Merge
```

#### Anti-Patterns

❌ **Single reviewer** → Misses issues, bottleneck
❌ **Reviewer knows developer intent** → Too lenient
❌ **Review after merge** → Takes longer to fix
❌ **No escalation for critical issues** → Unsafe code ships
❌ **Style reviewers stopping merges** → Blocks progress unnecessarily

---

### Stage 6: Debugging & Incident Response

#### What This Stage Needs
- Quickly identify root cause of production bugs
- Test multiple hypotheses simultaneously
- Investigate logs, code, config, dependencies
- Recover quickly with rollback or fix

#### Best Swarm Pattern
**Hypothesis-Generating Swarm** (Multiple agents propose theories, compete for evidence)

When production fails, don't investigate linearly. Spawn 3-4 agents with different hypotheses working in parallel.

#### Agent Team Composition

| Agent | Hypothesis | Investigates |
|-------|------------|--------------|
| **Logs Agent** | "It's a runtime error" | Logs, error messages, stack traces |
| **Code Agent** | "It's a code bug" | Recent commits, logic errors, race conditions |
| **Config Agent** | "It's a configuration issue" | Env vars, secrets, database connections |
| **Dependencies Agent** | "It's a dependency issue" | Package versions, breaking changes, CVEs |
| **Judge Agent** | Synthesize findings | All evidence, votes for root cause |

#### How to Implement It

##### With LangGraph Hypothesis Swarm

```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class DebugState(TypedDict):
    incident: str  # "Users seeing 500 errors on checkout"
    logs_findings: str
    code_findings: str
    config_findings: str
    deps_findings: str
    root_cause: str
    recommended_fix: str

def logs_investigator(state: DebugState) -> DebugState:
    """Investigate logs for the incident"""
    findings = """
    Found error in logs:
    ERROR: TypeError: Cannot read property 'price' of undefined
    Stack: checkout.ts:142 → stripe.ts:89
    Frequency: 100% of failed requests
    Timing: Started 2 hours ago (correlation: database migration)
    """
    return {"logs_findings": findings}

def code_investigator(state: DebugState) -> DebugState:
    """Investigate code for bugs"""
    findings = """
    Found issue in checkout.ts:
    - Line 142: const price = product.price
    - Product object missing 'price' field after DB migration
    - No null check before accessing price
    - Bug introduced in commit abc123 (2 hours ago)
    """
    return {"code_findings": findings}

def config_investigator(state: DebugState) -> DebugState:
    """Investigate config for issues"""
    findings = """
    Config investigation:
    - DATABASE_URL: correct
    - STRIPE_KEY: correct
    - ENABLE_NEW_PRICING: true (new feature flag)
    - But: Old code still uses old field names
    """
    return {"config_findings": findings}

def deps_investigator(state: DebugState) -> DebugState:
    """Investigate dependencies"""
    findings = """
    Dependency check:
    - No new package versions in last 24h
    - All CVEs clear
    - No breaking changes detected
    """
    return {"deps_findings": findings}

def judge_findings(state: DebugState) -> DebugState:
    """Synthesize findings and determine root cause"""
    root_cause = """
    ROOT CAUSE: Code bug + missing migration

    Timeline:
    1. Database migration renamed 'price' → 'unitPrice' (2 hours ago)
    2. Checkout code not updated (still uses product.price)
    3. product.price is undefined
    4. TypeError when calculating total

    This explains 100% of errors starting exactly 2 hours ago.
    """

    fix = """
    IMMEDIATE FIX (5 min):
    - Rollback database migration
    - Restore 'price' column
    - Service recovers

    OR FAST FIX (15 min):
    - Update checkout.ts to use unitPrice
    - Deploy hotfix
    - Service recovers

    RECOMMENDED: Rollback (safer, faster)
    """

    return {
        "root_cause": root_cause,
        "recommended_fix": fix
    }

# Build graph
builder = StateGraph(DebugState)
builder.add_node("logs", logs_investigator)
builder.add_node("code", code_investigator)
builder.add_node("config", config_investigator)
builder.add_node("deps", deps_investigator)
builder.add_node("judge", judge_findings)

builder.add_edge(START, ["logs", "code", "config", "deps"])
builder.add_edge(["logs", "code", "config", "deps"], "judge")
builder.add_edge("judge", END)

graph = builder.compile()

result = graph.invoke({
    "incident": "Users seeing 500 errors on checkout",
    "logs_findings": "",
    "code_findings": "",
    "config_findings": "",
    "deps_findings": "",
    "root_cause": "",
    "recommended_fix": ""
})

print(result["root_cause"])
print("\n" + result["recommended_fix"])
```

##### With CrewAI Debug Crew

```python
from crewai import Agent, Crew, Task, Process

logs_agent = Agent(
    role="Logs Investigator",
    goal="Find the incident in logs and error messages",
    model="claude-opus"
)

code_agent = Agent(
    role="Code Bug Hunter",
    goal="Find bugs in code that could cause the incident",
    model="claude-opus"
)

config_agent = Agent(
    role="Configuration Auditor",
    goal="Identify configuration issues",
    model="claude-opus"
)

deps_agent = Agent(
    role="Dependency Analyzer",
    goal="Check for dependency issues or breaking changes",
    model="claude-opus"
)

judge_agent = Agent(
    role="Root Cause Judge",
    goal="Synthesize findings and determine root cause",
    model="claude-opus"
)

tasks = [
    Task(
        description="Search production logs for errors related to: {incident}. Find stack traces, error messages, timing.",
        agent=logs_agent,
        expected_output="Findings from logs with evidence"
    ),
    Task(
        description="Review code for bugs that could cause: {incident}. Check recent commits, race conditions.",
        agent=code_agent,
        expected_output="Potential bugs with file/line numbers"
    ),
    Task(
        description="Audit configuration: environment variables, secrets, database connections",
        agent=config_agent,
        expected_output="Configuration issues found (or none)"
    ),
    Task(
        description="Check dependencies for breaking changes, CVEs, version conflicts",
        agent=deps_agent,
        expected_output="Dependency issues found (or none)"
    ),
    Task(
        description="""Synthesize all findings and determine root cause.
        Rank evidence by confidence. Recommend immediate fix.""",
        agent=judge_agent,
        expected_output="Root cause analysis + recommended fix + rollback/hotfix decision",
        depends_on=[tasks[0], tasks[1], tasks[2], tasks[3]]
    )
]

crew = Crew(
    agents=[logs_agent, code_agent, config_agent, deps_agent, judge_agent],
    tasks=tasks,
    process=Process.parallel
)

result = crew.kickoff(inputs={
    "incident": "Users seeing 500 errors on checkout"
})

print(result)
```

#### Example Workflow

```
Incident: "Checkout service returning 500 errors"

T+0 (Alert fires):
- Pagerduty wakes on-call engineer
- Engineer spawns debug swarm

T+3 (Parallel investigation):
- Logs agent scans: "TypeError at checkout.ts:142"
- Code agent reviews: "price field not updated after migration"
- Config agent checks: "All env vars correct"
- Deps agent validates: "No breaking changes"

T+5 (Results aggregated):
- Judge synthesizes: "Root cause = code bug + DB migration mismatch"
- Confidence: 95% (multiple confirming signals)
- Recommendation: "Rollback DB migration (5 min) or hotfix code (15 min)"

T+6 (Decision):
- Engineer chooses rollback (faster, safer)

T+11 (Recovery):
- Rollback completes
- Service stable
- Users see 0 errors
- Post-mortem scheduled

Total incident duration: 11 minutes (vs. 45+ if investigated sequentially)
```

#### Anti-Patterns

❌ **One engineer investigating linearly** → Takes 45+ minutes
❌ **No hypotheses generated** → Random exploration, miss obvious issues
❌ **Judge doesn't have all evidence** → Makes wrong decision
❌ **No rollback plan** → Stuck if hotfix fails

---

### Stage 7: Documentation & Knowledge

#### What This Stage Needs
- API documentation stays current with code
- README/architecture docs updated
- Examples and tutorials are accurate
- Knowledge is centralized and searchable

#### Best Swarm Pattern
**Generator + Verifier Mesh** (One agent generates docs, another verifies accuracy independently)

Documentation generator creates docs from code. Accuracy checker validates examples work and claims are true.

#### Agent Team Composition

| Agent | Role | Responsibilities |
|-------|------|------------------|
| **Doc Generator** | Creates docs from code | Read code, extract APIs, write docs |
| **Accuracy Checker** | Validates documentation | Run examples, verify claims, find mismatches |
| **Code Sync Agent** | Keeps docs in sync | Detect code changes, trigger doc updates |

#### How to Implement It

##### With DocAgent Pattern (Multi-Agent System)

```python
"""
DocAgent: Multi-agent documentation generation
Uses: Reader, Searcher, Writer, Verifier, Orchestrator
"""

from crewai import Agent, Crew, Task, Process

reader = Agent(
    role="API Reader",
    goal="Extract API signatures, types, return values from code",
    model="claude-opus"
)

searcher = Agent(
    role="Documentation Searcher",
    goal="Find existing docs, examples, related content",
    model="claude-opus"
)

writer = Agent(
    role="Documentation Writer",
    goal="Write clear, accurate documentation with examples",
    model="claude-opus"
)

verifier = Agent(
    role="Documentation Verifier",
    goal="Test examples, verify claims, find gaps",
    model="claude-opus"
)

orchestrator = Agent(
    role="Documentation Orchestrator",
    goal="Coordinate documentation generation and review",
    model="claude-opus"
)

tasks = [
    Task(
        description="Extract all public APIs from src/: function signatures, types, return values",
        agent=reader,
        expected_output="JSON: [{name, signature, description, params, returns}]"
    ),
    Task(
        description="Search for existing docs and examples",
        agent=searcher,
        expected_output="List of existing documentation and examples"
    ),
    Task(
        description="""Write comprehensive API documentation including:
        - Function description
        - Parameter descriptions with types
        - Return value description
        - Usage examples (working code)
        - Common pitfalls""",
        agent=writer,
        expected_output="Markdown documentation with examples",
        depends_on=[tasks[0], tasks[1]]
    ),
    Task(
        description="""Verify documentation:
        - Run example code to confirm it works
        - Check parameter descriptions match code
        - Verify return type matches code
        - Test edge cases mentioned""",
        agent=verifier,
        expected_output="Verification report: issues found (or approved)",
        depends_on=[tasks[2]]
    ),
    Task(
        description="Coordinate generation and address any verification issues",
        agent=orchestrator,
        expected_output="Final documentation approved and ready to publish",
        depends_on=[tasks[3]]
    )
]

crew = Crew(
    agents=[reader, searcher, writer, verifier, orchestrator],
    tasks=tasks,
    process=Process.sequential
)

result = crew.kickoff()
```

##### With LangGraph Generator-Verifier Mesh

```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class DocState(TypedDict):
    code_files: str
    draft_docs: str
    verification_results: str
    final_docs: str
    approved: bool

def generate_docs(state: DocState) -> DocState:
    """Generate draft docs from code"""
    draft = """
    # API Reference

    ## UserService

    ### authenticate(email, password)
    Authenticates a user with email and password.

    **Parameters:**
    - email (string): User's email
    - password (string): User's password

    **Returns:**
    - {token: string, user: User object}

    **Example:**
    ```javascript
    const result = await userService.authenticate("user@example.com", "password123");
    console.log(result.token); // Access token for API calls
    ```
    """
    return {"draft_docs": draft}

def verify_docs(state: DocState) -> DocState:
    """Verify docs are accurate"""
    # Run example code, check if it works
    # Verify parameter types match code
    # Verify return types match code

    verification = """
    Verification Results:
    ✓ Example code runs without errors
    ✓ Parameters match function signature
    ✗ Return type: docs say {token, user} but code returns {accessToken, user}
    ✓ No missing parameters

    Issues found: 1 (return type mismatch)
    Status: NEEDS FIXES
    """

    return {"verification_results": verification}

def fix_and_finalize(state: DocState) -> DocState:
    """Fix issues and finalize docs"""
    final = state["draft_docs"].replace("token:", "accessToken:")

    return {
        "final_docs": final,
        "approved": True
    }

# Build graph
builder = StateGraph(DocState)
builder.add_node("generate", generate_docs)
builder.add_node("verify", verify_docs)
builder.add_node("fix", fix_and_finalize)

builder.add_edge(START, "generate")
builder.add_edge("generate", "verify")
builder.add_edge("verify", "fix")
builder.add_edge("fix", END)

graph = builder.compile()

result = graph.invoke({
    "code_files": "[read from src/]",
    "draft_docs": "",
    "verification_results": "",
    "final_docs": "",
    "approved": False
})

print(result["final_docs"])
```

##### With Claude Code + Subagent

```bash
claude

# Main session
/doc-generator
# This subagent:
# 1. Reads src/ code
# 2. Extracts APIs
# 3. Generates docs/API.md

# Then parallel:
@accuracy-checker
# This subagent (independent):
# 1. Reads docs/API.md
# 2. Tests examples
# 3. Reports issues

# Back to main session:
# Reviews verification results
# Fixes docs
# Commits to repo
```

#### Example Workflow

```
Session 1: Scheduled (daily)
- Code changed in src/
- Cron trigger: "Generate and verify docs"

Session 2: Auto-generated (agents)
- Generator reads code, creates docs/API.md
- Accuracy checker runs examples
- Issues found: 2 examples broken, 1 type mismatch
- Fixes applied automatically

Session 3: Human review (you, 5 min)
- Review generated docs
- Approve or request changes
- Commit to repo

Session 4: Publish
- Docs deployed to website
- Users see latest API docs
- Always in sync with code
```

#### Keeping Docs in Sync

**Automated approach:**
```bash
# .github/workflows/sync-docs.yml
on:
  push:
    paths:
      - 'src/**'
trigger: 'Generate and verify docs'

# This runs:
# 1. Doc generator on changed files
# 2. Accuracy checker on generated docs
# 3. Auto-commit if approved, else create PR
```

#### Anti-Patterns

❌ **Docs written by humans only** → Drift from code
❌ **Examples never tested** → Broken, unusable
❌ **No verification step** → Hallucinated APIs
❌ **Docs not updated on code changes** → Users confused

---

### Stage 8: Deployment & DevOps

#### What This Stage Needs
- Pre-deployment validation (security, dependencies, config)
- Gradual rollout with monitoring
- Rollback capability if issues detected
- Zero-downtime deployments

#### Best Swarm Pattern
**Validation Pipeline** (Sequential gates, each verifies a concern in parallel)

Multiple validation agents run before deployment. If any fail, deployment stops.

#### Agent Team Composition

| Agent | Gate | Checks |
|-------|------|--------|
| **Security Validator** | Security | No hardcoded secrets, dependency CVEs, auth checks |
| **Dependency Validator** | Dependencies | No broken versions, compatibility matrix |
| **Config Validator** | Configuration | All env vars set, database connectivity |
| **Performance Validator** | Performance | No performance regressions vs. baseline |
| **Rollback Coordinator** | Safety | Rollback plan ready, database migrations reversible |

#### How to Implement It

##### With LangGraph Deployment Pipeline

```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class DeploymentState(TypedDict):
    version: str
    security_check: str
    deps_check: str
    config_check: str
    perf_check: str
    rollback_check: str
    can_deploy: bool
    deployment_status: str

def validate_security(state: DeploymentState) -> DeploymentState:
    """Check for security issues"""
    result = """
    Security Check:
    ✓ No hardcoded secrets
    ✓ No critical CVEs in dependencies
    ✓ Auth validation in place
    ✓ SQL injection checks present
    Status: PASS
    """
    return {"security_check": result}

def validate_dependencies(state: DeploymentState) -> DeploymentState:
    """Check dependency versions"""
    result = """
    Dependency Check:
    ✓ All packages up to date
    ✓ No breaking versions
    ✓ Lock file committed
    Status: PASS
    """
    return {"deps_check": result}

def validate_config(state: DeploymentState) -> DeploymentState:
    """Check configuration"""
    result = """
    Config Check:
    ✓ DATABASE_URL set in production
    ✓ API_KEY configured
    ✗ REDIS_URL missing
    Status: FAIL
    """
    return {"config_check": result}

def validate_performance(state: DeploymentState) -> DeploymentState:
    """Check performance vs. baseline"""
    result = """
    Performance Check:
    ✓ Latency vs. main: +2% (acceptable <5%)
    ✓ Throughput vs. main: +1% (acceptable)
    ✓ Memory footprint: stable
    Status: PASS
    """
    return {"perf_check": result}

def validate_rollback(state: DeploymentState) -> DeploymentState:
    """Check rollback readiness"""
    result = """
    Rollback Check:
    ✓ Database migrations are reversible
    ✓ Rollback plan documented
    ✓ Blue-green environment ready
    Status: PASS
    """
    return {"rollback_check": result}

def deployment_decision(state: DeploymentState) -> DeploymentState:
    """Decide if safe to deploy"""
    checks = [
        state["security_check"],
        state["deps_check"],
        state["config_check"],
        state["perf_check"],
        state["rollback_check"]
    ]

    can_deploy = all("PASS" in check for check in checks)

    if can_deploy:
        status = "✓ APPROVED FOR DEPLOYMENT"
    else:
        failed = [i for i, check in enumerate(checks) if "FAIL" in check]
        status = f"✗ DEPLOYMENT BLOCKED (failed checks: {failed})"

    return {"can_deploy": can_deploy, "deployment_status": status}

# Build graph
builder = StateGraph(DeploymentState)
builder.add_node("security", validate_security)
builder.add_node("deps", validate_dependencies)
builder.add_node("config", validate_config)
builder.add_node("perf", validate_performance)
builder.add_node("rollback", validate_rollback)
builder.add_node("decide", deployment_decision)

builder.add_edge(START, ["security", "deps", "config", "perf", "rollback"])
builder.add_edge(["security", "deps", "config", "perf", "rollback"], "decide")
builder.add_edge("decide", END)

graph = builder.compile()

result = graph.invoke({
    "version": "v1.2.3",
    "security_check": "",
    "deps_check": "",
    "config_check": "",
    "perf_check": "",
    "rollback_check": "",
    "can_deploy": False,
    "deployment_status": ""
})

print(result["deployment_status"])
```

##### Pre-Deployment Validation in CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Security Check
        run: |
          npm run security-scan
          # Checks for: secrets, CVEs, auth issues

      - name: Dependency Check
        run: |
          npm audit
          npm list --depth=0

      - name: Config Check
        run: |
          node -e "
            const required = ['DATABASE_URL', 'API_KEY', 'REDIS_URL'];
            const missing = required.filter(k => !process.env[k]);
            if (missing.length) throw new Error('Missing: ' + missing);
          "

      - name: Performance Check
        run: |
          npm run benchmark
          # Compare vs. baseline, fail if >5% regression

      - name: Rollback Check
        run: |
          npm run check-migrations
          # Verify migrations are reversible

      - name: Deploy (if all checks pass)
        if: success()
        run: |
          npm run deploy:prod
          # Blue-green deployment
          # Monitor for 5 minutes
          # Auto-rollback if errors > threshold
```

##### With CrewAI Deployment Crew

```python
from crewai import Agent, Crew, Task, Process

security_agent = Agent(
    role="Security Validator",
    goal="Ensure deployment is secure",
    model="claude-opus"
)

deps_agent = Agent(
    role="Dependency Validator",
    goal="Verify all dependencies are safe",
    model="claude-opus"
)

config_agent = Agent(
    role="Configuration Validator",
    goal="Check all configuration is correct",
    model="claude-opus"
)

perf_agent = Agent(
    role="Performance Validator",
    goal="Ensure no performance regression",
    model="claude-opus"
)

rollback_agent = Agent(
    role="Rollback Coordinator",
    goal="Ensure rollback is possible if needed",
    model="claude-opus"
)

deploy_agent = Agent(
    role="Deployment Manager",
    goal="Execute deployment if all checks pass",
    model="claude-opus"
)

tasks = [
    Task(
        description="Run security checks: secrets scan, CVE check, auth validation",
        agent=security_agent,
        expected_output="Security check report: PASS or FAIL"
    ),
    Task(
        description="Verify dependencies: audit for known vulnerabilities, check compatibility",
        agent=deps_agent,
        expected_output="Dependency check report: PASS or FAIL"
    ),
    Task(
        description="Validate configuration: all env vars set, database connectivity verified",
        agent=config_agent,
        expected_output="Config check report: PASS or FAIL"
    ),
    Task(
        description="Check performance: compare latency/throughput vs. main branch",
        agent=perf_agent,
        expected_output="Performance report: PASS (if <5% regression) or FAIL"
    ),
    Task(
        description="Verify rollback readiness: database migrations reversible, rollback plan documented",
        agent=rollback_agent,
        expected_output="Rollback check report: PASS or FAIL"
    ),
    Task(
        description="If all checks pass, execute deployment using blue-green strategy",
        agent=deploy_agent,
        expected_output="Deployment status: SUCCESS or FAILED",
        depends_on=[tasks[0], tasks[1], tasks[2], tasks[3], tasks[4]]
    )
]

crew = Crew(
    agents=[security_agent, deps_agent, config_agent, perf_agent, rollback_agent, deploy_agent],
    tasks=tasks,
    process=Process.parallel  # All validations run in parallel
)

result = crew.kickoff()
print(result)
```

#### Example Workflow

```
Commit to main → Deployment Pipeline Starts

T+0: Parallel Validation (all run in parallel)
- Security Agent: Scans code, checks CVEs → ✓ PASS
- Deps Agent: Audits packages → ✓ PASS
- Config Agent: Verifies env vars → ✗ FAIL (REDIS_URL missing)
- Perf Agent: Benchmarks latency → ✓ PASS
- Rollback Agent: Checks migrations → ✓ PASS

T+2: Decision
- Status: DEPLOYMENT BLOCKED
- Reason: Configuration missing
- Action: Notify engineer to set REDIS_URL in production

T+3 (engineer fixes config):
- Rerun validation pipeline
- All checks pass
- Deployment approved

T+4: Blue-Green Deploy
- Deploy v1.2.3 to green environment
- Route 5% traffic to green
- Monitor error rate, latency
- Gradual shift: 5% → 10% → 25% → 50% → 100%

T+10: Monitoring
- Error rate: 0.01% (same as blue)
- Latency: +1% (acceptable)
- Memory: stable

T+15: Rollout Complete
- 100% traffic on green
- Blue decommissioned
- Deployment successful

If errors spike at any point:
- Auto-rollback to blue
- Investigate root cause
- Fix and retry
```

#### Anti-Patterns

❌ **No pre-deployment validation** → Bugs ship to production
❌ **Single sequential check** → Takes 30 minutes
❌ **No rollback capability** → Stuck with broken production
❌ **Big-bang deployment** → All-or-nothing risk

---

### Stage 9: Maintenance & Refactoring

#### What This Stage Needs
- Identify tech debt
- Keep dependencies updated
- Refactor without introducing bugs
- Maintain code quality over time

#### Best Swarm Pattern
**Hierarchical Analysis + Parallel Fixes**

A coordinator identifies tech debt. Multiple agents refactor different modules in parallel.

#### Agent Team Composition

| Agent | Role | Responsibility |
|-------|------|-----------------|
| **Debt Analyzer** | Identifies tech debt | Large functions, duplication, outdated patterns |
| **Dependency Updater** | Updates packages | Check for updates, test compatibility |
| **Refactor Worker A** | Refactors module A | Extract functions, improve names, reduce duplication |
| **Refactor Worker B** | Refactors module B | Same as Worker A, different module |
| **Integration Tester** | Validates changes | Run test suite, check for regressions |

---

## Part III: Framework-Specific Implementation

### LangGraph for Development Workflows

**When to use:** Complex orchestration with conditional branching, parallel execution, persistence

**⚠️ Consider simpler alternatives first:** For 2-agent systems or quick prototypes, CrewAI's task-based approach or simple async loops may be more practical than LangGraph's graph abstraction. LangGraph shines when you need persistent state, error recovery, and complex conditional routing. Don't default to it for every multi-agent task.

**Key features for dev workflows:**
- Graph-based execution with conditional nodes
- Persistent state with checkpointing
- Parallel node execution with async/await
- Error recovery and retry logic

**Example: Multi-stage code review pipeline**

```python
from langgraph.graph import StateGraph, START, END
from langgraph.types import Command
from typing import TypedDict

class CodeReviewState(TypedDict):
    code: str
    security_review: str
    perf_review: str
    style_review: str
    approved: bool

def route_to_reviewers(state: CodeReviewState) -> Command:
    """Dispatch to all reviewers in parallel"""
    return Command(
        update={},
        goto=["security_review", "perf_review", "style_review"]
    )

def aggregate_reviews(state: CodeReviewState) -> CodeReviewState:
    """Aggregate reviews and decide"""
    issues = []
    if "issue" in state["security_review"]:
        issues.append("security")
    if "issue" in state["perf_review"]:
        issues.append("performance")
    if "issue" in state["style_review"]:
        issues.append("style")

    approved = len(issues) == 0
    return {"approved": approved}

builder = StateGraph(CodeReviewState)
builder.add_node("route", route_to_reviewers)
builder.add_node("sec", security_review)  # runs in parallel
builder.add_node("perf", perf_review)      # runs in parallel
builder.add_node("style", style_review)    # runs in parallel
builder.add_node("aggregate", aggregate_reviews)

builder.add_edge(START, "route")
builder.add_edge(["sec", "perf", "style"], "aggregate")
builder.add_edge("aggregate", END)
```

### CrewAI for Development Workflows

**When to use:** Fast prototyping, role-based teams, business workflows

**Key features for dev workflows:**
- Role-based agents with clear responsibilities
- Process types: sequential, hierarchical, parallel
- Delegation support (higher-level agents delegate to lower-level)
- Simple task orchestration

**Example: Research team with delegated tasks**

```python
from crewai import Agent, Crew, Task, Process

lead_agent = Agent(
    role="Research Lead",
    goal="Orchestrate research and synthesize findings",
    model="claude-opus",
    allow_delegation=True  # Can delegate to other agents
)

domain_agent = Agent(
    role="Domain Researcher",
    goal="Deep research on domain topics",
    model="claude-sonnet"
)

lead_task = Task(
    description="Create research plan and delegate to specialists",
    agent=lead_agent
)

research_task = Task(
    description="Execute domain research",
    agent=domain_agent
)

crew = Crew(
    agents=[lead_agent, domain_agent],
    tasks=[lead_task, research_task],
    process=Process.hierarchical
)
```

### Claude Agent SDK for Development Workflows

**When to use:** All-Anthropic stack, MCP-heavy workloads, container-per-task isolation

**Key features for dev workflows:**
- MCP integration (GitHub, Slack, databases)
- PreToolUse hooks for policy injection
- Container-per-task for isolation
- Tight Claude integration

**Example: MCP-based code review**

```python
from anthropic import Anthropic

client = Anthropic(
    model="claude-opus-4-6",
    mcpServers={
        "github": {
            "command": "npx",
            "args": ["@modelcontextprotocol/server-github"],
            "env": {"GITHUB_TOKEN": token}
        }
    }
)

# Review a PR
response = client.messages.create(
    messages=[
        {
            "role": "user",
            "content": "Review PR #456 for security issues"
        }
    ]
)
```

---

## Part IV: Practical Constraints & Considerations

### Token Costs by Pattern

| Pattern | Relative Cost | Cost Drivers | When It Matters |
|---------|---|---|---|
| Sequential | 1x | 1 agent per stage | Low-complexity workflows |
| Parallel | 1.5-2x | N agents + 1 aggregation | High-value decisions |
| Hierarchical | 1.5-2x | 1 planner + N workers | Complex decomposition |
| Debate | 2-3x | N agents + judge + rounds | Critical decisions |
| Adversarial | 3x | Coder + independent reviewer | Security/correctness critical |
| Swarm | 1-10x | Highly variable (can spiral) | Emergent coordination |

**Cost optimization:**
- Use cheaper models for specialized tasks (Sonnet vs. Opus)
- Run parallel agents to reduce wall-clock time
- Use async execution to batch API calls
- Monitor token spend per stage

### When Single Agent is Better Than Multi-Agent

❌ **Don't use multi-agent for:**
- Simple, well-defined tasks ("write a function")
- Low-complexity decisions ("rename a variable")
- Cost-sensitive applications (budget < $10/month)
- Tasks requiring deep context (entire codebase in prompt)

✅ **Use single agent for:**
- Writing one function
- Fixing a typo
- Explaining a concept
- Quick debugging (< 5 minutes)

### When Multi-Agent Becomes Cost-Effective

✅ **Use multi-agent when:**
- Task naturally decomposes (architecture choice)
- Quality improvement > cost increase (code review)
- Speed improvement matters (parallel testing)
- Resilience required (distributed debugging)
- Scale > 100K lines of code

### Error Handling & Recovery

**Multi-agent error patterns:**

1. **Agent Failure** → Retry with same agent (3x) or escalate to human
2. **Timeout** → Set realistic timeouts per agent, not global
3. **Conflicting Results** → Have a judge agent break tie
4. **Resource Exhaustion** → Monitor concurrent API calls, queue if needed

**Example error handling:**

```python
from langgraph.graph import StateGraph
from langgraph.errors import NodeFailureError

async def safe_node(state):
    """Node with retry logic"""
    max_retries = 3
    for attempt in range(max_retries):
        try:
            return await agent.invoke(state)
        except Exception as e:
            if attempt < max_retries - 1:
                wait = 2 ** attempt  # Exponential backoff
                await asyncio.sleep(wait)
            else:
                # Escalate to human
                raise NodeFailureError(f"Node failed after {max_retries} attempts: {e}")
```

### Observability & Monitoring

**For multi-agent systems, track:**
- Per-agent token usage and cost
- Agent latency (p50, p99)
- Error rates by agent
- Input/output quality metrics
- Agent disagreement (in consensus patterns)

**Tools:**
- **LangSmith** (LangGraph official)
- **Langfuse** (open-source tracing)
- **Braintrust** (evaluation platform)

```python
# With LangSmith
from langsmith import traceable

@traceable(name="code_reviewer")
def review_code(code: str) -> str:
    """Runs in LangSmith with automatic tracing"""
    return agent.invoke({"code": code})
```

---

## Part V: Decision Trees

### Choosing an Orchestration Pattern

```
Is the task clearly decomposable into independent subtasks?
├─ No → Use Sequential Pipeline
│   └─ Agent1 → Agent2 → Agent3
│
└─ Yes
   ├─ Does speed matter (parallel benefit > cost)?
   │  ├─ No → Hierarchical (director decomposes)
   │  │  └─ Director plans, workers execute
   │  │
   │  └─ Yes
   │     ├─ Is the decision high-stakes (security, architecture)?
   │     │  ├─ Yes → Debate/Consensus (2-3x cost for safety)
   │     │  │  └─ Pro vs. Con vs. Judge
   │     │  │
   │     │  └─ No → Parallel Fan-Out/Fan-In
   │     │     └─ All agents on same input, aggregate results
   │     │
   │     └─ Does resilience matter (no single point of failure)?
   │        ├─ Yes → Swarm (hard to debug, variable cost)
   │        │
   │        └─ No → Parallel (simpler, more controlled)
```

### Choosing a Framework

```
What's your stack?
├─ All Claude (Anthropic stack)
│  └─ Use Claude Agent SDK
│     └─ MCP-native, lifecycle control, container isolation
│
├─ LLM-agnostic
│  ├─ Complex stateful workflows? → LangGraph
│  │  └─ Graph-based, persistence, observability
│  │
│  └─ Rapid multi-agent prototyping? → CrewAI
│     └─ Role-based, easiest onboarding, visual editor
│
├─ Conversational/research agents? → AG2 (AutoGen)
│  └─ Event-driven, free/open-source, no paid tier
│
└─ TypeScript preference? → Mastra
   └─ Newer, supervisor pattern, modern stack
```

---

## Conclusion

**Key Takeaways:**

1. **Different stages need different patterns.** Research needs orchestrator-workers. Architecture needs debate. Code needs hierarchical. Testing needs parallel swarms.

2. **Pattern choice is a speed/resilience/cost tradeoff.** Sequential is cheap and simple. Parallel is fast. Debate is safe. Swarm is resilient but hard to control.

3. **Framework choice matters less than pattern choice.** LangGraph, CrewAI, AG2, and Claude Agent SDK can all implement most patterns. Choose based on ecosystem fit and learning curve.

4. **Multi-agent is not always better.** Start single-agent for simple tasks. Move to multi-agent when complexity justifies it (cost < benefit). Google/MIT research (March 2026) formalizes this with three scaling effects: **tool-coordination trade-off** (many-tool tasks suffer from multi-agent overhead), **capability saturation** (adding agents has diminishing returns past an optimal point), and **topology-dependent error amplification** (centralized orchestration reduces error propagation vs decentralized topologies).

5. **Observability is non-negotiable.** Multi-agent systems fail in non-obvious ways. Trace everything from day one.

6. **The planner-coder gap is real.** Hierarchical patterns show 7.9-83.3% robustness loss when inputs change semantically. Validate robustness before production.

---

## Sources

- [Codebridge: Multi-Agent Orchestration Coordination 2026](https://www.codebridge.tech/articles/mastering-multi-agent-orchestration-coordination-is-the-new-scale-frontier)
- [Kanerika: AI Agent Orchestration 2026](https://kanerika.com/blogs/ai-agent-orchestration/)
- [OnAbout: Multi-Agent Orchestration 2025-2026](https://www.onabout.ai/p/mastering-multi-agent-orchestration-architectures-patterns-roi-benchmarks-for-2025-2026)
- [MachineLearningMastery: 7 Agentic AI Trends 2026](https://machinelearningmastery.com/7-agentic-ai-trends-to-watch-in-2026/)
- [Iterathon: Agent Orchestration LangGraph CrewAI 2026](https://iterathon.tech/blog/ai-agent-orchestration-frameworks-2026)
- [Markaicode: LangGraph vs CrewAI 2026](https://markaicode.com/vs/langgraph-vs-crewai-multi-agent-production/)
- [AI Multiple: Agentic Frameworks 2026](https://aimultiple.com/agentic-frameworks)
- [Medium: Multi-Agent Debate-Based Consensus](https://medium.com/@edoardo.schepis/patterns-for-democratic-multi-agent-ai-debate-based-consensus-part-1-8ef80557ff8a)
- [Microsoft Azure: AI Agent Design Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
- [Google Cloud: Multi-Agent Code Review](https://medium.com/google-cloud/agents-that-prove-not-guess-a-multi-agent-code-review-system-e2c0a735e994)
- [Tribe AI: Agentic AI Future and Swarm Intelligence](https://www.tribe.ai/applied-ai/the-agentic-ai-future-understanding-ai-agents-swarm-intelligence-and-multi-agent-systems)
- [Microsoft Research: RedCodeAgent Red Teaming](https://www.microsoft.com/en-us/research/blog/redcodeagent-automatic-red-teaming-agent-against-diverse-code-agents/)
- [ArXiv: DoVer Intervention-Driven Auto Debugging](https://arxiv.org/html/2512.06749v1/)
- [ArXiv: DocAgent Multi-Agent Documentation](https://arxiv.org/html/2504.08725v1/)
- [TestingXperts: Multi-Agent QA Automation](https://www.testingxperts.com/blog/multi-agent-systems-redefining-automation/)
- [Zyrix: Multi-Agent AI Testing Guide 2025](https://zyrix.ai/blogs/multi-agent-ai-testing-guide-2025/)
- [LangChain: LangGraph Persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
- [LangChain: LangGraph Documentation](https://www.langchain.com/langgraph)
- [CrewAI: Official Homepage](https://crewai.com/)
- [Claude Agent SDK: Documentation](https://platform.claude.com/docs/en/agent-sdk/overview)
- [Claude Agent SDK: MCP Integration](https://platform.claude.com/docs/en/agent-sdk/mcp)
- [AG2 (AutoGen): GitHub](https://github.com/ag2ai/ag2)
- [Google/MIT Multi-Agent Scaling Principles (InfoQ, March 2026)](https://www.infoq.com/news/2026/03/google-multi-agent/)

---

## Related Topics

- [AI-Native Architecture](ai-native-architecture.md) — Foundation patterns for building multi-agent systems
- [Decision Trees](decision-trees.md) — Choosing between single-agent and multi-agent approaches
- [Tool Comparison Guide](tool-comparison-when-to-use.md) — Evaluating frameworks for swarm implementations
- [Mastra Framework](https://mastra.ai/)

---

## Changelog
| Date | Change | Source |
|------|--------|--------|
| 2026-03-20 | Added Google/MIT multi-agent scaling research findings: three dominant effects — (1) tool-coordination trade-off (tasks requiring many tools perform worse with multi-agent overhead), (2) capability saturation (diminishing returns past optimal agent count), (3) topology-dependent error amplification (centralized orchestration reduces errors vs decentralized). Added source to Sources section. | Daily briefing 2026-03-20 finding #3 |
