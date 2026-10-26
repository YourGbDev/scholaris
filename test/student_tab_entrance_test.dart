import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/widgets/student_tab_entrance.dart';

void main() {
  double opacity(WidgetTester tester, String id) => tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byKey(ValueKey(id)),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;

  testWidgets('heading leads rows in place; revisit retains state and scroll', (
    tester,
  ) async {
    var initializations = 0;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    Widget host(bool active, {bool reduced = false, bool accessible = false}) =>
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: reduced,
              accessibleNavigation: accessible,
            ),
            child: StudentTabEntrance(
              active: active,
              child: SingleChildScrollView(
                controller: scroll,
                child: Column(
                  children: [
                    const StudentTabReveal(
                      key: ValueKey('heading'),
                      order: 0,
                      child: SizedBox(height: 80, child: Text('Heading')),
                    ),
                    StudentTabReveal(
                      key: const ValueKey('row'),
                      order: 4,
                      child: _Counter(onInit: () => initializations++),
                    ),
                    const SizedBox(height: 1600),
                  ],
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(host(true));
    final initialBounds = tester.getRect(find.byKey(const ValueKey('row')));
    scroll.jumpTo(140);
    await tester.pump();
    await tester.pumpWidget(host(false));
    await tester.pumpWidget(host(true));
    expect(opacity(tester, 'heading'), 0);
    expect(opacity(tester, 'row'), 0);
    await tester.pump(const Duration(milliseconds: 120));
    expect(opacity(tester, 'heading'), greaterThan(0));
    expect(opacity(tester, 'row'), 0);
    expect(scroll.offset, 140);
    expect(
      tester.getSize(find.byKey(const ValueKey('row'))),
      initialBounds.size,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(tester, 'heading'), greaterThan(opacity(tester, 'row')));
    await tester.pumpAndSettle();
    expect(opacity(tester, 'row'), 1);
    expect(initializations, 1);
    await tester.pumpWidget(host(true));
    expect(
      opacity(tester, 'row'),
      1,
      reason: 'A data rebuild must not replay the visit.',
    );
    for (final accessible in [false, true]) {
      await tester.pumpWidget(
        host(false, reduced: !accessible, accessible: accessible),
      );
      await tester.pumpWidget(
        host(true, reduced: !accessible, accessible: accessible),
      );
      expect(opacity(tester, 'row'), 1);
      expect(initializations, 1);
    }
  });

  testWidgets(
    'invisible sections cannot activate; late content and standalone views are immediate',
    (tester) async {
      var taps = 0;
      Widget host(bool active, {bool late = false}) => MaterialApp(
        home: StudentTabEntrance(
          active: active,
          child: Column(
            children: [
              StudentTabReveal(
                key: const ValueKey('action'),
                order: 6,
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Action'),
                ),
              ),
              if (late)
                const StudentTabReveal(
                  key: ValueKey('late'),
                  order: 99,
                  child: Text('Late result'),
                ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(host(false));
      await tester.pumpWidget(host(true));
      await tester.tapAt(tester.getCenter(find.text('Action')));
      expect(taps, 0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Action'));
      expect(taps, 1);
      await tester.pumpWidget(host(true, late: true));
      expect(opacity(tester, 'late'), 1);
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentTabReveal(order: 2, child: Text('Standalone')),
        ),
      );
      expect(find.text('Standalone'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StudentTabReveal),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'rapid switches stop inactive clocks and dispose without pending work',
    (tester) async {
      Widget host(bool active) => MaterialApp(
        home: StudentTabEntrance(
          active: active,
          child: const StudentTabReveal(order: 5, child: Text('Content')),
        ),
      );
      await tester.pumpWidget(host(false));
      await tester.pumpWidget(host(true));
      await tester.pump(const Duration(milliseconds: 90));
      await tester.pumpWidget(host(false));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(host(true));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

class _Counter extends StatefulWidget {
  const _Counter({required this.onInit});
  final VoidCallback onInit;
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 120, child: Text('Retained row'));
}
