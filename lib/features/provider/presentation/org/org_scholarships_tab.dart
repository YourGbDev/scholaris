// lib/features/provider/presentation/org/org_scholarships_tab.dart
//
// Institutional "My Scholarships" Management Tab based on Stitch mockup
// (scholaris_provider_console_my_scholarships_marketing_view).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../scholarship_form_screen.dart';
import 'org_provider_theme.dart';

class OrgScholarshipsTab extends ConsumerStatefulWidget {
  const OrgScholarshipsTab({
    super.key,
    this.onViewApplicationsForScholarship,
  });

  final void Function(String scholarshipId)? onViewApplicationsForScholarship;

  @override
  ConsumerState<OrgScholarshipsTab> createState() => _OrgScholarshipsTabState();
}

class _OrgScholarshipsTabState extends ConsumerState<OrgScholarshipsTab> {
  String _searchQuery = '';

  void _openCreateScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const ScholarshipFormScreen(),
      ),
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

  @override
  Widget build(BuildContext context) {
    final scholarshipsAsync = ref.watch(providerScholarshipsProvider);
    final incomingAppsAsync = ref.watch(incomingApplicationsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Container(
      color: kOrgCanvas,
      child: scholarshipsAsync.when(
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
                Text('Error loading scholarships',
                    style: orgHeadline(fontSize: 16)),
                const SizedBox(height: 6),
                Text('$err',
                    style: orgBody(fontSize: 12, color: kOrgTextSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kOrgPrimary),
                  onPressed: () =>
                      ref.refresh(providerScholarshipsProvider.future),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (scholarships) {
          final apps = incomingAppsAsync.valueOrNull ?? [];

          final filteredScholarships = scholarships.where((s) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return s.title.toLowerCase().contains(query) ||
                (s.description?.toLowerCase().contains(query) ?? false) ||
                (s.requiredCourses?.any((c) => c.toLowerCase().contains(query)) ?? false);
          }).toList();

          return RefreshIndicator(
            color: kOrgPrimary,
            onRefresh: () async {
              ref.invalidate(providerScholarshipsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header Bar
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
                                Text('MY SCHOLARSHIPS',
                                    style: orgLabel(
                                        fontSize: 10, color: kOrgPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('My Scholarships',
                                style: orgHeadline(fontSize: isDesktop ? 22 : 18)),
                            const SizedBox(height: 2),
                            Text(
                              'Publish grant opportunities, monitor quota allocations, and configure eligibility benchmarks.',
                              style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kOrgPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _openCreateScreen,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text('Create Scholarship',
                            style: orgLabel(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kOrgSurfaceWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kOrgBorder),
                    ),
                    child: TextField(
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      style: orgBody(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search programs by title or field of study...',
                        hintStyle:
                            orgBody(fontSize: 12, color: kOrgTextMuted),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: kOrgTextMuted),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Scholarship Cards List
                  if (filteredScholarships.isEmpty)
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
                          Icon(Icons.school_outlined,
                              size: 48,
                              color: kOrgTextMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('No scholarship programs yet',
                              style: orgHeadline(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            'Create your first scholarship program to begin receiving and reviewing student applications.',
                            style: orgBody(
                                fontSize: 13, color: kOrgTextSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kOrgPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _openCreateScreen,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Create Scholarship'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredScholarships.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final scholarship = filteredScholarships[index];
                        final targetApps = apps
                            .where((a) => a.scholarshipId == scholarship.id)
                            .toList();
                        final approvedApps = targetApps
                            .where((a) =>
                                a.status == ApplicationStatus.approved ||
                                a.status == ApplicationStatus.awarded)
                            .length;
                        final totalSlots = scholarship.slots ?? 50;

                        return _buildScholarshipCard(
                          scholarship: scholarship,
                          applicantCount: targetApps.length,
                          approvedCount: approvedApps,
                          totalSlots: totalSlots,
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

  Widget _buildScholarshipCard({
    required Scholarship scholarship,
    required int applicantCount,
    required int approvedCount,
    required int totalSlots,
    required bool isDesktop,
  }) {
    final daysLeft = scholarship.deadline.difference(DateTime.now()).inDays;
    final isExpired = daysLeft < 0;
    final fillRatio = totalSlots > 0 ? (approvedCount / totalSlots).clamp(0.0, 1.0) : 0.0;
    final fillPercent = (fillRatio * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrgBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left Accent Border (Bridge Green)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: kOrgPrimary,
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isDesktop ? 22 : 18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? kOrgBadgeRejectedBg
                            : kOrgBadgeApprovedBg,
                        borderRadius: BorderRadius.circular(4),
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
                            isExpired
                                ? 'Application Closed'
                                : 'Accepting Applications',
                            style: orgLabel(
                              fontSize: 10,
                              color: isExpired
                                  ? kOrgBadgeRejectedText
                                  : kOrgBadgeApprovedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: daysLeft <= 7
                              ? kOrgBadgeRejectedBg
                              : kOrgCanvas,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: kOrgBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: daysLeft <= 7 ? kOrgError : kOrgTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$daysLeft days remaining',
                              style: orgLabel(
                                fontSize: 10,
                                color:
                                    daysLeft <= 7 ? kOrgError : kOrgTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: kOrgTextSecondary),
                      tooltip: 'Edit Scholarship Criteria',
                      onPressed: () => _openEditScreen(scholarship),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title & Description
                Text(scholarship.title, style: orgHeadline(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  scholarship.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: kOrgBorder),
                const SizedBox(height: 14),

                // Metrics Row (Endowment, Quota Bar, Target Scope)
                isDesktop
                    ? Row(
                        children: [
                          // 1. Grant Value
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GRANT VALUE',
                                    style: orgLabel(
                                        fontSize: 10, color: kOrgTextMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  scholarship.slots != null
                                      ? '₱50,000 / Sem'
                                      : 'Full Grant',
                                  style: orgHeadline(
                                      fontSize: 16, color: kOrgPrimary),
                                ),
                                Text('Per academic year',
                                    style: orgBody(
                                        fontSize: 11,
                                        color: kOrgTextSecondary)),
                              ],
                            ),
                          ),
                          // 2. Quota Capacity Bar
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('QUOTA CAPACITY',
                                        style: orgLabel(
                                            fontSize: 10, color: kOrgTextMuted)),
                                    Text('$fillPercent% filled',
                                        style: orgLabel(
                                            fontSize: 10,
                                            color: kOrgPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('$approvedCount',
                                        style: orgHeadline(fontSize: 16)),
                                    Text(' / $totalSlots slots',
                                        style: orgBody(
                                            fontSize: 11,
                                            color: kOrgTextSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fillRatio,
                                    minHeight: 6,
                                    backgroundColor: kOrgCanvas,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            kOrgPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 3. Target Scope
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TARGET SCOPE',
                                    style: orgLabel(
                                        fontSize: 10, color: kOrgTextMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  scholarship.requiredCourses?.isNotEmpty == true
                                      ? scholarship.requiredCourses!.join(', ')
                                      : 'General Academic',
                                  overflow: TextOverflow.ellipsis,
                                  style: orgHeadline(fontSize: 13),
                                ),
                                Text(
                                  'GWA ≤ ${scholarship.minGpa.toStringAsFixed(2)} requirement',
                                  style: orgBody(
                                      fontSize: 11, color: kOrgTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          // 4. Action Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kOrgPrimary,
                              side: const BorderSide(color: kOrgPrimary),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              widget.onViewApplicationsForScholarship
                                  ?.call(scholarship.id);
                            },
                            icon: const Icon(Icons.people_outline_rounded,
                                size: 16),
                            label: Text('View Applicants ($applicantCount)'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GRANT VALUE',
                                      style: orgLabel(
                                          fontSize: 10, color: kOrgTextMuted)),
                                  Text(
                                    scholarship.slots != null
                                        ? '₱50,000 / Sem'
                                        : 'Full Grant',
                                    style: orgHeadline(
                                        fontSize: 16, color: kOrgPrimary),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('QUOTA',
                                      style: orgLabel(
                                          fontSize: 10, color: kOrgTextMuted)),
                                  Text('$approvedCount / $totalSlots slots',
                                      style: orgHeadline(fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fillRatio,
                              minHeight: 6,
                              backgroundColor: kOrgCanvas,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  kOrgPrimary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kOrgPrimary,
                                side: const BorderSide(color: kOrgPrimary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                widget.onViewApplicationsForScholarship
                                    ?.call(scholarship.id);
                              },
                              icon: const Icon(Icons.people_outline_rounded,
                                  size: 16),
                              label: Text('View Applicants ($applicantCount)'),
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
}
