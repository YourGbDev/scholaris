# Compact landing typography — 2026-11-02

Scope: only `landing/landing.css` was edited for this task, in the `auth-tour-polish` worktree. The accepted landing composition, wording, image/video assets, and JavaScript were preserved. Existing dirty landing files are the baseline, not newly authored changes from this task. No root-workspace edits, commits, IPA builds, backend work, or new claims/features.

## Hierarchy

- Hero: 66 → 52 px at 1440; 42 → about 34 px at 390 and 30 px at 320. Existing desktop line break retained; phone text uses natural wrapping.
- Section/closing/provider headings: up to 52/43 → 32 px desktop, 24 px phone. Story chapter headings: 28/24 px. Titles retain 700 with modest negative tracking.
- Main descriptive prose: 16 px desktop, 15 px phone, 400 weight and natural tracking; supporting captions 12 px 500 and chapter metadata 13 px 500.
- FAQ controls use 16 px 600. Modal title 24 px 700; footer headings 15 px 700. Relevant content-card heading style is 17 px.
- Header links retain a 44 px target. Enlarged text wraps instead of shrinking; provider grid/flex minimum widths allow reflow. The phone header stays sticky in normal document flow, so a taller header does not cover the opening text.

## Browser evidence

Artifacts: `build/compact-landing/`; baseline artifacts: `build/compact-landing-before/`. Helpers: `build/compact-landing-check.mjs`, `build/compact-landing-extra-check.mjs`, `build/compact-landing-keyboard-check.mjs`, and `build/compact-landing-video-check.mjs`.

- Chrome captures at 1440×900, 390×900, and 320×900; inspected hero, story, closing section, provider preview, FAQ and download modal screenshots.
- Normal and reduced-motion rendering checked. Main browser check verifies no horizontal overflow, decoded images, open FAQ, organization switch, mobile menu, modal bounds/inert background, and absence of console errors.
- Actual Chrome rendered-font inspection (not CSS-family inference) identifies custom `Geist-Bold` title glyphs, `Geist-Regular` prose, `Geist-Medium` metadata, and `Geist-SemiBold` action glyphs.
- 200% text-size simulation at all three widths checks no horizontal overflow; relevant visible navigation/actions/provider/FAQ controls remain at least 44 px high. This is a browser text-size simulation, not a physical phone accessibility test.
- Download modal Shift-Tab focus trap and Escape close pass, restoring the non-inert page. Provider video/caption MIME headers are correct. Both individual/organization videos reach readyState 4 and advance playback without media errors.
- `node --check landing/landing.js` passes; no JavaScript edits were required.

## Intentional exceptions and limits

The approved visual direction was retained; no direction draw or composition replacement was appropriate for this explicitly scoped type refinement. Existing brand accents, preview illustration/shadows, section spacing and content remain. The long existing hero is four lines on narrow phones; its wording was preserved rather than reduced to satisfy a two-line style preference. The closing statement retains its authored multiline composition. Device status bars, screenshot pixels, and small labels inside dimensional preview artwork retain their existing scale; they are not ordinary marketing body copy.

No signup/pilot request was submitted, and application/backend routes were not exercised. Real device text scaling, native login, and IPA verification are outside this task. No new artwork/assets were generated. This report does not claim a full site content/legal/contrast audit.
