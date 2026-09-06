// Day 19 tests: the EmptyStage widget — the quiet auditorium shown behind the
// login form. Pure native Flutter (Container + CustomPaint), no images, no
// animation, so reduced motion is trivially satisfied.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/auth/presentation/empty_stage.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders successfully', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyStage())),
    );

    expect(find.byType(EmptyStage), findsOneWidget);
    expect(find.byKey(kEmptyStageKey), findsOneWidget);
    // The stage is drawn with a CustomPaint (plus the Container base).
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('uses kBackground as its base', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyStage())),
    );

    final box = tester.widget<ColoredBox>(find.byKey(kEmptyStageKey));
    expect(box.color, kBackground);
  });

  testWidgets('renders immediately under reduced motion', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyStage())),
    );
    await tester.pump();

    expect(find.byType(EmptyStage), findsOneWidget);
  });
}