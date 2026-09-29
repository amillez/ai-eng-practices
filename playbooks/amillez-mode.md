# amillez-mode

`amillez-mode` is the required working mode for every coding agent we invoke, a single agent or an Orca worker. It keeps the pstack craft bar (poteto-mode, MIT) and remaps its Cursor-first defaults onto our stack.

The skill is the source of truth. It lives in [`amillez/akit` `skills/amillez-mode`](https://github.com/amillez/akit/tree/main/skills/amillez-mode):

- [`SKILL.md`](https://github.com/amillez/akit/blob/main/skills/amillez-mode/SKILL.md) holds the non-negotiables, principles index, reply rules, playbook router, and the remap table from upstream defaults to our stack.
- `playbooks/`, `principles/`, and `references/` hold the ported craft.
- [`UPSTREAM.md`](https://github.com/amillez/akit/blob/main/skills/amillez-mode/UPSTREAM.md) holds the upstream pin, attribution, and per-file verdicts.

It installs with the core group of the amillez plugin (`scripts/ensure-install.sh`).

The pstack fan-out skills (`how`, `why`, `architect`, `arena`, `swarm`, `interrogate`) are not part of it. `reflect` is ported as the amillez-mode Reflect playbook. See [Steal from pstack](steal-from-pstack.md).

## How to require it

- Every launch prompt and every Orca worker brief names `amillez-mode`. See [agent use policy §1](../policies/agent-use-policy.md#1-coding-host-routing) and the [thorough launch prompt](agent-proof-feedback-loop.md#thorough-launch-prompt).
- Grok Bots do not load amillez-mode as their own working mode. They must know which skills to attach to launch prompts, and `amillez-mode` is always first.
- Model lanes stay in the [agent use policy](../policies/agent-use-policy.md#default-picks). When the skill and the policy disagree on lanes, the policy wins and the skill gets a fix PR.
- Change the skill through a PR in `amillez/akit`, not here.

## Related

- [Agent use policy](../policies/agent-use-policy.md)
- [Agent proof feedback loop](agent-proof-feedback-loop.md)
- [Agent dispatch lifecycle](agent-dispatch-lifecycle.md)
- [Steal from pstack](steal-from-pstack.md)
