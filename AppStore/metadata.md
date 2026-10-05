# Signal Scout App Store metadata

## Release state

Free-access release: version 1.3, build 5. The Release build, analysis, ten XCTest cases, two simulator UI tests, signed archive, and App Store IPA export passed on October 5, 2026. An upload reached Apple delivery, but final receipt and processing remain unconfirmed; build selection and review submission are pending. Apple rejected build 4 on September 15, 2026 and requested a new binary. Do not submit the old binary with these new free-access claims.

## Identity

- App Store name: Signal Scout - BLE Finder
- On-device display name: Signal Scout
- Apple app ID: `6810531496`
- Primary language: English (U.S.)
- Bundle ID: `com.nicholasvandervelden.SignalScout`
- SKU: `SIGNALSCOUT-IOS-2026`
- Version: 1.3
- Build: 5
- Primary category: Utilities
- Secondary category: Productivity (historical App Store Connect setting)
- Copyright: 2026 Nicholas Alan Vandervelden

## Product page draft

Subtitle: `Find Lost Headphones & Devices`

Promotional text:

Compare anonymous BLE signal strength with a live map, a signal chart, and warmer-or-colder guidance while searching for a device you own or have permission to locate.

Description:

Signal Scout helps you compare nearby Bluetooth Low Energy signal strength while searching for a device you own or have permission to locate. The device must be actively advertising and visible to your iPhone.

LIVE SIGNAL MAP AND DEVICE LIST

See nearby BLE advertisements as anonymous signal labels with measured RSSI in dBm. On the live map, stronger signals appear closer to the center and weaker signals appear farther out. Switch to the device list, or expand the map to pan, zoom, and tap a signal for focused tracking.

WARMER-AND-COLDER GUIDANCE

Select a signal and move slowly. Signal Scout smooths noisy readings and compares changes over time to show getting warmer, getting colder, or about the same. A recent-signal chart and haptic feedback help you compare positions. You can reset the trend when trying another direction.

ANONYMOUS SIGNALS

Signal Scout does not identify a device's owner, read device names, or show manufacturer information. Nearby devices receive generic labels such as Signal A1F3. When possible, move a device you control close to your iPhone and compare how its signal changes to help identify the relevant signal. Other nearby devices may also appear.

FREE ACCESS

All features are available without payment, a subscription, an account, or a time limit. Open the app and allow Bluetooth access to begin scanning.

PRIVATE BY DESIGN

Bluetooth scanning and signal analysis happen on your iPhone. Signal Scout has no account system, analytics, advertising, location tracking, or signal uploads. Temporary signal records stay in memory and are not sent to the developer.

IMPORTANT LIMITATIONS

Bluetooth RSSI indicates approximate relative signal strength, not an exact distance or compass direction. A dot's angle on the map is a visual layout position, not a measured bearing. Walls, reflections, orientation, and transmit power can affect readings. Signal Scout cannot locate a powered-off device or guarantee that headphones, earbuds, speakers, trackers, or other accessories will be visible. Devices that are asleep, in a closed charging case, already connected, or not actively advertising may not appear. This app does not identify people or provide their location.

Support: https://nickvan23-lang.github.io/signal-scout/support.html
Privacy Policy: https://nickvan23-lang.github.io/signal-scout/privacy.html
Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

Keywords: `bluetooth,BLE,headphones,earbuds,finder,signal,RSSI,lost,device,map,misplaced,earphones,speaker`

What's New:

All signal-scanning, map, and tracking features are now available without a subscription or time limit. Open directly to the scanner, with Support, Privacy Policy, and Terms of Use in Scanner options.

The haptics wording is intentional: `BluetoothScanner.provideFeedback(for:)` triggers haptic feedback on warmer/colder transitions. The source has no in-app haptics toggle, so the description must not call it optional.

## App Review notes draft: pending build association and real-device recording

Free-access resubmission: version 1.3, build 5. The app removes paid access and the timed preview; the historical subscription is excluded from this release. The build, simulator tests, archive, and export passed. Final upload receipt, processing, build association, and the requested real-device recording must be verified before these notes are submitted. Do not use the rejected build 4 to evaluate the free-access changes.

1. Physical-device recording
The requested physical-device recording has not yet been supplied. Before resubmission, provide a recording on a real iPhone running the latest public iOS, beginning at normal app launch and showing the complete flow below. Include the actual device model, OS version, and build number. The app has no accounts or user-generated content. The prepared free build has no paid access, purchase, restore, subscription, or time limit.

2. Purpose and audience
Signal Scout is an iPhone utility for people searching for BLE accessories they own or have permission to locate. It compares signal strength from actively advertising BLE devices to help narrow a search. It does not identify a person or device owner. Signals have generic labels rather than device names. RSSI is approximate: the map's radial position represents relative strength, and the angle is a visual lane rather than a bearing. It cannot locate silent, powered-off, or otherwise non-advertising devices.

3. Setup and main features
Enable Bluetooth, launch the app, and allow Bluetooth access when iOS asks. No sign-in, sample file, code, purchase, or trial activation is required. The scanner starts when Bluetooth is ready. Use an actively advertising BLE accessory owned by the tester. Where possible, bring it near the phone and compare the anonymous signal whose RSSI strengthens.
Use Live Map or Device List to inspect signals. Expand the map to pan and zoom, then tap a signal to track it. Walk slowly to see smoothed RSSI, warmer/colder guidance, a recent-signal chart, and haptic feedback. Reset the trend to try another direction. Stop tracking to return to scanning. Scanner options provide pause/resume, clear inactive devices, Support, Privacy Policy, and Terms of Use. Verify access continues beyond 60 seconds and after relaunch. If no signal appears, wake the accessory and confirm it is advertising; many headphones stop advertising while connected, asleep, or in a closed case.

4. External services and platforms
Core scanning uses Apple's CoreBluetooth on the iPhone; analysis and map layout are on device. There is no developer backend, account service, analytics, advertising, location service, AI service, or signal upload. The free build removes StoreKit product and entitlement requests. Support/privacy pages and Apple's standard EULA are external links opened only when selected. Temporary BLE records remain in memory.

5. Regional differences
The prepared source has no regional feature or content variations. Functionality is the same in every storefront where the app is made available; actual availability is set in App Store Connect.

6. Authorization and protected material
This app is a general-purpose BLE signal-strength utility, not a regulated financial, medical, gambling, or government service. It uses Apple system frameworks and does not display protected third-party content. No service login or authorization document is required for its core features.

The historical product com.nicholasvandervelden.SignalScout.monthly is not used by the free build and must not be included in this review submission. Its App Store Connect record is preserved. The description and screenshots must match the new free build before resubmission.

## Privacy and content evidence

- App or third-party partners collect data: No
- Tracking and location permission: None
- Analytics/advertising SDKs, developer backend, account system: None
- BLE records: anonymous, in memory, on device, not transmitted
- Preview start time: no longer read or written; a timestamp left by an earlier installation is ignored
- StoreKit purchase and entitlement calls: removed from free source
- Privacy questionnaire was published as `Data Not Collected` on September 10, 2026; verify current state before submission
- Privacy URL: `https://nickvan23-lang.github.io/signal-scout/privacy.html`
- Historical age-rating result: global `4+`, `All` in Brazil, `00+` in Korea; verify current state before submission
- Content Rights was saved as `No, this app does not contain, show, or access third-party content.`
- No proprietary or non-exempt encryption is implemented; `ITSAppUsesNonExemptEncryption` remains `NO`. Final legal/export declarations remain with the Account Holder.

## Apple state observed October 3, 2026

- Base app price changed from $4.99 to the free tier; Current Price verified as $0.00.
- Free Apps Agreement: Active.
- Paid Apps Agreement: Pending User Info, with banking and U.S. tax information missing; no changes made to that setup.
- Historical subscription removed from the unsubmitted review draft, not deleted. Its status remains Prepare for Submission.
- App storefront availability needs confirmation; do not treat historical subscription availability as the app's storefront setup.
- Build 4 remains Rejected. Build 5 and the physical-device recording are not supplied yet.
- The current release checklist supersedes the September 10 checklist, whose submission status predates the later submission and rejection.

## Historical subscription record: not part of this free release

Preserve the record and history in Apple systems; do not submit it with this release.

- Type: Auto-renewable subscription
- Group: Signal Scout Pro, ID `22373268`
- Reference name: Signal Scout Pro Monthly
- Product ID: `com.nicholasvandervelden.SignalScout.monthly`
- Apple subscription ID: `6810541300`
- Duration and historical U.S. price: 1 month, $4.99
- Historical subscription availability: United States only
- Historical Family Sharing: Off; no introductory offer
- Historical localization description: `Unlimited lost-device signal mapping and guidance.`
- Historical review screenshot: `Screenshots/04-subscription-review.png`; do not attach to the free release

These identifiers are retained for historical reference only. The free source contains no subscription purchase, restore, entitlement, preview countdown, or price fixture. Installing this free version does not itself cancel any existing Apple-managed subscription.

## App Store name decision

`Signal Scout` was unavailable in App Store Connect, so the app record was created as `Signal Scout - BLE Finder`. The on-device display name remains `Signal Scout`.
