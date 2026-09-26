// lib/admin/screens/reports_analytics_screen.dart
//
// Admin Console: Reports & Platform Analytics (Screen 6 Rebuild)
// Visual tokens: scholaris_sequoia/DESIGN.md
// Strictly real data: 100% wired to live Supabase queries across core tables.
// Zero fabricated metrics, zero fake compliance stamps, zero fake report sections.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_home_screen.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_trail_screen.dart';

// =============================================================================
// 1. Domain Model: ReportsAnalyticsData
// =============================================================================

class ReportsAnalyticsData {
  const ReportsAnalyticsData({
    required this.applicationStatusCounts,
    required this.profileRoleCounts,
    required this.totalScholarshipValue,
    required this.scholarshipCount,
    required this.recentAuditLogs,
  });

  final Map<String, int> applicationStatusCounts;
  final Map<String, int> profileRoleCounts;
  final double totalScholarshipValue;
  final int scholarshipCount;
  final List<AuditLogEntry> recentAuditLogs;
}

// =============================================================================
// 2. Data Provider
// =============================================================================

final reportsAnalyticsDataProvider =
    FutureProvider<ReportsAnalyticsData>((ref) async {
  final supabase = Supabase.instance.client;

  // Run all 4 queries concurrently in parallel
  final results = await Future.wait([
    supabase.from('applications').select('status'),
    supabase.from('profiles').select('role'),
    supabase.from('scholarships').select('amount'),
    supabase
        .from('audit_logs')
        .select('*')
        .order('created_at', ascending: false)
        .limit(5),
  ]);

  final appsResponse = results[0] as List;
  final profilesResponse = results[1] as List;
  final scholarshipsResponse = results[2] as List;
  final auditResponse = results[3] as List;

  // 1. Applications by status
  final appStatusMap = <String, int>{
    'draft': 0,
    'submitted': 0,
    'under_review': 0,
    'shortlisted': 0,
    'approved': 0,
    'awarded': 0,
    'rejected': 0,
    'withdrawn': 0,
  };
  for (final row in appsResponse) {
    final s = row['status'] as String? ?? 'unknown';
    appStatusMap[s] = (appStatusMap[s] ?? 0) + 1;
  }

  // 2. Profiles by role
  final profileRoleMap = <String, int>{};
  for (final row in profilesResponse) {
    final r = row['role'] as String? ?? 'unknown';
    profileRoleMap[r] = (profileRoleMap[r] ?? 0) + 1;
  }

  // 3. Scholarship coverage sum
  double sumValue = 0;
  for (final row in scholarshipsResponse) {
    final amt = (row['amount'] as num?)?.toDouble() ?? 0;
    sumValue += amt;
  }

  // 4. Recent audit logs (last 5)
  final auditList = List<Map<String, dynamic>>.from(auditResponse)
      .map(AuditLogEntry.fromMap)
      .toList();

  return ReportsAnalyticsData(
    applicationStatusCounts: appStatusMap,
    profileRoleCounts: profileRoleMap,
    totalScholarshipValue: sumValue,
    scholarshipCount: scholarshipsResponse.length,
    recentAuditLogs: auditList,
  );
});

// =============================================================================
// 3. UI Component: ReportsAnalyticsScreen
// =============================================================================

class ReportsAnalyticsScreen extends ConsumerWidget {
  const ReportsAnalyticsScreen({super.key});

  String _formatCurrency(double amount) {
    final rounded = amount.toInt();
    final chars = rounded.toString().split('');
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }
    return '₱$buffer';
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final local = dt.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$minute $ampm';
  }

  String _truncateId(String? id) {
    if (id == null || id.isEmpty) return '—';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsAnalyticsDataProvider);

    return Scaffold(
      backgroundColor: kSeqSurface,
      body: reportsAsync.when(
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
                  'Failed to load analytics summaries',
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
                  onPressed: () => ref.invalidate(reportsAnalyticsDataProvider),
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
          final isDesktop = width >= 900;

          return RefreshIndicator(
            color: kSeqPrimaryContainer,
            onRefresh: () async {
              ref.invalidate(reportsAnalyticsDataProvider);
              await ref.read(reportsAnalyticsDataProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildHeaderBar(context),
                const SizedBox(height: 24),

                // Section 3: Scholarship Coverage Card (Top Hero)
                _buildScholarshipCoverageCard(context, data: data),
                const SizedBox(height: 20),

                // Side-by-side or stacked: Applications by Status & Profiles by Role
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildApplicationsStatusSection(context,
                            counts: data.applicationStatusCounts),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildProfilesRoleSection(context,
                            counts: data.profileRoleCounts),
                      ),
                    ],
                  )
                else ...[
                  _buildApplicationsStatusSection(context,
                      counts: data.applicationStatusCounts),
                  const SizedBox(height: 16),
                  _buildProfilesRoleSection(context,
                      counts: data.profileRoleCounts),
                ],
                const SizedBox(height: 20),

                // Section 4: Recent Activity (Last 5 Audit Events)
                _buildRecentActivitySection(
                  context,
                  ref: ref,
                  logs: data.recentAuditLogs,
                ),
                const SizedBox(height: 24),
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
          'Reports & Analytics',
          style: seqHeadlineLg(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),

        // Subtitle: strictly live data summaries
        Text(
          'Live data summaries',
          style: seqBodyMd(color: kSeqOnSurfaceVariant),
        ),
      ],
    );
  }

  // --- Section 3: Scholarship Coverage --------------------------------------

  Widget _buildScholarshipCoverageCard(
    BuildContext context, {
    required ReportsAnalyticsData data,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Text(
                'SCHOLARSHIP COVERAGE',
                style: seqLabelSm(
                  color: kSeqOutline,
                  fontWeight: FontWeight.w700,
                ).copyWith(letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSeqPrimaryFixed.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${data.scholarshipCount} Active Grants',
                  style: seqLabelSm(
                    color: kSeqPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(data.totalScholarshipValue),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: kSeqPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total Declared Scholarship Value',
            style: seqBodyMd(
              color: kSeqOnSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 1: Applications by Status ------------------------------------

  Widget _buildApplicationsStatusSection(
    BuildContext context, {
    required Map<String, int> counts,
  }) {
    final total = counts.values.fold<int>(0, (sum, val) => sum + val);

    final statusList = [
      {'key': 'submitted', 'label': 'Submitted', 'color': kSeqSecondary},
      {'key': 'approved', 'label': 'Approved', 'color': kSeqPrimaryContainer},
      {'key': 'withdrawn', 'label': 'Withdrawn', 'color': kSeqOutline},
      {'key': 'draft', 'label': 'Draft', 'color': kSeqOnSurfaceVariant},
      {'key': 'under_review', 'label': 'Under Review', 'color': kSeqTertiaryContainer},
      {'key': 'shortlisted', 'label': 'Shortlisted', 'color': const Color(0xFF5D4037)},
      {'key': 'awarded', 'label': 'Awarded', 'color': const Color(0xFF1B5E20)},
      {'key': 'rejected', 'label': 'Rejected', 'color': kSeqError},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'APPLICATIONS BY STATUS',
                style: seqLabelSm(
                  color: kSeqOutline,
                  fontWeight: FontWeight.w700,
                ).copyWith(letterSpacing: 0.5),
              ),
              Text(
                '$total total',
                style: seqLabelSm(color: kSeqOutline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < statusList.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: kSeqSurfaceContainerHigh),
            _buildBreakdownRow(
              label: statusList[i]['label'] as String,
              count: counts[statusList[i]['key']] ?? 0,
              indicatorColor: statusList[i]['color'] as Color,
            ),
          ],
        ],
      ),
    );
  }

  // --- Section 2: Profiles by Role ------------------------------------------

  Widget _buildProfilesRoleSection(
    BuildContext context, {
    required Map<String, int> counts,
  }) {
    final total = counts.values.fold<int>(0, (sum, val) => sum + val);

    final roles = counts.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROFILES BY ROLE',
                style: seqLabelSm(
                  color: kSeqOutline,
                  fontWeight: FontWeight.w700,
                ).copyWith(letterSpacing: 0.5),
              ),
              Text(
                '$total registered',
                style: seqLabelSm(color: kSeqOutline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < roles.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: kSeqSurfaceContainerHigh),
            _buildBreakdownRow(
              label: roles[i].toUpperCase(),
              count: counts[roles[i]] ?? 0,
              indicatorColor: _roleColor(roles[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required int count,
    required Color indicatorColor,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: seqBodyMd(
              color: kSeqOnSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kSeqOnSurface,
          ),
        ),
      ],
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return kSeqPrimaryContainer;
      case 'student':
        return kSeqSecondary;
      case 'provider':
        return kSeqTertiaryContainer;
      default:
        return kSeqOutline;
    }
  }

  // --- Section 4: Recent Activity -------------------------------------------

  Widget _buildRecentActivitySection(
    BuildContext context, {
    required WidgetRef ref,
    required List<AuditLogEntry> logs,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ACTIVITY',
                style: seqLabelSm(
                  color: kSeqOutline,
                  fontWeight: FontWeight.w700,
                ).copyWith(letterSpacing: 0.5),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(adminTabIndexProvider.notifier).selectTab(6);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View full audit trail'),
                style: TextButton.styleFrom(
                  foregroundColor: kSeqPrimaryContainer,
                  textStyle: seqLabelSm(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < logs.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildRecentLogRow(context, entry: logs[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentLogRow(BuildContext context, {required AuditLogEntry entry}) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.action,
                        style: seqBodyMd(
                          fontWeight: FontWeight.w700,
                          color: kSeqOnSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${entry.targetType} · ${_truncateId(entry.targetId)}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          color: kSeqOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.actorEmail ?? 'System',
                    style: seqBodySm(color: kSeqOnSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDateTime(entry.createdAt),
                  style: seqLabelSm(color: kSeqOutline),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.action,
                  style: seqBodyMd(
                    fontWeight: FontWeight.w700,
                    color: kSeqOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.targetType} · ${_truncateId(entry.targetId)}',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: kSeqOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.actorEmail ?? 'System',
                        style: seqBodySm(color: kSeqOnSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(entry.createdAt),
                      style: seqLabelSm(color: kSeqOutline),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
