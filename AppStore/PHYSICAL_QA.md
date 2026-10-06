# Physical-device QA and reviewer recording

Updated October 6, 2026. Build **1.3 (5)** is installed on the physical iPhone after a verified backup of the old app data. Normal launch succeeded. Feature QA and the latest-OS reviewer recording remain incomplete.

## Approved installation completed

Nick approved an in-place, retained-data build-5 installation on October 6 at 02:16 UTC. This approval persists; no further installation permission is needed. It does not choose storefronts or authorize an OS update or data erase.

After Nick unlocked the phone, the 03:37 UTC preflight verified a live **wired, connected, unlocked** iPhone on **iOS 26.6.1 (23G83)**, with developer services available and SignalScout **1.2 (3)** installed. The old app-data folders were copied and verified before the approved update. The direct installation succeeded at **03:40 UTC**, and an independent app query confirmed **1.3 (5)**. No uninstall or data erase was used.

The installed app is the original tested **Release** archive app, with its existing developer signature and valid `YJTLRBVNSM` wildcard profile containing this phone. The install copy at `/tmp/SignalScout-approved-device-install-20261006/SignalScout.app` passed strict signature verification and matches the tested archive's executable SHA-256. No re-signing, new certificate/profile, device registration, TestFlight invitation, or duplicate upload was needed. The separate App Store IPA remains unchanged.

## Apple's actual request

The [current submission messages](https://appstoreconnect.apple.com/apps/6810531496/distribution/reviewsubmissions/details/5db11dc9-73b3-4102-b7f6-69f12e155e40) still contain the September 10 and September 15 requests. The review item now links build **1.3 (5)**; there is one app-version item and no IAP item. Resubmission remains disabled.

September 10 requires physical-device QA of the submitted build before resubmission, and a recording made on a physical device running the latest OS. The recording must start with app launch and demonstrate the normal user flow. Registration/login/deletion, user-generated content safeguards, and paid features need demonstrations only when the app includes them; build 5 has none of these. Apple specifies no recording duration, resolution, narration, or separate Settings introduction. A simulator recording does not meet the physical-device requirement.

Apple also asks for six items in both an App Review reply and the review Notes: the recording; purpose/audience; setup/main features and any credentials/files; core external services/platforms; regional differences or consistent behavior; and authorization documents if regulated services or protected third-party content are involved. The saved notes cover the free build accurately but still disclose that recording and hardware QA are pending. No reply has been sent.

The September 15 review concerned build 4 on an iPad Air 11-inch (M3), iPadOS 26.6.2. It identifies the description as an objectionable-marketing field without naming a particular offending term, and reports failed purchase/unsubmitted IAP. Build 5 removes the purchase system and has corrected neutral description text; Apple has not accepted those corrections yet.

## Current phone and preserved state

- The current installed app is **1.3 (5)** on an unlocked iPhone 17 Pro Max, verified again after the UI automation attempt at 03:52 UTC. Live device metadata confirms **26.6.1 (23G83)**, Developer Mode enabled, and developer services available.
- The original **1.2 (3)** app-data root listed only `Documents`, `Library`, and `tmp`. All three were copied before installation. The local backup matches the source inventory's **11 files and 15 directories**, file sizes, and its SHA-256 manifest. The backup is retained outside Git in `release-evidence/physical-fixture-20261006T033854142247Z/SignalScout-app-data-original`.
- The original preferences directory was empty: neither `com.nicholasvandervelden.SignalScout.plist` nor the historical `signalScout.preview.startedAt.v1` key existed. There was no genuine expired-preview fixture to claim; the old locked UI was not observed or fabricated.
- Before first launch, the post-update data copy contained seven original files with identical hashes, including all three saved-application-state files. iOS removed four old SplashBoard launch-screen cache images during the update. No other files were removed or changed, and the complete original 11-file backup remains preserved. Documents and preferences were empty before and after installation.

## Current physical QA result

Normal launch of the installed Release app succeeded without fixture arguments at 03:43 UTC and again at 03:53 UTC. This verifies launch-command success, not the scanner's displayed UI or BLE reception.

A dedicated UI-only Xcode runner built successfully using the same existing wildcard profile. XCTest installed its related `SignalScoutPhysicalQA-Runner` companion; its test configuration contains no SignalScout app-installation path or application target, so it did not rebuild or replace the installed Release app. The physical run failed during runner initialization with **`com.apple.dt.XCTest.XCTFuture Code=1000: Timed out while enabling automation mode`**. Xcode records one runner-initialization failure; **no feature test cases ran or passed**. The phone was unlocked both before testing and in the subsequent check; the timeout's cause is not established. No permission/access settings were changed to bypass it.

SignalScout was returned to the foreground with a successful normal-launch command. Nick has been asked what the scanner actually shows. Live reception, map/tracking behavior, movement results, permission/off states, external-link handoffs, and the 65-second physical UI check remain unverified. There is no physical screenshot or video from this attempt. Local evidence includes the install receipt, before/after backups, `retained-data-install-verification.json`, the UI-runner audit, and `physical-ui-currentOS-tests2.xcresult`.

## What Nick needs to do

1. Confirm what the currently launched scanner shows: Bluetooth ready with real signals, ready without signals, or permission/power guidance. Do not uninstall or reset SignalScout.
2. Manually update the phone to the latest public iOS, then reconnect and unlock it. [Apple currently lists iOS 27.0.1](https://support.apple.com/en-us/100100). The app-data backup and retained-data installation are complete; no OS update was started by this workflow.
3. Provide an owned, actively advertising BLE accessory. Wake it; many headphones stop advertising when connected, asleep, or inside a closed case. A visible anonymous advertisement alone does not establish which owned accessory it belongs to.
4. Perform and record the genuine flow below on the updated phone. Use the installed Release build, not the companion UI-test runner. The agent can inspect the resulting evidence, but successful automated touch control has not been established and physical movement requires Nick.
5. Complete the additional permission/off/interruption checks, preserving and restoring their actual starting settings. Enabling new automation/access permissions requires Nick's approval; the initialization timeout does not prove a particular setting is the cause.

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

**Completed:** verify device/OS/lock/app metadata, copy and verify the original app-data folders, install the approved Release build in place, verify its retained state before launch, and launch it normally. No storefront selection was made while Nick's answer is pending.

**For future scoped backups:** `release-evidence/read_physical_fixture.py --device <paired identifier> --backup-state` reads and copies only SignalScout app data. Apple's copy tool rejects the container-root `.` path and requires pre-existing local destination directories; the helper now copies the explicitly listed root entries into newly created local folders. The successful original backup was independently compared against the complete recursive source inventory. No data is written back to the phone.

**Next:** verify the phone's updated OS and installed identity, inspect genuine screenshots/video or Nick's reported results, and investigate the automation timeout if further automated checks are useful. New access/permission settings require Nick's approval. Xcode 26.5's automation compatibility after an iOS 27 update is unverified. Native phone recording does not depend on Xcode UI automation. Physical movement, phone-only controls/passcodes, and the genuine demonstration require Nick's participation.

**After receiving the genuine recording:** inspect the video and its actual duration/contents, attach it or verify a reviewer-accessible link, replace the pending-recording paragraph with actual device/OS/build/results, prepare the same six-part reply, verify the chosen storefronts and final one-app/no-IAP item set, and resubmit when the remaining gates are satisfied. Separate cloud refinement remains deferred.
