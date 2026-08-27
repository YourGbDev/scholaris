// Tests for the Application model: snake_case DB row ↔ camelCase domain object,
// the default status, and the status enum's DB-value mapping.

import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/models/application.dart';

Application _application() => Application(
      id: 'app-1',
      userId: 'user-a',
      scholarshipId: 'sch-dost',
      status: ApplicationStatus.submitted,
      notes: 'Statement of purpose attached.',
      appliedAt: DateTime.utc(2026, 8, 1, 4, 30),
      updatedAt: DateTime.utc(2026, 8, 1, 4, 30),
    );

void main() {
  group('Application JSON mapping (snake_case DB ↔ camelCase model)', () {
    test('fromJson parses a snake_case Supabase row', () {
      final application = Application.fromJson({
        'id': 'app-1',
        'user_id': 'user-a',
        'scholarship_id': 'sch-dost',
        'status': 'under_review',
        'notes': 'Statement of purpose attached.',
        'applied_at': '2026-08-01T04:30:00.000Z',
        'updated_at': '2026-08-01T04:30:00.000Z',
      });

      expect(application.id, 'app-1');
      expect(application.userId, 'user-a');
      expect(application.scholarshipId, 'sch-dost');
      expect(application.status, ApplicationStatus.underReview);
      expect(application.notes, 'Statement of purpose attached.');
      expect(application.appliedAt, DateTime.utc(2026, 8, 1, 4, 30));
      expect(application.updatedAt, DateTime.utc(2026, 8, 1, 4, 30));
    });

    test('fromJson applies defaults for omitted optional columns', () {
      final application = Application.fromJson({
        'id': 'app-2',
        'user_id': 'user-a',
        'scholarship_id': 'sch-ched',
      });

      expect(application.status, ApplicationStatus.draft);
      expect(application.notes, isNull);
      expect(application.appliedAt, isNull);
      expect(application.updatedAt, isNull);
    });

    test('toJson round-trips a full application', () {
      final decoded = Application.fromJson(_application().toJson());

      expect(decoded, _application());
    });

    test('toJson writes snake_case keys', () {
      final json = _application().toJson();

      expect(json.containsKey('user_id'), isTrue);
      expect(json.containsKey('scholarship_id'), isTrue);
      expect(json.containsKey('applied_at'), isTrue);
      expect(json.containsKey('updated_at'), isTrue);
      expect(json['status'], 'submitted');
      // No camelCase keys leak into the payload.
      expect(json.containsKey('userId'), isFalse);
      expect(json.containsKey('scholarshipId'), isFalse);
      expect(json.containsKey('appliedAt'), isFalse);
    });

    test('toJson serializes timestamps in UTC', () {
      // A local-time DateTime must be normalized to UTC for the timestamptz
      // column, whatever timezone the test machine is in.
      final local = DateTime(2026, 8, 1, 4, 30);
      final json = _application().copyWith(appliedAt: local).toJson();

      expect(json['applied_at'], local.toUtc().toIso8601String());
      expect(json['applied_at'], endsWith('Z'));
    });
  });

  group('ApplicationStatus', () {
    test('dbValue matches the applications.status CHECK constraint', () {
      expect(ApplicationStatus.draft.dbValue, 'draft');
      expect(ApplicationStatus.submitted.dbValue, 'submitted');
      expect(ApplicationStatus.underReview.dbValue, 'under_review');
      expect(ApplicationStatus.approved.dbValue, 'approved');
      expect(ApplicationStatus.rejected.dbValue, 'rejected');
    });

    test('fromDbValue maps each stored value back to the enum', () {
      expect(ApplicationStatus.fromDbValue('draft'), ApplicationStatus.draft);
      expect(ApplicationStatus.fromDbValue('submitted'),
          ApplicationStatus.submitted);
      expect(ApplicationStatus.fromDbValue('under_review'),
          ApplicationStatus.underReview);
      expect(ApplicationStatus.fromDbValue('approved'), ApplicationStatus.approved);
      expect(ApplicationStatus.fromDbValue('rejected'), ApplicationStatus.rejected);
    });

    test('fromDbValue rejects unknown values', () {
      expect(
        () => ApplicationStatus.fromDbValue('mystery'),
        throwsArgumentError,
      );
    });
  });
}
