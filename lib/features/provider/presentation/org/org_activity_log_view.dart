// lib/features/provider/presentation/org/org_activity_log_view.dart
//
// Institutional Organization Activity Log Tab View.
// Displays an immutable audit trail of evaluations, endorsements, approvals,
// and reviewer assignments within the grantor organization.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../models/organization_activity_log.dart';
import '../../providers/organization_activity_provider.dart';
import 'org_provider_theme.dart';

class OrgActivityLogView extends ConsumerStatefulWidget {
  const OrgActivityLogView({super.key});

  @override
  ConsumerState<OrgActivityLogView> createState() => _OrgActivityLogViewState();
}

class _OrgActivityLogViewState extends ConsumerState<OrgActivityLogView> {
  String _searchQuery = '';
  String? _selectedActionFilter;

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = monthNames[dt.month - 1];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$m ${dt.day}, ${dt.year} • $hour:$minute $ampm';
  }

  (IconData, Color) _getActionVisuals(String action) {
    final a = action.toLowerCase();
    if (a.contains('approve')) {
      return (Icons.check_circle_outline_rounded, kOrgPrimary);
    }
    if (a.contains('reject')) {
      return (Icons.cancel_outlined, kOrgError);
    }
    if (a.contains('endorse')) {
      return (Icons.rate_review_outlined, const Color(0xFF0058BC));
    }
    if (a.contains('assign')) {
      return (Icons.assignment_ind_outlined, const Color(0xFF00796B));
    }
    if (a.contains('unassign')) {
      return (Icons.person_remove_outlined, const Color(0xFFD97706));
    }
    if (a.contains('create') || a.contains('update')) {
      return (Icons.edit_note_rounded, const Color(0xFF5A645C));
    }
    return (Icons.history_rounded, kOrgTextSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(organizationActivityLogsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Container(
      color: kOrgCanvas,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(organizationActivityLogsProvider);
          await ref.read(organizationActivityLogsProvider.future);
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
              // Header Section
              _buildHeader(isDesktop),
              const SizedBox(height: 20),

              // Filter & Search Toolbar
              _buildToolbar(isDesktop),
              const SizedBox(height: 18),

              // Activity Log List
              logsAsync.when(
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
                        const Icon(Icons.error_outline_rounded,
                            size: 36, color: kOrgError),
                        const SizedBox(height: 10),
                        Text(
                          'Could not load activity logs',
                          style: orgHeadline(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kOrgTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          err.toString(),
                          style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                data: (logs) {
                  var filtered = logs;
                  if (_selectedActionFilter != null) {
                    final target = _selectedActionFilter!.toLowerCase();
                    filtered = filtered
                        .where((log) => log.action.toLowerCase().contains(target))
                        .toList();
                  }

                  if (_searchQuery.trim().isNotEmpty) {
                    final q = _searchQuery.trim().toLowerCase();
                    filtered = filtered.where((log) {
                      final matchActor = log.actorName.toLowerCase().contains(q);
                      final matchAction = log.action.toLowerCase().contains(q);
                      final matchTarget = log.targetType.toLowerCase().contains(q);
                      final matchDetails = log.details.toString().toLowerCase().contains(q);
                      return matchActor || matchAction || matchTarget || matchDetails;
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildLogList(filtered);
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
              'GOVERNANCE & AUDIT TRAIL',
              style: orgLabel(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kOrgPrimary,
                letterSpacing: 0.6,
              ),
            ),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: kOrgPrimary,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              'LIVE LEDGER',
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
          'Organization Activity Log',
          style: orgHeadline(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.w700,
            color: kOrgTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Immutable chronological record of administrative deliberations, endorsements, approvals, and reviewer assignments.',
          style: orgBody(
            fontSize: 13,
            color: kOrgTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isDesktop) {
    final filterOptions = [
      (label: 'All Actions', value: null),
      (label: 'Approvals', value: 'approve'),
      (label: 'Endorsements', value: 'endorse'),
      (label: 'Rejections', value: 'reject'),
      (label: 'Assignments', value: 'assign'),
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
          // Search row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F3F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: orgBody(fontSize: 13, color: kOrgTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by staff name, action, or target ID...',
                      hintStyle: orgBody(fontSize: 12.5, color: kOrgTextSecondary),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: kOrgTextSecondary),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((opt) {
                final isSelected = _selectedActionFilter == opt.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      opt.label,
                      style: orgLabel(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                        _selectedActionFilter = opt.value;
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
            const Icon(Icons.receipt_long_outlined,
                size: 42, color: kOrgTextSecondary),
            const SizedBox(height: 12),
            Text(
              'No Activity Recorded',
              style: orgHeadline(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kOrgTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Administrative and review decisions will automatically stream into this immutable audit log.',
              style: orgBody(fontSize: 12, color: kOrgTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList(List<OrganizationActivityLog> logs) {
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
        itemCount: logs.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 68, color: kOrgHairline),
        itemBuilder: (context, index) {
          final log = logs[index];
          final (actionIcon, actionColor) = _getActionVisuals(log.action);
          final timestampStr = _formatTimestamp(log.createdAt);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(actionIcon, size: 20, color: actionColor),
                  ),
                ),
                const SizedBox(width: 14),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  log.actorName,
                                  style: orgHeadline(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: kOrgTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    log.action.toUpperCase(),
                                    style: orgLabel(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: actionColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timestampStr,
                            style: orgLabel(
                              fontSize: 11,
                              color: kOrgTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Target: ${log.targetType}${log.targetId != null ? " • #${log.targetId!.substring(0, log.targetId!.length > 8 ? 8 : log.targetId!.length)}" : ""}',
                        style: orgBody(
                          fontSize: 12,
                          color: kOrgTextSecondary,
                        ),
                      ),
                      if (log.details.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.details.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('  •  '),
                            style: orgBody(
                              fontSize: 11.5,
                              color: const Color(0xFF404942),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
