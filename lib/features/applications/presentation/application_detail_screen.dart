// lib/features/applications/presentation/application_detail_screen.dart
//
// First-class application-level detail surface. Reached by tapping an
// application card in the tracking surface; it focuses on the application
// itself (status, application date, scholarship deadline, notes) rather than
// the scholarship, while still providing a clear path back to the scholarship
// detail.
//
// The screen stays reactive: it reads the latest application from
// [applicationsProvider], so a withdrawal or a notes save performed here is
// reflected immediately (and the screen itself re-renders).
//
// Lifecycle:
//  - pending (draft / submitted / under review) applications offer a
//    "Withdraw application" action that requires explicit confirmation;
//  - terminal applications (approved / rejected / withdrawn) show the status
//    with no withdrawal affordance.
//
// Notes editing is intentionally simple: a plain text field and a Save button
// that persists through the repository and updates provider state. Saving only
// touches the notes column — never the status or other fields.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/primary_button.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'application_status_chip.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
    this.initial,
  });

  final String applicationId;
  final Application? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Application')),
      body: ResponsiveContainer(child: _buildBody(context, ref)),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

    return applicationsAsync.when(
      loading: () => const LoadingView(),
      error: (_, _) => ErrorView(
        message: 'Could not load your application.',
        onRetry: () => ref.invalidate(applicationsProvider),
      ),
      data: (applications) {
        final application = applications
                .where((a) => a.id == applicationId)
                .firstOrNull ??
            initial;
        if (application == null) {
          return const EmptyView(
            icon: Icons.article_outlined,
            title: 'Application not found',
            message: 'This application is no longer available.',
          );
        }

        return scholarshipsAsync.when(
          loading: () => const LoadingView(),
          error: (_, _) => ErrorView(
            message: 'Could not load scholarship details.',
            onRetry: () => ref.invalidate(scholarshipsProvider),
          ),
          data: (all) {
            Scholarship? scholarship;
            for (final s in all) {
              if (s.id == application.scholarshipId) {
                scholarship = s;
                break;
              }
            }
            return _DetailBody(application: application, scholarship: scholarship);
          },
        );
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.application, required this.scholarship});

  final Application application;
  final Scholarship? scholarship;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  late final TextEditingController _notesController;
  bool _savingNotes = false;
  bool _withdrawing = false;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.application.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    final notes = _notesController.text.trim();
    setState(() => _savingNotes = true);
    try {
      await ref
          .read(applicationsProvider.notifier)
          .updateNotes(widget.application.id, notes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved.')),
      );
    } on ApplicationNotAuthenticatedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save notes.')),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your notes. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _savingNotes = false);
    }
  }

  Future<void> _confirmWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw application?'),
        content: Text(
          'You are about to withdraw your application for '
          '"${widget.scholarship?.name ?? 'this scholarship'}". '
          'Withdrawal is permanent, but the application stays in your '
          'history under Withdrawn.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('withdraw-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('withdraw-confirm'),
            style: TextButton.styleFrom(foregroundColor: kError),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _withdrawing = true);
    try {
      await ref
          .read(applicationsProvider.notifier)
          .withdraw(widget.application.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application withdrawn.')),
      );
    } on ApplicationWithdrawalException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This application can no longer be withdrawn.'),
        ),
      );
    } on ApplicationNotAuthenticatedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to withdraw.')),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not withdraw your application. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  void _openScholarship() {
    final scholarship = widget.scholarship;
    if (scholarship == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScholarshipDetailScreen(
          scholarshipId: scholarship.id,
          initial: scholarship,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the application changes (e.g. after a withdrawal) so the
    // status chip and lifecycle actions stay accurate.
    ref.watch(applicationsProvider);
    final application = widget.application;
    final scholarship = widget.scholarship;
    final scholarshipKnown = scholarship != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        if (scholarshipKnown)
          Semantics(
            button: true,
            label: 'View scholarship details',
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadiusCard),
              child: InkWell(
                borderRadius: BorderRadius.circular(kRadiusCard),
                onTap: _openScholarship,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    boxShadow: const [
                      BoxShadow(
                        color: kPrimarySoft,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scholarship.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              scholarship.provider ?? 'Scholarship provider',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: openSans(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadiusCard),
            ),
            child: Text(
              'This scholarship is no longer active.',
              style: openSans(fontSize: 14, color: Colors.black54),
            ),
          ),
        const SizedBox(height: 16),
        _StatusSection(application: application),
        const SizedBox(height: 16),
        _FactsCard(application: application, scholarship: scholarship),
        const SizedBox(height: 16),
        _NotesCard(
          controller: _notesController,
          saving: _savingNotes,
          onSave: _saveNotes,
        ),
        const SizedBox(height: 16),
        if (application.status.isPending)
          _WithdrawCard(withdrawing: _withdrawing, onWithdraw: _confirmWithdraw)
        else
          _TerminalNote(application: application),
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final ui = ApplicationStatusUi.of(application.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ui.background,
              shape: BoxShape.circle,
            ),
            child: Icon(ui.icon, size: 22, color: ui.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: openSans(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  ui.label,
                  style: poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ui.foreground,
                  ),
                ),
              ],
            ),
          ),
          ApplicationStatusChip(status: application.status),
        ],
      ),
    );
  }
}

class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.application, required this.scholarship});

  final Application application;
  final Scholarship? scholarship;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String)>[
      if (application.appliedAt != null)
        (Icons.send_rounded, 'Applied ${_formatDate(application.appliedAt!)}'),
      if (scholarship != null)
        (Icons.event_rounded, deadlineLabel(scholarship!.deadline)),
      if (scholarship != null)
        (Icons.account_balance_wallet_outlined,
            formatPeso(scholarship!.amount)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application details',
            style: poppins(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          for (final fact in facts) ...[
            Row(
              children: [
                Icon(fact.$1, size: 18, color: kPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fact.$2,
                    style: openSans(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: poppins(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Private notes only you can see.',
            style: openSans(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('application-notes-field'),
            controller: controller,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Add notes about this application…',
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: saving ? 'Saving…' : 'Save notes',
            onPressed: saving ? null : onSave,
          ),
        ],
      ),
    );
  }
}

class _WithdrawCard extends StatelessWidget {
  const _WithdrawCard({required this.withdrawing, required this.onWithdraw});

  final bool withdrawing;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE8E6),
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kError.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Withdraw application',
            style: poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kError,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'If you no longer want to pursue this scholarship, you can '
            'withdraw. It will stay in your history as Withdrawn.',
            style: openSans(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('withdraw-action'),
              onPressed: withdrawing ? null : onWithdraw,
              icon: withdrawing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.unsubscribe_rounded),
              label: const Text('Withdraw application'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kError,
                side: const BorderSide(color: kError),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalNote extends StatelessWidget {
  const _TerminalNote({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final message = switch (application.status) {
      ApplicationStatus.approved => 'This application has been approved. No '
          'further action is available.',
      ApplicationStatus.rejected => 'This application was not approved. '
          'It is kept here for your records.',
      ApplicationStatus.withdrawn => 'You withdrew this application. It is '
          'kept in your history for your records.',
      _ => '',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: kPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: openSans(fontSize: 13, color: kPrimary)),
          ),
        ],
      ),
    );
  }
}
