// lib/features/applications/presentation/applications_screen.dart
//
// "My Applications" — the student's dedicated tracking surface. It lists only
// the currently authenticated user's applications (via [applicationsProvider],
// which is strictly user-scoped) with the associated scholarship information
// (amount, deadline, provider) resolved from the existing scholarship data
// layer, and each application's status rendered as a clear chip.
//
// Day 10 turns this into a first-class tracking surface:
//   - a status filter bar (All / Draft / Submitted / Under review / Approved /
//     Rejected) with live per-status counts, backed by the reactive, user-
//     scoped [applicationFilterProvider];
//   - a compact summary bar showing total / pending / approved visibility;
//   - filtered empty states that let the student jump back to All.
//
// This is a tracking surface only: it never lets the student edit their own
// status. Tapping an application opens the existing scholarship detail screen
// for reference.
//
// The screen can be embedded as a Home tab body ([embedded]) — where it renders
// its own header inside the shell — or pushed as a standalone screen (from the
// Profile tab) with a Scaffold + AppBar. Both share the same tracking body.
//
// States: loading, error (with retry), empty (no applications yet), and the
// populated list. Uses the shared ResponsiveContainer and Loading/Empty/Error
// views so it stays consistent on narrow and wide screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'application_detail_screen.dart';
import 'application_status_chip.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key, this.embedded = false});

  /// True when this screen is rendered as a Home tab body (no own Scaffold or
  /// AppBar); false when pushed as a standalone screen.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = _buildTrackingBody(context, ref);

    if (embedded) {
      return SafeArea(
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Text(
                  'My Applications',
                  style: poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('My Applications')),
      body: ResponsiveContainer(child: body),
    );
  }

  Widget _buildTrackingBody(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final filteredAsync = ref.watch(filteredApplicationsProvider);

    return applicationsAsync.when(
      loading: () => const LoadingView(),
      error: (_, _) => ErrorView(
        message: 'Could not load your applications.',
        onRetry: () => ref.invalidate(applicationsProvider),
      ),
      data: (applications) {
        if (applications.isEmpty) {
          return const EmptyView(
            icon: Icons.send_outlined,
            title: 'No applications yet',
            message:
                'When you apply to a scholarship it will show up here so '
                'you can track its status.',
          );
        }

        final counts = ApplicationFilters.statusCounts(applications);
        final status = ref.watch(applicationFilterProvider).status;
        final filtered = filteredAsync.valueOrNull ?? const <Application>[];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _SummaryBar(applications: applications),
              const SizedBox(height: 12),
              _StatusFilterBar(
                counts: counts,
                selected: status,
                onSelect: (s) =>
                    ref.read(applicationFilterProvider.notifier).select(s),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? _buildFilteredEmpty(context, ref, status)
                    : scholarshipsAsync.when(
                        loading: () => const LoadingView(),
                        error: (_, _) => ErrorView(
                          message: 'Could not load scholarship details.',
                          onRetry: () => ref.invalidate(scholarshipsProvider),
                        ),
                        data: (all) {
                          final byId = <String, Scholarship>{
                            for (final s in all) s.id: s,
                          };
                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 32),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (_, i) => _ApplicationCard(
                              application: filtered[i],
                              scholarship: byId[filtered[i].scholarshipId],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilteredEmpty(
    BuildContext context,
    WidgetRef ref,
    ApplicationStatus? status,
  ) {
    final label = status == null
        ? 'this status'
        : ApplicationStatusUi.of(status).label.toLowerCase();
    return Center(
      child: EmptyView(
        icon: Icons.filter_alt_off_outlined,
        title: 'No $label applications',
        message:
            'You have no applications with this status yet. Tap another '
            'status or show all applications to keep tracking.',
        actionLabel: 'Show all applications',
        onAction: () => ref.read(applicationFilterProvider.notifier).reset(),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.applications});

  final List<Application> applications;

  @override
  Widget build(BuildContext context) {
    final total = applications.length;
    final pending = ApplicationFilters.pendingCount(applications);
    final approved = ApplicationFilters.approvedCount(applications);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryPill(
          key: const ValueKey('application-summary-total'),
          icon: Icons.send_outlined,
          label: '$total Total',
        ),
        _SummaryPill(
          key: const ValueKey('application-summary-pending'),
          icon: Icons.schedule_rounded,
          label: '$pending Pending',
        ),
        _SummaryPill(
          key: const ValueKey('application-summary-approved'),
          icon: Icons.check_circle_outline_rounded,
          label: '$approved Approved',
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final Map<ApplicationStatus, int> counts;
  final ApplicationStatus? selected;
  final ValueChanged<ApplicationStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusFilterChip(
            key: const ValueKey('application-filter-all'),
            label: 'All',
            count: total,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final status in ApplicationStatus.values) ...[
            const SizedBox(width: 8),
            _StatusFilterChip(
              key: ValueKey('application-filter-${status.dbValue}'),
              label: ApplicationStatusUi.of(status).label,
              count: counts[status] ?? 0,
              selected: selected == status,
              onTap: () => onSelect(status),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : kPrimary;
    final background = selected ? kPrimary : kPrimarySoft;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label ($count)',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              '$label ($count)',
              style: poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.scholarship,
  });

  final Application application;
  final Scholarship? scholarship;

  @override
  Widget build(BuildContext context) {
    final scholarshipKnown = scholarship != null;

    return Semantics(
      button: true,
      label: scholarshipKnown
          ? 'Open application for ${scholarship!.name}'
          : 'Open application',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusCard),
          onTap: () => _openApplicationDetail(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusCard),
              boxShadow: const [
                BoxShadow(
                  color: kPrimarySoft,
                  blurRadius: 16,
                  offset: Offset(0, 6),
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
                      child: Text(
                        scholarship?.name ?? 'Scholarship unavailable',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ApplicationStatusChip(status: application.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  scholarship?.provider ??
                      'This scholarship is no longer active.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: openSans(fontSize: 13, color: Colors.black54),
                ),
                if (scholarshipKnown) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPeso(scholarship!.amount),
                        style: poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            _coverageLabel(scholarship!.coverageType),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: openSans(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (scholarshipKnown)
                      _MetaChip(
                        icon: Icons.event_rounded,
                        label: deadlineLabel(scholarship!.deadline),
                      ),
                    if (application.appliedAt != null)
                      _MetaChip(
                        icon: Icons.send_rounded,
                        label: 'Applied ${_formatDate(application.appliedAt!)}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openApplicationDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ApplicationDetailScreen(
          applicationId: application.id,
          initial: application,
        ),
      ),
    );
  }

  String _coverageLabel(String? coverageType) {
    switch (coverageType) {
      case 'full':
        return '· full coverage';
      case 'partial':
        return '· partial coverage';
      case 'stipend':
        return '· stipend';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: openSans(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary),
          ),
        ],
      ),
    );
  }
}
