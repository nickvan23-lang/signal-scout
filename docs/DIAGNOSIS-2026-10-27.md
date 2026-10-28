# Signal Scout diagnosis — October 27, 2026

## Findings

There are two confirmed signal-analysis defects, a broken portable verification assertion, and separate simulator-capture problems. Release records also conflict. The recent red simulator workflows alone do not demonstrate an app crash or failed Bluetooth test.

Audited application baseline: `main` at `7de6ed0c468cbe33216ccd6fa80b30b671218d41`. The newer Duo branch at `4879a902539a0e913981fbc77833ed0efacbed2a` changes six tooling/workflow files and has identical application source.

## 1. Tracking can remain in Calibrating indefinitely

`SignalTrendAnalyzer` originally compared two 2.4-second windows, each requiring at least three samples. A regular one-second advertiser can place only five samples across the full 4.8-second horizon, so it cannot satisfy both windows. At fast rates, retaining only 60 raw samples can discard the prior window: 50 samples per second leave approximately 1.18 seconds of history.

The original implementation was compiled with Swift and exercised with deterministic inputs. It failed slow-cadence and fast-cadence guidance checks despite continued valid RSSI readings. This is an application logic defect, independent of simulator launch/capture infrastructure.

The proposed fix retains at most ten analysis samples per second, preserving a useful time span within the 60-sample memory bound. The scanner still receives advertisements. Comparison windows adapt to slower observed cadence, retain the three-samples-per-window evidence floor, and include a small jitter allowance. Until enough evidence exists, guidance remains Calibrating with zero confidence.

Regression coverage includes strengthening, weakening, and steady signals at one-, two-, and four-second intervals; 50 Hz arrivals; fractional 1.0225-second timing; jitter; and large absolute timestamps. These inputs validate the algorithm, not real radio reception or distance accuracy.

## 2. Signal recovery can reuse stale strength and invent a trend

The original analyzer retained its median history and exponential smoothing state across long gaps. After a stable -50 dBm history and a long interruption, the first two actual -90 dBm samples could still be displayed as -50 dBm. Subsequent constant -90 dBm readings could generate Colder solely as the old smoothing baseline decayed.

The patch resets the analyzer after a valid-reading gap longer than five seconds, matching the app's existing lost-signal threshold. A backward time jump also resets it. Resuming scanning clears comparison history and guidance before building a new baseline. Existing device records remain available for the last-reading display.

Native unit tests cover recovery and timing cases; UI regression coverage asserts that pause/resume discards the old chart and returns to calibration. Those new iOS tests require a native run; the Linux core result does not exercise CoreBluetooth, SwiftUI, or XCTest UI automation.

## 3. The portable release check rejects valid site navigation

Running `python3 scripts/check_free_release.py` against untouched main reproduced six failed subtests in its relative-link assertion. It used `Path.is_file()` directly on links such as `./` and `review/build-8/`, which are directories served through `index.html`. The separate SEO/navigation checker passed.

The correction resolves directory URLs to their index pages, decodes URL paths, skips external authority URLs, and checks nested HTML pages. All 14 release-source tests now pass. This was a checker defect, not six broken website links.

The previous README claim that all 14 checks passed did not match the checked-in revision. The README now explains the discrepancy rather than presenting that claim as verified historical evidence.

## 4. Duo fold capture has its own failures

The [latest October 24 run](https://github.com/nickvan23-lang/signal-scout/actions/runs/40126675261/job/120969501718) installed the simulator app, then timed out after 60 seconds in the initial `duoctl state` call, before capturing fold poses.

Two independent blockers were verified:

- `hinge_angle()` checked its ten-second deadline inside a blocking iteration over stdout. A silent stream or partial line could prevent the deadline check from running. An unchanged-source subprocess reproduction remained blocked beyond eleven seconds and required an external watchdog. The CI log does not identify which internal subprocess hung; this defect is consistent with, not a complete attribution of, that log.
- The workflow downloaded a hardcoded artifact from run `40125857391`, retained for one day. The [artifact endpoint](https://api.github.com/repos/nickvan23-lang/signal-scout/actions/runs/40125857391/artifacts) now returns zero artifacts. An unchanged rerun therefore cannot reach capture.

The separate Duo repair bounds subprocess and telemetry reads, reaps the motion stream, records startup failures before diagnostics, and requires valid hinge-angle readback for each claimed pose. Its workflow builds the current checkout instead of depending on the expired binary.

Thirteen portable harness regressions passed, including real silent/partial-output child processes and mocked simulator outcomes. The repaired native Duo workflow has not been executed. It deliberately removes `UIRequiresFullScreen` for an experimental configuration and labels that change in its source/build evidence; it does not validate the exact submitted binary or unchanged production configuration.

## 5. Release status was obscured by stale documents

The current README records version **1.3 (8)** submitted on **October 9 at 10:47 AM Pacific**, with **Waiting for Review** and automatic release. Older `AppStore` files describe paid build 4; the earlier free-access draft PR and work-tracker snapshot describe build 5. They cannot establish the current review state.

The historical files are now explicitly labeled and linked to [RELEASE_STATUS.md](../AppStore/RELEASE_STATUS.md). Their dated evidence is preserved.

A fresh Apple public lookup for app ID `6810531496`, United States storefront, returned `resultCount: 0`. No current U.S. public catalog result was established. This does not reveal the private App Store Connect review state or establish worldwide availability. No new upload, approval, submission, or release was performed in this investigation.

The October 9 source record still discloses incomplete physical BLE validation and Apple's earlier latest-OS physical-device recording request. That remains a material verification gap until current review instructions and device evidence are checked.

## Verification performed

| Check | Original baseline | Patched result | Scope |
| --- | --- | --- | --- |
| Same 26-case Swift signal regression harness | 4 passed, 22 failed | 26 passed, 0 failed | Actual production `SignalAnalysis.swift`, compiled and executed with Swift 6.4.1 on Linux |
| Full production core harness | Earlier historical run had 22 checks | 46 checks passed | Signal logic, tracking states, map calculations, identity handling, bundled manufacturer registry; no platform shims |
| Portable release-source suite | 6 failed link subtests within 14 tests | 14 tests passed | Source/configuration/site assertions |
| SEO/navigation checker | Passed | Passed | Local metadata and link checks; not search indexing |
| Duo capture regressions | Blocking-read defect reproduced separately | 13 tests passed | Timeout/error/evidence handling; not native simulator validation |

The regression comparison used frozen inputs. SHA-256 of the final patched analyzer: `a49f6288a25ab1571bacb1860c1cf01346247e69709ca64422cfd1b4f06fb2c2`. Full local receipts are retained in this diagnostic branch's evidence folder.

Prior native evidence was independently checked in GitHub job logs: [October 24](https://github.com/nickvan23-lang/signal-scout/actions/runs/40115239286/job/120935063065) passed 17 unit tests and 3 UI tests plus an unsigned Release archive. [October 9](https://github.com/nickvan23-lang/signal-scout/actions/runs/37959810850/job/113919470999) passed 22 core checks and 20 native tests; another screenshot simulator's boot timeout made the overall run red. Those results apply to their original source/configuration, not the new fixes.

The main diagnostic branch enables native unit/UI verification for pull requests and runs the portable checks first. Optional release-media capture is excluded from pull-request validation so unrelated simulator screenshot failures do not obscure application test results.

## Remaining work

1. Run the new native unit/UI tests on the exact repair revision and review the code changes.
2. Run the repaired Duo workflow only when its matching Xcode/runtime runner is available; review the actual captures and retain the experimental-configuration scope.
3. Check this app's live App Store Connect state and reviewer messages.
4. Build a new signed candidate with an unused build number, then complete real-iPhone BLE and requested recording checks for that candidate before submission.

The proposed source repairs are reviewable changes. They have not replaced the app installed on an iPhone or the build submitted to Apple.
