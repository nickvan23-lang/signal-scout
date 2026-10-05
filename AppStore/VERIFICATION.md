# Signal Scout 1.3 (5) verification

Verified October 5, 2026 on the connected Mac with Xcode 26.5 (17F42), the iOS 26.5 SDK, and a dedicated iPhone 17 Pro Max simulator. The application source compiled was commit `d11b0961e1007f612027f9c97891aed936b5326f`, based on main `3c5272c5404f944b9f7bcb0bfae1d7c510d8b306`. Subsequent verification, metadata, screenshot, and source-check changes do not change the application Swift source. The original checkout at `/Users/nicholas/Projects/SignalScout` remains clean at `e236eeb`.

## Passed checks

- Generic iOS Release build: **BUILD SUCCEEDED**.
- Xcode Release analysis: **ANALYZE SUCCEEDED**. No source diagnostics were reported; the emitted warning concerned unused App Intents metadata extraction.
- SignalScout XCTest: **10 tests passed, 0 failures**. Evidence: `release-evidence/SignalScout-build5-tests.xcresult` and `release-evidence/xctest.log`.
- Isolated Xcode UI test harness: **2 tests passed, 0 failures**. Evidence: `release-evidence/SignalScout-build5-ui-tests.xcresult`, `release-evidence/ui-tests.log`, and its seven exported attachments.
- The first UI test launched without DEBUG simulated BLE data, supplying the historical preview key as a launch argument. The scanner remained available after 65 seconds, background/foreground, termination, and relaunch. This does not establish a physical-device upgrade from an earlier installed binary.
- The second UI test used existing DEBUG simulated BLE fixtures to verify repeated full-screen map opening/closing, zoom/fit controls, Support/Privacy/Terms menu controls, seeded tracking, and return navigation. It does not verify live BLE reception or opening external links on a physical device.
- Signed Release archive and App Store IPA export succeeded. Both passed `codesign --verify --deep --strict`.
- Archive identity: `com.nicholasvandervelden.SignalScout`, version **1.3**, build **5**, arm64, device family **1**, minimum iOS **17.0**.
- The exported IPA uses the existing Cloud Managed Apple Distribution certificate for team `YJTLRBVNSM` and the existing SignalScout App Store provisioning profile, with `get-task-allow = false`. No new certificate, profile, or account access was requested.
- Exported IPA SHA-256: `eecb34cd03684f08ddb5e64595b9928a9af2707aa6aa93309e6de77eba0d0a8b`. Evidence: `release-evidence/SignalScout-1.3-5.ipa`, `release-evidence/DistributionSummary.plist`, `release-evidence/archive-audit.json`, and the archived `.xcarchive.zip`.
- Release binary audit found no StoreKit linkage, removed subscription types, old paywall/preview labels or date key, or DEBUG screenshot launch flags. The app plist reports `ITSAppUsesNonExemptEncryption = false`; this is a build-setting observation, not a new legal declaration.
- `python3 scripts/check_free_release.py`: **14 checks passed**. Configuration parsing now checks source configuration and accepts valid binary/XML plists without accidentally treating generated Xcode bundles as source XML.
- BluetoothScanner, SignalAnalysis, and SignalMapLayout remain unchanged from the free-release preparation base. The free source no longer reads or writes UserDefaults or a preview timestamp and has no payment or entitlement prerequisite.
- All six product screenshots were replaced and visually inspected: three native 1320-by-2868 UI-test captures from the iPhone 17 Pro Max simulator and three native 1284-by-2778 captures from the iPhone 13 Pro Max simulator. Both run iOS 26.5 and use the existing DEBUG simulated BLE fixtures. `Screenshots/BUILD5_PROVENANCE.json` records their source, dimensions, and hashes. The old subscription-review image remains historical and is not part of the free release.

## Recovered local build issue

Archiving in the synced Documents folder failed because Finder information was attached to the generated app bundle. Moving DerivedData and archive output to `/tmp` resolved the code-signing failure. The successful archive is `/tmp/SignalScout-1.3-5-20261005.xcarchive`; the preserved copy is `release-evidence/SignalScout-1.3-5.xcarchive.zip`. This did not require changing signing access or the app source.

## Upload outcome: not yet confirmed

The October 5 Xcode upload attempt first logged `CDWebService Code=1085: No provider associated with App Store Connect user` during the store-configuration lookup. The uploader continued afterward, received successful Apple API responses, and reached **Uploading to App Store Connect at 19:35 UTC**. The delivery log then sent an `uploaded: true` file notification; no final build receipt or processing confirmation appears in the retained logs.

After connection recovery at 19:42 UTC, no upload process was running. No duplicate upload was started. The warning alone is not proof of final upload failure. Check App Store Connect's build list and processing status before retrying. The separately exported IPA hash above identifies that deliverable, not an unconfirmed server-side build. Evidence: `release-evidence/upload.log` and `release-evidence/upload-diagnostic.json`.

## Remaining release gates

- Browser control was restored using a fresh tab in the Nick Chrome profile. App Store Connect still requires direct password/passkey and any two-factor sign-in for `nickvan23@gmail.com`. Current review messages, agreements, app availability, metadata, and build association have not yet been re-read.
- Replace App Store Connect's description, review notes, and product screenshots with the prepared free-build content after authentication; confirm the subscription is excluded and the correct processed build is selected.
- All six replacement screenshots are prepared in source; their App Store Connect attachment is pending authentication. No simulator capture is represented as the requested physical-device recording.
- The paired physical iPhone 17 Pro Max runs **iOS 26.6.1 (23G83)** with Developer Mode enabled. An October 5 `devicectl` app query confirmed that the existing installation is version **1.2 (3)**. That installation was preserved. No new installation, real BLE test, actual upgrade from an expired-preview installation, or recording has occurred in this attempt.
- [Apple's current release list](https://support.apple.com/en-us/100100), checked October 5, lists **iOS 27.0.1** as latest. The previously recorded review request calls for a real-device demonstration on the latest public OS.
- Physical-device Bluetooth permissions, denied/off/interrupted states, live signal reception while moving, extended navigation, external links, and upgrade behavior remain to be tested and recorded honestly.
- No review submission, legal agreement acceptance, compliance answer, paid commitment, credential creation, or account-access change occurred. Follow `SUBMISSION_CHECKLIST.md` before submission.

The results below are preserved as historical evidence for rejected build 4, not proof of build 5's removed subscription behavior.

---

# Historical record: Signal Scout 1.3 (4) verification

Verified on September 9, 2026 with Xcode 26.5 and the iOS 26.5 SDK.

## Passed gates

- iPhone 17 Pro Max simulator test run: 12 tests passed, 0 failed, 0 skipped (`Test-SignalScout-2026.09.09_8-51-24--0700.xcresult`).
- Generic iOS Release build: passed.
- Xcode static analysis: passed with no reported diagnostics.
- iPhone-only archive: `Archives/SignalScout-1.3-4-iPhone-final.xcarchive` created successfully.
- Archive identity: `com.nicholasvandervelden.SignalScout`, version 1.3, build 4, arm64, device family 1.
- Archive code signature integrity: `codesign --verify --deep --strict` passed.
- Privacy manifest: `plutil -lint SignalScout/PrivacyInfo.xcprivacy` passed.
- Release-binary audit: screenshot-mode arguments, the screenshot-only `$4.99` fixture, and sample identifiers are absent.
- Source privacy audit: no use of `peripheral.name`, advertised local-name keys, or manufacturer-data keys.
- Product screenshots: three 1320 by 2868 PNG files captured from an iPhone 17 Pro Max simulator.
- Subscription review screenshot: `Screenshots/04-subscription-review.png`, 1320 by 2868, captured from the same simulator and showing the renewal disclosure, restore control, terms, privacy, support, and `$4.99 per month` purchase control.
- Screenshot pricing fixture: implemented inside `#if DEBUG` solely to render the configured price when StoreKit is unavailable in the simulator; the Release archive continues to use `Product.displayPrice` and contains none of the fixture strings.

## Functional scope

- The one-time preview starts only after an explicit tap and counts down from 60 seconds.
- The preview start timestamp is stored locally so an ordinary relaunch does not reset it.
- Bluetooth scanning is constructed only while preview or subscribed access is active.
- A verified current StoreKit entitlement unlocks the app; purchases are verified before access is granted.
- Device names and manufacturer information are neither read into the app model nor presented. UI labels are anonymous.
- The full-screen map supports pan, pinch zoom, zoom controls, fit-all, pausing, and tap-to-track.

## Evidence boundary

The upload-ready IPA at `Export/SignalScout-1.3-4.ipa` is signed with `Apple Distribution: NICHOLAS ALAN VANDERVELDEN (YJTLRBVNSM)` and the App Store provisioning profile for `com.nicholasvandervelden.SignalScout`. Its SHA-256 digest is `6d156040db11887e85b2183440b9adc24e8906767a5181350c31a95c8041d3e1`. Product creation, sandbox subscription testing, build upload/processing, and App Review submission remain tracked in `SUBMISSION_CHECKLIST.md`.

The simulator validates UI, subscription-state logic, and deterministic signal analysis. Live BLE reception was previously validated on the paired iPhone using the installed pre-subscription build; the final subscription build has intentionally not replaced that usable phone build before the App Store product is available.
