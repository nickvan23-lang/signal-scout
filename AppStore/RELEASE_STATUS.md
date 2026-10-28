# Signal Scout release status

Reconciled October 27, 2026 (Pacific). This page separates dated evidence from live Apple status. It does not claim a new upload, approval, or release.

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

- [October 9 build-8 run](https://github.com/nickvan23-lang/signal-scout/actions/runs/37959810850): 22 core checks, 17 unit tests, and 3 UI tests passed. Preview and two screenshot sizes completed; another simulator's boot timeout made the overall capture workflow fail.
- [October 24 verification](https://github.com/nickvan23-lang/signal-scout/actions/runs/40115239286): 17 unit tests and 3 UI tests passed; an **unsigned** Release archive completed. This does not establish distribution signing, upload, live BLE reception, or fold-transition coverage.
- [Latest October 24 fold capture](https://github.com/nickvan23-lang/signal-scout/actions/runs/40126675261): simulator installation succeeded, then the initial `duoctl state` command timed out. This failed the capture harness before screenshots; it is not evidence of an app crash.
- The October 27 investigation found signal-analysis edge cases that the earlier test inputs did not cover. Earlier green tests do not validate the proposed fixes. See [the diagnosis](../docs/DIAGNOSIS-2026-10-27.md) for changes and verification boundaries.

## Next release steps

1. Review the diagnostic changes and run the native unit/UI workflow on their exact source revision.
2. Open the app in App Store Connect and record the current version, selected build, review state, and actual reviewer messages. Resolve current requests rather than assuming September's paid-build tasks still apply.
3. For a build containing source changes, choose an unused build number, create and verify a new signed distribution archive, and install that exact candidate on an iPhone while preserving existing user data.
4. Verify real BLE discovery, names and missing-name behavior, slow/fast changing signals, pause/resume, Bluetooth off/on, signal loss/recovery, and warmer/colder behavior. Record device model, OS, build, steps, and actual outcomes.
5. Complete any still-required physical-device recording on the OS requested by Apple. Keep simulated-data demonstrations explicitly labeled.
6. Verify the current free product-page text, screenshots, privacy answers, storefronts, and Mac/Vision compatibility against the actual build and existing user decisions. Do not change legal declarations or availability based on an obsolete checklist.
7. Upload and submit only after those checks. Record the submission receipt and later approval or release separately.

## Historical documents

[VERIFICATION.md](VERIFICATION.md), [SUBMISSION_CHECKLIST.md](SUBMISSION_CHECKLIST.md), and [metadata.md](metadata.md) preserve the **September paid build 1.3 (4)**. Their subscription, 60-second preview, anonymous-only identity, and pre-submission statements are historical. They are not the current launch instructions.

The older open free-access draft PR and October work-tracker snapshot describe build 5 and predate the October 9 build-8 submission record. Preserve their evidence dates when consulting them.
