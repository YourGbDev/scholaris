# Task Card: Builder (Master Remediation)

> **Assigned Role**: 🔨 Builder (`ai/builder`)  
> **Assigned Worktree**: `.../scholaris/cowrie`  
> **Master Plan**: `docs/plans/2026-10-06_master_remediation_plan.md`  
> **Status**: `AWAITING HUMAN APPROVAL`

---

## 1. Objectives (WS-1 & WS-2 Focus)
Resolve core domain validation traps, routing defects, dead-end chips, and draft state persistence.

---

## 2. Allowed Files to Modify
* `lib/features/profile/models/profile_validator.dart`
* `lib/features/profile/models/student_profile.dart`
* `lib/features/profile/presentation/profile_setup_screen.dart`
* `lib/features/scholarships/services/matching_engine.dart`
* `lib/features/scholarships/screens/discover_screen.dart`
* `lib/features/scholarships/presentation/scholarship_detail_screen.dart`
* `lib/features/auth/presentation/verify_email_screen.dart`
* `lib/features/auth/presentation/ceremony_screen.dart`
* `lib/app/router.dart`
* `test/features/profile/...`
* `test/features/scholarships/...`

---

## 3. Implementation Checklist
- [ ] **Fix Finding 3.2.1**: Update `ProfileValidator.validateGpa` to support Philippine 1.0–5.0 scale, 4.0 scale, and percentage scale. Update `MatchingEngine` scale comparison semantics.
- [ ] **Fix Finding 3.2.2**: Update route on `ProfileTabScreen` location edit badge to route to `/profile-setup/financial?focus=location` (avoiding 404).
- [ ] **Fix Finding 3.3.1**: Connect Discovery filter chips ("Match >90%", "₱50k - ₱150k+") to Riverpod's `scholarshipFilterProvider`.
- [ ] **Fix Finding 3.3.3**: Sync recommender input state into `applicationDraftProvider` so data is not lost on screen transitions.
- [ ] **Fix Finding 3.1.1**: Wire "Need help? Contact Support" on `VerifyEmailScreen` to an actionable support dialog or mailto trigger.
- [ ] **Fix Finding 3.1.2**: Cancel ceremony auto-navigation timer inside `dispose()` and on button tap.

---

## 4. Verification Requirements
* `flutter analyze <modified-paths>` must exit with 0 errors.
* Unit tests for GPA validation and Matching Engine must pass: `flutter test test/features/profile/` and `flutter test test/features/scholarships/`.

---

## 5. Output Report
Save report to: `docs/reports/remediation_builder_report.md`
Commit to branch `ai/builder`:
```bash
git add <modified-files> docs/reports/remediation_builder_report.md
git commit -m "feat(builder): implement WS-1 and WS-2 remediation fixes"
```
