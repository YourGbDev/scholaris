import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/applications/repositories/application_document_repository.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseApplicationDataSource source;
  late ApplicationRepository repo;
  var status = 200;
  Object? response;
  Map<String, dynamic>? sent;
  final paths = <String>[];
  var allowStorage = false;
  var emptyApplicationLookup = false;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      paths.add(request.uri.path);
      sent = body.isEmpty || request.headers.contentType?.mimeType != 'application/json'
          ? null : jsonDecode(body) as Map<String, dynamic>;
      final isStorage = request.uri.path.startsWith('/storage/');
      request.response.statusCode = isStorage && allowStorage ? 200 : status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(emptyApplicationLookup && request.method == 'GET' ? []
          : isStorage && allowStorage ? {'Key': 'private-path'} : response));
      await request.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'local-test-key');
    source = SupabaseApplicationDataSource(client: client);
    repo = ApplicationRepository(dataSource: source, currentUserId: () => 'reviewer');
    status = 200;
    response = [];
    sent = null;
    paths.clear();
    allowStorage = false;
    emptyApplicationLookup = false;
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  for (final operation in ['student update', 'provider status', 'provider notes']) {
    test('$operation does not report success on a zero-row RLS response', () async {
      status = 406;
      response = {'code': 'PGRST116', 'message': 'Expected one row, received zero'};
      final future = switch (operation) {
        'student update' => source.updateApplication('student', 'missing', {'status': 'submitted'}),
        'provider status' => source.updateApplicationStatus('missing', 'approved'),
        _ => source.updateApplicationNotes('missing', 'notes'),
      };
      await expectLater(future, throwsA(isA<PostgrestException>()));
    });
  }

  test('empty transaction response fails instead of displaying success', () async {
    await expectLater(repo.reviewApplication(applicationId: 'a', expectedStatus: ApplicationStatus.submitted,
      action: 'endorse'), throwsStateError);
  });

  test('draft insert uses only columns that exist in the live applications schema', () async {
    emptyApplicationLookup = true;
    response = {'id': 'a', 'user_id': 'reviewer', 'scholarship_id': 's', 'status': 'draft'};
    final draft = await repo.saveDraft(scholarshipId: 's');
    expect(draft.status, ApplicationStatus.draft);
    expect(sent!.keys, unorderedEquals(['user_id', 'scholarship_id', 'status', 'updated_at']));
  });

  test('backend authorization/transaction failure propagates to the UI caller', () async {
    status = 403;
    response = {'code': '42501', 'message': 'Only organization admins can decide'};
    await expectLater(repo.reviewApplication(applicationId: 'a', expectedStatus: ApplicationStatus.underReview,
      action: 'approve'), throwsA(isA<PostgrestException>()));
  });

  test('one confirmed RPC row returns persisted endorsement and uses no client actor', () async {
    response = [{'id': 'a', 'user_id': 'student', 'scholarship_id': 's', 'status': 'under_review',
      'endorsed_by': 'reviewer', 'endorsed_at': '2026-10-19T00:00:00Z'}];
    final application = await repo.reviewApplication(applicationId: 'a', expectedStatus: ApplicationStatus.submitted,
      action: 'endorse', scores: {'academic': 8, 'financial': 7, 'leadership': 9, 'vision': 8});
    expect(application.endorsedBy, 'reviewer');
    expect(application.endorsedAt, isNotNull);
    expect(sent!['p_expected_status'], 'submitted');
    expect(sent!.keys, isNot(contains('reviewer_id')));
  });

  test('mismatched result status is not success', () async {
    response = {'id': 'a', 'user_id': 'student', 'scholarship_id': 's', 'status': 'submitted'};
    await expectLater(repo.reviewApplication(applicationId: 'a', expectedStatus: ApplicationStatus.submitted,
      action: 'endorse'), throwsStateError);
  });

  for (final storageSucceeds in [false, true]) {
    test('document upload cannot report success when ${storageSucceeds ? 'metadata' : 'storage'} fails', () async {
      status = 403;
      response = {'code': '42501', 'message': 'Upload denied', 'error': 'Unauthorized', 'statusCode': '403'};
      allowStorage = storageSucceeds;
      await expectLater(ApplicationDocumentRepository(client).uploadAndLinkDocument(
        applicationId: '00000000-0000-0000-0000-000000000001', documentType: 'transcript',
        fileName: 'demo.pdf', fileBytes: Uint8List.fromList(utf8.encode('%PDF demo')), mimeType: 'application/pdf'),
        throwsA(isA<Exception>()));
      if (!storageSucceeds) {
        expect(paths.where((path) => path.startsWith('/rest/')), isEmpty);
      }
    });
  }
}
