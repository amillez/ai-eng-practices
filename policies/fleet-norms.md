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
8. Within the task Agustín asked for, proceed on reversible actions instead of asking him first in chat. When the platform raises its own approval card or Auto-review block, raise it once with the reason and add no separate "may I?" message; bots can't approve those cards and this rule is no way around one. It never covers external sends (email, Slack, messages, posts) he didn't ask for, purchases, deletes, or anything outside the task. Merges still wait for him except under rule 9. Ask him to merge other ready PRs, and merge them only when he says so in chat.
9. A bot may squash-merge a PR without asking Agustín only when all of these hold:
   - Agustín owns the repo, under his `amillez` user or an org he owns, such as `KaikuLabs`. Third-party open source doesn't count, and neither do the `amillez/<repo>` forks that rule 7 drafts in.
   - The change is docs or skills, a small pin bump that passes [agent use policy §11](agent-use-policy.md#11-dependency-versions), or a low-risk code change with a small blast radius. That means it stays in one area, reverts cleanly, and touches no auth, payments, user data, migrations, secrets, or release config. Check it with akit's [`blast-radius`](https://github.com/amillez/akit/blob/main/skills/blast-radius/SKILL.md) skill.
   - CI is green. In a repo without CI, the bot runs the repo's own check scripts on the exact PR head and posts the results as a PR comment or as a commit status on that head. Either one counts. The results list each command with its exit code, and a PR comment also names the tested head SHA. The checks cover every typecheck, lint, and test script the repo defines. If any of them is missing or skipped, the PR waits for Agustín. The commands for each repo are in [checks where a repo has no CI](../playbooks/agent-dispatch-lifecycle.md#checks-where-a-repo-has-no-ci).
   - When the Review row in [agent use policy §1](agent-use-policy.md#1-coding-host-routing) requires a cross-model review (code, script logic, policy changes), it passes with no blocking findings. Docs-only changes and §11 pin bumps need none.

   These always wait for Agustín: code changes that aren't low risk with a small blast radius, policy changes (any edit under this repo's `policies/`, this file included), and anything a reviewer flags. Pin the squash-merge to the head SHA that the checks and any review ran on with `gh pr merge --squash --match-head-commit <sha>`. Every Monday, Ivy's merge list includes the PRs that auto-merged.
10. Run scheduled Grok Bot routines that open PRs or start coding sessions on `agent-m1` between 00:00 and 06:00 Madrid time. Stagger them so only one heavy job or emulator runs at a time, per [agent use policy §12](agent-use-policy.md#12-agent-m1-resource-limits). Run non-coding scheduled Grok Bot routines on weekday mornings, spread across the week rather than all on Monday. These time windows apply only to scheduled Grok Bot routines. Work that Agustín or another bot asks for starts right away, at any hour. A bot never defers its own session for requested work to the night. That session still follows the §12 limits.
11. Start every coding session and every review through Orca, per [agent use policy §1](agent-use-policy.md#start-every-coding-session-through-orca).
12. Name every secret and env var so a reader can tell its scope and service from the name alone.
   - Give an app-scoped or org-scoped secret its owner's prefix. Use `FAVVY_` for Favvy only, such as `FAVVY_PLAY_SA_JSON`. Use `KAIKULABS_` for all of KaikuLabs, such as `KAIKULABS_ASC_*` and `KAIKULABS_EXPO_TOKEN`. Use `AMILLEZ_` for amillez scope. Leave a name unprefixed only when the secret is fleet-wide, or personal with no narrower owner. When in doubt, prefix it.
   - After the prefix, name the service and then what the secret is. Write `FAVVY_ASC_SUPPORT_KEY_ID`, not `ASC_SUPPORT_KEY_ID`.
   - Retired names may stay orphaned on the box, but no bot or script reads them, not even as a fallback such as `${FAVVY_X:-$X}`, `os.environ.get("X")`, or `process.env.X`. The retired names are `PLAY_SA_JSON`, `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_PRIVATE_KEY`, `EXPO_TOKEN`, `ASC_SUPPORT_P8`, `ASC_SUPPORT_KEY_ID`, and `ASC_SUPPORT_ISSUER_ID`. Never read a retired name.

## Related

- [Policy: Agent use policy](agent-use-policy.md)
- [Playbook: Eng team of bots](../playbooks/eng-team-of-bots.md)
