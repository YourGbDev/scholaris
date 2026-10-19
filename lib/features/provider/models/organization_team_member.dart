// lib/features/provider/models/organization_team_member.dart
//
// Domain model representing an organization team member returned by
// public.get_organization_roster RPC.

class OrganizationTeamMember {
  const OrganizationTeamMember({
    required this.userId,
    required this.fullName,
    required this.role,
    this.active = true,
    this.createdAt,
    this.assignedScholarshipCount = 0,
  });

  final String userId;
  final String fullName;
  final String role;
  final bool active;
  final DateTime? createdAt;
  final int assignedScholarshipCount;

  bool get isOrgAdmin => role == 'org_admin';
  bool get isReviewer => role == 'reviewer';
  bool get isFinance => role == 'finance';

  String get roleDisplay {
    return switch (role) {
      'org_admin' => 'Organization Admin',
      'reviewer' => 'Academic Evaluator',
      'finance' => 'Disbursing Officer',
      _ => role,
    };
  }

  factory OrganizationTeamMember.fromJson(Map<String, dynamic> json) {
    return OrganizationTeamMember(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? 'Team Member',
      role: json['role'] as String? ?? 'reviewer',
      active: json['active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      assignedScholarshipCount: json['assigned_scholarship_count'] != null
          ? (json['assigned_scholarship_count'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'role': role,
        'active': active,
        if (createdAt != null) 'created_at': createdAt?.toUtc().toIso8601String(),
        'assigned_scholarship_count': assignedScholarshipCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationTeamMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'OrganizationTeamMember(userId: $userId, name: $fullName, role: $role, assignments: $assignedScholarshipCount)';
}
