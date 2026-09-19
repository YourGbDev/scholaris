import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/admin_audit_log_repository.dart';

final adminAuditLogRepositoryProvider =
    Provider<AdminAuditLogRepository>((ref) => AdminAuditLogRepository());

final adminAuditLogsProvider = FutureProvider<List<AuditLog>>((ref) async {
  final repo = ref.watch(adminAuditLogRepositoryProvider);
  return repo.fetchAuditLogs();
});

final adminAuditLogSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminAuditLogActionFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all');
