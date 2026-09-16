# Eng team of bots

How **we** run specialized engineering bots that manage cloud agents.

**Snapshot, not scripture** — fleet patterns as of September 2026.

Standing bot rules: [policies/agent-use-policy.md](../policies/agent-use-policy.md).

Inspiration (not a copy-paste org chart): [Lingxi Li — Grok Bot for Engineering](https://x.com/lingxi/status/2094493172516966781) ([x.ai guide](https://x.ai/bot/guides/grok-bot-for-engineering)).

---

## Specialization

Focused bots stay sharper. Our split:

| Bot | Domain |
| --- | --- |
| **Sam** | This repo — playbooks, policies, model picks, skill hygiene. |
| **Mark** | RN client quality, visual proof, mobile best-practice skills. |
| **Jarvis (hub)** | Cross-project intake, routing, git handoffs. Plans and delegates; does not write feature code. |

Each bot carries **domain memory** (specs, test patterns, design principles). A harness bot should not own RN visual polish.

---

## Durable vs ephemeral bots

Source: Matt Palmer's GrokBot course (SpaceXAI DX), [via @kaorixbt](https://x.com/kaorixbt/status/2099853269191311760). Separate from the Lauren Tan / pstack workshop.

- **Durable (core)** — Sam, Mark, Jarvis. Domain memory, routines, [Monday 1:1s](#monday-eng-bot-11s). Continuity matters.
- **Ephemeral (throwaway)** — spin up a bot for a one-off (scrape, script, experiment); delete it when done.

Why throwaways:

- Context isolation — no pollution of specialist memory or chat.
- Clean sidebar; disposable tooling state.

Rules:

- Promote to a durable bot or routine only if the one-off keeps recurring.
- Never use a throwaway for standing specialty work (RN quality, playbooks, CoS routing).

---

## Share bots as templates

- Share a bot setup as a Grok Bot **template** (blueprint): instructions + plugin/skill wiring. Not a shared live session.
- Prefer templates that **scrub personal/internal memory** by default — clones must not inherit private chat history.
- Use `export-bot-template` intentionally when cloning eng bots.
- A template is not a transcript dump. Each installer gets a fresh, isolated copy.

---

## How bots dispatch cloud agents

Every launch includes:

1. **Skills + thorough prompt** aligned with [agent-use-policy](../policies/agent-use-policy.md).
2. **Expected proof** — screenshot, CI green, Bugbot clean, or explicit success criteria.
3. **Monitor** — transcript, artifacts, CI; queue follow-ups when a run stalls.
4. **Bar** — iterate until proof passes or escalate to a human. No "mostly works" merges on production paths.

Auto-merge only when confidence is high **and** blast radius is low.

---

## Monday eng-bot 1:1s

Weekly sync between eng bots (and humans when needed):

- Playbook / policy refresh — what changed on `main`?
- Blockers and misfires from the prior week.
- Postmortem → skill or policy edit when a bot under-reached the real goal.

Same retro loop as [plan lifecycle in git](cursor-projects.md#plan-lifecycle) — applied to bot behavior.

---

## Cursor Project vs Grok Bot

| | Cursor Project | Grok Bot routine |
| --- | --- | --- |
| **Best at** | Repo-scoped multi-PR work with human + Cursor | Standing loops, Slack intake, proof monitoring |
| **Our default** | Features, migrations, gardening in git | Eng-bot fleets that babysit cloud agents |

They compose: a Grok Bot can **create and manage** Cursor cloud agents. Decision guide: [cursor-projects.md](cursor-projects.md).

---

## Guardrails

- **P0 routines** (aggressive transcript polling) burn tokens — reserve for true P0.
- **Nightly audits** need the same review bar as daytime work — see [production vs throwaway](../policies/agent-use-policy.md#production-vs-throwaway-ai-code).
- Treat external fleet-size anecdotes as **snapshots**, not targets. Hold the quality bar locally.

---

## Related

- [Cursor Projects](cursor-projects.md)
- [Agent use policy](../policies/agent-use-policy.md)
- [amillez-mode](amillez-mode.md) — remap poteto / Cursor-first defaults for bot briefs
- [Steal from pstack](steal-from-pstack.md) — Lauren Tan / pstack workshop takeaways (distinct from the GrokBot course above)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
