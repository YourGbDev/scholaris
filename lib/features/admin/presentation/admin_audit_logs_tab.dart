import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import '../repositories/admin_audit_log_repository.dart';
import 'admin_audit_logs_provider.dart';
import 'admin_theme.dart';

class AdminAuditLogsTab extends ConsumerStatefulWidget {
  const AdminAuditLogsTab({super.key});

  @override
  ConsumerState<AdminAuditLogsTab> createState() => _AdminAuditLogsTabState();
}

class _AdminAuditLogsTabState extends ConsumerState<AdminAuditLogsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final searchQuery = ref.watch(adminAuditLogSearchQueryProvider);
    final actionFilter = ref.watch(adminAuditLogActionFilterProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Search / Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Audit Ledger',
                style: adminHeaderStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kAdminNavyTrust,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Immutable tracking of administrative actions, status transitions, and provider approvals.',
                style: adminLabelStyle(
                  fontSize: 13,
                  color: kAdminTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // Live Status Badge & Readiness Verification
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: kAdminBridgeGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Audit logging infrastructure readiness',
                      style: adminLabelStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kAdminNavyTrust,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kAdminBridgeGreen.withValues(alpha: 0.12),
                      borderRadius: kAdminPillRadius,
                    ),
                    child: Text(
                      'Active',
                      style: adminLabelStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kAdminBridgeGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Search Input Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: adminBodyStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by actor, action, or target ID...',
                          hintStyle: adminLabelStyle(
                            fontSize: 13,
                            color: kAdminTextSecondary.withValues(alpha: 0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: kAdminTextSecondary,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: kAdminTextSecondary,
                                  ),
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(
                                            adminAuditLogSearchQueryProvider.notifier)
                                        .state = '';
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          filled: true,
                          fillColor: Colors.white,
                          border: const OutlineInputBorder(
                            borderRadius: kAdminCardRadius,
                            borderSide:
                                BorderSide(color: kAdminHairline, width: 1),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: kAdminCardRadius,
                            borderSide:
                                BorderSide(color: kAdminHairline, width: 1),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: kAdminCardRadius,
                            borderSide:
                                BorderSide(color: kAdminBridgeGreen, width: 1.5),
                          ),
                        ),
                        onChanged: (val) => ref
                            .read(adminAuditLogSearchQueryProvider.notifier)
                            .state = val.trim().toLowerCase(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh logs',
                    color: kAdminNavyTrust,
                    onPressed: () => ref.invalidate(adminAuditLogsProvider),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Action Filters Scroll Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterSegment(
                      label: 'All',
                      selected: actionFilter == 'all',
                      onTap: () => ref
                          .read(adminAuditLogActionFilterProvider.notifier)
                          .state = 'all',
                    ),
                    const SizedBox(width: 6),
                    _FilterSegment(
                      label: 'Users',
                      selected: actionFilter == 'users',
                      onTap: () => ref
                          .read(adminAuditLogActionFilterProvider.notifier)
                          .state = 'users',
                    ),
                    const SizedBox(width: 6),
                    _FilterSegment(
                      label: 'Security',
                      selected: actionFilter == 'security',
                      onTap: () => ref
                          .read(adminAuditLogActionFilterProvider.notifier)
                          .state = 'security',
                    ),
                    const SizedBox(width: 6),
                    _FilterSegment(
                      label: 'Providers',
                      selected: actionFilter == 'providers',
                      onTap: () => ref
                          .read(adminAuditLogActionFilterProvider.notifier)
                          .state = 'providers',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Data Body
        Expanded(
          child: logsAsync.when(
            loading: () => const LoadingView(),
            error: (_, _) => const ErrorView(
              message: 'Failed to load system audit ledger.',
            ),
            data: (allLogs) {
              var list = allLogs;
              if (searchQuery.isNotEmpty) {
                list = list.where((log) {
                  final actorMatch = (log.actorEmail ?? '')
                          .toLowerCase()
                          .contains(searchQuery) ||
                      (log.actorId ?? '').toLowerCase().contains(searchQuery);
                  final actionMatch =
                      log.action.toLowerCase().contains(searchQuery);
                  final targetMatch =
                      (log.targetId ?? '').toLowerCase().contains(searchQuery) ||
                          log.targetType.toLowerCase().contains(searchQuery);
                  return actorMatch || actionMatch || targetMatch;
                }).toList();
              }

              if (actionFilter != 'all') {
                if (actionFilter == 'users') {
                  list = list
                      .where((l) =>
                          l.targetType == 'user' ||
                          l.action.startsWith('user_') ||
                          l.action.contains('role'))
                      .toList();
                } else if (actionFilter == 'security') {
                  list = list
                      .where((l) =>
                          l.action.contains('lockout') ||
                          l.action.contains('login') ||
                          l.action.contains('auth'))
                      .toList();
                } else if (actionFilter == 'providers') {
                  list = list
                      .where((l) =>
                          l.targetType == 'provider' ||
                          l.action.contains('provider'))
                      .toList();
                }
              }

              if (list.isEmpty) {
                return const EmptyView(
                  icon: Icons.fact_check_outlined,
                  title: 'No audit logs found',
                  message: 'No events match the current filter or search criteria.',
                );
              }

              // Responsive Rendering: Wide table on Desktop (>= 768px), fluid card feed on Mobile (< 768px)
              if (isDesktop) {
                return _buildDesktopTable(context, list);
              } else {
                return _buildMobileCardFeed(context, list);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<AuditLog> list) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
      child: Container(
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
                      'Timestamp',
                      style: adminLabelStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kAdminNavyTrust,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Action',
                      style: adminLabelStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kAdminNavyTrust,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Target',
                      style: adminLabelStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kAdminNavyTrust,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Actor',
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
                      'Role',
                      style: adminLabelStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kAdminNavyTrust,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Details',
                      textAlign: TextAlign.center,
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
            // Table Rows
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: kAdminHairline),
                itemBuilder: (context, i) {
                  final log = list[i];
                  final formattedTime = _formatTimestamp(log.createdAt);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            formattedTime,
                            style: adminDataMono(
                              fontSize: 11,
                              color: kAdminTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildActionBadge(log.action),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${log.targetType}${log.targetId != null ? ': ${log.targetId}' : ''}',
                            style: adminBodyStyle(
                              fontSize: 12,
                              color: kAdminNavyTrust,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            log.actorEmail ?? log.actorId ?? 'System',
                            style: adminBodyStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: kAdminNavyTrust,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.12),
                                borderRadius: kAdminPillRadius,
                              ),
                              child: Text(
                                log.actorRole,
                                style: adminLabelStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kAdminTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _showLogDetails(context, log),
                              child: Text(
                                'Inspect',
                                style: adminLabelStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kAdminBridgeGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCardFeed(BuildContext context, List<AuditLog> list) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final log = list[i];
        final formattedTime = _formatTimestamp(log.createdAt);

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: kAdminCardRadius,
            side: BorderSide(color: kAdminHairline, width: 1),
          ),
          child: InkWell(
            borderRadius: kAdminCardRadius,
            onTap: () => _showLogDetails(context, log),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: _buildActionBadge(log.action),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: adminDataMono(
                          fontSize: 11,
                          color: kAdminTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Target: ',
                        style: adminLabelStyle(
                          fontSize: 12,
                          color: kAdminTextSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${log.targetType}${log.targetId != null ? ' (${log.targetId})' : ''}',
                          style: adminBodyStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kAdminNavyTrust,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Actor: ',
                        style: adminLabelStyle(
                          fontSize: 12,
                          color: kAdminTextSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${log.actorEmail ?? log.actorId ?? 'System'} (${log.actorRole})',
                          style: adminBodyStyle(
                            fontSize: 12,
                            color: kAdminNavyTrust,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showLogDetails(context, log),
                        child: Text(
                          'Inspect',
                          style: adminLabelStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kAdminBridgeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBadge(String action) {
    Color bg;
    Color fg;

    if (action.contains('create')) {
      bg = kAdminBridgeGreen.withValues(alpha: 0.12);
      fg = kAdminBridgeGreen;
    } else if (action.contains('delete') || action.contains('deactivat')) {
      bg = kAdminCoralConnect.withValues(alpha: 0.12);
      fg = kAdminCoralConnect;
    } else if (action.contains('role') || action.contains('update')) {
      bg = kAdminNavyTrust.withValues(alpha: 0.10);
      fg = kAdminNavyTrust;
    } else if (action.contains('lock') || action.contains('fail')) {
      bg = kAdminGoldenOpportunity.withValues(alpha: 0.15);
      fg = const Color(0xFFB28109);
    } else {
      bg = Colors.grey.withValues(alpha: 0.12);
      fg = kAdminNavyTrust;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: kAdminPillRadius,
      ),
      child: Text(
        action,
        style: adminLabelStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  void _showLogDetails(BuildContext context, AuditLog log) {
    String formattedJson;
    try {
      formattedJson =
          const JsonEncoder.withIndent('  ').convert(log.details);
    } catch (_) {
      formattedJson = log.details.toString();
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        shape: const RoundedRectangleBorder(borderRadius: kAdminChromeRadius),
        title: isDesktop
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      'Audit Event Details',
                      style: adminHeaderStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildActionBadge(log.action),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Audit Event Details',
                    style: adminHeaderStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildActionBadge(log.action),
                  ),
                ],
              ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(context, 'Event ID', log.id),
                _detailRow(context, 'Timestamp', log.createdAt.toIso8601String()),
                _detailRow(context, 'Action', log.action),
                _detailRow(context, 'Target Type', log.targetType),
                _detailRow(context, 'Target ID', log.targetId ?? 'N/A'),
                _detailRow(context, 'Actor Email', log.actorEmail ?? 'N/A'),
                _detailRow(context, 'Actor ID', log.actorId ?? 'N/A'),
                _detailRow(context, 'Actor Role', log.actorRole),
                _detailRow(context, 'IP Address', log.ipAddress ?? 'N/A'),
                const SizedBox(height: 12),
                Text(
                  'Event Payload & Metadata',
                  style: adminLabelStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kAdminNavyTrust,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: kAdminCardRadius,
                    border: Border.all(color: kAdminHairline, width: 1),
                  ),
                  child: SelectableText(
                    formattedJson,
                    style: adminDataMono(
                      fontSize: 12,
                      color: kAdminNavyTrust,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Close',
              style: adminLabelStyle(fontSize: 13, color: kAdminNavyTrust),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    if (!isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: adminLabelStyle(fontSize: 11, color: kAdminTextSecondary),
            ),
            const SizedBox(height: 2),
            SelectableText(
              value,
              style: adminBodyStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kAdminNavyTrust,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: adminLabelStyle(fontSize: 12, color: kAdminTextSecondary),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: adminBodyStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kAdminNavyTrust,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSegment extends StatelessWidget {
  const _FilterSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? kAdminBridgeGreen.withValues(alpha: 0.08) : Colors.white,
      borderRadius: kAdminPillRadius,
      child: InkWell(
        borderRadius: kAdminPillRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: kAdminPillRadius,
            border: Border.all(
              color: selected ? kAdminBridgeGreen : kAdminHairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: adminLabelStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? kAdminBridgeGreen : kAdminNavyTrust,
            ),
          ),
        ),
      ),
    );
  }
}
