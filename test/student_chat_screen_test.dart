import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/home/presentation/student_chat_screen.dart';
import 'package:scholaris/features/home/presentation/widgets/student_action_sheet.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

void main() {
  Future<void> openChat(
    WidgetTester tester, {
    String? gender,
    String name = 'Alex Reyes',
    double scale = 1,
    bool seen = true,
    String userId = 'student',
  }) async {
    SharedPreferences.setMockInitialValues(
      seen ? {'student_chat_guide_v1_$userId': true} : {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith(
            (ref) async =>
                StudentProfile(id: userId, fullName: name, gender: gender),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showStudentActionSheet(context),
                child: const Text('Open actions'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
  }

  for (final gender in ['Male', 'Female']) {
    testWidgets(
      'chat uses profile name and $gender mascot with a working back button',
      (tester) async {
        await openChat(tester, gender: gender);
        expect(find.text('Hi, Alex!'), findsOneWidget);
        final images = tester
            .widgetList<Image>(find.byType(Image))
            .map((image) => image.image)
            .whereType<AssetImage>();
        expect(
          images.map((image) => image.assetName),
          contains(
            gender == 'Female'
                ? 'assets/mascots/chat/ariel_welcome.png'
                : 'assets/mascots/chat/ari_welcome.png',
          ),
        );
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Open actions'), findsOneWidget);
        expect(find.text('Quick Actions'), findsNothing);
      },
    );
  }

  testWidgets('chat explains availability and keeps a typed draft unsent', (
    tester,
  ) async {
    await openChat(tester);
    expect(find.text('AI replies are not connected yet.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Which scholarships fit my course?',
    );
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Send unavailable'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Chat help'));
    await tester.pumpAndSettle();
    expect(find.text('Meet Ari'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Which scholarships fit my course?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'chat composer remains usable with keyboard and enlarged phone text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await openChat(tester, gender: 'Female', scale: 2);
      expect(tester.takeException(), isNull, reason: 'before keyboard');
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'My draft');
      await tester.pumpAndSettle();
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      expect(
        tester.getBottomRight(find.byType(TextField)).dy,
        lessThanOrEqualTo(328),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('first use finishes only on skip or final start and can replay', (
    tester,
  ) async {
    await openChat(tester, seen: false, gender: 'Male');
    expect(find.text('Meet Ari'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('student_chat_guide_v1_student'), isNull);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Find your next opportunity'), findsOneWidget);
    expect(prefs.getBool('student_chat_guide_v1_student'), isNull);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Tools for your next step'), findsOneWidget);
    await tester.tap(find.text('Start chat'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('student_chat_guide_v1_student'), isTrue);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byTooltip('Chat help'));
    await tester.pumpAndSettle();
    expect(find.text('Meet Ari'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('completion is scoped to the current profile', (tester) async {
    await openChat(tester, seen: false, userId: 'second');
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('student_chat_guide_v1_second'), isTrue);
    expect(prefs.getBool('student_chat_guide_v1_student'), isNull);
  });

  testWidgets('each visible tool explains its real flow before opening', (
    tester,
  ) async {
    await openChat(tester);
    for (final label in ['Scan QR', 'Upload document', 'Find scholarships']) {
      expect(find.text(label).hitTestable(), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Open tool'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    }
  });

  testWidgets('Find scholarships opens Home with Discover selected', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'student_chat_guide_v1_student': true,
    });
    final router = GoRouter(
      initialLocation: '/chat',
      routes: [
        GoRoute(path: '/chat', builder: (_, _) => const StudentChatScreen()),
        GoRoute(
          path: '/home',
          builder: (_, _) => Consumer(
            builder: (_, ref, _) => Scaffold(
              body: Text('Selected tab ${ref.watch(homeTabIndexProvider)}'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('student'),
          currentProfileProvider.overrideWith(
            (ref) async =>
                const StudentProfile(id: 'student', fullName: 'Alex Reyes'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find scholarships'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open tool'));
    await tester.pumpAndSettle();
    expect(find.text('Selected tab 1'), findsOneWidget);
    expect(find.byType(StudentChatScreen), findsNothing);
  });

  testWidgets(
    'guide fits narrow enlarged text and leaving does not complete it',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await openChat(tester, seen: false, scale: 2);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Start chat').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Previous guide step'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous guide step'));
      await tester.pumpAndSettle();
      expect(find.text('Meet Ari'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('student_chat_guide_v1_student'), isNull);
    },
  );
}
