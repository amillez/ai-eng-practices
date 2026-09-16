# Steal from pstack

What we adopt from poteto's pstack vs what we only link. pstack skills are plain `SKILL.md` files, so the ideas port to Claude Code / Codex without installing the Cursor plugin. Do **not** wholesale-install pstack on `agent-m1`.

## Adopt into our stack (now / next)

- **Babysit until merged** — already in [agent-dispatch-lifecycle.md](agent-dispatch-lifecycle.md#babysit-until-merged). Align eng-bot watches with pstack's babysit playbook: drive the PR through conflicts, review, and CI; do not drop it when the agent goes idle. Our rule: the bot owns the workstream until `merged` | `discarded`; arm a finite session-settle ping; prefer a GitHub PR listener over polling.
- **Prove it works** — maps to [agent-proof-feedback-loop.md](agent-proof-feedback-loop.md). Real artifact evidence (sims, screens, logs), not "it compiles." Luna Max for visual verify; media on the `media` branch.
- **Project verification skill pattern** — from `/create-verification-skill`: **Launch / Doctor / Drive / Evidence / Cleanup** plus a feature map. Next experiment: generate or hand-port this shape for Expo/RN apps (Favvy, asnt), using Argent for Drive and Evidence. Do not require the Cursor plugin.
- **Worktree cleanup** — already required in dispatch teardown (plus sim/Metro teardown). Keep it explicit; use pstack's worktree-cleanup playbook as a checklist reference.
- **Hard constraints** — reinforced by poteto's GrokBot workshop: enforce footguns in lint/CI so the proof loop fails closed. See [hard-constraints.md](hard-constraints.md).

## Steal selectively later

- **Shipping** — independent verify-then-land for contiguous stacks (a different agent verifies than the one that wrote). Useful when we stack PRs; not default until we run multi-PR stacks often.
- **Arena / Swarm / Interrogate** — multi-model design and adversarial review. Map to our chooser (Sol / Opus / Fable / Luna) when needed; do not adopt pstack's panel defaults wholesale.
- **Automate-me / personal `*-mode`** — optional later: an Agustín-mode router on top of agent-use-policy. Not blocking.

## Link only / skip for now

- Full `/poteto-mode` sticky router as primary on `agent-m1` — our host is Claude Code / Codex + eng bots.
- Comment Sicko / no-comments culture — optional taste, not policy.
- Benny Slack automations pack — out of scope.
- Wholesale `npx` / plugin install of every pstack skill onto `agent-m1`.

## Upstream

https://github.com/cursor/plugins/tree/main/pstack
