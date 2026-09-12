# Agent use policy

Standing policy for **TSCOB + personal engineering bots** (including Grok Bot specialists and Cursor agents pointed at this repo).

Use imperative language. Follow this unless the **current chat** explicitly overrides for that one-off. Chat overrides win for one-off asks. Do not treat a one-off override as a new default.

Primary source: [Cursor workshop — Model Selection & Token Efficiency](../sources/cursor-model-selection-token-efficiency.md). Heuristics and savings numbers are **as of the workshop**, not eternal.

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

---

## 7. Overrides

This policy is for **TSCOB + personal** engineering bots.

- A **chat override** wins for that ask only ("use Fable", "stay in this thread", "skip the plan").
- Do not promote a chat override into standing policy. That takes a PR to this repo.
- If a playbook and this policy conflict, follow this policy for defaults, the playbook for the how-to, and the chat for the one-off.

---

## Related

- [Playbook: Model selection & token efficiency](../playbooks/model-selection-and-token-efficiency.md)
- [Source note](../sources/cursor-model-selection-token-efficiency.md)
