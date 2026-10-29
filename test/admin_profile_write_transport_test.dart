import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseProfileDataSource source;
  var response = '[]';

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      request.response.headers.contentType = ContentType.json;
      request.response.write(response);
      await request.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'local-test-key');
    source = SupabaseProfileDataSource(client: client);
    response = '[]';
  });
  tearDown(() async { await client.dispose(); await server.close(force: true); });

  for (final action in ['update', 'delete']) {
    test('$action fails when the server returns zero rows', () async {
      final op = action == 'update'
          ? source.updateProfile('missing', {'status': 'deactivated'})
          : source.deleteProfile('missing');
      await expectLater(op, throwsA(anyOf(isA<StateError>(), isA<PostgrestException>())));
    });
    test('$action succeeds when the server confirms one row', () async {
      response = '[{"id":"user-1"}]';
      final op = action == 'update'
          ? source.updateProfile('user-1', {'status': 'deactivated'})
          : source.deleteProfile('user-1');
      await expectLater(op, completes);
    });
  }
}
