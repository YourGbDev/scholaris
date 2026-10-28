import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import '../repositories/admin_audit_log_repository.dart';

final adminAuditLogRepositoryProvider =
    Provider<AdminAuditLogRepository>((ref) => AdminAuditLogRepository());

final FutureProvider<List<AuditLog>> adminAuditLogsProvider =
    FutureProvider<List<AuditLog>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final repo = ref.watch(adminAuditLogRepositoryProvider);
  final logs = await repo.fetchAuditLogs();

  // Guard against in-flight stale completion (e.g. sign-out or account switch while fetching)
  if (ref.read(currentUserIdProvider) != userId) {
    return const [];
  }

  return logs;
});

final adminAuditLogSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminAuditLogActionFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all');
