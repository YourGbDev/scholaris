// lib/features/scholarships/screens/discover_screen.dart
//
// The primary tab of the app. Personalized matching is the UX focus:
// - Greeting with the student's name
// - Search + filter controls that narrow both sections
// - "Your Matches" — ranked list with explainability chips
// - "Browse all scholarships" — the full active catalog, deduplicated

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/discovery_filter_sheet.dart';
import 'package:scholaris/features/scholarships/providers/discovery_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/services/discovery_filters.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final filteredMatches = ref.watch(filteredMatchesProvider);
    final filteredBrowse = ref.watch(filteredBrowseProvider);
    final bookmarkIds =
        ref.watch(bookmarksProvider).valueOrNull ?? const <String>{};
    final state = ref.watch(discoveryFilterProvider);

    return SafeArea(
      child: ResponsiveContainer(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentProfileProvider);
            ref.invalidate(matchesProvider);
            ref.invalidate(scholarshipsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _buildGreeting(profileAsync),
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
                state,
              ),
              const SizedBox(height: 32),
              _buildBrowseSection(context, ref, filteredBrowse, bookmarkIds),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(AsyncValue<StudentProfile?> profileAsync) {
    final name = profileAsync.valueOrNull?.fullName;
    final greeting = name != null
        ? 'Good to see you, ${name.split(' ').first}'
        : 'Welcome to Scholaris';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Here are scholarships that fit your profile.',
          style: openSans(fontSize: 14, color: Colors.black54),
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

    for (final coverage in state.coverageTypes) {
      final label = coverageLabel(coverage);
      chips.add(_ActiveFilterChip(
        key: ValueKey('filter-chip-$label'),
        label: label,
        onRemove: () =>
            ref.read(discoveryFilterProvider.notifier).toggleCoverage(coverage),
      ));
    }

    for (final tag in state.tags) {
      chips.add(_ActiveFilterChip(
        key: ValueKey('filter-chip-$tag'),
        label: tag,
        onRemove: () => ref.read(discoveryFilterProvider.notifier).toggleTag(tag),
      ));
    }

    if (state.minAmount != null || state.maxAmount != null) {
      final label = _amountChipLabel(state.minAmount, state.maxAmount);
      chips.add(_ActiveFilterChip(
        key: ValueKey('filter-chip-$label'),
        label: label,
        onRemove: () {
          final notifier = ref.read(discoveryFilterProvider.notifier);
          notifier.setMinAmount(null);
          notifier.setMaxAmount(null);
        },
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
            _buildSectionHeader('Your Matches', matches.length),
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
            Text(
              'Browse all scholarships',
              style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
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
                onToggleBookmark: () => _toggleBookmark(ref, browse[i].id),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: kAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
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
            color: kPrimarySoft,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: kPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: openSans(fontSize: 13, color: kPrimary),
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

String _amountChipLabel(double? min, double? max) {
  if (min != null && max != null) return '₱${min.round()} – ₱${max.round()}';
  if (min != null) return 'Min ₱${min.round()}';
  if (max != null) return 'Max ₱${max.round()}';
  return '';
}
