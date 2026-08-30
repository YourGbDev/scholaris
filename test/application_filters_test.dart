// Unit tests for the pure application tracking pipeline: filter → counts →
// summary state. These exercise the service layer directly with no Riverpod or
// widget dependencies, so every rule is independently verifiable.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';

Application _app({
  String id = 'a1',
  ApplicationStatus status = ApplicationStatus.submitted,
  DateTime? updatedAt,
}) =>
    Application(
      id: id,
      userId: 'u1',
      scholarshipId: 'sch-1',
      status: status,
      updatedAt: updatedAt,
    );

List<String> _ids(List<Application> items) => items.map((a) => a.id).toList();

void main() {
  group('matchesStatus', () {
    test('null status matches every application', () {
      expect(
        ApplicationFilters.matchesStatus(_app(status: ApplicationStatus.draft), null),
        isTrue,
      );
      expect(
        ApplicationFilters.matchesStatus(
            _app(status: ApplicationStatus.approved), null),
        isTrue,
      );
    });

    test('specific status matches only that status', () {
      expect(
        ApplicationFilters.matchesStatus(
          _app(status: ApplicationStatus.submitted),
          ApplicationStatus.submitted,
        ),
        isTrue,
      );
      expect(
        ApplicationFilters.matchesStatus(
          _app(status: ApplicationStatus.approved),
          ApplicationStatus.submitted,
        ),
        isFalse,
      );
    });
  });

  group('filterByStatus', () {
    final items = [
      _app(id: 'd', status: ApplicationStatus.draft),
      _app(id: 's', status: ApplicationStatus.submitted),
      _app(id: 'u', status: ApplicationStatus.underReview),
      _app(id: 'a', status: ApplicationStatus.approved),
      _app(id: 'r', status: ApplicationStatus.rejected),
    ];

    test('null returns all items in order', () {
      expect(_ids(ApplicationFilters.filterByStatus(items, null)),
          ['d', 's', 'u', 'a', 'r']);
    });

    test('draft returns only draft', () {
      expect(
        _ids(ApplicationFilters.filterByStatus(items, ApplicationStatus.draft)),
        ['d'],
      );
    });

    test('approved returns only approved', () {
      expect(
        _ids(
            ApplicationFilters.filterByStatus(items, ApplicationStatus.approved)),
        ['a'],
      );
    });

    test('unmatched status returns empty list', () {
      expect(
        ApplicationFilters.filterByStatus(
            [items[0]], ApplicationStatus.approved),
        isEmpty,
      );
    });
  });

  group('statusCounts', () {
    test('empty list returns zero for every status', () {
      final counts = ApplicationFilters.statusCounts([]);
      for (final status in ApplicationStatus.values) {
        expect(counts[status], 0);
      }
    });

    test('correct counts for mixed statuses', () {
      final items = [
        _app(status: ApplicationStatus.draft),
        _app(status: ApplicationStatus.submitted),
        _app(status: ApplicationStatus.submitted),
        _app(status: ApplicationStatus.approved),
        _app(status: ApplicationStatus.rejected),
      ];
      final counts = ApplicationFilters.statusCounts(items);
      expect(counts[ApplicationStatus.draft], 1);
      expect(counts[ApplicationStatus.submitted], 2);
      expect(counts[ApplicationStatus.underReview], 0);
      expect(counts[ApplicationStatus.approved], 1);
      expect(counts[ApplicationStatus.rejected], 1);
    });
  });

  group('countByStatus', () {
    final items = [
      _app(status: ApplicationStatus.draft),
      _app(status: ApplicationStatus.submitted),
      _app(status: ApplicationStatus.approved),
    ];

    test('null returns total', () {
      expect(ApplicationFilters.countByStatus(items, null), 3);
    });

    test('specific status returns its count', () {
      expect(ApplicationFilters.countByStatus(items, ApplicationStatus.draft), 1);
      expect(ApplicationFilters.countByStatus(items, ApplicationStatus.approved), 1);
      expect(
          ApplicationFilters.countByStatus(items, ApplicationStatus.underReview), 0);
    });
  });

  group('pendingCount', () {
    test('draft, submitted and under review are pending', () {
      final items = [
        _app(status: ApplicationStatus.draft),
        _app(status: ApplicationStatus.submitted),
        _app(status: ApplicationStatus.underReview),
        _app(status: ApplicationStatus.approved),
        _app(status: ApplicationStatus.rejected),
      ];
      expect(ApplicationFilters.pendingCount(items), 3);
    });

    test('no pending returns zero', () {
      expect(
        ApplicationFilters.pendingCount([
          _app(status: ApplicationStatus.approved),
          _app(status: ApplicationStatus.rejected),
        ]),
        0,
      );
    });
  });

  group('approvedCount', () {
    test('counts only approved', () {
      final items = [
        _app(status: ApplicationStatus.approved),
        _app(status: ApplicationStatus.approved),
        _app(status: ApplicationStatus.submitted),
      ];
      expect(ApplicationFilters.approvedCount(items), 2);
    });
  });

  group('applyAll', () {
    test('null status returns all items unchanged (order preserved)', () {
      final items = [
        _app(id: 'a', status: ApplicationStatus.draft),
        _app(id: 'b', status: ApplicationStatus.submitted),
      ];
      expect(_ids(ApplicationFilters.applyAll(items, null)), ['a', 'b']);
    });

    test('narrows to a single status', () {
      final items = [
        _app(id: 'a', status: ApplicationStatus.draft),
        _app(id: 'b', status: ApplicationStatus.submitted),
        _app(id: 'c', status: ApplicationStatus.approved),
      ];
      expect(
        _ids(ApplicationFilters.applyAll(items, ApplicationStatus.approved)),
        ['c'],
      );
    });
  });

  group('ApplicationFilterState', () {
    test('default status is null (All)', () {
      const state = ApplicationFilterState();
      expect(state.status, isNull);
      expect(state.isActive, isFalse);
    });

    test('non-null status is active', () {
      const state = ApplicationFilterState(status: ApplicationStatus.approved);
      expect(state.status, ApplicationStatus.approved);
      expect(state.isActive, isTrue);
    });

    test('copyWith sets status', () {
      const state = ApplicationFilterState();
      final updated = state.copyWith(status: ApplicationStatus.submitted);
      expect(updated.status, ApplicationStatus.submitted);
    });

    test('copyWith does not change unset fields', () {
      const state = ApplicationFilterState(status: ApplicationStatus.draft);
      final unchanged = state.copyWith();
      expect(unchanged.status, ApplicationStatus.draft);
    });

    test('reset restores default', () {
      const state = ApplicationFilterState(status: ApplicationStatus.approved);
      final reset = state.reset();
      expect(reset.status, isNull);
      expect(reset.isActive, isFalse);
    });
  });
}