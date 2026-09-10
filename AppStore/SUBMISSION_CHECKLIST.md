# App Store submission checklist

## Complete locally

- [x] SwiftUI/CoreBluetooth app implementation
- [x] Anonymous signal labels with no displayed device names
- [x] One-time, no-charge 60-second preview
- [x] StoreKit 2 monthly subscription, entitlement verification, restore purchases, and management link
- [x] Auto-renewal disclosure, privacy link, support link, and Apple standard EULA link
- [x] Privacy manifest and export-compliance plist key
- [x] App Store metadata draft and review notes
- [x] Public privacy policy/support/marketing site published and verified
- [x] Three product screenshots and one subscription-review screenshot at 1320 by 2868
- [x] Verified iPhone-only archive 1.3 (4) at `Archives/SignalScout-1.3-4-iPhone-final.xcarchive`
- [x] Twelve automated tests and static analysis

## Account Holder actions required in Apple systems

- [ ] Accept the updated Apple Developer Program License Agreement.
- [ ] Confirm or update the legal-entity information required for paid apps.
- [ ] Request and sign the Paid Apps Agreement.
- [ ] Complete banking and tax setup for paid proceeds.
- [ ] Complete the EU Digital Services Act trader-status workflow if distributing in the EU.
- [ ] Confirm export-compliance answers as legal declarations.

## Actions ready after those gates

- [x] Publish the public privacy/support site and verify each URL.
- [x] Register the explicit App ID `com.nicholasvandervelden.SignalScout`.
- [x] Create the App Store app record as `Signal Scout - BLE Finder` (Apple app ID `6810531496`) after the preferred name was unavailable.
- [x] Create the Signal Scout Pro subscription group (group ID `22373268`).
- [x] Create the `Signal Scout Pro Monthly` one-month product (Apple ID `6810541300`, product ID `com.nicholasvandervelden.SignalScout.monthly`).
- [x] Set the United States base storefront price to $4.99 per month.
- [x] Limit initial availability to the United States (1 of 175 storefronts).
- [x] Upload `Screenshots/04-subscription-review.png` as the subscription App Review screenshot.
- [x] Add the English (U.S.) subscription and subscription-group localizations.
- [x] Save the subscription App Review notes covering the no-account flow, one-time 60-second preview, anonymous BLE labels, StoreKit purchase, restore, and subscription management.
- [x] Export/re-sign build 4 for App Store Connect distribution.
- [x] Upload build 4 to App Store Connect (`Upload succeeded` on September 9, 2026).
- [x] Wait for Apple to finish processing build 4; it is available for selection as version 1.3, build 4.
- [ ] Run a StoreKit sandbox purchase, restore, expiration, and relaunch test on the physical iPhone.
- [ ] Enter metadata, screenshots, privacy answers, age-rating answers, and review notes.
- [ ] Select the uploaded build and subscription, then submit both for App Review.
- [ ] Monitor processing and App Review; resolve any Apple feedback without making unsupported claims.
