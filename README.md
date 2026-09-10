# Signal Scout

Signal Scout is a privacy-conscious iPhone utility for finding nearby Bluetooth Low Energy devices that are actively advertising. Its Live Signal Field maps every advertisement onto relative-strength rings, offers an expanded pannable and zoomable full-screen map, and provides warmer-and-colder guidance while you move.

Support, privacy, and subscription information is published at [nickvan23-lang.github.io/signal-scout](https://nickvan23-lang.github.io/signal-scout/).

## What it can and cannot do

- It can discover BLE advertisements visible to CoreBluetooth and compare signal strength over time.
- Its live map moves stronger signals toward the phone and weaker signals outward. Stable angular lanes reduce visual jumping but do not represent measured directions.
- It cannot discover silent devices, every Classic Bluetooth device, Wi-Fi clients, or a device hidden by iOS privacy protections.
- RSSI is affected by walls, people, reflections, radio orientation, and device transmit power. The app reports a qualitative trend, not a precise distance or compass bearing.
- Scanning and analysis stay on the phone. The app contains no account, analytics, advertising, network request, or location code.
- Device names and manufacturer information are never shown or retained by Signal Scout. Visible advertisements use anonymous labels such as `Signal A1F3`.

## Access and subscription

- A one-time 60-second preview begins only when the user taps the preview button. Starting the preview does not initiate a purchase or charge.
- After the preview expires, feature access requires the `Signal Scout Pro Monthly` auto-renewable subscription.
- The App Store supplies the localized subscription price. Purchases, entitlement verification, restoration, and subscription management use StoreKit 2.
- The planned United States price is $4.99 per month. App Store Connect remains the source of truth for price and storefront availability.

## Build

```sh
xcodegen generate
xcodebuild -project SignalScout.xcodeproj -scheme SignalScout -destination 'generic/platform=iOS' build
```
