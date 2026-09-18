# Steal from pstack

What we adopt from poteto's pstack vs what we only link. pstack skills are plain `SKILL.md` files, so the ideas port to Claude Code / Codex without installing the Cursor plugin (Cursor plugin trial is **not** required; Cursor coding is abandoned). Do **not** wholesale-install pstack on `agent-m1`.

## Adopt into our stack (now / next)

- **Babysit until merged** — already in [agent-dispatch-lifecycle.md](agent-dispatch-lifecycle.md#babysit-until-merged). Align eng-bot watches with pstack's babysit playbook: drive the PR through conflicts, review, and CI; do not drop it when the agent goes idle. Our rule: the bot owns the workstream until `merged` | `discarded`; arm a finite session-settle ping; prefer a GitHub PR listener over polling.
- **Prove it works** — maps to [agent-proof-feedback-loop.md](agent-proof-feedback-loop.md). Real artifact evidence (sims, screens, logs), not "it compiles." Luna Max for visual verify; media on the `media` branch.
- **Project verification skill pattern** — **Adopted (now)** into `amillez/agent-skills` `first-party/` as `create-verification-skill` + `maintain-verification-skill`, with an **amillez-mode overlay** (not a wholesale pstack install):
  - Keep: interview repo → generate `verify-<app>` → feature map shape → prove before handoff → maintain-loop rigor. Evidence dry-run nuance: some dry-runs still touch network/browser — observe what they skip, do not trust the name.
  - Overlay: default output under project-local `.claude/skills/verify-<app>/` and/or `.codex/skills/verify-<app>/` on agent-m1 only (never `.cursor/skills/`); generate/prove on agent-m1; Argent for Expo/RN; screenshots/videos → `media` branch + Luna Max (Codex) verify ([agent-proof-feedback-loop](agent-proof-feedback-loop.md), [agent-use-policy](../policies/agent-use-policy.md), [amillez-mode](amillez-mode.md)).
  - **Bot designer (Stella):** day-one wiring for coding bots on driveable apps — point at create + maintain; skip for pure library/docs/non-coding bots. Host stays agent-m1-first in the bot brief.
  - Next use: generate for Expo/RN apps (Favvy, asnt) via Argent Drive/Evidence. Do not require the Cursor plugin.
- **`setup-pstack` → thin `setup-amillez-models`** — **Adopted (now)** as a policy pointer only (`first-party/setup-amillez-models`). Points at [agent-use-policy](../policies/agent-use-policy.md) chooser (Luna Max / Sol High / Opus High / Fable). Does **not** write `~/.cursor/rules/pstack-models.mdc` or wholesale-copy pstack role maps. Optional offer to run `/create-verification-skill`. Stella: day-one wiring for coding bots.
- **Worktree cleanup** — already required in dispatch teardown (plus sim/Metro teardown). Keep it explicit; use pstack's worktree-cleanup playbook as a checklist reference.
- **Hard constraints** — reinforced by poteto's GrokBot workshop: enforce footguns in lint/CI so the proof loop fails closed. See [hard-constraints.md](hard-constraints.md).

## Steal selectively later

- **Shipping** — independent verify-then-land for contiguous stacks (a different agent verifies than the one that wrote). Useful when we stack PRs; not default until we run multi-PR stacks often.
- **Arena / Swarm / Interrogate** — multi-model design and adversarial review. Map to our chooser (Sol / Opus / Fable / Luna) when needed; do not adopt pstack's panel defaults wholesale. For structured multi-agent fan-out on our stack see [big-work-orchestration.md](big-work-orchestration.md) (**Orca** on `agent-m1`, Fable 5.1 High coordinator — not deferred).
- **Automate-me / personal `*-mode`** — optional later: an Agustín-mode router on top of agent-use-policy. Not blocking.
- **poteto-mode / unslop as separate skills** — craft bar stays in [design-grok-bot](https://github.com/amillez) / eng-bot skills for now; not ported as standalone skill bodies.

## Link only / skip for now

- Full `/poteto-mode` sticky router as primary on `agent-m1` — our host is Claude Code / Codex + eng bots.
- Comment Sicko / no-comments culture — optional taste, not policy.
- Benny Slack automations pack — out of scope.
- Wholesale `npx` / plugin install of every pstack skill onto `agent-m1`.
- Transcript / routine healthcheck *skill recipes* — we use Grok Bot routines, not poteto skill bodies.

## Upstream

https://github.com/cursor/plugins/tree/main/pstack
