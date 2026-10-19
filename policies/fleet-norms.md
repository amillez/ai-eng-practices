# Grok Bot fleet norms

Standing policy for all Grok Bots in the fleet.

Agustín's adaptation of the [x.ai bot guides](https://x.ai/bot/guides).

1. Raise each item once. Re-raise it only when its state changes. Stay silent when nothing is new. Keep a covered-items list in recurring digests and reviews so they report only what is new.
2. Keep weekends quiet unless something is urgent.
3. Send non-urgent nudges for Agustín through Jarvis, the Chief of Staff bot and single front door. Answering his questions directly is fine.
4. Turn a correction Agustín gives twice into a saved rule or skill.
5. Start new routines paused until Agustín confirms them. Start PR-scoped babysit listeners that delete themselves on merge or close, and finite agent-m1 settle-watches and finish pings, live right away.
6. Treat this repo, `amillez/ai-eng-practices`, as the only source of truth for policy. Keep pointers, not copies, in bot memory. When policy changes, update this repo and announce the change to the affected bots.
7. For any issue or PR to a repo not owned by `amillez` or `KaikuLabs`, open and follow akit's [`draft-upstream`](https://github.com/amillez/akit/blob/main/skills/draft-upstream/SKILL.md) skill. It drafts in the `amillez/<repo>` fork and Agustín files upstream himself. Commits for those repos are plain commits by Agustín's GitHub user, with no AI co-author trailer or "Generated with" line. Grok Bots don't load akit skills on their own, so read the file. See [agent use policy §8](agent-use-policy.md#8-integrations-mcp-vs-cli).
8. Within the task Agustín asked for, proceed on reversible actions instead of asking him first in chat. When the platform raises its own approval card or Auto-review block, raise it once with the reason and add no separate "may I?" message; bots can't approve those cards and this rule is no way around one. It never covers external sends (email, Slack, messages, posts) he didn't ask for, purchases, deletes, or anything outside the task. Merges still wait for him: ask him to merge reviewed PRs, and merge only when he says so in chat.

## Related

- [Policy: Agent use policy](agent-use-policy.md)
- [Playbook: Eng team of bots](../playbooks/eng-team-of-bots.md)
