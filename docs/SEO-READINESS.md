# Signal Scout SEO readiness

Prepared October 9, 2026. These changes are on the local website branch and are not deployed. Existing build-6 reviewer video routes are preserved.

## Search intent and pages

| Page | Primary intent | Supporting questions |
| --- | --- | --- |
| Home | Bluetooth signal finder for iPhone | What does the app do? Is my BLE accessory compatible? Is it available? |
| Support | Bluetooth finder not showing devices | Permission, advertising state, device names and manufacturer details, lost signals, RSSI meaning |
| Privacy | Signal Scout privacy | On-device analysis, no location permission, no signal uploads |

The copy explains actively advertising BLE and the limits of RSSI. It does not promise exact locations, universal headphone compatibility, or powered-off discovery. It uses ordinary language rather than keyword repetition.

## Prepared technical work

- Unique page titles and descriptions, one H1 per page, meaningful section headings and internal links.
- Absolute HTTPS canonical URLs for the GitHub Pages project path.
- Open Graph and social cards using the real app icon; meaningful alt text, explicit image dimensions, lazy loading below the fold.
- Static HTML and system fonts; no JavaScript dependency for navigation, content, or FAQ access.
- Native FAQ disclosure controls, keyboard focus, skip navigation, reduced-motion handling, responsive layout.
- WebSite / WebPage structured data describing the real product. No fabricated ratings, reviews, downloads, or ranking promises. No FAQ rich-result claims.
- Sitemap includes home, support, privacy. Reviewer page remains `noindex` and is excluded.

## Publication checklist

1. Deploy only the website changes after reviewing the local preview. Do not replace build 6 or its video while it is under review.
2. Verify all canonical URLs, image URLs, linked anchors, and sitemap return success on the deployed origin. Inspect mobile layout and loading again there.
3. Verify the URL-prefix property `https://nickvan23-lang.github.io/signal-scout/` in Google Search Console using an owner-authorized method, then submit `sitemap.xml`. No Search Console verification or indexing request has been performed in this work.
4. A robots.txt file is read at the host root, `https://nickvan23-lang.github.io/robots.txt`, not this project's `/signal-scout/robots.txt`. Do not add a misleading project-local robots.txt and call it active. Reviewer HTML uses its existing `noindex` directive.
5. Once Apple approves and the app is publicly released, replace the pending-review notice with the verified App Store download URL. Only then add the official badge and any app-install metadata that implies availability.
6. After publication, use Search Console impressions, relevant queries, click-through rates, indexing status, and Core Web Vitals to evaluate changes. No ranking or indexing result is claimed.

## Sources

- Google SEO Starter Guide: https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- Google canonical URL guidance: https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- Google robots.txt guidance: https://developers.google.com/search/docs/crawling-indexing/robots/create-robots-txt
- Apple product-page guidance: https://developer.apple.com/app-store/product-page/

## Screenshot boundary

The default page uses the real app icon and a labeled illustrative Bluetooth reading, rather than showing obsolete anonymous-device screenshots as if they reflected the new named-device behavior. The original build-6 reviewer movie remains unchanged and is not advertised as the new release. Updated native screenshots require a working simulator or physical device before they can be used as next-release evidence.

## Measured local verification

The final local page was checked in Chrome DevTools at 320, 390, and 1440 CSS pixels with no observed horizontal overflow or missing images. FAQ click/Enter behavior, help navigation, all support topic anchors, and keyboard Skip to content focusing the main element were verified. The final mobile Lighthouse snapshot scored 100 Accessibility, 100 Best Practices, and 100 SEO (33 checks passed). These automated results do not establish full accessibility compliance, performance scores, indexing, or rankings.

Screenshots: `hero-after.png`, `desktop-after.png`, `mobile-after.png`, and `support-after.png`. Reports: `lighthouse-mobile-snapshot.html`, `lighthouse-mobile-snapshot.json`, `seo-validation.json`.

Local preview: http://127.0.0.1:4175/ . This branch has not been deployed. Names and manufacturer details in this draft describe the next app release, not the submitted build-6 binary or its preserved review video.
