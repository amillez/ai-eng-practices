# Agent dispatch lifecycle

How bots dispatch work to coding agents: projects, worktrees, and teardown.

Standing stack: `agent-m1` running Claude Code / Codex **only**. Dispatch = Grok Bot → agent-m1 Claude/Codex session → proof → PR → teardown. Host rules: [agent use policy](../policies/agent-use-policy.md#1-coding-host-routing).

## Units

- **Task** — one ask with success criteria + proof type (bot chat + [thorough launch prompt](agent-proof-feedback-loop.md#thorough-launch-prompt)).
- **Workstream** — one git branch + one worktree + one agent session.
- **Project** (optional) — multi-task effort; thin tracker later (Notion).
- **Size gate → direct agent or Orca Run.** **Small** → corresponding agent (Luna/Sol/Opus) directly; no Orca Run. **Large / needs orch** (multi-surface, multi-package, parallelizable, multi-PR, multi-session, unclear blast radius) → eng bot kicks an **Opus 5.5 xhigh** coordinator inside **Orca** (`run-create` → tasks → `worker-start` Claude/Codex → `check --wait`). See [big-work orchestration](big-work-orchestration.md) · [Orca orchestration](https://www.onorca.dev/docs/cli/orchestration).

## Worktrees on `agent-m1`

Layout:

```text
~/agent-work/<repo>/
  main/                    # sync/human only — agents do not work here
  wt-<slug>-<shortid>/     # one agent = one worktree = one branch
```

Rules:

1. **On dispatch:** fetch, then `git worktree add -b agent/<bot>/<slug> <path> <base-ref>` from an up-to-date base (usually `main`).
2. **Ensure the amillez plugin on the host before coding.** Run [`amillez/akit`](https://github.com/amillez/akit) `scripts/ensure-install.sh`. It installs **core+mobile** at `~/.claude` and `~/.agents` (plus user rules and stamp, nothing under `~/.codex`) and continues when already present. Refresh with `scripts/update-install.sh` when policy or skills change or a human asks. Never install the plugin into the worktree. A project may commit selected stack skills (e.g. `uniwind`) as a teammate mirror, not the whole mobile set. Project `verify-*` skills stay in-repo. **Grok Bot dispatch prompts to Claude/Codex include this host ensure step first.**
3. **One agent per worktree.** Parallel work = Orca `worker-start` with disjoint paths (`--worktree new-child`, max 2 under disk pressure) or sequential `--worktree current`. Never two agents on one checkout — see [Worktrees and disk](big-work-orchestration.md#worktrees-and-disk).
4. **PR is the exit artifact.** Include or link proof in the PR body or bot message (see [agent proof feedback loop](agent-proof-feedback-loop.md)).
   - Screenshots/videos live on the repo's media branch (`media` or per-PR `media/<slug>`, per the repo's convention), never the PR branch; link them via GitHub blob URLs, not raw URLs. See [proof media hosting](agent-proof-feedback-loop.md#proof-media-hosting).
5. **After merge or abandon:** remove the worktree and delete the local branch. The remote branch follows PR merge/close.
   - Workstream teardown also covers sims/emulators, Metro/dev servers, watchers, and tunnels — not only `git worktree remove`. See [Teardown](#teardown) and [teardown after proof](agent-proof-feedback-loop.md#teardown-after-proof).
6. **No long-lived dirty trees.** If blocked, mark blocked with evidence; park or discard. No zombies on disk.

## Executor vs parent on `agent-m1`

Grok Bot **executor** Task subagents cannot pass `machineId` to Shell — their Shell runs on the **box**, not on `agent-m1`.

- **Parent** Grok Bot must run `agent-m1` Shell/Read with `machineId` (agent-m1 = `cbfdfd05-8447-4018-ad6b-26eb8a0e83b1`), or any machine-aware path.
- Do **not** delegate “launch Claude on agent-m1” / worktree create on m1 to an executor that expects Shell-with-`machineId`.
- Executors remain fine for `gh` / API / box work that does not need the Mac.

## Canonical Claude Code background launch on `agent-m1`

Recipe (parent Shell with `machineId`, after host ensure + worktree provision):

```bash
# Prefer positional prompt — do NOT use -p/--print (conflicts with attachable --bg)
claude --bg --dangerously-skip-permissions \
  --model claude-opus-5-5 --effort high \
  "<thorough launch prompt>"
# --model is the full lanes-table id, never an alias such as opus

# Capture session id
claude agents --json
```

Rules:

- Permissions bypass (`--dangerously-skip-permissions`) **only** on trusted `agent-m1`.
- Prefer explicit `--model` / `--effort` when the CLI supports them so Opus 5.5 High / GPT 6.1 Sol xHigh (etc.) is not “host default mystery.”
- Then arm hop-1 finite settle-watch per standing skill `agent-m1-completion-ping` / [Babysit until merged](#babysit-until-merged).
- **Post-upgrade stall:** if `--bg` sits on the startup dialog (`needs: open session`), unblock with `claude respawn <id>` (then re-check `claude agents --json`). Do not relaunch a duplicate session blindly.

## Lifecycle

```text
intake → thorough prompt (skills + proof) → provision worktree
  → ensure amillez core+mobile (host) → agent runs
  → collect & inspect proof → open PR → bot reviews
  → merge | changes-requested | abandon → teardown worktree
```

Statuses: `queued` → `running` → `needs-proof` → `ready-for-review` → `merged` | `blocked` | `discarded`

When the size gate says large/needs-orch, a parent **Orca Run** with an **Opus 5.5 xhigh** coordinator fans out Dispatches before integrate/prove; babysit still owns the landing PR(s) until terminal. Small work skips Orca. See [big-work orchestration](big-work-orchestration.md).

## Restate reports before acting

When the ask comes from a bug report, an issue, a user-feedback message, or a chat thread, the launcher (Grok Bot or an eng bot) passes the raw report or a link to it in the launch prompt and asks the agent to restate the underlying issue in plain words before any code. The launcher does **not** add its own hypothesis or suspected cause. A guess in the prompt anchors the agent and hides misreadings. Put the success criteria, skills, and proof type in the prompt as usual. If the launcher already has evidence (a stack trace, a failing command, a bisect result), include it labeled as evidence, not as the diagnosis. Read the agent's restatement first and correct a misreading before it builds. amillez-mode's Bug fix and Investigation playbooks start with the same restate step.

## Teardown

After proof, the task owner shuts down the iOS Simulator, Android emulator, Metro/dev servers, watchers, and tunnels started for the worktree. For Expo/RN work, also find and kill the matching `expo/bin/cli`, `expo start`, and `expo run` processes — they may not match `metro` or `Simulator` filters — then verify that no process is listening on every Metro port used (including 8081 or 8090). Ben's infra bot sweep of `agent-m1` is a backstop, not a substitute for the task owner's teardown. Use the [copy-pasteable check](agent-proof-feedback-loop.md#teardown-after-proof).

## Babysit until merged

1. **Own the workstream until a terminal status.** Terminal = merge, close, or abandon. Agent idle or session settle is not done.
2. **Hop 1 — session settle: arm a finite settle-watch.** Do not rely on silent background Shell wakes alone. The bot arms a finite weekday `*/10` Europe/Madrid routine that checks the Claude Code / Codex session on `agent-m1`, **must message** the user on settle, block, or deadline, then deletes itself. See standing skill `agent-m1-completion-ping`.
3. **Hop 2 — PR open: switch to GitHub listeners.** Babysit with PR-scoped GitHub event listeners (review, CI, push, `pr-merged`, `pr-closed`), not polling. `pr-merged` and `pr-closed` are always in the pack. Listeners do not reliably self-delete on merge, so every babysit routine prompt says explicitly to delete its own routine on the `pr-merged` or `pr-closed` wake. Launch prompts carry no Grok Bot webhook keys, and coding agents send no finish pings to a webhook.
4. **Match the PR on every listener wake.** On every GitHub listener wake, confirm the event's PR number matches this workstream's `pr_number`; ignore cross-PR payloads.
5. **Do not stop at settle.** While the PR is OPEN and review threads are unresolved, do not delete the settle-watch or stop babysitting just because the coding session finished.
6. **Filter listener noise, keep watching.** Empty-body COMMENTED reviews and agent fix-ack replies on unresolved threads can wake as review-commented. Stay quiet on pure noise, but do not treat it as a hard failure that abandons babysit.
7. **Apply Agustín's review comments as they appear.** No asking permission, no "I'll follow it" chatter. Ping only for real blockers, requested settle/proof results, or merge/close. Carve-out: a comment that can only be met by overriding platform behavior (new native module, dependency patch, native build change, dynamic font linking) ships the platform default plus a thread reply that names the override's cost. Build the override only on the reviewer's go.
8. **Changes requested or CI fails → follow up.** Send the coding agent back in, or open a follow-up workstream. Never go silent.
9. **Tear down in two stages.** Sims, emulators, dev servers, and matching Expo CLI processes go when proof is done; PR listeners and worktree stay until terminal. On terminal, the babysit routine deletes itself, and the bot sweeps any stale babysit routines left for the merged or closed PR. Verify every Metro port used is no longer listening.
10. **Keep status current.** `blocked` is not terminal — report it with evidence and keep watching or close it out.

Related: the coding agent's side of a babysit (what it does when sent back with review comments or red CI) is the amillez-mode [Babysit playbook](https://github.com/amillez/akit/blob/main/skills/amillez-mode/playbooks/babysit.md). The bot side stays here.

## Roles

- **Eng bots (Mark / Sam):** write the prompt, pick skills and proof type (always attach `amillez-mode` for coding agents; knowing which skills to attach is one of the bot's most important jobs), start the agent on `agent-m1`, follow up, verify proof and the PR the agent opens, babysit it until merged or closed, tear down. Responsibility ends at merge/teardown, not at agent launch.
- **Coding agent:** works only in its own workstream, under `amillez-mode`, and opens its PR. Never merges, arms auto-merge, or closes the PR.
- **Jarvis:** postmortems when the lifecycle breaks (merged without proof, orphan worktrees).

## Do not

- Use Cursor cloud, Cursor Projects, My Machines, or `register-worker-dir` for coding.
- Skip the size gate: Orca Run for a rename, or one mega-agent for large multi-surface work. Small → direct agent; large → Orca + Opus 5.5 xhigh coordinator (see [big-work orchestration](big-work-orchestration.md)).
- Auto-merge.
- Paraphrase a report into your own diagnosis in the launch prompt. Pass the raw report and ask for a restatement.
- Let agents share the `main` checkout.
- Put two agents in the same worktree.
- Leave sims, emulators, or dev servers running after proof.
- Delegate agent-m1 Shell/`machineId` work to a Grok Bot **executor** Task subagent.

## Related

- Orca `worker-start` readiness timeouts and the one-time Orca host install: [big-work orchestration](big-work-orchestration.md).
