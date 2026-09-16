import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/provider_scholarships_tab.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

void main() {
  Widget buildApp({
    required FakeScholarshipDataSource scholarships,
    FakeApplicationDataSource? applications,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('prov-1'),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(dataSource: scholarships),
        ),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: applications ?? FakeApplicationDataSource(),
            currentUserId: () => 'prov-1',
          ),
        ),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: FakeProfileDataSource(),
            currentUserId: () => 'prov-1',
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: ProviderScholarshipsTab(),
        ),
      ),
    );
  }

  group('ProviderScholarshipsTab', () {
    testWidgets('renders header, metrics, and scholarship cards', (tester) async {
      final fakeDs = FakeScholarshipDataSource([
        {
          'id': 'sch-1',
          'title': 'DOST Priority Grant',
          'provider': 'DOST',
          'description': 'Tech grants for university students.',
          'min_gpa': 2.0,
          'deadline': '2026-10-15',
          'slots': 50,
          'is_active': true,
          'created_by': 'prov-1',
        },
        {
          'id': 'sch-2',
          'title': 'Closed Arts Bursary',
          'provider': 'Cultural Center',
          'description': 'Grant for artists.',
          'min_gpa': 2.5,
          'deadline': '2026-09-01',
          'slots': 10,
          'is_active': false,
          'created_by': 'prov-1',
        },
      ]);

      await tester.pumpWidget(buildApp(scholarships: fakeDs));
      await tester.pumpAndSettle();

      expect(find.text('My Scholarships'), findsOneWidget);
      expect(find.text('New Program'), findsOneWidget);
      expect(find.text('DOST Priority Grant'), findsOneWidget);
      expect(find.text('Closed Arts Bursary'), findsOneWidget);

      // Status pills
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Closed'), findsWidgets);
    });

    testWidgets('renders empty view when provider has no scholarships', (tester) async {
      final emptyDs = FakeScholarshipDataSource([]);

      await tester.pumpWidget(buildApp(scholarships: emptyDs));
      await tester.pumpAndSettle();

      expect(find.text('No scholarship programs yet'), findsOneWidget);
      expect(find.text('Create First Scholarship'), findsOneWidget);
    });

    testWidgets('filters listings by Active and Closed chips', (tester) async {
      final fakeDs = FakeScholarshipDataSource([
        {
          'id': 'sch-1',
          'title': 'Active Tech Award',
          'min_gpa': 2.0,
          'deadline': '2026-10-15',
          'is_active': true,
          'created_by': 'prov-1',
        },
        {
          'id': 'sch-2',
          'title': 'Closed Music Award',
          'min_gpa': 2.5,
          'deadline': '2026-09-01',
          'is_active': false,
          'created_by': 'prov-1',
        },
      ]);

      await tester.pumpWidget(buildApp(scholarships: fakeDs));
      await tester.pumpAndSettle();

      expect(find.text('Active Tech Award'), findsOneWidget);
      expect(find.text('Closed Music Award'), findsOneWidget);

      // Tap Active filter chip
      await tester.tap(find.widgetWithText(InkWell, 'Active'));
      await tester.pumpAndSettle();

      expect(find.text('Active Tech Award'), findsOneWidget);
      expect(find.text('Closed Music Award'), findsNothing);

      // Tap Closed filter chip
      await tester.tap(find.widgetWithText(InkWell, 'Closed'));
      await tester.pumpAndSettle();

      expect(find.text('Active Tech Award'), findsNothing);
      expect(find.text('Closed Music Award'), findsOneWidget);
    });

    testWidgets('tapping delete icon shows confirmation dialog and deletes item', (tester) async {
      final fakeDs = FakeScholarshipDataSource([
        {
          'id': 'sch-1',
          'title': 'Scholarship To Delete',
          'min_gpa': 2.0,
          'deadline': '2026-10-15',
          'is_active': true,
          'created_by': 'prov-1',
        },
      ]);

      await tester.pumpWidget(buildApp(scholarships: fakeDs));
      await tester.pumpAndSettle();

      expect(find.text('Scholarship To Delete'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byTooltip('Delete Scholarship'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Scholarship?'), findsOneWidget);

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Scholarship To Delete'), findsNothing);
      expect(find.text('No scholarship programs yet'), findsOneWidget);
    });
  });
}
