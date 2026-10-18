// Approval letter integration and legacy opening ceremony coverage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/presentation/application_detail_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/auth/presentation/ceremony_screen.dart';
import 'package:scholaris/features/applications/presentation/application_decision_letter.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrapWithScope({
    required Widget child,
    required FakeApplicationDataSource applications,
    FakeScholarshipDataSource? scholarships,
    String userId = 'user-1',
  }) {
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => null),
        currentUserIdProvider.overrideWithValue(userId),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: applications,
            currentUserId: () => userId,
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: scholarships ?? FakeScholarshipDataSource(),
          ),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('CeremonyScreen Celebration Mode', () {
    testWidgets('renders custom title, subtitle, and top-right close button', (
      tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CeremonyScreen(
            title: '🎉 Grant Award Confirmed!',
            subtitle: 'You have officially been awarded this scholarship!',
            onCompleted: () => completed = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('🎉 Grant Award Confirmed!'), findsOneWidget);
      expect(
        find.text('You have officially been awarded this scholarship!'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ceremony-close-btn')), findsOneWidget);

      // Tapping the close button invokes onCompleted callback
      await tester.tap(find.byKey(const ValueKey('ceremony-close-btn')));
      await tester.pump();

      expect(completed, isTrue);
    });
  });

  group('ApplicationDetailScreen decision letter', () {
    testWidgets(
      'approved application opens an approval letter and returns safely',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final applications = FakeApplicationDataSource();
        final scholarships = FakeScholarshipDataSource();

        final inserted = await applications.insertApplication('user-1', {
          'user_id': 'user-1',
          'scholarship_id': 'sch-dost',
          'status': 'approved',
          'applied_at': DateTime.now().toUtc().toIso8601String(),
        });

        await tester.pumpWidget(
          wrapWithScope(
            child: ApplicationDetailScreen(applicationId: inserted['id']!),
            applications: applications,
            scholarships: scholarships,
          ),
        );
        await tester.pumpAndSettle();

        // Verify the celebratory action card is displayed
        expect(find.text('Your application is approved'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('view-decision-letter-btn')),
          findsOneWidget,
        );

        // Tap "🎉 View Award Ceremony & Package"
        await tester.tap(
          find.byKey(const ValueKey('view-decision-letter-btn')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // The approval letter is mounted on the Navigator stack
        expect(find.byType(ApplicationDecisionLetter), findsOneWidget);
        expect(find.text('Scholarship Approval Letter'), findsOneWidget);
        expect(find.textContaining('officially been awarded'), findsNothing);

        // Return to the application
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Returned back to ApplicationDetailScreen
        expect(find.byType(ApplicationDecisionLetter), findsNothing);
        expect(find.text('Your application is approved'), findsOneWidget);
      },
    );

    testWidgets(
      'responsive layout on 360px mobile and 1280px desktop without overflow',
      (tester) async {
        final applications = FakeApplicationDataSource();
        final scholarships = FakeScholarshipDataSource();

        final inserted = await applications.insertApplication('user-1', {
          'user_id': 'user-1',
          'scholarship_id': 'sch-dost',
          'status': 'approved',
          'applied_at': DateTime.now().toUtc().toIso8601String(),
        });

        for (final width in [360.0, 440.0, 1280.0]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            wrapWithScope(
              child: ApplicationDetailScreen(applicationId: inserted['id']!),
              applications: applications,
              scholarships: scholarships,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Zero RenderFlex overflow on width $width',
          );
          expect(find.text('Your application is approved'), findsOneWidget);
        }
      },
    );
  });
}
