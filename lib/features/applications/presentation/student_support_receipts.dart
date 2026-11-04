import '../../provider/presentation/widgets/support_payment_times.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/models/support_ledger.dart';
import '../../provider/repositories/support_repository.dart';

/// Receipt acknowledgement is separate from provider claims and bank verification.
class StudentSupportReceipts extends ConsumerWidget {
  const StudentSupportReceipts({super.key, required this.applicationId});
  final String applicationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(supportLedgerProvider);
    if (ledger.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Checking support records…'),
      );
    }
    if (ledger.hasError) {
      return TextButton(
        onPressed: () => ref.invalidate(supportLedgerProvider),
        child: const Text('Support records unavailable. Try again'),
      );
    }
    final payments = ledger.requireValue.payments
        .where((p) => p['application_id'] == applicationId)
        .toList();
    if (payments.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support payments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your own bank, e-wallet, or school receipt before confirming. Never share a PIN or OTP, pay a release fee, or agree to a private meeting to receive an award.',
            ),
            for (final payment in payments) ...[
              const Divider(height: 28),
              Text(
                '${supportMoney((payment['amount_cents'] as num).toInt())} · ${supportMethods[payment['method']] ?? payment['method']}',
              ),
              Text('Reference: ${payment['reference']}'),
              SupportPaymentTimes(payment: payment),
              if (payment['voided_at'] != null)
                Text(
                  'Entered in error: ${payment['void_reason']}. This does not confirm a refund or transfer.',
                )
              else if (payment['received_at'] != null)
                const Text(
                  'You confirmed receipt. This is not bank verification.',
                )
              else
                _ReceiptButton(payment: payment),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptButton extends ConsumerStatefulWidget {
  const _ReceiptButton({required this.payment});
  final Map<String, dynamic> payment;
  @override
  ConsumerState<_ReceiptButton> createState() => _ReceiptButtonState();
}

class _ReceiptButtonState extends ConsumerState<_ReceiptButton> {
  bool busy = false;
  String? error;
  Future<void> confirm() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Have you received this support?'),
        content: Text(
          'Confirm only if you personally received ${supportMoney((widget.payment['amount_cents'] as num).toInt())}. If you have not received it, choose Not yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, received'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .confirmReceipt(widget.payment['id'] as String);
      ref.invalidate(supportLedgerProvider);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not confirm receipt. Please try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Provider marked this as sent. Receipt is not confirmed.'),
      TextButton(
        onPressed: busy ? null : confirm,
        child: Text(busy ? 'Confirming…' : 'Confirm receipt'),
      ),
      if (error != null) Text(error!),
    ],
  );
}

