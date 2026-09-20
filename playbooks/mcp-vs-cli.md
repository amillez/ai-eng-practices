# MCP vs CLI

Short decision guide for how agents talk to external services and host tooling.

Related: [agent use policy §8](../policies/agent-use-policy.md#8-integrations-mcp-vs-cli), [source: Friday digest 2026-09-18](../sources/friday-digest-2026-09-18.md).

## Prefer MCP

Use a dedicated MCP / connector when:

- A connector exists for the service (Notion, GitHub, Slack, X, etc.).
- Auth, pagination, or structured results matter.
- Bots/agents should stay on the sanctioned tool surface (`GetDynamicTools` → `CallDynamicTool`) — do not scrape, invent `curl`, or drive a signed-in browser for the same job.

## Prefer CLI

Use CLI / shell when:

- No MCP / connector exists for the job.
- The work is local host tooling that is CLI-native: `git`, `gh` for forge ops already done that way, Orca CLI orchestration, Argent CLI on `agent-m1`, package managers.
- One-off scripts, pipes, or batch shell that MCP does not cover well.

## Anti-patterns

- Driving a signed-in browser or inventing HTTP when an MCP already covers the mutation or read.
- Dual-pathing (MCP + CLI for the **same** mutation) without a stated reason.
- Enabling unused MCPs (prefix bloat) — already in [policy hygiene](../policies/agent-use-policy.md#7-rules-skills-and-mcp-hygiene).

## Related

- [trq212 / Cursor eng — prefer MCP over ad-hoc CLI](https://x.com/trq212/status/2099958388230873165) (as of Friday digest 2026-09-18 propose #5)
