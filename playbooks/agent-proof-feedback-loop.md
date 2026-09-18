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
- No Cursor cloud coding / prove fallback (see [agent use policy](../policies/agent-use-policy.md)).

## Thorough launch prompt

A thin prompt produces thin proof. When Mark, Sam, or Jarvis kicks off **Claude Code or Codex** on agent-m1, write the launch prompt so the agent can close the loop on its own. Every launch prompt **must** include:

1. **Goal / success criteria.** State what "done" looks like in observable terms. Not "fix the header" — "header title no longer truncates on iPhone SE; tapping back returns to Home."
2. **Scope and constraints.** Name the files, packages, or areas in play. Say what is off-limits (no dependency bumps, no API changes, don't touch `ios/Podfile`, etc.).
3. **Skills to invoke, by name.** List the skills this task needs, using the [skill chooser](#skill-chooser) below. Include **craft** skills (how to build it) as well as **proof** skills (how to show it works). Tell the agent it may pick additional skills when the task clearly needs them, and to say which ones it used.
4. **Proof expected.** Spell out the exact evidence to return and inspect:
   - UI: before/after screenshots of named screens/states (or `argent-screenshot-diff` output).
   - Behavior: specific log lines, network requests, or profiler summaries.
   - Logic: the test command to run and the pass criteria (e.g. `yarn test src/cart` — all green, new test covers the empty-cart case).
5. **Host routing.** Note `agent-m1` (Claude Code / Codex with Argent + provisioned sims/AVDs). Claude vs Codex per chooser TBD.

Do not launch until all five are in the prompt. If you cannot state the proof expected, the task is not defined enough to launch.

### Skill chooser

Match the task to every row that fits and name the union of those skills in the prompt. Most UI tasks match more than one row.

| Task smell | Required skills |
| --- | --- |
| RN UI, screens, native chrome (headers, tab bars, lists, forms) | `apple-design`, `react-native-best-practices` |
| Motion, gestures, sheet feel, press feedback, transitions, haptics | `animate-expo`, `apple-design` |
| Critiquing existing motion ("does this feel right?") | `review-animations` (+ `animate-expo` if also fixing) |
| Building with `@expo/ui` / SwiftUI or Compose hosts | `expo-native-ui` |
| Device proof (screenshots, flows, recordings) | Argent: `argent-ios-simulator-setup` / `argent-android-emulator-setup` → `argent-react-native-app-workflow` → `argent-test-ui-flow` (+ `argent-screen-recording` for motion) |
| Uniwind `className` work | `uniwind` |

**Proof skills alone are never enough for feel-sensitive UI.** If the task touches sheets, motion, native chrome, or feel, include the craft skills above as well as Argent. A launch prompt that names only Argent skills for a sheet or animation task is incomplete. `review-animations` is not auto-invoked (`disable-model-invocation: true` upstream), so name it explicitly when you want a critique pass.

Example (bottom sheet with drag-to-dismiss): `Skills: animate-expo, apple-design, react-native-best-practices, argent-ios-simulator-setup, argent-android-emulator-setup, argent-react-native-app-workflow, argent-test-ui-flow, argent-screen-recording; review-animations for a final motion critique.`

### Template

```text
Goal: <what done looks like, observable>
Scope: <files/areas>. Constraints: <what not to touch / limits>
Skills: <craft skills from chooser>, <proof skills>. Use other skills if the task clearly needs them; list any you add.
Proof expected: <screenshots before/after of X | logs showing Y | run `<cmd>` and all pass>. Inspect the proof before reporting done; if it doesn't match, iterate or report the blocker with evidence.
Host: agent-m1 — Claude Code | Codex — <pick + reason>
```

## Loop

1. Launch with a [thorough prompt](#thorough-launch-prompt) — success criteria, skills, and expected proof stated up front.
2. Implement.
3. Collect proof (boot sim if needed; run flow or tests). [Host media](#proof-media-hosting) on the `media` branch.
4. **Inspect** proof. Visual (screenshots/videos): hand off to a [Luna Max verifier](#visual-verification-luna-max-subagent). Non-visual (logs, tests, exit codes): the coding agent reads it directly.
5. If mismatch: follow up and repeat until proof matches — or report the blocker with evidence.
6. [Tear down](#teardown-after-proof) everything booted for the task.
7. Package repeated unblock steps into a skill/playbook note (avoid re-discovering env flakiness).

## Proof media hosting

Proof media = **screenshots and videos** (screen recordings, before/after clips). Video is first-class proof for visual/UI flows when a still is insufficient.

- **Do not** commit proof media on the PR/workstream branch.
- Push media to a dedicated **`media`** branch in the **same repo** the PR targets. If it does not exist, create it as an orphan branch (unrelated to `main`; hosts media only).
- Use a clear path: `proof/<pr-number-or-slug>/<file>`.
- In the **PR description**, embed or link each asset with verification notes next to it.
- **No raw URLs.** Repos may be private; `raw.githubusercontent.com` and other unauthenticated raw links break for reviewers. Use GitHub UI links:
  - Images: `![before](https://github.com/<owner>/<repo>/blob/media/proof/<slug>/before.png?raw=true)` renders for logged-in viewers, or link the blob page.
  - Videos: link the blob page `https://github.com/<owner>/<repo>/blob/media/proof/<slug>/flow.mp4` — GitHub plays common formats there.

```bash
# separate worktree; never touch the workstream branch
git fetch origin media && git worktree add ../media-wt media \
  || git worktree add --orphan -b media ../media-wt   # first time only
mkdir -p ../media-wt/proof/<slug> && cp <files> ../media-wt/proof/<slug>/
git -C ../media-wt add proof && git -C ../media-wt commit -m "Proof for <slug>" && git -C ../media-wt push -u origin media
git worktree remove ../media-wt
```

## Visual verification: Luna Max subagent

Do not spend a heavy coding-model turn (Claude Code / Codex on `agent-m1`) on multimodal inspection of screenshots or videos.

- For visual proof, the eng bot (or the coding agent via spawn) launches a **Codex Luna-role session on agent-m1**, effort Max — verification-only.
- Its only job: inspect the media against the stated success criteria and report **pass/fail + specifics** (what matched, what didn't, which asset).
- Give it the success criteria and the media links; nothing else to implement.
- Non-visual proof (logs, tests, exit codes) stays with the coding agent — no Luna.
- Luna Max here is **verification-only**. Implementation stays on the [agent chooser](../policies/agent-use-policy.md#agent-chooser-examples) pick (Sol / Opus / Fable-role → Opus). Not a Cursor cloud subagent.

## Teardown after proof

Teardown is part of done — same bar as inspecting proof.

- After proof is collected and inspected, shut down what you started: iOS Simulator / Android emulator, Metro/dev servers, watchers, temporary tunnels — anything booted for the task.
- Prefer Argent/device skills to shut down cleanly (e.g. `stop-all-simulator-servers` scoped to the devices this session used). Otherwise quit the sim/emulator and kill leftover node/Metro processes for that workstream.
- Do not leave sims or emulators running "for the next agent." The next workstream boots what it needs.

## Skills allowlist

Only these skills are approved for launch prompts. Use each when its skill description matches the task, unless noted.

- **Argent** — all `argent-*` skills (device setup, interaction, UI flows, screenshot diff, profiling, recording, etc.); pick by description.
- `animate-expo` — building animations.
- `apple-design` — building UIs.
- `review-animations` (Emil) — reviewing / critiquing existing motion against Emil's craft bar. **Not auto-invoked** (`disable-model-invocation: true` upstream): name it explicitly in launch prompts for critique passes.
- `grill-me` — stress-test a plan or design before building.
- **Expo** (`expo/skills`):
  - `expo-native-ui` — building native UI.
  - `expo-dev-client` — build and distribute Expo development clients locally or via TestFlight for internal testing. For production TestFlight releases and store submission, use `eas-app-stores`.
  - `expo-upgrade` — per skill description: Expo SDK upgrades, dependency conflicts, deprecated packages, cache cleanup.
- `react-native-best-practices` (`software-mansion-labs/skills`) — per skill description; use when writing, reviewing, or debugging ANY React Native or Expo code.
- `uniwind` (`uni-stack/uniwind`) — per skill description; use when building or debugging Uniwind `className` styling in React Native.
- `orchestrate-agents` — fan out large work into parallel isolated prompts (works with Claude Code and Codex workers).
- **Native / Nitro** (only when building native modules): `api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`; pick by description.

### Skill store

Canonical install/update lives in the private repo [amillez/agent-skills](https://github.com/amillez/agent-skills): run `./scripts/install.sh` to install and `./scripts/update-upstream.sh` to pull upstream updates. Machines should not hand-duplicate skill folders.
