import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

ProfileSetupNotifier _notifier(ProfileDataSource dataSource,
    {String? Function()? currentUserId}) {
  return ProfileSetupNotifier(
    ProfileRepository(
      dataSource: dataSource,
      currentUserId: currentUserId ?? () => 'user-a',
    ),
  );
}

/// Fills every field with valid values.
void _fill(ProfileSetupNotifier n) {
  n.setFullName('Maria Santos');
  n.setNationality('Filipino');
  n.setYearLevel(2);
  n.setCourse('BS Computer Science');
  n.setGpa('3.5');
  n.setMonthlyFamilyIncome('15000');
  n.setRegion('NCR');
}

/// A fully-populated `profiles` row, as a returning user would have persisted.
Map<String, dynamic> _profileRow({
  String fullName = 'Maria Santos',
  double gpa = 3.6,
  int yearLevel = 3,
  String course = 'BS Nursing',
  String? school = 'UST',
  double? monthlyFamilyIncome = 30000,
  String region = 'NCR',
  String province = 'Metro Manila',
  String cityMunicipality = 'Manila',
  bool hasDisability = false,
  bool isIndigenous = false,
}) =>
    {
      'full_name': fullName,
      'nationality': 'Filipino',
      'gpa': gpa,
      'year_level': yearLevel,
      'course': course,
      'school': school,
      'monthly_family_income': monthlyFamilyIncome,
      'region': region,
      'province': province,
      'city_municipality': cityMunicipality,
      'has_disability': hasDisability,
      'is_indigenous': isIndigenous,
      'setup_complete': true,
    };

void main() {
  group('ProfileSetupNotifier', () {
    test('valid profile is persisted with setup_complete true', () async {
      final dataSource = FakeProfileDataSource();
      final notifier = _notifier(dataSource);
      _fill(notifier);

      final ok = await notifier.submit();

      expect(ok, isTrue);
      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.error, isNull);

      final row = dataSource.rows['user-a']!;
      expect(row['full_name'], 'Maria Santos');
      expect(row['gpa'], 3.5);
      expect(row['year_level'], 2);
      expect(row['monthly_family_income'], 15000);
      expect(row['region'], 'NCR');
      expect(row['setup_complete'], isTrue);
    });

    test('updating an existing profile overwrites the stored values', () async {
      final dataSource = FakeProfileDataSource();
      final notifier = _notifier(dataSource);
      _fill(notifier);
      await notifier.submit();

      notifier.setGpa('3.9');
      notifier.setMonthlyFamilyIncome('40000');
      final ok = await notifier.submit();

      expect(ok, isTrue);
      final row = dataSource.rows['user-a']!;
      expect(row['gpa'], 3.9);
      expect(row['monthly_family_income'], 40000);
    });

    test('incomplete profile is not created when validation fails', () async {
      final dataSource = FakeProfileDataSource();
      final notifier = _notifier(dataSource);
      // Nothing filled.
      final ok = await notifier.submit();

      expect(ok, isFalse);
      expect(dataSource.rows, isEmpty);
      expect(notifier.state.fieldErrors, isNotNull);
      expect(notifier.state.fieldErrors!.fullName, isNotNull);
    });

    test('invalid GPA blocks submission and sets the field error', () async {
      final dataSource = FakeProfileDataSource();
      final notifier = _notifier(dataSource);
      _fill(notifier);
      notifier.setGpa('4.5');

      final ok = await notifier.submit();

      expect(ok, isFalse);
      expect(dataSource.rows, isEmpty);
      expect(notifier.state.fieldErrors!.gpa, 'GPA must be between 1.0 and 4.0.');
    });

    test('invalid year level blocks submission', () async {
      final dataSource = FakeProfileDataSource();
      final notifier = _notifier(dataSource);
      _fill(notifier);
      notifier.setYearLevel(0);

      final ok = await notifier.submit();

      expect(ok, isFalse);
      expect(dataSource.rows, isEmpty);
      expect(notifier.state.fieldErrors!.yearLevel, isNotNull);
    });

    test('empty income blocks submission unless undisclosed', () async {
      final dataSource = FakeProfileDataSource();
      final notifier = _notifier(dataSource);
      _fill(notifier);
      notifier.setMonthlyFamilyIncome('');

      expect(await notifier.submit(), isFalse);
      expect(dataSource.rows, isEmpty);

      notifier.setIncomeUndisclosed(true);
      expect(await notifier.submit(), isTrue);
      expect(dataSource.rows['user-a']!['monthly_family_income'], isNull);
    });

    test('step validation surfaces only the current step errors', () async {
      final notifier = _notifier(FakeProfileDataSource());
      notifier.setFullName('');

      final personalErrors = notifier.validateStep('personal');
      expect(personalErrors!.fullName, isNotNull);
      expect(personalErrors.gpa, isNull);
      expect(notifier.state.fieldErrors!.fullName, isNotNull);
    });

    test('unauthenticated submission fails with a friendly error', () async {
      final notifier = _notifier(FakeProfileDataSource(), currentUserId: () => null);
      _fill(notifier);

      final ok = await notifier.submit();

      expect(ok, isFalse);
      expect(notifier.state.error, 'You must be signed in to save your profile.');
    });
  });

  group('ProfileSetupNotifier hydration', () {
    test('returning user draft hydrates from the persisted profile', () async {
      final dataSource = FakeProfileDataSource();
      await dataSource.upsertProfile('user-a', _profileRow());
      final notifier = _notifier(dataSource);

      await notifier.hydrationComplete;

      final state = notifier.state;
      expect(state.hydrated, isTrue);
      expect(state.fullName, 'Maria Santos');
      expect(state.nationality, 'Filipino');
      expect(state.gpa, '3.60');
      expect(state.yearLevel, 3);
      expect(state.course, 'BS Nursing');
      expect(state.school, 'UST');
      expect(state.monthlyFamilyIncome, '30000');
      expect(state.incomeUndisclosed, isFalse);
      expect(state.region, 'NCR');
      expect(state.province, 'Metro Manila');
      expect(state.cityMunicipality, 'Manila');
    });

    test('hydration maps undisclosed income to the prefer-not-to-say state',
        () async {
      final dataSource = FakeProfileDataSource();
      await dataSource.upsertProfile(
        'user-a',
        _profileRow(monthlyFamilyIncome: null),
      );
      final notifier = _notifier(dataSource);

      await notifier.hydrationComplete;

      expect(notifier.state.monthlyFamilyIncome, '');
      expect(notifier.state.incomeUndisclosed, isTrue);
    });

    test('first-time user with no profile stays on the empty form', () async {
      final notifier = _notifier(FakeProfileDataSource());

      await notifier.hydrationComplete;

      expect(notifier.state.hydrated, isFalse);
      expect(notifier.state.fullName, '');
      expect(notifier.state.gpa, '');
      expect(notifier.state.region, isNull);
    });

    test('hydration does not overwrite an in-progress draft', () async {
      final dataSource = FakeProfileDataSource();
      await dataSource.upsertProfile('user-a', _profileRow());
      final notifier = _notifier(dataSource);

      // The user starts typing before the async hydration lands.
      notifier.setFullName('J');
      await notifier.hydrationComplete;

      expect(notifier.state.fullName, 'J');
      expect(notifier.state.hydrated, isFalse);
    });

    test('hydration does not mark a failed fetch as hydrated', () async {
      final dataSource = _ThrowingProfileDataSource();
      final notifier = _notifier(dataSource);

      await notifier.hydrationComplete;

      expect(notifier.state.hydrated, isFalse);
      expect(notifier.state.fullName, '');
    });
  });
}

/// A [ProfileDataSource] whose reads throw, simulating a backend failure.
class _ThrowingProfileDataSource implements ProfileDataSource {
  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    throw Exception('network down');
  }

  @override
  Future<void> upsertProfile(String userId, Map<String, dynamic> row) async {}
}
