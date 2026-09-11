import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
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

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          style: adminBodyStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search by account name or ID...',
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
                                      ref.read(adminUserSearchQueryProvider.notifier).state = '';
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            filled: true,
                            fillColor: Colors.white,
                            border: const OutlineInputBorder(
                              borderRadius: kAdminCardRadius,
                              borderSide: BorderSide(color: kAdminHairline, width: 1),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: kAdminCardRadius,
                              borderSide: BorderSide(color: kAdminHairline, width: 1),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: kAdminCardRadius,
                              borderSide: BorderSide(color: kAdminBridgeGreen, width: 1.5),
                            ),
                          ),
                          onChanged: (val) => ref
                              .read(adminUserSearchQueryProvider.notifier)
                              .state = val.trim().toLowerCase(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RoleFilterSegment(
                      label: 'All',
                      selected: roleFilter == 'all',
                      onTap: () => ref.read(adminUserRoleFilterProvider.notifier).state = 'all',
                    ),
                    const SizedBox(width: 6),
                    _RoleFilterSegment(
                      label: 'Students',
                      selected: roleFilter == 'student',
                      onTap: () => ref.read(adminUserRoleFilterProvider.notifier).state = 'student',
                    ),
                    const SizedBox(width: 6),
                    _RoleFilterSegment(
                      label: 'Providers',
                      selected: roleFilter == 'provider',
                      onTap: () => ref.read(adminUserRoleFilterProvider.notifier).state = 'provider',
                    ),
                    const SizedBox(width: 6),
                    _RoleFilterSegment(
                      label: 'Admins',
                      selected: roleFilter == 'admin',
                      onTap: () => ref.read(adminUserRoleFilterProvider.notifier).state = 'admin',
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                    final nameMatch = u.fullName.toLowerCase().contains(searchQuery);
                    final idMatch = u.id.toLowerCase().contains(searchQuery);
                    return nameMatch || idMatch;
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
                                flex: 3,
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
                                flex: 2,
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
                              final isSetup = u.setupComplete;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        u.fullName.isNotEmpty ? u.fullName : 'Unnamed user',
                                        style: adminHeaderStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kAdminNavyTrust,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: u.role == 'admin'
                                                  ? kAdminNavyTrust.withValues(alpha: 0.10)
                                                  : u.role == 'provider'
                                                      ? kAdminBridgeGreen.withValues(alpha: 0.10)
                                                      : Colors.grey.withValues(alpha: 0.12),
                                              borderRadius: kAdminPillRadius,
                                            ),
                                            child: Text(
                                              u.role == 'admin'
                                                  ? 'Admin'
                                                  : u.role == 'provider'
                                                      ? 'Provider'
                                                      : 'Student',
                                              style: adminLabelStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: u.role == 'admin'
                                                    ? kAdminNavyTrust
                                                    : u.role == 'provider'
                                                        ? kAdminBridgeGreen
                                                        : kAdminTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
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
                                          Flexible(
                                            child: Text(
                                              isSetup ? 'Active' : 'Setup pending',
                                              style: adminLabelStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSetup ? kAdminBridgeGreen : kAdminGoldenOpportunity,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        u.id.length > 12 ? '${u.id.substring(0, 12)}...' : u.id,
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
                                      flex: 2,
                                      child: Center(
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, StudentProfile u) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: kAdminChromeRadius),
        title: Text(
          u.fullName.isNotEmpty ? u.fullName : 'Unnamed user',
          style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Account ID', u.id),
              _detailRow('System role', u.role == 'admin' ? 'Admin' : u.role == 'provider' ? 'Provider' : 'Student'),
              _detailRow('Profile status', u.setupComplete ? 'Active' : 'Setup pending'),
              if (u.region.isNotEmpty) _detailRow('Region', u.region),
              if (u.course.isNotEmpty) _detailRow('Course', u.course),
            ],
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

  Widget _detailRow(String label, String value) {
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
            child: Text(
              value,
              style: adminBodyStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kAdminNavyTrust),
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
      color: selected ? kAdminBridgeGreen.withValues(alpha: 0.08) : Colors.white,
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
