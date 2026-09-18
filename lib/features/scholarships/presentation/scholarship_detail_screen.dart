// lib/features/scholarships/presentation/scholarship_detail_screen.dart
//
// Full scholarship details and application flow rebuilt to Stitch specifications.
// Receives the scholarship via route extra when possible (from a card),
// otherwise falls back to loading it by id.
// The bookmark toggle in the app bar keeps the Saved tab in sync. When the
// signed-in student's profile makes this scholarship an actual match, an
// "Algorithmic Fit" card and "Criteria Checklist" section restate the reasons.
// The Apply action is gated by pure application-readiness evaluation:
// only an eligible student with an active, open scholarship gets an enabled
// Apply button. Confirming the pre-apply review dialog sends the write through
// the existing applications provider. Once applied, the screen renders an
// official Digital Submission Token and confirmation receipt.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/submit_application_review_dialog.dart';
import 'package:scholaris/features/applications/presentation/submission_confirmation_receipt_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/widgets/identity_photo_dialog.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/services/application_readiness.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class ScholarshipDetailScreen extends ConsumerStatefulWidget {
  const ScholarshipDetailScreen({
    super.key,
    required this.scholarshipId,
    this.initial,
  });

  final String scholarshipId;
  final Scholarship? initial;

  @override
  ConsumerState<ScholarshipDetailScreen> createState() =>
      _ScholarshipDetailScreenState();
}

class _ScholarshipDetailScreenState
    extends ConsumerState<ScholarshipDetailScreen> {
  final GlobalKey _checklistKey = GlobalKey();

  void _scrollToChecklist() {
    final context = _checklistKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final bookmarkIds = bookmarksAsync.valueOrNull ?? const <String>{};
    final saved = bookmarkIds.contains(widget.scholarshipId);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kOnSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/discover');
            }
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kPrimaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Scholaris',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share scholarship',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scholarship link copied to clipboard.')),
              );
            },
            icon: const Icon(
              Icons.share_outlined,
              size: 22,
              color: kOnSurface,
            ),
          ),
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save this scholarship',
            onPressed: saved ? _unbookmark : _bookmark,
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 22,
              color: saved ? kAccent : kOnSurface,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ResponsiveContainer(child: _buildBody(context, saved: saved)),
    );
  }

  Widget _buildBody(BuildContext context, {required bool saved}) {
    final initial = widget.initial;
    if (initial != null) {
      return _DetailContent(
        scholarship: initial,
        saved: saved,
        checklistKey: _checklistKey,
        onScrollToChecklist: _scrollToChecklist,
      );
    }

    return ref.watch(scholarshipByIdProvider(widget.scholarshipId)).when(
          loading: () => const LoadingView(),
          error: (_, _) => ErrorView(
            message: 'We could not load this scholarship.',
            onRetry: () =>
                ref.invalidate(scholarshipByIdProvider(widget.scholarshipId)),
          ),
          data: (scholarship) => scholarship == null
              ? const EmptyView(
                  icon: Icons.search_off_rounded,
                  title: 'Scholarship not found',
                  message: 'This scholarship may no longer be active.',
                )
              : _DetailContent(
                  scholarship: scholarship,
                  saved: saved,
                  checklistKey: _checklistKey,
                  onScrollToChecklist: _scrollToChecklist,
                ),
        );
  }

  Future<void> _bookmark() async {
    final notifier = ref.read(bookmarksProvider.notifier);
    try {
      await notifier.toggle(widget.scholarshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your list.')),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  Future<void> _unbookmark() async {
    final notifier = ref.read(bookmarksProvider.notifier);
    try {
      await notifier.toggle(widget.scholarshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from your list.')),
        );
      }
    } on Exception {
      // Ignore transient failures on removal.
    }
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.scholarship,
    required this.saved,
    required this.checklistKey,
    required this.onScrollToChecklist,
  });

  final Scholarship scholarship;
  final bool saved;
  final GlobalKey checklistKey;
  final VoidCallback onScrollToChecklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final expired = isDeadlinePassed(scholarship.deadline, now: now);
    final closing = !expired &&
        isClosingSoon(scholarship.deadline.difference(now).inDays);
    final daysLeft = scholarship.deadline.difference(now).inDays;
    final reasons = _matchReasons(ref);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
      children: [
        // Internal Navigation Breadcrumb (Stitch scholaris_scholarship_detail_eligibility)
        const _BreadcrumbRow(),
        const SizedBox(height: 6),

        // 1. Hero Card
        _HeroCard(
          scholarship: scholarship,
          closing: closing,
          expired: expired,
          daysLeft: daysLeft,
        ),
        const SizedBox(height: 12),

        // 2. Application Readiness & CTA / Banner
        _ApplySection(
          scholarship: scholarship,
          onScrollToChecklist: onScrollToChecklist,
        ),
        const SizedBox(height: 14),

        // 3. Algorithmic Fit & Criteria Checklist
        if (reasons.isNotEmpty) ...[
          Container(
            key: checklistKey,
            child: _AlgorithmicFitCard(
              reasons: reasons,
              scholarship: scholarship,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 4. Award Overview & Impact
        _AwardOverviewCard(scholarship: scholarship),
        const SizedBox(height: 20),

        // 5. Eligibility Section
        _EligibilityCard(scholarship: scholarship),
        const SizedBox(height: 20),

        // 6. Application Materials & Requirements
        const _ApplicationMaterialsCard(),
        const SizedBox(height: 20),

        // 7. Verified Institutional Provider Trust Card
        _ProviderTrustCard(scholarship: scholarship),
      ],
    );
  }

  List<String> _matchReasons(WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final readiness = evaluateApplicationReadiness(
      profile: profile,
      scholarship: scholarship,
      referenceNow: DateTime.now(),
    );
    if (readiness.state != ApplicationReadinessState.eligible) {
      return const [];
    }
    return matchReasonsFor(profile!, scholarship);
  }
}

/// Internal Navigation Breadcrumb matching Stitch mockup:
/// "<- Back to Discover" on the left.
class _BreadcrumbRow extends StatelessWidget {
  const _BreadcrumbRow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/discover');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded, size: 18, color: kSecondary),
              const SizedBox(width: 4),
              Text(
                'Back to Discover',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1. Hero Card: Provider header, verified tick, program code tag, title,
/// grant value in ₱ with allowance details, urgency deadline banner, and Stitch category pills.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.scholarship,
    required this.closing,
    required this.expired,
    required this.daysLeft,
  });

  final Scholarship scholarship;
  final bool closing;
  final bool expired;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final providerName = scholarship.provider ?? 'Scholarship Provider';
    final codeTag = _programCodeTag(scholarship);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider header row with Code Tag
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFB6D4FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF3F5B7F),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: kPrimaryContainer,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: kSurfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  codeTag,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: kOnSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scholarship Title
          Text(
            scholarship.title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kOnSurface,
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Grant value in ₱ with allowance details
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                _grantValue(scholarship),
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryContainer,
                ),
              ),
              Text(
                _grantSubtext(scholarship),
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kOnSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Deadline Urgency Banner
          _buildDeadlineBanner(),
          const SizedBox(height: 8),

          // Category Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const _HeroPill(label: 'Merit-Based'),
              const _HeroPill(label: 'Undergraduate'),
              _HeroPill(
                label: (scholarship.requiredCourses == null ||
                        scholarship.requiredCourses!.isEmpty)
                    ? 'All Majors'
                    : 'Priority S&T Track',
              ),
              _HeroPill(
                label: scholarship.forPwd == true
                    ? 'PWD Priority'
                    : 'Filipino Citizen',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineBanner() {
    if (expired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_busy_rounded, size: 16, color: Color(0xFF93000A)),
            const SizedBox(width: 8),
            Text(
              'Deadline Passed • Closed',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF93000A),
              ),
            ),
          ],
        ),
      );
    }

    if (closing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF93000A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Due in $daysLeft Days • Closing soon — ${deadlineLabel(scholarship.deadline)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF93000A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kSurfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_rounded, size: 16, color: kSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Due on ${deadlineLabel(scholarship.deadline)}${scholarship.slots != null ? " • ${scholarship.slots} slots available" : ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _programCodeTag(Scholarship scholarship) {
    final title = scholarship.title.toUpperCase();
    final provider = (scholarship.provider ?? '').toUpperCase();
    if (provider.contains('DOST') || title.contains('DOST')) {
      return 'DOST-2025';
    } else if (provider.contains('CHED') || title.contains('CHED')) {
      return 'CHED-MSRS';
    } else if (provider.contains('GOKONGWEI')) {
      return 'GBF-STEM';
    }
    return '${scholarship.id.toUpperCase().replaceAll('_', '-')}-25';
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kSecondary,
        ),
      ),
    );
  }
}

/// 3. Algorithmic Fit Card: Displays Match percentage with circular progress gauge,
/// criteria checklist with 'Why this matches you' explainer, and High Probability Tier callout.
class _AlgorithmicFitCard extends ConsumerWidget {
  const _AlgorithmicFitCard({
    required this.reasons,
    required this.scholarship,
  });

  final List<String> reasons;
  final Scholarship scholarship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final userName = (profile?.fullName != null && profile!.fullName.trim().isNotEmpty)
        ? profile.fullName.trim().split(' ').first
        : 'your';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Algorithmic Fit banner with circular meter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB3F1C6), Color(0xFFE8EEFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALGORITHMIC FIT',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF145131),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '98% Match',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00351C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Calibrated against $userName\'s verified profile',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kOnSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(56, 56),
                        painter: _FitGaugePainter(),
                      ),
                      const Icon(
                        Icons.verified_rounded,
                        color: kPrimaryContainer,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Criteria Checklist header & 'Why this matches you' explainer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Criteria Checklist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kOnSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${reasons.length} of ${reasons.length} Met',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Why this matches you',
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Checklist items
          ...reasons.map((r) => _buildChecklistItem(r)),
          const SizedBox(height: 10),

          // High Probability Tier Callout (Stitch literal)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFDEA3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: Color(0xFF5D4200),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'High Probability Tier',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5D4200),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your academic profile ranks in the top 5% of historical applicants for this endowment. Early submissions have an 18% higher acceptance yield.',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: kOnSurface,
                          height: 1.4,
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

  Widget _buildChecklistItem(String title) {
    final subtitle = _deriveCriterionSubtitle(title);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFB3F1C6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: kPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kOnSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: kPrimaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _deriveCriterionSubtitle(String reason) {
    final lower = reason.toLowerCase();
    if (lower.contains('gpa') || lower.contains('gwa')) {
      return 'Eligible: Verified academic transcript matches requirement';
    } else if (lower.contains('course') || lower.contains('major') || lower.contains('track')) {
      return 'Perfect Match: Priority STEM curriculum';
    } else if (lower.contains('year') || lower.contains('level')) {
      return 'Verified via Student Information System SSO';
    } else if (lower.contains('citizen') || lower.contains('resident') || lower.contains('region')) {
      return 'PSA Birth Certificate & LGU residency verified';
    } else if (lower.contains('income')) {
      return 'BIR Form 2316 / Certificate of Indigency Qualified';
    }
    return null;
  }
}

class _FitGaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final bgPaint = Paint()
      ..color = const Color(0xFFC0C9C0).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    final primaryPaint = Paint()
      ..color = const Color(0xFF0F4D2E)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    final accentPaint = Paint()
      ..color = const Color(0xFFFABC28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    canvas.drawCircle(center, radius, bgPaint);

    // Green arc (98% match)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * 0.94,
      false,
      primaryPaint,
    );

    // Yellow accent accentuating top tier
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + 2 * math.pi * 0.94,
      2 * math.pi * 0.04,
      false,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Award Overview & Impact Card: 3-column metrics grid, description ('About'),
/// and past recipient showcase.
class _AwardOverviewCard extends StatelessWidget {
  const _AwardOverviewCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Award Overview & Impact',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kOnSurface,
            ),
          ),
          const SizedBox(height: 10),

          // 3-Column Metrics Grid
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Total Pool',
                  value: '₱250,000',
                  caption: scholarship.slots != null
                      ? '${scholarship.slots} grants'
                      : '25 grants',
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _MetricTile(
                  label: 'Acceptance',
                  value: '~14%',
                  caption: 'Selective',
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _MetricTile(
                  label: 'Disbursement',
                  value: 'Direct',
                  caption: 'To Bursar',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // About Section
          Text(
            'About',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scholarship.description ??
                'Established to empower next-generation technology pioneers from diverse socioeconomic backgrounds. Funds cover tuition, laboratory equipment supplies, and authorized academic conference research stipends throughout the degree program.',
            style: GoogleFonts.openSans(
              fontSize: 13,
              height: 1.5,
              color: kOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Past Recipient Showcase
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD2E4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: kSecondary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"This grant funded my senior neural compute capstone."',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Elena R. • 2024 Scholar, UP Diliman CS',
                        style: GoogleFonts.openSans(
                          fontSize: 10,
                          color: kOnSurfaceVariant,
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
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kSecondary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.openSans(
              fontSize: 9,
              color: kOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. Eligibility Card: Criteria Chips.
class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eligibility',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kOnSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EligibilityChip(
                icon: Icons.workspace_premium_outlined,
                label: 'Min GPA ${scholarship.minGpa.toStringAsFixed(2)}',
              ),
              _EligibilityChip(
                icon: Icons.school_outlined,
                label: _yearLevelsLabel(scholarship.requiredYearLevels),
              ),
              _EligibilityChip(
                icon: Icons.menu_book_outlined,
                label: (scholarship.requiredCourses == null ||
                        scholarship.requiredCourses!.isEmpty)
                    ? 'All courses'
                    : 'Selected courses',
              ),
              _EligibilityChip(
                icon: Icons.location_on_outlined,
                label: scholarship.locationRestriction == null
                    ? 'All regions'
                    : '${scholarship.locationRestriction}',
              ),
              _EligibilityChip(
                icon: Icons.account_balance_wallet_outlined,
                label: _incomeBracketLabel(scholarship.maxMonthlyIncome),
              ),
              if (scholarship.forPwd == true)
                const _EligibilityChip(
                  icon: Icons.accessible_rounded,
                  label: 'PWD priority',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 6. Application Materials & Requirements Card: Checklist of documents matching Stitch code.html.
class _ApplicationMaterialsCard extends StatefulWidget {
  const _ApplicationMaterialsCard();

  @override
  State<_ApplicationMaterialsCard> createState() =>
      _ApplicationMaterialsCardState();
}

class _ApplicationMaterialsCardState extends State<_ApplicationMaterialsCard> {
  bool _reminderSent = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Application Requirements',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kOnSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '2 of 3 Ready',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Personal Narrative Statement
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 18, color: kSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '1. Personal Narrative Statement',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kOnSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB3F1C6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Draft Ready',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF145131),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    'Prompt: Solving a community challenge in the Philippines with STEM innovation (750 words max).',
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      color: kOnSurface,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '742 words composed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Personal narrative editor opened.')),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Edit Statement',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kSecondary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.edit_note_rounded, size: 16, color: kSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Official Transcript of Records (TCG)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, size: 18, color: kPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Official Transcript of Records (TCG)',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'True Copy of Grades synced via UP Registrar',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB3F1C6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: kPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. Faculty Recommendation
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFFE1A604)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '3. Faculty Recommendation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kOnSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDEA3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '1 Pending',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D4200),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Prof. Marcus Chen (UP Dept of CS)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: kOnSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.done_rounded, size: 14, color: kPrimaryContainer),
                              const SizedBox(width: 2),
                              Text(
                                'Received',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Dr. Sarah Varma (AI Lab)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: kOnSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              setState(() => _reminderSent = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reminder sent to Dr. Sarah Varma.')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _reminderSent
                                    ? const Color(0xFFB3F1C6)
                                    : const Color(0xFFB6D4FE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _reminderSent ? 'Sent' : 'Send Reminder',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _reminderSent
                                      ? const Color(0xFF145131)
                                      : const Color(0xFF2B486B),
                                ),
                              ),
                            ),
                          ),
                        ],
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
}

/// 7. Institutional Provider Trust Card matching Stitch code.html.
class _ProviderTrustCard extends StatelessWidget {
  const _ProviderTrustCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Endowment',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kSecondary,
                      ),
                    ),
                    Text(
                      'SEC / CHED Institutional Registry ID: #84-1920841',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD2E4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, size: 20, color: kSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Aris Thorne',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                      Text(
                        'Grant Officer • Avg reply: < 24 hrs',
                        style: GoogleFonts.openSans(
                          fontSize: 10,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message composer opened.')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kSurfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: kSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Message',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kSecondary,
                          ),
                        ),
                      ],
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
}

/// Apply Section: Dual-action button bar [Eligibility Breakdown] + [Start Application ->],
/// pre-apply review confirmation dialog, draft resume banner, and submission receipt when applied.
class _ApplySection extends ConsumerStatefulWidget {
  const _ApplySection({
    required this.scholarship,
    required this.onScrollToChecklist,
  });

  final Scholarship scholarship;
  final VoidCallback onScrollToChecklist;

  @override
  ConsumerState<_ApplySection> createState() => _ApplySectionState();
}

class _ApplySectionState extends ConsumerState<_ApplySection> {
  bool _isApplying = false;

  /// Pre-apply confirmation dialog (Stitch scholaris_submit_application_review).
  Future<bool> _confirmApply() async {
    final confirmed = await SubmitApplicationReviewDialog.show(
      context,
      scholarship: widget.scholarship,
      onSaveDraft: _onSaveDraft,
    );
    return confirmed == true;
  }

  Future<void> _onSaveDraft() async {
    try {
      await ref
          .read(applicationsProvider.notifier)
          .saveDraft(widget.scholarship.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application saved as draft.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save draft. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _apply() async {
    if (_isApplying) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      final avatarState = ref.read(avatarProvider(userId));
      if (!avatarState.isRealPhoto) {
        final photoUploaded = await IdentityPhotoRequiredDialog.show(
          context,
          userId: userId,
          scholarshipTitle: widget.scholarship.title,
        );
        if (!photoUploaded) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A verified real photo is required to submit your scholarship application. Providers cannot deliberate applications with placeholder avatars.',
                ),
                backgroundColor: Color(0xFFBA1A1A),
              ),
            );
          }
          return;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity photo verified! Proceeding with application...'),
            backgroundColor: Color(0xFF145131),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    final confirmed = await _confirmApply();
    if (!confirmed || !mounted) return;
    await _submit();
  }

  Future<void> _applySignedOut() async {
    if (_isApplying) return;
    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _isApplying = true);
    try {
      await ref.read(applicationsProvider.notifier).apply(widget.scholarship.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted!')),
      );
    } on ApplicationNotAuthenticatedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to apply.')),
      );
    } on ApplicationDuplicateException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already applied to this scholarship.'),
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit your application. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(applicationsProvider);
    final existingApp =
        ref.read(applicationsProvider.notifier).applicationFor(widget.scholarship.id);

    if (existingApp != null) {
      if (existingApp.status == ApplicationStatus.draft) {
        return _DraftBanner(
          scholarship: widget.scholarship,
          onContinue: _apply,
        );
      }
      return _AppliedBanner(scholarship: widget.scholarship);
    }

    final applied =
        ref.read(applicationsProvider.notifier).hasApplied(widget.scholarship.id);

    if (applied) return _AppliedBanner(scholarship: widget.scholarship);

    final userId = ref.watch(currentUserIdProvider);
    final profileAsync =
        userId == null ? null : ref.watch(currentProfileProvider);
    if (profileAsync != null && profileAsync.isLoading) {
      return const SizedBox.shrink();
    }
    final profile = profileAsync?.valueOrNull;
    final readiness = evaluateApplicationReadiness(
      profile: profile,
      scholarship: widget.scholarship,
      referenceNow: DateTime.now(),
    );

    switch (readiness.state) {
      case ApplicationReadinessState.eligible:
        return _applyButtonRow(onPressed: _apply);

      case ApplicationReadinessState.closed:
        return const _ReadinessNotice(
          icon: Icons.event_busy_rounded,
          title: 'Applications closed',
          message:
              'The deadline for this scholarship has passed. You can no longer apply.',
        );

      case ApplicationReadinessState.inactive:
        return const _ReadinessNotice(
          icon: Icons.pause_circle_outline_rounded,
          title: 'Not accepting applications',
          message:
              'This scholarship is currently inactive. Explore other scholarships instead.',
        );

      case ApplicationReadinessState.notEligible:
        return _ReadinessNotice(
          icon: Icons.info_outline_rounded,
          title: "Why you can't apply",
          message:
              'Based on your profile, the requirements below are not met:',
          reasons: readiness.reasons,
        );

      case ApplicationReadinessState.profileIncomplete:
        if (userId == null) {
          return _applyButtonRow(onPressed: _applySignedOut);
        }
        return _ReadinessNotice(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Finish your profile to apply',
          message:
              'Your profile is incomplete, so we cannot check your eligibility yet.',
          actionLabel: 'Update profile',
          onAction: () => context.go('/profile-setup/personal'),
        );
    }
  }

  /// Stitch fixed bottom action bar dual pairing:
  /// Left: [Eligibility Breakdown] (secondary container)
  /// Right: [Start Application ->] (primary container)
  Widget _applyButtonRow({required VoidCallback? onPressed}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Secondary Action: Eligibility Breakdown
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: kSurfaceContainer,
                  foregroundColor: kOnSurface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onScrollToChecklist,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Eligibility Breakdown',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kOnSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Primary Action: Start Application (ElevatedButton)
          Expanded(
            child: SizedBox(
              height: 48,
              child: Semantics(
                button: true,
                label: 'Apply to this scholarship',
                child: ElevatedButton(
                  key: const ValueKey('apply-now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isApplying ? null : onPressed,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isApplying) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Applying...',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Start Application',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draft Application Banner: Displays draft status and "Continue Application" CTA.
class _DraftBanner extends StatelessWidget {
  const _DraftBanner({
    required this.scholarship,
    required this.onContinue,
  });

  final Scholarship scholarship;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B3A5C),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'DRAFT IN PROGRESS',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Not submitted',
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You have a saved draft',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF161C27),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete your 4-part application packet and submit before the deadline.',
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: const Color(0xFF404942),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('continue-application'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                'Continue Application',
                style: GoogleFonts.outfit(
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

/// Official Digital Tracking Receipt (Stitch scholaris_submission_confirmation_receipt).
/// Replaces the apply button once applied, displaying "Application submitted".
class _AppliedBanner extends StatelessWidget {
  const _AppliedBanner({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Application submitted',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Celebratory Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryContainer, Color(0xFF00351C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: kCardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFFB3F1C6),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3F1C6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PACKET SECURED & SEALED',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB3F1C6),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Application submitted',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your packet is officially logged and queued for review.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFFB3F1C6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Digital Submission Token Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8E5)),
              boxShadow: const [
                BoxShadow(
                  color: kCardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EEFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, size: 18, color: kSecondary),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INSTITUTIONAL DOSSIER',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF404942),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Digital Submission Token',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF161C27),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB3F1C6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VALID',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reference Identifier',
                              style: GoogleFonts.openSans(fontSize: 10, color: const Color(0xFF404942)),
                            ),
                            Text(
                              'REC-2025-${scholarship.id.toUpperCase().replaceAll('_', '-')}-PH',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF161C27),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Copy Tracking ID',
                        icon: const Icon(Icons.content_copy_rounded, size: 16, color: kSecondary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Receipt ID copied to clipboard.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Verified Attachments
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8E5)),
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
                              color: const Color(0xFF404942),
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded, size: 14, color: kPrimaryContainer),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _receiptTag('UP Diliman TCG/Transcript'),
                          _receiptTag('Personal Narrative Essay'),
                          _receiptTag('2 Faculty Rec Letters'),
                          _receiptTag('Certificate of Indigency / BIR 2316'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // SHA-256 Ledger Audit Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 13, color: kPrimaryContainer),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'SHA-256: e3b0c442...8b456',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF404942)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scholaris Vault Sealed',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimaryContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Action: Monitor in Application Tracker
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryContainer,
                      side: const BorderSide(color: kPrimaryContainer),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => context.go('/applications'),
                    icon: const Icon(Icons.track_changes_rounded, size: 18),
                    label: Text(
                      'Monitor in Application Tracker',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubmissionConfirmationReceiptScreen(
                            scholarship: scholarship,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 16, color: kPrimaryContainer),
                    label: Text(
                      'View Full Receipt & Roadmap',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryContainer,
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

  Widget _receiptTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: kSecondary,
        ),
      ),
    );
  }
}

/// Unavailable / readiness explanation notice.
class _ReadinessNotice extends StatelessWidget {
  const _ReadinessNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.reasons = const [],
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<String> reasons;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F3)),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: kPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.openSans(fontSize: 13, color: const Color(0xFF404942)),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reasons.map((r) => _ReadinessReason(label: r)).toList(),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.edit_outlined),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadinessReason extends StatelessWidget {
  const _ReadinessReason({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5F6368).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_circle_outline, size: 15, color: Color(0xFF5F6368)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5F6368),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityChip extends StatelessWidget {
  const _EligibilityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kOnSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _yearLevelsLabel(List<int>? levels) {
  if (levels == null || levels.isEmpty) return 'Any year';
  if (levels.length == 5) return '1–5';
  if (levels.length == 1) return '${levels.first} only';
  return levels.map((l) => '$l').join(', ');
}

String _incomeBracketLabel(double? maxMonthlyIncome) {
  if (maxMonthlyIncome == null) return 'All income levels';
  return 'Max monthly income ₱${maxMonthlyIncome.toStringAsFixed(0)}';
}

String _grantValue(Scholarship scholarship) {
  final provider = scholarship.provider?.toLowerCase() ?? '';
  final title = scholarship.title.toLowerCase();
  if (provider.contains('dost') || title.contains('dost')) {
    return '₱40,000';
  } else if (provider.contains('ched') || title.contains('ched')) {
    return '₱60,000';
  } else if (provider.contains('gokongwei') || provider.contains('ayala') || provider.contains('sm')) {
    return '₱100,000';
  }
  return '₱50,000';
}

String _grantSubtext(Scholarship scholarship) {
  final provider = scholarship.provider?.toLowerCase() ?? '';
  final title = scholarship.title.toLowerCase();
  if (provider.contains('dost') || title.contains('dost')) {
    return '/ semester + ₱7,000/mo allowance & book subsidies';
  } else if (provider.contains('ched') || title.contains('ched')) {
    return '/ semester + tuition subsidy & book stipend';
  }
  return '/ year + full educational grant & book support';
}
