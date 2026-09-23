// lib/features/provider/presentation/org/org_analytics_tab.dart
//
// Institutional Analytics & Impact Dashboard based on Stitch mockup
// (scholaris_provider_console_analytics_impact_dashboard).
// Aggregates live data from provider applications and student profiles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../profile/models/student_profile.dart';
import '../../providers/provider_scholarships_provider.dart';
import 'org_provider_theme.dart';

class OrgAnalyticsTab extends ConsumerWidget {
  const OrgAnalyticsTab({super.key});

  String _formatCurrency(int amount) {
    return '₱${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAppsAsync = ref.watch(incomingApplicationsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Container(
      color: kOrgCanvas,
      child: incomingAppsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: kOrgPrimary),
        ),
        error: (err, _) => Center(
          child: Text('Error loading analytics: $err', style: orgBody(color: kOrgError)),
        ),
        data: (apps) {
          final profiles = ref.watch(providerApplicantProfilesProvider).valueOrNull ??
              <String, StudentProfile>{};

          final totalApplications = apps.length;
          final approvedApps = apps
              .where((a) =>
                  a.status == ApplicationStatus.approved ||
                  a.status == ApplicationStatus.awarded)
              .toList();
          final approvedCount = approvedApps.length;

          // Calculate Total Committed Funds (₱50,000 per approved award)
          final totalCommitted = approvedApps.length * 50000;

          // GWA Distribution
          int summaMagna = 0; // 1.00 - 1.45
          int deansList = 0;  // 1.46 - 1.75
          int satisfactory = 0; // 1.76 - 2.00
          int otherGwa = 0;

          // School Breakdown
          final Map<String, List<double>> schoolGwas = {};

          for (final a in apps) {
            final p = profiles[a.userId];
            if (p != null && p.gpa > 0) {
              final g = p.gpa;
              if (g <= 1.45) {
                summaMagna++;
              } else if (g <= 1.75) {
                deansList++;
              } else if (g <= 2.00) {
                satisfactory++;
              } else {
                otherGwa++;
              }

              final schoolName = p.school?.trim().isNotEmpty == true
                  ? p.school!.trim()
                  : 'Other Institutions';
              schoolGwas.putIfAbsent(schoolName, () => []).add(g);
            }
          }

          final totalGwaCount = summaMagna + deansList + satisfactory + otherGwa;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('CONSOLE', style: orgLabel(fontSize: 10, color: kOrgTextMuted)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: kOrgTextMuted),
                            const SizedBox(width: 4),
                            Text('ANALYTICS', style: orgLabel(fontSize: 10, color: kOrgPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Analytics & Impact Dashboard',
                            style: orgHeadline(fontSize: isDesktop ? 22 : 18)),
                        const SizedBox(height: 2),
                        Text(
                          'Executive cohort performance, fund utilization, and institutional distribution.',
                          style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kOrgSurfaceWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kOrgBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 16, color: kOrgPrimary),
                          const SizedBox(width: 6),
                          Text('AY 2024–2025 Semester 1',
                              style: orgLabel(fontSize: 11, color: kOrgTextPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 3 Top KPI Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = isDesktop
                        ? (constraints.maxWidth - 24) / 3
                        : constraints.maxWidth;

                    final cards = [
                      _buildKpiTile(
                        title: 'TOTAL COMMITTED ENDOWMENT',
                        value: _formatCurrency(totalCommitted),
                        subtitle: 'Across approved scholar grants',
                        badgeText: 'Active Releases',
                        badgePositive: true,
                        width: cardWidth,
                      ),
                      _buildKpiTile(
                        title: 'AWARDED SCHOLARS COHORT',
                        value: '$approvedCount',
                        subtitle: 'Students in good standing',
                        badgeText: 'Verified Enrolled',
                        badgePositive: true,
                        width: cardWidth,
                      ),
                      _buildKpiTile(
                        title: 'APPLICANT PIPELINE VOLUME',
                        value: '$totalApplications',
                        subtitle: 'Incoming application dossiers',
                        badgeText: 'AY 2024-2025',
                        badgePositive: false,
                        width: cardWidth,
                      ),
                    ];

                    return isDesktop
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: cards,
                          )
                        : Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 10),
                              cards[1],
                              const SizedBox(height: 10),
                              cards[2],
                            ],
                          );
                  },
                ),

                const SizedBox(height: 20),

                // Main Layout Grid (Academic Performance + School Breakdown)
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Panel: Academic Performance (GWA Distribution)
                          Expanded(
                            flex: 6,
                            child: _buildGwaDistributionCard(
                              summa: summaMagna,
                              deans: deansList,
                              satisfactory: satisfactory,
                              other: otherGwa,
                              total: totalGwaCount,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right Panel: University Partner Breakdown Table
                          Expanded(
                            flex: 6,
                            child: _buildSchoolBreakdownCard(schoolGwas),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildGwaDistributionCard(
                            summa: summaMagna,
                            deans: deansList,
                            satisfactory: satisfactory,
                            other: otherGwa,
                            total: totalGwaCount,
                          ),
                          const SizedBox(height: 16),
                          _buildSchoolBreakdownCard(schoolGwas),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiTile({
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required bool badgePositive,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrgBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: orgLabel(fontSize: 10, color: kOrgTextMuted)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgePositive ? kOrgPrimary : kOrgCivicNavy).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: orgLabel(
                    fontSize: 10,
                    color: badgePositive ? kOrgPrimary : kOrgCivicNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: orgHeadline(fontSize: 22, color: kOrgPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: orgBody(fontSize: 11, color: kOrgTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildGwaDistributionCard({
    required int summa,
    required int deans,
    required int satisfactory,
    required int other,
    required int total,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_rounded, size: 18, color: kOrgPrimary),
                  const SizedBox(width: 8),
                  Text('Academic GWA Retention', style: orgHeadline(fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kOrgCanvas,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Passing Benchmark: GWA ≤ 2.50',
                  style: orgLabel(fontSize: 10, color: kOrgTextMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4 GWA Bar Blocks
          Row(
            children: [
              Expanded(
                child: _buildGwaTierBlock(
                  title: 'Summa / Magna',
                  range: '1.00–1.45',
                  count: summa,
                  total: total,
                  color: kOrgPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGwaTierBlock(
                  title: "Dean's Lister",
                  range: '1.46–1.75',
                  count: deans,
                  total: total,
                  color: kOrgPrimary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGwaTierBlock(
                  title: 'Satisfactory',
                  range: '1.76–2.00',
                  count: satisfactory,
                  total: total,
                  color: kOrgAccentGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGwaTierBlock(
                  title: 'Needs Review',
                  range: '> 2.00',
                  count: other,
                  total: total,
                  color: kOrgTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Distribution automatically aggregated from verified registrar transcript records on student profiles.',
            style: orgBody(fontSize: 11, color: kOrgTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildGwaTierBlock({
    required String title,
    required String range,
    required int count,
    required int total,
    required Color color,
  }) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    final barHeight = total > 0 ? (count / total).clamp(0.15, 1.0) * 50 : 10.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kOrgCanvas,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: orgHeadline(fontSize: 11, color: color)),
          Text(range, style: orgLabel(fontSize: 9, color: kOrgTextMuted)),
          const SizedBox(height: 8),
          Container(
            height: 48,
            alignment: Alignment.bottomCenter,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$count', style: orgHeadline(fontSize: 14)),
              Text('$pct%', style: orgLabel(fontSize: 10, color: kOrgTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolBreakdownCard(Map<String, List<double>> schoolGwas) {
    final sortedSchools = schoolGwas.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_rounded, size: 18, color: kOrgPrimary),
                  const SizedBox(width: 8),
                  Text('University Partner Cohort', style: orgHeadline(fontSize: 14)),
                ],
              ),
              Text(
                '${sortedSchools.length} Institutional Centers',
                style: orgLabel(fontSize: 10, color: kOrgTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sortedSchools.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No school records logged yet.',
                    style: orgBody(fontSize: 12, color: kOrgTextMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedSchools.take(5).length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: kOrgBorder),
              itemBuilder: (context, index) {
                final entry = sortedSchools[index];
                final schoolName = entry.key;
                final scholarsCount = entry.value.length;
                final avgGwa = entry.value.isNotEmpty
                    ? (entry.value.reduce((a, b) => a + b) / scholarsCount)
                        .toStringAsFixed(2)
                    : '1.50';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: kOrgPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schoolName,
                          overflow: TextOverflow.ellipsis,
                          style: orgHeadline(fontSize: 12),
                        ),
                      ),
                      Text('$scholarsCount scholars',
                          style: orgLabel(fontSize: 11, color: kOrgTextSecondary)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kOrgCanvas,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Avg GWA $avgGwa',
                            style: orgLabel(fontSize: 10, color: kOrgPrimary)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
