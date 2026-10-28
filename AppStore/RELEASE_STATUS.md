# Signal Scout release status

Updated October 28, 2026 (Pacific). The native app verification completed October 27 at approximately 10:09 PM Pacific. This page separates dated evidence from live Apple status. It does not claim a new upload, approval, or release.

## Repair integration

- [PR #3](https://github.com/nickvan23-lang/signal-scout/pull/3) is merged into `main` at `a4a8f71bd8a3ef03de43605ab4aecc81f2968732`. Its complete source tree matches the passing native-test checkout. The corrected app logic is now on the default branch.
- [PR #4](https://github.com/nickvan23-lang/signal-scout/pull/4) is merged into the existing experimental Duo branch at `91d4b589762223713c1bf626cded0d1d197b8880`. [Run 40636901678](https://github.com/nickvan23-lang/signal-scout/actions/runs/40636901678) passed all 13 portable checks and built/installed a fresh candidate. It then failed explicitly at the first cover-portrait pose because `hingeAngle` was unavailable. The [native receipt](../docs/evidence/2026-10-27/duo-ci-40636901678.json) preserves the distinction between working build/install and incomplete fold verification. This experimental branch does not yet contain the app fixes merged in PR #3.
- App Store Connect presents Apple account sign-in in the available browser. A secure sign-in attempt timed out, and authenticated access was not established by the recovery check. No authenticated submission state, new build-number availability, or upload has been verified in this session.

## Latest recorded release

| Item | Evidence and limit |
| --- | --- |
| App | Signal Scout - BLE Finder; Apple app ID `6810531496`; bundle ID `com.nicholasvandervelden.SignalScout` |
| Latest recorded submitted binary | Version **1.3 (8)** |
| Submission | The [October 9 README record](https://github.com/nickvan23-lang/signal-scout/blob/7de6ed0c468cbe33216ccd6fa80b30b671218d41/README.md) records submission on October 9, 2026 at **10:47 AM Pacific**, with **Waiting for Review** and automatic release after approval. This is a dated repository record, not a fresh App Store Connect observation. |
| Current private review status | **Unverified in this investigation.** Check this exact app in [App Store Connect](https://appstoreconnect.apple.com/apps/6810531496). Do not infer approval, rejection, or continued waiting from absent email or a public lookup. |
| Public U.S. catalog check | On October 27 Pacific, Apple's [lookup for this exact app ID](https://itunes.apple.com/lookup?id=6810531496&country=us&entity=software) returned HTTP success with `resultCount: 0`. This establishes no U.S. catalog result at that check, not the private review state or availability in every storefront. |
| Product behavior in current source | All features free; no purchase, subscription, account, or time limit. Broadcast device names and manufacturer identifiers may appear and stay in memory on the phone. |
| Physical BLE validation | **Incomplete for the submitted build.** The October 9 record explicitly discloses this and the earlier requested latest-OS physical-device recording. A successful simulator run is not radio verification. |

## What the automated evidence establishes

- [October 27 repair verification](https://github.com/nickvan23-lang/signal-scout/actions/runs/40635520267/job/122641465486): **46 production core checks and all 28 native tests passed: 24 unit, four UI, zero failed, zero skipped.** Xcode 26.6 ran an iPhone 17 Pro Max simulator on iOS 26.5. The tested PR head is `573699002f3c538ccf042f2628c0368dfd5ff75d`; the actual PR merge checkout is `d886adee14f77be516b6cb805b5c2de04aed6e58`. The [public CI receipt](../docs/evidence/2026-10-27/native-ci-40635520267.json) records the source and results. This validates the signal-analysis repairs and pause/resume regression in the simulator; it does not establish physical radio reception, a signed distribution archive, or Apple approval.
- [October 9 build-8 run](https://github.com/nickvan23-lang/signal-scout/actions/runs/37959810850): 22 core checks, 17 unit tests, and 3 UI tests passed. Preview and two screenshot sizes completed; another simulator's boot timeout made the overall capture workflow fail.
- [October 24 verification](https://github.com/nickvan23-lang/signal-scout/actions/runs/40115239286): 17 unit tests and 3 UI tests passed; an **unsigned** Release archive completed. This does not establish distribution signing, upload, live BLE reception, or fold-transition coverage.
- [Latest October 24 fold capture](https://github.com/nickvan23-lang/signal-scout/actions/runs/40126675261): simulator installation succeeded, then the initial `duoctl state` command timed out. This failed the capture harness before screenshots; it is not evidence of an app crash.
- The October 27 investigation found signal-analysis edge cases that the earlier test inputs did not cover. The new tests reproduce the original failures and pass with the repairs. See [the diagnosis](../docs/DIAGNOSIS-2026-10-27.md) for changes and verification boundaries.

The repair workflow also passed its portable release and website checks. Preview recording and extra screenshot sizes were intentionally skipped for this pull request; the native test suite had no skipped cases.

## Signed-release capability

The repository has a working simulator verification workflow, but no automated signed iOS release route was found in the inspected workflow and script files. `ios-release-qa.yml` explicitly sets `CODE_SIGNING_ALLOWED=NO` and runs tests; it does not archive, export, or upload an App Store binary. The Pages workflow publishes the support site only.

`ExportOptions-AppStore.plist` and `ExportOptions-Upload.plist` retain Xcode settings for automatic signing and App Store export/upload. These configuration files are useful inputs for an authenticated Xcode release on a Mac; they do not provide a signing identity, provisioning profile, or App Store Connect authentication. No credential stores were inspected to infer that those capabilities exist.

The current execution environment can compile the portable Swift core on Linux and can run simulator CI on a hosted Mac. It has no connected Mac/Xcode control service or authenticated signing/upload route available for producing the repaired distribution binary. The next release requires access to a Mac or configured release runner with the app's authorized distribution signing identity, matching provisioning, and App Store Connect authentication. The source still specifies build **8**; verify the existing Apple build inventory before selecting an unused number for the corrected binary. The older unsigned experimental build does not establish that a number is free or that a signed release exists.

## Next release steps

1. Open the app in App Store Connect and record the current version, selected build, review state, and actual reviewer messages. Resolve current requests rather than assuming September's paid-build tasks still apply.
2. Establish the signed-release capabilities above, choose an unused build number, create and verify a new signed distribution archive containing the tested repairs, and install that exact candidate on an iPhone while preserving existing user data.
3. Verify real BLE discovery, names and missing-name behavior, slow/fast changing signals, pause/resume, Bluetooth off/on, signal loss/recovery, and warmer/colder behavior. Record device model, OS, build, steps, and actual outcomes.
4. Complete any still-required physical-device recording on the OS requested by Apple. Keep simulated-data demonstrations explicitly labeled.
5. Verify the current free product-page text, screenshots, privacy answers, storefronts, and Mac/Vision compatibility against the actual build and existing user decisions. Do not change legal declarations or availability based on an obsolete checklist.
6. Upload and submit only after those checks. Record the submission receipt and later approval or release separately.

## Historical documents

[VERIFICATION.md](VERIFICATION.md), [SUBMISSION_CHECKLIST.md](SUBMISSION_CHECKLIST.md), and [metadata.md](metadata.md) preserve the **September paid build 1.3 (4)**. Their subscription, 60-second preview, anonymous-only identity, and pre-submission statements are historical. They are not the current launch instructions.

The older free-access draft PR and the Signal Scout entry in the October work-tracker snapshot describe build 5. Although the tracker file was updated after October 9, this entry retains older build-5 observations; it does not supersede the October 9 build-8 submission record. Preserve the observation dates rather than treating a file's later modification date as fresh release evidence.
