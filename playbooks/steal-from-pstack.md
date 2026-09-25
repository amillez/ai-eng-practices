# Steal from pstack

What we adopt from poteto's pstack vs what we only link. pstack skills are plain `SKILL.md` files, so the ideas port to Claude Code / Codex without installing the Cursor plugin (Cursor plugin trial is **not** required; Cursor coding is abandoned). Do **not** wholesale-install pstack on `agent-m1`.

## Adopt into our stack (now / next)

- **Babysit until merged** — already in [agent-dispatch-lifecycle.md](agent-dispatch-lifecycle.md#babysit-until-merged). Align eng-bot watches with pstack's babysit playbook: drive the PR through conflicts, review, and CI; do not drop it when the agent goes idle. Our rule: the bot owns the workstream until `merged` | `discarded`; arm a finite session-settle ping; prefer a GitHub PR listener over polling. **Next (from pstack 0.15.3 autopilot):** verification *rounds* that re-run when the code-ready head changes, and a small `children.tsv` (or equivalent) so the owner tracks subagents and only posts status when a tracked item changed — port the idea into eng-bot babysit notes, not the Cursor autopilot scripts.
- **Prove it works** — maps to [agent-proof-feedback-loop.md](agent-proof-feedback-loop.md). Real artifact evidence (sims, screens, logs), not "it compiles." Luna Max for visual verify; media on the `media` branch.
- **Blast radius (adopt next)** — pstack `blast-radius` skill: for a small diff you do not fully trust, find the *one fact* the change is safe because of, and prove that fact by running real code (script/test), not a convincing writeup. Companion to how/why. Fits review comments and eng-bot self-checks before merge. Port as a short playbook section or skill pointer — do not install the Cursor skill wholesale.
- **Project verification skill pattern** — **Adopted (now)** into `amillez/agent-skills` `first-party/` as `create-verification-skill` + `maintain-verification-skill`, with an **amillez-mode overlay** (not a wholesale pstack install):
  - Keep: interview repo → generate `verify-<app>` → feature map shape → prove before handoff → maintain-loop rigor. Evidence dry-run nuance: some dry-runs still touch network/browser — observe what they skip, do not trust the name.
  - Overlay: default output under project-local `.claude/skills/verify-<app>/` and/or `.codex/skills/verify-<app>/` on agent-m1 only (never `.cursor/skills/`); generate/prove on agent-m1; Argent for Expo/RN; screenshots/videos → `media` branch + Luna Max (Codex) verify ([agent-proof-feedback-loop](agent-proof-feedback-loop.md), [agent-use-policy](../policies/agent-use-policy.md), [amillez-mode](amillez-mode.md)).
  - **Bot designer (Stella):** day-one wiring for coding bots on driveable apps — point at create + maintain; skip for pure library/docs/non-coding bots. Host stays agent-m1-first in the bot brief.
  - Next use: generate for Expo/RN apps (Favvy, asnt) via Argent Drive/Evidence. Do not require the Cursor plugin.
- **`setup-pstack` → thin `setup-amillez-models`** — **Adopted (now)** as a policy pointer only (`first-party/setup-amillez-models`). Points at [agent-use-policy](../policies/agent-use-policy.md) chooser (GPT 6 Luna Max / Opus 5.5 High / GPT 6 Sol fallback over 70% Claude Code usage / Fable 5.1). Does **not** write `~/.cursor/rules/pstack-models.mdc` or wholesale-copy pstack role maps. Optional offer to run `/create-verification-skill`. Stella: day-one wiring for coding bots. **Upstream note (pstack 0.15.3, 2026-09-23):** pstack defaults moved to Opus 5.5 (judgment) and Grok 4.7 (code delegates); panels are three runners (Opus 5.5 / Sol / Grok 4.7). Our chooser stays amillez policy — do not copy pstack's Cursor rule file; just keep lanes current (see open lane PRs).
- **Worktree cleanup** — already required in dispatch teardown (plus sim/Metro teardown). Keep it explicit; use pstack's worktree-cleanup playbook as a checklist reference.
- **Hard constraints** — reinforced by poteto's GrokBot workshop: enforce footguns in lint/CI so the proof loop fails closed. See [hard-constraints.md](hard-constraints.md).

## Steal selectively later

- **Figure it out + show me your work** — design an auditable playbook when no narrower one fits; keep a TSV decision trail (`decisions.tsv` / `.audit/<slug>.tsv`) with evidence pointers, then cross-model review of the trail. Strong fit for long Orca / unattended multi-hour runs a human reviews after stepping away. Defer until we want a durable audit format in big-work orchestration — not a day-one skill install.
- **Shipping** — independent verify-then-land for contiguous stacks (a different agent verifies than the one that wrote). Useful when we stack PRs; not default until we run multi-PR stacks often.
- **Arena / Swarm / Interrogate** — multi-model design and adversarial review. Map to our chooser (Sol / Opus / Fable / Luna) when needed; do not adopt pstack's panel defaults wholesale. For structured multi-agent fan-out on our stack see [big-work-orchestration.md](big-work-orchestration.md) (**Orca** on `agent-m1`, Opus 5.5 xhigh coordinator — not deferred).
- **Automate-me / personal `*-mode`** — optional later: an Agustín-mode router on top of agent-use-policy. Not blocking.
- **poteto-mode / unslop as separate skills** — craft bar stays in [design-grok-bot](https://github.com/amillez) / eng-bot skills for now; not ported as standalone skill bodies.
- **Post-merge "rollouts" pattern (idea only)** — Cursor's Rollouts bot (Sep 2026) watches PR→deploy with a monitoring plan vs telemetry. We are not on Cursor coding; if we ever want the *pattern*, sketch a Grok Bot + PagerDuty/Sentry listener after merge — do not install Cursor Rollouts.

## Link only / skip for now

- Full `/poteto-mode` sticky router as primary on `agent-m1` — our host is Claude Code / Codex + eng bots.
- Comment Sicko / no-comments culture — optional taste, not policy.
- Benny Slack automations pack — out of scope.
- Wholesale `npx` / plugin install of every pstack skill onto `agent-m1`.
- Transcript / routine healthcheck *skill recipes* — we use Grok Bot routines, not poteto skill bodies.
- Cursor Projects as a coding host — historical / parallel-orchestration inspiration only; coding stays on agent-m1.

## Upstream

https://github.com/cursor/plugins/tree/main/pstack

Last Friday revisit: **2026-09-25** (pstack 0.15.3 port: Opus 5.5 / Grok 4.7 defaults, autopilot verification rounds, blast-radius / figure-it-out / show-me-your-work still the main steal candidates).
