# Model selection & token efficiency

Opinionated playbook for humans and engineering bots. Distilled from Cursor's workshop **[Model Selection & Token Efficiency](https://www.youtube.com/watch?v=KcshxSB3sNY)** (Santi Garza, SpaceX AI field engineer; live session 25 August 2026, ~1 hour).

**Snapshot, not scripture.** Prices, quality/$, router savings, and "N× cheaper" examples are **as of the workshop**. They drift. Check [Models & pricing](https://cursor.com/docs/models-and-pricing) for live rates. Model names below use Cursor's common spellings (Grok, Fable, Opus, Composer, GPT 5.6 Sol / Luna). Spoken names on the recording may differ.

Standing bot rules: [policies/agent-use-policy.md](../policies/agent-use-policy.md). Source note: [sources/cursor-model-selection-token-efficiency.md](../sources/cursor-model-selection-token-efficiency.md).

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

Cursor wraps the model in a harness (tools, orchestration, system context) and **tunes that harness per model**. The same ask can behave differently across models because the car is different, not only because the engine is.

Hold these as design facts, not bugs:

- **Non-determinism.** Same prompt, same model, not the same path. Judge on task completion and cost, not one lucky run.
- **Tool orchestration.** The model chooses tools; the harness runs them. You pay for the model's tokens around those calls, not (per the talk) for the search/grep action itself.
- **You pick the engine; Cursor drives the car.** Switching models is a first-class move, not a failure.

---

## 3. Amnesia + context

The model does not remember your repo between turns. **Every turn re-feeds context.**

```
[prefix]  system + rules + skills index + tool schemas + …
[middle]  conversation so far
[latest]  the ask you just sent
```

**Compaction (workshop heuristic):** around **~90%** of the window, Cursor summarizes the **middle only**. Prefix and latest ask stay. After several compactions the middle is a photocopy of a photocopy — blurry decisions, invented constraints, forgotten files.

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

Two families:

- **Specialized SWE** (Composer): scoped coding, discrete implementation, fast/efficient. Default for most build work.
- **Frontier general reasoning** (Grok, Opus, Fable, GPT Sol): hard or wide problems, planning, reading a large unfamiliar surface, gnarly debug, visual-heavy work.

### Heuristics as of the workshop

| Model | Use it for | Skip it when |
| --- | --- | --- |
| **Composer 2.5** | Default for most discrete coding / SWE tasks. Fast, efficient. Implementation after a plan. | The problem is wide, unfamiliar, or still needs a strategy. |
| **Grok 4.6** | Strong **quality/$** (Pareto). Good general reasoning **and** coding. A default "smart" pick when Composer is not enough. | You already know the edit is local and specified — use Composer. |
| **Fable** (Claude Fable) | Highly complex / wide surface / gnarly debugging / visual-heavy. Expensive. Escalate here on purpose. | Everyday tickets, "always on", or first attempt at a small task. |
| **Opus** (Claude Opus) | Strong **writer / execution / plans you will actually read**. Sometimes better than Fable for those. | You only need a cheap implementer. |
| **GPT 5.6 Sol** | Planning + reading codebases (per the talk). | Routine implementation (Composer) or quality/$ vs Grok. |
| **GPT 5.6 Luna** | Cheaper GPT-class option. Workshop take: **weaker quality/$** vs Grok / Composer. | You care about Pareto quality/$. Prefer Grok or Composer. |

### Quick chooser

```
Is the edit already scoped (files + success criteria)?
  yes → Composer 2.5
  no  → Is the area unfamiliar or the ask vague?
          yes → Ask mode (recon), then Plan with Grok / Opus / Sol
          no  → Plan with Grok / Opus, then Composer to build

Did Composer / Balance fail or is the surface huge / visual / gnarly?
  yes → escalate to Fable (or Opus if the artifact is a plan/write-up)
  no  → stay cheap
```

Worked situation rows and concrete picks live in the policy: [Agent chooser examples](../policies/agent-use-policy.md#agent-chooser-examples).

---

## 6. Knobs

These are **spend multipliers**. Turn them with intent.

| Knob | What it actually does | Default |
| --- | --- | --- |
| **Effort** | More agent loops / more work per turn → more tokens | **Low** for mechanical, low-verification work. Raise after the shot is clear, not before. Do not raise effort to fix a vague prompt. |
| **Fast** | **Queue priority**, not a smarter model | Off. Use sparingly when waiting is the bottleneck. |
| **Auto router** | Cost / **Balance** / Intelligence | **Balance** as the recommended default. Cost when the work is routine. Intelligence when you want harder turns sent up. |
| **Context / max** | Bigger window, more prefix + middle each turn | Normal until a complex refactor truly needs the extra room. |

Workshop claim (snapshot): an **org-wide router policy** produced **~30–60% savings overnight**. That is a policy lever, not a reason to pick Intelligence on every personal chat.

Auto may send a harder turn to a stronger model. That is a feature. Still do not combine Intelligence + Fast + max effort + Fable unless you can say why.

---

## Evals drift (CursorBench 4.0)

**As of 10 September 2026** ([Lee Robinson](https://x.com/leerob/status/2098144600594465148), [CursorBench](https://cursor.com/cursorbench)):

- **CursorBench 4.0** added harder long-horizon tasks: edit, refactor, investigation, intent understanding, managing jobs, design adherence.
- **Scores dropped across the board** because the bench got harder — not necessarily because models got worse.
- **Grok 4.6** scored lower on 4.0 than on 3.x (e.g. ~41% at Extra High on 4.0 vs higher on 3.2 — **snapshot**; check leaderboard for current numbers).
- **Grok 4.7** was teased around the same window; revisit picks when it ships — do not pre-switch on hype.

**What to do:**

1. Revisit model defaults when **Cursor changes defaults** or **CursorBench major versions** ship — not on every minor release.
2. Re-run [skill/plugin regression](skill-and-plugin-regression.md) on pinned skills after a bump.
3. Judge models on **your repo's tasks**, not leaderboard alone. Benches drift; your test suite does not lie (if you have one).

---

## 7. Biggest tip: plan the shot

Vague prompts force the agent to **explore**, make **wrong guesses**, and then **carry that baggage on every later turn** (re-fed, then compacted into mush).

Clarify **before** you build, or **with Plan mode**:

- What does done look like?
- Which files / folders / services are in play?
- What must not change?
- How will we know (test, repro, screenshot, log line)?

A short plan on a strong general model, then Composer to implement, is the workshop's core cost-and-quality move.

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

Scope the file or folder → **Composer**. One chat. Success criteria in the same turn.

### Vague or unfamiliar

**Ask mode** (recon, safe, read-only) → **Plan** → **Build**. Optionally `@` a prior chat instead of continuing it.

### Feature

Pull context (ticket, `@` areas, Ask if needed) → **Plan** → split **subtasks** / multitask. Do not one-shot the whole feature in a single agent loop if it can be cut.

### Refactor

Define success first. **TDD:** tests green before and after. Run **Bugbot** on the PR (and locally if that is your loop). Do not "clean it up" without a check.

### Hard bug

**Debug mode:** reproduce + logs. Do not run guess loops on a frontier model. A failed hypothesis that stays in the thread becomes compacted folklore.

---

## 10. Recommended model workflow (from Q&A)

1. **Plan** with strong general reasoning — **Grok, Opus, or GPT** (Sol when the job is planning + reading the codebase).
2. **Implement** with **Composer**.
3. **Reserve** a big general model **+ max context** for extremely complex refactors that need **ongoing decisions** in one thread.

That is the default recipe. Fable is an escalation, not a lifestyle.

---

## 11. Worked cost levers (as of workshop)

The talk's point was not a spreadsheet. It was **compounding**.

| Lever | Workshop-scale effect | How you pull it |
| --- | --- | --- |
| Prompt quality | **~10–12×** from better prompting **alone** (same model, vague vs specific / well-anchored) | Plan the shot; `@` anchors; one task; success criteria |
| Wrong expensive model on top | Stacks to **~175×** vs a tight prompt on the right cheap model | Composer (or Balance) first; escalate on evidence |
| Each extra habit | **~12–15%** each — new chat, short rules, skills vs fat prefix, no Fast-by-default, router policy, … | They **compound**. None is heroic; the pile is. |

If usage exploded, do not start by "the model got worse." Walk the levers: vague prompt? eternal chat? always-on Fable? Fast + max effort? 30k-line paste? unused MCPs?

---

## Anti-patterns

| Anti-pattern | Why it hurts |
| --- | --- |
| **Eternal chats** | Compaction blur + baggage re-fed every turn |
| **Vague "fix auth"** | Exploration + wrong guesses + expensive recovery |
| **Always-on Fable** | Pays frontier rates for work Composer would finish |
| **Fast by default** | You bought queue priority, not intelligence |
| **Giant always-apply rules** | Prefix tax on every request; cache-bust if you edit them mid-flight |
| **Dumping 30k-line files into context** | Input burn, drowned signal, worse answers |
| **One provider forever** | You miss the Pareto pick; no model wins every category |
| **Max effort + Fast + frontier "to be safe"** | Multipliers stack; the task was probably underspecified |

---

## Bot-ready defaults

If you are an agent reading this as policy, also follow [policies/agent-use-policy.md](../policies/agent-use-policy.md). Short version:

1. Balance or Composer unless told otherwise.
2. New chat per task; `@` anchors; no novel-length pastes.
3. Plan before build when the work is not small and obvious.
4. Escalate one knob at a time; de-escalate to Composer to implement.
5. Chat overrides win for that ask only.
