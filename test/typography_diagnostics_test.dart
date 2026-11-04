import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/typography_diagnostics.dart';

void main() {
  for (final bold in [false, true]) {
    testWidgets('diagnostic exposes runtime bold=$bold without changing it', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: scholarisTheme(),
          home: MediaQuery(
            data: MediaQueryData(
              boldText: bold,
              textScaler: const TextScaler.linear(1.2),
            ),
            child: const Scaffold(body: TypographyDiagnostics()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Runtime bold text: $bold'), findsOneWidget);
      expect(find.text('Text scale at 16px: 19.2px'), findsOneWidget);
      RichText rendered(String key) => tester.widget<RichText>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(RichText),
        ),
      );
      final standard = rendered('diagnostic-standard-700').text as TextSpan;
      expect(standard.style!.fontWeight, FontWeight.w700);
      final control = tester.widget<RichText>(
        find.byKey(const ValueKey('diagnostic-direct-700')),
      );
      expect((control.text as TextSpan).style!.fontWeight, FontWeight.w700);
      expect(control.textScaler.scale(16), 19.2);
      expect(
        MediaQuery.boldTextOf(
          tester.element(find.byType(TypographyDiagnostics)),
        ),
        bold,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
