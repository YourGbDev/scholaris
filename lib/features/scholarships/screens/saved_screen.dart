// lib/features/scholarships/screens/saved_screen.dart
//
// "Saved" tab — the scholarships the student has bookmarked, rebuilt to 100%
// visual, structural, and literal fidelity against Stitch V2 specifications:
// `design-reference/stitch_scholaris_mobile_app/scholaris_no_bookmarks_yet_saved_grants_empty_state/code.html`
//
// Features:
// - Header with "Saved Scholarships" title, dynamic "(X saved)" counter, and search toggle
// - Search filter bar with live text search and clear button
// - Stitch Empty State:
//   - Dual-layer concentric halo with bookmarks icon & amber star badge
//   - Literal Stitch copy: "Save scholarships you're interested in"
//   - "Discover Scholarships" primary CTA button navigating to Discover tab
//   - "Trending Grants Near You" section with DOST-SEI & Megaworld Foundation cards
//   - Live interactive bookmark buttons with Stitch toast snackbars
// - Populated State:
//   - Full ScholarshipCard integration with bookmark toggle & quick apply
//   - Pull-to-refresh
//   - Empty search results state with quick clear action

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final allAsync = ref.watch(scholarshipsProvider);
    final appliedIds = ApplicationFilters.activeAppliedScholarshipIds(
      ref.watch(applicationsProvider).valueOrNull ?? const <Application>[],
    );

    final savedCount = bookmarksAsync.valueOrNull?.length ?? 0;

    return SafeArea(
      child: ResponsiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header matching Stitch
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Saved Scholarships',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF161C27),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '($savedCount saved)',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF404942),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: _searchOpen
                        ? const Color(0xFFE8EEFF)
                        : Colors.transparent,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Search saved scholarships',
                      icon: Icon(
                        _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                        size: 22,
                        color: const Color(0xFF404942),
                      ),
                      onPressed: () {
                        setState(() {
                          _searchOpen = !_searchOpen;
                          if (!_searchOpen) {
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Expandable Search Bar
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search saved scholarships...',
                    hintStyle: GoogleFonts.openSans(
                      fontSize: 13.5,
                      color: const Color(0xFF707971),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFF436084),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kPrimary, width: 1.5),
                    ),
                  ),
                  style: GoogleFonts.openSans(fontSize: 14),
                ),
              ),

            Expanded(
              child: _buildBody(
                ref,
                bookmarksAsync,
                allAsync,
                appliedIds,
                _searchQuery,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    WidgetRef ref,
    AsyncValue<Set<String>> bookmarksAsync,
    AsyncValue<List<Scholarship>> allAsync,
    Set<String> appliedIds,
    String searchQuery,
  ) {
    return bookmarksAsync.when(
      loading: () => const LoadingView(),
      error: (_, _) => ErrorView(
        message: 'Could not load your saved scholarships.',
        onRetry: () => ref.invalidate(bookmarksProvider),
      ),
      data: (ids) {
        if (ids.isEmpty) {
          return const _SavedEmptyState();
        }

        return allAsync.when(
          loading: () => const LoadingView(),
          error: (_, _) => ErrorView(
            message: 'Could not load scholarship details.',
            onRetry: () => ref.invalidate(scholarshipsProvider),
          ),
          data: (all) {
            final saved = all.where((s) => ids.contains(s.id)).toList();

            if (saved.isEmpty) {
              return const _SavedEmptyState();
            }

            final filtered = searchQuery.isEmpty
                ? saved
                : saved.where((s) {
                    final title = s.title.toLowerCase();
                    final provider = (s.provider ?? '').toLowerCase();
                    return title.contains(searchQuery) ||
                        provider.contains(searchQuery);
                  }).toList();

            if (filtered.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Color(0xFF707971),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No matching saved scholarships',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF161C27),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try searching with a different keyword.',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: const Color(0xFF404942),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _searchController.clear(),
                        child: Text(
                          'Clear search',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(bookmarksProvider);
                ref.invalidate(scholarshipsProvider);
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, i) => ScholarshipCard(
                  scholarship: filtered[i],
                  isBookmarked: true,
                  isApplied: appliedIds.contains(filtered[i].id),
                  onToggleBookmark: () => _toggleBookmark(ref, filtered[i].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleBookmark(WidgetRef ref, String id) async {
    try {
      final added = await ref.read(bookmarksProvider.notifier).toggle(id);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2A303D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                Icon(
                  added ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: const Color(0xFFB3F1C6),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  added
                      ? 'Scholarship saved to your list!'
                      : 'Scholarship removed from bookmarks',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } on Exception {
      // Silent on card failure
    }
  }
}

/// Stitch Empty State for Saved Grants (`scholaris_no_bookmarks_yet_saved_grants_empty_state`)
class _SavedEmptyState extends ConsumerWidget {
  const _SavedEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Card with Dual Concentric Halo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x081B3A5C),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Concentric Halo with Bookmark and Star
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2E4FF).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD2E4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmarks_rounded,
                        size: 36,
                        color: Color(0xFF436084),
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.hotel_class_rounded,
                          size: 15,
                          color: Color(0xFFFABC28),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Literal Stitch copy
                Text(
                  "Save scholarships you're interested in",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF161C27),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep track of deadlines, compare grant stipends, and prepare your '
                  'application requirements without losing your spot. Tap the bookmark '
                  'icon on any scholarship card to save it here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFF404942),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: () {
                      // Navigate to Discover tab (tab 1 in home navigation)
                      ref.read(homeTabIndexProvider.notifier).selectTab(1);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4D2E), // Stitch primary-container
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      'Discover Scholarships',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Trending Grants Near You Section (Stitch lines 33-87)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: Color(0xFFFABC28),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Trending Grants Near You',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF161C27),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2E4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'SUGGESTED',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF001C38),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Trending Grant Suggestion 1: DOST-SEI
          _SuggestedGrantCard(
            scholarshipId: 'sch-dost',
            category: 'STEM & Tech',
            title: 'DOST-SEI Undergraduate Merit Scholarship',
            provider: 'Department of Science and Technology',
            amount: '₱80,000',
            frequency: '/yr',
            badgeText: 'Closing in 14 days',
            badgeIcon: Icons.schedule_rounded,
            badgeColor: const Color(0xFFFFDAD6),
            badgeTextColor: const Color(0xFFBA1A1A),
          ),
          const SizedBox(height: 10),

          // Trending Grant Suggestion 2: Megaworld Foundation
          _SuggestedGrantCard(
            scholarshipId: 'sch-megaworld',
            category: 'Corporate Grant',
            title: 'Megaworld Foundation Future Tech Leaders',
            provider: 'Megaworld Foundation, Inc.',
            amount: '₱120,000',
            frequency: '/yr',
            badgeText: 'SUC Accredited',
            badgeIcon: Icons.verified_rounded,
            badgeColor: const Color(0xFFD2E4FF),
            badgeTextColor: const Color(0xFF001C38),
          ),
        ],
      ),
    );
  }
}

class _SuggestedGrantCard extends ConsumerWidget {
  const _SuggestedGrantCard({
    required this.scholarshipId,
    required this.category,
    required this.title,
    required this.provider,
    required this.amount,
    required this.frequency,
    required this.badgeText,
    required this.badgeIcon,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final String scholarshipId;
  final String category;
  final String title;
  final String provider;
  final String amount;
  final String frequency;
  final String badgeText;
  final IconData badgeIcon;
  final Color badgeColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final isSaved = bookmarksAsync.valueOrNull?.contains(scholarshipId) ?? false;
    final allScholarships = ref.watch(scholarshipsProvider).valueOrNull;
    final realScholarship = allScholarships?.cast<Scholarship?>().firstWhere(
          (s) => s?.id == scholarshipId,
          orElse: () => null,
        );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (realScholarship != null) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ScholarshipDetailScreen(scholarshipId: realScholarship.id),
              ),
            );
          } else {
            // Switch to discover tab
            ref.read(homeTabIndexProvider.notifier).selectTab(1);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF404942),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF161C27),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: const Color(0xFF404942),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Interactive Bookmark toggle button (Stitch lines 49-51)
                  Material(
                    color: isSaved
                        ? const Color(0xFF0F4D2E)
                        : const Color(0xFFF1F3FF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async {
                        try {
                          final added = await ref.read(bookmarksProvider.notifier).toggle(scholarshipId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF2A303D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                content: Row(
                                  children: [
                                    Icon(
                                      added ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                      color: const Color(0xFFB3F1C6),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      added
                                          ? 'Scholarship saved to your list!'
                                          : 'Scholarship removed from bookmarks',
                                      style: GoogleFonts.openSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        } catch (_) {}
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                          size: 18,
                          color: isSaved ? Colors.white : const Color(0xFF436084),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3FF).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          amount,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F4D2E),
                          ),
                        ),
                        Text(
                          frequency,
                          style: GoogleFonts.openSans(
                            fontSize: 11,
                            color: const Color(0xFF404942),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: badgeTextColor),
                          const SizedBox(width: 3),
                          Text(
                            badgeText,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: badgeTextColor,
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
      ),
    );
  }
}
