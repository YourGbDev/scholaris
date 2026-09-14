// lib/features/scholarships/screens/discover_screen.dart
//
// The primary tab of the app. Personalized matching is the UX focus:
// - Greeting with the student's name
// - Search + filter controls that narrow both sections
// - "Your Matches" — ranked list with explainability chips
// - "Browse all scholarships" — the full active catalog, deduplicated

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/discovery_filter_sheet.dart';
import 'package:scholaris/features/scholarships/providers/dashboard_provider.dart';
import 'package:scholaris/features/scholarships/providers/discovery_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/services/discovery_filters.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/shared/widgets/section_header.dart';
import 'package:scholaris/shared/widgets/state_views.dart';
import 'package:scholaris/shared/widgets/student_mascot.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final filteredMatches = ref.watch(filteredMatchesProvider);
    final filteredBrowse = ref.watch(filteredBrowseProvider);
    final bookmarkIds =
        ref.watch(bookmarksProvider).valueOrNull ?? const <String>{};
    final appliedIds = ApplicationFilters.activeAppliedScholarshipIds(
      ref.watch(applicationsProvider).valueOrNull ?? const <Application>[],
    );
    final state = ref.watch(discoveryFilterProvider);

    return SafeArea(
      top: false,
      child: ResponsiveContainer(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentProfileProvider);
            ref.invalidate(matchesProvider);
            ref.invalidate(scholarshipsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _buildDashboard(context, ref, bookmarkIds, appliedIds, profileAsync),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(context, ref),
                    if (state.isActive) ...[
                      const SizedBox(height: 12),
                      _buildActiveFilterChips(context, ref, state),
                    ],
                    const SizedBox(height: 24),
                    _buildMatchesSection(
                      context,
                      ref,
                      filteredMatches,
                      filteredBrowse,
                      bookmarkIds,
                      appliedIds,
                      state,
                    ),
                    const SizedBox(height: 32),
                    _buildBrowseSection(
                      context,
                      ref,
                      filteredBrowse,
                      bookmarkIds,
                      appliedIds,
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

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    Set<String> bookmarkIds,
    Set<String> appliedIds,
    AsyncValue<StudentProfile?> profileAsync,
  ) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final profile = profileAsync.valueOrNull;
    final info = dashboardAsync.valueOrNull ??
        const DashboardInfo(
          matchCount: 0,
          closingSoonCount: 0,
          savedCount: 0,
          appliedCount: 0,
          pendingApplicationCount: 0,
          closingSoonScholarships: [],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TarsiDashboardHero(
          info: info,
          profile: profile,
        ),
        if (info.closingSoonScholarships.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildClosingSoonSection(
              ref,
              info,
              bookmarkIds,
              appliedIds,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClosingSoonSection(
    WidgetRef ref,
    DashboardInfo info,
    Set<String> bookmarkIds,
    Set<String> appliedIds,
  ) {
    return Column(
      key: const ValueKey('closing-soon-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Closing Soon', info.closingSoonCount),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: info.closingSoonScholarships.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, i) {
            final s = info.closingSoonScholarships[i];
            return ScholarshipCard(
              scholarship: s,
              isBookmarked: bookmarkIds.contains(s.id),
              isApplied: appliedIds.contains(s.id),
              onToggleBookmark: () => _toggleBookmark(ref, s.id),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(child: _SearchField()),
        const SizedBox(width: 12),
        _FilterButton(
          onPressed: () => showDiscoveryFilterSheet(context),
        ),
      ],
    );
  }

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
            child: const Text('Clear all'),
          ),
        ),
      ],
    );
  }

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
      loading: () => const LoadingView(),
      error: (err, _) => ErrorView(
        message: 'Could not load your matches.',
        onRetry: () => ref.invalidate(matchesProvider),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          final browse = browseAsync.valueOrNull;
          // The full empty state only appears when the entire filtered
          // discovery result is empty.
          if (browse != null && browse.isEmpty) {
            return _buildNoResultsEmptyState(context, ref);
          }
          return _buildMatchesEmptyNote(context, ref, state);
        }

        final profile = ref.read(currentProfileProvider).valueOrNull!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Your Matches',
              matches.length,
              trailing: _seeAllApplications(ref),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final s = matches[i];
                return ScholarshipCard(
                  scholarship: s,
                  reasons: matchReasonsFor(profile, s),
                  isBookmarked: bookmarkIds.contains(s.id),
                  isApplied: appliedIds.contains(s.id),
                  onToggleBookmark: () => _toggleBookmark(ref, s.id),
                );
              },
            ),
          ],
        );
      },
    );
  }

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
              style: openSans(fontSize: 13, color: Colors.black54),
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
              ),
            ),
          ],
        );
      },
    );
  }

  /// All section headers route through the shared [SectionHeader] so
  /// typography, the gold count badge and trailing actions stay consistent
  /// across every scrollable surface.
  Widget _buildSectionHeader(String title, int count, {Widget? trailing}) {
    return SectionHeader(title: title, count: count, trailing: trailing);
  }

  /// Trailing "See all" action for the matches section — jumps to the
  /// Applications tab. Title-left / action-right, the reference templates'
  /// section-title pattern restated with Scholaris tokens.
  Widget _seeAllApplications(WidgetRef ref) {
    return TextButton(
      key: const ValueKey('see-all-applications'),
      onPressed: () => ref.read(homeTabIndexProvider.notifier).selectTab(2),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        'See all',
        style: poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary),
      ),
    );
  }

  Widget _buildNoResultsEmptyState(BuildContext context, WidgetRef ref) {
    return EmptyView(
      icon: Icons.search_off_rounded,
      title: 'No scholarships found',
      message:
          'No scholarships match your current search and filters. Try adjusting them to see more results.',
      actionLabel: 'Clear search & filters',
      onAction: () => ref.read(discoveryFilterProvider.notifier).reset(),
      animateSearchIcon: true,
    );
  }

  Widget _buildMatchesEmptyNote(
    BuildContext context,
    WidgetRef ref,
    DiscoveryFilterState state,
  ) {
    final message = state.isActive
        ? 'No scholarships in your matches match the current search and filters.'
        : 'No matches yet. Update your profile or adjust your preferences to discover scholarships.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Your Matches', 0),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kWarmCream,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: kWarmCreamBorder),
          ),
          child: Row(
            children: [
              const StudentMascot(pose: StudentMascotPose.thinking, height: 48, width: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: openSans(
                    fontSize: 13,
                    color: const Color(0xFF5C4D38),
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

  Future<void> _toggleBookmark(WidgetRef ref, String id) async {
    try {
      await ref.read(bookmarksProvider.notifier).toggle(id);
    } on Exception {
      // Silent on card; the icon state is sufficient feedback.
    }
  }
}

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
    ref.listenManual<DiscoveryFilterState>(discoveryFilterProvider, (prev, next) {
      // Keep the field in sync when a filter is cleared from elsewhere.
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
    return TextField(
      controller: _controller,
      onChanged: (value) =>
          ref.read(discoveryFilterProvider.notifier).setQuery(value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search scholarships',
        prefixIcon: const Icon(Icons.search_rounded, color: kPrimary),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: () =>
                    ref.read(discoveryFilterProvider.notifier).setQuery(''),
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
      borderRadius: BorderRadius.circular(kRadiusInput),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(kRadiusInput),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusInput),
            border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.tune_rounded, color: kPrimary, size: 26),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
      padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: 'Remove filter',
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 14, color: kPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarsiDashboardHero extends StatelessWidget {
  const _TarsiDashboardHero({
    required this.info,
    this.profile,
  });

  final DashboardInfo info;
  final StudentProfile? profile;

  @override
  Widget build(BuildContext context) {
    final firstName = profile?.fullName.split(' ').first;
    final greeting = firstName != null && firstName.isNotEmpty
        ? 'Good to see you, $firstName'
        : 'Welcome to Scholaris';

    final fundingCount = info.matchCount > 0 ? info.matchCount : 2;
    final fundingAmount = fundingCount * 90000;
    final formattedFunding = fundingAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    // Profile strength / matching power (85% when setup complete, 45% initial)
    final double matchingPower = profile?.setupComplete == true ? 0.85 : 0.45;

    final topInset = MediaQuery.paddingOf(context).top;

    // Eli's casual message combining greeting + match/deadline insight
    final String eliMessage;
    final StudentMascotPose pose;
    final bool isDeadlineAlert = info.closingSoonCount > 0;

    if (isDeadlineAlert) {
      pose = StudentMascotPose.determined;
      final count = info.closingSoonCount;
      eliMessage =
          "You've got $count scholarship${count == 1 ? '' : 's'} closing soon worth ₱$formattedFunding. Don't miss your opportunity!";
    } else if (info.matchCount > 0) {
      pose = StudentMascotPose.hero;
      final count = info.matchCount;
      eliMessage =
          "You've got $count new scholarship match${count == 1 ? '' : 'es'} worth ₱$formattedFunding waiting for you.";
    } else {
      pose = StudentMascotPose.hero;
      eliMessage =
          "Explore opportunities below and bookmark the ones that match your academic goals!";
    }

    return Container(
      decoration: BoxDecoration(
        gradient: kHeroSurface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting on its own line at the top
          Text(
            greeting,
            style: poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          // Student mascot full-body illustration + speech bubble
          Container(
            key: const ValueKey('eli-advice-card'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kLumiGold.withValues(alpha: 0.38),
                            kLumiGold.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    StudentMascot(
                      pose: pose,
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Lumi Guide',
                                style: openSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (isDeadlineAlert)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kAccent.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Deadline Alert!',
                                  style: openSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: kAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          eliMessage,
                          style: openSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.95),
                            height: 1.38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Matching Power mini-progress bar
          Row(
            children: [
              Text(
                'Matching Power',
                style: openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
              const Spacer(),
              Text(
                '${(matchingPower * 100).toInt()}%',
                style: poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: kAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: matchingPower,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
            ),
          ),
          const SizedBox(height: 16),

          // Quick stat chips row (4-tile layout with left-edge accent bars)
          Row(
            children: [
              Expanded(
                child: _TarsiStatChip(
                  statKey: 'matches',
                  count: info.matchCount,
                  label: 'Matches',
                  icon: Icons.auto_awesome_rounded,
                  accent: kPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TarsiStatChip(
                  statKey: 'closing-soon',
                  count: info.closingSoonCount,
                  label: 'Closing soon',
                  icon: Icons.schedule_rounded,
                  accent: kAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TarsiStatChip(
                  statKey: 'saved',
                  count: info.savedCount,
                  label: 'Bookmarked',
                  icon: Icons.collections_bookmark_rounded,
                  accent: kNavyTrust,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TarsiStatChip(
                  statKey: 'applied',
                  count: info.appliedCount,
                  label: 'Applied',
                  icon: Icons.send_rounded,
                  accent: kCoralConnect,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarsiStatChip extends StatelessWidget {
  const _TarsiStatChip({
    required this.statKey,
    required this.count,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String statKey;
  final int count;
  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count $label',
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3.5,
                color: accent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 13, color: accent),
                          const SizedBox(width: 3),
                          Text(
                            '$count',
                            key: ValueKey('stat-count-$statKey'),
                            style: poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: openSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
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
      ),
    );
  }
}