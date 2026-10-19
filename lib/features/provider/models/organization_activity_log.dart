// lib/features/provider/models/organization_activity_log.dart
//
// Domain model representing an audit log entry within an organization,
// returned by public.get_organization_activity_logs RPC.

class OrganizationActivityLog {
  const OrganizationActivityLog({
    required this.id,
    this.actorId,
    required this.actorName,
    required this.action,
    required this.targetType,
    this.targetId,
    this.details = const {},
    required this.createdAt,
  });

  final String id;
  final String? actorId;
  final String actorName;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  factory OrganizationActivityLog.fromJson(Map<String, dynamic> json) {
    return OrganizationActivityLog(
      id: json['id'] as String,
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String? ?? 'System',
      action: json['action'] as String,
      targetType: json['target_type'] as String? ?? 'general',
      targetId: json['target_id'] as String?,
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : const {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (actorId != null) 'actor_id': actorId,
        'actor_name': actorName,
        'action': action,
        'target_type': targetType,
        if (targetId != null) 'target_id': targetId,
        'details': details,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationActivityLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrganizationActivityLog(id: $id, actor: $actorName, action: $action, at: $createdAt)';
}
