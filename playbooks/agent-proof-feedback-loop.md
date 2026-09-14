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

## Loop

1. State success criteria and the proof type up front in the agent prompt.
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
- `autoreview` — optional closeout
