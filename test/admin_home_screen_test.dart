import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/admin/screens/applications_oversight_screen.dart';
import 'package:scholaris/admin/screens/audit_trail_screen.dart';
import 'package:scholaris/admin/screens/platform_overview_screen.dart';
import 'package:scholaris/admin/screens/reports_analytics_screen.dart';
import 'package:scholaris/features/admin/presentation/admin_home_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/data/provider_verification_repository.dart';
import 'package:scholaris/features/provider/models/provider_verification.dart';
import 'package:scholaris/features/provider/providers/provider_verification_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

class FakeProviderVerificationRepository extends ProviderVerificationRepository {
  FakeProviderVerificationRepository({List<ProviderVerification>? initial})
      : _items = initial ?? [
          const ProviderVerification(
            userId: 'prov-1',
            providerType: 'organization',
            orgName: 'DOST-SEI',
            status: 'pending',
            repEmail: 'contact@sei.dost.gov.ph',
            regNumber: 'SEC-12345',
            repName: 'Dr. Josette Biyo',
            repPosition: 'Director',
            secCertPath: 'prov-1/sec_reg.pdf',
            bir2303Path: 'prov-1/bir_2303.pdf',
          ),
        ],
        super(
          client: SupabaseClient(
            'https://mock.supabase.co',
            'dummy-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  final List<ProviderVerification> _items;

  @override
  Future<List<ProviderVerification>> fetchAllVerifications() async =>
      List.unmodifiable(_items);

  @override
  Future<ProviderVerification?> fetchVerificationForUser(String userId) async {
    return _items.where((v) => v.userId == userId).firstOrNull;
  }

  @override
  Future<ProviderVerification> submitVerification(
      ProviderVerification verification) async {
    _items.removeWhere((v) => v.userId == verification.userId);
    _items.add(verification);
    return verification;
  }

  @override
  Future<void> updateVerificationStatus({
    required String userId,
    required String status,
    required String adminId,
    String? reviewNote,
  }) async {
    final index = _items.indexWhere((v) => v.userId == userId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        status: status,
        reviewedBy: adminId,
        reviewedAt: DateTime.now(),
        reviewNote: reviewNote,
      );
    }
  }

  @override
  Future<String> getSignedUrl(String storagePath, {int expiresIn = 3600}) async =>
      'https://example.com/signed/$storagePath';

  @override
  Future<String> uploadDocument({
    required String userId,
    required String docType,
    required Uint8List bytes,
    required String fileName,
  }) async =>
      '$userId/$fileName';
}

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('admin-1'),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: FakeScholarshipDataSource([
              {
                ...FakeScholarshipDataSource.defaultRows.first,
                'id': 'sch-0001',
                'title': 'Test Science Grant',
                'provider': 'DOST-SEI',
                'is_active': true,
              },
            ]),
          ),
        ),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: FakeApplicationDataSource(),
            currentUserId: () => 'admin-1',
          ),
        ),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: FakeProfileDataSource(),
            currentUserId: () => 'admin-1',
          ),
        ),
        providerVerificationRepositoryProvider.overrideWithValue(
          FakeProviderVerificationRepository(),
        ),
        platformOverviewDataProvider.overrideWith(
          (ref) => const PlatformOverviewData(
            registeredUsers: 120,
            activeScholarships: 5,
            totalScholarshipValue: 500000,
            applications: 42,
            providerVerifications: 3,
            auditEvents: 15,
            loginAttempts: 8,
            bookmarks: 25,
          ),
        ),
        adminApplicationsProvider.overrideWith(
          (ref) => Future.value([
            ApplicationRecord(
              id: 'app-1',
              userId: 'user-1',
              scholarshipId: 'sch-1',
              status: 'submitted',
              notes: null,
              appliedAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 2),
              applicantName: 'Juan Dela Cruz',
              scholarshipTitle: 'Test Science Grant',
            ),
          ]),
        ),
        reportsAnalyticsDataProvider.overrideWith(
          (ref) => Future.value(
            const ReportsAnalyticsData(
              applicationStatusCounts: {
                'submitted': 5,
                'under_review': 3,
                'approved': 2,
              },
              profileRoleCounts: {
                'student': 100,
                'provider': 10,
                'admin': 2,
              },
              totalScholarshipValue: 250000.0,
              scholarshipCount: 5,
              recentAuditLogs: [],
            ),
          ),
        ),
        auditTrailLogsProvider.overrideWith((ref) => Future.value([])),
      ],
      child: const MaterialApp(
        home: AdminHomeScreen(),
      ),
    );
  }

  group('AdminHomeScreen', () {
    testWidgets('renders Scholaris Admin title and Sign out button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Scholaris Admin'), findsWidgets);
      expect(find.byTooltip('Sign out'), findsOneWidget);
    });

    testWidgets('renders seven navigation destinations', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Scholarships'), findsOneWidget);
      expect(find.text('Providers'), findsOneWidget);
      expect(find.text('Applicants'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Audit Logs'), findsOneWidget);
    });

    testWidgets('overview tab displays metrics and pipeline sections', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Platform Overview'), findsOneWidget);
      expect(find.text('CORE PLATFORM SCALE'), findsOneWidget);
      expect(find.text('REGISTERED USERS'), findsOneWidget);
      expect(find.text('ACTIVE SCHOLARSHIPS'), findsOneWidget);
    });

    testWidgets('switching to Scholarships tab renders catalog with search and chips', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scholarships'));
      await tester.pumpAndSettle();

      expect(find.text('Scholarship Oversight & Moderation'), findsOneWidget);
      expect(find.text('Test Science Grant'), findsOneWidget);
      expect(find.text('DOST-SEI'), findsOneWidget);
    });

    testWidgets('switching to Providers tab renders verification queue', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Providers'));
      await tester.pumpAndSettle();

      expect(find.text('Provider Verifications'), findsOneWidget);
      expect(find.text('DOST-SEI'), findsOneWidget);
    });

    testWidgets('switching to Applicants tab renders student directory', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Applicants'));
      await tester.pumpAndSettle();

      expect(find.text('Applications Oversight'), findsOneWidget);
    });

    testWidgets('switching to Users tab renders user management', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('User Directory & Access Control'), findsOneWidget);
    });

    testWidgets('switching to Analytics tab renders platform analytics', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      expect(find.text('Reports & Analytics'), findsOneWidget);
    });

    testWidgets('switching to Audit Logs tab renders system audit ledger', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Logs'));
      await tester.pumpAndSettle();

      expect(find.text('System Audit Trail'), findsOneWidget);
    });

    testWidgets('tapping Review provider shows accreditation dialog and close dismisses dialog', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Providers'));
      await tester.pumpAndSettle();

      // Find the unverified provider review button
      final reviewBtn = find.text('Review →').first;
      expect(reviewBtn, findsOneWidget);
      await tester.ensureVisible(reviewBtn);
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      // Verify review dialog appeared
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Organization Accreditation Dossier'), findsOneWidget);

      // Tap close button on Dialog
      final closeBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Dialog dismissed and provider review button still exists
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Review →'), findsOneWidget);
    });

    testWidgets('tapping Review and confirming Approve & Accredit verifies provider', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Providers'));
      await tester.pumpAndSettle();

      // Find the unverified provider review button
      final reviewBtn = find.text('Review →').first;
      expect(reviewBtn, findsOneWidget);
      await tester.ensureVisible(reviewBtn);
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      // Verify review dialog appeared
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Organization Accreditation Dossier'), findsOneWidget);

      // Tap Approve & Accredit
      final approveBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Approve & Accredit'),
      );
      expect(approveBtn, findsOneWidget);
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      // Dialog dismissed, provider is now accredited, SnackBar is shown
      expect(find.byType(Dialog), findsNothing);
      expect(find.textContaining('accredited successfully'), findsOneWidget);
    });
  });
}
