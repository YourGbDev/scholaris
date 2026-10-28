// Platform provider-review presentation. Decisions use the existing repository;
// returned-row checks and new review states require the backend handoff.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/provider/models/provider_verification.dart';
import 'package:scholaris/features/provider/providers/provider_verification_provider.dart';

const _green = Color(0xFF0F4D2E);

class AdminProvidersTab extends ConsumerStatefulWidget {
  const AdminProvidersTab({super.key});
  @override
  ConsumerState<AdminProvidersTab> createState() => _AdminProvidersTabState();
}

class _AdminProvidersTabState extends ConsumerState<AdminProvidersTab> {
  String _status = 'pending', _type = 'all', _query = '';
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminProviderVerificationsProvider);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Provider approvals',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _green,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh queue',
                      onPressed: () =>
                          ref.invalidate(adminProviderVerificationsProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review organization and individual submissions. Pending submissions appear oldest first.',
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    labelText: 'Search name or contact',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Review status'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final status in [
                      'pending',
                      'changes_requested',
                      'all',
                      'approved',
                      'rejected',
                    ])
                      ChoiceChip(
                        label: Text(
                          {
                            'pending': 'Pending',
                            'changes_requested': 'Changes requested',
                            'all': 'All statuses',
                            'approved': 'Approved',
                            'rejected': 'Rejected',
                          }[status]!,
                        ),
                        selected: _status == status,
                        onSelected: (_) => setState(() => _status = status),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Provider type'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final type in ['all', 'organization', 'individual'])
                      ChoiceChip(
                        label: Text(
                          {
                            'all': 'Both provider types',
                            'organization': 'Organization',
                            'individual': 'Individual',
                          }[type]!,
                        ),
                        selected: _type == type,
                        onSelected: (_) => setState(() => _type = type),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        data.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (_, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('Could not load provider submissions. Try again.'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(adminProviderVerificationsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (rows) {
            final filtered = rows
                .where(
                  (v) =>
                      (_status == 'all' || v.status == _status) &&
                      (_type == 'all' || v.providerType == _type) &&
                      [
                        v.displayName,
                        v.email ?? '',
                        v.repName ?? '',
                        v.repEmail ?? '',
                      ].any((value) => value.toLowerCase().contains(_query)),
                )
                .toList();
            filtered.sort((a, b) {
              if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
              if (a.submittedAt == null) return b.submittedAt == null ? 0 : 1;
              if (b.submittedAt == null) return -1;
              return a.isPending
                  ? a.submittedAt!.compareTo(b.submittedAt!)
                  : b.submittedAt!.compareTo(a.submittedAt!);
            });
            if (filtered.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No submissions match these filters. Try another status, provider type or search.',
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final v = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.displayName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${v.providerType == 'organization' ? 'Organization' : 'Individual'} • ${_statusLabel(v.status)}',
                          ),
                          Text('Submitted: ${_date(v.submittedAt)}'),
                          Text(v.email ?? v.repEmail ?? 'Contact not provided'),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            key: ValueKey('review-${v.userId}'),
                            onPressed: () => showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) =>
                                  _ProviderReviewDialog(verification: v),
                            ),
                            child: const Text('Review'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

String _date(DateTime? date) => date == null
    ? 'Not recorded'
    : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String _statusLabel(String status) => switch (status) {
  'pending' => 'Pending review',
  'approved' => 'Approved',
  'rejected' => 'Rejected',
  'changes_requested' => 'Changes requested',
  _ => status,
};

class _ProviderReviewDialog extends ConsumerStatefulWidget {
  const _ProviderReviewDialog({required this.verification});
  final ProviderVerification verification;
  @override
  ConsumerState<_ProviderReviewDialog> createState() =>
      _ProviderReviewDialogState();
}

class _ProviderReviewDialogState extends ConsumerState<_ProviderReviewDialog> {
  final _note = TextEditingController();
  bool _busy = false;
  bool _saving = false;
  String? _error;
  final Set<String> _opening = {};
  @override
  void initState() {
    super.initState();
    _note.text = widget.verification.reviewNote ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _decide(String status) async {
    if (_busy || !widget.verification.isPending) return;
    final note = _note.text.trim();
    if (note.length < 10 || note.length > 1000) {
      setState(
        () => _error =
            'Explain the evidence reviewed and the reason for this decision.',
      );
      return;
    }
    final actor = ref.read(currentUserIdProvider);
    if (actor == null || actor.isEmpty) {
      setState(() => _error = 'Sign in again before making a decision.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final action = status == 'approved'
          ? 'Approve'
          : status == 'changes_requested'
              ? 'Request changes from'
              : 'Reject';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          scrollable: true,
          title: Text('$action provider?'),
          content: Text(
            status == 'changes_requested'
                ? 'Request changes from ${widget.verification.displayName}? The provider will be notified of your note and can resubmit with updated documents.'
                : '$action ${widget.verification.displayName}? This saves the review decision and note. Approval is not independent verification of funds or credentials.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Confirm ${status == 'approved' ? 'Approve' : (status == 'changes_requested' ? 'Request changes' : 'Reject')}',
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (ref.read(currentUserIdProvider) != actor) {
        setState(
          () => _error =
              'Your session changed. Sign in again before making a decision.',
        );
        return;
      }
      setState(() => _saving = true);
      final notifier = ref.read(adminProviderVerificationsProvider.notifier);
      ProviderVerification updated;
      if (status == 'approved') {
        updated = await notifier.approveVerification(
          userId: widget.verification.userId,
          adminId: actor,
          note: note,
          expectedStatus: widget.verification.status,
        );
      } else if (status == 'changes_requested') {
        updated = await notifier.requestChangesVerification(
          userId: widget.verification.userId,
          adminId: actor,
          note: note,
          expectedStatus: widget.verification.status,
        );
      } else {
        updated = await notifier.rejectVerification(
          userId: widget.verification.userId,
          adminId: actor,
          note: note,
          expectedStatus: widget.verification.status,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Decision recorded: ${updated.status.replaceAll('_', ' ').toUpperCase()} for ${widget.verification.displayName}.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save the decision. Your note is preserved. Try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _saving = false;
        });
      }
    }
  }

  Future<void> _openDocument(String label, String path) async {
    if (_opening.contains(path)) return;
    setState(() {
      _opening.add(path);
      _error = null;
    });
    try {
      final url = await ref
          .read(providerVerificationRepositoryProvider)
          .getSignedUrl(path);
      if (!mounted) return;
      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Document unavailable');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open $label. Try again.');
    } finally {
      if (mounted) setState(() => _opening.remove(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.verification,
        org = widget.verification.providerType == 'organization';
    final actor = ref.watch(currentUserIdProvider);
    final canDecide =
        !_busy && v.isPending && actor != null && actor.isNotEmpty;
    return PopScope(
      canPop: !_busy,
      child: FocusScope(
        autofocus: true,
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Dialog(
            insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          org
                              ? 'Organization review'
                              : 'Individual provider review',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close review',
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    v.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${_statusLabel(v.status)} • Submitted ${_date(v.submittedAt)}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Submitted information',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                  const Text(
                    'These are provider declarations and uploads. Their presence does not establish authenticity or available funding.',
                  ),
                  if (org) ...[
                    _info('Organization type', v.orgType),
                    _info('Registration number (masked)', v.maskedIdNumber),
                    _info('Representative', v.repName),
                    _info('Position', v.repPosition),
                    _info('Email', v.repEmail),
                    _info('Phone', v.repPhone),
                  ] else ...[
                    _info('Email', v.email),
                    _info('Phone', v.phone),
                    _info('Government ID type', v.govIdType),
                    _info('ID number (masked)', v.maskedIdNumber),
                    _info('Stated source of funds', v.sourceOfFunds),
                    _info('Proposed giving budget', v.monthlyGivingBudget),
                    _info('TIN (masked)', v.maskedTin),
                  ],
                  const Divider(height: 32),
                  const Text(
                    'Submitted documents',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                  const Text(
                    'Available files open through a temporary private link. Review their contents before deciding.',
                  ),
                  if (org) ...[
                    _document('SEC certificate', v.secCertPath),
                    _document('BIR Form 2303', v.bir2303Path),
                    _document('Board resolution', v.boardResolutionPath),
                  ] else ...[
                    _document('Government ID (front)', v.govIdFrontPath),
                    _document('Selfie with ID', v.selfieIdPath),
                  ],
                  const Divider(height: 32),
                  TextField(
                    controller: _note,
                    enabled: !_busy && v.isPending,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Review note (required)',
                      helperText: '10–1000 characters. Explain the evidence reviewed and your decision.',
                      helperMaxLines: 4,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFF93000A)),
                        ),
                      ),
                    ),
                  if (actor == null || actor.isEmpty)
                    const Text('Sign in again before making a decision.'),
                  if (!v.isPending)
                    const Text(
                      'This submission has already been reviewed. Decisions are available only for pending submissions.',
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Review note is required for Request changes and Rejection. It will be sent to the provider.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: canDecide
                            ? () => _decide('changes_requested')
                            : null,
                        child: const Text('Request changes'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF93000A),
                        ),
                        onPressed: canDecide ? () => _decide('rejected') : null,
                        child: const Text('Reject'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        onPressed: canDecide ? () => _decide('approved') : null,
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(
                        semanticsLabel: 'Saving review decision',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _info(String label, String? value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF555D58))),
        SelectableText(
          value?.trim().isNotEmpty == true ? value! : 'Not provided',
        ),
      ],
    ),
  );
  Widget _document(String label, String? path) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        if (path == null || path.isEmpty)
          const Text('Not provided')
        else
          TextButton.icon(
            onPressed: _busy || _opening.contains(path)
                ? null
                : () => _openDocument(label, path),
            icon: const Icon(Icons.open_in_new),
            label: Text(
              _opening.contains(path) ? 'Opening document…' : 'Open document',
            ),
          ),
      ],
    ),
  );
}
