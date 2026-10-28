import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/controllers/auth_controller.dart';

const supportConcernCategories = {
  'payment_not_received': 'Payment not received',
  'unsafe_request': 'Unsafe or inappropriate request',
  'release_fee': 'Asked to pay a release fee',
  'other': 'Other concern',
};

abstract class SupportConcernRepository {
  Future<List<Map<String, dynamic>>> load(String? application);
  Future<void> report(String application, String category, String description);
  Future<void> review(String id, String status, String note);
}

class SupabaseSupportConcernRepository implements SupportConcernRepository {
  SupabaseClient get _client => Supabase.instance.client;
  @override
  Future<List<Map<String, dynamic>>> load(String? application) async {
    final query = _client.from('support_concerns').select();
    final rows =
        await (application == null
                ? query
                : query.eq('application_id', application))
            .order('created_at', ascending: false);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  @override
  Future<void> report(
    String application,
    String category,
    String description,
  ) async => _client.rpc(
    'report_support_concern',
    params: {
      'p_application': application,
      'p_category': category,
      'p_description': description,
    },
  );
  @override
  Future<void> review(String id, String status, String note) async =>
      _client.rpc(
        'review_support_concern',
        params: {'p_concern': id, 'p_status': status, 'p_note': note},
      );
}

final supportConcernRepositoryProvider = Provider<SupportConcernRepository>(
  (ref) => SupabaseSupportConcernRepository(),
);
final supportConcernsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, application) async {
      if (ref.watch(currentUserIdProvider) == null) return [];
      return ref.watch(supportConcernRepositoryProvider).load(application);
    });

