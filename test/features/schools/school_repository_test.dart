// test/features/schools/school_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/schools/data/school_repository.dart';
import 'package:scholaris/features/schools/models/school.dart';

class FakeSchoolDataSource implements SchoolDataSource {
  FakeSchoolDataSource({List<Map<String, dynamic>>? initial})
      : _schools = initial ??
            [
              {
                'id': 'sch-1',
                'name': 'University of the Philippines Diliman',
                'normalized_name': 'university of the philippines diliman',
                'aliases': ['up diliman', 'upd', 'up'],
                'is_curated': true,
              },
              {
                'id': 'sch-2',
                'name': 'Ateneo de Manila University',
                'normalized_name': 'ateneo de manila university',
                'aliases': ['admu', 'ateneo'],
                'is_curated': true,
              },
              {
                'id': 'sch-3',
                'name': 'De La Salle University',
                'normalized_name': 'de la salle university',
                'aliases': ['dlsu', 'la salle'],
                'is_curated': true,
              },
            ];

  final List<Map<String, dynamic>> _schools;
  final List<String> addedCustomNames = [];

  @override
  Future<List<Map<String, dynamic>>> fetchSchools() async =>
      List<Map<String, dynamic>>.from(_schools);

  @override
  Future<String> addCustomSchool(String name) async {
    final norm = name.trim().toLowerCase();
    addedCustomNames.add(name);
    // Check for existing
    for (final s in _schools) {
      if (s['normalized_name'] == norm ||
          (s['aliases'] as List).contains(norm)) {
        return s['id'] as String;
      }
    }
    final newId = 'sch-${_schools.length + 1}';
    _schools.add({
      'id': newId,
      'name': name.trim(),
      'normalized_name': norm,
      'aliases': <String>[],
      'is_curated': false,
    });
    return newId;
  }
}

void main() {
  group('School Model Tests', () {
    test('fromJson and toJson round-trip correctly', () {
      final json = {
        'id': 'sch-1',
        'name': 'University of the Philippines Diliman',
        'normalized_name': 'university of the philippines diliman',
        'aliases': ['up diliman', 'upd', 'up'],
        'is_curated': true,
      };

      final school = School.fromJson(json);
      expect(school.id, 'sch-1');
      expect(school.name, 'University of the Philippines Diliman');
      expect(school.normalizedName, 'university of the philippines diliman');
      expect(school.aliases, ['up diliman', 'upd', 'up']);
      expect(school.isCurated, isTrue);

      final outJson = school.toJson();
      expect(outJson['id'], 'sch-1');
      expect(outJson['name'], 'University of the Philippines Diliman');
      expect(outJson['is_curated'], isTrue);
    });

    test('equality and hashCode work as expected by id', () {
      const s1 = School(
        id: 'sch-1',
        name: 'UP Diliman',
        normalizedName: 'up diliman',
      );
      const s2 = School(
        id: 'sch-1',
        name: 'UP Diliman Different Label',
        normalizedName: 'up diliman diff',
      );
      const s3 = School(
        id: 'sch-2',
        name: 'Ateneo',
        normalizedName: 'ateneo',
      );

      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
      expect(s1.hashCode, equals(s2.hashCode));
    });
  });

  group('SchoolRepository Tests', () {
    late FakeSchoolDataSource dataSource;
    late SchoolRepository repository;

    setUp(() {
      dataSource = FakeSchoolDataSource();
      repository = SchoolRepository(dataSource: dataSource);
    });

    test('fetchSchools returns all schools parsed', () async {
      final schools = await repository.fetchSchools();
      expect(schools.length, 3);
      expect(schools.first.name, 'University of the Philippines Diliman');
    });

    test('searchSchools matches by name case-insensitively', () async {
      final results = await repository.searchSchools('ateneo');
      expect(results.length, 1);
      expect(results.first.id, 'sch-2');
    });

    test('searchSchools matches by alias', () async {
      final results = await repository.searchSchools('dlsu');
      expect(results.length, 1);
      expect(results.first.name, 'De La Salle University');

      final upResults = await repository.searchSchools('upd');
      expect(upResults.length, 1);
      expect(upResults.first.id, 'sch-1');
    });

    test('searchSchools with empty query returns all schools', () async {
      final results = await repository.searchSchools('   ');
      expect(results.length, 3);
    });

    test('searchSchools with non-matching query returns empty list', () async {
      final results = await repository.searchSchools('Harvard');
      expect(results, isEmpty);
    });

    test('addSchool deduplicates existing school alias or normalized name', () async {
      final existingId = await repository.addSchool('DLSU');
      expect(existingId, 'sch-3');
      expect(dataSource.addedCustomNames, ['DLSU']);
    });

    test('addSchool adds new uncurated school when not found', () async {
      final newId = await repository.addSchool('Silliman University');
      expect(newId, 'sch-4');

      final all = await repository.fetchSchools();
      expect(all.length, 4);
      final added = all.firstWhere((s) => s.id == 'sch-4');
      expect(added.name, 'Silliman University');
      expect(added.isCurated, isFalse);
    });

    test('addSchool throws ArgumentError on empty or whitespace name', () async {
      expect(() => repository.addSchool(''), throwsArgumentError);
      expect(() => repository.addSchool('   '), throwsArgumentError);
    });
  });
}
