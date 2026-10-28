// Amounts are integer centavos, never floating-point ledger arithmetic.
int? parsePesoCents(String value) {
  final text = value.trim();
  if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final cents =
      int.parse(parts[0]) * 100 +
      int.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  return cents > 0 && cents <= 100000000000 ? cents : null;
}

String supportMoney(int cents) {
  final whole = (cents.abs() ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  final fraction = cents.abs() % 100;
  return '${cents < 0 ? '−' : ''}₱$whole${fraction == 0 ? '' : '.${fraction.toString().padLeft(2, '0')}'}';
}

class SupportLedger {
  SupportLedger.fromJson(Map<String, dynamic> json)
    : budgets = _rows(json['budgets']),
      commitments = _rows(json['commitments']),
      payments = _rows(json['payments']);
  final List<Map<String, dynamic>> budgets, commitments, payments;
  static List<Map<String, dynamic>> _rows(dynamic value) =>
      (value as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  Map<String, dynamic>? budget(String id) =>
      budgets.where((r) => r['scholarship_id'] == id).firstOrNull;
  Map<String, dynamic>? commitment(String id) =>
      commitments.where((r) => r['application_id'] == id).firstOrNull;
  int committed(String id) => commitments
      .where((r) => r['scholarship_id'] == id)
      .fold(0, (n, r) => n + (r['amount_cents'] as num).toInt());
  int? unallocated(String id) => budget(id) == null
      ? null
      : (budget(id)!['budget_cents'] as num).toInt() - committed(id);
  int sent(String id) => payments
      .where((r) => r['application_id'] == id && r['voided_at'] == null)
      .fold(0, (n, r) => n + (r['amount_cents'] as num).toInt());
  int received(String id) => payments
      .where(
        (r) =>
            r['application_id'] == id &&
            r['received_at'] != null &&
            r['voided_at'] == null,
      )
      .fold(0, (n, r) => n + (r['amount_cents'] as num).toInt());
  int outstanding(String id) =>
      ((commitment(id)?['amount_cents'] as num?)?.toInt() ?? 0) - sent(id);
}

const supportMethods = {
  'bank': 'Bank transfer',
  'gcash': 'GCash',
  'maya': 'Maya',
  'school': 'Direct to school',
  'official_venue': 'Official-venue distribution',
};
