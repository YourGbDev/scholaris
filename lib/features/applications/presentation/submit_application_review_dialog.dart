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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/save_draft_dialog.dart';

class SubmitApplicationReviewDialog extends ConsumerStatefulWidget {
  const SubmitApplicationReviewDialog({
    super.key,
    required this.scholarship,
    required this.onSaveDraft,
    this.initialCertificationsChecked = true,
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
    final studentName = (profile?.fullName != null && profile!.fullName.trim().isNotEmpty)
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                          Text(
                            'Final Step • Review',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kSecondary,
                              letterSpacing: 0.5,
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
                      maxLines: 1,
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
                  'Step 3 of 3: Sign & Submit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '100% Prepared',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kOnSurfaceVariant,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepMarker(
                  icon: Icons.check_circle_rounded,
                  label: '1. Overview',
                  active: true,
                ),
                const SizedBox(width: 16),
                _stepMarker(
                  icon: Icons.check_circle_rounded,
                  label: '2. Packet',
                  active: true,
                ),
                const SizedBox(width: 16),
                _stepMarker(
                  icon: Icons.verified_rounded,
                  label: '3. Finalize',
                  active: true,
                  bold: true,
                ),
              ],
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                              maxLines: 1,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                              maxLines: 1,
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
    final school = profile?.school;
    final hasTranscript = profile != null && school != null && school.isNotEmpty;
    final transcriptTitle = hasTranscript
        ? '$school Academic Transcript'
        : 'Official Academic Transcript';
    final gpaText = profile != null
        ? 'GPA ${profile.gpa.toStringAsFixed(2)}'
        : 'Pending';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Packet',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kOnSurface,
                      ),
                    ),
                    Text(
                      hasTranscript
                          ? 'Academic records & materials verified'
                          : 'Materials pending verification',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        color: kOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasTranscript ? Icons.verified_rounded : Icons.pending_rounded,
                    size: 16,
                    color: hasTranscript ? kPrimaryContainer : kSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasTranscript ? 'Verified' : 'In Review',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasTranscript ? kPrimaryContainer : kSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Personal Statement
          _buildPacketItem(
            icon: Icons.description_outlined,
            iconBg: kPrimaryFixed,
            iconColor: kOnPrimaryFixed,
            title: 'Personal Statement',
            tag: 'Draft Included',
            subtitle: 'Personal statement and academic intent',
            statusIcon: Icons.check_rounded,
            statusLabel: 'Attached to Application Packet',
            actionIcon: Icons.visibility_outlined,
          ),
          const SizedBox(height: 8),

          // 2. Academic Transcript
          _buildPacketItem(
            icon: Icons.school_outlined,
            iconBg: hasTranscript ? kSecondaryFixed : const Color(0xFFFFDAD6),
            iconColor: hasTranscript ? kOnSecondaryFixed : const Color(0xFF93000A),
            title: transcriptTitle,
            tag: gpaText,
            subtitle: hasTranscript
                ? 'Synced and verified from student profile'
                : 'Academic transcript record pending in profile',
            statusIcon: hasTranscript ? Icons.lock_outline_rounded : Icons.info_outline_rounded,
            statusLabel: hasTranscript
                ? 'Official Academic Record Attached'
                : 'Pending Profile Verification',
            actionIcon: Icons.open_in_new_rounded,
          ),
          const SizedBox(height: 8),

          // 3. Recommendations
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPrimaryFixed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.contact_mail_outlined,
                    size: 20,
                    color: kOnPrimaryFixed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty Recommendations',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Institutional endorsements and academic references',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 4. PSA Birth Cert & BIR Form 2316
          _buildPacketItem(
            icon: Icons.receipt_long_outlined,
            iconBg: kSecondaryFixed,
            iconColor: kOnSecondaryFixed,
            title: 'PSA Birth Cert & BIR Form 2316',
            tag: 'Verified',
            subtitle: 'Philippine PSA & BIR Proof Encrypted & Synced',
            statusIcon: Icons.enhanced_encryption_outlined,
            statusLabel: 'Financial Need Verification Passed',
            actionIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 10),

          // Combined Packet Action Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: kSurfaceContainer,
                foregroundColor: kSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Viewing Combined Packet PDF (4.2 MB)...')),
                );
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'View Combined Packet (PDF 4.2 MB)',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacketItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String tag,
    required String subtitle,
    required IconData statusIcon,
    required String statusLabel,
    required IconData actionIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kSurfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: kOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(statusIcon, size: 12, color: kPrimaryContainer),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(actionIcon, size: 18, color: kSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // --- CARD 4: Affirmations & Honor Code Card ------------------------------
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
              Text(
                'Affirmations & Honor Code',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kOnSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Affirmation 1
          _buildCheckboxItem(
            value: _cert1,
            onChanged: (v) => setState(() => _cert1 = v ?? false),
            text:
                'I certify under penalty of law that all personal information, essays, and UP Diliman academic records provided are true, accurate, and original.',
          ),
          const SizedBox(height: 8),

          // Affirmation 2
          _buildCheckboxItem(
            value: _cert2,
            onChanged: (v) => setState(() => _cert2 = v ?? false),
            text:
                'I authorize Scholaris and the DOST-SEI screening panel to verify academic standing with the University of the Philippines Diliman Office of the University Registrar (OUR).',
          ),
          const SizedBox(height: 8),

          // Affirmation 3
          _buildCheckboxItem(
            value: _cert3,
            onChanged: (v) => setState(() => _cert3 = v ?? false),
            text:
                'I understand that stipends and tuition subsidies will be disbursed via authorized LandBank / DBP scholar accounts or direct to university upon official awarding.',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIGITAL SIGNATURE',
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
                    'Legally Binding',
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
                            'Applicant Full Legal Name',
                            style: GoogleFonts.openSans(
                              fontSize: 10,
                              color: kOnSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            studentName,
                            maxLines: 1,
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
                        'Timestamp: Oct 10, 2025 • 4:18 PM PST',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          fontSize: 10,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: SCH-98214-ML',
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
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: kSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tamper-evident SHA-256 ledger record created upon submission.',
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
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              key: const ValueKey('apply-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryContainer,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kPrimaryContainer.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white70,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _allAffirmationsChecked && !_isSavingDraft
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Submit Application (Final)',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Secondary Action Row: Cancel & Save Progress
          Row(
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
              const SizedBox(width: 8),
              // Save Progress Button
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const ValueKey('apply-save-draft'),
                    onPressed: _isSavingDraft ? null : _handleSaveDraftDirectly,
                    child: _isSavingDraft
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Save Progress & Return to Grant Detail',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryContainer,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Once submitted, your application is locked and transmitted to the review committee. You will receive an official timestamp receipt via your UP Diliman email.',
            textAlign: TextAlign.center,
            maxLines: 2,
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
