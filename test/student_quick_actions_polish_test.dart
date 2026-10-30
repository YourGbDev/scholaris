import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/home/presentation/widgets/student_action_sheet.dart';

void main() {
  testWidgets(
    'quick actions have normal sheet typography and scroll on short enlarged-text phones',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showStudentActionSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final titleContext = tester.element(find.text('Quick Actions'));
      expect(
        DefaultTextStyle.of(titleContext).style.decoration,
        isNot(TextDecoration.underline),
      );
      expect(find.byTooltip('Close quick actions'), findsOneWidget);
      await tester.ensureVisible(find.text('Upload document'));
      await tester.pumpAndSettle();
      expect(find.text('Upload document').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Ask Scholaris'), findsNothing);
      await tester.tap(find.byTooltip('Close quick actions'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Actions'), findsNothing);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('Quick Actions'), findsNothing);
    },
  );

  testWidgets('menu actions select the existing QR and upload destinations', (
    tester,
  ) async {
    final selected = <StudentQuickAction>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StudentActionSheet(onSelect: selected.add)),
      ),
    );
    await tester.tap(find.text('Scan scholarship QR'));
    await tester.tap(find.text('Upload document'));
    expect(selected, [StudentQuickAction.scan, StudentQuickAction.upload]);
  });
}
