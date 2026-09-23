// lib/features/provider/presentation/org/org_incoming_applications_tab.dart
//
// Institutional Incoming Applications Tab based on Stitch mockup
// (scholaris_provider_console_applications_marketing_view).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../profile/models/student_profile.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../../scholarships/providers/scholarships_provider.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../widgets/applicant_review_drawer.dart';
import 'org_provider_theme.dart';

class OrgIncomingApplicationsTab extends ConsumerStatefulWidget {
  const OrgIncomingApplicationsTab({super.key});

  @override
  ConsumerState<OrgIncomingApplicationsTab> createState() =>
      _OrgIncomingApplicationsTabState();
}

class _OrgIncomingApplicationsTabState
    extends ConsumerState<OrgIncomingApplicationsTab> {
  ApplicationStatus? _statusFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final incomingAppsAsync = ref.watch(incomingApplicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Container(
      color: kOrgCanvas,
      child: incomingAppsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: kOrgPrimary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 40, color: kOrgError),
                const SizedBox(height: 12),
                Text('Error loading incoming applications',
                    style: orgHeadline(fontSize: 16)),
                const SizedBox(height: 6),
                Text('$err',
                    style: orgBody(fontSize: 12, color: kOrgTextSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kOrgPrimary),
                  onPressed: () =>
                      ref.refresh(incomingApplicationsProvider.future),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (apps) {
          final profiles = ref.watch(providerApplicantProfilesProvider).valueOrNull ??
              <String, StudentProfile>{};
          final scholarshipsMap = {
            for (final s in scholarshipsAsync.valueOrNull ?? []) s.id: s
          };

          // Filter by status and search
          final filteredApps = apps.where((app) {
            if (_statusFilter != null && app.status != _statusFilter) {
              return false;
            }
            if (_searchQuery.isNotEmpty) {
              final profile = profiles[app.userId];
              final name = profile?.fullName.toLowerCase() ?? '';
              final school = profile?.school?.toLowerCase() ?? '';
              final course = profile?.course.toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              return name.contains(query) ||
                  school.contains(query) ||
                  course.contains(query);
            }
            return true;
          }).toList();

          // Metrics calculation
          final totalCount = apps.length;
          final awaitingCount = apps
              .where((a) =>
                  a.status == ApplicationStatus.submitted ||
                  a.status == ApplicationStatus.underReview)
              .length;
          final approvedCount = apps
              .where((a) =>
                  a.status == ApplicationStatus.approved ||
                  a.status == ApplicationStatus.awarded)
              .length;

          return RefreshIndicator(
            color: kOrgPrimary,
            onRefresh: () async {
              ref.invalidate(incomingApplicationsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text('CONSOLE',
                                    style: orgLabel(
                                        fontSize: 10, color: kOrgTextMuted)),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 14, color: kOrgTextMuted),
                                Text('APPLICATIONS',
                                    style: orgLabel(
                                        fontSize: 10, color: kOrgPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Incoming Applications',
                                style: orgHeadline(fontSize: isDesktop ? 22 : 18)),
                            const SizedBox(height: 2),
                            Text(
                              'Review, verify, and advance student cohorts across institutional scholarship pipelines.',
                              style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kOrgBorderDark),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Exporting CSV applications ledger...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_rounded,
                              size: 16, color: kOrgPrimary),
                          label: Text('Export CSV',
                              style: orgLabel(color: kOrgTextPrimary)),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3 Highlight KPI Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useThreeCols = constraints.maxWidth >= 720;
                      final cardWidth = useThreeCols
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth;

                      final cards = [
                        _buildKpiCard(
                          title: 'TOTAL SUBMISSIONS',
                          value: '$totalCount',
                          trend: 'All pipelines',
                          trendPositive: true,
                          subtitle: 'Live applicant pool',
                          icon: Icons.folder_shared_rounded,
                          accentColor: kOrgPrimary,
                          width: cardWidth,
                        ),
                        _buildKpiCard(
                          title: 'AWAITING REVIEW',
                          value: '$awaitingCount',
                          trend: awaitingCount > 0 ? 'Needs Action' : 'All Clear',
                          trendPositive: awaitingCount == 0,
                          subtitle: 'Pending verification',
                          icon: Icons.pending_actions_rounded,
                          accentColor: kOrgAccentGold,
                          width: cardWidth,
                        ),
                        _buildKpiCard(
                          title: 'APPROVED CANDIDATES',
                          value: '$approvedCount',
                          trend: 'Active cohort',
                          trendPositive: true,
                          subtitle: 'Awarded grants',
                          icon: Icons.task_alt_rounded,
                          accentColor: kOrgPrimary,
                          width: cardWidth,
                        ),
                      ];

                      if (useThreeCols) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: cards,
                        );
                      } else {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 10),
                            cards[1],
                            const SizedBox(height: 10),
                            cards[2],
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Filter Strip & Search Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kOrgSurfaceWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kOrgBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Search box
                            Expanded(
                              child: TextField(
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val.trim()),
                                style: orgBody(fontSize: 13),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText:
                                      'Search applicant name, school, course...',
                                  hintStyle: orgBody(
                                      fontSize: 12, color: kOrgTextMuted),
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      size: 18, color: kOrgTextMuted),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 12),
                                  filled: true,
                                  fillColor: kOrgCanvas,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kOrgBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kOrgBorder),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: kOrgCanvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kOrgBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 14, color: kOrgPrimary),
                                  const SizedBox(width: 6),
                                  Text('AY 2024–2025',
                                      style: orgLabel(
                                          fontSize: 11, color: kOrgTextPrimary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusFilterChip(
                                label: 'All',
                                count: totalCount,
                                isSelected: _statusFilter == null,
                                onTap: () => setState(() => _statusFilter = null),
                              ),
                              const SizedBox(width: 6),
                              _buildStatusFilterChip(
                                label: 'Submitted',
                                count: apps
                                    .where((a) =>
                                        a.status == ApplicationStatus.submitted)
                                    .length,
                                isSelected:
                                    _statusFilter == ApplicationStatus.submitted,
                                onTap: () => setState(() => _statusFilter =
                                    ApplicationStatus.submitted),
                              ),
                              const SizedBox(width: 6),
                              _buildStatusFilterChip(
                                label: 'Under Review',
                                count: apps
                                    .where((a) =>
                                        a.status ==
                                        ApplicationStatus.underReview)
                                    .length,
                                isSelected: _statusFilter ==
                                    ApplicationStatus.underReview,
                                onTap: () => setState(() => _statusFilter =
                                    ApplicationStatus.underReview),
                              ),
                              const SizedBox(width: 6),
                              _buildStatusFilterChip(
                                label: 'Approved',
                                count: apps
                                    .where((a) =>
                                        a.status == ApplicationStatus.approved ||
                                        a.status == ApplicationStatus.awarded)
                                    .length,
                                isSelected:
                                    _statusFilter == ApplicationStatus.approved,
                                onTap: () => setState(() => _statusFilter =
                                    ApplicationStatus.approved),
                              ),
                              const SizedBox(width: 6),
                              _buildStatusFilterChip(
                                label: 'Rejected',
                                count: apps
                                    .where((a) =>
                                        a.status == ApplicationStatus.rejected)
                                    .length,
                                isSelected:
                                    _statusFilter == ApplicationStatus.rejected,
                                onTap: () => setState(() => _statusFilter =
                                    ApplicationStatus.rejected),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Column Headers (Desktop Only)
                  if (isDesktop && filteredApps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text('APPLICANT & ACADEMIC BACKGROUND',
                                style: orgLabel(
                                    fontSize: 10, color: kOrgTextMuted)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('TARGET SCHOLARSHIP GRANT',
                                style: orgLabel(
                                    fontSize: 10, color: kOrgTextMuted)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('STATUS',
                                style: orgLabel(
                                    fontSize: 10, color: kOrgTextMuted)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('ACTION',
                                  style: orgLabel(
                                      fontSize: 10, color: kOrgTextMuted)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Applications List / Empty State
                  if (filteredApps.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: kOrgSurfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kOrgBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 48,
                              color: kOrgTextMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('No applications found',
                              style: orgHeadline(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            _statusFilter != null
                                ? 'No applications match the current filter criteria.'
                                : 'Incoming applications to your published scholarships will appear here.',
                            style: orgBody(
                                fontSize: 13, color: kOrgTextSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredApps.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final app = filteredApps[index];
                        final profile = profiles[app.userId];
                        final scholarship = scholarshipsMap[app.scholarshipId];

                        return _buildApplicantCard(
                          app: app,
                          profile: profile,
                          scholarship: scholarship,
                          isDesktop: isDesktop,
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String trend,
    required bool trendPositive,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: orgLabel(fontSize: 10, color: kOrgTextMuted)),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(value, style: orgHeadline(fontSize: 22)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (trendPositive ? kOrgPrimary : kOrgAccentGold)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trend,
                        style: orgLabel(
                          fontSize: 10,
                          color: trendPositive ? kOrgPrimary : kOrgAccentGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: orgBody(fontSize: 11, color: kOrgTextSecondary)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kOrgSidebarDark : kOrgCanvas,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? kOrgSidebarDark : kOrgBorder,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: orgLabel(
                fontSize: 11,
                color: isSelected ? Colors.white : kOrgTextSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? kOrgPrimary
                    : kOrgBorderDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: orgLabel(
                  fontSize: 10,
                  color: isSelected ? Colors.white : kOrgTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard({
    required Application app,
    required StudentProfile? profile,
    required Scholarship? scholarship,
    required bool isDesktop,
  }) {
    final studentName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : 'Applicant #${app.id.substring(0, 6).toUpperCase()}';

    final studentSchool = profile?.school?.isNotEmpty == true
        ? profile!.school!
        : 'Higher Education Institution';

    final studentCourse = profile?.course.isNotEmpty == true
        ? profile!.course
        : 'Degree Program';

    final gwa = profile != null && profile.gpa > 0
        ? profile.gpa.toStringAsFixed(2)
        : '1.50';

    final income = profile?.incomeBracket != null
        ? '${profile!.incomeBracket!.toUpperCase()} Tier'
        : 'Low Income';

    final statusColor = app.status == ApplicationStatus.approved
        ? kOrgBadgeApprovedBg
        : app.status == ApplicationStatus.rejected
            ? kOrgBadgeRejectedBg
            : kOrgBadgePendingBg;

    final statusTextColor = app.status == ApplicationStatus.approved
        ? kOrgBadgeApprovedText
        : app.status == ApplicationStatus.rejected
            ? kOrgBadgeRejectedText
            : kOrgBadgePendingText;

    final statusBorderColor = app.status == ApplicationStatus.approved
        ? kOrgBadgeApprovedBorder
        : app.status == ApplicationStatus.rejected
            ? kOrgBadgeRejectedBorder
            : kOrgBadgePendingBorder;

    return Container(
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kOrgBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left Accent Border
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(
              decoration: BoxDecoration(
                color: app.status == ApplicationStatus.approved
                    ? kOrgPrimary
                    : app.status == ApplicationStatus.rejected
                        ? kOrgError
                        : kOrgAccentGold,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isDesktop ? 20 : 16, 12, 16, 12),
            child: isDesktop
                ? Row(
                    children: [
                      // Applicant Info
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: kOrgPrimary,
                              child: Text(
                                studentName.isNotEmpty
                                    ? studentName[0].toUpperCase()
                                    : 'A',
                                style: orgHeadline(
                                    fontSize: 13, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(studentName,
                                      style: orgHeadline(fontSize: 14)),
                                  Text('$studentCourse • $studentSchool',
                                      overflow: TextOverflow.ellipsis,
                                      style: orgBody(
                                          fontSize: 12,
                                          color: kOrgTextSecondary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: kOrgBadgeApprovedBg,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text('GWA $gwa',
                                            style: orgLabel(
                                                fontSize: 10,
                                                color: kOrgBadgeApprovedText)),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: kOrgCanvas,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(color: kOrgBorder),
                                        ),
                                        child: Text(income,
                                            style: orgLabel(
                                                fontSize: 10,
                                                color: kOrgTextMuted)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Target Scholarship
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scholarship?.title ?? 'Merit Scholarship',
                              overflow: TextOverflow.ellipsis,
                              style: orgHeadline(
                                  fontSize: 13, color: kOrgTextPrimary),
                            ),
                            Text(
                              scholarship != null
                                  ? (scholarship.slots != null
                                      ? '₱50,000 / Sem'
                                      : 'Full Grant')
                                  : 'Full Support',
                              style: orgBody(
                                  fontSize: 11, color: kOrgPrimary),
                            ),
                          ],
                        ),
                      ),
                      // Status
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusBorderColor),
                            ),
                            child: Text(
                              _statusLabel(app.status),
                              style: orgLabel(
                                  fontSize: 11, color: statusTextColor),
                            ),
                          ),
                        ),
                      ),
                      // Action
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: kOrgPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ApplicantReviewDrawer.show(
                                context,
                                application: app,
                                scholarship: scholarship,
                                applicantProfile: profile,
                                onStatusChanged: () {
                                  ref
                                      .read(
                                          incomingApplicationsProvider.notifier)
                                      .refresh();
                                },
                              );
                            },
                            icon: const Icon(Icons.description_rounded, size: 14),
                            label: Text('Review Dossier',
                                style: orgLabel(
                                    color: Colors.white, fontSize: 11)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(studentName,
                                overflow: TextOverflow.ellipsis,
                                style: orgHeadline(fontSize: 15)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusBorderColor),
                            ),
                            child: Text(
                              _statusLabel(app.status),
                              style: orgLabel(
                                  fontSize: 10, color: statusTextColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('$studentCourse • $studentSchool',
                          style:
                              orgBody(fontSize: 12, color: kOrgTextSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: kOrgBadgeApprovedBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('GWA $gwa',
                                style: orgLabel(
                                    fontSize: 10,
                                    color: kOrgBadgeApprovedText)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: kOrgCanvas,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: kOrgBorder),
                            ),
                            child: Text(income,
                                style: orgLabel(
                                    fontSize: 10, color: kOrgTextMuted)),
                          ),
                          const Spacer(),
                          Text(
                            scholarship != null
                                ? (scholarship.slots != null
                                    ? '₱50,000 / Sem'
                                    : 'Full Grant')
                                : '',
                            style: orgHeadline(
                                fontSize: 13, color: kOrgPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kOrgPrimary),
                            foregroundColor: kOrgPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ApplicantReviewDrawer.show(
                              context,
                              application: app,
                              scholarship: scholarship,
                              applicantProfile: profile,
                              onStatusChanged: () {
                                ref
                                    .read(
                                        incomingApplicationsProvider.notifier)
                                    .refresh();
                              },
                            );
                          },
                          icon: const Icon(Icons.description_rounded, size: 15),
                          label: const Text('Review Application Dossier'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.draft:
      return 'Draft';
    case ApplicationStatus.submitted:
      return 'Submitted';
    case ApplicationStatus.underReview:
      return 'Under Review';
    case ApplicationStatus.approved:
      return 'Approved';
    case ApplicationStatus.rejected:
      return 'Rejected';
    case ApplicationStatus.withdrawn:
      return 'Withdrawn';
    case ApplicationStatus.awarded:
      return 'Awarded';
  }
}
