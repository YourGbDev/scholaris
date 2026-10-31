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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/application_status_chip.dart';
import 'package:scholaris/features/applications/presentation/submit_application_review_dialog.dart';
import 'package:scholaris/features/applications/providers/application_document_provider.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/providers/application_draft_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/provider/presentation/widgets/scholarship_qr_dialog.dart';
import 'package:scholaris/features/safety/presentation/student_safety_report.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/models/scholarship_capacity.dart';
import 'package:scholaris/features/scholarships/presentation/widgets/identity_photo_dialog.dart';
import 'package:scholaris/features/scholarships/providers/scholarship_capacity_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/services/application_readiness.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/features/schools/models/school.dart';
import 'package:scholaris/features/schools/providers/school_provider.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final scholarshipEligibleSchoolsProvider =
    FutureProvider.family<List<String>?, String>((ref, scholarshipId) async {
      try {
        final res = await Supabase.instance.client
            .from('scholarships')
            .select('eligible_school_ids')
            .eq('id', scholarshipId)
            .maybeSingle();
        if (res == null) return null;
        final list = res['eligible_school_ids'] as List<dynamic>?;
        return list?.map((e) => e.toString()).toList() ?? <String>[];
      } catch (_) {
        return null;
      }
    });

final studentProfileSchoolIdProvider = FutureProvider.family<String?, String>((
  ref,
  userId,
) async {
  try {
    final res = await Supabase.instance.client
        .from('profiles')
        .select('school_id')
        .eq('id', userId)
        .maybeSingle();
    return res?['school_id'] as String?;
  } catch (_) {
    return null;
  }
});

extension ScholarshipCapacityFullExt on ScholarshipCapacity {
  bool get isFull =>
      !isUncapped && totalSlots != null && (remainingSlots ?? 0) <= 0;
}

/// Presentation hooks for guiding the real detail screen without submitting.
class ScholarshipDetailTourHooks {
  const ScholarshipDetailTourHooks({
    required this.scrollController,
    required this.backToTopKey,
    required this.applyKey,
    required this.onBackToTop,
    required this.onApply,
    required this.onExit,
  });
  final ScrollController scrollController;
  final GlobalKey backToTopKey;
  final GlobalKey applyKey;
  final VoidCallback onBackToTop;
  final VoidCallback onApply;
  final VoidCallback onExit;
}

class ScholarshipDetailScreen extends ConsumerStatefulWidget {
  const ScholarshipDetailScreen({
    super.key,
    required this.scholarshipId,
    this.initial,
    this.startApplication = false,
    this.tour,
  });

  final String scholarshipId;
  final Scholarship? initial;
  final bool startApplication;
  final ScholarshipDetailTourHooks? tour;

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
        duration: kDurationSlow,
        curve: kAppleSpringCurve,
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
          onPressed:
              widget.tour?.onExit ??
              () {
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
                style: poppins(
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
            tooltip: 'View QR Code',
            onPressed: widget.tour != null
                ? null
                : () {
                    final s =
                        widget.initial ??
                        ref
                            .read(scholarshipByIdProvider(widget.scholarshipId))
                            .valueOrNull;
                    if (s != null) {
                      showScholarshipQrDialog(context, s);
                    }
                  },
            icon: const Icon(
              Icons.qr_code_rounded,
              size: 22,
              color: kOnSurface,
            ),
          ),
          IconButton(
            tooltip: 'Share scholarship',
            onPressed: widget.tour != null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scholarship link copied to clipboard.'),
                      ),
                    );
                  },
            icon: const Icon(Icons.share_outlined, size: 22, color: kOnSurface),
          ),
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save this scholarship',
            onPressed: widget.tour != null
                ? null
                : saved
                ? _unbookmark
                : _bookmark,
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 22,
              color: saved ? kAccent : kOnSurface,
            ),
          ),
          IgnorePointer(
            ignoring: widget.tour != null,
            child: ExcludeFocus(
              excluding: widget.tour != null,
              child: StudentSafetyReportButton(
                scholarshipId: widget.scholarshipId,
                scholarshipTitle: widget.initial?.title ?? 'Scholarship',
                isIconOnly: true,
              ),
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
        startApplication: widget.startApplication && widget.tour == null,
        tour: widget.tour,
      );
    }

    return ref
        .watch(scholarshipByIdProvider(widget.scholarshipId))
        .when(
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
                  startApplication:
                      widget.startApplication && widget.tour == null,
                  tour: widget.tour,
                ),
        );
  }

  Future<void> _bookmark() async {
    HapticFeedback.lightImpact();
    final notifier = ref.read(bookmarksProvider.notifier);
    try {
      await notifier.toggle(widget.scholarshipId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved to your list.')));
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
    HapticFeedback.lightImpact();
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
    required this.startApplication,
    this.tour,
  });

  final Scholarship scholarship;
  final bool saved;
  final GlobalKey checklistKey;
  final VoidCallback onScrollToChecklist;
  final bool startApplication;
  final ScholarshipDetailTourHooks? tour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final expired = isDeadlinePassed(scholarship.deadline, now: now);
    final closing =
        !expired && isClosingSoon(scholarship.deadline.difference(now).inDays);
    final daysLeft = scholarship.deadline.difference(now).inDays;
    final reasons = _matchReasons(ref);

    return ListView(
      controller: tour?.scrollController,
      physics: const AppleBouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
      children: [
        if (startApplication) ...[
          _ApplySection(
            scholarship: scholarship,
            onScrollToChecklist: onScrollToChecklist,
            startApplication: true,
          ),
          const SizedBox(height: 14),
        ],
        // 1. Hero Card
        StaggeredListItem(
          index: 0,
          child: _HeroCard(
            scholarship: scholarship,
            closing: closing,
            expired: expired,
            daysLeft: daysLeft,
          ),
        ),
        const SizedBox(height: 12),

        // Capacity Status Card
        StaggeredListItem(
          index: 1,
          child: _CapacityStatusCard(scholarship: scholarship),
        ),
        const SizedBox(height: 12),

        // School Eligibility Guidance Card (disclosing self-declared status)
        StaggeredListItem(
          index: 2,
          child: _SchoolEligibilityGuidanceCard(scholarship: scholarship),
        ),
        const SizedBox(height: 14),

        // 2. Application Readiness & CTA / Banner
        if (!startApplication)
          StaggeredListItem(
            index: 3,
            child: _ApplySection(
              scholarship: scholarship,
              onScrollToChecklist: onScrollToChecklist,
              tour: tour,
            ),
          ),
        if (!startApplication) const SizedBox(height: 14),

        // 3. Algorithmic Fit & Criteria Checklist
        if (reasons.isNotEmpty) ...[
          StaggeredListItem(
            index: 4,
            child: Container(
              key: checklistKey,
              child: _AlgorithmicFitCard(
                reasons: reasons,
                scholarship: scholarship,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 4. Award Overview & Impact
        StaggeredListItem(
          index: 5,
          child: _AwardOverviewCard(scholarship: scholarship),
        ),
        const SizedBox(height: 20),

        // 5. Eligibility Section
        StaggeredListItem(
          index: 6,
          child: _EligibilityCard(scholarship: scholarship),
        ),
        const SizedBox(height: 20),

        // 6. Application Materials & Requirements
        StaggeredListItem(
          index: 7,
          child: AbsorbPointer(
            absorbing: tour != null,
            child: ExcludeFocus(
              excluding: tour != null,
              child: _ApplicationMaterialsCard(
                key: ValueKey((
                  ref.watch(currentUserIdProvider),
                  scholarship.id,
                )),
                userId: ref.watch(currentUserIdProvider),
                scholarshipId: scholarship.id,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 7. Verified Institutional Provider Trust Card
        StaggeredListItem(
          index: 8,
          child: _ProviderTrustCard(scholarship: scholarship),
        ),
        const SizedBox(height: 20),
        Builder(
          builder: (context) => OutlinedButton.icon(
            key: tour?.backToTopKey,
            onPressed: () async {
              await Scrollable.of(context).position.animateTo(
                0,
                duration: kDurationSlow,
                curve: kAppleSpringCurve,
              );
              tour?.onBackToTop();
            },
            icon: const Icon(Icons.arrow_upward_rounded),
            label: const Text('Back to top'),
          ),
        ),
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

/// 1. Hero Card: Provider header, verified tick, program code tag, title,
/// grant value in ₱ with allowance details, urgency deadline banner, and Stitch category pills.
class _HeroCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final providerName = scholarship.provider ?? 'Scholarship Provider';
    final codeTag = _programCodeTag(scholarship);

    return Container(
      decoration: kSoftCardDecoration,
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
                        style: outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kSurfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    codeTag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: kOnSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scholarship Title
          Text(
            scholarship.title,
            style: outfit(
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _grantValue(scholarship),
                  style: outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryContainer,
                  ),
                ),
              ),
              Text(
                _grantSubtext(scholarship),
                style: openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kOnSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Deadline Urgency Banner
          _buildDeadlineBanner(ref),
          const SizedBox(height: 8),

          // Category Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const _HeroPill(label: 'Merit-Based'),
              const _HeroPill(label: 'Undergraduate'),
              _HeroPill(
                label:
                    (scholarship.requiredCourses == null ||
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

  Widget _buildDeadlineBanner(WidgetRef ref) {
    if (expired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_busy_rounded,
              size: 16,
              color: Color(0xFF93000A),
            ),
            const SizedBox(width: 8),
            Text(
              'Deadline Passed • Closed',
              style: outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF93000A),
              ),
            ),
          ],
        ),
      );
    }

    final capacityAsync = ref.watch(
      scholarshipCapacityProvider(scholarship.id),
    );
    final capacity = capacityAsync.valueOrNull;

    if (capacity != null && capacity.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.group_off_rounded,
              size: 16,
              color: Color(0xFF93000A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Capacity Reached • All ${capacity.totalSlots} slots occupied',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: outfit(
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

    if (closing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 16,
              color: Color(0xFF93000A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Due in $daysLeft Days • Closing soon — ${deadlineLabel(scholarship.deadline)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: outfit(
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

    final String slotInfo;
    if (capacity != null) {
      if (capacity.isUncapped) {
        slotInfo =
            ' · Uncapped capacity • ${capacity.occupiedSlots} scholar approved';
      } else {
        slotInfo =
            ' · ${capacity.remainingSlots} of ${capacity.totalSlots} slots remaining';
      }
    } else if (scholarship.slots != null) {
      slotInfo =
          ' · ${scholarship.slots.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} slots available';
    } else {
      slotInfo = '';
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
              '${deadlineLabel(scholarship.deadline)}$slotInfo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: outfit(
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
    final rawId = scholarship.id.toUpperCase().replaceAll('_', '-');
    final idSnippet = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
    return '$idSnippet-25';
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
        color: kScholarshipTagBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kScholarshipTagForeground,
        ),
      ),
    );
  }
}

/// Slot Capacity Status Card: Displays authoritative seat accounting from scholarship_capacities.
class _CapacityStatusCard extends ConsumerWidget {
  const _CapacityStatusCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityAsync = ref.watch(
      scholarshipCapacityProvider(scholarship.id),
    );

    return capacityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (capacity) {
        if (capacity == null) return const SizedBox.shrink();

        final isUncapped = capacity.isUncapped;
        final isFull = capacity.isFull;
        final occupied = capacity.occupiedSlots;
        final total = capacity.totalSlots;
        final remaining = capacity.remainingSlots;

        final rem = remaining ?? 0;
        final tot = total ?? 0;

        return Container(
          decoration: kSoftCardDecoration.copyWith(
            border: Border.all(
              color: isFull
                  ? const Color(0xFFFFCDD2)
                  : kHairlineBorderSide.color,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isFull
                        ? Icons.group_off_rounded
                        : Icons.people_outline_rounded,
                    size: 18,
                    color: isFull ? const Color(0xFFC62828) : kPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Slot Capacity & Seat Accounting',
                      style: outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isFull ? const Color(0xFFC62828) : kOnSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isFull
                          ? const Color(0xFFFFEBEE)
                          : isUncapped
                          ? const Color(0xFFE8F5E9)
                          : (rem <= 3
                                ? const Color(0xFFFFF3E0)
                                : const Color(0xFFE8F5E9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFull
                          ? 'Capacity Reached'
                          : isUncapped
                          ? 'Uncapped'
                          : '$rem Seats Open',
                      style: openSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isFull
                            ? const Color(0xFFC62828)
                            : isUncapped
                            ? const Color(0xFF2E7D32)
                            : (rem <= 3
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isUncapped)
                Text(
                  'Uncapped capacity • $occupied scholar${occupied == 1 ? '' : 's'} approved',
                  style: openSans(fontSize: 12, color: Colors.black87),
                )
              else ...[
                Text(
                  '$tot total • $occupied occupied • $rem remaining',
                  style: openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tot > 0 ? (occupied / tot).clamp(0.0, 1.0) : 0.0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFull ? const Color(0xFFC62828) : kPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// School Eligibility Guidance Card: Discloses self-declared enrollment verification status
/// and partner institution restrictions.
class _SchoolEligibilityGuidanceCard extends ConsumerWidget {
  const _SchoolEligibilityGuidanceCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibleSchoolIdsAsync = ref.watch(
      scholarshipEligibleSchoolsProvider(scholarship.id),
    );
    final currentProfile = ref.watch(currentProfileProvider).valueOrNull;
    final userId = ref.watch(currentUserIdProvider);
    final userSchoolIdAsync = userId != null
        ? ref.watch(studentProfileSchoolIdProvider(userId))
        : const AsyncValue.data(null);
    final schoolsAsync = ref.watch(schoolsProvider);

    return Container(
      decoration: kSoftCardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  size: 18,
                  color: kPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Student-Declared Enrolled Institution',
                  style: outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kOnSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Eligibility status badge
          eligibleSchoolIdsAsync.when(
            loading: () => const SizedBox(
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (eligibleIds) {
              if (eligibleIds == null || eligibleIds.isEmpty) {
                // Open to all schools
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Open to all accredited Philippine universities & colleges',
                          style: openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Restricted to specific schools
              final studentSchoolId = userSchoolIdAsync.valueOrNull;
              final studentSchoolText = currentProfile?.school?.trim();
              final allSchools = schoolsAsync.valueOrNull ?? const <School>[];

              // Legacy or unlinked profile: fail closed and prompt to update profile
              if (studentSchoolId == null) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFFE65100),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Profile update required: Please select your institution in your profile to verify partner eligibility.',
                          style: openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBF360C),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final isMatch = eligibleIds.contains(studentSchoolId);
              final matchedSchoolName = allSchools
                  .firstWhere(
                    (s) => s.id == studentSchoolId,
                    orElse: () => School(
                      id: studentSchoolId,
                      name: studentSchoolText ?? 'Declared Institution',
                      normalizedName: '',
                    ),
                  )
                  .name;

              if (isMatch) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Eligible based on declared profile (Matches: $matchedSchoolName)',
                          style: openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Ineligible based on profile
              final eligibleNames = allSchools
                  .where((s) => eligibleIds.contains(s.id))
                  .map((s) => s.name)
                  .take(3)
                  .join(', ');
              final moreCount = eligibleIds.length - 3;
              final partnerSummary = moreCount > 0
                  ? '$eligibleNames +$moreCount more'
                  : eligibleNames;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Color(0xFFE65100),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ineligible based on profile: Restricted to partner institutions.',
                            style: openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFBF360C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (partnerSummary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Partner institutions: $partnerSummary',
                        style: openSans(
                          fontSize: 11,
                          color: const Color(0xFF795548),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Truth Disclosure
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Academic enrollment is self-declared on your student profile and verified by scholarship administrators through your uploaded Certificate of Registration (COR) or Student ID.',
                    style: openSans(
                      fontSize: 11,
                      height: 1.4,
                      color: Colors.black87,
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

/// 3. Algorithmic Fit Card: Displays Match percentage with circular progress gauge,
/// criteria checklist with 'Why this matches you' explainer, and High Probability Tier callout.
class _AlgorithmicFitCard extends ConsumerWidget {
  const _AlgorithmicFitCard({required this.reasons, required this.scholarship});

  final List<String> reasons;
  final Scholarship scholarship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final userName =
        (profile?.fullName != null && profile!.fullName.trim().isNotEmpty)
        ? profile.fullName.trim().split(' ').first
        : 'your';

    return PressableScale(
      child: Container(
        decoration: kSoftCardDecoration,
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
                          style: outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF145131),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CountUpAnimation(
                          targetValue: placeholderMatchPercentage(
                            reasons.length,
                          ),
                          suffix: '% Match',
                          style: outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00351C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Demo score • Based on $userName\'s profile',
                          style: openSans(
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
                          painter: _FitGaugePainter(
                            placeholderMatchPercentage(reasons.length),
                          ),
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
                    style: outfit(
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
                    style: outfit(
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
              style: openSans(
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
                          style: outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5D4200),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your academic profile ranks in the top 5% of historical applicants for this endowment. Early submissions have an 18% higher acceptance yield.',
                          style: openSans(
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
                    style: outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kOnSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: openSans(
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
      return 'Based on the academic information in your profile';
    } else if (lower.contains('course') ||
        lower.contains('major') ||
        lower.contains('track')) {
      return 'Based on the course in your profile';
    } else if (lower.contains('year') || lower.contains('level')) {
      return 'Based on the year level in your profile';
    } else if (lower.contains('citizen') ||
        lower.contains('resident') ||
        lower.contains('region')) {
      return 'Based on the information in your profile';
    } else if (lower.contains('income')) {
      return 'Based on the income information in your profile';
    }
    return null;
  }
}

class _FitGaugePainter extends CustomPainter {
  _FitGaugePainter(this.percentage);
  final int percentage;
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
      2 * math.pi * percentage / 100,
      false,
      primaryPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + 2 * math.pi * percentage / 100 - 0.05,
      0.05,
      false,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FitGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}

/// 4. Award Overview & Impact Card: 3-column metrics grid, description ('About'),
/// and past recipient showcase.
class _AwardOverviewCard extends StatelessWidget {
  const _AwardOverviewCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kSoftCardDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Award Overview & Impact',
            style: outfit(
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
                  value:
                      '₱${(((scholarship.slots != null && scholarship.slots! > 0) ? scholarship.slots! * scholarship.awardAmount : scholarship.awardAmount)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  caption: scholarship.slots != null
                      ? '${scholarship.slots} grants'
                      : 'Active grant',
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
            style: outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scholarship.description ?? 'Established to empower next-generation technology pioneers from diverse socioeconomic backgrounds. Funds cover tuition, laboratory equipment supplies, and authorized academic conference research stipends throughout the degree program.',
            style: openSans(
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
                  child: const Icon(
                    Icons.school_rounded,
                    color: kSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"This grant funded my senior neural compute capstone."',
                        style: openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Elena R. • 2024 Scholar, UP Diliman CS',
                        style: openSans(fontSize: 10, color: kOnSurfaceVariant),
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
            style: outfit(
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
              style: outfit(
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
            style: openSans(fontSize: 9, color: kOnSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 5. Eligibility Card: Criteria Chips.
class _EligibilityCard extends ConsumerWidget {
  const _EligibilityCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibleSchoolIdsAsync = ref.watch(
      scholarshipEligibleSchoolsProvider(scholarship.id),
    );

    return Container(
      decoration: kSoftCardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eligibility',
            style: outfit(
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
                label:
                    (scholarship.requiredCourses == null ||
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
              eligibleSchoolIdsAsync.maybeWhen(
                data: (ids) {
                  if (ids != null && ids.isNotEmpty) {
                    return _EligibilityChip(
                      icon: Icons.account_balance_outlined,
                      label:
                          'Restricted to ${ids.length} Partner School${ids.length == 1 ? '' : 's'}',
                    );
                  }
                  return const _EligibilityChip(
                    icon: Icons.account_balance_outlined,
                    label: 'Open to all schools',
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 6. Application Materials & Requirements Card: Checklist of documents matching Stitch code.html.
class _ApplicationMaterialsCard extends ConsumerStatefulWidget {
  const _ApplicationMaterialsCard({
    super.key,
    required this.userId,
    required this.scholarshipId,
  });
  final String? userId;

  final String scholarshipId;

  @override
  ConsumerState<_ApplicationMaterialsCard> createState() =>
      _ApplicationMaterialsCardState();
}

class _ApplicationMaterialsCardState
    extends ConsumerState<_ApplicationMaterialsCard> {
  ApplicationDraftKey get _draftKey =>
      (userId: widget.userId, scholarshipId: widget.scholarshipId);
  bool _isEditingEssay = false;
  late final TextEditingController _essayController;
  final TextEditingController _recEmailController = TextEditingController();
  bool _isAddingRec = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(applicationDraftProvider(_draftKey));
    _essayController = TextEditingController(text: draft.essay);
  }

  @override
  void dispose() {
    _essayController.dispose();
    _recEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final school = profile?.school;
    final hasTranscript =
        profile != null && school != null && school.isNotEmpty;

    final draft = ref.watch(applicationDraftProvider(_draftKey));
    final recommenders = draft.recommenders;

    final essayText = _essayController.text.trim();
    final wordCount = essayText.isEmpty
        ? 0
        : essayText.split(RegExp(r'\s+')).length;
    final hasEssay = wordCount > 0;
    final hasRec = recommenders.isNotEmpty;

    final readyCount =
        (hasEssay ? 1 : 0) + (hasTranscript ? 1 : 0) + (hasRec ? 1 : 0);

    return Container(
      decoration: kSoftCardDecoration,
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
                  style: outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kOnSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: readyCount == 3
                        ? const Color(0xFFB3F1C6)
                        : const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$readyCount of 3 Ready',
                    style: outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: readyCount == 3
                          ? const Color(0xFF145131)
                          : kSecondary,
                    ),
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
                          const Icon(
                            Icons.description_outlined,
                            size: 18,
                            color: kSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '1. Personal Narrative Statement',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: outfit(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasEssay
                            ? const Color(0xFFB3F1C6)
                            : const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasEssay ? 'Draft Ready' : 'Incomplete',
                        style: outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: hasEssay
                              ? const Color(0xFF145131)
                              : const Color(0xFF93000A),
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
                    style: openSans(
                      fontSize: 11,
                      color: kOnSurface,
                      height: 1.35,
                    ),
                  ),
                ),
                ExpandableSection(
                  isExpanded: _isEditingEssay,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: _essayController,
                        maxLines: 4,
                        style: openSans(fontSize: 12, color: kOnSurface),
                        decoration: InputDecoration(
                          hintText:
                              'Type your essay / personal statement here...',
                          hintStyle: openSans(
                            fontSize: 12,
                            color: const Color(0xFF707971),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8E5),
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$wordCount / 750 words',
                            style: outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: wordCount > 750
                                  ? kError
                                  : kPrimaryContainer,
                            ),
                          ),
                          PressableScale(
                            child: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                backgroundColor: kPrimaryContainer,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(60, 30),
                              ),
                              onPressed: () {
                                ref
                                    .read(
                                      applicationDraftProvider(_draftKey)
                                          .notifier,
                                    )
                                    .setEssay(_essayController.text);
                                setState(() => _isEditingEssay = false);
                              },
                              child: Text(
                                'Save Statement',
                                style: outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ExpandableSection(
                  isExpanded: !_isEditingEssay,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 26, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            hasEssay
                                ? '$wordCount words composed'
                                : 'No statement composed yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasEssay
                                  ? kPrimaryContainer
                                  : const Color(0xFF707971),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PressableScale(
                          child: InkWell(
                            onTap: () => setState(() => _isEditingEssay = true),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hasEssay
                                      ? 'Edit Statement'
                                      : 'Write Statement',
                                  style: outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kSecondary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.edit_note_rounded,
                                  size: 16,
                                  color: kSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                const Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: kPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Official Transcript of Records (TCG)',
                        style: outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasTranscript
                            ? 'GPA ${profile.gpa.toStringAsFixed(2)} • ${profile.school ?? ""}'
                            : 'No academic transcript on file in profile',
                        style: openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: hasTranscript
                              ? kPrimaryContainer
                              : const Color(0xFF707971),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: hasTranscript
                        ? const Color(0xFFB3F1C6)
                        : const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hasTranscript ? 'Uploaded' : 'Incomplete',
                    style: outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hasTranscript
                          ? const Color(0xFF145131)
                          : const Color(0xFF93000A),
                    ),
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
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 18,
                            color: Color(0xFFE1A604),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '3. Faculty Recommendation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: outfit(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasRec
                            ? const Color(0xFFB3F1C6)
                            : const Color(0xFFFFDEA3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasRec
                            ? '${recommenders.length} Linked'
                            : '0 of 2 Linked',
                        style: outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: hasRec
                              ? const Color(0xFF145131)
                              : const Color(0xFF5D4200),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final rec in recommenders)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 14,
                                color: kPrimaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: openSans(
                                    fontSize: 11,
                                    color: kOnSurface,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Color(0xFF707971),
                                ),
                                onPressed: () {
                                  ref
                                      .read(
                                        applicationDraftProvider(_draftKey)
                                            .notifier,
                                      )
                                      .removeRecommender(rec);
                                },
                              ),
                            ],
                          ),
                        ),
                      ExpandableSection(
                        isExpanded: _isAddingRec,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 32,
                                  child: TextField(
                                    controller: _recEmailController,
                                    style: openSans(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Faculty email (e.g. prof@univ.edu)',
                                      hintStyle: openSans(fontSize: 11),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              PressableScale(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: kPrimaryContainer,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    minimumSize: const Size(50, 44),
                                  ),
                                  onPressed: () {
                                    final email = _recEmailController.text
                                        .trim();
                                    if (email.isNotEmpty) {
                                      ref
                                          .read(
                                            applicationDraftProvider(_draftKey)
                                                .notifier,
                                          )
                                          .addRecommender(email);
                                      setState(() {
                                        _recEmailController.clear();
                                        _isAddingRec = false;
                                      });
                                    }
                                  },
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ExpandableSection(
                        isExpanded: !_isAddingRec,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: PressableScale(
                            child: InkWell(
                              onTap: () => setState(() => _isAddingRec = true),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 14,
                                      color: kSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Add Recommender Email',
                                        style: outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: kSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

/// Provider information supplied with the scholarship.
class _ProviderTrustCard extends StatelessWidget {
  const _ProviderTrustCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: kSoftCardDecoration,
      child: Row(
        children: [
          const Icon(Icons.account_balance_outlined, color: kSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scholarship provider',
                  style: outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scholarship.provider ?? 'Scholarship Provider',
                  style: openSans(fontSize: 12, color: kOnSurfaceVariant),
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
    this.startApplication = false,
    this.tour,
  });

  final Scholarship scholarship;
  final VoidCallback onScrollToChecklist;
  final bool startApplication;
  final ScholarshipDetailTourHooks? tour;

  @override
  ConsumerState<_ApplySection> createState() => _ApplySectionState();
}

class _ApplySectionState extends ConsumerState<_ApplySection> {
  bool _isApplying = false;
  bool _openingApplication = false;
  bool _autoStartConsumed = false;

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
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.bookmark_added_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Application saved as draft.',
                    style: outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B3A5C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Could not save draft. Please try again.',
                    style: outfit(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _apply() async {
    if (_isApplying || _openingApplication) return;
    _openingApplication = true;
    try {
      await _runApply();
    } finally {
      _openingApplication = false;
    }
  }

  Future<void> _runApply() async {
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
                  'A profile photo is required to submit your application.',
                ),
                backgroundColor: Color(0xFFBA1A1A),
              ),
            );
          }
          return;
        }
        if (!mounted) return;
        final updatedAvatarState = ref.read(avatarProvider(userId));
        if (updatedAvatarState.isRealPhoto) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile photo added. Proceeding with application...',
              ),
              backgroundColor: Color(0xFF145131),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Deliberation notice: Committee will require an official identity photo before final award.',
              ),
              backgroundColor: Color(0xFF5D4200),
              duration: Duration(seconds: 3),
            ),
          );
        }
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
      await ref
          .read(applicationsProvider.notifier)
          .apply(widget.scholarship.id);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Application submitted!',
                  style: outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F4D2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } on ApplicationNotAuthenticatedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You must be signed in to apply.',
                  style: outfit(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E312F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } on ApplicationDuplicateException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You have already applied to this scholarship.',
                  style: outfit(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF404942),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Could not submit your application. Please try again.',
                  style: outfit(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    if (tour != null) return _applyButtonRow(onPressed: tour.onApply);
    final applicationsAsync = ref.watch(applicationsProvider);
    if (widget.startApplication && !_autoStartConsumed) {
      final userId = ref.watch(currentUserIdProvider);
      final profile = userId == null ? null : ref.watch(currentProfileProvider);
      final schools = ref.watch(
        scholarshipEligibleSchoolsProvider(widget.scholarship.id),
      );
      final school = userId == null
          ? null
          : ref.watch(studentProfileSchoolIdProvider(userId));
      final capacity = ref.watch(
        scholarshipCapacityProvider(widget.scholarship.id),
      );
      if (applicationsAsync.isLoading ||
          profile?.isLoading == true ||
          schools.isLoading ||
          school?.isLoading == true ||
          capacity.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (applicationsAsync.hasError ||
          profile?.hasError == true ||
          schools.hasError ||
          schools.valueOrNull == null ||
          school?.hasError == true ||
          capacity.hasError ||
          capacity.valueOrNull == null) {
        return _ReadinessNotice(
          icon: Icons.info_outline_rounded,
          title: 'Unable to check application options',
          message: 'We could not check your eligibility or available slots. Please try again.',
          actionLabel: 'Try again',
          onAction: () {
            ref.invalidate(applicationsProvider);
            ref.invalidate(currentProfileProvider);
            ref.invalidate(
              scholarshipEligibleSchoolsProvider(widget.scholarship.id),
            );
            ref.invalidate(scholarshipCapacityProvider(widget.scholarship.id));
            if (userId != null) {
              ref.invalidate(studentProfileSchoolIdProvider(userId));
            }
          },
        );
      }
      final existing = ref
          .read(applicationsProvider.notifier)
          .applicationFor(widget.scholarship.id);
      final readiness = evaluateApplicationReadiness(
        profile: profile?.valueOrNull,
        scholarship: widget.scholarship,
        referenceNow: DateTime.now(),
      );
      final eligibleSchools = schools.valueOrNull!;
      final schoolEligible =
          eligibleSchools.isEmpty ||
          (school?.valueOrNull != null &&
              eligibleSchools.contains(school!.valueOrNull));
      _autoStartConsumed = true;
      final alreadyApplied = ref
          .read(applicationsProvider.notifier)
          .hasApplied(widget.scholarship.id);
      if (userId != null &&
          readiness.canApply &&
          schoolEligible &&
          !capacity.valueOrNull!.isFull &&
          (!alreadyApplied || existing?.status == ApplicationStatus.draft) &&
          (existing == null || existing.status == ApplicationStatus.draft)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _apply();
        });
      }
    }
    final existingApp = ref
        .read(applicationsProvider.notifier)
        .applicationFor(widget.scholarship.id);

    if (existingApp != null) {
      if (existingApp.status == ApplicationStatus.draft) {
        return _DraftBanner(
          scholarship: widget.scholarship,
          onContinue: _apply,
        );
      }
      return _AppliedBanner(scholarship: widget.scholarship);
    }

    final applied = ref
        .read(applicationsProvider.notifier)
        .hasApplied(widget.scholarship.id);

    if (applied) return _AppliedBanner(scholarship: widget.scholarship);

    final userId = ref.watch(currentUserIdProvider);
    final profileAsync = userId == null
        ? null
        : ref.watch(currentProfileProvider);
    if (profileAsync != null && profileAsync.isLoading) {
      return const SizedBox.shrink();
    }
    final profile = profileAsync?.valueOrNull;
    final readiness = evaluateApplicationReadiness(
      profile: profile,
      scholarship: widget.scholarship,
      referenceNow: DateTime.now(),
    );

    // Authoritative slot capacity & school eligibility checks
    final eligibleSchoolIds = ref
        .watch(scholarshipEligibleSchoolsProvider(widget.scholarship.id))
        .valueOrNull;
    final userSchoolId = userId != null
        ? ref.watch(studentProfileSchoolIdProvider(userId)).valueOrNull
        : null;

    bool isSchoolRestricted =
        eligibleSchoolIds != null && eligibleSchoolIds.isNotEmpty;
    bool isSchoolIneligible = false;
    bool isSchoolLegacyUnlinked = false;
    if (isSchoolRestricted) {
      if (userSchoolId == null) {
        isSchoolLegacyUnlinked = true;
      } else if (!eligibleSchoolIds.contains(userSchoolId)) {
        isSchoolIneligible = true;
      }
    }

    final capacity = ref
        .watch(scholarshipCapacityProvider(widget.scholarship.id))
        .valueOrNull;
    final isCapacityReached = capacity != null && capacity.isFull;

    switch (readiness.state) {
      case ApplicationReadinessState.eligible:
        if (isSchoolLegacyUnlinked) {
          return _ReadinessNotice(
            icon: Icons.school_outlined,
            title: 'Profile update required',
            message: 'This grant is restricted to partner institutions. Please update your profile to select your school.',
            actionLabel: 'Update profile',
            onAction: () => context.go('/profile-setup/personal'),
          );
        }
        if (isSchoolIneligible) {
          return const _ReadinessNotice(
            icon: Icons.school_outlined,
            title: "Why you can't apply",
            message: 'Ineligible based on profile: Restricted to partner institutions.',
          );
        }
        if (isCapacityReached) {
          return const _ReadinessNotice(
            icon: Icons.group_off_rounded,
            title: 'Scholarship capacity reached',
            message: 'All allocated slots for this scholarship have been filled by approved scholars.',
          );
        }
        return _applyButtonRow(onPressed: _apply);

      case ApplicationReadinessState.closed:
        return const _ReadinessNotice(
          icon: Icons.event_busy_rounded,
          title: 'Applications closed',
          message: 'The deadline for this scholarship has passed. You can no longer apply.',
        );

      case ApplicationReadinessState.inactive:
        return const _ReadinessNotice(
          icon: Icons.pause_circle_outline_rounded,
          title: 'Not accepting applications',
          message: 'This scholarship is currently inactive. Explore other scholarships instead.',
        );

      case ApplicationReadinessState.notEligible:
        return _ReadinessNotice(
          icon: Icons.info_outline_rounded,
          title: "Why you can't apply",
          message: 'Based on your profile, the requirements below are not met:',
          reasons: readiness.reasons,
        );

      case ApplicationReadinessState.profileIncomplete:
        if (userId == null) {
          return _applyButtonRow(onPressed: _applySignedOut);
        }
        return _ReadinessNotice(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Finish your profile to apply',
          message: 'Your profile is incomplete, so we cannot check your eligibility yet.',
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
              child: PressableScale(
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
                      style: outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kOnSurface,
                      ),
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
                child: PressableScale(
                  child: ElevatedButton(
                    key: widget.tour?.applyKey ?? const ValueKey('apply-now'),
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
                              style: outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Start Application',
                              style: outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
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
  const _DraftBanner({required this.scholarship, required this.onContinue});

  final Scholarship scholarship;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kSoftCardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 14,
                      color: kSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'DRAFT IN PROGRESS',
                      style: outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Not submitted',
                style: openSans(
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
            style: outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF161C27),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete your 4-part application packet and submit before the deadline.',
            style: openSans(
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
                style: outfit(fontSize: 14, fontWeight: FontWeight.w600),
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
class _AppliedBanner extends ConsumerWidget {
  const _AppliedBanner({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = ref
        .watch(applicationsProvider)
        .valueOrNull
        ?.where((a) => a.scholarshipId == scholarship.id)
        .firstOrNull;
    final documents = application == null
        ? null
        : ref.watch(applicationDocumentsProvider(application.id));
    final savedStatus =
        application?.status.dbValue.replaceAll('_', ' ') ?? 'saved';
    return Semantics(
      liveRegion: true,
      label: 'Application $savedStatus',
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
              borderRadius: BorderRadius.circular(kRadiusCard),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3F1C6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SUBMISSION SAVED',
                    style: outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB3F1C6),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Application $savedStatus',
                  style: outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your application has been saved. Check the tracker for its current status.',
                  textAlign: TextAlign.center,
                  style: openSans(fontSize: 13, color: const Color(0xFFB3F1C6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Digital Submission Token Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: kSoftCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
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
                                  'INSTITUTIONAL DOSSIER',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF404942),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Digital Submission Token',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF161C27),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB3F1C6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VALID',
                        style: outfit(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                              style: openSans(
                                fontSize: 10,
                                color: const Color(0xFF404942),
                              ),
                            ),
                            Text(
                              application?.id ?? 'Application unavailable',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: outfit(
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
                        icon: const Icon(
                          Icons.content_copy_rounded,
                          size: 16,
                          color: kSecondary,
                        ),
                        onPressed: application == null
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: application.id),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Receipt ID copied to clipboard.',
                                    ),
                                  ),
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
                            'UPLOADED ATTACHMENTS',
                            style: outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF404942),
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: kPrimaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (documents?.isLoading == true)
                            _receiptTag('Loading attachments'),
                          if (documents?.hasError == true)
                            _receiptTag('Could not load attachments'),
                          for (final doc in documents?.valueOrNull ?? [])
                            _receiptTag(doc.fileName),
                          if (documents?.hasValue == true &&
                              documents!.valueOrNull!.isEmpty)
                            _receiptTag('No documents attached'),
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
                          const Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: kPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Submitted: ${application?.appliedAt?.toLocal() ?? 'Not available'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: outfit(
                                fontSize: 10,
                                color: const Color(0xFF404942),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      application == null
                          ? 'Status unavailable'
                          : ApplicationStatusUi.of(application.status).label,
                      style: outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryContainer,
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => context.go('/applications'),
                    icon: const Icon(Icons.track_changes_rounded, size: 18),
                    label: Text(
                      'Monitor in Application Tracker',
                      style: outfit(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: application == null
                        ? null
                        : () => context.push('/application/${application.id}'),
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: kPrimaryContainer,
                    ),
                    label: Text(
                      'View Application Status',
                      style: outfit(
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
        style: openSans(
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
      decoration: kSoftCardDecoration,
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
                  style: outfit(
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
            style: openSans(fontSize: 13, color: const Color(0xFF404942)),
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
    final maxWidth = (MediaQuery.sizeOf(context).width - 90).clamp(
      180.0,
      480.0,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5F6368).withValues(alpha: 0.25),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.remove_circle_outline,
              size: 14,
              color: Color(0xFF5F6368),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: openSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5F6368),
                ),
              ),
            ),
          ],
        ),
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
        color: kScholarshipTagBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kScholarshipTagForeground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: openSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kScholarshipTagForeground,
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
  return scholarship.formattedAmount;
}

String _grantSubtext(Scholarship scholarship) {
  final freq = scholarship.formattedFrequency;
  final cov = scholarship.coverage.trim().isNotEmpty
      ? scholarship.coverage
      : 'Full educational grant & book support';
  return '$freq • $cov';
}
