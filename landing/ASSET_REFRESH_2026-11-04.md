# Landing artwork and student preview refresh — November 4, 2026

## Approved celebration pose

Asset: `assets/images/mascot_couple_celebrating_v4.png` (1024 × 1536, alpha PNG). Built-in image editing, generated `exec-5844dce8-70a6-410a-bc85-b9b2349edcae.png`, based on the user-approved akbay pair. Final prompt: preserve faces, warm toothy smile, deep emerald/gold uniforms, male/female height difference and girl's celebration; retain Ariel's arm around Ari's shoulders; change only his free arm to a relaxed hand on his own hip; preserve transparent cutout and full-body framing. The earlier v2 and intermediate v3 assets remain available. Student app animation assets were not changed.

## Current phone-preview screens

Replaced all five old JPEG references in desktop and mobile landing layouts with sibling `app-*-current.png` files. These are 880 × 1912 renders at 440 × 956 logical pixels using the current production Flutter widgets and the actual bundled Geist and icon fonts, with reduced motion. Fictional profiles, scholarships, in-memory application records and empty attachment lists are used; no backend reads/writes or actual awards occurred. Captions disclose fictional demo data.

Views: Home, Discover, scholarship detail before application, saved application receipt within scholarship detail, and submitted application tracker. Receipt/status reflect the same fictional Next Chapter Scholarship; do not use the obsolete standalone receipt mock with hardcoded verification/award claims. Home/Discover also include fictional additional programs.

Capture harness is local ignored tooling (`build/capture_landing_student_test.dart`, based on the existing student regression fixture). Capture run passed with no Flutter exceptions (`build/landing-student-refresh.log`). Screens visually inspected for white surfaces, visible cards, Geist text and intact icons. These are widget-rendered preview images, not physical-device screenshots or evidence of an IPA/backend test.

Local preview server was corrected to serve CSS and media with appropriate content types. This was an ignored preview helper change, not a redesign or deployment.

## Phone chrome correction

User reference: iPhone-style status row with 5:14, cellular/Wi-Fi glyphs and a 40% charging battery. Replaced the independently positioned shell pseudo-element island with a dedicated center column in the status row. Chrome uses phone-container-relative dimensions, separate time/island/icon columns and safe corner insets. All shared phone shells inherit this treatment. Increased status glyph size and reduced the app-content top inset. Removed the obsolete 5% top crop/105% image scaling so current full-frame captures retain the Scholaris app header.

Validation: JavaScript syntax and landing diff checks passed. Browser inspection at the default desktop layout and a 390px narrow viewport confirmed a positive island/icon gap (approximately 14px or greater in the inspected frames), correct status markup and full-height images starting at top 0. Inspected the narrow hero screenshot with the Scholaris header immediately below the hardware row. Temporary viewport overrides were reset. This is decorative website hardware, not Apple's iOS Simulator, and does not claim native device verification.
