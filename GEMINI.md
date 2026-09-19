# Scholaris Project Guidelines & Reusable Rules

## 1. UI Verification & Real Browser Validation

- **`flutter test` and `flutter analyze` are NOT sufficient proof of UI correctness**:
  - Headless widget tests render text with the fixed-width `Ahem` font where all glyphs are identical square blocks. Real browser engines render proportional typography (e.g. Google Fonts Outfit, Poppins, Open Sans) which takes up substantially different width and line heights.
  - Headless tests do not execute browser DOM lifecycle or web-specific dart compilation rules (e.g. `dart:io` `File` operations crash on Flutter Web with `Unsupported operation: _Namespace`).
- **Mandatory Real-Browser Viewport Checks**:
  - Before declaring any UI fix or feature complete, verify the layout in an actual browser environment at target viewport sizes (e.g., narrow mobile 360px, iPhone 16 Pro Max 440×956, tablet, and desktop).
  - Actively inspect browser console logs for live `RenderFlex overflowed` warnings and unhandled exceptions.
- **Defensive Flex Layouts**:
  - Always guard text inside rows with `Flexible` or `Expanded`, specify `maxLines` and `overflow: TextOverflow.ellipsis`, and use `FittedBox(fit: BoxFit.scaleDown)` on constrained action buttons or chips to guarantee responsiveness across variable font metrics.

---

## 2. Live Data Integrity & Completion Badges

- **Never render placeholder or mock data as completed user state**:
  - Do not hardcode "verified", "ready", "synced", or completed states (e.g. fake "748/750 words", hardcoded academic transcripts, static recommenders).
  - All completion indicators, progress bars, and packet badges must strictly bind to live student profile attributes (`profile.gpa`, `profile.school`) and real saved draft contents.
- **Uncompleted Items Must Remain Actionable**:
  - If a student has not uploaded a transcript, written an essay, or requested a recommendation, the item must display as "Incomplete" / "Missing" and provide a clickable, editable path for the user to complete it.
  - Form fields (such as personal statements and essays) must remain open for editing regardless of word count or draft status.

---

## 3. Router Guard & Navigation Verification

- **Comprehensive Route Matrix Checks**:
  - Never report router or navigation fixes without tracing the full redirect decision tree across all auth states (`isLoggedIn: true/false`, `profileComplete: true/false`, `role: student/provider/admin`).
  - Ensure deep-linked routes (such as `/scholarship/:id`, `/application/:id`, `/discover`, `/tracker`, `/profile`) are explicitly whitelisted and do not inadvertently bounce valid authenticated users back to `/home`.
