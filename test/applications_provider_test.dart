// Verifies the applications provider: it loads only the signed-in user's
// applications, keeps state in sync through apply/updateStatus, and stays
// empty / guarded when signed out. (Logout/login isolation is covered in
// auth_boundary_test.dart.)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';

import 'helpers/fake_application_data_source.dart';

ProviderContainer _container(
  FakeApplicationDataSource source,
  String? userId,
) {
  return ProviderContainer(
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
}

void main() {
  group('ApplicationsNotifier', () {
    test('loads only the signed-in user applications', () async {
      final source = FakeApplicationDataSource();
      await source.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-dost',
        'status': 'submitted',
      });
      await source.insertApplication('user-b', {
        'user_id': 'user-b',
        'scholarship_id': 'sch-other',
        'status': 'draft',
      });

      final container = _container(source, 'user-a');
      addTearDown(container.dispose);

      final applications = await container.read(applicationsProvider.future);

      expect(applications.map((a) => a.scholarshipId), ['sch-dost']);
      expect(container.read(applicationsProvider.notifier).hasApplied('sch-dost'), isTrue);
      expect(container.read(applicationsProvider.notifier).hasApplied('sch-other'), isFalse);
    });

    test('apply appends the created application to the state', () async {
      final source = FakeApplicationDataSource();
      final container = _container(source, 'user-a');
      addTearDown(container.dispose);

      final notifier = container.read(applicationsProvider.notifier);
      await container.read(applicationsProvider.future);

      final created = await notifier.apply('sch-dost', notes: 'Statement');

      expect(created.scholarshipId, 'sch-dost');
      final current = container.read(applicationsProvider).valueOrNull!;
      expect(current, hasLength(1));
      expect(current.single.id, created.id);
      expect(notifier.hasApplied('sch-dost'), isTrue);
      // Persisted too.
      expect(await source.fetchApplications('user-a'), hasLength(1));
    });

    test('apply rejects a duplicate through the provider', () async {
      final source = FakeApplicationDataSource();
      final container = _container(source, 'user-a');
      addTearDown(container.dispose);

      final notifier = container.read(applicationsProvider.notifier);
      await container.read(applicationsProvider.future);

      await notifier.apply('sch-dost');

      expect(
        () => notifier.apply('sch-dost'),
        throwsA(isA<ApplicationDuplicateException>()),
      );
      expect(container.read(applicationsProvider).valueOrNull, hasLength(1));
    });

    test('updateStatus keeps the provider state in sync', () async {
      final source = FakeApplicationDataSource();
      final container = _container(source, 'user-a');
      addTearDown(container.dispose);

      final notifier = container.read(applicationsProvider.notifier);
      await container.read(applicationsProvider.future);

      final created = await notifier.apply('sch-dost');
      await notifier.updateStatus(created.id, ApplicationStatus.approved);

      expect(
        container.read(applicationsProvider).valueOrNull!.single.status,
        ApplicationStatus.approved,
      );
    });

    test('unauthenticated provider stays empty and apply throws', () async {
      final source = FakeApplicationDataSource();
      final container = _container(source, null);
      addTearDown(container.dispose);

      final notifier = container.read(applicationsProvider.notifier);
      await container.read(applicationsProvider.future);

      expect(container.read(applicationsProvider).valueOrNull, isEmpty);
      expect(notifier.hasApplied('sch-dost'), isFalse);
      expect(
        () => notifier.apply('sch-dost'),
        throwsA(isA<ApplicationNotAuthenticatedException>()),
      );
    });
  });
}
