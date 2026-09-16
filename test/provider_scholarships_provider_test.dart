import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/provider/providers/provider_scholarships_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_scholarship_data_source.dart';

void main() {
  group('ProviderScholarshipsNotifier', () {
    late FakeScholarshipDataSource dataSource;
    late ProviderContainer container;

    setUp(() {
      dataSource = FakeScholarshipDataSource([
        {
          'id': 'sch-1',
          'title': 'Active STEM Grant',
          'provider': 'Acme Corp',
          'min_gpa': 2.0,
          'deadline': '2026-10-15',
          'is_active': true,
          'created_by': 'prov-1',
        },
        {
          'id': 'sch-2',
          'title': 'Closed Arts Grant',
          'provider': 'Acme Corp',
          'min_gpa': 2.5,
          'deadline': '2026-09-01',
          'is_active': false,
          'created_by': 'prov-1',
        },
        {
          'id': 'sch-3',
          'title': 'Other Provider Scholarship',
          'provider': 'Other Corp',
          'min_gpa': 3.0,
          'deadline': '2026-11-01',
          'is_active': true,
          'created_by': 'prov-2',
        },
      ]);

      container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('prov-1'),
          scholarshipRepositoryProvider.overrideWith(
            (ref) => ScholarshipRepository(dataSource: dataSource),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('build loads scholarships scoped to currentUserId', () async {
      final list = await container.read(providerScholarshipsProvider.future);
      expect(list.length, 2);
      expect(list.map((s) => s.id), containsAll(['sch-1', 'sch-2']));
      expect(list.any((s) => s.id == 'sch-3'), isFalse);
    });

    test('createScholarship adds item and updates state', () async {
      final notifier = container.read(providerScholarshipsProvider.notifier);

      final created = await notifier.createScholarship({
        'title': 'New Emerging Leaders Fund',
        'provider': 'Acme Corp',
        'min_gpa': 2.2,
        'deadline': '2026-12-31',
      });

      expect(created.title, 'New Emerging Leaders Fund');
      expect(created.createdBy, 'prov-1');

      final updatedList = await container.read(providerScholarshipsProvider.future);
      expect(updatedList.length, 3);
      expect(updatedList.any((s) => s.title == 'New Emerging Leaders Fund'), isTrue);
    });

    test('updateScholarship modifies item and updates state', () async {
      final notifier = container.read(providerScholarshipsProvider.notifier);

      final updated = await notifier.updateScholarship('sch-1', {
        'title': 'Renamed STEM Grant',
        'min_gpa': 2.1,
      });

      expect(updated.title, 'Renamed STEM Grant');
      expect(updated.minGpa, 2.1);

      final list = await container.read(providerScholarshipsProvider.future);
      final item = list.firstWhere((s) => s.id == 'sch-1');
      expect(item.title, 'Renamed STEM Grant');
    });

    test('toggleActive toggles scholarship active state', () async {
      final notifier = container.read(providerScholarshipsProvider.notifier);

      await notifier.toggleActive('sch-1', false);

      final list = await container.read(providerScholarshipsProvider.future);
      final item = list.firstWhere((s) => s.id == 'sch-1');
      expect(item.isActive, isFalse);
    });

    test('deleteScholarship removes scholarship from state', () async {
      final notifier = container.read(providerScholarshipsProvider.notifier);

      await notifier.deleteScholarship('sch-2');

      final list = await container.read(providerScholarshipsProvider.future);
      expect(list.length, 1);
      expect(list.any((s) => s.id == 'sch-2'), isFalse);
    });

    test('filteredProviderScholarshipsProvider filters by status and query', () async {
      await container.read(providerScholarshipsProvider.future);

      // Initially all
      final all = container.read(filteredProviderScholarshipsProvider).value!;
      expect(all.length, 2);

      // Filter active
      container.read(providerScholarshipStatusFilterProvider.notifier).state = 'active';
      final active = container.read(filteredProviderScholarshipsProvider).value!;
      expect(active.length, 1);
      expect(active.first.id, 'sch-1');

      // Filter closed
      container.read(providerScholarshipStatusFilterProvider.notifier).state = 'closed';
      final closed = container.read(filteredProviderScholarshipsProvider).value!;
      expect(closed.length, 1);
      expect(closed.first.id, 'sch-2');

      // Reset status filter, search query
      container.read(providerScholarshipStatusFilterProvider.notifier).state = 'all';
      container.read(providerScholarshipSearchQueryProvider.notifier).state = 'stem';
      final searched = container.read(filteredProviderScholarshipsProvider).value!;
      expect(searched.length, 1);
      expect(searched.first.id, 'sch-1');
    });
  });
}
