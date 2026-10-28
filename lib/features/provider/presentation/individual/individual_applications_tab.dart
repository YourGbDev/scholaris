// lib/features/provider/presentation/individual/individual_applications_tab.dart
//
// Mobile-first review feed for Individual Benefactors.
// Features a compact "My Impact" card at the top, followed by a
// streamlined single-column applicant review feed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../profile/models/applicant_profile.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../../models/support_ledger.dart';
import '../../repositories/support_repository.dart';

import 'package:scholaris/shared/theme/app_motion.dart';

import '../org/org_provider_theme.dart';
import '../widgets/org_summary_disclosure.dart';
import '../widgets/org_metric_count.dart';
import '../widgets/applicant_review_drawer.dart';

class IndividualApplicationsTab extends ConsumerStatefulWidget {
  const IndividualApplicationsTab({super.key, this.initialAwaitingReview = false});
  final bool initialAwaitingReview;

  @override
  ConsumerState<IndividualApplicationsTab> createState() =>
      _IndividualApplicationsTabState();
}

class _IndividualApplicationsTabState
    extends ConsumerState<IndividualApplicationsTab> {
  ApplicationStatus? _selectedStatus;
  late bool _awaitingReview;

  @override
  void initState() {
    super.initState();
    _awaitingReview = widget.initialAwaitingReview;
  }

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
    final scholarshipsAsync = ref.watch(providerScholarshipsProvider);
    final supportAsync = ref.watch(supportLedgerProvider);

    return Container(
      color: kOrgCanvas,
      child: CrossFadeLoading(
        isLoading: incomingAppsAsync.isLoading,
        skeleton: _buildSkeletonLoader(),
        child: incomingAppsAsync.when(
          loading: () => _buildSkeletonLoader(),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: kOrgError,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading applicants',
                    style: orgHeadline(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check your connection and try again.',
                    style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrgPrimary,
                    ),
                    onPressed: () =>
                        ref.refresh(incomingApplicationsProvider.future),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (apps) {
            final profiles =
                ref.watch(providerApplicantProfilesProvider).valueOrNull ??
                <String, ApplicantProfile>{};
            final scholarshipsMap = {
              for (final Scholarship s
                  in (scholarshipsAsync.valueOrNull ?? <Scholarship>[]))
                s.id: s,
            };

            final approvedApps = apps
                .where(
                  (a) =>
                      a.status == ApplicationStatus.approved ||
                      a.status == ApplicationStatus.awarded,
                )
                .toList();
            final commitments = [
              for (final app in approvedApps)
                supportAsync.valueOrNull?.commitment(app.id),
            ];
            final committedCents = commitments.fold<int>(
              0,
              (total, record) =>
                  total + ((record?['amount_cents'] as num?)?.toInt() ?? 0),
            );
            final missing = commitments
                .where((record) => record == null)
                .length;

            final filteredApps = _awaitingReview
                ? apps.where((a) => a.status == ApplicationStatus.submitted || a.status == ApplicationStatus.underReview).toList()
                : _selectedStatus == null
                ? apps
                : _selectedStatus == ApplicationStatus.approved
                ? approvedApps
                : apps.where((a) => a.status == _selectedStatus).toList();

            return RefreshIndicator(
              color: kOrgPrimary,
              onRefresh: () async {
                ref.invalidate(incomingApplicationsProvider);
                ref.invalidate(supportLedgerProvider);
                try {
                  await Future.wait([
                    ref.read(incomingApplicationsProvider.future),
                    ref.read(supportLedgerProvider.future),
                  ]);
                } catch (_) {
                  // Each provider exposes its retry state in the page.
                }
              },
              child: ListView(
                physics: const AppleBouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text('Applications', style: orgHeadline(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    'Get to know your applicants and review their requirements.',
                    style: orgBody(fontSize: 14, color: kOrgTextSecondary),
                  ),
                  const SizedBox(height: 24),
                  // Compact "My Impact" Summary Card (collapsed from full Analytics)
                  OrgSummaryDisclosure(
                    title: 'Your support summary',
                    summary: '${approvedApps.length} approved applications',
                    child: Container(
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
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      size: 13,
                                      color: kOrgAccentGold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Your support',
                                      style: orgLabel(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Recorded activity',
                                style: orgLabel(
                                  color: const Color(0xFFB3F1C6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recorded commitments',
                                      style: orgLabel(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    supportAsync.when(
                                      skipLoadingOnRefresh: false,
                                      loading: () => const Text(
                                        'Checking support totals…',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      error: (_, _) => const Text(
                                        'Support totals unavailable',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      data: (_) => Text(
                                        supportMoney(committedCents),
                                        style: orgHeadline(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
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
                                    Text(
                                      'Approved applications',
                                      style: orgLabel(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        OrgMetricCount(
                                          motionId: 'individual-applications.approved',
                                          targetValue: approvedApps.length,
                                          style: orgHeadline(
                                            fontSize: 18,
                                            color: kOrgAccentGold,
                                          ),
                                        ),
                                        Text(
                                          ' Student${approvedApps.length == 1 ? '' : 's'}',
                                          style: orgHeadline(
                                            fontSize: 18,
                                            color: kOrgAccentGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (supportAsync.hasError)
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(supportLedgerProvider),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry support totals'),
                            ),
                          if (supportAsync.hasValue &&
                              !supportAsync.isLoading &&
                              !supportAsync.hasError) ...[
                            const SizedBox(height: 12),
                            Text(
                              missing > 0
                                  ? '$missing approved ${missing == 1 ? 'application has' : 'applications have'} no recorded commitment. Totals are incomplete; record agreed amounts in Budget & support.'
                                  : 'Agreed amounts are fixed records. Approval does not send money.',
                              style: orgBody(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Review Queue Header & Status Filter Chips
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text('Applicant Feed', style: orgHeadline(fontSize: 16)),
                      Text(
                        '${apps.length} Total Candidates',
                        style: orgLabel(fontSize: 11, color: kOrgTextMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    physics: const AppleBouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip(
                          'All',
                          apps.length,
                          !_awaitingReview && _selectedStatus == null,
                          () => setState(() { _awaitingReview = false; _selectedStatus = null; }),
                        ),
                        const SizedBox(width: 6),
                        _buildChip('Awaiting review', apps.where((a) => a.status == ApplicationStatus.submitted || a.status == ApplicationStatus.underReview).length, _awaitingReview, () => setState(() { _awaitingReview = true; _selectedStatus = null; })),
                        const SizedBox(width: 6),
                        _buildChip(
                          'Submitted',
                          apps
                              .where(
                                (a) => a.status == ApplicationStatus.submitted,
                              )
                              .length,
                          !_awaitingReview && _selectedStatus == ApplicationStatus.submitted,
                          () => setState(
                            () { _awaitingReview = false; _selectedStatus = ApplicationStatus.submitted; },
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          'Under Review',
                          apps
                              .where(
                                (a) =>
                                    a.status == ApplicationStatus.underReview,
                              )
                              .length,
                          !_awaitingReview && _selectedStatus == ApplicationStatus.underReview,
                          () => setState(
                            () { _awaitingReview = false; _selectedStatus = ApplicationStatus.underReview; },
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          'Approved',
                          approvedApps.length,
                          !_awaitingReview && _selectedStatus == ApplicationStatus.approved,
                          () => setState(
                            () { _awaitingReview = false; _selectedStatus = ApplicationStatus.approved; },
                          ),
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
                          const Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: kOrgTextMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No candidates in this queue',
                            style: orgHeadline(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'New student applications to your grants will appear here.',
                            style: orgBody(
                              fontSize: 12,
                              color: kOrgTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredApps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final app = entry.value;
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

                      final hasGwa = profile != null && profile.gpa > 0;
                      final gwa = hasGwa
                          ? profile.gpa.toStringAsFixed(2)
                          : 'N/A';

                      final isApproved =
                          app.status == ApplicationStatus.approved ||
                          app.status == ApplicationStatus.awarded;

                      return StaggeredListItem(
                        index: index,
                        child: Container(
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
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName,
                                          style: orgHeadline(fontSize: 14),
                                        ),
                                        Text(
                                          '$studentCourse • $studentSchool',
                                          overflow: TextOverflow.ellipsis,
                                          style: orgBody(
                                            fontSize: 11,
                                            color: kOrgTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
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
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasGwa
                                          ? kOrgBadgeApprovedBg
                                          : kOrgBadgePendingBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      hasGwa ? 'GWA $gwa' : 'GWA Pending',
                                      style: orgLabel(
                                        fontSize: 10,
                                        color: hasGwa
                                            ? kOrgBadgeApprovedText
                                            : kOrgBadgePendingText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (profile?.incomeBracket != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kOrgCanvas,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: kOrgBorder),
                                      ),
                                      child: Text(
                                        '${profile!.incomeBracket!.toUpperCase()} Tier',
                                        style: orgLabel(
                                          fontSize: 10,
                                          color: kOrgTextMuted,
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  Text(
                                    scholarship != null
                                        ? _formatCurrency(
                                            _getAwardAmount(scholarship),
                                          )
                                        : 'Grant pending',
                                    style: orgHeadline(
                                      fontSize: 13,
                                      color: kOrgPrimary,
                                    ),
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
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: PressableScale(
                                  scale: 0.97,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: kOrgPrimary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                                                incomingApplicationsProvider
                                                    .notifier,
                                              )
                                              .refresh();
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.rate_review_outlined,
                                      size: 15,
                                    ),
                                    label: const Text(
                                      'Review Application & Decide',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonBand(height: 120, borderRadius: 16),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SkeletonBand(width: 140, height: 20, borderRadius: 6),
            SkeletonBand(width: 90, height: 16, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonBand(height: 130, borderRadius: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    int count,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFFE5EDDD),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: orgLabel(fontSize: 12, color: kOrgPrimary)),
            const SizedBox(width: 6),
            Text(
              '($count)',
              style: orgBody(fontSize: 12, color: kOrgTextSecondary),
            ),
          ],
        ),
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
