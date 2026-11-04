# Scholaris current UI typography recovery

This supersedes Build30's release source and the earlier typography screenshots as evidence for the current UI. Do not rebuild commit2145caa or ee24041.

## Correct reference

Latest application UI: **78c377810df0ce3fd37e4f50fc663566fc2e31b4**, codex/auth-tour-polish. This includes Build29's student entry/open mascot hero and the subsequent provider/admin neutral-workspace polish. The faulty typography branch had started at Build17 (1804904). The recovery restores the latest product source, behavior, assets and tests, then reapplies centralized typography. Landing and unrelated reports remain untouched; this is a product-source restoration, not a wholesale merge of unrelated landing/docs work.

## Typography retained

Native iOS: supported CupertinoSystemText/CupertinoSystemDisplay SF Pro proxies, chosen by size. Web is checked first and always uses genuine bundled Inter400/500/600/700, including iOS Safari; Android/other native platforms use Inter. No SF Pro Rounded, Nunito, Geist font helper or independent app-owned weight definitions. Retained old font assets are unregistered.

700: display, screenTitle, metric. 600: sectionTitle, cardTitle, button. 500: bodyEmphasis, label, navigation, badge. 400: subtitle, body, caption, input, placeholder.

Latest helper defaults were expanded explicitly to preserve existing font sizes, heights, tracking and colors. No layout, spacing, icon, animation, asset, business-logic or navigation redesign. Restored source includes the matching existing CAPTCHA protocol/challenge implementation and existing unlock migration; no database migration or deployment was executed.

## Evidence

- [28 matched PNG comparisons](index.html), also available individually under comparisons/. Before: correct latest UI with Geist. After: restored UI with Inter, Flutter desktop test rendering. Matched content, viewport, appearance and scale; Home includes320/390px at100%/200%. Exported panels verified pixel-identical to source captures. Images are explicitly awaited to finish decoding; icon fonts loaded.
- [Source preservation](evidence/structure-verification.json):229/229 application files preserve non-typography tokens compared with latest UI. Imports, typography expressions/parameters, formatting commas and constant-context changes are normalized. Three core theme files, removed legacy app_font and adapted diagnostic panel are separately reviewed. This check does not claim geometric equivalence for text expressions; helper-default review and matched captures cover that.
- All existing tracked tests passed in the workspace run. Complete workspace: **1,338 passed,9 skipped,5 failed**. The five are pre-existing ignored local audit/live tests, not release-tracked tests; all five reproduce on the unchanged correct reference UI: [baseline rerun](evidence/latest-ui-local-test-reproduction.log), [workspace run](evidence/full-suite-final.log). They expect the former hero banner and separate amount Text widgets; current UI already uses the newer hero and rich amount text. Preserved without editing those local files.
- Final post-review focused checks: **92 passed**, including receipt role and provider tracking tests, current entry, tracker/card/nav/guide, shared typography and CAPTCHA. [Log](evidence/final-focused.log).
- Analysis, typography guard, font metadata/license tests and CAPTCHA build guard: verified in accompanying evidence. Production web build uses lib/main.dart.
- [Unrelated-file preservation](evidence/preservation.json): original landing/readiness modifications preserved; no IPA/ZIP archives modified or created.

## Review corrections

Screen-title helper now uses screenTitle700; provider sign-in retains its original inherited tracking of-.4; receipt helper accepts explicit semantic roles, distinguishing a scholarship title600, grant value700 and metadata500. These correct the conversion rather than introduce design changes. Existing title/body sizes and layout remain unchanged. Shared input/chip theme adaptation preserves each existing base style. Historical heavy-weight/font-name assertions were updated to the approved roles, with their size/tracking assertions retained. Old Geist-only tests are replaced by semantic-role, font-metadata and reference-pill tests.

The capture harness initially captured some images before decode; those incomplete captures were replaced. Current comparisons contain loaded artwork and icons.

## Platform status and next IPA

The 28 captures prove the restored UI in desktop rendering with Inter; they do not prove native SF Pro rendering. Genuine iOS/Android captures and browser runtime verification of this recovery remain pending. Native iOS normal/enlarged text, Bold Text, CAPTCHA and login must be checked using the new IPA.

Build the correction commit containing this report, using the production entry point and the next unused build number (inspect all releases; do not assume31 is unused). Prefer .github/workflows/build_ios.yml with captcha_enabled=true and verify the resolved release SHA plus actual compiler CAPTCHA settings. Preserve the existing site key/page, native WebView and server enforcement. Report the exact source/release SHA, version/build, workflow run, IPA location/SHA256 and physical-device verification status. Never disable CAPTCHA. No IPA was built in this correction task.

At320px/200% text, the restored Home naturally grows and scrolls; the viewport capture shows its upper portion. No text-scaling clamp or layout workaround was added. Production artifact verification confirms Inter is the only app-owned font family and its OFL license is included; Material/Cupertino icon fonts are retained.
