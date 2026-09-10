import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

final adminScholarshipSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminScholarshipFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all'); // 'all', 'active', 'inactive'

class AdminScholarshipsTab extends ConsumerStatefulWidget {
  const AdminScholarshipsTab({super.key});

  @override
  ConsumerState<AdminScholarshipsTab> createState() => _AdminScholarshipsTabState();
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scholarship Catalog',
                  style: poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and inspect scholarship listings across all providers.',
                  style: openSans(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by scholarship or provider...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(adminScholarshipSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  onChanged: (val) => ref
                      .read(adminScholarshipSearchQueryProvider.notifier)
                      .state = val.trim().toLowerCase(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: statusFilter == 'all',
                      onTap: () => ref
                          .read(adminScholarshipFilterProvider.notifier)
                          .state = 'all',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Active',
                      selected: statusFilter == 'active',
                      onTap: () => ref
                          .read(adminScholarshipFilterProvider.notifier)
                          .state = 'active',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
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
                    final titleMatch = s.title.toLowerCase().contains(searchQuery);
                    final providerMatch =
                        s.provider?.toLowerCase().contains(searchQuery) ?? false;
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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _AdminScholarshipCard(scholarship: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminScholarshipCard extends StatefulWidget {
  const _AdminScholarshipCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  State<_AdminScholarshipCard> createState() => _AdminScholarshipCardState();
}

class _AdminScholarshipCardState extends State<_AdminScholarshipCard> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.scholarship.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scholarship;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
                      s.title,
                      style: poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.provider ?? 'Independent Provider',
                      style: openSans(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isActive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isActive
                        ? const Color(0xFF166534)
                        : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _InfoTag(
                icon: Icons.people_outline_rounded,
                text: s.slots != null ? '${s.slots} slots' : 'Open slots',
              ),
              _InfoTag(
                icon: Icons.grade_rounded,
                text: 'Min GPA ${s.minGpa.toStringAsFixed(1)}',
              ),
              if (s.locationRestriction != null)
                _InfoTag(
                  icon: Icons.location_on_outlined,
                  text: s.locationRestriction!,
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Publish Status',
                style: openSans(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Switch(
                value: _isActive,
                activeThumbColor: kPrimary,
                onChanged: (val) {
                  setState(() => _isActive = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${s.title} is now ${val ? "Active" : "Inactive"}.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kPrimary),
        const SizedBox(width: 4),
        Text(
          text,
          style: openSans(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kPrimary : kPrimarySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
  }
}
