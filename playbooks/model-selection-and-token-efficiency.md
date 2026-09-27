# Model selection & token efficiency

Opinionated playbook for humans and engineering bots. Distilled from Cursor's workshop **[Model Selection & Token Efficiency](https://www.youtube.com/watch?v=KcshxSB3sNY)** (Santi Garza, SpaceX AI field engineer; live session 25 August 2026, ~1 hour).

**Snapshot, not scripture.** Token ratios and "N× cheaper" examples are **as of the workshop**. They drift.

Model lanes live in the [agent use policy](../policies/agent-use-policy.md#default-picks). This playbook covers the token economics and prompt craft behind them.

Source note: [sources/cursor-model-selection-token-efficiency.md](../sources/cursor-model-selection-token-efficiency.md).

---

## 1. Why tokens matter

Tokens are the **billing unit**. Rough workshop heuristic: **~1–2 tokens per word**. Images and files tokenize too — attaching them is not free.

You pay for **model I/O** (what goes into the model and what it emits). In the talk, most harness / tool actions — search, grep, and similar — were called out as **not billed**. Wandering still costs you: every extra turn re-sends context and generates more output.

| Burns money | Usually does not (as of workshop) |
| --- | --- |
| Prompt + conversation + rules/skills/tools prefix sent to the model | Search / grep / most harness tool calls themselves |
| Model output (completions, plans, patches, thinking if billed as output) | Clicking around the IDE |
| Images, files, and other attachments once they are in the model context | |

**Implication:** make the model do less guessing. Point it. A cheap model that finishes in two turns beats an expensive model that explores for twenty.

---

## 2. Agent anatomy

**Model = engine. Harness = car.**

The harness (Claude Code or Codex on `agent-m1`) wraps the model in tools, orchestration, and system context. The same ask can behave differently across models because the car is different, not only because the engine is.

Hold these as design facts, not bugs:

- **Non-determinism.** Same prompt, same model, not the same path. Judge on task completion and cost, not one lucky run.
- **Tool orchestration.** The model chooses tools; the harness runs them. You pay for the model's tokens around those calls, not (per the talk) for the search/grep action itself.
- **You pick the engine; the harness drives the car.** Switching models is a first-class move, not a failure.

---

## 3. Amnesia + context

The model does not remember your repo between turns. **Every turn re-feeds context.**

```
[prefix]  system + rules + skills index + tool schemas + …
[middle]  conversation so far
[latest]  the ask you just sent
```

**Compaction (workshop heuristic):** around **~90%** of the window, the harness summarizes the **middle only**. Prefix and latest ask stay. After several compactions the middle is a photocopy of a photocopy — blurry decisions, invented constraints, forgotten files.

| Do | Don't |
| --- | --- |
| New chat per task | Eternal "workspace brain" threads |
| `@` a past chat as a pointer | Paste the whole old transcript |
| Start fresh when the agent is arguing with last week's plan | Keep compacting and hoping |

**Rule of thumb:** if you would not trust a three-paragraph summary of the thread, do not trust the compacted middle. New chat.

---

## 4. Token flavors

Four meters (as of workshop):

| Flavor | Role | Cost character |
| --- | --- | --- |
| **Input** | Fresh tokens the model reads | Baseline |
| **Output** | Tokens the model writes (including a lot of "thinking" on some models) | **Costlier** than input |
| **Cache write** | First time a prefix / prompt chunk is stored at the provider | More than a cache read |
| **Cache read** | Reuse of that stored prefix | Cheapest of the four |

**Cache lives per provider.** Changing always-on rules mid-session, or switching providers / models, **busts cache** and you pay a write again.

That blip is small. **Do not fear switching** when the task needs a different engine. Fear the 40-turn thread on the wrong model more than a cache miss.

---

## 5. Model portfolio (decision guide)

**No single model wins every category.** Do not lock to one provider. Use a **portfolio**.

Our lanes span two providers: Opus 5.5 and Fable 5.1 on Claude Code, GPT 6 Luna and GPT 6 Sol on Codex. The picks, efforts, and the Claude Code usage rule are in the [default picks](../policies/agent-use-policy.md#default-picks). Worked situations are in the [agent chooser examples](../policies/agent-use-policy.md#agent-chooser-examples).

---

## 6. Knobs

These are **spend multipliers**. Turn them with intent.

| Knob | What it actually does | Default |
| --- | --- | --- |
| **Effort** | More agent loops / more work per turn → more tokens | **Low** for mechanical, low-verification work. Raise after the shot is clear, not before. Do not raise effort to fix a vague prompt. |
| **Fast** | Faster output, not a smarter model | Off unless the human asks. |
| **Context / max** | Bigger window, more prefix + middle each turn | Normal until a complex refactor truly needs the extra room. |

Do not combine Fast, max effort, and Fable unless you can say why.

---

## Evals drift (CursorBench 4.0)

**As of 10 September 2026** ([Lee Robinson](https://x.com/leerob/status/2098144600594465148), [CursorBench](https://cursor.com/cursorbench)):

- **CursorBench 4.0** added harder long-horizon tasks: edit, refactor, investigation, intent understanding, managing jobs, design adherence.
- **Scores dropped across the board** because the bench got harder — not necessarily because models got worse.

**What to do:**

1. Revisit the lanes when a new model generation or a major benchmark version ships, not on every minor release. Do not pre-switch on hype.
2. Smoke-test pinned skills after a bump — does the agent still follow the playbook?
3. Judge models on **your repo's tasks**, not leaderboard alone. Benches drift; your test suite does not lie (if you have one).

---

## 7. Biggest tip: plan the shot

Vague prompts force the agent to **explore**, make **wrong guesses**, and then **carry that baggage on every later turn** (re-fed, then compacted into mush).

Clarify **before** you build, or **with Plan mode**:

- What does done look like?
- Which files / folders / services are in play?
- What must not change?
- How will we know (test, repro, screenshot, log line)?

A short plan on a strong general model, then a lighter lane to implement, is the core cost-and-quality move.

---

## 8. Prompting checklist

Use this as a pre-flight. Bots: if the user skipped these and the task is non-trivial, ask or switch to Plan — do not freestyle.

- [ ] **Specific.** Not "fix auth." Name the symptom, the surface, the constraint.
- [ ] **`@` files / folders / logs** so the agent does not search the universe.
- [ ] **Paste only relevant error lines**, not the giant log.
- [ ] **One task per turn.** Split the epic.
- [ ] **Success criteria.** "Done when test X is green" / "done when the 500 on `/checkout` is gone."
- [ ] **Do not paste huge files.** Point at them. 30k-line dumps waste input and drown the signal.
- [ ] **New chat per task.** `@` a past chat if you need the pointer.
- [ ] **Always-on rules stay short.** They ride every turn as prefix.
- [ ] **Prefer skills** (lazy-loaded body) over fat always-apply rules.
- [ ] **Audit unused MCPs.** Tool schemas you never use still sit in the prefix (and invite detours).

---

## 9. Golden paths

### Small, direct task

Scope the file or folder → **GPT 6 Luna Max**. One chat. Success criteria in the same turn.

### Vague or unfamiliar

**Read-only recon** → **Plan** → **Build**. Optionally `@` a prior chat instead of continuing it.

### Feature

Pull context (ticket, `@` areas, read-only recon if needed) → **Plan** → split **subtasks** / multitask. Do not one-shot the whole feature in a single agent loop if it can be cut.

### Refactor

Define success first. **TDD:** tests green before and after. Run automated review on the PR where the repo has it. Do not "clean it up" without a check.

### Hard bug

**Reproduce first**, with logs. Do not run guess loops on a frontier model. A failed hypothesis that stays in the thread becomes compacted folklore.

---

## 10. Worked cost levers (as of workshop)

The talk's point was not a spreadsheet. It was **compounding**.

| Lever | Workshop-scale effect | How you pull it |
| --- | --- | --- |
| Prompt quality | **~10–12×** from better prompting **alone** (same model, vague vs specific / well-anchored) | Plan the shot; `@` anchors; one task; success criteria |
| Wrong expensive model on top | Stacks to **~175×** vs a tight prompt on the right cheap model | Cheapest lane that fits first; escalate on evidence |
| Each extra habit | **~12–15%** each — new chat, short rules, skills vs fat prefix, no Fast-by-default, … | They **compound**. None is heroic; the pile is. |

If usage exploded, do not start by "the model got worse." Walk the levers: vague prompt? eternal chat? always-on Fable? Fast + max effort? 30k-line paste? unused MCPs?

---

## Anti-patterns

| Anti-pattern | Why it hurts |
| --- | --- |
| **Eternal chats** | Compaction blur + baggage re-fed every turn |
| **Vague "fix auth"** | Exploration + wrong guesses + expensive recovery |
| **Always-on Fable** | Pays frontier rates for work GPT 6 Luna or Opus 5.5 High would finish |
| **Fast by default** | You bought speed, not intelligence |
| **Giant always-apply rules** | Prefix tax on every request; cache-bust if you edit them mid-flight |
| **Dumping 30k-line files into context** | Input burn, drowned signal, worse answers |
| **One provider forever** | You miss the Pareto pick; no model wins every category |
| **Max effort + Fast + frontier "to be safe"** | Multipliers stack; the task was probably underspecified |

---

## Bot-ready defaults

If you are an agent reading this as policy, also follow [policies/agent-use-policy.md](../policies/agent-use-policy.md). Short version:

1. Pick model + effort per slice from the [agent-use-policy](../policies/agent-use-policy.md) chooser on `agent-m1` Claude Code or Codex.
2. New chat per task; `@` anchors; no novel-length pastes.
3. Plan before build when the work is not small and obvious.
4. Escalate one knob at a time; de-escalate to GPT 6 Luna Max or Opus 5.5 High to implement.
5. Chat overrides win for that ask only.
