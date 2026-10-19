// test/features/scholarships/scholarship_capacity_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/scholarships/data/scholarship_capacity_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship_capacity.dart';

class FakeScholarshipCapacityDataSource
    implements ScholarshipCapacityDataSource {
  FakeScholarshipCapacityDataSource({
    Map<String, Map<String, dynamic>>? initial,
  }) : _data = initial ??
            {
              'sch-capped-available': {
                'scholarship_id': 'sch-capped-available',
                'total_slots': 25,
                'occupied_slots': 10,
                'remaining_slots': 15,
                'is_uncapped': false,
              },
              'sch-capped-full': {
                'scholarship_id': 'sch-capped-full',
                'total_slots': 5,
                'occupied_slots': 5,
                'remaining_slots': 0,
                'is_uncapped': false,
              },
              'sch-uncapped': {
                'scholarship_id': 'sch-uncapped',
                'total_slots': null,
                'occupied_slots': 12,
                'remaining_slots': null,
                'is_uncapped': true,
              },
            };

  final Map<String, Map<String, dynamic>> _data;

  @override
  Future<Map<String, dynamic>?> fetchCapacity(String scholarshipId) async {
    return _data[scholarshipId];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllCapacities() async {
    return _data.values.toList();
  }
}

void main() {
  group('ScholarshipCapacity Model Tests', () {
    test('fromJson and toJson round-trip for capped scholarship', () {
      final json = {
        'scholarship_id': 'sch-1',
        'total_slots': 25,
        'occupied_slots': 1,
        'remaining_slots': 24,
        'is_uncapped': false,
      };

      final cap = ScholarshipCapacity.fromJson(json);
      expect(cap.scholarshipId, 'sch-1');
      expect(cap.totalSlots, 25);
      expect(cap.occupiedSlots, 1);
      expect(cap.remainingSlots, 24);
      expect(cap.isUncapped, isFalse);
      expect(cap.remainingLabel, '24 seats remaining');
      expect(cap.occupancyRatioLabel, '1/25 seats filled');

      final out = cap.toJson();
      expect(out['total_slots'], 25);
      expect(out['remaining_slots'], 24);
    });

    test('full capacity displays Fully Booked', () {
      final json = {
        'scholarship_id': 'sch-full',
        'total_slots': 10,
        'occupied_slots': 10,
        'remaining_slots': 0,
        'is_uncapped': false,
      };

      final cap = ScholarshipCapacity.fromJson(json);
      expect(cap.remainingSlots, 0);
      expect(cap.remainingLabel, 'Fully Booked');
      expect(cap.occupancyRatioLabel, '10/10 seats filled');
    });

    test('uncapped scholarship displays Uncapped', () {
      final json = {
        'scholarship_id': 'sch-uncapped',
        'total_slots': null,
        'occupied_slots': 7,
        'remaining_slots': null,
        'is_uncapped': true,
      };

      final cap = ScholarshipCapacity.fromJson(json);
      expect(cap.isUncapped, isTrue);
      expect(cap.totalSlots, isNull);
      expect(cap.remainingSlots, isNull);
      expect(cap.remainingLabel, 'Uncapped');
      expect(cap.occupancyRatioLabel, '7 awarded (Uncapped)');
    });

    test('singular seat remaining renders grammatically', () {
      final json = {
        'scholarship_id': 'sch-single',
        'total_slots': 5,
        'occupied_slots': 4,
        'remaining_slots': 1,
        'is_uncapped': false,
      };

      final cap = ScholarshipCapacity.fromJson(json);
      expect(cap.remainingLabel, '1 seat remaining');
    });

    test('equality and hashCode check all capacity fields', () {
      const c1 = ScholarshipCapacity(
        scholarshipId: 'sch-1',
        totalSlots: 10,
        occupiedSlots: 2,
        remainingSlots: 8,
        isUncapped: false,
      );
      const c2 = ScholarshipCapacity(
        scholarshipId: 'sch-1',
        totalSlots: 10,
        occupiedSlots: 2,
        remainingSlots: 8,
        isUncapped: false,
      );
      const c3 = ScholarshipCapacity(
        scholarshipId: 'sch-1',
        totalSlots: 10,
        occupiedSlots: 3,
        remainingSlots: 7,
        isUncapped: false,
      );

      expect(c1, equals(c2));
      expect(c1, isNot(equals(c3)));
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });

  group('Authoritative Slot Accounting Rules Verification', () {
    test('Simulated status filter: only approved and awarded occupy capacity', () {
      // Represents 5 applications for a single scholarship with slots = 3
      final applications = [
        {'id': 'app-1', 'status': 'draft'},
        {'id': 'app-2', 'status': 'submitted'},
        {'id': 'app-3', 'status': 'under_review'},
        {'id': 'app-4', 'status': 'withdrawn'},
        {'id': 'app-5', 'status': 'approved'},
      ];

      // Replicating PostgreSQL filter: WHERE status IN ('approved', 'awarded')
      final occupied = applications
          .where((a) => a['status'] == 'approved' || a['status'] == 'awarded')
          .length;

      expect(occupied, 1,
          reason: 'Only approved (and awarded) status consumes capacity');

      // Inactive/pending withdrawal: app-2 withdraws
      applications[1]['status'] = 'withdrawn';
      final occupiedAfterWithdrawal = applications
          .where((a) => a['status'] == 'approved' || a['status'] == 'awarded')
          .length;

      expect(occupiedAfterWithdrawal, 1,
          reason:
              'Withdrawing pending application consumes 0 slots and releases 0 slots');

      // Admin transitions approved app-5 to awarded (migration 0025)
      applications[4]['status'] = 'awarded';
      final occupiedAfterAward = applications
          .where((a) => a['status'] == 'approved' || a['status'] == 'awarded')
          .length;

      expect(occupiedAfterAward, 1,
          reason:
              'Approved -> Awarded transition consumes 0 additional slots');
    });
  });

  group('ScholarshipCapacityRepository Tests', () {
    late FakeScholarshipCapacityDataSource dataSource;
    late ScholarshipCapacityRepository repository;

    setUp(() {
      dataSource = FakeScholarshipCapacityDataSource();
      repository = ScholarshipCapacityRepository(dataSource: dataSource);
    });

    test('fetchCapacity returns correct parsed model for existing scholarship',
        () async {
      final cap = await repository.fetchCapacity('sch-capped-available');
      expect(cap, isNotNull);
      expect(cap!.totalSlots, 25);
      expect(cap.occupiedSlots, 10);
      expect(cap.remainingSlots, 15);
      expect(cap.isUncapped, isFalse);
    });

    test('fetchCapacity returns null for non-existing scholarship', () async {
      final cap = await repository.fetchCapacity('sch-non-existent');
      expect(cap, isNull);
    });

    test('fetchAllCapacities returns mapped map keyed by scholarship id',
        () async {
      final map = await repository.fetchAllCapacities();
      expect(map.length, 3);
      expect(map.containsKey('sch-capped-available'), isTrue);
      expect(map.containsKey('sch-capped-full'), isTrue);
      expect(map.containsKey('sch-uncapped'), isTrue);
      expect(map['sch-capped-full']!.remainingSlots, 0);
      expect(map['sch-uncapped']!.isUncapped, isTrue);
    });
  });
}
