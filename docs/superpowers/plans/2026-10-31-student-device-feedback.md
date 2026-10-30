# Student device feedback implementation plan

**Goal:** Reduce Home hero prominence, simplify Discover, keep deadline/Applied metadata together, and replace the navigation tour with a hands-on sample application guide.

**Architecture:** Keep production Home, Discover and scholarship card components. Use an isolated, in-memory practice widget inside the existing authenticated Home tour layer. No application repository, uploader, file picker, provider write, or real submission is used by the practice flow. Retain per-account local opt-out/completion and Support replay.

**Tech stack:** Existing Flutter, Riverpod and SharedPreferences; no new dependencies or generated artwork.

**Spec:** User device screenshots and feedback, plus the user's explicit selection of a clearly labelled sample application without real uploads or submission. This document records the implementation choices.

## Design and constraints

- Keep the existing illustration identity, female .94 scale, button offset, glass navbar, application banner, and stats. Reduce the normal hero from roughly 290px including cap clearance to roughly 235px through spacing/type adjustments, not screen-wide scaling. Large text may use more height.
- Keep deadline/Applied adjacent as a metadata group; allow wrapping at narrow widths or enlarged text rather than clipping or scaling text down.
- Remove the Active profile criteria quick-bar and duplicate targeted-opportunities subtitle. Retain filters, removable selected-filter chips, Matched for you, sorting, result counts and matching logic.
- Updated user direction: the optional guide is a six-step demonstration controlled only by Next/Back/Skip: View Details → criteria → document controls → Apply now → final review/submit → temporary sample Tracker. Students must not select dummy documents or check practice confirmations. Demo labelling explains nothing is uploaded or sent. Finishing or skipping removes the entire sample; it never enters real Tracker.
- Use the real review flow's concepts: profile/photo readiness, scholarship-specific documents, review, confirmations, then submission/Tracker. No invented signature-typing requirement.
- Exit/back, replay, account switch/auth teardown, small screens and enlarged text must remain usable. Practice choices reset when closed; only guide dismissal/completion is saved locally.
- Follow-up user request: replace Home/Discover profile avatars with Settings shortcuts opening the existing account settings screen. Preserve Profile in the dock. Collapsed selected-tab icon must remain the same green outline throughout collapse/expand, with existing glass and spacing intact.
- Do not commit, push, build an IPA, or alter unrelated landing/review work.

## Tasks (execute in this chat)

1. Refine Home/card/Discover in their existing files. Update stale Discover checks; verify metadata adjacency at normal phone width with actual Geist metrics and wrapping at narrow/enlarged sizes. Verify both hero variants still navigate.
2. Add `student_application_guide.dart` and tests for demonstration progression, exit/back, replay/reset and small/enlarged screens. Replace spotlight rendering in `student_app_tour.dart` with the isolated guide and keep dismissal per account. Update Support replay wording. Test account change and no leakage into real applications.
3. Run affected tests, targeted analysis and diff checks. Inspect fresh phone-sized previews of male/female Home, Discover and practice stages. Obtain a read-only code review before completion. Record limitations and leave changes uncommitted for device review.

## Review focus

- A sample submission must never call real application/storage APIs or change real counts.
- Only Next/Back/Skip operate in the demonstration; highlighted upload/submit controls are labelled examples, not real actions.
- Demonstration completion is visibly distinct from real submission success; returning or skipping destroys sample state.
- Guide teardown on account change must clear sample state and restore underlying focus/semantics.
- Keyboard/large text, long deadline labels and bookmarks must not cause overflow or inaccessible actions.
