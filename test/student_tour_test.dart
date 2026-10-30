import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholaris/features/home/presentation/widgets/student_app_tour.dart';

void main() {
  final selectedTabs = <int>[];
  Future<void> mount(WidgetTester tester, String? user) async {
    final targets = List.generate(5, (_) => GlobalKey());
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        SizedBox(key: targets[i], width: 50, height: 50),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: StudentTourLayer(
                    userId: user,
                    targets: targets,
                    bottomClearance: 80,
                    onSelectTab: selectedTabs.add,
                    onActiveChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    selectedTabs.clear();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'tour is optional, explicit, and remembered separately per account',
    (tester) async {
      await mount(tester, 'alice');
      expect(find.text('Take a quick tour'), findsOneWidget);
      await tester.tap(find.text('Start tour'));
      await tester.pumpAndSettle();
      expect(find.text('Find your opportunities'), findsOneWidget);
      expect(find.text('1 of 4'), findsOneWidget);
      await tester.tap(find.text('Skip tour'));
      await tester.pumpAndSettle();
      expect(find.text('Take a quick tour'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await mount(tester, 'alice');
      expect(find.text('Take a quick tour'), findsNothing);
      await mount(tester, 'bob');
      expect(find.text('Take a quick tour'), findsOneWidget);
    },
  );

  testWidgets('all four tips finish and Help can replay a dismissed tour', (
    tester,
  ) async {
    await mount(tester, 'alice');
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(StudentTourLayer));
    ProviderScope.containerOf(context)
        .read(studentTourReplayProvider.notifier)
        .state++;
    await tester.pumpAndSettle();
    for (var i = 1; i <= 4; i++) {
      expect(find.text('$i of 4'), findsOneWidget);
      await tester.tap(find.text(i == 4 ? 'Finish tour' : 'Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Skip tour'), findsNothing);
    expect(selectedTabs, [1, 2, 3, 3]);
  });

  testWidgets('account change closes active guide and signed-out users see no invitation', (tester) async {
    await mount(tester, 'alice');
    await tester.tap(find.text('Start tour'));
    await tester.pumpAndSettle();
    await mount(tester, 'bob');
    expect(find.text('Skip tour'), findsNothing);
    expect(find.text('Take a quick tour'), findsOneWidget);
    await mount(tester, null);
    expect(find.text('Take a quick tour'), findsNothing);
  });

  testWidgets('tip controls remain usable at 320 wide with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester, 'alice');
    await tester.ensureVisible(find.text('Start tour'));
    await tester.tap(find.text('Start tour'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Skip tour'));
    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
