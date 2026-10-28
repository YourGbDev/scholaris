import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/models/support_ledger.dart';

void main() {
  test('approval commitment and sent/confirmed totals remain separate', () {
    final ledger = SupportLedger.fromJson({
      'budgets': [
        {
          'scholarship_id': 's',
          'cycle_label': '2026 semester 1',
          'budget_cents': 10000000,
        },
      ],
      'commitments': [
        {
          'application_id': 'a',
          'scholarship_id': 's',
          'student_id': 'u',
          'amount_cents': 5000000,
        },
      ],
      'payments': [
        {
          'id': 'p',
          'application_id': 'a',
          'amount_cents': 1000000,
          'method': 'gcash',
          'sent_at': '2026-10-23T00:00:00Z',
        },
      ],
    });
    expect(ledger.committed('s'), 5000000);
    expect(ledger.unallocated('s'), 5000000);
    expect(ledger.sent('a'), 1000000);
    expect(ledger.received('a'), 0);
    expect(ledger.outstanding('a'), 4000000);
  });
  test('money accepts decimal pesos exactly and rejects malformed amounts', () {
    expect(parsePesoCents('25000.50'), 2500050);
    for (final value in ['NaN', '-1', '0', '1.001', '1e5', '']) {
      expect(parsePesoCents(value), isNull);
    }
  });
  test(
    'corrected payment remains in history but no longer consumes allocation',
    () {
      final ledger = SupportLedger.fromJson({
        'commitments': [
          {
            'application_id': 'a',
            'scholarship_id': 's',
            'amount_cents': 5000000,
          },
        ],
        'payments': [
          {
            'id': 'valid',
            'application_id': 'a',
            'amount_cents': 1000000,
            'received_at': '2026-10-23',
          },
          {
            'id': 'void',
            'application_id': 'a',
            'amount_cents': 2000000,
            'voided_at': '2026-10-23',
            'void_reason': 'Wrong amount',
          },
        ],
      });
      expect(ledger.payments.length, 2);
      expect(ledger.sent('a'), 1000000);
      expect(ledger.received('a'), 1000000);
      expect(ledger.outstanding('a'), 4000000);
    },
  );
}
