// test/matching_power_sheet_test.dart
//
// Widget test for MatchingPowerSheet verifying diagnostic rendering,
// progress percentage, item indicators, and action triggers.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/load_app_fonts.dart';

import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/matching_power_sheet.dart';
import 'package:scholaris/features/profile/services/matching_power_service.dart';

void main() {
  setUpAll(loadAppFonts);
  testWidgets('MatchingPowerSheet displays saved and missing profile details', (
    tester,
  ) async {
    const profile = StudentProfile(
      id: 'std_test',
      fullName: 'Aurelia Dela Cruz',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 1.5,
      yearLevel: 3,
      course: 'BS Information Technology',
      setupComplete: true,
      // school and monthlyFamilyIncome omitted
    );

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final report = MatchingPowerService.evaluate(profile);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MatchingPowerSheet(report: report)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('matching-power-sheet')), findsOneWidget);
    expect(find.text('Profile completeness'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('matching-power-score-badge')),
      findsOneWidget,
    );
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('6 of 8 details provided'), findsOneWidget);
    expect(find.textContaining('unlock'), findsNothing);
    expect(
      find.text('Completeness does not guarantee scholarship eligibility.'),
      findsOneWidget,
    );
    expect(find.text('Profile details'), findsOneWidget);

    // Verified items should be marked
    expect(find.text('Aurelia Dela Cruz'), findsOneWidget);
    expect(find.text('Filipino'), findsOneWidget);
    expect(find.text('Provided'), findsWidgets);

    // Missing items should show action needed
    expect(find.text('Missing details'), findsWidgets);
    expect(find.text('Not yet added'), findsOneWidget);
    expect(find.text('Not yet specified'), findsOneWidget);

    // CTA button exists
    expect(
      find.byKey(const ValueKey('matching-power-cta-button')),
      findsOneWidget,
    );
    expect(find.text('Add missing details'), findsOneWidget);
  });
  testWidgets(
    'completion details and primary action retain setup routes at enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => showMatchingPowerSheet(context, null),
                child: const Text('Open details'),
              ),
            ),
          ),
          GoRoute(
            path: '/profile-setup/personal',
            builder: (_, _) => const Scaffold(body: Text('Personal setup')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
      );
      await tester.tap(find.text('Open details'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 of 8 details provided'), findsOneWidget);
      expect(find.text('Provided'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('matching-power-cta-button')));
      await tester.pumpAndSettle();
      expect(find.text('Personal setup'), findsOneWidget);
    },
  );
}
