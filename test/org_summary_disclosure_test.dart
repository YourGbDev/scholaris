import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/provider/presentation/widgets/org_summary_disclosure.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('summary keeps secondary metrics behind an explicit disclosure', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrgSummaryDisclosure(
            title: 'Application summary',
            summary: '12 applications · 3 under review',
            child: Text('Detailed metrics'),
          ),
        ),
      ),
    );
    expect(find.text('12 applications · 3 under review'), findsOneWidget);
    expect(find.text('Detailed metrics'), findsNothing);
    await tester.tap(find.text('Application summary'));
    await tester.pumpAndSettle();
    expect(find.text('Detailed metrics'), findsOneWidget);
    await tester.tap(find.text('Application summary'));
    await tester.pumpAndSettle();
    expect(find.text('Detailed metrics'), findsNothing);
  });
}
