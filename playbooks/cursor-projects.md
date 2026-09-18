# Cursor Projects — decision guide

> **Historical / abandoned for coding (2026-09-18).** Coding work runs on `agent-m1` via Claude Code + Codex only. Grok Bot remains the control plane. Keep this page as context for older notes; do not start Cursor Projects or Cursor cloud agents for eng coding.


When to use a **one-shot cloud agent**, a **Cursor Project**, or a **Grok Bot routine**.

**Snapshot, not scripture** — product names as of September 2026. Harness details: [Cursor changelog](https://cursor.com/changelog).

Standing bot rules: [policies/agent-use-policy.md](../policies/agent-use-policy.md).

---

## Pick a layer

| Layer | Use when |
| --- | --- |
| **One-shot cloud agent** | One PR, one bug, one doc pass — clear done criteria, no standing watch. |
| **Cursor Project** | Human + Cursor coordinated work across **multiple PRs** with shared repo context (features, migrations, gardening). |
| **Grok Bot routine** | Standing eng-bot loops: Slack intake, proof monitoring, fleet of cloud agents. **Not** a Cursor Project. |

**Default:** one-shot until the same thread needs a second PR, subscriptions, or a coordinator that remembers how you test.

---

## Cursor Project patterns (short)

- **Feature** — research → plan → parallel implementation → post-ship watch.
- **Migration** — safe pattern first; tighten review early, loosen as the pattern holds.
- **Gardening** — design-system drift, lint from repeated mistakes, CI follow-up.

Skip a Project for a single scoped edit or throwaway recon with no follow-on plan.

Source: [Introducing Projects](https://cursor.com/blog/projects).

---

## Plan lifecycle

Keep plans and coordinator notes **in git** so a fresh Project can rebuild state in one turn. Stage folders, retro → skill edits, and cross-project handoffs: see [Fatih Arslan — How I manage my agents](https://arslan.io/2026/09/11/how-i-manage-my-agents/) (adapt folder names to your repo; do not copy his skills verbatim).

---

## Decision tree

```
One PR / one answer with clear done criteria?
  yes → one-shot cloud agent (or local Composer)
  no  → Same work needs 2+ PRs, subscriptions, or shared learnings?
          yes → Cursor Project
          no  → one-shot

Standing eng-bot loop (Slack, proofs, many agents)?
  yes → Grok Bot routine — see eng-team-of-bots.md
  no  → Project or one-shot
```

Self-hosted workers: skip by default; use only when VPN, Simulator, or compliance requires your machines.

---

## Related

- [Eng team of bots](eng-team-of-bots.md)
- [Agent use policy](../policies/agent-use-policy.md)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
