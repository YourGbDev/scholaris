// Unit tests for the pure discovery pipeline: search → filters → sort.
// These exercise the service layer directly with no Riverpod or widget
// dependencies, so every rule is independently verifiable.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/services/discovery_filters.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';

DateTime _inDays(int days) => DateTime(2026, 1, 1).add(Duration(days: days));

Scholarship _s({
  String id = 's1',
  String title = 'DOST-SEI Scholarship',
  String? provider = 'Department of Science and Technology',
  String? description = 'Supports students in priority STEM programs.',
  List<String>? requiredCourses = const ['BS Computer Science'],
  String? locationRestriction,
  double? maxMonthlyIncome,
  DateTime? deadline,
  int? slots,
  double amount = 0,
}) =>
    Scholarship(
      id: id,
      title: title,
      provider: provider,
      description: description,
      minGpa: 2.0,
      requiredYearLevels: const [1, 2, 3, 4, 5],
      requiredCourses: requiredCourses,
      locationRestriction: locationRestriction,
      maxMonthlyIncome: maxMonthlyIncome,
      forPwd: false,
      forIndigenous: false,
      slots: slots,
      amount: amount,
      deadline: deadline ?? _inDays(30),
      isActive: true,
    );

List<String> _ids(List<Scholarship> items) => items.map((s) => s.id).toList();

void main() {
  test('match reasons respect the Philippine GPA scale', () {
    final scholarship = Scholarship(id: 'gpa', title: 'Grant', minGpa: 1.75, deadline: _inDays(30), isActive: true);
    const student = StudentProfile(id: 'student', fullName: 'Student', gpa: 1.5);
    expect(matchReasonsFor(student, scholarship), contains('Your GPA qualifies'));
  });
  group('search', () {
    test('matches the title field', () {
      final items = [
        _s(id: 'dost', title: 'DOST-SEI Scholarship'),
        _s(id: 'ched', title: 'CHED Merit Scholarship'),
      ];
      expect(_ids(DiscoveryFilters.applySearch(items, 'DOST')), ['dost']);
    });

    test('matches the provider field', () {
      final items = [
        _s(id: 'dost', provider: 'Department of Science and Technology'),
        _s(id: 'ched', provider: 'Commission on Higher Education'),
      ];
      expect(
        _ids(DiscoveryFilters.applySearch(items, 'Science and Technology')),
        ['dost'],
      );
    });

    test('matches the description field', () {
      final items = [
        _s(id: 'dost', description: 'Supports students in priority STEM.'),
        _s(id: 'ched', description: 'A national merit scholarship.'),
      ];
      expect(_ids(DiscoveryFilters.applySearch(items, 'merit')), ['ched']);
    });

    test('matches the required courses field', () {
      final items = [
        _s(id: 'nursing', requiredCourses: const ['BS Nursing']),
        _s(id: 'cs', requiredCourses: const ['BS Computer Science']),
      ];
      expect(
        _ids(DiscoveryFilters.applySearch(items, 'computer science')),
        ['cs'],
      );
    });

    test('matches the location restriction field', () {
      final items = [
        _s(id: 'ncr', locationRestriction: 'NCR'),
        _s(id: 'visayas', locationRestriction: 'Region VII'),
      ];
      expect(_ids(DiscoveryFilters.applySearch(items, 'ncr')), ['ncr']);
    });

    test('is case-insensitive', () {
      final items = [_s(id: 'dost', title: 'DOST-SEI Scholarship')];
      expect(_ids(DiscoveryFilters.applySearch(items, 'dost')), ['dost']);
      expect(_ids(DiscoveryFilters.applySearch(items, 'DoSt')), ['dost']);
    });

    test('performs partial substring matching', () {
      final items = [_s(id: 'dost', title: 'DOST-SEI Scholarship')];
      expect(_ids(DiscoveryFilters.applySearch(items, 'sei')), ['dost']);
    });

    test('requires every token to match (AND)', () {
      final items = [
        _s(id: 'dost', title: 'DOST-SEI Scholarship', requiredCourses: const ['STEM']),
        _s(id: 'ched', title: 'CHED Merit Scholarship', requiredCourses: const ['Merit']),
      ];
      expect(_ids(DiscoveryFilters.applySearch(items, 'dost stem')), ['dost']);
      expect(_ids(DiscoveryFilters.applySearch(items, 'dost ched')), isEmpty);
    });

    test('collapses whitespace and trims the query', () {
      final items = [_s(id: 'dost', title: 'DOST-SEI Scholarship')];
      expect(_ids(DiscoveryFilters.applySearch(items, '  dost   sei  ')), ['dost']);
    });

    test('empty query is a no-op', () {
      final items = [_s(id: 'a'), _s(id: 'b')];
      expect(_ids(DiscoveryFilters.applySearch(items, '')), ['a', 'b']);
      expect(_ids(DiscoveryFilters.applySearch(items, '   ')), ['a', 'b']);
    });

    test('returns no results for an unmatched query', () {
      final items = [_s(id: 'a'), _s(id: 'b')];
      expect(DiscoveryFilters.applySearch(items, 'nonexistent'), isEmpty);
    });
  });

  group('income filter', () {
    final items = [
      _s(id: 'low', maxMonthlyIncome: 15000),
      _s(id: 'mid', maxMonthlyIncome: 25000),
      _s(id: 'high', maxMonthlyIncome: 60000),
      _s(id: 'any', maxMonthlyIncome: null),
    ];

    test('low selection allows low/mid/high/any', () {
      final state = const DiscoveryFilterState(incomeBracket: 'low');
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['low', 'mid', 'high', 'any'],
      );
    });

    test('mid selection allows mid/high/any', () {
      final state = const DiscoveryFilterState(incomeBracket: 'mid');
      expect(_ids(DiscoveryFilters.applyFilters(items, state)),
          ['mid', 'high', 'any']);
    });

    test('high selection allows high/any', () {
      final state = const DiscoveryFilterState(incomeBracket: 'high');
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['high', 'any'],
      );
    });

    test('any (null) selection leaves everything eligible', () {
      final state = const DiscoveryFilterState();
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['low', 'mid', 'high', 'any'],
      );
    });
  });

  group('region filter', () {
    final items = [
      _s(id: 'ncr', locationRestriction: 'NCR'),
      _s(id: 'visayas', locationRestriction: 'Region VII'),
      _s(id: 'anywhere', locationRestriction: null),
    ];

    test('selected regions use OR semantics', () {
      final state = const DiscoveryFilterState(
        regions: {'NCR', 'Region VII'},
      );
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['ncr', 'visayas', 'anywhere'],
      );
    });

    test('null location restriction means any region', () {
      final state = const DiscoveryFilterState(regions: {'BARMM'});
      expect(_ids(DiscoveryFilters.applyFilters(items, state)), ['anywhere']);
    });
  });

  group('deadline filter', () {
    test('closing soon boundary: exactly 14 days included, 15 excluded', () {
      final now = DateTime(2026, 1, 1);
      final items = [
        _s(id: 'day14', deadline: DateTime(2026, 1, 15)),
        _s(id: 'day15', deadline: DateTime(2026, 1, 16)),
      ];
      const state = DiscoveryFilterState(closingSoonOnly: true);
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state, now: now)),
        ['day14'],
      );
    });

    test('disabled closing-soon leaves deadlines untouched', () {
      final now = DateTime(2026, 1, 1);
      final items = [
        _s(id: 'far', deadline: DateTime(2026, 6, 1)),
      ];
      const state = DiscoveryFilterState();
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state, now: now)),
        ['far'],
      );
    });
  });

  group('combinations', () {
    final items = [
      _s(
        id: 'fit',
        locationRestriction: 'NCR',
        maxMonthlyIncome: 15000,
      ),
      _s(
        id: 'no',
        locationRestriction: 'BARMM',
        maxMonthlyIncome: 60000,
      ),
    ];

    test('filters combine with AND semantics', () {
      final state = const DiscoveryFilterState(
        incomeBracket: 'low',
        regions: {'NCR'},
      );
      expect(_ids(DiscoveryFilters.applyFilters(items, state)), ['fit']);
    });
  });

  group('sorting', () {
    final items = [
      _s(id: 'lateBig', deadline: _inDays(20), amount: 100000),
      _s(id: 'soonSmall', deadline: _inDays(5), amount: 20000),
      _s(id: 'soonBig', deadline: _inDays(5), amount: 100000),
    ];

    test('default sorts by soonest deadline', () {
      final sorted = DiscoveryFilters.sort(items, DiscoverySort.defaultSort);
      expect(_ids(sorted), ['soonSmall', 'soonBig', 'lateBig']);
    });

    test('highest amount sorts by amount, then deadline', () {
      final sorted = DiscoveryFilters.sort(items, DiscoverySort.highestAmount);
      expect(_ids(sorted), ['soonBig', 'lateBig', 'soonSmall']);
    });
  });

  test('high-fit filtering uses the supplied displayed-score decision', () {
    final items = [_s(id: 'high'), _s(id: 'low')];
    const state = DiscoveryFilterState(highFitOnly: true);
    expect(_ids(DiscoveryFilters.applyAll(items, state, isHighFit: (s) => s.id == 'high')), ['high']);
    expect(DiscoveryFilters.applyAll(items, state), isEmpty);
  });

  group('state mutation', () {
    test('reset restores defaults', () {
      const state = DiscoveryFilterState(
        query: 'dost',
        incomeBracket: 'low',
        regions: {'NCR'},
        closingSoonOnly: true,
        sort: DiscoverySort.highestAmount,
      );
      final reset = state.reset();
      expect(reset.query, '');
      expect(reset.incomeBracket, isNull);
      expect(reset.regions, isEmpty);
      expect(reset.closingSoonOnly, isFalse);
      expect(reset.sort, DiscoverySort.defaultSort);
    });

    test('individual filters can be cleared via copyWith', () {
      final state = const DiscoveryFilterState(
        query: 'dost',
        incomeBracket: 'low',
        regions: {'NCR'},
      );
      final cleared = state.copyWith(
        query: '',
        incomeBracket: null,
        regions: const <String>{},
      );
      expect(cleared.query, '');
      expect(cleared.incomeBracket, isNull);
      expect(cleared.regions, isEmpty);
    });

    test('isActive reflects any active control', () {
      expect(const DiscoveryFilterState().isActive, isFalse);
      expect(const DiscoveryFilterState(query: 'x').isActive, isTrue);
      expect(
        const DiscoveryFilterState(closingSoonOnly: true).isActive,
        isTrue,
      );
      expect(
        const DiscoveryFilterState(sort: DiscoverySort.highestAmount).isActive,
        isFalse,
      );
    });
  });
}
