import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

ProfileSetupNotifier _notifier(FakeProfileDataSource dataSource,
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
}
