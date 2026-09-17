# Big-work orchestration

When eng bots (Mark / Sam) face large work, default to a **dedicated orchestrator agent session** — not one mega worker, and not the eng bot personally juggling N chats mid-stream.

Standing stack: `agent-m1` (Claude Code / Codex) is primary. Cursor cloud is fallback or explicit A/B only. Fan-out uses `orchestrate-agents` ([amillez/agent-skills](https://github.com/amillez/agent-skills)) and the worktree rules in [agent dispatch lifecycle](agent-dispatch-lifecycle.md) (parallel workers never share one tree; see [Worktrees and disk](#worktrees-and-disk)). Proof follows [agent proof feedback loop](agent-proof-feedback-loop.md).

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
2. Eng bot dispatches a **dedicated orchestrator agent session** (preferred) on the chosen host — on `agent-m1`, Claude Code **Opus 5 / xhigh**; job is plan → fan-out → integrate, not feature code itself.
3. Orchestrator runs the pipeline below.
4. Eng bot arms babysit on the resulting PR(s) per [dispatch lifecycle](agent-dispatch-lifecycle.md#babysit-until-merged).

Do **not** collapse big work into one mega agent that owns every file. Do **not** keep the eng bot as a forever-orchestrator inside Slack/chat while spinning workers by hand unless the work is tiny enough that a single workstream is clearly enough.

## Pipeline

```text
Plan (scout) → Workers (disjoint paths; disk modes below) → Integrate (orchestrator only)
  → Prove (proof loop; RN visual → agent-m1 Argent) → Babysit (dispatch lifecycle)
```

### 1. Plan (scout)

- Recon the repo: surfaces, packages, ownership boundaries, risks.
- Slice into **disjoint** worker scopes (paths/packages that do not collide).
- Write one isolated prompt per worker (goal, scope, constraints, skills, proof expected for that slice). Use `orchestrate-agents`.
- Hardware / device validation is **never** parallel — schedule it after integrate (or as a single later hop).

### 2. Workers

- Plan still uses `orchestrate-agents` with **disjoint path ownership** per slice. If two slices need the same path, serialize or merge scopes in the plan.
- Pick a [worktree / disk mode](#worktrees-and-disk) before launch. Parallel workers must not share one working tree.
- Workers return code + slice-level evidence (tests, typecheck, notes). They do not own end-to-end product proof unless the slice is the whole product ask.

### Worktrees and disk

**Hard rule:** parallel workers must **not** share one working tree. Same checkout = colliding git index, dirty files, locks, Metro/Pods, and half-applied edits. Do not claim parallel agents can safely share one worktree.

On `agent-m1` (256GB host), prefer disk-conscious modes in this order:

1. **Default under disk pressure / RN-sized repos:** one shared worktree, **sequential** workers — same tree, one agent at a time, still disjoint path ownership in the plan. Orchestrator still plans with `orchestrate-agents`; fan-out is **temporal**, not parallel. Saves N copies of `node_modules` / Pods.
2. **Limited parallel:** at most **2** worktrees unless Agustín explicitly raises the cap. Prefer package-level cuts.
3. **If using multiple worktrees:** git objects are already shared across worktrees; the expensive part is usually `node_modules` / CocoaPods / build artifacts. Mitigations: shared pnpm store, delete/teardown worktrees promptly after integrate, avoid copying derived artifacts into every tree, stay aware of Colima/Docker disk use. Branch naming stays `agent/<bot>/<slug>` per [dispatch lifecycle](agent-dispatch-lifecycle.md#worktrees-on-agent-m1).

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
| **Orchestrator agent** | On `agent-m1`: Claude Code running **Claude Opus 5** at **xhigh**. Plans and fans out; writes isolated prompts via `orchestrate-agents`; assigns each worker **model + effort** from [agent-use-policy](../policies/agent-use-policy.md); applies [disk modes](#worktrees-and-disk); integrates; hands off prove. Does **not** implement every slice itself. |
| **Worker agents** | Spawned by the orchestrator on a host/harness that can run the assigned model. Slice-appropriate chooser pick (not Opus 5 xhigh by default); thorough prompts, skills, disk modes. Return code + slice evidence. |

## Host matrix

| Host | Use for |
| --- | --- |
| **`agent-m1` (Claude Code / Codex)** | **Primary full pipeline** — plan, workers, integrate, prove (including Argent RN sims/AVDs). |
| **Cursor cloud** | Code slices (plan / workers / integrate) when `agent-m1` is down, or when an explicit A/B comparison experiment requests it. **Prove hop:** sim-dependent RN/visual proof returns to `agent-m1`; unit/typecheck/CI can stay on cloud. |

Do not use Cursor cloud as the default prove host for RN visual work. Do not use Cursor as the default coding host when `agent-m1` is up, except for an explicit comparison experiment (below).

## Model assignment

`orchestrate-agents` is **prompt fan-out only** — it writes isolated worker prompts; it does **not** launch models or sessions.

- **Orchestrator (agent-m1):** Claude Code running **Claude Opus 5** at **xhigh**. Plans and fans out; does **not** implement every slice. Eng bot launches this session; the orchestrator then spawns workers per [agent-use-policy](../policies/agent-use-policy.md) + this playbook.
- **Workers:** assign **model + effort per slice** from the [agent chooser](../policies/agent-use-policy.md#agent-chooser-examples) (Luna Max / Sol High / Opus High→xhigh / Fable; Fast off; escalate one knob at a time). Do **not** inherit Opus 5 xhigh for every worker. Thorough prompts, skills, [disk modes](#worktrees-and-disk); integrate; RN prove hops to `agent-m1` Argent; babysit handoff stays with the eng bot.

**Host / harness must run the assigned model.** The launcher starts each worker where that model actually runs:

| Where | When |
| --- | --- |
| **`agent-m1` Claude Code or Codex** | Work stays on agent-m1 and the harness can run the assigned model. Claude Code cannot spawn Codex in-process (and vice versa) — use a **separate** worktree/session. When both harnesses are used, **log** Claude Code vs Codex per slice. |
| **Cursor cloud** | The chooser pick is a Cursor/Grok Bot lane that Claude Code / Codex cannot run — spawn that worker on Cursor cloud (pass model/effort/Fast explicitly per policy), **or** document the gap and escalate. Normal Cursor launches follow [agent-use-policy](../policies/agent-use-policy.md). |
| **Comparison experiment arm B only** | **Orchestrator:** Grok 4.6 at **xhigh**, **Fast off**. **Workers:** Grok 4.6 and/or Composer 2.5; log which is used. Do not use Luna, Sol, Opus, or Fable on this arm — see [Comparison experiment](#comparison-experiment). Overrides the standing chooser for that arm. |

**Rule:** pick model + effort from policy first, then pick a host/harness that can run it. Do not collapse every worker onto the orchestrator's Opus 5 xhigh.

Prove for sim-dependent RN still hops to `agent-m1` Argent regardless of which host wrote the slice.

## Out of scope / later

### Orca CLI (deferred for v1)

[Orca](https://onorca.dev) (stablyai/orca) offers structured Runs / Tasks / Dispatches / `worker_done` / DAGs. **Defer for v1.**

We get orchestration from eng-bot intake + `orchestrate-agents` + worktrees first. Revisit Orca only if we need a **durable DAG / `worker_done` runtime** beyond what Claude Code / Codex session tools already provide.

Do not wholesale-adopt Orca (or pstack Arena/Swarm) in this playbook. Optional cross-link: [Steal from pstack](steal-from-pstack.md) (Arena/Swarm deferred).

## Comparison experiment

When Agustín asks for an A/B (Claude/Codex orchestration on `agent-m1` vs Cursor cloud orchestration), Mark runs both fairly. This section is **only** for that experiment — it does not change standing [agent-use-policy](../policies/agent-use-policy.md) defaults for normal Cursor fallback.

### Arms

| Arm | Host | What to run |
| --- | --- | --- |
| **A — agent-m1** | `agent-m1` (+ Cursor cloud only if a worker model cannot run there) | **Orchestrator:** Claude Code **Opus 5 / xhigh**. **Workers:** model + effort per slice from [agent-use-policy](../policies/agent-use-policy.md) chooser (not all Opus 5 xhigh); log model/effort/Fast and harness (Claude Code vs Codex) when both are used; hop a worker to Cursor cloud if the pick cannot run on agent-m1. |
| **B — Cursor cloud** | Cursor cloud | **Orchestrator:** **Grok 4.6 / xhigh**, with **Fast off** when launching. **Workers:** may use Grok 4.6 and/or Composer 2.5; log which is used. Do not use Luna, Sol, Opus, or Fable on this experiment arm. |

Outside experiment arm B, Cursor launches (including Arm A workers hopped to cloud) follow [agent-use-policy](../policies/agent-use-policy.md).

### Fairness checklist

1. **Same task brief** — identical goal, scope, constraints, skills list.
2. **Same success criteria** — observable "done when…".
3. **Same proof bar** — same proof type and inspect standard; state prove **location** explicitly. Sim-dependent RN visual proof still hops to `agent-m1` (Argent) for **both** arms; unit/typecheck/CI may stay on the arm that wrote the code.
4. **Log host / harness / model / effort** for each arm (and Fast off unless explicitly requested). Arm A: orchestrator = Opus 5 xhigh; per worker log chooser model + effort (+ Claude Code vs Codex harness when used). Arm B: must show **Grok 4.6 / xhigh** as the orchestrator with **Fast off**; Composer 2.5 may appear only when used as a worker, and workers must not use Luna, Sol, Opus, or Fable.
5. **Do not** change the brief mid-flight on only one arm. Record blockers with evidence.

Use this section so the experiment is comparable, not vibes.

## Anti-patterns

- Single mega session that owns the whole epic end-to-end without slices.
- Parallel workers on the same files / overlapping paths.
- Parallel workers sharing one working tree (use sequential-on-one-tree or separate worktrees — never both at once on the same checkout).
- Running sim-dependent RN prove on Cursor cloud (no Mac sims/AVDs like `agent-m1`).
- Eng bot acting as forever-orchestrator in chat instead of launching an orchestrator session.
- Blindly inheriting Opus 5 xhigh (or the orchestrator's harness) for every worker, skipping the agent-use-policy chooser, or expecting Claude Code to spawn Codex in-process (or vice versa).
- Parallel hardware / device validation.
- Adopting Orca or Arena/Swarm wholesale before the eng-bot + `orchestrate-agents` path is proven.

## Related

- [Agent dispatch lifecycle](agent-dispatch-lifecycle.md) — worktrees, babysit, teardown
- [Agent proof feedback loop](agent-proof-feedback-loop.md) — thorough launch, Argent, Luna Max, media branch
- [Agent use policy](../policies/agent-use-policy.md) — host routing defaults
- Skill: `orchestrate-agents` in [amillez/agent-skills](https://github.com/amillez/agent-skills)
- [Steal from pstack](steal-from-pstack.md) — Arena/Swarm deferred; Orca deferred here
