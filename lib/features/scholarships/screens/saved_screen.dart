// lib/features/scholarships/screens/saved_screen.dart
//
// "Saved" tab — the scholarships the student has bookmarked. Combines the
// bookmark ids from [bookmarksProvider] with the active catalog to render
// scholarship cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
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

    return SafeArea(
      child: ResponsiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Saved',
                style: poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kPrimary),
              ),
            ),
            Expanded(child: _buildBody(ref, bookmarksAsync, allAsync, appliedIds)),
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
          return const EmptyView(
            icon: Icons.bookmark_border_rounded,
            title: 'Nothing saved yet',
            message: 'Tap the bookmark on any scholarship to keep it here.',
          );
        }

        return allAsync.when(
          loading: () => const LoadingView(),
          error: (_, _) => ErrorView(
            message: 'Could not load scholarship details.',
            onRetry: () => ref.invalidate(scholarshipsProvider),
          ),
          data: (all) {
            final saved =
                all.where((s) => ids.contains(s.id)).toList();

            if (saved.isEmpty) {
              return const EmptyView(
                icon: Icons.bookmark_border_rounded,
                title: 'Nothing saved yet',
                message: 'Tap the bookmark on any scholarship to keep it here.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: saved.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => ScholarshipCard(
                scholarship: saved[i],
                isBookmarked: true,
                isApplied: appliedIds.contains(saved[i].id),
                onToggleBookmark: () => _toggleBookmark(ref, saved[i].id),
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