# Signal Scout

Signal Scout is a free iPhone Bluetooth Low Energy utility for comparing nearby signal strength while searching for an accessory you own or have permission to locate.

Version **1.3 (8)** was submitted to App Review on **October 9, 2026 at 10:47 AM Pacific**. App Store Connect confirmed **Waiting for Review**, with **automatic release after approval**. This is a submission receipt, not approval or a live App Store release.

- [Website, support, and privacy](https://nickvan23-lang.github.io/signal-scout/)
- [Build 8 iPhone Simulator video](https://nickvan23-lang.github.io/signal-scout/review/build-8/)

## Features and limits

- Shows advertised or iOS-reported device names and advertised manufacturer company identifiers, resolved offline using 4,047 Bluetooth SIG assignments. Missing information is labeled clearly. Broadcast details do not authenticate ownership or identity.
- Opens directly to the device list. The live map, expanded pan/zoom view, smoothed RSSI chart, and warmer/colder guidance help compare readings.
- Includes an in-app search guide, clear fresh/paused/lost states, direct pause/resume and return controls, optional haptics, and accessibility refinements.
- Every feature is free, without a subscription, account, purchase, or time limit.
- Scanning and analysis stay on the phone. Temporary names, manufacturer information, and readings remain in memory. No analytics, advertising, location tracking, or signal uploads.
- Only actively advertising BLE devices visible to CoreBluetooth can appear. Silent, powered-off, sleeping, connected, or closed-case accessories may be unavailable. RSSI is relative strength, not an exact distance; map angles are visual spacing, not bearings.

## Build and verify

```sh
xcodegen generate
xcodebuild -project SignalScout.xcodeproj -scheme SignalScout -destination 'generic/platform=iOS' build
sh scripts/check_core.sh
python3 scripts/check_free_release.py
```

Build 8 passed 20 native unit/UI tests (0 failures or skips) on an iPhone 17 Pro Max simulator running iOS 26.5 on a hosted Apple silicon Mac with Xcode 26.6. All 22 production core checks and 14 release-source checks passed. The signed distribution archive was verified and uploaded successfully. The local Intel Mac's asset compiler stalled, so the distribution archive reused the unchanged, hash-verified compiled visual assets while compiling all updated Swift sources. Hosted simulator builds used the normal asset pipeline.

[Hosted run and artifacts](https://github.com/nickvan23-lang/signal-scout/actions/runs/37959810850): core checks, native tests, preview video, and the medium/large screenshot sets succeeded. The overall workflow is marked failed because an optional third screenshot-size simulator timed out during boot. The completed evidence was downloaded and preserved locally. App Store Connect uses the new medium/large assets and scales them to other sizes.

The 26-second video records the actual app with visibly labeled simulated Bluetooth data. DEBUG demo controls and sample names are absent from Release. Physical BLE testing and Apple's earlier latest-OS physical-device recording request remain incomplete and were disclosed in the review notes. Simulator results do not verify radio reception.
