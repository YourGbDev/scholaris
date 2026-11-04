# Scholaris mascot refinement

Reference UI/source baseline: b45f1a3a43ff0b91d3a93856d9cb3d94b4f3990a. Only mascot PNGs and artwork documentation changed; no application source, typography, spacing, layout, navigation, authentication or mascot-routing code was changed. Existing unrelated landing/readiness modifications and archives are preserved. The separate typography revert already present at baseline was left untouched.

## Approved change

Deeper emerald gowns/caps, subtly warmer brown skin and vivid gold trim, matching the approved right-hand preview. Restore the missing long front gold bands on the female discovery/companion and Ari explaining artwork. Retain all original canvas sizes, identities, poses, props and alpha backgrounds. The source companion/discovery drawings were more head-heavy than the welcome pair; the image edits bring their styling closer while preserving the UI's contained, unstretched image layout. No numerical claim of an exact body-proportion correction is made.

## Coverage and method

All22 files under assets/mascots/: shared welcome pair, Home/tour portraits, all six Chat poses, all four feature-onboarding poses, the existing welcome illustration and eight emotional poses. Existing shared asset resolution makes the changes available to each consuming screen automatically.

Seven individual edits were generated with the built-in image tool, supplying eight file paths because Ari's greeting and Chat welcome are shared. The tool then reached its daily limit. The user explicitly approved completing the remaining14 files with direct edits, preserving the original poses and every alpha pixel. Direct treatment changes only green and skin color ranges, preserves non-target colors, and adds front trim to Ari's explaining pose. No CLI/API fallback or API key was used.

Generation prompt: edit the source illustration with real alpha, keep identity/expression/props/framing, match the canonical pair's deep emerald and warm brown skin, retain vivid gold/white, and include two continuous gold front bands. The two flagged onboarding edits additionally reference the pair's more balanced head/torso proportions. [Output source identifiers](evidence/generation-sources.json).

## Review

[28 matched before/after screen comparisons](index.html): welcome, all four onboarding features, login/errors, Home at320/390px and100%/200% text, shared cards/dialogs and role previews. The latter surfaces are controls for unexpected changes. Screenshots are desktop Flutter-test renders, not native platform proof. Exported panels are verified pixel-identical to their source captures.

[Asset verification](evidence/asset-verification.json): all22 preserve their original width/height and retain transparency; all14 direct edits preserve every original alpha pixel. Generated artwork was visually checked for the intended pose, props, full gold bands and clean cutouts. Shared greeting and Chat identity tests, loading states and narrow/enlarged-text screen checks were run. [Unrelated/source preservation](evidence/preservation.json).

The user subsequently authorized committing/pushing this asset update and handing it to Archi for a new IPA. Geist Sans is now the explicit universal font decision; AGENTS.md was corrected to match the already implemented font revert. No IPA was built by this task. Genuine iOS/Android visual confirmation remains pending until a new build is installed.
