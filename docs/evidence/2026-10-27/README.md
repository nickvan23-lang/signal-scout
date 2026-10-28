# Diagnostic evidence

These are deterministic software checks recorded October 27, 2026 Pacific (October 28 UTC). They do not establish iOS UI behavior, live Bluetooth operation, or App Store approval.

- `swift-results.json`: compiler, source hashes, exit codes, and complete output for the original/patched comparison and full core harness.
- `signal-regression-main.swift`: the exact same 26-case harness used for both versions of the production analyzer.
- `apple-us-lookup.json`: the dated public U.S. Apple catalog response for the exact app ID. A zero-result public response does not reveal the private review state.

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

Native unit/UI tests are configured in the pull-request QA workflow. Their execution is a separate result from these portable checks. The separate Duo branch's `python3 tools/test_duo_capture.py` runs 13 subprocess/evidence regressions, with its native capture validation still pending.
