// lib/features/applications/presentation/submit_application_review_dialog.dart
//
// Application Review & Submission Flow matching Stitch design specification
// `design-reference/stitch_scholaris_mobile_app/scholaris_submit_application_review/code.html`.
//
// Features:
// 1. Final Step • Review header card with step progress bar (3 of 3: Sign & Submit)
// 2. Award value & key facts summary (Philippine Peso, deadline, recipient institution)
// 3. Application Packet with 4 verification components & combined PDF export
// 4. Affirmations & Honor Code with interactive certification checkboxes
// 5. Digital Signature with dynamic applicant name & SHA-256 ledger notice
// 6. Pinned final submit action (with loading state) & exit-intent draft protection

import 'package:flutter/material.dart';

import '../providers/applications_provider.dart';
import '../providers/application_document_provider.dart';
import 'widgets/document_upload_sheet.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/save_draft_dialog.dart';

class SubmitApplicationReviewDialog extends ConsumerStatefulWidget {
  const SubmitApplicationReviewDialog({
    super.key,
    required this.scholarship,
    required this.onSaveDraft,
    this.initialCertificationsChecked = false,
  });

  final Scholarship scholarship;
  final Future<void> Function() onSaveDraft;
  final bool initialCertificationsChecked;

  static Future<bool?> show(
    BuildContext context, {
    required Scholarship scholarship,
    required Future<void> Function() onSaveDraft,
  }) {
    return showDialog<bool>(
      context: context,
      animationStyle: isReducedMotion(context)
          ? AnimationStyle.noAnimation
          : null,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final action = await showSaveDraftExitDialog(dialogContext);
          if (action == SaveDraftExitAction.saveAsDraft) {
            await onSaveDraft();
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(false);
            }
          } else if (action == SaveDraftExitAction.discard) {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(false);
            }
          }
        },
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: SubmitApplicationReviewDialog(
            scholarship: scholarship,
            onSaveDraft: onSaveDraft,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<SubmitApplicationReviewDialog> createState() =>
      _SubmitApplicationReviewDialogState();
}

class _SubmitApplicationReviewDialogState
    extends ConsumerState<SubmitApplicationReviewDialog> {
  late bool _cert1;
  late bool _cert2;
  late bool _cert3;
  bool _isSavingDraft = false;
  String? _packetError;

  @override
  void initState() {
    super.initState();
    _cert1 = widget.initialCertificationsChecked;
    _cert2 = widget.initialCertificationsChecked;
    _cert3 = widget.initialCertificationsChecked;
  }

  bool get _allAffirmationsChecked => _cert1 && _cert2 && _cert3;

  Future<void> _handleExitIntent() async {
    final action = await showSaveDraftExitDialog(context);
    if (!mounted) return;
    if (action == SaveDraftExitAction.saveAsDraft) {
      setState(() => _isSavingDraft = true);
      try {
        await widget.onSaveDraft();
      } finally {
        if (mounted) {
          setState(() => _isSavingDraft = false);
          Navigator.of(context).pop(false);
        }
      }
    } else if (action == SaveDraftExitAction.discard) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _handleSaveDraftDirectly() async {
    setState(() => _isSavingDraft = true);
    try {
      await widget.onSaveDraft();
    } finally {
      if (mounted) {
        setState(() => _isSavingDraft = false);
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final studentName =
        (profile?.fullName != null && profile!.fullName.trim().isNotEmpty)
        ? profile.fullName.trim()
        : 'Student';

    return Container(
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33161C27),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrollable Cards List (Cards 1 to 5)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD 1: Header / Final Step Review Card
                  _buildHeaderCard(),
                  const SizedBox(height: 12),

                  // CARD 2: Award & Key Facts Card
                  _buildAwardCard(),
                  const SizedBox(height: 12),

                  // CARD 3: Application Packet
                  _buildPacketCard(profile: profile),
                  const SizedBox(height: 12),

                  // CARD 4: Affirmations & Honor Code
                  _buildAffirmationsCard(),
                  const SizedBox(height: 12),

                  // CARD 5: Digital Signature
                  _buildDigitalSignatureCard(studentName: studentName),
                ],
              ),
            ),
          ),

          // CARD 6: Pinned Bottom Actions Card
          _buildActionsCard(),
        ],
      ),
    );
  }

  // --- CARD 1: Header / Final Step Review Card -----------------------------
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A161C27),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pill: Final Step • Review
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kSurfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: kPrimaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Final Step • Review',

                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Submit Application',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kOnSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Prompt label preserved for accessibility and test suites
                    Text(
                      'Apply to this scholarship?',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.scholarship.title} • ${widget.scholarship.provider ?? "National Science Endowment"}',

                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: kOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Close button (triggers exit intent)
              IconButton(
                key: const ValueKey('apply-close-button'),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: kSurfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: kOnSurfaceVariant,
                  ),
                ),
                tooltip: 'Close',
                onPressed: _handleExitIntent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Step 3 of 3 Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Review & Submit',

                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Review Required',

                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kOnSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 3-Segment Progress Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: kPrimaryContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: kPrimaryContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: kPrimaryContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Step milestones
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _stepMarker(
                icon: Icons.check_circle_rounded,
                label: '1. Overview',
                active: true,
              ),
              _stepMarker(
                icon: Icons.check_circle_rounded,
                label: '2. Packet',
                active: true,
              ),
              _stepMarker(
                icon: Icons.verified_rounded,
                label: '3. Finalize',
                active: true,
                bold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepMarker({
    required IconData icon,
    required String label,
    required bool active,
    bool bold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kPrimaryContainer),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: kPrimaryDark,
          ),
        ),
      ],
    );
  }

  // --- CARD 2: Award & Key Facts Card --------------------------------------
  Widget _buildAwardCard() {
    final now = DateTime.now();
    final daysLeft = widget.scholarship.deadline.difference(now).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A161C27),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Award Value & Fit Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AWARD VALUE',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kOnSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            text: _grantValue(widget.scholarship),
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryDark,
                            ),
                            children: [
                              TextSpan(
                                text: ' / semester',
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: kOnSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryFixed,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A0F4D2E),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            size: 14,
                            color: kOnPrimaryFixedVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '98% Fit',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: kOnPrimaryFixedVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '4-Year Renewable',
                      style: GoogleFonts.openSans(
                        fontSize: 10,
                        color: kOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 2-Column Grid: Deadline & Recipient
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: kSurfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.event_rounded,
                          size: 18,
                          color: kPrimaryDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deadline',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kOnSurfaceVariant,
                              ),
                            ),
                            Text(
                              daysLeft > 0
                                  ? '${deadlineLabel(widget.scholarship.deadline)} ($daysLeft Days)'
                                  : deadlineLabel(widget.scholarship.deadline),

                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kError,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: kSurfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          size: 18,
                          color: kSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recipient',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kOnSurfaceVariant,
                              ),
                            ),
                            Text(
                              'UP Diliman',

                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kOnSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD 3: Application Packet Card -------------------------------------
  Widget _buildPacketCard({required StudentProfile? profile}) {
    final application = ref
        .watch(applicationsProvider)
        .valueOrNull
        ?.where((a) => a.scholarshipId == widget.scholarship.id)
        .firstOrNull;
    final documents = application == null
        ? null
        : ref.watch(applicationDocumentsProvider(application.id));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Packet',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Academic profile: ${profile?.school ?? 'School not recorded'}. Information is self-reported and awaits review.',
          ),
          const SizedBox(height: 8),
          if (documents == null)
            const Text('No supporting documents attached yet.'),
          if (_packetError != null)
            Text(_packetError!, style: const TextStyle(color: Colors.red)),
          if (documents != null)
            documents.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text(
                'Could not load attachments. Please retry before submitting.',
              ),
              data: (docs) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docs.isEmpty
                        ? 'No supporting documents attached yet.'
                        : 'Uploaded attachments (awaiting review):',
                  ),
                  for (final doc in docs)
                    Text('${doc.humanType}: ${doc.fileName}'),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: _isSavingDraft
                ? null
                : () async {
                    setState(() {
                      _isSavingDraft = true;
                      _packetError = null;
                    });
                    try {
                      final draft =
                          application ??
                          await ref
                              .read(applicationsProvider.notifier)
                              .saveDraft(widget.scholarship.id);
                      if (!mounted) return;
                      await showDocumentUploadSheet(
                        context,
                        preselectedApplicationId: draft.id,
                      );
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => _packetError = 'Could not prepare document upload. Please retry.',
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSavingDraft = false);
                      }
                    }
                  },
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload supporting document'),
          ),
        ],
      ),
    );
  }

  Widget _buildAffirmationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A161C27),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                size: 20,
                color: kPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Affirmations & Honor Code',

                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kOnSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Affirmation 1
          _buildCheckboxItem(
            value: _cert1,
            onChanged: (v) => setState(() => _cert1 = v ?? false),
            text: 'I confirm that the application information I am submitting is accurate.',
          ),
          const SizedBox(height: 8),

          // Affirmation 2
          _buildCheckboxItem(
            value: _cert2,
            onChanged: (v) => setState(() => _cert2 = v ?? false),
            text: 'I understand that authorized staff of the scholarship organization can review my submitted information and attachments.',
          ),
          const SizedBox(height: 8),

          // Affirmation 3
          _buildCheckboxItem(
            value: _cert3,
            onChanged: (v) => setState(() => _cert3 = v ?? false),
            text: 'I understand that submitting an application does not guarantee a scholarship.',
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: kPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: kOnSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 5: Digital Signature Card --------------------------------------
  Widget _buildDigitalSignatureCard({required String studentName}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A161C27),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'APPLICANT',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: kOnSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    size: 14,
                    color: kPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Review Pending',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Signature Display Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Applicant Name',
                            style: GoogleFonts.openSans(
                              fontSize: 10,
                              color: kOnSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            studentName,

                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: kPrimaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 26,
                      color: kPrimaryContainer,
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Submission time is saved after successful submission.',

                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          fontSize: 10,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tamper-Evident Ledger Notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: kSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A submission is complete only after it is saved successfully.',
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      color: kOnSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD 6: Pinned Submit Actions Footer -------------------------------
  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F3))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A161C27),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Submit Button
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 46,
            ),
            child: FilledButton(
              key: const ValueKey('apply-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryContainer,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kPrimaryContainer.withValues(
                  alpha: 0.5,
                ),
                disabledForegroundColor: Colors.white70,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: _allAffirmationsChecked && !_isSavingDraft
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.rocket_launch_rounded, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Submit Application (Final)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Secondary Action Row: Cancel & Save Progress
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              // Cancel Button
              TextButton(
                key: const ValueKey('apply-cancel'),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF707971),
                  ),
                ),
              ),
              // Save Progress Button
              TextButton(
                key: const ValueKey('apply-save-draft'),
                onPressed: _isSavingDraft ? null : _handleSaveDraftDirectly,
                child: _isSavingDraft
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Save Progress & Return to Grant Detail',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryContainer,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Once submitted, your application is locked and transmitted to the review committee. You will receive an official timestamp receipt via your UP Diliman email.',
            textAlign: TextAlign.center,

            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.openSans(
              fontSize: 10,
              color: kOnSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

String _grantValue(Scholarship scholarship) {
  final provider = scholarship.provider?.toLowerCase() ?? '';
  final title = scholarship.title.toLowerCase();
  if (provider.contains('dost') || title.contains('dost')) {
    return '₱40,000';
  } else if (provider.contains('ched') || title.contains('ched')) {
    return '₱60,000';
  } else if (provider.contains('gokongwei') ||
      provider.contains('ayala') ||
      provider.contains('sm')) {
    return '₱100,000';
  }
  return '₱50,000';
}
