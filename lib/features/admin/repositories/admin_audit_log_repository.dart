import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLog {
  const AuditLog({
    required this.id,
    this.actorId,
    this.actorEmail,
    this.actorRole = 'unknown',
    required this.action,
    required this.targetType,
    this.targetId,
    this.details = const {},
    this.ipAddress,
    required this.createdAt,
  });

  final String id;
  final String? actorId;
  final String? actorEmail;
  final String actorRole;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final DateTime createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id']?.toString() ?? '',
      actorId: json['actor_id']?.toString(),
      actorEmail: json['actor_email']?.toString(),
      actorRole: json['actor_role']?.toString() ?? 'unknown',
      action: json['action']?.toString() ?? '',
      targetType: json['target_type']?.toString() ?? '',
      targetId: json['target_id']?.toString(),
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : json['details'] is Map
              ? Map<String, dynamic>.from(json['details'] as Map)
              : const {},
      ipAddress: json['ip_address']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'actor_id': actorId,
        'actor_email': actorEmail,
        'actor_role': actorRole,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'details': details,
        'ip_address': ipAddress,
        'created_at': createdAt.toIso8601String(),
      };
}

abstract class AuditLogDataSource {
  Future<List<Map<String, dynamic>>> fetchAuditLogs();
}

class SupabaseAuditLogDataSource implements AuditLogDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchAuditLogs() async {
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fall back to in-memory audit logs if offline or unauthenticated
    }
    return LoginLockoutService.instance.inMemoryAuditLogs;
  }
}

class AdminAuditLogRepository {
  AdminAuditLogRepository({AuditLogDataSource? dataSource})
      : _dataSource = dataSource ?? SupabaseAuditLogDataSource();

  final AuditLogDataSource _dataSource;

  Future<List<AuditLog>> fetchAuditLogs() async {
    final rows = await _dataSource.fetchAuditLogs();
    return rows.map((r) => AuditLog.fromJson(r)).toList();
  }
}
