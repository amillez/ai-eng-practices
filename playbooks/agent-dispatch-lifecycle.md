# Agent dispatch lifecycle

How bots dispatch work to coding agents: projects, worktrees, and teardown.

Standing stack: `agent-m1` running Claude Code / Codex **only**. Dispatch = Grok Bot → agent-m1 Claude/Codex session → proof → PR → teardown. No Cursor cloud / My Machines coding path (see [agent use policy](../policies/agent-use-policy.md#1-coding-host-routing)).

## Units

- **Task** — one ask with success criteria + proof type (bot chat + [thorough launch prompt](agent-proof-feedback-loop.md#thorough-launch-prompt)).
- **Workstream** — one git branch + one worktree + one agent session.
- **Project** (optional) — multi-task effort; thin tracker later (Notion). Cursor Projects are out of scope for coding.
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
2. **Ensure amillez plugin before coding (SoT).** On the **host** (user root), run [`amillez/agent-skills`](https://github.com/amillez/agent-skills) `scripts/ensure-install.sh` → **core+mobile** at `~/.claude` + `~/.agents` (+ user rules + stamp). **No `~/.codex`.** **Not** into the worktree/project tree. `ensure-project.sh` is a **thin alias that ignores any project path** — do **not** treat it as per-project plugin install into the worktree. If already present, continue — refresh only when policy/skills changed or a human asks (`--force`). Optionally also commit selected stack skills into the project for teammates (e.g. `uniwind`) even though they are on the device — do not dump the whole mobile set. Project `verify-*` stay in-repo. **Grok Bot dispatch prompts to Claude/Codex must include this host ensure step** first. (Host-ensure wording in [big-work orchestration](big-work-orchestration.md) is fixed in open #30 — coordinate, don't conflict.)
3. **One agent per worktree.** Parallel work = Orca `worker-start` with disjoint paths (`--worktree new-child`, max 2 under disk pressure) or sequential `--worktree current`. Never two agents on one checkout — see [Worktrees and disk](big-work-orchestration.md#worktrees-and-disk).
4. **PR is the exit artifact.** Include or link proof in the PR body or bot message (see [agent proof feedback loop](agent-proof-feedback-loop.md)).
   - Screenshots/videos live on the repo's `media` branch, never the PR branch; link them via GitHub blob URLs, not raw URLs. See [proof media hosting](agent-proof-feedback-loop.md#proof-media-hosting).
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
  --model <opaque-model-id> --effort <effort> \
  "<thorough launch prompt>"

# Capture session id
claude agents --json
```

Rules:

- Permissions bypass (`--dangerously-skip-permissions`) **only** on trusted `agent-m1`.
- Prefer explicit `--model` / `--effort` when the CLI supports them so Opus 5.5 High / GPT 6 Sol xHigh (etc.) is not “host default mystery.”
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

## Teardown

After proof, the task owner shuts down the iOS Simulator, Android emulator, Metro/dev servers, watchers, and tunnels started for the worktree. For Expo/RN work, also find and kill the matching `expo/bin/cli`, `expo start`, and `expo run` processes — they may not match `metro` or `Simulator` filters — then verify that no process is listening on every Metro port used (including 8081 or 8090). Ben's infra bot sweep of `agent-m1` is a backstop, not a substitute for the task owner's teardown. Use the [copy-pasteable check](agent-proof-feedback-loop.md#teardown-after-proof).

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
9. **Tear down in two stages.** Sims, emulators, dev servers, and matching Expo CLI processes go when proof is done; PR listeners and worktree stay until terminal. Verify every Metro port used is no longer listening.
10. **Keep status current.** `blocked` is not terminal — report it with evidence and keep watching or close it out.

Related: pstack's babysit playbook — see [Steal from pstack](steal-from-pstack.md).

## Roles

- **Eng bots (Mark / Sam):** write the prompt, pick skills and proof type, start the agent on `agent-m1`, follow up, verify proof, open the PR, babysit it until merged or closed, tear down. Responsibility ends at merge/teardown, not at agent launch.
- **Coding agent:** works only in its own workstream.
- **Jarvis:** postmortems when the lifecycle breaks (merged without proof, orphan worktrees).

## Do not

- Use Cursor cloud, Cursor Projects, My Machines, or `register-worker-dir` for coding.
- Skip the size gate: Orca Run for a rename, or one mega-agent for large multi-surface work. Small → direct agent; large → Orca + Opus 5.5 xhigh coordinator (see [big-work orchestration](big-work-orchestration.md)).
- Auto-merge.
- Let agents share the `main` checkout.
- Put two agents in the same worktree.
- Leave sims, emulators, or dev servers running after proof.
- Delegate agent-m1 Shell/`machineId` work to a Grok Bot **executor** Task subagent.

## Notes / Related

- Learning source: Anibal (ASNT) + Mark + Stella Monday eng 1:1s, 2026-09-21 — real-run Grok Bot→agent-m1 dispatch gaps (executor/`machineId`, `claude --bg`, ensure-install SoT, `claude respawn`, Orca `worker-start` flake).
- Orca orch readiness flake + one-time host install gate: [big-work orchestration](big-work-orchestration.md).
- Leave open #29 / #30 alone; coordinate ensure-host wording with #30 on `big-work-orchestration.md`.
