# Changed files

App source migration: semantic roles replace font-specific helpers; existing style measurements and colors retained.

| File | Change |
|---|---|
| `lib/admin/screens/admin_settings_screen.dart` | 9 reviewed style calls migrated; inherited styles audited |
| `lib/admin/screens/applications_oversight_screen.dart` | 52 reviewed style calls migrated; inherited styles audited |
| `lib/admin/screens/audit_trail_screen.dart` | 32 reviewed style calls migrated; inherited styles audited |
| `lib/admin/screens/disbursements_oversight_screen.dart` | 24 reviewed style calls migrated; inherited styles audited |
| `lib/admin/screens/platform_overview_screen.dart` | 15 reviewed style calls migrated; inherited styles audited |
| `lib/admin/screens/reports_analytics_screen.dart` | 27 reviewed style calls migrated; inherited styles audited |
| `lib/admin/screens/reports_safety_screen.dart` | 6 reviewed style calls migrated; inherited styles audited |
| `lib/admin/screens/support_concerns_screen.dart` | Explicit semantic roles for inherited styles |
| `lib/admin/widgets/admin_review_priorities.dart` | 7 reviewed style calls migrated; inherited styles audited |
| `lib/app/router.dart` | 3 reviewed style calls migrated; inherited styles audited |
| `lib/dev/provider_preview/main.dart` | Explicit semantic roles for inherited styles |
| `lib/dev/student_navbar_preview/main.dart` | 14 reviewed style calls migrated; inherited styles audited |
| `lib/features/account/presentation/account_settings_screen.dart` | 44 reviewed style calls migrated; inherited styles audited |
| `lib/features/account/presentation/change_email_dialog.dart` | Explicit semantic roles for inherited styles |
| `lib/features/admin/presentation/admin_home_screen.dart` | 6 reviewed style calls migrated; inherited styles audited |
| `lib/features/admin/presentation/admin_login_screen.dart` | 17 reviewed style calls migrated; inherited styles audited |
| `lib/features/admin/presentation/admin_providers_tab.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/features/admin/presentation/admin_scholarships_tab.dart` | 63 reviewed style calls migrated; inherited styles audited |
| `lib/features/admin/presentation/admin_theme.dart` | Remove legacy font helpers; keep colors, surfaces, numeric features |
| `lib/features/admin/presentation/admin_users_tab.dart` | 78 reviewed style calls migrated; inherited styles audited |
| `lib/features/applications/presentation/application_decision_letter.dart` | 9 reviewed style calls migrated; inherited styles audited |
| `lib/features/applications/presentation/application_detail_screen.dart` | 32 reviewed style calls migrated; inherited styles audited |
| `lib/features/applications/presentation/application_status_chip.dart` | 1 reviewed style calls migrated; inherited styles audited |
| `lib/features/applications/presentation/applications_screen.dart` | 57 reviewed style calls migrated; inherited styles audited |
| `lib/features/applications/presentation/student_support_concerns.dart` | Explicit semantic roles for inherited styles |
| `lib/features/applications/presentation/student_support_receipts.dart` | Explicit semantic roles for inherited styles |
| `lib/features/applications/presentation/submission_confirmation_receipt_screen.dart` | 31 reviewed style calls migrated; inherited styles audited |
| `lib/features/applications/presentation/submit_application_review_dialog.dart` | 30 reviewed style calls migrated; inherited styles audited |
| `lib/features/applications/presentation/widgets/document_upload_sheet.dart` | 12 reviewed style calls migrated; inherited styles audited |
| `lib/features/auth/presentation/ceremony_screen.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/features/auth/presentation/forgot_password_screen.dart` | 16 reviewed style calls migrated; inherited styles audited |
| `lib/features/auth/presentation/graduation_ceremony.dart` | 1 reviewed style calls migrated; inherited styles audited |
| `lib/features/auth/presentation/login_screen.dart` | 28 reviewed style calls migrated; inherited styles audited |
| `lib/features/auth/presentation/reset_password_screen.dart` | 19 reviewed style calls migrated; inherited styles audited |
| `lib/features/auth/presentation/signup_screen.dart` | 31 reviewed style calls migrated; inherited styles audited |
| `lib/features/auth/presentation/verify_email_screen.dart` | 18 reviewed style calls migrated; inherited styles audited |
| `lib/features/dashboard/presentation/student_dashboard_screen.dart` | 17 reviewed style calls migrated; inherited styles audited |
| `lib/features/dashboard/presentation/widgets/student_notifications_sheet.dart` | 8 reviewed style calls migrated; inherited styles audited |
| `lib/features/home/presentation/home_screen.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/features/home/presentation/student_chat_screen.dart` | 11 reviewed style calls migrated; inherited styles audited |
| `lib/features/home/presentation/widgets/student_action_sheet.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/features/home/presentation/widgets/student_application_guide.dart` | 5 reviewed style calls migrated; inherited styles audited |
| `lib/features/home/presentation/widgets/student_guide_greeting.dart` | 6 reviewed style calls migrated; inherited styles audited |
| `lib/features/intro/presentation/intro_screen.dart` | 5 reviewed style calls migrated; inherited styles audited |
| `lib/features/onboarding/presentation/onboarding_screen.dart` | 40 reviewed style calls migrated; inherited styles audited |
| `lib/features/profile/presentation/matching_power_sheet.dart` | 13 reviewed style calls migrated; inherited styles audited |
| `lib/features/profile/presentation/profile_setup_screen.dart` | 88 reviewed style calls migrated; inherited styles audited |
| `lib/features/profile/presentation/profile_tab_screen.dart` | 57 reviewed style calls migrated; inherited styles audited |
| `lib/features/profile/presentation/widgets/avatar_selector_sheet.dart` | 11 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/individual/individual_applications_tab.dart` | 26 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/individual/individual_grant_tab.dart` | 14 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/individual/individual_provider_shell.dart` | 8 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/individual/individual_settings_tab.dart` | 14 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/individual/individual_support_tab.dart` | 12 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_activity_log_view.dart` | 16 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_analytics_tab.dart` | 90 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_disbursements_tab.dart` | 92 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_incoming_applications_tab.dart` | 56 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_provider_shell.dart` | 31 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_provider_theme.dart` | Remove legacy font helpers; keep colors, surfaces, numeric features |
| `lib/features/provider/presentation/org/org_review_analytics_tab.dart` | 13 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_scholarships_tab.dart` | 46 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_settings_tab.dart` | 80 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/org_team_view.dart` | 23 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/org/widgets/assign_reviewer_dialog.dart` | 12 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/provider_application_detail_screen.dart` | 39 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/provider_incoming_applications.dart` | 19 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/provider_login_screen.dart` | 46 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/provider_review_screen.dart` | 3 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/provider_scholarships_tab.dart` | 25 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/provider_signup_screen.dart` | 58 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/scholarship_form_screen.dart` | 40 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/widgets/applicant_review_drawer.dart` | 68 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/widgets/individual_support_summary.dart` | 1 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/widgets/org_overview_workspace.dart` | 19 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/widgets/org_review_snapshot.dart` | 6 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/widgets/org_summary_disclosure.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/widgets/provider_overview_panel.dart` | 15 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/widgets/provider_verification_banner.dart` | 7 reviewed style calls migrated; inherited styles audited |
| `lib/features/provider/presentation/widgets/scholarship_qr_dialog.dart` | 6 reviewed style calls migrated; inherited styles audited |
| `lib/features/safety/presentation/student_safety_report.dart` | 8 reviewed style calls migrated; inherited styles audited |
| `lib/features/scholarships/presentation/discovery_filter_sheet.dart` | 10 reviewed style calls migrated; inherited styles audited |
| `lib/features/scholarships/presentation/scholarship_detail_screen.dart` | 95 reviewed style calls migrated; inherited styles audited |
| `lib/features/scholarships/presentation/scholarship_qr_scanner_screen.dart` | 11 reviewed style calls migrated; inherited styles audited |
| `lib/features/scholarships/presentation/widgets/identity_photo_dialog.dart` | 8 reviewed style calls migrated; inherited styles audited |
| `lib/features/scholarships/screens/discover_screen.dart` | 20 reviewed style calls migrated; inherited styles audited |
| `lib/features/scholarships/screens/saved_screen.dart` | 21 reviewed style calls migrated; inherited styles audited |
| `lib/features/splash/presentation/splash_screen.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/shared/theme/app_motion.dart` | 1 reviewed style calls migrated; inherited styles audited |
| `lib/shared/theme/app_theme.dart` | Shared theme and implicit component typography |
| `lib/shared/widgets/logout_confirmation_dialog.dart` | 4 reviewed style calls migrated; inherited styles audited |
| `lib/shared/widgets/primary_button.dart` | 1 reviewed style calls migrated; inherited styles audited |
| `lib/shared/widgets/radial_matching_gauge.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/shared/widgets/save_draft_dialog.dart` | 5 reviewed style calls migrated; inherited styles audited |
| `lib/shared/widgets/scholaris_logo.dart` | 1 reviewed style calls migrated; inherited styles audited |
| `lib/shared/widgets/scholarship_card.dart` | 12 reviewed style calls migrated; inherited styles audited |
| `lib/shared/widgets/section_header.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/shared/widgets/state_views.dart` | 8 reviewed style calls migrated; inherited styles audited |
| `lib/shared/widgets/success_overlay.dart` | 2 reviewed style calls migrated; inherited styles audited |
| `lib/shared/theme/app_typography.dart` | Central platform resolver and semantic typography API |
| `assets/fonts/inter/Inter-Regular.ttf` | Local official Inter 4.1 asset/license |
| `assets/fonts/inter/Inter-Medium.ttf` | Local official Inter 4.1 asset/license |
| `assets/fonts/inter/Inter-SemiBold.ttf` | Local official Inter 4.1 asset/license |
| `assets/fonts/inter/Inter-Bold.ttf` | Local official Inter 4.1 asset/license |
| `assets/fonts/inter/OFL.txt` | Local official Inter 4.1 asset/license |
| `tools/check_typography.mjs` | Source guard and font asset verification |
| `tools/check_typography.test.mjs` | Source guard and font asset verification |
| `tools/capture_typography_web.mjs` | Reproducible matched browser captures |
| `test/shared/theme/app_typography_test.dart` | Typography, platform, accessibility or visual regression coverage |
| `test/shared/theme/semantic_theme_test.dart` | Typography, platform, accessibility or visual regression coverage |
| `test/shared/theme/semantic_widgets_test.dart` | Typography, platform, accessibility or visual regression coverage |
| `test/shared/theme/reference_typography_test.dart` | Typography, platform, accessibility or visual regression coverage |
| `test/typography_visual_capture_test.dart` | Typography, platform, accessibility or visual regression coverage |
| `test/scholarship_card_test.dart` | Use bundled Inter in font-loading fixtures or assert approved navigation weight |
| `test/student_application_guide_test.dart` | Use bundled Inter in font-loading fixtures or assert approved navigation weight |
| `test/student_detail_tour_test.dart` | Use bundled Inter in font-loading fixtures or assert approved navigation weight |
| `test/student_frosted_nav_test.dart` | Use bundled Inter in font-loading fixtures or assert approved navigation weight |
| `test/student_quick_actions_polish_test.dart` | Use bundled Inter in font-loading fixtures or assert approved navigation weight |
| `test/shared/theme/geist_typography_test.dart` | Renamed to reference_typography_test.dart; asserts Inter offline |
| `pubspec.yaml` | Register Inter 400/500/600/700; remove unused Geist registration; retain original Geist files |
| `AGENTS.md` | Approved platform fonts, role weights, preservation and validation rules |
| `docs/reports/2026-11-04-typography/` | Handoff, review evidence, execution ledger and matched screenshots |
| `test/hero_section_test.dart` | Pin dashboard greeting and opportunity hero weight at 700 |
| `test/student_chat_screen_test.dart` | Pin personalized chat greeting weight at 700 |
| `test/screenshots/generate_stitch_screenshots_test.dart` | Replace legacy font aliases with genuine Inter; apply central typography to the legacy screenshot preview theme |
