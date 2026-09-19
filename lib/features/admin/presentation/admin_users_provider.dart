import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_audit_logs_provider.dart';

final adminUsersProvider = FutureProvider<List<StudentProfile>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.fetchAllProfiles();
});

final adminUserSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminUserRoleFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all'); // 'all', 'student', 'provider', 'admin'

Future<void> logAdminAuditEvent({
  required String action,
  required String targetType,
  String? targetId,
  Map<String, dynamic>? details,
}) async {
  try {
    final client = Supabase.instance.client;
    await client.rpc('log_audit_event', params: {
      'p_action': action,
      'p_target_type': targetType,
      'p_target_id': targetId,
      'p_details': details ?? {},
    });
  } catch (_) {
    // Non-fatal if offline or unauthenticated
  }
  // Local fallback / in-memory ledger
  await LoginLockoutService.instance.logAuditEvent(
    action: action,
    targetType: targetType,
    targetId: targetId,
    details: details,
    actorRole: 'admin',
  );
}

class AdminUsersController {
  AdminUsersController(this.ref);
  final Ref ref;

  Future<void> createUser({
    required String fullName,
    required String email,
    required String role,
    required String status,
    String region = 'NCR',
    String? school,
    String? course,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    final newId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
    final data = {
      'id': newId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'status': status,
      'region': region,
      'school': school ?? '',
      'course': course ?? '',
      'gpa': 0.0,
      'year_level': 1,
      'setup_complete': true,
    };
    await repo.adminUpsertProfile(newId, data);
    await logAdminAuditEvent(
      action: 'user_created',
      targetType: 'user',
      targetId: newId,
      details: {
        'full_name': fullName,
        'email': email,
        'role': role,
        'status': status,
      },
    );
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> updateRoleAndStatus({
    required StudentProfile user,
    required String newRole,
    required String newStatus,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    final data = {
      ...user.toDbRow(),
      'id': user.id,
      'email': user.email,
      'role': newRole,
      'status': newStatus,
    };
    await repo.adminUpsertProfile(user.id, data);
    await logAdminAuditEvent(
      action: 'role_and_status_updated',
      targetType: 'user',
      targetId: user.id,
      details: {
        'old_role': user.role,
        'new_role': newRole,
        'old_status': user.status,
        'new_status': newStatus,
        'email': user.email,
        'full_name': user.fullName,
      },
    );
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> deactivateUser(StudentProfile user) async {
    final repo = ref.read(profileRepositoryProvider);
    final data = {
      ...user.toDbRow(),
      'id': user.id,
      'email': user.email,
      'role': user.role,
      'status': 'deactivated',
    };
    await repo.adminUpsertProfile(user.id, data);
    await logAdminAuditEvent(
      action: 'user_deactivated',
      targetType: 'user',
      targetId: user.id,
      details: {
        'previous_status': user.status,
        'email': user.email,
        'full_name': user.fullName,
      },
    );
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> deleteUser(StudentProfile user) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.adminDeleteProfile(user.id);
    await logAdminAuditEvent(
      action: 'user_deleted',
      targetType: 'user',
      targetId: user.id,
      details: {
        'role': user.role,
        'email': user.email,
        'full_name': user.fullName,
      },
    );
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminAuditLogsProvider);
  }
}

final adminUsersControllerProvider = Provider<AdminUsersController>((ref) {
  return AdminUsersController(ref);
});
