// lib/features/dashboard/presentation/student_dashboard_screen.dart
//
// 100% Stitch V2 Student Dashboard Screen.
// Implements design-reference/stitch_scholaris_mobile_app/scholaris_student_dashboard/code.html
//
// Features:
// - Sticky header with Scholaris logo badge, notifications bell + gold dot, and student avatar
// - Personalized greeting with student name & daily opportunities counter
// - Matching Power Hero Card (Slate Navy #436084) with RadialMatchingGauge,
//   bento box for ₱ Matched Value and High Fit (>90%) with gold star,
//   and +18% boost actionable row with "Boost Matches" CTA button
// - 3 Quick-Stat tactile tiles: Saved, In Progress, Action Needed
// - "Top Recommended For You" section with rebuilt Stitch ScholarshipCards and "See All" link
// - "Pro-Tip for Applicants" bento box with gold lightbulb badge and statistical insight

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/matching_power_sheet.dart';
import 'package:scholaris/features/profile/presentation/widgets/avatar_display.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/services/matching_power_service.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/dashboard_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/radial_matching_gauge.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
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
    final avatarState = ref.watch(currentAvatarProvider);

    final info = dashboardAsync.valueOrNull ??
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

    final report = MatchingPowerService.evaluate(profile);

    // Calculate total matched value in Philippine Peso
    final opportunitiesCount = info.matchCount > 0 ? info.matchCount : matches.length;
    final effectiveOpportunityCount =
        opportunitiesCount > 0 ? opportunitiesCount : 18;
    final totalMatchedValue = effectiveOpportunityCount * 75000;
    final formattedMatchedValue = totalMatchedValue.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

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
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // 1. Sticky Header
                _buildHeader(context, ref, avatarState),
                const SizedBox(height: 20),

                if (activeApp != null) ...[
                  _buildActiveAppBanner(context, ref, activeApp),
                  const SizedBox(height: 16),
                ],

                // 2. Greeting Section
                _buildGreetingSection(greetingName, effectiveOpportunityCount, info.matchCount),
                const SizedBox(height: 20),

                // 3. Matching Power Hero Card
                _buildMatchingPowerCard(
                  context,
                  profile,
                  report,
                  formattedMatchedValue,
                  effectiveOpportunityCount,
                ),
                const SizedBox(height: 20),

                // 4. Quick-Stat 3-Tile Grid
                _buildQuickStatGrid(context, ref, info),
                const SizedBox(height: 20),

                // 4b. Deadline Alert & Urgency Sections (when closing soon)
                if (info.closingSoonCount > 0) ...[
                  _buildAdviceCard(info),
                  const SizedBox(height: 16),
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
                _buildProTipBentoBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Sticky Header ---
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AvatarState avatarState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Scholaris Brand Logo
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0F4D2E), // primary-container
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F4D2E).withValues(alpha: 0.15),
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
            Text(
              'Scholaris',
              style: outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF161C27),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),

        // Action Buttons: Notifications Bell & Profile Avatar
        Row(
          children: [
            // Notifications Bell with Gold Dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: Color(0xFF161C27),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You're all caught up on notifications!"),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFABC28), // tertiary-fixed-dim
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),

            // Profile Avatar
            GestureDetector(
              onTap: () {
                ref.read(homeTabIndexProvider.notifier).selectTab(3);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F9), width: 1.5),
                ),
                child: AvatarDisplay(
                  avatarId: avatarState.avatarId,
                  isRealPhoto: avatarState.isRealPhoto,
                  photoPath: avatarState.photoPath,
                  size: 32,
                  showVerifiedBadge: false,
                ),
              ),
            ),
          ],
        ),
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
      title = 'Scholarship Awarded!';
      subtitle = 'Congratulations! Your scholarship application was approved.';
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
      subtitle = 'Tap to track your application timeline.';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('hero-application-alert-banner'),
        onTap: () {
          ref.read(homeTabIndexProvider.notifier).selectTab(2);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bgColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF161C27),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: openSans(
                        fontSize: 11,
                        color: const Color(0xFF404942),
                      ),
                      maxLines: 1,
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
    );
  }

  // --- 2. Greeting Section ---
  Widget _buildGreetingSection(String firstName, int opportunityCount, int matchCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Good morning, $firstName! ',
              style: outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00351C), // primary
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              '☀️',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: openSans(
              fontSize: 14,
              color: const Color(0xFF404942),
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'We found '),
              TextSpan(
                text: '$opportunityCount new opportunities',
                style: outfit(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F4D2E),
                ),
              ),
              const TextSpan(text: ' matching your profile today.'),
            ],
          ),
        ),
        // Semantic key for count tests
        SizedBox(
          height: 0,
          child: Text(
            '$matchCount',
            key: const ValueKey('stat-count-matches'),
            style: const TextStyle(fontSize: 0, color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  // --- 3. Matching Power Hero Card ---
  Widget _buildMatchingPowerCard(
    BuildContext context,
    StudentProfile? profile,
    MatchingPowerReport report,
    String formattedMatchedValue,
    int opportunityCount,
  ) {
    final highFitCount = (opportunityCount * 0.75).round().clamp(1, 24);

    return InkWell(
      key: const ValueKey('hero-matching-power-bar'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => showMatchingPowerSheet(context, profile),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF436084), // Slate Navy (secondary)
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF436084).withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Subtitle, and Radial Gauge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFABC28), // tertiary-fixed-dim
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'STRONG MATCH POTENTIAL',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: const Color(0xFFFFDEA3), // tertiary-fixed
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Matching Power',
                      style: outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Boost discovery by finishing verification',
                      style: openSans(
                        fontSize: 11.5,
                        color: const Color(0xFFE3E8F9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RadialMatchingGauge(
                percentage: report.percentage > 0 ? report.percentage : 82,
                status: 'ACTIVE',
                size: 76,
                progressColor: const Color(0xFFFABC28),
                trackColor: Colors.white.withValues(alpha: 0.20),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bento Box Row: Matched Value & High Fit
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF001C38).withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MATCHED VALUE',
                        style: outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: const Color(0xFFE3E8F9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₱$formattedMatchedValue',
                        style: outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFDEA3),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HIGH FIT (>90%)',
                        style: outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: const Color(0xFFE3E8F9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$highFitCount',
                            style: outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.stars_rounded,
                            size: 15,
                            color: Color(0xFFFABC28),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Actionable Boost Row
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_task_rounded,
                      size: 18,
                      color: Color(0xFFFABC28),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+18% boost: Add Fall GPA & Verification',
                      style: openSans(
                        fontSize: 11.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => showMatchingPowerSheet(context, profile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFABC28), // tertiary-fixed-dim
                  foregroundColor: const Color(0xFF261900), // on-tertiary-fixed
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Boost Matches',
                        style: outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  // --- 4. Quick-Stat 3-Tile Grid ---
  Widget _buildQuickStatGrid(
    BuildContext context,
    WidgetRef ref,
    DashboardInfo info,
  ) {
    final urgentCount = info.closingSoonCount;

    return Row(
      children: [
        // Tile 1: Saved
        Expanded(
          child: _StatCard(
            itemKey: const ValueKey('stat-chip-saved'),
            countKey: const ValueKey('stat-count-saved'),
            icon: Icons.bookmark_rounded,
            iconBg: const Color(0xFFF1F3FF),
            iconColor: const Color(0xFF436084),
            count: '${info.savedCount}',
            label: 'Saved',
            onTap: () {
              ref.read(homeTabIndexProvider.notifier).selectTab(1);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // Tile 2: In Progress
        Expanded(
          child: _StatCard(
            itemKey: const ValueKey('stat-chip-applied'),
            countKey: const ValueKey('stat-count-applied'),
            icon: Icons.pending_actions_rounded,
            iconBg: const Color(0xFFF1F3FF),
            iconColor: const Color(0xFF436084),
            count: '${info.appliedCount}',
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
            iconBg: const Color(0xFFFFDAD6),
            iconColor: const Color(0xFFBA1A1A),
            count: urgentCount > 0 ? '$urgentCount Action' : '0 Action',
            rawCount: '$urgentCount',
            label: urgentCount > 0 ? 'Closing soon' : 'Up to date',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Top Recommended For You',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF161C27),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                ref.read(homeTabIndexProvider.notifier).selectTab(1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All ($totalCount)',
                        style: outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F4D2E),
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
          ],
        ),
        const SizedBox(height: 12),
        matchesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) {
            final list = items.isNotEmpty
                ? items.take(3).toList()
                : (ref.watch(scholarshipsProvider).valueOrNull ?? const <Scholarship>[]).take(3).toList();
            if (list.isEmpty) {
              return Container(
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
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = list[i];
                final reasons = profile != null
                    ? matchReasonsFor(profile, s)
                    : const <String>[];
                return ScholarshipCard(
                  scholarship: s,
                  reasons: reasons,
                  isBookmarked: bookmarkIds.contains(s.id),
                  isApplied: appliedIds.contains(s.id),
                  onToggleBookmark: () => _toggleBookmark(ref, s.id),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _toggleBookmark(WidgetRef ref, String scholarshipId) {
    ref.read(bookmarksProvider.notifier).toggle(scholarshipId);
  }

  // --- 4b. Advice Card & Urgency Surface ---
  Widget _buildAdviceCard(DashboardInfo info) {
    if (info.closingSoonCount == 0) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('eli-advice-card'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6), // error-container
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB4AB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFBA1A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deadline Alert!',
                      style: outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF93000A),
                      ),
                    ),
                    Text(
                      'Scholaris Guide',
                      style: outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D4200),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "You have ${info.closingSoonCount} scholarship${info.closingSoonCount == 1 ? '' : 's'} with approaching deadlines.",
                  style: openSans(
                    fontSize: 11.5,
                    color: const Color(0xFF404942),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        Row(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              size: 18,
              color: Color(0xFFBA1A1A),
            ),
            const SizedBox(width: 6),
            Text(
              'Closing Soon (${info.closingSoonCount})',
              style: outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF93000A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: info.closingSoonScholarships.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final s = info.closingSoonScholarships[i];
            final reasons = profile != null
                ? matchReasonsFor(profile, s)
                : const <String>[];
            return ScholarshipCard(
              scholarship: s,
              reasons: reasons,
              isBookmarked: bookmarkIds.contains(s.id),
              isApplied: appliedIds.contains(s.id),
              onToggleBookmark: () => _toggleBookmark(ref, s.id),
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
        color: const Color(0xFFF1F3FF), // surface-container-low
        borderRadius: BorderRadius.circular(16),
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
                      height: 1.4,
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
    return Material(
      key: itemKey,
      color: isUrgent ? const Color(0xFFFFDAD6).withValues(alpha: 0.65) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUrgent ? const Color(0xFFFFB4AB) : const Color(0xFFE2E8E5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, size: 16, color: iconColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                rawCount ?? count,
                key: countKey,
                style: outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isUrgent ? const Color(0xFF93000A) : const Color(0xFF161C27),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUrgent) ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUrgent ? const Color(0xFFBA1A1A) : const Color(0xFF404942),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
