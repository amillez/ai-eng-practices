# Hard constraints and agent-friendly co-location

Two repo-shape practices that make coding agents on `agent-m1` (Claude Code / Codex) land correct changes with less thrash. Inspired by Lauren Tan (poteto)'s GrokBot workshop, as shared on X by Sheema; paraphrased, not quoted.

Related: [agent proof feedback loop](agent-proof-feedback-loop.md), [agent use policy](../policies/agent-use-policy.md), [steal from pstack](steal-from-pstack.md).

## 1. Hard constraints over soft prompts

Agents ignore prose rules ("don't use X") often enough that prose cannot own correctness. Put footguns where the agent cannot get past them.

### Rule

- **Enforce correctness boundaries in tooling** — lint, typecheck, compiler, CI. If a banned pattern can merge, the rule does not exist.
- **The proof loop fails closed.** A red lint/typecheck/test step means not done; see [agent proof feedback loop](agent-proof-feedback-loop.md#rule). Babysit the PR until those checks pass — do not merge around them.
- **Soft prompts keep taste.** Naming, style, comment tone, and design preference stay in prompts, skills, and review. Correctness does not.

### Kinds of rules to encode

Examples of the shape, not mandates for any project:

- Ban problematic APIs or imports via eslint / biome (`no-restricted-imports`, `no-restricted-syntax`, custom rules).
- Typecheck must pass in CI; no `any`/`@ts-ignore` escape hatches without an allowlist.
- Changed modules need tests (coverage or "test file touched" gate) where the repo can support it.
- No fix-by-silencing: disabling a lint rule, skipping a test, or loosening a type requires root-cause evidence in the PR description.

### When an agent hits a repeat footgun

1. Fix the instance.
2. Ask: can a lint rule, type, or CI check make this impossible next time? If yes, add it in a follow-up PR (small, one rule).
3. Only if tooling cannot express it, add a short prompt/skill note — and treat it as best effort.

## 2. Agent-friendly co-location (shortest path)

Agents optimize for the shortest path. When a feature is scattered across a monorepo, they thrash searching and ship incomplete edits (entrypoint updated, test or doc missed).

### Rule

- **Co-locate what changes together:** feature code, entrypoints, tests, and local docs (a short `README.md` in the module) when practical.
- **Prefer clear module boundaries** — one obvious public entry per module — over organic sprawl only a long-tenured human can navigate.
- **No big-bang rewrite.** Apply on new features and when touching a module; gardening PRs can chip away. Keep moves in their own PR, separate from behavior changes.

### RN / Expo

- Keep a feature's screens, hooks, components, and native module bits discoverable together (e.g. `features/<name>/`) when possible.
- Respect the app's existing layout conventions — Expo Router's `app/` routes stay where the router needs them; route files can stay thin and import from the feature folder.
- Native code that must live in `ios/` / `android/` or a Nitro module package: link it from the feature's local doc so agents find it.

### In launch prompts

Name the feature folder in **Scope** of the [thorough launch prompt](agent-proof-feedback-loop.md#thorough-launch-prompt). If the relevant code is scattered, say where each piece lives — that is cheaper than the agent rediscovering it.
