# Agent proof feedback loop

Standing practice for eng work on `agent-m1` (Claude Code / Codex). Inspired by Lingxi's "complete feedback loop" — adapted to flexible proof.

Related: pstack's prove-it-works and verification-skill pattern — see [Steal from pstack](steal-from-pstack.md). Checks that must fail closed: [Hard constraints](hard-constraints.md).

## Rule

A coding agent is not done when CI is green or files changed. It is done when it has **produced and inspected** task-relevant proof that the ask was met.

## Choose proof by task type

- **Visual / UI**: screenshots (before/after when useful); screen recordings when a still cannot show the flow (animations, transitions, multi-step interactions). Prefer Argent skills: `argent-ios-simulator-setup` or `argent-android-emulator-setup` → `argent-react-native-app-workflow` → `argent-test-ui-flow` (or `argent-screenshot-diff`).
- **Multi-platform apps** (Expo/RN and similar): verify on **every supported platform** named in the task (typically iOS + Android). iOS-only or Android-only is not done unless the task explicitly scoped one platform.
- **Non-visual behavior**: logs, test output, CLI exit codes, network traces, profiler summaries — whatever a human would check.
- **Do not** attach screenshots for purely backend/logic changes just for show. Do not claim "verified" without reading the proof.

## Host

- **Only:** `agent-m1` with simulators/AVDs already provisioned. Requires **Argent CLI + MCP** (`@swmansion/argent`) — skills alone are not enough.

## Thorough launch prompt

A thin prompt produces thin proof. When Mark, Sam, or Jarvis kicks off **Claude Code or Codex** on agent-m1, write the launch prompt so the agent can close the loop on its own. Every launch prompt **must** include:

1. **Goal / success criteria.** State what "done" looks like in observable terms. Not "fix the header" — "header title no longer truncates on iPhone SE; tapping back returns to Home."
2. **Scope and constraints.** Name the files, packages, or areas in play. Say what is off-limits (no dependency bumps, no API changes, don't touch `ios/Podfile`, etc.).
3. **Skills to invoke, by name.** Always name `amillez-mode` first. Then list the skills this task needs, using the [skill chooser](#skill-chooser) below. Include **craft** skills (how to build it) as well as **proof** skills (how to show it works). Tell the agent it may pick additional skills when the task clearly needs them, and to say which ones it used.
4. **Proof expected.** Spell out the exact evidence to return and inspect:
   - UI: before/after screenshots of named screens/states (or `argent-screenshot-diff` output).
   - Behavior: specific log lines, network requests, or profiler summaries.
   - Logic: the test command to run and the pass criteria (e.g. `yarn test src/cart` — all green, new test covers the empty-cart case).
5. **Host routing.** Note `agent-m1` (Claude Code / Codex with Argent + provisioned sims/AVDs). Claude vs Codex per the [model lanes](../policies/agent-use-policy.md#default-picks) + Claude Code usage > 70% rule.

Do not launch until all five are in the prompt. If you cannot state the proof expected, the task is not defined enough to launch.

### Skill chooser

Match the task to every row that fits and name the union of those skills in the prompt. Most UI tasks match more than one row.

| Task smell | Required skills |
| --- | --- |
| Any coding task (single agent or Orca worker) | `amillez-mode` |
| RN UI, screens, native chrome (headers, tab bars, lists, forms) | `apple-design`, `react-native-best-practices` |
| Motion, gestures, sheet feel, spring or interruptible press motion, transitions, haptics | `animate-expo`, `apple-design` |
| Plain scale or opacity press feedback in a uniwind project | `uniwind` (`active:` variants), plus `apple-design` and `react-native-best-practices` as needed |
| Critiquing existing motion ("does this feel right?") | `review-animations` (+ `animate-expo` if also fixing) |
| Device proof (screenshots, flows, recordings) | Argent: `argent-ios-simulator-setup` / `argent-android-emulator-setup` → `argent-react-native-app-workflow` → `argent-test-ui-flow` (+ `argent-screen-recording` for motion) |
| Uniwind `className` work | `uniwind` |
| Any `.ts` or `.tsx` file | `typescript-best-practices` |

**Proof skills alone are never enough for feel-sensitive UI.** If the task touches sheets, motion, native chrome, or feel, include the craft skills above as well as Argent. A launch prompt that names only Argent skills for a sheet or animation task is incomplete. `review-animations` is not auto-invoked (`disable-model-invocation: true` upstream), so name it explicitly when you want a critique pass.

Example (bottom sheet with drag-to-dismiss): `Skills: amillez-mode, animate-expo, apple-design, react-native-best-practices, argent-ios-simulator-setup, argent-android-emulator-setup, argent-react-native-app-workflow, argent-test-ui-flow, argent-screen-recording; review-animations for a final motion critique.`

### Template

```text
Goal: <what done looks like, observable>
Scope: <files/areas>. Constraints: <what not to touch / limits>
Skills: amillez-mode, <craft skills from chooser>, <proof skills>. Use other skills if the task clearly needs them; list any you add.
Proof expected: <screenshots before/after of X | logs showing Y | run `<cmd>` and all pass>. Inspect the proof before reporting done; if it doesn't match, iterate or report the blocker with evidence.
Host: agent-m1 — Claude Code | Codex — <pick + reason>
```

## Loop

1. Launch with a [thorough prompt](#thorough-launch-prompt) — success criteria, skills, and expected proof stated up front.
2. Implement.
3. Collect proof with Launch, Doctor, Drive, and Evidence ([prove and inspect](#prove-and-inspect)). [Host media](#proof-media-hosting) on the repo's media branch.
4. **Inspect** proof against the success criteria. The coding agent that drove the app reads every asset, visual or not, and reports pass or fail with specifics.
5. If mismatch: follow up and repeat until proof matches — or report the blocker with evidence.
6. [Tear down](#teardown-after-proof) everything booted for the task.
7. Package repeated unblock steps into a skill/playbook note (avoid re-discovering env flakiness).

## Proof media hosting

Proof media = **screenshots and videos** (screen recordings, before/after clips). Video is first-class proof for visual/UI flows when a still is insufficient.

- **Do not** commit proof media on the PR/workstream branch.
- Push media to a media branch in the **same repo** the PR targets. Before pushing, list `git ls-remote --heads origin 'media*'` and follow the repo's existing convention: one `media` branch, or per-PR `media/<slug>` branches.
- Do not create a `media` branch beside an existing `media/<slug>` tree, and do not create `media/<slug>` beside a `media` branch. Git rejects both refs together.
- Create the media branch as an orphan (unrelated to `main`, hosts media only) only when it does not exist yet.
- Push from a detached temporary worktree. Never touch the workstream branch.
- Use a clear path: `proof/<pr-number-or-slug>/<file>`.
- In the **PR description**, embed or link each asset with verification notes next to it.
- **No raw URLs.** Repos may be private; `raw.githubusercontent.com` and other unauthenticated raw links break for reviewers. Use GitHub UI links built from the actual media branch name (`<media-branch>` below):
  - Images: `![before](https://github.com/<owner>/<repo>/blob/<media-branch>/proof/<slug>/before.png?raw=true)` renders for logged-in viewers, or link the blob page.
  - Videos: link the blob page `https://github.com/<owner>/<repo>/blob/<media-branch>/proof/<slug>/flow.mp4` — GitHub plays common formats there.

```bash
git ls-remote --heads origin 'media*'
MEDIA=media   # or media/<slug> when the repo keeps per-PR media branches
if git ls-remote --exit-code --heads origin "$MEDIA" >/dev/null; then
  git fetch origin "$MEDIA" && git worktree add --detach ../media-wt FETCH_HEAD
else
  git worktree add --orphan -b "$MEDIA" ../media-wt   # branch does not exist yet
fi
mkdir -p ../media-wt/proof/<slug> && cp <files> ../media-wt/proof/<slug>/
git -C ../media-wt add proof && git -C ../media-wt commit -m "Proof for <slug>"
git -C ../media-wt push origin "HEAD:refs/heads/$MEDIA"
git worktree remove ../media-wt
git branch -D "$MEDIA" 2>/dev/null || true   # local orphan branch only
```

## Prove and inspect

Prove the change on the real surface with the project's `verify-<app>` skill when the repo has one. Without one, run the same four steps by hand:

1. **Launch.** Start the app for verification and confirm it is ready. For Expo/RN, use Argent simulator or emulator setup.
2. **Doctor.** Run one read-only check that the instance is worth driving: process up, right build, port owned by this task. Run it again after any surprising drive.
3. **Drive.** Exercise the real user path with stable handles (accessibility labels, test IDs, routes), not internal setters or test-only endpoints. For Expo/RN, drive with Argent.
4. **Evidence.** Capture the action and the resulting state, plus side effects such as files written or requests sent. Screenshots and videos go to the [media branch](#proof-media-hosting). Logs, test output, and exit codes go in the PR body or a linked artifact.

Then inspect the evidence against the success criteria in the launch prompt:

- The coding agent that drove the app inspects every asset and reports **pass or fail with specifics**: what matched, what did not, and which asset shows it.
- When the task matches a visual reference, the success criteria list per-element checks: each icon's glyph, relative sizes, presentation type, and native versus drawn chrome. Whoever inspects reports pass or fail per element, not an overall match.
- A second judge is not required when the implementer already proved the change on device.
- A separate verification session is optional. Give it the success criteria and the media links. It only inspects proof and never implements. Pick its model per task from the [agent chooser](../policies/agent-use-policy.md#agent-chooser-examples).

## Teardown after proof

Teardown is part of done — same bar as inspecting proof.

- After proof is collected and inspected, shut down what you started: iOS Simulator / Android emulator, Metro/dev servers, watchers, temporary tunnels — anything booted for the task.
- Prefer Argent/device skills to shut down cleanly (e.g. `stop-all-simulator-servers` scoped to the devices this session used). Otherwise quit the sim/emulator and kill leftover node/Metro processes for that workstream.
- For Expo/RN work, explicitly find and kill the matching `expo/bin/cli`, `expo start`, and `expo run` processes started for the worktree; do not rely only on `metro` or `Simulator` process-name patterns. Then verify that nothing is listening on every Metro port used (commonly 8081 and 8090). Ben's infra bot sweep of `agent-m1` is a backstop; the task owner still tears down.
- On macOS, review the matching PIDs before terminating them, then check the common ports (add any port the task used):

  ```bash
  pgrep -fl 'expo/bin/cli|expo (start|run)' || true
  # After confirming the matches belong to this worktree:
  pkill -TERM -f 'expo/bin/cli|expo (start|run)' || true
  for port in 8081 8090; do
    lsof -nP -iTCP:"$port" -sTCP:LISTEN || true
  done
  ```

  Empty `lsof` output for each used port is the teardown check. Do not leave sims or emulators running "for the next agent." The next workstream boots what it needs.

## Skills allowlist

Only these skills are approved for launch prompts. Use each when its skill description matches the task, unless noted.

- `amillez-mode` (amillez skill, core). **Required** working mode for every coding agent, single agent or Orca worker. Name it in every launch prompt and worker brief. Grok Bots do not load it; attaching the right skills to prompts is one of their most important jobs, and `amillez-mode` is always first.
- **Argent** — all `argent-*` skills (device setup, interaction, UI flows, screenshot diff, profiling, recording, etc.); pick by description.
- `animate-expo` — building animations.
- `apple-design` — building UIs.
- `review-animations` (Emil) — reviewing / critiquing existing motion against Emil's craft bar. **Not auto-invoked** (`disable-model-invocation: true` upstream): name it explicitly in launch prompts for critique passes.
- `grill-me`. Settle a contested product or preference call that a prototype can't settle.
- **Expo** (`expo/skills`):
  - `expo-dev-client` — build and distribute Expo development clients locally or via TestFlight for internal testing. For production TestFlight releases and store submission, use `eas-app-stores`.
  - `expo-upgrade` — per skill description: Expo SDK upgrades, dependency conflicts, deprecated packages, cache cleanup.
- `react-native-best-practices` (`software-mansion-labs/skills`) — per skill description; use when writing, reviewing, or debugging ANY React Native or Expo code.
- `uniwind` (`uni-stack/uniwind`) — per skill description; use when building or debugging Uniwind `className` styling in React Native.
- `typescript-best-practices` (amillez skill, core). TypeScript type discipline for any `.ts` or `.tsx` file. Auto-loads by file path in Claude Code and by description in Codex. React Native library usage defers to `react-native-best-practices`.
- `orchestrate-agents`. Size gate, then Orca for large work, with the worker brief template (every brief names `amillez-mode`) and retry by failure mode.
- `create-verification-skill`, `maintain-verification-skill` (amillez skill, core). Generate and maintain a project's `verify-<app>` skill and feature map.
- `setup-amillez-models` (amillez skill, core). Install or refresh the Claude Code and Codex model-lane rules that mirror the [agent use policy](../policies/agent-use-policy.md#default-picks).
- **Native / Nitro** (only when building native modules): `api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`; pick by description.

### Skill store

Canonical install/update lives in the private repo [amillez/akit](https://github.com/amillez/akit). **Before coding, run `./scripts/ensure-install.sh`**. It ensures **core+mobile** on the host at `~/.claude` / `~/.agents` (no `~/.codex`, never into the project tree) and continues when already present. Use `./scripts/install.sh` for a full install and `./scripts/update-install.sh` / `./scripts/update-upstream.sh` to refresh or pull upstream updates. Machines should not hand-duplicate skill folders.
