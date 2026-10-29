# Student navbar: reference comparison after owner rejection

Scope: inspection only, no further product edits in this pass. Current navbar is functionally verified, but owner has rejected its visual/interaction fidelity. Do not treat 39 passing tests as material/motion acceptance.

## Evidence inspected

- Original supplied recording 20261026-1814-33.0572804.mp4: ffprobe confirms 520x1024, 30fps. Extracted 15 consecutive footer frames from 4.3 through approximately 4.77 seconds: scratch/tarsi-video-review/collapse-30fps-detail.jpg. These are actual video frames, not generated mockups.
- Earlier 10fps collapse contact, tab entrance contact, tight material video contact, and supplied pale navbar screenshot codex-clipboard-848d2923-616e-4170-8bf1-80402c7ed65b.png.
- Actual current CUA5032 screenshot and new vibrant-band inspection: scratch/navbar-comparison-scholaris-color.jpg. Compared pale and colorful conditions; different background content means this is qualitative, not a pixel-error measurement.
- Current source StudentBottomNav, StudentSelectionIndicator, shared LiquidGlass and opt-in StudentGlassRefraction.

## Concrete gaps

1. Outer silhouette: reference has a distinct fine gray perimeter on pale content and bright rim on color. Our nearly white perimeter disappears against pale content. Merely reducing fill opacity did not establish the same edge/depth.
2. Selected surface: reference is a broad stadium, relatively neutral on pale content and transmitting the purple/orange beneath it on color. Our selection uses opaque #E7ECE8, so it remains a solid sage patch. Its narrow, near-circular proportions compound the difference.
3. Optical appearance: reference has visible localized distortion/magnification near rims. Our production material is a blur plus white veil and saturation adjustment. The refraction experiment is default-off and unsupported by this browser path; no native renderer verification has occurred. We cannot infer Tarsi's implementation stack from appearance.
4. Motion: reference selection shows a substantial transient bulge/overhang in the supplied frames. Our stretch is capped at 12px horizontally/2px vertically and is constrained inside an outer ClipRRect. It cannot reproduce that silhouette. Our collapse uses a steep cubic width curve and removes labels/inactive items by 25% geometric collapse; the disappearance is correspondingly abrupt. Exact reference label timing remains a frame-analysis question, not a measured constant here.
5. Quick action: consecutive reference frames show + becoming smaller along with the compact selected control. Ours deliberately keeps +58px. Its position can remain fixed while the visible circle changes size; these are separate design properties.
6. Compact finish: ours introduces a separate 44px opaque inner sage disc when reaching the 52px endpoint. The reference reads as a single translucent circle, so the endpoint treatment still changes abruptly even though icon travel is now connected.
7. Icons: current Cupertino house_alt has a sharper roof/chimney and doc_text is a different silhouette from the reference. Consistent outline weight helped, but it is not an exact icon match.

## Diagnosis and next bounded correction

Previous work optimized behavior and test coverage, then treated those checks as enough to present a visual refinement. The material and endpoint composition were never close enough; tiny parameter changes could not close those structural gaps.

Prioritize a navbar-local surface with a visible neutral rim, translucent broader selection and no new opaque compact disc; retain Scholaris green foreground. Then coordinate visible dock/+ sizing and a genuinely visible, interruptible selection deformation while keeping hit targets and stable content clearance. Compare the same pale and colorful conditions before calling appearance ready. Native optical refraction stays explicitly unverified; do not promise it from a blur-only web preview. Keep large-text reflow, keyboard restoration, reduced motion and tab state intact. No backend/content redesign/dependency/remote/build changes.
