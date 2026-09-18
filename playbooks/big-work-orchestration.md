# Big-work orchestration

When eng bots (Mark / Sam) face large work, default to a **dedicated orchestrator agent session** — not one mega worker, and not the eng bot personally juggling N chats mid-stream.

Standing stack: `agent-m1` (Claude Code / Codex) **only**. Cursor coding / Cursor cloud A/B arms are **historical/abandoned** (Agustín 2026-09-18). Fan-out uses `orchestrate-agents` ([amillez/agent-skills](https://github.com/amillez/agent-skills)) and the worktree rules in [agent dispatch lifecycle](agent-dispatch-lifecycle.md) (parallel workers never share one tree; see [Worktrees and disk](#worktrees-and-disk)). Proof follows [agent proof feedback loop](agent-proof-feedback-loop.md).

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

- Follow [agent proof feedback loop](agent-proof-feedback-loop.md): thorough criteria, inspect proof, Luna-role (Codex) for visual media, media on `media` branch.
- **RN / mobile visual proof (sims/AVDs):** the prove hop **must** run on `agent-m1` with Argent.
- Non-visual proof (unit tests, typecheck, CI) also runs on `agent-m1` (Claude Code / Codex).
- **Prove before PR.** Collect and inspect task-relevant proof before opening (or claiming ready) the PR. Do not open a prove-empty PR and backfill later.
- **Sim mutex on `agent-m1`:** one prove owner at a time for Argent/sim work; max **2** sims host-wide. Do not fan out parallel sim proves on the same host.

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
| **`agent-m1` (Claude Code / Codex)** | **Only coding host** — full pipeline: plan, workers, integrate, prove (including Argent RN sims/AVDs). |
| **Cursor cloud / My Machines** | **Abandoned** (Agustín 2026-09-18). Do not dispatch coding work there. Historical A/B Cursor arm docs below are archive-only. |

Prove everything on `agent-m1`. Do not use Cursor as a coding or prove host.

## Model assignment

`orchestrate-agents` is **prompt fan-out only** — it writes isolated worker prompts; it does **not** launch models or sessions.

- **Orchestrator (agent-m1):** Claude Code running **Claude Opus 5** at **xhigh**. Plans and fans out; does **not** implement every slice. Eng bot launches this session; the orchestrator then spawns workers per [agent-use-policy](../policies/agent-use-policy.md) + this playbook.
- **Workers:** assign **model + effort per slice** from the [agent chooser](../policies/agent-use-policy.md#agent-chooser-examples) (Luna Max / Sol High / Opus High→xhigh / Fable→Opus; escalate one knob at a time; Claude vs Codex per chooser TBD). Do **not** inherit Opus 5 xhigh for every worker. Thorough prompts, skills, [disk modes](#worktrees-and-disk); integrate; RN prove hops to `agent-m1` Argent; babysit handoff stays with the eng bot.

**Host / harness must run the assigned model.** The launcher starts each worker on `agent-m1` where that model actually runs:

| Where | When |
| --- | --- |
| **`agent-m1` Claude Code or Codex** | Only coding path. Claude Code cannot spawn Codex in-process (and vice versa) — use a **separate** worktree/session. When both harnesses are used, **log** Claude Code vs Codex per slice. Map policy labels (Luna/Sol/Opus/Fable) per [agent-use-policy](../policies/agent-use-policy.md#1-coding-host-routing). If a historical Cursor-only lane has no Claude/Codex equivalent, **skip that lane** and pick the nearest Sol/Opus equivalent. |
| **Cursor cloud / comparison arm B** | **Abandoned** — see [Comparison experiment (historical)](#comparison-experiment-historicalabandoned). |

**Rule:** pick model + effort from policy first, then pick Claude Code vs Codex on `agent-m1`. Do not collapse every worker onto the orchestrator's Opus xhigh. Claude vs Codex chooser remains TBD.

Prove for sim-dependent RN stays on `agent-m1` Argent.

## Out of scope / later

### Orca CLI (deferred for v1)

[Orca](https://onorca.dev) (stablyai/orca) offers structured Runs / Tasks / Dispatches / `worker_done` / DAGs. **Defer for v1.**

We get orchestration from eng-bot intake + `orchestrate-agents` + worktrees first. Revisit Orca only if we need a **durable DAG / `worker_done` runtime** beyond what Claude Code / Codex session tools already provide.

Do not wholesale-adopt Orca (or pstack Arena/Swarm) in this playbook. Optional cross-link: [Steal from pstack](steal-from-pstack.md) (Arena/Swarm deferred).

## Comparison experiment (historical/abandoned)

**Abandoned 2026-09-18.** Cursor is removed from the coding workflow. Do **not** run Arm B (Cursor cloud) or hop workers to Cursor. Standing path is Arm A only: prove on `agent-m1` with Claude Code / Codex.

Archive of the old A/B framing (do not execute):

| Arm | Host | What was run |
| --- | --- | --- |
| **A — agent-m1** | `agent-m1` | Orchestrator: Claude Code Opus / xhigh. Workers: chooser per slice (Claude/Codex). |
| **B — Cursor cloud** | Cursor cloud | Orchestrator: Grok 4.6 / xhigh, Fast off. Workers: Grok and/or Composer. **Do not use.** |

## Anti-patterns

- Single mega session that owns the whole epic end-to-end without slices.
- Parallel workers on the same files / overlapping paths.
- Parallel workers sharing one working tree (use sequential-on-one-tree or separate worktrees — never both at once on the same checkout).
- Dispatching coding work to Cursor cloud, Cursor My Machines, or any Cursor coding host (abandoned).
- Claiming Argent/sim proof from anywhere other than `agent-m1` Claude Code / Codex + Argent.
- Parallel sim proves on `agent-m1` (break the one-prove-owner / max-2-sims mutex) or opening a PR before prove.
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
