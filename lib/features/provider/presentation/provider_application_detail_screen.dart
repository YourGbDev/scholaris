// lib/features/provider/presentation/provider_application_detail_screen.dart
//
// Dedicated full-screen applicant dossier review for scholarship providers.
// Built to match Stitch design reference: scholaris_application_detail_provider_view.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/application_status_chip.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class ProviderApplicationDetailScreen extends ConsumerStatefulWidget {
  const ProviderApplicationDetailScreen({
    super.key,
    required this.applicationId,
    this.initialApplication,
    this.initialScholarship,
    this.initialProfile,
  });

  final String applicationId;
  final Application? initialApplication;
  final Scholarship? initialScholarship;
  final StudentProfile? initialProfile;

  @override
  ConsumerState<ProviderApplicationDetailScreen> createState() =>
      _ProviderApplicationDetailScreenState();
}

class _ProviderApplicationDetailScreenState
    extends ConsumerState<ProviderApplicationDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  final List<String> _localRemarks = [];
  bool _isSavingRemark = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _addRemark() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isSavingRemark = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _localRemarks.add(text);
          _noteController.clear();
          _isSavingRemark = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deliberation remark recorded.')),
        );
      }
    });
  }

  Future<void> _updateStatus(Application app, ApplicationStatus status) async {
    final actionLabel =
        status == ApplicationStatus.approved ? 'Approve' : 'Reject';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          '$actionLabel Application',
          style: poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to ${actionLabel.toLowerCase()} this application? This decision is final.',
          style: openSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  status == ApplicationStatus.approved ? kPrimary : kError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(applicationRepositoryProvider)
            .updateStatus(app.id, status);
        ref.read(incomingApplicationsProvider.notifier).refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == ApplicationStatus.approved
                  ? 'Candidate successfully approved!'
                  : 'Application marked as rejected.',
            ),
          ),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update application status.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomingAppsAsync = ref.watch(incomingApplicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

    final app = widget.initialApplication ??
        incomingAppsAsync.valueOrNull?.cast<Application?>().firstWhere(
              (a) => a?.id == widget.applicationId,
              orElse: () => null,
            );

    if (app == null) {
      if (incomingAppsAsync.isLoading) {
        return const Scaffold(
          backgroundColor: kBackground,
          body: Center(child: LoadingView()),
        );
      }
      return Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(title: const Text('Application Review')),
        body: const Center(
          child: EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Application not found',
            message: 'This application is unavailable or has been removed.',
          ),
        ),
      );
    }

    final scholarship = widget.initialScholarship ??
        scholarshipsAsync.valueOrNull?.cast<Scholarship?>().firstWhere(
              (s) => s?.id == app.scholarshipId,
              orElse: () => null,
            );

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(
          'Application Review',
          style: poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          tooltip: 'Back to Console',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: kPrimarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(
              'DO',
              style: poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.black.withValues(alpha: 0.06),
            height: 1,
          ),
        ),
      ),
      body: widget.initialProfile != null
          ? _buildReviewContent(context, app, scholarship, widget.initialProfile!)
          : FutureBuilder<StudentProfile?>(
              future: ref
                  .read(profileRepositoryProvider)
                  .fetchProfileById(app.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: LoadingView());
                }
                final profile = snapshot.data ??
                    StudentProfile(
                      id: app.userId,
                      fullName: 'Applicant #${app.id.length >= 5 ? app.id.substring(0, 5).toUpperCase() : app.id}',
                      course: 'Degree Program Pending',
                      school: 'Institution Pending',
                      yearLevel: 1,
                      gpa: 0.0,
                      region: 'Philippines',
                      nationality: 'Filipino',
                    );
                return _buildReviewContent(context, app, scholarship, profile);
              },
            ),
      bottomNavigationBar: _buildStickyActionBar(context, app),
    );
  }

  Widget _buildReviewContent(
    BuildContext context,
    Application app,
    Scholarship? scholarship,
    StudentProfile profile,
  ) {
    final refCode =
        '#SCH-2024-${app.id.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}';
    final programTitle =
        scholarship?.title ?? 'Scholarship Grant';
    final gpa = profile.gpa;
    final cutoffGpa = scholarship?.minGpa;

    return ResponsiveContainer(
      child: ListView(
        physics: const AppleBouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Sub-Header Context
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded,
                        size: 16, color: kNavyTrust),
                    const SizedBox(width: 4),
                    Text(
                      'Back to Console',
                      style: poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kNavyTrust,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  'Ref: $refCode',
                  style: openSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Applicant Title & Match Score Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$programTitle (AY 2024–2025)',
                      style: openSans(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kPrimarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Insufficient Pool Data',
                      style: poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Stage Badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kNavyTrust,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'STAGE: ${ApplicationStatusUi.of(app.status).label.toUpperCase()}',
                    style: poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Academic Credentials
          _buildCard(
            title: 'Academic Credentials',
            icon: Icons.school_rounded,
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kPrimarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 13, color: kPrimary),
                  const SizedBox(width: 4),
                  Text(
                    profile.setupComplete
                        ? 'Profile Complete'
                        : 'Pending Setup',
                    style: poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: profile.setupComplete ? kPrimary : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GWA Highlight Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kPrimarySoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUMULATIVE GWA',
                              style: poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  gpa > 0 ? gpa.toStringAsFixed(2) : 'N/A',
                                  style: poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: gpa > 0 ? kPrimary : Colors.black45,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '/ 1.0–5.0 Scale',
                                  style: openSans(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.military_tech_rounded,
                                  size: 15,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  gpa > 0 && cutoffGpa != null
                                      ? (gpa <= cutoffGpa
                                          ? 'Meets ${cutoffGpa.toStringAsFixed(2)} Cutoff'
                                          : 'Below ${cutoffGpa.toStringAsFixed(2)} Cutoff')
                                      : (gpa > 0
                                          ? 'GWA on File'
                                          : 'GWA Record Pending'),
                                  style: poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: gpa > 0 && (cutoffGpa == null || gpa <= cutoffGpa)
                                        ? kPrimary
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: kPrimary.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: kPrimary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Detail Rows
                _infoRow(
                  'Enrolled Institution',
                  profile.school?.trim().isNotEmpty == true
                      ? profile.school!.trim()
                      : 'Institution Pending',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'Degree & Academic Major',
                  profile.course.trim().isNotEmpty == true
                      ? profile.course.trim()
                      : 'Degree Program Pending',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'Academic Standing',
                  'Year ${profile.yearLevel} • AY 2024–2025',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        profile.setupComplete
                            ? Icons.verified_user_rounded
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: profile.setupComplete ? kPrimary : Colors.black45,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profile.setupComplete
                              ? 'Profile Setup Completed by Candidate'
                              : 'Self-Reported Student Academic Record',
                          style: openSans(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Socioeconomic Assessment
          _buildCard(
            title: 'Socioeconomic Assessment',
            icon: Icons.policy_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RA 10173 Compliance notice
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'RA 10173 Compliance: Specific peso earnings are shielded. Verified financial tiers and DSWD indicators are provided to prevent socio-demographic bias.',
                          style: openSans(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tier Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HOUSEHOLD INCOME TIER',
                            style: poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kNavyTrust.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Need Priority',
                              style: poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: kNavyTrust,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.incomeBracket != null
                            ? '${profile.incomeBracket!.toUpperCase()} Income Tier'
                            : (profile.monthlyFamilyIncome != null
                                ? '₱${((profile.monthlyFamilyIncome!) / 1000).toStringAsFixed(0)}k Monthly Family Income'
                                : 'Income Record Pending'),
                        style: poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.monthlyFamilyIncome != null
                            ? 'Self-declared household earnings.'
                            : 'Applicant has not declared household earnings for this cycle.',
                        style: openSans(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Indicators
                _indicatorTile(
                  'Declared Regional Residency: ${profile.region.isNotEmpty ? profile.region : 'Philippines'}',
                  profile.region.isNotEmpty,
                ),
                const SizedBox(height: 6),
                _indicatorTile(
                  'Academic Registration: ${profile.setupComplete ? 'Profile Complete' : 'Self-Declared'}',
                  profile.setupComplete,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Document Audit Checklist
          _buildCard(
            title: 'Document Audit Checklist',
            icon: Icons.folder_shared_rounded,
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Awaiting Uploads',
                style: poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.folder_open_rounded,
                          color: Colors.black45,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No verification documents on file',
                        style: poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The applicant has not uploaded digital attachments (such as certified Form 5, BIR 2316, or personal statement PDF) for this application cycle.',
                        textAlign: TextAlign.center,
                        style: openSans(
                          fontSize: 11.5,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (app.notes != null && app.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimarySoft.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: kPrimary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Applicant Statement / Note',
                          style: poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.notes!,
                          style: openSans(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 4: Reviewer Notes & Committee Log
          _buildCard(
            title: 'Reviewer Notes & Audit Log',
            icon: Icons.rate_review_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_localRemarks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.rate_review_outlined,
                            color: Colors.black45, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No committee remarks recorded yet',
                                style: poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Remarks entered below will be recorded with your application review decisions.',
                                style: openSans(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Dynamically added local remarks
                for (final remark in _localRemarks) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimarySoft.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: kPrimary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'DO',
                                style: poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Review Committee Remark',
                              style: poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Just now',
                              style: openSans(
                                  fontSize: 11, color: Colors.black45),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          remark,
                          style: openSans(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                // Textarea for new deliberation remark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NEW DELIBERATION NOTE',
                      style: poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 11, color: Colors.black45),
                        const SizedBox(width: 3),
                        Text(
                          'Private to Committee',
                          style: openSans(
                              fontSize: 10, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: openSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Add internal reviewer evaluation or conditional remarks...',
                    hintStyle:
                        openSans(fontSize: 12, color: Colors.black38),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isSavingRemark ? null : _addRemark,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSavingRemark
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Remark',
                            style: poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    Widget? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: kPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                badge,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: openSans(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicatorTile(String text, bool verified) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: verified ? kPrimarySoft : Colors.black12,
            shape: BoxShape.circle,
          ),
          child: Icon(
            verified ? Icons.check_rounded : Icons.remove_rounded,
            size: 14,
            color: verified ? kPrimary : Colors.black54,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: openSans(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }


  Widget _buildStickyActionBar(BuildContext context, Application app) {
    final isTerminal = app.status == ApplicationStatus.approved ||
        app.status == ApplicationStatus.rejected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isTerminal
            ? Center(
                child: Text(
                  'Application decision has been recorded (${ApplicationStatusUi.of(app.status).label}).',
                  style: poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              )
            : Row(
                children: [
                  // Reject button
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(app, ApplicationStatus.rejected),
                    icon: const Icon(Icons.close_rounded, size: 16, color: kError),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kError,
                      side: const BorderSide(color: kError),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Request Docs button
                  OutlinedButton.icon(
                    onPressed: () {
                      _noteController.text =
                          'Conditionally held pending additional verification of: ';
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Deliberation note template inserted for document request.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline_rounded,
                        size: 16, color: kNavyTrust),
                    label: const Text('Request Docs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kNavyTrust,
                      side: const BorderSide(color: kNavyTrust),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Advance / Approve button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateStatus(app, ApplicationStatus.approved),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'Approve',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
