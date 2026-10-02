# Scholaris Implementation & Changes Report

**Date:** September 30, 2026  
**Target:** `scholaris` Codebase  
**Focus Area:** Apple Design DNA & Apple HIG Motion/Typography Audit & Implementation  

---

## 1. Executive Summary

This report documents the architectural improvements, motion integration, gesture refactoring, and typography alignments implemented in the Scholaris application. 

The most recent implementation specifically addresses 5 core Apple Design DNA & Human Interface Guidelines (HIG) compliance issues in the **Student Dashboard** (`lib/features/dashboard/presentation/student_dashboard_screen.dart`).

---

## 2. Recent Implementation: Student Dashboard Refactor

**File:** `lib/features/dashboard/presentation/student_dashboard_screen.dart`  
**Static Analysis Status:** Clean (`dart analyze lib/features/dashboard/` → 0 issues found).

### Fix 1 — Entrance Springs (First-Load Stagger Only)
* **Problem:** Top-level dashboard sections previously mounted statically without animated entrance transitions, making the initial dashboard load feel rigid and non-fluid.
* **Solution:**
  - Added `_hasAnimated` state tracking inside `_StudentDashboardScreenState`.
  - Registered a post-frame callback in `initState()` to flip `_hasAnimated = true` after the initial render.
  - Implemented the `_wrapSection({required int index, required Widget child})` helper.
  - On the first mount, sections stagger smoothly using `StaggeredListItem` driven by Apple's critically damped reposition spring (`AppleSpringDescription.pip`) with an incremental 50ms stagger delay (`staggerMs: 50`).
  - On subsequent renders or state updates, `_hasAnimated` bypasses the wrapper and renders children directly without re-triggering animations.
* **Sections Staggered in Sequence:**
  1. Sticky Header (`index: 0`)
  2. Date & Dynamic Tagalog Greeting (`index: 1`)
  3. Free-Floating Mascot Hero Section (`index: 2`)
  4. Active Application Banner (`index: 3`, if active)
  5. Quick-Stat 3-Tile Grid (`index: 4`)
  6. Pro-Tip for Applicants Bento Box (`index: 5`)

---

### Fix 2 — Apple Optical Typography (Tracking & Leading)
* **Problem:** Hardcoded typography values diverged from Apple HIG optical sizing standards, leading to inconsistent text density and cramped line heights.
* **Solution:**
  - **17pt Section Header ("Top Recommended For You"):**
    - Updated `letterSpacing` from `-0.3` to `-0.34` (strictly adhering to $17 \times -0.02\text{em} = -0.34\text{px}$).
  - **16pt Section Header ("Closing Soon"):**
    - Added explicit optical negative tracking: `letterSpacing: -0.32` ($16 \times -0.02\text{em} = -0.32\text{px}$).
  - **Body Text Leading ("Match Count Banner"):**
    - Increased `openSans` height multiplier from `1.3` to `1.45` to match Apple HIG relaxed body reading metrics and prevent clipping on dynamic fonts.
  - **Body Text Leading ("Pro-Tip Bento Box RichText"):**
    - Increased `openSans` height multiplier from `1.4` to `1.45`.

---

### Fix 3 — Direct Manipulation Gesture Conflict Resolution
* **Problem:** Inside the top bar header, the student profile avatar button had a `GestureDetector` nested *inside* a `PressableScale` widget while `PressableScale.onTap` was set to `null`. The child `GestureDetector` intercepted touch events before `PressableScaleState._onPointerDown` could fire, causing the scale-down spring effect to be swallowed.
* **Solution:**
  - Removed the nested `GestureDetector` entirely.
  - Moved the navigation callback (`ref.read(homeTabIndexProvider.notifier).selectTab(3);`) directly onto `PressableScale.onTap`.
  - The avatar button now smoothly scales down with Apple snappy press feedback on pointer down and triggers navigation on release.

---

### Fix 4 — Apple Bouncing Scroll Physics with AlwaysScrollable
* **Problem:** The outer `ListView` used `const AppleBouncingScrollPhysics()`. On larger viewports or devices with short content where the list does not exceed viewport height, the physics engine defaulted to clamping, disabling pull-to-refresh and Apple boundary rubber-banding.
* **Solution:**
  - Chained the scroll physics with `parent: AlwaysScrollableScrollPhysics()`:
    ```dart
    physics: const AppleBouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    ```
  - Pull-to-refresh and rubber-band boundary resistance now engage consistently across all screen heights.

---

## 3. Side-by-Side Code Diffs

### A. State Tracking & Stagger Helper
```diff
@@ -48,6 +48,23 @@ class StudentDashboardScreen extends ConsumerStatefulWidget {
 class _StudentDashboardScreenState
     extends ConsumerState<StudentDashboardScreen> {
+  bool _hasAnimated = false;
+
+  @override
+  void initState() {
+    super.initState();
+    WidgetsBinding.instance.addPostFrameCallback((_) {
+      _hasAnimated = true;
+    });
+  }
+
+  Widget _wrapSection({required int index, required Widget child}) {
+    if (_hasAnimated) return child;
+    return StaggeredListItem(
+      index: index,
+      staggerMs: 50,
+      spring: AppleSpringDescription.pip,
+      child: child,
+    );
+  }
```

### B. Outer Scroll Physics & Section Wrapping
```diff
@@ -130,17 +132,26 @@ class _StudentDashboardScreenState
             child: ListView(
-              physics: const AppleBouncingScrollPhysics(),
+              physics: const AppleBouncingScrollPhysics(
+                parent: AlwaysScrollableScrollPhysics(),
+              ),
               padding: EdgeInsets.fromLTRB(
                 20,
                 16,
                 20,
                 MediaQuery.of(context).padding.bottom + 64 + 16,
               ),
               children: [
                 // 1. Sticky Header
-                _buildHeader(context, ref, avatarState),
+                _wrapSection(
+                  index: 0,
+                  child: _buildHeader(context, ref, avatarState),
+                ),
                 const SizedBox(height: 16),
 
                 // 2. Date & Dynamic Tagalog Greeting
-                _buildDateAndGreeting(greetingName),
+                _wrapSection(
+                  index: 1,
+                  child: _buildDateAndGreeting(greetingName),
+                ),
                 const SizedBox(height: 6),
 
                 // 3. Free-Floating Mascot Hero Section
-                _buildMascotHeroSection(
+                _wrapSection(
+                  index: 2,
+                  child: _buildMascotHeroSection(
                     profile: profile,
                     matchCount: info.matchCount > 0 ? info.matchCount : matches.length,
                   ),
```

### C. Gesture Conflict Removal on Avatar Button
```diff
@@ -310,13 +320,11 @@ class _StudentDashboardScreenState
             const SizedBox(width: 4),
 
             // Profile Avatar
             PressableScale(
-              child: GestureDetector(
-                onTap: () {
-                  ref.read(homeTabIndexProvider.notifier).selectTab(3);
-                },
-                child: Container(
+              onTap: () {
+                ref.read(homeTabIndexProvider.notifier).selectTab(3);
+              },
+              child: Container(
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     border: Border.all(color: const Color(0xFFE2E8F9), width: 1.5),
                   ),
```

### D. Typography Leading & Tracking
```diff
@@ -744,7 +744,7 @@ class _StudentDashboardScreenState
                   fontSize: 17,
                   fontWeight: FontWeight.bold,
                   color: const Color(0xFF161C27),
-                  letterSpacing: -0.3,
+                  letterSpacing: -0.34,
                 ),
               ),
             ),
@@ -942,7 +942,7 @@ class _StudentDashboardScreenState
                     fontSize: 12.5,
                     fontWeight: FontWeight.w500,
                     color: Colors.white,
-                    height: 1.3,
+                    height: 1.45,
                   ),
                 ),
               ],
@@ -1066,6 +1066,7 @@ class _StudentDashboardScreenState
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
                 color: const Color(0xFF93000A),
+                letterSpacing: -0.32,
               ),
             ),
           ],
@@ -1150,7 +1150,7 @@ class _StudentDashboardScreenState
                     style: openSans(
                       fontSize: 12,
                       color: const Color(0xFF404942),
-                      height: 1.4,
+                      height: 1.45,
                     ),
                     children: [
                       const TextSpan(
```

---

## 4. Summary of Overall System Changes in the Workspace

Beyond the dashboard screen, the ongoing evolution of the codebase encompasses:

1. **Apple Motion System (`lib/shared/theme/app_motion.dart`)**:
   - Critically damped (`AppleSpringDescription.critical`, `AppleSpringDescription.pip`) and snappy momentum springs.
   - Apple logarithmic rubber-banding resistance formula ($f(x, d, c) = \frac{x \cdot d \cdot c}{d + c \cdot |x|}$).
   - `LiquidGlass` translucent frosted glass components with 20px blur, 180% saturation boost, and light-edge reflection borders.
   - Optical typography tracking and leading helpers (`opticalTracking`, `opticalLeading`).
2. **Application Documents Feature**:
   - New database migrations: `supabase/migrations/0017_application_documents.sql` and `0018_secure_storage_application_documents.sql`.
   - Data models and repositories: `application_document.dart`, `application_document_repository.dart`, and Riverpod providers.
3. **Scholarship QR Code Flow**:
   - Implemented provider QR code dialog (`scholarship_qr_dialog.dart`) and student-facing scanner (`scholarship_qr_scanner_screen.dart`).
4. **Provider & Admin Consoles Alignment**:
   - Sequoia design tokens applied across organization and individual provider shells, incoming applications tabs, and audit trails.

---

## 5. Recommended Git Commit

To commit the verified student dashboard modifications:

```bash
git add lib/features/dashboard/presentation/student_dashboard_screen.dart report/REPORT.md
git commit -m "fix(dashboard): entrance springs, typography, scroll physics, gesture fix"
```
