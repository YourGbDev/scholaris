import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'admin_theme.dart';

final adminScholarshipSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminScholarshipFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all'); // 'all', 'active', 'inactive'

class AdminScholarshipsTab extends ConsumerStatefulWidget {
  const AdminScholarshipsTab({super.key});

  @override
  ConsumerState<AdminScholarshipsTab> createState() =>
      _AdminScholarshipsTabState();
}

class _AdminScholarshipsTabState extends ConsumerState<AdminScholarshipsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final searchQuery = ref.watch(adminScholarshipSearchQueryProvider);
    final statusFilter = ref.watch(adminScholarshipFilterProvider);

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
                  'Scholarship Catalog',
                  style: adminHeaderStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kAdminNavyTrust,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and inspect scholarship listings across all providers.',
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
                            hintText: 'Search by scholarship or provider...',
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
                                            adminScholarshipSearchQueryProvider
                                                .notifier,
                                          )
                                          .state = '';
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: kAdminHairline,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: kAdminHairline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: kAdminBridgeGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (val) => ref
                              .read(
                                adminScholarshipSearchQueryProvider.notifier,
                              )
                              .state = val.trim().toLowerCase(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FilterSegment(
                      label: 'All',
                      selected: statusFilter == 'all',
                      onTap: () => ref
                          .read(adminScholarshipFilterProvider.notifier)
                          .state = 'all',
                    ),
                    const SizedBox(width: 6),
                    _FilterSegment(
                      label: 'Active',
                      selected: statusFilter == 'active',
                      onTap: () => ref
                          .read(adminScholarshipFilterProvider.notifier)
                          .state = 'active',
                    ),
                    const SizedBox(width: 6),
                    _FilterSegment(
                      label: 'Inactive',
                      selected: statusFilter == 'inactive',
                      onTap: () => ref
                          .read(adminScholarshipFilterProvider.notifier)
                          .state = 'inactive',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: scholarshipsAsync.when(
              loading: () => const LoadingView(),
              error: (_, _) => const ErrorView(
                message: 'Failed to load scholarship catalog.',
              ),
              data: (allScholarships) {
                var list = allScholarships;
                if (searchQuery.isNotEmpty) {
                  list = list.where((s) {
                    final titleMatch =
                        s.title.toLowerCase().contains(searchQuery);
                    final providerMatch =
                        s.provider?.toLowerCase().contains(searchQuery) ??
                            false;
                    return titleMatch || providerMatch;
                  }).toList();
                }

                if (statusFilter == 'active') {
                  list = list.where((s) => s.isActive).toList();
                } else if (statusFilter == 'inactive') {
                  list = list.where((s) => !s.isActive).toList();
                }

                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No scholarships found',
                    message: 'Try changing your search keywords or filter.',
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kAdminHairline, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Dense Table Header
                        Container(
                          color: const Color(0xFFF9FAFB),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Program / Title',
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
                                  'Provider',
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
                                  'Deadline',
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
                                  'Slots',
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
                                  'Status',
                                  textAlign: TextAlign.center,
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
                        // Dense Table Rows
                        Expanded(
                          child: ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, color: kAdminHairline),
                            itemBuilder: (_, i) =>
                                _AdminScholarshipTableRow(scholarship: list[i]),
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
      color: selected
          ? kAdminBridgeGreen.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
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

class _AdminScholarshipTableRow extends StatefulWidget {
  const _AdminScholarshipTableRow({required this.scholarship});

  final Scholarship scholarship;

  @override
  State<_AdminScholarshipTableRow> createState() =>
      _AdminScholarshipTableRowState();
}

class _AdminScholarshipTableRowState extends State<_AdminScholarshipTableRow> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.scholarship.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scholarship;

    final deadlineStr =
        '${s.deadline.year}-${s.deadline.month.toString().padLeft(2, '0')}-${s.deadline.day.toString().padLeft(2, '0')}';
    final slotsStr = s.slots != null ? '${s.slots}' : 'Open';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              s.title,
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
            child: Text(
              s.provider ?? 'Independent Provider',
              style: adminBodyStyle(
                fontSize: 13,
                color: kAdminTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              deadlineStr,
              style: adminDataMono(
                fontSize: 12,
                color: kAdminTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              slotsStr,
              textAlign: TextAlign.right,
              style: adminDataMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kAdminNavyTrust,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isActive
                          ? kAdminBridgeGreen
                          : kAdminCoralConnect,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _isActive ? 'Active' : 'Inactive',
                      style: adminLabelStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isActive
                            ? kAdminBridgeGreen
                            : kAdminCoralConnect,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _isActive,
                  activeThumbColor: kAdminBridgeGreen,
                  onChanged: (val) {
                    setState(() => _isActive = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                              ? '${s.title} is now active'
                              : '${s.title} has been deactivated',
                          style: adminBodyStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
