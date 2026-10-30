import 'package:scholaris/features/home/presentation/widgets/student_tab_entrance.dart';
// lib/features/scholarships/screens/discover_screen.dart
//
// Student Core Flow — Stitch Discover Screen (scholaris_discover_filters/code.html):
// - Sticky top bar with Scholaris logo, notifications, and account settings
// - Search & Active Filter Bar (Search input + "Filters" button with active count badge)
// - Filter Chips Horizontal Carousel (All Matches, Match >90%, Deadline < 14 Days, No Essay, ₱50k - ₱150k+, Need-Based)
// - Compact Matched for you heading; sorting remains in Filters
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
import 'package:scholaris/shared/widgets/student_header_actions.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/discovery_filter_sheet.dart';
import 'package:scholaris/features/scholarships/providers/dashboard_provider.dart';
import 'package:scholaris/features/scholarships/providers/discovery_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/services/discovery_filters.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/shared/widgets/section_header.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({
    super.key,
    this.scrollController,
    this.detailsGuideKey,
    this.endGuideKey,
  });
  final ScrollController? scrollController;
  final GlobalKey? detailsGuideKey;
  final GlobalKey? endGuideKey;

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final GlobalKey _matchesKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final filteredMatches = ref.watch(filteredMatchesProvider);
    final filteredBrowse = ref.watch(filteredBrowseProvider);
    final bookmarkIds =
        ref.watch(bookmarksProvider).valueOrNull ?? const <String>{};
    final appliedIds = ApplicationFilters.activeAppliedScholarshipIds(
      ref.watch(applicationsProvider).valueOrNull ?? const <Application>[],
    );
    final state = ref.watch(discoveryFilterProvider);

    final matchesList = filteredMatches.valueOrNull ?? const <Scholarship>[];
    final totalOpportunities = matchesList.length;

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
              physics: const AppleBouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 64 + 16,
              ),
              children: [
                // 1. Sticky Header
                StudentTabReveal(
                  order: 0,
                  immediate: true,
                  child: _buildHeader(context),
                ),
                const SizedBox(height: 16),

                // 2. Search & Active Filter Bar
                StudentTabReveal(
                  order: 1,
                  structural: true,
                  child: _buildSearchBar(context, ref),
                ),
                const SizedBox(height: 12),

                // 3. Filter Chips Horizontal Carousel
                StudentTabReveal(
                  order: 1,
                  structural: true,
                  child: _buildFilterChipsCarousel(
                    context,
                    ref,
                    state,
                    totalOpportunities,
                  ),
                ),

                if (state.isActive) ...[
                  const SizedBox(height: 12),
                  StudentTabReveal(
                    order: 1,
                    structural: true,
                    child: _buildActiveFilterChips(context, ref, state),
                  ),
                ],
                const SizedBox(height: 16),

                // 5. Opportunity Feed Header
                StudentTabReveal(
                  order: 2,
                  structural: true,
                  child: _buildFeedHeader(),
                ),
                const SizedBox(height: 12),

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
                KeyedSubtree(
                  key: widget.endGuideKey,
                  child: StudentTabReveal(
                    order: 6,
                    child: _buildEditorialHelperCard(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Sticky Top Bar ---
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
            ),
          ),
        ),

        const StudentHeaderActions(),
      ],
    );
  }

  // --- 2. Search & Active Filter Bar ---
  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(child: _SearchField()),
        const SizedBox(width: 8),
        _FilterButton(onPressed: () => showDiscoveryFilterSheet(context)),
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

    return SingleChildScrollView(
      physics: const AppleBouncingScrollPhysics(),
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
            label: 'Match >90% • Demo',
            hasDot: true,
            isActive: state.highFitOnly,
            onTap: () {
              notifier.setHighFitOnly(!state.highFitOnly);
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
            isActive: state.query == 'No Essay',
            onTap: () {
              if (state.query == 'No Essay') {
                notifier.setQuery('');
              } else {
                notifier.setQuery('No Essay');
              }
            },
          ),
          const SizedBox(width: 8),

          // ₱50k - ₱150k+ Chip
          _StitchCarouselChip(
            label: '₱50k - ₱150k+',
            isActive: state.minAmount == 50000,
            onTap: () {
              notifier.setMinAmount(state.minAmount == 50000 ? null : 50000);
            },
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

  // --- Active Filter Removable Chips ---
  Widget _buildActiveFilterChips(
    BuildContext context,
    WidgetRef ref,
    DiscoveryFilterState state,
  ) {
    final chips = <Widget>[];

    if (state.query.trim().isNotEmpty) {
      final label = state.query.trim();
      chips.add(
        _ActiveFilterChip(
          key: ValueKey('filter-chip-$label'),
          label: label,
          onRemove: () =>
              ref.read(discoveryFilterProvider.notifier).setQuery(''),
        ),
      );
    }

    if (state.incomeBracket != null) {
      final label = 'Income: ${incomeLabel(state.incomeBracket)}';
      chips.add(
        _ActiveFilterChip(
          key: ValueKey('filter-chip-$label'),
          label: label,
          onRemove: () =>
              ref.read(discoveryFilterProvider.notifier).setIncomeBracket(null),
        ),
      );
    }

    for (final region in state.regions) {
      chips.add(
        _ActiveFilterChip(
          key: ValueKey('filter-chip-$region'),
          label: region,
          onRemove: () =>
              ref.read(discoveryFilterProvider.notifier).toggleRegion(region),
        ),
      );
    }

    if (state.closingSoonOnly) {
      const label = 'Closing soon';
      chips.add(
        _ActiveFilterChip(
          key: const ValueKey('filter-chip-Closing soon'),
          label: label,
          onRemove: () => ref
              .read(discoveryFilterProvider.notifier)
              .setClosingSoonOnly(false),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: chips),
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
  Widget _buildFeedHeader() => Text(
    'Matched for you',
    style: outfit(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF161C27),
      letterSpacing: -0.3,
    ),
  );

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
      loading: () =>
          StudentTabReveal(order: 3, child: _buildDiscoverSkeleton()),
      error: (err, _) => StudentTabReveal(
        order: 3,
        child: ErrorView(
          message: 'Could not load your matches.',
          onRetry: () => ref.invalidate(matchesProvider),
        ),
      ),
      data: (matches) {
        final browse = browseAsync.valueOrNull ?? const <Scholarship>[];
        if (matches.isEmpty && browse.isEmpty) {
          return StudentTabReveal(
            order: 3,
            child: _buildNoResultsEmptyState(context, ref),
          );
        }
        if (matches.isEmpty) {
          return StudentTabReveal(
            order: 3,
            child: _buildMatchesEmptyNote(context, ref, state),
          );
        }

        final profile = ref.watch(currentProfileProvider).valueOrNull;

        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final scholarship = matches[index];
            final reasons = profile != null
                ? matchReasonsFor(profile, scholarship)
                : const <String>[];
            return StudentTabReveal(
              order: 1 + index,
              child: ScholarshipCard(
                viewDetailsKey: index == 0 ? widget.detailsGuideKey : null,
                scholarship: scholarship,
                studentProfile: profile,
                reasons: reasons,
                isBookmarked: bookmarkIds.contains(scholarship.id),
                isApplied: appliedIds.contains(scholarship.id),
                onToggleBookmark: () => _toggleBookmark(ref, scholarship.id),
                onQuickApply: () {
                  context.push(
                    '/scholarship/${scholarship.id}?apply=1',
                    extra: scholarship,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDiscoverSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
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
                    SkeletonBand(width: 90, height: 22, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 12),
                SkeletonBand(width: 240, height: 20, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonBand(width: 160, height: 14, borderRadius: 4),
                SizedBox(height: 12),
                SkeletonBand(height: 48, borderRadius: 8),
              ],
            ),
          ),
        ),
      ),
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
      error: (err, _) => StudentTabReveal(
        order: 3,
        child: ErrorView(
          message: 'Could not load the scholarship catalog.',
          onRetry: () => ref.invalidate(scholarshipsProvider),
        ),
      ),
      data: (browse) {
        if (browse.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentTabReveal(
              order: 2,
              structural: true,
              child: SectionHeader(title: 'Browse all scholarships'),
            ),
            const SizedBox(height: 4),
            StudentTabReveal(
              order: 0,
              child: Text(
                'Showing ${browse.length} scholarships',
                style: openSans(fontSize: 13, color: const Color(0xFF404942)),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: browse.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => StudentTabReveal(
                order: 1 + i,
                child: ScholarshipCard(
                  scholarship: browse[i],
                  viewDetailsKey:
                      i == 0 &&
                          (ref
                                  .watch(filteredMatchesProvider)
                                  .valueOrNull
                                  ?.isEmpty ??
                              false)
                      ? widget.detailsGuideKey
                      : null,
                  studentProfile: ref.watch(currentProfileProvider).valueOrNull,
                  reasons: ref.watch(currentProfileProvider).valueOrNull == null
                      ? const []
                      : matchReasonsFor(
                          ref.watch(currentProfileProvider).valueOrNull!,
                          browse[i],
                        ),
                  isBookmarked: bookmarkIds.contains(browse[i].id),
                  isApplied: appliedIds.contains(browse[i].id),
                  onToggleBookmark: () => _toggleBookmark(ref, browse[i].id),
                  onQuickApply: () {
                    context.push(
                      '/scholarship/${browse[i].id}?apply=1',
                      extra: browse[i],
                    );
                  },
                ),
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
      decoration: kSoftCardDecoration,
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
          PressableScale(
            child: ElevatedButton(
              onPressed: () => showDiscoveryFilterSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF436084,
                ), // secondary Slate Navy
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                      style: outfit(fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildNoResultsEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: kSoftCardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotPoseView(pose: MascotPose.confused, height: 110),
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
              onPressed: () =>
                  ref.read(discoveryFilterProvider.notifier).reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
              color: const Color(0xFFF0F0F0),
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
          decoration: kSoftCardDecoration,
          child: Column(
            children: [
              const MascotPoseView(pose: MascotPose.consoling, height: 110),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
    ref.listenManual<DiscoveryFilterState>(discoveryFilterProvider, (
      prev,
      next,
    ) {
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
        border: kCardBorderCrisp,
        boxShadow: kCardElevationCrisp,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
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
    return PressableScale(
      child: Tooltip(
        message: 'Open discovery filters',
        child: Material(
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
                border: kCardBorderCrisp,
                boxShadow: kCardElevationCrisp,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
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
      bg = const Color(0xFFFFF0EE);
      fg = const Color(0xFFC62828);
      border = Border.all(color: const Color(0x33FF6F59), width: 0.75);
    } else {
      bg = Colors.white;
      fg = const Color(0xFF0F172A);
      border = kCardBorderCrisp;
    }

    return PressableScale(
      child: Material(
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
              boxShadow: isActive || isUrgent ? null : kCardElevationCrisp,
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
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0F4D2E).withValues(alpha: 0.25),
        ),
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
            child: PressableScale(
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF0F4D2E),
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
