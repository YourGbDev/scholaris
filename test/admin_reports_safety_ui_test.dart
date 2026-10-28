import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/admin/models/safety_report_presentation.dart';
import 'package:scholaris/admin/screens/reports_safety_screen.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/safety/data/safety_report_repository.dart';
import 'package:scholaris/features/safety/models/safety_report.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/admin/presentation/admin_analytics_provider.dart';
import 'package:scholaris/features/provider/repositories/support_concern_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';

class FakeSafetyReportRepository extends SafetyReportRepository {
  final List<SafetyReport> reports;
  FakeSafetyReportRepository([this.reports = const []]);

  @override
  Future<List<SafetyReport>> fetchAllReportsForAdmin() async => reports;
}

final apps = [const Application(id: 'a', userId: 'u', scholarshipId: 's')];
final programs = [
  Scholarship(
    id: 's',
    title: 'Community scholarship',
    provider: 'Community foundation',
    createdBy: 'p',
    minGpa: 2,
    deadline: DateTime(2027),
  ),
];

Map<String, dynamic> report(
  String id,
  String reporter, {
  String category = 'other',
  String application = 'a',
  String status = 'open',
}) => {
  'id': id,
  'application_id': application,
  'reporter_id': reporter,
  'category': category,
  'status': status,
  'description': 'Private concern details',
  'created_at': '2026-10-24T01:00:00Z',
};

void main() {
  test('counts people separately from reports and excludes corrections', () {
    final groups = groupSafetyReports(
      [
        report('1', 'u'),
        report('2', 'u', category: 'unsafe_request'),
        report('3', 'v'),
        report('4', 'provider', category: 'payment_record_correction'),
      ],
      apps,
      programs,
      now: DateTime.utc(2026, 10, 24, 5),
    );
    expect(groups, hasLength(1));
    final g = groups.single;
    expect(g.totalReports, 3);
    expect(g.distinctReporters, 2);
    expect(g.recentDistinctReporters, 2);
    expect(g.openReports, 3);
    expect(g.urgent, true);
    expect(g.providerId, 'p');
  });

  test(
    'missing context never merges unrelated applications or missing IDs',
    () {
      final groups = groupSafetyReports(
        [
          report('1', 'u', application: 'missing'),
          report('2', 'u', application: 'other'),
          report('3', 'u', application: ''),
          report('4', 'u', application: ''),
        ],
        [],
        [],
      );
      expect(groups, hasLength(4));
      expect(groups.every((g) => g.scholarshipId == null), true);
    },
  );

  test('closed urgent reports and future timestamps do not create urgency or recent counts', () {
    final groups = groupSafetyReports(
      [report('1', 'u', category: 'unsafe_request', status: 'resolved')],
      apps,
      programs,
      now: DateTime.utc(2026, 10, 23),
    );
    expect(groups.single.urgent, false);
    expect(groups.single.recentDistinctReporters, 0);
    expect(groups.single.oldestOpenAt, null);
  });

  for (final width in [360.0, 440.0, 1280.0]) {
    testWidgets('queue and detail fit at $width with large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            safetyReportRepositoryProvider
                .overrideWithValue(FakeSafetyReportRepository()),
            supportConcernsProvider(null).overrideWith(
              (ref) async => [report('1', 'u', category: 'unsafe_request')],
            ),
            adminAllApplicationsProvider.overrideWith((ref) async => apps),
            scholarshipsProvider.overrideWith((ref) async => programs),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const Scaffold(body: ReportsSafetyScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('View reports'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Needs urgent review'), findsOneWidget);
      await tester.ensureVisible(find.text('View reports'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View reports'));
      await tester.pumpAndSettle();
      expect(find.text('Private concern details'), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }

  testWidgets('failure stays visible and retry reloads', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetyReportRepositoryProvider
              .overrideWithValue(FakeSafetyReportRepository()),
          supportConcernsProvider(null).overrideWith((ref) async {
            attempts++;
            if (attempts == 1) throw Exception('private diagnostic');
            return [];
          }),
          adminAllApplicationsProvider.overrideWith((ref) async => apps),
          scholarshipsProvider.overrideWith((ref) async => programs),
        ],
        child: const MaterialApp(home: Scaffold(body: ReportsSafetyScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reports could not be loaded.'), findsOneWidget);
    expect(find.textContaining('private diagnostic'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No reports match these filters.'), findsOneWidget);
  });

  testWidgets('safety reports failure stays visible and retry reloads', (tester) async {
    var safetyAttempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetyReportRepositoryProvider.overrideWithValue(
            _CallbackSafetyReportRepository(() {
              safetyAttempts++;
              if (safetyAttempts == 1) throw Exception('Safety DB down');
              return [];
            }),
          ),
          supportConcernsProvider(null).overrideWith((ref) async => []),
          adminAllApplicationsProvider.overrideWith((ref) async => apps),
          scholarshipsProvider.overrideWith((ref) async => programs),
        ],
        child: const MaterialApp(home: Scaffold(body: ReportsSafetyScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reports could not be loaded.'), findsOneWidget);
    expect(find.textContaining('Safety DB down'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No reports match these filters.'), findsOneWidget);
  });

  testWidgets(
    'search and status filters preserve separate supported payment navigation',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            safetyReportRepositoryProvider
                .overrideWithValue(FakeSafetyReportRepository()),
            supportConcernsProvider(null).overrideWith(
              (ref) async => [
                report('1', 'u'),
                report('2', 'v', category: 'payment_record_correction'),
              ],
            ),
            adminAllApplicationsProvider.overrideWith((ref) async => apps),
            scholarshipsProvider.overrideWith((ref) async => programs),
          ],
          child: const MaterialApp(home: Scaffold(body: ReportsSafetyScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 report'), findsOneWidget);
      expect(find.text('2 reports'), findsNothing);
      await tester.tap(find.text('Urgent'));
      await tester.pumpAndSettle();
      expect(find.text('No reports match these filters.'), findsOneWidget);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'no matching scholarship');
      await tester.pumpAndSettle();
      expect(find.text('No reports match these filters.'), findsOneWidget);
      await tester.tap(find.text('Payment & support'));
      await tester.pumpAndSettle();
      expect(find.text('Support concerns'), findsOneWidget);
      expect(find.text('Provider payment correction request'), findsOneWidget);
    },
  );

  testWidgets('removed provider selection resets after refreshed context', (
    tester,
  ) async {
    var currentPrograms = programs;
    final container = ProviderContainer(
      overrides: [
        safetyReportRepositoryProvider
            .overrideWithValue(FakeSafetyReportRepository()),
        supportConcernsProvider(null)
            .overrideWith((ref) async => [report('1', 'u')]),
        adminAllApplicationsProvider.overrideWith((ref) async => apps),
        scholarshipsProvider.overrideWith((ref) async => currentPrograms),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ReportsSafetyScreen())),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .onChanged!('p');
    await tester.pumpAndSettle();
    currentPrograms = [
      programs.single.copyWith(
        createdBy: 'new-provider',
        provider: 'New foundation',
      ),
    ];
    container.invalidate(scholarshipsProvider);
    await tester.pumpAndSettle();
    expect(find.text('No reports match these filters.'), findsNothing);
    expect(find.text('New foundation'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .initialValue,
      '',
    );
    expect(tester.takeException(), null);
  });

  testWidgets(
    'details label preview relationships and missing legacy relationship honestly',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            safetyReportRepositoryProvider
                .overrideWithValue(FakeSafetyReportRepository()),
            supportConcernsProvider(null).overrideWith(
              (ref) async => [
                report('1', 'u', category: 'unsafe_meetup')
                  ..['relationship'] = 'told',
                report('2', 'v'),
              ],
            ),
            adminAllApplicationsProvider.overrideWith((ref) async => apps),
            scholarshipsProvider.overrideWith((ref) async => programs),
          ],
          child: const MaterialApp(home: Scaffold(body: ReportsSafetyScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('View reports'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View reports'));
      await tester.pumpAndSettle();
      expect(find.text('Unsafe meetup request'), findsOneWidget);
      expect(
        find.text('Relationship: Someone told the reporter'),
        findsOneWidget,
      );
      expect(find.text('Relationship: Not recorded'), findsOneWidget);
    },
  );
}

class _CallbackSafetyReportRepository extends SafetyReportRepository {
  _CallbackSafetyReportRepository(this._loader);
  final List<SafetyReport> Function() _loader;

  @override
  Future<List<SafetyReport>> fetchAllReportsForAdmin() async => _loader();
}
