# AI engineering practices

Living, opinionated practices for AI-assisted software engineering.

**Coding hosts:** the [Orca hosts](policies/agent-use-policy.md#host-table), `agent-m1` by default and the M4 as overflow, running **Claude Code** (default coder), the **Cursor Agent CLI** (Grok 4.7 xHigh when Claude Code usage > 70%), and **Codex** (code review only, plus the [raster image exception](policies/agent-use-policy.md#codex-raster-image-exception)). Every coding session and review starts through Orca. Grok Bot is the chat and control plane. See [agent use policy](policies/agent-use-policy.md).

This repo is a small set of playbooks and standing policies. Prefer checklists and decision guides over essays. Keep advice cost-aware and anti-hype. When a number comes from a talk or eval, treat it as a snapshot, not eternal truth.

## Playbooks

| Playbook | Use when |
| --- | --- |
| [Model selection & token efficiency](playbooks/model-selection-and-token-efficiency.md) | Choosing a model, writing a prompt, or diagnosing spend / blurry context |
| [Eng team of bots](playbooks/eng-team-of-bots.md) | Running specialized eng bots that dispatch and babysit coding agents on the Orca hosts |
| [Agent proof feedback loop](playbooks/agent-proof-feedback-loop.md) | Deciding when a coding agent is done and what proof it must produce |
| [Agent dispatch lifecycle](playbooks/agent-dispatch-lifecycle.md) | Dispatching work to a coding agent: worktree, PR, teardown |
| [Big-work orchestration](playbooks/big-work-orchestration.md) | Large work: an Orca Run whose Opus 5.5 xHigh coordinator plans and dispatches while workers implement, integrate, and prove |
| [Steal from pstack](playbooks/steal-from-pstack.md) | Deciding which pstack skills/playbooks to adopt, defer, or skip |
| [Hard constraints](playbooks/hard-constraints.md) | Encoding footguns in lint/CI instead of prose, so the proof loop fails closed |
| [amillez-mode](playbooks/amillez-mode.md) | Pointer to the required `amillez-mode` skill in `amillez/akit`, which every coding agent loads |
| [MCP vs CLI](playbooks/mcp-vs-cli.md) | Choosing MCP connectors vs CLI/`curl` for service integrations |

## Standing policies (for humans and bots)

| Policy | Use when |
| --- | --- |
| [Agent use policy](policies/agent-use-policy.md) | Default operating rules for any agent unless a chat explicitly overrides |
| [Grok Bot fleet norms](policies/fleet-norms.md) | A Grok Bot decides whether to raise an item, nudge Agustín, start a routine, or store policy |

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
4. Keep the layout small: `playbooks/`, `policies/`, `sources/`, and `scripts/` for checks. No extra scaffolding.
5. Run `scripts/check-links.sh` before you push. It checks every relative link and `#anchor`.

## For agents

Treat playbooks and policies in this repo as **standing policy** for any agent pointed at them.

- Follow them unless the current chat explicitly overrides for that one-off.
- Prefer the latest merged `main` over memory of an older version.
- Do not invent workshop quotes. Paraphrase practices; cite the source note.
- Every coding agent you invoke, single or Orca worker, loads and follows [`amillez-mode`](playbooks/amillez-mode.md), and the launch prompt names it. Grok Bots do not load amillez-mode themselves; they must know which skills to attach to launch prompts, and `amillez-mode` is always first.
- Model lanes ([agent use policy](policies/agent-use-policy.md#default-picks)): super defined → Claude Haiku 5.5 Max (Claude Code `claude-haiku-5-5`); general code, UI, and docs → Opus 5.5 High (Claude Code `claude-opus-5-5`), or Grok 4.7 xHigh (Cursor Agent CLI `grok-4.7-xhigh`) when Claude Code usage > 70%; large-work orch → Opus 5.5 xHigh Orca coordinator; large reasoning → Fable 5.1 Medium→High/xhigh. Code review, when the [Review row](policies/agent-use-policy.md#1-coding-host-routing) requires one → GPT 6.1 Sol High (Codex `gpt-6.1-sol`, read-only).
