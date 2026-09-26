// lib/admin/screens/disbursements_oversight_screen.dart
//
// Admin Console: Disbursements Oversight (Screen 7)
// Visual tokens: scholaris_sequoia/DESIGN.md
// Strictly real data: 100% wired to public.disbursements, public.profiles, and public.scholarships.
// Zero fabricated metrics, zero fake compliance stamps, honest empty states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/shared/widgets/state_views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// 1. Domain Model: DisbursementRecord
// =============================================================================

class DisbursementRecord {
  const DisbursementRecord({
    required this.id,
    required this.applicationId,
    required this.scholarshipId,
    required this.recipientId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paymentMethod,
    this.referenceNumber,
    this.releasedAt,
    this.releasedBy,
    this.notes,
    this.recipientName,
    this.recipientEmail,
    this.releasedByName,
    this.scholarshipTitle,
  });

  final String id;
  final String applicationId;
  final String scholarshipId;
  final String recipientId;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paymentMethod;
  final String? referenceNumber;
  final DateTime? releasedAt;
  final String? releasedBy;
  final String? notes;

  // Joined fields
  final String? recipientName;
  final String? recipientEmail;
  final String? releasedByName;
  final String? scholarshipTitle;

  factory DisbursementRecord.fromMap(
    Map<String, dynamic> row, {
    Map<String, dynamic>? recipientProfile,
    Map<String, dynamic>? releasedByProfile,
  }) {
    final scholarshipMap = row['scholarships'] as Map<String, dynamic>?;

    final createdAtStr = row['created_at'] as String?;
    final createdAt = createdAtStr != null && createdAtStr.isNotEmpty
        ? DateTime.parse(createdAtStr)
        : DateTime.now();

    final updatedAtStr = row['updated_at'] as String?;
    final updatedAt = updatedAtStr != null && updatedAtStr.isNotEmpty
        ? DateTime.parse(updatedAtStr)
        : DateTime.now();

    final releasedAtStr = row['released_at'] as String?;
    final releasedAt = releasedAtStr != null && releasedAtStr.isNotEmpty
        ? DateTime.tryParse(releasedAtStr)
        : null;

    final amountNum = row['amount'] as num?;
    final amount = amountNum?.toDouble() ?? 0.0;

    return DisbursementRecord(
      id: row['id'] as String,
      applicationId: row['application_id'] as String,
      scholarshipId: row['scholarship_id'] as String,
      recipientId: row['recipient_id'] as String,
      amount: amount,
      status: (row['status'] as String? ?? 'pending').toLowerCase().trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      paymentMethod: row['payment_method'] as String?,
      referenceNumber: row['reference_number'] as String?,
      releasedAt: releasedAt,
      releasedBy: row['released_by'] as String?,
      notes: row['notes'] as String?,
      recipientName: (recipientProfile?['full_name'] as String?)?.trim(),
      recipientEmail: (recipientProfile?['email'] as String?)?.trim(),
      releasedByName: (releasedByProfile?['full_name'] as String?)?.trim(),
      scholarshipTitle: (scholarshipMap?['title'] as String?)?.trim(),
    );
  }
}

// =============================================================================
// 2. Data Provider
// =============================================================================

final adminDisbursementsProvider =
    FutureProvider.autoDispose<List<DisbursementRecord>>((ref) async {
  final supabase = Supabase.instance.client;

  // Step 1: Fetch disbursements with embedded scholarships join
  final response = await supabase
      .from('disbursements')
      .select('*, scholarships:scholarship_id(id, title)')
      .order('created_at', ascending: false);

  final rawList = response as List<dynamic>;
  if (rawList.isEmpty) return <DisbursementRecord>[];

  // Step 2: Two-step fetch for recipient profiles & released_by profiles
  final userIds = <String>{};
  for (final row in rawList) {
    final map = row as Map<String, dynamic>;
    final rId = map['recipient_id'] as String?;
    if (rId != null && rId.isNotEmpty) userIds.add(rId);
    final relBy = map['released_by'] as String?;
    if (relBy != null && relBy.isNotEmpty) userIds.add(relBy);
  }

  final profilesMap = <String, Map<String, dynamic>>{};
  if (userIds.isNotEmpty) {
    final profilesRes = await supabase
        .from('profiles')
        .select('id, full_name, email')
        .filter('id', 'in', userIds.toList());
    for (final p in (profilesRes as List<dynamic>)) {
      final pMap = p as Map<String, dynamic>;
      profilesMap[pMap['id'] as String] = pMap;
    }
  }

  return rawList.map((row) {
    final map = row as Map<String, dynamic>;
    final recipientId = map['recipient_id'] as String?;
    final releasedById = map['released_by'] as String?;
    return DisbursementRecord.fromMap(
      map,
      recipientProfile: recipientId != null ? profilesMap[recipientId] : null,
      releasedByProfile:
          releasedById != null ? profilesMap[releasedById] : null,
    );
  }).toList();
});

final adminDisbursementFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all');

// =============================================================================
// 3. Screen Widget
// =============================================================================

class DisbursementsOversightScreen extends ConsumerStatefulWidget {
  const DisbursementsOversightScreen({super.key});

  @override
  ConsumerState<DisbursementsOversightScreen> createState() =>
      _DisbursementsOversightScreenState();
}

class _DisbursementsOversightScreenState
    extends ConsumerState<DisbursementsOversightScreen> {
  String _formatCurrency(double? amount) {
    if (amount == null) return '₱0';
    final rounded = amount.toInt();
    final chars = rounded.toString().split('');
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }
    return '₱$buffer';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatPaymentMethod(String? pm) {
    if (pm == null || pm.trim().isEmpty) return '—';
    switch (pm.toLowerCase().trim()) {
      case 'gcash':
        return 'GCash';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      case 'check':
        return 'Check';
      default:
        return pm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disbsAsync = ref.watch(adminDisbursementsProvider);
    final activeTab = ref.watch(adminDisbursementFilterProvider);

    return Scaffold(
      backgroundColor: kSeqSurface,
      body: disbsAsync.when(
        loading: () => _buildSkeleton(context),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorView(
              title: 'Unable to Load Disbursements',
              message: 'Failed to query live disbursements: $err',
              onRetry: () => ref.invalidate(adminDisbursementsProvider),
            ),
          ),
        ),
        data: (allDisbursements) {
          final totalCount = allDisbursements.length;
          final pendingCount = allDisbursements
              .where((d) => d.status == 'pending')
              .length;
          final releasedCount = allDisbursements
              .where((d) => d.status == 'released')
              .length;
          final failedCount = allDisbursements
              .where((d) => d.status == 'failed')
              .length;
          final cancelledCount = allDisbursements
              .where((d) => d.status == 'cancelled')
              .length;

          // Filter by active status tab
          final filteredList = allDisbursements.where((d) {
            if (activeTab == 'all') return true;
            return d.status == activeTab;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminDisbursementsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  _buildHeader(context, totalCount: totalCount),
                  const SizedBox(height: 20),

                  // --- Filter Shelf ---
                  _buildFilterShelf(
                    context,
                    activeTab: activeTab,
                    totalCount: totalCount,
                    pendingCount: pendingCount,
                    releasedCount: releasedCount,
                    failedCount: failedCount,
                    cancelledCount: cancelledCount,
                  ),
                  const SizedBox(height: 20),

                  // --- Content ---
                  if (filteredList.isEmpty)
                    _buildEmptyState(activeTab: activeTab)
                  else
                    ...filteredList.map(
                      (record) => _buildDisbursementCard(context, record),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context, {required int totalCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live data tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: kSeqPrimaryFixed,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: kSeqPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Live data',
                style: seqLabelSm(
                  color: kSeqOnPrimaryFixedVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Disbursements Oversight',
          style: GoogleFonts.newsreader(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: kSeqOnSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$totalCount disbursements on platform',
          style: seqBodyMd(color: kSeqOnSurfaceVariant),
        ),
      ],
    );
  }

  // --- Filter Shelf ---
  Widget _buildFilterShelf(
    BuildContext context, {
    required String activeTab,
    required int totalCount,
    required int pendingCount,
    required int releasedCount,
    required int failedCount,
    required int cancelledCount,
  }) {
    final tabs = [
      {'key': 'all', 'label': 'All', 'count': totalCount},
      {'key': 'pending', 'label': 'Pending', 'count': pendingCount},
      {'key': 'released', 'label': 'Released', 'count': releasedCount},
      {'key': 'failed', 'label': 'Failed', 'count': failedCount},
      {'key': 'cancelled', 'label': 'Cancelled', 'count': cancelledCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final key = t['key'] as String;
          final label = t['label'] as String;
          final count = t['count'] as int;
          final isSelected = activeTab == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$label ($count)'),
              selected: isSelected,
              onSelected: (_) {
                ref
                    .read(adminDisbursementFilterProvider.notifier)
                    .state = key;
              },
              backgroundColor: kSeqSurfaceContainerLow,
              selectedColor: kSeqPrimary,
              labelStyle: seqLabelSm(
                color: isSelected ? kSeqOnPrimary : kSeqOnSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? kSeqPrimary
                      : kSeqOutlineVariant.withValues(alpha: 0.4),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState({required String activeTab}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(
                color: kSeqOutlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 26,
              color: kSeqOutline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No disbursements yet',
            style: seqHeadlineSm(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Disbursements appear here once created from an approved application.',
            style: seqBodySm(color: kSeqOnSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Disbursement Card ---
  Widget _buildDisbursementCard(
    BuildContext context,
    DisbursementRecord record,
  ) {
    final recipient = record.recipientName ?? 'Name not set';
    final scholarship = record.scholarshipTitle ?? 'General Bursary';
    final amountStr = _formatCurrency(record.amount);
    final dateStr = _formatDate(record.createdAt);
    final paymentMethodStr = _formatPaymentMethod(record.paymentMethod);
    final refStr = record.referenceNumber != null &&
            record.referenceNumber!.trim().isNotEmpty
        ? record.referenceNumber!
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDisbursementDetail(context, record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipient,
                          style: seqHeadlineSm(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scholarship,
                          style: seqBodySm(color: kSeqOnSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(record.status),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: kSeqOutlineVariant.withValues(alpha: 0.2)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOUNT',
                          style: seqLabelSm(
                            color: kSeqOutline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          amountStr,
                          style: seqHeadlineSm(
                            fontWeight: FontWeight.w700,
                            color: kSeqPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'METHOD',
                          style: seqLabelSm(
                            color: kSeqOutline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          paymentMethodStr,
                          style: seqBodySm(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REF NO.',
                          style: seqLabelSm(
                            color: kSeqOutline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          refStr,
                          style: seqBodySm(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    dateStr,
                    style: seqLabelSm(color: kSeqOutline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Status Chip ---
  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    Color dot;
    String label;

    switch (status) {
      case 'released':
        bg = kSeqPrimaryFixed;
        fg = kSeqOnPrimaryFixedVariant;
        dot = kSeqPrimary;
        label = 'Released';
        break;
      case 'pending':
        bg = kSeqSecondaryFixed;
        fg = kSeqOnSecondaryFixedVariant;
        dot = kSeqSecondary;
        label = 'Pending';
        break;
      case 'failed':
        bg = kSeqErrorContainer;
        fg = kSeqOnErrorContainer;
        dot = kSeqError;
        label = 'Failed';
        break;
      case 'cancelled':
        bg = kSeqSurfaceContainerHigh;
        fg = kSeqOnSurfaceVariant;
        dot = kSeqOutline;
        label = 'Cancelled';
        break;
      default:
        bg = kSeqSurfaceContainer;
        fg = kSeqOnSurfaceVariant;
        dot = kSeqOutline;
        label = status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: seqLabelSm(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // --- Detail Drawer / Dialog ---
  void _showDisbursementDetail(BuildContext context, DisbursementRecord record) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final recipient = record.recipientName ?? 'Name not set';
    final scholarship = record.scholarshipTitle ?? 'General Bursary';
    final amountStr = _formatCurrency(record.amount);
    final dateStr = _formatDate(record.createdAt);
    final releasedAtStr = record.releasedAt != null
        ? _formatDate(record.releasedAt)
        : 'Not yet released';
    final releasedByStr = record.releasedByName ?? '—';
    final notesStr = record.notes != null && record.notes!.trim().isNotEmpty
        ? record.notes!
        : 'No notes';

    showDialog<void>(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: kSeqSurfaceContainerLowest,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Disbursement Details',
                style: seqHeadlineSm(fontWeight: FontWeight.w700),
              ),
            ),
            _buildStatusChip(record.status),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Recipient', recipient),
                if (record.recipientEmail != null)
                  _detailRow('Email', record.recipientEmail!),
                _detailRow('Scholarship', scholarship),
                _detailRow('Disbursement Amount', amountStr),
                _detailRow(
                  'Payment Method',
                  _formatPaymentMethod(record.paymentMethod),
                ),
                _detailRow(
                  'Reference Number',
                  record.referenceNumber ?? '—',
                ),
                _detailRow('Created At', dateStr),
                _detailRow('Released At', releasedAtStr),
                _detailRow('Released By', releasedByStr),
                _detailRow('Disbursement ID', record.id),
                _detailRow('Application ID', record.applicationId),
                const SizedBox(height: 12),
                Divider(
                  color: kSeqOutlineVariant.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 8),
                Text(
                  'INTERNAL NOTES',
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSeqSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kSeqOutlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    notesStr,
                    style: record.notes != null &&
                            record.notes!.trim().isNotEmpty
                        ? seqBodySm(color: kSeqOnSurface)
                        : seqBodySm(color: kSeqOutline),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: Text(
              'Close',
              style: seqLabelMd(
                color: kSeqOnSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style:
                  seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  seqBodySm(color: kSeqOnSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --- Skeleton Loading ---
  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 300,
            height: 36,
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
