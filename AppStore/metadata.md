# Signal Scout App Store metadata

## Release state

Free-access release: version 1.3, build 5. The Release build, analysis, ten XCTest cases, two simulator UI tests, signed archive, and App Store IPA export passed on October 5, 2026. App Store Connect confirmed the upload as validated and ready to submit; build 5 is selected. Free copy and all nine native screenshots are saved. The requested physical-device recording, hardware QA, storefront selection, and review submission remain pending. Apple rejected build 4 on September 15, 2026 and requested a new binary. Do not submit the old binary with these new free-access claims.

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

## App Review notes saved in Apple draft: physical recording pending

Signal Scout 1.3 (5) is a free BLE accessory utility. This new binary removes StoreKit, purchases, restoration, subscriptions, the paywall, and the one-time 60-second preview. No in-app purchase is included in this release. Do not evaluate these changes using rejected build 4.

1. Physical-device demonstration
Apple's requested latest-OS physical-device recording is pending and is not attached. No real-device verification is claimed here. Build 5 passed a Release build/analysis, ten XCTest cases, and two simulator UI tests. The simulator screenshots use DEBUG BLE fixtures; those are excluded from the Release binary and are not live-Bluetooth evidence. The recording and physical-device QA must be completed before resubmission. The app has no accounts, user-generated content, or paid access.

2. Purpose and audience
This iPhone utility helps people look for a misplaced BLE accessory they own or have permission to locate by comparing its advertising signal strength. It shows anonymous signal labels and relative RSSI. Stronger signals appear closer to the map center; angle is visual spacing, not a bearing. It cannot locate devices that are silent or powered off or guarantee that an accessory is visible.

3. Setup and main features
Enable Bluetooth, launch normally, and allow Bluetooth access when prompted. No login, sample file, purchase, or trial activation is needed. Use a BLE accessory owned by the tester that is actively advertising. Bring it close and compare the anonymous signal whose RSSI increases. Use Live Map or Device List; expand the map for pan, zoom, fit-all, and signal selection. Select a signal, walk slowly, and compare smoothed readings, warmer/colder guidance, the chart, and haptic feedback. Reset the trend for a new direction and stop tracking to return. Scanner options provide pause/resume, clearing inactive signals, Support, Privacy Policy, and Terms of Use. Access continues beyond 60 seconds and after relaunch. Accessories may stop advertising while connected, asleep, or in a closed case.

4. Core platforms and external services
Apple CoreBluetooth provides BLE advertisements. Analysis and layout are on the iPhone. There is no developer backend, authentication service, analytics, advertising, location service, AI service, payment processor, or signal upload. Temporary records stay in memory. Support/privacy pages and Apple's standard EULA open externally only when selected.

5. Regions
The source has no regional feature or content variations. Its functionality is consistent across supported storefronts; distribution availability is configured in App Store Connect.

6. Regulated services and third-party material
This is a general-purpose BLE signal-strength utility. It does not offer regulated services or display protected third-party material. It uses Apple system frameworks; no additional service credentials or authorization documents are needed for its core functionality.

The notes were verified against the saved Apple field. They must be updated with genuine device/video evidence before submission, and the six answers must also be provided in the requested review reply.

## Privacy and content evidence

- App or third-party partners collect data: No
- Tracking and location permission: None
- Analytics/advertising SDKs, developer backend, account system: None
- BLE records: anonymous, in memory, on device, not transmitted
- Preview start time: no longer read or written; a timestamp left by an earlier installation is ignored
- StoreKit purchase and entitlement calls: removed from free source
- Privacy questionnaire remains published as `Data Not Collected`, verified October 6, 2026; privacy URL points to the corrected live policy
- Privacy URL: `https://nickvan23-lang.github.io/signal-scout/privacy.html`
- Age-rating page rechecked October 6: `4+` with regional exceptions; existing Content Rights and standard Apple license remain saved
- Content Rights was saved as `No, this app does not contain, show, or access third-party content.`
- No proprietary or non-exempt encryption is implemented; `ITSAppUsesNonExemptEncryption` remains `NO`. Final legal/export declarations remain with the Account Holder.

## Apple state observed October 5–6, 2026

- Base app price changed from $4.99 to the free tier; Current Price verified as $0.00.
- Free Apps Agreement: Active.
- Paid Apps Agreement: Pending User Info, with banking and U.S. tax information missing; no changes made to that setup.
- Historical subscription removed from the unsubmitted review draft, not deleted. Its status remains Prepare for Submission.
- App storefront availability is unconfigured: Apple shows Set Up Availability. User launch-region choice is pending; historical subscription availability is separate.
- Build 5 is Ready to Submit / Validated and selected in version 1.3, which shows Prepare for Submission and the previous rejection notice. Build 4 and its history remain preserved. The physical-device recording is not supplied yet.
- All nine native product screenshots and the corrected free copy are saved and verified.
- Version-specific support/privacy pages are live via merged PR #2 and verified successful Pages deployment; the privacy update is dated October 6, 2026.
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
