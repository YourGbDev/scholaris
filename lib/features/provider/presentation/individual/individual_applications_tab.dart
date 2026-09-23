// lib/features/provider/presentation/individual/individual_applications_tab.dart
//
// Mobile-first review feed for Individual Benefactors.
// Features a compact "My Impact" card at the top, followed by a
// streamlined single-column applicant review feed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../profile/models/student_profile.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../../scholarships/providers/scholarships_provider.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../org/org_provider_theme.dart';
import '../widgets/applicant_review_drawer.dart';

class IndividualApplicationsTab extends ConsumerStatefulWidget {
  const IndividualApplicationsTab({super.key});

  @override
  ConsumerState<IndividualApplicationsTab> createState() =>
      _IndividualApplicationsTabState();
}

class _IndividualApplicationsTabState
    extends ConsumerState<IndividualApplicationsTab> {
  ApplicationStatus? _selectedStatus;

  int _getAwardAmount(dynamic s) {
    if (s is Scholarship) {
      return s.awardAmount;
    }
    return 50000;
  }

  String _formatCurrency(int amount) {
    return '₱${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final incomingAppsAsync = ref.watch(incomingApplicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

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
                Text('Error loading applicants', style: orgHeadline(fontSize: 16)),
                const SizedBox(height: 6),
                Text('$err',
                    style: orgBody(fontSize: 12, color: kOrgTextSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kOrgPrimary),
                  onPressed: () =>
                      ref.refresh(incomingApplicationsProvider.future),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (apps) {
          final profiles = ref.watch(providerApplicantProfilesProvider).valueOrNull ??
              <String, StudentProfile>{};
          final scholarshipsMap = {
            for (final Scholarship s in (scholarshipsAsync.valueOrNull ?? <Scholarship>[])) s.id: s
          };

          final approvedApps = apps
              .where((a) =>
                  a.status == ApplicationStatus.approved ||
                  a.status == ApplicationStatus.awarded)
              .toList();

          final totalGrantAmount = approvedApps.length * 50000;

          final filteredApps = _selectedStatus == null
              ? apps
              : apps.where((a) => a.status == _selectedStatus).toList();

          return RefreshIndicator(
            color: kOrgPrimary,
            onRefresh: () async {
              ref.invalidate(incomingApplicationsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Compact "My Impact" Summary Card (collapsed from full Analytics)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kOrgSidebarDark, kOrgPrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kOrgPrimary.withValues(alpha: 0.15),
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.favorite_rounded,
                                    size: 13, color: kOrgAccentGold),
                                const SizedBox(width: 4),
                                Text(
                                  'My Philanthropic Impact',
                                  style: orgLabel(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Text('AY 2024–2025',
                              style: orgLabel(
                                  color: const Color(0xFFB3F1C6), fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Committed Grants',
                                    style: orgLabel(
                                        color: Colors.white70, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  totalGrantAmount > 0
                                      ? _formatCurrency(totalGrantAmount)
                                      : '₱50,000',
                                  style: orgHeadline(
                                      fontSize: 18, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Scholars Supported',
                                    style: orgLabel(
                                        color: Colors.white70, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  '${approvedApps.length} Student${approvedApps.length == 1 ? '' : 's'}',
                                  style: orgHeadline(
                                      fontSize: 18, color: kOrgAccentGold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Review Queue Header & Status Filter Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Applicant Feed', style: orgHeadline(fontSize: 16)),
                    Text('${apps.length} Total Candidates',
                        style: orgLabel(fontSize: 11, color: kOrgTextMuted)),
                  ],
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('All', apps.length, _selectedStatus == null,
                          () => setState(() => _selectedStatus = null)),
                      const SizedBox(width: 6),
                      _buildChip(
                        'Submitted',
                        apps
                            .where((a) =>
                                a.status == ApplicationStatus.submitted)
                            .length,
                        _selectedStatus == ApplicationStatus.submitted,
                        () => setState(() =>
                            _selectedStatus = ApplicationStatus.submitted),
                      ),
                      const SizedBox(width: 6),
                      _buildChip(
                        'Under Review',
                        apps
                            .where((a) =>
                                a.status == ApplicationStatus.underReview)
                            .length,
                        _selectedStatus == ApplicationStatus.underReview,
                        () => setState(() =>
                            _selectedStatus = ApplicationStatus.underReview),
                      ),
                      const SizedBox(width: 6),
                      _buildChip(
                        'Approved',
                        approvedApps.length,
                        _selectedStatus == ApplicationStatus.approved,
                        () => setState(() =>
                            _selectedStatus = ApplicationStatus.approved),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Applications List
                if (filteredApps.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: kOrgSurfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kOrgBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 40, color: kOrgTextMuted),
                        const SizedBox(height: 8),
                        Text('No candidates in this queue',
                            style: orgHeadline(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'New student applications to your grants will appear here.',
                          style: orgBody(
                              fontSize: 12, color: kOrgTextSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredApps.map((app) {
                    final profile = profiles[app.userId];
                    final scholarship = scholarshipsMap[app.scholarshipId];

                    final studentName = profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : 'Applicant #${app.id.substring(0, 5).toUpperCase()}';

                    final studentSchool = profile?.school?.isNotEmpty == true
                        ? profile!.school!
                        : 'Higher Education Institution';

                    final studentCourse = profile?.course.isNotEmpty == true
                        ? profile!.course
                        : 'Degree Program';

                    final gwa = profile != null && profile.gpa > 0
                        ? profile.gpa.toStringAsFixed(2)
                        : '1.50';

                    final isApproved = app.status == ApplicationStatus.approved ||
                        app.status == ApplicationStatus.awarded;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kOrgSurfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kOrgBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: kOrgPrimary,
                                child: Text(
                                  studentName.isNotEmpty
                                      ? studentName[0].toUpperCase()
                                      : 'S',
                                  style: orgHeadline(
                                      fontSize: 13, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(studentName,
                                        style: orgHeadline(fontSize: 14)),
                                    Text('$studentCourse • $studentSchool',
                                        overflow: TextOverflow.ellipsis,
                                        style: orgBody(
                                            fontSize: 11,
                                            color: kOrgTextSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isApproved
                                      ? kOrgBadgeApprovedBg
                                      : kOrgBadgePendingBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _statusLabel(app.status),
                                  style: orgLabel(
                                    fontSize: 10,
                                    color: isApproved
                                        ? kOrgBadgeApprovedText
                                        : kOrgBadgePendingText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
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
                              if (profile?.incomeBracket != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kOrgCanvas,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: kOrgBorder),
                                  ),
                                  child: Text(
                                    '${profile!.incomeBracket!.toUpperCase()} Tier',
                                    style: orgLabel(
                                        fontSize: 10, color: kOrgTextMuted),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                scholarship != null
                                    ? _formatCurrency(_getAwardAmount(scholarship))
                                    : '₱35,000 / sem',
                                style: orgHeadline(
                                    fontSize: 13, color: kOrgPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Deliberation Note / Essay Snippet
                          if (app.notes?.isNotEmpty == true)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: kOrgCanvas,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '"${app.notes!.trim()}"',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: orgBody(
                                    fontSize: 11,
                                    color: kOrgTextSecondary,
                                    height: 1.4),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: kOrgPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
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
                              icon: const Icon(Icons.rate_review_outlined,
                                  size: 15),
                              label: const Text('Review Application & Decide'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(
      String label, int count, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? kOrgSidebarDark : kOrgSurfaceWhite,
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
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: orgLabel(
                fontSize: 10,
                color: isSelected ? kOrgAccentGold : kOrgTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.draft: return 'Draft';
    case ApplicationStatus.submitted: return 'Submitted';
    case ApplicationStatus.underReview: return 'Under Review';
    case ApplicationStatus.approved: return 'Approved';
    case ApplicationStatus.rejected: return 'Rejected';
    case ApplicationStatus.withdrawn: return 'Withdrawn';
    case ApplicationStatus.awarded: return 'Awarded';
  }
}
