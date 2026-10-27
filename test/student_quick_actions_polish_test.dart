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
      await tester.ensureVisible(find.text('Upload Quick Documents'));
      await tester.pumpAndSettle();
      expect(find.text('Upload Quick Documents').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
