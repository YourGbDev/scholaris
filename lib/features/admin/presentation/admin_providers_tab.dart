// lib/features/admin/presentation/admin_providers_tab.dart
//
// Admin Provider Verification & Accreditation Management.
// Real-time inspection of submitted Individual & Organization provider applications.
// - Status sorting (Pending first, Approved, Rejected)
// - Detail view with masked ID numbers and signed URL previews
// - Approve & Reject actions with review notes and immutable audit log writes
// - Apple Design DNA: squircle geometry, hairline keylines, responsive data tables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scholaris/features/provider/models/provider_verification.dart';
import 'package:scholaris/features/provider/providers/provider_verification_provider.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';
import 'admin_theme.dart';

class AdminProvidersTab extends ConsumerStatefulWidget {
  const AdminProvidersTab({super.key});

  @override
  ConsumerState<AdminProvidersTab> createState() => _AdminProvidersTabState();
}

class _AdminProvidersTabState extends ConsumerState<AdminProvidersTab> {
  String _statusFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'
  String _typeFilter = 'all'; // 'all', 'organization', 'individual'
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final verificationsAsync = ref.watch(adminProviderVerificationsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Provider Verifications',
                      style: adminHeaderStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kAdminNavyTrust,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          size: 20, color: kAdminTextSecondary),
                      tooltip: 'Refresh queue',
                      onPressed: () =>
                          ref.invalidate(adminProviderVerificationsProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Review provider accreditation dossiers, verify regulatory credentials, and manage clearance.',
                  style: adminLabelStyle(
                    fontSize: 13,
                    color: kAdminTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Search & Filter controls
                _buildFilterControls(isDesktop),
              ],
            ),
          ),

          // Content surface
          Expanded(
            child: verificationsAsync.when(
              loading: () => const LoadingView(),
              error: (err, _) => ErrorView(
                message: 'Failed to load provider verifications: $err',
                onRetry: () =>
                    ref.invalidate(adminProviderVerificationsProvider),
              ),
              data: (verifications) {
                // Apply search and filter
                final filtered = verifications.where((v) {
                  if (_statusFilter != 'all' && v.status != _statusFilter) {
                    return false;
                  }
                  if (_typeFilter != 'all' && v.providerType != _typeFilter) {
                    return false;
                  }
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final name = v.displayName.toLowerCase();
                    final rep = (v.repName ?? '').toLowerCase();
                    final email =
                        (v.email ?? v.repEmail ?? '').toLowerCase();
                    return name.contains(query) ||
                        rep.contains(query) ||
                        email.contains(query);
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              size: 48, color: Color(0xFFC0C9C0)),
                          const SizedBox(height: 12),
                          Text(
                            'No provider verifications found',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kAdminNavyTrust,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All pending applications have been processed or none match the active filters.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: kAdminTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                  child: isDesktop
                      ? _buildDesktopTable(filtered)
                      : _buildMobileCards(filtered),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(bool isDesktop) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search Input
        SizedBox(
          width: isDesktop ? 260 : double.infinity,
          height: 36,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search provider name, rep, email...',
              hintStyle: GoogleFonts.inter(
                fontSize: 12.5,
                color: kAdminTextSecondary,
              ),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 16, color: kAdminTextSecondary),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAdminHairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAdminHairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAdminBridgeGreen),
              ),
            ),
          ),
        ),

        // Status Filter Chips
        _filterChip('All Status', 'all', _statusFilter,
            (val) => setState(() => _statusFilter = val)),
        _filterChip('Pending', 'pending', _statusFilter,
            (val) => setState(() => _statusFilter = val),
            badgeColor: const Color(0xFFF99A00)),
        _filterChip('Approved', 'approved', _statusFilter,
            (val) => setState(() => _statusFilter = val),
            badgeColor: const Color(0xFF0F4D2E)),
        _filterChip('Rejected', 'rejected', _statusFilter,
            (val) => setState(() => _statusFilter = val),
            badgeColor: const Color(0xFFBA1A1A)),

        // Type Filter Chips
        _filterChip('All Types', 'all', _typeFilter,
            (val) => setState(() => _typeFilter = val)),
        _filterChip('Organization', 'organization', _typeFilter,
            (val) => setState(() => _typeFilter = val)),
        _filterChip('Individual', 'individual', _typeFilter,
            (val) => setState(() => _typeFilter = val)),
      ],
    );
  }

  Widget _filterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelected, {
    Color? badgeColor,
  }) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F4D2E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F4D2E) : kAdminHairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : kAdminTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<ProviderVerification> items) {
    return Container(
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
                  flex: 5,
                  child: Text(
                    'Provider / Organization',
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
                    'Type',
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
                    'Submitted',
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
                    'Status',
                    style: adminLabelStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kAdminNavyTrust,
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    'Action',
                    textAlign: TextAlign.right,
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
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: kAdminHairline),
              itemBuilder: (context, index) {
                final v = items[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Provider Name & Subtitle
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: v.providerType == 'organization'
                                    ? const Color(0xFFD8E2FF)
                                    : const Color(0xFFB3F1C6)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                v.providerType == 'organization'
                                    ? Icons.apartment_rounded
                                    : Icons.person_rounded,
                                size: 18,
                                color: v.providerType == 'organization'
                                    ? const Color(0xFF004493)
                                    : const Color(0xFF0F4D2E),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.displayName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kAdminTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    v.email ?? v.repEmail ?? '—',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: kAdminTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Type Badge
                      Expanded(
                        flex: 3,
                        child: Text(
                          v.providerType == 'organization'
                              ? 'Organization'
                              : 'Individual',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kAdminTextPrimary,
                          ),
                        ),
                      ),

                      // Submitted Date
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatDate(v.submittedAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: kAdminTextSecondary,
                          ),
                        ),
                      ),

                      // Status Badge
                      Expanded(
                        flex: 3,
                        child: _buildStatusPill(v.status),
                      ),

                      // Action Button
                      SizedBox(
                        width: 110,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _openReviewModal(v),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF4F3F8),
                              foregroundColor: const Color(0xFF0F4D2E),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Review →',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildMobileCards(List<ProviderVerification> items) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAdminHairline),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusPill(v.status),
                  Text(
                    _formatDate(v.submittedAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: kAdminTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    v.providerType == 'organization'
                        ? Icons.apartment_rounded
                        : Icons.person_rounded,
                    size: 20,
                    color: const Color(0xFF0F4D2E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      v.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kAdminTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Type: ${v.providerType == 'organization' ? 'Organization' : 'Individual Benefactor'} • Email: ${v.email ?? v.repEmail ?? '—'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: kAdminTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openReviewModal(v),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4D2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Inspect & Review Dossier',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFB3F1C6).withValues(alpha: 0.5);
        fg = const Color(0xFF00351C);
        label = 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFFDAD6);
        fg = const Color(0xFF93000A);
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFF92400E);
        label = 'Pending Review';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Detail Inspection Modal
  // ---------------------------------------------------------------------------

  void _openReviewModal(ProviderVerification v) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ProviderReviewDialog(verification: v),
    );
  }
}

class _ProviderReviewDialog extends ConsumerStatefulWidget {
  const _ProviderReviewDialog({required this.verification});

  final ProviderVerification verification;

  @override
  ConsumerState<_ProviderReviewDialog> createState() =>
      _ProviderReviewDialogState();
}

class _ProviderReviewDialogState extends ConsumerState<_ProviderReviewDialog> {
  final _noteController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.verification.reviewNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(String status) async {
    final note = _noteController.text.trim();
    if (status == 'rejected' && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a review note explaining the rejection reason.'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final adminId =
        Supabase.instance.client.auth.currentUser?.id ?? 'admin-reviewer';

    if (status == 'approved') {
      await ref
          .read(adminProviderVerificationsProvider.notifier)
          .approveVerification(
            userId: widget.verification.userId,
            adminId: adminId,
            note: note.isNotEmpty ? note : 'All credentials accredited.',
          );
    } else {
      await ref
          .read(adminProviderVerificationsProvider.notifier)
          .rejectVerification(
            userId: widget.verification.userId,
            adminId: adminId,
            note: note,
          );
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'approved'
              ? 'Provider "${widget.verification.displayName}" accredited successfully.'
              : 'Provider "${widget.verification.displayName}" marked as rejected.',
        ),
        backgroundColor: status == 'approved'
            ? const Color(0xFF0F4D2E)
            : const Color(0xFFBA1A1A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.verification;
    final isOrg = v.providerType == 'organization';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOrg
                              ? 'Organization Accreditation Dossier'
                              : 'Individual Provider Verification',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kAdminNavyTrust,
                          ),
                        ),
                        Text(
                          'Review and verify identity, regulatory documents, and funding source.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: kAdminTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24, color: kAdminHairline),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Identity & Credentials
                      _sectionTitle('Applicant Profile'),
                      _infoRow('Entity / Legal Name', v.displayName),
                      _infoRow('Provider Type', isOrg ? 'Organization' : 'Individual'),
                      if (isOrg) ...[
                        _infoRow('Organization Type', v.orgType ?? '—'),
                        _infoRow('Registration No. (SEC/BIR)', v.maskedIdNumber),
                        _infoRow('Authorized Representative', v.repName ?? '—'),
                        _infoRow('Rep Position', v.repPosition ?? '—'),
                        _infoRow('Rep Email', v.repEmail ?? '—'),
                        _infoRow('Rep Phone', v.repPhone ?? '—'),
                      ] else ...[
                        _infoRow('Personal Email', v.email ?? '—'),
                        _infoRow('Contact Phone', v.phone ?? '—'),
                        _infoRow('Government ID Type', v.govIdType ?? '—'),
                        _infoRow('Masked ID Number', v.maskedIdNumber),
                        _infoRow('Source of Funds', v.sourceOfFunds ?? '—'),
                        _infoRow('Giving Budget', v.monthlyGivingBudget ?? '—'),
                        if (v.tin != null && v.tin!.isNotEmpty)
                          _infoRow('Masked TIN', v.maskedTin),
                      ],
                      const SizedBox(height: 16),

                      // Section 2: Uploaded Documents with Signed URL previews
                      _sectionTitle('Accreditation Documents'),
                      if (isOrg) ...[
                        _documentPreviewTile('SEC Certificate', v.secCertPath),
                        _documentPreviewTile('BIR Form 2303', v.bir2303Path),
                        if (v.boardResolutionPath != null)
                          _documentPreviewTile(
                              'Board Resolution', v.boardResolutionPath),
                      ] else ...[
                        _documentPreviewTile(
                            'Government ID (Front)', v.govIdFrontPath),
                        if (v.selfieIdPath != null)
                          _documentPreviewTile(
                              'Selfie with ID', v.selfieIdPath),
                      ],
                      const SizedBox(height: 16),

                      // Section 3: Review Note Input
                      _sectionTitle('Auditor Review Note'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText:
                              'Enter review feedback, accreditation remarks, or revision instructions...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 12, color: kAdminTextSecondary),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kAdminHairline),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 24, color: kAdminHairline),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleDecision('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBA1A1A),
                      side: const BorderSide(color: Color(0xFFBA1A1A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Reject Verification'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleDecision('approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4D2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Approve & Accredit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F4D2E),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.5, color: kAdminTextSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kAdminTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentPreviewTile(String label, String? storagePath) {
    if (storagePath == null || storagePath.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: kAdminTextSecondary)),
            Text('Not Provided', style: GoogleFonts.inter(fontSize: 12, color: kAdminTextSecondary)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kAdminHairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.attachment_rounded, size: 16, color: Color(0xFF0F4D2E)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: kAdminTextPrimary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(providerVerificationRepositoryProvider);
              final signedUrl = await repo.getSignedUrl(storagePath);
              if (signedUrl.isNotEmpty) {
                try {
                  await launchUrl(Uri.parse(signedUrl),
                      mode: LaunchMode.externalApplication);
                } catch (_) {
                  _showSignedUrlPreviewDialog(label, signedUrl);
                }
              } else {
                _showSignedUrlPreviewDialog(label, 'Simulated signed URL (local offline mode)');
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              foregroundColor: const Color(0xFF0F4D2E),
            ),
            child: const Text('View Document →', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  void _showSignedUrlPreviewDialog(String title, String signedUrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed Document URL (Expires in 1 hour):',
                style: GoogleFonts.inter(fontSize: 12, color: kAdminTextSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F3F8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                signedUrl,
                style: GoogleFonts.inter(fontSize: 11, color: kAdminTextPrimary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
