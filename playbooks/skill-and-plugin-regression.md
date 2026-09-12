# Skill and plugin regression

Short playbook: after a **model bump** or harness change, re-check that your top skills and plugins still fire and still earn their context budget.

**Snapshot, not scripture.** Commands and flags are **as of September 2026**.

---

## 1. Why this exists

Models absorb capability over time. A skill that was essential on Grok 4.5 may be **decoration** on 4.6. Conversely, a harder bench (see [evals drift](model-selection-and-token-efficiency.md#evals-drift-cursorbench-40)) can expose skills that no longer trigger reliably.

Skills without evals are markdown and hope. Same principle applies to **Cursor skills** even when you are not on Claude Code plugins.

---

## 2. When to run

| Trigger | Action |
| --- | --- |
| Cursor default model changes | Re-run top 3–5 skills you rely on for routing |
| Major model release (Grok, Fable, Opus, Composer) | Full regression on pinned skills |
| Skill PR merged | Smoke eval before merge if the skill gates behavior |
| Repeated "agent ignored my skill" reports | Description / trigger eval first |

Do **not** chase every minor model drop. Revisit on defaults, benches, or user-visible regressions.

---

## 3. Claude Code: `claude plugin eval`

If you maintain Claude Code plugins/skills, use the official eval harness.

### Start cheap

```bash
claude plugin eval . --case first-case --runs 1 --ablation none
```

`--runs 1` first — token cost control. Iterate on one failing case before scaling.

### Full delta check

```bash
claude plugin eval . --runs 3 --ablation with-without --report report.html
```

Read **Δ (delta)**, not the headline score:

- **Δ near zero** — base model handles the task without your plugin; skill may be redundant or description does not trigger.
- **Δ positive + `tool_used: Skill` passes** — plugin earns its place.
- Pin `--model` and `--judge-model` in CI so a provider rollout is not mistaken for your regression.

### Graders (minimal set)

1. **Output check** — regex or short-output LLM rubric.
2. **`tool_used: Skill`** — confirm the skill actually fired.

---

## 4. Cursor skills (general principle)

Cursor does not ship `claude plugin eval` today. Apply the same **with/without** mindset:

| Check | How |
| --- | --- |
| **Trigger** | Run 3–5 natural-language prompts that *should* load the skill. Does the agent follow the playbook? |
| **Delta** | Repeat without the skill (or in a fresh chat with skill disabled). Did behavior change? |
| **Description** | If trigger fails, fix skill description / index entry first — same fix as plugin frontmatter. |
| **Custom Mode** | If the skill is pinned as a Mode, re-verify pinned behavior separately from lazy-load. |

Keep a tiny `evals/` or checklist in the skill repo — even manual — so model bumps are not guesswork.

---

## 5. What to do with results

| Result | Action |
| --- | --- |
| Skill redundant (Δ ≈ 0) | Shrink, merge into always-on rules, or delete |
| Skill fails to trigger | Rewrite description; add one canonical example prompt |
| Skill triggers but output wrong | Edit body; add verification step (tests, screenshot, lint) |
| Model upgrade fixes the gap | Downgrade effort or remove skill section that duplicated model capability |

After retro from bot failures, prefer **skill edits** over longer always-on rules. See [cursor-projects.md](cursor-projects.md) (plan-retro) and [agent-use-policy.md](../policies/agent-use-policy.md).

---

## Bot-ready defaults

1. After model bumps, **`--runs 1` smoke first**, then widen.
2. Optimize for **delta**, not vanity pass rate.
3. Pin models in automated evals.
4. Apply the same loop to **Cursor skills** manually until a native eval ships.

## Related

- [Model selection & token efficiency](model-selection-and-token-efficiency.md)
- [Agent use policy](../policies/agent-use-policy.md)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
