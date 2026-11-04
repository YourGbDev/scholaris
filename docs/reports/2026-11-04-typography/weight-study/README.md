# Scholarship-card weight proof

This is an isolated visual study. The running app and production source have not changed.

## The proposed card

Open [card-proof.png](card-proof.png): current Inter on the left, proposed Inter on the right.

The provider's organization name changes from `subtitle` (400) to `label` (500). The reason is semantic: this is identifying metadata, rather than a descriptive sentence. This stays inside the existing approved hierarchy.

| Element | Current | Proposed |
|---|---:|---:|
| Scholarship title | 600 | 600 |
| Provider identity | 400 | 500 |
| Scholarship amount | 700 | 700 |
| Frequency and requirement notes | 400 | 400 |
| Tags/chips | 500 | 500 |
| Actions | 600 | 600 |

Tag styles also use the more precise `badge` role in the prototype; both label and badge are 500, so that correction makes no visual difference.

No font size, line height, tracking, color, padding, dimension, content or layout rule changes. Both cards use locally loaded Inter. The current card reproduction is byte-identical to the existing review screenshot. Pixel differences between current and proposed are confined to the provider-name row (1,393 pixels, bounding rectangle x=61–291, y=123–136). See [pixel audit](pixel-audit.json).

My assessment: the 500-weight provider identity is a subtle improvement in readability and information hierarchy. It does not make the amount itself bolder or change its glyph shapes. This is a candidate for review, not an app-wide change.

## Controlled numerals

Open [numerals-700.png](numerals-700.png). Both genuine bundled fonts use exactly:

- Weight 700, derived from the approved metric role.
- Size 18; line height 1.25; letter spacing −0.4.
- The same color, strings, text scale and Windows Flutter renderer.

The samples include peso amounts and all ten digits. This separates the typeface's numeral shapes from the surrounding card's hierarchy. Neither sample uses artificial bolding or an 800 weight. Native iOS/SF Pro rendering is not represented.

The [original Geist/current Inter reference](../review-package/comparisons/16-scholarship-card-390-comparison.png) is also available. That older full-card comparison changes both family and several role weights, so it should not be treated as a controlled font-only experiment.

## Verification and scope

- Isolated candidate fixture test passed: provider 400→500; title 600 and amount 700 unchanged; every other provider style property unchanged.
- Controlled numeral fixture test passed with equal settings.
- Current card reproduction matches the prior screenshot byte-for-byte.
- SHA-256 checks confirm 403 tracked/current app, test, config and font files remained unchanged. See [source preservation](source-preservation.json).
- Test output: [card prototype](card-candidate-proof.log), [numeral proof](numeral-proof.log).

Only study artifacts and ignored temporary rendering fixtures were created. No app source edits, global weight changes, font substitutions in production, commits, or IPA builds were performed.
