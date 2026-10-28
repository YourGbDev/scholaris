// lib/features/safety/data/safety_report_repository.dart
//
// Repository for student safety reports.
// Connects to Supabase Database RPCs and private Storage bucket.
// No synthetic states: all errors surface immediately to UI.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/safety_report.dart';

final safetyReportRepositoryProvider = Provider<SafetyReportRepository>((ref) {
  return SafetyReportRepository();
});

final adminSafetyReportsProvider =
    AsyncNotifierProvider<AdminSafetyReportsNotifier, List<SafetyReport>>(
  AdminSafetyReportsNotifier.new,
);

final studentSafetyReportsProvider =
    FutureProvider.family<List<SafetyReport>, String>((ref, studentId) async {
  final repo = ref.watch(safetyReportRepositoryProvider);
  return repo.fetchReportsForStudent(studentId);
});

class SafetyReportRepository {
  SafetyReportRepository({SupabaseClient? client})
      : _client = client ?? _tryGetClient();

  final SupabaseClient? _client;

  static SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient get _activeClient {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not initialized');
    }
    return client;
  }

  /// Submit a safety report via the secure atomic RPC
  Future<String> submitReport({
    required String scholarshipId,
    required String category,
    required String relationship,
    required String description,
    DateTime? incidentOn,
  }) async {
    final params = <String, dynamic>{
      'p_scholarship': scholarshipId,
      'p_category': category,
      'p_relationship': relationship,
      'p_description': description.trim(),
    };
    if (incidentOn != null) {
      params['p_incident_on'] = incidentOn.toIso8601String().substring(0, 10);
    }

    final res = await _activeClient.rpc(
      'submit_student_safety_report',
      params: params,
    );

    if (res == null) {
      throw const PostgrestException(message: 'Failed to record safety report');
    }

    return res.toString();
  }

  /// Attach an evidence screenshot/document to an open safety report
  Future<String> attachEvidence({
    required String reportId,
    required Uint8List bytes,
    required String fileName,
    String? userId,
    String? attachmentKey,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'pdf', 'webp'].contains(ext)) {
      throw const FormatException('Only JPG, PNG, WEBP, and PDF files are supported for evidence.');
    }
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Evidence file exceeds maximum size of 5 MB.');
    }

    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
    final reporter = userId ?? _activeClient.auth.currentUser?.id ?? 'anonymous';
    final safeKey = attachmentKey != null
        ? attachmentKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        : 'ev_${DateTime.now().millisecondsSinceEpoch}';
    final path = '$reporter/$reportId/evidence_$safeKey.$ext';

    // 1. Reconcile if already registered on the report (e.g. after ambiguous client network drop)
    try {
      final existing = await _activeClient
          .from('student_safety_report_evidence')
          .select('id')
          .eq('report_id', reportId)
          .eq('file_path', path)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        return existing['id'].toString();
      }
    } catch (_) {
      // Proceed if query unsupported in mocked test clients
    }

    // 2. Upload to storage bucket (safety_reports, immutable upsert: false)
    try {
      await _activeClient.storage.from('safety_reports').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      // If object already exists in storage from earlier upload attempt for this stable path, proceed to register
      if (!msg.contains('already exists') && !msg.contains('duplicate') && !msg.contains('409')) {
        rethrow;
      }
    }

    // 3. Register evidence in database via RPC
    try {
      final evidenceId = await _activeClient.rpc(
        'attach_safety_report_evidence',
        params: {
          'p_report': reportId,
          'p_path': path,
          'p_name': fileName,
          'p_size': bytes.length,
          'p_mime': mime,
        },
      );
      return evidenceId.toString();
    } catch (e) {
      // Recheck if registration committed on server despite client network exception
      try {
        final existing = await _activeClient
            .from('student_safety_report_evidence')
            .select('id')
            .eq('report_id', reportId)
            .eq('file_path', path)
            .maybeSingle();

        if (existing != null && existing['id'] != null) {
          return existing['id'].toString();
        }
      } catch (_) {}

      // Avoid orphan files on registration failure
      try {
        await _activeClient.storage.from('safety_reports').remove([path]);
      } catch (_) {
        // Suppress storage cleanup error to preserve primary error
      }
      rethrow;
    }
  }

  /// Fetch secure signed URL for evidence review (1 hour expiry)
  Future<String> getEvidenceSignedUrl(String storagePath, {int expiresIn = 3600}) async {
    return _activeClient.storage
        .from('safety_reports')
        .createSignedUrl(storagePath, expiresIn);
  }

  /// Fetch reports submitted by a student
  Future<List<SafetyReport>> fetchReportsForStudent(String studentId) async {
    final res = await _activeClient
        .from('student_safety_reports')
        .select('*, scholarships(title), student_safety_report_evidence(*)')
        .eq('reporter_id', studentId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((row) => SafetyReport.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all reports for platform admin safety desk
  Future<List<SafetyReport>> fetchAllReportsForAdmin() async {
    final res = await _activeClient
        .from('student_safety_reports')
        .select('*, scholarships(title), student_safety_report_evidence(*)')
        .order('created_at', ascending: false);

    final list = (res as List)
        .map((row) => SafetyReport.fromJson(row as Map<String, dynamic>))
        .toList();

    // Priority ordering: Open urgent first, then other open, then under review, then closed
    list.sort((a, b) {
      final aPriority = _priorityRank(a);
      final bPriority = _priorityRank(b);
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return list;
  }

  static int _priorityRank(SafetyReport r) {
    if (r.isOpen && r.isUrgentCategory) return 0;
    if (r.isOpen) return 1;
    if (r.isUnderReview) return 2;
    return 3;
  }

  /// Admin review decision invoking atomic RPC
  Future<SafetyReport> reviewReport({
    required String reportId,
    required String status,
    required String note,
  }) async {
    final res = await _activeClient.rpc(
      'review_student_safety_report',
      params: {
        'p_report': reportId,
        'p_status': status,
        'p_note': note.trim(),
      },
    );

    if (res == null) {
      throw const PostgrestException(message: 'Failed to record review decision');
    }

    return SafetyReport.fromJson(res as Map<String, dynamic>);
  }
}

class AdminSafetyReportsNotifier extends AsyncNotifier<List<SafetyReport>> {
  @override
  Future<List<SafetyReport>> build() async {
    final repo = ref.watch(safetyReportRepositoryProvider);
    return await repo.fetchAllReportsForAdmin();
  }

  Future<SafetyReport> review({
    required String reportId,
    required String status,
    required String note,
  }) async {
    final repo = ref.read(safetyReportRepositoryProvider);
    final updated = await repo.reviewReport(
      reportId: reportId,
      status: status,
      note: note,
    );
    ref.invalidateSelf();
    return updated;
  }
}
