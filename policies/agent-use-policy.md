# Agent use policy

Standing policy for **all agents** pointed at this repo.

Use imperative language. Follow this unless the **current chat** explicitly overrides for that one-off. Chat overrides win for one-off asks. Do not treat a one-off override as a new default.

Primary sources:

- [Cursor workshop — Model Selection & Token Efficiency](../sources/cursor-model-selection-token-efficiency.md)
- [Research digest 2026-09-12](../sources/research-digest-2026-09-12.md)

Heuristics and savings numbers are **as of the cited source**, not eternal.

---

## 1. Default model posture

- Default to **Auto → Balance**, or pick **Composer 2.5** when the task is discrete implementation / SWE-scoped coding.
- Do not lock the session (or the org) to a single provider or a single frontier model.
- Escalate model, effort, or context **deliberately**, with a reason you can state in one sentence.
- Do not start on Fable, max effort, Fast, or max context "just in case."

### Default picks (as of workshop)

| Situation | Default |
| --- | --- |
| Discrete coding / scoped SWE task | Composer 2.5 |
| Unsure, mixed, or org default | Auto → Balance |
| Planning / wide reasoning before a build | Grok 4.6 or Opus (or GPT 5.6 Sol when the job is planning + reading a large codebase) |
| Highly complex, wide surface, gnarly debug, visual-heavy | Fable — only after a cheaper path failed or the surface is clearly too wide |
| Writing / execution plans a human will read | Opus (sometimes better than Fable for this) |

### Agent chooser examples

Use this when you need a pick, not a philosophy. Leave **Fast** off by default. Escalate **one knob at a time**. De-escalate to Composer when the hard part is done.

| Situation | Model | Effort | Notes |
| --- | --- | --- | --- |
| Straightforward / super defined | Composer 2.5 | **low** (medium only if a few tool loops are needed) | Auto → Balance is OK if you are not picking. Files and success criteria are already clear. |
| High complexity, wide surface | Fable | **high** (→ xhigh only if still thrashing after a clear plan) | Escalate after cheaper paths fail, or the surface is obviously huge / visual / gnarly. Do not start here. |
| Reading / understanding a codebase | GPT 5.6 Sol or Grok 4.6 | **medium** | Prefer Ask mode (recon). Composer is also fine for cheaper navigation. Sol was the workshop pick for planning + reading large codebases. |
| General reasoning + implementation that still needs reasoning | Plan with Grok 4.6 → build with Composer 2.5 | Plan **medium/high**. Build **low/medium**. | If decisions keep appearing mid-build, stay on Grok (or escalate). Do not force Composer through ambiguity. |
| Writing / agreeing on a plan | Opus (or Grok 4.6) | **medium** → **high** if architecture tradeoffs matter | Use Opus when a human will read the plan. Do not implement in the same turn until the plan is agreed. |
| Mechanical chore (format, rename in known files, boilerplate with tests already green) | Composer 2.5 | **low** | Few edge cases, little verification needed. Lower effort before escalating model. |

Concrete picks:

1. Rename a prop in `UserCard.tsx` and fix call sites in that folder → **Composer 2.5**, **low**.
2. Auth broken for `@edu` emails; 12-line stack + `@` the auth folder → **Composer 2.5**, **medium**. If two wrong fixes: new chat + Grok plan, then Composer again.
3. New to the monorepo — where should a billing webhook live / what breaks → **Ask** + **GPT 5.6 Sol** or **Grok 4.6**, **medium** (recon only). Then a short Opus/Grok plan before a Composer build.
4. Draft a migration plan for splitting payments into a new service (a human will review / push back) → **Opus**, **high**. Implement later with Composer against the agreed plan.
5. Huge flaky race across web + RN + API; intermittent; two Composer loops already burned → **Fable**, **high**, debug/repro-first. After the root cause is pinned, drop to Composer for the surgical fix.

---

## 2. When to escalate

Escalate **one knob at a time**. Say why.

**Escalate the model** when:

- The task is wide, poorly bounded, or needs general reasoning across systems.
- Composer (or Balance) is spinning: wrong guesses, missed files, or a plan that does not survive contact with the repo.
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

De-escalate as soon as the hard part is done. After a strong-model plan, implement with Composer unless the remaining work still needs general reasoning.

---

## 3. Context hygiene

- **New chat per task.** Do not keep an eternal thread across unrelated jobs.
- `@`-mention the files, folders, logs, and past chats that matter. Do not dump a whole repo or a 30k-line file into the prompt.
- Paste only the relevant error lines, not the giant log.
- One task per turn. State success criteria ("done when…").
- If the thread has been compacted repeatedly or the agent is acting on blurry memory, **start a fresh chat**. Optionally `@` the old chat as a pointer, or carry a short written summary of decisions — not the whole transcript.
- Always-on rules ride every turn. Keep them short. Put long procedure in **skills** (lazy-loaded body).
- Do not enable MCPs you are not using. Audit unused ones.

---

## 4. Plan before build (non-trivial work)

For anything that is not a small, direct, already-scoped change:

1. **Recon** in Ask mode when the area is unfamiliar (read-only; safe).
2. **Plan** with a strong general-reasoning model. Get the shot clear: files, approach, risks, success criteria.
3. **Build** with Composer (or Balance) against that plan.
4. Split a feature into subtasks. Do not ask one turn to "do the whole epic."

If the human's ask is vague ("fix auth"), **stop and clarify** or enter Plan mode. Do not explore the repo by guessing.

---

## 5. Cost visibility

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

## 6. Rules, skills, and MCP hygiene

- Keep always-apply rules **short**. They are prefix and are re-fed every turn.
- Prefer **skills** for playbooks, checklists, and long how-tos. The body loads when relevant.
- Do not change always-on rules mid-session unless you mean to. That busts provider cache. The blip is small — still switch model or provider when the task needs it.
- Disable unused MCPs. Extra tool surface is extra prefix and extra chances to wander.
- Do not paste huge files "for context." Point at them.

### Custom Modes vs skills vs always-on rules

| Mechanism | Behavior | Use for |
| --- | --- | --- |
| **Always-on rules** | Re-fed every turn as prefix. | Short defaults only — a few lines. |
| **Skills** | Lazy-loaded when relevant (or invoked with `/`). | Playbooks, checklists, long how-tos. |
| **Custom Mode** | A skill **pinned** for the chat ("always on" for this session). | Repeatable workflows: migration mode, review mode, gardening. |

From `/`, pick a skill → **Use as Mode** (or ⌥⏎ / Alt+Enter). Do not duplicate a skill's body into always-on rules just to keep it loaded — that burns prefix every turn.

Source: [Cursor changelog — Custom modes](https://cursor.com/changelog) (Aug 2026).

After model bumps, re-eval top skills. See [playbooks/skill-and-plugin-regression.md](../playbooks/skill-and-plugin-regression.md).

---

## 7. Production vs throwaway AI code

Boris Cherny's frame (paraphrased, Sep 2026): **both modes are valid** — pick explicitly.

| Mode | Bar | Examples |
| --- | --- | --- |
| **Throwaway / prototype** | Black box OK. Low blast radius. You will discard or replace soon. | Spikes, mockups, one-off scripts, "does the API work?" probes. |
| **Production** | **Higher bar than human-written code.** Reviewable, owned, tested, maintainable. | Anything merged to `main`, shipped to users, or touched again in six months. |

Production guardrails (pick what fits your stack):

- Lint + tests + CI required before merge.
- Automated review (Bugbot, security scan) on PRs.
- Owner who can explain the change.
- Fuzzing / e2e where blast radius warrants it.

If production agent code misses the bar: escalate model or effort, invest in skills/rules, steer more — or have the agent pay down debt in the repo. Do not silently merge slop because it "mostly works."

Source: [Boris Cherny on X](https://x.com/bcherny/status/2098217571153838124) (Sep 2026).

---

## 8. Research hygiene

When researching **Anthropic / Claude tooling**, prefer primary builder accounts (e.g. [@ClaudeDevs](https://x.com/ClaudeDevs), shipping notes, official docs) over marketing accounts. Marketing posts lag product reality.

---

## 9. Overrides

This policy applies to **all agents**. It is not scoped to a team, product, or bot flavor.

- A **chat override** wins for that ask only ("use Fable", "stay in this thread", "skip the plan").
- Do not promote a chat override into standing policy. That takes a PR to this repo.
- If a playbook and this policy conflict, follow this policy for defaults, the playbook for the how-to, and the chat for the one-off.

---

## Related

- [Playbook: Model selection & token efficiency](../playbooks/model-selection-and-token-efficiency.md)
- [Playbook: Cursor Projects](../playbooks/cursor-projects.md)
- [Playbook: Eng team of bots](../playbooks/eng-team-of-bots.md)
- [Playbook: Skill and plugin regression](../playbooks/skill-and-plugin-regression.md)
- [Source: workshop](../sources/cursor-model-selection-token-efficiency.md)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
