import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/provider/presentation/widgets/org_review_snapshot.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/provider/presentation/org/org_review_analytics_tab.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [360.0, 1280.0]) {
    testWidgets('analytics and review snapshot fit $width with empty data', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReviewAnalyticsPanel(applications: [], scholarships: []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No submitted applications in this selection.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('All time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 30 days').last);
      await tester.pumpAndSettle();
      expect(find.text('Last 30 days'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Copy report (CSV)'));
      await tester.tap(find.text('Copy report (CSV)'));
      await tester.pumpAndSettle();
      expect(
        copied,
        contains('Submission window,Last 30 days'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrgReviewSnapshot(
                total: 4,
                pending: 2,
                decided: 2,
                onReview: () {},
                onAnalytics: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test('cohort excludes drafts and filters by submission date and program', () {
    final now = DateTime(2026, 10, 23);
    final apps = [
      Application(
        id: 'a',
        userId: 'u',
        scholarshipId: 's',
        status: ApplicationStatus.submitted,
        appliedAt: now,
      ),
      Application(
        id: 'b',
        userId: 'u',
        scholarshipId: 's',
        status: ApplicationStatus.draft,
        appliedAt: now,
      ),
      Application(
        id: 'c',
        userId: 'u',
        scholarshipId: 's',
        status: ApplicationStatus.rejected,
        appliedAt: DateTime(2026, 1),
      ),
      const Application(
        id: 'd',
        userId: 'u',
        scholarshipId: 'other',
        status: ApplicationStatus.approved,
      ),
    ];
    expect(reviewCohort(apps, now: now).length, 3);
    expect(
      reviewCohort(
        apps,
        now: now,
        days: 30,
        scholarshipId: 's',
      ).map((a) => a.id),
      ['a'],
    );
  });
  test('decision time requires valid recorded timestamps', () {
    final start = DateTime(2026, 10, 1);
    expect(
      averageDecisionDays([
        Application(
          id: 'a',
          userId: 'u',
          scholarshipId: 's',
          status: ApplicationStatus.approved,
          appliedAt: start,
          decidedAt: start.add(const Duration(days: 4)),
        ),
        Application(
          id: 'b',
          userId: 'u',
          scholarshipId: 's',
          status: ApplicationStatus.rejected,
          appliedAt: start,
        ),
      ]),
      4,
    );
    expect(averageDecisionDays([]), isNull);
  });
}
