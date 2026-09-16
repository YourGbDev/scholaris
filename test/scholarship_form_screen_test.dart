import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/provider/presentation/scholarship_form_screen.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_scholarship_data_source.dart';

void main() {
  Widget buildApp({
    required FakeScholarshipDataSource dataSource,
    Scholarship? initialScholarship,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('prov-1'),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(dataSource: dataSource),
        ),
      ],
      child: MaterialApp(
        home: ScholarshipFormScreen(
          initialScholarship: initialScholarship,
        ),
      ),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('ScholarshipFormScreen', () {
    testWidgets('renders create mode fields and validates empty title', (tester) async {
      configureViewport(tester);

      final fakeDs = FakeScholarshipDataSource([]);

      await tester.pumpWidget(buildApp(dataSource: fakeDs));
      await tester.pumpAndSettle();

      expect(find.text('New Scholarship'), findsOneWidget);
      expect(find.text('Scholarship Title *'), findsOneWidget);
      expect(find.text('Publish Listing'), findsOneWidget);

      // Tap Publish Listing without filling title
      await tester.tap(find.text('Publish Listing'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('creates a new scholarship successfully', (tester) async {
      configureViewport(tester);

      final fakeDs = FakeScholarshipDataSource([]);

      await tester.pumpWidget(buildApp(dataSource: fakeDs));
      await tester.pumpAndSettle();

      // Enter Title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Scholarship Title *'),
        'Future Builders STEM Grant',
      );

      // Enter Organization
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Provider / Organization Name'),
        'Future Foundation',
      );

      // Enter slots
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Available Slots'),
        '25',
      );

      await tester.pumpAndSettle();

      // Tap Publish Listing
      await tester.tap(find.text('Publish Listing'));
      await tester.pumpAndSettle();

      // Verify row created in data source
      expect(fakeDs.rows.length, 1);
      final created = fakeDs.rows.first;
      expect(created['title'], 'Future Builders STEM Grant');
      expect(created['provider'], 'Future Foundation');
      expect(created['slots'], 25);
      expect(created['created_by'], 'prov-1');
    });

    testWidgets('renders edit mode and pre-fills existing data', (tester) async {
      configureViewport(tester);

      final existing = Scholarship(
        id: 'sch-existing',
        title: 'Existing Tech Grant',
        provider: 'Tech Innovators',
        description: 'For budding developers.',
        minGpa: 2.5,
        deadline: DateTime(2026, 12, 1),
        slots: 100,
        isActive: true,
        createdBy: 'prov-1',
      );

      final fakeDs = FakeScholarshipDataSource([
        {
          'id': 'sch-existing',
          'title': 'Existing Tech Grant',
          'provider': 'Tech Innovators',
          'description': 'For budding developers.',
          'min_gpa': 2.5,
          'deadline': '2026-12-01',
          'slots': 100,
          'is_active': true,
          'created_by': 'prov-1',
        }
      ]);

      await tester.pumpWidget(
        buildApp(dataSource: fakeDs, initialScholarship: existing),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Scholarship'), findsOneWidget);
      expect(find.text('Existing Tech Grant'), findsOneWidget);
      expect(find.text('Tech Innovators'), findsOneWidget);
      expect(find.text('Update Listing'), findsOneWidget);

      // Change title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Scholarship Title *'),
        'Updated Tech Grant 2026',
      );
      await tester.pumpAndSettle();

      // Tap Update Listing
      await tester.tap(find.text('Update Listing'));
      await tester.pumpAndSettle();

      final updated = fakeDs.rows.firstWhere((r) => r['id'] == 'sch-existing');
      expect(updated['title'], 'Updated Tech Grant 2026');
    });
  });
}
