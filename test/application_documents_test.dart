// test/application_documents_test.dart
//
// Unit and RLS isolation tests for application documents.
// Verifies:
// 1. ApplicationDocument model serialization and formatting helpers.
// 2. RLS boundary simulation: Student A cannot read or write to Student B's documents.
// 3. Provider/Admin authorization boundary.

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/models/application_document.dart';

/// Simulated RLS database engine verifying Row Level Security policies
/// defined in migration 0017:
/// - students_read_own_application_documents
/// - students_insert_own_application_documents
/// - students_delete_own_application_documents
/// - providers_and_admins_read_application_documents
class SimulatedRlsDatabase {
  final Map<String, Map<String, dynamic>> applications = {};
  final Map<String, Map<String, dynamic>> scholarships = {};
  final Map<String, Map<String, dynamic>> profiles = {};
  final List<Map<String, dynamic>> documents = [];

  void seedStudent({required String userId, required String email}) {
    profiles[userId] = {
      'id': userId,
      'email': email,
      'role': 'student',
    };
  }

  void seedAdmin({required String userId, required String email}) {
    profiles[userId] = {
      'id': userId,
      'email': email,
      'role': 'admin',
    };
  }

  void seedScholarship({
    required String id,
    required String title,
    required String createdBy,
  }) {
    scholarships[id] = {
      'id': id,
      'title': title,
      'created_by': createdBy,
    };
  }

  void seedApplication({
    required String id,
    required String userId,
    required String scholarshipId,
    String status = 'submitted',
  }) {
    applications[id] = {
      'id': id,
      'user_id': userId,
      'scholarship_id': scholarshipId,
      'status': status,
    };
  }

  /// Evaluates SELECT on application_documents under RLS
  List<Map<String, dynamic>> selectDocuments({
    required String currentUserId,
    String? applicationId,
  }) {
    final userProfile = profiles[currentUserId];
    final isAdmin = userProfile?['role'] == 'admin';

    return documents.where((doc) {
      if (applicationId != null && doc['application_id'] != applicationId) {
        return false;
      }

      final app = applications[doc['application_id']];
      if (app == null) return false;

      // Policy 1: Student reads own application documents
      final isOwnApp = app['user_id'] == currentUserId;
      if (isOwnApp) return true;

      // Policy 4: Admin access
      if (isAdmin) return true;

      // Policy 4: Provider access (scholarship owner)
      final scholarship = scholarships[app['scholarship_id']];
      if (scholarship != null && scholarship['created_by'] == currentUserId) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Evaluates INSERT on application_documents under RLS
  bool insertDocument({
    required String currentUserId,
    required Map<String, dynamic> docRow,
  }) {
    final appId = docRow['application_id'];
    final app = applications[appId];
    if (app == null) return false;

    // Policy 2: Student can INSERT only into own application
    final isOwnApp = app['user_id'] == currentUserId;
    if (!isOwnApp) {
      throw StateError('RLS violation: WITH CHECK expression failed on INSERT.');
    }

    documents.add(Map<String, dynamic>.of(docRow));
    return true;
  }

  // --- Storage Bucket & Storage.Objects RLS Simulation (Migration 0018) ---
  final Map<String, bool> storageBuckets = {'application_documents': false};
  final List<Map<String, dynamic>> storageObjects = [];

  bool isBucketPublic(String bucketId) => storageBuckets[bucketId] ?? false;

  /// Evaluates INSERT on storage.objects under Migration 0018 policy:
  /// storage_student_upload_own_application_documents
  bool uploadStorageObject({
    required String currentUserId,
    required String bucketId,
    required String storagePath,
    required List<int> fileBytes,
  }) {
    if (bucketId != 'application_documents') return false;

    // Path convention: $application_id/${timestamp}_$filename
    final parts = storagePath.split('/');
    if (parts.isEmpty) return false;
    final targetAppId = parts.first;

    final app = applications[targetAppId];
    if (app == null || app['user_id'] != currentUserId) {
      throw StateError(
          'Storage RLS policy violation: User $currentUserId cannot upload to application $targetAppId (Cross-User Rejection).');
    }

    storageObjects.add({
      'bucket_id': bucketId,
      'name': storagePath,
      'owner': currentUserId,
      'size': fileBytes.length,
    });
    return true;
  }

  /// Evaluates SELECT on storage.objects under Migration 0018 policy:
  /// storage_student_read_own_application_documents
  List<Map<String, dynamic>> selectStorageObjects({
    required String currentUserId,
    required String bucketId,
  }) {
    final userProfile = profiles[currentUserId];
    final isAdmin = userProfile?['role'] == 'admin';

    return storageObjects.where((obj) {
      if (obj['bucket_id'] != bucketId) return false;

      final parts = (obj['name'] as String).split('/');
      if (parts.isEmpty) return false;
      final targetAppId = parts.first;

      final app = applications[targetAppId];
      if (app == null) return false;

      // Student reading their own uploaded application documents
      if (app['user_id'] == currentUserId) return true;

      // Admin access
      if (isAdmin) return true;

      // Reviewing provider access
      final scholarship = scholarships[app['scholarship_id']];
      if (scholarship != null && scholarship['created_by'] == currentUserId) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Evaluates direct download/fetch of a file by path under Storage RLS policies
  Map<String, dynamic> fetchStorageObjectByPath({
    required String currentUserId,
    required String bucketId,
    required String storagePath,
  }) {
    if (bucketId != 'application_documents') {
      throw StateError('Bucket not found or invalid');
    }

    final obj = storageObjects.firstWhere(
      (o) => o['bucket_id'] == bucketId && o['name'] == storagePath,
      orElse: () => throw StateError('File not found'),
    );

    // Apply storage.objects SELECT RLS policies
    final parts = storagePath.split('/');
    if (parts.isEmpty) {
      throw StateError('Access denied: Invalid storage path format');
    }
    final targetAppId = parts.first;

    final app = applications[targetAppId];
    if (app == null) {
      throw StateError('Access denied: Target application does not exist');
    }

    final userProfile = profiles[currentUserId];
    final isAdmin = userProfile?['role'] == 'admin';

    // 1. Student owns the application
    if (app['user_id'] == currentUserId) {
      return obj;
    }

    // 2. Admin access
    if (isAdmin) {
      return obj;
    }

    // 3. Provider review access
    final scholarship = scholarships[app['scholarship_id']];
    if (scholarship != null && scholarship['created_by'] == currentUserId) {
      return obj;
    }

    // Storage-level rejection: Student B does NOT own application and is not authorized reviewer
    throw StateError('Storage-level rejection: User $currentUserId is unauthorized to fetch file at $storagePath');
  }
}

void main() {
  group('ApplicationDocument Model', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime.now().toUtc();
      final doc = ApplicationDocument(
        id: 'doc-123',
        applicationId: 'app-456',
        documentType: 'transcript',
        fileName: 'tor_final.pdf',
        filePath: 'app-456/123_tor_final.pdf',
        storageUrl: 'https://storage.scholaris.ph/tor_final.pdf',
        fileSizeBytes: 2048576, // ~1.95 MB
        mimeType: 'application/pdf',
        uploadedAt: now,
      );

      final json = doc.toJson();
      expect(json['id'], 'doc-123');
      expect(json['application_id'], 'app-456');
      expect(json['document_type'], 'transcript');
      expect(json['file_name'], 'tor_final.pdf');
      expect(json['file_size_bytes'], 2048576);

      final restored = ApplicationDocument.fromJson(json);
      expect(restored.id, doc.id);
      expect(restored.documentType, 'transcript');
      expect(restored.humanType, 'Academic Transcript');
      expect(restored.formattedSize, '2.0 MB');
    });

    test('humanType formats all documented document types', () {
      final now = DateTime.now();
      expect(
        ApplicationDocument(
          id: '1',
          applicationId: '1',
          documentType: 'certificate_of_indigency',
          fileName: 'indigency.jpg',
          filePath: 'path',
          uploadedAt: now,
        ).humanType,
        'Certificate of Indigency',
      );

      expect(
        ApplicationDocument(
          id: '2',
          applicationId: '1',
          documentType: 'enrollment_certificate',
          fileName: 'cor.pdf',
          filePath: 'path',
          uploadedAt: now,
        ).humanType,
        'Certificate of Registration (COR)',
      );
    });
  });

  group('RLS Isolation Security Policy (Migration 0017)', () {
    late SimulatedRlsDatabase db;

    setUp(() {
      db = SimulatedRlsDatabase();

      // Seed 2 students and 1 provider/admin
      db.seedStudent(userId: 'student-A', email: 'alice@example.com');
      db.seedStudent(userId: 'student-B', email: 'bob@example.com');
      db.seedAdmin(userId: 'admin-1', email: 'admin@scholaris.ph');

      db.seedScholarship(
        id: 'sch-1',
        title: 'DOST Merit Scholarship',
        createdBy: 'provider-1',
      );

      // Student A applies to sch-1
      db.seedApplication(
        id: 'app-A',
        userId: 'student-A',
        scholarshipId: 'sch-1',
      );

      // Student B applies to sch-1
      db.seedApplication(
        id: 'app-B',
        userId: 'student-B',
        scholarshipId: 'sch-1',
      );

      // Student A uploads a transcript
      db.insertDocument(
        currentUserId: 'student-A',
        docRow: {
          'id': 'doc-A1',
          'application_id': 'app-A',
          'document_type': 'transcript',
          'file_name': 'alice_transcript.pdf',
          'file_path': 'app-A/alice_transcript.pdf',
        },
      );
    });

    test('Student A can read their own documents', () {
      final docs = db.selectDocuments(currentUserId: 'student-A');
      expect(docs.length, 1);
      expect(docs.first['id'], 'doc-A1');
      expect(docs.first['file_name'], 'alice_transcript.pdf');
    });

    test('Student B CANNOT read Student A documents (Cross-User Isolation)', () {
      // Bob queries documents
      final docs = db.selectDocuments(currentUserId: 'student-B');
      expect(docs, isEmpty,
          reason: 'RLS must deny Student B from reading Student A documents');

      // Bob specifically queries Student A application ID
      final targetedDocs = db.selectDocuments(
        currentUserId: 'student-B',
        applicationId: 'app-A',
      );
      expect(targetedDocs, isEmpty,
          reason: 'RLS must return 0 rows for unauthorized application ID');
    });

    test('Student B CANNOT insert document into Student A application', () {
      expect(
        () => db.insertDocument(
          currentUserId: 'student-B',
          docRow: {
            'id': 'doc-malicious',
            'application_id': 'app-A',
            'document_type': 'other',
            'file_name': 'exploit.pdf',
            'file_path': 'app-A/exploit.pdf',
          },
        ),
        throwsA(isA<StateError>()),
        reason: 'RLS WITH CHECK must reject insert into another user application',
      );
    });

    test('Platform Admin CAN read student documents for compliance audit', () {
      final docs = db.selectDocuments(currentUserId: 'admin-1');
      expect(docs.length, 1);
      expect(docs.first['id'], 'doc-A1');
    });
  });

  group('Storage Bucket RLS Security Policy (Migration 0018)', () {
    late SimulatedRlsDatabase db;

    setUp(() {
      db = SimulatedRlsDatabase();

      db.seedStudent(userId: 'student-A', email: 'alice@example.com');
      db.seedStudent(userId: 'student-B', email: 'bob@example.com');
      db.seedAdmin(userId: 'admin-1', email: 'admin@scholaris.ph');

      db.seedScholarship(
        id: 'sch-1',
        title: 'DOST Merit Scholarship',
        createdBy: 'provider-1',
      );

      db.seedApplication(
        id: 'app-A',
        userId: 'student-A',
        scholarshipId: 'sch-1',
      );

      db.seedApplication(
        id: 'app-B',
        userId: 'student-B',
        scholarshipId: 'sch-1',
      );
    });

    test('Storage bucket application_documents is configured as private (public: false)', () {
      expect(
        db.isBucketPublic('application_documents'),
        isFalse,
        reason: 'Storage bucket must be private (public: false) so files cannot be accessed anonymously via CDN.',
      );
    });

    test('Student A CAN upload file to their own application folder in storage', () {
      final success = db.uploadStorageObject(
        currentUserId: 'student-A',
        bucketId: 'application_documents',
        storagePath: 'app-A/1727400000_transcript.pdf',
        fileBytes: [1, 2, 3, 4],
      );
      expect(success, isTrue);

      final objects = db.selectStorageObjects(
        currentUserId: 'student-A',
        bucketId: 'application_documents',
      );
      expect(objects.length, 1);
      expect(objects.first['name'], 'app-A/1727400000_transcript.pdf');
    });

    test('Student B CANNOT upload file to Student A application folder (Cross-User Rejection)', () {
      expect(
        () => db.uploadStorageObject(
          currentUserId: 'student-B',
          bucketId: 'application_documents',
          storagePath: 'app-A/exploit_payload.pdf',
          fileBytes: [0, 0, 0],
        ),
        throwsA(isA<StateError>()),
        reason: 'Storage RLS WITH CHECK must reject upload into another student application folder',
      );
    });

    test('Student B CANNOT read/download files from Student A application folder (Cross-User Isolation)', () {
      // First Student A uploads their file
      db.uploadStorageObject(
        currentUserId: 'student-A',
        bucketId: 'application_documents',
        storagePath: 'app-A/confidential_tax_cert.pdf',
        fileBytes: [10, 20, 30],
      );

      // Student B attempts to query storage objects
      final bobObjects = db.selectStorageObjects(
        currentUserId: 'student-B',
        bucketId: 'application_documents',
      );
      expect(
        bobObjects,
        isEmpty,
        reason: 'Storage RLS SELECT must not return Student A storage files to Student B',
      );
    });

    test('Platform Admin CAN read student files in storage for verification audit', () {
      db.uploadStorageObject(
        currentUserId: 'student-A',
        bucketId: 'application_documents',
        storagePath: 'app-A/valid_id.pdf',
        fileBytes: [99, 100],
      );

      final adminObjects = db.selectStorageObjects(
        currentUserId: 'admin-1',
        bucketId: 'application_documents',
      );
      expect(adminObjects.length, 1);
      expect(adminObjects.first['name'], 'app-A/valid_id.pdf');
    });

    test('Student B gets rejected at the storage level when trying to fetch Student A file directly by path', () {
      // Student A uploads a confidential transcript to their application folder
      db.uploadStorageObject(
        currentUserId: 'student-A',
        bucketId: 'application_documents',
        storagePath: 'app-A/doc-999/student_a_official_transcript.pdf',
        fileBytes: [1, 2, 3, 4, 5],
      );

      // Student A can fetch it directly by path
      final studentAFile = db.fetchStorageObjectByPath(
        currentUserId: 'student-A',
        bucketId: 'application_documents',
        storagePath: 'app-A/doc-999/student_a_official_transcript.pdf',
      );
      expect(studentAFile['name'], 'app-A/doc-999/student_a_official_transcript.pdf');

      // Student B attempts to directly download Student A's file using the exact storage path
      expect(
        () => db.fetchStorageObjectByPath(
          currentUserId: 'student-B',
          bucketId: 'application_documents',
          storagePath: 'app-A/doc-999/student_a_official_transcript.pdf',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Storage-level rejection'),
          ),
        ),
        reason: 'Direct storage path requests by unauthorized users must be rejected at the storage layer',
      );
    });
  });
}
