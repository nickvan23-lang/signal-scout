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
- All nine product screenshots were replaced and visually inspected: three native 1320-by-2868 UI-test captures from the iPhone 17 Pro Max simulator, three native 1284-by-2778 captures from the iPhone 13 Pro Max simulator, and three native 1206-by-2622 captures from the iPhone 16 Pro simulator. All run iOS 26.5 and use the existing DEBUG simulated BLE fixtures. The medium set was captured October 6 UTC; only its dedicated simulator was shut down afterward. `Screenshots/BUILD5_PROVENANCE.json` records their source, dimensions, and hashes. The old subscription-review image remains historical and is not part of the free release.

## Recovered local build issue

Archiving in the synced Documents folder failed because Finder information was attached to the generated app bundle. Moving DerivedData and archive output to `/tmp` resolved the code-signing failure. The successful archive is `/tmp/SignalScout-1.3-5-20261005.xcarchive`; the preserved copy is `release-evidence/SignalScout-1.3-5.xcarchive.zip`. This did not require changing signing access or the app source.

## Upload and saved Apple draft confirmed

The October 5 Xcode uploader logged `CDWebService Code=1085: No provider associated with App Store Connect user` during its configuration lookup, then continued delivery. After the user signed in to the connected Mac's existing Chrome session, App Store Connect confirmed **1.3 (5), Ready to Submit**, with **Binary State: Validated**. Its upload time is October 5, 12:36 PM GMT−7 (19:36 UTC). The server build ID is `4a6682d1-454f-4394-b78f-21b05b9c363d`; the bundle, arm64 architecture, iPhone family, minimum iOS 17.0, and team `YJTLRBVNSM` match the signed archive. No duplicate upload was needed.

Build 5 is selected in the version 1.3 draft. Free promotional text, description, and the six-part review notes were saved and verified after navigation/reload. The notes explicitly disclose that the real-device recording and physical QA remain pending. All nine screenshot associations, their native size groups, and the order live field → expanded map → warmer guidance were verified after reload and visually checked in Apple's Media Manager. The replaced associations were removed without deleting historical Asset Library assets. Manual release remains selected.

Evidence, retained locally outside Git: `release-evidence/app-store-builds-confirmed.txt`, `app-store-build5-metadata.txt`, `upload-diagnostic.json`, `version-build5-final-draft.txt`, `screenshots-after-reload.txt`, `screenshots-verified.json`, and `app-store-build5-media-verified.png`. Raw browser/account evidence is not published in the PR.

The version-specific support and privacy pages were published through [website-only PR #2](https://github.com/nickvan23-lang/signal-scout/pull/2), merged as `69031732011f28cc2179d7bb0be0306e5e77a329`. [The existing Pages workflow succeeded](https://github.com/nickvan23-lang/signal-scout/actions/runs/37392702265). All three public pages returned HTTP 200 and matched the reviewed source byte for byte. The privacy update is dated October 6, 2026. Application source remains in draft PR #1.

## Approved direct-device install prepared

Nick approved a retained-data build-5 installation October 6 at 02:16 UTC. The tested Release archive app is already signed by the existing Apple Development certificate with the valid wildcard profile containing this phone. An unchanged install copy is prepared in `/tmp/SignalScout-approved-device-install-20261006/SignalScout.app`; strict signature verification passed, and its executable SHA-256 matches the archive: `48347dc81f5ced3196d8ec796c2c4f14bb8bb1908662ee6123f6ad4feec8c484`. No re-signing, new certificate/profile, device registration, TestFlight invitation, or duplicate upload was needed. This development signature differs from the existing App Store export's distribution signature; it is the same compiled Release app, not a simulator or DEBUG-fixture build.

After Nick reported connecting the phone, the October 6 **02:46 UTC** preflight acquired a live wired, connected tunnel and verified **iOS 26.6.1 (23G83)** with Developer Mode and developer services available. The phone was locked (`passcodeRequired = true`), also confirmed by a fresh **02:47 UTC** lock query. The backup helper stopped before inspecting or copying app data. No backup, installation, app launch, or physical QA occurred. Nick needs to unlock the phone and keep it awake and connected, leaving SignalScout closed, before preserving/verifying the old data and any preview fixture and performing the already-authorized in-place install. The prepared app's strict signature and matching executable hash were reverified. See `PHYSICAL_QA.md`. Installation permission must not be requested again.

## Remaining release gates

- Latest review messages were re-read from the current submission. September 15 cites guideline 1.1 description wording (without identifying an exact offending term), and 2.1(b) failed purchase/unsubmitted IAP, and requests a new binary. September 10 requires a latest-OS physical-device recording and the same six answers in a review reply and Notes. Corrected copy/build preparation is not an Apple acceptance decision.
- Current base price was re-confirmed as **$0.00** in the visible Current Price details. Free Apps Agreement is **Active**; Paid Apps Agreement remains **Pending User Info**. No agreement, banking, tax, security, or access settings changed.
- App Privacy remains published as **Data Not Collected**; its privacy URL points to the corrected live policy. No new privacy answer was entered.
- App availability is **not configured**: Apple displays **Set Up Availability**. The launch storefront choice is pending the user's answer. Historical subscription availability is not evidence of the intended app storefronts.
- The paired physical iPhone 17 Pro Max was re-read October 5 at 23:33 UTC: **iOS 26.6.1 (23G83)**, Developer Mode enabled, paired and connected. An October 5 app query confirmed the existing installation is **1.2 (3)**. That installation was preserved. No new installation, real BLE test, actual upgrade from an expired-preview installation, or recording has occurred.
- [Apple's current release list](https://support.apple.com/en-us/100100), rechecked October 6, lists **iOS 27.0.1** as latest. The user must update/unlock/connect a physical device and identify an owned actively advertising BLE accessory for the requested demonstration.
- Earlier October 6 preparation reconfirmed installed **1.2 (3)**, but local-network preference access failed with **Network.NWError error 60 — Operation timed out**. The 02:46 UTC wired preflight now has working developer services and is blocked only by the phone's passcode lock. No current app-data backup or expired-preview fixture is confirmed. `PHYSICAL_QA.md` records the exact reviewer requirements, short recording flow, and scoped read-only follow-up.
- Physical-device Bluetooth permissions, denied/off/interrupted states, live reception while moving, extended navigation, external links, and upgrade behavior remain to be tested and recorded honestly. Simulator screenshots do not satisfy the physical recording request.
- Attach a reviewer-accessible genuine recording; replace the pending-recording paragraph with its actual device/OS/build/results; provide the same six answers in the required review reply; then verify the final submission item set before resubmitting.
- No App Review reply, review submission, new legal/compliance answer, paid commitment, credential creation, or account-access change occurred. Follow `SUBMISSION_CHECKLIST.md` before submission.

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
