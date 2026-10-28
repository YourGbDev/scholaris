import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/presentation/widgets/org_workspace_transition.dart';

void main() {
  testWidgets('rapid navigation leaves only the current screen interactive', (
    tester,
  ) async {
    var active = 0;
    late StateSetter change;
    Widget screen(int value) => Align(
      alignment: Alignment.topLeft,
      child: TextButton(onPressed: () {}, child: Text('Screen $value')),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, update) {
              change = update;
              return OrgWorkspaceTransition(
                activeKey: ValueKey(active),
                child: screen(active),
              );
            },
          ),
        ),
      ),
    );
    change(() => active = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    change(() => active = 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('Screen 0').hitTestable(), findsNothing);
    expect(find.text('Screen 1').hitTestable(), findsNothing);
    expect(find.text('Screen 2').hitTestable(), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Screen 0'), findsNothing);
    expect(find.text('Screen 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'reduce motion switches immediately without retaining outgoing content',
    (tester) async {
      var active = 0;
      late StateSetter change;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, update) {
                  change = update;
                  return OrgWorkspaceTransition(
                    activeKey: ValueKey(active),
                    child: Text('Screen $active'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      change(() => active = 1);
      await tester.pump();
      await tester.pump();
      expect(find.text('Screen 0'), findsNothing);
      expect(find.text('Screen 1'), findsOneWidget);
    },
  );
}
