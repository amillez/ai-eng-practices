# Agent proof feedback loop

Standing practice for eng work on `agent-m1` (Claude Code / Codex). Inspired by Lingxi's "complete feedback loop" — adapted to flexible proof.

## Rule

A coding agent is not done when CI is green or files changed. It is done when it has **produced and inspected** task-relevant proof that the ask was met.

## Choose proof by task type

- **Visual / UI**: screenshots (before/after when useful). Prefer Argent skills: `argent-ios-simulator-setup` or `argent-android-emulator-setup` → `argent-react-native-app-workflow` → `argent-test-ui-flow` (or `argent-screenshot-diff`).
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
6. Package repeated unblock steps into a skill/playbook note (avoid re-discovering env flakiness).

## Skills to invoke (when applicable)

Personal skill store on the agent host: `~/.agents/skills`.

- `argent-ios-simulator-setup` / `argent-android-emulator-setup` — boot and connect a device
- `argent-react-native-app-workflow` — start the app, Metro, builds
- `argent-test-ui-flow` — interact → screenshot → verify loops
- `argent-screenshot-diff` — before/after visual comparison
