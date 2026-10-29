import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scholaris/features/admin/presentation/admin_scholarships_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('admin activation rejects a zero-row update and sends no client success claim', () async {
    SharedPreferences.setMockInitialValues({});
    final paths = <String>[];
    final httpClient = MockClient((request) async {
      paths.add(request.url.path);
      final isRpc = request.url.path.contains('set_admin_scholarship_active');
      return http.Response(isRpc ? '{"code":"P0002","message":"not found"}' : 'null', isRpc ? 404 : 200,
          request: request, headers: {'content-type': 'application/json'});
    });
    await Supabase.initialize(url: 'https://example.test', publishableKey: 'test-key', httpClient: httpClient);
    final container = ProviderContainer();
    addTearDown(() async { container.dispose(); await Supabase.instance.dispose(); httpClient.close(); });
    final scholarship = Scholarship(id: 's', title: 'Test', minGpa: 1, deadline: DateTime(2026, 12));
    await expectLater(container.read(adminScholarshipsControllerProvider).toggleActive(scholarship, false), throwsA(isA<PostgrestException>()));
    expect(paths.where((path) => path.contains('log_audit_event')), isEmpty);
  });
}
