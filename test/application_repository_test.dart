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

    group('withdraw', () {
    test('withdraws a pending (submitted) application and preserves the record',
        () async {
      final created = await repo.apply(scholarshipId: 'sch-dost');

      await repo.withdraw(created.id);

      final applications = await repo.fetchMyApplications();
      expect(applications.single.id, created.id);
      expect(applications.single.status, ApplicationStatus.withdrawn);
      // The record is preserved, not deleted.
      expect(await repo.hasApplied('sch-dost'), isTrue);
    });

    test('withdraws draft and under-review applications too', () async {
      for (final status in [
        ApplicationStatus.draft,
        ApplicationStatus.submitted,
        ApplicationStatus.underReview,
      ]) {
        final row = await dataSource.insertApplication('user-a', {
          'user_id': 'user-a',
          'scholarship_id': 'sch-$status',
          'status': status.dbValue,
        });
        await repo.withdraw(row['id'] as String);
        final app = (await repo.fetchMyApplications())
            .firstWhere((a) => a.id == row['id']);
        expect(app.status, ApplicationStatus.withdrawn,
            reason: 'withdraw should allow $status');
      }
    });

    test('rejects withdrawing an approved application', () async {
      final row = await dataSource.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-approved',
        'status': 'approved',
      });

      expect(
        () => repo.withdraw(row['id'] as String),
        throwsA(isA<ApplicationWithdrawalException>()),
      );

      final app = (await repo.fetchMyApplications())
          .firstWhere((a) => a.id == row['id']);
      expect(app.status, ApplicationStatus.approved);
    });

    test('rejects withdrawing a rejected application', () async {
      final row = await dataSource.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-rejected',
        'status': 'rejected',
      });

      expect(
        () => repo.withdraw(row['id'] as String),
        throwsA(isA<ApplicationWithdrawalException>()),
      );

      final app = (await repo.fetchMyApplications())
          .firstWhere((a) => a.id == row['id']);
      expect(app.status, ApplicationStatus.rejected);
    });

    test('rejects a duplicate withdrawal (already withdrawn is terminal)',
        () async {
      final created = await repo.apply(scholarshipId: 'sch-dost');
      await repo.withdraw(created.id);

      expect(
        () => repo.withdraw(created.id),
        throwsA(isA<ApplicationWithdrawalException>()),
      );

      final app = (await repo.fetchMyApplications()).single;
      expect(app.status, ApplicationStatus.withdrawn);
    });

    test('rejects withdrawing an application that does not exist', () async {
      expect(
        () => repo.withdraw('does-not-exist'),
        throwsA(isA<ApplicationWithdrawalException>()),
      );
    });

    test('cannot withdraw another user application', () async {
      final other = await dataSource.insertApplication('user-b', {
        'user_id': 'user-b',
        'scholarship_id': 'sch-other',
        'status': 'submitted',
      });

      expect(
        () => repo.withdraw(other['id'] as String),
        throwsA(isA<ApplicationWithdrawalException>()),
      );

      final userB = await dataSource.fetchApplications('user-b');
      expect(userB.single['status'], 'submitted');
    });

    test('withdraw while unauthenticated throws', () async {
      final unauthenticated = ApplicationRepository(
        dataSource: dataSource,
        currentUserId: () => null,
      );

      expect(
        () => unauthenticated.withdraw('any'),
        throwsA(isA<ApplicationNotAuthenticatedException>()),
      );
    });
    });

    group('updateNotes', () {
    test('updates notes and leaves status untouched', () async {
      final created = await repo.apply(scholarshipId: 'sch-dost', notes: 'old');

      await repo.updateNotes(created.id, 'new notes');

      final app = (await repo.fetchMyApplications()).single;
      expect(app.notes, 'new notes');
      expect(app.status, ApplicationStatus.submitted);
    });

    test('clearing notes sets them to empty', () async {
      final created = await repo.apply(scholarshipId: 'sch-dost', notes: 'old');

      await repo.updateNotes(created.id, '');

      final app = (await repo.fetchMyApplications()).single;
      expect(app.notes, '');
    });

    test('notes update is owner-scoped', () async {
      final other = await dataSource.insertApplication('user-b', {
        'user_id': 'user-b',
        'scholarship_id': 'sch-other',
        'status': 'submitted',
        'notes': 'b notes',
      });

      await repo.updateNotes(other['id'] as String, 'hacked');

      final userB = await dataSource.fetchApplications('user-b');
      expect(userB.single['notes'], 'b notes');
    });

    test('updates notes on an application with null notes', () async {
      final row = await dataSource.insertApplication('user-a', {
        'user_id': 'user-a',
        'scholarship_id': 'sch-null-notes',
        'status': 'submitted',
      });

      await repo.updateNotes(row['id'] as String, 'first note');

      final app = (await repo.fetchMyApplications())
          .firstWhere((a) => a.id == row['id']);
      expect(app.notes, 'first note');
    });

    test('notes update while unauthenticated throws', () async {
      final unauthenticated = ApplicationRepository(
        dataSource: dataSource,
        currentUserId: () => null,
      );

      expect(
        () => unauthenticated.updateNotes('any', 'notes'),
        throwsA(isA<ApplicationNotAuthenticatedException>()),
      );
    });

    group('Provider persistence & transaction cycle', () {
      test('providerUpdateNotes updates notes regardless of applicant user_id', () async {
        final row = await dataSource.insertApplication('user-student', {
          'user_id': 'user-student',
          'scholarship_id': 'sch-provider-owned',
          'status': 'submitted',
          'notes': 'original notes',
        });

        final providerRepo = ApplicationRepository(
          dataSource: dataSource,
          currentUserId: () => 'provider-1',
        );

        await providerRepo.providerUpdateNotes(row['id'] as String, 'Deliberation notes');

        final studentApps = await dataSource.fetchApplications('user-student');
        expect(studentApps.single['notes'], 'Deliberation notes');
      });

      test('saveEvaluation records rubric criteria scores and JSON fallback in notes', () async {
        final row = await dataSource.insertApplication('user-student', {
          'user_id': 'user-student',
          'scholarship_id': 'sch-provider-owned',
          'status': 'submitted',
        });

        final providerRepo = ApplicationRepository(
          dataSource: dataSource,
          currentUserId: () => 'provider-1',
        );

        await providerRepo.saveEvaluation(
          applicationId: row['id'] as String,
          scoreAcademic: 9.5,
          scoreFinancial: 9.0,
          scoreLeadership: 8.8,
          scoreVision: 9.2,
          compositeScore: 9.18,
          notes: 'Top tier candidate',
          decision: 'approved',
        );

        expect(dataSource.evaluations, hasLength(1));
        final eval = dataSource.evaluations.single;
        expect(eval['application_id'], row['id']);
        expect(eval['reviewer_id'], 'provider-1');
        expect(eval['score_academic'], 9.5);
        expect(eval['score_financial'], 9.0);
        expect(eval['score_leadership'], 8.8);
        expect(eval['score_vision'], 9.2);
        expect(eval['composite_score'], 9.18);
        expect(eval['deliberation_notes'], 'Top tier candidate');
        expect(eval['decision'], 'approved');

        // Check JSON fallback in notes
        final studentApps = await dataSource.fetchApplications('user-student');
        expect(studentApps.single['notes'], contains('"composite":9.18'));
        expect(studentApps.single['notes'], contains('"decision":"approved"'));
      });

      test('recordStatusTransition logs from_status and to_status in history', () async {
        final row = await dataSource.insertApplication('user-student', {
          'user_id': 'user-student',
          'scholarship_id': 'sch-provider-owned',
          'status': 'submitted',
        });

        final providerRepo = ApplicationRepository(
          dataSource: dataSource,
          currentUserId: () => 'provider-1',
        );

        await providerRepo.recordStatusTransition(
          applicationId: row['id'] as String,
          fromStatus: 'submitted',
          toStatus: 'approved',
          remarks: 'Approved by committee',
        );

        expect(dataSource.statusHistory, hasLength(1));
        final hist = dataSource.statusHistory.single;
        expect(hist['application_id'], row['id']);
        expect(hist['changed_by'], 'provider-1');
        expect(hist['from_status'], 'submitted');
        expect(hist['to_status'], 'approved');
        expect(hist['remarks'], 'Approved by committee');
      });

      test('createNotification persists notification for student user_id', () async {
        final providerRepo = ApplicationRepository(
          dataSource: dataSource,
          currentUserId: () => 'provider-1',
        );

        await providerRepo.createNotification(
          userId: 'user-student',
          title: 'Application Approved! 🎉',
          message: 'Congratulations! Your grant has been approved.',
          targetId: 'app-1',
        );

        expect(dataSource.notifications, hasLength(1));
        final notif = dataSource.notifications.single;
        expect(notif['user_id'], 'user-student');
        expect(notif['title'], 'Application Approved! 🎉');
        expect(notif['message'], 'Congratulations! Your grant has been approved.');
        expect(notif['target_id'], 'app-1');
        expect(notif['is_read'], isFalse);
      });
    });
  });
  });
}
