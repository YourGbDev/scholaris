import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/presentation/widgets/org_metric_count.dart';

void main() {
  testWidgets(
    'count settles once and remains final after remount in the workspace',
    (tester) async {
      final bucket = PageStorageBucket();
      var show = true;
      var value = 1000;
      late StateSetter change;
      await tester.pumpWidget(
        MaterialApp(
          home: PageStorage(
            bucket: bucket,
            child: StatefulBuilder(
              builder: (context, update) {
                change = update;
                return show
                    ? OrgMetricCount(motionId: 'test', targetValue: value)
                    : const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('1,000').hitTestable(), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('1,000').hitTestable(), findsOneWidget);
      change(() => value = 1200);
      await tester.pump();
      expect(find.text('1,200').hitTestable(), findsOneWidget);
      change(() => show = false);
      await tester.pump();
      change(() => show = true);
      await tester.pump();
      expect(find.text('1,200').hitTestable(), findsOneWidget);
    },
  );
  testWidgets(
    'reduced motion and semantics expose the final value immediately',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: OrgMetricCount(
              motionId: 'test',
              targetValue: 50000,
              prefix: '₱',
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('₱50,000'), findsOneWidget);
      expect(find.text('₱50,000').hitTestable(), findsOneWidget);
      semantics.dispose();
    },
  );
}
