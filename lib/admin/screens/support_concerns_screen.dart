import '../../shared/theme/app_motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/provider/repositories/support_concern_repository.dart';
import '../../features/provider/repositories/support_repository.dart';
import '../../features/provider/models/support_ledger.dart';
import '../../features/provider/presentation/widgets/support_payment_correction.dart';
import '../../features/provider/presentation/widgets/support_payment_times.dart';

class SupportConcernsScreen extends ConsumerWidget {
  const SupportConcernsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concerns = ref.watch(supportConcernsProvider(null));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Support concerns',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Private student reports and provider payment review requests. Review the facts and update the reporter; requests do not automatically change access, decisions or payments.',
        ),
        const SizedBox(height: 24),
        concerns.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Column(
            children: [
              const Text('Could not load concerns.'),
              TextButton(
                onPressed: () => ref.invalidate(supportConcernsProvider(null)),
                child: const Text('Try again'),
              ),
            ],
          ),
          data: (rows) => Column(
            children: [
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No support concerns have been reported.'),
                ),
              for (final row in rows) _ConcernCard(row: row),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConcernCard extends ConsumerStatefulWidget {
  const _ConcernCard({required this.row});
  final Map<String, dynamic> row;
  @override
  ConsumerState<_ConcernCard> createState() => _ConcernCardState();
}

class _ConcernCardState extends ConsumerState<_ConcernCard> {
  bool _busy = false;
  bool _expanded = false;
  Future<void> _update(String status) async {
    final providerRequest =
        widget.row['category'] == 'payment_record_correction';
    var note = '';
    final form = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          status == 'under_review'
              ? 'Start review'
              : status == 'resolved'
              ? 'Resolve concern'
              : 'Close without action',
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This update is visible to the ${providerRequest ? 'provider' : 'student'}. Explain the next step or outcome. It does not automatically suspend a provider or reverse a payment.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onChanged: (v) => note = v,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: providerRequest
                          ? 'Update for provider'
                          : 'Update for student',
                    ),
                    validator: (v) => (v?.trim().length ?? 0) < 10
                        ? 'Include at least 10 characters'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, note.trim());
              }
            },
            child: const Text('Save update'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(supportConcernRepositoryProvider)
          .review(widget.row['id'] as String, status, result);
      ref.invalidate(supportConcernsProvider(null));
      ref.invalidate(
        supportConcernsProvider(widget.row['application_id'] as String),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update the concern. Refresh before retrying.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final closed = ['resolved', 'dismissed'].contains(row['status']);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        expansionAnimationStyle: AnimationStyle(
          duration: isReducedMotion(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
        ),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        title: Text(
          row['category'] == 'payment_record_correction'
              ? 'Provider payment correction request'
              : supportConcernCategories[row['category']] ?? 'Support concern',
        ),
        subtitle: Text((row['status'] as String).replaceAll('_', ' ')),
        childrenPadding: const EdgeInsets.all(20),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            'Application: ${row['application_id']}\nReporter: ${row['reporter_id']}',
          ),
          const SizedBox(height: 12),
          SelectableText(row['description'] as String),
          if (row['resolution_note'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Latest update: ${row['resolution_note']}'),
            ),
          if (!closed)
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _update('under_review'),
                  child: const Text('Start review'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _update('resolved'),
                  child: const Text('Resolve'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _update('dismissed'),
                  child: const Text('Close without action'),
                ),
              ],
            ),
          if (_expanded)
            _ConcernPayments(
              application: row['application_id'] as String,
              paymentId: row['payment_id'] as String?,
            ),
        ],
      ),
    );
  }
}

class _ConcernPayments extends ConsumerWidget {
  const _ConcernPayments({required this.application, this.paymentId});
  final String application;
  final String? paymentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(supportLedgerProvider)
      .when(
        loading: () => const Text('Loading related payment records…'),
        error: (_, _) => TextButton(
          onPressed: () => ref.invalidate(supportLedgerProvider),
          child: const Text('Payment records unavailable. Retry'),
        ),
        data: (ledger) {
          final payments = ledger.payments
              .where(
                (p) =>
                    p['application_id'] == application &&
                    (paymentId == null || p['id'] == paymentId),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 24),
              Text(
                paymentId == null
                    ? 'Related payment records'
                    : 'Requested payment record',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (payments.isEmpty)
                const Text(
                  'No recorded support payments for this application.',
                ),
              for (final p in payments)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('Payment ID: ${p['id']}'),
                      Text(
                        '${supportMoney((p['amount_cents'] as num).toInt())} · ${p['reference']}',
                      ),
                      Text(
                        p['received_at'] == null
                            ? 'Student receipt not confirmed'
                            : 'Student confirmed receipt',
                      ),
                      SupportPaymentTimes(payment: p),
                      SupportPaymentCorrection(payment: p, admin: true),
                    ],
                  ),
                ),
            ],
          );
        },
      );
}
