// lib/features/applications/presentation/application_detail_screen.dart
//
// First-class application-level detail surface. Reached by tapping an
// application card in the tracking surface; it focuses on the application
// itself (status, application date, scholarship deadline, notes) rather than
// the scholarship, while still providing a clear path back to the scholarship
// detail.
//
// Rebuilt to match Stitch design language with crisp white cards, 16px corner
// radius, and subtle borders.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';
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
            icon: Icons.search_off_rounded,
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Withdraw application?'),
        content: Text(
          'You are about to withdraw your application for '
          '"${widget.scholarship?.title ?? 'this scholarship'}". '
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
    } on Exception catch (e, st) {
      debugPrint('[WITHDRAW ERROR] $e\n$st');
      if (!mounted) return;
      final errorStr = e.toString().toLowerCase();
      final msg = errorStr.contains('check constraint') || errorStr.contains('applications_status_check')
          ? 'Database migration pending for withdrawal status.'
          : 'Could not withdraw your application. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
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
    ref.watch(applicationsProvider);
    final application = widget.application;
    final scholarship = widget.scholarship;
    final scholarshipKnown = scholarship != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        if (scholarshipKnown)
          Semantics(
            button: true,
            label: 'View scholarship details',
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openScholarship,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x081B3A5C),
                        blurRadius: 12,
                        offset: Offset(0, 4),
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
                              scholarship.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              scholarship.provider ?? 'Scholarship provider',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: const Color(0xFF404942),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF707971),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
            ),
            child: Text(
              'This scholarship is no longer active.',
              style: GoogleFonts.openSans(fontSize: 14, color: const Color(0xFF404942)),
            ),
          ),
        const SizedBox(height: 14),
        if (application.status == ApplicationStatus.rejected) ...[
          _RejectedConsolingBanner(
            programName: scholarship?.title ?? 'Scholarship Program',
            reason: application.notes,
          ),
          const SizedBox(height: 14),
        ],
        _StatusSection(application: application),
        if (application.status == ApplicationStatus.draft && scholarshipKnown) ...[
          const SizedBox(height: 14),
          _ContinueApplicationCard(onContinue: _openScholarship),
        ],
        const SizedBox(height: 14),
        _FactsCard(application: application, scholarship: scholarship),
        const SizedBox(height: 14),
        _NotesCard(
          controller: _notesController,
          saving: _savingNotes,
          onSave: _saveNotes,
        ),
        const SizedBox(height: 14),
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
    final isCelebratory = application.status == ApplicationStatus.approved ||
        application.status == ApplicationStatus.awarded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isCelebratory)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: MascotPoseView(
                pose: MascotPose.celebrating,
                height: 48,
                width: 48,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ui.background,
                shape: BoxShape.circle,
              ),
              child: Icon(ui.icon, color: ui.foreground, size: 22),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF707971)),
                ),
                const SizedBox(height: 2),
                Text(
                  ui.label,
                  style: GoogleFonts.poppins(
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

class _RejectedConsolingBanner extends StatelessWidget {
  const _RejectedConsolingBanner({
    required this.programName,
    this.reason,
  });

  final String programName;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B3A5C),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const MascotPoseView(
            pose: MascotPose.consoling,
            height: 120,
          ),
          const SizedBox(height: 14),
          Text(
            '"Hindi ito ang katapusan."',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF161C27),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This isn't the end of the road.",
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF404942),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kError.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$programName — Not Selected',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFBA1A1A),
              ),
            ),
          ),
          if (reason != null && reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason!.trim(),
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 12.5,
                color: const Color(0xFF707971),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/discover'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'See other scholarships you may qualify for',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
            scholarship!.slots == null
                ? 'Slots not specified'
                : '${scholarship!.slots} slot(s)'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application details',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF161C27),
            ),
          ),
          const SizedBox(height: 12),
          for (final fact in facts) ...[
            Row(
              children: [
                Icon(fact.$1, size: 16, color: kPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fact.$2,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: const Color(0xFF404942),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF161C27),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Private notes only you can see.',
            style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF707971)),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('application-notes-field'),
            controller: controller,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            style: GoogleFonts.openSans(fontSize: 13.5, color: const Color(0xFF161C27)),
            decoration: InputDecoration(
              hintText: 'Add notes about this application…',
              hintStyle: GoogleFonts.openSans(fontSize: 13.5, color: const Color(0xFF707971)),
              filled: true,
              fillColor: const Color(0xFFF1F3FF),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kPrimary, width: 1.5),
              ),
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
        color: const Color(0xFFFFF0ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kError.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Withdraw application',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kError,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'If you no longer want to pursue this scholarship, you can '
            'withdraw. It will stay in your history as Withdrawn.',
            style: GoogleFonts.openSans(fontSize: 13, color: const Color(0xFF404942)),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: kPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.openSans(fontSize: 13, color: kPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueApplicationCard extends StatelessWidget {
  const _ContinueApplicationCard({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B3A5C),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 20, color: kPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Draft In Progress',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kOnSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'This application has not been submitted yet. Complete and submit your application packet before the deadline.',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: const Color(0xFF404942),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('detail-continue-application'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                'Continue Application',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
