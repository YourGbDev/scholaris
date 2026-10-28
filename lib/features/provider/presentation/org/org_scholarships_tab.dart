// lib/features/provider/presentation/org/org_scholarships_tab.dart
//
// Institutional "My Scholarships" Management Tab faithfully matching Stitch mockup
// (stitch_scholaris_provider_console_mockup/scholaris_provider_my_scholarships).
// Displays real Philippines scholarship grant portfolios, live quota fulfillment,
// executive Bento performance metrics, and institutional escrow verification.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../../scholarships/providers/scholarship_capacity_provider.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../scholarship_form_screen.dart';
import '../widgets/scholarship_qr_dialog.dart';

import 'package:scholaris/shared/theme/app_motion.dart';

import 'org_provider_theme.dart';
import '../widgets/org_metric_count.dart';
import '../widgets/org_summary_disclosure.dart';
import 'widgets/assign_reviewer_dialog.dart';

class OrgScholarshipsTab extends ConsumerStatefulWidget {
  const OrgScholarshipsTab({super.key, this.onViewApplicationsForScholarship});

  final void Function(String scholarshipId)? onViewApplicationsForScholarship;

  @override
  ConsumerState<OrgScholarshipsTab> createState() => _OrgScholarshipsTabState();
}

class _OrgScholarshipsTabState extends ConsumerState<OrgScholarshipsTab> {
  int _selectedSegment = 0; // 0: Active, 1: Archived, 2: Drafts
  String _sortBy = 'deadline'; // 'deadline' | 'allocation' | 'title'

  void _openCreateScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(builder: (_) => const ScholarshipFormScreen()),
    );
  }

  void _openEditScreen(Scholarship scholarship) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => ScholarshipFormScreen(
          scholarshipId: scholarship.id,
          initialScholarship: scholarship,
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '₱${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final scholarshipsAsync = ref.watch(providerScholarshipsProvider);
    final incomingAppsAsync = ref.watch(incomingApplicationsProvider);
    if (incomingAppsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (incomingAppsAsync.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Application totals could not load.'),
            TextButton(
              onPressed: () => ref.invalidate(incomingApplicationsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final profile = ref.watch(currentProfileProvider).valueOrNull;

    final orgName = (profile?.fullName.trim().isNotEmpty == true)
        ? profile!.fullName.trim()
        : 'Institutional Provider';

    return Container(
      color: kOrgCanvas,
      child: CrossFadeLoading(
        isLoading: scholarshipsAsync.isLoading,
        skeleton: _buildSkeletonLoader(),
        child: scholarshipsAsync.when(
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
                    'Error loading scholarships',
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
                        ref.refresh(providerScholarshipsProvider.future),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (scholarships) {
            final apps = incomingAppsAsync.valueOrNull ?? <Application>[];

            // Compute Bento KPIs from live database
            final activeScholarships = scholarships
                .where((s) => s.isActive)
                .toList();
            final archivedScholarships = scholarships
                .where((s) => !s.isActive)
                .toList();

            final activeCount = activeScholarships.length;
            final totalCommittedCapital = scholarships.fold<int>(
              0,
              (sum, s) =>
                  sum + (s.slots != null ? s.slots! * s.awardAmount : 0),
            );
            final totalQuota = scholarships.fold<int>(
              0,
              (sum, s) => sum + (s.slots ?? 0),
            );

            final awardedApps = apps
                .where(
                  (a) =>
                      a.status == ApplicationStatus.approved ||
                      a.status == ApplicationStatus.awarded,
                )
                .toList();
            final awardedCount = awardedApps.length;

            final quotaRatio = totalQuota > 0
                ? (awardedCount / totalQuota)
                : 0.0;
            final quotaPercent = quotaRatio * 100;

            final scholarshipsMap = <String, Scholarship>{
              for (final s in scholarships) s.id: s,
            };
            final annualDisbursement = awardedApps.fold<int>(
              0,
              (sum, a) =>
                  sum + (scholarshipsMap[a.scholarshipId]?.awardAmount ?? 0),
            );

            // Filter by selected segment
            List<Scholarship> segmentScholarships;
            if (_selectedSegment == 0) {
              segmentScholarships = activeScholarships;
            } else if (_selectedSegment == 1) {
              segmentScholarships = archivedScholarships;
            } else {
              segmentScholarships = []; // Drafts
            }

            final displayScholarships = List<Scholarship>.from(
              segmentScholarships,
            );

            // Sort
            if (_sortBy == 'deadline') {
              displayScholarships.sort(
                (a, b) => a.deadline.compareTo(b.deadline),
              );
            } else if (_sortBy == 'allocation') {
              displayScholarships.sort((a, b) {
                final allocA = (a.slots ?? 0) * a.awardAmount;
                final allocB = (b.slots ?? 0) * b.awardAmount;
                return allocB.compareTo(allocA);
              });
            } else if (_sortBy == 'title') {
              displayScholarships.sort((a, b) => a.title.compareTo(b.title));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 768;

                return RefreshIndicator(
                  color: kOrgPrimary,
                  onRefresh: () async {
                    ref.invalidate(providerScholarshipsProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AppleBouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: isDesktop ? 28 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Breadcrumb + Title + Subtitle + Action Controls
                        _buildHeaderSection(context, orgName, isDesktop),

                        const SizedBox(height: 24),

                        // 2. Bento Metrics Row (4 Cards)
                        OrgSummaryDisclosure(
                          title: 'Program summary',
                          summary:
                              '$activeCount active ${activeCount == 1 ? 'program' : 'programs'} · $awardedCount approved / awarded',
                          child: _buildBentoRow(
                            constraints: constraints,
                            activeCount: activeCount,
                            totalCommittedCapital: totalCommittedCapital,
                            awardedCount: awardedCount,
                            totalQuota: totalQuota,
                            quotaPercent: quotaPercent,
                            annualDisbursement: annualDisbursement,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 3. Filter Segment Toolbar & Sort Dropdown
                        _buildFilterToolbar(
                          activeCount: activeCount,
                          archivedCount: archivedScholarships.length,
                          isDesktop: isDesktop,
                        ),

                        const SizedBox(height: 18),

                        // 4. Grant Portfolio Cards Grid
                        if (displayScholarships.isEmpty)
                          _buildEmptyState()
                        else
                          _buildCardGrid(
                            displayScholarships: displayScholarships,
                            apps: apps,
                            isDesktop: isDesktop,
                            maxWidth: constraints.maxWidth,
                          ),

                        const SizedBox(height: 32),

                        // 5. Institutional Escrow Verification Footer Strip
                        _buildEscrowBanner(
                          context,
                          scholarships.length,
                          isDesktop,
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: Top Navigation, Breadcrumb & Header
  // ===========================================================================
  Widget _buildHeaderSection(
    BuildContext context,
    String orgName,
    bool isDesktop,
  ) {
    final breadcrumb = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: kOrgPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.domain_rounded, size: 11, color: kOrgPrimary),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            orgName.toUpperCase(),
            style: orgLabel(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kOrgTextSecondary,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '•',
            style: orgLabel(fontSize: 11, color: const Color(0xFFC0C9C0)),
          ),
        ),
        Text(
          'PORTFOLIO OVERSIGHT',
          style: orgLabel(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kOrgPrimary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );

    final titleAndSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        breadcrumb,
        const SizedBox(height: 8),
        Text(
          'Scholarship programs',
          style: orgHeadline(
            fontSize: isDesktop ? 32 : 26,
            fontWeight: FontWeight.w700,
            color: kOrgTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Manage programs, eligibility requirements, and application deadlines.',
            style: orgBody(fontSize: 13.5, color: kOrgTextSecondary),
          ),
        ),
      ],
    );

    final actionButtons = Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: _openCreateScreen,
          style: FilledButton.styleFrom(
            backgroundColor: kOrgPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create scholarship'),
        ),
        PopupMenuButton<String>(
          tooltip: 'Additional program tools',
          icon: const Icon(Icons.more_horiz_rounded, color: kOrgTextSecondary),
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              enabled: false,
              child: Text('Export summary — not available'),
            ),
          ],
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: titleAndSubtitle),
          const SizedBox(width: 20),
          actionButtons,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleAndSubtitle,
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: actionButtons,
          ),
        ],
      );
    }
  }

  // ===========================================================================
  // SECTION 2: Executive Bento Metrics Row
  // ===========================================================================
  Widget _buildBentoRow({
    required BoxConstraints constraints,
    required int activeCount,
    required int totalCommittedCapital,
    required int awardedCount,
    required int totalQuota,
    required double quotaPercent,
    required int annualDisbursement,
  }) {
    final card1 = _buildBentoCard(
      title: 'TOTAL ACTIVE GRANTS',
      icon: Icons.layers_outlined,
      iconColor: kOrgPrimary,
      isSelected: _selectedSegment == 0,
      tooltip: 'Show active grant programs ($activeCount)',
      onTap: () => setState(() => _selectedSegment = 0),
      primaryWidget: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          OrgMetricCount(
            motionId: 'programs.activeCount',
            targetValue: activeCount,
            style: orgHeadline(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kOrgTextPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            activeCount == 1 ? 'Program' : 'Programs',
            style: orgHeadline(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kOrgTextPrimary,
            ),
          ),
        ],
      ),
      bottomWidget: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: kOrgPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$activeCount active programs',
              style: orgLabel(fontSize: 11, color: kOrgTextSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final card2 = _buildBentoCard(
      title: 'ESTIMATED SLOT ALLOCATION',
      icon: Icons.account_balance_outlined,
      iconColor: kOrgPrimary,
      primaryWidget: OrgMetricCount(
        motionId: 'programs.totalCommittedCapital',
        targetValue: totalCommittedCapital,
        prefix: '₱',
        formatWithCommas: true,
        style: orgHeadline(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: kOrgTextPrimary,
        ),
      ),
      bottomWidget: Text(
        'Listed slots × award amount; excludes unspecified slots.',
        style: orgBody(fontSize: 11, color: kOrgTextSecondary),
      ),
    );

    final card3 = _buildBentoCard(
      title: 'AWARDED SCHOLARS',
      icon: Icons.group_outlined,
      iconColor: const Color(0xFF0058BC),
      tooltip: 'View candidate applications roster',
      onTap: () => widget.onViewApplicationsForScholarship?.call(''),
      primaryWidget: OrgMetricCount(
        motionId: 'programs.awardedCount',
        targetValue: awardedCount,
        style: orgHeadline(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: kOrgTextPrimary,
        ),
      ),
      secondarySuffix: totalQuota > 0 ? '/ $totalQuota Quota' : '/ Uncapped',
      bottomWidget: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalQuota > 0
                    ? (awardedCount / totalQuota).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: 5,
                backgroundColor: const Color(0xFFE9E7ED),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF0070EB),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${quotaPercent.toStringAsFixed(1)}%',
            style: orgHeadline(fontSize: 11.5, color: kOrgTextPrimary),
          ),
        ],
      ),
    );

    final card4 = _buildBentoCard(
      title: 'ESTIMATED AWARD COMMITMENTS',
      icon: Icons.payments_outlined,
      iconColor: kOrgPrimary,
      primaryWidget: OrgMetricCount(
        motionId: 'programs.annualDisbursement',
        targetValue: annualDisbursement,
        prefix: '₱',
        formatWithCommas: true,
        style: orgHeadline(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: kOrgTextPrimary,
        ),
      ),
      bottomWidget: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Known awards only; excludes missing programs',
              style: orgLabel(fontSize: 11, color: kOrgTextSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDF3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Not a payment total',
                style: orgHeadline(fontSize: 9.5, color: kOrgTextPrimary),
              ),
            ),
          ),
        ],
      ),
    );

    if (constraints.maxWidth >= 1280) {
      return Row(
        children: [
          Expanded(child: card1),
          const SizedBox(width: 14),
          Expanded(child: card2),
          const SizedBox(width: 14),
          Expanded(child: card3),
          const SizedBox(width: 14),
          Expanded(child: card4),
        ],
      );
    } else if (constraints.maxWidth >= 540) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 14),
              Expanded(child: card2),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: card3),
              const SizedBox(width: 14),
              Expanded(child: card4),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          card1,
          const SizedBox(height: 12),
          card2,
          const SizedBox(height: 12),
          card3,
          const SizedBox(height: 12),
          card4,
        ],
      );
    }
  }

  Widget _buildBentoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? primaryMetric,
    Widget? primaryWidget,
    String? secondarySuffix,
    required Widget bottomWidget,
    VoidCallback? onTap,
    bool isSelected = false,
    String? tooltip,
  }) {
    final cardContent = AnimatedContainer(
      duration: isReducedMotion(context) ? Duration.zero : kDurationFast,
      curve: kEaseOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? kOrgPrimary : const Color(0xFFEEEDF3),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? kOrgPrimary.withValues(alpha: 0.12)
                : const Color(0x06000000),
            blurRadius: isSelected ? 10 : 6,
            offset: isSelected ? const Offset(0, 3) : const Offset(0, 1),
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
                  title,
                  style: orgLabel(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? kOrgPrimary : kOrgTextSecondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? kOrgPrimary.withValues(alpha: 0.10)
                      : const Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? kOrgPrimary : iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (primaryWidget != null)
                primaryWidget
              else
                Text(
                  primaryMetric ?? '',
                  style: orgHeadline(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kOrgTextPrimary,
                  ),
                ),
              if (secondarySuffix != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    secondarySuffix,
                    style: orgBody(fontSize: 12.5, color: kOrgTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          bottomWidget,
        ],
      ),
    );

    if (onTap != null) {
      Widget interactive = PressableScale(
        scale: 0.985,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            hoverColor: const Color(0xFFFAF9FD),
            child: cardContent,
          ),
        ),
      );
      if (tooltip != null) {
        interactive = Tooltip(message: tooltip, child: interactive);
      }
      return interactive;
    }
    return cardContent;
  }

  // ===========================================================================
  // SECTION 3: Filter & Segment View Toolbar
  // ===========================================================================
  Widget _buildFilterToolbar({
    required int activeCount,
    required int archivedCount,
    required bool isDesktop,
  }) {
    final segmentTabs = [
      'Active Programs ($activeCount)',
      'Archived & Historical',
      'Draft Endowments',
    ];

    final pills = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEDF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(segmentTabs.length, (idx) {
          final isSelected = _selectedSegment == idx;
          return Semantics(
            selected: isSelected,
            child: PressableScale(
              scale: 0.97,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedSegment = idx),
                child: AnimatedContainer(
                  duration: isReducedMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  constraints: const BoxConstraints(minHeight: 36),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? kOrgSurfaceWhite : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    segmentTabs[idx],
                    style: orgLabel(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? kOrgTextPrimary : kOrgTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );

    final sortDropdown = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sort by:',
          style: orgLabel(fontSize: 12, color: kOrgTextSecondary),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          initialValue: _sortBy,
          tooltip: 'Sort scholarships',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (val) => setState(() => _sortBy = val),
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'deadline',
              child: Text('Deadline (Soonest first)'),
            ),
            const PopupMenuItem(
              value: 'allocation',
              child: Text('Total Allocation (Highest first)'),
            ),
            const PopupMenuItem(value: 'title', child: Text('Title (A–Z)')),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sortBy == 'deadline'
                      ? 'Deadline / Allocation'
                      : _sortBy == 'allocation'
                      ? 'Total Allocation'
                      : 'Title (A–Z)',
                  style: orgHeadline(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kOrgTextPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: kOrgTextPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: pills,
            ),
          ),
          const SizedBox(width: 12),
          sortDropdown,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: pills),
          const SizedBox(height: 10),
          sortDropdown,
        ],
      );
    }
  }

  // ===========================================================================
  // SECTION 4: Grant Portfolio Cards Grid
  // ===========================================================================
  Widget _buildCardGrid({
    required List<Scholarship> displayScholarships,
    required List<Application> apps,
    required bool isDesktop,
    required double maxWidth,
  }) {
    if (maxWidth >= 760) {
      // 2-column balanced pairs
      final rows = <Widget>[];
      for (int i = 0; i < displayScholarships.length; i += 2) {
        final first = displayScholarships[i];
        final second = (i + 1 < displayScholarships.length)
            ? displayScholarships[i + 1]
            : null;

        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StaggeredListItem(
                  index: i,
                  child: _buildScholarshipCard(first, apps),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: second != null
                    ? StaggeredListItem(
                        index: i + 1,
                        child: _buildScholarshipCard(second, apps),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
        if (i + 2 < displayScholarships.length) {
          rows.add(const SizedBox(height: 18));
        }
      }
      return Column(children: rows);
    } else {
      // 1-column mobile stacked layout
      return Column(
        children: [
          for (int i = 0; i < displayScholarships.length; i++) ...[
            StaggeredListItem(
              index: i,
              child: _buildScholarshipCard(displayScholarships[i], apps),
            ),
            if (i < displayScholarships.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBand(width: 240, height: 28, borderRadius: 8),
          const SizedBox(height: 12),
          const SkeletonBand(width: 380, height: 16, borderRadius: 6),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: SkeletonBand(height: 110, borderRadius: 16)),
              SizedBox(width: 14),
              Expanded(child: SkeletonBand(height: 110, borderRadius: 16)),
              SizedBox(width: 14),
              Expanded(child: SkeletonBand(height: 110, borderRadius: 16)),
              SizedBox(width: 14),
              Expanded(child: SkeletonBand(height: 110, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: SkeletonBand(height: 220, borderRadius: 16)),
              SizedBox(width: 18),
              Expanded(child: SkeletonBand(height: 220, borderRadius: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScholarshipCard(
    Scholarship scholarship,
    List<Application> apps,
  ) {
    final targetApps = apps
        .where((a) => a.scholarshipId == scholarship.id)
        .toList();
    final applicantCount = targetApps.length;

    final capacityAsync = ref.watch(
      scholarshipCapacityProvider(scholarship.id),
    );
    final capacity = capacityAsync.valueOrNull;

    final occupiedCount =
        capacity?.occupiedSlots ??
        targetApps
            .where(
              (a) =>
                  a.status == ApplicationStatus.approved ||
                  a.status == ApplicationStatus.awarded,
            )
            .length;
    final totalSlots = capacity?.totalSlots ?? scholarship.slots;
    final hasSlots = totalSlots != null && !(capacity?.isUncapped ?? false);
    final remainingSeats =
        capacity?.remainingSlots ??
        (hasSlots ? (totalSlots - occupiedCount).clamp(0, totalSlots) : null);

    final daysLeft = scholarship.deadline.difference(DateTime.now()).inDays;
    final isExpired = daysLeft < 0;
    final fillRatio = hasSlots && totalSlots > 0
        ? (occupiedCount / totalSlots).clamp(0.0, 1.0)
        : 0.0;
    final fillPercent = (fillRatio * 100).toInt();
    final totalAllocation = hasSlots
        ? totalSlots * scholarship.awardAmount
        : null;

    return Container(
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Body Padding
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Bar & Trailing Options
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 8,
                  children: [
                    // Status Tag: Active Intake or Deliberation
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? const Color(0xFFFFDAD6).withValues(alpha: 0.5)
                            : kOrgPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isExpired ? kOrgError : kOrgPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isExpired ? 'Application Closed' : 'Active Intake',
                            style: orgLabel(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isExpired ? kOrgError : kOrgPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Countdown / Quota Tag
                    if (!isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E7ED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: kOrgTextPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              daysLeft == 0
                                  ? 'Closing today'
                                  : 'Closing in $daysLeft days',
                              style: orgLabel(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: kOrgTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E7ED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Archived Intake',
                          style: orgLabel(
                            fontSize: 10.5,
                            color: kOrgTextSecondary,
                          ),
                        ),
                      ),

                    // More options popup
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: kOrgTextSecondary,
                      ),
                      tooltip: 'Grant Actions',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (action) {
                        if (action == 'edit') {
                          _openEditScreen(scholarship);
                        } else if (action == 'view_apps') {
                          widget.onViewApplicationsForScholarship?.call(
                            scholarship.id,
                          );
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Criteria'),
                        ),
                        const PopupMenuItem(
                          value: 'view_apps',
                          child: Text('View Applicants'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Scholarship Title
                Text(
                  scholarship.title,
                  style: orgHeadline(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kOrgTextPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  scholarship.description?.isNotEmpty == true
                      ? scholarship.description!
                      : 'Comprehensive collegiate grant for enrolled undergraduate students across recognized Philippine higher education institutions.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: orgBody(
                    fontSize: 13,
                    color: kOrgTextSecondary,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 16),

                // 3-Metric Light Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F3F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Quota Fulfillment
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quota Fulfillment',
                              style: orgLabel(
                                fontSize: 10.5,
                                color: kOrgTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$occupiedCount ',
                                    style: orgHeadline(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: hasSlots
                                        ? '/ $totalSlots'
                                        : '/ Uncapped',
                                    style: orgBody(
                                      fontSize: 12,
                                      color: kOrgTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Funding / Scholar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Funding / Scholar',
                              style: orgLabel(
                                fontSize: 10.5,
                                color: kOrgTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _formatCurrency(
                                      scholarship.awardAmount,
                                    ),
                                    style: orgHeadline(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / yr',
                                    style: orgBody(
                                      fontSize: 11,
                                      color: kOrgTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total Allocation
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Allocation',
                              style: orgLabel(
                                fontSize: 10.5,
                                color: kOrgTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalAllocation != null
                                  ? _formatCurrency(totalAllocation)
                                  : 'Uncapped',
                              style: orgHeadline(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: kOrgPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Selection Quota Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            hasSlots
                                ? '$totalSlots total • $occupiedCount occupied • ${remainingSeats ?? 0} remaining'
                                : 'Uncapped capacity • $occupiedCount scholar${occupiedCount == 1 ? "" : "s"} approved',
                            style: orgLabel(
                              fontSize: 11,
                              color: kOrgTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          !hasSlots
                              ? 'Uncapped intake ($occupiedCount approved)'
                              : fillPercent >= 100
                              ? '100% (Fully Booked)'
                              : '$fillPercent% (${remainingSeats ?? 0} open)',
                          style: orgHeadline(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: fillPercent >= 100
                                ? kOrgPrimary
                                : kOrgTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: hasSlots ? fillRatio : 0.0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE9E7ED),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          kOrgPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card Footer Quick Action Links
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F6FA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                top: BorderSide(color: Color(0xFFEEEDF3), width: 1),
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Text Link: View N Applicants
                InkWell(
                  onTap: () {
                    widget.onViewApplicationsForScholarship?.call(
                      scholarship.id,
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          size: 16,
                          color: Color(0xFF0058BC),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View $applicantCount ${applicantCount == 1 ? "Applicant" : "Applicants"}',
                          style: orgLabel(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0058BC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right buttons: Edit Criteria & Manage Ledger
                Wrap(
                  runSpacing: 8,
                  children: [
                    Material(
                      color: const Color(0xFFE3E2E7).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            showScholarshipQrDialog(context, scholarship),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code_rounded,
                                size: 15,
                                color: kOrgTextPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'QR',
                                style: orgLabel(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: kOrgTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0xFFE3E2E7).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            AssignReviewerDialog.show(context, scholarship),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.assignment_ind_outlined,
                                size: 15,
                                color: kOrgTextPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reviewers',
                                style: orgLabel(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: kOrgTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0xFFE3E2E7).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openEditScreen(scholarship),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'Edit Criteria',
                            style: orgLabel(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: kOrgTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0xFFE3E2E7).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ledger details for "${scholarship.title}" loaded.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'Manage Ledger',
                            style: orgLabel(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: kOrgTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: Institutional Escrow Verification Footer Strip
  // ===========================================================================
  Widget _buildEscrowBanner(BuildContext context, int count, bool isDesktop) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F3F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Funding verification not recorded. Program allocations are estimates, not confirmed escrow balances or completed payments.',
          style: orgBody(fontSize: 13, color: kOrgTextSecondary),
        ),
      );
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEDF3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.folder_special_outlined,
                size: 28,
                color: kOrgTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _selectedSegment == 1
                ? 'No Archived Endowments'
                : _selectedSegment == 2
                ? 'No Draft Endowments'
                : 'No Active Scholarships Found',
            style: orgHeadline(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              _selectedSegment == 0
                  ? 'Get started by creating your first scholarship grant endowment to review student applications and allocate quotas.'
                  : 'There are no scholarship records in this category.',
              style: orgBody(fontSize: 13, color: kOrgTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          if (_selectedSegment == 0) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kOrgPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              onPressed: _openCreateScreen,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create New Grant'),
            ),
          ],
        ],
      ),
    );
  }
}
