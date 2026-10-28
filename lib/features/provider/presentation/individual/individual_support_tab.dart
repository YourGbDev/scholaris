import '../widgets/support_payment_times.dart';
import '../widgets/support_payment_correction.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../models/support_ledger.dart';
import '../../repositories/support_repository.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../org/org_provider_theme.dart';

class IndividualSupportTab extends ConsumerWidget {
  const IndividualSupportTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(supportLedgerProvider);
    final programs = ref.watch(providerScholarshipsProvider);
    final applications = ref.watch(incomingApplicationsProvider);
    final profiles =
        ref.watch(providerApplicantProfilesProvider).valueOrNull ?? {};
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 32),
      children: [
        Text('Budget & support', style: orgHeadline(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          'Know what you have set aside, promised, and recorded as sent.',
          style: orgBody(fontSize: 14, color: kOrgTextSecondary),
        ),
        const SizedBox(height: 24),
        if (ledger.isLoading || programs.isLoading || applications.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (ledger.hasError || programs.hasError || applications.hasError)
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support records could not load',
                  style: orgHeadline(fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check your connection and try again. This workspace also requires the support-ledger database update.',
                ),
                TextButton(
                  onPressed: () {
                    ref.invalidate(supportLedgerProvider);
                    ref.invalidate(providerScholarshipsProvider);
                    ref.invalidate(incomingApplicationsProvider);
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else ...[
          for (final program in programs.valueOrNull ?? <Scholarship>[])
            _program(
              context,
              ref,
              ledger.requireValue,
              program,
              applications.valueOrNull ?? [],
              profiles.map((k, v) => MapEntry(k, v.fullName)),
            ),
          if ((programs.valueOrNull ?? []).isEmpty)
            _panel(
              child: const Text(
                'Create a scholarship first, then set its cycle budget here.',
              ),
            ),
        ],
        const SizedBox(height: 24),
        _panel(
          color: const Color(0xFFEDF2E6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safer ways to support students',
                style: orgHeadline(fontSize: 19),
              ),
              const SizedBox(height: 10),
              const Text(
                'Prefer bank transfer, GCash, Maya, or direct payment to a school. If distribution must be in person, use a school or official public venue with staff present. Never make a private meetup a condition of receiving support.',
              ),
              const SizedBox(height: 10),
              const Text(
                'Never ask for a student’s PIN, password, OTP, or a fee to release an award. Keep account details outside payment references. Students should confirm receipt only after checking their own account or school receipt.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your support assistant', style: orgHeadline(fontSize: 19)),
              const SizedBox(height: 8),
              const Text(
                'Budget insights above are calculated from your records. AI assistance is not connected yet. When enabled, it can help draft program details and explain recorded information; you will still approve every decision. Student private chats will not be shared here.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _program(
    BuildContext context,
    WidgetRef ref,
    SupportLedger ledger,
    Scholarship program,
    List<Application> apps,
    Map<String, String> names,
  ) {
    final budget = ledger.budget(program.id);
    final remaining = ledger.unallocated(program.id);
    final accepted = apps
        .where(
          (a) =>
              a.scholarshipId == program.id &&
              [
                ApplicationStatus.approved,
                ApplicationStatus.awarded,
              ].contains(a.status),
        )
        .toList();
    final missing = accepted
        .where((a) => ledger.commitment(a.id) == null)
        .length;
    final cents = (program.amount * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(program.title, style: orgHeadline(fontSize: 22)),
                OutlinedButton.icon(
                  onPressed: () => _edit(
                    context,
                    ref,
                    kind: 'budget',
                    id: program.id,
                    budget: budget,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    budget == null ? 'Set cycle budget' : 'Edit budget',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              budget?['cycle_label'] as String? ?? 'No cycle budget set',
              style: orgBody(fontSize: 13, color: kOrgTextSecondary),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _metric(
                    'Cycle budget',
                    budget == null
                        ? 'Not set'
                        : supportMoney((budget['budget_cents'] as num).toInt()),
                    constraints.maxWidth,
                  ),
                  _metric(
                    'Committed support',
                    supportMoney(ledger.committed(program.id)),
                    constraints.maxWidth,
                  ),
                  _metric(
                    remaining != null && remaining < 0
                        ? 'Over budget'
                        : 'Unallocated',
                    remaining == null
                        ? 'Set a budget'
                        : supportMoney(remaining),
                    constraints.maxWidth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (remaining != null) ...[
              LinearProgressIndicator(
                value: budget!['budget_cents'] == 0
                    ? 0
                    : (ledger.committed(program.id) /
                              (budget['budget_cents'] as num))
                          .clamp(0.0, 1.0),
                backgroundColor: kOrgBorder,
                color: remaining < 0 ? kOrgError : kOrgPrimary,
                semanticsLabel: 'Budget committed',
              ),
              const SizedBox(height: 12),
              Text(
                remaining < 0
                    ? 'Recorded commitments exceed this budget by ${supportMoney(-remaining)}. Review your funding before making another promise.'
                    : cents > 0
                    ? 'At the current listed award of ${supportMoney(cents)}, this allocation can cover ${remaining ~/ cents} more full awards.'
                    : 'Set a listed award amount to estimate additional support.',
              ),
            ],
            if (missing > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '$missing approved ${missing == 1 ? 'application has' : 'applications have'} no recorded commitment yet. Totals are incomplete until you record the agreed amounts.',
                  style: orgBody(fontSize: 13, color: kOrgError),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Approval commits support; it does not send money. These records are not a bank balance.',
            ),
            const Divider(height: 32),
            Text(
              'Students & payment records',
              style: orgHeadline(fontSize: 18),
            ),
            if (accepted.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Approved students will appear here. No support has been committed yet.',
                ),
              ),
            for (final app in accepted) ...[
              const SizedBox(height: 16),
              Text(
                names[app.userId]?.isNotEmpty == true
                    ? names[app.userId]!
                    : 'Student application',
                style: orgLabel(fontSize: 16),
              ),
              if (ledger.commitment(app.id) == null)
                TextButton(
                  onPressed: () =>
                      _edit(context, ref, kind: 'commitment', id: app.id),
                  child: const Text('Record agreed award'),
                )
              else ...[
                const SizedBox(height: 8),
                Text(
                  'Committed ${supportMoney((ledger.commitment(app.id)!['amount_cents'] as num).toInt())} · Marked sent ${supportMoney(ledger.sent(app.id))} · Student confirmed ${supportMoney(ledger.received(app.id))}',
                ),
                const SizedBox(height: 8),
                if (ledger.outstanding(app.id) == 0)
                  const Text(
                    'Support fully marked sent — no payment remains planned.',
                  ),
                if (ledger.outstanding(app.id) > 0 &&
                    ledger.commitment(app.id)!['next_due_on'] != null)
                  Text(
                    'Planned payment date: ${MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(ledger.commitment(app.id)!['next_due_on'] as String))}',
                  ),
                if (ledger.commitment(app.id)!['next_due_on'] != null)
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(supportRepositoryProvider)
                            .schedule(app.id, null);
                        ref.invalidate(supportLedgerProvider);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not clear the planned date. Try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Clear planned date'),
                  ),
                Text(
                  'Remaining to send: ${supportMoney(ledger.outstanding(app.id))}',
                ),
                if (ledger.outstanding(app.id) > 0)
                  TextButton(
                    onPressed: () async {
                      final due = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(
                              ledger.commitment(app.id)!['next_due_on']
                                      as String? ??
                                  '',
                            ) ??
                            DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 36500),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (due == null) return;
                      try {
                        await ref
                            .read(supportRepositoryProvider)
                            .schedule(app.id, due);
                        ref.invalidate(supportLedgerProvider);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not save the planned date. Please try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Set next payment date'),
                  ),
                if (ledger.outstanding(app.id) > 0)
                  TextButton.icon(
                    onPressed: () => _edit(
                      context,
                      ref,
                      kind: 'payment',
                      id: app.id,
                      maximum: ledger.outstanding(app.id),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Record payment sent'),
                  ),
                for (final payment in ledger.payments.where(
                  (p) => p['application_id'] == app.id,
                ))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${supportMoney((payment['amount_cents'] as num).toInt())} · ${supportMethods[payment['method']] ?? payment['method']} · ${payment['voided_at'] != null
                              ? 'Entered in error'
                              : payment['received_at'] == null
                              ? 'Provider marked sent — awaiting student confirmation'
                              : 'Student confirmed receipt'}\nReference: ${payment['reference']}',
                        ),
                        SupportPaymentTimes(payment: payment),
                        SupportPaymentCorrection(payment: payment),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, double width) => SizedBox(
    width: width < 500 ? width : (width - 32) / 3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: orgBody(fontSize: 12, color: kOrgTextSecondary)),
        const SizedBox(height: 8),
        Text(value, style: orgHeadline(fontSize: 26)),
      ],
    ),
  );
  static Widget _panel({required Widget child, Color color = Colors.white}) =>
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: kOrgBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    required String kind,
    required String id,
    Map<String, dynamic>? budget,
    int? maximum,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SupportRecordDialog(
        kind: kind,
        id: id,
        budget: budget,
        maximum: maximum,
      ),
    );
  }
}

class _SupportRecordDialog extends ConsumerStatefulWidget {
  const _SupportRecordDialog({
    required this.kind,
    required this.id,
    this.budget,
    this.maximum,
  });
  final String kind, id;
  final Map<String, dynamic>? budget;
  final int? maximum;
  @override
  ConsumerState<_SupportRecordDialog> createState() =>
      _SupportRecordDialogState();
}

class _SupportRecordDialogState extends ConsumerState<_SupportRecordDialog> {
  final _form = GlobalKey<FormState>();
  late final _label = TextEditingController(
    text: widget.budget?['cycle_label'] as String? ?? '',
  );
  late final _amount = TextEditingController(
    text: widget.budget == null
        ? ''
        : ((widget.budget!['budget_cents'] as num) / 100).toStringAsFixed(2),
  );
  final _reference = TextEditingController();
  String _method = 'bank';
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final cents = parsePesoCents(_amount.text)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(supportRepositoryProvider);
      if (widget.kind == 'budget') {
        await repo.saveBudget(widget.id, _label.text.trim(), cents);
      } else if (widget.kind == 'commitment') {
        await repo.recordCommitment(widget.id, cents);
      } else {
        await repo.recordPayment(
          widget.id,
          cents,
          _method,
          _reference.text.trim(),
        );
      }
      ref.invalidate(supportLedgerProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not save this record. Refresh and check whether it was saved before trying again.';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.kind == 'budget'
          ? 'Set cycle budget'
          : widget.kind == 'commitment'
          ? 'Record agreed award'
          : 'Record payment sent',
    ),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.kind == 'budget'
                    ? 'This budget covers this scholarship listing’s funding cycle. Create a separate listing for a new cycle.'
                    : widget.kind == 'commitment'
                    ? 'Enter the award amount you already agreed with the student. This becomes a fixed record; changing the listing later will not change it.'
                    : 'Record a payment you have already made. Scholaris does not transfer money or verify your bank balance.',
              ),
              const SizedBox(height: 16),
              if (widget.kind == 'budget') ...[
                TextFormField(
                  controller: _label,
                  enabled: !_busy,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Cycle label',
                    hintText: '2026–2027 academic year',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter a cycle label'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _amount,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount in pesos',
                  prefixText: '₱ ',
                ),
                validator: (v) {
                  final cents = parsePesoCents(v ?? '');
                  if (cents == null) {
                    return 'Enter a positive amount with up to 2 decimal places';
                  }
                  if (widget.maximum != null && cents > widget.maximum!) {
                    return 'Amount exceeds remaining support';
                  }
                  return null;
                },
              ),
              if (widget.kind == 'payment') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                  ),
                  items: supportMethods.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: _busy ? null : (v) => setState(() => _method = v!),
                ),
                if (_method == 'official_venue')
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Use a school or official public venue with staff present. Never require a private meeting, favor, or release fee.',
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reference,
                  enabled: !_busy,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Transaction or school receipt reference',
                    helperText: 'Do not enter account numbers, passwords, PINs or OTPs.',
                    helperMaxLines: 3,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter a reference'
                      : null,
                ),
                const Text(
                  'The student must independently confirm receipt. A payment screenshot alone is not confirmation.',
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: kOrgError),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(
          _busy
              ? 'Saving…'
              : widget.kind == 'payment'
              ? 'Confirm record'
              : 'Save record',
        ),
      ),
    ],
  );
}
