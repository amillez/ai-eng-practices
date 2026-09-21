# SimSlim on agent-m1 (iOS simulators)

Run more concurrent iOS simulators on the 16 GB `agent-m1` host by disabling background daemons the prove loop usually does not need.

Tool: [SimSlim](https://github.com/mobai-app/simslim) (`brew install mobai-app/tap/simslim`).

Related: [Agent proof feedback loop](agent-proof-feedback-loop.md) · [Agent dispatch lifecycle](agent-dispatch-lifecycle.md).

## When to use

- Default for **named agent iOS sims** on `agent-m1` before Argent / Expo prove.
- Keep the playbook concurrent cap at **2** until a slim-sim Argent smoke stays green; then consider 3.

## Install (once per host)

```bash
brew tap mobai-app/tap
brew install mobai-app/tap/simslim
simslim list
```

Needs Xcode with an iOS Simulator runtime (not CLI tools alone).

## Named agent sims (trial 2026-09-21)

| Name | UDID | Runtime |
| --- | --- | --- |
| `agent-iPhone-17-iOS26` | `0DFFA3DE-FC1E-4986-A657-2544683CB3BC` | iOS 26.1 |
| `agent-iPhone-16-Pro-iOS26` | `84ED1A2A-B800-4E06-ADBE-57E78A0F4DB8` | iOS 26.1 |
| `agent-iPhone-16-iOS18` | `000A9C25-4804-4B27-B1AE-8D7F695B3F91` | iOS 18.6 |

## Default: slim on

Persistent slim (survives reboot on supported runtimes):

```bash
simslim on <udid>
simslim verify <udid>
simslim measure <udid>
```

Idle `phys_footprint` from the 2026-09-21 trial (stock → slim):

| Simulator | Stock | Slim |
| --- | --- | --- |
| agent-iPhone-17-iOS26 | 2.78 GB | 1.31 GB |
| agent-iPhone-16-Pro-iOS26 | 2.81 GB | 1.35 GB |
| agent-iPhone-16-iOS18 | 2.51 GB | 895 MB |

Two slim iOS 26 sims booted together ≈ **2.5 GB** total (~1.21 + 1.23 GB) vs ~5.6 GB stock.

## Re-enable categories the app needs (`--except`)

Default slim turns off many background services. **If the app under prove needs a capability, leave that category enabled** with `--except` (comma-separated). Examples:

| Need | Category id (`simslim profiles`) |
| --- | --- |
| Photo picker / Photos library | `photos` |
| Push / StoreKit / App Store | `store` |
| HealthKit / HomeKit | `health` |
| Contacts / Calendar pickers | `pim` |
| Universal links / Safari sync | `web` |
| Siri / speech | `siri` |
| iCloud / Keychain workflows | `icloud` |

```bash
# Photos picker required for this prove
simslim on <udid> --except photos

# Photos + push / StoreKit
simslim on <udid> --except photos,store

simslim verify <udid> --except photos,store
```

List every category and what disabling breaks:

```bash
simslim profiles
simslim profiles photos   # daemons in one category
```

Prefer the smallest `--except` set that matches the task. Do not leave everything stock “just in case.”

To go fully stock again:

```bash
simslim off <udid>
```

## Prove-loop recipe

1. Pick a named agent sim (or create one).
2. `simslim on <udid>` — add `--except …` when the task needs Photos, push, etc.
3. `simslim verify <udid>` (pass the same `--except` / `--keep` as `on`).
4. Run Argent / Expo prove as usual.
5. Tear down sims when proof is done ([teardown](agent-proof-feedback-loop.md#teardown-after-proof)). Slim overrides can stay; next boot remains slim.

## Argent smoke (2026-09-21)

Mark: **PASS** on slim `agent-iPhone-17-iOS26` (`0DFFA3DE-…`).

- `simslim verify` matched 170/170 before prove and with the app running.
- App: rn-bedrock `examples/grok-bot` via `expo run:ios` on that UDID.
- Argent: list / screenshot / describe + gesture into Settings (Home AX + Settings sheet).
- `--except` not needed for that flow (no Photos / push / StoreKit).
- Teardown: Argent device servers stopped, app terminated, sim shut down.

Keep concurrent cap at **2** until a dual-slim idle + prove memory note exists; do not raise from a single-sim smoke alone.

## Concurrent cap

- **Current:** max **2** concurrent iOS sims (unchanged until slim Argent smoke is green).
- Dual slim iOS 26 fits comfortably on 16 GB; raising toward 3 is a follow-up after prove reliability, not after memory alone.

## Do not

- Raise the concurrent cap on memory numbers alone.
- Blind-slim when the task needs Photos, push, StoreKit, HealthKit, etc. — use `--except`.
- Leave sims booted after proof.
