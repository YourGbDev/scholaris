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
      expect(scholarships[0].name, 'DOST-SEI Undergraduate Scholarship');
      expect(scholarships[0].minGpa, 2.0);
      expect(scholarships[0].maxIncomeBracket, 'any');
      expect(scholarships[0].deadline, DateTime(2026, 10, 15));
      // Inactive row is excluded by the repository's data source contract.
      expect(scholarships.map((s) => s.id), isNot(contains('sch-inactive')));
    });

    test('fetchActive preserves deadline ordering of the source', () async {
      final repo = ScholarshipRepository(
        dataSource: FakeScholarshipDataSource([
          {'id': 'late', 'name': 'Late', 'min_gpa': 1.0, 'year_levels': [1], 'eligible_courses': <String>[], 'regions_eligible': <String>[], 'deadline': '2026-12-31', 'amount': 1000, 'tags': <String>[], 'is_active': true},
          {'id': 'soon', 'name': 'Soon', 'min_gpa': 1.0, 'year_levels': [1], 'eligible_courses': <String>[], 'regions_eligible': <String>[], 'deadline': '2026-09-01', 'amount': 1000, 'tags': <String>[], 'is_active': true},
        ]),
      );

      final scholarships = await repo.fetchActive();

      expect(scholarships.map((s) => s.id), ['soon', 'late']);
    });
  });
}
