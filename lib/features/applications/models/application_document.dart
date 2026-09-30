// lib/features/applications/models/application_document.dart
//
// Domain model representing a student-uploaded verification document
// linked to a scholarship application.

class ApplicationDocument {
  const ApplicationDocument({
    required this.id,
    required this.applicationId,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    this.storageUrl,
    this.fileSizeBytes,
    this.mimeType,
    required this.uploadedAt,
  });

  final String id;
  final String applicationId;
  final String documentType;
  final String fileName;
  final String filePath;
  final String? storageUrl;
  final int? fileSizeBytes;
  final String? mimeType;
  final DateTime uploadedAt;

  factory ApplicationDocument.fromJson(Map<String, dynamic> json) {
    return ApplicationDocument(
      id: json['id'] as String,
      applicationId: json['application_id'] as String,
      documentType: json['document_type'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      storageUrl: json['storage_url'] as String?,
      fileSizeBytes: json['file_size_bytes'] != null
          ? (json['file_size_bytes'] as num).toInt()
          : null,
      mimeType: json['mime_type'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_id': applicationId,
      'document_type': documentType,
      'file_name': fileName,
      'file_path': filePath,
      if (storageUrl != null) 'storage_url': storageUrl,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      'uploaded_at': uploadedAt.toUtc().toIso8601String(),
    };
  }

  String get humanType {
    switch (documentType) {
      case 'transcript':
        return 'Academic Transcript';
      case 'certificate_of_indigency':
        return 'Certificate of Indigency';
      case 'certificate_of_grades':
        return 'Certificate of Grades';
      case 'recommendation_letter':
        return 'Recommendation Letter';
      case 'enrollment_certificate':
        return 'Certificate of Registration (COR)';
      case 'id_document':
        return 'Student / Government ID';
      case 'other':
      default:
        return 'Supporting Document';
    }
  }

  String get formattedSize {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) return '';
    final bytes = fileSizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
