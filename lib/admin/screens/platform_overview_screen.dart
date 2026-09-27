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
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// 1. Domain Model: PlatformOverviewData
// =============================================================================

class PlatformOverviewData {
  const PlatformOverviewData({
    required this.registeredUsers,
    required this.activeScholarships,
    required this.totalScholarshipValue,
    required this.applications,
    required this.providerVerifications,
    required this.auditEvents,
    required this.loginAttempts,
    required this.bookmarks,
  });

  final int registeredUsers;
  final int activeScholarships;
  final double totalScholarshipValue;
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
      final res = await supabase.from(table).select('id');
      return (res as List).length;
    }
  }

  final results = await Future.wait<dynamic>([
    fetchCount('profiles'),
    supabase.from('scholarships').select('id, amount'),
    fetchCount('applications'),
    fetchCount('provider_verifications'),
    fetchCount('audit_logs'),
    fetchCount('login_attempts'),
    fetchCount('bookmarks'),
  ]);

  final scholarshipsList = results[1] as List;
  double sumValue = 0;
  for (final row in scholarshipsList) {
    final amt = (row['amount'] as num?)?.toDouble() ?? 0;
    sumValue += amt;
  }

  return PlatformOverviewData(
    registeredUsers: results[0] as int,
    activeScholarships: scholarshipsList.length,
    totalScholarshipValue: sumValue,
    applications: results[2] as int,
    providerVerifications: results[3] as int,
    auditEvents: results[4] as int,
    loginAttempts: results[5] as int,
    bookmarks: results[6] as int,
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

          return RefreshIndicator(
            color: kSeqPrimaryContainer,
            onRefresh: () async {
              ref.invalidate(platformOverviewDataProvider);
              await ref.read(platformOverviewDataProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                _buildHeaderBar(context),
                const SizedBox(height: 24),

                // 1. Top Hero Section (3 cards)
                _buildSectionHeader('CORE PLATFORM SCALE'),
                const SizedBox(height: 12),
                _buildHeroGrid(context, data: data, width: width),
                const SizedBox(height: 32),

                // 2. Secondary Section (2 cards)
                _buildSectionHeader('APPLICATION & INSTITUTION WORKFLOW'),
                const SizedBox(height: 12),
                _buildSecondaryGrid(context, data: data, width: width),
                const SizedBox(height: 32),

                // 3. System Activity Section (3 muted cards)
                _buildSectionHeader('SYSTEM INTEGRITY & EVENT TELEMETRY'),
                const SizedBox(height: 12),
                _buildSystemActivityGrid(context, data: data, width: width),
                const SizedBox(height: 32),

                // Bottom Note
                _buildBottomNote(context),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Section Header Helper ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: seqLabelSm(
        color: kSeqOutline,
        fontWeight: FontWeight.w700,
      ).copyWith(letterSpacing: 0.8),
    );
  }

  // --- Header Bar -----------------------------------------------------------

  Widget _buildHeaderBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live data badge
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
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: kSeqOnSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Text(
          'Live platform statistics',
          style: seqBodyMd(color: kSeqOnSurfaceVariant),
        ),
      ],
    );
  }

  // --- 1. Hero Grid (3 Large Cards) -----------------------------------------

  Widget _buildHeroGrid(
    BuildContext context, {
    required PlatformOverviewData data,
    required double width,
  }) {
    final heroCards = [
      _HeroCardItem(
        label: 'REGISTERED USERS',
        targetValue: data.registeredUsers,
        icon: Icons.people_alt_outlined,
        accentColor: kSeqPrimaryContainer,
        containerBg: kSeqPrimaryFixed.withValues(alpha: 0.4),
        subtitle: 'Verified students, providers & administrators',
        isCurrency: false,
      ),
      _HeroCardItem(
        label: 'ACTIVE SCHOLARSHIPS',
        targetValue: data.activeScholarships,
        icon: Icons.school_outlined,
        accentColor: kSeqSecondary,
        containerBg: kSeqSecondaryFixed.withValues(alpha: 0.4),
        subtitle: 'Open programs actively accepting applications',
        isCurrency: false,
      ),
      _HeroCardItem(
        label: 'TOTAL SCHOLARSHIP VALUE',
        targetValue: data.totalScholarshipValue.round(),
        icon: Icons.payments_outlined,
        accentColor: const Color(0xFF1B5E20),
        containerBg: const Color(0xFFD4EBD9),
        subtitle: 'Cumulative declared financial grant coverage',
        isCurrency: true,
      ),
    ];

    final isDesktop = width >= 960;

    if (!isDesktop) {
      return Column(
        children: [
          for (int i = 0; i < heroCards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            StaggeredListItem(
              index: i,
              child: _buildHeroCard(context, item: heroCards[i]),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < heroCards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(
            child: StaggeredListItem(
              index: i,
              child: _buildHeroCard(context, item: heroCards[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, {required _HeroCardItem item}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                  item.label,
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ).copyWith(letterSpacing: 0.6),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.containerBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: item.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          item.isCurrency
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₱',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kSeqOnSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: CountUpAnimation(
                        targetValue: item.targetValue,
                        duration: const Duration(milliseconds: 800),
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          color: kSeqOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                )
              : CountUpAnimation(
                  targetValue: item.targetValue,
                  duration: const Duration(milliseconds: 800),
                  style: GoogleFonts.inter(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: kSeqOnSurface,
                    letterSpacing: -0.5,
                  ),
                ),
          const SizedBox(height: 10),
          Text(
            item.subtitle,
            style: seqBodySm(color: kSeqOnSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 2. Secondary Grid (2 Medium Cards) -----------------------------------

  Widget _buildSecondaryGrid(
    BuildContext context, {
    required PlatformOverviewData data,
    required double width,
  }) {
    final secondaryCards = [
      _SecondaryCardItem(
        label: 'APPLICATIONS',
        count: data.applications,
        icon: Icons.assignment_outlined,
        accentColor: kSeqTertiaryContainer,
        containerBg: kSeqTertiaryFixed.withValues(alpha: 0.4),
        subtitle: 'Submitted for review across all grants',
      ),
      _SecondaryCardItem(
        label: 'PROVIDER VERIFICATIONS',
        count: data.providerVerifications,
        icon: Icons.verified_user_outlined,
        accentColor: const Color(0xFF2E6B4E),
        containerBg: const Color(0xFFD4EBD9),
        subtitle: 'Verified organizations funding education',
      ),
    ];

    final isDesktop = width >= 720;

    if (!isDesktop) {
      return Column(
        children: [
          for (int i = 0; i < secondaryCards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            StaggeredListItem(
              index: 3 + i,
              child: _buildSecondaryCard(context, item: secondaryCards[i]),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < secondaryCards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(
            child: StaggeredListItem(
              index: 3 + i,
              child: _buildSecondaryCard(context, item: secondaryCards[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecondaryCard(BuildContext context, {required _SecondaryCardItem item}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.4),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.containerBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              size: 24,
              color: item.accentColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ).copyWith(letterSpacing: 0.6),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                CountUpAnimation(
                  targetValue: item.count,
                  duration: const Duration(milliseconds: 800),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: kSeqOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: seqBodySm(color: kSeqOnSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. System Activity Grid (3 Muted Small Cards) ------------------------

  Widget _buildSystemActivityGrid(
    BuildContext context, {
    required PlatformOverviewData data,
    required double width,
  }) {
    final systemCards = [
      _SystemCardItem(
        label: 'AUDIT EVENTS',
        count: data.auditEvents,
        icon: Icons.history_rounded,
        accentColor: const Color(0xFF6B4C1B),
        containerBg: const Color(0xFFF7E6CC),
      ),
      _SystemCardItem(
        label: 'LOGIN ATTEMPTS',
        count: data.loginAttempts,
        icon: Icons.login_rounded,
        accentColor: const Color(0xFF1E5280),
        containerBg: const Color(0xFFD1E4F5),
      ),
      _SystemCardItem(
        label: 'ACTIVE BOOKMARKS',
        count: data.bookmarks,
        icon: Icons.bookmark_border_rounded,
        accentColor: kSeqOutline,
        containerBg: kSeqSurfaceContainerHigh,
      ),
    ];

    final isDesktop = width >= 720;

    if (!isDesktop) {
      return Column(
        children: [
          for (int i = 0; i < systemCards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            StaggeredListItem(
              index: 5 + i,
              child: _buildSystemCard(context, item: systemCards[i]),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < systemCards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: StaggeredListItem(
              index: 5 + i,
              child: _buildSystemCard(context, item: systemCards[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSystemCard(BuildContext context, {required _SystemCardItem item}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.containerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: 16,
                  color: item.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: seqLabelSm(
                  color: kSeqOutline,
                  fontWeight: FontWeight.w600,
                ).copyWith(letterSpacing: 0.5),
              ),
            ],
          ),
          CountUpAnimation(
            targetValue: item.count,
            duration: const Duration(milliseconds: 800),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
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

class _HeroCardItem {
  const _HeroCardItem({
    required this.label,
    required this.targetValue,
    required this.icon,
    required this.accentColor,
    required this.containerBg,
    required this.subtitle,
    required this.isCurrency,
  });

  final String label;
  final int targetValue;
  final IconData icon;
  final Color accentColor;
  final Color containerBg;
  final String subtitle;
  final bool isCurrency;
}

class _SecondaryCardItem {
  const _SecondaryCardItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.containerBg,
    required this.subtitle,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color containerBg;
  final String subtitle;
}

class _SystemCardItem {
  const _SystemCardItem({
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

