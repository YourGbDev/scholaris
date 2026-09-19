import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final searchQuery = ref.watch(adminUserSearchQueryProvider);
    final roleFilter = ref.watch(adminUserRoleFilterProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management',
                            style: adminHeaderStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kAdminNavyTrust,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Inspect and administer all user accounts across students, providers, and admins.',
                            style: adminLabelStyle(
                              fontSize: 13,
                              color: kAdminTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kAdminBridgeGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: const RoundedRectangleBorder(
                          borderRadius: kAdminCardRadius,
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text(
                        'Create User',
                        style:
                            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _showCreateUserModal(context),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'User Management',
                        style: adminHeaderStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kAdminNavyTrust,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kAdminBridgeGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          shape: const RoundedRectangleBorder(
                            borderRadius: kAdminCardRadius,
                          ),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                        label: const Text(
                          'Create User',
                          style:
                              TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _showCreateUserModal(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspect and administer all user accounts across students, providers, and admins.',
                  style: adminLabelStyle(
                    fontSize: 12,
                    color: kAdminTextSecondary,
                  ),
                ),
              ],
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
                          hintText: 'Search by account name, email, or ID...',
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
                                            adminUserSearchQueryProvider.notifier)
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
                            .read(adminUserSearchQueryProvider.notifier)
                            .state = val.trim().toLowerCase(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh users',
                    color: kAdminNavyTrust,
                    onPressed: () => ref.invalidate(adminUsersProvider),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Role Filters Horizontally Scrollable Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _RoleFilterSegment(
                      label: 'All',
                      selected: roleFilter == 'all',
                      onTap: () => ref
                          .read(adminUserRoleFilterProvider.notifier)
                          .state = 'all',
                    ),
                    const SizedBox(width: 6),
                    _RoleFilterSegment(
                      label: 'Students',
                      selected: roleFilter == 'student',
                      onTap: () => ref
                          .read(adminUserRoleFilterProvider.notifier)
                          .state = 'student',
                    ),
                    const SizedBox(width: 6),
                    _RoleFilterSegment(
                      label: 'Providers',
                      selected: roleFilter == 'provider',
                      onTap: () => ref
                          .read(adminUserRoleFilterProvider.notifier)
                          .state = 'provider',
                    ),
                    const SizedBox(width: 6),
                    _RoleFilterSegment(
                      label: 'Admins',
                      selected: roleFilter == 'admin',
                      onTap: () => ref
                          .read(adminUserRoleFilterProvider.notifier)
                          .state = 'admin',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Data Body
        Expanded(
          child: usersAsync.when(
            loading: () => const LoadingView(),
            error: (_, _) => const ErrorView(
              message: 'Failed to load user directory.',
            ),
            data: (allUsers) {
              var list = allUsers;
              if (searchQuery.isNotEmpty) {
                list = list.where((u) {
                  final nameMatch =
                      u.fullName.toLowerCase().contains(searchQuery);
                  final idMatch = u.id.toLowerCase().contains(searchQuery);
                  final emailMatch = (u.email ?? '')
                      .toLowerCase()
                      .contains(searchQuery);
                  return nameMatch || idMatch || emailMatch;
                }).toList();
              }

              if (roleFilter != 'all') {
                list = list.where((u) => u.role == roleFilter).toList();
              }

              if (list.isEmpty) {
                return const EmptyView(
                  icon: Icons.group_off_rounded,
                  title: 'No users found',
                  message: 'Try changing your search keywords or role filter.',
                );
              }

              // Responsive: Wide table on Desktop (>= 768px), fluid card feed on Mobile (< 768px)
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

  Widget _buildDesktopTable(BuildContext context, List<StudentProfile> list) {
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
                    flex: 4,
                    child: Text(
                      'Account / identity',
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
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
                      'Account ID',
                      textAlign: TextAlign.right,
                      style: adminLabelStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kAdminNavyTrust,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Action',
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
                  final u = list[i];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.fullName.isNotEmpty
                                    ? u.fullName
                                    : 'Unnamed user',
                                style: adminHeaderStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kAdminNavyTrust,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (u.email != null && u.email!.isNotEmpty)
                                Text(
                                  u.email!,
                                  style: adminLabelStyle(
                                    fontSize: 11,
                                    color: kAdminTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildRoleBadge(u.role),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildStatusBadge(u),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            u.id.length > 12
                                ? '${u.id.substring(0, 12)}...'
                                : u.id,
                            textAlign: TextAlign.right,
                            style: adminDataMono(
                              fontSize: 11,
                              color: kAdminTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _showUserDetails(context, u),
                                child: Text(
                                  'Inspect',
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminBridgeGreen,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  size: 16,
                                  color: kAdminTextSecondary,
                                ),
                                tooltip: 'User actions',
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
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit Role / Status'),
                                  ),
                                  PopupMenuItem(
                                    value: 'deactivate',
                                    child: Text(
                                      u.status == 'deactivated'
                                          ? 'Reactivate Account'
                                          : 'Deactivate Account',
                                      style: const TextStyle(
                                          color: kAdminCoralConnect),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete Account',
                                      style: TextStyle(
                                          color: kAdminCoralConnect),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCardFeed(
      BuildContext context, List<StudentProfile> list) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final u = list[i];

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: kAdminCardRadius,
            side: BorderSide(color: kAdminHairline, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        u.fullName.isNotEmpty ? u.fullName : 'Unnamed user',
                        style: adminHeaderStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kAdminNavyTrust,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildRoleBadge(u.role),
                    ),
                    const SizedBox(width: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildStatusBadge(u),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (u.email != null && u.email!.isNotEmpty)
                  Text(
                    u.email!,
                    style: adminLabelStyle(
                      fontSize: 12,
                      color: kAdminNavyTrust,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'ID: ${u.id}',
                  style: adminDataMono(
                    fontSize: 11,
                    color: kAdminTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (u.region.isNotEmpty || u.course.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        if (u.course.isNotEmpty) u.course,
                        if (u.region.isNotEmpty) u.region,
                      ].join(' • '),
                      style: adminLabelStyle(
                        fontSize: 11,
                        color: kAdminTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showUserDetails(context, u),
                      child: Text(
                        'Inspect',
                        style: adminLabelStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kAdminBridgeGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showEditUserModal(context, u),
                      child: Text(
                        'Edit',
                        style: adminLabelStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kAdminNavyTrust,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 16,
                        color: kAdminTextSecondary,
                      ),
                      tooltip: 'User actions',
                      onSelected: (val) {
                        if (val == 'deactivate') {
                          _confirmDeactivate(context, u);
                        } else if (val == 'delete') {
                          _confirmDelete(context, u);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text(
                            u.status == 'deactivated'
                                ? 'Reactivate'
                                : 'Deactivate',
                            style: const TextStyle(color: kAdminCoralConnect),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete Account',
                            style: TextStyle(color: kAdminCoralConnect),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    String label;

    if (role == 'admin') {
      bg = kAdminNavyTrust.withValues(alpha: 0.10);
      fg = kAdminNavyTrust;
      label = 'Admin';
    } else if (role == 'provider') {
      bg = kAdminBridgeGreen.withValues(alpha: 0.10);
      fg = kAdminBridgeGreen;
      label = 'Provider';
    } else {
      bg = Colors.grey.withValues(alpha: 0.12);
      fg = kAdminTextSecondary;
      label = 'Student';
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: kAdminPillRadius,
        ),
        child: Text(
          label,
          style: adminLabelStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(StudentProfile u) {
    if (u.status == 'deactivated') {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: kAdminCoralConnect.withValues(alpha: 0.12),
            borderRadius: kAdminPillRadius,
          ),
          child: Text(
            'Deactivated',
            style: adminLabelStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kAdminCoralConnect,
            ),
          ),
        ),
      );
    }

    if (u.status == 'suspended') {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: kAdminGoldenOpportunity.withValues(alpha: 0.15),
            borderRadius: kAdminPillRadius,
          ),
          child: Text(
            'Suspended',
            style: adminLabelStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB28109),
            ),
          ),
        ),
      );
    }

    // Default 'active' status: inspect setupComplete
    final isSetup = u.setupComplete;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isSetup ? kAdminBridgeGreen : kAdminGoldenOpportunity,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isSetup ? 'Active' : 'Setup pending',
            style: adminLabelStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSetup ? kAdminBridgeGreen : kAdminGoldenOpportunity,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, StudentProfile u) {
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
                      u.fullName.isNotEmpty ? u.fullName : 'Unnamed user',
                      style: adminHeaderStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildRoleBadge(u.role),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    u.fullName.isNotEmpty ? u.fullName : 'Unnamed user',
                    style: adminHeaderStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildRoleBadge(u.role),
                  ),
                ],
              ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(context, 'Account ID', u.id),
                _detailRow(context, 'Email', u.email ?? 'Not specified'),
                _detailRow(
                    context,
                    'System role',
                    u.role == 'admin'
                        ? 'Admin'
                        : u.role == 'provider'
                            ? 'Provider'
                            : 'Student'),
                _detailRow(context, 'Account status', u.status),
                _detailRow(context, 'Profile status',
                    u.setupComplete ? 'Active' : 'Setup pending'),
                if (u.region.isNotEmpty) _detailRow(context, 'Region', u.region),
                if (u.province != null && u.province!.isNotEmpty)
                  _detailRow(context, 'Province', u.province!),
                if (u.cityMunicipality != null &&
                    u.cityMunicipality!.isNotEmpty)
                  _detailRow(context, 'City/Municipality', u.cityMunicipality!),
                if (u.school != null && u.school!.isNotEmpty)
                  _detailRow(context, 'School', u.school!),
                if (u.course.isNotEmpty) _detailRow(context, 'Course', u.course),
                _detailRow(context, 'Year level', 'Year ${u.yearLevel}'),
                _detailRow(context, 'GPA', u.gpa.toStringAsFixed(2)),
                if (u.monthlyFamilyIncome != null)
                  _detailRow(context, 'Monthly Income',
                      'PHP ${u.monthlyFamilyIncome!.toStringAsFixed(0)}'),
                if (u.hasDisability)
                  _detailRow(context, 'Disability', 'Declared'),
                if (u.isIndigenous)
                  _detailRow(context, 'Indigenous', 'Declared'),
                if (u.createdAt != null)
                  _detailRow(
                      context, 'Created At', u.createdAt!.toIso8601String()),
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
              style: adminLabelStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kAdminBridgeGreen),
            ),
          ),
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
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 16,
            vertical: 24,
          ),
          actionsOverflowButtonSpacing: 8,
          shape: const RoundedRectangleBorder(borderRadius: kAdminChromeRadius),
          title: Text(
            'Create User Account',
            style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter an email';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'System Role'),
                      items: const [
                        DropdownMenuItem(
                            value: 'student',
                            child: Text('Student',
                                overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'provider',
                            child: Text('Provider',
                                overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin',
                                overflow: TextOverflow.ellipsis)),
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
                        DropdownMenuItem(
                            value: 'active',
                            child: Text('Active',
                                overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'deactivated',
                            child: Text('Deactivated',
                                overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'suspended',
                            child: Text('Suspended',
                                overflow: TextOverflow.ellipsis)),
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
                          .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => region = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: schoolCtrl,
                      decoration: const InputDecoration(
                        labelText: 'School (optional)',
                        hintText: 'e.g. UP Diliman',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: courseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Course (optional)',
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
              child: Text(
                'Cancel',
                style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kAdminBridgeGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop();
                  await ref.read(adminUsersControllerProvider).createUser(
                        fullName: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim().toLowerCase(),
                        role: role,
                        status: status,
                        region: region,
                        school: schoolCtrl.text.trim(),
                        course: courseCtrl.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User account created successfully.'),
                        backgroundColor: kAdminBridgeGreen,
                      ),
                    );
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
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 16,
            vertical: 24,
          ),
          actionsOverflowButtonSpacing: 8,
          shape: const RoundedRectangleBorder(borderRadius: kAdminChromeRadius),
          title: Text(
            'Edit Role & Status: ${user.fullName}',
            style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                  style: adminDataMono(fontSize: 11, color: kAdminTextSecondary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'System Role'),
                  items: const [
                    DropdownMenuItem(
                        value: 'student',
                        child:
                            Text('Student', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'provider',
                        child:
                            Text('Provider', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admin', overflow: TextOverflow.ellipsis)),
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
                    DropdownMenuItem(
                        value: 'active',
                        child:
                            Text('Active', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'deactivated',
                        child: Text('Deactivated',
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'suspended',
                        child: Text('Suspended',
                            overflow: TextOverflow.ellipsis)),
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
              child: Text(
                'Cancel',
                style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kAdminBridgeGreen,
                foregroundColor: Colors.white,
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
                      backgroundColor: kAdminBridgeGreen,
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
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        actionsOverflowButtonSpacing: 8,
        shape: const RoundedRectangleBorder(borderRadius: kAdminChromeRadius),
        title: Text(
          '$actionName Account',
          style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          'Are you sure you want to $actionName account for ${user.fullName}?',
          style: adminBodyStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  willDeactivate ? kAdminCoralConnect : kAdminBridgeGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (willDeactivate) {
                await ref
                    .read(adminUsersControllerProvider)
                    .deactivateUser(user);
              } else {
                await ref
                    .read(adminUsersControllerProvider)
                    .updateRoleAndStatus(
                      user: user,
                      newRole: user.role,
                      newStatus: 'active',
                    );
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User account ${actionName.toLowerCase()}d.'),
                    backgroundColor:
                        willDeactivate ? kAdminCoralConnect : kAdminBridgeGreen,
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
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        actionsOverflowButtonSpacing: 8,
        shape: const RoundedRectangleBorder(borderRadius: kAdminChromeRadius),
        title: Text(
          'Delete Account: ${user.fullName}',
          style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          'Are you sure you want to permanently delete account ${user.id}? This action cannot be undone and will be logged in the immutable audit ledger.',
          style: adminBodyStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kAdminCoralConnect,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(adminUsersControllerProvider).deleteUser(user);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User account permanently deleted.'),
                    backgroundColor: kAdminCoralConnect,
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
            width: 130,
            child: Text(
              label,
              style: adminLabelStyle(fontSize: 12, color: kAdminTextSecondary),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: adminBodyStyle(
                fontSize: 13,
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

class _RoleFilterSegment extends StatelessWidget {
  const _RoleFilterSegment({
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
