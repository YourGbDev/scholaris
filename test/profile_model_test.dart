import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/profile/models/profile_validator.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';

StudentProfile _profile({
  double gpa = 3.0,
  int yearLevel = 2,
  String course = 'BS Computer Science',
  double? monthlyFamilyIncome = 15000,
  String region = 'NCR',
  String nationality = 'Filipino',
  String fullName = 'Maria Santos',
  String? school = 'Western Leyte College of Ormoc',
  String? province = 'Metro Manila',
  String? cityMunicipality = 'Manila',
  DateTime? birthDate,
  String? gender,
}) =>
    StudentProfile(
      id: 'user-a',
      fullName: fullName,
      nationality: nationality,
      region: region,
      province: province,
      cityMunicipality: cityMunicipality,
      gpa: gpa,
      yearLevel: yearLevel,
      course: course,
      school: school,
      birthDate: birthDate,
      gender: gender,
      monthlyFamilyIncome: monthlyFamilyIncome,
      setupComplete: true,
    );

void main() {
  group('StudentProfile JSON mapping (snake_case DB ↔ camelCase model)', () {
    test('fromJson parses a snake_case Supabase row', () {
      final profile = StudentProfile.fromJson({
        'id': 'user-a',
        'full_name': 'Maria Santos',
        'nationality': 'Filipino',
        'region': 'NCR',
        'province': 'Metro Manila',
        'city_municipality': 'Manila',
        'gpa': 3.5,
        'year_level': 3,
        'course': 'BS Computer Science',
        'school': 'Western Leyte College of Ormoc',
        'monthly_family_income': 20000,
        'has_disability': true,
        'is_indigenous': false,
        'setup_complete': true,
        'birth_date': '2004-05-12',
        'created_at': '2026-08-01T00:00:00.000Z',
        'updated_at': '2026-08-01T00:00:00.000Z',
      });

      expect(profile.id, 'user-a');
      expect(profile.fullName, 'Maria Santos');
      expect(profile.gpa, 3.5);
      expect(profile.yearLevel, 3);
      expect(profile.monthlyFamilyIncome, 20000);
      expect(profile.hasDisability, isTrue);
      expect(profile.setupComplete, isTrue);
      expect(profile.birthDate, DateTime(2004, 5, 12));
      expect(profile.createdAt, isNotNull);
    });

    test('fromJson applies defaults for missing optional columns', () {
      final profile = StudentProfile.fromJson({
        'id': 'user-a',
        'full_name': 'Maria Santos',
        'region': 'NCR',
        'gpa': 3.0,
        'year_level': 1,
        'course': 'BS Accountancy',
      });

      expect(profile.nationality, 'Filipino');
      expect(profile.monthlyFamilyIncome, isNull);
      expect(profile.hasDisability, isFalse);
      expect(profile.isIndigenous, isFalse);
      expect(profile.setupComplete, isFalse);
      expect(profile.birthDate, isNull);
    });

    test('toJson round-trips a full profile', () {
      final profile = _profile(
        gpa: 3.75,
        yearLevel: 4,
        course: 'BS Nursing',
        monthlyFamilyIncome: 40000,
      );
      final decoded = StudentProfile.fromJson(profile.toJson());

      expect(decoded, profile);
    });

    test('toDbRow maps to snake_case DB columns and excludes system columns', () {
      final profile = _profile();

      final row = profile.toDbRow();

      expect(row, {
        'full_name': 'Maria Santos',
        'birth_date': null,
        'gender': null,
        'nationality': 'Filipino',
        'region': 'NCR',
        'province': 'Metro Manila',
        'city_municipality': 'Manila',
        'gpa': 3.0,
        'year_level': 2,
        'course': 'BS Computer Science',
        'school': 'Western Leyte College of Ormoc',
        'monthly_family_income': 15000,
        'has_disability': false,
        'is_indigenous': false,
        'setup_complete': true,
      });
      expect(row.containsKey('id'), isFalse);
      expect(row.containsKey('created_at'), isFalse);
      expect(row.containsKey('updated_at'), isFalse);
    });
  });

  group('incomeBracket derivation', () {
    test('derives low / mid / high from monthly income', () {
      expect(_profile(monthlyFamilyIncome: 10000).incomeBracket, 'low');
      expect(_profile(monthlyFamilyIncome: 25000).incomeBracket, 'mid');
      expect(_profile(monthlyFamilyIncome: 70000).incomeBracket, 'mid');
      expect(_profile(monthlyFamilyIncome: 90000).incomeBracket, 'high');
    });

    test('is null when income is not disclosed', () {
      expect(_profile(monthlyFamilyIncome: null).incomeBracket, isNull);
    });
  });

  group('ProfileValidator', () {
    const validator = ProfileValidator();

    ProfileFieldErrors validate({
      String fullName = 'Maria Santos',
      String nationality = 'Filipino',
      double? gpa = 3.0,
      int? yearLevel = 2,
      String course = 'BS Computer Science',
      String monthlyFamilyIncome = '15000',
      bool incomeUndisclosed = false,
      String? region = 'NCR',
    }) =>
        validator.validate(
          fullName: fullName,
          nationality: nationality,
          gpa: gpa,
          yearLevel: yearLevel,
          course: course,
          monthlyFamilyIncome: monthlyFamilyIncome,
          incomeUndisclosed: incomeUndisclosed,
          region: region,
        );

    test('a valid profile has no errors', () {
      expect(validate().isValid, isTrue);
    });

    test('invalid GPA is rejected (below and above range, missing)', () {
      expect(validate(gpa: 0.5).gpa, isNotNull);
      expect(validate(gpa: 4.5).gpa, isNotNull);
      expect(validate(gpa: null).gpa, 'Enter your GPA.');
      expect(validate(gpa: 1.0).gpa, isNull);
      expect(validate(gpa: 4.0).gpa, isNull);
    });

    test('invalid year level is rejected', () {
      expect(validate(yearLevel: 0).yearLevel, isNotNull);
      expect(validate(yearLevel: 6).yearLevel, isNotNull);
      expect(validate(yearLevel: null).yearLevel, isNotNull);
      expect(validate(yearLevel: 5).yearLevel, isNull);
    });

    test('invalid income is rejected', () {
      expect(
        validate(monthlyFamilyIncome: '').monthlyFamilyIncome,
        isNotNull,
      );
      expect(
        validate(monthlyFamilyIncome: '-100').monthlyFamilyIncome,
        isNotNull,
      );
      expect(
        validate(monthlyFamilyIncome: 'not-a-number').monthlyFamilyIncome,
        isNotNull,
      );
    });

    test('income is optional when the student prefers not to say', () {
      final errors = validate(
        monthlyFamilyIncome: '',
        incomeUndisclosed: true,
      );
      expect(errors.monthlyFamilyIncome, isNull);
      expect(errors.isValid, isTrue);
    });

    test('invalid required fields are rejected', () {
      expect(validate(course: '').course, isNotNull);
      expect(validate(region: null).region, isNotNull);
      expect(validate(region: '   ').region, isNotNull);
      expect(validate(fullName: '  ').fullName, isNotNull);
      expect(validate(nationality: '').nationality, isNotNull);
    });

    test('optional personalization fields do not affect validity', () {
      final profile = _profile(
        school: null,
        province: null,
        cityMunicipality: null,
        birthDate: null,
        gender: null,
      );
      expect(profile.school, isNull);
      expect(profile.province, isNull);
      expect(profile.cityMunicipality, isNull);
    });

    test('formatDate writes yyyy-MM-dd for the date DB column', () {
      expect(formatDate(DateTime(2004, 5, 12)), '2004-05-12');
      expect(formatDate(DateTime(2004, 12, 1)), '2004-12-01');
    });
  });
}
