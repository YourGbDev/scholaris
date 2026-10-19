// test/features/provider/organization_activity_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/data/organization_activity_repository.dart';
import 'package:scholaris/features/provider/models/organization_activity_log.dart';

class FakeOrganizationActivityDataSource
    implements OrganizationActivityDataSource {
  FakeOrganizationActivityDataSource({List<Map<String, dynamic>>? initial})
      : _logs = initial ??
            [
              {
                'id': 'log-1',
                'actor_id': 'user-admin',
                'actor_name': 'DOST Admin',
                'action': 'assign_reviewer',
                'target_type': 'scholarship',
                'target_id': 'sch-1',
                'details': {
                  'reviewer_id': 'rev-1',
                  'scholarship_id': 'sch-1',
                },
                'created_at': '2026-10-19T10:00:00Z',
              },
              {
                'id': 'log-2',
                'actor_id': 'user-admin',
                'actor_name': 'DOST Admin',
                'action': 'approve',
                'target_type': 'application',
                'target_id': 'app-1',
                'details': {
                  'application_id': 'app-1',
                  'status': 'approved',
                },
                'created_at': '2026-10-19T09:30:00Z',
              },
            ];

  final List<Map<String, dynamic>> _logs;
  String? lastOrgId;
  String? lastActionFilter;
  int? lastLimit;
  int? lastOffset;

  @override
  Future<List<Map<String, dynamic>>> fetchActivityLogs(
    String organizationId, {
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  }) async {
    lastOrgId = organizationId;
    lastActionFilter = actionFilter;
    lastLimit = limit;
    lastOffset = offset;

    var filtered = _logs;
    if (actionFilter != null) {
      filtered =
          filtered.where((log) => log['action'] == actionFilter).toList();
    }
    return filtered;
  }
}

void main() {
  group('OrganizationActivityLog Model Tests', () {
    test('fromJson and toJson round-trip correctly', () {
      final json = {
        'id': 'log-1',
        'actor_id': 'user-1',
        'actor_name': 'Dr. Renato Solidum',
        'action': 'endorse',
        'target_type': 'application',
        'target_id': 'app-123',
        'details': {'score': 8.5},
        'created_at': '2026-10-19T10:00:00.000Z',
      };

      final log = OrganizationActivityLog.fromJson(json);
      expect(log.id, 'log-1');
      expect(log.actorId, 'user-1');
      expect(log.actorName, 'Dr. Renato Solidum');
      expect(log.action, 'endorse');
      expect(log.targetType, 'application');
      expect(log.targetId, 'app-123');
      expect(log.details['score'], 8.5);

      final out = log.toJson();
      expect(out['id'], 'log-1');
      expect(out['action'], 'endorse');
    });

    test('equality checks by id', () {
      final log1 = OrganizationActivityLog(
        id: 'log-1',
        actorName: 'User A',
        action: 'action_a',
        targetType: 'test',
        createdAt: DateTime.now(),
      );
      final log2 = OrganizationActivityLog(
        id: 'log-1',
        actorName: 'User B',
        action: 'action_b',
        targetType: 'test',
        createdAt: DateTime.now(),
      );
      final log3 = OrganizationActivityLog(
        id: 'log-2',
        actorName: 'User A',
        action: 'action_a',
        targetType: 'test',
        createdAt: DateTime.now(),
      );

      expect(log1, equals(log2));
      expect(log1, isNot(equals(log3)));
      expect(log1.hashCode, equals(log2.hashCode));
    });
  });

  group('OrganizationActivityRepository Tests', () {
    late FakeOrganizationActivityDataSource dataSource;
    late OrganizationActivityRepository repository;

    setUp(() {
      dataSource = FakeOrganizationActivityDataSource();
      repository = OrganizationActivityRepository(dataSource: dataSource);
    });

    test('fetchActivityLogs returns all logs without filter', () async {
      final logs = await repository.fetchActivityLogs('org-dost');
      expect(logs.length, 2);
      expect(dataSource.lastOrgId, 'org-dost');
      expect(dataSource.lastActionFilter, isNull);
      expect(logs.first.action, 'assign_reviewer');
    });

    test('fetchActivityLogs passes action filter correctly', () async {
      final logs = await repository.fetchActivityLogs(
        'org-dost',
        actionFilter: 'approve',
      );
      expect(logs.length, 1);
      expect(dataSource.lastActionFilter, 'approve');
      expect(logs.first.action, 'approve');
    });

    test('fetchActivityLogs returns empty list when none match', () async {
      final logs = await repository.fetchActivityLogs(
        'org-dost',
        actionFilter: 'non_existent_action',
      );
      expect(logs, isEmpty);
    });
  });
}
