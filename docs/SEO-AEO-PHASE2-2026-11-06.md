# Signal Scout: search automation and technical follow-through

Prepared November 6, 2026. This continues the [first SEO/AEO pass](SEO-AEO-2026-11-06.md) for the public [Signal Scout website](https://nickvan23-lang.github.io/signal-scout/). It does not change the native app binary or the published App Store name.

## Observed publication outcome

The [Pages workflow](https://github.com/nickvan23-lang/signal-scout/actions/runs/42278946077) completed successfully for commit [`7baafee`](https://github.com/nickvan23-lang/signal-scout/commit/7baafeea9a89b19396aaec0c7339d9f9f8ff50c0). Its metadata checks, deployment, IndexNow notification, and receipt upload all succeeded.

The public key preflight returned HTTP 200. At **2026-11-06 19:22:15 UTC**, the one POST containing six URLs received **HTTP 202, key validation pending**. This establishes receipt of the notification, not completed validation, indexing, ranking, or AI citations. The [exact emitted receipt and provenance](evidence/2026-11-06/indexnow-live-receipt.json) are preserved here beyond the Actions artifact's seven-day retention. No manual duplicate submission was made.

All **11 checked live paths** returned HTTP 200 and matched the deployed commit byte for byte: six HTML pages, the sitemap, the public key, and three responsive images. See the [live verification record](evidence/2026-11-06/phase2-live-verification.json).

Fresh static extraction read the homepage's product facts, download link, FAQs, and all three responsive image candidates. The troubleshooting guide's title, canonical, direct answer, author, and dates were also extracted; the extractor reported no structured-data parsing issues. The [extraction record](evidence/2026-11-06/phase2-extraction.json) preserves field provenance and limitations. A fresh mobile screenshot at a requested 390 × 844 viewport was visually checked: the page, screenshot, buttons, and navigation rendered without visible clipping or overlap. These checks do not measure search visibility or Core Web Vitals.

## Website improvements

- The homepage uses responsive WebP screenshots with the original PNG fallback, explicit dimensions, descriptive alternative text, and the existing simulator-data label.
- Homepage Twitter metadata now matches the current free-app description. Support and privacy have complete social metadata and structured page/breadcrumb descriptions tied to the same app and website identities.
- Privacy includes direct navigation to Home, Support, and the Bluetooth guides. The policy body and effective date are unchanged.
- The SEO checker now also verifies assets referenced by `srcset`. GitHub Pages runs this checker before uploading the site.

| Screenshot | Dimensions | Bytes | Reduction from original PNG |
| --- | --- | ---: | ---: |
| Original PNG fallback | 1320 × 2868 | 389,658 | — |
| WebP, small | 490 × 1065 | 95,918 | 75.4% |
| WebP, medium | 610 × 1325 | 136,716 | 64.9% |
| WebP, large | 915 × 1988 | 225,266 | 42.2% |

The browser chooses a suitable image for the screen and pixel density. These are measured file-size reductions, not measured Core Web Vitals improvements. A public PageSpeed API request returned HTTP 429, so no Lighthouse or PageSpeed score is reported.

## Search-engine notification

The IndexNow key is hosted under this project's `/signal-scout/` path. Submissions specify its `keyLocation`, restricting the authorized URL prefix to this project. This follows [IndexNow's documented non-root verification option](https://www.indexnow.org/documentation).

The [submission script](../scripts/submit_indexnow.py) is a dry run by default. The Pages workflow explicitly submits after a successful deployment and saves a receipt as the `indexnow-receipt` Actions artifact, retained for seven days. A notification failure does not take down a successful site deployment. The sitemap is the submission source; the private-review/demo pages remain excluded.

HTTP 200 means the receiving service accepted the notification. HTTP 202 means key validation is pending. Neither response establishes crawling, indexing, a search ranking, or an AI citation. See the [indexing runbook](INDEXING-2026-11-06.md) for exact scope and operation. An observed live receipt, when available, is recorded separately in `docs/evidence/2026-11-06/`.

## App Store metadata

The [ASO brief](../AppStore/ASO-2026-11-06.md) and [English metadata manifest](../AppStore/aso-en-US.json) prepare field values for App Store Connect. They are drafts. The manifest does not invent App Store Connect localization or version-resource IDs. No authenticated App Store Connect session is available here, so no listing fields or review submission have been changed.

## Account access and measurement

Search Console and Bing Webmaster Tools were not connected to the available Windsor.ai account during this work. Its existing analytics connections did not establish access to this app's search properties. The browser connector also reported that an originating browser context is required.

Consequently, Google property verification, sitemap submission, URL inspection, search-performance reports, and Apple metadata submission remain account-level tasks. IndexNow notification is separate from Google Search Console and Bing Webmaster property verification. No private authorization link or account credential belongs in this repository.

## Validation

- All six public content pages pass `python3 scripts/check_seo.py`.
- All 14 existing checks in `python3 scripts/check_free_release.py` pass. These are source checks, not evidence of a new native binary release.
- Responsive image widths match their `srcset` descriptors; each decoded WebP matches the resized source pixels.
- Structured data parses, local links resolve, and reviewer pages retain `noindex`.
- `git diff --check` passes.

An independent read-only review found no blockers in the website, notification script, workflow, or ASO manifest. The actual live deployment and response evidence above establish the external actions completed in this pass.
