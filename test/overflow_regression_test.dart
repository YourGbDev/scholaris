import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/presentation/submit_application_review_dialog.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'helpers/fake_scholarship_data_source.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Constrained layout & overflow regressions', () {
    testWidgets('ErrorView renders inside a constrained height container without overflowing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 320,
              child: ErrorView(
                title: 'Unable to connect to database',
                message: 'A network timeout occurred while fetching records.',
                onRetry: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Unable to connect to database'), findsOneWidget);
    });

    testWidgets('SubmitApplicationReviewDialog does not overflow with 1.5x text scale on 360px viewport',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final scholarship =
          Scholarship.fromJson(FakeScholarshipDataSource.defaultRows.first);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.5),
                size: Size(360, 800),
              ),
              child: Scaffold(
                body: SubmitApplicationReviewDialog(
                  scholarship: scholarship,
                  onSaveDraft: () async {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Affirmations & Honor Code'), findsOneWidget);
    });
  });
}
