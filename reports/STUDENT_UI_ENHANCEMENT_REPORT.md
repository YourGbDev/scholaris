# Scholaris Student Mobile UI/UX Enhancement Report

**Date**: September 30, 2026  
**Scope**: Student Mobile Experience (`lib/features/...`)  
**Design Foundations**: Apple Human Interface Guidelines (`apple-hig`), Apple Fluid Motion (`apple-design`), Scholaris Project Guidelines (`GEMINI.md`)  
**Target Viewports**: Narrow Mobile (360×800) and Large Mobile (iPhone 16 Pro Max 440×956)

---

## 1. Executive Summary

A targeted optimization was executed across the Scholaris student mobile application to deliver authentic **Apple Human Interface Guidelines (HIG)** fidelity, fluid spring motion, and tactile physicality while strictly enforcing **Live Data Integrity** and **Defensive Flex Layouts**. 

All placeholder and ghost metrics were eradicated, modal bottom sheets were stabilized against framework assertions, raw fonts were standardized to optical tracking scales, and a live, provider-bound notification modal was introduced to replace transient floating snackbars.

---

## 2. Design Principles & Guidelines Applied

1. **Physicality & Tactile Haptics (`apple-design §1`)**:
   - Touch interactions on primary calls-to-action, bottom navigation tabs, chips, and bookmarks now feature `PressableScale` spring touch-down physics combined with system haptic feedback (`HapticFeedback.lightImpact()`, `selectionClick()`, and `mediumImpact()`).
2. **Apple Translucent Materials & Depth (`apple-design §4`)**:
   - Replaced flat dark gradient blocks with authentic frosted `LiquidGlass` overlays featuring 16px background blur, soft dark tinting, and light-edge refraction.
3. **Defensive Flex Layouts (`GEMINI.md §1`)**:
   - Prevented text and button clipping across variable font metrics by guarding inner rows with `FittedBox(fit: BoxFit.scaleDown)` and `Expanded` with explicit text truncation.
4. **Live Data Integrity (`GEMINI.md §2`)**:
   - Zero hardcoded or mock indicators. All counts, notifications, and badges strictly bind to live student profile records (`currentProfileProvider`) and real application submissions (`applicationsProvider`).

---

## 3. Detailed Summary of Enhancements

### Batch 1: Dashboard Hardening & Navigation Physicality
- **Elimination of Fake Dashboard Stats** (`student_dashboard_screen.dart`):
  - Removed ghost fallback count of `18` opportunities (`opportunitiesCount > 0 ? opportunitiesCount : 18` → `opportunitiesCount`).
  - Conditioned "See All ($totalCount)" link to only render numeric counters when positive.
- **Quick-Stat 3-Tile Grid Hardening** (`student_dashboard_screen.dart`):
  - Shielded stat counters with `FittedBox(fit: BoxFit.scaleDown)` while retaining invisible semantic keys to guarantee headless test compatibility.
- **Bottom Navigation Bar & Detached Action Button** (`home_screen.dart`):
  - Added `HapticFeedback.selectionClick()` on tab switching.
  - Added `HapticFeedback.lightImpact()` on the floating circular `+` action button.
- **Bookmark & Onboarding Tactile Swiping** (`scholarship_card.dart` & `onboarding_screen.dart`):
  - Added light impact haptic feedback when toggling scholarship bookmarks.
  - Added selection click haptic feedback on page swipes in the onboarding carousel.
- **Optical Typography on Action Sheet** (`student_action_sheet.dart`):
  - Replaced raw `GoogleFonts` calls with optical tracking helpers `outfit()` and `openSans()`.

---

### Batch 2: Filter Sheets, Interaction Feedback & Avatar Customization
- **Discovery Filter Sheet Overhaul** (`discovery_filter_sheet.dart`):
  - Configured `showDragHandle: true`, `isScrollControlled: true`, and dynamic bottom home-indicator inset (`MediaQuery.paddingOf(context).bottom + 16`).
  - Wrapped sheet content inside a `Material` widget ancestor, resolving Flutter framework `ListTile` DecoratedBox assertions.
  - Added `selectionClick` haptics to sort segments, income chips, and regional filters, and `lightImpact` on Reset and Done actions.
- **Applications Tracking Filter Chips** (`applications_screen.dart`):
  - Added `HapticFeedback.selectionClick()` to `_StatusFilterChip.onTap`.
- **Scholarship Detail Tactile Feedback** (`scholarship_detail_screen.dart`):
  - Added `HapticFeedback.lightImpact()` on bookmark toggles and `HapticFeedback.mediumImpact()` upon application submission.
- **Avatar Selector Sheet** (`avatar_selector_sheet.dart`):
  - Replaced 9 raw `GoogleFonts` calls with optical `poppins()` and `openSans()`.
  - Added `selectionClick` haptics on doodle presets and standardized modal presentation.

---

### Batch 3: Welcome Intro, QR Scanner, Document Upload & Notifications Modal
- **Welcome Intro Tactile Physicality** (`intro_screen.dart`):
  - Wrapped both the primary **"Get Started →"** CTA and the secondary **"Already have an account? Sign In"** link in `PressableScale` for spring-loaded touch response.
  - Added `HapticFeedback.lightImpact()` on button tap prior to route transitions.
- **Document Upload Sheet Fix & Typography** (`document_upload_sheet.dart`):
  - Fixed modal invocation: Replaced `showAppleSpringModalBottomSheet` (which crashed due to unbounded `AnimationController` with no default duration) with `showModalBottomSheet(isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)))`.
  - Replaced all raw `GoogleFonts` calls with `outfit()` and `openSans()`.
  - Added interactive haptics: `selectionClick` on document type choice chips, `lightImpact` on file pick, and `mediumImpact` on upload completion.
- **LiquidGlass Scanner Overlay & Camera Haptics** (`scholarship_qr_scanner_screen.dart`):
  - Replaced solid dark gradient navigation bar and bottom control panels with floating `LiquidGlass` frosted glass pills (`blur: 16`, `tintColor: Colors.black`, `tintOpacity: 0.50`, `borderRadius: 20–22`).
  - Added `HapticFeedback.heavyImpact()` on QR detection, `vibrate()` on invalid payload, and `lightImpact()` on flashlight and camera toggle.
  - Upgraded all error banners, fallback text, and manual code input dialogs to optical typography.
- **Live Student Notifications Modal** (`student_notifications_sheet.dart`):
  - Replaced the transient `SnackBar("You're all caught up on notifications!")` on the **Student Dashboard**, **Discover Screen**, and **Profile Tab** with an Apple HIG modal sheet (`showStudentNotificationsSheet`).
  - **Live Data Integrity**:
    - **Academic Profile Completeness**: Dynamically checks `currentProfileProvider` for missing GWA or institution and displays an actionable alert with one-tap navigation to the profile tab.
    - **Live Application Tracking**: Dynamically reflects submitted, in-review, approved, and awarded statuses from `applicationsProvider` with deep links to `application/:id`.
    - **Apple HIG Empty State**: Displays an "All Caught Up" state with a direct shortcut to `AccountSettingsScreen` for notification preferences.
  - **Defensive Flex**: Wrapped inner titles in `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` to eliminate `RenderFlex` overflow at narrow 360px mobile viewports.

---

## 4. Verification & Automated Test Results

- **Flutter Analyzer**: **0 errors / 0 warnings** across all modified files.
- **Automated Regression Suite**: **69 of 69 tests passed** (100% pass rate):
  - `test/student_notifications_sheet_test.dart` (4/4 passed)
  - `test/intro_screen_test.dart` (9/9 passed)
  - `test/dashboard_widget_test.dart` (19/19 passed)
  - `test/student_nav_rebuild_test.dart` (10/10 passed)
  - `test/onboarding_screen_test.dart` (4/4 passed)
  - `test/scholarship_card_test.dart` (6/6 passed)
  - `test/discovery_search_widget_test.dart` (17/17 passed)

---

## 5. Recommended Next Steps for Student Mobile Experience

### Step 1: Interactive Essay & Personal Statement Editor Enhancement
- **Target File**: `lib/features/applications/presentation/submit_application_review_dialog.dart`
- **Scope & Value**:
  - Implement a live, optical word & character counter with an Apple-style subtle ring progress indicator.
  - Ensure essay and personal statement input fields remain permanently open and editable regardless of word count or draft status, strictly adhering to `GEMINI.md Rule 2`.
  - Add `HapticFeedback.selectionClick()` when reaching required milestone thresholds (e.g. 250 words / 500 words).

### Step 2: Offline Resilience & Cached Feed Skeleton Placeholders
- **Target Files**: `lib/features/scholarships/screens/discover_screen.dart` and `lib/features/dashboard/presentation/student_dashboard_screen.dart`
- **Scope & Value**:
  - Replace generic circular progress spinners with tailored `SkeletonBand` shimmer layouts during pull-to-refresh and network latency.
  - Provide offline caching indicators to ensure students can review previously loaded scholarship eligibility criteria even during unstable campus Wi-Fi connections.
