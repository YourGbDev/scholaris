import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/controllers/auth_controller.dart';
import '../models/support_ledger.dart';

abstract class SupportRepository {
  Future<SupportLedger> load();
  Future<void> saveBudget(String scholarship, String label, int cents);
  Future<void> recordCommitment(String application, int cents);
  Future<void> recordPayment(
    String application,
    int cents,
    String method,
    String reference,
  );
  Future<void> confirmReceipt(String payment);
  Future<void> voidPayment(String payment, String reason);
  Future<void> requestReview(String payment, String reason);
  Future<void> schedule(String application, DateTime? due);
}

class SupabaseSupportRepository implements SupportRepository {
  SupabaseClient get _client => Supabase.instance.client;
  @override
  Future<SupportLedger> load() async {
    // RLS restricts every table to the owner or intended student recipient.
    final values = await Future.wait([
      _client.from('individual_support_budgets').select(),
      _client.from('individual_support_commitments').select(),
      _client
          .from('individual_support_payments')
          .select()
          .order('sent_at', ascending: false),
    ]);
    return SupportLedger.fromJson({
      'budgets': values[0],
      'commitments': values[1],
      'payments': values[2],
    });
  }

  @override
  Future<void> saveBudget(String scholarship, String label, int cents) async =>
      _client.rpc(
        'save_individual_support_budget',
        params: {
          'p_scholarship': scholarship,
          'p_label': label,
          'p_cents': cents,
        },
      );
  @override
  Future<void> recordCommitment(String application, int cents) async =>
      _client.rpc(
        'record_individual_support_commitment',
        params: {'p_application': application, 'p_cents': cents},
      );
  @override
  Future<void> recordPayment(
    String application,
    int cents,
    String method,
    String reference,
  ) async => _client.rpc(
    'record_individual_support_payment',
    params: {
      'p_application': application,
      'p_cents': cents,
      'p_method': method,
      'p_reference': reference,
    },
  );
  @override
  Future<void> confirmReceipt(String payment) async => _client.rpc(
    'confirm_individual_support_receipt',
    params: {'p_payment': payment},
  );
  @override
  Future<void> voidPayment(String payment, String reason) async => _client.rpc(
    'void_individual_support_payment',
    params: {'p_payment': payment, 'p_reason': reason},
  );
  @override
  Future<void> requestReview(String payment, String reason) async =>
      _client.rpc(
        'request_support_payment_review',
        params: {'p_payment': payment, 'p_description': reason},
      );
  @override
  Future<void> schedule(String application, DateTime? due) async => _client.rpc(
    'schedule_individual_support',
    params: {
      'p_application': application,
      'p_due': due?.toIso8601String().substring(0, 10),
    },
  );
}

// Repository implementation remains server-authorized for all ledger mutations.
final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupabaseSupportRepository(),
);
final supportLedgerProvider = FutureProvider.autoDispose<SupportLedger>((
  ref,
) async {
  final user = ref.watch(currentUserIdProvider);
  if (user == null) return SupportLedger.fromJson({});
  return ref.watch(supportRepositoryProvider).load();
});
