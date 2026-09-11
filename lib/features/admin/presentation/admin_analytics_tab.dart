import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'admin_analytics_provider.dart';
import 'admin_theme.dart';

class AdminAnalyticsTab extends ConsumerWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsDataProvider);

    return ResponsiveContainer(
      child: RefreshIndicator(
        color: kAdminBridgeGreen,
        onRefresh: () async {
          ref.invalidate(adminAnalyticsDataProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              'Platform Analytics',
              style: adminHeaderStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kAdminNavyTrust,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Empirical distribution across schools, pipeline stages, and regional applicant coverage.',
              style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
            ),
            const SizedBox(height: 18),
            analyticsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: LoadingView(),
                ),
              ),
              error: (_, _) => const ErrorView(
                message: 'Failed to load platform analytics.',
              ),
              data: (data) => _buildAnalyticsContent(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(AdminAnalyticsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Stat Strip
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: kAdminCardRadius,
            border: Border.all(color: kAdminHairline, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _AnalyticsStatCell(
                    label: 'Total applications',
                    value: '${data.totalApplications}',
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: kAdminHairline),
                Expanded(
                  child: _AnalyticsStatCell(
                    label: 'Participating schools',
                    value: '${data.schoolCounts.length}',
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: kAdminHairline),
                Expanded(
                  child: _AnalyticsStatCell(
                    label: 'Active scholarships',
                    value: '${data.activeScholarships}',
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: kAdminHairline),
                Expanded(
                  child: _AnalyticsStatCell(
                    label: 'Platform acceptance',
                    value: '${data.acceptanceRate.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Institution Breakdown Section
        Text(
          'Institution breakdown',
          style: adminHeaderStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
        ),
        const SizedBox(height: 4),
        Text(
          'Applicant volume grouped by declared educational institution.',
          style: adminLabelStyle(fontSize: 12, color: kAdminTextSecondary),
        ),
        const SizedBox(height: 10),
        _InstitutionTable(schoolCounts: data.schoolCounts, totalApplicants: data.totalApplicants),
        const SizedBox(height: 24),
        // Stage Pipeline Breakdown
        Text(
          'Pipeline stage distribution',
          style: adminHeaderStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
        ),
        const SizedBox(height: 10),
        _StatusDistributionTable(
          statusCounts: data.statusCounts,
          totalApplications: data.totalApplications,
        ),
        const SizedBox(height: 24),
        // Regional Distribution Section
        Text(
          'Regional coverage',
          style: adminHeaderStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
        ),
        const SizedBox(height: 10),
        _RegionalTable(regionCounts: data.regionCounts, totalApplicants: data.totalApplicants),
      ],
    );
  }
}

class _AnalyticsStatCell extends StatelessWidget {
  const _AnalyticsStatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kAdminTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: adminDataMono(fontSize: 20, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
          ),
        ],
      ),
    );
  }
}

class _InstitutionTable extends StatelessWidget {
  const _InstitutionTable({required this.schoolCounts, required this.totalApplicants});

  final Map<String, int> schoolCounts;
  final int totalApplicants;

  @override
  Widget build(BuildContext context) {
    if (schoolCounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: kAdminTableRadius,
          border: Border.all(color: kAdminHairline, width: 1),
        ),
        child: Text(
          'No institution data recorded yet.',
          style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
        ),
      );
    }

    final sorted = schoolCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: kAdminTableRadius,
        border: Border.all(color: kAdminHairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text(
                    'Institution / university',
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Applicants',
                    textAlign: TextAlign.right,
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Share',
                    textAlign: TextAlign.right,
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kAdminHairline),
          for (var i = 0; i < sorted.length && i < 10; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Text(
                      sorted[i].key,
                      style: adminBodyStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kAdminNavyTrust),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${sorted[i].value}',
                      textAlign: TextAlign.right,
                      style: adminDataMono(fontSize: 13, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      totalApplicants > 0
                          ? '${((sorted[i].value / totalApplicants) * 100).toStringAsFixed(1)}%'
                          : '0.0%',
                      textAlign: TextAlign.right,
                      style: adminDataMono(fontSize: 12, color: kAdminTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
            if (i < sorted.length - 1 && i < 9)
              const Divider(height: 1, color: kAdminHairline),
          ],
        ],
      ),
    );
  }
}

class _StatusDistributionTable extends StatelessWidget {
  const _StatusDistributionTable({
    required this.statusCounts,
    required this.totalApplications,
  });

  final Map<ApplicationStatus, int> statusCounts;
  final int totalApplications;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: kAdminTableRadius,
        border: Border.all(color: kAdminHairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Stage / status',
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Count',
                    textAlign: TextAlign.right,
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Share',
                    textAlign: TextAlign.right,
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kAdminHairline),
          _statusRow('Submitted', statusCounts[ApplicationStatus.submitted] ?? 0, kAdminGoldenOpportunity),
          const Divider(height: 1, color: kAdminHairline),
          _statusRow('Under review', statusCounts[ApplicationStatus.underReview] ?? 0, kAdminGoldenOpportunity),
          const Divider(height: 1, color: kAdminHairline),
          _statusRow('Approved', statusCounts[ApplicationStatus.approved] ?? 0, kAdminBridgeGreen),
          const Divider(height: 1, color: kAdminHairline),
          _statusRow('Awarded', statusCounts[ApplicationStatus.awarded] ?? 0, kAdminBridgeGreen),
          const Divider(height: 1, color: kAdminHairline),
          _statusRow('Rejected', statusCounts[ApplicationStatus.rejected] ?? 0, kAdminCoralConnect),
        ],
      ),
    );
  }

  Widget _statusRow(String label, int count, Color indicator) {
    final pct = totalApplications > 0
        ? '${((count / totalApplications) * 100).toStringAsFixed(1)}%'
        : '0.0%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: indicator, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: adminBodyStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kAdminNavyTrust)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: adminDataMono(fontSize: 13, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              pct,
              textAlign: TextAlign.right,
              style: adminDataMono(fontSize: 12, color: kAdminTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionalTable extends StatelessWidget {
  const _RegionalTable({required this.regionCounts, required this.totalApplicants});

  final Map<String, int> regionCounts;
  final int totalApplicants;

  @override
  Widget build(BuildContext context) {
    if (regionCounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: kAdminTableRadius,
          border: Border.all(color: kAdminHairline, width: 1),
        ),
        child: Text(
          'No regional applicant data recorded yet.',
          style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
        ),
      );
    }

    final sorted = regionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: kAdminTableRadius,
        border: Border.all(color: kAdminHairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text(
                    'Administrative region',
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Applicants',
                    textAlign: TextAlign.right,
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Share',
                    textAlign: TextAlign.right,
                    style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kAdminHairline),
          for (var i = 0; i < sorted.length && i < 8; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Text(
                      sorted[i].key,
                      style: adminBodyStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kAdminNavyTrust),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${sorted[i].value}',
                      textAlign: TextAlign.right,
                      style: adminDataMono(fontSize: 13, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      totalApplicants > 0
                          ? '${((sorted[i].value / totalApplicants) * 100).toStringAsFixed(1)}%'
                          : '0.0%',
                      textAlign: TextAlign.right,
                      style: adminDataMono(fontSize: 12, color: kAdminTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
            if (i < sorted.length - 1 && i < 7)
              const Divider(height: 1, color: kAdminHairline),
          ],
        ],
      ),
    );
  }
}
