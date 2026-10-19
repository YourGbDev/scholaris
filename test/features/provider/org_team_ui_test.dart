// test/features/provider/org_team_ui_test.dart
//
// UI Test Suite: OrgTeamView
// Verifies:
// 1. Team roster view renders KPI bento summary cards (Total Staff, Reviewers, Finance, Admins).
// 2. Role filter chips ('All Roles', 'Evaluators', 'Finance', 'Org Admins') filter roster items.
// 3. Search query filters staff by name and role.
// 4. 'Assign Grants' button opens scholarship selection and assigns grants.
// 5. Responsive layout across viewports: 360x800, 440x956, and 1280x800 without RenderFlex overflow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/models/organization_team_member.dart';
import 'package:scholaris/features/provider/presentation/org/org_team_view.dart';
import 'package:scholaris/features/provider/providers/organization_team_provider.dart';
import 'package:scholaris/features/provider/providers/provider_scholarships_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';

class _FakeProviderScholarshipsNotifier extends ProviderScholarshipsNotifier {
  _FakeProviderScholarshipsNotifier(this._data);
  final List<Scholarship> _data;

  @override
  Future<List<Scholarship>> build() async => _data;
}

void main() {
  final sampleRoster = [
    const OrganizationTeamMember(
      userId: 'u-admin-1',
      fullName: 'Dr. Maria Santos',
      role: 'org_admin',
      active: true,
    ),
    const OrganizationTeamMember(
      userId: 'u-rev-1',
      fullName: 'Prof. Juan Reyes',
      role: 'reviewer',
      active: true,
      assignedScholarshipCount: 2,
    ),
    const OrganizationTeamMember(
      userId: 'u-fin-1',
      fullName: 'Elena Cruz',
      role: 'finance',
      active: true,
    ),
    const OrganizationTeamMember(
      userId: 'u-rev-2',
      fullName: 'Carlos Diaz',
      role: 'reviewer',
      active: false,
      assignedScholarshipCount: 0,
    ),
  ];

  final sampleScholarships = [
    Scholarship(
      id: 'sch-101',
      title: 'Ayala Future Leaders STEM Grant',
      minGpa: 1.75,
      deadline: DateTime.now().add(const Duration(days: 30)),
      amount: 75000,
    ),
  ];

  Widget createWidget({Size size = const Size(1280, 800)}) {
    return ProviderScope(
      overrides: [
        organizationRosterProvider.overrideWith((ref) async => sampleRoster),
        providerScholarshipsProvider.overrideWith(
          () => _FakeProviderScholarshipsNotifier(sampleScholarships),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: const OrgTeamView(),
          ),
        ),
      ),
    );
  }

  group('OrgTeamView UI Suite', () {
    testWidgets('Renders KPI bento cards, role filter chips, and roster entries', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Team & Reviewers'), findsOneWidget);
      expect(find.text('TOTAL STAFF'), findsOneWidget);
      expect(find.text('EVALUATORS'), findsOneWidget);
      expect(find.text('DISBURSING'), findsOneWidget);
      expect(find.text('ADMINS'), findsOneWidget);

      expect(find.text('All Roles'), findsOneWidget);
      expect(find.text('Evaluators'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Org Admins'), findsOneWidget);

      expect(find.text('Dr. Maria Santos'), findsOneWidget);
      expect(find.text('Prof. Juan Reyes'), findsOneWidget);
      expect(find.text('Elena Cruz'), findsOneWidget);
      expect(find.text('Carlos Diaz'), findsOneWidget);

      // 'Assign Grants' button should appear for active reviewer Prof. Juan Reyes
      expect(find.text('Assign Grants'), findsOneWidget);
    });

    testWidgets('Tapping role filter chip filters displayed staff', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap Evaluators chip
      await tester.tap(find.text('Evaluators'));
      await tester.pumpAndSettle();

      expect(find.text('Prof. Juan Reyes'), findsOneWidget);
      expect(find.text('Carlos Diaz'), findsOneWidget);
      expect(find.text('Dr. Maria Santos'), findsNothing);
      expect(find.text('Elena Cruz'), findsNothing);
    });

    testWidgets('Search query filters staff by name', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Elena');
      await tester.pumpAndSettle();

      expect(find.text('Elena Cruz'), findsOneWidget);
      expect(find.text('Prof. Juan Reyes'), findsNothing);
      expect(find.text('Dr. Maria Santos'), findsNothing);
    });

    testWidgets('Tapping Assign Grants opens grant selector dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final assignBtn = find.text('Assign Grants');
      expect(assignBtn, findsOneWidget);

      await tester.tap(assignBtn);
      await tester.pumpAndSettle();

      expect(find.text('Select Grant Program for Prof. Juan Reyes'), findsOneWidget);
      expect(find.text('Ayala Future Leaders STEM Grant'), findsOneWidget);
    });

    testWidgets('Responsive rendering: Zero overflow on narrow mobile (360x800)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget(size: const Size(360, 800)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Team & Reviewers'), findsOneWidget);
    });

    testWidgets('Responsive rendering: Zero overflow on large mobile (440x956)', (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget(size: const Size(440, 956)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Team & Reviewers'), findsOneWidget);
    });
  });
}
