# Signal Scout diagnosis — October 27, 2026

## Findings

**Delivery update, October 28:** the app repairs are merged into `main` through [PR #3](https://github.com/nickvan23-lang/signal-scout/pull/3), and the initial Duo harness repair is merged into its original experimental branch through [PR #4](https://github.com/nickvan23-lang/signal-scout/pull/4). The app's merge tree exactly matches the successful native-test checkout. [Draft PR #5](https://github.com/nickvan23-lang/signal-scout/pull/5) combines the verified main app fixes with a supported UIKit readback candidate. Its 30 portable checks and native observer build passed in two native runs. The fresh simulator in [run 40713094528](https://github.com/nickvan23-lang/signal-scout/actions/runs/40713094528) reached boot readiness, then installation and cleanup timed out while host load was very high. No app launch or live fold capture was exercised. PR #5 remains a draft pending a healthy runner and live verification. A signed iPhone/App Store release remains a separate pending step; see [release status](../AppStore/RELEASE_STATUS.md).

There are two confirmed signal-analysis defects, a broken portable verification assertion, and separate simulator-capture problems. Release records also conflict. The recent red simulator workflows alone do not demonstrate an app crash or failed Bluetooth test.

Audited application baseline: `main` at `7de6ed0c468cbe33216ccd6fa80b30b671218d41`. At the original audit, Duo revision `4879a902539a0e913981fbc77833ed0efacbed2a` had the same application source as that baseline and differed in six tooling/workflow files.

## 1. Tracking can remain in Calibrating indefinitely

`SignalTrendAnalyzer` originally compared two 2.4-second windows, each requiring at least three samples. A regular one-second advertiser can place only five samples across the full 4.8-second horizon, so it cannot satisfy both windows. At fast rates, retaining only 60 raw samples can discard the prior window: 50 samples per second leave approximately 1.18 seconds of history.

The original implementation was compiled with Swift and exercised with deterministic inputs. It failed slow-cadence and fast-cadence guidance checks despite continued valid RSSI readings. This is an application logic defect, independent of simulator launch/capture infrastructure.

The fix retains at most ten analysis samples per second, preserving a useful time span within the 60-sample memory bound. The scanner still receives advertisements. Comparison windows adapt to slower observed cadence, retain the three-samples-per-window evidence floor, and include a small jitter allowance. Until enough evidence exists, guidance remains Calibrating with zero confidence.

Regression coverage includes strengthening, weakening, and steady signals at one-, two-, and four-second intervals; 50 Hz arrivals; fractional 1.0225-second timing; jitter; and large absolute timestamps. These inputs validate the algorithm, not real radio reception or distance accuracy.

## 2. Signal recovery can reuse stale strength and invent a trend

The original analyzer retained its median history and exponential smoothing state across long gaps. After a stable -50 dBm history and a long interruption, the first two actual -90 dBm samples could still be displayed as -50 dBm. Subsequent constant -90 dBm readings could generate Colder solely as the old smoothing baseline decayed.

The patch resets the analyzer after a valid-reading gap longer than five seconds, matching the app's existing lost-signal threshold. A backward time jump also resets it. Resuming scanning clears comparison history and guidance before building a new baseline. Existing device records remain available for the last-reading display.

Native unit tests cover recovery and timing cases; UI regression coverage asserts that pause/resume discards the old chart and returns to calibration. The [October 27 native CI run](https://github.com/nickvan23-lang/signal-scout/actions/runs/40635520267/job/122641465486) passed all 24 unit tests and four UI tests, with zero failures or skipped tests. This verifies the new cases in the iPhone simulator; neither the simulator nor the separate Linux core checks establish physical Bluetooth reception.

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

Thirteen portable harness regressions passed, including real silent/partial-output child processes and mocked simulator outcomes. After the repair was merged, [native run 40636901678](https://github.com/nickvan23-lang/signal-scout/actions/runs/40636901678) successfully built and installed its fresh candidate, then failed explicitly at the first cover-portrait pose because hinge-angle telemetry was unavailable. Its failure state records an active portrait cover display with `hingeAngle: null`; zero poses were verified. See the [original Duo receipt](evidence/2026-10-27/duo-ci-40636901678.json).

The [October 28 bounded diagnostic, run 40706423363](https://github.com/nickvan23-lang/signal-scout/actions/runs/40706423363), established a more specific cause for the old readback path: `xcrun devicectl device motion hinge-angle -d <simulator-udid>` exited **64**, reporting `Unknown option '-d'`. That confirms rejection of this invocation by the inspected Xcode 27.1 command parser. It does not establish that the operating system lacks all hinge telemetry, or that every possible readback provider fails.

The same diagnostic separately recorded a boot command returning zero, followed by a `bootstatus` operation that exceeded its actual **60-second deadline** and was terminated. It did not reach helper compilation, close/open/half actions, transition observations, an app build, or app tests. Six native process-regression checks passed before the diagnostic step failed. The [telemetry receipt](evidence/2026-10-28/duo-telemetry-40706423363.json) retains the command results and these limits.

**Supported readback candidate:** [draft PR #5](https://github.com/nickvan23-lang/signal-scout/pull/5), branch `codex/duo-supported-readback-20261028`, includes the verified main app fixes and replaces hinge readback with the supported UIKit `UIHingeInteraction` API. The observer is absent unless the `DUO_DIAGNOSTICS` compilation condition is set and a valid session UUID is supplied at launch. Each new request requires an actual callback from its current observer generation; cached angles cannot be relabeled as new observations. Nil/background updates invalidate availability, and failed snapshot writes stop the diagnostic session.

The host checks exact session/request identity, the live launched PID, increasing callback sequence, foreground scene state, and finite timestamps and angles. Each screenshot is bracketed by fresh observations made after distinct requests; the scene and display identities must remain the same across that interval. Requested target angles are never used as substitute measurements, and the one-degree tolerance and matching status remain required.

[Native run 40710723536](https://github.com/nickvan23-lang/signal-scout/actions/runs/40710723536), head `c3cba603a757fb5d017879d0748e6eb571f3413c`, tree `f6684f166c27c670d7d7cd38509246f5480dd49e`, passed all **30 portable checks** and **compiled the native UIKit observer successfully** with Xcode 27.1 and `DUO_DIAGNOSTICS`. It then failed when `bootstatus` exceeded its **180-second deadline**. Installation, app launch, callback delivery, and screenshots were not reached, leaving zero verified poses. Empty boot logs do not identify the underlying startup cause. The [supported-readback receipt](evidence/2026-10-28/duo-supported-readback-40710723536.json) records these results and source/build hashes.

The fresh-fixture attempt, [run 40713094528](https://github.com/nickvan23-lang/signal-scout/actions/runs/40713094528), completed at head `803bf1640e984351c47fb3c14fbba02b5f70ed44`, tree `5b43addcebed32efbbb7940d9171062a11c64d6d`. App and capture inputs were unchanged from the prior successful compile; the recorded workflow input changed. All **30 portable checks** and the **native build** passed again. The new run-owned simulator booted in **3.27 seconds** and reached readiness in **113.36 seconds**, within the 300-second bound. Installation then exceeded its **30-second deadline** (33.65 seconds elapsed, no output). App launch, live hinge callbacks, and screenshots were never reached: **zero poses and zero screenshots**.

Post-startup diagnostics reported load averages of **353.16 / 148.92 / 67.18**, and even a read-only simulator listing exceeded its ten-second deadline. Shutdown and deletion of the exact owned simulator each exceeded 30 seconds, and the cleanup step timed out at two minutes; **deletion is not confirmed**. Together these observations support host/CoreSimulator contention as an infrastructure blocker. They do not identify its underlying source or establish a defect in app installation. The [fresh-fixture receipt](evidence/2026-10-28/duo-fresh-fixture-40713094528.json) retains the ownership, command timings, artifact digest, and source/build binding. PR #5 remains a draft. No further native run was started on this environment.

The Duo workflow deliberately removes `UIRequiresFullScreen` for an experimental configuration and labels that change in its source/build evidence. The original PR #4 candidate lacked the main app fixes; the new PR #5 candidate includes them. Neither validates the submitted binary or physical Bluetooth reception. Rendered screenshot orientation and visual layout remain separate review items rather than inferred from unordered panel pixel dimensions.

## 5. Release status was obscured by stale documents

The current README records version **1.3 (8)** submitted on **October 9 at 10:47 AM Pacific**, with **Waiting for Review** and automatic release. Older `AppStore` files describe paid build 4; the earlier free-access draft PR and the Signal Scout entry in the work-tracker snapshot describe build 5. The tracker file was updated after October 9, but that entry retains older build-5 observations. Its later modification date does not make those observations current. These records cannot establish the present review state.

The historical files are now explicitly labeled and linked to [RELEASE_STATUS.md](../AppStore/RELEASE_STATUS.md). Their dated evidence is preserved.

A fresh Apple public lookup for app ID `6810531496`, United States storefront, returned `resultCount: 0`. No current U.S. public catalog result was established. This does not reveal the private App Store Connect review state or establish worldwide availability. No new upload, approval, submission, or release was performed in this investigation.

The October 9 source record still discloses incomplete physical BLE validation and Apple's earlier latest-OS physical-device recording request. That remains a material verification gap until current review instructions and device evidence are checked.

## Verification performed

| Check | Original baseline | Patched result | Scope |
| --- | --- | --- | --- |
| Same 26-case Swift signal regression harness | 4 passed, 22 failed | 26 passed, 0 failed | Actual production `SignalAnalysis.swift`, compiled and executed with Swift 6.4.1 on Linux |
| Full production core harness | Earlier historical run had 22 checks | 46 checks passed on Linux and in native CI | Signal logic, tracking states, map calculations, identity handling, bundled manufacturer registry; no platform shims |
| Native iPhone unit/UI suite | Earlier source had 17 unit and 3 UI tests | 24 unit and 4 UI tests passed; 0 failures, 0 skipped | Xcode 26.6, iPhone 17 Pro Max simulator, iOS 26.5; no physical radio verification |
| Portable release-source suite | 6 failed link subtests within 14 tests | 14 tests passed | Source/configuration/site assertions |
| SEO/navigation checker | Passed | Passed | Local metadata and link checks; not search indexing |
| Initial Duo capture regressions | Blocking-read defect reproduced separately | 13 tests passed | Timeout/error/evidence handling; native capture later stopped with no verified poses |
| Supported UIKit readback protocol | Legacy command rejection and boot timeout recorded | 30 portable checks and native observer build passed twice; fresh-fixture run 40713094528 reached readiness in 113.36 seconds, then installation timed out | Zero live callbacks, poses, or screenshots; cleanup unconfirmed; healthy runner required; PR #5 remains draft |

The regression comparison used frozen inputs. SHA-256 of the final patched analyzer: `a49f6288a25ab1571bacb1860c1cf01346247e69709ca64422cfd1b4f06fb2c2`. Full local receipts are retained in the repository's evidence folder.

The successful native run completed on **October 27 at approximately 10:09 PM Pacific** (October 28 at 05:09 UTC). It checked PR #3 head `573699002f3c538ccf042f2628c0368dfd5ff75d` merged with baseline `7de6ed0c468cbe33216ccd6fa80b30b671218d41`; the actual checkout was `d886adee14f77be516b6cb805b5c2de04aed6e58`. The [public CI receipt](evidence/2026-10-27/native-ci-40635520267.json) records the exact source, environment, results, and evidence digest. All 28 XCTest cases ran and passed. Optional preview recording and additional screenshot-size workflow steps were intentionally skipped for the pull request; no XCTest cases were skipped.

Prior native evidence was independently checked in GitHub job logs: [October 24](https://github.com/nickvan23-lang/signal-scout/actions/runs/40115239286/job/120935063065) passed 17 unit tests and 3 UI tests plus an unsigned Release archive. [October 9](https://github.com/nickvan23-lang/signal-scout/actions/runs/37959810850/job/113919470999) passed 22 core checks and 20 native tests; another screenshot simulator's boot timeout made the overall run red. Those results apply to their original source/configuration, not the new fixes.

The workflow on `main` enables native unit/UI verification for pull requests and runs the portable checks first. Optional release-media capture is excluded from pull-request validation so unrelated simulator screenshot failures do not obscure application test results.

## Remaining work

1. Check this app's live App Store Connect state and reviewer messages.
2. Once signing and authenticated Apple access are available, build a new signed candidate with an unused build number and install it through the authorized signing or internal TestFlight route. A TestFlight upload may precede device validation; complete real-iPhone BLE and requested recording checks before App Review submission. Record upload, testing, submission, and approval separately. The repository's current CI disables signing and does not export or upload a distribution candidate; no upload is established by this session. See the [release capability assessment](../AppStore/RELEASE_STATUS.md#signed-release-capability).
3. Restore a healthy Xcode 27.1 runner before retrying PR #5. If its run-owned simulator still exists, finish cleanup only for the exact UUID recorded in run 40713094528's ownership receipt; do not erase unrelated devices. Then obtain fresh live callbacks and verified fold poses before treating supported UIKit readback as complete. Review rendered screenshots separately and retain the experimental-configuration scope. The successful native build and portable protocol tests do not establish live callback delivery or successful capture.

The source repairs have passed portable and native simulator verification. They have not replaced the app installed on an iPhone or the build submitted to Apple.
