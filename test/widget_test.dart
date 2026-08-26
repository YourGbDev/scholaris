// Smoke tests for the profile-setup wizard. The broken default counter test
// is replaced with meaningful coverage of the actual app: the three-step
// wizard renders its headings, progress and required/optional field markers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/presentation/profile_setup_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

Widget _wrap(String step) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-a'),
      profileSetupProvider.overrideWith(
        (ref, userId) => ProfileSetupNotifier(
          ProfileRepository(
            dataSource: FakeProfileDataSource(),
            currentUserId: () => 'user-a',
          ),
        ),
      ),
    ],
    child: MaterialApp(
      home: ProfileSetupScreen(step: step),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('personal step renders with required/optional markers',
      (tester) async {
    await tester.pumpWidget(_wrap('personal'));

    expect(find.text('Profile Setup'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Nationality *'), findsOneWidget);
    expect(find.text('Birth Date (optional)'), findsOneWidget);
  });

  testWidgets('academic step renders GPA, year level, course and school',
      (tester) async {
    await tester.pumpWidget(_wrap('academic'));

    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Academic Information'), findsOneWidget);
    expect(find.text('Year Level *'), findsOneWidget);
    expect(find.text('Course *'), findsOneWidget);
    expect(find.text('GPA *'), findsOneWidget);
    expect(find.text('School (optional)'), findsOneWidget);
  });

  testWidgets('financial step renders income, region and optional flags',
      (tester) async {
    await tester.pumpWidget(_wrap('financial'));

    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Financial Information'), findsOneWidget);
    expect(find.text('Monthly Family Income *'), findsOneWidget);
    expect(find.text('Prefer not to say'), findsOneWidget);
    expect(find.text('Region *'), findsOneWidget);
    expect(find.text('Province (optional)'), findsOneWidget);
    expect(find.text('City / Municipality (optional)'), findsOneWidget);
    expect(find.text('Has a disability'), findsOneWidget);
    expect(find.text('Indigenous person'), findsOneWidget);
  });

  testWidgets('returning user form is populated from the persisted profile',
      (tester) async {
    final dataSource = FakeProfileDataSource();
    await dataSource.upsertProfile('user-a', {
      'full_name': 'Maria Santos',
      'nationality': 'Filipino',
      'gpa': 3.6,
      'year_level': 3,
      'course': 'BS Nursing',
      'school': 'UST',
      'monthly_family_income': 30000,
      'region': 'NCR',
      'province': 'Metro Manila',
      'city_municipality': 'Manila',
      'setup_complete': true,
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-a'),
        profileSetupProvider.overrideWith(
          (ref, userId) => ProfileSetupNotifier(
            ProfileRepository(
              dataSource: dataSource,
              currentUserId: () => 'user-a',
            ),
          ),
        ),
      ],
      // Academic step exposes GPA / course / school — distinctive hydrated values.
      child: const MaterialApp(home: ProfileSetupScreen(step: 'academic')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('3.60'), findsOneWidget);
    expect(find.text('BS Nursing'), findsOneWidget);
    expect(find.text('UST'), findsOneWidget);
  });

  testWidgets('returning user full name populates on the personal step',
      (tester) async {
    final dataSource = FakeProfileDataSource();
    await dataSource.upsertProfile('user-a', {
      'full_name': 'Juan Dela Cruz',
      'nationality': 'Filipino',
      'gpa': 2.8,
      'year_level': 1,
      'course': 'BS Accountancy',
      'monthly_family_income': 20000,
      'region': 'NCR',
      'setup_complete': true,
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-a'),
        profileSetupProvider.overrideWith(
          (ref, userId) => ProfileSetupNotifier(
            ProfileRepository(
              dataSource: dataSource,
              currentUserId: () => 'user-a',
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: ProfileSetupScreen(step: 'personal')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Juan Dela Cruz'), findsOneWidget);
  });

  testWidgets('first-time user form starts empty even with async hydration',
      (tester) async {
    final dataSource = FakeProfileDataSource(); // No profile row for user-a.

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-a'),
        profileSetupProvider.overrideWith(
          (ref, userId) => ProfileSetupNotifier(
            ProfileRepository(
              dataSource: dataSource,
              currentUserId: () => 'user-a',
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: ProfileSetupScreen(step: 'personal')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Maria Santos'), findsNothing);
  });
}
