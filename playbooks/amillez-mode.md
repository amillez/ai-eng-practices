# amillez-mode

Canonical remap for bots that load poteto-style craft skills (Stella the bot designer, eng bots). Keep the craft bar. Remount Cursor-first defaults onto our org stack (Claude Code + Codex on agent-m1 only).

Source: Stella onboard / poteto craft remount, 2026-09-16. Ensure-install SoT + voice capitalization: Stella Monday eng 1:1, 2026-09-21.

---

## Intent

- **Keep poteto craft.** One job, unslopped, verified — Prove It Works.
- **Call it amillez-mode.** Same bar, our labels.
- **Do not fight poteto skills.** Remap only the defaults that conflict with our stack; leave the rest intact.

---

## Remap table

| poteto / Cursor-default signal | amillez-mode | Where it lives |
| --- | --- | --- |
| Cursor cloud / Composer / My Machines as coding host | **override** — **abandoned**; agent-m1 Claude Code/Codex **only** | [agent-use-policy §1](../policies/agent-use-policy.md#1-coding-host-routing) |
| Freestyle expensive / Cursor-only models | **override** — follow the agent-use-policy chooser mapped to Claude/Codex; skip Cursor-only lanes | [agent-use-policy §2](../policies/agent-use-policy.md#2-default-model-posture) |
| Done = green CI / files changed | **override** — proof loop: flexible evidence, media on the `media` branch, Luna Max for visual | [agent-proof-feedback-loop](agent-proof-feedback-loop.md) |
| Skills / plugins ad-hoc | **override** — allowlist via `amillez/agent-skills` | [agent-proof-feedback-loop](agent-proof-feedback-loop.md) + `amillez/agent-skills` README |
| Background Shell wake as babysit | **override** — hop-1 finite settle-watch (must message, then delete); hop-2 GitHub listeners; match `pr_number`; terminal = merge / close / abandon | [agent-dispatch-lifecycle → Babysit](agent-dispatch-lifecycle.md#babysit-until-merged) |
| poteto craft / one job / anti-jobs / one voice | **keep** — rename labels to amillez-mode in briefs; do not strip | This file |
| poteto “short lowercase OK” voice | **remap** — org voice prefers **regular capitalization** (design-grok-bot already does) | This file + bot briefs |
| Naming `ensure-project` as the primary install | **override** — SoT is `scripts/ensure-install.sh` (core+mobile → `~/.claude` + `~/.agents`; no `~/.codex`). `ensure-project.sh` is a **thin alias only** | [dispatch lifecycle](agent-dispatch-lifecycle.md#worktrees-on-agent-m1) · [agent-use-policy §1](../policies/agent-use-policy.md#1-coding-host-routing) |

When a skill and this table disagree on host, model, done, skills, or babysit: this table wins. On craft: the skill wins.

---

## Coding-bot brief overlay

Paste into any coding bot Stella designs:

- **Host:** agent-m1 Claude Code/Codex only. No Cursor coding path.
- **Ensure (SoT one-liner):** [`amillez/agent-skills`](https://github.com/amillez/agent-skills) `scripts/ensure-install.sh` → core+mobile at `~/.claude` + `~/.agents` (no `~/.codex`). `ensure-project.sh` is a thin alias only — do **not** name ensure-project as the primary in bot briefs.
- **Thorough launch:** goal, scope, named skills, expected proof.
- **Skills:** only from the `amillez/agent-skills` allowlist.
- **Babysit until merged** per the dispatch lifecycle.
- **Review comments:** apply Agustín's review comments without permission chatter.
- **Language:** reply in EN; Agustín may write EN/ES/CA. Prefer **regular capitalization** (remap poteto “short lowercase OK”).
- **Framing:** no Peersyst / company framing unless he brings it up.

---

## Checklist before shipping a bot brief

- [ ] Craft bar kept (one job, anti-jobs, one voice, Prove It Works).
- [ ] Every row in the remap table applied — no Cursor-first default left in.
- [ ] Overlay pasted for coding bots.
- [ ] Labels say amillez-mode, not poteto.

---

## Related

- [Eng team of bots](eng-team-of-bots.md)
- [Agent use policy](../policies/agent-use-policy.md)
- [Agent proof feedback loop](agent-proof-feedback-loop.md)
- [Agent dispatch lifecycle](agent-dispatch-lifecycle.md)
- [Steal from pstack](steal-from-pstack.md)
