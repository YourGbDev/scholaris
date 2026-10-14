import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

void main() {
  group('Apple WWDC Spring Physics Specification', () {
    test('Calculates mass, stiffness, and damping from dampingRatio and response', () {
      // Test critically damped spring with response 0.35s
      final spring = AppleSpringDescription.fromDampingAndResponse(
        dampingRatio: 1.0,
        response: 0.35,
      );

      final expectedOmega = (2 * math.pi) / 0.35;
      final expectedStiffness = expectedOmega * expectedOmega;
      final expectedDamping = 2 * 1.0 * expectedOmega;

      expect(spring.mass, equals(1.0));
      expect(spring.stiffness, closeTo(expectedStiffness, 0.01));
      expect(spring.damping, closeTo(expectedDamping, 0.01));
      expect(spring.dampingRatio, equals(1.0));
      expect(spring.response, equals(0.35));
    });

    test('Apple Shipped Presets adhere to WWDC parameters', () {
      // 1. Critical UI: damping 1.0, response 0.35
      expect(AppleSpringDescription.critical.dampingRatio, equals(1.0));
      expect(AppleSpringDescription.critical.response, equals(0.35));

      // 2. Snappy Press: damping 1.0, response 0.20
      expect(AppleSpringDescription.snappyPress.dampingRatio, equals(1.0));
      expect(AppleSpringDescription.snappyPress.response, equals(0.20));

      // 3. Sheet / Drawer: damping 0.8, response 0.30
      expect(AppleSpringDescription.sheet.dampingRatio, equals(0.8));
      expect(AppleSpringDescription.sheet.response, equals(0.30));

      // 4. Move / PiP: damping 1.0, response 0.40
      expect(AppleSpringDescription.pip.dampingRatio, equals(1.0));
      expect(AppleSpringDescription.pip.response, equals(0.40));

      // 5. Rotation: damping 0.8, response 0.40
      expect(AppleSpringDescription.rotation.dampingRatio, equals(0.8));
      expect(AppleSpringDescription.rotation.response, equals(0.40));
    });
  });

  group('Apple Fluid Mechanics: Rubber-Banding & Velocity Handoff', () {
    test('appleRubberBand implements exact logarithmic resistance formula (c = 0.55)', () {
      const dimension = 800.0;
      const overshoot = 150.0;

      // Formula: (x * d * 0.55) / (d + 0.55 * |x|)
      final expected = (150.0 * 800.0 * 0.55) / (800.0 + 0.55 * 150.0);
      final result = appleRubberBand(overshoot: overshoot, dimension: dimension);

      expect(result, closeTo(expected, 0.001));
      // Sub-linear resistance: resisted displacement is far less than raw 150px
      expect(result, closeTo(74.787, 0.01));

      // Negative overshoot (scrolling past opposite edge) preserves direction
      final negResult = appleRubberBand(overshoot: -overshoot, dimension: dimension);
      expect(negResult, closeTo(-expected, 0.001));

      // Inverse formula round-trips correctly
      final reconstructed = appleRubberBandInverse(resistedOffset: result, dimension: dimension);
      expect(reconstructed, closeTo(overshoot, 0.01));
    });

    test('calculateRelativeVelocity normalizes gesture velocity against distance to target', () {
      // Pointer moving at -500 px/s from 1.0 to 0.97 (distance = -0.03)
      final vRel = calculateRelativeVelocity(
        gestureVelocity: -0.5,
        currentValue: 1.0,
        targetValue: 0.97,
      );
      // vRel = -0.5 / (0.97 - 1.0) = -0.5 / -0.03 = 16.666...
      expect(vRel, closeTo(16.666, 0.01));
    });

    test('projectMomentum implements exponential decay projection (deceleration = 0.998)', () {
      const initialVelocity = 1200.0; // px/sec
      // Formula: (1200 / 1000) * 0.998 / (1 - 0.998) = 1.2 * 0.998 / 0.002 = 598.8 px
      final projection = projectMomentum(initialVelocity: initialVelocity);
      expect(projection, closeTo(598.8, 0.01));
    });
  });

  group('PressableScale Spring & Interruptibility', () {
    testWidgets('Interruptible mid-flight: releases cleanly without snapping or jumping', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressableScale(
                scale: 0.97,
                child: Container(
                  key: const ValueKey('pressable_box'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<PressableScaleState>(find.byType(PressableScale));
      // Initial scale is 1.0
      expect(state.currentScale, closeTo(1.0, 0.001));

      // 1. Pointer Down begins compression towards 0.97
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('pressable_box'))));
      await tester.pump(); // Register pointer down and initiate simulation
      await tester.pump(const Duration(milliseconds: 60)); // Advance into compression

      final midScale = state.currentScale;
      // Mid-flight: scale has shrunk towards 0.97
      expect(midScale, lessThan(1.0));
      expect(midScale, greaterThanOrEqualTo(0.96));

      // 2. Interrupt mid-flight by lifting pointer
      await gesture.up();
      await tester.pump(); // Register pointer up and retarget spring back to 1.0 with inherited velocity
      await tester.pump(const Duration(milliseconds: 30));

      final reversingScale = state.currentScale;
      expect(reversingScale, greaterThanOrEqualTo(0.96));

      // Pump enough time for the spring simulation to come to a critically damped rest at 1.0
      await tester.pumpAndSettle();

      expect(state.currentScale, closeTo(1.0, 0.001));
    });
  });

  group('Apple Liquid Glass Material', () {
    testWidgets('Renders BackdropFilter with blur, light-edge border, and tint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiquidGlass(
                blur: 20.0,
                saturation: 1.8,
                tintOpacity: 0.82,
                borderRadius: 20.0,
                showLightEdge: true,
                child: SizedBox(
                  width: 200,
                  height: 60,
                  child: Text('Liquid Glass Content'),
                ),
              ),
            ),
          ),
        ),
      );

      // BackdropFilter must be present
      expect(find.byType(BackdropFilter), findsOneWidget);

      // Outer glass border is uniform (avoids Flutter non-uniform border assertion)
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        ),
      );
      expect(containers.isNotEmpty, isTrue);
      final mainContainer = containers.first;
      final decoration = mainContainer.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);

      // Specular light edge highlight is present
      expect(find.byType(Positioned), findsOneWidget);
    });
  });

  group('Apple HIG Optical Typography System', () {
    test('Calculates optical tracking and leading correctly across scales', () {
      // Display Large: 36pt -> negative tracking (-0.72), tight leading (1.10)
      expect(opticalTracking(36), closeTo(-0.72, 0.01));
      expect(opticalLeading(36), equals(1.10));

      // Headline Large: 28pt -> negative tracking (-0.42), tight leading (1.15)
      expect(opticalTracking(28), closeTo(-0.42, 0.01));
      expect(opticalLeading(28), equals(1.15));

      // Body Large: 16pt -> neutral tracking (0.0), relaxed reading leading (1.50)
      expect(opticalTracking(16), equals(0.0));
      expect(opticalLeading(16, isBody: true), equals(1.50));

      // Body Medium: 14pt -> neutral tracking (0.0), relaxed reading leading (1.45)
      expect(opticalTracking(14), equals(0.0));
      expect(opticalLeading(14, isBody: true), equals(1.45));

      // Label Small: 11pt -> positive tracking (+0.308) for micro-legibility
      expect(opticalTracking(11), closeTo(0.308, 0.01));
      expect(opticalLeading(11), equals(1.30));
    });

    test('ThemeData integrates optical typography', () {
      final theme = scholarisTheme();
      final textTheme = theme.textTheme;

      // Display text has negative letter spacing and tight leading
      expect(textTheme.displayLarge?.letterSpacing, lessThan(0.0));
      expect(textTheme.displayLarge?.height, inInclusiveRange(1.05, 1.15));

      // Body text has neutral letter spacing and relaxed leading
      expect(textTheme.bodyLarge?.letterSpacing, equals(0.0));
      expect(textTheme.bodyLarge?.height, inInclusiveRange(1.45, 1.55));

      // Micro labels have positive letter spacing
      expect(textTheme.labelSmall?.letterSpacing, greaterThan(0.0));
    });
  });
}
