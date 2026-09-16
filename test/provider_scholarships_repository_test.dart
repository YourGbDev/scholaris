import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_scholarship_data_source.dart';

void main() {
  group('ScholarshipRepository - Provider CRUD operations', () {
    late FakeScholarshipDataSource dataSource;
    late ScholarshipRepository repository;

    setUp(() {
      dataSource = FakeScholarshipDataSource([
        {
          'id': 'sch-1',
          'title': 'Provider A Scholarship 1',
          'provider': 'Provider A Org',
          'min_gpa': 2.0,
          'deadline': '2026-10-15',
          'is_active': true,
          'created_by': 'prov-1',
        },
        {
          'id': 'sch-2',
          'title': 'Provider A Scholarship 2',
          'provider': 'Provider A Org',
          'min_gpa': 2.5,
          'deadline': '2026-11-20',
          'is_active': false,
          'created_by': 'prov-1',
        },
        {
          'id': 'sch-3',
          'title': 'Provider B Scholarship',
          'provider': 'Provider B Org',
          'min_gpa': 1.75,
          'deadline': '2026-12-01',
          'is_active': true,
          'created_by': 'prov-2',
        },
      ]);
      repository = ScholarshipRepository(dataSource: dataSource);
    });

    test('fetchByProvider returns only scholarships matching providerId', () async {
      final prov1Scholarships = await repository.fetchByProvider('prov-1');
      expect(prov1Scholarships.length, 2);
      expect(prov1Scholarships.map((s) => s.id), containsAll(['sch-1', 'sch-2']));
      expect(prov1Scholarships.any((s) => s.id == 'sch-3'), isFalse);

      final prov2Scholarships = await repository.fetchByProvider('prov-2');
      expect(prov2Scholarships.length, 1);
      expect(prov2Scholarships.first.id, 'sch-3');
    });

    test('createScholarship persists and returns newly created scholarship', () async {
      final newScholarship = await repository.createScholarship({
        'title': 'Ayala Tech Fellowship',
        'provider': 'Ayala Foundation',
        'description': 'Empowering tech leaders.',
        'min_gpa': 3.0,
        'deadline': '2026-12-15',
        'slots': 50,
        'is_active': true,
        'created_by': 'prov-1',
      });

      expect(newScholarship.title, 'Ayala Tech Fellowship');
      expect(newScholarship.minGpa, 3.0);
      expect(newScholarship.createdBy, 'prov-1');
      expect(newScholarship.slots, 50);

      final providerList = await repository.fetchByProvider('prov-1');
      expect(providerList.length, 3);
      expect(providerList.any((s) => s.title == 'Ayala Tech Fellowship'), isTrue);
    });

    test('updateScholarship updates fields correctly', () async {
      final updated = await repository.updateScholarship('sch-1', {
        'title': 'Updated DOST STEM Grant',
        'min_gpa': 2.25,
        'slots': 150,
      });

      expect(updated.id, 'sch-1');
      expect(updated.title, 'Updated DOST STEM Grant');
      expect(updated.minGpa, 2.25);
      expect(updated.slots, 150);
      // Unchanged fields preserved
      expect(updated.provider, 'Provider A Org');
      expect(updated.createdBy, 'prov-1');
    });

    test('toggleActive toggles is_active status', () async {
      final before = (await repository.fetchByProvider('prov-1')).firstWhere((s) => s.id == 'sch-1');
      expect(before.isActive, isTrue);

      await repository.toggleActive('sch-1', false);

      final after = (await repository.fetchByProvider('prov-1')).firstWhere((s) => s.id == 'sch-1');
      expect(after.isActive, isFalse);

      await repository.toggleActive('sch-1', true);
      final restored = (await repository.fetchByProvider('prov-1')).firstWhere((s) => s.id == 'sch-1');
      expect(restored.isActive, isTrue);
    });

    test('deleteScholarship removes the scholarship', () async {
      final before = await repository.fetchByProvider('prov-1');
      expect(before.length, 2);

      await repository.deleteScholarship('sch-2');

      final after = await repository.fetchByProvider('prov-1');
      expect(after.length, 1);
      expect(after.any((s) => s.id == 'sch-2'), isFalse);
    });
  });
}
