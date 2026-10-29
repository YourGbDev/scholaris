// lib/features/admin/presentation/admin_scholarships_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_audit_logs_provider.dart';
import 'admin_users_provider.dart';

/// Fetches all scholarships across all providers (both active and inactive) for admin oversight.
final adminScholarshipsProvider = FutureProvider<List<Scholarship>>((ref) async {
  try {
    final client = Supabase.instance.client;
    final rows = await client
        .from('scholarships')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows)
        .map(Scholarship.fromJson)
        .toList();
  } catch (_) {
    // Fallback if offline or testing
    final repo = ref.watch(scholarshipRepositoryProvider);
    return repo.fetchActive();
  }
});

/// Fetches count of submitted/reviewed applications per scholarship for real demand metric.
final adminScholarshipDemandProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    final client = Supabase.instance.client;
    final rows = await client
        .from('applications')
        .select('id, scholarship_id');
    final Map<String, int> counts = {};
    for (final r in rows) {
      final sId = r['scholarship_id'] as String?;
      if (sId != null && sId.isNotEmpty) {
        counts[sId] = (counts[sId] ?? 0) + 1;
      }
    }
    return counts;
  } catch (_) {
    return {};
  }
});

/// Map of provider ID -> profile metadata for resolving provider organization names
final adminScholarshipProvidersMapProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  try {
    final client = Supabase.instance.client;
    final rows = await client
        .from('profiles')
        .select('id, full_name, organization, role')
        .eq('role', 'provider');
    final Map<String, Map<String, dynamic>> map = {};
    for (final r in rows) {
      final id = r['id'] as String?;
      if (id != null) {
        map[id] = r;
      }
    }
    return map;
  } catch (_) {
    return {};
  }
});

final adminScholarshipSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminScholarshipFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all'); // 'all', 'active', 'inactive', 'unverified'

final adminScholarshipScopeFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all'); // 'all', 'NCR', 'Nationwide', etc.

class AdminScholarshipsController {
  AdminScholarshipsController(this.ref);
  final Ref ref;

  Future<void> toggleActive(Scholarship scholarship, bool newActive) async {
    final client = Supabase.instance.client;
    final result = await client.rpc('set_admin_scholarship_active', params: {
      'p_id': scholarship.id,
      'p_active': newActive,
    });
    if (result != scholarship.id) {
      throw StateError('The scholarship update could not be confirmed.');
    }

    ref.invalidate(adminScholarshipsProvider);
    ref.invalidate(scholarshipsProvider);
    ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> flagScholarship({
    required Scholarship scholarship,
    required String reason,
    String? resolutionNote,
  }) async {
    await logAdminAuditEvent(
      action: 'scholarship_flagged',
      targetType: 'scholarship',
      targetId: scholarship.id,
      details: {
        'title': scholarship.title,
        'provider': scholarship.provider,
        'reason': reason,
        'resolution_note': resolutionNote,
      },
    );

    ref.invalidate(adminAuditLogsProvider);
  }
}

final adminScholarshipsControllerProvider =
    Provider<AdminScholarshipsController>((ref) {
  return AdminScholarshipsController(ref);
});
