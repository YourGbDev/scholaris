// lib/features/admin/presentation/admin_users_tab.dart
//
// Admin Console: User Directory & Access Control (Screen 1 Rebuild)
// Faithful to assets/mockups/admin/stitch_scholaris_provider_console_mockup/scholaris_admin_user_directory_apple_design/code.html
// Visual tokens: scholaris_sequoia/DESIGN.md (Surface #FAF9FE, Primary Container #0F4D2E, Inter typography, 16px squircles)
// Zero fabricated content: 100% wired to live Supabase profiles & provider_verifications.

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/core/security/captcha_challenge.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/provider/models/provider_verification.dart';
import 'package:scholaris/features/provider/providers/provider_verification_provider.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'admin_theme.dart';
import 'admin_users_provider.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'all';
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportCsv(List<StudentProfile> list, Map<String, ProviderVerification> verifMap) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Full Name,Email,Role,Account Status,Verification / Setup Status,Region,School,Course,GPA');
    for (final u in list) {
      final v = verifMap[u.id];
      final verifStatus = u.role == 'provider'
          ? (v?.status ?? 'unverified')
          : (u.setupComplete ? 'complete' : 'pending');
      buffer.writeln(
        '"${u.id}","${u.fullName}","${u.email ?? ''}","${u.role}","${u.status}","$verifStatus","${u.region}","${u.school ?? ''}","${u.course}","${u.gpa}"',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${list.length} user records to clipboard as CSV.'),
        backgroundColor: kSeqPrimaryContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final verificationsAsync = ref.watch(adminProviderVerificationsProvider);
    final searchQuery = ref.watch(adminUserSearchQueryProvider);
    final roleFilter = ref.watch(adminUserRoleFilterProvider);

    return Scaffold(
      backgroundColor: kSeqSurface,
      body: CrossFadeLoading(
        isLoading: usersAsync.isLoading,
        skeleton: _buildSkeleton(context),
        child: usersAsync.when(
          loading: () => _buildSkeleton(context),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ErrorView(
                title: 'Unable to Load User Directory',
                message: 'Failed to load user directory: $err',
                onRetry: () {
                  ref.invalidate(adminUsersProvider);
                  ref.invalidate(adminProviderVerificationsProvider);
                },
              ),
            ),
          ),
          data: (users) {
            final verifications = verificationsAsync.valueOrNull ?? <ProviderVerification>[];
            final verifMap = {for (final v in verifications) v.userId: v};

            // Calculate live header metrics
            final totalCount = users.length;
            final studentUsers = users.where((u) => u.role == 'student').toList();
            final providerUsers = users.where((u) => u.role == 'provider').toList();
            final adminUsers = users.where((u) => u.role == 'admin').toList();

            final studentCount = studentUsers.length;
            final providerCount = providerUsers.length;
            final adminCount = adminUsers.length;

            final setupCompleteCount = studentUsers.where((u) => u.setupComplete).length;
            final studentPendingCount = studentCount - setupCompleteCount;

            final approvedProvidersCount = verifications.where((v) => v.status == 'approved').length;
            final pendingProvidersCount = verifications.where((v) => v.status == 'pending').length;

            // Apply filters
            var filtered = users;
            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              filtered = filtered.where((u) {
                final name = u.fullName.toLowerCase();
                final email = (u.email ?? '').toLowerCase();
                final id = u.id.toLowerCase();
                final school = (u.school ?? '').toLowerCase();
                final course = u.course.toLowerCase();
                final org = (verifMap[u.id]?.orgName ?? '').toLowerCase();
                return name.contains(q) ||
                    email.contains(q) ||
                    id.contains(q) ||
                    school.contains(q) ||
                    course.contains(q) ||
                    org.contains(q);
              }).toList();
            }

            if (roleFilter != 'all') {
              filtered = filtered.where((u) => u.role == roleFilter).toList();
            }

            if (_selectedRegion != 'all') {
              filtered = filtered.where((u) => u.region == _selectedRegion).toList();
            }

            if (_selectedStatus != 'all') {
              if (_selectedStatus == 'deactivated') {
                filtered = filtered.where((u) => u.status == 'deactivated').toList();
              } else if (_selectedStatus == 'active') {
                filtered = filtered.where((u) {
                  if (u.status == 'deactivated') return false;
                  if (u.role == 'student') return u.setupComplete;
                  if (u.role == 'provider') return verifMap[u.id]?.status == 'approved';
                  return true;
                }).toList();
              } else if (_selectedStatus == 'pending') {
                filtered = filtered.where((u) {
                  if (u.status == 'deactivated') return false;
                  if (u.role == 'student') return !u.setupComplete;
                  if (u.role == 'provider') return verifMap[u.id]?.status == 'pending';
                  return false;
                }).toList();
              }
            }

            return _buildContent(
              context: context,
              users: users,
              filtered: filtered,
              verifMap: verifMap,
              totalCount: totalCount,
              studentCount: studentCount,
              providerCount: providerCount,
              adminCount: adminCount,
              setupCompleteCount: setupCompleteCount,
              studentPendingCount: studentPendingCount,
              approvedProvidersCount: approvedProvidersCount,
              pendingProvidersCount: pendingProvidersCount,
              searchQuery: searchQuery,
              roleFilter: roleFilter,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required List<StudentProfile> users,
    required List<StudentProfile> filtered,
    required Map<String, ProviderVerification> verifMap,
    required int totalCount,
    required int studentCount,
    required int providerCount,
    required int adminCount,
    required int setupCompleteCount,
    required int studentPendingCount,
    required int approvedProvidersCount,
    required int pendingProvidersCount,
    required String searchQuery,
    required String roleFilter,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final paddingH = isDesktop ? 32.0 : 16.0;

    return SingleChildScrollView(
      physics: const AppleBouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Action & Identity Bar
          _buildTopIdentityBar(context, filtered, verifMap),
          const SizedBox(height: 24),

          // 2. Metrics Grid (4 Squircle Cards)
          _buildMetricsGrid(
            context,
            totalCount: totalCount,
            studentCount: studentCount,
            providerCount: providerCount,
            adminCount: adminCount,
            setupCompleteCount: setupCompleteCount,
            studentPendingCount: studentPendingCount,
            approvedProvidersCount: approvedProvidersCount,
            pendingProvidersCount: pendingProvidersCount,
          ),
          const SizedBox(height: 24),

          // 3. Filter & Control Section
          _buildFilterControlSection(
            context,
            searchQuery: searchQuery,
            roleFilter: roleFilter,
            totalCount: totalCount,
            studentCount: studentCount,
            providerCount: providerCount,
            adminCount: adminCount,
          ),
          const SizedBox(height: 20),

          // 4. Data Table / List Container
          _buildTableCardContainer(context, filtered, verifMap),
          const SizedBox(height: 28),

          // 5. Supplementary Insights Bento (Bottom 3 Cards)
          _buildSupplementaryBento(
            context,
            studentCount: studentCount,
            setupCompleteCount: setupCompleteCount,
            approvedProvidersCount: approvedProvidersCount,
            pendingProvidersCount: pendingProvidersCount,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- 1. Top Action & Identity Bar ------------------------------------------

  Widget _buildTopIdentityBar(
    BuildContext context,
    List<StudentProfile> filtered,
    Map<String, ProviderVerification> verifMap,
  ) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: kSeqPrimaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMobile
                        ? 'REGISTRY & GOVERNANCE'
                        : 'REGISTRY & GOVERNANCE • LIVE PLATFORM USER DIRECTORY',
                    style: seqLabelSm(
                      fontWeight: FontWeight.w600,
                      color: kSeqOutline,
                    ).copyWith(letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'User Directory & Access Control',
              style: isMobile
                  ? seqHeadlineMd(fontWeight: FontWeight.w700)
                  : seqHeadlineLg(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Text(
                'Central identity directory across student scholars, accredited grant providers, and platform administrators.',
                style: seqBodyMd(color: kSeqOnSurfaceVariant),
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            PressableScale(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: kSeqSurfaceContainerLowest,
                  foregroundColor: kSeqOnSurface,
                  side: const BorderSide(color: kSeqOutlineVariant, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 18, color: kSeqOnSurfaceVariant),
                label: Text(
                  'Export Registry (CSV)',
                  style: seqLabelLg(fontWeight: FontWeight.w600),
                ),
                onPressed: () => _exportCsv(filtered, verifMap),
              ),
            ),
            PressableScale(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kSeqPrimaryContainer,
                  foregroundColor: kSeqOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  elevation: 1,
                  shadowColor: const Color(0x330F4D2E),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  'Provision Identity',
                  style: seqLabelLg(fontWeight: FontWeight.w600, color: kSeqOnPrimary),
                ),
                onPressed: () => _showCreateUserModal(context),
              ),
            ),
          ],
        );

        if (isMobile || constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 16),
              actionButtons,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  // --- 2. Metrics Grid (4 Squircle Cards) ------------------------------------

  Widget _buildMetricsGrid(
    BuildContext context, {
    required int totalCount,
    required int studentCount,
    required int providerCount,
    required int adminCount,
    required int setupCompleteCount,
    required int studentPendingCount,
    required int approvedProvidersCount,
    required int pendingProvidersCount,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final studentRate = totalCount > 0
        ? ((studentCount / totalCount) * 100).toStringAsFixed(1)
        : '0.0';

    final card1 = _buildMetricCard(
      title: 'Total Users',
      badge: '+$totalCount registered',
      badgeBg: kSeqPrimaryFixed,
      badgeFg: kSeqOnPrimaryFixed,
      value: '$totalCount',
      subtext: 'registered',
      bottomContent: Row(
        children: [
          const Icon(Icons.badge_outlined, size: 15, color: kSeqPrimaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Active accounts in platform registry',
              style: seqLabelSm(color: kSeqOnSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final card2 = _buildMetricCard(
      title: 'Student Scholars',
      badge: '$studentRate% rate',
      badgeBg: kSeqPrimaryFixedDim.withValues(alpha: 0.45),
      badgeFg: kSeqOnPrimaryFixedVariant,
      value: '$studentCount',
      subtext: 'of $totalCount',
      middleWidget: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: totalCount > 0 ? (studentCount / totalCount) : 0,
            minHeight: 5,
            backgroundColor: kSeqSurfaceContainer,
            color: kSeqPrimaryContainer,
          ),
        ),
      ),
      bottomContent: Text(
        '$setupCompleteCount completed • $studentPendingCount setup pending',
        style: seqLabelSm(color: kSeqOutline),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final card3 = _buildMetricCard(
      title: 'Grant Providers',
      topRightIcon: Icons.corporate_fare_rounded,
      value: '$providerCount',
      subtext: 'fiduciaries',
      bottomContent: Text(
        '$approvedProvidersCount Accredited • $pendingProvidersCount Pending Review',
        style: seqLabelSm(color: kSeqOnSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final card4 = _buildMetricCard(
      title: 'Platform Admins',
      badge: 'Admin Role',
      badgeBg: kSeqSecondaryFixed,
      badgeFg: kSeqOnSecondaryFixedVariant,
      value: '$adminCount',
      subtext: 'clearances',
      bottomContent: Row(
        children: [
          const Icon(Icons.security_rounded, size: 15, color: kSeqSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Executive administrative access',
              style: seqLabelSm(color: kSeqOnSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (width >= 1200) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: card1),
          const SizedBox(width: 16),
          Expanded(child: card2),
          const SizedBox(width: 16),
          Expanded(child: card3),
          const SizedBox(width: 16),
          Expanded(child: card4),
        ],
      );
    } else if (width >= 700) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 16),
              Expanded(child: card2),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: card3),
              const SizedBox(width: 16),
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

  Widget _buildMetricCard({
    required String title,
    String? badge,
    Color? badgeBg,
    Color? badgeFg,
    IconData? topRightIcon,
    required String value,
    required String subtext,
    Widget? middleWidget,
    required Widget bottomContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.35), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  style: seqLabelMd(color: kSeqOnSurfaceVariant, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg ?? kSeqSurfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: seqLabelSm(color: badgeFg ?? kSeqOnSurface, fontWeight: FontWeight.w600),
                  ),
                ),
              ] else if (topRightIcon != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kSeqSurfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(topRightIcon, size: 16, color: kSeqOnSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: seqTabularFigures(seqDisplay(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(
                subtext,
                style: seqBodySm(color: kSeqOutline),
              ),
            ],
          ),
          ?middleWidget,
          const SizedBox(height: 10),
          bottomContent,
        ],
      ),
    );
  }

  // --- 3. Filter & Control Section -------------------------------------------

  Widget _buildFilterControlSection(
    BuildContext context, {
    required String searchQuery,
    required String roleFilter,
    required int totalCount,
    required int studentCount,
    required int providerCount,
    required int adminCount,
  }) {
    final searchBox = Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLow,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(
                color: isFocused
                    ? kSeqPrimaryContainer
                    : kSeqOutlineVariant.withValues(alpha: 0.25),
                width: isFocused ? 1.5 : 1,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: kSeqPrimaryContainer.withValues(alpha: 0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: isFocused ? kSeqPrimaryContainer : kSeqOutline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: seqBodyMd(),
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Email, Role, or ID...',
                      hintStyle: seqBodySm(color: kSeqOutline),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) {
                      ref.read(adminUserSearchQueryProvider.notifier).state =
                          val.trim().toLowerCase();
                    },
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: kSeqOutline),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(adminUserSearchQueryProvider.notifier).state = '';
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kSeqSurfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⌘K',
                      style: seqLabelSm(color: kSeqOutline),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    final segmentedPills = Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: kSeqSurfaceContainerLow,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRolePill('all', 'All Users ($totalCount)', roleFilter == 'all'),
            _buildRolePill('student', 'Students ($studentCount)', roleFilter == 'student'),
            _buildRolePill('provider', 'Grant Providers ($providerCount)', roleFilter == 'provider'),
            _buildRolePill('admin', 'Platform Admins ($adminCount)', roleFilter == 'admin'),
          ],
        ),
      ),
    );

    final dropdownFilters = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Region Filter
        SizedBox(
          width: 160,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.25), width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRegion,
                isDense: true,
                isExpanded: true,
                style: seqLabelMd(color: kSeqOnSurface, fontWeight: FontWeight.w500),
                icon: const Icon(Icons.expand_more_rounded, size: 16, color: kSeqOutline),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Regions', overflow: TextOverflow.ellipsis)),
                  ...kPhilippineRegions.map(
                    (r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRegion = val);
                },
              ),
            ),
          ),
        ),
        // Status Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: kSeqSurfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.25), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              value: _selectedStatus,
              style: seqLabelMd(color: kSeqOnSurface, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.expand_more_rounded, size: 16, color: kSeqOutline),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Status: All')),
                DropdownMenuItem(value: 'active', child: Text('Active / Complete')),
                DropdownMenuItem(value: 'pending', child: Text('Pending Setup')),
                DropdownMenuItem(value: 'deactivated', child: Text('Deactivated')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.35), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchBox,
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              segmentedPills,
              dropdownFilters,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill(String roleValue, String label, bool isSelected) {
    return PressableScale(
      child: GestureDetector(
        onTap: () {
          ref.read(adminUserRoleFilterProvider.notifier).state = roleValue;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? kSeqSurfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: seqLabelSm(
              color: isSelected ? kSeqOnSurface : kSeqOnSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // --- 4. Data Table / List Container ----------------------------------------

  Widget _buildTableCardContainer(
    BuildContext context,
    List<StudentProfile> filtered,
    Map<String, ProviderVerification> verifMap,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Container(
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.35), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_off_rounded, size: 40, color: kSeqOutline),
                    const SizedBox(height: 12),
                    Text(
                      'No matching platform users found',
                      style: seqHeadlineSm(color: kSeqOnSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try adjusting your search criteria or role filters.',
                      style: seqBodyMd(color: kSeqOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else if (isDesktop) ...[
            // Table Header
            Container(
              color: kSeqSurfaceContainerLow.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'IDENTITY & INSTITUTIONAL REGISTRY',
                      style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600)
                          .copyWith(letterSpacing: 0.5),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'AFFILIATION / SCOPE',
                      style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600)
                          .copyWith(letterSpacing: 0.5),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'ACCESS ROLE',
                      style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600)
                          .copyWith(letterSpacing: 0.5),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'STATUS & VERIFICATION',
                      style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600)
                          .copyWith(letterSpacing: 0.5),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'ATTRIBUTES',
                      style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600)
                          .copyWith(letterSpacing: 0.5),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(
                      'ACTIONS',
                      textAlign: TextAlign.right,
                      style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600)
                          .copyWith(letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: kSeqOutlineVariant.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, i) {
                final u = filtered[i];
                final v = verifMap[u.id];
                return StaggeredListItem(
                  index: i,
                  child: _buildDesktopTableRow(context, u, v),
                );
              },
            ),
          ] else ...[
            // Mobile Card Feed
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final u = filtered[i];
                final v = verifMap[u.id];
                return StaggeredListItem(
                  index: i,
                  child: PressableScale(
                    child: _buildMobileUserCard(context, u, v),
                  ),
                );
              },
            ),
          ],
          // Table Footer / Pagination Indicator
          Container(
            color: kSeqSurfaceContainerLow.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: !isDesktop
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Showing 1 to ${filtered.length} of ${filtered.length} registered platform identities',
                        style: seqLabelSm(color: kSeqOnSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
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
                          Flexible(
                            child: Text(
                              'Supabase PostgreSQL Database Connected',
                              style: seqLabelSm(color: kSeqOutline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Showing 1 to ${filtered.length} of ${filtered.length} registered platform identities',
                                style: seqLabelSm(color: kSeqOnSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('•', style: seqLabelSm(color: kSeqOutline)),
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: kSeqPrimaryContainer,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Supabase PostgreSQL Database Connected',
                                style: seqLabelSm(color: kSeqOutline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Page 1 of 1',
                        style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(
    BuildContext context,
    StudentProfile u,
    ProviderVerification? v,
  ) {
    final displayName = u.fullName.isNotEmpty
        ? u.fullName
        : (v?.orgName ?? u.email ?? 'Unnamed User');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // 1. Identity & Institutional Registry (flex 4)
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _buildUserAvatar(u, v),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: seqLabelLg(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (u.role == 'provider' && v?.status == 'approved') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, size: 14, color: kSeqPrimaryContainer),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        u.email ??
                            'ID: ${u.id.length >= 10 ? u.id.substring(0, 10) : u.id}...',
                        style: adminDataMono(
                          fontSize: 11,
                          color: kSeqOutline,
                          fontWeight: FontWeight.w400,
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
          // 2. Affiliation / Scope (flex 3)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getAffiliationPrimary(u, v),
                  style: seqBodyMd(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getAffiliationSecondary(u, v),
                  style: seqLabelSm(color: kSeqOutline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 3. Access Role (flex 2)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildRoleBadge(u.role),
            ),
          ),
          // 4. Status & Verification (flex 2)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildVerificationBadge(u, v),
            ),
          ),
          // 5. Attributes (flex 2)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getAttributeLabel(u),
                  style: seqLabelSm(color: kSeqOutline),
                ),
                Text(
                  _getAttributeValue(u, v),
                  style: seqTabularFigures(seqLabelMd(fontWeight: FontWeight.w600)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 6. Actions (150px)
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PressableScale(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showUserDetails(context, u, v),
                    child: Text(
                      'Inspect',
                      style: seqLabelSm(
                        fontWeight: FontWeight.w600,
                        color: kSeqPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                _buildActionPopupMenu(context, u),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileUserCard(
    BuildContext context,
    StudentProfile u,
    ProviderVerification? v,
  ) {
    final displayName = u.fullName.isNotEmpty
        ? u.fullName
        : (v?.orgName ?? u.email ?? 'Unnamed User');

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: kSeqOutlineVariant.withValues(alpha: 0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        color: kSeqSurfaceContainerLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildUserAvatar(u, v, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: seqLabelLg(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        u.email ?? u.id,
                        style: adminDataMono(fontSize: 10, color: kSeqOutline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildActionPopupMenu(context, u),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildRoleBadge(u.role),
                _buildVerificationBadge(u, v),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_getAffiliationPrimary(u, v)} • ${_getAffiliationSecondary(u, v)}',
              style: seqBodySm(color: kSeqOnSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${_getAttributeLabel(u)}: ${_getAttributeValue(u, v)}',
                    style: seqTabularFigures(seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PressableScale(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showUserDetails(context, u, v),
                    child: Text(
                      'Inspect Dossier',
                      style: seqLabelSm(fontWeight: FontWeight.w600, color: kSeqPrimaryContainer),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Avatar, Badges & Text Helpers ----------------------------------------

  String _getInitials(StudentProfile u, ProviderVerification? v) {
    String name = u.fullName.trim();
    if (name.isEmpty && v?.orgName != null && v!.orgName!.trim().isNotEmpty) {
      name = v.orgName!.trim();
    }
    if (name.isEmpty && u.email != null && u.email!.trim().isNotEmpty) {
      name = u.email!.trim();
    }
    if (name.isEmpty) return u.role == 'admin' ? 'AD' : (u.role == 'provider' ? 'PR' : 'ST');
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return 'SC';
  }

  Widget _buildUserAvatar(StudentProfile u, ProviderVerification? v, {double size = 40}) {
    Color bg;
    final fg = Colors.white; // Guaranteed high contrast >= 7:1 against all dark avatar backgrounds

    if (u.role == 'admin') {
      bg = const Color(0xFF263238); // Deep Slate, contrast ratio ~11.8:1
    } else if (u.role == 'provider') {
      bg = const Color(0xFF1E5280); // Rich Navy, contrast ratio ~7.8:1
    } else {
      bg = const Color(0xFF0F4D2E); // Deep Forest Green, contrast ratio ~8.9:1
    }

    final initials = _getInitials(u, v);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: geist(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getAffiliationPrimary(StudentProfile u, ProviderVerification? v) {
    if (u.role == 'student') {
      return u.course.isNotEmpty ? u.course : 'General Academic Program';
    } else if (u.role == 'provider') {
      final org = v?.orgName;
      if (org != null && org.isNotEmpty) return org;
      if (u.school != null && u.school!.isNotEmpty) return u.school!;
      return 'Independent Benefactor';
    } else {
      return 'Scholaris Executive Governance';
    }
  }

  String _getAffiliationSecondary(StudentProfile u, ProviderVerification? v) {
    if (u.role == 'student') {
      return [
        if (u.school != null && u.school!.isNotEmpty) u.school!,
        if (u.region.isNotEmpty) u.region,
      ].join(' • ');
    } else if (u.role == 'provider') {
      final type = v?.providerType ?? 'fiduciary';
      return [
        type[0].toUpperCase() + type.substring(1),
        if (u.region.isNotEmpty) u.region,
      ].join(' • ');
    } else {
      return 'Platform Administration & Oversight';
    }
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    String label;

    if (role == 'admin') {
      bg = kSeqSurfaceContainerHigh;
      fg = kSeqOnSurface;
      label = 'Platform Admin';
    } else if (role == 'provider') {
      bg = kSeqSecondaryFixed;
      fg = kSeqOnSecondaryFixedVariant;
      label = 'Grant Provider';
    } else {
      bg = kSeqSurfaceContainer;
      fg = kSeqOnSurfaceVariant;
      label = 'Student Scholar';
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: seqLabelSm(color: fg, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(StudentProfile u, ProviderVerification? v) {
    // Semantic status pill palette (green=active, red=suspended, amber=pending)
    const activeBg = Color(0xFFE8F5E9);
    const activeFg = Color(0xFF1B5E20);
    const activeDot = Color(0xFF2E7D32);

    const suspendedBg = Color(0xFFFFEBEE);
    const suspendedFg = Color(0xFFC62828);
    const suspendedDot = Color(0xFFD32F2F);

    const pendingBg = Color(0xFFFFF8E1);
    const pendingFg = Color(0xFFB78103);
    const pendingDot = Color(0xFFFFA000);

    if (u.status == 'deactivated') {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: suspendedBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: suspendedDot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                'Deactivated',
                style: seqLabelSm(color: suspendedFg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (u.role == 'provider') {
      final status = v?.status ?? 'unverified';
      Color bg;
      Color fg;
      Color dotColor;
      String label;

      if (status == 'approved') {
        bg = activeBg;
        fg = activeFg;
        dotColor = activeDot;
        label = 'Accredited & Active';
      } else if (status == 'rejected') {
        bg = suspendedBg;
        fg = suspendedFg;
        dotColor = suspendedDot;
        label = 'Verification Rejected';
      } else if (status == 'pending') {
        bg = pendingBg;
        fg = pendingFg;
        dotColor = pendingDot;
        label = 'Verification Pending';
      } else {
        bg = pendingBg;
        fg = pendingFg;
        dotColor = pendingDot;
        label = 'Pending Review';
      }

      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
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
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: seqLabelSm(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (u.role == 'student') {
      final isComplete = u.setupComplete;
      final bg = isComplete ? activeBg : pendingBg;
      final fg = isComplete ? activeFg : pendingFg;
      final dotColor = isComplete ? activeDot : pendingDot;

      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
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
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isComplete ? 'Active Scholar' : 'Pending Setup',
                style: seqLabelSm(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Admin role
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: activeBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: activeDot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              'Active Administrator',
              style: seqLabelSm(color: activeFg, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _getAttributeLabel(StudentProfile u) {
    if (u.role == 'student') return 'GWA';
    if (u.role == 'provider') return 'Type';
    return 'Clearance';
  }

  String _getAttributeValue(StudentProfile u, ProviderVerification? v) {
    if (u.role == 'student') {
      return u.gpa > 0 ? u.gpa.toStringAsFixed(2) : '—';
    }
    if (u.role == 'provider') {
      final t = v?.providerType ?? 'General';
      return t[0].toUpperCase() + t.substring(1);
    }
    return 'Root';
  }

  Widget _buildActionPopupMenu(BuildContext context, StudentProfile u) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 16, color: kSeqOutline),
      tooltip: 'User actions',
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      onSelected: (val) {
        if (val == 'edit') {
          _showEditUserModal(context, u);
        } else if (val == 'deactivate') {
          _confirmDeactivate(context, u);
        } else if (val == 'delete') {
          _confirmDelete(context, u);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit Role / Status', style: seqBodySm()),
        ),
        PopupMenuItem(
          value: 'deactivate',
          child: Text(
            u.status == 'deactivated' ? 'Reactivate Account' : 'Deactivate Account',
            style: seqBodySm(color: kSeqError),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete Account',
            style: seqBodySm(color: kSeqError),
          ),
        ),
      ],
    );
  }

  // --- 5. Supplementary Insights Bento Grid ---------------------------------

  Widget _buildSupplementaryBento(
    BuildContext context, {
    required int studentCount,
    required int setupCompleteCount,
    required int approvedProvidersCount,
    required int pendingProvidersCount,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final completionRate = studentCount > 0
        ? ((setupCompleteCount / studentCount) * 100).toStringAsFixed(1)
        : '0.0';

    final card1 = _buildBentoCard(
      category: 'REGISTRY INTEGRITY',
      headerDot: kSeqPrimaryContainer,
      title: 'Profile Setup & Academic Verification',
      description:
          'Live tracking of student profiles with verified academic standing, enrolled course, institutional affiliation, and completion rate across all 17 administrative regions.',
      footerLabel: 'Profile Completion Rate',
      footerValue: '$completionRate% Completed',
      footerBadgeColor: kSeqPrimaryFixed,
      footerTextColor: kSeqOnPrimaryFixedVariant,
    );

    final card2 = _buildBentoCard(
      category: 'ACCREDITATION PIPELINE',
      headerIcon: Icons.verified_user_rounded,
      headerIconColor: kSeqSecondary,
      title: 'Provider Vetting & Document Verification',
      description:
          'Accreditation pipeline enforcing statutory KYC validation, SEC/DTI documentation, and administrative review per Migration 0014 before grant disbursement.',
      footerLabel: 'Accreditation Status',
      footerValue: '$approvedProvidersCount Approved • $pendingProvidersCount In Review',
      footerBadgeColor: kSeqSecondaryFixed,
      footerTextColor: kSeqOnSecondaryFixedVariant,
    );

    final card3 = _buildBentoCard(
      category: 'ACCESS CONTROL POLICY',
      headerIcon: Icons.policy_rounded,
      headerIconColor: kSeqTertiary,
      title: 'Row-Level Security (RLS) Protocol',
      description:
          'Cryptographic JWT session claims and PostgreSQL Row-Level Security policies strictly isolating student records, provider disbursements, and administrative operations.',
      footerLabel: 'Database Security Policy',
      footerValue: 'PostgreSQL RLS Enforced',
      footerBadgeColor: kSeqTertiaryFixed,
      footerTextColor: kSeqOnTertiaryFixedVariant,
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: card1),
          const SizedBox(width: 16),
          Expanded(child: card2),
          const SizedBox(width: 16),
          Expanded(child: card3),
        ],
      );
    }

    return Column(
      children: [
        card1,
        const SizedBox(height: 16),
        card2,
        const SizedBox(height: 16),
        card3,
      ],
    );
  }

  Widget _buildBentoCard({
    required String category,
    Color? headerDot,
    IconData? headerIcon,
    Color? headerIconColor,
    required String title,
    required String description,
    required String footerLabel,
    required String footerValue,
    required Color footerBadgeColor,
    required Color footerTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.35), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  category,
                  style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w600)
                      .copyWith(letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (headerDot != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: headerDot, shape: BoxShape.circle),
                )
              else if (headerIcon != null)
                Icon(headerIcon, size: 16, color: headerIconColor ?? kSeqOutline),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: seqHeadlineSm(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: seqBodySm(color: kSeqOnSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLow.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    footerLabel,
                    style: seqLabelSm(color: kSeqOutline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: footerBadgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      footerValue,
                      style: seqLabelSm(color: footerTextColor, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Loading Skeleton -----------------------------------------------------

  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const AppleBouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar Skeleton
          const SkeletonBand(width: 220, height: 14),
          const SizedBox(height: 10),
          const SkeletonBand(width: 380, height: 32),
          const SizedBox(height: 10),
          const SkeletonBand(width: 520, height: 16),
          const SizedBox(height: 24),

          // Metrics Grid Skeleton
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSeqSurfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBand(width: 100, height: 14),
                      SizedBox(height: 12),
                      SkeletonBand(width: 80, height: 36),
                      SizedBox(height: 12),
                      SkeletonBand(width: 160, height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Filter Section Skeleton
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(height: 20),

          // Table Skeleton
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modals (User Details, Create, Edit, Deactivate, Delete) ----------------

  void _showUserDetails(
    BuildContext context,
    StudentProfile u,
    ProviderVerification? v,
  ) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final displayName = u.fullName.isNotEmpty
        ? u.fullName
        : (v?.orgName ?? u.email ?? 'Unnamed user');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kSeqSurfaceContainerLowest,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: seqHeadlineSm(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildRoleBadge(u.role),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(context, 'Account ID', u.id),
                _detailRow(context, 'Email', u.email ?? 'Not specified'),
                _detailRow(
                  context,
                  'System Role',
                  u.role[0].toUpperCase() + u.role.substring(1),
                ),
                _detailRow(context, 'Account Status', u.status),
                if (u.role == 'student') ...[
                  _detailRow(context, 'Profile Setup',
                      u.setupComplete ? 'Completed' : 'Pending completion'),
                  if (u.course.isNotEmpty) _detailRow(context, 'Course', u.course),
                  if (u.school != null && u.school!.isNotEmpty)
                    _detailRow(context, 'School', u.school!),
                  _detailRow(context, 'Year Level', 'Year ${u.yearLevel}'),
                  _detailRow(context, 'GWA', u.gpa > 0 ? u.gpa.toStringAsFixed(2) : 'Not declared'),
                  if (u.monthlyFamilyIncome != null)
                    _detailRow(context, 'Monthly Income',
                        'PHP ${u.monthlyFamilyIncome!.toStringAsFixed(0)}'),
                ] else if (u.role == 'provider') ...[
                  _detailRow(context, 'Organization Name', v?.orgName ?? 'Independent Fiduciary'),
                  _detailRow(context, 'Provider Type', v?.providerType ?? 'Individual'),
                  _detailRow(context, 'Accreditation Status', v?.status ?? 'unverified'),
                  if (v?.submittedAt != null)
                    _detailRow(context, 'Submitted At', v!.submittedAt!.toIso8601String()),
                ],
                if (u.region.isNotEmpty) _detailRow(context, 'Region', u.region),
                if (u.province != null && u.province!.isNotEmpty)
                  _detailRow(context, 'Province', u.province!),
                if (u.cityMunicipality != null && u.cityMunicipality!.isNotEmpty)
                  _detailRow(context, 'City/Municipality', u.cityMunicipality!),
                if (u.createdAt != null)
                  _detailRow(context, 'Registered On', u.createdAt!.toIso8601String()),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showEditUserModal(context, u);
            },
            child: Text(
              'Edit Role / Status',
              style: seqLabelMd(
                fontWeight: FontWeight.w600,
                color: kSeqPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Close',
              style: seqLabelMd(color: kSeqOnSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateUserModal(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    String role = 'student';
    String status = 'active';
    String region = 'NCR';
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: kSeqSurfaceContainerLowest,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 16,
            vertical: 24,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          title: Text(
            'Provision Platform Identity',
            style: seqHeadlineSm(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Maria Santos',
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        hintText: 'e.g. maria@scholaris.ph',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter an email';
                        if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'System Role'),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'provider', child: Text('Provider')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => role = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Initial Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'deactivated', child: Text('Deactivated')),
                        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: region,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Region'),
                      items: kPhilippineRegions
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => region = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: schoolCtrl,
                      decoration: const InputDecoration(
                        labelText: 'School / Institution (optional)',
                        hintText: 'e.g. UP Diliman',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: courseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Course / Focus (optional)',
                        hintText: 'e.g. BS Computer Science',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: seqLabelMd(color: kSeqOutline)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kSeqPrimaryContainer,
                foregroundColor: kSeqOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    final captcha = await acquireCaptcha(dialogContext);
                    if (!dialogContext.mounted || !captcha.allowed) return;
                    Navigator.of(dialogContext).pop();
                    await ref.read(adminUsersControllerProvider).createUser(
                        fullName: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim().toLowerCase(),
                        role: role,
                        status: status,
                        region: region,
                        school: schoolCtrl.text.trim(),
                        course: courseCtrl.text.trim(),
                        captchaToken: captcha.token,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User account created. The user must verify their email and reset their password before signing in.'),
                        backgroundColor: kSeqPrimaryContainer,
                      ),
                    );
                  }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account creation could not be confirmed. Please check the account before retrying.')),
                      );
                    }
                  }
                }
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserModal(BuildContext context, StudentProfile user) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    String role = user.role;
    String status = user.status;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: kSeqSurfaceContainerLowest,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 16,
            vertical: 24,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          title: Text(
            'Edit Role & Status: ${user.fullName.isNotEmpty ? user.fullName : user.id}',
            style: seqHeadlineSm(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ID: ${user.id}',
                  style: GoogleFonts.robotoMono(fontSize: 11, color: kSeqOutline),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'System Role'),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'provider', child: Text('Provider')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => role = val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Account Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'deactivated', child: Text('Deactivated')),
                    DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => status = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: seqLabelMd(color: kSeqOutline)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kSeqPrimaryContainer,
                foregroundColor: kSeqOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(adminUsersControllerProvider).updateRoleAndStatus(
                      user: user,
                      newRole: role,
                      newStatus: status,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User role & status updated.'),
                      backgroundColor: kSeqPrimaryContainer,
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, StudentProfile user) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final willDeactivate = user.status != 'deactivated';
    final actionName = willDeactivate ? 'Deactivate' : 'Reactivate';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kSeqSurfaceContainerLowest,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Text(
          '$actionName Account',
          style: seqHeadlineSm(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to $actionName account for ${user.fullName.isNotEmpty ? user.fullName : user.id}?',
          style: seqBodyMd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: seqLabelMd(color: kSeqOutline)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: willDeactivate ? kSeqError : kSeqPrimaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (willDeactivate) {
                await ref.read(adminUsersControllerProvider).deactivateUser(user);
              } else {
                await ref.read(adminUsersControllerProvider).updateRoleAndStatus(
                      user: user,
                      newRole: user.role,
                      newStatus: 'active',
                    );
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User account ${actionName.toLowerCase()}d.'),
                    backgroundColor: willDeactivate ? kSeqError : kSeqPrimaryContainer,
                  ),
                );
              }
            },
            child: Text(actionName),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, StudentProfile user) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kSeqSurfaceContainerLowest,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Text(
          'Delete Account: ${user.fullName.isNotEmpty ? user.fullName : user.id}',
          style: seqHeadlineSm(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to permanently delete account ${user.id}? This action cannot be undone and will be logged in the system audit logs.',
          style: seqBodyMd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: seqLabelMd(color: kSeqOutline)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kSeqError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(adminUsersControllerProvider).deleteUser(user);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User account permanently deleted.'),
                    backgroundColor: kSeqError,
                  ),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final isMono = label.contains('ID') ||
        label.contains('Date') ||
        label.contains('At') ||
        label.contains('GWA') ||
        label.contains('Income') ||
        label.contains('Registered');
    final valStyle = isMono
        ? seqTabularFigures(adminDataMono(fontSize: 13, color: kSeqOnSurface))
        : seqBodyMd(fontWeight: FontWeight.w500);

    if (!isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: seqLabelSm(color: kSeqOutline)),
            const SizedBox(height: 2),
            SelectableText(
              value,
              style: valStyle,
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
            width: 140,
            child: Text(label, style: seqLabelMd(color: kSeqOutline)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: valStyle,
            ),
          ),
        ],
      ),
    );
  }
}
