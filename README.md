# AI engineering practices

Living, opinionated practices for AI-assisted software engineering.

**Coding host (2026-09-18):** `agent-m1` running **Claude Code + Codex only**. Cursor cloud / Composer / My Machines are out of the coding workflow. Grok Bot remains the chat/control plane. See [agent use policy](policies/agent-use-policy.md).

This repo is a small set of playbooks and standing policies. Prefer checklists and decision guides over essays. Keep advice cost-aware and anti-hype. When a number comes from a talk or eval, treat it as a snapshot, not eternal truth.

## Playbooks

| Playbook | Use when |
| --- | --- |
| [Model selection & token efficiency](playbooks/model-selection-and-token-efficiency.md) | Choosing a model, writing a prompt, or diagnosing spend / blurry context |
| [Cursor Projects](playbooks/cursor-projects.md) | **Historical** — Cursor Projects vs Grok Bot; coding host is Claude/Codex |
| [Eng team of bots](playbooks/eng-team-of-bots.md) | Running specialized eng bots that dispatch/babysit agent-m1 Claude Code / Codex |
| [Agent proof feedback loop](playbooks/agent-proof-feedback-loop.md) | Deciding when a coding agent is done and what proof it must produce |
| [Agent dispatch lifecycle](playbooks/agent-dispatch-lifecycle.md) | Dispatching work to a coding agent: worktree, PR, teardown |
| [Big-work orchestration](playbooks/big-work-orchestration.md) | Large features: orchestrator session → workers → integrate → prove → babysit |
| [Steal from pstack](playbooks/steal-from-pstack.md) | Deciding which pstack skills/playbooks to adopt, defer, or skip |
| [Hard constraints](playbooks/hard-constraints.md) | Encoding footguns in lint/CI instead of prose, so the proof loop fails closed |
| [amillez-mode](playbooks/amillez-mode.md) | Remapping poteto / Cursor-first skill defaults onto our stack while keeping the craft bar |
| [MCP vs CLI](playbooks/mcp-vs-cli.md) | Choosing MCP connectors vs CLI/`curl` for service integrations |

## Standing policies (for humans and bots)

| Policy | Use when |
| --- | --- |
| [Agent use policy](policies/agent-use-policy.md) | Default operating rules for any agent unless a chat explicitly overrides |

## Sources

Workshop notes and citations live under [`sources/`](sources/).

| Source | Topic |
| --- | --- |
| [Cursor: Model Selection & Token Efficiency](sources/cursor-model-selection-token-efficiency.md) | Workshop (Aug 2026) |
| [Research digest 2026-09-12](sources/research-digest-2026-09-12.md) | Projects, Grok Bot fleets, evals drift, policy updates |
| [Friday digest 2026-09-18](sources/friday-digest-2026-09-18.md) | Prefer MCP over CLI for most integrations (propose #5) |

## How to propose updates

1. Open a PR against `main`. One topic per PR when you can.
2. Say what changed, why, and which source it came from (talk, docs, lived practice).
3. Mark any prices, evals, or model-quality claims as **as of [date / source]**. Do not present them as permanent.
4. Keep the layout small: `playbooks/`, `policies/`, `sources/`. No extra scaffolding.

## For agents

Treat playbooks and policies in this repo as **standing policy** for any agent pointed at them.

- Follow them unless the current chat explicitly overrides for that one-off.
- Prefer the latest merged `main` over memory of an older version.
- Do not invent workshop quotes. Paraphrase practices; cite the source note.
- Model role labels (Luna/Sol/Opus/Fable) map to Claude Code / Codex per [agent use policy](policies/agent-use-policy.md); skip Cursor-only lanes.
