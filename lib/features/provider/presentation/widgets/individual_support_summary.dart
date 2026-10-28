import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/support_ledger.dart';
import '../../repositories/support_repository.dart';
import '../org/org_provider_theme.dart';

class IndividualSupportSummary extends ConsumerWidget {
  const IndividualSupportSummary({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(supportLedgerProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kOrgBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your support at a glance', style: orgHeadline(fontSize: 18)),
          const SizedBox(height: 8),
          ledger.when(
            loading: () => const Text('Loading your support records…'),
            error: (_, _) => const Text(
              'Support records are unavailable. Open Budget & support to retry.',
            ),
            data: (data) {
              final committed = data.commitments.fold<int>(
                0,
                (n, r) => n + (r['amount_cents'] as num).toInt(),
              );
              final sent = data.payments
                  .where((p) => p['voided_at'] == null)
                  .fold<int>(
                    0,
                    (n, r) => n + (r['amount_cents'] as num).toInt(),
                  );
              return Text(
                '${supportMoney(committed)} recorded commitments · ${supportMoney(sent)} marked sent',
              );
            },
          ),
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Open Budget & support'),
          ),
        ],
      ),
    );
  }
}
