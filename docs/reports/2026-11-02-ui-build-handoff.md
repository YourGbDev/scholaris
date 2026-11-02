# UI source handoff for Archi — November 2, 2026

Build source: branch `codex/auth-tour-polish`, using the UI commit that contains this report (based on61476a5). The commit hash is provided in the chat handoff; verify the remote branch resolves to it before making a release commit.

Approved scope: compact bundled Geist across student/provider/super-admin/landing, neutral cards and responsive hierarchy, friendly campus hero, new five-page welcome/onboarding, minimalist student login with larger mascot pair, five new transparent mascot assets. AI/merged companion tools are not implemented; the introduction labels those features Coming soon.

Pre-push verification:1,247 passed,6 skipped,6 known baseline failures in full Flutter suite (admin audit-write3; scholarship/matching order3). These were previously reproduced on unchanged source. Analyzer has no errors/warnings and12 informational lints. CAPTCHA workflow configuration check, landing JavaScript syntax and staged whitespace checks pass. Rendered phone/desktop/enlarged-text evidence accompanies the design reports. Physical-device CAPTCHA/login remains pending.

## IPA requirements

- Prefer `.github/workflows/build_ios.yml`, manually dispatched against the intended committed release branch/commit with `captcha_enabled=true`. No workflow was dispatched by this UI task.
- Use production `lib/main.dart`, never a `lib/dev` preview target. The new entry preview deliberately initializes no live backend and is not a release entry point.
- Current source metadata remains `1.0.0+25`. Verify the next unused iOS build number before packaging; bump it in a committed release change if needed, preserving the UI commit in its ancestry. Do not reuse a previous build number or assume the next number without checking existing releases/runs.
- Preserve the configured CAPTCHA site key, native challenge WebView, production challenge-page URL and Supabase requirements. Every IPA must compile with CAPTCHA enabled. Follow AGENTS.md for all required defines and verify the actual compiler log, not just defaults.
- Run the CAPTCHA configuration and gate/mobile protocol checks. Complete CAPTCHA and real login on a physical device when available. If unavailable, report that verification as pending.
- Final build handoff must include UI source SHA, exact release SHA, version/build, workflow run, IPA location and SHA-256, CAPTCHA build-log evidence, and physical-device login status. Preserve old archives and unrelated workspace work.

Existing signed-out startup routing still opens onboarding regardless of persisted completion; direct login, signed-in destinations and recovery routes retain their prior policy. This visual task did not change that policy.
