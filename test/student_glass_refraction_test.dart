import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/widgets/student_glass_refraction.dart';
import 'package:scholaris/features/home/presentation/widgets/liquid_glass_pill.dart';
import 'package:scholaris/shared/widgets/student_header_actions.dart';

void main() {
  testWidgets(
    'header shortcuts stay reachable with high-contrast glass fallback',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(highContrast: true),
            child: Scaffold(body: StudentHeaderActions()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LiquidGlassPill), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      for (final label in ['Notifications', 'Settings']) {
        expect(
          tester.getSize(find.byTooltip(label)).shortestSide,
          greaterThanOrEqualTo(44),
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'opt-in lens keeps the existing dock available on unsupported renderers',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentGlassRefraction(
            enabled: true,
            child: SizedBox(
              width: 300,
              height: 58,
              child: Text('Existing dock'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Existing dock'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
