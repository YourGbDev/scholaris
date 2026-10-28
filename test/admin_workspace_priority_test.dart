import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/admin/widgets/admin_review_priorities.dart';
import 'package:scholaris/features/provider/models/provider_verification.dart';
import 'package:scholaris/features/provider/providers/provider_verification_provider.dart';
import 'package:scholaris/features/provider/repositories/support_concern_repository.dart';
import 'package:scholaris/features/safety/data/safety_report_repository.dart';
import 'package:scholaris/features/safety/models/safety_report.dart';

class _Verifications extends AdminProviderVerificationsNotifier {
  @override
  Future<List<ProviderVerification>> build() async => [
    ProviderVerification(
      userId: 'org',
      providerType: 'organization',
      submittedAt: DateTime(2026, 10, 1),
    ),
    const ProviderVerification(
      userId: 'individual',
      providerType: 'individual',
    ),
    const ProviderVerification(
      userId: 'done',
      providerType: 'individual',
      status: 'approved',
    ),
  ];
}

class _SafetyReports extends AdminSafetyReportsNotifier {
  _SafetyReports([this._reports = const []]);
  final List<SafetyReport> _reports;
  @override
  Future<List<SafetyReport>> build() async => _reports;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'owner queue prioritizes both provider types and one urgent report',
    (tester) async {
      var providers = 0;
      var reports = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminProviderVerificationsProvider.overrideWith(_Verifications.new),
            adminSafetyReportsProvider.overrideWith(_SafetyReports.new),
            supportConcernsProvider(null).overrideWith(
              (ref) async => [
                {
                  'id': 'r1',
                  'status': 'open',
                  'category': 'unsafe_request',
                  'reporter_id': 's1',
                },
                {
                  'id': 'r2',
                  'status': 'resolved',
                  'category': 'unsafe_request',
                  'reporter_id': 's2',
                },
                {
                  'id': 'r3',
                  'status': 'open',
                  'category': 'payment_record_correction',
                  'reporter_id': 'p1',
                },
              ],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminReviewPriorities(
                  onProviders: () => providers++,
                  onReports: () => reports++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 pending provider applications'), findsOneWidget);
      expect(find.text('1 organization · 1 individual'), findsOneWidget);
      expect(find.text('1 urgent report needs review'), findsOneWidget);
      await tester.tap(find.text('Review providers'));
      await tester.tap(find.text('Review safety reports'));
      expect(providers, 1);
      expect(reports, 1);
    },
  );
  testWidgets('unavailable queues stay actionable and never become zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminProviderVerificationsProvider.overrideWith(_Verifications.new),
          supportConcernsProvider(
            null,
          ).overrideWith((ref) async => throw StateError('private diagnostic')),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AdminReviewPriorities(onProviders: () {}, onReports: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Safety reports unavailable'), findsOneWidget);
    expect(find.textContaining('private diagnostic'), findsNothing);
    expect(find.text('Retry safety reports'), findsOneWidget);
  });
  testWidgets(
    'loading is not an empty safety queue at 200 percent mobile text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final waiting = Completer<List<Map<String, dynamic>>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminProviderVerificationsProvider.overrideWith(_Verifications.new),
            adminSafetyReportsProvider.overrideWith(_SafetyReports.new),
            supportConcernsProvider(null).overrideWith((ref) => waiting.future),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminReviewPriorities(
                  onProviders: () {},
                  onReports: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Loading safety reports…'), findsOneWidget);
      expect(tester.takeException(), isNull);
      waiting.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('No unresolved student reports'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'combines scholarship safety reports and support concerns in priorities queue',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminProviderVerificationsProvider.overrideWith(_Verifications.new),
            adminSafetyReportsProvider.overrideWith(
              () => _SafetyReports([
                const SafetyReport(
                  id: 'safe-1',
                  scholarshipId: 'sch-1',
                  providerId: 'p-1',
                  reporterId: 'rep-1',
                  category: 'threat',
                  relationship: 'experienced',
                  description: 'Received intimidating message',
                  status: 'open',
                ),
              ]),
            ),
            supportConcernsProvider(null).overrideWith(
              (ref) async => [
                {
                  'id': 'c-1',
                  'status': 'open',
                  'category': 'other',
                  'reporter_id': 'rep-2',
                },
              ],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminReviewPriorities(
                  onProviders: () {},
                  onReports: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 urgent report needs review'), findsOneWidget);
      expect(find.text('URGENT REVIEW'), findsOneWidget);
    },
  );
}
