# Agent dispatch lifecycle

How bots dispatch work to coding agents: projects, worktrees, and teardown.

Standing stack: `agent-m1` running Claude Code / Codex is primary. Cursor cloud is fallback only when `agent-m1` is down (see [agent use policy](../policies/agent-use-policy.md#1-coding-host-routing)).

## Units

- **Task** — one ask with success criteria + proof type (bot chat + [thorough launch prompt](agent-proof-feedback-loop.md#thorough-launch-prompt)).
- **Workstream** — one git branch + one worktree + one agent session.
- **Project** (optional) — multi-task effort; thin tracker later (Notion). Not Cursor Projects as primary.

## Worktrees on `agent-m1`

Layout:

```text
~/agent-work/<repo>/
  main/                    # sync/human only — agents do not work here
  wt-<slug>-<shortid>/     # one agent = one worktree = one branch
```

Rules:

1. **On dispatch:** fetch, then `git worktree add -b agent/<bot>/<slug> <path> <base-ref>` from an up-to-date base (usually `main`).
2. **One agent per worktree.** Parallel work = `orchestrate-agents` with disjoint paths.
3. **PR is the exit artifact.** Include or link proof in the PR body or bot message (see [agent proof feedback loop](agent-proof-feedback-loop.md)).
4. **After merge or abandon:** remove the worktree and delete the local branch. The remote branch follows PR merge/close.
   - Workstream teardown also covers sims/emulators, Metro/dev servers, watchers, and tunnels — not only `git worktree remove`. See [teardown after proof](agent-proof-feedback-loop.md#teardown-after-proof).
5. **No long-lived dirty trees.** If blocked, mark blocked with evidence; park or discard. No zombies on disk.

**Cursor cloud fallback:** use the cloud agent's branch/PR lifecycle (no local worktree). Same thorough prompt and proof rules.

## Lifecycle

```text
intake → thorough prompt (skills + proof) → provision worktree → agent runs
  → collect & inspect proof → open PR → bot reviews
  → merge | changes-requested | abandon → teardown worktree
```

Statuses: `queued` → `running` → `needs-proof` → `ready-for-review` → `merged` | `blocked` | `discarded`

## Roles

- **Eng bots (Mark / Sam):** write the prompt, pick skills and proof type, start the agent on `agent-m1`, follow up, verify proof, open the PR, tear down.
- **Coding agent:** works only in its own workstream.
- **Jarvis:** postmortems when the lifecycle breaks (merged without proof, orphan worktrees).

## Do not

- Use full Cursor Projects / Orca DAGs as the primary path.
- Auto-merge.
- Let agents share the `main` checkout.
- Put two agents in the same worktree.
- Leave sims, emulators, or dev servers running after proof.
