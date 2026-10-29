import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scholaris/features/admin/presentation/admin_users_provider.dart';
import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/features/admin/repositories/admin_audit_log_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('successful audit RPC writes one remote event', () async {
    SharedPreferences.setMockInitialValues({});
    final paths = <String>[];
    final httpClient = MockClient((request) async {
      paths.add(request.url.path);
      return http.Response('"test-id"', 200, request: request, headers: {'content-type': 'application/json'});
    });
    await Supabase.initialize(url: 'https://example.test', publishableKey: 'test-key', httpClient: httpClient);
    addTearDown(() async { await Supabase.instance.dispose(); httpClient.close(); });
    await logAdminAuditEvent(action: 'user_updated', targetType: 'user', targetId: 'u');
    expect(paths.where((p) => p.contains('/rest/v1/rpc/log_audit_event')).length, 1);
    expect(paths.where((p) => p.endsWith('/rest/v1/audit_logs')), isEmpty);
  });

  test('failed flag annotation propagates and creates no local or direct-table success', () async {
    SharedPreferences.setMockInitialValues({});
    LoginLockoutService.instance.resetState();
    final paths = <String>[];
    final httpClient = MockClient((request) async {
      paths.add(request.url.path);
      return http.Response('{"code":"42501","message":"permission denied"}', 403,
          request: request, headers: {'content-type': 'application/json'});
    });
    await Supabase.initialize(url: 'https://example.test', publishableKey: 'test-key', httpClient: httpClient);
    addTearDown(() async { await Supabase.instance.dispose(); httpClient.close(); });
    await expectLater(logAdminAuditEvent(action: 'scholarship_flagged', targetType: 'scholarship', targetId: 's', details: {'reason': 'Review'}), throwsA(isA<PostgrestException>()));
    expect(paths.where((p) => p.endsWith('/rest/v1/audit_logs')), isEmpty);
    expect(LoginLockoutService.instance.inMemoryAuditLogs, isEmpty);
  });

  test('flag annotation requires a returned audit identifier', () async {
    SharedPreferences.setMockInitialValues({});
    final httpClient = MockClient((request) async => http.Response('null', 200,
        request: request, headers: {'content-type': 'application/json'}));
    await Supabase.initialize(url: 'https://example.test', publishableKey: 'test-key', httpClient: httpClient);
    addTearDown(() async { await Supabase.instance.dispose(); httpClient.close(); });
    await expectLater(logAdminAuditEvent(action: 'scholarship_flagged', targetType: 'scholarship', targetId: 's'), throwsStateError);
  });

  test('empty canonical ledger does not substitute local audit claims', () async {
    SharedPreferences.setMockInitialValues({});
    LoginLockoutService.instance.resetState();
    await LoginLockoutService.instance.logAuditEvent(action: 'unverified_local_claim', targetType: 'user');
    final httpClient = MockClient((request) async => http.Response('[]', 200,
        request: request, headers: {'content-type': 'application/json'}));
    await Supabase.initialize(url: 'https://example.test', publishableKey: 'test-key', httpClient: httpClient);
    addTearDown(() async { await Supabase.instance.dispose(); httpClient.close(); LoginLockoutService.instance.resetState(); });
    expect(await SupabaseAuditLogDataSource().fetchAuditLogs(), isEmpty);
  });

  test('canonical ledger read failure remains visible', () async {
    SharedPreferences.setMockInitialValues({});
    final httpClient = MockClient((request) async => http.Response('{"code":"42501","message":"permission denied"}', 403,
        request: request, headers: {'content-type': 'application/json'}));
    await Supabase.initialize(url: 'https://example.test', publishableKey: 'test-key', httpClient: httpClient);
    addTearDown(() async { await Supabase.instance.dispose(); httpClient.close(); });
    await expectLater(SupabaseAuditLogDataSource().fetchAuditLogs(), throwsA(isA<PostgrestException>()));
  });
}
