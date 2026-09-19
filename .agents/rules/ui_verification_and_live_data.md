# UI Verification, Real Browser Validation, and Live Data Integrity

## Core Principles

1. **Passing `flutter test` and `flutter analyze` is NOT sufficient proof of UI correctness.**
   - Headless widget tests render text using the `Ahem` font (uniform square blocks) and do not emulate real browser font rendering, kerning, or word wrapping.
   - Proportional fonts (e.g. Outfit, Poppins, Open Sans) in a live browser frequently trigger `RenderFlex` overflows that headless tests cannot detect.
   - Flutter web platform incompatibilities (such as `dart:io` `File` references throwing `Unsupported operation: _Namespace`) never manifest in headless VM tests.

2. **Mandatory Real-Browser Viewport Verification**:
   - Before reporting any UI fix or screen implementation as complete, verify it in an actual browser at the requested viewport dimensions (e.g., iPhone 16 Pro Max 440×956, 360px mobile, 1280px desktop).
   - Check the browser console directly for runtime exceptions and `RenderFlex overflowed by X pixels` warnings.

3. **Live Data Integrity**:
   - Never render placeholder or mock data as if it represents genuine user-entered or verified state.
   - Completion badges, readiness counts, and verified statuses must bind directly to live model fields (`profile.gpa`, `profile.school`, draft storage) rather than hardcoded strings or static placeholders.
   - Uncompleted requirements must clearly display as incomplete and remain interactive/editable so users can fulfill them.

4. **Navigation & Redirect Guard Rigor**:
   - Verify route redirect logic against the complete state matrix (`isLoggedIn`, `profileComplete`, `role`).
   - Ensure specific routes (e.g., `/scholarship/:id`, `/application/:id`, `/discover`) are not masked or prematurely redirected.
