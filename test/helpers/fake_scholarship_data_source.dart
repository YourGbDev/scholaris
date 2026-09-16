import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

/// In-memory [ScholarshipDataSource] for tests. Returns a fixed list of rows,
/// which can be overridden per test.
class FakeScholarshipDataSource implements ScholarshipDataSource {
  FakeScholarshipDataSource([List<Map<String, dynamic>>? rows])
      : rows = rows ?? defaultRows;

  List<Map<String, dynamic>> rows;

  @override
  Future<List<Map<String, dynamic>>> fetchScholarships() async =>
      List<Map<String, dynamic>>.of(rows.where((row) => row['is_active'] == true));

  @override
  Future<List<Map<String, dynamic>>> fetchScholarshipsByProvider(
    String providerId,
  ) async =>
      List<Map<String, dynamic>>.of(
        rows.where((row) => row['created_by'] == providerId),
      );

  @override
  Future<Map<String, dynamic>> createScholarship(
    Map<String, dynamic> data,
  ) async {
    final newRow = Map<String, dynamic>.of(data);
    newRow['id'] ??= 'sch-${rows.length + 1}';
    newRow['created_at'] ??= DateTime.now().toIso8601String();
    newRow['is_active'] ??= true;
    rows.add(newRow);
    return newRow;
  }

  @override
  Future<Map<String, dynamic>> updateScholarship(
    String id,
    Map<String, dynamic> data,
  ) async {
    final index = rows.indexWhere((row) => row['id'] == id);
    if (index == -1) {
      throw Exception('Scholarship not found: $id');
    }
    final updated = Map<String, dynamic>.of(rows[index])..addAll(data);
    rows[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteScholarship(String id) async {
    rows.removeWhere((row) => row['id'] == id);
  }

  /// A small set of realistic rows matching the production schema.
  static final List<Map<String, dynamic>> defaultRows = [
    {
      'id': 'sch-dost',
      'title': 'DOST-SEI Undergraduate Scholarship',
      'provider': 'Department of Science and Technology',
      'description': 'Supports students in priority STEM programs.',
      'min_gpa': 2.0,
      'required_year_levels': [1, 2, 3, 4, 5],
      'required_courses': <String>[],
      'location_restriction': null,
      'max_monthly_income': null,
      'for_pwd': false,
      'for_indigenous': false,
      'slots': 8000,
      'deadline': '2026-10-15',
      'application_url': 'https://ched.gov.ph/scholarships',
      'is_active': true,
    },
    {
      'id': 'sch-ched',
      'title': 'CHED Merit Scholarship (MSRS)',
      'provider': 'Commission on Higher Education',
      'description': 'A national merit scholarship for strong students.',
      'min_gpa': 3.0,
      'required_year_levels': [1, 2, 3, 4, 5],
      'required_courses': <String>[],
      'location_restriction': null,
      'max_monthly_income': 15000,
      'for_pwd': false,
      'for_indigenous': false,
      'slots': 2000,
      'deadline': '2026-11-30',
      'application_url': 'https://ched.gov.ph/scholarships',
      'is_active': true,
    },
    {
      'id': 'sch-inactive',
      'title': 'Old Grant',
      'provider': 'Unknown',
      'description': 'Should not appear.',
      'min_gpa': 1.0,
      'required_year_levels': [1, 2, 3, 4, 5],
      'required_courses': <String>[],
      'location_restriction': null,
      'max_monthly_income': null,
      'for_pwd': false,
      'for_indigenous': false,
      'slots': null,
      'deadline': '2027-01-01',
      'application_url': null,
      'is_active': false,
    },
  ];
}
