// lib/features/provider/models/scholarship_reviewer_assignment.dart
//
// Domain model representing a reviewer assignment for a scholarship,
// mapped to public.scholarship_reviewer_assignments.

class ScholarshipReviewerAssignment {
  const ScholarshipReviewerAssignment({
    required this.id,
    required this.scholarshipId,
    required this.reviewerId,
    required this.assignedBy,
    required this.assignedAt,
  });

  final String id;
  final String scholarshipId;
  final String reviewerId;
  final String assignedBy;
  final DateTime assignedAt;

  factory ScholarshipReviewerAssignment.fromJson(Map<String, dynamic> json) {
    return ScholarshipReviewerAssignment(
      id: json['id'] as String,
      scholarshipId: json['scholarship_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      assignedBy: json['assigned_by'] as String,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scholarship_id': scholarshipId,
        'reviewer_id': reviewerId,
        'assigned_by': assignedBy,
        'assigned_at': assignedAt.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScholarshipReviewerAssignment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ScholarshipReviewerAssignment(id: $id, scholarship: $scholarshipId, reviewer: $reviewerId)';
}
