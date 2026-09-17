# Big-work orchestration

When eng bots (Mark / Sam) face large work, default to a **dedicated orchestrator agent session** — not one mega worker, and not the eng bot personally juggling N chats mid-stream.

Standing stack: `agent-m1` (Claude Code / Codex) is primary. Cursor cloud is fallback or explicit A/B only. Fan-out uses `orchestrate-agents` ([amillez/agent-skills](https://github.com/amillez/agent-skills)) with worktree-per-worker ([agent dispatch lifecycle](agent-dispatch-lifecycle.md)). Proof follows [agent proof feedback loop](agent-proof-feedback-loop.md).

## When work is "big"

Treat the ask as big (and use this playbook) when any of these hold:

- Multi-surface or multi-package (e.g. RN + API + shared package).
- Clearly parallelizable slices with disjoint paths.
- Likely multi-PR or stacked landings.
- Estimated effort is well beyond one focused coding session.
- The eng bot (or human) asked for a "big" / large feature / epic-sized change.

Small, already-scoped, single-worktree tasks stay on the normal dispatch path. Do not over-orchestrate a rename.

## Default path

1. **Eng bot intakes** the ask: success criteria, proof type, constraints, host pick.
2. Eng bot dispatches a **dedicated orchestrator agent session** (preferred) on the chosen host — one workstream whose job is plan → fan-out → integrate, not feature code itself.
3. Orchestrator runs the pipeline below.
4. Eng bot arms babysit on the resulting PR(s) per [dispatch lifecycle](agent-dispatch-lifecycle.md#babysit-until-merged).

Do **not** collapse big work into one mega agent that owns every file. Do **not** keep the eng bot as a forever-orchestrator inside Slack/chat while spinning workers by hand unless the work is tiny enough that a single workstream is clearly enough.

## Pipeline

```text
Plan (scout) → Workers (disjoint worktrees) → Integrate (orchestrator only)
  → Prove (proof loop; RN visual → agent-m1 Argent) → Babysit (dispatch lifecycle)
```

### 1. Plan (scout)

- Recon the repo: surfaces, packages, ownership boundaries, risks.
- Slice into **disjoint** worker scopes (paths/packages that do not collide).
- Write one isolated prompt per worker (goal, scope, constraints, skills, proof expected for that slice). Use `orchestrate-agents`.
- Hardware / device validation is **never** parallel — schedule it after integrate (or as a single later hop).

### 2. Workers

- One worker = one worktree = one branch (`agent/<bot>/<slug>`), per [dispatch lifecycle](agent-dispatch-lifecycle.md#worktrees-on-agent-m1).
- Workers do not share files. If two slices need the same path, serialize or merge scopes in the plan.
- Workers return code + slice-level evidence (tests, typecheck, notes). They do not own end-to-end product proof unless the slice is the whole product ask.

### 3. Integrate (orchestrator only)

- Only the orchestrator merges worker outputs, resolves conflicts, and lands a coherent branch/PR set.
- Re-run unit/typecheck/CI at the integration boundary before claiming integrate-done.
- Prefer one reviewable PR (or a short explicit stack) over a pile of half-integrated branches.

### 4. Prove

- Follow [agent proof feedback loop](agent-proof-feedback-loop.md): thorough criteria, inspect proof, Luna Max for visual media, media on `media` branch.
- **RN / mobile visual proof (sims/AVDs):** the prove hop **must** run on `agent-m1` with Argent. Cursor cloud VMs cannot run Mac sims/AVDs the way `agent-m1` can.
- Non-visual proof (unit tests, typecheck, CI) may stay on Cursor cloud when that host ran the code slices.
- If plan/workers/integrate ran on Cursor cloud for an RN visual task, **return prove to `agent-m1`** (Argent) before calling the work done.

### 5. Babysit

- Eng bot owns the workstream(s) until `merged` | `discarded`, per [babysit until merged](agent-dispatch-lifecycle.md#babysit-until-merged).
- A big Task may spawn an orchestrator workstream that fans out child workstreams; babysit covers the parent PR (and children if they land separately) until terminal.

## Roles

| Role | Owns |
| --- | --- |
| **Eng bot (Mark / Sam)** | Intake, host pick, launch orchestrator with a thorough prompt, arm babysit, verify final proof bar, merge/close decisions. |
| **Orchestrator agent** | Plan, write isolated worker prompts via `orchestrate-agents`, fan-out, integrate, hand off prove. Does not personally implement every slice. |
| **Worker agents** | One worktree each; implement their slice only; return code + slice evidence. |

## Host matrix

| Host | Use for |
| --- | --- |
| **`agent-m1` (Claude Code / Codex)** | **Primary full pipeline** — plan, workers, integrate, prove (including Argent RN sims/AVDs). |
| **Cursor cloud** | Code slices (plan / workers / integrate) when `agent-m1` is down, or when an explicit A/B comparison experiment requests it. **Prove hop:** sim-dependent RN/visual proof returns to `agent-m1`; unit/typecheck/CI can stay on cloud. |

Do not use Cursor cloud as the default prove host for RN visual work. Do not use Cursor as the default coding host when `agent-m1` is up, except for an explicit comparison experiment (below).

## Out of scope / later

### Orca CLI (deferred for v1)

[Orca](https://onorca.dev) (stablyai/orca) offers structured Runs / Tasks / Dispatches / `worker_done` / DAGs. **Defer for v1.**

We get orchestration from eng-bot intake + `orchestrate-agents` + worktrees first. Revisit Orca only if we need a **durable DAG / `worker_done` runtime** beyond what Claude Code / Codex session tools already provide.

Do not wholesale-adopt Orca (or pstack Arena/Swarm) in this playbook. Optional cross-link: [Steal from pstack](steal-from-pstack.md) (Arena/Swarm deferred).

## Comparison experiment

When Agustín asks for an A/B (Claude/Codex orchestration on `agent-m1` vs Cursor cloud orchestration), Mark runs both fairly:

1. **Same task brief** — identical goal, scope, constraints, skills list.
2. **Same success criteria** — observable "done when…".
3. **Same proof bar** — same proof type and inspect standard; state prove **location** explicitly (`agent-m1` Argent vs cloud-only non-visual).
4. **Log host / model / effort** for each arm (and Fast off unless explicitly requested).
5. **Do not** change the brief mid-flight on only one arm. Record blockers with evidence.

Use this section so the experiment is comparable, not vibes.

## Anti-patterns

- Single mega session that owns the whole epic end-to-end without slices.
- Parallel workers on the same files / overlapping paths.
- Running sim-dependent RN prove on Cursor cloud (no Mac sims/AVDs like `agent-m1`).
- Eng bot acting as forever-orchestrator in chat instead of launching an orchestrator session.
- Parallel hardware / device validation.
- Adopting Orca or Arena/Swarm wholesale before the eng-bot + `orchestrate-agents` path is proven.

## Related

- [Agent dispatch lifecycle](agent-dispatch-lifecycle.md) — worktrees, babysit, teardown
- [Agent proof feedback loop](agent-proof-feedback-loop.md) — thorough launch, Argent, Luna Max, media branch
- [Agent use policy](../policies/agent-use-policy.md) — host routing defaults
- Skill: `orchestrate-agents` in [amillez/agent-skills](https://github.com/amillez/agent-skills)
- [Steal from pstack](steal-from-pstack.md) — Arena/Swarm deferred; Orca deferred here
