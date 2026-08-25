import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

/// In-memory [ScholarshipDataSource] for tests. Returns a fixed list of rows,
/// which can be overridden per test.
class FakeScholarshipDataSource implements ScholarshipDataSource {
  FakeScholarshipDataSource([List<Map<String, dynamic>>? rows])
      : rows = rows ?? defaultRows;

  List<Map<String, dynamic>> rows;

  @override
  Future<List<Map<String, dynamic>>> fetchScholarships() async =>
      List<Map<String, dynamic>>.of(rows);

  /// A small set of realistic rows matching the 0002 contract.
  static final List<Map<String, dynamic>> defaultRows = [
    {
      'id': 'sch-dost',
      'name': 'DOST-SEI Undergraduate Scholarship',
      'provider': 'Department of Science and Technology',
      'description': 'Supports students in priority STEM programs.',
      'min_gpa': 2.0,
      'year_levels': [1, 2, 3, 4, 5],
      'eligible_courses': <String>[],
      'citizenship_required': 'Filipino',
      'regions_eligible': <String>[],
      'max_income_bracket': 'any',
      'is_pwd_priority': false,
      'is_working_student_priority': false,
      'slots_available': 8000,
      'deadline': '2026-10-15',
      'amount': 70000,
      'coverage_type': 'full',
      'tags': const ['stem', 'stipend'],
      'is_active': true,
    },
    {
      'id': 'sch-ched',
      'name': 'CHED Merit Scholarship (MSRS)',
      'provider': 'Commission on Higher Education',
      'description': 'A national merit scholarship for strong students.',
      'min_gpa': 3.0,
      'year_levels': [1, 2, 3, 4, 5],
      'eligible_courses': <String>[],
      'citizenship_required': 'Filipino',
      'regions_eligible': <String>[],
      'max_income_bracket': 'low',
      'is_pwd_priority': false,
      'is_working_student_priority': false,
      'slots_available': 2000,
      'deadline': '2026-11-30',
      'amount': 50000,
      'coverage_type': 'full',
      'tags': const ['merit'],
      'is_active': true,
    },
    {
      'id': 'sch-inactive',
      'name': 'Old Grant',
      'provider': 'Unknown',
      'description': 'Should not appear.',
      'min_gpa': 1.0,
      'year_levels': [1, 2, 3, 4, 5],
      'eligible_courses': <String>[],
      'citizenship_required': 'any',
      'regions_eligible': <String>[],
      'max_income_bracket': 'any',
      'is_pwd_priority': false,
      'is_working_student_priority': false,
      'slots_available': null,
      'deadline': '2027-01-01',
      'amount': 10000,
      'coverage_type': 'partial',
      'tags': const [],
      'is_active': false,
    },
  ];
}
