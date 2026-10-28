// lib/features/provider/presentation/org/org_team_view.dart
//
// Institutional Organization Team & Reviewers Management View.
// Displays active staff roster (Org Admins, Evaluators, Finance Officers)
// and reviewer scholarship assignments.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/theme/app_motion.dart';

import '../../providers/provider_scholarships_provider.dart';
import '../../models/organization_team_member.dart';
import '../../providers/organization_team_provider.dart';
import 'org_provider_theme.dart';
import '../widgets/org_summary_disclosure.dart';
import '../widgets/org_metric_count.dart';
import 'widgets/assign_reviewer_dialog.dart';

class OrgTeamView extends ConsumerStatefulWidget {
  const OrgTeamView({super.key});

  @override
  ConsumerState<OrgTeamView> createState() => _OrgTeamViewState();
}

class _OrgTeamViewState extends ConsumerState<OrgTeamView> {
  String _searchQuery = '';
  String? _selectedRoleFilter;

  Future<void> _openScholarshipAssignmentPicker(
    OrganizationTeamMember reviewer,
  ) async {
    final scholarships = await ref.read(providerScholarshipsProvider.future);
    if (!mounted) return;

    if (scholarships.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No scholarships available to assign.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: const Color(0x33000000),
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Select Grant Program for ${reviewer.fullName}',
            style: orgHeadline(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 400,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: scholarships.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: kOrgHairline),
              itemBuilder: (c, i) {
                final s = scholarships[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.school_outlined,
                    color: kOrgPrimary,
                  ),
                  title: Text(
                    s.title,
                    style: orgHeadline(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '₱${s.awardAmount} / yr',
                    style: orgBody(fontSize: 11.5, color: kOrgTextSecondary),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    AssignReviewerDialog.show(context, s);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(organizationRosterProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Container(
      color: kOrgCanvas,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(organizationRosterProvider);
          await ref.read(organizationRosterProvider.future);
        },
        color: kOrgPrimary,
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
              // Header
              _buildHeader(isDesktop),
              const SizedBox(height: 20),

              // Roster Content
              rosterAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kOrgHairline),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 36,
                          color: kOrgError,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Could not load team roster',
                          style: orgHeadline(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kOrgTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check your connection and try again.',
                          style: orgBody(
                            fontSize: 12,
                            color: kOrgTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(organizationRosterProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (roster) {
                  final totalMembers = roster.length;
                  final reviewersCount = roster
                      .where((m) => m.isReviewer && m.active)
                      .length;
                  final financeCount = roster
                      .where((m) => m.isFinance && m.active)
                      .length;
                  final adminCount = roster
                      .where((m) => m.isOrgAdmin && m.active)
                      .length;

                  var filtered = roster;
                  if (_selectedRoleFilter != null) {
                    filtered = filtered
                        .where((m) => m.role == _selectedRoleFilter)
                        .toList();
                  }

                  if (_searchQuery.trim().isNotEmpty) {
                    final q = _searchQuery.trim().toLowerCase();
                    filtered = filtered.where((m) {
                      return m.fullName.toLowerCase().contains(q) ||
                          m.roleDisplay.toLowerCase().contains(q);
                    }).toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bento Summary Cards
                      OrgSummaryDisclosure(
                        title: 'Team summary',
                        summary:
                            '$totalMembers members · $reviewersCount active reviewers',
                        child: _buildBentoRow(
                          totalMembers: totalMembers,
                          reviewersCount: reviewersCount,
                          financeCount: financeCount,
                          adminCount: adminCount,
                          isDesktop: isDesktop,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Filter Toolbar
                      _buildToolbar(),
                      const SizedBox(height: 18),

                      // Team Roster Cards
                      if (filtered.isEmpty)
                        _buildEmptyState()
                      else
                        _buildRosterList(filtered, isDesktop: isDesktop),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(
              'ORGANIZATION ROSTER & ASSIGNMENTS'.toUpperCase(),
              style: orgLabel(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kOrgPrimary,
                letterSpacing: 0.6,
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: kOrgPrimary,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              'ACTIVE TEAM',
              style: orgLabel(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: kOrgPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Team & Reviewers',
          style: orgHeadline(
            fontSize: isDesktop ? 32 : 26,
            fontWeight: FontWeight.w700,
            color: kOrgTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your team and scholarship review assignments.',
          style: orgBody(fontSize: 13, color: kOrgTextSecondary),
        ),
      ],
    );
  }

  Widget _buildBentoRow({
    required int totalMembers,
    required int reviewersCount,
    required int financeCount,
    required int adminCount,
    required bool isDesktop,
  }) {
    final cardTotal = _buildMetricCard(
      title: 'TOTAL STAFF',
      value: '$totalMembers',
      subtitle: 'Registered org members',
      icon: Icons.groups_rounded,
      color: kOrgPrimary,
    );

    final cardReviewers = _buildMetricCard(
      title: 'EVALUATORS',
      value: '$reviewersCount',
      subtitle: 'Active triage reviewers',
      icon: Icons.rate_review_rounded,
      color: const Color(0xFF0058BC),
    );

    final cardFinance = _buildMetricCard(
      title: 'DISBURSING',
      value: '$financeCount',
      subtitle: 'Financial ledger officers',
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF0F4D2E),
    );

    final cardAdmins = _buildMetricCard(
      title: 'ADMINS',
      value: '$adminCount',
      subtitle: 'Full decisioning authority',
      icon: Icons.shield_rounded,
      color: const Color(0xFF7B1FA2),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: cardTotal),
          const SizedBox(width: 14),
          Expanded(child: cardReviewers),
          const SizedBox(width: 14),
          Expanded(child: cardFinance),
          const SizedBox(width: 14),
          Expanded(child: cardAdmins),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cardTotal),
              const SizedBox(width: 12),
              Expanded(child: cardReviewers),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cardFinance),
              const SizedBox(width: 12),
              Expanded(child: cardAdmins),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 1),
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
                    color: kOrgTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          OrgMetricCount(
            motionId: 'team.$title',
            targetValue: int.parse(value),
            style: orgHeadline(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kOrgTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: orgBody(fontSize: 11, color: kOrgTextSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final roleFilters = [
      (label: 'All Roles', value: null),
      (label: 'Evaluators', value: 'reviewer'),
      (label: 'Finance', value: 'finance'),
      (label: 'Org Admins', value: 'org_admin'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
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
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: orgBody(fontSize: 13, color: kOrgTextPrimary),
              decoration: InputDecoration(
                hintText: 'Search staff by name or role...',
                hintStyle: orgBody(fontSize: 12.5, color: kOrgTextSecondary),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: kOrgTextSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: roleFilters.map((opt) {
                final isSelected = _selectedRoleFilter == opt.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      opt.label,
                      style: orgLabel(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : kOrgTextPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: kOrgPrimary,
                    backgroundColor: const Color(0xFFF4F3F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? kOrgPrimary : Colors.transparent,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedRoleFilter = opt.value;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEDF3)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.group_off_rounded,
              size: 42,
              color: kOrgTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No Members Found',
              style: orgHeadline(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kOrgTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No team members match the search query or selected role filter.',
              style: orgBody(fontSize: 12, color: kOrgTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterList(
    List<OrganizationTeamMember> members, {
    required bool isDesktop,
  }) {
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 72, color: kOrgHairline),
        itemBuilder: (context, index) {
          final member = members[index];

          Color roleBadgeBg;
          Color roleBadgeText;
          if (member.isOrgAdmin) {
            roleBadgeBg = const Color(0xFFF3E5F5);
            roleBadgeText = const Color(0xFF7B1FA2);
          } else if (member.isFinance) {
            roleBadgeBg = const Color(0xFFE8F5E9);
            roleBadgeText = const Color(0xFF0F4D2E);
          } else {
            roleBadgeBg = const Color(0xFFE3F2FD);
            roleBadgeText = const Color(0xFF0058BC);
          }

          final assignButton = (member.isReviewer && member.active)
              ? OutlinedButton.icon(
                  onPressed: () => _openScholarshipAssignmentPicker(member),
                  icon: const Icon(Icons.assignment_ind_rounded, size: 15),
                  label: Text(
                    'Assign Grants',
                    style: orgLabel(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kOrgPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kOrgPrimary,
                    side: const BorderSide(color: kOrgPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                )
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: member.isOrgAdmin
                      ? kOrgPrimary
                      : member.isFinance
                      ? const Color(0xFF0F4D2E)
                      : const Color(0xFF0058BC),
                  child: Text(
                    member.fullName.isNotEmpty
                        ? member.fullName[0].toUpperCase()
                        : 'M',
                    style: orgLabel(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            member.fullName,
                            style: orgHeadline(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kOrgTextPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleBadgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member.roleDisplay.toUpperCase(),
                              style: orgLabel(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: roleBadgeText,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: member.active
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member.active ? 'ACTIVE' : 'INACTIVE',
                              style: orgLabel(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: member.active
                                    ? const Color(0xFF0F4D2E)
                                    : kOrgError,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        member.isReviewer
                            ? '${member.assignedScholarshipCount} scholarship grant${member.assignedScholarshipCount == 1 ? "" : "s"} assigned for review'
                            : 'Organization Member • User ID: #${member.userId.substring(0, member.userId.length > 8 ? 8 : member.userId.length)}',
                        style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                      ),
                      if (assignButton != null && !isDesktop) ...[
                        const SizedBox(height: 8),
                        assignButton,
                      ],
                    ],
                  ),
                ),
                if (assignButton != null && isDesktop) ...[
                  const SizedBox(width: 8),
                  assignButton,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
