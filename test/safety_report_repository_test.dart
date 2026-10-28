import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/safety/data/safety_report_repository.dart';
import 'package:scholaris/features/safety/models/safety_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SafetyReport model', () {
    test('parses snake_case json correctly with nested evidence', () {
      final json = {
        'id': 'rep-1',
        'scholarship_id': 'sch-100',
        'provider_id': 'prov-200',
        'reporter_id': 'stud-300',
        'category': 'fraud',
        'relationship': 'experienced',
        'description': 'Demanded payment before reviewing application.',
        'incident_on': '2026-10-15',
        'status': 'open',
        'resolution_note': null,
        'reviewed_by': null,
        'reviewed_at': null,
        'created_at': '2026-10-24T01:00:00Z',
        'scholarships': {'title': 'STEM Benefactor Fund'},
        'student_safety_report_evidence': [
          {
            'id': 'evi-1',
            'report_id': 'rep-1',
            'file_path': 'rep-1/evidence_1.png',
            'file_name': 'screenshot.png',
            'file_size_bytes': 10240,
            'mime_type': 'image/png',
            'uploaded_at': '2026-10-24T01:05:00Z',
          }
        ],
      };

      final report = SafetyReport.fromJson(json);

      expect(report.id, 'rep-1');
      expect(report.scholarshipId, 'sch-100');
      expect(report.providerId, 'prov-200');
      expect(report.reporterId, 'stud-300');
      expect(report.category, 'fraud');
      expect(report.categoryLabel, 'Fraud or scam');
      expect(report.relationship, 'experienced');
      expect(report.relationshipLabel, 'It happened to me (first-hand)');
      expect(report.isOpen, true);
      expect(report.isClosed, false);
      expect(report.scholarshipTitle, 'STEM Benefactor Fund');
      expect(report.evidence.length, 1);
      expect(report.evidence[0].fileName, 'screenshot.png');
      expect(report.evidence[0].fileSizeBytes, 10240);
    });

    test('correctly identifies urgent categories', () {
      final harassment = SafetyReport(
        scholarshipId: 's',
        providerId: 'p',
        reporterId: 'u',
        category: 'harassment',
        relationship: 'experienced',
        description: 'Detail text for report',
      );
      final fraud = harassment.copyWith(category: 'fraud');
      final threat = harassment.copyWith(category: 'threat');
      final unsafeMeetup = harassment.copyWith(category: 'unsafe_meetup');

      expect(harassment.isUrgentCategory, true);
      expect(threat.isUrgentCategory, true);
      expect(unsafeMeetup.isUrgentCategory, true);
      expect(fraud.isUrgentCategory, false);
    });

    test('reconciles alias labels for display', () {
      expect(
        SafetyReport.categoryDisplayLabel('unsafe_request'),
        'Unsafe or private meetup',
      );
      expect(
        SafetyReport.categoryDisplayLabel('payment_not_received'),
        'Delayed or unreleased stipend',
      );
      expect(
        SafetyReport.relationshipDisplayLabel('first_hand'),
        'It happened to me (first-hand)',
      );
    });
  });

  group('SafetyReportRepository evidence validation', () {
    test('rejects unsupported extensions', () async {
      final repo = SafetyReportRepository();
      expect(
        () => repo.attachEvidence(
          reportId: 'rep-1',
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'malicious.exe',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects oversized files > 5MB', () async {
      final repo = SafetyReportRepository();
      final oversizedBytes = Uint8List(5 * 1024 * 1024 + 1);
      expect(
        () => repo.attachEvidence(
          reportId: 'rep-1',
          bytes: oversizedBytes,
          fileName: 'large.jpg',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SafetyReportRepository transport and storage client behavior', () {
    late HttpServer server;
    late SupabaseClient client;
    late SafetyReportRepository repo;
    final requests = <Map<String, dynamic>>[];
    var simulateRpcFailure = false;
    var simulateCommittedExisting = false;
    Uint8List? uploadedBytes;

    setUp(() async {
      simulateRpcFailure = false;
      simulateCommittedExisting = false;
      uploadedBytes = null;
      requests.clear();

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final path = request.uri.path;
        final method = request.method;

        if (path.startsWith('/storage/v1/object/safety_reports')) {
          if (method == 'POST') {
            final bytes = await request.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
            uploadedBytes = Uint8List.fromList(bytes);
            requests.add({'method': method, 'path': path, 'size': uploadedBytes!.length});
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'Key': 'safety_reports/test.png'}));
            await request.response.close();
            return;
          } else if (method == 'DELETE') {
            final body = await utf8.decoder.bind(request).join();
            requests.add({'method': method, 'path': path, 'body': body});
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode([{'name': 'test.png'}]));
            await request.response.close();
            return;
          }
        }

        if (path.contains('/rest/v1/student_safety_report_evidence')) {
          requests.add({'method': method, 'path': path});
          request.response.statusCode = 200;
          request.response.headers.contentType = ContentType.json;
          if (simulateCommittedExisting) {
            request.response.write(jsonEncode({'id': 'reconciled-uuid-999'}));
          } else {
            request.response.statusCode = 406;
            request.response.write(jsonEncode({'code': 'PGRST116', 'message': '0 rows'}));
          }
          await request.response.close();
          return;
        }

        if (path.contains('/rest/v1/rpc/attach_safety_report_evidence')) {
          final body = await utf8.decoder.bind(request).join();
          requests.add({'method': method, 'path': path, 'body': body});
          if (simulateRpcFailure) {
            request.response.statusCode = 400;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'code': '22023', 'message': 'Invalid file size'}));
          } else {
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode('evidence-uuid-12345'));
          }
          await request.response.close();
          return;
        }

        request.response.statusCode = 404;
        await request.response.close();
      });

      client = SupabaseClient('http://127.0.0.1:${server.port}', 'local-test-key');
      repo = SafetyReportRepository(client: client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close(force: true);
    });

    test('uploads real binary bytes and registers evidence successfully', () async {
      final sampleBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 4]);
      final resultId = await repo.attachEvidence(
        reportId: 'rep-001',
        bytes: sampleBytes,
        fileName: 'proof.png',
        userId: 'stud-001',
        attachmentKey: 'att_k1',
      );

      expect(resultId, 'evidence-uuid-12345');
      expect(uploadedBytes, isNotNull);
      // Supabase storage client uploads binary via multipart/form-data envelope
      expect(uploadedBytes, containsAllInOrder(sampleBytes));
    });

    test('failed registration triggers storage cleanup to prevent orphan files', () async {
      simulateRpcFailure = true;
      final sampleBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 5, 6, 7, 8]);

      await expectLater(
        () => repo.attachEvidence(
          reportId: 'rep-001',
          bytes: sampleBytes,
          fileName: 'proof.png',
          userId: 'stud-001',
          attachmentKey: 'att_k2',
        ),
        throwsA(isA<PostgrestException>()),
      );

      final deleteRequests = requests.where((r) => r['method'] == 'DELETE' && (r['path'] as String).contains('/storage/'));
      expect(deleteRequests, isNotEmpty, reason: 'Must trigger storage remove on RPC registration failure');
    });

    test('reconciles existing registration after ambiguous response loss without re-upload', () async {
      simulateCommittedExisting = true;
      final sampleBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 9, 10]);

      final resultId = await repo.attachEvidence(
        reportId: 'rep-001',
        bytes: sampleBytes,
        fileName: 'proof.png',
        userId: 'stud-001',
        attachmentKey: 'att_k3',
      );

      expect(resultId, 'reconciled-uuid-999');
      final uploadRequests = requests.where((r) => r['method'] == 'POST' && (r['path'] as String).contains('/storage/'));
      expect(uploadRequests, isEmpty, reason: 'Must not re-upload if registration was already committed');
    });
  });
}
