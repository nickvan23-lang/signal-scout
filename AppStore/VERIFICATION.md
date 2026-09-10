# Signal Scout 1.3 (4) verification

Verified on September 9, 2026 with Xcode 26.5 and the iOS 26.5 SDK.

## Passed gates

- iPhone 17 Pro Max simulator test run: 12 tests passed, 0 failed, 0 skipped.
- Generic iOS Release build: passed.
- Xcode static analysis: passed with no reported diagnostics.
- iPhone-only archive: `Archives/SignalScout-1.3-4-iPhone.xcarchive` created successfully.
- Archive identity: `com.nicholasvandervelden.SignalScout`, version 1.3, build 4, arm64, device family 1.
- Archive code signature integrity: `codesign --verify --deep --strict` passed.
- Privacy manifest: `plutil -lint SignalScout/PrivacyInfo.xcprivacy` passed.
- Release-binary audit: screenshot-mode arguments and sample identifiers are absent.
- Source privacy audit: no use of `peripheral.name`, advertised local-name keys, or manufacturer-data keys.
- App Store screenshots: three 1320 by 2868 PNG files captured from an iPhone 17 Pro Max simulator.

## Functional scope

- The one-time preview starts only after an explicit tap and counts down from 60 seconds.
- The preview start timestamp is stored locally so an ordinary relaunch does not reset it.
- Bluetooth scanning is constructed only while preview or subscribed access is active.
- A verified current StoreKit entitlement unlocks the app; purchases are verified before access is granted.
- Device names and manufacturer information are neither read into the app model nor presented. UI labels are anonymous.
- The full-screen map supports pan, pinch zoom, zoom controls, fit-all, pausing, and tap-to-track.

## Evidence boundary

The archive currently uses an Apple Development identity and development provisioning profile. It is a valid local archive, but it is not yet an App Store-distribution-signed upload. Distribution export, product creation, sandbox subscription testing, build upload, and App Review submission require the Apple account gates in `SUBMISSION_CHECKLIST.md`.

The simulator validates UI, subscription-state logic, and deterministic signal analysis. Live BLE reception was previously validated on the paired iPhone using the installed pre-subscription build; the final subscription build has intentionally not replaced that usable phone build before the App Store product is available.
