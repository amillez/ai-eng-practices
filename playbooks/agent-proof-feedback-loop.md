# Agent proof feedback loop

Standing practice for eng work on `agent-m1` (Claude Code / Codex). Inspired by Lingxi's "complete feedback loop" — adapted to flexible proof.

## Rule

A coding agent is not done when CI is green or files changed. It is done when it has **produced and inspected** task-relevant proof that the ask was met.

## Choose proof by task type

- **Visual / UI**: screenshots (before/after when useful). Prefer Argent skills: `argent-ios-simulator-setup` or `argent-android-emulator-setup` → `argent-react-native-app-workflow` → `argent-test-ui-flow` (or `argent-screenshot-diff`).
- **Multi-platform apps** (Expo/RN and similar): verify on **every supported platform** named in the task (typically iOS + Android). iOS-only or Android-only is not done unless the task explicitly scoped one platform.
- **Non-visual behavior**: logs, test output, CLI exit codes, network traces, profiler summaries — whatever a human would check.
- **Do not** attach screenshots for purely backend/logic changes just for show. Do not claim "verified" without reading the proof.

## Host

- Primary: `agent-m1` with simulators/AVDs already provisioned. Requires **Argent CLI + MCP** (`@swmansion/argent`) — skills alone are not enough.
- Cursor cloud fallback only if `agent-m1` is down (see [agent use policy](../policies/agent-use-policy.md)). Screenshot loops are weaker there without a private worker.

## Thorough launch prompt

A thin prompt produces thin proof. When Mark, Sam, or Jarvis kicks off **Claude Code, Codex, or a Cursor cloud agent**, write the launch prompt so the agent can close the loop on its own. Every launch prompt **must** include:

1. **Goal / success criteria.** State what "done" looks like in observable terms. Not "fix the header" — "header title no longer truncates on iPhone SE; tapping back returns to Home."
2. **Scope and constraints.** Name the files, packages, or areas in play. Say what is off-limits (no dependency bumps, no API changes, don't touch `ios/Podfile`, etc.).
3. **Skills to invoke, by name.** List the skills this task needs (e.g. `argent-ios-simulator-setup`, `argent-react-native-app-workflow`, `argent-test-ui-flow`). Tell the agent it may pick additional skills when the task clearly needs them — and to say which ones it used.
4. **Proof expected.** Spell out the exact evidence to return and inspect:
   - UI: before/after screenshots of named screens/states (or `argent-screenshot-diff` output).
   - Behavior: specific log lines, network requests, or profiler summaries.
   - Logic: the test command to run and the pass criteria (e.g. `yarn test src/cart` — all green, new test covers the empty-cart case).
5. **Host routing (when relevant).** Note `agent-m1` as primary (Claude Code / Codex with Argent + provisioned sims/AVDs). If falling back to Cursor cloud, say so and adjust proof expectations accordingly.

Do not launch until all five are in the prompt. If you cannot state the proof expected, the task is not defined enough to launch.

### Template

```text
Goal: <what done looks like, observable>
Scope: <files/areas>. Constraints: <what not to touch / limits>
Skills: <skill-a>, <skill-b>. Use other skills if the task clearly needs them; list any you add.
Proof expected: <screenshots before/after of X | logs showing Y | run `<cmd>` and all pass>. Inspect the proof before reporting done; if it doesn't match, iterate or report the blocker with evidence.
Host: agent-m1 (primary) | Cursor cloud fallback — <reason>
```

## Loop

1. Launch with a [thorough prompt](#thorough-launch-prompt) — success criteria, skills, and expected proof stated up front.
2. Implement.
3. Collect proof (boot sim if needed; run flow or tests).
4. **Inspect** proof (multimodal for screenshots; read logs/tests for non-visual).
5. If mismatch: follow up and repeat until proof matches — or report the blocker with evidence.
6. [Tear down](#teardown-after-proof) everything booted for the task.
7. Package repeated unblock steps into a skill/playbook note (avoid re-discovering env flakiness).

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
- `grill-me` — stress-test a plan or design before building.
- **Expo** (`expo/skills`):
  - `expo-native-ui` — building native UI.
  - `expo-ui` — building native UI.
  - `expo-dev-client` — build and distribute Expo development clients locally or via TestFlight for internal testing. For production TestFlight releases and store submission, use `eas-app-stores`.
  - `expo-upgrade` — per skill description: Expo SDK upgrades, dependency conflicts, deprecated packages, cache cleanup.
- `react-native-best-practices` (`software-mansion-labs/skills`) — per skill description; use when writing, reviewing, or debugging ANY React Native or Expo code.
- `uniwind` (`uni-stack/uniwind`) — per skill description; use when building or debugging Uniwind `className` styling in React Native.
- `orchestrate-agents` — fan out large work into parallel isolated prompts (works with Claude Code and Codex workers).
- **Native / Nitro** (only when building native modules): `api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`; pick by description.

### Skill store

Canonical install/update lives in the private repo [amillez/agent-skills](https://github.com/amillez/agent-skills): run `./scripts/install.sh` to install and `./scripts/update-upstream.sh` to pull upstream updates. Machines should not hand-duplicate skill folders.
