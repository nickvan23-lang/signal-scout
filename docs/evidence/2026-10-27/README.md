# Diagnostic evidence

The original receipts record software verification performed October 27, 2026 Pacific (October 28 UTC); linked follow-up evidence is dated October 28 Pacific. The portable Swift checks establish algorithm behavior; the separate native CI receipt establishes the listed iPhone simulator test outcomes. None establishes physical Bluetooth operation, a signed distribution release, or App Store approval.

- `swift-results.json`: compiler, source hashes, exit codes, and complete output for the original/patched comparison and full core harness.
- `signal-regression-main.swift`: the exact same 26-case harness used for both versions of the production analyzer.
- `apple-us-lookup.json`: the dated public U.S. Apple catalog response for the exact app ID. A zero-result public response does not reveal the private review state.
- `duo-ci-40636901678.json`: native experimental Duo build/install success followed by an explicit missing-hinge-telemetry failure. This is not passing fold verification or validation of the merged main app fixes.
- `native-ci-40635520267.json`: public receipt for PR #3's successful native run, with the tested source, environment, 46 production core passes, 24 unit and four UI passes, zero failed/skipped tests, and the uploaded evidence digest. It contains no account credentials or device identifiers.
- [../2026-10-28/duo-telemetry-40706423363.json](../2026-10-28/duo-telemetry-40706423363.json): bounded native diagnostic confirming exit 64 for the old hinge command and a separate real 60-second boot-readiness timeout. Later hinge actions and app tests were not reached; this is not evidence that every runtime hinge provider is unavailable.
- [../2026-10-28/duo-supported-readback-40710723536.json](../2026-10-28/duo-supported-readback-40710723536.json): 30 portable checks and the native UIKit observer build passed, then boot readiness timed out at 180 seconds. Installation, app launch, live callbacks, and capture were not reached; zero fold poses were verified. Source/build hashes bind the successful compile to this experimental candidate.
- [../2026-10-28/duo-fresh-fixture-40713094528.json](../2026-10-28/duo-fresh-fixture-40713094528.json): 30 portable checks and the native build passed again; the new run-owned simulator reached readiness in 113.36 seconds. Installation, a read-only simulator listing, and cleanup commands then timed out while host load was very high. No app launch, live callback, pose, or screenshot was exercised; simulator deletion is unconfirmed.

## Reproduce the algorithm comparison

Run from the repository root with a Swift toolchain on PATH. The recorded run used official Swift 6.4.1 on Ubuntu 24.04, compiling the production source without substitutions. On macOS, `xcrun swiftc` can be used instead of `swiftc`.

```sh
work=$(mktemp -d)
cp docs/evidence/2026-10-27/signal-regression-main.swift "$work/main.swift"
git show 7de6ed0c468cbe33216ccd6fa80b30b671218d41:SignalScout/SignalAnalysis.swift > "$work/OriginalSignalAnalysis.swift"
swiftc -module-cache-path "$work/cache" "$work/OriginalSignalAnalysis.swift" "$work/main.swift" -o "$work/original"
"$work/original"
```

The original executable is expected to exit **1**, reporting **4 passed / 22 failed**. Then compile the patched source with the identical harness:

```sh
swiftc -module-cache-path "$work/cache" SignalScout/SignalAnalysis.swift "$work/main.swift" -o "$work/patched"
"$work/patched"
```

The patched executable should exit **0**, reporting **26 passed / 0 failed**. The source SHA-256 recorded for this comparison is `a49f6288a25ab1571bacb1860c1cf01346247e69709ca64422cfd1b4f06fb2c2`.

## Other checks

```sh
python3 scripts/check_free_release.py
python3 scripts/check_seo.py
```

On a Mac with Xcode, `sh scripts/check_core.sh` runs all **46** production core checks, including the bundled manufacturer registry. The same unmodified Swift inputs were compiled and executed successfully on Linux for the recorded result; the wrapper itself uses Xcode's `xcrun`.

Native unit/UI tests are configured in the pull-request QA workflow. [Run 40635520267](https://github.com/nickvan23-lang/signal-scout/actions/runs/40635520267) passed all **28** cases on Xcode 26.6 with an iPhone 17 Pro Max simulator running iOS 26.5; the receipt above binds that result to PR head `573699002f3c538ccf042f2628c0368dfd5ff75d` and the actual merge checkout. Optional preview recording and additional screenshot sizes were skipped as configured for pull requests, while no test cases were skipped. The separate Duo branch's `python3 tools/test_duo_capture.py` passed all 13 subprocess/evidence regressions. Its native run built and installed the candidate, then stopped because hinge-angle telemetry was unavailable; no fold poses have been verified.

[Draft PR #5](https://github.com/nickvan23-lang/signal-scout/pull/5) includes the verified main app fixes and a supported UIKit readback candidate. Head `c3cba603a757fb5d017879d0748e6eb571f3413c` (tree `f6684f166c27c670d7d7cd38509246f5480dd49e`) passed **30 portable protocol checks** and the **native observer build** in [run 40710723536](https://github.com/nickvan23-lang/signal-scout/actions/runs/40710723536). Boot readiness then exceeded 180 seconds, preventing installation, app launch, callbacks, and capture. This establishes compilation, with no verified fold poses.

The fresh-fixture attempt, [run 40713094528](https://github.com/nickvan23-lang/signal-scout/actions/runs/40713094528), completed with an **installation timeout**. Its head is `803bf1640e984351c47fb3c14fbba02b5f70ed44`, tree `5b43addcebed32efbbb7940d9171062a11c64d6d`. App/capture inputs were unchanged from the prior successful compile; the recorded workflow input changed. The 30 checks and native build passed again. The new run-owned simulator reached readiness in **113.36 seconds**, then installation exceeded its **30-second deadline**. The host reported load averages of **353.16 / 148.92 / 67.18**; a read-only simulator listing and owned-device shutdown/deletion also timed out. Cleanup is **unconfirmed**. These observations support infrastructure contention, without identifying its underlying cause or an app defect. No app launch, live callbacks, poses, or screenshots were exercised.

PR #5 remains a draft pending a healthy runner and live capture; no further native attempt was started. Any remaining cleanup is limited to the exact simulator in the run's ownership receipt. Actual callbacks must match fresh session/request/PID/sequence/scene gates before and after each screenshot; requested angles are never substituted for observations. Rendered screenshot orientation, visual layout, physical BLE operation, signing, and App Store release remain unverified by these experimental results.
