# Source: Model Selection & Token Efficiency

| Field | Value |
| --- | --- |
| Title | Model Selection & Token Efficiency |
| Series | [Cursor Workshops](https://cursor.com/workshops) |
| Recording | [youtube.com/watch?v=KcshxSB3sNY](https://www.youtube.com/watch?v=KcshxSB3sNY) |
| Presenter | Santi Garza (SpaceX AI field engineer; Cursor workshop presenter) |
| Date | Live session **25 August 2026** (per the YouTube description). ~1 hour. A later workshop slot was also listed for 23 September 2026. |
| Related docs | [Models & pricing](https://cursor.com/docs/models-and-pricing), [Plan Mode](https://cursor.com/docs/agent/plan-mode), [Rules](https://cursor.com/docs/context/rules), [Skills](https://cursor.com/docs/skills) |

## One-line summary

How tokens are billed, how Cursor's harness feeds and compacts context, and how to pick a model and prompt so an agent finishes the task instead of exploring on your dime.

## Extracted practices

The durable write-up is [playbooks/model-selection-and-token-efficiency.md](../playbooks/model-selection-and-token-efficiency.md). Standing bot rules are [policies/agent-use-policy.md](../policies/agent-use-policy.md).

Practices pulled from the workshop (paraphrased, not quoted):

- Bill for model I/O tokens, not for most harness / tool actions (search, grep, and similar were called out as free in the talk).
- Treat the model as the engine and the harness as the car; Cursor tunes the harness per model.
- Every turn re-feeds prefix + conversation + latest ask. Compaction near ~90% summarizes the middle only. Repeated compaction blurs context — start a new chat.
- Four token flavors: input, output (costlier), cache write, cache read. Cache lives per provider. Changing always-on rules mid-session or switching providers busts cache (a small blip; switch anyway when the task needs it).
- No single model wins every category. Do not lock to one provider.
- Portfolio heuristics as of the workshop: Composer 2.5 for most discrete SWE work; Grok 4.6 for quality/$; Fable for highly complex / wide / visual-heavy; Opus for writing, execution, and plans you will read; GPT 5.6 Sol for planning + reading codebases; Luna weaker quality/$ vs Grok/Composer.
- Effort = more loops = more spend. Fast = queue priority, not a smarter model. Auto router flavors: Cost / Balance (recommended default) / Intelligence. Org-wide router policy was claimed to save 30–60% overnight in the talk.
- Plan the shot. Vague prompts force exploration, wrong guesses, and baggage on every later turn.
- Prompting: be specific; `@` files/folders/logs; paste only relevant error lines; one task per turn; state success criteria; new chat per task; `@` past chats as pointers; keep always-on rules short; prefer skills (lazy-loaded) over fat rules; audit unused MCPs.
- Golden paths: scoped Composer for small tasks; Ask → Plan → Build when vague; Plan + split for features; TDD + Bugbot for refactors; Debug mode for hard bugs.
- Q&A workflow: plan with a strong general model (Grok / Opus / GPT); implement with Composer; reserve a big general model + max context for extremely complex refactors with ongoing decisions.
- Cost levers compound. Workshop examples: ~10–12× from better prompting alone; ~175× when that stacks with the wrong expensive model. Each lever ~12–15%.

## Snapshot warning

Prices, quality/$ rankings, router savings, and eval-style multiples in the playbook are **as of this workshop**. They will drift. Check [cursor.com/docs/models-and-pricing](https://cursor.com/docs/models-and-pricing) for live rates.

## Caption / extraction honesty

This write-up is a distillation for practice, not a transcript.

- Auto-captions and spoken model names are approximate. Prefer Cursor's common UI spellings: **Grok**, **Fable**, **Opus**, **Composer**, **GPT 5.6 Sol / Luna**.
- No invented quotes. Practices are paraphrased from the talk's structure and the official video description.
- If a detail was unclear on the recording, it is omitted or marked as a workshop claim — not filled in from other sessions.
