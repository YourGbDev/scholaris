import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_scholarship_data_source.dart';

void main() {
  group('ScholarshipRepository', () {
    test('fetchActive returns scholarships from snake_case rows', () async {
      final repo =
          ScholarshipRepository(dataSource: FakeScholarshipDataSource());

      final scholarships = await repo.fetchActive();

      expect(scholarships.length, 2);
      expect(scholarships[0].id, 'sch-dost');
      expect(scholarships[0].title, 'DOST-SEI Undergraduate Scholarship');
      expect(scholarships[0].minGpa, 2.0);
      expect(scholarships[0].maxMonthlyIncome, isNull);
      final dostRow = FakeScholarshipDataSource.defaultRows.firstWhere((r) => r['id'] == 'sch-dost');
      expect(scholarships[0].deadline, DateTime.parse(dostRow['deadline'] as String));
      expect(scholarships[1].id, 'sch-ched');
      expect(scholarships[1].deadline, DateTime(2026, 11, 30));
      // Inactive row is excluded by the repository's data source contract.
      expect(scholarships.map((s) => s.id), isNot(contains('sch-inactive')));
    });

    test('fetchActive preserves deadline ordering of the source', () async {
      final repo = ScholarshipRepository(
        dataSource: FakeScholarshipDataSource([
          {
            'id': 'late',
            'title': 'Late',
            'min_gpa': 1.0,
            'required_year_levels': [1],
            'required_courses': <String>[],
            'location_restriction': null,
            'deadline': '2026-12-31',
            'is_active': true,
          },
          {
            'id': 'soon',
            'title': 'Soon',
            'min_gpa': 1.0,
            'required_year_levels': [1],
            'required_courses': <String>[],
            'location_restriction': null,
            'deadline': '2026-09-01',
            'is_active': true,
          },
        ]),
      );

      final scholarships = await repo.fetchActive();

      expect(scholarships.map((s) => s.id), ['soon', 'late']);
    });

    test('handles deadline boundary and expired scholarship dates independently', () async {
      final repo = ScholarshipRepository(
        dataSource: FakeScholarshipDataSource([
          {
            'id': 'boundary-today',
            'title': 'Boundary Grant',
            'min_gpa': 2.0,
            'required_year_levels': [1],
            'required_courses': <String>[],
            'location_restriction': null,
            'deadline': '2026-10-21',
            'is_active': true,
          },
          {
            'id': 'expired-past',
            'title': 'Expired Grant',
            'min_gpa': 2.0,
            'required_year_levels': [1],
            'required_courses': <String>[],
            'location_restriction': null,
            'deadline': '2026-01-01',
            'is_active': true,
          },
        ]),
      );

      final scholarships = await repo.fetchActive();
      expect(scholarships.length, 2);
      expect(scholarships[0].id, 'expired-past');
      expect(scholarships[0].deadline, DateTime(2026, 1, 1));
      expect(scholarships[1].id, 'boundary-today');
      expect(scholarships[1].deadline, DateTime(2026, 10, 21));
    });
  });
}
