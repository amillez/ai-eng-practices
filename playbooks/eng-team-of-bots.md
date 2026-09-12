# Eng team of bots

Distilled playbook for running **specialized engineering bots** that manage coding agents — illustrated with **Sam (AI practices)**, **Mark (RN)**, and **Jarvis (hub coordinator)** as one example split.

**Snapshot, not scripture.** Fleet sizes and product names are **as of September 2026**.

Primary sources:

- [Lingxi Li — Grok Bot for Engineering](https://x.com/lingxi/status/2094493172516966781) (also on [x.ai guides](https://x.ai/bot/guides/grok-bot-for-engineering))
- [Eric Zakariasson — summary thread](https://x.com/ericzakariasson/status/2094818067905941886)

Standing bot rules: [policies/agent-use-policy.md](../policies/agent-use-policy.md).

---

## 1. Core framing

> Treat Grok Bot like a **sharp eng intern with its own computers** that manages coding agents.

The intern does not replace you on architecture, taste, or risk calls. It:

- Spins up cloud agents with your skills and a thorough prompt + **expected proof**
- Monitors transcripts and artifacts (screenshots, CI, Bugbot)
- Queues follow-ups or interrupts when the run stalls
- Keeps going until the result hits **your bar** — or escalates

Before bots: ~**15** cloud agents managed by hand. With a fleet: **200+** simultaneously (Lingxi's account, Sep 2026 — treat as anecdote, not a target).

---

## 2. Specialize by domain

Focused bots stay sharper. Lingxi's fleet (names are his; use your own):

| Bot role | Domain |
| --- | --- |
| Mobile shared / iOS | RN + native edges Mark cares about |
| Desktop + CI/CD | Client builds, release hygiene |
| Infra | Unclear ownership, env flakiness |
| Android | Platform-specific surface |
| Harness | Agent tooling, skills, coordinator behavior |

They *can* cross areas, but each carries **domain memory** — specs, design principles, test patterns. A harness bot should not own RN visual polish.

### Example role split

| Role | Bot posture |
| --- | --- |
| **Sam** | Owns this repo's playbooks/policies, skill regressions, model-pick reviews. |
| **Mark** | Owns RN client quality, visual proof, `/react-native-best-practices`-class skills. |
| **Jarvis (hub)** | Coordinator across projects: intake, routing, cross-domain handoffs in git. Does not write feature code. |

---

## 3. The feedback loop (non-negotiable)

A bot without verification is an expensive autocomplete.

1. **Launch** — cloud agent + skills + success criteria + proof spec ("screenshot must show before/after").
2. **Monitor** — transcript, artifacts, CI, Bugbot/security findings.
3. **Unblock** — environment flakiness, missing permissions, wrong approach.
4. **Review** — multimodal check for UI; architecture skills for structural work.
5. **Merge policy** — auto-merge only when confidence is high **and** blast radius is low; otherwise queue for human.

Lingxi uses a **shared Notion PR database** past context limits: bots poll every ~30 min for CI failures, merge conflicts, and Bugbot comments. For us, a git-based PR index or lightweight board is fine — the pattern matters more than the tool.

---

## 4. Ops bot (Jenny pattern)

Engineering is not only code. An **ops bot** that does not write production code:

- Daily 1:1s with engineer bots (playbook refresh, blockers, vibe)
- Postmortems when a bot under-reaches the real goal
- Playbook updates announced to the fleet so mistakes do not repeat
- Onboarding new bots with team rules and peer help

This mirrors Fatih Arslan's **plan-retro → skill rewrite** and Cursor **gardening** — applied to bot behavior, not just the codebase. See [cursor-projects.md](cursor-projects.md).

---

## 5. Eric's summary (condensed)

From [Eric's thread](https://x.com/ericzakariasson/status/2094818067905941886) on Lingxi's setup:

- Sharp intern + own computers + manages coding agents
- **Specialize by domain** — iOS, desktop, infra, Android, harness
- Spin cloud agents, **check proofs**, unblock flakiness, iterate to bar
- Own machines when VPN / Simulator / screenshots require it
- **Notion (or equivalent)** past context: watch Bugbot / CI / conflicts → follow up → review → auto-merge when safe
- **Ops bot** for 1:1s, postmortems, onboarding

Eric's own experiment ([multiple teams of Grok Bots](https://x.ai/bot/guides/how-i-run-multiple-teams-of-grok-bots)): one channel per project, Notion Projects/Tasks, a manager bot staffs ≤5 specialists — reuse bench bots before creating new ones.

---

## 6. Cursor Projects vs Grok Bot routines

| | Cursor Project | Grok Bot routine |
| --- | --- | --- |
| **Primary interface** | Cursor coordinator + shared context files | Slack / messaging + bot memory |
| **Best at** | Repo-scoped features, migrations, gardening in git | Fleet orchestration, proof loops, org chores |
| **Scale pattern** | Thousands of subagents via coordinator | 200+ cloud agents via specialized bots |
| **Our default** | Start here for repo work | Add when manual agent babysitting hurts |

They compose: a Grok Bot can **create and manage** Cursor cloud agents. Jarvis (hub) might own cross-project routing; each Project owns repo context.

Decision guide: [cursor-projects.md](cursor-projects.md).

---

## 7. Risk and cost guardrails

- **P0 urgency routines** (Lingxi): check transcript every ~5 min, steer aggressively. Effective; **burns tokens fast**. Reserve for true P0.
- **Nightly audits**: great for slop cleanup; still need review bar — see [production vs throwaway](../policies/agent-use-policy.md#production-vs-throwaway-ai-code).
- **Auto-merge**: only with low blast radius + strong proof. Production paths need human or Bot-reviewed merge.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
| --- | --- |
| One mega-bot for all domains | Context dilution; weak proofs |
| No proof spec on launch | Bot declares done; you discover gaps in prod |
| Babysitting 15+ agents by hand | Exactly what the fleet pattern removes |
| Copying Lingxi's exact bot names/skills | His memory systems are tuned to Grok Bot; adapt |

---

## Bot-ready defaults

1. **Specialize** bots by domain (Sam / Mark / Jarvis split).
2. Every dispatch includes **proof expectations**.
3. **Ops loop**: postmortem → playbook/skill update.
4. Prefer **Cursor Projects** for repo-scoped work; **Grok Bot** when fleet + Slack + proof monitoring is the bottleneck.
5. Treat throughput claims as **snapshots**; hold the quality bar locally.

## Related

- [Cursor Projects](cursor-projects.md)
- [Agent use policy](../policies/agent-use-policy.md)
- [Skill and plugin regression](skill-and-plugin-regression.md)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
