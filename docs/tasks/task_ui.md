# Task Card: UI/UX (`bowhead` / `ai/ui`)

**Sprint:** 3rd Increment Checking (End-to-End Transaction Cycle)  
**Role:** 🎨 Frontend Components, Polish & Apple HIG Specialist  
**Reference Plan:** `docs/plans/2026-10-15_3rd_increment_transaction_cycle_plan.md`  
**Status:** `READY FOR IMPLEMENTATION`

---

## 1. Objective
1. Bridge the Student Award Celebration flow: enable students to trigger and view the Ceremony celebration directly upon approval.
2. Enforce the **STRICT UI RULE**: Zero browser alerts (`window.alert`), zero raw error messages, and cohesive, branded in-app feedback (SnackBars, dialogs, toasts) throughout the entire transaction cycle.

---

## 2. Deliverables & Specifications

### A. Award Celebration & Ceremony Screen Enhancements
1. **Update `CeremonyScreen` (`lib/features/auth/presentation/ceremony_screen.dart`)**:
   - Add optional constructor parameters:
     - `final VoidCallback? onCompleted;`
     - `final String? title;` (e.g. `'Grant Award Confirmed!'`)
     - `final String? subtitle;` (e.g. `'You have officially been awarded this scholarship!'`)
   - If `onCompleted` is provided, invoke it on completion instead of hardcoding `context.go('/login')`.
   - Provide a calm close/dismiss button in the top-right corner so authenticated students can easily exit back to their application details.
2. **Update `ApplicationDetailScreen` (`lib/features/applications/presentation/application_detail_screen.dart`)**:
   - When `application.status == ApplicationStatus.approved || application.status == ApplicationStatus.awarded`:
     - Display a prominent, celebratory action card:
       - Header: `"Congratulations! Your Grant is Approved"`
       - Action Button: `"🎉 View Award Ceremony & Package"`
       - On Tap: Open `CeremonyScreen` in a full-screen modal or page route with custom celebratory text and return callback.
3. **Update `ApplicationsScreen` (`lib/features/applications/presentation/applications_screen.dart`)**:
   - In `_buildApprovedSection`, ensure the action button `"Accept & Sign Award Package"` clearly leads to the detail screen and prompts the celebration flow.

### B. STRICT UI Enforcement (Zero Browser Alerts)
Audit every user touchpoint along the transaction path:
1. **Student Apply Action (`scholarship_detail_screen.dart`)**:
   - Verify that submission errors or duplicate notifications use styled `ScaffoldMessenger.of(context).showSnackBar` with clear human-readable copy.
   - Show loading state on button (`_isApplying`) to prevent double-clicks.
2. **Provider Decision Action (`applicant_review_drawer.dart`)**:
   - Audit `_handleDecision`:
     - Replace any generic error SnackBar with styled feedback banner indicating specific success/error.
     - Confirmation dialog must use Apple HIG typography, rounded corners (16dp), clear primary vs destructive colors (`kOrgPrimary` vs `kOrgError`).
3. **Student Notification Center (`student_notifications_sheet.dart`)**:
   - Ensure the notification item for `approved`/`awarded` has an active visual badge, celebratory icon, and immediate tap-through to the application detail screen.

---

## 3. Allowed Files to Modify
- `lib/features/auth/presentation/ceremony_screen.dart`
- `lib/features/applications/presentation/application_detail_screen.dart`
- `lib/features/applications/presentation/applications_screen.dart`
- `lib/features/dashboard/presentation/widgets/student_notifications_sheet.dart`
- `lib/features/scholarships/presentation/scholarship_detail_screen.dart`

---

## 4. Verification & Testing
Run:
```bash
flutter analyze lib/features/auth lib/features/applications lib/features/dashboard
flutter test test/shared/theme/apple_motion_test.dart
```
Ensure responsive layouts across mobile (360px) and desktop (1280px) viewports with zero `RenderFlex` overflows.
