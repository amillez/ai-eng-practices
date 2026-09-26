# Agent use policy

Standing policy for **all agents** pointed at this repo.

Use imperative language. Follow this unless the **current chat** explicitly overrides for that one-off. Chat overrides win for one-off asks. Do not treat a one-off override as a new default.

Primary sources:

- [Cursor workshop — Model Selection & Token Efficiency](../sources/cursor-model-selection-token-efficiency.md)
- [Research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
- [Friday digest 2026-09-18](../sources/friday-digest-2026-09-18.md)

Heuristics and savings numbers are **as of the cited source**, not eternal.

---

## 1. Coding host routing

For heavy coding / engineering agent work:

- **Only coding host**: `agent-m1` (dedicated Mac) running **Claude Code + Codex only**. No Cursor installed. No Cursor cloud coding path. No Cursor My Machines / self-hosted Cursor worker / `register-worker-dir`.
- **Grok Bot** remains the chat/control plane (intake, dispatch, babysit, proof orchestration). It does **not** code on Cursor.
- **Claude vs Codex** on `agent-m1` is decided by the model lanes below plus the [Claude Code usage > 70%](#claude-code-usage--70) rule: Claude Code (Opus 5.5 / Fable 5.1) by default; Codex for GPT 6 Luna work and for GPT 6 Sol when Claude Code usage is above 70%.

Do **not** use Cursor Composer, Cursor cloud agents, Cursor Projects as a coding host, or Fast-mode Cursor notes as a coding path.

**Model role labels → Claude Code / Codex (as of 2026-09-25):**

Policy keeps the role names (Luna / Sol / Opus / Fable) as **labels** and pins each to a verified CLI model id on `agent-m1` (Claude Code 2.1.282, Codex CLI 0.157.0). If a lane cannot run on either harness, use the nearest equivalent or skip that lane.

| Policy label | Intent | Run on | CLI pick (verified 2026-09-25) |
| --- | --- | --- | --- |
| **Luna** — GPT 6 Luna (Max) | Very direct / super defined; mechanical; visual-verify | **Codex** | `codex exec -m gpt-6-luna -c model_reasoning_effort=max` |
| **Opus** — Opus 5.5 (High) | General code / some reasoning **and** UI work (default) | **Claude Code** | `claude --model claude-opus-5-5 --effort high` |
| **Sol** — GPT 6 Sol | Fallback for general code (**xHigh**) and UI (**High**) when [Claude Code usage > 70%](#claude-code-usage--70) | **Codex** | General: `codex exec -m gpt-6-sol -c model_reasoning_effort=xhigh` · UI: `… model_reasoning_effort=high` |
| **Opus 5.5 xhigh** | Large-work **Orca coordinator** default | **Claude Code** driving Orca CLI | `claude --model claude-opus-5-5 --effort xhigh`; coordinator only plans/dispatches/waits (does not integrate/validate) |
| **Fable** — Fable 5.1 (Medium → High/xhigh) | Large reasoning / gnarly escalate (non-orch) | **Claude Code** | Fable 5.1 at **Medium**, escalate to **High** then **xhigh** one step at a time (Opus 5.5 at high effort if Fable unavailable). Replan/split if still thrashing. **Not** the Orca coordinator default (**Opus 5.5 xhigh**) |
| **Composer / Grok (Cursor lanes)** | Historical Cursor coding lanes | **Skip** — no Cursor coding host | Nearest: general code → Opus 5.5 High (or GPT 6 Sol xHigh over 70% usage) |

Bot orchestrators (Grok Bots) pick **Claude vs Codex** from the lanes above: Claude Code (Opus 5.5) by default for general code and UI; Codex (GPT 6 Sol) when Claude Code usage is above 70%; Codex (GPT 6 Luna) for super-defined work.

**Proof before done** (see [agent proof feedback loop](../playbooks/agent-proof-feedback-loop.md)):

- **Thorough launch prompt.** Every Claude Code / Codex launch states goal, scope, skills to invoke by name, and the proof expected. See [thorough launch prompt](../playbooks/agent-proof-feedback-loop.md#thorough-launch-prompt).
- **Require proof.** Not done at green CI or changed files — done when the agent has produced and inspected task-relevant proof.
- **Flexible evidence.** Screenshots or videos for UI; logs, test output, exit codes, or traces for non-visual work. No screenshots for show.
- **Proof media on `media` branch.** Never commit screenshots/videos to the PR branch. Link them in the PR body via GitHub blob URLs, not raw URLs. See [proof media hosting](../playbooks/agent-proof-feedback-loop.md#proof-media-hosting).
- **Visual verification (Luna role).** Inspect screenshots/videos with a **Codex GPT 6 Luna** session (`gpt-6-luna`, effort Max) that reports pass/fail against the success criteria — not a Cursor cloud subagent. Coding agents do not burn heavy turns on it; non-visual proof stays with the coding agent. See [visual verification](../playbooks/agent-proof-feedback-loop.md#visual-verification-luna-max-subagent).
- **Argent on `agent-m1` for RN/UI.** Use Argent CLI + MCP with provisioned simulators/AVDs; skills alone are not enough.
- **Mismatch → iterate or report the blocker with evidence.** Never claim "verified" without reading the proof.
- **Tear down after proof.** Shut down sims/emulators, dev servers, and matching Expo CLI processes (`expo/bin/cli`, `expo start`, `expo run`), then verify no used Metro port is listening. See [teardown after proof](../playbooks/agent-proof-feedback-loop.md#teardown-after-proof).

**Amillez plugin before coding** (see [`amillez/agent-skills`](https://github.com/amillez/agent-skills) `scripts/ensure-install.sh`):

- **Before coding on `agent-m1`:** run amillez plugin **host** ensure (`./scripts/ensure-install.sh` from the agent-skills checkout, or `AMILLEZ_SKILLS_ROOT`; thin alias `ensure-project.sh`). Default = **core+mobile** at **`~/.claude` / `~/.agents`** (skills + user rules `amillez-models.md` + stamp). **No `~/.codex`** — Codex uses `~/.agents`. If the pack is **missing**, install core+mobile at user root — do **not** link/copy the plugin into the project/worktree. If already present, continue (refresh only when policy/skills changed or a human asks / `--force`). Optionally also commit selected stack skills into the project for teammates (e.g. `uniwind`) even though they are on the device — not a dump of the whole mobile set. Project `verify-*` stay in-repo.
- **Grok Bot dispatch prompts** to Claude Code / Codex **must include**: ensure amillez **core+mobile** plugin on the **host** first (not a per-project path link).

**Dispatch and worktrees** (see [agent dispatch lifecycle](../playbooks/agent-dispatch-lifecycle.md)):

- **Worktree per agent.** Dispatch each workstream into its own `git worktree` on branch `agent/<bot>/<slug>`, from an up-to-date base. Agents never work in the `main` checkout.
- **One agent per tree.** Parallel work uses separate worktrees with disjoint paths.
- **Parent owns `agent-m1` Shell.** Grok Bot **executor** Task subagents cannot pass `machineId` to Shell (box only). Parent must run agent-m1 Shell/Read with `machineId` (`cbfdfd05-8447-4018-ad6b-26eb8a0e83b1`) for Claude launch / worktree create on the Mac. Executors stay fine for `gh`/API/box work. Canonical `claude --bg` recipe + `claude respawn` unblock: [dispatch lifecycle](../playbooks/agent-dispatch-lifecycle.md#canonical-claude-code-background-launch-on-agent-m1).
- **Size gate before launch.** **Small** (single surface/package, one PR, clear blast radius, one focused session) → dispatch the **corresponding agent directly** (Luna/Opus/Sol from this chooser on Claude Code / Codex). **No Orca Run. No orchestrator.** **Large / needs orch** (multi-surface, multi-package, parallelizable, multi-PR, multi-session, unclear blast radius, or more than one focused session) → **Orca** Run on `agent-m1` with an **Opus 5.5 xhigh** coordinator (`claude --model claude-opus-5-5 --effort xhigh`). Prerequisites: `orca status --json`, Settings → Experimental orchestration, skills `orca-cli` + `orchestration`. Preferred loop: `run-create` → `task-create` → `worker-start --agent claude|codex --model … --effort … --worktree new-child|current` → `check --wait`. Workers get **model + effort per slice** from this chooser — not all Opus xhigh. Coordinator only plans/dispatches/waits (does not integrate/validate). Grok Bot still ensures amillez plugin + babysits PRs; it does not replace Orca for the DAG. Do not collapse to one mega agent; do not skip the gate; do not use Cursor. See [big-work orchestration](../playbooks/big-work-orchestration.md) · [Orca orchestration docs](https://www.onorca.dev/docs/cli/orchestration).
- **Babysit until merged.** Bots own the workstream until `merged` or `discarded`; agent idle is not done. Promised pings need a finite watch, not a lone background Shell wake. See [babysit until merged](../playbooks/agent-dispatch-lifecycle.md#babysit-until-merged).
- **Teardown after merge or abandon.** Remove the worktree and delete the local branch; runtime teardown and Metro-port verification still apply. No dirty or orphan trees left on disk.

**Permissions bypass on `agent-m1` only**: Run Claude Code and Codex with permission prompts disabled for unattended agent work. Use the CLI's skip-permissions flag (Claude Code) or equivalent sandbox bypass option (Codex) so agents are not blocked waiting for interactive approval. This applies only to the trusted `agent-m1` host.

**Claude Code / Codex launches** (eng-bot Mark's launch discipline, adapted):

- **Ensure amillez plugin first.** Every dispatch prompt must tell the coding agent (or the bot must run it before launch) to run `agent-skills` `scripts/ensure-install.sh` (host **core+mobile** at `~/.claude` / `~/.agents`; no `~/.codex`). `ensure-project.sh` is a **thin alias only** (ignores project path) — do not name it as the primary. Missing pack → install at user root; already present → continue. Do not install the device plugin into the project tree. Optionally also commit selected stack skills for teammates (e.g. `uniwind`) even though they are on the device.
- **Never omit model or effort.** Harness defaults are not the Agent chooser.
- **Fast / queue-priority knobs:** leave off unless the human explicitly asks (historical Cursor Fast — not a coding path).
- **Private-ref docs / knowledge PRs:** if the agent needs private reference repos, set up clone/ref access up front on `agent-m1`. Do not expect the agent to invent trees without access.

---

## 2. Default model posture

- Do not lock the session (or the org) to a single provider or a single frontier model.
- Escalate model, effort, or context **deliberately**, with a reason you can state in one sentence.
- Do not start on Fable-role / Opus xhigh, max effort, or max context "just in case."

### Default picks

| Situation | Model (effort) | Harness | Notes |
| --- | --- | --- | --- |
| Very direct / super defined | **GPT 6 Luna** (**Max**) | Codex (`gpt-6-luna`) | Mechanical, files + success criteria clear |
| General code / some reasoning | **Opus 5.5** (**High**) | Claude Code (`claude-opus-5-5`) | Default for most implementation + light reasoning. **Claude Code usage > 70% → GPT 6 Sol (xHigh)** on Codex (`gpt-6-sol`) |
| UI work | **Opus 5.5** (**High**) | Claude Code (`claude-opus-5-5`) | Product UI / visual taste. **Claude Code usage > 70% → GPT 6 Sol (High)** on Codex (`gpt-6-sol`) |
| Large-work orchestration (needs orch) | **Opus 5.5** (**xHigh**) coordinator inside **Orca** | Claude Code + Orca CLI | Size gate → Orca Run. Workers: `worker-start --agent claude|codex` + chooser model/effort. Coordinator does not integrate/validate. No Cursor. |
| Large reasoning (non-orch) | **Fable 5.1** (**Medium** → High/xhigh) | Claude Code | Hard single-agent reasoning. Escalate effort one step at a time. |

#### Claude Code usage > 70%

Before launching a Claude Code lane (general code or UI), check plan usage on `agent-m1`: run `/usage` (or `/status`) in a Claude Code session — it shows plan usage for the current window. If the current window is **above 70%**, route that task to Codex **GPT 6 Sol** instead (**xHigh** for general code, **High** for UI). At or below 70%, stay on **Opus 5.5 High**. Orca coordinator (Opus 5.5 xHigh) and Fable lanes are unaffected; if usage is exhausted, say so and pick the nearest Codex lane rather than stalling.

### Agent chooser examples

Use this when you need a pick, not a philosophy. Leave queue-priority / Fast knobs off by default. Escalate **one knob at a time**. De-escalate when the hard part is done.

| Situation | Model | Effort | Harness | Notes |
| --- | --- | --- | --- | --- |
| Straightforward / super defined | **GPT 6 Luna** | **Max** | Codex | Files and success criteria are already clear. |
| General reasoning + implementation | **Opus 5.5** (usage > 70% → **GPT 6 Sol**) | **High** (Sol: **xHigh**) | Claude Code (Sol: Codex) | Default for most implementation + light reasoning. |
| UI work | **Opus 5.5** (usage > 70% → **GPT 6 Sol**) | **High** (Sol: **High**) | Claude Code (Sol: Codex) | Product UI / visual taste. |
| Large-work orchestration (needs orch) | **Opus 5.5** (Orca coordinator) | **xHigh** | Claude Code + Orca | Prefer **Opus 5.5 xhigh** label. Workers via Orca `--agent claude|codex` + chooser — not all Opus xhigh. Coordinator does not integrate/validate. No Cursor. |
| Large reasoning / gnarly escalate (non-orch) | **Fable 5.1** | **Medium** (→ High → xhigh) | Claude Code | Escalate **effort** for hard single-agent work — not the Orca coordinator default. |
| Writing / agreeing on a plan | **Opus 5.5** | **High** (→ **xhigh** if architecture tradeoffs matter) | Claude Code | Use Opus when a human will read the plan. Do not implement in the same turn until the plan is agreed. |
| Mechanical chore (format, rename in known files, boilerplate with tests already green) | **GPT 6 Luna** | **Max** | Codex | Few edge cases, little verification needed. |
| Visual proof verification (screenshots/videos) | **GPT 6 Luna** | **Max** | Codex | Verification-only session on agent-m1; reports pass/fail. Never implements. Not a Cursor cloud subagent. |

Concrete picks:

1. Rename a prop in `UserCard.tsx` and fix call sites in that folder → **GPT 6 Luna** (Codex), **Max effort**.
2. Auth broken for `@edu` emails; 12-line stack + `@` the auth folder → **Opus 5.5** (Claude Code), **High** (Claude Code usage > 70% → **GPT 6 Sol** xHigh on Codex). If two wrong fixes: new chat + plan, then implement again.
3. New to the monorepo — where should a billing webhook live / what breaks → **Ask** + **Opus 5.5** (Claude Code), **High** (recon only; > 70% usage → GPT 6 Sol xHigh). Then a short plan before the build.
4. Draft a migration plan for splitting payments into a new service (a human will review / push back) → **Opus 5.5** (Claude Code), **High** (→ **xhigh** if architecture tradeoffs). Implement later against the agreed plan.
5. Huge flaky race across web + RN + API; intermittent; two loops already burned → **Fable 5.1** (Claude Code), **Medium** (→ **High** / **xhigh** if needed), debug/repro-first. After the root cause is pinned, drop to GPT 6 Luna Max (Codex) or Opus 5.5 High for the surgical fix.

---

## 3. When to escalate

Escalate **one knob at a time**. Say why.

**Escalate the model** when:

- The task is wide, poorly bounded, or needs general reasoning across systems.
- The current model is spinning: wrong guesses, missed files, or a plan that does not survive contact with the repo.
- The human asked for a plan they will actually read, or for a hard architectural call.

**Escalate effort** when:

- The task is correctly scoped and the model is the right class, but it needs more tool loops to finish.
- Do not raise effort to compensate for a vague prompt. Clarify first.

**Lower effort** when (cost lever — as of Sep 2026 signals from Thariq / jxnlco):

- The task is mechanical, well-specified, and needs **less verification** or fewer edge cases (rename, format, straightforward refactor with tests).
- The agent is over-verifying routine work — extra file reads, redundant tool loops, "speedrun cheating" at low effort is often what you want.
- Do not raise effort to paper over ambiguity. Fix the prompt or plan first.

Escalate **one knob at a time** (model, effort, context). De-escalate when the hard part is done. Queue-priority / Fast knobs are not a coding path.

**Escalate context** when:

- The work is an extremely complex refactor with ongoing decisions in one thread.
- You still `@`-mention the files and folders that matter. A bigger window is not a substitute for anchors.

**Do not escalate** when:

- The ask is a small, local change.
- You have not scoped the files, success criteria, or repro.
- You are only trying to go faster in the queue (that is Fast, not intelligence).

De-escalate as soon as the hard part is done. After a strong-model plan, implement with a lighter model (GPT 6 Luna at Max for mechanical work, Opus 5.5 High — or GPT 6 Sol xHigh when Claude Code usage > 70% — for general implementation) unless the remaining work still needs complex reasoning.

---

## 4. Context hygiene

- **New chat per task.** Do not keep an eternal thread across unrelated jobs.
- `@`-mention the files, folders, logs, and past chats that matter. Do not dump a whole repo or a 30k-line file into the prompt.
- Paste only the relevant error lines, not the giant log.
- One task per turn. State success criteria ("done when…").
- If the thread has been compacted repeatedly or the agent is acting on blurry memory, **start a fresh chat**. Optionally `@` the old chat as a pointer, or carry a short written summary of decisions — not the whole transcript.
- Always-on rules ride every turn — keep them **short**; put long procedure in **skills** (lazy-loaded). Prefer Claude Code / Codex project skills over always-on rules.
- Do not enable MCPs you are not using. Audit unused ones.

---

## 5. Plan before build (non-trivial work)

For anything that is not a small, direct, already-scoped change:

1. **Recon** in Ask mode when the area is unfamiliar (read-only; safe).
2. **Plan** with a strong general-reasoning model. Get the shot clear: files, approach, risks, success criteria.
3. **Build** with an appropriate model against that plan.
4. Split a feature into subtasks. Do not ask one turn to "do the whole epic."

If the human's ask is vague ("fix auth"), **stop and clarify** or enter Plan mode. Do not explore the repo by guessing.

---

## 6. Cost visibility

You are billed for **tokens in and out of the model**, not for most harness/tool actions (search, grep, and similar were called out as free in the workshop). Output tokens cost more than input. Cache reads are cheaper than fresh input.

Do **not** freestyle this combo without a stated need:

- frontier / most expensive model
- plus max effort
- plus a fat always-on prompt
- plus an eternal chat

Workshop claim (snapshot, Cursor-era): an org-wide Auto router policy saved **30–60% overnight**. On agent-m1, prefer the chooser defaults above; do not invent a Cursor Balance/Auto coding path.

If spend looks wrong, inspect prompting and model class first. Workshop examples: ~10–12× from a vague vs specific prompt on the same model; ~175× when that stacks with the wrong expensive model. Each lever is modest (~12–15%); they compound.

---

## 7. Rules, skills, and MCP hygiene

- Keep always-apply rules **short**. They are prefix and are re-fed every turn.
- Prefer **skills** for playbooks, checklists, and long how-tos. The body loads when relevant.
- Do not change always-on rules mid-session unless you mean to. That busts provider cache. The blip is small — still switch model or provider when the task needs it.
- Disable unused MCPs. Extra tool surface is extra prefix and extra chances to wander.
- Do not paste huge files "for context." Point at them.

---

## 8. Integrations: MCP vs CLI

When both a dedicated MCP / connector and an ad-hoc CLI/`curl` path exist for the **same** service job, **prefer MCP**.

**Prefer MCP** when a connector exists (Notion, GitHub, Slack, X, etc.), when auth / pagination / structured results matter, or when bots should stay on the sanctioned tool surface (`GetDynamicTools` → `CallDynamicTool`) instead of scraping or inventing HTTP.

**Only exception:** a paid MCP with no credits left (e.g. X once credits run out) falls back to the web for that job; return to the MCP when credits are back.

**Prefer CLI** when no MCP exists; for CLI-native host tooling (`git`, `gh` for forge ops already done that way, Orca CLI, Argent CLI on `agent-m1`, package managers); or for one-off scripts / pipes / batch shell MCP does not cover well.

**Anti-patterns:** signed-in browser or invented HTTP when an MCP exists; dual-pathing MCP + CLI for the same mutation without a reason; enabling unused MCPs (see §7).

Decision checklist: [MCP vs CLI](../playbooks/mcp-vs-cli.md). Source: [Friday digest 2026-09-18](../sources/friday-digest-2026-09-18.md).

---

## 9. Production vs throwaway AI code

[Boris Cherny's frame](https://x.com/bcherny/status/2098217571153838124) (Sep 2026): **both modes are valid** — pick explicitly before the agent starts. Throwaway work (spikes, mockups, one-off probes) can be a black box with low blast radius. Anything merged to `main` or touched again in six months is **production** and needs a **higher bar than human-written code**: reviewable, owned, tested, CI + automated review where you have it.

If production agent output misses the bar, escalate model or effort, invest in skills/rules, or have the agent pay down debt — do not merge slop because it "mostly works."

---

## 10. Research hygiene

When researching **Anthropic / Claude tooling**, prefer primary builder accounts (e.g. [@ClaudeDevs](https://x.com/ClaudeDevs), shipping notes, official docs) over marketing accounts. Marketing posts lag product reality.

---

## 11. Overrides

This policy applies to **all agents**. It is not scoped to a team, product, or bot flavor.

- A **chat override** wins for that ask only ("use Fable", "stay in this thread", "skip the plan").
- Do not promote a chat override into standing policy. That takes a PR to this repo.
- If a playbook and this policy conflict, follow this policy for defaults, the playbook for the how-to, and the chat for the one-off.

---

## Related

- [Playbook: Model selection & token efficiency](../playbooks/model-selection-and-token-efficiency.md)
- [Playbook: MCP vs CLI](../playbooks/mcp-vs-cli.md)
- [Playbook: Cursor Projects](../playbooks/cursor-projects.md) — **historical**; coding host is Claude/Codex on agent-m1
- [Playbook: Eng team of bots](../playbooks/eng-team-of-bots.md)
- [Playbook: Agent dispatch lifecycle](../playbooks/agent-dispatch-lifecycle.md)
- [Playbook: Big-work orchestration](../playbooks/big-work-orchestration.md)
- [Source: workshop](../sources/cursor-model-selection-token-efficiency.md)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
- [Source: Friday digest 2026-09-18](../sources/friday-digest-2026-09-18.md)
