# Agent use policy

Standing policy for **all agents** pointed at this repo.

Use imperative language. Follow this unless the **current chat** explicitly overrides for that one-off. Chat overrides win for one-off asks. Do not treat a one-off override as a new default.

Primary sources:

- [Cursor workshop — Model Selection & Token Efficiency](../sources/cursor-model-selection-token-efficiency.md)
- [Research digest 2026-09-12](../sources/research-digest-2026-09-12.md)

Heuristics and savings numbers are **as of the cited source**, not eternal.

---

## 1. Coding host routing

For heavy coding / engineering agent work:

- **Primary host**: `agent-m1` (dedicated Mac) running **Claude Code + Codex only**. No Cursor installed.
- **Cursor cloud fallback**: Use only when `agent-m1` is unavailable (offline / unreachable).
  - Straightforward / super defined → **Composer**
  - General code / light reasoning → **Grok 4.6**

Do not use Cursor as the default path when `agent-m1` is up. The Claude vs Codex chooser on `agent-m1` is still TBD.

**Proof before done** (see [agent proof feedback loop](../playbooks/agent-proof-feedback-loop.md)):

- **Thorough launch prompt.** Every Claude Code / Codex / Cursor cloud launch states goal, scope, skills to invoke by name, and the proof expected. See [thorough launch prompt](../playbooks/agent-proof-feedback-loop.md#thorough-launch-prompt).
- **Require proof.** Not done at green CI or changed files — done when the agent has produced and inspected task-relevant proof.
- **Flexible evidence.** Screenshots for UI; logs, test output, exit codes, or traces for non-visual work. No screenshots for show.
- **Argent on `agent-m1` for RN/UI.** Use Argent CLI + MCP with provisioned simulators/AVDs; skills alone are not enough.
- **Mismatch → iterate or report the blocker with evidence.** Never claim "verified" without reading the proof.
- **Tear down after proof.** Shut down sims/emulators and dev servers the agent started. See [teardown after proof](../playbooks/agent-proof-feedback-loop.md#teardown-after-proof).

**Dispatch and worktrees** (see [agent dispatch lifecycle](../playbooks/agent-dispatch-lifecycle.md)):

- **Worktree per agent.** Dispatch each workstream into its own `git worktree` on branch `agent/<bot>/<slug>`, from an up-to-date base. Agents never work in the `main` checkout.
- **One agent per tree.** Parallel work uses separate worktrees with disjoint paths.
- **Teardown after merge or abandon.** Remove the worktree and delete the local branch. No dirty or orphan trees left on disk.

**Permissions bypass on `agent-m1` only**: Run Claude Code and Codex with permission prompts disabled for unattended agent work. Use the CLI's skip-permissions flag (Claude Code) or equivalent sandbox bypass option (Codex) so agents are not blocked waiting for interactive approval. This applies only to the trusted `agent-m1` host, not Cursor cloud or other machines.

**Cursor cloud launches** (per eng-bot Mark's 1:1 feedback):

- **Never omit model, effort, or Fast.** Account or team defaults are not the Agent chooser. Omitting `model` so it falls through to Sonnet (or any non-chooser default) is a policy violation.
- **Always pass Fast `false`** unless the human explicitly asks for Fast.
- **Map effort to the launch param.** Cursor cloud often exposes effort as `reasoning`, not a separate effort field. "Max effort" = `reasoning: max`.
- **Private-ref docs / knowledge PRs:** if the agent needs private reference repos, set up a **multi-repo environment up front**. Do not expect the agent to invent trees without clone/ref access.

---

## 2. Default model posture

- Do not lock the session (or the org) to a single provider or a single frontier model.
- Escalate model, effort, or context **deliberately**, with a reason you can state in one sentence.
- Do not start on Fable, max effort, Fast, or max context "just in case."

### Default picks

| Situation | Model | Notes |
| --- | --- | --- |
| Very direct / super defined | **GPT 5.6 Luna** | Mechanical, files + success criteria clear |
| General code / some reasoning | **GPT 5.6 Sol** | Default for most implementation + light reasoning. Effort **High** by default; **xhigh** when needed |
| UI work | **Opus 5** | Product UI / visual taste. Effort **High** by default; **xhigh** when needed |
| Large reasoning, orchestration, very complex / wide surface | **Fable 5.1** | Escalate after cheaper paths fail; do not start here |

### Agent chooser examples

Use this when you need a pick, not a philosophy. Leave **Fast** off by default. Escalate **one knob at a time**. De-escalate when the hard part is done.

| Situation | Model | Effort | Notes |
| --- | --- | --- | --- |
| Straightforward / super defined | **GPT 5.6 Luna** | **Max** (reasoning Max) | Files and success criteria are already clear. |
| General reasoning + implementation | **GPT 5.6 Sol** | **High** (reasoning High; → **xhigh** if still needs reasoning after a few loops) | Default for most implementation + light reasoning. |
| UI work | **Opus 5** | **High** (→ **xhigh** if taste/architecture tradeoffs) | Product UI / visual taste. |
| High complexity, wide surface | **Fable 5.1** | **medium** (→ **high** → **xhigh** only if still thrashing after a clear plan) | Escalate after cheaper paths fail, or the surface is obviously huge / visual / gnarly. Do not start here. |
| Writing / agreeing on a plan | **Opus 5** | **High** (→ **xhigh** if architecture tradeoffs matter) | Use Opus when a human will read the plan. Do not implement in the same turn until the plan is agreed. |
| Mechanical chore (format, rename in known files, boilerplate with tests already green) | **GPT 5.6 Luna** | **Max** (reasoning Max) | Few edge cases, little verification needed. Lower effort before escalating model. |

Concrete picks:

1. Rename a prop in `UserCard.tsx` and fix call sites in that folder → **GPT 5.6 Luna**, **Max effort / reasoning Max**.
2. Auth broken for `@edu` emails; 12-line stack + `@` the auth folder → **GPT 5.6 Sol**, **High** (→ **xhigh** if needed). If two wrong fixes: new chat + plan, then implement again.
3. New to the monorepo — where should a billing webhook live / what breaks → **Ask** + **GPT 5.6 Sol**, **High** (recon only). Then a short plan before the build.
4. Draft a migration plan for splitting payments into a new service (a human will review / push back) → **Opus 5**, **High** (→ **xhigh** if architecture tradeoffs). Implement later against the agreed plan.
5. Huge flaky race across web + RN + API; intermittent; two loops already burned → **Fable 5.1**, **medium** (→ **high** if needed), debug/repro-first. After the root cause is pinned, drop to Luna (Max effort / reasoning Max) or Sol (High) for the surgical fix.

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

Escalate **one knob at a time** (model, effort, context, Fast). De-escalate when the hard part is done.

**Escalate context** when:

- The work is an extremely complex refactor with ongoing decisions in one thread.
- You still `@`-mention the files and folders that matter. A bigger window is not a substitute for anchors.

**Do not escalate** when:

- The ask is a small, local change.
- You have not scoped the files, success criteria, or repro.
- You are only trying to go faster in the queue (that is Fast, not intelligence).

De-escalate as soon as the hard part is done. After a strong-model plan, implement with a lighter model (Luna at Max effort / reasoning Max for mechanical work, Sol at High for general implementation) unless the remaining work still needs complex reasoning.

---

## 4. Context hygiene

- **New chat per task.** Do not keep an eternal thread across unrelated jobs.
- `@`-mention the files, folders, logs, and past chats that matter. Do not dump a whole repo or a 30k-line file into the prompt.
- Paste only the relevant error lines, not the giant log.
- One task per turn. State success criteria ("done when…").
- If the thread has been compacted repeatedly or the agent is acting on blurry memory, **start a fresh chat**. Optionally `@` the old chat as a pointer, or carry a short written summary of decisions — not the whole transcript.
- Always-on rules ride every turn — keep them **short**; put long procedure in **skills** (lazy-loaded). Custom Modes pin a skill for one chat; see [Cursor changelog](https://cursor.com/changelog) if you need harness details.
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
- plus Fast
- plus a fat always-on prompt
- plus an eternal chat

Fast is **queue priority**, not a smarter model. Use it sparingly.

Workshop claim (snapshot): an org-wide Auto router policy saved **30–60% overnight**. Prefer Balance as the org default unless a chat or owner says otherwise.

If spend looks wrong, inspect prompting and model class first. Workshop examples: ~10–12× from a vague vs specific prompt on the same model; ~175× when that stacks with the wrong expensive model. Each lever is modest (~12–15%); they compound.

---

## 7. Rules, skills, and MCP hygiene

- Keep always-apply rules **short**. They are prefix and are re-fed every turn.
- Prefer **skills** for playbooks, checklists, and long how-tos. The body loads when relevant.
- Do not change always-on rules mid-session unless you mean to. That busts provider cache. The blip is small — still switch model or provider when the task needs it.
- Disable unused MCPs. Extra tool surface is extra prefix and extra chances to wander.
- Do not paste huge files "for context." Point at them.

---

## 8. Production vs throwaway AI code

[Boris Cherny's frame](https://x.com/bcherny/status/2098217571153838124) (Sep 2026): **both modes are valid** — pick explicitly before the agent starts. Throwaway work (spikes, mockups, one-off probes) can be a black box with low blast radius. Anything merged to `main` or touched again in six months is **production** and needs a **higher bar than human-written code**: reviewable, owned, tested, CI + automated review where you have it.

If production agent output misses the bar, escalate model or effort, invest in skills/rules, or have the agent pay down debt — do not merge slop because it "mostly works."

---

## 9. Research hygiene

When researching **Anthropic / Claude tooling**, prefer primary builder accounts (e.g. [@ClaudeDevs](https://x.com/ClaudeDevs), shipping notes, official docs) over marketing accounts. Marketing posts lag product reality.

---

## 10. Overrides

This policy applies to **all agents**. It is not scoped to a team, product, or bot flavor.

- A **chat override** wins for that ask only ("use Fable", "stay in this thread", "skip the plan").
- Do not promote a chat override into standing policy. That takes a PR to this repo.
- If a playbook and this policy conflict, follow this policy for defaults, the playbook for the how-to, and the chat for the one-off.

---

## Related

- [Playbook: Model selection & token efficiency](../playbooks/model-selection-and-token-efficiency.md)
- [Playbook: Cursor Projects](../playbooks/cursor-projects.md)
- [Playbook: Eng team of bots](../playbooks/eng-team-of-bots.md)
- [Playbook: Agent dispatch lifecycle](../playbooks/agent-dispatch-lifecycle.md)
- [Source: workshop](../sources/cursor-model-selection-token-efficiency.md)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
