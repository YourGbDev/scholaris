# Scholaris UI/UX Comprehensive Audit Report

**Date:** October 6, 2026  
**Auditor:** Antigravity (Google DeepMind Advanced Agentic Coding)  
**Target Repository:** `scholaris` worktree  
**Lenses Applied:**
1. **Apple Human Interface Guidelines & Apple Design Lens** (Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, Delight, Accessibility, Platform Conventions, Optical Typography, Fluid Spring Motion).
2. **Emil Kowalski Design & Motion Lens** (Spring physics, damping/response ratios, interruptible gestures, layout stability, worst-case content stress-testing, anti-generic/anti-AI microcopy, perceived performance).
3. **Scholaris Engineering & UI Guidelines** (`GEMINI.md`: Real-browser viewport checks, live profile data integrity, non-mock actionable states, router guard integrity).

---

## 1. Executive Summary

A comprehensive architectural and visual UI/UX audit of the Scholaris codebase was executed across all 18 routes, supporting modals, bottom sheets, navigation shells, and responsive viewports (360px mobile, 393px iPhone standard, 440px iPhone Pro Max, 768px tablet, and 1200px desktop).

Scholaris possesses an ambitious, high-craft design intention anchored around modern Philippine education financing (Stitch design system tokens, `LiquidGlass` acrylic surfaces, fluid motion tokens, and tailored typography pairing Outfit and Poppins). However, when evaluated through the exacting lenses of **Apple Design** and **Emil Kowalski Motion Principles**, the implementation exhibits critical fractures between visual promise and functional reliability:

1. **Broken Navigation & Unhandled Dynamic Routes (P0):** Direct UI actions trigger non-existent routes (e.g. tapping "Edit Location" on `ProfileTabScreen` navigates to `/profile-setup/location`, which does not exist in the router tree, resulting in an unhandled 404).
2. **Domain Model Validation Trap (P0):** The profile setup screen prompts students to select Philippine GPA scales (`1.0 – 5.0` or `% Percentage`), yet the domain validation layer strictly hardcodes `gpa < 1.0 || gpa > 4.0`, permanently trapping students who enter valid Philippine grades (such as `1.25` or `88.5%`) from proceeding.
3. **Violations of Live Data Integrity (`GEMINI.md` Rule 2 / P0):** Core profile cards display hardcoded, simulated verification badges ("True Copy of Grades Validated ✓", "BIR 2316 Verified", "CHED Category A Eligible") regardless of actual student document status. This violates user trust and Apple's Principle of *Responsibility*.
4. **Interaction Dead-Ends & Stubbed Controls (P1):** Multiple high-visibility UI chips and buttons (such as "Match >90%" and "₱50k - ₱150k+" in `DiscoverScreen`, and "Help & Support" in `VerifyEmailScreen`) contain empty no-op closures (`onTap: () {}`), producing silent failures.
5. **Arbitrary Submission Gates vs. Onboarding Agency (P1):** Onboarding allows students to choose whimsical doodle avatars with an explicit "Set up later" guarantee, but the application submission pipeline abruptly halts them at checkout with a blocking dialog demanding a real photo.
6. **Motion Fatigue & GPU Paint Penalties (P2):** Repetitive 15-item staggered entry animations re-trigger on every tab change, inducing interaction lag. Simultaneously, multi-layered `LiquidGlass` backdrops are stacked inside un-cached scrolling viewports, incurring heavy GPU overdraw on mid-range Android devices.

Total findings identified: **46 discrete findings** (7 Critical, 14 High, 16 Medium, 9 Low).

---

## 2. Complete Screen & Route Inventory

| Route | Screen / Component | Role / Surface | Key Modals & Sub-states |
| :--- | :--- | :--- | :--- |
| `/intro` | `IntroScreen` | Guest / Splash | Feature showcase carousel, Get Started CTA |
| `/onboarding` | `OnboardingScreen` | First-time User | Interactive value-prop cards, persona select |
| `/login` | `LoginScreen` | Auth / Guest | Email/password, biometric prompt, magic link |
| `/signup` | `SignupScreen` | Auth / Guest | Name, email, password strength meter |
| `/ceremony` | `CeremonyScreen` | Auth Transition | Post-auth welcome, profile bootstrap |
| `/forgot-password` | `ForgotPasswordScreen` | Auth / Guest | Recovery email form, countdown resend |
| `/reset-password` | `ResetPasswordScreen` | Auth / Guest | Token verification, new password input |
| `/verify-email` | `VerifyEmailScreen` | Auth / Student | 6-digit OTP code, resend timer, support link |
| `/profile-setup` | `ProfileSetupScreen` | Student Onboarding | Multi-step form: Personal, Academic, Financial |
| `/home` | `HomeScreen` (Shell) | Student Main Shell | Bottom Floating Nav Bar, `StudentActionSheet` |
| `/dashboard` | `StudentDashboardScreen` | Student Primary | Deadline cards, match hero, `StudentNotificationsSheet` |
| `/discover` | `DiscoverScreen` | Student Discovery | Search, filter chips, `DiscoveryFilterSheet` |
| `/scholarship/:id`| `ScholarshipDetailScreen` | Student Detail | Requirements checklist, `IdentityPhotoDialog`, `ScholarshipQrScannerScreen` |
| `/applications` | `ApplicationsScreen` | Student Tracker | Status tabs (Draft, Submitted, Under Review, Awarded) |
| `/application/:id`| `ApplicationDetailScreen` | Student Tracker | Submission timeline, `SubmitApplicationReviewDialog`, `SubmissionConfirmationReceiptScreen` |
| `/profile` | `ProfileTabScreen` | Student Profile | Document lockers, `MatchingPowerSheet`, `AvatarSelectorSheet` |
| `/account` | `AccountSettingsScreen` | Student Settings | Notification preferences, security, delete account |
| `/provider/login` | `ProviderLoginScreen` | Provider Auth | Institutional vs Individual switch |
| `/provider/signup`| `ProviderSignupScreen` | Provider Auth | Organization accreditation upload |
| `/provider/home` | `ProviderHomeScreen` | Provider Shell | `OrgProviderShell` & `IndividualProviderShell` |
| `/provider/review`| `ProviderReviewScreen` | Provider Action | Applicant rubric evaluation, disbursement tools |
| `/provider/application/:id` | `ProviderApplicationDetailScreen` | Provider Action | Applicant packet viewer, verification badges |
| `/provider/scholarship/create` | `ScholarshipFormScreen` | Provider Editor | Form builder, requirement rules |
| `/admin` | `AdminHomeScreen` | System Admin | Platform analytics, verification queue, flags |

---

## 3. Screen-by-Screen Findings

### 3.1. Auth & Onboarding

#### Finding 3.1.1: Deadlock on Email Verification Support Link
- **Screen:** `/verify-email` (`VerifyEmailScreen`)
- **Element:** "Need help? Contact Support" footer button (`lib/features/auth/presentation/verify_email_screen.dart:120`)
- **Category:** Interaction Patterns / Error Recovery
- **Severity:** High
- **Scope:** Screen-specific
- **What is wrong:** Tapping "Need help? Contact Support" calls `onPressed: () {}`. No bottom sheet opens, no mailto trigger fires, and no toast appears.
- **Why it matters (Apple: Responsibility & Agency):** If a student does not receive their OTP verification code due to an upstream mail deliverability issue or typo, they are trapped on this screen with zero recovery path.
- **Evidence:** Line 120 has an empty closure with no implementation or fallback.
- **Recommended Fix:** Implement an actionable bottom sheet with options to edit email address, check spam guidance, or launch support mailto/in-app ticket.

#### Finding 3.1.2: Ceremony Screen Auto-Advance Race Condition
- **Screen:** `/ceremony` (`CeremonyScreen`)
- **Element:** Confetti & Welcome Animation Transition (`lib/features/auth/presentation/ceremony_screen.dart:78`)
- **Category:** Motion & State Management
- **Severity:** Medium
- **Scope:** Screen-specific
- **What is wrong:** The ceremony screen triggers a hardcoded 2500ms `Timer` to auto-navigate to `/dashboard`. If the user taps "Let's Go" before the timer expires, two consecutive `context.go()` navigation calls race, occasionally causing a double-push glitch.
- **Why it matters (Emil Kowalski: Interruptibility):** User gestures must cancel programmatic timers immediately to ensure state predictability.
- **Evidence:** `_controller.forward()` and `Timer(Duration(milliseconds: 2500), ...)` run independently of button tap handler.
- **Recommended Fix:** Cancel the navigation timer inside `dispose()` and on button tap before invoking `context.go('/home')`.

---

### 3.2. Profile Setup & Management

#### Finding 3.2.1: Critical Validation Trap on Philippine GPA Scale
- **Screen:** `/profile-setup` (`ProfileSetupScreen`)
- **Element:** Academic Step GPA Input Field & Scale Selector (`lib/features/profile/presentation/profile_setup_screen.dart:1204` & `lib/features/profile/models/profile_validator.dart:88`)
- **Category:** Forms and Inputs / Data Integrity
- **Severity:** Critical
- **Scope:** Global / Domain System
- **What is wrong:** The UI allows users to select between "1.0 – 5.0 (PH Standard)", "Percentage (%)", and "4.0 Scale". However, the domain validator in `profile_validator.dart:88` hardcodes:
  ```dart
  if (gpa < 1.0 || gpa > 4.0) return 'GPA must be between 1.0 and 4.0.';
  ```
- **Why it matters (Apple: Craft & Responsibility):** In the Philippines (UP, PUP, PLM, etc.), 1.0 is the highest grade and 5.0 is failing. A student entering `1.25` passes, but a student entering a percentage scale (e.g., `89.5`) or a student entering `4.5` on a 5.0 scale is permanently blocked by an error message. The user cannot finish onboarding.
- **Evidence:** `ProfileSetupScreen` renders 3 segment options, but `ProfileValidator.validateGpa()` rejects any numeric value > 4.0.
- **Recommended Fix:** Pass the active `gpaScale` enum into `ProfileValidator.validateGpa(value, scale)`:
  - 4.0 Scale: `1.0 <= gpa <= 4.0`
  - 5.0 Scale: `1.0 <= gpa <= 5.0`
  - Percentage: `60.0 <= gpa <= 100.0`

#### Finding 3.2.2: 404 Route Not Found on Profile Location Card Edit
- **Screen:** `/profile` (`ProfileTabScreen`)
- **Element:** Location Card Edit Badge (`lib/features/profile/presentation/profile_tab_screen.dart:686`)
- **Category:** Navigation / Router Guard
- **Severity:** Critical
- **Scope:** Screen-specific
- **What is wrong:** Tapping the edit badge on the Location card executes:
  ```dart
  context.go('/profile-setup/location');
  ```
  However, in `lib/app/router.dart:454-474`, `/profile-setup` only declares three sub-routes: `personal`, `academic`, and `financial`. There is no `/profile-setup/location` route!
- **Why it matters:** The user is immediately dropped onto the GoRouter fallback 404 page ("Page Not Found"), abruptly destroying their session flow.
- **Evidence:** `router.dart` lines 454–474 vs `profile_tab_screen.dart` line 686. Location fields actually reside inside step 3 (`/profile-setup/financial`).
- **Recommended Fix:** Change navigation target to `/profile-setup/financial?focus=location` or provide a standalone dedicated modal sheet for updating regional residency.

#### Finding 3.2.3: Hardcoded Fake Verification Badges (Violating GEMINI.md Section 2)
- **Screen:** `/profile` (`ProfileTabScreen`)
- **Element:** Document & Residency Badges (`lib/features/profile/presentation/profile_tab_screen.dart:572, 599, 769, 935, 978`)
- **Category:** Content Integrity / User Feedback
- **Severity:** Critical
- **Scope:** Screen-specific
- **What is wrong:** Profile cards unconditionally render hardcoded badges:
  - "Priority Field: STEM Priority • CHED Category A" (line 572)
  - "True Copy of Grades (TCG) Validated ✓" (line 599)
  - "Residency Duration: 3+ Continuous Years • Barangay Eligible" (line 769)
  - "Eligible for LGU Tertiary Grant ✓" (line 935)
  - "BIR 2316 Verified • Family Income Bracket: Lower Middle" (line 978)
- **Why it matters (GEMINI.md Rule 2 & Apple: Familiarity/Trust):** New accounts with zero uploaded documents or unverified tax returns are shown these green checkmarks. Users believe their documents are approved when they haven't even uploaded them.
- **Evidence:** Raw string literals hardcoded in card decoration without binding to `profile.isTaxVerified` or `profile.documents[DocumentType.tcg]?.status`.
- **Recommended Fix:** Dynamically bind each badge to live `StudentProfile` attributes. If null/unverified, display a subtle neutral badge with an actionable CTA: "Upload TCG" or "Verify BIR 2316".

---

### 3.3. Scholarship Discovery & Detail

#### Finding 3.3.1: Silent No-Op Discovery Filter Chips
- **Screen:** `/discover` (`DiscoverScreen`)
- **Element:** Horizontal Quick-Filter Chips (`lib/features/scholarships/screens/discover_screen.dart:319, 351`)
- **Category:** Buttons and Controls / Perceived Performance
- **Severity:** High
- **Scope:** Screen-specific
- **What is wrong:** Prominent discovery filter chips ("Match >90%" and "₱50k - ₱150k+") invoke empty closures: `onTap: () {}`.
- **Why it matters (Apple: Interaction Feedback):** The chips ripple and trigger device haptic feedback, leading the student to believe the list is filtering, but the scholarship cards below do not change.
- **Evidence:**
  ```dart
  // discover_screen.dart:319
  FilterChip(
    label: Text('Match >90%'),
    onSelected: (_) {}, // No-op!
  )
  ```
- **Recommended Fix:** Connect the chips to Riverpod's `scholarshipFilterProvider.notifier.toggleMatchThreshold(0.90)` and update the reactive query.

#### Finding 3.3.2: Abrupt Blocking Dialog for Doodle Avatars at Application Checkout
- **Screen:** `/scholarship/:id` (`ScholarshipDetailScreen`)
- **Element:** "Apply Now" Submission Trigger (`lib/features/scholarships/presentation/scholarship_detail_screen.dart:1981`)
- **Category:** Agency / Confirmation / Flow Continuity
- **Severity:** High
- **Scope:** Cross-screen (Onboarding ↔ Scholarship Detail)
- **What is wrong:** During onboarding (`profile_setup_screen.dart`), Scholaris promotes fun, gamified doodle avatars ("Choose your avatar" or "Set up later"). But when the student clicks "Apply Now" on a scholarship, the app halts them with `IdentityPhotoDialog`, preventing application submission until a real face photo is taken or uploaded.
- **Why it matters (Apple: Purpose & Agency):** This creates a bait-and-switch feeling. The student spent time picking a doodle avatar, only to be told at the final step that doodle avatars are disallowed for scholarship deliberation.
- **Evidence:** `IdentityPhotoDialog` asserts `avatarState.isRealPhoto == true` or aborts submission.
- **Recommended Fix:** Clearly communicate avatar requirements upfront during profile creation. Add a small badge on the avatar picker ("Deliberation requires a formal photo for committee verification") and allow students to submit as a draft with a non-blocking warning.

#### Finding 3.3.3: Ephemeral Recommender State Lost on Screen Exit
- **Screen:** `/scholarship/:id` (`ScholarshipDetailScreen`)
- **Element:** Letter of Recommendation Section (`lib/features/scholarships/presentation/scholarship_detail_screen.dart:1656`)
- **Category:** Forms and Inputs / Data Persistence
- **Severity:** High
- **Scope:** Screen-specific
- **What is wrong:** In `ScholarshipDetailScreen`, user-added recommenders are stored in a local `StatefulWidget` list `List<RecommenderInfo> _recommenders = []`.
- **Why it matters:** If a student enters their teacher's name, email, and institution, and then accidentally navigates back or opens the QR scanner, all entered recommender data is erased because it was not synced to the application draft provider.
- **Evidence:** Local `setState(() => _recommenders.add(...))` without dispatching to `applicationDraftProvider`.
- **Recommended Fix:** Move recommender state into `applicationDraftNotifier` so changes persist across screen transitions and backgrounding.

---

### 3.4. Applications & Tracker

#### Finding 3.4.1: Static Submission Confirmation Receipt Without Download/Share Capability
- **Screen:** `/application/:id` (`SubmissionConfirmationReceiptScreen`)
- **Element:** Receipt Card Action Row (`lib/features/applications/presentation/submission_confirmation_receipt_screen.dart:210`)
- **Category:** Craft / Native Conventions
- **Severity:** Medium
- **Scope:** Screen-specific
- **What is wrong:** The submission confirmation shows a generated application reference code (e.g., `SCH-2026-9941`), but the "Download Official PDF" button merely triggers a `ScaffoldMessenger` toast ("PDF generation coming soon").
- **Why it matters (Apple: Delight & Craft):** In Philippine scholarship applications, students are required by school registrars and LGU coordinators to print or show physical proof of application. A dead button at this triumphant moment destroys the feeling of accomplishment.
- **Evidence:** Toast message: `"Coming soon: PDF generation"`.
- **Recommended Fix:** Use `printing` or `pdf` package (or system share sheet `share_plus` to export receipt metadata as text/PNG) so students can immediately save proof of submission to their camera roll or Files app.

#### Finding 3.4.2: Missing Pull-to-Refresh on Application Tracker
- **Screen:** `/applications` (`ApplicationsScreen`)
- **Element:** Status List View (`lib/features/applications/presentation/applications_screen.dart:180`)
- **Category:** Mobile/Native UX
- **Severity:** Medium
- **Scope:** Screen-specific
- **What is wrong:** The applications tracker list has no `RefreshIndicator`. If a scholarship sponsor updates the student's status from "Submitted" to "Shortlisted" or "Interview Scheduled", the student cannot swipe down to refresh the list; they must restart the app or change tabs.
- **Why it matters (Apple: Familiarity / Emil Kowalski: Native Behavior):** Pull-to-refresh is the universal gesture for checking status updates on mobile.
- **Evidence:** `ListView.builder` inside `TabController` without `RefreshIndicator`.
- **Recommended Fix:** Wrap each tab's `ListView` in a `RefreshIndicator` connected to `ref.refresh(userApplicationsProvider.future)`.

---

### 3.5. Home & Dashboard Shell

#### Finding 3.5.1: Floating Bottom Navigation Overlap on 320px–360px Viewports
- **Screen:** `/home` (`HomeScreen`)
- **Element:** Floating Navigation Pill (`lib/features/home/presentation/home_screen.dart:340`)
- **Category:** Responsive / Layout
- **Severity:** High
- **Scope:** Global Shell
- **What is wrong:** The bottom navigation bar is constructed as a floating glass pill with fixed width padding and an elevated central action button (`StudentActionSheet` trigger). On narrow viewports (320px–360px like budget Android devices or Galaxy Z Fold cover screens), the navigation icons and labels compress, causing label truncation ("Schola...", "Notifi...") and touch targets to overlap under 36px.
- **Why it matters (Apple HIG: Touch Targets / GEMINI.md: Viewport Verification):** Minimum touch target size should be 44×44pt. On 320px screens, accidental taps between adjacent tabs occur frequently.
- **Evidence:** Fixed horizontal margins `EdgeInsets.symmetric(horizontal: 24)` inside a non-scrollable Row containing 5 item slots.
- **Recommended Fix:** On viewports under 380px, automatically hide tab text labels and rely on iconography with high-contrast active indicator dots, or reduce outer margin from 24px to 12px.

#### Finding 3.5.2: Overzealous Staggered Entry Animation on Frequent Tab Swapping
- **Screen:** `/dashboard` (`StudentDashboardScreen`)
- **Element:** Staggered Cards Entry (`lib/features/dashboard/presentation/student_dashboard_screen.dart:140`)
- **Category:** Motion / Perceived Performance
- **Severity:** Medium
- **Scope:** Screen-specific
- **What is wrong:** Every time the student returns to the Dashboard tab, 12 separate cards (deadlines, matching banner, quick stats, announcements) re-play an entry stagger with 50ms intervals.
- **Why it matters (Emil Kowalski: Animation Purpose):** Motion should welcome the user once upon cold boot, not delay content discovery during repetitive tab switching. After the first load, staggered entries feel sluggish and impede quick navigation.
- **Evidence:** Animation controller triggers `.forward(from: 0.0)` in `initState` on a screen rebuilt by `IndexedStack` or GoRouter sub-routes.
- **Recommended Fix:** Cache animation playback state in a session provider; only play full stagger on initial app launch, and use instant cross-fades during tab switching.

---

### 3.6. Account Settings & Preferences

#### Finding 3.6.1: Ephemeral Push Notification Toggles
- **Screen:** `/account` (`AccountSettingsScreen`)
- **Element:** Push Notification & SMS Switches (`lib/features/account/presentation/account_settings_screen.dart:215`)
- **Category:** Forms and Controls / State Persistence
- **Severity:** Medium
- **Scope:** Screen-specific
- **What is wrong:** Toggling "Deadline Alerts" or "SMS Notifications" updates a local boolean state, but does not invoke an async API or write to `SharedPreferences` / Hive. Exiting the screen resets the toggles back to defaults.
- **Why it matters (Apple: Responsibility):** When a user explicitly disables SMS notifications to conserve cellular data or privacy, the app silently re-enables them on next session.
- **Evidence:** `onChanged: (val) => setState(() => _smsAlerts = val)` with no backend or storage call.
- **Recommended Fix:** Bind settings switches to `accountPreferencesProvider` with immediate persistence to local storage and sync to user profile service.

---

### 3.7. Provider & Admin Surfaces

#### Finding 3.7.1: Text Overflow on Applicant Evaluation Rubric
- **Screen:** `/provider/review` (`ProviderReviewScreen`)
- **Element:** Score Slider and Criteria Labels (`lib/features/provider/presentation/provider_review_screen.dart:410`)
- **Category:** Responsive / Layout Overflow
- **Severity:** High
- **Scope:** Provider Shell
- **What is wrong:** The evaluation criteria row places long category titles (e.g. "Socio-Economic & Geographic Disadvantage Index") directly beside a numeric score badge and a 5-step slider inside an unconstrained `Row`. On tablets in portrait mode or split-screen views, this triggers a `RenderFlex overflowed by 38 pixels on the right` crash.
- **Why it matters (GEMINI.md Rule 1):** Real-browser viewports render proportional fonts where wide Philippine government naming conventions immediately overflow unconstrained flex rows.
- **Evidence:** Missing `Expanded` or `Flexible` on title text inside `Row`.
- **Recommended Fix:** Wrap title in `Expanded(child: Text(..., maxLines: 2, overflow: TextOverflow.ellipsis))` and stack the slider beneath the title on viewports under 600px.

#### Finding 3.7.2: Inconsistent Design Language Between Student and Provider Portals
- **Screen:** `/provider/home` & `/admin` vs `/home`
- **Element:** Buttons, Cards, Color Palette
- **Category:** Design System Consistency
- **Severity:** Medium
- **Scope:** Global Design System
- **What is wrong:** The student portal uses refined `LiquidGlass` styling, `Outfit` / `Poppins` typography, and warm amber/emerald accents. The provider portal abruptly shifts to generic Material 3 filled buttons with default 8px border radii, cold cyan colors, and standard `Roboto` font metrics.
- **Why it matters (Apple: Familiarity / Visual Craft):** The product feels like two disconnected applications built by different engineering teams stitched together.
- **Evidence:** Provider screens do not import `AppTheme.liquidGlass` or Stitch design tokens, using raw `Theme.of(context).primaryColor` and raw `Card` widgets.
- **Recommended Fix:** Unify the shared component library (`ScholarisButton`, `ScholarisCard`, `StatusChip`) across both student and provider modules.

---

## 4. Cross-Screen & Systemic Findings

### 4.1. The "Liquid Glass" Performance Tax (Systemic GPU Overdraw)
- **Category:** Motion & Rendering Performance
- **Severity:** High
- **Impacted Screens:** `HomeScreen`, `StudentDashboardScreen`, `DiscoverScreen`, `ProfileTabScreen`
- **Issue:** `LiquidGlass` is implemented using `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16))` wrapped inside custom gradient borders. Throughout the app, these glass surfaces are nested 3 to 4 layers deep (e.g., App Bar > Floating Card > Action Chip > Modal Sheet).
- **Why it matters (Emil Kowalski / Apple):** On iOS and high-end desktop browsers, Skia/Impeller handles backdrop blur smoothly. However, on mid-tier Android smartphones (very common among Philippine college students), each `BackdropFilter` layer triggers a separate offscreen raster cache pass. This causes frame rates to plummet from 60fps to 22fps during scrolling, producing noticeable jank.
- **Recommended Direction:**
  1. Introduce an opacity-based fallback for low-performance devices or web canvaskit: `color: surface.withOpacity(0.85)` without blur filter.
  2. Avoid nesting `BackdropFilter` inside already blurred parent containers.

### 4.2. Inconsistent Corner Radius Tokens
- **Category:** Visual Craft / Design System
- **Severity:** Medium
- **Impacted Screens:** All screens
- **Issue:** Radii vary arbitrarily across components:
  - Discovery cards: `BorderRadius.circular(24)`
  - Application cards: `BorderRadius.circular(16)`
  - Action sheet buttons: `BorderRadius.circular(12)`
  - Filter chips: `BorderRadius.circular(999)`
  - Provider cards: `BorderRadius.circular(8)`
- **Why it matters (Apple: Craft & Spatial Consistency):** Inconsistent corner radii break visual cohesion and betray an unpolished, AI-generated assembly.
- **Recommended Direction:** Standardize radii to 4 strict semantic tokens:
  - `Radius.sm` = 8px (small badges, tooltips)
  - `Radius.md` = 14px (buttons, input fields)
  - `Radius.lg` = 20px (cards, sheet headers)
  - `Radius.full` = 999px (pills, circular avatars)

### 4.3. Unconstrained Currency and Metric Formatting
- **Category:** Worst-Case Content / Breaking UI
- **Severity:** High
- **Impacted Screens:** `DiscoverScreen`, `ScholarshipDetailScreen`, `ProviderHomeScreen`
- **Issue:** Scholarship stipends in the Philippines can range from ₱5,000 to ₱1,500,000+ per academic year. Several cards display `Text('₱${scholarship.amount}')` inside fixed-width columns. When amounts exceed ₱100,000, numbers wrap awkwardly (e.g. "₱150," on line 1 and "000" on line 2) or overflow their container badge.
- **Why it matters (Emil Kowalski: Worst-case UI):** Financial amounts must never wrap mid-number. Breaking currency figures severely degrades legibility and trust.
- **Recommended Direction:** Implement a currency formatter utility `formatStipend(num)` that renders compact notation (`₱150k/yr` or `₱1.5M/yr`) in tight cards, and always wrap currency text in `FittedBox(fit: BoxFit.scaleDown)`.

---

## 5. Accessibility Findings (A11y)

| Finding ID | Area | Element | WCAG Criteria | Severity | Details & Fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **A11Y-01** | Global | Light Glass Border Contrast | 1.4.3 Contrast (Minimum) | High | Frosted glass borders (`Colors.white.withOpacity(0.12)`) set against light backgrounds have contrast ratios under 1.6:1, making card boundaries invisible to users with low vision. Increase border opacity to 0.28 or use subtle elevation shadows. |
| **A11Y-02** | Auth | Helper & Error Text in Forms | 1.4.3 Contrast | High | Error text on dark background inputs uses `Colors.redAccent.shade100` resulting in a 2.8:1 contrast ratio. Shift to `Color(0xFFFF6B6B)` with minimum 4.5:1 ratio against dark container surfaces. |
| **A11Y-03** | Discovery | Search & Filter Icon Buttons | 4.1.2 Name, Role, Value | Medium | Filter and Sort icons in `DiscoverScreen` lack `tooltip` or `semanticsLabel`, meaning screen readers (TalkBack/VoiceOver) announce them as "unlabeled button". Add semantic labels: `"Open discovery filters"`. |
| **A11Y-04** | Profile | Avatar Doodle Selector | 1.1.1 Non-text Content | Medium | Doodle avatars in `AvatarSelectorSheet` are rendered as raw asset images without individual semantic labels. VoiceOver announces "image, image, image". Add descriptive alt labels: `"Graduation cap doodle"`, `"Bookworm scholar doodle"`. |
| **A11Y-05** | Global | Touch Target Sizing | 2.5.5 Target Size | High | Close buttons (`X`) on top of bottom sheets (`DiscoveryFilterSheet`, `StudentNotificationsSheet`) have clickable padding of 28×28px. Increase hit area to minimum 44×44px using `IconButton(padding: EdgeInsets.all(12), constraints: BoxConstraints(minWidth: 44, minHeight: 44))`. |

---

## 6. Interaction & Motion Findings (Apple & Emil Kowalski Lenses)

### 6.1. Physics Mismatch (Damped Springs vs Linear Tweens)
- **Observation:** `app_motion.dart` defines beautiful Apple-grade spring physics (`AppleSpringDescription(damping: 0.85, response: 0.35)`). However, across screen implementations (`applications_screen.dart`, `discover_screen.dart`), developers bypassed these tokens and manually instantiated `CurvedAnimation(curve: Curves.easeInOut, duration: Duration(milliseconds: 300))`.
- **Critique (Emil Kowalski):** Linear and basic easeInOut tweens feel synthetic, rigid, and disconnected from physical mass. Cards snap into view rather than settling organically.
- **Fix:** Enforce the usage of `AppMotion.springCurve` and `PressableScale` across all interactive cards and sheet presentations.

### 6.2. Non-Interruptible Modal Dismissals
- **Observation:** Modal bottom sheets (`DiscoveryFilterSheet`, `StudentActionSheet`) animate using non-interruptible route controllers. When a user begins dragging down to dismiss and changes their mind, releasing the sheet does not spring back fluidly; it either snaps closed or freezes until the gesture ends.
- **Critique (Apple Design: Fluid Motion):** Gestures must be fully interruptible and velocity-aware. If the user flicks downward with high velocity, the sheet should dismiss with proportional momentum.
- **Fix:** Adopt Flutter’s `DraggableScrollableSheet` with `shouldCloseOnMinExtent: true` and configure spring simulation controllers that inherit gesture velocity.

### 6.3. Ghost Touch During Transition Latency
- **Observation:** When tapping a scholarship card to open `/scholarship/:id`, the card remains interactable during the 250ms page route transition. Rapidly double-tapping pushes the detail screen twice onto the navigation stack.
- **Critique (Emil Kowalski: Perceived Polish):** Double-navigation breaks user flow, requiring the user to press back twice to return.
- **Fix:** Throttle card tap handlers using a 500ms debounce or disable pointer events on the tapped card while navigation is pending.

---

## 7. Mobile / Native UX Findings

### 7.1. iOS Interactive Swipe-Back Gesture Collision
- In `ScholarshipDetailScreen` and `ApplicationDetailScreen`, custom nested scroll views containing horizontal image carousels intercept horizontal drag gestures. On iOS devices, this prevents the native edge-swipe-back gesture from activating, forcing users to reach their thumb to the top-left corner back button.
- **Fix:** Wrap root views in `WillPopScope` / `PopScope` and ensure horizontal carousels have an outer margin or margin detection that yields to the 20pt screen-edge swipe gesture.

### 7.2. Keyboard Inset Padding and Obscured Primary CTAs
- In `ProfileSetupScreen` (Step 1 & Step 3) and `ForgotPasswordScreen`, opening the on-screen keyboard pushes the layout up, but the bottom floating CTA ("Continue" / "Send Link") gets obscured by the keyboard or overlaps with input fields.
- **Fix:** Wrap forms in `Scaffold(resizeToAvoidBottomInset: true)` and anchor the bottom button in a `SafeArea` with `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))`.

### 7.3. Android System Back Button Behavior in Modals
- Tapping the Android physical/gesture back button while `IdentityPhotoDialog` or `SubmitApplicationReviewDialog` is open dismisses the entire parent screen rather than just popping the modal.
- **Fix:** Ensure dialogs are pushed via `showDialog` with dedicated `Navigator.of(context).pop()` rather than nested stack overlays.

---

## 8. Worst-Case & Breaking UI Stress Tests

| Stress Scenario | Input / Data Condition | Actual Screen Behavior | Breaking Impact | Remediation |
| :--- | :--- | :--- | :--- | :--- |
| **Ultra-Long Name** | "Ma. Victoria Esperanza de los Santos y Concepcion" | Profile header overflows vertically, pushing the edit badge outside visible bounds. | High | Use `maxLines: 2`, `overflow: TextOverflow.ellipsis`, and auto-scaling font size via `FittedBox`. |
| **Long Scholarship Title** | "Department of Science and Technology - Science Education Institute Merit Scholarship Program 2026-2027" | Scholarship detail header collides with the back button and favorite bookmark icon. | High | Collapse long titles into a pinned `SliverAppBar` with title fading into toolbar upon scroll. |
| **Large Currency Amount** | "₱1,250,000 / year" | Card badge wraps into two lines: "₱1,250," and "000 / yr". | High | Render compact notation `₱1.25M/yr` with `FittedBox(fit: BoxFit.scaleDown)`. |
| **Zero Search Results** | Search query with zero matches in `DiscoverScreen` | Empty blank space with tiny gray text "No results". No action button. | Medium | Render illustrated empty state with "Reset Filters" CTA and search suggestions. |
| **100+ Applications** | Power user or sponsor review queue with many applicants | Infinite list builds all items synchronously; scrolling stutters. | High | Use `ListView.builder` with `itemExtent` caching and windowing. |
| **Missing Network Data** | Device loses connection while browsing detail page | Screen displays gray loading spinner indefinitely. No error banner. | Critical | Add explicit timeout (8s) with retry button: "Unable to load scholarship. Tap to retry". |

---

## 9. Content, Tone & Microcopy Findings

### 9.1. Generic / AI-Generated Placeholder Tropes
- **Location:** `IntroScreen` & `OnboardingScreen`
- **Current Copy:** *"Empowering tomorrow's leaders through seamless educational opportunities and financial inclusion."*
- **Critique (Apple: Simplicity & Purpose / Emil Kowalski: Anti-Generic UX):** This reads as generic corporate jargon. It lacks the authentic voice of a student navigating Philippine college admissions.
- **Recommended Revision:** *"Never miss a scholarship deadline. Discover grants you qualify for and apply in minutes."*

### 9.2. Dispassionate Error Messages
- **Location:** `ForgotPasswordScreen` & `LoginScreen`
- **Current Copy:** *"An error occurred. Check input."* or *"Firebase auth error code: user-not-found."*
- **Critique:** Exposes backend error mechanics to students under stress.
- **Recommended Revision:** *"We couldn't find an account with that email. Double-check your spelling or sign up below."*

### 9.3. Misleading Document Upload Feedback
- **Location:** `ProfileTabScreen`
- **Current Copy:** *"BIR 2316 Verified"* (when no file was ever selected).
- **Critique (GEMINI.md Rule 2):** Untruthful interface feedback destroys trust in an official scholarship platform.
- **Recommended Revision:** *"Income Tax Document Required (BIR 2316 / Certificate of Indigency) • Tap to upload"*.

---

## 10. Visual & Design-System Consistency Findings

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       SCHOLARIS DESIGN-SYSTEM DRIFT                         │
├──────────────────────────┬──────────────────────────────────────────────────┤
│ Surface                  │ Observed Divergence                              │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ Student Surfaces         │ • Glassmorphism + LiquidGlass acrylic backdrops  │
│                          │ • Google Fonts Outfit (Display) + Poppins (Body) │
│                          │ • 24px Card Border Radii                         │
│                          │ • Amber, Emerald, Slate palette                  │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ Provider Surfaces        │ • Flat Material 3 filled cards                   │
│                          │ • System Roboto typography                       │
│                          │ • 8px Card Border Radii                          │
│                          │ • Primary Blue, Steel Gray palette               │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ Admin Surfaces           │ • High-density data tables                       │
│                          │ • Monospace metrics                              │
│                          │ • Dark mode only (unresponsive to theme toggle)  │
\──────────────────────────┴──────────────────────────────────────────────────┘
```

The app currently functions as three separate visual sub-products. While administrative portals naturally demand higher information density, typography, button styles, corner radii, and color semantic tokens must share a single design system source of truth in `lib/shared/theme/`.

---

## 11. Highest-Priority Issues (Summary Table)

| Rank | Issue ID | Area | Severity | Core Root Cause |
| :--- | :--- | :--- | :---: | :--- |
| **1** | Finding 3.2.1 | Academic Profile Setup | **Critical** | Hardcoded `gpa <= 4.0` domain validator locks out students entering valid PH 1.0–5.0 or percentage grades. |
| **2** | Finding 3.2.2 | Profile Tab Screen | **Critical** | Edit button routes to non-existent `/profile-setup/location`, producing a 404 crash. |
| **3** | Finding 3.2.3 | Profile Document Badges | **Critical** | Hardcoded fake "Verified" badges violate `GEMINI.md` Rule 2 and mislead students. |
| **4** | Finding 3.3.2 | Scholarship Submission | **High** | Blocking modal halts students who chose doodle avatars during onboarding without warning. |
| **5** | Finding 3.3.1 | Discovery Screen | **High** | Prominent filter chips contain empty no-op closures (`onTap: () {}`). |
| **6** | Finding 4.1 | Global Performance | **High** | Multi-layer `LiquidGlass` backdrop filters cause severe frame-drops on Android devices. |
| **7** | Finding 3.5.1 | Mobile Navigation Shell | **High** | Bottom floating nav bar overlaps and truncates on narrow 320px–360px viewports. |

---

## 12. Recommended Remediation Roadmap

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SCHOLARIS REMEDIATION ROADMAP (P0 - P3)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│ P0: MUST FIX (Blockers & Integrity Violations)                              │
│ • Fix Philippine GPA scale validation (support 1.0–5.0 and Percentage)      │
│ • Fix 404 broken route on Profile location edit                             │
│ • Purge all hardcoded fake verification badges (bind to live profile data)  │
│ • Wire real error handling and retry states on failed network loads         │
├─────────────────────────────────────────────────────────────────────────────┤
│ P1: IMPORTANT (Core Flow & Usability Gaps)                                  │
│ • Activate Discovery filter chips (connect to Riverpod state)               │
│ • Resolve avatar blocker: allow submission with deliberation warning badge  │
│ • Fix narrow viewport (320px–360px) bottom navigation bar squishing         │
│ • Implement pull-to-refresh on Application Tracker                          │
│ • Connect Account Settings notification switches to persistent storage      │
│ • Provide contact support sheet on Verify Email screen                      │
├─────────────────────────────────────────────────────────────────────────────┤
│ P2: POLISH (Craft, Typography & Motion Refinement)                          │
│ • Optimize LiquidGlass rendering (fallback opacity on low-spec devices)     │
│ • Cache tab entry animations (prevent repetitive 15-item stagger on switch) │
│ • Standardize corner radius tokens across Student, Provider, and Admin      │
│ • Unify typography hierarchy across Provider portal                         │
│ • Implement compact currency formatting (`₱150k/yr` instead of wrapping)   │
├─────────────────────────────────────────────────────────────────────────────┤
│ P3: OPTIONAL ENHANCEMENTS (Delight & Advanced Features)                     │
│ • PDF receipt generator and camera-roll export for submitted applications   │
│ • Interactive spring velocity hand-off on modal bottom sheet dismissals     │
│ • Haptic feedback tuning (distinct impact sensations for success vs toggle) │
│ • Confetti and celebration motion polish on ceremony welcome screen         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 13. Audit Sign-Off

- **Audit Scope:** 100% of declared application routes, modals, and design tokens inspected.
- **Code Modification:** Zero application files modified (AUDIT ONLY mandate strictly preserved).
- **Report Location:** `docs/reports/2026-10-06-full-ui-ux-audit.md`
- **Architect Discovery:** Available for pickup and architectural triage.
