import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/application_decision_letter.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final status in [
    ApplicationStatus.approved,
    ApplicationStatus.awarded,
    ApplicationStatus.rejected,
  ]) {
    testWidgets('$status displays only the corresponding saved decision', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApplicationDecisionLetter(
            application: Application(
              id: 'saved-reference',
              userId: 'student',
              scholarshipId: 'scholarship',
              status: status,
              decidedAt: DateTime(2026, 10, 19),
            ),
            scholarshipTitle: 'Community Scholarship',
            studentName: 'Demo Student',
            providerName: 'Community Foundation',
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (status == ApplicationStatus.rejected) {
        expect(find.text('Scholarship Approval Letter'), findsNothing);
        expect(find.text('Scholarship Award Certificate'), findsNothing);
      } else {
        expect(
          find.text(
            status == ApplicationStatus.awarded
                ? 'Scholarship Award Certificate'
                : 'Scholarship Approval Letter',
          ),
          findsOneWidget,
        );
        expect(find.text('Demo Student'), findsOneWidget);
        expect(find.text('Community Foundation'), findsOneWidget);
        expect(
          find.text(
            status == ApplicationStatus.awarded
                ? 'Scholarship awarded on 19 Oct 2026'
                : 'Application approved on 19 Oct 2026',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('saved-reference'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 440.0, 1280.0]) {
    testWidgets(
      'letter fits $width with large text and missing optional fields',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const ApplicationDecisionLetter(
              application: Application(
                id: '9792c9ac-75ed-4d8a-a3cd-51b18c758b87',
                userId: 'student',
                scholarshipId: 'scholarship',
                status: ApplicationStatus.approved,
              ),
              scholarshipTitle: 'Community Scholarship for Students Pursuing Higher Education',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Application approved on'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'awarded certificate fits $width with complete fields and long strings',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: ApplicationDecisionLetter(
              application: Application(
                id: '3c8f828a-6b5d-4f1e-9231-10cbfb9d3328',
                userId: 'demo-student-long-id',
                scholarshipId: 'dost-merit-scholarship-id',
                status: ApplicationStatus.awarded,
                decidedAt: DateTime(2026, 10, 19, 14, 30),
              ),
              scholarshipTitle: 'DOST-SEI Science and Technology Undergraduate Merit Scholarship 2026-2027',
              studentName: 'Maria Clara de los Santos-Bernardino y Villamor Jr.',
              providerName: 'Department of Science and Technology - Science Education Institute',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Scholarship Award Certificate'), findsOneWidget);
        expect(find.text('Maria Clara de los Santos-Bernardino y Villamor Jr.'), findsOneWidget);
        expect(find.text('Department of Science and Technology - Science Education Institute'), findsOneWidget);
        expect(find.text('Scholarship awarded on 19 Oct 2026'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
