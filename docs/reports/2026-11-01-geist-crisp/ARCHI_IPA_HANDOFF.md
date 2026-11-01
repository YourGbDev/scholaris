# Archi: next Scholaris IPA with approved Geist typography

User authorized a new IPA on November2,2026. Read AGENTS.md before building.

## Integrate the correct source

Typography is on `codex/open-runde-typography`; use the final typography commit supplied in the Codex handoff. This branch starts from build17. Do NOT build it alone as the next release: latest successful IPA source observed is `codex/auth-tour-polish` at `8a96fc11423441549cb2efb2586fdf080a8b740c`, version1.0.0+19, workflow run41207862991.

Fetch current remote refs and integrate the typography commit into the newest intended release source. Preserve all later auth, CAPTCHA, inactivity, tour and other readiness fixes. Resolve conflicts by retaining the approved Geist family, actual400–800 faces, strong800 titles,600 supporting text,700 eligibility/stat labels and current tracking. Review the resulting diff and rerun relevant checks. Do not replace the release branch with the older typography branch. Record the exact resulting release SHA.

## CAPTCHA is mandatory

Prefer `.github/workflows/build_ios.yml`, explicitly selecting the intended release ref and `captcha_enabled=true`. Build the production entry point, never a dev preview. Keep the existing configured site key, native CAPTCHA WebView, challenge page and Supabase enforcement intact.

The actual Flutter compiler invocation must include:

- `SCHOLARIS_CAPTCHA_ENABLED=true`
- `SCHOLARIS_CAPTCHA_SITE_KEY` equal to the existing configured key (do not invent or substitute one)
- `SCHOLARIS_CAPTCHA_PAGE_URL=https://scholaris-captcha.pages.dev/captcha_challenge`

Run `node tools/test_ios_captcha_build_config.mjs` plus `test/captcha_gate_test.dart` and `test/captcha_mobile_protocol_test.dart`. Inspect actual verbose compiler/build-log settings; defaults and a successful archive alone are not proof. Do not disable CAPTCHA to work around login problems.

## Version and delivery

Use the next unused build number after checking current runs/releases. Build20 is the next candidate after observed build19, not a reservation. Preserve all older IPA/ZIP archives.

Return exact source/release SHA, version/build, workflow URL, IPA download/local location, SHA-256 and CAPTCHA compiler-log evidence. Complete CAPTCHA and sign in on a physical iPhone if available; otherwise mark physical-device CAPTCHA/login verification PENDING and have the user test. Do not claim successful login from mocked tests.

## Verification caveat

Focused typography/layout/navigation checks passed. A full-suite audit surfaced seven failures also reproduced on unchanged HEAD: four admin audit assertions plus auth-boundary matching, matches-provider and scholarship-repository tests. They are not typography regressions. Matching/date fixtures need separate investigation; do not report the whole suite green. The old rounded-theme expectation and nav-label animation issue found by the audit were corrected in this typography change.
