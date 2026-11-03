# Canonical greeting portraits

- `ariel.png`: male Ariel; high-resolution transparent reconstruction of the approved November 3 open-hero pose, using the tracking onboarding art as the face reference and Ari as the gown/linework reference. Generated with the built-in image tool; the source generation is `exec-b7980533-1c6a-41d7-a113-8c162f7c611e.png` in the Codex generated-images session folder.
- `ari.png`: the exact existing Ari welcome portrait from `assets/mascots/chat/ari_welcome.png`, reused as the approved female hero reference.

The generation prompt requests only Ariel, cap to chest, relaxed open-palm wave, natural dark eyes, closed-mouth smile, swept black hair, emerald gown and cap, gold trim/tassel, white shirt and green tie, transparent background, clean curved lower silhouette. No scenery, props, lettering, glow, blur or childlike facial proportions.

Home, the tour greeting and the chat welcome resolve these shared portraits. Welcome/login use welcome_pair.png: a close overlapping pair with one straight lower crop. Ariel is visibly taller, using 5 foot 11 versus Ari at 5 foot 3 as stature references. Chat retains the opposite-companion identity rule. Feature onboarding keeps its explanatory poses; their green palette is aligned to Ari by `flutter test tools/prepare_mascot_palette.dart`. That explicit asset-preparation command preserves non-green skin, gold and alpha; it is not part of the test suite.

`greeting_mascot.dart` contains portrait-specific normalized wrist/head pivots. If an asset's framing changes, update its rig and stationary hair/shoulder checks. Runtime motion is Flutter code, not a generated video or GIF. Greeting duration is 2.8 seconds followed by three seconds of rest. Honor reduced motion, inactive tabs and app lifecycle.

Keep these character faces/proportions as the reference for future poses; do not independently reinterpret the welcome faces again.

Combined pair: built-in image tool edit of approved exec-122a015c-7299-4e06-8cdc-5e3c191b4d3b.png. Final height edit exec-b58cc7c4-c821-4567-81e0-588668986c0d.png.
Prompt: preserve exact faces, existing smiles, emerald/gold palette, close overlapping pose and straight bottom; adjust relative stature to male 5 foot 11 and female 5 foot 3, natural adult head sizes, transparent background. Keep Ariel's closed-mouth smile.

November 3 follow-up: user approved the warm toothy-smile pair (exec-dfe89d22-9de3-469a-b556-0f00d8bd59e3.png) for student welcome/onboarding/login and landing. It supersedes the earlier closed-mouth expression. Pose, height difference and straight shared crop remain.

The same approved toothy smile is applied to solo ariel.png via built-in edit exec-ef2bda75-5491-41de-9750-342c38e36625.png. Prompt: change only the smile/cheeks/eyebrows to match the approved pair; preserve solo framing, head/hand/shoulder positions, emerald/gold palette and transparent cutout for the existing animation rig.
