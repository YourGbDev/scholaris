// lib/features/safety/models/safety_report.dart
//
// Model for scholarship-level student safety reports.
// Complies with RA 10173 privacy bounds.

class SafetyReportEvidence {
  const SafetyReportEvidence({
    this.id,
    required this.reportId,
    required this.filePath,
    required this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.uploadedAt,
  });

  final String? id;
  final String reportId;
  final String filePath;
  final String fileName;
  final int? fileSizeBytes;
  final String? mimeType;
  final DateTime? uploadedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'report_id': reportId,
        'file_path': filePath,
        'file_name': fileName,
        if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
        if (mimeType != null) 'mime_type': mimeType,
        if (uploadedAt != null) 'uploaded_at': uploadedAt!.toIso8601String(),
      };

  factory SafetyReportEvidence.fromJson(Map<String, dynamic> json) =>
      SafetyReportEvidence(
        id: json['id'] as String?,
        reportId: json['report_id'] as String? ?? '',
        filePath: json['file_path'] as String? ?? '',
        fileName: json['file_name'] as String? ?? '',
        fileSizeBytes: json['file_size_bytes'] as int?,
        mimeType: json['mime_type'] as String?,
        uploadedAt: json['uploaded_at'] != null
            ? DateTime.tryParse(json['uploaded_at'] as String)
            : null,
      );
}

class SafetyReport {
  const SafetyReport({
    this.id,
    required this.scholarshipId,
    required this.providerId,
    required this.reporterId,
    required this.category,
    required this.relationship,
    required this.description,
    this.incidentOn,
    this.status = 'open',
    this.resolutionNote,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
    this.evidence = const [],
    this.scholarshipTitle,
  });

  final String? id;
  final String scholarshipId;
  final String providerId;
  final String reporterId;
  final String category;
  final String relationship;
  final String description;
  final DateTime? incidentOn;
  final String status;
  final String? resolutionNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SafetyReportEvidence> evidence;
  final String? scholarshipTitle;

  bool get isOpen => status == 'open';
  bool get isUnderReview => status == 'under_review';
  bool get isResolved => status == 'resolved';
  bool get isDismissed => status == 'dismissed';
  bool get isClosed => isResolved || isDismissed;

  bool get isUrgentCategory =>
      category == 'harassment' ||
      category == 'unsafe_meetup' ||
      category == 'threat';

  String get categoryLabel => categoryDisplayLabel(category);
  String get relationshipLabel => relationshipDisplayLabel(relationship);

  static String categoryDisplayLabel(String category) {
    switch (category) {
      case 'fraud':
        return 'Fraud or scam';
      case 'unsafe_meetup':
      case 'unsafe_request':
        return 'Unsafe or private meetup';
      case 'harassment':
        return 'Harassment or misconduct';
      case 'threat':
        return 'Threat or intimidation';
      case 'release_fee':
        return 'Demand for fee or payment';
      case 'payment_problem':
      case 'payment_not_received':
        return 'Delayed or unreleased stipend';
      case 'other':
      default:
        return 'Other concern';
    }
  }

  static String relationshipDisplayLabel(String relationship) {
    switch (relationship) {
      case 'experienced':
      case 'first_hand':
        return 'It happened to me (first-hand)';
      case 'witnessed':
        return 'I saw or witnessed it';
      case 'told':
        return 'I was told about it by someone else';
      default:
        return relationship;
    }
  }

  SafetyReport copyWith({
    String? id,
    String? scholarshipId,
    String? providerId,
    String? reporterId,
    String? category,
    String? relationship,
    String? description,
    DateTime? incidentOn,
    String? status,
    String? resolutionNote,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SafetyReportEvidence>? evidence,
    String? scholarshipTitle,
  }) {
    return SafetyReport(
      id: id ?? this.id,
      scholarshipId: scholarshipId ?? this.scholarshipId,
      providerId: providerId ?? this.providerId,
      reporterId: reporterId ?? this.reporterId,
      category: category ?? this.category,
      relationship: relationship ?? this.relationship,
      description: description ?? this.description,
      incidentOn: incidentOn ?? this.incidentOn,
      status: status ?? this.status,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      evidence: evidence ?? this.evidence,
      scholarshipTitle: scholarshipTitle ?? this.scholarshipTitle,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'scholarship_id': scholarshipId,
        'provider_id': providerId,
        'reporter_id': reporterId,
        'category': category,
        'relationship': relationship,
        'description': description,
        if (incidentOn != null)
          'incident_on': incidentOn!.toIso8601String().substring(0, 10),
        'status': status,
        if (resolutionNote != null) 'resolution_note': resolutionNote,
        if (reviewedBy != null) 'reviewed_by': reviewedBy,
        if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  factory SafetyReport.fromJson(Map<String, dynamic> json) => SafetyReport(
        id: json['id'] as String?,
        scholarshipId: json['scholarship_id'] as String? ?? '',
        providerId: json['provider_id'] as String? ?? '',
        reporterId: json['reporter_id'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        relationship: json['relationship'] as String? ?? 'experienced',
        description: json['description'] as String? ?? '',
        incidentOn: json['incident_on'] != null
            ? DateTime.tryParse(json['incident_on'] as String)
            : null,
        status: json['status'] as String? ?? 'open',
        resolutionNote: json['resolution_note'] as String?,
        reviewedBy: json['reviewed_by'] as String?,
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.tryParse(json['reviewed_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
        scholarshipTitle: (json['scholarships'] is Map)
            ? (json['scholarships'] as Map)['title'] as String?
            : json['scholarship_title'] as String?,
        evidence: (json['student_safety_report_evidence'] is List)
            ? (json['student_safety_report_evidence'] as List)
                .map((e) =>
                    SafetyReportEvidence.fromJson(e as Map<String, dynamic>))
                .toList()
            : const [],
      );
}
