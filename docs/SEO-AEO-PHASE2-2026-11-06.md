# Signal Scout: search automation and technical follow-through

Prepared November 6, 2026. This continues the [first SEO/AEO pass](SEO-AEO-2026-11-06.md) for the public [Signal Scout website](https://nickvan23-lang.github.io/signal-scout/). It does not change the native app binary or the published App Store name.

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

Live deployment and notification outcomes must be assessed from the actual workflow run and response receipt; prepared code alone is not proof of a successful external action.
