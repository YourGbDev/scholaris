import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'helpers/fake_profile_data_source.dart';

StudentProfile _profile({
  String id = 'user-a',
  double gpa = 3.0,
  int yearLevel = 2,
  String course = 'BS Computer Science',
  double? monthlyFamilyIncome = 15000,
  String region = 'NCR',
  bool setupComplete = true,
  String fullName = 'Maria Santos',
}) =>
    StudentProfile(
      id: id,
      fullName: fullName,
      nationality: 'Filipino',
      region: region,
      province: 'Metro Manila',
      cityMunicipality: 'Manila',
      gpa: gpa,
      yearLevel: yearLevel,
      course: course,
      school: 'WLC',
      monthlyFamilyIncome: monthlyFamilyIncome,
      setupComplete: setupComplete,
    );

void main() {
  group('ProfileRepository', () {
    late FakeProfileDataSource dataSource;
    late ProfileRepository repo;

    setUp(() {
      dataSource = FakeProfileDataSource();
      repo = ProfileRepository(
        dataSource: dataSource,
        currentUserId: () => 'user-a',
      );
    });

    test('fetchCurrent returns null when no profile exists', () async {
      final result = await repo.fetchCurrent();
      expect(result, isNull);
    });

    test('create and retrieve own profile (persistence round-trip)', () async {
      final profile = _profile();
      await repo.saveCurrent(profile: profile);

      final fetched = await repo.fetchCurrent();
      expect(fetched, isNotNull);
      expect(fetched!.id, 'user-a');
      expect(fetched.gpa, 3.0);
      expect(fetched.yearLevel, 2);
      expect(fetched.course, 'BS Computer Science');
      expect(fetched.monthlyFamilyIncome, 15000);
      expect(fetched.region, 'NCR');
      expect(fetched.fullName, 'Maria Santos');
      expect(fetched.setupComplete, isTrue);
    });

    test('update profile overwrites fields', () async {
      final first = _profile();
      await repo.saveCurrent(profile: first);

      final updated = _profile(monthlyFamilyIncome: 40000, gpa: 3.5);
      await repo.saveCurrent(profile: updated);

      final fetched = await repo.fetchCurrent();
      expect(fetched!.monthlyFamilyIncome, 40000);
      expect(fetched.gpa, 3.5);
    });

    test('retrieve incomplete profile (setupComplete false)', () async {
      final profile = _profile(setupComplete: false);
      await repo.saveCurrent(profile: profile);

      final fetched = await repo.fetchCurrent();
      expect(fetched!.setupComplete, isFalse);
    });

    test('own profile access: authenticated user reads only own row', () async {
      // Save a row for user-b.
      await dataSource.upsertProfile('user-b', {'full_name': 'Other User'});

      // Authenticated as user-a (no row yet).
      final result = await repo.fetchCurrent();
      expect(result, isNull);
    });

    test('prevents saving another user\'s profile', () async {
      final otherProfile = _profile(id: 'user-b');

      expect(
        () => repo.saveCurrent(profile: otherProfile),
        throwsA(isA<ProfileOwnershipException>()),
      );
    });

    test('unauthenticated user cannot fetch or save', () async {
      final unauthenticatedRepo = ProfileRepository(
        dataSource: dataSource,
        currentUserId: () => null,
      );

      expect(await unauthenticatedRepo.fetchCurrent(), isNull);

      expect(
        () => unauthenticatedRepo.saveCurrent(profile: _profile()),
        throwsA(isA<ProfileNotAuthenticatedException>()),
      );
    });

    test('snake_case columns are written to the data source', () async {
      final profile = _profile();
      await repo.saveCurrent(profile: profile);

      // Check the raw row stored in the fake data source.
      final raw = dataSource.rows['user-a']!;
      expect(raw['full_name'], 'Maria Santos');
      expect(raw['gpa'], 3.0);
      expect(raw['year_level'], 2);
      expect(raw['monthly_family_income'], 15000);
      expect(raw['setup_complete'], isTrue);
      // camelCase keys should NOT appear in the DB row.
      expect(raw.containsKey('fullName'), isFalse);
      expect(raw.containsKey('yearLevel'), isFalse);
    });
  });
}