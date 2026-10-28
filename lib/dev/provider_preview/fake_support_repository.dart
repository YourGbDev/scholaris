import 'package:scholaris/features/provider/models/support_ledger.dart';
import 'package:scholaris/features/provider/repositories/support_repository.dart';

// Fictional in-memory records used only by the local UI preview.
class PreviewSupportRepository implements SupportRepository {
  final budgets = <Map<String, dynamic>>[
    {
      'scholarship_id': 'sch-1',
      'cycle_label': '2026–2027 academic year',
      'budget_cents': 10000000,
    },
  ];
  final commitments = <Map<String, dynamic>>[];
  final payments = <Map<String, dynamic>>[];
  @override
  Future<SupportLedger> load() async => SupportLedger.fromJson({
    'budgets': budgets,
    'commitments': commitments,
    'payments': payments,
  });
  @override
  Future<void> saveBudget(String scholarship, String label, int cents) async {
    budgets.removeWhere((r) => r['scholarship_id'] == scholarship);
    budgets.add({
      'scholarship_id': scholarship,
      'cycle_label': label,
      'budget_cents': cents,
    });
  }

  @override
  Future<void> recordCommitment(String application, int cents) async {
    if (commitments.any((r) => r['application_id'] == application)) {
      throw StateError('Already recorded');
    }
    commitments.add({
      'application_id': application,
      'scholarship_id': 'sch-1',
      'student_id': 'stud-1',
      'amount_cents': cents,
    });
  }

  @override
  Future<void> recordPayment(
    String application,
    int cents,
    String method,
    String reference,
  ) async {
    final ledger = await load();
    if (cents <= 0 || cents > ledger.outstanding(application)) {
      throw StateError('Amount exceeds outstanding support');
    }
    payments.add({
      'id': 'payment-${payments.length}',
      'application_id': application,
      'amount_cents': cents,
      'method': method,
      'reference': reference,
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> voidPayment(String payment, String reason) async {
    final row = payments.firstWhere((p) => p['id'] == payment);
    if (row['received_at'] != null) {
      throw StateError('Platform review required');
    }
    row['voided_at'] = DateTime.now().toIso8601String();
    row['void_reason'] = reason;
  }

  final reviewRequests = <String, String>{};
  @override
  Future<void> requestReview(String payment, String reason) async {
    reviewRequests[payment] = reason;
  }

  @override
  Future<void> schedule(String application, DateTime? due) async {
    commitments.firstWhere(
      (r) => r['application_id'] == application,
    )['next_due_on'] = due?.toIso8601String().substring(
      0,
      10,
    );
  }

  @override
  Future<void> confirmReceipt(String payment) async =>
      throw StateError('Only the student can confirm receipt');
}

