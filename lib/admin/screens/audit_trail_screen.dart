// lib/admin/screens/audit_trail_screen.dart
//
// Admin Console: System Audit Trail (Screen 4 Rebuild)
// Visual tokens: scholaris_sequoia/DESIGN.md
// Strictly real data: 100% wired to public.audit_logs.
// Zero fabricated metrics, zero fake compliance stamps, zero fake log entries.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// 1. Domain Model: AuditLogEntry
// =============================================================================

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorEmail,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    required this.ipAddress,
    required this.createdAt,
  });

  final String id;
  final String? actorId;
  final String? actorEmail;
  final String actorRole;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final DateTime createdAt;

  factory AuditLogEntry.fromMap(Map<String, dynamic> row) {
    Map<String, dynamic>? detailsMap;
    final rawDetails = row['details'];
    if (rawDetails != null) {
      if (rawDetails is Map<String, dynamic>) {
        detailsMap = rawDetails;
      } else if (rawDetails is String && rawDetails.isNotEmpty) {
        try {
          detailsMap = jsonDecode(rawDetails) as Map<String, dynamic>?;
        } catch (_) {}
      }
    }

    final createdAtStr = row['created_at'] as String?;
    final createdAt = createdAtStr != null && createdAtStr.isNotEmpty
        ? DateTime.parse(createdAtStr)
        : DateTime.now();

    return AuditLogEntry(
      id: row['id'] as String,
      actorId: row['actor_id'] as String?,
      actorEmail: row['actor_email'] as String?,
      actorRole: row['actor_role'] as String? ?? 'system',
      action: row['action'] as String? ?? 'unknown',
      targetType: row['target_type'] as String? ?? 'unknown',
      targetId: row['target_id'] as String?,
      details: detailsMap,
      ipAddress: row['ip_address'] as String?,
      createdAt: createdAt,
    );
  }
}

// =============================================================================
// 2. Data Providers
// =============================================================================

final auditTrailLogsProvider =
    FutureProvider<List<AuditLogEntry>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('audit_logs')
      .select('*')
      .order('created_at', ascending: false);

  final list = List<Map<String, dynamic>>.from(response);
  return list.map(AuditLogEntry.fromMap).toList();
});

final auditRoleFilterProvider = StateProvider<String>((ref) => 'all');
final auditActionFilterProvider = StateProvider<String>((ref) => 'all');
final auditSearchQueryProvider = StateProvider<String>((ref) => '');
final auditDateFromProvider = StateProvider<DateTime?>((ref) => null);
final auditDateToProvider = StateProvider<DateTime?>((ref) => null);

// =============================================================================
// 3. UI Component: AuditTrailScreen
// =============================================================================

class AuditTrailScreen extends ConsumerStatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  ConsumerState<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends ConsumerState<AuditTrailScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Formatting Helpers ---------------------------------------------------

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final local = dt.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$minute $ampm';
  }

  String _formatDateShort(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _truncateId(String? id) {
    if (id == null || id.isEmpty) return '—';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  void _clearFilters() {
    ref.read(auditRoleFilterProvider.notifier).state = 'all';
    ref.read(auditActionFilterProvider.notifier).state = 'all';
    ref.read(auditSearchQueryProvider.notifier).state = '';
    ref.read(auditDateFromProvider.notifier).state = null;
    ref.read(auditDateToProvider.notifier).state = null;
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditTrailLogsProvider);
    final roleFilter = ref.watch(auditRoleFilterProvider);
    final actionFilter = ref.watch(auditActionFilterProvider);
    final searchQuery = ref.watch(auditSearchQueryProvider);
    final dateFrom = ref.watch(auditDateFromProvider);
    final dateTo = ref.watch(auditDateToProvider);

    return Scaffold(
      backgroundColor: kSeqSurface,
      body: logsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: kSeqPrimaryContainer,
            strokeWidth: 2.5,
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: kSeqError),
                const SizedBox(height: 12),
                Text(
                  'Failed to load audit logs',
                  style: seqHeadlineSm(color: kSeqOnSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  err.toString(),
                  style: seqBodyMd(color: kSeqOnSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(auditTrailLogsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSeqPrimary,
                    foregroundColor: kSeqOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (allLogs) {
          // Dynamic roles and actions present in real data
          final dynamicRoles = <String>{
            for (final l in allLogs) l.actorRole
          }.toList()
            ..sort();

          final dynamicActions = <String>{
            for (final l in allLogs) l.action
          }.toList()
            ..sort();

          // Client-side filtering
          final filtered = allLogs.where((log) {
            // Role filter
            if (roleFilter != 'all' && log.actorRole != roleFilter) {
              return false;
            }

            // Action filter
            if (actionFilter != 'all' && log.action != actionFilter) {
              return false;
            }

            // Search query filter
            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              final matchesAction = log.action.toLowerCase().contains(q);
              final matchesTargetType =
                  log.targetType.toLowerCase().contains(q);
              final matchesTargetId =
                  (log.targetId ?? '').toLowerCase().contains(q);
              final matchesActor =
                  (log.actorEmail ?? '').toLowerCase().contains(q);
              final matchesIp =
                  (log.ipAddress ?? '').toLowerCase().contains(q);

              if (!matchesAction &&
                  !matchesTargetType &&
                  !matchesTargetId &&
                  !matchesActor &&
                  !matchesIp) {
                return false;
              }
            }

            // Date Range
            if (dateFrom != null) {
              final startOfDay =
                  DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
              if (log.createdAt.isBefore(startOfDay)) return false;
            }
            if (dateTo != null) {
              final endOfDay =
                  DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
              if (log.createdAt.isAfter(endOfDay)) return false;
            }

            return true;
          }).toList();

          return RefreshIndicator(
            color: kSeqPrimaryContainer,
            onRefresh: () async {
              ref.invalidate(auditTrailLogsProvider);
              await ref.read(auditTrailLogsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildHeaderBar(context, totalCount: allLogs.length),
                const SizedBox(height: 16),
                _buildFilterRow(
                  context,
                  dynamicRoles: dynamicRoles,
                  dynamicActions: dynamicActions,
                  activeRole: roleFilter,
                  activeAction: actionFilter,
                  dateFrom: dateFrom,
                  dateTo: dateTo,
                  searchQuery: searchQuery,
                  hasActiveFilters: roleFilter != 'all' ||
                      actionFilter != 'all' ||
                      searchQuery.isNotEmpty ||
                      dateFrom != null ||
                      dateTo != null,
                ),
                const SizedBox(height: 16),
                _buildLogList(context, logs: filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Header Bar -----------------------------------------------------------

  Widget _buildHeaderBar(BuildContext context, {required int totalCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live data badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kSeqSurfaceContainerHighest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: kSeqPrimaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live data',
                style: seqLabelSm(
                  color: kSeqOnSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Title
        Text(
          'System Audit Trail',
          style: seqHeadlineLg(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),

        // Subtitle: strictly live database count
        Text(
          '$totalCount audit events',
          style: seqBodyMd(color: kSeqOnSurfaceVariant),
        ),
      ],
    );
  }

  // --- Filter Row -----------------------------------------------------------

  Widget _buildFilterRow(
    BuildContext context, {
    required List<String> dynamicRoles,
    required List<String> dynamicActions,
    required String activeRole,
    required String activeAction,
    required DateTime? dateFrom,
    required DateTime? dateTo,
    required String searchQuery,
    required bool hasActiveFilters,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          SizedBox(
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(auditSearchQueryProvider.notifier).state = val.trim();
              },
              style: seqBodyMd(),
              decoration: InputDecoration(
                hintText:
                    'Search by action, target, actor email, or IP address...',
                hintStyle: seqBodyMd(color: kSeqOutline),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: kSeqOutline,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(auditSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: kSeqSurfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: kSeqOutlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: kSeqOutlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: kSeqPrimaryContainer,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filters row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Actor Role dropdown
              _buildDropdownFilter(
                label: 'Role',
                value: activeRole,
                items: ['all', ...dynamicRoles],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(auditRoleFilterProvider.notifier).state = val;
                  }
                },
              ),

              // Action dropdown
              _buildDropdownFilter(
                label: 'Action',
                value: activeAction,
                items: ['all', ...dynamicActions],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(auditActionFilterProvider.notifier).state = val;
                  }
                },
              ),

              // Date Range Button
              OutlinedButton.icon(
                onPressed: () async {
                  final initialRange = dateFrom != null && dateTo != null
                      ? DateTimeRange(start: dateFrom, end: dateTo)
                      : null;
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                    initialDateRange: initialRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: kSeqPrimaryContainer,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    ref.read(auditDateFromProvider.notifier).state = picked.start;
                    ref.read(auditDateToProvider.notifier).state = picked.end;
                  }
                },
                icon: const Icon(Icons.date_range_outlined, size: 16),
                label: Text(
                  dateFrom != null && dateTo != null
                      ? '${_formatDateShort(dateFrom)} – ${_formatDateShort(dateTo)}'
                      : 'Date range',
                  style: seqLabelSm(
                    color: dateFrom != null ? kSeqPrimaryContainer : kSeqOnSurface,
                    fontWeight: dateFrom != null ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(
                    color: dateFrom != null
                        ? kSeqPrimaryContainer
                        : kSeqOutlineVariant.withValues(alpha: 0.8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Clear filters
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                  label: const Text('Clear filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: kSeqError,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value != 'all'
              ? kSeqPrimaryContainer
              : kSeqOutlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : 'all',
          isDense: true,
          style: seqLabelSm(color: kSeqOnSurface, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.arrow_drop_down, color: kSeqOutline),
          items: items.map((it) {
            final displayText = it == 'all'
                ? '$label: All'
                : '$label: ${_formatActionName(it)}';
            return DropdownMenuItem<String>(
              value: it,
              child: Text(displayText),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _formatActionName(String action) {
    return action.replaceAll('_', ' ');
  }

  // --- Audit Log List -------------------------------------------------------

  Widget _buildLogList(BuildContext context, {required List<AuditLogEntry> logs}) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kSeqSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kSeqOutlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: kSeqOutline,
            ),
            const SizedBox(height: 12),
            Text(
              'No audit events found',
              style: seqHeadlineSm(
                color: kSeqOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting or clearing your filters to see more events.',
              style: seqBodyMd(color: kSeqOnSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < logs.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildLogRow(context, entry: logs[i]),
        ],
      ],
    );
  }

  Widget _buildLogRow(BuildContext context, {required AuditLogEntry entry}) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 800;

    return InkWell(
      onTap: () => _showDetailDrawer(context, entry: entry),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSeqSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: kSeqOutlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: isDesktop
            ? Row(
                children: [
                  // Action & Target
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.action,
                          style: seqHeadlineSm(
                            fontWeight: FontWeight.w700,
                            color: kSeqOnSurface,
                          ).copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.targetType} · ${_truncateId(entry.targetId)}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            color: kSeqOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Actor & Role
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        _buildRoleBadge(entry.actorRole),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.actorEmail ?? 'System',
                            style: seqBodySm(
                              color: kSeqOnSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // IP Address
                  SizedBox(
                    width: 120,
                    child: Text(
                      entry.ipAddress ?? '—',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: kSeqOutline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Timestamp
                  SizedBox(
                    width: 170,
                    child: Text(
                      _formatDateTime(entry.createdAt),
                      style: seqBodySm(color: kSeqOnSurfaceVariant),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: kSeqOutline,
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
                        child: Text(
                          entry.action,
                          style: seqHeadlineSm(
                            fontWeight: FontWeight.w700,
                            color: kSeqOnSurface,
                          ).copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildRoleBadge(entry.actorRole),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${entry.targetType} · ${_truncateId(entry.targetId)}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: kSeqOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          entry.actorEmail ?? 'System',
                          style: seqBodySm(
                            color: kSeqOnSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(entry.createdAt),
                        style: seqLabelSm(color: kSeqOutline),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    switch (role.toLowerCase()) {
      case 'admin':
        bg = kSeqPrimaryFixed.withValues(alpha: 0.5);
        fg = kSeqPrimaryContainer;
        break;
      case 'student':
        bg = kSeqSecondaryFixed.withValues(alpha: 0.5);
        fg = kSeqSecondary;
        break;
      case 'provider':
        bg = kSeqTertiaryFixed.withValues(alpha: 0.5);
        fg = kSeqTertiaryContainer;
        break;
      default:
        bg = kSeqSurfaceContainerHigh;
        fg = kSeqOnSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: seqLabelSm(
          color: fg,
          fontWeight: FontWeight.w700,
        ).copyWith(letterSpacing: 0.5),
      ),
    );
  }

  // --- Detail Drawer / Modal ------------------------------------------------

  void _showDetailDrawer(BuildContext context, {required AuditLogEntry entry}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: kSeqSurfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kSeqOutlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Audit Event Detail',
                                style: seqHeadlineSm(
                                  fontWeight: FontWeight.w700,
                                  color: kSeqOnSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Immutable ledger record',
                                style: seqLabelSm(color: kSeqOutline),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(modalContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: kSeqOutlineVariant),

                  // Scrollable Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Core Audit Fields
                        _buildDetailField('Action', entry.action, isBold: true),
                        _buildDetailField('Event ID', entry.id, isMonospace: true),
                        _buildDetailField('Timestamp', _formatDateTime(entry.createdAt)),
                        _buildDetailField('Actor Email', entry.actorEmail ?? 'System'),
                        _buildDetailField('Actor Role', entry.actorRole),
                        _buildDetailField('Actor ID', entry.actorId ?? '—', isMonospace: true),
                        _buildDetailField('Target Type', entry.targetType),
                        _buildDetailField('Target ID', entry.targetId ?? '—', isMonospace: true),
                        _buildDetailField('IP Address', entry.ipAddress ?? '—', isMonospace: true),

                        const SizedBox(height: 16),
                        Text(
                          'EVENT DETAILS (JSONB)',
                          style: seqLabelSm(
                            color: kSeqOutline,
                            fontWeight: FontWeight.w700,
                          ).copyWith(letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),

                        // Formatted JSON Details or "No details"
                        if (entry.details != null && entry.details!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSeqSurfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kSeqOutlineVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final kv in entry.details!.entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 140,
                                          child: Text(
                                            kv.key,
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 12,
                                              color: kSeqOnSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            kv.value?.toString() ?? 'null',
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 12,
                                              color: kSeqOnSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSeqSurfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'No details',
                              style: seqBodyMd(
                                color: kSeqOutline,
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailField(String label, String value,
      {bool isBold = false, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: seqLabelSm(
                color: kSeqOutline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isMonospace
                  ? GoogleFonts.robotoMono(
                      fontSize: 13,
                      color: kSeqOnSurface,
                    )
                  : seqBodySm(
                      color: kSeqOnSurface,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
