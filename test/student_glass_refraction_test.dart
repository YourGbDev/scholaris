import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/widgets/student_glass_refraction.dart';

void main() {
  testWidgets('opt-in lens keeps the existing dock available on unsupported renderers', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentGlassRefraction(
      enabled: true, child: SizedBox(width: 300, height: 58, child: Text('Existing dock')),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Existing dock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
