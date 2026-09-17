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
2. Eng bot dispatches a **dedicated orchestrator agent session** (preferred) on the chosen host — one workstream whose job is plan → fan-out → integrate, not feature code itself.
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
| **Orchestrator agent** | Plan, write isolated worker prompts via `orchestrate-agents`, fan-out, integrate, hand off prove. Does not personally implement every slice. |
| **Worker agents** | Implement one slice each (disjoint paths); one agent per live worktree when parallel — or sequential on one tree under disk mode 1; return code + slice evidence. |

## Host matrix

| Host | Use for |
| --- | --- |
| **`agent-m1` (Claude Code / Codex)** | **Primary full pipeline** — plan, workers, integrate, prove (including Argent RN sims/AVDs). |
| **Cursor cloud** | Code slices (plan / workers / integrate) when `agent-m1` is down, or when an explicit A/B comparison experiment requests it. **Prove hop:** sim-dependent RN/visual proof returns to `agent-m1`; unit/typecheck/CI can stay on cloud. |

Do not use Cursor cloud as the default prove host for RN visual work. Do not use Cursor as the default coding host when `agent-m1` is up, except for an explicit comparison experiment (below).

## Model assignment

`orchestrate-agents` is **prompt fan-out only** — it writes isolated worker prompts; it does **not** launch models or sessions.

Cross-harness fan-out is supported when the **launcher** (eng bot or orchestrator session) starts each worker on a harness that can run that provider:

| Host | Reality |
| --- | --- |
| **`agent-m1`** | Claude Code = Anthropic; Codex = OpenAI. A Claude Code session cannot natively spawn a Codex worker in-process (and vice versa) — start a **separate worktree/session** for that slice. Assign **harness/provider per slice** (Claude Code vs Codex) according to the canonical Claude-vs-Codex chooser **once that chooser is established** (still TBD in [agent-use-policy](../policies/agent-use-policy.md)). Do **not** treat Cursor/Grok Bot lane names as agent-m1 model picks. |
| **Cursor cloud** | Normal / fallback work: follow [agent-use-policy](../policies/agent-use-policy.md) (chooser + Cursor cloud launch rules). **Comparison experiment arm only:** Composer 2.5 + Grok 4.6 — see [Comparison experiment](#comparison-experiment). |

**Rule:** the orchestrator assigns **host + harness (and, on Cursor, model/effort) per worker** by slice. Do **not** inherit the parent session's harness or model blindly.

Prove for sim-dependent RN still hops to `agent-m1` Argent regardless of which harness wrote the slice.

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
| **A — agent-m1** | `agent-m1` Claude Code + Codex | Separate Claude Code and/or Codex sessions/worktrees per slice. Claude-vs-Codex assignment is part of the experiment and **must be logged** (chooser still TBD). Do not label slices with Cursor/Grok Bot lane names. |
| **B — Cursor cloud** | Cursor cloud | **Composer 2.5** + **Grok 4.6** only. Do **not** use the standing Cursor/Grok Bot chooser lanes on this experiment arm. |

Normal Cursor fallback (non-experiment) continues to follow [agent-use-policy](../policies/agent-use-policy.md) — do not restate those model names here.

### Fairness checklist

1. **Same task brief** — identical goal, scope, constraints, skills list.
2. **Same success criteria** — observable "done when…".
3. **Same proof bar** — same proof type and inspect standard; state prove **location** explicitly. Sim-dependent RN visual proof still hops to `agent-m1` (Argent) for **both** arms; unit/typecheck/CI may stay on the arm that wrote the code.
4. **Log host / harness / model / effort** for each arm (and Fast off unless explicitly requested). Arm A: log Claude Code vs Codex per slice. Arm B: must show Composer 2.5 and/or Grok 4.6 only.
5. **Do not** change the brief mid-flight on only one arm. Record blockers with evidence.

Use this section so the experiment is comparable, not vibes.

## Anti-patterns

- Single mega session that owns the whole epic end-to-end without slices.
- Parallel workers on the same files / overlapping paths.
- Parallel workers sharing one working tree (use sequential-on-one-tree or separate worktrees — never both at once on the same checkout).
- Running sim-dependent RN prove on Cursor cloud (no Mac sims/AVDs like `agent-m1`).
- Eng bot acting as forever-orchestrator in chat instead of launching an orchestrator session.
- Blindly inheriting the orchestrator's harness/model for every worker (or expecting Claude Code to spawn Codex in-process, or vice versa).
- Parallel hardware / device validation.
- Adopting Orca or Arena/Swarm wholesale before the eng-bot + `orchestrate-agents` path is proven.

## Related

- [Agent dispatch lifecycle](agent-dispatch-lifecycle.md) — worktrees, babysit, teardown
- [Agent proof feedback loop](agent-proof-feedback-loop.md) — thorough launch, Argent, Luna Max, media branch
- [Agent use policy](../policies/agent-use-policy.md) — host routing defaults
- Skill: `orchestrate-agents` in [amillez/agent-skills](https://github.com/amillez/agent-skills)
- [Steal from pstack](steal-from-pstack.md) — Arena/Swarm deferred; Orca deferred here
