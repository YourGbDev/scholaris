import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/dashboard/presentation/widgets/student_notifications_sheet.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';

class _FakeApplicationsNotifier extends ApplicationsNotifier {
  final List<Application> _list;
  _FakeApplicationsNotifier(this._list);

  @override
  Future<List<Application>> build() async => _list;
}

void main() {
  Widget buildTestSubject({
    required List<Application> applications,
    required List<Scholarship> scholarships,
    required StudentProfile? profile,
    List<Map<String, dynamic>> notifications = const [],
  }) {
    return ProviderScope(
      overrides: [
        applicationsProvider.overrideWith(() => _FakeApplicationsNotifier(applications)),
        scholarshipsProvider.overrideWith((ref) => Future.value(scholarships)),
        currentProfileProvider.overrideWith((ref) => Future.value(profile)),
        studentNotificationsProvider.overrideWith((ref) => Future.value(notifications)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: StudentNotificationsSheet(),
        ),
      ),
    );
  }

  group('StudentNotificationsSheet', () {
    testWidgets('renders all caught up empty state when profile is complete and no active apps', (tester) async {
      final completeProfile = StudentProfile(
        id: 'std_1',
        fullName: 'Juan Dela Cruz',
        school: 'University of the Philippines Diliman',
        course: 'BS Computer Science',
        yearLevel: 3,
        gpa: 1.25,
      );

      await tester.pumpWidget(
        buildTestSubject(
          applications: [],
          scholarships: [],
          profile: completeProfile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text("You're All Caught Up"), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
    });

    testWidgets('renders profile completion notice when GPA is missing', (tester) async {
      final incompleteProfile = StudentProfile(
        id: 'std_2',
        fullName: 'Maria Santos',
        school: 'Polytechnic University of the Philippines',
        course: 'BS Accountancy',
        yearLevel: 2,
        gpa: 0.0, // missing GPA
      );

      await tester.pumpWidget(
        buildTestSubject(
          applications: [],
          scholarships: [],
          profile: incompleteProfile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('1 Active'), findsOneWidget);
      expect(find.text('Complete Your Academic Profile'), findsOneWidget);
      expect(find.text('Action Required'), findsOneWidget);
    });

    testWidgets('renders live application status notices', (tester) async {
      final completeProfile = StudentProfile(
        id: 'std_3',
        fullName: 'Pedro Penduko',
        school: 'Ateneo de Manila University',
        course: 'BS Biology',
        yearLevel: 4,
        gpa: 1.40,
      );

      final dummyScholarship = Scholarship(
        id: 'sch_1',
        title: 'DOST STEM Excellence Grant',
        provider: 'DOST-SEI',
        amount: 50000,
        frequency: 'per semester',
        minGpa: 1.75,
        deadline: DateTime(2026, 12, 31),
        description: 'STEM grant',
      );

      final submittedApp = Application(
        id: 'app_1',
        userId: 'u_3',
        scholarshipId: 'sch_1',
        status: ApplicationStatus.submitted,
        appliedAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      await tester.pumpWidget(
        buildTestSubject(
          applications: [submittedApp],
          scholarships: [dummyScholarship],
          profile: completeProfile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('1 Active'), findsOneWidget);
      expect(find.text('Application Under Review'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.textContaining('DOST STEM Excellence Grant'), findsOneWidget);
    });

    testWidgets('responsive at narrow mobile 360x800 without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dummyScholarship = Scholarship(
        id: 'sch_2',
        title: 'Ayala Future Leaders Program 2026',
        provider: 'Ayala Foundation',
        amount: 60000,
        frequency: 'per year',
        minGpa: 1.50,
        deadline: DateTime(2026, 11, 30),
        description: 'Leadership grant',
      );

      final awardedApp = Application(
        id: 'app_2',
        userId: 'u_4',
        scholarshipId: 'sch_2',
        status: ApplicationStatus.awarded,
        appliedAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 9, 20),
      );

      await tester.pumpWidget(
        buildTestSubject(
          applications: [awardedApp],
          scholarships: [dummyScholarship],
          profile: null,
          notifications: [
            {
              'id': 'notif_award_1',
              'title': 'Grant Awarded!',
              'message': 'Congratulations! Your submission for Ayala Future Leaders Program 2026 has been awarded.',
              'is_read': false,
              'target_id': 'app_2',
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grant Awarded!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
