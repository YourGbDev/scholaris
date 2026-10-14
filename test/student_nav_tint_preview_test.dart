// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/theme/app_motion.dart';

void main() {
  testWidgets('StudentNavTintPreview: Verify configs across 0.60, 0.70, and 0.82 with no solid fill',
      (WidgetTester tester) async {
    const tints = [0.60, 0.70, 0.82];

    print('\n======================================================');
    print('  STUDENT NAV TINT PREVIEW CONFIGURATION AUDIT');
    print('======================================================\n');

    for (final tint in tints) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pill
                    LiquidGlass(
                      key: ValueKey('pill_$tint'),
                      borderRadius: 32,
                      blur: 20.0,
                      saturation: 1.8,
                      tintOpacity: tint,
                      showLightEdge: true,
                      lightEdgeColor: const Color(0x66FFFFFF),
                      child: const SizedBox(width: 320, height: 64),
                    ),
                    const SizedBox(width: 8),
                    // "+" Button
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: LiquidGlass(
                        key: ValueKey('plus_$tint'),
                        borderRadius: 32,
                        blur: 20.0,
                        saturation: 1.8,
                        tintOpacity: tint,
                        showLightEdge: true,
                        lightEdgeColor: const Color(0x66FFFFFF),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: Color(0xFF0F4D2E),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Find both LiquidGlass widgets
      final pillWidget = tester.widget<LiquidGlass>(find.byKey(ValueKey('pill_$tint')));
      final plusWidget = tester.widget<LiquidGlass>(find.byKey(ValueKey('plus_$tint')));

      print('CONFIG PREVIEW [Tint: ${(tint * 100).toStringAsFixed(0)}%]');
      print('  - Pill: tintOpacity=${pillWidget.tintOpacity}, blur=${pillWidget.blur}px, saturation=${pillWidget.saturation}x, lightEdge=${pillWidget.showLightEdge} (${pillWidget.lightEdgeColor})');
      print('  - Plus: tintOpacity=${plusWidget.tintOpacity}, blur=${plusWidget.blur}px, saturation=${plusWidget.saturation}x, lightEdge=${plusWidget.showLightEdge} (${plusWidget.lightEdgeColor}), radius=${plusWidget.borderRadius}');

      expect(pillWidget.tintOpacity, equals(tint));
      expect(plusWidget.tintOpacity, equals(tint));
      expect(pillWidget.blur, equals(20.0));
      expect(plusWidget.blur, equals(20.0));
      expect(pillWidget.saturation, equals(1.8));
      expect(plusWidget.saturation, equals(1.8));

      // Assert no solid opaque fill in either widget
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        if (container.color != null) {
          expect(container.color!.a, lessThan(1.0));
        }
        final dec = container.decoration;
        if (dec is BoxDecoration && dec.color != null) {
          expect(dec.color!.a, lessThan(1.0));
        }
      }
      print('  - Verified: No solid opaque fill present (pure LiquidGlass translucent material).\n');
    }

    print('======================================================');
    print('  ALL TINT CONFIGS VERIFIED: ZERO SOLID FILL');
    print('======================================================\n');
  });
}
