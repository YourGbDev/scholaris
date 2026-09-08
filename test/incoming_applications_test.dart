// Verifies the provider-scoped incoming-applications path: the repository
// resolves only applications to scholarships the current user owns (via
// scholarships.created_by) and the notifier mirrors the session-derived-id guard.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';

import 'helpers/fake_application_data_source.dart';

ApplicationRepository _repo(FakeApplicationDataSource source, String? userId) =>
    ApplicationRepository(
      dataSource: source,
      currentUserId: () => userId,
    );

void main() {
  group('ApplicationRepository.fetchIncomingApplications', () {
    test('returns only applications to the provider-owned scholarships', () async {
      final source = FakeApplicationDataSource();
      // Provider 'prov-a' owns sch-1 and sch-2.
      source.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-a'};
      source.scholarshipIndex['sch-2'] = {'id': 'sch-2', 'created_by': 'prov-a'};
      source.scholarshipIndex['sch-3'] = {'id': 'sch-3', 'created_by': 'prov-b'};

      // Applicant applies to prov-a's sch-1 and a different provider's sch-3.
      await source.insertApplication('applicant-1', {
        'user_id': 'applicant-1',
        'scholarship_id': 'sch-1',
        'status': 'submitted',
      });
      await source.insertApplication('applicant-2', {
        'user_id': 'applicant-2',
        'scholarship_id': 'sch-3',
        'status': 'submitted',
      });

      final repo = _repo(source, 'prov-a');

      final incoming = await repo.fetchIncomingApplications();

      expect(incoming.map((a) => a.scholarshipId), ['sch-1']);
    });

    test('returns empty when the provider owns no scholarships', () async {
      final source = FakeApplicationDataSource();
      source.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-b'};
      await source.insertApplication('applicant-1', {
        'user_id': 'applicant-1',
        'scholarship_id': 'sch-1',
        'status': 'submitted',
      });

      final repo = _repo(source, 'prov-a');

      expect(await repo.fetchIncomingApplications(), isEmpty);
    });

    test('returns empty when signed out', () async {
      final source = FakeApplicationDataSource();
      source.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-a'};
      await source.insertApplication('applicant-1', {
        'user_id': 'applicant-1',
        'scholarship_id': 'sch-1',
        'status': 'submitted',
      });

      final repo = _repo(source, null);

      expect(await repo.fetchIncomingApplications(), isEmpty);
    });
  });

  group('IncomingApplicationsNotifier', () {
    ProviderContainer makeContainer(
      FakeApplicationDataSource source,
      String? userId,
    ) =>
        ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(userId),
            applicationRepositoryProvider.overrideWith(
              (ref) => ApplicationRepository(
                dataSource: source,
                currentUserId: () => userId,
              ),
            ),
          ],
        );

    test('loads only the provider-owned incoming applications', () async {
      final source = FakeApplicationDataSource();
      source.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-a'};
      source.scholarshipIndex['sch-3'] = {'id': 'sch-3', 'created_by': 'prov-b'};
      await source.insertApplication('applicant-1', {
        'user_id': 'applicant-1',
        'scholarship_id': 'sch-1',
        'status': 'submitted',
      });
      await source.insertApplication('applicant-2', {
        'user_id': 'applicant-2',
        'scholarship_id': 'sch-3',
        'status': 'submitted',
      });

      final container = makeContainer(source, 'prov-a');
      addTearDown(container.dispose);

      final incoming = await container.read(incomingApplicationsProvider.future);

      expect(incoming.map((a) => a.scholarshipId), ['sch-1']);
    });

    test('stays empty and guarded when signed out', () async {
      final source = FakeApplicationDataSource();
      source.scholarshipIndex['sch-1'] = {'id': 'sch-1', 'created_by': 'prov-a'};

      final container = makeContainer(source, null);
      addTearDown(container.dispose);

      await container.read(incomingApplicationsProvider.future);

      expect(container.read(incomingApplicationsProvider).valueOrNull, isEmpty);
    });
  });
}
