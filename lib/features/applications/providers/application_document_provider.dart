// lib/features/applications/providers/application_document_provider.dart
//
// Riverpod provider family managing application documents state per application.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application_document.dart';
import '../repositories/application_document_repository.dart';
import '../../auth/controllers/auth_controller.dart';

final applicationDocumentsProvider = AsyncNotifierProvider.family<
    ApplicationDocumentsNotifier, List<ApplicationDocument>, String>(
  ApplicationDocumentsNotifier.new,
);

class ApplicationDocumentsNotifier
    extends FamilyAsyncNotifier<List<ApplicationDocument>, String> {
  @override
  Future<List<ApplicationDocument>> build(String arg) async {
    ref.watch(currentUserIdProvider);
    final repo = ref.watch(applicationDocumentRepositoryProvider);
    return repo.fetchForApplication(arg);
  }

  Future<ApplicationDocument> uploadDocument({
    required String documentType,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final repo = ref.read(applicationDocumentRepositoryProvider);
    final newDoc = await repo.uploadAndLinkDocument(
      applicationId: arg,
      documentType: documentType,
      fileName: fileName,
      fileBytes: fileBytes,
      mimeType: mimeType,
    );

    // Refresh list with the newly uploaded document
    final currentList = state.valueOrNull ?? [];
    state = AsyncData([newDoc, ...currentList.where((d) => d.id != newDoc.id)]);
    return newDoc;
  }

  Future<void> removeDocument(ApplicationDocument doc) async {
    final repo = ref.read(applicationDocumentRepositoryProvider);
    await repo.deleteDocument(doc);
    final currentList = state.valueOrNull ?? [];
    state = AsyncData(currentList.where((d) => d.id != doc.id).toList());
  }
}
