// test/student_mascot_test.dart
//
// Comprehensive unit and widget tests for the StudentMascot component (Aris & Aria),
// covering gender resolution, pose path generation, profile-aware adaptive rendering,
// fallback behavior, interactivity, and backwards compatibility aliases.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/shared/widgets/student_mascot.dart';
import 'package:scholaris/shared/widgets/eli_mascot.dart';

void main() {
  group('MascotGender', () {
    test('fromString correctly parses male variations', () {
      expect(MascotGender.fromString('male'), MascotGender.male);
      expect(MascotGender.fromString('Male'), MascotGender.male);
      expect(MascotGender.fromString('MALE'), MascotGender.male);
      expect(MascotGender.fromString('m'), MascotGender.male);
      expect(MascotGender.fromString('M'), MascotGender.male);
      expect(MascotGender.fromString('boy'), MascotGender.male);
      expect(MascotGender.fromString('Boy'), MascotGender.male);
      expect(MascotGender.fromString('man'), MascotGender.male);
      expect(MascotGender.fromString('  male  '), MascotGender.male);
    });

    test('fromString defaults to female for null, female variations, and unknowns', () {
      expect(MascotGender.fromString(null), MascotGender.female);
      expect(MascotGender.fromString('female'), MascotGender.female);
      expect(MascotGender.fromString('Female'), MascotGender.female);
      expect(MascotGender.fromString('FEMALE'), MascotGender.female);
      expect(MascotGender.fromString('f'), MascotGender.female);
      expect(MascotGender.fromString('F'), MascotGender.female);
      expect(MascotGender.fromString('girl'), MascotGender.female);
      expect(MascotGender.fromString('woman'), MascotGender.female);
      expect(MascotGender.fromString('other'), MascotGender.female);
      expect(MascotGender.fromString(''), MascotGender.female);
    });
  });

  group('StudentMascotPose asset paths & semantics', () {
    test('all poses have non-empty assetKey and semanticsLabel', () {
      for (final pose in StudentMascotPose.values) {
        expect(pose.assetKey, isNotEmpty);
        expect(pose.semanticsLabel, isNotEmpty);
      }
    });

    test('assetPath resolves aris_ for male and aria_ for female', () {
      for (final pose in StudentMascotPose.values) {
        final malePath = pose.assetPath(MascotGender.male);
        final femalePath = pose.assetPath(MascotGender.female);

        expect(malePath, 'assets/images/mascot/aris_${pose.assetKey}.png');
        expect(femalePath, 'assets/images/mascot/aria_${pose.assetKey}.png');
      }
    });

    test('core expressions resolve correctly', () {
      expect(StudentMascotPose.hero.assetPath(MascotGender.male),
          'assets/images/mascot/aris_hero.png');
      expect(StudentMascotPose.happy.assetPath(MascotGender.female),
          'assets/images/mascot/aria_happy.png');
      expect(StudentMascotPose.determined.assetPath(MascotGender.male),
          'assets/images/mascot/aris_determined.png');
      expect(StudentMascotPose.thinking.assetPath(MascotGender.female),
          'assets/images/mascot/aria_thinking.png');
      expect(StudentMascotPose.celebrating.assetPath(MascotGender.male),
          'assets/images/mascot/aris_celebrating.png');
      expect(StudentMascotPose.curious.assetPath(MascotGender.female),
          'assets/images/mascot/aria_curious.png');
    });

    test('journey stages resolve correctly', () {
      expect(StudentMascotPose.student.assetPath(MascotGender.male),
          'assets/images/mascot/aris_student.png');
      expect(StudentMascotPose.applicant.assetPath(MascotGender.female),
          'assets/images/mascot/aria_applicant.png');
      expect(StudentMascotPose.scholar.assetPath(MascotGender.male),
          'assets/images/mascot/aris_scholar.png');
      expect(StudentMascotPose.graduate.assetPath(MascotGender.female),
          'assets/images/mascot/aria_graduate.png');
    });

    test('turnaround poses resolve correctly', () {
      expect(StudentMascotPose.front.assetPath(MascotGender.male),
          'assets/images/mascot/aris_front.png');
      expect(StudentMascotPose.side.assetPath(MascotGender.female),
          'assets/images/mascot/aria_side.png');
      expect(StudentMascotPose.back.assetPath(MascotGender.male),
          'assets/images/mascot/aris_back.png');
    });

    test('backwards compatibility aliases map to valid assets', () {
      expect(StudentMascotPose.welcome.assetKey, 'hero');
      expect(StudentMascotPose.neutral.assetKey, 'happy');
      expect(StudentMascotPose.brightGlow.assetKey, 'celebrating');
      expect(StudentMascotPose.dimGlow.assetKey, 'thinking');
      expect(StudentMascotPose.concerned.assetKey, 'thinking');
      expect(StudentMascotPose.guiding.assetKey, 'determined');
      expect(StudentMascotPose.studying.assetKey, 'scholar');
      expect(StudentMascotPose.encouraging.assetKey, 'celebrating');
      expect(StudentMascotPose.peeking.assetKey, 'curious');
      expect(StudentMascotPose.mail.assetKey, 'applicant');
      expect(StudentMascotPose.security.assetKey, 'determined');
    });
  });

  group('StudentMascot Widget', () {
    testWidgets('renders Aris when explicit male gender provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudentMascot(
              pose: StudentMascotPose.hero,
              gender: MascotGender.male,
              height: 120,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/mascot/aris_hero.png');
      expect(imageWidget.height, 120);
      expect(imageWidget.semanticLabel, StudentMascotPose.hero.semanticsLabel);
    });

    testWidgets('renders Aria when explicit female gender provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudentMascot(
              pose: StudentMascotPose.celebrating,
              gender: MascotGender.female,
              height: 150,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/mascot/aria_celebrating.png');
      expect(imageWidget.height, 150);
      expect(imageWidget.semanticLabel, StudentMascotPose.celebrating.semanticsLabel);
    });

    testWidgets('defaults to Aria (female) when no ProviderScope is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudentMascot(
              pose: StudentMascotPose.thinking,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/mascot/aria_thinking.png');
    });

    testWidgets('adapts to male profile from currentProfileProvider', (tester) async {
      const maleProfile = StudentProfile(
        id: 'male-user',
        fullName: 'Juan Dela Cruz',
        gender: 'Male',
        region: 'NCR',
        gpa: 3.5,
        yearLevel: 2,
        course: 'BS IT',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => Future.value(maleProfile)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudentMascot(
                pose: StudentMascotPose.applicant,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/mascot/aris_applicant.png');
    });

    testWidgets('adapts to female profile from currentProfileProvider', (tester) async {
      const femaleProfile = StudentProfile(
        id: 'female-user',
        fullName: 'Maria Santos',
        gender: 'Female',
        region: 'Region VII',
        gpa: 3.8,
        yearLevel: 3,
        course: 'BS Nursing',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => Future.value(femaleProfile)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudentMascot(
                pose: StudentMascotPose.scholar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/mascot/aria_scholar.png');
    });

    testWidgets('fires onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentMascot(
              pose: StudentMascotPose.happy,
              width: 140,
              height: 140,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StudentMascot));
      expect(tapped, isTrue);
    });

    testWidgets('backward compatibility aliases work seamlessly', (tester) async {
      // EliMascot and LumiMascot are typedefs for StudentMascot
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EliMascot(
                  pose: EliPose.celebrating,
                  gender: MascotGender.male,
                ),
                LumiMascot(
                  pose: LumiPose.thinking,
                  gender: MascotGender.female,
                ),
              ],
            ),
          ),
        ),
      );

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, 2);

      final img1 = images[0].image as AssetImage;
      final img2 = images[1].image as AssetImage;

      expect(img1.assetName, 'assets/images/mascot/aris_celebrating.png');
      expect(img2.assetName, 'assets/images/mascot/aria_thinking.png');
    });
  });
}
