import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/app/supabase_config.dart';
import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_audit_logs_provider.dart';

final FutureProvider<List<StudentProfile>> adminUsersProvider =
    FutureProvider<List<StudentProfile>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final repository = ref.watch(profileRepositoryProvider);
  final profiles = await repository.fetchAllProfiles();

  // Guard against in-flight stale completion (e.g. sign-out or account switch while fetching)
  if (ref.read(currentUserIdProvider) != userId) {
    return const [];
  }

  return profiles;
});

final adminUserSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminUserRoleFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all'); // 'all', 'student', 'provider', 'admin'

typedef AdminSignup = Future<String> Function({required String email, required String fullName, required String role, String? captchaToken});

final adminSignupProvider = Provider<AdminSignup>((ref) => ({required email, required fullName, required role, captchaToken}) async {
  final client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false));
  final random = Random.secure();
  final password = 'Sc!1${base64UrlEncode(List.generate(24, (_) => random.nextInt(256)))}';
  final response = await client.auth.signUp(
    email: email,
    password: password,
    data: {'full_name': fullName, 'role': role},
    captchaToken: captchaToken,
  );
  final id = response.user?.id;
  if (id == null) throw StateError('Account creation could not be confirmed.');
  return id;
});

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
    String? captchaToken,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    final newId = await ref.read(adminSignupProvider)(email: email, fullName: fullName, role: role, captchaToken: captchaToken);
    final data = {
      'id': newId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'status': status,
      'region': region,
      'school': school ?? '',
      'course': course ?? '',
      'setup_complete': true,
    };

    await repo.adminUpdateProfile(newId, data);
    final saved = await repo.fetchProfileById(newId);
    if (saved == null || saved.role != role || saved.status != status) {
      throw StateError('Account creation could not be confirmed.');
    }

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
      'role': newRole,
      'status': newStatus,
    };
    try {
      await repo.adminUpdateProfile(user.id, data);
    } catch (_) {
      await repo.adminUpsertProfile(user.id, {...user.toDbRow(), ...data});
    }
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
      'status': 'deactivated',
    };
    try {
      await repo.adminUpdateProfile(user.id, data);
    } catch (_) {
      await repo.adminUpsertProfile(user.id, {...user.toDbRow(), ...data});
    }
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
