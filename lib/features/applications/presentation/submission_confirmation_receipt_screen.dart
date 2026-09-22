// lib/features/applications/presentation/submission_confirmation_receipt_screen.dart
//
// Submission Confirmation Receipt Screen matching Stitch design specification
// `design-reference/stitch_scholaris_mobile_app/scholaris_submission_confirmation_receipt/code.html`.
//
// Features:
// 1. Celebratory Hero Banner with pulsating badge & sealed status
// 2. Official Digital Tracking Receipt Card with copyable Reference ID & SHA-256 vault record
// 3. Evaluation Roadmap with 4-stage review milestones
// 4. Momentum anchor encouraging multiple applications
// 5. Direct navigation to Application Tracker & Student Dashboard

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';

class SubmissionConfirmationReceiptScreen extends ConsumerStatefulWidget {
  const SubmissionConfirmationReceiptScreen({
    super.key,
    required this.scholarship,
    this.receiptId = 'REC-2025-DOST-98214-PH',
  });

  final Scholarship scholarship;
  final String receiptId;

  @override
  ConsumerState<SubmissionConfirmationReceiptScreen> createState() =>
      _SubmissionConfirmationReceiptScreenState();
}

class _SubmissionConfirmationReceiptScreenState
    extends ConsumerState<SubmissionConfirmationReceiptScreen> {
  bool _copied = false;

  void _copyReceiptId() {
    Clipboard.setData(ClipboardData(text: widget.receiptId));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt Identifier copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _navigateToTracker() {
    ref.read(homeTabIndexProvider.notifier).selectTab(2);
    if (context.canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    context.go('/home');
  }

  void _navigateToDashboard() {
    ref.read(homeTabIndexProvider.notifier).selectTab(0);
    if (context.canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final userName = (profile?.fullName != null && profile!.fullName.trim().isNotEmpty)
        ? profile.fullName.trim()
        : 'Maya Santos';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kOnSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: kPrimaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scholaris',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryDark,
                    ),
                  ),
                  Text(
                    'SCHOLARSHIP DETAIL & ELIGIBILITY',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: kOnSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20, color: kOnSurface),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt link copied for sharing.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, size: 20, color: kOnSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // SECTION 1: Celebratory Hero Banner
            _buildCelebratoryHeroBanner(),
            const SizedBox(height: 16),

            // SECTION 2: Official Digital Tracking Receipt Card
            _buildDigitalReceiptCard(userName: userName),
            const SizedBox(height: 16),

            // SECTION 3: Review Timeline Milestones (Evaluation Roadmap)
            _buildEvaluationRoadmapCard(),
            const SizedBox(height: 16),

            // SECTION 4: Keep the Momentum
            _buildMomentumCard(),
            const SizedBox(height: 20),

            // SECTION 5: Action Navigation Controls
            _buildActionControls(),
          ],
        ),
      ),
    );
  }

  // --- SECTION 1: Celebratory Hero Banner -----------------------------------
  Widget _buildCelebratoryHeroBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4D2E), Color(0xFF00351C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x290F4D2E),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Milestone Badge with glow
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFFB3F1C6).withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.verified_rounded,
                size: 34,
                color: Color(0xFFB3F1C6),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Badge: PACKET SECURED & SEALED
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFB3F1C6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB3F1C6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'PACKET SECURED & SEALED',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB3F1C6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Mascot Celebrating
          const MascotPoseView(
            pose: MascotPose.celebrating,
            height: 110,
          ),
          const SizedBox(height: 12),

          // Headline
          Text(
            'Application Successfully Submitted!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            'Your packet is officially logged and queued for the ${widget.scholarship.provider ?? "DOST-SEI (Department of Science and Technology)"} review panel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: const Color(0xFF82BD95),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Timestamp Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Color(0xFFFFDEA3),
                ),
                const SizedBox(width: 6),
                Text(
                  'Oct 10, 2025 • 4:19 PM PHT ',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '(5 days ahead)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFDEA3),
                  ),
                ),
              ],
            ),
          ),

          // Accessible Status Tag for tests
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Application submitted',
              style: GoogleFonts.openSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB3F1C6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 2: Official Digital Tracking Receipt Card -------------------
  Widget _buildDigitalReceiptCard({required String userName}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A161C27),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Institutional Dossier & Valid Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: kSurfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                      color: kPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSTITUTIONAL DOSSIER',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: kOnSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Digital Submission Token',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kOnSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimaryFixed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'VALID',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kOnPrimaryFixedVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reference Identifier Box with Copy Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reference Identifier',
                        style: GoogleFonts.openSans(
                          fontSize: 10,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.receiptId,
                        style: GoogleFonts.robotoMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kOnSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy Tracking ID',
                  icon: Icon(
                    _copied ? Icons.done_rounded : Icons.content_copy_rounded,
                    size: 18,
                    color: _copied ? kPrimaryContainer : kSecondary,
                  ),
                  onPressed: _copyReceiptId,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Details Grid
          _receiptRow(
            label: 'Grant Opportunity',
            value: widget.scholarship.title,
            bold: true,
          ),
          const Divider(height: 14),
          _receiptRow(
            label: 'Endowment Value',
            value: '${_grantValue(widget.scholarship)} / year + Monthly Stipend',
            subvalue: '(4-Yr Renewable)',
            valueColor: kPrimaryContainer,
            bold: true,
          ),
          const Divider(height: 14),
          _receiptRow(
            label: 'Review Committee',
            value: '${widget.scholarship.provider ?? "DOST-SEI"} Screening Board',
            subvalue: '#PH-84-192',
          ),
          const Divider(height: 14),
          _receiptRow(
            label: 'Applicant',
            value: userName,
            subvalue: '(UP Diliman #2022-88219)',
          ),
          const SizedBox(height: 14),

          // Verified Attachments Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VERIFIED ATTACHMENTS (4 OF 4)',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kOnSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: kPrimaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _attachmentBullet('Research Essay.pdf')),
                    Expanded(child: _attachmentBullet('UP Diliman TCG/Transcript')),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _attachmentBullet('2 Rec Letters (Faculty)')),
                    Expanded(child: _attachmentBullet('PSA Birth Cert & BIR ITR')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SHA-256 Ledger Audit Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 14, color: kPrimaryContainer),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'SHA-256: e3b0c44298fc1c...8b456',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Scholaris Vault Sealed',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Action Export Buttons (Export PDF & Sync Calendar)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFE2E8F3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exporting official receipt PDF...')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16, color: kPrimaryContainer),
                  label: Text(
                    'Export PDF',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kOnSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFE2E8F3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Application dates synced with calendar.')),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_outlined, size: 16, color: kSecondary),
                  label: Text(
                    'Sync Calendar',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kOnSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptRow({
    required String label,
    required String value,
    String? subvalue,
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: kOnSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.end,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? kOnSurface,
                ),
              ),
              if (subvalue != null)
                Text(
                  subvalue,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.openSans(
                    fontSize: 10,
                    color: kOnSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _attachmentBullet(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: kPrimaryContainer,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.openSans(
              fontSize: 11,
              color: kOnSurface,
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 3: Review Timeline Milestones --------------------------------
  Widget _buildEvaluationRoadmapCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A161C27),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_tree_rounded,
                    size: 20,
                    color: kPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Evaluation Roadmap',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kOnSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kSurfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Stage 1 of 4',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kOnSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Milestones
          _roadmapStep(
            icon: Icons.check_rounded,
            iconBg: kPrimaryContainer,
            iconColor: Colors.white,
            title: 'Packet Received & Authenticated',
            tag: 'Today',
            tagBg: kPrimaryFixed,
            tagColor: kOnPrimaryFixedVariant,
            caption: 'Oct 10, 2025 • Timestamp certified via UP Registrar link',
            isFirst: true,
          ),
          _roadmapStep(
            icon: Icons.sync_rounded,
            iconBg: kSecondary,
            iconColor: Colors.white,
            title: 'Compliance & Priority S&T Audit',
            tag: 'Active',
            tagBg: kSecondaryFixed,
            tagColor: kOnSecondaryFixedVariant,
            caption: 'Oct 11 - Oct 14 • Automated STEM priority course & citizenship check',
          ),
          _roadmapStep(
            icon: Icons.circle_outlined,
            iconBg: kSurfaceContainerHighest,
            iconColor: kOutline,
            title: 'DOST Technical Committee Review',
            caption: 'Oct 16 - Nov 05 • Deliberation and scoring of essays',
            opacity: 0.7,
          ),
          _roadmapStep(
            icon: Icons.circle_outlined,
            iconBg: kSurfaceContainerHighest,
            iconColor: kOutline,
            title: 'Final Award Allocation & Notice of Award (NOA)',
            tag: 'Target',
            tagBg: kSurfaceContainer,
            tagColor: kOnSurfaceVariant,
            caption:
                'Nov 15, 2025 • Formal NOA delivered via Scholaris portal & LandBank disbursement schedule',
            isLast: true,
            opacity: 0.7,
          ),
          const SizedBox(height: 12),

          // Dispatch Guarantees Notice Box
          Container(
            padding: const EdgeInsets.all(10),
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
                    color: kPrimaryFixed.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: kPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch Guarantees',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Copy emailed to applicant & SMS notice to +63 917 **** 421',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: kOnSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roadmapStep({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? tag,
    Color? tagBg,
    Color? tagColor,
    required String caption,
    bool isFirst = false,
    bool isLast = false,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, size: 14, color: iconColor),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: kSurfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: kOnSurface,
                            ),
                          ),
                        ),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: tagBg ?? kSurfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: tagColor ?? kOnSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        color: kOnSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION 4: Keep the Momentum -----------------------------------------
  Widget _buildMomentumCard() {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kTertiaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  size: 22,
                  color: kOnTertiaryFixed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KEEP THE MOMENTUM',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kOnTertiaryContainer,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Multiple submissions triple your grant odds.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kOnSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Scholars applying to 3 or more matched Philippine programs secure an average of ₱180,000 in non-repayable education grants.',
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: kOnSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Recommended Opportunity Micro-Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08161C27),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryFixed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '96% Match',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kOnPrimaryFixedVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Due in 18d',
                            style: GoogleFonts.openSans(
                              fontSize: 10,
                              color: kOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gokongwei Brothers STEM Excellence Grant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kOnSurface,
                        ),
                      ),
                      Text(
                        '₱100,000 Award',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kSurfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: kOnSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 5: Action Navigation Controls --------------------------------
  Widget _buildActionControls() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: _navigateToTracker,
            icon: const Icon(Icons.track_changes_rounded, size: 18),
            label: Text(
              'Monitor in Application Tracker',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: kSurfaceContainer,
              foregroundColor: kSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _navigateToDashboard,
            child: Text(
              'Return to Student Dashboard',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _grantValue(Scholarship scholarship) {
  final provider = scholarship.provider?.toLowerCase() ?? '';
  final title = scholarship.title.toLowerCase();
  if (provider.contains('dost') || title.contains('dost')) {
    return '₱80,000';
  } else if (provider.contains('ched') || title.contains('ched')) {
    return '₱60,000';
  } else if (provider.contains('gokongwei') ||
      provider.contains('ayala') ||
      provider.contains('sm')) {
    return '₱100,000';
  }
  return '₱50,000';
}
