# Big-work orchestration

When eng bots (Mark / Sam) face work that needs more than one focused coding session, use this playbook. Standing stack: **`agent-m1`** running **Claude Code / Codex** workers inside **Orca** orchestration. Cursor coding / Cursor cloud A/B arms are **historical/abandoned** (Agustín 2026-09-18). Do **not** resurrect Cursor as a coding host — even if Orca's CLI accepts `--agent cursor`, we do not use it.

Proof follows [agent proof feedback loop](agent-proof-feedback-loop.md). Worktree / babysit rules: [agent dispatch lifecycle](agent-dispatch-lifecycle.md).

**Docs (cite):**
- [Orca CLI overview](https://www.onorca.dev/docs/cli/overview)
- [Orca Orchestration](https://www.onorca.dev/docs/cli/orchestration)

**Lesson from the Mark trial (2026-09-18):** do **not** collapse big work into one mega-agent; do **not** skip the [size gate](#size-gate); prove-before-PR still stands; keep the sim mutex / max 2 concurrent sims. Large work uses **Orca** (not deferred) with an **Opus 5.5 xhigh** coordinator.

## Size gate

**Decide once at intake** — eng bot (or human), before any launch:

| Gate | Condition | Action |
| --- | --- | --- |
| **Small** | Single surface/package, one PR, already-scoped paths, fits one focused session, blast radius clear | Dispatch the **corresponding agent directly** — model + harness from the [agent chooser](../policies/agent-use-policy.md#agent-chooser-examples) (Luna / Sol / Opus on Claude Code / Codex). **No Orca Run. No orchestrator layer.** |
| **Needs orch (large)** | Any of: multi-surface, multi-package, clearly parallelizable slices, multi-PR / stacked landings, multi-session, unclear blast radius, or more than one focused session | Start an **Orca Run** with an **Opus 5.5 xhigh** coordinator. Coordinator only plans, dispatches, waits, and routes decisions (`plan → workers → integrate → prove → babysit` as **worker tasks**). Workers get **model + effort per slice** from the chooser via `orca orchestration worker-start --agent claude\|codex --model … --effort …` — not all Opus xhigh. Coordinator does **not** implement, integrate, or validate. |

### Small examples (direct agent — no Orca)

- Rename a prop in one component folder → **Luna** (Codex) Max.
- Fix a known auth bug in one package → **Sol** (Codex) High.
- One UI polish PR in a single app surface → **Opus** (Claude Code) High.
- Mechanical chore with tests already green → **Luna** Max.

### Needs-orch examples (Orca + Opus 5.5 xhigh coordinator)

- RN + API + shared package feature with disjoint paths.
- Parallelizable cuts across two+ packages that should land as one coherent PR (or a short stack).
- Epic-sized ask where blast radius is unclear until scout.
- Multi-PR / multi-session landing that needs integrate + prove coordination.

Do **not** over-orchestrate a rename. Do **not** skip the gate and send everything to one mega session "to save hops."

## Prerequisites (needs orch only)

On `agent-m1`, before creating a Run:

1. **Orca runtime up:** `orca status --json` succeeds ([CLI overview](https://www.onorca.dev/docs/cli/overview)).
2. **Orchestration enabled:** Settings → Experimental → orchestration on ([Orchestration](https://www.onorca.dev/docs/cli/orchestration)).
3. **Skills installed** for the coordinator (and workers that need them):
   - `orca skills install --skill orca-cli` (or `npx skills add https://github.com/stablyai/orca --skill orca-cli`)
   - Install / refresh the **orchestration** skill (`orca skills get orchestration --full` after install).
4. **Amillez plugin** ensured on the target project path (Grok Bot / ensure-project) before coding workers touch the tree.
5. Prefer `orca skills get orchestration --full` when flags drift — command surface evolves with the app.

Grok Bot still: ensure amillez plugin, kick off / babysit PR, human pings. Grok Bot does **not** replace Orca for the multi-agent DAG.

## Default path (needs orch)

1. **Eng bot intakes** the ask: success criteria, proof type, constraints; applies the [size gate](#size-gate).
2. Eng bot (or a kickoff hop) verifies [prerequisites](#prerequisites-needs-orch-only), then launches an **Opus 5.5 xhigh** coordinator session that owns the Orca Run (see [Model assignment](#model-assignment)).
3. Coordinator runs the [supervised Orca loop](#preferred-supervised-orca-loop) below and picks **worker `--agent` / `--model` / `--effort` per slice** from the chooser.
4. Eng bot arms babysit on the resulting PR(s) per [dispatch lifecycle](agent-dispatch-lifecycle.md#babysit-until-merged).

Do **not** collapse big work into one mega agent that owns every file. Do **not** keep the eng bot as a forever-orchestrator inside Slack/chat while spinning workers by hand unless the size gate said **small**.

## Preferred supervised Orca loop

Cite: [Orchestration — preferred supervised loop](https://www.onorca.dev/docs/cli/orchestration).

```text
run-create → task-create (+ deps as needed) → worker-start (claude|codex + model + effort + worktree)
  → check --wait (worker_done / escalation / question) → worker tasks for integrate + prove → babysit
```

Concrete shape (coordinator drives these):

```bash
orca orchestration run-create --objective "<thorough objective>" --json
orca orchestration task-create --spec "<isolated worker spec>" --task-title "<slice>" --json
orca orchestration worker-start \
  --task <taskId> \
  --worktree new-child \   # or: current — never two agents on one checkout
  --name <slug> \
  --agent claude \         # or: codex — NEVER cursor for coding
  --model <opaque-model-id> \
  --effort high \
  --setup run \
  --json

orca orchestration check --wait --types worker_done,escalation,question --timeout-ms 900000 --json
orca orchestration check --ack <deliveryId> --wait --types worker_done,escalation,question --timeout-ms 900000 --json
```

Notes from Orca docs:

- A **Run** is a durable namespace + coordinator inbox — it does not schedule workers by itself.
- A **Task** has spec, dependencies, status (`pending` → `ready` → `dispatched` → `completed`/`failed`/`blocked`).
- **Dispatch** is one attempt; completion authority is `worker_done` with `--outcome succeeded|failed` plus `taskId` + `dispatchId`.
- Do **not** use retired `orca orchestration run` / `run-stop` / `coordinator-start` — use Run + `worker-start`.
- After accepted `worker_done`, `worker-release` (or `worker-retain` if debugging). Prefer `worker-read` over leaving dead terminals open.
- Decision gates (`gate-create` / `gate-resolve`) and `ask` for blocking questions — do not rely on local TUI prompts for cross-agent decisions.

### Pipeline mapping

| Stage | Who | How |
| --- | --- | --- |
| **Plan (scout)** | Opus 5.5 xhigh coordinator | Recon blast radius; cut disjoint scopes; `task-create` with precise specs; assign chooser model/effort per task. |
| **Workers** | Claude Code / Codex via Orca | `worker-start --agent claude\|codex --model … --effort …`; disk modes below. |
| **Integrate** | Worker task (delegated) | Merge outputs, resolve conflicts, re-run unit/typecheck. Coordinator does **not** integrate — dispatch an integrate worker (often sequential `--worktree current`). |
| **Prove** | Prove hop on `agent-m1` | [Proof loop](agent-proof-feedback-loop.md); RN visual → Argent; **prove before PR**; sim mutex / max **2** sims. |
| **Babysit** | Eng bot (Grok) | Until `merged`\|`discarded`; PR listeners — does not replace Orca during the Run. |

## Worktrees and disk

**Hard rule:** parallel workers must **not** share one working tree. Same checkout = colliding git index, dirty files, locks, Metro/Pods. Map to Orca: do not start two `--worktree current` workers on the same checkout; use `new-child` (or sequential reuse of one tree).

On `agent-m1`, prefer disk-conscious modes in this order:

1. **Default under disk pressure / RN-sized repos:** one shared worktree, **sequential** workers — `worker-start … --worktree current` one at a time (or release then reuse). Fan-out is **temporal**. Saves N copies of `node_modules` / Pods.
2. **Limited parallel:** at most **2** worktrees (`new-child`) unless Agustín explicitly raises the cap. Prefer package-level cuts.
3. **If using multiple worktrees:** tear down / `worker-release` promptly after integrate; shared pnpm store where possible; stay aware of Colima/Docker disk. Branch naming stays `agent/<bot>/<slug>` when creating git branches outside Orca's naming, per [dispatch lifecycle](agent-dispatch-lifecycle.md#worktrees-on-agent-m1).

Hardware / device validation is **never** parallel — schedule after integrate (or as a single later hop).

## Prove

- Follow [agent proof feedback loop](agent-proof-feedback-loop.md).
- **RN / mobile visual proof:** prove hop **must** run on `agent-m1` with Argent (Orca emulator bridge is optional assist — Argent remains the RN proof path).
- **Prove before PR.** Do not open a prove-empty PR and backfill later.
- **Sim mutex on `agent-m1`:** one prove owner at a time for Argent/sim work; max **2** sims host-wide.

## Babysit

- Eng bot owns the workstream(s) until `merged` | `discarded`, per [babysit until merged](agent-dispatch-lifecycle.md#babysit-until-merged).
- A large Task may spawn an Orca Run + coordinator workstream that fans out child Dispatches; babysit covers the parent PR (and children if they land separately) until terminal.

## Roles

| Role | Owns |
| --- | --- |
| **Eng bot (Mark / Sam / Grok Bot)** | Intake, [size gate](#size-gate), prerequisites check, kick off coordinator / direct agent, ensure amillez plugin, arm babysit, human pings, verify final proof bar, merge/close. Does **not** replace Orca for the multi-agent DAG. |
| **Coordinator (Opus 5.5 xhigh)** | Inside Orca: `run-create`, decompose, `task-create`, `worker-start` with per-slice agent/model/effort, `check --wait`, route gates/`ask`. Does **not** implement, integrate, or validate — those are worker tasks. |
| **Worker agents** | Claude Code or Codex Dispatches. Slice-appropriate chooser pick; return `worker_done` with evidence. **No Cursor.** |

## Host matrix

| Host | Use for |
| --- | --- |
| **`agent-m1` + Orca + Claude Code / Codex** | **Only coding path** — small direct agents; large Orca Runs; prove (including Argent). |
| **Cursor cloud / My Machines / `--agent cursor`** | **Abandoned** for coding. Do not dispatch. |

## Model assignment

### Coordinator label: Opus 5.5 xhigh

- **Policy label:** **Opus 5.5 xhigh** — standing name for the large-work Orca coordinator (Agustín 2026-09-20; was Fable 5.1 High). Prefer this name in prompts, PR titles, and bot messages.
- **Harness:** Claude Code on `agent-m1` (Opus at **xhigh** effort), driving the Orca CLI.
- Plans / fans out via Orca; does **not** implement, integrate, or validate — those are worker tasks.

### Workers

- Assign **`--agent claude|codex`**, **`--model`**, **`--effort`** per slice from the [agent chooser](../policies/agent-use-policy.md#agent-chooser-examples) (Luna Max / Sol High / Opus High→xhigh).
- Do **not** inherit Opus 5.5 xhigh for every worker.
- `--model` / `--effort` apply to Claude and Codex launches only (Orca docs); we never pass Cursor.

**Rule:** apply the [size gate](#size-gate) first. Small → direct agent, no Orca Run. Large → Opus 5.5 xhigh coordinator inside Orca, then chooser-per-slice workers.

## Prompt fan-out skill

`orchestrate-agents` (amillez/agent-skills) still helps the coordinator write isolated task specs. **Runtime ownership, `worker_done`, and the DAG live in Orca** — the skill does not replace `run-create` / `worker-start` / `check --wait`.

## Out of scope / later

- Federated workers (`--on <remote>`) — optional; default stays local `agent-m1`.
- Wholesale Arena/Swarm from pstack — still deferred; see [Steal from pstack](steal-from-pstack.md).
- Do not use retired Orca commands (`orchestration run`, `run-stop`, `coordinator-start`).

## Comparison experiment (historical/abandoned)

**Abandoned 2026-09-18.** Cursor removed from the coding workflow. Standing path: `agent-m1` + Claude Code / Codex, with **Orca** for large multi-agent work. Do not resurrect the A/B experiment.

| Arm | Host | Status |
| --- | --- | --- |
| **A — agent-m1** | `agent-m1` Claude/Codex (+ Orca for large) | **Current** — orch label **Opus 5.5 xhigh**. |
| **B — Cursor cloud** | Cursor cloud | **Do not use.** |

## Anti-patterns

- Skipping the [size gate](#size-gate) — Orca Run for a rename, or one mega-agent for an epic.
- Using Orca without runtime up / Experimental orchestration enabled / skills installed.
- Collapsing large work into one mega session outside Orca (Mark trial lesson).
- Parallel workers on the same checkout (`--worktree current` twice).
- More than 2 parallel worktrees under disk pressure without an explicit raise.
- `--agent cursor` or any Cursor coding host.
- Claiming Argent/sim proof from anywhere other than `agent-m1`.
- Parallel sim proves or opening a PR before prove.
- Eng bot juggling N chats as forever-orchestrator instead of an Orca Run when the gate says large.
- Stamping Opus 5.5 xhigh on every worker; renaming the coordinator away from **Opus 5.5 xhigh** (or using Fable as orch default).
- Treating `orchestrate-agents` prompt text as a substitute for Orca Dispatches / `worker_done`.
- Retired `orca orchestration run` instead of `run-create` + `worker-start`.

## Related

- [Agent dispatch lifecycle](agent-dispatch-lifecycle.md) — worktrees, babysit, teardown
- [Agent proof feedback loop](agent-proof-feedback-loop.md) — thorough launch, Argent, Luna Max, media branch
- [Agent use policy](../policies/agent-use-policy.md) — host routing + chooser
- [Orca CLI overview](https://www.onorca.dev/docs/cli/overview)
- [Orca Orchestration](https://www.onorca.dev/docs/cli/orchestration)
- Skill: `orchestrate-agents` in [amillez/agent-skills](https://github.com/amillez/agent-skills) (spec writing; Orca owns the Run)
- [Steal from pstack](steal-from-pstack.md) — Arena/Swarm deferred
