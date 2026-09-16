// test/matching_power_sheet_test.dart
//
// Widget test for MatchingPowerSheet verifying diagnostic rendering,
// progress percentage, item indicators, and action triggers.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/matching_power_sheet.dart';
import 'package:scholaris/features/profile/services/matching_power_service.dart';

void main() {
  testWidgets('MatchingPowerSheet displays breakdown and verified/action badges',
      (tester) async {
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
        home: Scaffold(
          body: MatchingPowerSheet(report: report),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('matching-power-sheet')), findsOneWidget);
    expect(find.text('Matching Power Diagnostics'), findsOneWidget);
    expect(find.byKey(const ValueKey('matching-power-score-badge')), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Criteria Breakdown'), findsOneWidget);

    // Verified items should be marked
    expect(find.text('Aurelia Dela Cruz'), findsOneWidget);
    expect(find.text('Filipino'), findsOneWidget);
    expect(find.text('Verified'), findsWidgets);

    // Missing items should show action needed
    expect(find.text('Action needed'), findsWidgets);
    expect(find.text('Not yet added'), findsOneWidget);
    expect(find.text('Not yet specified'), findsOneWidget);

    // CTA button exists
    expect(
      find.byKey(const ValueKey('matching-power-cta-button')),
      findsOneWidget,
    );
    expect(find.text('Complete Missing Details'), findsOneWidget);
  });
}
