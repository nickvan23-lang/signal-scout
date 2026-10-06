# Physical-device QA and reviewer recording

Prepared October 6, 2026. This is a test plan, not completed hardware evidence. The installed app and its data have not been changed.

## Approved installation preparation

Nick approved an in-place, retained-data build-5 installation on October 6 at 02:16 UTC. This approval persists; no further installation permission is needed. It does not choose storefronts or authorize an OS update or data erase.

At 02:18 UTC the Mac was reachable, but the phone's tunnel was unavailable and its USB inventory was empty. A lock-state query failed with **CoreDevice error 1011: unable to locate the device**. The reported 26.6.1 OS is retained metadata; the live OS and current lock state cannot be verified while the phone is absent. No backup or installation was attempted.

The original tested Release archive app is already **developer-signed** using the existing valid `YJTLRBVNSM` wildcard profile, which explicitly includes this phone. An unchanged copy is prepared at `/tmp/SignalScout-approved-device-install-20261006/SignalScout.app`; its executable SHA-256 matches the tested archive, and strict signature verification passed. This direct-device route needs no new certificate/profile, device registration, or TestFlight tester invitation. The separate App Store IPA remains unchanged. Its installation still requires the phone and a verified state backup first.

## Apple's actual request

The [current submission messages](https://appstoreconnect.apple.com/apps/6810531496/distribution/reviewsubmissions/details/5db11dc9-73b3-4102-b7f6-69f12e155e40) still contain the September 10 and September 15 requests. The review item now links build **1.3 (5)**; there is one app-version item and no IAP item. Resubmission remains disabled.

September 10 requires physical-device QA of the submitted build before resubmission, and a recording made on a physical device running the latest OS. The recording must start with app launch and demonstrate the normal user flow. Registration/login/deletion, user-generated content safeguards, and paid features need demonstrations only when the app includes them; build 5 has none of these. Apple specifies no recording duration, resolution, narration, or separate Settings introduction. A simulator recording does not meet the physical-device requirement.

Apple also asks for six items in both an App Review reply and the review Notes: the recording; purpose/audience; setup/main features and any credentials/files; core external services/platforms; regional differences or consistent behavior; and authorization documents if regulated services or protected third-party content are involved. The saved notes cover the free build accurately but still disclose that recording and hardware QA are pending. No reply has been sent.

The September 15 review concerned build 4 on an iPad Air 11-inch (M3), iPadOS 26.6.2. It identifies the description as an objectionable-marketing field without naming a particular offending term, and reports failed purchase/unsubmitted IAP. Build 5 removes the purchase system and has corrected neutral description text; Apple has not accepted those corrections yet.

## Current phone and preserved state

- Read-only app metadata confirms Signal Scout **1.2 (3)** on the paired iPhone 17 Pro Max. The phone reports **26.6.1 (23G83)**, Developer Mode enabled, and a passcode required.
- Device metadata queries work intermittently over the local network. Developer disk-image services were unavailable, and reading the app's preference directory failed with `Network.NWError error 60 — Operation timed out`. The USB inventory showed no connected iPhone or iPad.
- The historical preview key is `signalScout.preview.startedAt.v1`; the old source stores it only when the user starts the preview and considers it expired after 60 seconds. Its presence on this installed phone has **not** been verified. Version metadata alone does not establish an expired-preview fixture or prove the old installed binary implements that gate.
- No preference backup was created. Do not delete, reinstall, clear preferences, start an old preview, or overwrite the installed app before inspecting and preserving the relevant data. Copying preferences alone would preserve a migration fixture; it would not prove the old UI was actually locked.

## What Nick needs to do

1. Unlock the phone and connect it to the Mac by a data-capable USB cable. Leave Signal Scout installed and do not launch/reset it yet. Any passcode or trust prompt is handled directly by Nick. This lets us retry the scoped read-only fixture inspection and backup.
2. After preserving the relevant fixture, Nick manually updates to the latest public iOS and reconnects/unlocks the phone. [Apple currently lists iOS 27.0.1](https://support.apple.com/en-us/100100). No OS update is started by this workflow.
3. Provide an owned, actively advertising BLE accessory. Wake it; many headphones stop advertising when connected, asleep, or inside a closed case. We must observe a genuine signal rather than substitute fixtures if the accessory is not visible.
4. The **in-place update to build 1.3 (5) that retains the app data is approved**. Once the phone is reachable, preserve its app-data container and verify any historical preview key before installing the already-signed Release app. Do not uninstall first. TestFlight is an optional alternative: build 5 has **Groups (0)** and **Individual Testers (0)**, so no existing tester route is configured. No tester invitation, account change, device registration, or new signing profile has been created.
5. Perform the brief flow below on the phone. The agent can observe/capture/inspect the evidence once the necessary device access is working, but the current CLI has no physical touch control and cannot move the phone or accessory.

## Short recording: approximately two to three minutes

The suggested duration exceeds the removed 60-second gate for useful release evidence; it is our test choice, not an Apple-specified minimum. Verify the OS/build separately and include them in the notes, so the recording itself starts at app launch.

1. Begin a real screen recording, close Control Center, and launch Signal Scout normally. Allow Bluetooth if prompted. Show direct access to the scanner without purchase, trial activation, or login.
2. Show actual advertisements in **Device List**, then **Live Map**. Bring the owned accessory near the phone and compare the anonymous signal that strengthens; do not claim an identity based only on its generic label.
3. Expand the map. Pan, zoom, fit all, select a signal, and return. Pause/resume scanning once.
4. Track the signal while moving several slow steps. Show changing RSSI/chart and whatever warmer/colder/stable result actually occurs. Reset the trend and stop tracking. A particular direction result must not be staged.
5. Continue beyond 60 seconds, background/foreground, then close and relaunch normally. Show the scanner remains accessible. Stop the recording, save the original, and review it for legibility and private notifications before upload.

[iPhone Screen Recording](https://support.apple.com/en-us/102653) is the shortest capture method: Control Center's Record control, its countdown, then exit Control Center; the movie is saved in Photos. Do not use simultaneous screen mirroring. If a USB-connected capture input is available, [QuickTime's New Movie Recording](https://support.apple.com/guide/quicktime-player/record-a-movie-qtp356b55534/mac) can save the real phone screen directly on the Mac. QuickTime and iPhone Mirroring are installed here; a working capture input has not been verified and no recording was started.

## Additional physical QA outside the short video

| Check | Actual result needed |
| --- | --- |
| Upgrade fixture | Record old version/key state before an authorized in-place update. Verify the legacy key is ignored afterward. Claim an upgrade from an expired locked preview only if that old locked state was genuinely observed. |
| Bluetooth permission | Denied access has clear guidance; re-enabling access permits scanning. Record the starting setting and restore it after the test. |
| Bluetooth power/interruption | With Bluetooth genuinely off in Settings, scanning shows the correct state; switching it back on and foregrounding restores operation. [Apple distinguishes Control Center disconnection from turning Bluetooth off in Settings](https://support.apple.com/en-us/102412). |
| Empty/inactive signals | Empty scanning is understandable; an accessory that stops advertising becomes inactive, and Clear Inactive Devices removes the stale entry. |
| Navigation and links | Repeated expand/close, pan/zoom/fit, selection/back, reset trend, pause/resume, and Support/Privacy/Terms links work; returning to the app remains usable. |
| Remaining enabled platforms | Apple's message asks for testing each supported device platform. Existing Apple Silicon Mac and Vision Pro availability settings remain enabled and unverified; no compatibility declaration was made. Account for these before final submission rather than claiming iPhone testing covers them. |

## Work the agent can perform

**Now:** inspect device/OS/lock/app metadata read-only, verify release artifacts, prepare this sequence, and preserve browser review evidence. No storefront selection is made while Nick's answer is pending.

**After unlock/USB access:** list and copy only SignalScout's app-data container to ignored local evidence, hash its files, and inspect the preview key. No data is written back to the device. A local helper, `release-evidence/read_physical_fixture.py --device <paired identifier> --backup-state`, implements these scoped reads and stops on an error. Its syntax/help are verified; no successful physical backup is claimed.

**After an authorized build update and compatible device services:** verify installed identity, launch/observe/log the free build, and run appropriate device checks that do not reset the fixture. Xcode 26.5's ability to automate a phone after its iOS 27 update is not yet verified. TestFlight recording remains possible independently of Xcode UI automation. Physical movement, phone-only controls/passcodes, and the genuine demonstration require Nick's participation.

**After receiving the genuine recording:** inspect the video and its actual duration/contents, attach it or verify a reviewer-accessible link, replace the pending-recording paragraph with actual device/OS/build/results, prepare the same six-part reply, verify the chosen storefronts and final one-app/no-IAP item set, and resubmit when the remaining gates are satisfied. Separate cloud refinement remains deferred.
