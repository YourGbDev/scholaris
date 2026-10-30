import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholaris/features/home/presentation/widgets/student_app_tour.dart';
import 'package:scholaris/features/home/presentation/widgets/student_guide_greeting.dart';

void main() {
  testWidgets('reintroduction continues from copy, portrait, and background', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var advances = 0;
    var skips = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentGuideGreeting(
            title: 'I’m back!',
            message: 'Let me show you Discover.',
            gender: 'male',
            explicitContinue: false,
            onContinue: () => advances++,
            onSkip: () => skips++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let me show you Discover.'));
    expect(advances, 1);
    await tester.tapAt(const Offset(66, 794));
    expect(advances, 2);
    await tester.tapAt(const Offset(300, 200));
    expect(advances, 3);
    await tester.tap(find.byTooltip('Skip guide'));
    expect(skips, 1);
    expect(advances, 3);
    final card = tester.getRect(
      find
          .ancestor(
            of: find.text('Let me show you Discover.'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(card.left, 28);
    expect(card.width, 334);
    expect(
      tester.getRect(find.text('Tap anywhere to continue')).top,
      greaterThanOrEqualTo(card.bottom),
    );
  });

  testWidgets('first introduction only advances through its explicit button', (
    tester,
  ) async {
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentGuideGreeting(
            title: 'Hi, Maria!',
            message: 'Let me show you around.',
            gender: 'female',
            onContinue: () => advances++,
            onSkip: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let me show you around.'));
    await tester.tapAt(const Offset(66, 550));
    await tester.tapAt(const Offset(300, 200));
    expect(advances, 0);
    expect(find.byTooltip('Skip guide'), findsNothing);
    await tester.tap(find.text('Continue'));
    expect(advances, 1);
  });

  testWidgets(
    'scrolling enlarged greeting does not advance or hide the exterior hint',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var advances = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentGuideGreeting(
              title: 'I’m back!',
              message: List.filled(10, 'Let me show you Discover.').join(' '),
              gender: 'female',
              explicitContinue: false,
              onContinue: () => advances++,
              onSkip: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(advances, 0);
      expect(
        find.text('Tap anywhere to continue').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  final selectedTabs = <int>[];
  Future<void> mount(
    WidgetTester tester,
    String? user, {
    bool profileReady = true,
    String studentName = 'Student',
    String? gender,
  }) async {
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
                    profileReady: profileReady,
                    studentName: studentName,
                    gender: gender,
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

  testWidgets('invitation waits for the student profile before greeting', (
    tester,
  ) async {
    await mount(tester, 'maria', profileReady: false);
    expect(find.byType(StudentGuideGreeting), findsNothing);
    await mount(tester, 'maria', studentName: 'Maria Santos', gender: 'female');
    expect(find.text('Hi, Maria!'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/mascot_female.png')),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage('assets/images/mascot_male_welcome_wave.png'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'replay requested while profile loads starts at welcome once ready',
    (tester) async {
      SharedPreferences.setMockInitialValues({'student_tour_v1_maria': true});
      await mount(tester, 'maria', profileReady: false);
      final context = tester.element(find.byType(StudentTourLayer));
      ProviderScope.containerOf(context)
          .read(studentTourReplayProvider.notifier)
          .state++;
      await tester.pumpAndSettle();
      expect(find.byType(StudentGuideGreeting), findsNothing);
      expect(selectedTabs, isEmpty);
      await mount(
        tester,
        'maria',
        studentName: 'Maria Santos',
        gender: 'female',
      );
      expect(find.text('Hi, Maria!'), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/mascot_female.png')),
        findsOneWidget,
      );
      expect(find.text('View saved scholarships'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('View saved scholarships'), findsOneWidget);
    },
  );

  testWidgets('queued replay does not carry into another account', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'student_tour_v1_bob': true});
    await mount(tester, 'maria', profileReady: false);
    final context = tester.element(find.byType(StudentTourLayer));
    ProviderScope.containerOf(context)
        .read(studentTourReplayProvider.notifier)
        .state++;
    await tester.pumpAndSettle();
    await mount(tester, 'bob', studentName: 'Bob');
    expect(find.byType(StudentGuideGreeting), findsNothing);
    expect(selectedTabs, isEmpty);
  });

  testWidgets(
    'tour is optional, explicit, and remembered separately per account',
    (tester) async {
      await mount(tester, 'alice');
      expect(find.text('Hi, Student!'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('View saved scholarships'), findsOneWidget);

      await tester.tap(find.byTooltip('Skip guide'));
      await tester.pumpAndSettle();
      expect(find.text('Hi, Student!'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await mount(tester, 'alice');
      expect(find.text('Hi, Student!'), findsNothing);
      await mount(tester, 'bob');
      expect(find.text('Hi, Student!'), findsOneWidget);
    },
  );

  testWidgets('Help replays a dismissed guide from the welcome', (
    tester,
  ) async {
    await mount(tester, 'alice');
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(StudentTourLayer));
    ProviderScope.containerOf(context)
        .read(studentTourReplayProvider.notifier)
        .state++;
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('View saved scholarships'), findsOneWidget);
    await tester.tap(find.byTooltip('Skip guide'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Skip guide'), findsNothing);
    expect(selectedTabs.last, 0);
  });

  testWidgets(
    'account change closes active guide and signed-out users see no invitation',
    (tester) async {
      await mount(tester, 'alice');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await mount(tester, 'bob');
      expect(find.text('View saved scholarships'), findsNothing);
      expect(find.text('Hi, Student!'), findsOneWidget);
      await mount(tester, null);
      expect(find.text('Hi, Student!'), findsNothing);
    },
  );

  testWidgets('tip controls remain usable at 320 wide with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester, 'alice');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Skip guide'));
    await tester.tap(find.byTooltip('Skip guide'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
