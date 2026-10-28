import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/repositories/support_concern_repository.dart';

class StudentSupportConcerns extends ConsumerStatefulWidget {
  const StudentSupportConcerns({super.key, required this.applicationId});
  final String applicationId;
  @override
  ConsumerState<StudentSupportConcerns> createState() =>
      _StudentSupportConcernsState();
}

class _StudentSupportConcernsState
    extends ConsumerState<StudentSupportConcerns> {
  Future<void> _report() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ReportConcernDialog(applicationId: widget.applicationId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final concerns = ref.watch(supportConcernsProvider(widget.applicationId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help with this scholarship?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Report an unsafe request, a release fee, or a payment problem. Your report details are shared with platform admins, not the provider. Reports are reviewed; this is not a live emergency service.',
            ),
            TextButton.icon(
              onPressed: _report,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Report a problem'),
            ),
            concerns.when(
              loading: () => const Text('Loading your reports…'),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(
                  supportConcernsProvider(widget.applicationId),
                ),
                child: const Text('Reports unavailable. Try again'),
              ),
              data: (rows) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${supportConcernCategories[row['category']]} · ${(row['status'] as String).replaceAll('_', ' ')}',
                          ),
                          if (row['resolution_note'] != null)
                            Text('Admin update: ${row['resolution_note']}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportConcernDialog extends ConsumerStatefulWidget {
  const _ReportConcernDialog({required this.applicationId});
  final String applicationId;
  @override
  ConsumerState<_ReportConcernDialog> createState() =>
      _ReportConcernDialogState();
}

class _ReportConcernDialogState extends ConsumerState<_ReportConcernDialog> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _category = 'payment_not_received';
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(supportConcernRepositoryProvider)
          .report(widget.applicationId, _category, _description.text.trim());
      ref.invalidate(supportConcernsProvider(widget.applicationId));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not submit. Check your existing reports before retrying; one open report per category is allowed.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Report a problem'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share only what admins need to understand the concern. Do not include account passwords, PINs or OTPs. The provider cannot read this report.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Concern'),
                  items: supportConcernCategories.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  enabled: !_busy,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v?.trim().length ?? 0) < 10
                      ? 'Please include at least 10 characters'
                      : null,
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Submitting…' : 'Submit private report'),
        ),
      ],
    ),
  );
}
