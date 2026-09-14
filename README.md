# AI engineering practices

Living, opinionated practices for AI-assisted software engineering.

This repo is a small set of playbooks and standing policies. Prefer checklists and decision guides over essays. Keep advice cost-aware and anti-hype. When a number comes from a talk or eval, treat it as a snapshot, not eternal truth.

## Playbooks

| Playbook | Use when |
| --- | --- |
| [Model selection & token efficiency](playbooks/model-selection-and-token-efficiency.md) | Choosing a model, writing a prompt, or diagnosing spend / blurry context |
| [Cursor Projects](playbooks/cursor-projects.md) | Deciding Project vs one-shot agent vs Grok Bot |
| [Eng team of bots](playbooks/eng-team-of-bots.md) | Running specialized bots that manage cloud agents |
| [Agent proof feedback loop](playbooks/agent-proof-feedback-loop.md) | Deciding when a coding agent is done and what proof it must produce |

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
- If a playbook and a live Cursor UI label disagree, use Cursor's current spelling in the product and keep the playbook's intent.
