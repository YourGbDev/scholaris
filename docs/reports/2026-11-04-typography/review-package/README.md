# Scholaris typography review package

Prepared for review on 4 November 2026. The implementation is unchanged, uncommitted, and on `codex/typography-refinement`. No visual changes or IPA build were made while preparing this package.

## Contents

- **23 lossless side-by-side PNG comparisons** in [comparisons/](comparisons/). Before is on the left, after on the right. Screenshot panels are at their original pixel size, without resampling, and were verified pixel-identical to the source captures. Only white margins and review labels were added outside the panels.
- [Exact names and errors for all seven failing tests](failing-tests.md), with original/current paired excerpts, a fresh original-source rerun log, and source-file hash verification.
- [Narrow-screen/enlarged-text explanation](enlarged-text-limitations.md), naming the affected Home elements and the evidence limits.
- [All 15 semantic roles and Geist-reference audit](typography-confirmation.md), including fresh passing tests and the production font manifest.
- [Working-tree scope and preservation](working-tree.md), with SHA-256 before/after records for all existing changed/untracked files.

## Key findings

The fresh original-source test rerun produced **15 passed, 7 failed**, reproducing all seven exact assertion messages from the migration suite. Original-source verification checks 226 tracked app files and four relevant test files against commit `1804904c45594803989e5d7ec83e5b3ec09d25dd`.

All 15 role weights match the approved mapping. No Geist references remain in app Dart source or pubspec.yaml; the production font manifest has no Geist registration. Retained font files, the separate landing site, historical evidence and negative guard-test strings are intentional. Native rendering checks remain pending.

The working tree is **not clean**: it contains the pre-existing unrelated landing/readiness edits and untracked work. No unexpected tracked modifications were found. Review preparation preserved all 646 existing changed/untracked files byte-for-byte (about 2.56 GB), including 78 IPA/ZIP archives; the already-deleted renamed test path remains deleted. Original pre-migration hashes were not captured, so the report states that historical verification limit explicitly.

## PNG index

| # | Comparison | Viewport | Text scale | Capture type |
|---|---|---|---|---|
| 1 | [admin-320](comparisons/01-admin-320-comparison.png) | 320 × 844 | 100% | Windows Flutter tester |
| 2 | [admin-390](comparisons/02-admin-390-comparison.png) | 390 × 844 | 100% | Windows Flutter tester |
| 3 | [authentication-320](comparisons/03-authentication-320-comparison.png) | 320 × 844 | 100% | Windows Flutter tester |
| 4 | [authentication-390](comparisons/04-authentication-390-comparison.png) | 390 × 844 | 100% | Windows Flutter tester |
| 5 | [authentication-errors-320](comparisons/05-authentication-errors-320-comparison.png) | 320 × 844 | 100% | Windows Flutter tester |
| 6 | [authentication-errors-390](comparisons/06-authentication-errors-390-comparison.png) | 390 × 844 | 100% | Windows Flutter tester |
| 7 | [logout-dialog-320](comparisons/07-logout-dialog-320-comparison.png) | 320 × 844 | 100% | Windows Flutter tester |
| 8 | [logout-dialog-390](comparisons/08-logout-dialog-390-comparison.png) | 390 × 844 | 100% | Windows Flutter tester |
| 9 | [onboarding-320](comparisons/09-onboarding-320-comparison.png) | 320 × 844 | 100% | Windows Flutter tester |
| 10 | [onboarding-390](comparisons/10-onboarding-390-comparison.png) | 390 × 844 | 100% | Windows Flutter tester |
| 11 | [provider-individual-320](comparisons/11-provider-individual-320-comparison.png) | 320 × 844 | 100% | Windows Flutter tester |
| 12 | [provider-individual-390](comparisons/12-provider-individual-390-comparison.png) | 390 × 844 | 100% | Windows Flutter tester |
| 13 | [provider-organization-320](comparisons/13-provider-organization-320-comparison.png) | 320 × 844 | 100% | Windows Flutter tester |
| 14 | [provider-organization-390](comparisons/14-provider-organization-390-comparison.png) | 390 × 844 | 100% | Windows Flutter tester |
| 15 | [scholarship-card-320](comparisons/15-scholarship-card-320-comparison.png) | 320 × 844 | 100% | Windows Flutter tester |
| 16 | [scholarship-card-390](comparisons/16-scholarship-card-390-comparison.png) | 390 × 844 | 100% | Windows Flutter tester |
| 17 | [web-detail-390](comparisons/17-web-detail-390-comparison.png) | 390 × 844 | 100% | Chrome web |
| 18 | [web-discover-390](comparisons/18-web-discover-390-comparison.png) | 390 × 844 | 100% | Chrome web |
| 19 | [web-home-390](comparisons/19-web-home-390-comparison.png) | 390 × 844 | 100% | Chrome web |
| 20 | [web-home-large-text-320](comparisons/20-web-home-large-text-320-comparison.png) | 320 × 844 | 200% | Chrome web |
| 21 | [web-home-narrow-320](comparisons/21-web-home-narrow-320-comparison.png) | 320 × 844 | 100% | Chrome web |
| 22 | [web-profile-390](comparisons/22-web-profile-390-comparison.png) | 390 × 844 | 100% | Chrome web |
| 23 | [web-tracker-390](comparisons/23-web-tracker-390-comparison.png) | 390 × 844 | 100% | Chrome web |

These PNGs are not native iOS/Android evidence. Only the Home web case uses 200% scaling; other comparison images are at 100%. No approval of pending rendering or large-text limitations is implied by the exports.
