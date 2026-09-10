import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final applicationsAsync = ref.watch(incomingApplicationsProvider);

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(scholarshipsProvider);
          ref.invalidate(incomingApplicationsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
          Text(
            'System Overview',
            style: poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Live monitoring across scholarships, applications, and system roles.',
            style: openSans(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
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
              final activeScholarships = scholarships.where((s) => s.isActive).length;

              return applicationsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: LoadingView(),
                  ),
                ),
                error: (_, _) => _buildStatsGrid(
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

                  return _buildStatsGrid(
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

  Widget _buildStatsGrid({
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            final cardWidth = isWide
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    title: 'Active Scholarships',
                    value: '$activeScholarships',
                    icon: Icons.school_rounded,
                    color: kPrimary,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    title: 'Total Applications',
                    value: '$totalApplications',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    title: 'Approved Grants',
                    value: '$approvedCount',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    title: 'Acceptance Rate',
                    value: '$acceptanceRate%',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Application Pipeline',
          style: poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusCard),
            boxShadow: const [
              BoxShadow(
                color: kCardShadow,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _PipelineRow(
                label: 'Submitted',
                count: submittedCount,
                color: const Color(0xFF0284C7),
                icon: Icons.send_rounded,
              ),
              const Divider(height: 20),
              _PipelineRow(
                label: 'Under Review',
                count: underReviewCount,
                color: const Color(0xFFD97706),
                icon: Icons.search_rounded,
              ),
              const Divider(height: 20),
              _PipelineRow(
                label: 'Approved',
                count: approvedCount,
                color: const Color(0xFF16A34A),
                icon: Icons.check_circle_rounded,
              ),
              const Divider(height: 20),
              _PipelineRow(
                label: 'Rejected',
                count: rejectedCount,
                color: const Color(0xFFDC2626),
                icon: Icons.cancel_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Role-Based Security & Supabase RLS Active',
                  style: openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
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
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: openSans(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
