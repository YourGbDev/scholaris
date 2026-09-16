// lib/features/provider/presentation/provider_scholarships_tab.dart
//
// "My Scholarships" management tab for the Provider Console.
// Allows scholarship providers to view, filter, create, edit, toggle, and delete listings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../../shared/widgets/state_views.dart';
import '../../applications/providers/applications_provider.dart';
import '../../scholarships/models/scholarship.dart';
import '../providers/provider_scholarships_provider.dart';
import 'scholarship_form_screen.dart';

class ProviderScholarshipsTab extends ConsumerStatefulWidget {
  const ProviderScholarshipsTab({super.key});

  @override
  ConsumerState<ProviderScholarshipsTab> createState() =>
      _ProviderScholarshipsTabState();
}

class _ProviderScholarshipsTabState
    extends ConsumerState<ProviderScholarshipsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const ScholarshipFormScreen(),
      ),
    );
  }

  void _openEditScreen(Scholarship scholarship) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => ScholarshipFormScreen(
          scholarshipId: scholarship.id,
          initialScholarship: scholarship,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Scholarship scholarship, int applicantCount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Scholarship?',
          style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${scholarship.title}"?',
              style: openSans(fontSize: 14),
            ),
            if (applicantCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kErrorSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: kError, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This scholarship has $applicantCount student application(s). '
                        'Deactivating instead of deleting is strongly recommended.',
                        style: openSans(
                          fontSize: 12,
                          color: kError,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: openSans(color: Colors.black54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kError),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: openSans(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(providerScholarshipsProvider.notifier)
            .deleteScholarship(scholarship.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${scholarship.title}".')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete scholarship: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scholarshipsAsync = ref.watch(providerScholarshipsProvider);
    final filteredAsync = ref.watch(filteredProviderScholarshipsProvider);
    final statusFilter = ref.watch(providerScholarshipStatusFilterProvider);
    final applicationsAsync = ref.watch(incomingApplicationsProvider);

    final incomingApps = applicationsAsync.valueOrNull ?? const [];

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Create button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Scholarships',
                        style: poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your active grants, deadlines, and eligibility criteria.',
                        style: openSans(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openCreateScreen,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'New Program',
                    style: openSans(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Overview Metrics Bar (when data is loaded)
          scholarshipsAsync.maybeWhen(
            data: (all) {
              if (all.isEmpty) return const SizedBox.shrink();
              final activeCount = all.where((s) => s.isActive).length;
              final closedCount = all.length - activeCount;

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    _MetricPill(
                      label: 'Total',
                      count: all.length,
                      color: kPrimary,
                    ),
                    const SizedBox(width: 8),
                    _MetricPill(
                      label: 'Active',
                      count: activeCount,
                      color: const Color(0xFF1B7A43),
                    ),
                    const SizedBox(width: 8),
                    _MetricPill(
                      label: 'Closed',
                      count: closedCount,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    _MetricPill(
                      label: 'Applicants',
                      count: incomingApps.length,
                      color: kNavyTrust,
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      style: openSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search programs...',
                        hintStyle:
                            openSans(fontSize: 13, color: Colors.black38),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Colors.black45,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(
                                        providerScholarshipSearchQueryProvider
                                            .notifier,
                                      )
                                      .state = '';
                                  setState(() {});
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
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                      ),
                      onChanged: (val) {
                        ref
                            .read(
                              providerScholarshipSearchQueryProvider.notifier,
                            )
                            .state = val;
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'All',
                  selected: statusFilter == 'all',
                  onTap: () => ref
                      .read(providerScholarshipStatusFilterProvider.notifier)
                      .state = 'all',
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Active',
                  selected: statusFilter == 'active',
                  onTap: () => ref
                      .read(providerScholarshipStatusFilterProvider.notifier)
                      .state = 'active',
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Closed',
                  selected: statusFilter == 'closed',
                  onTap: () => ref
                      .read(providerScholarshipStatusFilterProvider.notifier)
                      .state = 'closed',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Scholarships List
          Expanded(
            child: filteredAsync.when(
              loading: () => const LoadingView(),
              error: (err, _) => ErrorView(
                message: 'Could not load your scholarships.',
                onRetry: () =>
                    ref.read(providerScholarshipsProvider.notifier).refresh(),
              ),
              data: (scholarships) {
                if (scholarships.isEmpty) {
                  final query = ref.watch(providerScholarshipSearchQueryProvider);
                  if (query.isNotEmpty || statusFilter != 'all') {
                    return const EmptyView(
                      icon: Icons.search_off_rounded,
                      title: 'No matching scholarships',
                      message: 'Try adjusting your search query or filter.',
                    );
                  }
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kPrimarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              size: 36,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No scholarship programs yet',
                            style: poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Publish your organization\'s scholarships so eligible Filipino students can discover and apply for them.',
                            textAlign: TextAlign.center,
                            style: openSans(fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openCreateScreen,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create First Scholarship'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: scholarships.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final s = scholarships[index];
                    final applicantCount = incomingApps
                        .where((app) => app.scholarshipId == s.id)
                        .length;

                    return _ScholarshipCard(
                      scholarship: s,
                      applicantCount: applicantCount,
                      onEdit: () => _openEditScreen(s),
                      onToggleActive: (val) {
                        ref
                            .read(providerScholarshipsProvider.notifier)
                            .toggleActive(s.id, val);
                      },
                      onDelete: () => _confirmDelete(s, applicantCount),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: openSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: openSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? kPrimary : Colors.black12,
          ),
        ),
        child: Text(
          label,
          style: openSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _ScholarshipCard extends StatelessWidget {
  const _ScholarshipCard({
    required this.scholarship,
    required this.applicantCount,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Scholarship scholarship;
  final int applicantCount;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = scholarship;
    final isActive = s.isActive;
    final deadlineStr = deadlineLabel(s.deadline);
    final isPassed = isDeadlinePassed(s.deadline);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.black12 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isActive ? kPrimary : Colors.black54,
                        ),
                      ),
                      if (s.provider != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.provider!,
                          style: openSans(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1B7A43).withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Closed',
                    style: openSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF1B7A43)
                          : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),

            if (s.description != null && s.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: openSans(fontSize: 13, color: Colors.black87),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 10),

            // Metadata Chips: Deadline, GPA, Slots, Applicants
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Deadline chip
                _InfoChip(
                  icon: Icons.event_rounded,
                  label: deadlineStr,
                  color: isPassed
                      ? kError
                      : (isClosingSoon(s.deadline.difference(DateTime.now()).inDays)
                          ? kAccent
                          : kPrimary),
                ),
                // Min GPA chip
                _InfoChip(
                  icon: Icons.grade_rounded,
                  label: 'Min GPA ${s.minGpa.toStringAsFixed(1)}',
                  color: Colors.black87,
                ),
                // Slots chip
                _InfoChip(
                  icon: Icons.group_rounded,
                  label: s.slots != null ? '${s.slots} slots' : 'Open slots',
                  color: Colors.black87,
                ),
                // Applicants chip
                _InfoChip(
                  icon: Icons.send_rounded,
                  label: '$applicantCount applicant${applicantCount == 1 ? '' : 's'}',
                  color: kNavyTrust,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Actions: Toggle Active Switch, Edit, Delete
            Row(
              children: [
                Text(
                  'Accepting Applications',
                  style: openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isActive,
                    activeThumbColor: kPrimary,
                    onChanged: onToggleActive,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Scholarship',
                  color: kPrimary,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Delete Scholarship',
                  color: kError,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: openSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
