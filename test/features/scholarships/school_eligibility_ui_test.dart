// test/features/scholarships/school_eligibility_ui_test.dart
//
// UI Test Suite: School Eligibility & Capacity Accounting on ScholarshipDetailScreen
// Verifies:
// 1. Open to all schools banner when eligible_school_ids is empty or null.
// 2. Truthful self-declared enrollment disclosure note is displayed.
// 3. Matching school displays green "Eligible based on declared profile" badge and enables apply.
// 4. Ineligible school displays amber "Ineligible based on profile" banner and gates apply action.
// 5. Authoritative slot capacity card renders seat metrics (uncapped vs. remaining seats vs. full).
// 6. Viewport responsiveness across narrow mobile (360x800), large mobile (440x956), and desktop (1280x800).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/models/scholarship_capacity.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarship_capacity_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/schools/models/school.dart';
import 'package:scholaris/features/schools/providers/school_provider.dart';

class _FakeBookmarksNotifier extends BookmarksNotifier {
  @override
  Future<Set<String>> build() async => <String>{};
}

class _FakeApplicationsNotifier extends ApplicationsNotifier {
  @override
  Future<List<Application>> build() async => <Application>[];
}

void main() {
  final sampleSchools = [
    const School(
      id: 'sch-upd',
      name: 'University of the Philippines Diliman',
      normalizedName: 'university of the philippines diliman',
      aliases: ['UP Diliman', 'UPD'],
    ),
    const School(
      id: 'sch-ateneo',
      name: 'Ateneo de Manila University',
      normalizedName: 'ateneo de manila university',
      aliases: ['ADMU', 'Ateneo'],
    ),
    const School(
      id: 'sch-dlsu',
      name: 'De La Salle University',
      normalizedName: 'de la salle university',
      aliases: ['DLSU', 'La Salle'],
    ),
  ];

  final baseScholarship = Scholarship(
    id: 'sch-stem-101',
    title: 'Future Leaders STEM Grant',
    minGpa: 1.75,
    deadline: DateTime.now().add(const Duration(days: 30)),
    amount: 75000,
    isActive: true,
  );

  Widget createWidget({
    required Scholarship scholarship,
    required StudentProfile profile,
    List<String>? eligibleSchoolIds,
    String? studentSchoolId,
    ScholarshipCapacity? capacity,
    Size size = const Size(1280, 800),
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => 'student-1'),
        currentProfileProvider.overrideWith((ref) async => profile),
        scholarshipByIdProvider(scholarship.id).overrideWith((ref) async => scholarship),
        scholarshipCapacityProvider(scholarship.id).overrideWith((ref) async => capacity),
        scholarshipEligibleSchoolsProvider(scholarship.id).overrideWith((ref) async => eligibleSchoolIds),
        studentProfileSchoolIdProvider('student-1').overrideWith((ref) async => studentSchoolId),
        schoolsProvider.overrideWith((ref) async => sampleSchools),
        bookmarksProvider.overrideWith(() => _FakeBookmarksNotifier()),
        applicationsProvider.overrideWith(() => _FakeApplicationsNotifier()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: ScholarshipDetailScreen(
              scholarshipId: scholarship.id,
              initial: scholarship,
            ),
          ),
        ),
      ),
    );
  }

  group('School Eligibility & Capacity UI Suite', () {
    testWidgets('Open to all schools: Renders open banner and verification disclosure note', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = StudentProfile(
        id: 'student-1',
        fullName: 'Juan Dela Cruz',
        school: 'University of the Philippines Diliman',
        gpa: 1.5,
        setupComplete: true,
      );

      await tester.pumpWidget(createWidget(
        scholarship: baseScholarship,
        profile: profile,
        eligibleSchoolIds: null, // Open to all
        capacity: const ScholarshipCapacity(
          scholarshipId: 'sch-stem-101',
          totalSlots: 25,
          occupiedSlots: 1,
          remainingSlots: 24,
          isUncapped: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Open badge text
      expect(
        find.text('Open to all accredited Philippine universities & colleges'),
        findsOneWidget,
      );

      // Truthful verification disclosure
      expect(
        find.textContaining('Academic enrollment is self-declared on your student profile'),
        findsOneWidget,
      );

      // Apply button should be visible and ready
      expect(find.byKey(const ValueKey('apply-now')), findsOneWidget);
      expect(find.text('Start Application'), findsOneWidget);
    });

    testWidgets('Matching partner school: Renders green eligible badge and enables apply', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = StudentProfile(
        id: 'student-1',
        fullName: 'Juan Dela Cruz',
        school: 'University of the Philippines Diliman',
        gpa: 1.5,
        setupComplete: true,
      );

      await tester.pumpWidget(createWidget(
        scholarship: baseScholarship,
        profile: profile,
        eligibleSchoolIds: ['sch-upd', 'sch-ateneo'],
        studentSchoolId: 'sch-upd',
        capacity: const ScholarshipCapacity(
          scholarshipId: 'sch-stem-101',
          totalSlots: 25,
          occupiedSlots: 1,
          remainingSlots: 24,
          isUncapped: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Eligible based on declared profile (Matches: University of the Philippines Diliman)'),
        findsOneWidget,
      );

      // Apply button remains enabled
      expect(find.byKey(const ValueKey('apply-now')), findsOneWidget);
      expect(find.text('Start Application'), findsOneWidget);
    });

    testWidgets('Non-matching partner school: Renders ineligible notice and gates Apply button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = StudentProfile(
        id: 'student-1',
        fullName: 'Juan Dela Cruz',
        school: 'De La Salle University',
        gpa: 1.5,
        setupComplete: true,
      );

      await tester.pumpWidget(createWidget(
        scholarship: baseScholarship,
        profile: profile,
        eligibleSchoolIds: ['sch-upd'],
        studentSchoolId: 'sch-dlsu',
        capacity: const ScholarshipCapacity(
          scholarshipId: 'sch-stem-101',
          totalSlots: 25,
          occupiedSlots: 1,
          remainingSlots: 24,
          isUncapped: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Ineligible guidance badge
      expect(
        find.text('Ineligible based on profile: Restricted to partner institutions.'),
        findsAtLeastNWidgets(1),
      );

      // Apply button should NOT be available; instead gate notice is shown
      expect(find.byKey(const ValueKey('apply-now')), findsNothing);
      expect(find.text('Start Application'), findsNothing);
    });

    testWidgets('Capacity accounting: Uncapped capacity renders Uncapped status', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = StudentProfile(
        id: 'student-1',
        fullName: 'Juan Dela Cruz',
        school: 'University of the Philippines Diliman',
        gpa: 1.5,
        setupComplete: true,
      );

      await tester.pumpWidget(createWidget(
        scholarship: baseScholarship,
        profile: profile,
        eligibleSchoolIds: null,
        capacity: const ScholarshipCapacity(
          scholarshipId: 'sch-stem-101',
          totalSlots: null,
          occupiedSlots: 5,
          remainingSlots: null,
          isUncapped: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Slot Capacity & Seat Accounting'), findsOneWidget);
      expect(find.text('Uncapped'), findsOneWidget);
      expect(find.text('Uncapped capacity • 5 scholars approved'), findsOneWidget);
    });

    testWidgets('Capacity accounting: Capped slots render remaining seat metric', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = StudentProfile(
        id: 'student-1',
        fullName: 'Juan Dela Cruz',
        school: 'University of the Philippines Diliman',
        gpa: 1.5,
        setupComplete: true,
      );

      await tester.pumpWidget(createWidget(
        scholarship: baseScholarship,
        profile: profile,
        eligibleSchoolIds: null,
        capacity: const ScholarshipCapacity(
          scholarshipId: 'sch-stem-101',
          totalSlots: 25,
          occupiedSlots: 1,
          remainingSlots: 24,
          isUncapped: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('24 Seats Open'), findsOneWidget);
      expect(find.text('25 total • 1 occupied • 24 remaining'), findsOneWidget);
    });

    testWidgets('Capacity accounting: Full capacity gates apply button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = StudentProfile(
        id: 'student-1',
        fullName: 'Juan Dela Cruz',
        school: 'University of the Philippines Diliman',
        gpa: 1.5,
        setupComplete: true,
      );

      await tester.pumpWidget(createWidget(
        scholarship: baseScholarship,
        profile: profile,
        eligibleSchoolIds: null,
        capacity: const ScholarshipCapacity(
          scholarshipId: 'sch-stem-101',
          totalSlots: 25,
          occupiedSlots: 25,
          remainingSlots: 0,
          isUncapped: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Capacity Reached'), findsOneWidget);
      expect(find.text('Scholarship capacity reached'), findsOneWidget);
      expect(find.byKey(const ValueKey('apply-now')), findsNothing);
      expect(find.text('Start Application'), findsNothing);
    });

    testWidgets('Responsive rendering: Zero overflow on narrow mobile (360x800)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = StudentProfile(
        id: 'student-1',
        fullName: 'Juan Dela Cruz',
        school: 'University of the Philippines Diliman',
        gpa: 1.5,
        setupComplete: true,
      );

      await tester.pumpWidget(createWidget(
        scholarship: baseScholarship,
        profile: profile,
        eligibleSchoolIds: ['sch-upd'],
        studentSchoolId: 'sch-upd',
        capacity: const ScholarshipCapacity(
          scholarshipId: 'sch-stem-101',
          totalSlots: 25,
          occupiedSlots: 1,
          remainingSlots: 24,
          isUncapped: false,
        ),
        size: const Size(360, 800),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Future Leaders STEM Grant'), findsOneWidget);
    });

    testWidgets('Responsive rendering: Zero overflow on large mobile (440x956)', (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = StudentProfile(
        id: 'student-1',
        fullName: 'Juan Dela Cruz',
        school: 'University of the Philippines Diliman',
        gpa: 1.5,
        setupComplete: true,
      );

      await tester.pumpWidget(createWidget(
        scholarship: baseScholarship,
        profile: profile,
        eligibleSchoolIds: ['sch-upd'],
        studentSchoolId: 'sch-upd',
        capacity: const ScholarshipCapacity(
          scholarshipId: 'sch-stem-101',
          totalSlots: 25,
          occupiedSlots: 1,
          remainingSlots: 24,
          isUncapped: false,
        ),
        size: const Size(440, 956),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Future Leaders STEM Grant'), findsOneWidget);
    });
  });
}
