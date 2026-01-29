# Collaborative Intelligence System: Architectural Vision

A system of collaborative agents whose primary purpose is preserving and serving the project's vision and architectural integrity. Every capability this system provides, institutional memory, quality enforcement, research, session management, exists to ensure that all development work, whether by a single agent or a coordinated team, faithfully serves the project's vision and follows established architecture. Originally conceived as a "Quality Co-Agent," the scope expanded when we recognized that code quality is downstream of architecture, and architecture is downstream of vision. Protecting the higher-order concerns is what makes the lower-order ones achievable.

**Execution Platform: Claude Code Max.** This entire system operates through Claude Code sessions on a Claude Max subscription. Claude Code provides the core execution primitives (subagents, parallel sessions, headless invocations, hooks, session resume), and MCP servers extend those primitives to encompass inter-agent communication, persistent knowledge graphs, agent registries, semantic memory, and more. No API keys are needed. No external orchestration frameworks. The combination of Claude Code's native capabilities and the MCP ecosystem gives us a platform that can grow to meet virtually any coordination or intelligence need, while remaining grounded in what works today.

---

## Core Principles

**P1: Vision First, Architecture Second, Quality Third**
The system's hierarchy of concerns mirrors the hierarchy of what matters in a project. Vision (what the project IS and who it serves) governs architecture (how we build it). Architecture governs quality (the standards we enforce). Every agent's work is measured against this hierarchy: a perfectly linted function that violates the project's voice-first design is a failure, not a success. Vision standards are immutable by agents (only the human defines the vision). Architectural standards are high-friction (agents propose changes, human approves). Quality standards are automated and low-friction. This ordering ensures the system protects what matters most.

**P2: Mutual Confidence, Not Gatekeeping**
The quality system and dev agents should "have each other's back." Confidence in tool calls comes from genuine understanding of the VALUE of each action. The quality agent doesn't just check boxes; it understands why a check matters. The dev agent trusts that quality feedback is genuinely helpful. Neither side "owns" quality; it's shared.

**P3: Bidirectional Agency**
The quality system is not an admonishing schoolmarm. It pushes back constructively, questions architectural decisions, but ultimately enables the coding agent to do its best work. The dev agent should feel supported, not policed.

**P4: True Multi-Agentic Composition**
Not "multiple copies of the same thing." True specialization where:
- Task specialists handle specific domains (CodeRabbit for code review, specialized linters per language)
- External specialist agents are delegated to and their output consumed agentically (not just human-readable PR comments)
- If something is 3x better at TypeScript linting, it gets the TypeScript work

**P5: Specialist Delegation with Agentic Information Exchange**
External tools designed for human consumption (CodeRabbit PR reviews, etc.) should be consumed programmatically. The information exchange between all agents should be agentic and full of agency, not limited to human-readable formats.

**P6: Justified Complexity / Simplicity as a Vector**
Every architectural decision must justify its existence. "Simple" is not a state but an intention, a constant reflective pressure. When pushing hard on features, the answer will often be "yes, this earns its place." But not always. Architectural flexibility and pluggability where needed, but not where it doesn't earn its keep.

**P7: Extended Autonomous Sessions (The Ultimate Goal)**
A system of 1-to-many coding agents + the quality system works for hours (many hours) without:
- Derailing or losing focus
- Quality degradation
- Going into the weeds
- Being unchecked

End result is not just what was hoped for but potentially BETTER. That success is attributable specifically to the collaboration, not achievable by multiple Claude Code instances alone.

**P8: Claude Code Max as the Execution Platform**
All agentic work runs through Claude Code sessions on a Max subscription. This means:
- Agents are Claude Code sessions (interactive or headless) and built-in subagents
- MCP servers provide the extensibility layer: inter-agent communication, persistent memory, agent registries, semantic search, and any other capability the system needs
- Git coordinates code state; the filesystem stores artifacts and human-readable archives
- The human developer is always the ultimate orchestrator with Claude Code as the instrument
- Model selection follows "capability first": Opus 4.5 is the default for anything requiring judgment; Sonnet 4.5 for genuinely routine tasks where speed is an advantage; Haiku only for purely mechanical operations
- No API keys are needed; no external orchestration frameworks

Claude Code's native primitives combined with MCP servers create a platform capable of supporting sophisticated multi-agent coordination, persistent institutional memory, and real-time inter-session communication.

---

## The Core Metaphor: A Team with a Shared Mission

A pipeline is: hooks fire, tools run, state files update, agents read state. That's plumbing. This system is a **team united by a shared mission**: realizing the project's vision through disciplined architecture and quality execution. Every member's work, from code generation to quality review to research, is measured against that mission.

- Members have distinct expertise and genuinely different perspectives
- They communicate bidirectionally with rich context, not just pass structured findings
- They develop working confidence in each other through track record, not just permission scoping
- The quality of the collective output exceeds what any individual member could produce
- They can sustain focus and coherence over long working sessions
- **Every member understands the project's vision and protects it.** The quality session is the explicit guardian, but all sessions operate within the vision's boundaries.

The architecture supports this at every level: the knowledge graph encodes vision and architectural standards that all sessions consult, MCP servers provide the shared infrastructure for communication and coordination, Claude Code sessions provide the execution, and git provides the transaction log.

---

## The Platform: Claude Code Max + MCP Ecosystem

Claude Code provides the execution primitives, and MCP servers extend them into a full-featured platform for multi-agent coordination. The combination is more capable than either alone: Claude Code handles session management, code generation, and tool invocation, while MCP servers provide communication, memory, agent coordination, and virtually any other shared service the system needs.

### Core Primitives

| Primitive | Capability | Notes |
|-----------|-----------|-------|
| **Built-in subagents** | Parallel task delegation within a session. Explore, Plan, General-purpose types. Independent context windows. | One level deep (no nesting). Background subagents lack MCP access. Results return to parent session. |
| **Parallel sessions** | Multiple Claude Code instances in separate terminals/worktrees. Full file isolation. Independent MCP connections. | Inter-session messaging handled by shared MCP servers. |
| **Headless mode** | `claude -p "prompt"` for non-interactive queries. Structured JSON output. Session ID capture. | Each invocation is isolated unless explicitly resumed. |
| **Session resume** | Full context persistence. Resume by session ID. Multi-day continuity. | Long sessions benefit from periodic compaction and segmentation. |
| **Hooks** | Lifecycle interceptors (PreToolUse, PostToolUse, SessionStart, etc.). Can run scripts, validate operations. | Reactive by design. Can invoke `claude -p` for event-driven coordination. |
| **MCP servers** | The extensibility layer. Standardized tool/data access. Multiple sessions share the same server. Persistent state, bidirectional communication, push notifications. HTTP transport handles 50+ concurrent clients. | Server must be running. HTTP transport for multi-client; STDIO for single-client. |
| **Git/filesystem** | Code state coordination (branches, merges, diffs). Artifact storage (task briefs, reports, archives). | Real-time coordination handled by MCP; git handles code state and versioned artifacts. |
| **Model routing** | Opus 4.5 as default (capability first). Sonnet 4.5 for routine tasks where speed helps. Haiku for purely mechanical subagent operations. | Model selected per-session or per-subagent at creation time. Never downgrade capability for speed. |

### MCP as the Extensibility Layer (The Key Insight)

The critical realization: MCP servers are not just "tool access." They are a general-purpose capability channel that can provide:

**Inter-Agent Communication**: An MCP server can act as a "patch panel," a shared communication bus that multiple Claude Code sessions connect to. Sessions register themselves (name, type, current task), discover other active sessions, and exchange structured messages. This is not theoretical. Projects like [Agent-MCP](https://github.com/rinadelph/Agent-MCP) already implement this pattern: direct messaging between agents, broadcast capabilities, and shared knowledge graphs, all exposed as MCP tools.

**Persistent Memory**: MCP memory servers already exist and are production-ready:
- [Knowledge Graph Memory](https://github.com/modelcontextprotocol/servers/tree/main/src/memory) (Anthropic's own): Persistent knowledge graph with entities, relations, and observations. JSONL-backed. Tools for creating, searching, and traversing the graph.
- [mcp-memory-service](https://github.com/doobidoo/mcp-memory-service): Semantic search over persistent context. SQLite-backed with 5ms response times. Multi-session memory sharing is the core value proposition.
- [graph-mem-mcp](https://github.com/arnokamphuis/graph-mem-mcp): Graph memory with relevance scoring and semantic search.
- Hybrid architectures combining Mem0 with Neo4j graph databases exist as MCP servers.

**Agent Registry and Discovery**: The [MCP Gateway & Registry](https://github.com/agentic-community/mcp-gateway-registry) provides agent registration, discovery, A2A communication, and virtual MCP servers that act as routing layers. MuleSoft's Agent Registry wraps MCP servers in enterprise governance.

**State Management**: MCP servers can maintain persistent state via in-memory storage, SQLite, Postgres, Redis, or any backing store. Session state persists via session IDs in HTTP headers. Context stores bridge calls and sessions.

**Push Notifications**: The MCP protocol supports bidirectional communication. Servers can push notifications to connected clients when state changes, a monitoring threshold is breached, or another agent needs attention. This is not polling; it is event-driven when using HTTP/SSE transport.

This gives the architecture a rich coordination infrastructure:
- Real-time inter-session communication through typed MCP tool calls
- Structured persistent memory via knowledge graphs with semantic search
- Agent discovery and registration through shared MCP services
- Event-driven coordination via push notifications on HTTP/SSE transport

### Genuine Boundaries

A few things sit outside the platform's reach. These are the actual boundaries, not the broader list of capabilities that MCP servers handle:

| Boundary | Why |
|----------|-----|
| Agent SDK orchestration | Requires API keys. Not needed; Claude Code sessions + MCP servers cover the same use cases. |
| LangGraph/AutoGen/CrewAI as orchestrators | These frameworks require API access to call LLMs. Our platform provides equivalent orchestration patterns through MCP and git. |
| Subagent nesting | Subagents cannot spawn subagents. Workflows are designed one level deep; MCP servers handle any coordination that would otherwise require nesting. |
| Dynamic model switching mid-session | Model is set at session/subagent creation. Strategic model selection happens at session start. |

### Architecture Summary

The system architecture is:
- **MCP-mediated for communication and memory**, leveraging existing MCP servers for inter-session messaging, persistent knowledge graphs, and agent discovery
- **Filesystem-based for artifacts and human-readable archives**, because files are universal, auditable, version-controlled, and always available
- **Human-orchestrated at the top level**, with Claude Code sessions as the execution units
- **Subagent-parallel within sessions**, for fast, tight coordination on subtasks
- **Git-coordinated for code state**, because git is the natural transaction log for code changes

The combination of MCP servers (for communication, memory, coordination) and filesystem/git (for artifacts and code state) gives us a richer foundation than either alone. We should adopt existing MCP servers where they fit rather than building inferior replacements from scratch.

---

## 1. Agent Topology

The three-tier model maps naturally onto Claude Code's primitives and MCP infrastructure:

```
┌─────────────────────────────────────────────────────────────┐
│              HUMAN + PRIMARY SESSION (Orchestrator)          │
│  The human developer in an interactive Claude Code session.  │
│  Maintains goals, delegates work, reviews results,           │
│  manages checkpoints via git, brokers across sessions.       │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
             │     ┌──────────────────┐   │
             │     │   MCP HUB        │   │
             │     │  Communication,  │   │
             │     │  Memory, Agent   │   │
             │     │  Registry        │   │
             │     └──┬───────────┬───┘   │
             │        │           │       │
    ┌────────┴────────┴┐        ┌─┴───────┴────────┐
    │  WORKER SESSIONS  │        │  QUALITY SESSION  │
    │  (Parallel CC     │        │  (Dedicated CC    │
    │   in worktrees)   │        │   instance with   │
    │                   │        │   quality focus)   │
    └────────┬──────────┘        └────────┬─────────┘
             │                            │
             │       ┌────────────────────┤
             │       │                    │
    ┌────────┴───────┴──┐       ┌────────┴────────┐
    │  SUBAGENT POOL     │       │  SPECIALIST TOOLS │
    │  (Built-in: Explore│       │  (MCP servers,     │
    │   Plan, General)   │       │   linters, etc.)   │
    └────────────────────┘       └───────────────────┘
```

**The Orchestrator Layer: Human + Primary Session**
- The human developer is the session orchestrator, the strategic decision-maker who directs the team.
- The primary Claude Code session acts as the "project lead" brain, maintaining context about what all sessions are doing.
- Research on Human-Agent Interaction strongly validates this: the "Co-pilot" model where humans navigate and agents drive (or vice versa) consistently outperforms full automation. The market success of Cursor and Copilot confirms that users prefer tools that empower them over tools that attempt to replace them.
- The orchestrator session uses subagents for parallel investigation, headless invocations for quick queries, and delegates sustained work to parallel sessions.

**Worker Sessions: Parallel Claude Code Instances**
- Each worker runs in its own terminal, typically in its own git worktree for file isolation.
- Workers receive their brief through structured task files (markdown docs with goals, acceptance criteria, constraints).
- Workers produce code artifacts in their worktree and register status via the MCP communication hub.
- The MCP hub provides real-time coordination: workers announce progress, receive findings from the quality session, and respond to messages, all through typed MCP tool calls.
- Git handles code state (branches, diffs, merges). Files handle larger artifacts (task briefs, reports).

**The Quality Session: Guardian of Vision, Architecture, and Quality**
- A persistent Claude Code session whose CLAUDE.md, skills, and prompting are specialized for oversight across all three tiers.
- Runs in its own terminal, reads the same codebase, has access to all quality, communication, and memory tools via MCP.
- At startup, loads vision documents and queries the knowledge graph for vision-tier and architecture-tier entities relevant to the current work area.
- Evaluates all work through three ordered lenses: vision alignment first (does this serve the project's purpose?), architectural conformance second (does this follow established patterns?), quality compliance third (does the code pass automated checks?). This ordering ensures higher-tier issues are surfaced before lower-tier ones.
- Communicates findings to workers through the MCP communication hub, with severity and tier attached to every finding.
- Can be resumed across days for continuity, with the knowledge graph carrying institutional memory forward.

**Subagent Pool: Within-Session Parallelism**
- Each session (orchestrator, worker, quality) can use built-in subagents for parallel subtasks.
- Explore agents for fast codebase search, Plan agents for strategy, General-purpose for complex subtasks.
- This is the "free" parallelism: no extra sessions needed, runs within the parent's context budget.
- Critical constraint: subagents cannot nest. Design workflows to be one level deep.

**Specialist Tools: MCP and Deterministic Verifiers**
- Linters, formatters, compilers, test runners, CodeRabbit: accessed via MCP or direct tool calls.
- These are not agents; they are tools. The distinction matters. An agent reasons; a tool executes.
- Research strongly validates using deterministic verifiers (compilers, linters, test suites) as the primary trust mechanism. They are cheaper and more reliable than LLM-based verification.

---

## 2. Oversight Tiers: Vision, Architecture, and Quality

The system organizes its oversight responsibilities into three tiers, ordered by what matters most. This hierarchy is the organizing principle for everything that follows: how agents communicate, what memory protects, how trust is calibrated, and how findings are prioritized.

### The Three Tiers

| Tier | Scope | Mutability | Enforcement |
|------|-------|------------|-------------|
| **T1: Vision** | Project identity, fundamental purpose, design philosophy. What the project IS and who it serves. | **Immutable by agents.** Only the human defines and modifies vision. Agents enforce vision but never propose changes to it. | Quality session checks all work against vision documents and vision-tier knowledge graph entities. Vision conflicts are the highest-severity finding and stop work immediately. |
| **T2: Architecture** | Established patterns, conventions, performance targets, resiliency standards, resource usage requirements. How the project is built to realize the vision. | **High-friction.** Agents can propose changes through structured proposals. Human must approve before any architectural standard changes. | Quality session consults the knowledge graph for architectural entities before reviewing changes. Blocks deviations that lack an approved change proposal. Monitors for "ad-hoc pattern drift" (creating new implementations when established functions exist). |
| **T3: Quality** | Lint, syntax, security scanning, test coverage, formatting. The standards that code must meet. | **Low-friction, automated.** Agents fix deterministic issues autonomously. | Pre-commit hooks, `/validate`, CI gates. Quality session auto-fixes deterministic violations. Goal: code passes all checks on first commit attempt, eliminating the stop-and-fix cycle. |

### Why This Ordering Matters

A perfectly linted function that violates the project's voice-first design is a failure, not a success. A well-architected service that ignores an established DI pattern creates maintenance debt, regardless of how clean its code is. The tiers ensure that agents address the most important concerns first:

1. **Vision lens** (first): Does this work align with project identity? Example: "This feature requires screen taps during oral practice. The hands-free first design requires 100% hands-free operation within voice-centric activities."
2. **Architecture lens** (second): Does this work follow established patterns? Example: "This creates an inline service instead of using protocol-based DI via init injection through the ServiceRegistry."
3. **Quality lens** (third): Does the code pass automated checks? Example: "SwiftLint reports 3 violations. 2 are auto-fixable."

A worker should never hear "fix your lint" when the real problem is "this feature contradicts the voice-first design."

### Change Protocols

**Tier 1 (Vision) Changes:**
- Vision documents are read-only for all agents
- The knowledge graph marks vision entities with `mutability: human_only`
- If an agent's work conflicts with a vision standard, the quality session raises the conflict via the MCP hub with severity `vision_conflict`
- Agents adapt their work to fit the vision. They never propose that the vision adapt to fit their work.
- The quality session loads all vision documents and vision-tier entities at startup

**Tier 2 (Architecture) Changes:**
- Architecture standards can evolve, but changes require a structured proposal
- An agent that believes an architectural standard should change creates a `change_proposal` message via the MCP hub: current standard, proposed change, rationale, impact analysis
- The proposal is flagged for human review (severity: `architecture_change_proposal`)
- Until the human approves, the existing standard is enforced
- Approved changes update the knowledge graph entity and the corresponding living document
- The quality session specifically monitors for "ad-hoc pattern drift": when a worker creates something new instead of using an existing established function or pattern, this is an architecture-tier finding, even if the new code works

**Tier 3 (Quality) Changes:**
- Quality rules are largely automated and low-friction
- Tool configurations can be updated as part of normal work, subject to the Tool Trust Doctrine (never suppress findings without proof)
- The quality session auto-fixes deterministic issues (formatting, simple lint violations) silently
- The goal is that code passes all quality checks on first commit, preventing the gated process where everything stops for long error-fixing iterations

### Conflict Resolution

When work conflicts with a standard, the tier determines the response:

| Conflict Tier | Response | Who Resolves |
|---------------|----------|-------------|
| T1: Vision | **Stop.** Work must conform to vision. Escalate to human if ambiguous. | Human |
| T2: Architecture | **Pause.** Provide rationale and reference the established pattern. Worker adapts or submits a formal change proposal. | Worker + Human (for proposals) |
| T3: Quality | **Auto-fix** if deterministic. Report if judgment is needed. Low urgency. | Agent (autonomous) |

Higher tiers always override lower ones. A vision conflict makes lint issues irrelevant until the vision conflict is resolved.

### Living Documents by Tier

Each tier has authoritative documents that define its standards. These documents are the source of truth; knowledge graph entities reference them.

| Document | Tier | Mutability | Purpose |
|----------|------|------------|---------|
| `docs/design/HANDS_FREE_FIRST_DESIGN.md` | T1: Vision | Human-only | Voice-first design philosophy and requirements |
| (Future) Project identity/purpose documents | T1: Vision | Human-only | Core project identity beyond voice-first |
| `docs/ios/IOS_STYLE_GUIDE.md` | T2: Architecture | Human-approved | iOS coding standards and patterns |
| `AGENTS.md` (testing philosophy sections) | T2: Architecture | Human-approved | Testing standards, development conventions |
| `docs/quality/TOOL_TRUST_DOCTRINE.md` | T2: Architecture | Human-approved | Tool trust philosophy and dismissal standards |
| Component-level ADRs in knowledge graph | T2: Architecture | Human-approved | Per-component architectural decisions |
| `docs/quality/CODE_QUALITY_INITIATIVE.md` | T3: Quality | Automated | Quality gate definitions and implementation |
| `.swiftlint.yml`, `ruff.toml`, tool configs | T3: Quality | Automated | Tool-specific rule configurations |

---

## 3. Communication Architecture: MCP-Mediated Structured Dialogue

Research into multi-agent dialogue is unambiguous: unstructured chat between agents devolves into "sycophancy loops" where agents politely agree with each other's hallucinations. Natural language is a poor coordination protocol. The solution is structured, typed communication through reliable channels.

Claude Code sessions communicate through MCP servers that act as shared communication infrastructure. This is what MCP was designed for: standardized, bidirectional, stateful connections between AI agents and services.

### Five Communication Channels

**Channel A: MCP Communication Hub (The Primary Channel)**

A shared MCP server acts as the communication "patch panel" for all active sessions. Every Claude Code session connects to the same MCP server and uses it for:

- **Agent registration**: Sessions announce themselves (name, type, current task, capabilities)
- **Agent discovery**: Sessions query who else is active and what they're working on
- **Direct messaging**: Structured messages between specific sessions (findings, questions, status updates)
- **Broadcast**: Team-wide announcements (goal changes, blockers, drift alerts)
- **State queries**: "What is the current session state?" "What findings are open?"

This can be implemented using existing tools like [Agent-MCP](https://github.com/rinadelph/Agent-MCP), which already provides direct messaging, broadcast, and shared knowledge graph access as MCP tools. Alternatively, a purpose-built lightweight MCP server could expose exactly the tools we need.

Example interaction via MCP tools:
```
# Worker session registers itself
→ register_agent(name: "worker-1", type: "implementation", task: "task-001-auth-fix",
                 worktree: "../unamentis-kb-voice/")

# Quality session discovers active workers
→ list_agents(type: "implementation")
← [{name: "worker-1", task: "task-001-auth-fix", status: "implementing"}]

# Quality session sends a finding to worker-1
→ send_message(to: "worker-1", type: "finding", severity: "architectural",
               component: "KBOralSessionView",
               finding: "New service protocol diverges from established DI pattern",
               rationale: "Existing pattern injects via init. This creates inline.",
               suggestion: "Refactor to match TTSService.swift:23-45")

# Worker session checks for messages
→ get_messages(for: "worker-1", status: "unread")
← [{from: "quality", type: "finding", severity: "architectural", ...}]

# Worker acknowledges and responds
→ send_message(to: "quality", type: "response", ref: "finding-001",
               status: "acknowledged", plan: "Will refactor in next commit")

# Quality session sends a vision-tier finding (highest severity, work stops)
→ send_message(to: "worker-1", type: "finding", tier: "vision",
               severity: "vision_conflict",
               standard: "hands_free_first_design",
               finding: "New 'tap to confirm' button violates hands-free first requirement",
               rationale: "HANDS_FREE_FIRST_DESIGN.md: All state transitions must have voice alternatives",
               action: "MUST resolve before proceeding. Voice alternative required.")

# Agent proposes an architecture-tier change (requires human approval)
→ send_message(to: "orchestrator", type: "change_proposal", tier: "architecture",
               standard: "performance_latency_target",
               current: "E2E latency <500ms median",
               proposed: "E2E latency <400ms median for voice commands specifically",
               rationale: "Voice command recognition needs tighter targets than general E2E")
```

Every finding includes a `tier` field so that recipients immediately know the severity hierarchy: vision findings override everything, architectural findings require resolution before proceeding, quality findings are routine.

**Why MCP over filesystem for primary communication**: MCP provides typed tool interfaces (not free-text files), real-time availability (not polling), bidirectional push notifications, and structured state management. The MCP protocol is already Claude Code's native language for tool interaction. Using it for inter-agent communication means agents use the same interface they use for everything else.

**Channel B: Persistent Memory (MCP-backed)**

Separate from the communication hub, a dedicated MCP memory server provides institutional knowledge. This is detailed in Section 5 (Memory Architecture) but listed here as a communication channel because agents reading and writing to shared memory IS a form of asynchronous, persistent communication.

Existing options include Anthropic's [Knowledge Graph Memory](https://github.com/modelcontextprotocol/servers/tree/main/src/memory) server and [mcp-memory-service](https://github.com/doobidoo/mcp-memory-service) for semantic persistent context.

**Channel C: Git as Code State Protocol**

For code-level coordination, git remains the right tool:
- Workers stage changes on feature branches. The quality session reviews diffs.
- Branch naming conventions signal intent: `task/001-auth-fix`, `review/001-auth-fix`.
- The orchestrator session can examine branch state to understand progress.
- Git's built-in conflict detection handles the case where two workers touch the same file.
- Git is the transaction log: every code change is versioned and reversible.

**Channel D: Structured Files (Artifacts and Archives)**

Some content is naturally suited to files: task briefs, research reports, architecture reviews, and other artifacts that benefit from version control, human readability, and persistence independent of any running service:

```
.claude/collab/
├── session-state.md          # Current goals, progress, blockers
├── task-briefs/              # Task assignments for worker sessions
│   ├── task-001-auth-fix.md
│   └── task-002-test-coverage.md
└── artifacts/                # Larger documents, reports, plans
    ├── architecture-review.md
    └── research-brief.md
```

Task briefs and larger artifacts (research reports, architecture reviews) are better as files: they're version-controlled, human-readable, and don't need real-time delivery. But operational communication (findings, status updates, messages) should flow through the MCP hub.

**Channel E: Headless Queries (Quick Synchronous Exchange)**

When the orchestrator needs a quick answer from a specialized perspective:

```bash
claude -p "Given this diff, identify any architectural pattern violations against our DI convention" \
  --output-format json
```

This is a synchronous tool call, similar to invoking a linter. Use it for quick, scoped questions, not for sustained work.

### The Protocol-First Principle

Research is emphatic: structured protocols beat unstructured chat for multi-agent coordination. In our case:
- **Every inter-agent message is a structured object** with typed fields, delivered through MCP tool calls or structured documents.
- **The MCP hub is the primary message bus.** Real-time, typed, bidirectional.
- **The filesystem handles artifacts and briefs.** Auditable, version-controlled, human-readable.
- **Git is the code state transaction log.** Every code change is versioned and reversible.
- **No free-text chat between agents.** All communication uses schemas, whether via MCP tools or structured files.

---

## 4. Orchestration: State Management Through MCP and Git

Research identifies checkpoint-resume, loop detection, and strict state schemas as the critical patterns for multi-agent orchestration. Our platform implements these through a combination of MCP state management, git checkpoints, and Claude Code's session resume.

### What Research Says Matters Most

The research identifies three capabilities that determine whether multi-agent orchestration succeeds or fails:

1. **The Resume Button**: If you cannot pause mid-task, fix a state variable, and resume, the system is not viable. Claude Code's session resume (`--resume <session_id>`) provides this natively.

2. **Loop Detection**: Without circuit breakers to detect infinite loops (trying the same fix 50 times), agents consume infinite resources. Claude Code's token budget per session provides a natural ceiling, but explicit loop detection must be built into task briefs and quality session monitoring.

3. **Strict State Schemas**: Relying on natural language for state management is a failure point. The MCP communication hub enforces this: status is typed MCP tool calls and structured data, not prose.

### Session State as Checkpoint-Resume

We use a combination of the MCP communication hub (live state), git (code state), and structured files (human-readable snapshots):

```yaml
# .claude/collab/session-state.md
session_id: "2026-01-28-kb-feature"
started: "2026-01-28T09:00:00Z"
goals:
  - id: G1
    description: "Implement hands-free voice navigation for KBOralSessionView"
    acceptance_criteria:
      - "All voice commands recognized with >95% accuracy"
      - "Zero UI taps required during oral practice session"
      - "VoiceOver compatible"
    status: in_progress
  - id: G2
    description: "Achieve 80% test coverage for voice module"
    status: pending
current_phase: "implementation"
active_workers:
  - session: "worker-1"
    worktree: "../unamentis-kb-voice/"
    task: "task-001"
    status: "implementing voice command recognizer"
  - session: "quality"
    task: "continuous review"
    status: "monitoring worker-1 output"
checkpoints:
  - id: CP1
    timestamp: "2026-01-28T10:30:00Z"
    description: "Voice command protocol defined and tested"
    git_ref: "abc1234"
blockers: []
drift_notes: []
```

**Checkpoint creation**: After each meaningful unit of work, the orchestrator (human + primary session) updates `session-state.md` and tags the git state. If something goes wrong, you can reset to any checkpoint's `git_ref`.

**Drift detection**: The quality session periodically reads `session-state.md`, compares it to what workers are actually producing, and writes drift alerts to `findings/`. Research confirms that drift detection (goal drift, context drift) is essential for sessions lasting more than 30 minutes.

### Model Routing: Capability First, Speed as a Bonus

With Claude Code Max (200 plan), the constraint is not cost per token but rate limits and session quality. The governing principle: **never downgrade model capability for the sake of speed or token budget.** Opus 4.5 is the default for anything that requires judgment, reasoning, or could benefit from deeper understanding. Sonnet 4.5 is appropriate when a task is genuinely routine and speed is an advantage. Haiku is reserved for purely mechanical operations where the task is so well-defined that any model would produce the same output.

**The Decision Rule**: If there is any doubt about whether a task needs Opus, use Opus. The cost of using Opus on a routine task is negligible (slightly slower). The cost of using Sonnet on a task that needed Opus is real (missed issues, shallow reasoning, architectural drift).

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| Orchestrator session | Opus 4.5 | Strategic decisions, cross-session coordination, judgment calls |
| Quality session | Opus 4.5 | Vision enforcement and architectural review require deep reasoning. The quality session must catch subtle issues that cheaper models miss. |
| Complex code generation | Opus 4.5 | Novel implementations, architectural decisions, anything touching established patterns |
| Routine code generation | Opus 4.5 or Sonnet 4.5 | Sonnet when the task is well-defined and follows an established pattern exactly. Opus when there's any ambiguity. |
| Code review | Opus 4.5 | Judgment-intensive. Must evaluate vision alignment and architectural conformance, not just syntax. |
| Fast exploration, search | Sonnet 4.5 (via Explore subagent) | Speed is the advantage here. Exploration is about breadth, not depth. |
| Documentation, formatting | Sonnet 4.5 | Routine, well-defined, low judgment required |
| Headless quick queries | Sonnet 4.5 | Latency-sensitive, narrowly scoped, clear expected output |
| Mechanical operations | Haiku | Purely mechanical tasks with unambiguous instructions: defined file set + defined transformation. Example: renaming a symbol across known files, applying a formatting rule. Only when any model would produce identical output. |

**Session defaults**: The orchestrator and quality sessions always run Opus 4.5. Worker sessions default to Opus 4.5 and may be set to Sonnet 4.5 when the orchestrator determines the task is routine. Subagents inherit their parent's model unless explicitly overridden (Explore subagents default to faster models for speed). Haiku is never a session default; it is only used for specific subagent tasks where the operation is mechanical.

---

## 5. Memory Architecture: MCP-Backed Institutional Knowledge

Research is clear that simple vector storage (dump everything, semantic search) fails for code development. The problems:
- No temporal reasoning (which snippet is the latest valid one?)
- No relational context (what depends on what?)
- "Context clutter" as similar-looking but outdated information pollutes retrieval

The solution is structured, actively curated memory. And crucially, MCP memory servers already exist that provide persistent knowledge graphs, semantic search, and multi-session shared access, all usable from Claude Code without API keys.

### The Memory Stack: MCP + Files (Hybrid)

The memory architecture uses two layers:

**Layer 1: MCP Knowledge Graph (Active, Queryable Memory)**

An MCP memory server provides the live, queryable memory layer. All sessions connect to the same server and access the same knowledge graph. Candidates:

- **Anthropic's [Knowledge Graph Memory](https://github.com/modelcontextprotocol/servers/tree/main/src/memory)**: Entities, relations, and observations in a persistent JSONL-backed graph. Tools for creating, searching, and traversing. Lightweight, zero infrastructure.
- **[mcp-memory-service](https://github.com/doobidoo/mcp-memory-service)**: Semantic search over persistent context with 5ms response times. SQLite-backed. Multi-session sharing is the core design. Knowledge graph visualization. Quality scoring for memory retention.
- **[graph-mem-mcp](https://github.com/arnokamphuis/graph-mem-mcp)**: Graph memory with relevance scoring and semantic search. More advanced graph traversal.

The MCP knowledge graph stores:
- **Entities**: Components, services, patterns, decisions, problems, vision standards, architectural standards
- **Relations**: "depends_on", "implements_pattern", "was_fixed_by", "rejected_in_favor_of", "governed_by", "follows_pattern"
- **Observations**: Atomic facts attached to entities (timestamps, outcomes, rationale, protection tier, mutability)

Every entity carries a `protection_tier` observation that encodes its position in the oversight hierarchy (see Section 2):
- `protection_tier: vision` / `mutability: human_only` for vision standards
- `protection_tier: architecture` / `mutability: human_approved_only` for architectural standards and established components
- `protection_tier: quality` / `mutability: automated` for quality rules

Example interactions via MCP tools:
```
# Record a vision standard (Tier 1, immutable by agents)
→ create_entities([{name: "hands_free_first_design", entityType: "vision_standard",
    observations: ["protection_tier: vision",
                   "mutability: human_only",
                   "source_document: docs/design/HANDS_FREE_FIRST_DESIGN.md",
                   "Voice is PRIMARY interaction mode within activities",
                   "All voice-centric activities must support 100% hands-free operation",
                   "IMMUTABLE BY AGENTS. Only human can modify vision standards."]}])

# Record an architectural component (Tier 2, human-approved changes only)
→ create_entities([{name: "KBOralSessionView", entityType: "component",
    observations: ["protection_tier: architecture",
                   "mutability: human_approved_only",
                   "Uses protocol-based DI via init injection",
                   "Established 2026-01-10 over 3 sessions",
                   "GUARD: Fix targeted, don't rewrite. Architecture is intentional."]}])

# Record relationships (architecture tier + vision governance)
→ create_relations([{from: "KBOralSessionView", to: "ServiceRegistry",
    relationType: "follows_pattern"},
   {from: "KBOralSessionView", to: "hands_free_first_design",
    relationType: "governed_by"}])

# Query before modifying a component (returns protection tier + vision governance)
→ search_nodes("KBOralSessionView")
← {entities: [{name: "KBOralSessionView",
    observations: ["protection_tier: architecture", ...],
    relations: [{to: "ServiceRegistry", type: "follows_pattern"},
                {to: "hands_free_first_design", type: "governed_by"}, ...]}]}

# Record a troubleshooting outcome
→ add_observations("STT_audio_drop_problem",
    ["Circular buffer with fixed cap + graceful degradation: SUCCESS",
     "Retry with backoff: partial fix only, added latency",
     "Unbounded pre-buffer: FAILED, memory pressure"])
```

**Why MCP over flat files for active memory**: Semantic search finds relevant knowledge even when the agent doesn't know the exact key. Graph traversal reveals relationships (what depends on what). Multi-session sharing means the quality session and worker sessions see the same memory simultaneously without file-locking issues. And existing MCP servers already implement all of this.

**Layer 2: Structured Files (Archival, Human-Readable Memory)**

Some memory is better as files: version-controlled, human-reviewable, and readable without an MCP server running.

```
.claude/collab/memory/
├── architectural-decisions.md   # ADR-style decision log (human-curated)
├── troubleshooting-log.md       # Append-only problem/attempt/outcome log
└── solution-patterns.md         # Curated patterns extracted from experience
```

These files serve as:
- **Bootstrap data** for populating the MCP knowledge graph at session start
- **Human-readable archive** that survives independent of any MCP server
- **Version-controlled history** (git tracks changes to memory over time)

The relationship between the two layers: The MCP knowledge graph is the live, queryable interface agents use during work. The structured files are the durable, human-readable archive. The quality session syncs between them: promoting important graph entries to files, and ensuring file-based decisions are reflected in the graph.

### Three Memory Types (Stored in Both Layers)

**1. Architectural Memory (Long-term, Project-scoped)**

Purpose: Protect architectural decisions and significant work from being casually rewritten. Research calls this "Architecture Destruction" prevention.

In the knowledge graph: Components as entities with observations about their architecture, effort invested, and guard notes. Relations map dependencies and pattern adherence.

In files: `architectural-decisions.md` as a structured ADR (Architecture Decision Record) log.

Example graph entry:
```
Entity: KBOralSessionView
  Type: component
  Observations:
    - "protection_tier: architecture"
    - "mutability: human_approved_only"
    - "Protocol-based DI via init injection"
    - "Established 2026-01-10, significant effort (3 sessions)"
    - "GUARD: Fix targeted, don't rewrite. Architecture is intentional."
  Relations:
    → follows_pattern: ServiceRegistry
    → follows_pattern: protocol_based_di_pattern
    → depends_on: KBOnDeviceSTT
    → depends_on: VoiceCommandRecognizer
    → governed_by: hands_free_first_design
```

The `governed_by` relation links this component to the vision standard it must honor. The `protection_tier` observation tells any agent querying this entity that architectural changes require human approval.

**2. Troubleshooting Memory (Medium-term, Problem-scoped)**

Purpose: When a problem recurs, know what was tried before. Research validates this as the "Librarian" pattern.

In the knowledge graph: Problems as entities, with observations for each attempt and its outcome. Relations link problems to components and successful fixes.

In files: `troubleshooting-log.md` as an append-only structured log.

Example graph entry:
```
Entity: STT_audio_drop_during_network_transition
  Type: problem
  Observations:
    - "First seen 2026-01-12 in KBOnDeviceSTT"
    - "Attempt 1: Retry w/ exponential backoff → partial (60% reduction, latency spikes)"
    - "Attempt 2: Pre-buffer during transition → FAILED (unbounded buffer, memory kill)"
    - "Attempt 3: Circular buffer, fixed cap, graceful degradation → SUCCESS"
    - "Key insight: Buffer management problem, not retry problem"
  Relations:
    → affects: KBOnDeviceSTT
    → fixed_by: circular_buffer_pattern
```

**3. Solution Memory (Long-term, Pattern-scoped)**

Purpose: Recognize when a current situation matches a previously-solved class of problem.

In the knowledge graph: Patterns as entities, with observations about when they apply and how to implement them. Relations link patterns to components that exemplify them.

In files: `solution-patterns.md` as a curated pattern catalog.

Example graph entry:
```
Entity: provider_protocol_pattern
  Type: solution_pattern
  Observations:
    - "Applies when: Adding new STT, TTS, LLM, or Embeddings provider"
    - "Steps: 1) Define protocol, 2) Implement, 3) Register in ServiceRegistry, 4) Integration test"
    - "Reference implementation: TTSService.swift"
  Relations:
    → exemplified_by: TTSService
    → exemplified_by: STTService
    → used_in: KBOralSessionView
```

### Memory Lifecycle: The "Librarian" Principle

Research is emphatic: if the system just dumps everything into memory ("digital hoarding"), retrieval quality collapses. Active curation is essential.

In our system, the quality session acts as the Librarian:
- After each work session, it reviews what happened and updates the knowledge graph
- It consolidates observations (multiple attempts on the same problem become one coherent entry)
- It promotes recurring troubleshooting patterns to solution memory
- It flags stale entries and removes obsolete observations
- It syncs important graph entries to the archival files
- It does NOT save everything. Failed approaches are noted briefly; successful patterns get detailed entries.
- **It validates protection tiers remain consistent.** Vision-tier entities are never modified by agents. Architecture-tier entities are only updated when the Librarian receives confirmation of a human-approved change. If a tier violation is detected (an agent modified a vision entity, or changed an architecture entity without approval), the Librarian reverts the change and alerts the human.
- **It reconciles the knowledge graph with source documents.** Each entity's `source_document` observation points to its authoritative file. The Librarian periodically checks that graph entries and source documents are in sync, catching drift in either direction.

### Memory Consultation Protocol

Every session's startup procedure should include:
1. Query the knowledge graph for `vision_standard` entities that govern the task's components (Tier 1 check)
2. Query for `architectural_standard` and `component` entities related to the current task, noting their `protection_tier` and established patterns (Tier 2 check)
3. Check for solution patterns that match the task type
4. If the task involves a component with troubleshooting history, review those entries
5. Quality session queries all memory across all tiers and actively references it during review, applying the three-lens model (vision first, architecture second, quality third)

This is implemented through session-specific CLAUDE.md files or skill prompts that instruct the session to consult memory before starting work. Because the memory is accessed via MCP tools, it integrates naturally into the agent's workflow: querying memory is just another tool call, indistinguishable from querying a linter or reading a file.

---

## 6. Mutual Confidence: Earned Trust Through Verification

Research is unambiguous: "blind trust" between agents leads to catastrophic error propagation. One hallucinating agent can pollute the context of five others. But research also shows that LLMs are terrible at self-assessing their own confidence: "Verbalized Confidence" (asking "Are you sure?") is unreliable.

### The Zero-Trust-with-Verification Model

Trust is established through a hierarchy of verification mechanisms:

**a) Deterministic Verification (The Primary Trust Mechanism)**

The most reliable trust signal is not another LLM's opinion but a compiler, linter, or test suite. Research rates deterministic verification as "Very High" reliability at "Low" cost.

- Code must compile before review
- Lint must pass before review
- Tests must pass before merge
- Coverage must meet threshold before marking complete
- The `/validate` skill is the embodiment of this principle

**b) Track Record (Observable Outcomes)**

Each agent-to-agent interaction has an observable outcome. The quality session tracks these in memory:
- Was the architectural concern legitimate? (11/12 = high trust)
- Did the suggested fix work? (8/10 = good track record)
- Were the pattern suggestions relevant? (varies by domain)

This is not a numeric score displayed to agents. It is context that informs how the orchestrator allocates work and how much scrutiny to apply.

**c) Explanation Quality (Show Your Work)**

Research validates that findings with project-specific rationale carry more weight than generic lint rules:
- HIGH confidence: "This force unwrap is dangerous because KBOralSessionView can receive nil from the STT pipeline during network transitions"
- LOW confidence: "Force unwrapping should be avoided"

The quality session's findings must always include rationale tied to this specific codebase, not generic best practices.

**d) Proportional Response (Calibrated Scrutiny)**

Research identifies "alert fatigue" as a system killer. The quality system must calibrate:

| Severity | Tier | Response | Channel |
|----------|------|----------|---------|
| Vision conflict | T1 | **Work stops.** Must conform to vision. Escalate to human if ambiguous. | MCP message + human notification |
| Security | T2/T3 | Immediate escalation to human | MCP message + human notification |
| Architectural | T2 | Direct dialogue, requires resolution before proceeding | MCP message + orchestrator alert |
| Logic | T3 | Finding with rationale, blocks task completion | MCP message |
| Style | T3 | Note via MCP hub, no urgency | MCP message |
| Formatting | T3 | Auto-fix silently | Hook (PostToolUse) |

An agent that treats everything as critical loses the dev agent's confidence quickly.

### Circuit Breakers (External Safety)

Research identifies circuit breakers as essential: automated safeguards that operate outside the LLM context.

The platform provides multiple layers of circuit breakers:
- **Hooks**: PreToolUse hooks that block dangerous operations (mass file deletion, dropping databases)
- **Git guards**: Pre-commit hooks that enforce quality gates
- **MCP monitoring**: The quality session monitors worker status via the MCP hub and can broadcast halt signals
- **Token budgets**: Natural session limits prevent infinite loops (explicit loop detection in task briefs adds a second layer)
- **The human**: Always in the loop at the orchestrator level. Can intervene in any session.

---

## 7. Extended Session Coherence: How to Work for Hours

This is the ultimate goal. Research identifies "Context Drift" and "Goal Drift" as primary failure modes for long-running sessions. The context window fills with irrelevant history, the model's attention degrades ("getting lost in the middle"), and the agent's objective gradually shifts.

### Five Mechanisms

**a) Session Goals + Acceptance Criteria (Set Once, Reference Always)**

At session start, the orchestrator writes `session-state.md` with explicit goals and acceptance criteria. Every agent can reference these. When the quality agent pushes back, it is grounded in: "this doesn't meet acceptance criterion #3," not "I think this could be better."

Research validates that explicit, deterministic criteria (tests pass, coverage met, build succeeds) are more effective anchors than subjective goals.

**b) Checkpoint-Resume via Git**

After each meaningful unit of work (feature complete, test passing, module done), the orchestrator:
1. Stages all changes
2. Updates `session-state.md` with checkpoint entry
3. Tags the git state: `git tag checkpoint/CP1`

If a session drifts, crashes, or loses context, work resumes from the last checkpoint. Claude Code's native session resume (`--resume`) handles conversation context; git handles code state. Together, they provide the "time-travel debugging" that research identifies as critical.

**c) Drift Detection**

The quality session monitors for drift signals:
- **Time drift**: Worker has been on a single task exceeding threshold without progress (measurable by git diff activity)
- **Loop drift**: Repeated failures on the same issue (the "doom spiral" research warns about)
- **Scope drift**: Worker producing artifacts not related to session goals
- **Quality drift**: New findings accumulating faster than they're resolved

On drift detection: the quality session sends a drift alert through the MCP communication hub, targeting both the affected worker and the orchestrator. The orchestrator intervenes, redirecting the worker, suggesting a different approach, or escalating to the human.

Research specifically recommends "Supervisor nodes" that periodically check semantic similarity between current activity and original goals. In our system, the quality session fulfills this supervisor role.

**d) Context Hygiene**

Context is a finite resource. Claude Code's auto-compaction helps but is not sufficient for multi-hour sessions.

Proactive measures:
- **Session segmentation**: Break long tasks into phases. Start new sessions for new phases, carrying forward only a structured brief (not full conversation history). Research (Goose framework) recommends creating new sessions for distinct tasks to prevent doom spiraling.
- **Subagent delegation**: Verbose operations (exploring a large codebase, running extensive tests) should be delegated to subagents. Their output stays in their context; only the summary returns to the parent.
- **Structured summaries**: Between phases, use `/compact` with explicit instructions about what to preserve.
- **Scoped context per specialist**: Don't send full session history to a linter or a quick headless query. Send only the relevant diff or file.

**e) Progressive Confidence**

As the session progresses and more work passes quality checks, the system builds momentum:
- Early in a session: more frequent quality checks, more dialogue
- Mid-session with good track record: lighter touch, trust the dev agent more
- Late session or after regressions: increase scrutiny

Research validates this adaptive intensity as essential for preventing alert fatigue while maintaining safety.

---

## 8. The Enabling Role: Making Dev Agents Better (Not Just Policing Them)

Research into Human-AI collaboration strongly favors the "Augmentation" model over the "Replacement" model. The quality system's primary purpose is making the dev agent produce better work than it would alone.

### The Driver-Navigator Dynamic

Research adapts pair programming's Driver-Navigator pattern:
- **Agent as Navigator**: The human writes core logic, while the Agent suggests strategies, looks up documentation, spots potential bugs.
- **Agent as Driver**: The Agent generates code under strategic direction from the human.
- **Role Fluidity**: The human should be able to switch between these roles fluidly.

In our system, this manifests as:
- Worker sessions drive (generate code) while the quality session navigates (provides pattern guidance, catches issues)
- The human orchestrator can switch any session from driving to navigating as needed
- The quality session proactively offers pattern memory and architectural guidance, not just reactive checking

### Four Concrete Enabling Mechanisms

**a) Pattern Memory (Proactive Guidance)**
"In this codebase, new services always implement the protocol pattern. Here's an example from TTSService." This is proactive guidance, not reactive checking. The quality session consults solution memory and offers relevant patterns before the worker starts, not after it finishes.

**b) Architectural Guardrails as Navigation Aids**
Instead of "you violated the layer boundary," the message is: "The pattern in this codebase for accessing the data layer from a view model is through the ServiceRegistry. Here's how SessionManager does it." The quality system acts as institutional memory of the codebase.

**c) Suggestion, Not Just Rejection**
When a finding requires a non-obvious fix, the quality agent suggests HOW, not just WHAT. "This cyclomatic complexity of 15 could be reduced by extracting the retry logic into a shared RetryPolicy, similar to what exists in NetworkService.swift:45."

Research calls this the "Diff-based interaction" principle: humans (and agents) are better at reviewing suggested changes than generating fixes from abstract feedback.

**d) Coaching Over Replacement**
Research warns about "Vibe Coding," where agents generate code that looks correct but is architecturally unsound. To prevent this:
- The quality session explains WHY patterns exist, not just enforcing them
- Troubleshooting memory records WHY approaches failed, teaching future sessions
- The system documents its work, maintaining human understanding of the codebase

---

## 9. Cost, Security, and Systemic Risk

Research identifies three "invisible killers" that vision documents typically ignore: cost, security, and cascading failures. Claude Code Max changes the cost equation significantly (flat subscription vs per-token billing), but the other risks remain.

### Cost Management

With Claude Code Max, we do not pay per token. This removes the acute risk of "infinite loop = massive bill" that research warns about. However, token consumption still matters:
- Context windows fill, causing compaction and information loss
- Long sessions degrade in quality regardless of cost
- Parallel sessions consume the subscription's rate limits

**Mitigation**: Session segmentation (new sessions for distinct tasks), subagent delegation (keeps verbose work out of main context), and explicit task scoping (time and scope limits in task briefs).

### Security: Sandboxing and Least Privilege

Research identifies "Indirect Prompt Injection" as a critical risk for agents with tool access. In our context:
- Claude Code runs with the developer's filesystem permissions. A compromised session could read/write anything the developer can.
- Multiple sessions amplify the attack surface.

**Mitigations already in place**:
- Claude Code's built-in permission system (asks before destructive operations)
- Hooks for PreToolUse validation (block dangerous patterns)
- Git as a safety net (any change is reversible)
- The human orchestrator provides oversight

**Additional mitigations for this system**:
- Worker sessions should use worktrees (isolation from main branch)
- Quality session should be read-focused (it reviews, it doesn't write production code)
- Task briefs should explicitly scope what a worker session is allowed to modify
- Never give a session secrets (API keys, credentials) it doesn't need

### Failure Cascades: The Cogwheel Effect

Research describes the "Cogwheel Effect": if the Planner hallucinates a file that doesn't exist, the Coder fails, the Tester fails, and the Manager panics and restarts the loop.

In our architecture, this risk is mitigated by:
- **Deterministic verification at every stage**: Code must compile before it is reviewed. Tests must pass before work is marked complete.
- **Independent sessions**: A worker session's hallucination is contained within its worktree. It cannot corrupt the main branch without the orchestrator staging and committing.
- **Quality session as independent verifier**: Research says "never let the author verify their own work." The quality session reviews worker output with fresh eyes.
- **Git as the circuit breaker**: Any change can be reverted. Checkpoints provide known-good states.

### Observability

Research emphasizes that you cannot optimize what you cannot see. For debugging cascading failures, you need to trace the full execution graph.

In our system, observability comes from:
- **MCP communication hub**: Every session's registration, status updates, and messages are queryable in real time
- **MCP knowledge graph**: Decisions, outcomes, and patterns are recorded as structured entities and relations
- **Git history**: Every code change is tracked with context
- **Session transcripts**: Claude Code stores conversation history locally
- **Log server integration**: The existing log server (port 8765) captures runtime behavior
- **The `/debug-logs` skill**: Already provides structured debugging workflow

---

## 10. Specialist Routing: Best-in-Class Per Domain

**Capability Registry**: Each specialist declares what it's good at and how good it is.

```yaml
specialists:
  - id: swiftlint
    domains: [swift, ios]
    capabilities: [lint, style]
    strength: high  # well-tuned for this project's .swiftlint.yml

  - id: ruff
    domains: [python]
    capabilities: [lint, style, security]
    strength: high

  - id: coderabbit
    domains: [all]
    capabilities: [review, architecture, patterns]
    strength: high
    type: external  # consumed via MCP wrapper
    latency: async  # returns minutes later, not seconds

  - id: clippy
    domains: [rust]
    capabilities: [lint, correctness, performance]
    strength: high

  - id: generic-llm-reviewer
    domains: [all]
    capabilities: [review, architecture, patterns]
    strength: medium  # good generalist, not as deep as specialists
    latency: sync
```

**Routing logic** (in the orchestrator or quality session):
1. Determine the domain of the work (Swift? Rust? Cross-cutting architecture?)
2. Determine the type of quality concern (lint? architectural pattern? security? test coverage?)
3. Route to the highest-strength specialist for that (domain, concern) pair
4. If async specialists are available and time permits, dispatch to them in parallel
5. If no specialist exists, fall back to the generalist

**External service integration**: CodeRabbit, for example, is wrapped in an MCP server that:
- Accepts a diff or file set
- Calls CodeRabbit's API programmatically
- Parses the structured review output (not the human-readable PR comment)
- Returns findings in the same format as internal specialists
- The quality system consumes this identically to an internal specialist's output

**Simplicity check (P5)**: Start with a static YAML registry. Only add dynamic capability discovery if the number of specialists grows beyond what's manageable in a config file.

---

## 11. What We Don't Build vs. What We Adopt (Simplicity Vector)

Applying P5 rigorously, but equally rigorously avoiding the trap of under-building: a system that is too constrained to be effective is worse than no system at all.

### What We Adopt (Existing MCP Tools)

| Capability | Approach | Why Adopt, Not Build |
|------------|----------|---------------------|
| Inter-agent communication | MCP communication hub (Agent-MCP or purpose-built) | Existing tools already provide agent registration, messaging, and discovery as MCP servers. Building our own file-polling system would be inferior. |
| Knowledge graph memory | Anthropic's Knowledge Graph Memory MCP or mcp-memory-service | Production-ready, multi-session shared access, semantic search. Writing YAML files by hand is not a viable long-term memory system. |
| Agent discovery/registry | MCP Gateway & Registry or lightweight custom registration | Sessions need to know who else is active. Static config doesn't work for dynamic session counts. |

### What We Don't Build

| Idea | Verdict | Reasoning |
|------|---------|-----------|
| LangGraph / AutoGen / CrewAI as orchestrators | Skip | Requires API keys to call LLMs. Incompatible with Claude Code Max. |
| Agent SDK multi-agent pipelines | Skip | Requires API keys. Claude Code's built-in subagents + parallel sessions + MCP servers cover our needs. |
| Kafka / Redis event bus | Skip | Overkill for 1-4 agents on a single machine. MCP servers with HTTP transport handle our concurrency needs. |
| A2A protocol / Agent Cards | Skip (for now) | MCP-based agent registration and discovery is sufficient for <10 agents. A2A is for internet-scale agent meshes. |
| Custom vector database infrastructure | Skip | MCP memory servers with semantic search already exist. No need to operate Pinecone/ChromaDB infrastructure. |
| Quantified confidence scores | Skip | Research shows the field hasn't solved LLM self-assessment. Use structural trust (deterministic verification, track record, explanation quality) instead of numeric scores. |
| Full peer-review debate architecture | Simplify | Don't need formal FIPA-ACL performatives or "author/reviewer/editor" roles. Structured messages through MCP hub achieve the same effect with less ceremony. |
| W3C agent standards | Too early | Standards expected 2026-2027. Build on MCP now, adopt standards when they mature. |
| Dynamic capability discovery | Skip (for now) | Static YAML registry plus MCP-based agent registration is sufficient until the specialist count demands more. |
| Cryptographic agent reputation (ERC-8004) | Skip | We're not a decentralized marketplace. Track record in the knowledge graph is sufficient. |
| Consistency sampling (N-times inference) | Skip | Expensive and unnecessary when deterministic verification (tests, linters) provides higher reliability at lower cost. Reserve for future expansion. |

### The Decision Principle

Before building anything custom, ask: "Does an MCP server already exist that does this?" If yes, evaluate it. The MCP ecosystem is growing rapidly (dozens of new memory and coordination servers in late 2025 and early 2026). Adopting a well-maintained MCP server beats building an inferior custom solution every time. Building custom is only justified when no existing server fits our specific needs AND the capability is critical enough to warrant the maintenance burden.

---

## 12. Implementation Approach: Start Small, Validate, Expand

Research's strongest recommendation: "Build the harness first." The state management, memory, and safety infrastructure must be solid before scaling up agent count.

### Phase 1: Foundation (MCP Infrastructure + Single Worker)

Stand up the MCP communication and memory infrastructure, then validate with a single worker + quality session:

1. **Evaluate and select MCP servers**: Test Knowledge Graph Memory, mcp-memory-service, and Agent-MCP (or alternatives) in Claude Code. Determine which servers work reliably with Claude Code Max and our project structure.
2. **MCP communication hub**: Set up the communication server. Test agent registration, messaging, and discovery between two Claude Code sessions.
3. **MCP knowledge graph**: Set up the memory server. Populate with initial architectural decisions and component metadata from the existing codebase.
4. **Directory structure**: Create `.claude/collab/` for task briefs, artifacts, and archival memory files.
5. **Quality session setup**: Create a quality-focused CLAUDE.md and skills for the dedicated quality session, including instructions to consult the knowledge graph.
6. **Validation**: Run a single task through the full cycle: brief -> implement -> review via MCP messaging -> findings -> fix -> validate.

Success criteria: One task completed through the full cycle with MCP-mediated communication and memory, demonstrating that the infrastructure works end-to-end.

### Phase 2: Memory Depth

Build out institutional memory with tier-aware protection and validate it prevents known failure modes:

1. **Vision-tier memory population**: Add vision standards to the knowledge graph as `vision_standard` entities with `mutability: human_only`. Link components to the vision standards that govern them via `governed_by` relations.
2. **Architecture-tier memory population**: Systematically add all established components, patterns, performance targets, and conventions as entities with `protection_tier: architecture` and `mutability: human_approved_only`.
3. **Troubleshooting memory**: Start logging problems, approaches, and outcomes as they occur
4. **Solution memory**: Extract generalized patterns from troubleshooting entries and promote to the graph
5. **Memory consultation protocol**: Add tier-aware memory querying to session startup procedures (via CLAUDE.md instructions). Sessions query vision-tier entities first, then architecture-tier, then solution patterns.
6. **Vision protection test**: Verify that the quality session, given work that conflicts with a vision standard, raises a `vision_conflict` finding and stops work until the human resolves it.
7. **Architecture protection test**: Verify that the quality session, armed with knowledge graph context, prevents destructive rewrites of established components and detects ad-hoc pattern drift.

Success criteria: (a) A worker session whose work conflicts with the voice-first design is stopped by a vision-tier finding. (b) A worker session touching an established component queries the knowledge graph, discovers the established pattern, and follows it rather than reinventing.

### Phase 3: Multi-Session Coordination

Scale to parallel workers:

1. **Worktree-based isolation**: Workers operate in separate worktrees
2. **Agent registry**: All workers register via MCP hub. The orchestrator can query who's active and what they're working on.
3. **Cross-session communication**: Test quality session sending findings to workers via MCP messaging, workers acknowledging and responding.
4. **Drift detection**: Quality session monitors all workers via MCP status queries and code diffs.
5. **Checkpoint-resume**: Test checkpoint creation and resumption after simulated failures.

Success criteria: Two workers operating in parallel on related tasks, coordinated through MCP messaging, with the quality session providing cross-cutting review and the orchestrator maintaining visibility via the MCP hub.

### Phase 4: Extended Sessions

Push toward the hours-long session goal:

1. **Context hygiene protocols**: Session segmentation, subagent delegation, structured summaries
2. **Progressive confidence**: Adaptive scrutiny levels based on track record stored in the knowledge graph
3. **Session continuity**: Multi-day work with resume, knowledge graph carrying memory forward across session boundaries
4. **Librarian curation**: Quality session actively curates the knowledge graph, consolidating entries, promoting patterns, removing stale data
5. **Measurement**: Track session duration, drift incidents, memory utilization, and quality metrics over time

Success criteria: A 2+ hour coordinated session that maintains quality and goal alignment throughout, with the knowledge graph providing continuous institutional memory.

---

## Lessons from PocketTTS: The Embryonic Pattern

The PocketTTS project already implements a crude but effective version of multi-agent collaboration that informed this vision.

### What Works Well

1. **Fresh Eyes Principle**: Each agent runs in a completely fresh session. This prevents confirmation bias and tunnel vision. The Research Advisor starts by re-reading everything rather than inheriting stale assumptions.

2. **Artifact-Based Communication**: Agents talk through files (`docs/audit/`), not real-time chat. Reports are structured, timestamped, versioned (2-version rotation). The Implementation Agent reads the Research Advisor's report as a briefing, not a conversation.

3. **"Don't Repeat Work" as a Core Rule**: The Research Advisor prompt explicitly says "Read what's been tried and suggest NEW things." `PORTING_STATUS.md` tracks "Issues Found and Fixed" and "Hypotheses Ruled Out." This is proto-memory.

4. **Confidence Levels on Output**: Suggestions are categorized as "High Confidence," "Worth Trying," and "Speculative." This graduated certainty builds the dev agent's trust. The dev agent learned to ask for the Research Advisor because its reports repeatedly broke through blockers.

5. **Separation of Concerns**: Each agent has one job. The Cleanup Auditor doesn't write code. The Verification Agent doesn't suggest fixes. The Research Advisor doesn't implement. This prevents role confusion.

### What's Missing (and This System Must Address)

1. **Automation**: Everything is manually triggered (copy-paste prompt into fresh session). Session startup procedures, CLAUDE.md configuration, and MCP-based memory consultation replace manual copy-paste.
2. **Real-time collaboration**: No dialogue channel. The MCP communication hub provides real-time, typed, bidirectional messaging between sessions, replacing ad-hoc file drops with structured agent-to-agent communication.
3. **Memory beyond 2 reports**: The 2-version rotation means history evaporates. The MCP knowledge graph provides persistent, curated, semantically searchable memory across all sessions and across days.
4. **Confidence as track record**: The confidence levels are self-assessed by each agent. The quality session tracks outcomes in the knowledge graph over time, building system-level (not self-assessed) confidence.
5. **No orchestration layer**: The human IS the orchestrator. This system keeps the human as orchestrator but gives them structured tools, MCP-mediated visibility, and knowledge graph context to orchestrate effectively.
6. **No architectural protection**: Nothing prevents a fresh agent from rewriting code another agent spent days building. Architectural entities in the knowledge graph with guard notes directly address this.

---

## Beyond "Quality": The Full Scope

"Quality Co-Agent" is too narrow a name for what this system actually is. The system's responsibilities span all three oversight tiers:

| Tier | Domain | What It Does | Example |
|------|--------|-------------|---------|
| **T1: Vision** | Vision Enforcement | Ensures all work aligns with the project's fundamental identity and purpose | "This feature requires screen taps during oral practice. The voice-first design requires 100% hands-free operation." |
| **T1: Vision** | Vision-Level Drift Prevention | Keeps work aligned with project purpose, not just task goals | "You've built a complex visual UI for what should be a voice-first flow." |
| **T2: Architecture** | Pattern Enforcement | Guards established patterns, prevents ad-hoc reimplementation | "This component uses protocol-based DI. Don't create an inline service, inject via init." |
| **T2: Architecture** | Architecture Protection | Prevents destructive rewrites of established components | "This component was established over 3 sessions. Fix targeted, don't rewrite." |
| **T2: Architecture** | Research | Fresh perspective and hypothesis generation when stuck | PocketTTS Research Advisor pattern, providing new approaches grounded in architectural context |
| **T3: Quality** | Code Quality | Lint, test, coverage, security scanning | SwiftLint findings, test failures, coverage gaps |
| **T3: Quality** | Troubleshooting Memory | Remember what was tried, what failed, what worked | "Retry with backoff was partial. Circular buffer with fixed cap worked." |
| **T3: Quality** | Solution Memory | Recognize recurring patterns and apply proven solutions | "This is the same class of bug we fixed in TTSService. The fix was..." |

This is **three tiers of institutional oversight**: vision enforcement (the project's immutable identity), architecture protection (established patterns and standards with human-gated changes), and quality automation (routine checks that should pass on first attempt). All three operate as perspectives of the quality session, a collaborative peer to the dev agents, powered by Claude Code sessions coordinated through MCP infrastructure.

---

## Vision Summary

This system exists to preserve and serve the project's vision. Everything it does, from quality enforcement to institutional memory to multi-session coordination, serves that purpose.

**Three-tiered oversight** is the organizing principle. Vision standards (the project's fundamental identity, like the voice-first design philosophy) are immutable by agents and enforced as the highest priority. Architectural standards (established patterns, performance targets, DI conventions) can evolve through structured proposals requiring human approval. Quality standards (lint, tests, coverage) are automated and low-friction, with the goal of passing on first commit attempt. The quality session applies all three tiers as ordered lenses: vision first, architecture second, quality third.

A human developer, working through a primary Claude Code session, orchestrates parallel worker sessions and a dedicated quality session. Workers operate in isolated git worktrees, receiving task briefs as structured documents and producing code artifacts. The quality session operates as the guardian of all three oversight tiers, reviewing worker output against vision standards, architectural patterns, and deterministic quality checks.

Communication flows through an MCP communication hub that provides real-time agent registration, discovery, and structured messaging between sessions. Every finding carries a tier and severity, ensuring that vision conflicts are surfaced before architectural concerns, and architectural concerns before routine quality issues. Institutional memory lives in an MCP-backed knowledge graph where every entity carries a `protection_tier` observation encoding its mutability level. Structured files serve as the durable, human-readable archive. Code state is coordinated through git.

The building blocks are Claude Code sessions (interactive and headless), built-in subagents, hooks, MCP servers (both existing community servers and purpose-built ones), git, and the filesystem. The human developer is always the ultimate orchestrator, empowered by MCP-mediated communication, persistent knowledge graphs, and structured coordination tools to manage multi-session, multi-hour development work.

**Core capabilities:**
1. **Vision enforcement**: Project identity and purpose preserved as immutable standards that all work must serve
2. **Architecture protection**: Established patterns, performance targets, and conventions guarded with human-gated change protocols
3. **Quality automation**: Lint, test, coverage, security, Tool Trust, verified deterministically with minimal friction
4. **Institutional memory**: MCP knowledge graph storing vision standards, architectural decisions, troubleshooting history, and solution patterns, with tier-aware protection, queryable by all sessions, curated by the quality session
5. **Inter-agent communication**: MCP communication hub for real-time agent registration, discovery, and tier-tagged structured messaging
6. **Research capability**: Fresh perspective on demand, breaking through blockers (via dedicated sessions)
7. **Session orchestration**: Goals, checkpoints, drift detection, adaptive intensity
8. **Specialist routing**: Best-in-class per domain, external services consumed agentically via MCP

**The confidence mechanism**: Confidence emerges from deterministic verification first (does it compile? do tests pass?), then from track record (did previous suggestions work?), then from explanation quality (is the rationale project-specific?). Never from self-assessment. The quality session tracks outcomes in the knowledge graph; the orchestrator uses this history to calibrate trust.

**The team relationship**: Dev sessions and the quality session have each other's back. The quality session provides vision enforcement, architectural guidance, institutional memory, and quality automation that makes dev sessions dramatically more effective. Dev sessions aren't being policed; they're being supported by a teammate that remembers everything, knows the codebase patterns, guards the project's vision, and can bring fresh perspective when things get stuck.

**The platform**: Everything described here runs on Claude Code Max, with MCP servers providing the shared infrastructure for communication, memory, and coordination. The architecture leverages the MCP ecosystem aggressively, adopting existing community servers for knowledge graphs, inter-agent messaging, agent registries, and semantic search rather than building inferior custom replacements. Where the ecosystem doesn't have what we need, we build purpose-fit MCP servers. The result is a system that is practically powerful, readily extensible, and designed to grow as both Claude Code and the MCP ecosystem evolve.

---

*This vision document is the conceptual foundation. The implementation details (specific tools, configurations, MCP servers, hooks) live in `work/QUALITY_CO_AGENT_MASTER.md`. This document answers "why this system exists, what it's shaped like, how the pieces relate, and what principles govern it." The master doc answers "what specific tools and configurations do we build."*
