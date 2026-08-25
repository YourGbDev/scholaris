// Smoke tests for the profile-setup wizard. The broken default counter test
// is replaced with meaningful coverage of the actual app: the three-step
// wizard renders its headings, progress and required/optional field markers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/profile/presentation/profile_setup_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

Widget _wrap(String step) {
  return ProviderScope(
    overrides: [
      profileSetupProvider.overrideWith(
        (ref) => ProfileSetupNotifier(
          ProfileRepository(
            dataSource: FakeProfileDataSource(),
            currentUserId: () => null,
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
}
