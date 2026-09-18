# Agent dispatch lifecycle

How bots dispatch work to coding agents: projects, worktrees, and teardown.

Standing stack: `agent-m1` running Claude Code / Codex is primary. Cursor cloud is fallback only when `agent-m1` is down (see [agent use policy](../policies/agent-use-policy.md#1-coding-host-routing)).

## Units

- **Task** — one ask with success criteria + proof type (bot chat + [thorough launch prompt](agent-proof-feedback-loop.md#thorough-launch-prompt)).
- **Workstream** — one git branch + one worktree + one agent session.
- **Project** (optional) — multi-task effort; thin tracker later (Notion). Not Cursor Projects as primary.
- **Big Task → orchestrator workstream** — when the ask is multi-surface, parallelizable, multi-PR, or more than one session, the eng bot may spawn an **orchestrator** workstream that fans out child workstreams (plan → workers → integrate → prove). See [big-work orchestration](big-work-orchestration.md).

## Worktrees on `agent-m1`

Layout:

```text
~/agent-work/<repo>/
  main/                    # sync/human only — agents do not work here
  wt-<slug>-<shortid>/     # one agent = one worktree = one branch
```

Rules:

1. **On dispatch:** fetch, then `git worktree add -b agent/<bot>/<slug> <path> <base-ref>` from an up-to-date base (usually `main`).
2. **One agent per worktree.** Parallel work = `orchestrate-agents` with disjoint paths. Parallel workers must not share one tree; under disk pressure prefer sequential workers on one worktree — see [Worktrees and disk](big-work-orchestration.md#worktrees-and-disk).
3. **PR is the exit artifact.** Include or link proof in the PR body or bot message (see [agent proof feedback loop](agent-proof-feedback-loop.md)).
   - Screenshots/videos live on the repo's `media` branch, never the PR branch; link them via GitHub blob URLs, not raw URLs. See [proof media hosting](agent-proof-feedback-loop.md#proof-media-hosting).
4. **After merge or abandon:** remove the worktree and delete the local branch. The remote branch follows PR merge/close.
   - Workstream teardown also covers sims/emulators, Metro/dev servers, watchers, and tunnels — not only `git worktree remove`. See [teardown after proof](agent-proof-feedback-loop.md#teardown-after-proof).
5. **No long-lived dirty trees.** If blocked, mark blocked with evidence; park or discard. No zombies on disk.

**Cursor cloud fallback:** use the cloud agent's branch/PR lifecycle (no local worktree). Same thorough prompt and proof rules.

**Cursor My Machines (`worker=agent-m1`):** only for repos whose git remote is registered via `--worker-dir` on LaunchAgent `com.cursor.agent-worker.agent-m1`. Unregistered → do not route `worker=agent-m1`; register first (`register-worker-dir`) or stay on Claude Code / Codex / managed cloud without sim proof. See [Cursor self-hosted prove host](big-work-orchestration.md#cursor-self-hosted-prove-host-agent-m1).

## Lifecycle

```text
intake → thorough prompt (skills + proof) → provision worktree → agent runs
  → collect & inspect proof → open PR → bot reviews
  → merge | changes-requested | abandon → teardown worktree
```

Statuses: `queued` → `running` → `needs-proof` → `ready-for-review` → `merged` | `blocked` | `discarded`

For big work, a parent orchestrator workstream may fan out child workstreams before integrate/prove; babysit still owns the landing PR(s) until terminal. See [big-work orchestration](big-work-orchestration.md).

## Babysit until merged

Hardened after Mark's rn-bedrock PR #11 notes (background wakes missed `agent-m1` settles twice); aligned with Agustín 2026-09-16.

1. **Own the workstream until a terminal status.** Terminal = merge, close, or abandon. Agent idle or session settle is not done.
2. **Hop 1 — session settle: arm a finite settle-watch.** Do not rely on silent background Shell wakes alone. Arm a finite weekday `*/10` Europe/Madrid routine that checks the Claude Code / Codex session on `agent-m1`, **must message** the user on settle, block, or deadline, then deletes itself. See standing skill `agent-m1-completion-ping`.
3. **Hop 2 — PR open: switch to GitHub listeners.** Prefer PR-scoped event listeners (review, CI, push, `pr-merged`, `pr-closed`) over polling. No Claude/Codex → Grok Bot webhook bridge for now.
4. **Match the PR on every listener wake.** On every GitHub listener wake, confirm the event's PR number matches this workstream's `pr_number`; ignore cross-PR payloads (Mark: #19 wake hit #11 babysit).
5. **Do not stop at settle.** While the PR is OPEN and review threads are unresolved, do not delete the settle-watch or stop babysitting just because the coding session finished.
6. **Filter listener noise, keep watching.** Empty-body COMMENTED reviews and agent fix-ack replies on unresolved threads can wake as review-commented. Stay quiet on pure noise, but do not treat it as a hard failure that abandons babysit.
7. **Apply Agustín's review comments as they appear.** No asking permission, no "I'll follow it" chatter. Ping only for real blockers, requested settle/proof results, or merge/close.
8. **Changes requested or CI fails → follow up.** Send the coding agent back in, or open a follow-up workstream. Never go silent.
9. **Tear down in two stages.** Sims, emulators, and dev servers go when proof is done; PR listeners and worktree stay until terminal.
10. **Keep status current.** `blocked` is not terminal — report it with evidence and keep watching or close it out.

Related: pstack's babysit playbook — see [Steal from pstack](steal-from-pstack.md).

## Roles

- **Eng bots (Mark / Sam):** write the prompt, pick skills and proof type, start the agent on `agent-m1`, follow up, verify proof, open the PR, babysit it until merged or closed, tear down. Responsibility ends at merge/teardown, not at agent launch.
- **Coding agent:** works only in its own workstream.
- **Jarvis:** postmortems when the lifecycle breaks (merged without proof, orphan worktrees).

## Do not

- Use full Cursor Projects / Orca DAGs as the primary path.
- Auto-merge.
- Let agents share the `main` checkout.
- Put two agents in the same worktree.
- Leave sims, emulators, or dev servers running after proof.
