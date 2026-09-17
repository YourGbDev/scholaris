// lib/features/scholarships/screens/saved_screen.dart
//
// "Saved" tab — the scholarships the student has bookmarked, rebuilt to match the
// Stitch design specifications. Combines the bookmark ids from [bookmarksProvider]
// with the active catalog to render scholarship cards. Includes a Stitch empty state
// with halo bookmark icon, CTA to Discover, and Trending Grants suggestions.

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
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Saved Scholarships',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF161C27),
                    ),
                  ),
                  const SizedBox(width: 8),
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
            Expanded(
              child: _buildBody(ref, bookmarksAsync, allAsync, appliedIds),
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

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(bookmarksProvider);
                ref.invalidate(scholarshipsProvider);
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: saved.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, i) => ScholarshipCard(
                  scholarship: saved[i],
                  isBookmarked: true,
                  isApplied: appliedIds.contains(saved[i].id),
                  onToggleBookmark: () => _toggleBookmark(ref, saved[i].id),
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
      await ref.read(bookmarksProvider.notifier).toggle(id);
    } on Exception {
      // Silent on card; the icon state is sufficient feedback.
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
          // Hero Card
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
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2E4FF).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD2E4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmarks_rounded,
                        size: 32,
                        color: Color(0xFF436084),
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 24,
                        height: 24,
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
                          size: 14,
                          color: Color(0xFFFABC28),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Nothing saved yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF161C27),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep track of deadlines, compare grant stipends, and prepare your '
                  'application requirements without losing your spot. Tap the bookmark '
                  'icon on any scholarship to keep it here.',
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
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(homeTabIndexProvider.notifier).selectTab(0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Discover Scholarships',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Trending Grants Near You Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 18,
                    color: Color(0xFFFABC28),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Trending Grants Near You',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF161C27),
                    ),
                  ),
                ],
              ),
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
            category: 'STEM & Tech',
            title: 'DOST-SEI Undergraduate Merit Scholarship',
            provider: 'Department of Science and Technology',
            amount: '₱80,000',
            frequency: '/yr',
            badgeText: 'Closing in 14 days',
            badgeIcon: Icons.schedule_rounded,
            badgeColor: const Color(0xFFFFDAD6),
            badgeTextColor: const Color(0xFFBA1A1A),
            onTap: () {
              ref.read(homeTabIndexProvider.notifier).selectTab(0);
            },
          ),
          const SizedBox(height: 10),
          // Trending Grant Suggestion 2: Megaworld Foundation
          _SuggestedGrantCard(
            category: 'Corporate Grant',
            title: 'Megaworld Foundation Future Tech Leaders',
            provider: 'Megaworld Foundation, Inc.',
            amount: '₱120,000',
            frequency: '/yr',
            badgeText: 'SUC Accredited',
            badgeIcon: Icons.verified_rounded,
            badgeColor: const Color(0xFFD2E4FF),
            badgeTextColor: const Color(0xFF001C38),
            onTap: () {
              ref.read(homeTabIndexProvider.notifier).selectTab(0);
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestedGrantCard extends StatelessWidget {
  const _SuggestedGrantCard({
    required this.category,
    required this.title,
    required this.provider,
    required this.amount,
    required this.frequency,
    required this.badgeText,
    required this.badgeIcon,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.onTap,
  });

  final String category;
  final String title;
  final String provider;
  final String amount;
  final String frequency;
  final String badgeText;
  final IconData badgeIcon;
  final Color badgeColor;
  final Color badgeTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
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
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3FF).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          amount,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
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
