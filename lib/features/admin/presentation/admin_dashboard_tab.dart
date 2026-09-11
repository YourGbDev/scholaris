import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'admin_theme.dart';

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final applicationsAsync = ref.watch(incomingApplicationsProvider);

    return ResponsiveContainer(
      child: RefreshIndicator(
        color: kAdminBridgeGreen,
        onRefresh: () async {
          ref.invalidate(scholarshipsProvider);
          ref.invalidate(incomingApplicationsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              'System Overview',
              style: adminHeaderStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kAdminNavyTrust,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live monitoring across scholarships, applications, and system roles.',
              style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
            ),
            const SizedBox(height: 18),
            scholarshipsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: LoadingView(),
                ),
              ),
              error: (_, _) => const ErrorView(
                message: 'Failed to load scholarship statistics.',
              ),
              data: (scholarships) {
                final activeScholarships =
                    scholarships.where((s) => s.isActive).length;

                return applicationsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: LoadingView(),
                    ),
                  ),
                  error: (_, _) => _buildDashboardContent(
                    activeScholarships: activeScholarships,
                    totalApplications: 0,
                    approvedCount: 0,
                    underReviewCount: 0,
                    submittedCount: 0,
                    rejectedCount: 0,
                  ),
                  data: (applications) {
                    final totalApps = applications.length;
                    final approved = applications
                        .where((a) => a.status == ApplicationStatus.approved)
                        .length;
                    final underReview = applications
                        .where((a) => a.status == ApplicationStatus.underReview)
                        .length;
                    final submitted = applications
                        .where((a) => a.status == ApplicationStatus.submitted)
                        .length;
                    final rejected = applications
                        .where((a) => a.status == ApplicationStatus.rejected)
                        .length;

                    return _buildDashboardContent(
                      activeScholarships: activeScholarships,
                      totalApplications: totalApps,
                      approvedCount: approved,
                      underReviewCount: underReview,
                      submittedCount: submitted,
                      rejectedCount: rejected,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent({
    required int activeScholarships,
    required int totalApplications,
    required int approvedCount,
    required int underReviewCount,
    required int submittedCount,
    required int rejectedCount,
  }) {
    final acceptanceRate = totalApplications > 0
        ? ((approvedCount / totalApplications) * 100).toStringAsFixed(1)
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Stat Strip
        _CompactStatStrip(
          activeScholarships: activeScholarships,
          totalApplications: totalApplications,
          approvedCount: approvedCount,
          acceptanceRate: '$acceptanceRate%',
        ),
        const SizedBox(height: 24),
        // Pipeline Section Header
        Text(
          'Application Pipeline',
          style: adminHeaderStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kAdminNavyTrust,
          ),
        ),
        const SizedBox(height: 10),
        // Dense Pipeline Table
        _DensePipelineTable(
          totalApplications: totalApplications,
          submittedCount: submittedCount,
          underReviewCount: underReviewCount,
          approvedCount: approvedCount,
          rejectedCount: rejectedCount,
        ),
        const SizedBox(height: 20),
        // System Ops / Security Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: kAdminCardRadius,
            border: Border.all(color: kAdminHairline, width: 1),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: kAdminBridgeGreen,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Access control and row-level security active',
                  style: adminBodyStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kAdminNavyTrust,
                  ),
                ),
              ),
              Text(
                'Active policies enforced',
                style: adminLabelStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kAdminBridgeGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactStatStrip extends StatelessWidget {
  const _CompactStatStrip({
    required this.activeScholarships,
    required this.totalApplications,
    required this.approvedCount,
    required this.acceptanceRate,
  });

  final int activeScholarships;
  final int totalApplications;
  final int approvedCount;
  final String acceptanceRate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 540;

        if (isNarrow) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: kAdminCardRadius,
              border: Border.all(color: kAdminHairline, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCell(
                        label: 'Active Scholarships',
                        value: '$activeScholarships',
                      ),
                    ),
                    Container(width: 1, height: 50, color: kAdminHairline),
                    Expanded(
                      child: _StatCell(
                        label: 'Total Applications',
                        value: '$totalApplications',
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1, color: kAdminHairline),
                Row(
                  children: [
                    Expanded(
                      child: _StatCell(
                        label: 'Approved Grants',
                        value: '$approvedCount',
                      ),
                    ),
                    Container(width: 1, height: 50, color: kAdminHairline),
                    Expanded(
                      child: _StatCell(
                        label: 'Acceptance Rate',
                        value: acceptanceRate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: kAdminCardRadius,
            border: Border.all(color: kAdminHairline, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'Active Scholarships',
                    value: '$activeScholarships',
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: kAdminHairline),
                Expanded(
                  child: _StatCell(
                    label: 'Total Applications',
                    value: '$totalApplications',
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: kAdminHairline),
                Expanded(
                  child: _StatCell(
                    label: 'Approved Grants',
                    value: '$approvedCount',
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: kAdminHairline),
                Expanded(
                  child: _StatCell(
                    label: 'Acceptance Rate',
                    value: acceptanceRate,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
  });

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
            style: adminLabelStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kAdminTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: adminDataMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kAdminNavyTrust,
            ),
          ),
        ],
      ),
    );
  }
}

class _DensePipelineTable extends StatelessWidget {
  const _DensePipelineTable({
    required this.totalApplications,
    required this.submittedCount,
    required this.underReviewCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  final int totalApplications;
  final int submittedCount;
  final int underReviewCount;
  final int approvedCount;
  final int rejectedCount;

  String _pct(int count) {
    if (totalApplications <= 0) return '0.0%';
    return '${((count / totalApplications) * 100).toStringAsFixed(1)}%';
  }

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
          // Table Header
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Stage / status',
                    style: adminLabelStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kAdminNavyTrust,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Count',
                    textAlign: TextAlign.right,
                    style: adminLabelStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kAdminNavyTrust,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Share',
                    textAlign: TextAlign.right,
                    style: adminLabelStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kAdminNavyTrust,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Queue state',
                    style: adminLabelStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kAdminNavyTrust,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kAdminHairline),
          _PipelineTableRow(
            label: 'Submitted',
            count: submittedCount,
            share: _pct(submittedCount),
            stateLabel: 'Pending intake',
            indicatorColor: kAdminGoldenOpportunity,
          ),
          const Divider(height: 1, color: kAdminHairline),
          _PipelineTableRow(
            label: 'Under review',
            count: underReviewCount,
            share: _pct(underReviewCount),
            stateLabel: 'Awaiting decision',
            indicatorColor: kAdminGoldenOpportunity,
          ),
          const Divider(height: 1, color: kAdminHairline),
          _PipelineTableRow(
            label: 'Approved',
            count: approvedCount,
            share: _pct(approvedCount),
            stateLabel: 'Granted',
            indicatorColor: kAdminBridgeGreen,
          ),
          const Divider(height: 1, color: kAdminHairline),
          _PipelineTableRow(
            label: 'Rejected',
            count: rejectedCount,
            share: _pct(rejectedCount),
            stateLabel: 'Closed',
            indicatorColor: kAdminCoralConnect,
          ),
        ],
      ),
    );
  }
}

class _PipelineTableRow extends StatelessWidget {
  const _PipelineTableRow({
    required this.label,
    required this.count,
    required this.share,
    required this.stateLabel,
    required this.indicatorColor,
  });

  final String label;
  final int count;
  final String share;
  final String stateLabel;
  final Color indicatorColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: adminBodyStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kAdminNavyTrust,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: adminDataMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kAdminNavyTrust,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              share,
              textAlign: TextAlign.right,
              style: adminDataMono(
                fontSize: 12,
                color: kAdminTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              stateLabel,
              style: adminLabelStyle(
                fontSize: 12,
                color: kAdminTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
