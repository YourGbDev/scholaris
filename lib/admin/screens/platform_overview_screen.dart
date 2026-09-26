// lib/admin/screens/platform_overview_screen.dart
//
// Admin Console: Platform Overview (Screen 5 Rebuild)
// Visual tokens: scholaris_sequoia/DESIGN.md
// Strictly real data: 100% wired to live Supabase counts across core tables.
// Zero fabricated metrics, zero fake compliance stamps, zero fake trends/charts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// 1. Domain Model: PlatformOverviewData
// =============================================================================

class PlatformOverviewData {
  const PlatformOverviewData({
    required this.registeredUsers,
    required this.activeScholarships,
    required this.applications,
    required this.providerVerifications,
    required this.auditEvents,
    required this.loginAttempts,
    required this.bookmarks,
  });

  final int registeredUsers;
  final int activeScholarships;
  final int applications;
  final int providerVerifications;
  final int auditEvents;
  final int loginAttempts;
  final int bookmarks;
}

// =============================================================================
// 2. Data Provider
// =============================================================================

final platformOverviewDataProvider =
    FutureProvider<PlatformOverviewData>((ref) async {
  final supabase = Supabase.instance.client;

  Future<int> fetchCount(String table) async {
    try {
      final res = await supabase.from(table).select('id').count(CountOption.exact);
      return res.count;
    } catch (_) {
      // Fallback: fetch ids with limit
      final res = await supabase.from(table).select('id');
      return (res as List).length;
    }
  }

  final results = await Future.wait([
    fetchCount('profiles'),
    fetchCount('scholarships'),
    fetchCount('applications'),
    fetchCount('provider_verifications'),
    fetchCount('audit_logs'),
    fetchCount('login_attempts'),
    fetchCount('bookmarks'),
  ]);

  return PlatformOverviewData(
    registeredUsers: results[0],
    activeScholarships: results[1],
    applications: results[2],
    providerVerifications: results[3],
    auditEvents: results[4],
    loginAttempts: results[5],
    bookmarks: results[6],
  );
});

// =============================================================================
// 3. UI Component: PlatformOverviewScreen
// =============================================================================

class PlatformOverviewScreen extends ConsumerWidget {
  const PlatformOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(platformOverviewDataProvider);

    return Scaffold(
      backgroundColor: kSeqSurface,
      body: overviewAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: kSeqPrimaryContainer,
            strokeWidth: 2.5,
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: kSeqError),
                const SizedBox(height: 12),
                Text(
                  'Failed to load platform statistics',
                  style: seqHeadlineSm(color: kSeqOnSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  err.toString(),
                  style: seqBodyMd(color: kSeqOnSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(platformOverviewDataProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSeqPrimary,
                    foregroundColor: kSeqOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final width = MediaQuery.sizeOf(context).width;

          final statCards = [
            _StatCardConfig(
              label: 'Registered Users',
              count: data.registeredUsers,
              icon: Icons.people_alt_outlined,
              accentColor: kSeqPrimaryContainer,
              containerBg: kSeqPrimaryFixed.withValues(alpha: 0.35),
            ),
            _StatCardConfig(
              label: 'Active Scholarships',
              count: data.activeScholarships,
              icon: Icons.school_outlined,
              accentColor: kSeqSecondary,
              containerBg: kSeqSecondaryFixed.withValues(alpha: 0.35),
            ),
            _StatCardConfig(
              label: 'Applications',
              count: data.applications,
              icon: Icons.assignment_outlined,
              accentColor: kSeqTertiaryContainer,
              containerBg: kSeqTertiaryFixed.withValues(alpha: 0.35),
            ),
            _StatCardConfig(
              label: 'Provider Verifications',
              count: data.providerVerifications,
              icon: Icons.verified_user_outlined,
              accentColor: const Color(0xFF2E6B4E),
              containerBg: const Color(0xFFD4EBD9),
            ),
            _StatCardConfig(
              label: 'Audit Events',
              count: data.auditEvents,
              icon: Icons.history_rounded,
              accentColor: const Color(0xFF6B4C1B),
              containerBg: const Color(0xFFF7E6CC),
            ),
            _StatCardConfig(
              label: 'Login Attempts',
              count: data.loginAttempts,
              icon: Icons.login_rounded,
              accentColor: const Color(0xFF1E5280),
              containerBg: const Color(0xFFD1E4F5),
            ),
            _StatCardConfig(
              label: 'Bookmarks',
              count: data.bookmarks,
              icon: Icons.bookmark_border_rounded,
              accentColor: kSeqOutline,
              containerBg: kSeqSurfaceContainerHigh,
            ),
          ];

          return RefreshIndicator(
            color: kSeqPrimaryContainer,
            onRefresh: () async {
              ref.invalidate(platformOverviewDataProvider);
              await ref.read(platformOverviewDataProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildHeaderBar(context),
                const SizedBox(height: 24),
                _buildStatCardsGrid(context, cards: statCards, width: width),
                const SizedBox(height: 32),
                _buildBottomNote(context),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Header Bar -----------------------------------------------------------

  Widget _buildHeaderBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live data tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kSeqSurfaceContainerHighest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: kSeqPrimaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live data',
                style: seqLabelSm(
                  color: kSeqOnSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Title
        Text(
          'Platform Overview',
          style: seqHeadlineLg(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),

        // Subtitle: strictly live platform statistics
        Text(
          'Live platform statistics',
          style: seqBodyMd(color: kSeqOnSurfaceVariant),
        ),
      ],
    );
  }

  // --- Stat Cards Grid ------------------------------------------------------

  Widget _buildStatCardsGrid(
    BuildContext context, {
    required List<_StatCardConfig> cards,
    required double width,
  }) {
    int crossAxisCount;
    if (width >= 1100) {
      crossAxisCount = 4;
    } else if (width >= 720) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    if (crossAxisCount == 1) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildCardWidget(context, config: cards[i]),
          ],
        ],
      );
    }

    // Grid layout for tablet and desktop
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += crossAxisCount) {
      final chunk = cards.skip(i).take(crossAxisCount).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              for (int j = 0; j < chunk.length; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(child: _buildCardWidget(context, config: chunk[j])),
              ],
              // Empty spacers if chunk is smaller than crossAxisCount
              for (int k = 0; k < crossAxisCount - chunk.length; k++) ...[
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildCardWidget(BuildContext context, {required _StatCardConfig config}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  config.label.toUpperCase(),
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ).copyWith(letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: config.containerBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  config.icon,
                  size: 20,
                  color: config.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${config.count}',
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: kSeqOnSurface,
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Note ----------------------------------------------------------

  Widget _buildBottomNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: kSeqOutline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data reflects current platform state. Historical trends will appear as the platform grows.',
              style: seqBodySm(color: kSeqOnSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardConfig {
  const _StatCardConfig({
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.containerBg,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color containerBg;
}
