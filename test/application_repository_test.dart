import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'helpers/fake_application_data_source.dart';

void main() {
  group('ApplicationRepository', () {
    late FakeApplicationDataSource dataSource;
    late ApplicationRepository repo;

    setUp(() {
      dataSource = FakeApplicationDataSource();
      repo = ApplicationRepository(
        dataSource: dataSource,
        currentUserId: () => 'user-a',
      );
    });

    test('fetchMyApplications returns the signed-in user applications only',
        () async {
      // A row for another user must never be visible to user-a.
      await dataSource.insertApplication('user-b', {
        'user_id': 'user-b',
        'scholarship_id': 'sch-other',
        'status': 'submitted',
      });

      expect(await repo.fetchMyApplications(), isEmpty);

      await repo.apply(scholarshipId: 'sch-dost');
      await repo.apply(scholarshipId: 'sch-ched');

      final applications = await repo.fetchMyApplications();
      expect(applications.map((a) => a.scholarshipId), containsAll([
        'sch-dost',
        'sch-ched',
      ]));
      // user-b untouched.
      final userBRows = await dataSource.fetchApplications('user-b');
      expect(userBRows.single['scholarship_id'], 'sch-other');
    });

    test('apply creates a submitted application with applied_at and notes',
        () async {
      final created =
          await repo.apply(scholarshipId: 'sch-dost', notes: 'Essay attached.');

      expect(created.userId, 'user-a');
      expect(created.scholarshipId, 'sch-dost');
      expect(created.status, ApplicationStatus.submitted);
      expect(created.notes, 'Essay attached.');
      expect(created.appliedAt, isNotNull);
      expect(created.id, isNotEmpty);

      expect(await repo.hasApplied('sch-dost'), isTrue);
    });

    test('apply rejects a duplicate application for the same scholarship',
        () async {
      await repo.apply(scholarshipId: 'sch-dost');

      expect(
        () => repo.apply(scholarshipId: 'sch-dost'),
        throwsA(isA<ApplicationDuplicateException>()),
      );
      expect((await repo.fetchMyApplications()).length, 1);
    });

    test('different users may apply to the same scholarship independently',
        () async {
      await repo.apply(scholarshipId: 'sch-dost');

      final otherRepo = ApplicationRepository(
        dataSource: dataSource,
        currentUserId: () => 'user-b',
      );
      final created = await otherRepo.apply(scholarshipId: 'sch-dost');

      expect(created.userId, 'user-b');
      expect(await repo.hasApplied('sch-dost'), isTrue);
      expect(await otherRepo.hasApplied('sch-dost'), isTrue);
      expect(await dataSource.fetchApplications('user-b'), hasLength(1));
    });

    test('unauthenticated fetch returns empty and apply throws', () async {
      final unauthenticated = ApplicationRepository(
        dataSource: dataSource,
        currentUserId: () => null,
      );

      expect(await unauthenticated.fetchMyApplications(), isEmpty);
      expect(await unauthenticated.hasApplied('sch-dost'), isFalse);
      expect(
        () => unauthenticated.apply(scholarshipId: 'sch-dost'),
        throwsA(isA<ApplicationNotAuthenticatedException>()),
      );
    });

    test('updateStatus advances the status of an own application', () async {
      final created = await repo.apply(scholarshipId: 'sch-dost');
      await repo.updateStatus(created.id, ApplicationStatus.approved);

      final applications = await repo.fetchMyApplications();
      expect(applications.single.status, ApplicationStatus.approved);
    });

    test('updateStatus cannot modify another user application', () async {
      final other = await dataSource.insertApplication('user-b', {
        'user_id': 'user-b',
        'scholarship_id': 'sch-other',
        'status': 'draft',
      });

      await repo.updateStatus(
        other['id'] as String,
        ApplicationStatus.approved,
      );

      final userB = await dataSource.fetchApplications('user-b');
      expect(userB.single['status'], 'draft');
    });

    test('snake_case columns are written to the data source', () async {
      await repo.apply(scholarshipId: 'sch-dost', notes: 'n');

      final raw = (await dataSource.fetchApplications('user-a')).single;
      expect(raw['user_id'], 'user-a');
      expect(raw['scholarship_id'], 'sch-dost');
      expect(raw['status'], 'submitted');
      expect(raw['notes'], 'n');
      expect(raw.containsKey('applied_at'), isTrue);
      // No camelCase keys appear in the DB row.
      expect(raw.containsKey('userId'), isFalse);
      expect(raw.containsKey('scholarshipId'), isFalse);
    });
  });
}
