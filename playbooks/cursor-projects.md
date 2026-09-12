# Cursor Projects

Opinionated playbook for when to spin up a **Cursor Project** (coordinator + shared context + subscriptions) vs a **Grok Bot routine** vs a **one-shot cloud agent**.

**Snapshot, not scripture.** Product names and harness features are **as of September 2026**. Check [Cursor changelog](https://cursor.com/changelog) for current behavior.

Standing bot rules: [policies/agent-use-policy.md](../policies/agent-use-policy.md).

---

## 1. Three layers of delegation

| Layer | What it is | Best for |
| --- | --- | --- |
| **One-shot cloud agent** | Single run: prompt → branch → PR (or answer). No persistent coordinator. | Scoped tasks with clear done criteria. One PR, one bug, one doc pass. |
| **Cursor Project** | Long-running **coordinator** that plans, delegates to worker agents, and keeps **shared context** in git-synced files. | Work that outlives one chat: features, migrations, gardening. |
| **Grok Bot routine** | Persistent eng intern on its own computers that **manages** cloud agents, checks proofs, and closes the feedback loop. | Domain-owned fleets, Slack-driven intake, proof-heavy UI work. See [eng-team-of-bots](eng-team-of-bots.md). |

**Default for TSCOB + personal:** start with a one-shot cloud agent. Promote to a Project when the same body of work needs a second PR, a standing watch, or a coordinator that remembers how you test.

---

## 2. When to use a Cursor Project

Use a Project when the work has **duration**, **parallelism**, or **recurrence**:

- **Feature work** — research → plan → parallel implementation → local test → post-ship monitoring. The coordinator learns your architecture across turns.
- **Migrations** — safe pattern first, then incremental PRs across hundreds of files. Review tightly early; loosen as the pattern holds.
- **Gardening** — design-system drift, lint rules from repeated mistakes, CI follow-up, Slack bug intake. Subscriptions wake the coordinator without you.

Do **not** open a Project for:

- A single, already-scoped edit ("rename this prop, fix call sites").
- Exploratory recon with no follow-on build plan.
- Work you will abandon in one session.

Source: [Introducing Projects](https://cursor.com/blog/projects) (Cursor blog, Sep 10 2026).

---

## 3. Cursor's three Project patterns

From Cursor's internal usage (paraphrased):

### Feature work

Agents research and write findings into **shared context**. Coordinator creates a plan and dispatches parallel implementers. After ship, the same Project can watch logs and handle bug reports with full decision history.

### Migrations

Establish a safe approach with the coordinator, then apply incrementally. Early PRs get close review; later PRs run with lighter touch as the pattern proves out.

### Gardening

Coordinator follows new PRs, Slack channels, or a schedule. Example from the blog: a design-system Project scans PRs, extracts components, and adds a lint rule when it sees the same mistake twice — targeting 20–100 PRs/day with human check-in only where needed.

---

## 4. Practitioner plan lifecycle (Fatih Arslan patterns)

Fatih Arslan's workflow predates Projects but maps cleanly onto them. Paraphrased from [How I manage my agents](https://arslan.io/2026/09/11/how-i-manage-my-agents/) — **do not copy his skill files verbatim**; adapt folder names and checks to your repo.

### Plan folders

Keep plans as markdown in git so agents and humans share one index:

```
plans/
  README.md      # what's next / open
  drafts/        # captured ideas, no decisions yet
  next/          # ready to dispatch — decisions made
  open/          # agent working; PR is the artifact
  done/          # merged / closed
  discarded/
```

| Stage | Meaning |
| --- | --- |
| **drafts** | Capture without deciding. `/plan-add` equivalent: free the thought before you forget. |
| **next** | Investigation or spec complete. Agent can implement without design questions. |
| **open** | Dispatched. Expect one or more PRs. |
| **done** | PR merged; sync plan file with what landed. |

### Coordinator notes in git

Each Project (or domain) keeps a `coordinator-notes.md` in the repo — goal, open/next/draft lists, PR links, research. **Commit notes in the same turn as state changes.** If the coordinator hits a platform limit or error loop, a fresh Project can rebuild from git in one turn.

Cross-Project handoffs live in git too (`docs/coordinator/inbox/…`) with `From` / `To` / `Date` / `Why` headers. Coordinators do not read each other's private context; git is the bus.

### Plan retro → rewrite skills

After work lands in `done/` or `discarded/`, run a retro pass: read transcripts, spot repeated misunderstandings, **propose a concrete skill or rule edit**. Cursor's gardening pattern is the same idea applied to the codebase; retro applies it to your skills.

---

## 5. Related harness (Sep 2026)

These ship alongside Projects in the Cursor harness. Use them inside a Project or a one-shot agent.

| Feature | What it does | When to use |
| --- | --- | --- |
| **Custom Modes** | Pin a skill as an always-on mode (`/` → skill → Use as Mode). | Repeatable playbook work: migrations, reviews, gardening checks. |
| **`/goal`** | Long-lived objective until complete. | "Fix all flaky tests and make CI green." Pair with a Custom Mode for the playbook. |
| **Subagents on own VMs** | Isolated copies of the project, clean context each. | Parallel test swarms, independent fixes without collision. |
| **Subscriptions** | Watch PRs, Slack, or a schedule; wake coordinator on events. | CI follow-up, bug channels, nightly audits. |

Source: [Cursor changelog](https://cursor.com/changelog) (Aug–Sep 2026).

**Custom Modes vs skills vs always-on rules:** Custom Mode = pinned skill for this chat. Skills lazy-load when relevant. Always-on rules stay **short** — they ride every turn. Details in [agent-use-policy](../policies/agent-use-policy.md).

---

## 6. Self-hosted machines

Cursor supports **self-hosted workers** (your laptop, team pools, sandboxes on Lambda/Coder/Cloudflare/etc.) so tool execution stays on your network. Useful for VPN, iOS Simulator, screenshots, secrets on internal machines.

**Default for TSCOB + personal: skip.** Cloud agents on Cursor's infra are enough for most web/RN/docs work. Self-hosted adds Enterprise/ops cost: pool sizing, hibernation, reconnect windows, desktop packages for computer use. Reach for it when compliance or device access **requires** it — not as the default topology.

Source: [Self-hosted machines](https://cursor.com/changelog) (Sep 2 2026).

---

## 7. Decision guide

```
Is the task scoped to one PR / one answer with clear done criteria?
  yes → one-shot cloud agent (or local Composer)
  no  → Will the same thread of work need 2+ PRs, a standing watch, or shared learnings?
          yes → Cursor Project
          no  → still one-shot; don't over-coordinator

Does the work need a persistent eng intern managing many agents + proof loops + Slack?
  yes → Grok Bot routine (see eng-team-of-bots.md)
  no  → Project or one-shot is enough
```

---

## Bot-ready defaults

1. Default to **one-shot** until evidence says otherwise.
2. Put **plans and coordinator notes in git**, not only in chat.
3. Use **subscriptions** for gardening; use **subagents on VMs** for parallel verification.
4. **Retro** finished work into skill edits — same loop as lint-from-twice-seen mistakes.
5. **Self-hosted** only when cloud cannot reach the environment.

## Related

- [Eng team of bots](eng-team-of-bots.md)
- [Agent use policy](../policies/agent-use-policy.md)
- [Model selection & token efficiency](model-selection-and-token-efficiency.md)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
