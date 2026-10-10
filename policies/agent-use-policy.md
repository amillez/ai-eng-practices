# Agent use policy

Standing policy for **all agents** pointed at this repo.

Use imperative language. Follow this unless the **current chat** explicitly overrides for that one-off. Chat overrides win for one-off asks. Do not treat a one-off override as a new default.

Primary sources:

- [Cursor workshop — Model Selection & Token Efficiency](../sources/cursor-model-selection-token-efficiency.md)
- [Research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
- [Friday digest 2026-09-18](../sources/friday-digest-2026-09-18.md)

Heuristics and savings numbers are **as of the cited source**, not eternal.

---

## 1. Coding host routing

For heavy coding / engineering agent work:

- **Only coding host**: `agent-m1` (dedicated Mac) running **Claude Code + Codex only**. No Cursor installed.
- **Grok Bot** is the chat and control plane (intake, dispatch, babysit, proof orchestration). It does not write code.
- **Claude vs Codex** on `agent-m1` is decided by the model lanes below plus the [Claude Code usage > 70%](#claude-code-usage--70) rule: Claude Code (Opus 5.5 / Fable 5.1) by default; Codex for GPT 6 Luna work and for GPT 6.1 Sol when Claude Code usage is above 70%.

Do **not** code through Cursor: no Cursor cloud agents, Cursor My Machines workers (`register-worker-dir`), Composer, or Grok 4.6 fallbacks.

**Model role labels → Claude Code / Codex (as of 2026-10-04):**

Policy keeps the role names (Luna / Sol / Opus / Fable) as **labels** and pins each to a verified CLI model id on `agent-m1` (Claude Code 2.1.289, Codex CLI 0.160.0). If a lane cannot run on either harness, use the nearest equivalent or skip that lane.

| Policy label | Intent | Run on | CLI pick (verified 2026-10-04) |
| --- | --- | --- | --- |
| **Luna** — GPT 6 Luna (Max) | Very direct / super defined; mechanical | **Codex** | `codex exec -m gpt-6-luna -c model_reasoning_effort=max` |
| **Opus** — Opus 5.5 (High) | General code / some reasoning **and** UI work (default) | **Claude Code** | `claude --model claude-opus-5-5 --effort high` |
| **Sol** — GPT 6.1 Sol | Fallback for general code (**xHigh**) and UI (**High**) when [Claude Code usage > 70%](#claude-code-usage--70) | **Codex** | General: `codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh` · UI: `… model_reasoning_effort=high` |
| **Opus 5.5 xhigh** | Large-work **Orca coordinator** default | **Claude Code** driving Orca CLI | `claude --model claude-opus-5-5 --effort xhigh`; coordinator only plans/dispatches/waits (does not integrate/validate) |
| **Fable** — Fable 5.1 (Medium → High/xhigh) | Large reasoning / gnarly escalate (non-orch) | **Claude Code** | Fable 5.1 at **Medium**, escalate to **High** then **xhigh** one step at a time (Opus 5.5 at high effort if Fable unavailable). Replan/split if still thrashing. **Not** the Orca coordinator default (**Opus 5.5 xhigh**) |

Bot orchestrators (Grok Bots) pick **Claude vs Codex** from the lanes above: Claude Code (Opus 5.5) by default for general code and UI; Codex (GPT 6.1 Sol) when Claude Code usage is above 70%; Codex (GPT 6 Luna) for super-defined work.

**Proof before done** (see [agent proof feedback loop](../playbooks/agent-proof-feedback-loop.md)):

- **Thorough launch prompt.** Every Claude Code / Codex launch states goal, scope, skills to invoke by name, and the proof expected. See [thorough launch prompt](../playbooks/agent-proof-feedback-loop.md#thorough-launch-prompt).
- **amillez-mode is required for coding agents.** Every invoked coding agent, a single agent or an Orca worker, loads and follows the `amillez-mode` skill ([`amillez/akit`](https://github.com/amillez/akit/tree/main/skills/amillez-mode)). The launch prompt or worker brief names it explicitly. A prompt that does not name amillez-mode is not ready to launch. Grok Bots do not load amillez-mode themselves; knowing which skills to attach to prompts is one of their most important jobs, and `amillez-mode` is always first. This policy stays the source of truth for model lanes; the skill mirrors them.
- **Require proof.** Not done at green CI or changed files — done when the agent has produced and inspected task-relevant proof.
- **Flexible evidence.** Screenshots or videos for UI; logs, test output, exit codes, or traces for non-visual work. No screenshots for show.
- **Proof media on `media` branch.** Never commit screenshots/videos to the PR branch. Link them in the PR body via GitHub blob URLs, not raw URLs. See [proof media hosting](../playbooks/agent-proof-feedback-loop.md#proof-media-hosting).
- **Prove on the real surface.** Launch the app, run a read-only doctor check, drive the real user path, and capture evidence, following the project's `verify-<app>` skill when the repo has one. See [prove and inspect](../playbooks/agent-proof-feedback-loop.md#prove-and-inspect).
- **Inspect proof against the success criteria.** The agent that drove the app reads every asset and reports pass or fail with specifics. A second judge is not required when the implementer already proved the change on device. A separate verification session is optional. If you start one, it only inspects proof and never implements, and you pick its model per task from the [agent chooser](#agent-chooser-examples).
- **Argent on `agent-m1` for RN/UI.** Use Argent CLI + MCP with provisioned simulators/AVDs; skills alone are not enough.
- **Mismatch → iterate or report the blocker with evidence.** Never claim "verified" without reading the proof.
- **Tear down after proof.** Shut down sims/emulators, dev servers, and matching Expo CLI processes (`expo/bin/cli`, `expo start`, `expo run`), then verify no used Metro port is listening. For Android jobs, also stop the Gradle and Kotlin daemons per [§12](#12-agent-m1-resource-limits). See [teardown after proof](../playbooks/agent-proof-feedback-loop.md#teardown-after-proof).

**Amillez plugin before coding** (see [`amillez/akit`](https://github.com/amillez/akit) `scripts/ensure-install.sh`):

- **Host install.** Before coding on `agent-m1`, run `./scripts/ensure-install.sh` from the akit checkout (or `AMILLEZ_SKILLS_ROOT`). It installs the **core+mobile** groups at **`~/.claude`** and **`~/.agents`** (skills, user rules `amillez-models.md`, stamp) when they are missing and continues when they are present. Codex reads `~/.agents`; nothing goes under `~/.codex`. Refresh with `./scripts/update-install.sh` when policy or skills change or a human asks.
- **Project trees.** The plugin never installs into a project or worktree. A project may commit selected stack skills (e.g. `uniwind`) as a teammate mirror, not the whole mobile set. Project `verify-*` skills live in the repo.
- **Dispatch prompts.** Every Grok Bot dispatch prompt to Claude Code / Codex starts with the host ensure step, or the bot runs it before launch.

**Dispatch and worktrees** (see [agent dispatch lifecycle](../playbooks/agent-dispatch-lifecycle.md)):

- **Worktree per agent.** Dispatch each workstream into its own `git worktree` on branch `agent/<bot>/<slug>`, from an up-to-date base. Agents never work in the `main` checkout.
- **One agent per tree.** Parallel work uses separate worktrees with disjoint paths.
- **Parent owns `agent-m1` Shell.** Grok Bot **executor** Task subagents cannot pass `machineId` to Shell (box only). Parent must run agent-m1 Shell/Read with `machineId` (`cbfdfd05-8447-4018-ad6b-26eb8a0e83b1`) for Claude launch / worktree create on the Mac. Executors stay fine for `gh`/API/box work. Canonical `claude --bg` recipe + `claude respawn` unblock: [dispatch lifecycle](../playbooks/agent-dispatch-lifecycle.md#canonical-claude-code-background-launch-on-agent-m1).
- **Size gate before launch.** **Small** (single surface or package, one PR, clear blast radius, one focused session) → dispatch the matching agent from this chooser directly. No Orca Run, no orchestrator. **Large** (multi-surface, multi-package, parallelizable, multi-PR, multi-session, or unclear blast radius) → an **Orca** Run on `agent-m1` with an **Opus 5.5 xHigh** coordinator (`claude --model claude-opus-5-5 --effort xhigh`). The coordinator only plans, dispatches, and waits. Workers implement, integrate, and prove, each with model and effort per slice from this chooser. Grok Bot ensures the amillez plugin and babysits the PRs. Do not collapse large work into one mega agent. **Needs parallel workers → Orca; one agent can own the whole loop but the work is long, cross-cutting, or reviewed after stepping away → the akit [`figure-it-out`](https://github.com/amillez/akit/blob/main/skills/figure-it-out/SKILL.md) skill.** Prerequisites and the Orca loop are in [big-work orchestration](../playbooks/big-work-orchestration.md).
- **Babysit until merged.** Bots own the workstream until `merged` or `discarded`; agent idle is not done. Bots babysit an open PR with PR-scoped GitHub event listeners, and every babysit routine deletes itself on the `pr-merged` or `pr-closed` wake. A babysitter starts one coding session per submitted review with every unresolved thread batched in, never one per inline comment. Launch prompts carry no Grok Bot webhook keys, and coding agents send no finish pings to a webhook. See [babysit until merged](../playbooks/agent-dispatch-lifecycle.md#babysit-until-merged).
- **Teardown after merge or abandon.** Remove the worktree and delete the local branch; runtime teardown and Metro-port verification still apply. No dirty or orphan trees left on disk.

**Permissions bypass on `agent-m1` only**: Run Claude Code and Codex with permission prompts disabled for unattended agent work. Use the CLI's skip-permissions flag (Claude Code) or equivalent sandbox bypass option (Codex) so agents are not blocked waiting for interactive approval. This applies only to the trusted `agent-m1` host.

**Claude Code / Codex launches** (eng-bot Mark's launch discipline, adapted):

- **Never omit model or effort.** Harness defaults are not the Agent chooser.
- **Fast:** leave off unless the human explicitly asks.
- **Private-ref docs / knowledge PRs:** if the agent needs private reference repos, set up clone/ref access up front on `agent-m1`. Do not expect the agent to invent trees without access.

---

## 2. Default model posture

- Do not lock the session (or the org) to a single provider or a single frontier model.
- Escalate model, effort, or context **deliberately**, with a reason you can state in one sentence.
- Do not start on Fable-role / Opus xhigh, max effort, or max context "just in case."

### Default picks

| Situation | Model (effort) | Harness | Notes |
| --- | --- | --- | --- |
| Very direct / super defined | **GPT 6 Luna** (**Max**) | Codex (`gpt-6-luna`) | Mechanical, files + success criteria clear |
| General code / some reasoning | **Opus 5.5** (**High**) | Claude Code (`claude-opus-5-5`) | Default for most implementation + light reasoning. **Claude Code usage > 70% → GPT 6.1 Sol (xHigh)** on Codex (`gpt-6.1-sol`) |
| UI work | **Opus 5.5** (**High**) | Claude Code (`claude-opus-5-5`) | Product UI / visual taste. **Claude Code usage > 70% → GPT 6.1 Sol (High)** on Codex (`gpt-6.1-sol`) |
| Large-work orchestration (needs orch) | **Opus 5.5** (**xHigh**) coordinator inside **Orca** | Claude Code + Orca CLI | Size gate → Orca Run. Workers: `worker-start --agent claude|codex` + chooser model/effort. Coordinator does not integrate/validate. |
| Large reasoning (non-orch) | **Fable 5.1** (**Medium** → High/xhigh) | Claude Code | Hard single-agent reasoning. Escalate effort one step at a time. |

#### Claude Code usage > 70%

Before launching a Claude Code lane (general code or UI), check plan usage on `agent-m1`: run `/usage` (or `/status`) in a Claude Code session — it shows plan usage for the current window. If the current window is **above 70%**, route that task to Codex **GPT 6.1 Sol** instead (**xHigh** for general code, **High** for UI). At or below 70%, stay on **Opus 5.5 High**. Orca coordinator (Opus 5.5 xHigh) and Fable lanes are unaffected; if usage is exhausted, say so and pick the nearest Codex lane rather than stalling.

### Agent chooser examples

Use this when you need a pick, not a philosophy. Leave Fast off by default. Escalate **one knob at a time**. De-escalate when the hard part is done.

| Situation | Model | Effort | Harness | Notes |
| --- | --- | --- | --- | --- |
| Straightforward / super defined | **GPT 6 Luna** | **Max** | Codex | Files and success criteria are already clear. |
| General reasoning + implementation | **Opus 5.5** (usage > 70% → **GPT 6.1 Sol**) | **High** (Sol: **xHigh**) | Claude Code (Sol: Codex) | Default for most implementation + light reasoning. |
| UI work | **Opus 5.5** (usage > 70% → **GPT 6.1 Sol**) | **High** (Sol: **High**) | Claude Code (Sol: Codex) | Product UI / visual taste. |
| Large-work orchestration (needs orch) | **Opus 5.5** (Orca coordinator) | **xHigh** | Claude Code + Orca | Prefer **Opus 5.5 xhigh** label. Workers via Orca `--agent claude|codex` + chooser — not all Opus xhigh. Coordinator does not integrate/validate. |
| Large reasoning / gnarly escalate (non-orch) | **Fable 5.1** | **Medium** (→ High → xhigh) | Claude Code | Escalate **effort** for hard single-agent work — not the Orca coordinator default. |
| Writing / agreeing on a plan | **Opus 5.5** | **High** (→ **xhigh** if architecture tradeoffs matter) | Claude Code | Use Opus when a human will read the plan. Do not implement in the same turn until the plan is agreed. |
| Mechanical chore (format, rename in known files, boilerplate with tests already green) | **GPT 6 Luna** | **Max** | Codex | Few edge cases, little verification needed. |
| Reflect on a finished session (explicit only) | Reviewers: **Opus 5.5** (general-code lane, usage > 70% → **GPT 6.1 Sol**) ×2 + **GPT 6.1 Sol**; synthesizer **Opus 5.5** | Reviewers **High** (Sol: **xHigh**); synthesizer **xHigh** | Claude Code + Codex | The akit [`reflect`](https://github.com/amillez/akit/blob/main/skills/reflect/SKILL.md) skill. The synthesizer is the one non-Orca Opus 5.5 xHigh use. Output is one PR for review or a garden hand-off. |

Concrete picks:

1. Rename a prop in `UserCard.tsx` and fix call sites in that folder → **GPT 6 Luna** (Codex), **Max effort**.
2. Auth broken for `@edu` emails; 12-line stack + `@` the auth folder → **Opus 5.5** (Claude Code), **High** (Claude Code usage > 70% → **GPT 6.1 Sol** xHigh on Codex). If two wrong fixes: new chat + plan, then implement again.
3. New to the monorepo — where should a billing webhook live / what breaks → read-only recon on **Opus 5.5** (Claude Code), **High** (> 70% usage → GPT 6.1 Sol xHigh). Then a short plan before the build.
4. Draft a migration plan for splitting payments into a new service (a human will review / push back) → **Opus 5.5** (Claude Code), **High** (→ **xhigh** if architecture tradeoffs). Implement later against the agreed plan.
5. Huge flaky race across web + RN + API; intermittent; two loops already burned → **Fable 5.1** (Claude Code), **Medium** (→ **High** / **xhigh** if needed), debug/repro-first. After the root cause is pinned, drop to GPT 6 Luna Max (Codex) or Opus 5.5 High for the surgical fix.

---

## 3. When to escalate

Escalate **one knob at a time**. Say why.

**Escalate the model** when:

- The task is wide, poorly bounded, or needs general reasoning across systems.
- The current model is spinning: wrong guesses, missed files, or a plan that does not survive contact with the repo.
- The human asked for a plan they will actually read, or for a hard architectural call.

**Escalate effort** when:

- The task is correctly scoped and the model is the right class, but it needs more tool loops to finish.
- Do not raise effort to compensate for a vague prompt. Clarify first.

**Lower effort** when (cost lever — as of Sep 2026 signals from Thariq / jxnlco):

- The task is mechanical, well-specified, and needs **less verification** or fewer edge cases (rename, format, straightforward refactor with tests).
- The agent is over-verifying routine work — extra file reads, redundant tool loops, "speedrun cheating" at low effort is often what you want.
- Do not raise effort to paper over ambiguity. Fix the prompt or plan first.

**Escalate context** when:

- The work is an extremely complex refactor with ongoing decisions in one thread.
- You still `@`-mention the files and folders that matter. A bigger window is not a substitute for anchors.

**Do not escalate** when:

- The ask is a small, local change.
- You have not scoped the files, success criteria, or repro.
- You only want faster output (that is Fast, not intelligence).

De-escalate as soon as the hard part is done. After a strong-model plan, implement with a lighter model (GPT 6 Luna at Max for mechanical work, Opus 5.5 High — or GPT 6.1 Sol xHigh when Claude Code usage > 70% — for general implementation) unless the remaining work still needs complex reasoning.

---

## 4. Context hygiene

- **New chat per task.** Do not keep an eternal thread across unrelated jobs.
- `@`-mention the files, folders, logs, and past chats that matter. Do not dump a whole repo or a 30k-line file into the prompt.
- Paste only the relevant error lines, not the giant log.
- One task per turn. State success criteria ("done when…").
- If the thread has been compacted repeatedly or the agent is acting on blurry memory, **start a fresh chat**. Optionally `@` the old chat as a pointer, or carry a short written summary of decisions — not the whole transcript.
- Always-on rules ride every turn — keep them **short**; put long procedure in **skills** (lazy-loaded). Prefer Claude Code / Codex project skills over always-on rules.
- Do not enable MCPs you are not using. Audit unused ones.

---

## 5. Plan before build (non-trivial work)

For anything that is not a small, direct, already-scoped change:

1. **Recon** read-only when the area is unfamiliar.
2. **Plan** with a strong general-reasoning model. Get the shot clear: files, approach, risks, success criteria.
3. **Build** with an appropriate model against that plan.
4. Split a feature into subtasks. Do not ask one turn to "do the whole epic."

If the human's ask is vague ("fix auth"), **stop and clarify** or enter Plan mode. Do not explore the repo by guessing.

---

## 6. Cost visibility

You are billed for **tokens in and out of the model**, not for most harness/tool actions (search, grep, and similar were called out as free in the workshop). Output tokens cost more than input. Cache reads are cheaper than fresh input.

Do **not** freestyle this combo without a stated need:

- frontier / most expensive model
- plus max effort
- plus a fat always-on prompt
- plus an eternal chat

If spend looks wrong, inspect prompting and model class first. Workshop examples: ~10–12× from a vague vs specific prompt on the same model; ~175× when that stacks with the wrong expensive model. Each lever is modest (~12–15%); they compound.

---

## 7. Rules, skills, and MCP hygiene

- Keep always-apply rules **short**. They are prefix and are re-fed every turn.
- Prefer **skills** for playbooks, checklists, and long how-tos. The body loads when relevant.
- Do not change always-on rules mid-session unless you mean to. That busts provider cache. The blip is small — still switch model or provider when the task needs it.
- Disable unused MCPs. Extra tool surface is extra prefix and extra chances to wander.
- Do not paste huge files "for context." Point at them.

---

## 8. Integrations: MCP vs CLI

When both a dedicated MCP / connector and an ad-hoc CLI/`curl` path exist for the **same** service job, **prefer MCP**.

**Prefer MCP** when a connector exists (Notion, GitHub, Slack, X, etc.), when auth / pagination / structured results matter, or when bots should stay on the sanctioned tool surface (`GetDynamicTools` → `CallDynamicTool`) instead of scraping or inventing HTTP.

**Only exception:** a paid MCP with no credits left (e.g. X once credits run out) falls back to the web for that job; return to the MCP when credits are back.

**Prefer CLI** when no MCP exists; for CLI-native host tooling (`git`, `gh` for forge ops already done that way, Orca CLI, Argent CLI on `agent-m1`, package managers); or for one-off scripts / pipes / batch shell MCP does not cover well.

**Anti-patterns:** signed-in browser or invented HTTP when an MCP exists; dual-pathing MCP + CLI for the same mutation without a reason; enabling unused MCPs (see §7).

Decision checklist: [MCP vs CLI](../playbooks/mcp-vs-cli.md). Source: [Friday digest 2026-09-18](../sources/friday-digest-2026-09-18.md).

---

## 9. Production vs throwaway AI code

[Boris Cherny's frame](https://x.com/bcherny/status/2098217571153838124) (Sep 2026): **both modes are valid** — pick explicitly before the agent starts. Throwaway work (spikes, mockups, one-off probes) can be a black box with low blast radius. Anything merged to `main` or touched again in six months is **production** and needs a **higher bar than human-written code**: reviewable, owned, tested, CI + automated review where you have it.

If production agent output misses the bar, escalate model or effort, invest in skills/rules, or have the agent pay down debt — do not merge slop because it "mostly works."

---

## 10. Research hygiene

When researching **Anthropic / Claude tooling**, prefer primary builder accounts (e.g. [@ClaudeDevs](https://x.com/ClaudeDevs), shipping notes, official docs) over marketing accounts. Marketing posts lag product reality.

---

## 11. Dependency versions

This rule covers project dependencies in every repo: npm packages, Expo and React Native SDKs, CocoaPods, Gradle, and any other package a project declares.

- Install, bump to, or migrate to a version only when it is **at least 1 month old** (from its publish date) and has **no significant reported issues**. Significant issues are open regressions or crash reports in the issue tracker, or release notes or a follow-up patch that warn against the version.
- A newer version waits until it is a month old. Pick the newest version that passes both checks. Do not take `@latest` or `@next` blindly, and that includes skill steps such as `expo-upgrade`'s `npx expo install expo@latest`.
- Before the change, check the publish date (`npm view <pkg> time --json`, the GitHub release, or the CocoaPods or Maven publish date) and the issue tracker. State the version, its release date, and the issue check in the PR description.
- Where the package manager supports it, enforce the age check in config, for example pnpm `minimumReleaseAge: 43200` (30 days in minutes) in `pnpm-workspace.yaml`. See [hard constraints](../playbooks/hard-constraints.md).
- Host tooling on `agent-m1` (Claude Code, Codex, `gh`, Argent) is out of scope and keeps its own update rules.

---

## 12. agent-m1 resource limits

`agent-m1` has 16 GB of RAM and a 245 GB disk, and on 2026-10-10 three Android emulators plus Gradle and Kotlin daemons filled memory and disk, froze the host, and killed a Codex job with `ENOSPC`.

- **One Android emulator at a time.** At most one Android emulator runs on `agent-m1` at a time, across the whole fleet. Before you boot one, check what is running. Use `simfleet status` or `simfleet emu list` when simfleet is up, otherwise `adb devices` and `pgrep -fl qemu-system`. If an emulator is already running and it isn't yours, wait for it or reuse it through a simfleet claim. Never boot a second one. simfleet has no emulator-count setting today, so this check is the cap. If simfleet gains that setting, set the cap in its config.
- **Android teardown.** When an Android job finishes, run `./gradlew --stop` in the project's `android/` directory to stop the Gradle and Kotlin daemons. Then shut down every simulator, emulator, and Metro or Expo server the job started, per the teardown rules in [§1](#1-coding-host-routing). Check with `pgrep -fl 'GradleDaemon|KotlinCompileDaemon'` and kill any daemon from this job that is still listed.
- **Disk floor.** Don't start a heavy build or an emulator when `agent-m1` has under 20 GB free. Heavy builds are a native iOS or Android build, `expo prebuild`, `pod install`, a Gradle build, and a full test matrix. Check free space with `df -h ~` and read the Avail column. Under 20 GB, ping Ben (the infra bot) with the `df -h ~` output and wait.

---

## 13. Overrides

This policy applies to **all agents**. It is not scoped to a team, product, or bot flavor.

- A **chat override** wins for that ask only ("use Fable", "stay in this thread", "skip the plan").
- Do not promote a chat override into standing policy. That takes a PR to this repo.
- If a playbook and this policy conflict, follow this policy for defaults, the playbook for the how-to, and the chat for the one-off.

---

## Related

- [Policy: Grok Bot fleet norms](fleet-norms.md)
- [Playbook: Model selection & token efficiency](../playbooks/model-selection-and-token-efficiency.md)
- [Playbook: MCP vs CLI](../playbooks/mcp-vs-cli.md)
- [Playbook: Eng team of bots](../playbooks/eng-team-of-bots.md)
- [Playbook: Agent dispatch lifecycle](../playbooks/agent-dispatch-lifecycle.md)
- [Playbook: Big-work orchestration](../playbooks/big-work-orchestration.md)
- [Source: workshop](../sources/cursor-model-selection-token-efficiency.md)
- [Source: research digest 2026-09-12](../sources/research-digest-2026-09-12.md)
- [Source: Friday digest 2026-09-18](../sources/friday-digest-2026-09-18.md)
