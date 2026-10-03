# Signal Scout

Signal Scout is a privacy-conscious iPhone utility for narrowing the search for lost headphones, earbuds, and other Bluetooth Low Energy devices that are actively advertising. Its Live Signal Field maps every advertisement onto relative-strength rings, offers an expanded pannable and zoomable full-screen map, and provides warmer-and-colder guidance while you move.

Support and privacy information is published at [nickvan23-lang.github.io/signal-scout](https://nickvan23-lang.github.io/signal-scout/).

## What it can and cannot do

- It can discover BLE advertisements visible to CoreBluetooth and compare signal strength over time.
- Its live map moves stronger signals toward the phone and weaker signals outward. Stable angular lanes reduce visual jumping but do not represent measured directions.
- It cannot discover silent devices, every Classic Bluetooth device, Wi-Fi clients, or a device hidden by iOS privacy protections.
- RSSI is affected by walls, people, reflections, radio orientation, and device transmit power. The app reports a qualitative trend, not a precise distance or compass bearing.
- Scanning and analysis stay on the phone. The app contains no account, analytics, advertising, network request, or location code.
- Device names and manufacturer information are never shown or retained by Signal Scout. Visible advertisements use anonymous labels such as `Signal A1F3`.

## Free access

- Version 1.3 (5) opens directly to the scanner. All signal maps, tracking, charts, and guidance are available without payment or a time limit.
- There is no subscription screen, preview countdown, purchase, restore, or App Store entitlement check in this release.
- Existing local preview timestamps from older installations are ignored. No account or sign-in is required.
- Support, Privacy Policy, and Terms of Use remain available in Scanner options.
- Historical subscription product records are preserved in App Store Connect; this release does not use or submit them.

## Build

```sh
xcodegen generate
xcodebuild -project SignalScout.xcodeproj -scheme SignalScout -destination 'generic/platform=iOS' build
```

## Verify

Run the portable source checks with `python3 scripts/check_free_release.py`. These checks do not compile or run the iOS app.

On a Mac with Xcode, run the `SignalScout` scheme's tests on an available iPhone simulator, build and analyze Release, and archive build 5. The remaining device tests, screenshots, and review-video requirements are listed in `AppStore/SUBMISSION_CHECKLIST.md`. The earlier build 4 verification is historical and does not validate build 5.
