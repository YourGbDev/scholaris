// lib/features/scholarships/screens/discover_screen.dart
//
// Student Core Flow — Stitch Discover Screen (scholaris_discover_filters/code.html):
// - Sticky Top Bar with Scholaris logo badge, Notification bell with gold dot, and Profile Avatar
// - Search & Active Filter Bar (Search input + "Filters" button with active count badge)
// - Filter Chips Horizontal Carousel (All Matches, Match >90%, Deadline < 14 Days, No Essay, ₱50k - ₱150k+, Need-Based)
// - Applied Criteria Quick-Bar ("Active: STEM • Undergrad • Need-Based • EFC < ₱50k" + "Edit" action)
// - Opportunity Feed Header ("Verified Matches", "Showing N targeted opportunities for Maya", "Highest Match %" sort selector)
// - Feed Cards Container (rebuilt ScholarshipCard components with full Stitch anatomy)
// - Deduplicated Browse Section
// - Editorial End-of-Feed Helper Card ("Looking for more niche grants?")

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/widgets/avatar_display.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/discovery_filter_sheet.dart';
import 'package:scholaris/features/scholarships/providers/dashboard_provider.dart';
import 'package:scholaris/features/scholarships/providers/discovery_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/services/discovery_filters.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/shared/widgets/section_header.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final GlobalKey _matchesKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final filteredMatches = ref.watch(filteredMatchesProvider);
    final filteredBrowse = ref.watch(filteredBrowseProvider);
    final bookmarkIds =
        ref.watch(bookmarksProvider).valueOrNull ?? const <String>{};
    final appliedIds = ApplicationFilters.activeAppliedScholarshipIds(
      ref.watch(applicationsProvider).valueOrNull ?? const <Application>[],
    );
    final state = ref.watch(discoveryFilterProvider);
    final avatarState = ref.watch(currentAvatarProvider);

    final firstName = profile?.fullName.trim().split(' ').first;
    final studentName = (firstName != null && firstName.isNotEmpty)
        ? firstName
        : 'you';

    final matchesList = filteredMatches.valueOrNull ?? const <Scholarship>[];
    final totalOpportunities = matchesList.length;

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
                const SizedBox(height: 16),

                // 2. Search & Active Filter Bar
                _buildSearchBar(context, ref),
                const SizedBox(height: 12),

                // 3. Filter Chips Horizontal Carousel
                _buildFilterChipsCarousel(
                  context,
                  ref,
                  state,
                  totalOpportunities,
                ),
                const SizedBox(height: 12),

                // 4. Applied Criteria Quick-Bar
                _buildAppliedCriteriaQuickBar(context, ref, profile, state),

                if (state.isActive) ...[
                  const SizedBox(height: 12),
                  _buildActiveFilterChips(context, ref, state),
                ],
                const SizedBox(height: 20),

                // 5. Opportunity Feed Header
                _buildFeedHeader(
                  context,
                  ref,
                  totalOpportunities,
                  studentName,
                  state.sort,
                ),
                const SizedBox(height: 16),

                // 6. Feed Cards Container
                KeyedSubtree(
                  key: _matchesKey,
                  child: _buildMatchesSection(
                    context,
                    ref,
                    filteredMatches,
                    filteredBrowse,
                    bookmarkIds,
                    appliedIds,
                    state,
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Deduplicated Browse Section
                _buildBrowseSection(
                  context,
                  ref,
                  filteredBrowse,
                  bookmarkIds,
                  appliedIds,
                ),
                const SizedBox(height: 28),

                // 8. Editorial End-of-Feed Helper Card
                _buildEditorialHelperCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Sticky Top Bar ---
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
                  size: 20,
                  color: Colors.white,
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

        // Notifications Bell & Profile Avatar
        Row(
          children: [
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

            GestureDetector(
              onTap: () {
                ref.read(homeTabIndexProvider.notifier).selectTab(3);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F9),
                    width: 1.5,
                  ),
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

  // --- 2. Search & Active Filter Bar ---
  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(child: _SearchField()),
        const SizedBox(width: 8),
        _FilterButton(
          onPressed: () => showDiscoveryFilterSheet(context),
        ),
      ],
    );
  }

  // --- 3. Filter Chips Horizontal Carousel ---
  Widget _buildFilterChipsCarousel(
    BuildContext context,
    WidgetRef ref,
    DiscoveryFilterState state,
    int totalMatches,
  ) {
    final notifier = ref.read(discoveryFilterProvider.notifier);
    final highFitActive = state.query.isEmpty && !state.closingSoonOnly && state.incomeBracket == null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          // All Matches Chip
          _StitchCarouselChip(
            label: 'All Matches ($totalMatches)',
            isActive: !state.isActive,
            onTap: () => notifier.reset(),
          ),
          const SizedBox(width: 8),

          // Match >90% Chip with green dot
          _StitchCarouselChip(
            label: 'Match >90%',
            hasDot: true,
            isActive: highFitActive && state.isActive,
            onTap: () {
              // Toggle search or filter focus
            },
          ),
          const SizedBox(width: 8),

          // Deadline < 14 Days Chip
          _StitchCarouselChip(
            label: 'Deadline < 14 Days',
            icon: Icons.schedule_rounded,
            isUrgent: true,
            isActive: state.closingSoonOnly,
            onTap: () {
              notifier.setClosingSoonOnly(!state.closingSoonOnly);
            },
          ),
          const SizedBox(width: 8),

          // No Essay Required Chip
          _StitchCarouselChip(
            label: 'No Essay Required',
            isActive: false,
            onTap: () {
              notifier.setQuery('No Essay');
            },
          ),
          const SizedBox(width: 8),

          // ₱50k - ₱150k+ Chip
          _StitchCarouselChip(
            label: '₱50k - ₱150k+',
            isActive: false,
            onTap: () {},
          ),
          const SizedBox(width: 8),

          // Need-Based Chip
          _StitchCarouselChip(
            label: 'Need-Based',
            isActive: state.incomeBracket == 'low',
            onTap: () {
              if (state.incomeBracket == 'low') {
                notifier.setIncomeBracket(null);
              } else {
                notifier.setIncomeBracket('low');
              }
            },
          ),
        ],
      ),
    );
  }

  // --- 4. Applied Criteria Quick-Bar ---
  Widget _buildAppliedCriteriaQuickBar(
    BuildContext context,
    WidgetRef ref,
    StudentProfile? profile,
    DiscoveryFilterState state,
  ) {
    final items = <String>[];
    if (profile != null) {
      if (profile.course.isNotEmpty) {
        items.add(profile.course);
      }
      items.add('College Yr ${profile.yearLevel}');
      if (profile.region.isNotEmpty) {
        items.add(profile.region);
      }
      if (profile.gpa > 0) {
        items.add('GPA ${profile.gpa.toStringAsFixed(1)}+');
      }
      if (profile.monthlyFamilyIncome != null &&
          profile.monthlyFamilyIncome! <= 20000) {
        items.add('Need-Based');
      }
    }
    if (state.incomeBracket != null) {
      items.add('Income: ${incomeLabel(state.incomeBracket)}');
    }
    if (state.closingSoonOnly) {
      items.add('Closing Soon (<14d)');
    }
    final criteriaSummary = items.isNotEmpty
        ? items.join(' • ')
        : 'All Fields • General Eligibility';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF), // surface-container-low
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE2F3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 18,
            color: Color(0xFF436084), // secondary
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: openSans(
                  fontSize: 12,
                  color: const Color(0xFF404942),
                ),
                children: [
                  TextSpan(
                    text: 'Active: ',
                    style: outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF161C27),
                    ),
                  ),
                  TextSpan(text: criteriaSummary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => showDiscoveryFilterSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Edit',
                style: outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF436084),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Active Filter Removable Chips ---
  Widget _buildActiveFilterChips(
    BuildContext context,
    WidgetRef ref,
    DiscoveryFilterState state,
  ) {
    final chips = <Widget>[];

    if (state.query.trim().isNotEmpty) {
      final label = state.query.trim();
      chips.add(_ActiveFilterChip(
        key: ValueKey('filter-chip-$label'),
        label: label,
        onRemove: () => ref.read(discoveryFilterProvider.notifier).setQuery(''),
      ));
    }

    if (state.incomeBracket != null) {
      final label = 'Income: ${incomeLabel(state.incomeBracket)}';
      chips.add(_ActiveFilterChip(
        key: ValueKey('filter-chip-$label'),
        label: label,
        onRemove: () =>
            ref.read(discoveryFilterProvider.notifier).setIncomeBracket(null),
      ));
    }

    for (final region in state.regions) {
      chips.add(_ActiveFilterChip(
        key: ValueKey('filter-chip-$region'),
        label: region,
        onRemove: () =>
            ref.read(discoveryFilterProvider.notifier).toggleRegion(region),
      ));
    }

    if (state.closingSoonOnly) {
      const label = 'Closing soon';
      chips.add(_ActiveFilterChip(
        key: const ValueKey('filter-chip-Closing soon'),
        label: label,
        onRemove: () =>
            ref.read(discoveryFilterProvider.notifier).setClosingSoonOnly(false),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => ref.read(discoveryFilterProvider.notifier).reset(),
            child: Text(
              'Clear all',
              style: outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F4D2E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 5. Opportunity Feed Header ---
  Widget _buildFeedHeader(
    BuildContext context,
    WidgetRef ref,
    int count,
    String studentName,
    DiscoverySort currentSort,
  ) {
    final sortLabel = currentSort == DiscoverySort.highestAmount
        ? 'Highest Amount'
        : 'Highest Match %';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verified Matches',
                style: outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF161C27),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Showing $count targeted opportunities for $studentName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: openSans(
                  fontSize: 12,
                  color: const Color(0xFF404942),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<DiscoverySort>(
          initialValue: currentSort,
          onSelected: (sort) {
            ref.read(discoveryFilterProvider.notifier).setSort(sort);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: DiscoverySort.defaultSort,
              child: Text('Highest Match %'),
            ),
            const PopupMenuItem(
              value: DiscoverySort.highestAmount,
              child: Text('Highest Amount'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8E5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sortLabel,
                    style: outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF161C27),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: Color(0xFF404942),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 6. Feed Cards Container ---
  Widget _buildMatchesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Scholarship>> matchesAsync,
    AsyncValue<List<Scholarship>> browseAsync,
    Set<String> bookmarkIds,
    Set<String> appliedIds,
    DiscoveryFilterState state,
  ) {
    return matchesAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotPoseView(
              pose: MascotPose.searching,
              height: 100,
            ),
            const SizedBox(height: 12),
            Text(
              'Finding matching scholarships...',
              style: outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161C27),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Analyzing eligibility requirements against your profile.',
              textAlign: TextAlign.center,
              style: openSans(fontSize: 12.5, color: const Color(0xFF707971)),
            ),
          ],
        ),
      ),
      error: (err, _) => ErrorView(
        message: 'Could not load your matches.',
        onRetry: () => ref.invalidate(matchesProvider),
      ),
      data: (matches) {
        final browse = browseAsync.valueOrNull ?? const <Scholarship>[];
        if (matches.isEmpty && browse.isEmpty) {
          return _buildNoResultsEmptyState(context, ref);
        }
        if (matches.isEmpty) {
          return _buildMatchesEmptyNote(context, ref, state);
        }

        final profile = ref.watch(currentProfileProvider).valueOrNull;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final scholarship = matches[index];
            final reasons = profile != null
                ? matchReasonsFor(profile, scholarship)
                : const <String>[];
            return ScholarshipCard(
              scholarship: scholarship,
              reasons: reasons,
              isBookmarked: bookmarkIds.contains(scholarship.id),
              isApplied: appliedIds.contains(scholarship.id),
              onToggleBookmark: () => _toggleBookmark(ref, scholarship.id),
              onQuickApply: () {
                context.push(
                  '/scholarship/${scholarship.id}',
                  extra: scholarship,
                );
              },
            );
          },
        );
      },
    );
  }

  // --- 7. Deduplicated Browse Section ---
  Widget _buildBrowseSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Scholarship>> browseAsync,
    Set<String> bookmarkIds,
    Set<String> appliedIds,
  ) {
    return browseAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => ErrorView(
        message: 'Could not load the scholarship catalog.',
        onRetry: () => ref.invalidate(scholarshipsProvider),
      ),
      data: (browse) {
        if (browse.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Browse all scholarships'),
            const SizedBox(height: 4),
            Text(
              'Showing ${browse.length} scholarships',
              style: openSans(fontSize: 13, color: const Color(0xFF404942)),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: browse.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => ScholarshipCard(
                scholarship: browse[i],
                isBookmarked: bookmarkIds.contains(browse[i].id),
                isApplied: appliedIds.contains(browse[i].id),
                onToggleBookmark: () => _toggleBookmark(ref, browse[i].id),
                onQuickApply: () {
                  context.push(
                    '/scholarship/${browse[i].id}',
                    extra: browse[i],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 8. Editorial End-of-Feed Helper Card ---
  Widget _buildEditorialHelperCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFB6D4FE), // secondary-container
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.hub_rounded,
                size: 24,
                color: Color(0xFF001C38),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Looking for more niche grants?',
            textAlign: TextAlign.center,
            style: outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF161C27),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect your local community college, regional foundation, or alumni affinity groups to unlock hyper-local aid.',
            textAlign: TextAlign.center,
            style: openSans(
              fontSize: 13,
              color: const Color(0xFF404942),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => showDiscoveryFilterSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF436084), // secondary Slate Navy
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.manage_search_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Update Eligibility Filters',
                    style: outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8E5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x081B3A5C),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotPoseView(
              pose: MascotPose.confused,
              height: 110,
            ),
            const SizedBox(height: 16),
            Text(
              'No scholarships found',
              textAlign: TextAlign.center,
              style: outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF161C27),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No scholarships match your current search and filters. Try adjusting your filters to see more results.',
              textAlign: TextAlign.center,
              style: openSans(
                fontSize: 13.5,
                color: const Color(0xFF404942),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => ref.read(discoveryFilterProvider.notifier).reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Clear search & filters',
                style: outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesEmptyNote(
    BuildContext context,
    WidgetRef ref,
    DiscoveryFilterState state,
  ) {
    if (state.isActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Your Matches', count: 0),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE2F3)),
            ),
            child: Row(
              children: [
                const MascotPoseView(
                  pose: MascotPose.confused,
                  height: 48,
                  width: 48,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No scholarships in your matches match the current search and filters.',
                    style: openSans(
                      fontSize: 13,
                      color: const Color(0xFF404942),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Your Matches', count: 0),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8E5)),
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
                height: 110,
              ),
              const SizedBox(height: 14),
              Text(
                'No matches found for your profile yet',
                textAlign: TextAlign.center,
                style: outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF161C27),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Complete your profile with your course, university, and GWA to unlock targeted grants and scholarships.',
                textAlign: TextAlign.center,
                style: openSans(
                  fontSize: 13,
                  color: const Color(0xFF404942),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Complete your profile',
                  style: outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleBookmark(WidgetRef ref, String id) async {
    try {
      await ref.read(bookmarksProvider.notifier).toggle(id);
    } on Exception {
      // Silent on card
    }
  }
}

// --- Components ---

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(discoveryFilterProvider).query;
    ref.listenManual<DiscoveryFilterState>(discoveryFilterProvider,
        (prev, next) {
      if (_controller.text != next.query) {
        _controller.text = next.query;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(discoveryFilterProvider).query;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) =>
            ref.read(discoveryFilterProvider.notifier).setQuery(value),
        textInputAction: TextInputAction.search,
        style: openSans(fontSize: 14, color: const Color(0xFF161C27)),
        decoration: InputDecoration(
          hintText: 'Search scholarships',
          hintStyle: openSans(fontSize: 13, color: const Color(0xFF707971)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF404942),
            size: 22,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () =>
                      ref.read(discoveryFilterProvider.notifier).setQuery(''),
                ),
        ),
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  const _FilterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(discoveryActiveFilterCountProvider);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8E5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                color: Color(0xFF436084),
                size: 20,
              ),
              const SizedBox(width: 5),
              Text(
                'Filter',
                style: outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF436084),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4D2E), // primary-container
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StitchCarouselChip extends StatelessWidget {
  const _StitchCarouselChip({
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isUrgent = false,
    this.hasDot = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isUrgent;
  final bool hasDot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    if (isActive) {
      bg = const Color(0xFF0F4D2E); // primary-container
      fg = Colors.white;
    } else if (isUrgent) {
      bg = const Color(0xFFFFDAD6); // error-container
      fg = const Color(0xFF93000A);
    } else {
      bg = Colors.white;
      fg = const Color(0xFF0F172A);
      border = Border.all(color: const Color(0xFFE2E8E5));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasDot) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB3F1C6), // primary-fixed
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0F4D2E).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              label,
              style: openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F4D2E),
              ),
            ),
          ),
          Tooltip(
            message: 'Remove filter',
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(Icons.close, size: 14, color: Color(0xFF0F4D2E)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
