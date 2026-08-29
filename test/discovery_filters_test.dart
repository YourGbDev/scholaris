// Unit tests for the pure discovery pipeline: search → filters → sort.
// These exercise the service layer directly with no Riverpod or widget
// dependencies, so every rule is independently verifiable.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/services/discovery_filters.dart';

DateTime _inDays(int days) => DateTime(2026, 1, 1).add(Duration(days: days));

Scholarship _s({
  String id = 's1',
  String name = 'DOST-SEI Scholarship',
  String? provider = 'Department of Science and Technology',
  String? description = 'Supports students in priority STEM programs.',
  List<String> tags = const ['stem', 'stipend'],
  List<String> eligibleCourses = const ['BS Computer Science'],
  List<String> regionsEligible = const ['NCR', 'Region III'],
  String maxIncomeBracket = 'any',
  double amount = 50000,
  DateTime? deadline,
  String? coverageType = 'full',
}) =>
    Scholarship(
      id: id,
      name: name,
      provider: provider,
      description: description,
      minGpa: 2.0,
      yearLevels: const [1, 2, 3, 4, 5],
      eligibleCourses: eligibleCourses,
      citizenshipRequired: 'any',
      regionsEligible: regionsEligible,
      maxIncomeBracket: maxIncomeBracket,
      isPwdPriority: false,
      isWorkingStudentPriority: false,
      slotsAvailable: null,
      deadline: deadline ?? _inDays(30),
      amount: amount,
      coverageType: coverageType,
      tags: tags,
      isActive: true,
    );

List<String> _ids(List<Scholarship> items) => items.map((s) => s.id).toList();

void main() {
  group('search', () {
    test('matches the name field', () {
      final items = [
        _s(id: 'dost', name: 'DOST-SEI Scholarship'),
        _s(id: 'ched', name: 'CHED Merit Scholarship'),
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

    test('matches the tags field', () {
      final items = [
        _s(id: 'dost', tags: const ['stem', 'stipend']),
        _s(id: 'ched', tags: const ['merit']),
      ];
      expect(_ids(DiscoveryFilters.applySearch(items, 'stipend')), ['dost']);
    });

    test('matches the eligible courses field', () {
      final items = [
        _s(id: 'nursing', eligibleCourses: const ['BS Nursing']),
        _s(id: 'cs', eligibleCourses: const ['BS Computer Science']),
      ];
      expect(
        _ids(DiscoveryFilters.applySearch(items, 'computer science')),
        ['cs'],
      );
    });

    test('matches the regions eligible field', () {
      final items = [
        _s(id: 'ncr', regionsEligible: const ['NCR']),
        _s(id: 'visayas', regionsEligible: const ['Region VII']),
      ];
      expect(_ids(DiscoveryFilters.applySearch(items, 'ncr')), ['ncr']);
    });

    test('is case-insensitive', () {
      final items = [_s(id: 'dost', name: 'DOST-SEI Scholarship')];
      expect(_ids(DiscoveryFilters.applySearch(items, 'dost')), ['dost']);
      expect(_ids(DiscoveryFilters.applySearch(items, 'DoSt')), ['dost']);
    });

    test('performs partial substring matching', () {
      final items = [_s(id: 'dost', name: 'DOST-SEI Scholarship')];
      expect(_ids(DiscoveryFilters.applySearch(items, 'sei')), ['dost']);
    });

    test('requires every token to match (AND)', () {
      final items = [
        _s(id: 'dost', name: 'DOST-SEI Scholarship', tags: const ['stipend']),
        _s(id: 'ched', name: 'CHED Merit Scholarship', tags: const ['merit']),
      ];
      expect(_ids(DiscoveryFilters.applySearch(items, 'dost stipend')),
          ['dost']);
      expect(_ids(DiscoveryFilters.applySearch(items, 'dost ched')), isEmpty);
    });

    test('collapses whitespace and trims the query', () {
      final items = [_s(id: 'dost', name: 'DOST-SEI Scholarship')];
      expect(_ids(DiscoveryFilters.applySearch(items, '  dost   sei  ')),
          ['dost']);
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
      _s(id: 'low', maxIncomeBracket: 'low'),
      _s(id: 'mid', maxIncomeBracket: 'mid'),
      _s(id: 'high', maxIncomeBracket: 'high'),
      _s(id: 'any', maxIncomeBracket: 'any'),
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
      _s(id: 'ncr', regionsEligible: const ['NCR']),
      _s(id: 'visayas', regionsEligible: const ['Region VII']),
      _s(id: 'anywhere', regionsEligible: const []),
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

    test('empty regionsEligible means any region', () {
      final state = const DiscoveryFilterState(regions: {'BARMM'});
      expect(_ids(DiscoveryFilters.applyFilters(items, state)), ['anywhere']);
    });
  });

  group('coverage filter', () {
    final items = [
      _s(id: 'full', coverageType: 'full'),
      _s(id: 'partial', coverageType: 'partial'),
      _s(id: 'stipend', coverageType: 'stipend'),
      _s(id: 'none', coverageType: null),
    ];

    test('single coverage selection', () {
      final state = const DiscoveryFilterState(coverageTypes: {'full'});
      expect(_ids(DiscoveryFilters.applyFilters(items, state)), ['full']);
    });

    test('multi coverage selection uses OR', () {
      final state = const DiscoveryFilterState(
        coverageTypes: {'full', 'stipend'},
      );
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['full', 'stipend'],
      );
    });

    test('null coverage never matches a selected coverage', () {
      final state = const DiscoveryFilterState(coverageTypes: {'stipend'});
      expect(_ids(DiscoveryFilters.applyFilters(items, state)), ['stipend']);
    });
  });

  group('tags filter', () {
    final items = [
      _s(id: 'stem', tags: const ['stem', 'stipend']),
      _s(id: 'merit', tags: const ['merit']),
      _s(id: 'other', tags: const ['vocational']),
    ];

    test('multi-selection uses OR', () {
      final state = const DiscoveryFilterState(tags: {'stem', 'merit'});
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['stem', 'merit'],
      );
    });

    test('available tags are derived from the catalog', () {
      final tags = DiscoveryFilters.availableTags(items);
      expect(tags, {'stem', 'stipend', 'merit', 'vocational'});
    });
  });

  group('amount filter', () {
    final items = [
      _s(id: 'small', amount: 20000),
      _s(id: 'mid', amount: 50000),
      _s(id: 'large', amount: 90000),
    ];

    test('minimum is inclusive', () {
      final state = const DiscoveryFilterState(minAmount: 50000);
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['mid', 'large'],
      );
    });

    test('maximum is inclusive', () {
      final state = const DiscoveryFilterState(maxAmount: 50000);
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['small', 'mid'],
      );
    });

    test('min/max boundaries are inclusive', () {
      final state = const DiscoveryFilterState(
        minAmount: 50000,
        maxAmount: 50000,
      );
      expect(_ids(DiscoveryFilters.applyFilters(items, state)), ['mid']);
    });

    test('invalid amount input parses to null (unset)', () {
      expect(DiscoveryFilters.parseAmount('abc'), isNull);
      expect(DiscoveryFilters.parseAmount('   '), isNull);
      expect(DiscoveryFilters.parseAmount('-5'), isNull);
      expect(DiscoveryFilters.parseAmount('50000'), 50000);
    });

    test('min greater than max is treated as unset', () {
      final state = const DiscoveryFilterState(
        minAmount: 70000,
        maxAmount: 50000,
      );
      expect(
        _ids(DiscoveryFilters.applyFilters(items, state)),
        ['small', 'mid', 'large'],
      );
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
        maxIncomeBracket: 'low',
        coverageType: 'full',
        regionsEligible: const ['NCR'],
        amount: 60000,
        tags: const ['stem'],
      ),
      _s(
        id: 'no',
        maxIncomeBracket: 'high',
        coverageType: 'stipend',
        regionsEligible: const ['BARMM'],
        amount: 10000,
        tags: const ['community'],
      ),
    ];

    test('filters combine with AND semantics', () {
      final state = const DiscoveryFilterState(
        incomeBracket: 'low',
        coverageTypes: {'full'},
        regions: {'NCR'},
        minAmount: 50000,
        tags: {'stem'},
      );
      expect(_ids(DiscoveryFilters.applyFilters(items, state)), ['fit']);
    });
  });

  group('sorting', () {
    final items = [
      _s(id: 'lateBig', deadline: _inDays(20), amount: 90000),
      _s(id: 'soonSmall', deadline: _inDays(5), amount: 10000),
      _s(id: 'soonBig', deadline: _inDays(5), amount: 80000),
    ];

    test('default sorts by soonest deadline then highest amount', () {
      final sorted = DiscoveryFilters.sort(items, DiscoverySort.defaultSort);
      expect(_ids(sorted), ['soonBig', 'soonSmall', 'lateBig']);
    });

    test('highest amount sorts by amount then deadline', () {
      final sorted = DiscoveryFilters.sort(items, DiscoverySort.highestAmount);
      expect(_ids(sorted), ['lateBig', 'soonBig', 'soonSmall']);
    });
  });

  group('state mutation', () {
    test('reset restores defaults', () {
      const state = DiscoveryFilterState(
        query: 'dost',
        incomeBracket: 'low',
        regions: {'NCR'},
        coverageTypes: {'full'},
        tags: {'stem'},
        minAmount: 100,
        maxAmount: 200,
        closingSoonOnly: true,
        sort: DiscoverySort.highestAmount,
      );
      final reset = state.reset();
      expect(reset.query, '');
      expect(reset.incomeBracket, isNull);
      expect(reset.regions, isEmpty);
      expect(reset.coverageTypes, isEmpty);
      expect(reset.tags, isEmpty);
      expect(reset.minAmount, isNull);
      expect(reset.maxAmount, isNull);
      expect(reset.closingSoonOnly, isFalse);
      expect(reset.sort, DiscoverySort.defaultSort);
    });

    test('individual filters can be cleared via copyWith', () {
      final state = const DiscoveryFilterState(
        query: 'dost',
        incomeBracket: 'low',
        regions: {'NCR'},
        coverageTypes: {'full'},
      );
      final cleared = state.copyWith(
        query: '',
        incomeBracket: null,
        regions: const <String>{},
      );
      expect(cleared.query, '');
      expect(cleared.incomeBracket, isNull);
      expect(cleared.regions, isEmpty);
      expect(cleared.coverageTypes, {'full'});
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
