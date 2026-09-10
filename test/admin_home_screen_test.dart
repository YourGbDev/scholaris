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

    testWidgets('renders three navigation destinations', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Scholarships'), findsOneWidget);
      expect(find.text('Providers'), findsOneWidget);
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
  });
}
