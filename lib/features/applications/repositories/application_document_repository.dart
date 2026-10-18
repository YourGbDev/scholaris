// lib/features/applications/repositories/application_document_repository.dart
//
// Repository for fetching, uploading, and managing student application documents
// via Supabase Storage and public.application_documents table.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application_document.dart';

final applicationDocumentRepositoryProvider =
    Provider<ApplicationDocumentRepository>((ref) {
  return ApplicationDocumentRepository(Supabase.instance.client);
});

class ApplicationDocumentRepository {
  ApplicationDocumentRepository(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'application_documents';

  /// Fetches all documents uploaded for a specific application.
  Future<List<ApplicationDocument>> fetchForApplication(
      String applicationId) async {
      final response = await _client
          .from('application_documents')
          .select('*')
          .eq('application_id', applicationId)
          .order('uploaded_at', ascending: false);

      final list = (response as List<dynamic>)
          .map((json) =>
              ApplicationDocument.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
  }

  /// Uploads file bytes to Supabase Storage and records metadata in application_documents.
  Future<ApplicationDocument> uploadAndLinkDocument({
    required String applicationId,
    required String documentType,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecondsSinceEpoch % 10000).toRadixString(16)}';
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$applicationId/$documentId/$sanitizedFileName';

      // 1. Upload to Supabase Storage
      await _client.storage.from(_bucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );


    // 2. Insert into application_documents table
    final docData = <String, dynamic>{
      'application_id': applicationId,
      'document_type': documentType,
      'file_name': fileName,
      'file_path': storagePath,
      'storage_url': null,
      'file_size_bytes': fileBytes.length,
      'mime_type': mimeType,
      'uploaded_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final res = await _client
          .from('application_documents')
          .insert(docData)
          .select()
          .single();

      return ApplicationDocument.fromJson(res);
    } catch (_) {
      // Best-effort cleanup never turns a failed metadata write into success.
      try { await _client.storage.from(_bucket).remove([storagePath]); }
      catch (_) { /* An orphaned private object can be cleaned up by an operator. */ }
      rethrow;
    }
  }

  /// Deletes a document record and removes file from storage.
  Future<void> deleteDocument(ApplicationDocument doc) async {
    await _client.storage.from(_bucket).remove([doc.filePath]);
    await _client.from('application_documents').delete()
        .eq('id', doc.id).select('id').single();
  }

  /// Generates a time-limited signed URL for securely reading private documents.
  Future<String?> getSecureDocumentUrl(String filePath, {int expiresIn = 3600}) async {
    try {
      final signedUrl =
          await _client.storage.from(_bucket).createSignedUrl(filePath, expiresIn);
      return signedUrl;
    } catch (e) {
      debugPrint('[DOCUMENTS REPO] createSignedUrl notice: $e');
      return null;
    }
  }
}
