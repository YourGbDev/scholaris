// lib/features/provider/data/provider_verification_repository.dart
//
// Repository for Provider Verification and Document Uploads.
// Communicates directly with Supabase Database and Storage.
// NO in-memory fallback: failures immediately surface to the UI.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/provider_verification.dart';

const int kMaxUploadSizeBytes = 5 * 1024 * 1024; // 5 MB
const Set<String> kAllowedFileExtensions = {'jpg', 'jpeg', 'png', 'pdf'};

class ProviderVerificationRepository {
  ProviderVerificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Validate file bytes and extension client-side
  static String? validateFile({
    required String fileName,
    required int byteLength,
  }) {
    if (byteLength == 0) {
      return 'File is empty. Please select a valid document.';
    }
    if (byteLength > kMaxUploadSizeBytes) {
      return 'File exceeds maximum allowed size of 5 MB.';
    }
    final ext = fileName.split('.').last.toLowerCase();
    if (!kAllowedFileExtensions.contains(ext)) {
      return 'Unsupported file format ($ext). Only JPG, PNG, and PDF are allowed.';
    }
    return null;
  }

  /// Uploads a verification file to the private `provider_documents` bucket.
  /// Path pattern: `{userId}/{docType}_{timestamp}.{ext}`
  Future<String> uploadDocument({
    required String userId,
    required String docType,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final validationError = validateFile(
      fileName: fileName,
      byteLength: bytes.length,
    );
    if (validationError != null) {
      throw FormatException(validationError);
    }

    final ext = fileName.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${docType}_$timestamp.$ext';

    // Must succeed or throw directly to the caller
    await _client.storage.from('provider_documents').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: ext == 'pdf'
                ? 'application/pdf'
                : ext == 'png'
                    ? 'image/png'
                    : 'image/jpeg',
            upsert: true,
          ),
        );
    return path;
  }

  /// Generates a signed URL for secure document inspection (default expiry: 1 hour).
  Future<String> getSignedUrl(String storagePath, {int expiresIn = 3600}) async {
    final signedUrl = await _client.storage
        .from('provider_documents')
        .createSignedUrl(storagePath, expiresIn);
    return signedUrl;
  }

  /// Submits or updates a provider verification record in Supabase.
  Future<ProviderVerification> submitVerification(
      ProviderVerification verification) async {
    final now = DateTime.now();
    final withTimestamp = verification.copyWith(
      submittedAt: verification.submittedAt ?? now,
      status: 'pending',
    );

    // 1. Persist directly to provider_verifications table (DB trigger syncs profiles)
    final json = withTimestamp.toJson();
    await _client.from('provider_verifications').upsert(
          json,
          onConflict: 'user_id',
        );

    return withTimestamp;
  }

  /// Fetches verification record for a specific user ID directly from Supabase.
  Future<ProviderVerification?> fetchVerificationForUser(String userId) async {
    final res = await _client
        .from('provider_verifications')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) return null;
    return ProviderVerification.fromJson(res);
  }

  /// Fetches all verifications across the platform (for Admin verification tab).
  /// Orders: 'pending' first, then latest submitted.
  Future<List<ProviderVerification>> fetchAllVerifications() async {
    final res = await _client
        .from('provider_verifications')
        .select()
        .order('submitted_at', ascending: false);

    final list = (res as List)
        .map((row) => ProviderVerification.fromJson(row as Map<String, dynamic>))
        .toList();

    // Sort: pending first, then newest submitted
    list.sort((a, b) {
      if (a.status == 'pending' && b.status != 'pending') return -1;
      if (a.status != 'pending' && b.status == 'pending') return 1;
      final aDate = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return list;
  }

  /// Admin approval or rejection of a verification request.
  /// Server-side trigger writes audit log and sets reviewed_by / reviewed_at.
  Future<void> updateVerificationStatus({
    required String userId,
    required String status, // 'approved' | 'rejected'
    required String adminId,
    String? reviewNote,
  }) async {
    await _client.from('provider_verifications').update({
      'status': status,
      'reviewed_by': adminId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'review_note': reviewNote,
    }).eq('user_id', userId);
  }
}
