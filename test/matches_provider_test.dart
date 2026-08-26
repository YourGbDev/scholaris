// Verifies the personalized matches provider: it combines the signed-in
// student's profile with the active catalog through the deterministic
// MatchingEngine and returns the ranked eligible set.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

StudentProfile _student() => StudentProfile(
      id: 'user-a',
      fullName: 'Maria Santos',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 3.2,
      yearLevel: 2,
      course: 'BS Computer Science',
      monthlyFamilyIncome: 15000,
      setupComplete: true,
    );

ProviderContainer _container() {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile('user-a', _student().toDbRow());

  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-a'),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileSource,
          currentUserId: () => 'user-a',
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(
          dataSource: FakeScholarshipDataSource(),
        ),
      ),
    ],
  );
}

void main() {
  test('matchesProvider returns ranked eligible scholarships for the student',
      () async {
    final container = _container();
    addTearDown(container.dispose);

    final matches = await container.read(matchesProvider.future);

    // Profile: GPA 3.2, year 2, NCR, income 15000 (low bracket).
    // CHED requires GPA 3.0 + low income → eligible.
    // DOST requires GPA 2.0 → eligible (soonest deadline → ranks first).
    expect(matches.map((s) => s.id), ['sch-dost', 'sch-ched']);
  });

  test('matchesProvider is empty without a built profile', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-a'),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: FakeProfileDataSource(),
            currentUserId: () => 'user-a',
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: FakeScholarshipDataSource(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final matches = await container.read(matchesProvider.future);

    expect(matches, isEmpty);
  });
}
