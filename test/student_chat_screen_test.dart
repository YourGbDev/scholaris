import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/widgets/student_action_sheet.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

void main() {
  Future<void> openChat(
    WidgetTester tester, {
    String? gender,
    String name = 'Alex Reyes',
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith(
            (ref) async =>
                StudentProfile(id: 'student', fullName: name, gender: gender),
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
            'assets/mascots/mascot_${gender.toLowerCase()}_celebrating.png',
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
    expect(find.text('About scholarship chat'), findsOneWidget);
    expect(find.textContaining('eligibility'), findsOneWidget);
    await tester.tap(find.text('Got it'));
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
      await openChat(tester, gender: 'Female', scale: 1.6);
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
}
