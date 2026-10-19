// test/features/provider/org_activity_log_ui_test.dart
//
// UI Test Suite: OrgActivityLogView
// Verifies:
// 1. Activity Log view renders action filter chips, search input, and log tiles.
// 2. Filter chips switch active filter smoothly.
// 3. Search query filters list items.
// 4. Viewport responsiveness across narrow mobile (360x800), iPhone (440x956), and desktop (1280x800).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/models/organization_activity_log.dart';
import 'package:scholaris/features/provider/presentation/org/org_activity_log_view.dart';
import 'package:scholaris/features/provider/providers/organization_activity_provider.dart';

void main() {
  final sampleLogs = [
    OrganizationActivityLog(
      id: 'log-1',
      actorId: 'admin-1',
      actorName: 'Dr. Santos (Org Admin)',
      action: 'assign_reviewer',
      targetType: 'scholarship',
      targetId: 'sch-101',
      details: {'reviewer_id': 'rev-2'},
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    OrganizationActivityLog(
      id: 'log-2',
      actorId: 'rev-1',
      actorName: 'Prof. Reyes (Reviewer)',
      action: 'approve',
      targetType: 'application',
      targetId: 'app-501',
      details: {'applicant_name': 'Juan Dela Cruz'},
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    OrganizationActivityLog(
      id: 'log-3',
      actorId: 'admin-1',
      actorName: 'Dr. Santos (Org Admin)',
      action: 'award',
      targetType: 'application',
      targetId: 'app-501',
      details: {'amount': 50000},
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Widget createWidget({Size size = const Size(1280, 800)}) {
    return ProviderScope(
      overrides: [
        organizationActivityLogsProvider.overrideWith((ref) async => sampleLogs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: const OrgActivityLogView(),
          ),
        ),
      ),
    );
  }

  group('OrgActivityLogView UI Suite', () {
    testWidgets('Renders header, action filter chips, and log tiles', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Organization Activity Log'), findsOneWidget);
      expect(find.text('All Actions'), findsOneWidget);
      expect(find.text('Approvals'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);

      expect(find.text('Dr. Santos (Org Admin)'), findsNWidgets(2));
      expect(find.text('Prof. Reyes (Reviewer)'), findsOneWidget);
    });

    testWidgets('Tapping filter chip filters displayed log entries', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap Approvals chip
      await tester.tap(find.text('Approvals'));
      await tester.pumpAndSettle();

      expect(find.text('Prof. Reyes (Reviewer)'), findsOneWidget);
      expect(find.text('Dr. Santos (Org Admin)'), findsNothing);
    });

    testWidgets('Search query filters log records', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Reyes');
      await tester.pumpAndSettle();

      expect(find.text('Prof. Reyes (Reviewer)'), findsOneWidget);
      expect(find.text('Dr. Santos (Org Admin)'), findsNothing);
    });

    testWidgets('Responsive rendering: Zero overflow on narrow mobile (360x800)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget(size: const Size(360, 800)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Organization Activity Log'), findsOneWidget);
    });

    testWidgets('Responsive rendering: Zero overflow on large mobile (440x956)', (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget(size: const Size(440, 956)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Organization Activity Log'), findsOneWidget);
    });
  });
}
