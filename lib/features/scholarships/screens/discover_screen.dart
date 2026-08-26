// lib/features/scholarships/screens/discover_screen.dart
//
// The primary tab of the app. Personalized matching is the UX focus:
// - Greeting with the student's name
// - "Your Matches" — ranked list with explainability chips
// - "Browse all scholarships" — the full active catalog

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
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
    final matchesAsync = ref.watch(matchesProvider);
    final bookmarkIds = ref.watch(bookmarksProvider).valueOrNull ?? const <String>{};

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
              const SizedBox(height: 24),
              _buildMatchesSection(context, ref, matchesAsync, bookmarkIds),
              const SizedBox(height: 32),
              _buildBrowseSection(ref, bookmarkIds),
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

  Widget _buildMatchesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Scholarship>> matchesAsync,
    Set<String> bookmarkIds,
  ) {
    return matchesAsync.when(
      loading: () => const LoadingView(),
      error: (err, _) => ErrorView(
        message: 'Could not load your matches.',
        onRetry: () => ref.invalidate(matchesProvider),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return EmptyView(
            icon: Icons.search_off_rounded,
            title: 'No matches yet',
            message: 'Update your profile or adjust your preferences to discover scholarships.',
          );
        }

        final profile = ref.read(currentProfileProvider).valueOrNull!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your Matches',
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
                    '${matches.length}',
                    style: poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
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
                  onToggleBookmark: () => _toggleBookmark(ref, s.id),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrowseSection(WidgetRef ref, Set<String> bookmarkIds) {
    final allAsync = ref.watch(scholarshipsProvider);

    return allAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => ErrorView(
        message: 'Could not load the scholarship catalog.',
        onRetry: () => ref.invalidate(scholarshipsProvider),
      ),
      data: (all) {
        final matches = ref.read(matchesProvider).valueOrNull ?? [];
        final browse = all.where((s) => !matches.any((m) => m.id == s.id)).toList();

        if (browse.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browse all scholarships',
              style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
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

  Future<void> _toggleBookmark(WidgetRef ref, String id) async {
    try {
      await ref.read(bookmarksProvider.notifier).toggle(id);
    } on Exception {
      // Silent on card; the icon state is sufficient feedback.
    }
  }
}