import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/admin/presentation/admin_home_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

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
                'id': 'sch-1',
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

      expect(find.text('Scholaris Admin'), findsOneWidget);
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

      expect(find.text('System Overview'), findsOneWidget);
      expect(find.text('Active Scholarships'), findsOneWidget);
      expect(find.text('Total Applications'), findsOneWidget);
      expect(find.text('Application Pipeline'), findsOneWidget);
    });

    testWidgets('switching to Scholarships tab renders catalog with search and chips', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scholarships'));
      await tester.pumpAndSettle();

      expect(find.text('Scholarship Catalog'), findsOneWidget);
      expect(find.text('Test Science Grant'), findsOneWidget);
      expect(find.text('DOST-SEI'), findsOneWidget);
    });

    testWidgets('switching to Providers tab renders verification queue', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Providers'));
      await tester.pumpAndSettle();

      expect(find.text('Provider Verification'), findsOneWidget);
      expect(find.text('DOST-SEI'), findsOneWidget);
    });

    testWidgets('switching to Applicants tab renders student directory', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Applicants'));
      await tester.pumpAndSettle();

      expect(find.text('Student Directory'), findsOneWidget);
    });

    testWidgets('switching to Users tab renders user management', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('User Management'), findsOneWidget);
    });

    testWidgets('switching to Analytics tab renders platform analytics', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      expect(find.text('Platform Analytics'), findsOneWidget);
    });

    testWidgets('switching to Audit Logs tab renders system audit ledger', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audit Logs'));
      await tester.pumpAndSettle();

      expect(find.text('System Audit Ledger'), findsOneWidget);
      expect(find.text('Audit logging infrastructure readiness'), findsOneWidget);
    });

    testWidgets('tapping Verify & Approve Provider shows confirmation dialog and Cancel aborts approval', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Providers'));
      await tester.pumpAndSettle();

      // Find the unverified provider button
      final approveBtn = find.widgetWithText(FilledButton, 'Verify & Approve Provider').first;
      expect(approveBtn, findsOneWidget);
      await tester.ensureVisible(approveBtn);
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Approve Provider'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed and provider is still unverified (button still exists)
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Verify & Approve Provider'), findsWidgets);
    });

    testWidgets('tapping Verify & Approve Provider and confirming Approve verifies provider', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Providers'));
      await tester.pumpAndSettle();

      // Find the unverified provider button
      final approveBtn = find.widgetWithText(FilledButton, 'Verify & Approve Provider').first;
      expect(approveBtn, findsOneWidget);
      await tester.ensureVisible(approveBtn);
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Approve Provider'), findsOneWidget);

      // Tap Approve
      final confirmApprove = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Approve'),
      );
      expect(confirmApprove, findsOneWidget);
      await tester.tap(confirmApprove);
      await tester.pumpAndSettle();

      // Dialog dismissed, provider is now verified, SnackBar is shown
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('has been verified and approved.'), findsOneWidget);
    });
  });
}
