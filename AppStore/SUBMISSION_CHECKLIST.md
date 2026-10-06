# Signal Scout 1.3 (5): free-access resubmission

Build 4 was rejected on September 15, 2026. Apple cited description wording, a failed purchase, and an in-app purchase that had not been submitted, and explicitly requested a new binary. The September 10 request also requires detailed review information and a physical-device demonstration on the latest OS. The September 10 checklist predates the later submission and rejection, so its earlier submission status is stale and must not be used for this release.

## Prepared in source

- [x] Direct launch into the BLE scanner with no payment or account prerequisite.
- [x] Remove StoreKit product loading, purchases, restoration, entitlement checks, paywall, and the 60-second preview gate.
- [x] Remove preview countdowns from the scanner and full-screen map, including Xcode preview dependencies.
- [x] Preserve anonymous BLE labels, existing analysis, maps, charts, and guidance.
- [x] Preserve Support and Privacy links; move the Terms of Use link into Scanner options.
- [x] Update both project definitions to version 1.3, build 5.
- [x] Remove obsolete UserDefaults required-reason declaration from the privacy manifest; this source no longer accesses UserDefaults.
- [x] Replace old preview-clock unit tests with portable source-contract checks while keeping the ten signal/map/privacy unit tests.
- [x] Prepare free-access website text and product-page/review notes.

These source checks do not prove an iOS build, live BLE operation, or Apple review readiness.

## App Store Connect, rechecked October 5–6, 2026

- [x] Set the base app download price to the free tier and verify Current Price $0.00. The older base download price was $4.99 separately from the subscription.
- [x] Remove the unsubmitted subscription item from the current review draft without deleting the product or its history. The product remains Prepare for Submission.
- [x] Confirm the Free Apps Agreement is Active.
- [ ] Configure the intended storefronts after the user chooses launch regions. Apple currently shows Set Up Availability; no app availability exists. Historical subscription availability is a separate setting.
- [x] Save the free promotional text, description, and six-part review notes, and verify persistence. The recording paragraph accurately remains pending.
- [x] Publish and verify the version-specific support/privacy pages. Website-only PR #2 merged; Pages deployment succeeded; three public pages match source; privacy update dated October 6, 2026.
- [x] Attach and verify all nine native product screenshots across required medium and two large display groups, including saved order and visual previews.
- [ ] Attach and verify the real-device demonstration Apple requested.
- [x] Select processed build 5 in version 1.3 and verify after navigation. Apple reports Ready to Submit / Binary State Validated. Build 4 and historical records remain preserved.
- [ ] Check the latest review-draft contents and submit the free app only when all remaining gates are satisfied.

The Paid Apps Agreement remains Pending User Info (banking and U.S. tax information missing). This free-access change does not accept, complete, or change any agreement, tax, banking, security, or credential settings. Any Apple-required legal declarations remain with the Account Holder.

## Required Mac verification and new binary

- [x] Verify build 5 in the existing project and signed archive (October 5). No production project regeneration was needed.
- [x] Run the SignalScout scheme's ten XCTest cases on an available iPhone simulator (October 5: 10 passed, 0 failures).
- [x] Build and analyze the Release configuration without screenshot flags (October 5: both passed; Release binary audit passed).
- [ ] Check cold launch, relaunch, foreground/background transitions, and an upgrade over an expired-preview installation. No purchase, countdown, or lock screen should appear.
- [ ] Use the scanner, device list, focused tracking, and full-screen map for longer than 60 seconds; repeat opening, closing, pan, zoom, pause/resume, select/back, reset trend, and clear inactive devices.
- [ ] Verify Support, Privacy Policy, and Terms of Use links from Scanner options, including returning to the app.
- [ ] Verify Bluetooth denied, powered-off, unavailable, empty, and interrupted states; restoring Bluetooth permission should allow scanning.
- [x] Archive/sign version 1.3 (5), verify identity and signature, and audit the Release binary for absent StoreKit/paywall/preview and screenshot-only fixtures (October 5: passed; App Store IPA exported).
- [x] Upload and confirm processing of the new 1.3 (5) binary. Apple confirms the October 5 upload at 19:36 UTC; no duplicate upload occurred.

## Simulator verification completed October 5

Two isolated Xcode UI tests passed. Normal launch remained accessible beyond 60 seconds with the legacy preview key supplied as a launch argument, after background/foreground, and after termination/relaunch. A separate test using DEBUG simulated BLE verified repeated full-screen map navigation, zoom/fit controls, seeded tracking/return, and Support/Privacy/Terms controls. Neither test establishes live BLE reception, physical-device upgrade behavior, or the requested recording.

App Store Connect now confirms the existing delivery succeeded: build 5 is validated, ready to submit, and selected. The earlier Code 1085 configuration warning did not prevent this upload. See `VERIFICATION.md`.

## Physical-device demonstration

- [ ] On a real iPhone running the latest public iOS version available at recording time, show the OS version and installed build identity.
- [ ] Record normal launch without DEBUG screenshot modes or seeded signals, Bluetooth permission/state, real actively advertising BLE devices, the device list/live map, full-screen map, selection, changing signal strength while moving, and return navigation.
- [ ] Keep the demonstration running beyond 60 seconds and relaunch to show there is no timed gate. Explain that no paid access exists in this build.
- [ ] Use devices owned by the tester or with permission. Do not expose private notifications, account credentials, precise locations, or unrelated personal information.
- [ ] Include a reviewer-accessible recording in App Review attachments or a verified accessible link, and update notes with the actual device model, iOS version, build number, and result. Do not claim it is attached or tested before verifying it.

## Screenshot replacement

- [x] Replace the live field and expanded full-screen map from build 5: `Screenshots/01-live-signal-field.png`, `Screenshots/02-full-screen-map.png`, and their native `Screenshots/65/` and `Screenshots/63/` size variants. All six were visually inspected and show no preview/countdown presentation.
- [x] Recapture and visually inspect `Screenshots/03-warmer-guidance.png` and its native `Screenshots/65/` and `Screenshots/63/` variants from build 5.
- Do not attach `Screenshots/04-subscription-review.png` to this free release. Preserve it as historical evidence only.
- [x] Upload all nine replacement product screenshots to App Store Connect and verify their order and previews after reload. Native dimensions and SHA-256 hashes are recorded in `Screenshots/BUILD5_PROVENANCE.json`. These are simulator captures using existing DEBUG BLE fixtures; the requested physical-device demonstration remains separate and pending.

## Historical subscription record: preserve, do not submit

- Product: Signal Scout Pro Monthly, `com.nicholasvandervelden.SignalScout.monthly`
- Apple subscription ID: `6810541300`
- Group: Signal Scout Pro, ID `22373268`
- Historical price: $4.99/month; historical subscription availability: United States only

The free binary does not load, purchase, restore, or require this product. Do not delete its Apple record or assume a free update cancels any pre-existing Apple-managed subscription.
