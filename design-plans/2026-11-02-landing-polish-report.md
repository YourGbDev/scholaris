# Landing final polish — 2026-11-02

Scope: `landing/**` in `C:/Users/Windows 11/.codex/worktrees/auth-tour-polish/scholaris`. Root `C:/scholaris/landing` was read and left untouched. No commit, push, Flutter build, IPA or backend change.

## Source choice and inventory

The newer root landing is the content/composition/behavior source of truth. Imported its HTML, CSS, JS, local Lenis runtime/license and only recursively referenced media/font dependencies: 28 files, initially 11,495,405 bytes. The import inventory is `build/landing-polish/import.json`. Excluded unreferenced root screenshots, older films and other mascot variants. Existing unrelated worktree files/assets were preserved.

At parent request, the final five Geist TTFs come from the app's `assets/fonts/geist` in this checkout, including its verified family metadata correction. Root landing font binaries remain untouched. Imported typography CSS registers 400/500/600/700/800 without the stale worktree's blanket 800/600 promotion; icons retain their separate Material Symbols font.

## Changes

- Preserve all copy, page order, scroll story, green accents, mascot art, screenshots, audience switching, media, links and download/pilot behavior.
- Use Geist 700 for titles; prose 400, metadata 500 and controls 600. Hero now uses 700 instead of 800. Hardware labels also use Geist.
- Display tracking -.02em; 20px title role -.3px; 16px title role -.15px; prose 0; uppercase overlines .6px. Remove the prior unusually tight large-title tracking and wide micro-label tracking.
- Neutral pale green-gray paper and white FAQ cards; neutralize decorative secondary blue download surfaces. Keep brand green and existing success meaning.
- FAQ cards follow 26px radius, faint .5px border and soft ambient shadow. Download dialog uses matching 26px corners, viewport-height scrolling and a contained email field.
- At 320px, preserve a single-line header action and wrap the final call-to-action row where needed.
- Correct inherited FAQ initialization selector `& > div` to `:scope > div`; this removes a runtime exception and restores intended first-open/others-closed accordion state.
- Add MP4 and VTT MIME types to the local server, preserving the existing routes.

## Verification evidence

- `node --check landing/landing.js` and `node --check landing/serve.mjs`: passed.
- `git diff --check -- landing`: passed (only repository CRLF conversion notices).
- Headless Chrome normal-motion before/after inspector: `build/landing-polish-before` and `build/landing-polish-after`. Visually inspected desktop/mobile fold and story/footer contact sheets.
- Final reduced-motion Chrome interaction/layout checks at 1440, 768, 440, 390 and 320px: zero page horizontal overflow; all referenced images loaded; FAQ accordion, organization switch, mobile menu and modal behaved as expected; zero JS exceptions. Reports/screenshots: `build/landing-polish/browser-checks.json` and `hero-*`, `faq-*`, `provider-*`, `modal-*` PNGs.
- CDP `CSS.getPlatformFontsForNode` reports custom `Geist-Regular` for real prose; computed heading roles show Geist 700 and the intended tracking. This is rendered font evidence, not inference from the films.
- Keyboard dialog check at 390x700: Shift+Tab stayed within dialog; Escape closed it and removed page inert state. Evidence: `build/landing-polish/keyboard-media-check.json`.
- Both provider films loaded with readyState4, advanced playback time, and no media error. Correct video/caption response types confirmed. Evidence: `build/landing-polish/video-playback-check.json`.
- Ran Impeccable detector once plus taste inspector/lint. Their style-policy reports are not clean: preserved multi-line headlines, overlines, layered phone shadows, hairlines and small device/demo labels trigger the generic house rules. These incumbent design elements are intentionally retained under the explicit refinement brief. Corrected the real issues found: overline contrast/legibility, small explanatory captions and FAQ initialization. Geist and separate icon font are explicit project requirements, overriding generic font warnings.

## Limits and inherited behavior

No physical device or Safari verification; browser checks used Chrome emulation. No 200% text-size verification claimed. Existing app screenshots and concept videos still show their recorded older UI; no media was regenerated. Footer placeholder `#` destinations and the local pilot-request success simulation were preserved; a displayed queue message is not proof of an actual invitation backend. Existing factual copy was retained without adding claims.
