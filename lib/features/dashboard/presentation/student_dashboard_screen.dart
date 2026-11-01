import 'package:scholaris/features/home/presentation/widgets/student_tab_entrance.dart';
// lib/features/dashboard/presentation/student_dashboard_screen.dart
//
// 100% Stitch V2 Student Dashboard Screen.
// Implements design-reference/stitch_scholaris_mobile_app/scholaris_student_dashboard/code.html
//
// Features:
// - Sticky header with Scholaris logo, notifications, and account settings
// - Personalized greeting with student name & daily opportunities counter
// - Compact graduate hero with a live match summary and Explore matches action
// - 3 Quick-Stat tactile tiles: Saved, In Progress, Action Needed
// - Recommended for you section with scholarship cards and a See all action
// - "Pro-Tip for Applicants" bento box with gold lightbulb badge and statistical insight

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/shared/widgets/student_header_actions.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/dashboard_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/shared/widgets/typography_diagnostics.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({
    super.key,
    this.savedGuideKey,
    this.progressGuideKey,
    this.scrollController,
    this.recommendationsGuideKey,
    this.detailsGuideKey,
  });
  final GlobalKey? savedGuideKey;
  final GlobalKey? progressGuideKey;
  final ScrollController? scrollController;
  final GlobalKey? recommendationsGuideKey;
  final GlobalKey? detailsGuideKey;

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  Widget _wrapSection({required int index, required Widget child}) =>
      StudentTabReveal(
        order: const [0, 1, 2, 3, 4, 5][index.clamp(0, 5)],
        structural: index < 5,
        immediate: index <= 2,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final dashboardAsync = ref.watch(dashboardProvider);
    final matchesAsync = ref.watch(matchesProvider);
    final matches = matchesAsync.valueOrNull ?? const <Scholarship>[];
    final bookmarkIds =
        ref.watch(bookmarksProvider).valueOrNull ?? const <String>{};
    final appliedIds = ApplicationFilters.activeAppliedScholarshipIds(
      ref.watch(applicationsProvider).valueOrNull ?? const <Application>[],
    );

    final summaryReady =
        dashboardAsync.hasValue &&
        !dashboardAsync.isLoading &&
        !dashboardAsync.hasError;
    final info =
        (summaryReady ? dashboardAsync.valueOrNull : null) ??
        const DashboardInfo(
          matchCount: 0,
          closingSoonCount: 0,
          savedCount: 0,
          appliedCount: 0,
          pendingApplicationCount: 0,
          closingSoonScholarships: [],
        );

    final firstName = profile?.fullName.trim().split(' ').first;
    final greetingName = (firstName != null && firstName.isNotEmpty)
        ? firstName
        : 'Student';

    // Calculate total matched value in Philippine Peso for downstream recommendations
    final opportunitiesCount = info.matchCount > 0
        ? info.matchCount
        : matches.length;
    final effectiveOpportunityCount = opportunitiesCount;

    final rawApps =
        ref.watch(applicationsProvider).valueOrNull ?? const <Application>[];
    Application? activeApp;
    for (final app in rawApps) {
      if (ApplicationFilters.isActive(app)) {
        activeApp = app;
        break;
      }
    }

    return Scaffold(
      backgroundColor: kStudentCanvas,
      body: SafeArea(
        bottom: false,
        child: ResponsiveContainer(
          child: RefreshIndicator(
            color: const Color(0xFF0F4D2E),
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              ref.invalidate(currentProfileProvider);
              ref.invalidate(matchesProvider);
              ref.invalidate(scholarshipsProvider);
              ref.invalidate(applicationsProvider);
              ref.invalidate(bookmarksProvider);
            },
            child: ListView(
              controller: widget.scrollController,
              physics: const AppleBouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(context).padding.bottom + 64 + 16,
              ),
              children: [
                // 1. Sticky Header
                _wrapSection(index: 0, child: _buildHeader(context)),
                const SizedBox(height: 10),

                // 2. Date & Dynamic Tagalog Greeting
                _wrapSection(
                  index: 1,
                  child: _buildDateAndGreeting(greetingName),
                ),
                const SizedBox(height: 8),

                // 3. Free-Floating Mascot Hero Section
                _wrapSection(
                  index: 2,
                  child: _buildMascotHeroSection(
                    profile: profile,
                    matchCount: matchesAsync.hasError
                        ? null
                        : matchesAsync.valueOrNull?.length,
                    matchesFailed: matchesAsync.hasError,
                  ),
                ),
                const SizedBox(height: 16),

                if (activeApp != null) ...[
                  _wrapSection(
                    index: 3,
                    child: _buildActiveAppBanner(context, ref, activeApp),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Quick-Stat 3-Tile Grid
                _wrapSection(
                  index: 4,
                  child: _buildQuickStatGrid(context, ref, info, summaryReady),
                ),
                const SizedBox(height: 20),

                // 4b. Deadline Alert & Urgency Sections (when closing soon)
                if (info.closingSoonCount > 0) ...[
                  _buildClosingSoonSection(
                    context,
                    ref,
                    info,
                    bookmarkIds,
                    appliedIds,
                    profile,
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Top Recommended For You Section
                _buildTopRecommendedSection(
                  context,
                  ref,
                  profile,
                  matchesAsync,
                  effectiveOpportunityCount,
                  bookmarkIds,
                  appliedIds,
                ),
                const SizedBox(height: 20),

                // 6. Pro-Tip for Applicants Bento Box
                _wrapSection(index: 5, child: _buildProTipBentoBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Sticky Header ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Scholaris Brand Logo
        Expanded(
          child: StudentTabReveal(
            order: 0,
            immediate: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4D2E), // primary-container
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F4D2E)
                              .withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onLongPress: () => showTypographyDiagnostics(context),
                    child: Text(
                      'Scholaris',
                      style: appHeading(fontSize: 26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const StudentHeaderActions(),
      ],
    );
  }

  // --- Active Application Banner ---
  Widget _buildActiveAppBanner(
    BuildContext context,
    WidgetRef ref,
    Application app,
  ) {
    final String title;
    final String subtitle;
    final IconData icon;
    final Color iconColor;
    final Color bgColor;

    if (app.status == ApplicationStatus.approved ||
        app.status == ApplicationStatus.awarded) {
      icon = Icons.celebration_rounded;
      iconColor = const Color(0xFF0F4D2E);
      bgColor = const Color(0xFFB3F1C6);
      title = app.status == ApplicationStatus.awarded
          ? 'Scholarship Awarded!'
          : 'Application Approved';
      subtitle = app.status == ApplicationStatus.awarded
          ? 'View your award details in the tracker.'
          : 'View your approval letter and contact your provider for next steps.';
    } else if (app.status == ApplicationStatus.underReview) {
      icon = Icons.hourglass_top_rounded;
      iconColor = const Color(0xFF5D4200);
      bgColor = const Color(0xFFFFDEA3);
      title = 'Application Under Review';
      subtitle = 'A provider is currently evaluating your application.';
    } else {
      icon = Icons.mark_email_read_rounded;
      iconColor = const Color(0xFF001C38);
      bgColor = const Color(0xFFD2E4FF);
      title = 'Application Submitted';
      subtitle = 'Track your application.';
    }

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('hero-application-alert-banner'),
          onTap: () {
            ref.read(homeTabIndexProvider.notifier).selectTab(2);
          },
          borderRadius: BorderRadius.circular(kRadiusCard),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: kSoftCardDecoration,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: app.status == ApplicationStatus.underReview
                        ? const Color(0xFFFEF3D6)
                        : bgColor.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: appCardTitle(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: appSupporting(fontSize: 12.5, color: const Color(0xFF475569)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF404942),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. Dynamic Date & Tagalog Greeting ---
  Widget _buildDateAndGreeting(String greetingName) {
    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final greetingStr = '${_getTagalogGreeting(now)}, $greetingName!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateStr,
          style: appOverline(),
        ),
        const SizedBox(height: 3),
        Text(
          greetingStr,
          style: appGreeting(fontSize: 28),
        ),
      ],
    );
  }

  String _formatDate(DateTime now) {
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, $monthName ${now.day}';
  }

  String _getTagalogGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return 'Magandang umaga';
    } else if (hour >= 12 && hour < 13) {
      return 'Magandang tanghali';
    } else if (hour >= 13 && hour < 18) {
      return 'Magandang hapon';
    } else {
      return 'Magandang gabi';
    }
  }

  // One quiet hero with real text and a real, accessible action.
  Widget _buildMascotHeroSection({
    required StudentProfile? profile,
    required int? matchCount,
    required bool matchesFailed,
  }) {
    if (profile == null) {
      return const SizedBox(key: ValueKey('student-hero-loading'), height: 220);
    }
    final isFemale = profile.gender?.trim().toLowerCase() == 'female';
    final asset = isFemale
        ? 'assets/images/student_hero_graduate_campus_female.png'
        : 'assets/images/student_hero_graduate_campus.png';
    final countLabel = matchesFailed
        ? 'Matches unavailable'
        : matchCount == null
        ? 'Finding matches…'
        : '$matchCount ${matchCount == 1 ? 'scholarship matches' : 'scholarships match'} your profile.';
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Find your next opportunity.',
          style: appHeading(fontSize: 21),
        ),
        const SizedBox(height: 5),
        Text(
          countLabel,
          key: const ValueKey('stat-count-matches'),
          style: appSupporting(fontSize: 14, color: const Color(0xFF475569)),
        ),
        const SizedBox(height: 12),
        PressableScale(
          child: FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(homeTabIndexProvider.notifier).selectTab(1);
            },
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 42),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore matches',
                    style: outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    Widget portrait(double height) => Transform.scale(
      scale: isFemale ? .94 : 1,
      alignment: Alignment.bottomLeft,
      child: Image.asset(
        asset,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomLeft,
        excludeFromSemantics: true,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LayoutBuilder(
        builder: (context, box) {
          final stacked =
              box.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(14) > 18;
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4EF),
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: const Color(0xFFE0EDE1), width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusCard),
              child: stacked
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: portrait(125)),
                          const SizedBox(height: 12),
                          summary,
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 118,
                          height: 155,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(kRadiusCard),
                            ),
                            child: portrait(155),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 16, 16, 16),
                            child: summary,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  // --- 4. Quick-Stat 3-Tile Grid ---
  Widget _buildQuickStatGrid(
    BuildContext context,
    WidgetRef ref,
    DashboardInfo info,
    bool summaryReady,
  ) {
    final urgentCount = info.closingSoonCount;

    return Row(
      children: [
        // Tile 1: Saved
        Expanded(
          key: widget.savedGuideKey,
          child: _StatCard(
            itemKey: const ValueKey('stat-chip-saved'),
            countKey: const ValueKey('stat-count-saved'),
            icon: Icons.bookmark_rounded,
            iconBg: const Color(0xFFE4EEE6),
            iconColor: kPrimary,
            count: summaryReady ? '${info.savedCount}' : '—',
            label: 'Saved',
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SavedScreen()));
            },
          ),
        ),
        const SizedBox(width: 10),

        // Tile 2: In Progress
        Expanded(
          key: widget.progressGuideKey,
          child: _StatCard(
            itemKey: const ValueKey('stat-chip-applied'),
            countKey: const ValueKey('stat-count-applied'),
            icon: Icons.pending_actions_rounded,
            iconBg: const Color(0xFFE4EEE6),
            iconColor: kPrimary,
            count: summaryReady ? '${info.appliedCount}' : '—',
            label: 'In Progress',
            onTap: () {
              ref.read(homeTabIndexProvider.notifier).selectTab(2);
            },
          ),
        ),
        const SizedBox(width: 10),

        // Tile 3: Action Needed
        Expanded(
          child: _StatCard(
            itemKey: const ValueKey('stat-chip-urgent'),
            countKey: const ValueKey('stat-count-closing-soon'),
            icon: Icons.notification_important_rounded,
            iconBg: urgentCount > 0
                ? const Color(0xFFFEF3D6)
                : const Color(0xFFE4EEE6),
            iconColor: urgentCount > 0 ? const Color(0xFFD97706) : kPrimary,
            count: !summaryReady
                ? '—'
                : urgentCount > 0
                ? '$urgentCount Action'
                : '0 Action',
            rawCount: summaryReady ? '$urgentCount' : '—',
            label: !summaryReady || urgentCount > 0
                ? 'Closing soon'
                : 'Up to date',
            isUrgent: urgentCount > 0,
            onTap: () {
              ref.read(homeTabIndexProvider.notifier).selectTab(2);
            },
          ),
        ),
      ],
    );
  }

  // --- 5. Top Recommended For You Section ---
  Widget _buildTopRecommendedSection(
    BuildContext context,
    WidgetRef ref,
    StudentProfile? profile,
    AsyncValue<List<Scholarship>> matchesAsync,
    int totalCount,
    Set<String> bookmarkIds,
    Set<String> appliedIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentTabReveal(
          order: 1,
          structural: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recommended for you',
                    key: widget.recommendationsGuideKey,
                    maxLines: 1,
                    style: appHeading(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PressableScale(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    ref.read(homeTabIndexProvider.notifier).selectTab(1);
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            totalCount > 0
                                ? 'See all ($totalCount)'
                                : 'See all',
                            style: outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F4D2E),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF0F4D2E),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        matchesAsync.when(
          loading: () =>
              StudentTabReveal(order: 3, child: _buildDashboardSkeleton()),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) {
            final list = items.isNotEmpty
                ? items.take(3).toList()
                : (ref.watch(scholarshipsProvider).valueOrNull ??
                          const <Scholarship>[])
                      .take(3)
                      .toList();
            if (list.isEmpty) {
              return StudentTabReveal(
                order: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8E5)),
                  ),
                  child: Center(
                    child: Text(
                      'Complete your profile to discover matched scholarships.',
                      textAlign: TextAlign.center,
                      style: openSans(
                        fontSize: 13,
                        color: const Color(0xFF404942),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = list[i];
                    final reasons = profile != null
                        ? matchReasonsFor(profile, s)
                        : const <String>[];
                    return StudentTabReveal(
                      order: 1 + i,
                      child: ScholarshipCard(
                        scholarship: s,
                        cardGuideKey: i == 0 ? widget.detailsGuideKey : null,
                        studentProfile: profile,
                        reasons: reasons,
                        isBookmarked: bookmarkIds.contains(s.id),
                        isApplied: appliedIds.contains(s.id),
                        onToggleBookmark: () => _toggleBookmark(ref, s.id),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboardSkeleton() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: kSoftCardDecoration,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBand(width: 80, height: 22, borderRadius: 11),
                    SkeletonBand(width: 70, height: 22, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 12),
                SkeletonBand(width: 220, height: 20, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonBand(width: 140, height: 14, borderRadius: 4),
                SizedBox(height: 14),
                SkeletonBand(height: 40, borderRadius: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleBookmark(WidgetRef ref, String scholarshipId) {
    ref.read(bookmarksProvider.notifier).toggle(scholarshipId);
  }

  Widget _buildClosingSoonSection(
    BuildContext context,
    WidgetRef ref,
    DashboardInfo info,
    Set<String> bookmarkIds,
    Set<String> appliedIds,
    StudentProfile? profile,
  ) {
    if (info.closingSoonScholarships.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const ValueKey('closing-soon-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentTabReveal(
          order: 2,
          structural: true,
          child: Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 18,
                color: Color(0xFFBA1A1A),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Closing Soon (${info.closingSoonCount})',
                  style: outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC62828),
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: info.closingSoonScholarships.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final s = info.closingSoonScholarships[i];
            final reasons = profile != null
                ? matchReasonsFor(profile, s)
                : const <String>[];
            return StudentTabReveal(
              order: 1 + i,
              child: ScholarshipCard(
                scholarship: s,
                studentProfile: profile,
                reasons: reasons,
                isBookmarked: bookmarkIds.contains(s.id),
                isApplied: appliedIds.contains(s.id),
                onToggleBookmark: () => _toggleBookmark(ref, s.id),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- 6. Pro-Tip for Applicants Bento Box ---
  Widget _buildProTipBentoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDEA3), // tertiary-fixed
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.lightbulb_rounded,
                size: 18,
                color: Color(0xFF583F00), // tertiary-container
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro-Tip for Applicants',
                  style: outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF161C27),
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: openSans(
                      fontSize: 12,
                      color: const Color(0xFF404942),
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Scholarships that require personal essays receive ',
                      ),
                      TextSpan(
                        text: '40% fewer applicants',
                        style: outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F4D2E),
                        ),
                      ),
                      const TextSpan(
                        text: ', doubling your acceptance likelihood.',
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    this.itemKey,
    this.countKey,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.count,
    this.rawCount,
    required this.label,
    required this.onTap,
    this.isUrgent = false,
  });

  final Key? itemKey;
  final Key? countKey;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String count;
  final String? rawCount;
  final String label;
  final VoidCallback onTap;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final unknown = count == '—';
    final numericValue =
        int.tryParse(rawCount ?? count.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return PressableScale(
      child: Material(
        key: itemKey,
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusCard),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: kSoftCardDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isUrgent ? const Color(0xFFFEF3D6) : iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 14,
                        color: isUrgent ? const Color(0xFFD97706) : iconColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          unknown ? '—' : '$numericValue',
                          semanticsLabel: unknown ? 'Loading' : '$numericValue',
                          style: outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (countKey != null)
                  SizedBox(
                    height: 0,
                    width: 0,
                    child: ExcludeSemantics(
                      child: Text(
                        unknown ? '—' : '$numericValue',
                        key: countKey,
                        style: const TextStyle(
                          fontSize: 0,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.1,
                    color: isUrgent ? const Color(0xFF8A5B00) : kTextSupporting,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
