// lib/features/provider/presentation/provider_incoming_applications.dart
//
// Read-only "Incoming Applications" list for /provider-home. Shows applications
// submitted to scholarships the signed-in provider owns (resolved via
// [incomingApplicationsProvider], which is scoped to scholarships.created_by).
//
// Both the applicant name and the scholarship title are resolved through
// separate client-side lookups — exactly how the student side resolves
// scholarship titles (applications_screen.dart builds a
// Map<String, Scholarship> byId from [scholarshipsProvider]):
//   - scholarship title  → [scholarshipsProvider] (all active scholarships)
//   - applicant full name → [currentProfileProvider]-style lookup, but fetched
//     per applicant id through [profileRepositoryProvider] (the
//     providers_select_applicant_profiles RLS policy already live in Supabase
//     lets a provider read only the applicants who applied to their own
//     scholarships).
//
// The screen is strictly read-only: it renders loading / error / empty states
// with the shared LoadingView / ErrorView / EmptyView and rows carrying the
// applicant name, scholarship title, applied date and status chip. No writes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/application_status_chip.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

final providerStatusFilterProvider =
    StateProvider.autoDispose<ApplicationStatus?>((ref) => null);

class ProviderIncomingApplications extends ConsumerWidget {
  const ProviderIncomingApplications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(incomingApplicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final selectedStatus = ref.watch(providerStatusFilterProvider);

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Incoming Applications',
              style: poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ),
          Expanded(
            child: applicationsAsync.when(
              loading: () => const LoadingView(),
              error: (_, _) => ErrorView(
                message: 'Could not load incoming applications.',
                onRetry: () => ref.invalidate(incomingApplicationsProvider),
              ),
              data: (applications) {
                if (applications.isEmpty) {
                  return const EmptyView(
                    icon: Icons.inbox_outlined,
                    title: 'No applications yet',
                    message:
                        'Applications submitted to scholarships you own will '
                        'appear here.',
                  );
                }

                final counts = <ApplicationStatus, int>{
                  for (final s in const [
                    ApplicationStatus.submitted,
                    ApplicationStatus.underReview,
                    ApplicationStatus.approved,
                    ApplicationStatus.rejected,
                  ])
                    s: applications.where((a) => a.status == s).length,
                };

                final filteredApplications = selectedStatus == null
                    ? applications
                    : applications
                        .where((a) => a.status == selectedStatus)
                        .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: _ProviderStatusFilterBar(
                        counts: counts,
                        totalCount: applications.length,
                        selected: selectedStatus,
                        onSelect: (status) => ref
                            .read(providerStatusFilterProvider.notifier)
                            .state = status,
                      ),
                    ),
                    Expanded(
                      child: filteredApplications.isEmpty
                          ? EmptyView(
                              icon: Icons.filter_list_off_rounded,
                              title:
                                  'No ${ApplicationStatusUi.of(selectedStatus!).label.toLowerCase()} applications',
                              message:
                                  'No incoming applications match this status filter.',
                            )
                          : scholarshipsAsync.when(
                              loading: () => const LoadingView(),
                              error: (_, _) => ErrorView(
                                message: 'Could not load scholarship details.',
                                onRetry: () =>
                                    ref.invalidate(scholarshipsProvider),
                              ),
                              data: (all) {
                                final byId = <String, Scholarship>{
                                  for (final s in all) s.id: s,
                                };
                                return _ApplicantNameBuilder(
                                  applications: filteredApplications,
                                  byId: byId,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Resolves each applicant's profile through a provider-scoped lookup and
/// renders the list. Kept as a separate widget so the applicant-profile fetch
/// can be awaited once from here rather than re-reading per row.
class _ApplicantNameBuilder extends ConsumerWidget {
  const _ApplicantNameBuilder({
    required this.applications,
    required this.byId,
  });

  final List<Application> applications;
  final Map<String, Scholarship> byId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Distinct applicant ids → one profile lookup each (RLS permits a provider
    // to read only applicants who applied to their own scholarships).
    final applicantIds = applications.map((a) => a.userId).toSet().toList();
    final repository = ref.watch(profileRepositoryProvider);

    return FutureBuilder<List<StudentProfile?>>(
      future: Future.wait(
        applicantIds.map((id) => repository.fetchProfileById(id)),
      ),
      builder: (context, snapshot) {
        final profiles = snapshot.data;
        final profileByUserId = <String, StudentProfile?>{};
        if (profiles != null) {
          for (var i = 0; i < applicantIds.length; i++) {
            profileByUserId[applicantIds[i]] = profiles[i];
          }
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(incomingApplicationsProvider.notifier).refresh(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: applications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _IncomingApplicationRow(
              application: applications[i],
              scholarship: byId[applications[i].scholarshipId],
              applicantName:
                  profileByUserId[applications[i].userId]?.fullName ??
                      'Applicant',
              applicantProfile: profileByUserId[applications[i].userId],
            ),
          ),
        );
      },
    );
  }
}

class _IncomingApplicationRow extends ConsumerWidget {
  const _IncomingApplicationRow({
    required this.application,
    required this.scholarship,
    required this.applicantName,
    this.applicantProfile,
  });

  final Application application;
  final Scholarship? scholarship;
  final String applicantName;
  final StudentProfile? applicantProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = scholarship?.title ?? 'Scholarship unavailable';
    final appliedLabel = application.appliedAt == null
        ? 'Not submitted yet'
        : 'Applied ${_formatDate(application.appliedAt!)}';

    final isTerminal = application.status == ApplicationStatus.approved ||
        application.status == ApplicationStatus.rejected ||
        application.status == ApplicationStatus.withdrawn;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(kRadiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusCard),
        onTap: isTerminal ? null : () => _showStatusSheet(context, ref),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusCard),
            boxShadow: const [
              BoxShadow(
                color: kCardShadow,
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
                      title,
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
                applicantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: openSans(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    icon: Icons.event_rounded,
                    label: appliedLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref) {
    final validNextStatuses = <ApplicationStatus>[];
    if (application.status == ApplicationStatus.submitted) {
      validNextStatuses.addAll([
        ApplicationStatus.underReview,
        ApplicationStatus.approved,
        ApplicationStatus.rejected,
      ]);
    } else if (application.status == ApplicationStatus.underReview) {
      validNextStatuses.addAll([
        ApplicationStatus.approved,
        ApplicationStatus.rejected,
      ]);
    }

    if (validNextStatuses.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Update Application Status',
                    style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                if (applicantProfile != null)
                  _ApplicantCredentialsCard(
                    profile: applicantProfile!,
                    notes: application.notes,
                  ),
              for (final status in validNextStatuses)
                ListTile(
                  leading: Icon(
                    ApplicationStatusUi.of(status).icon,
                    color: ApplicationStatusUi.of(status).foreground,
                  ),
                  title: Text(ApplicationStatusUi.of(status).label),
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();

                    final isTerminalTransition =
                        status == ApplicationStatus.approved ||
                        status == ApplicationStatus.rejected;

                    if (isTerminalTransition) {
                      final confirmed =
                          await _confirmTerminalStatus(context, status);
                      if (!confirmed) return;
                    }

                    try {
                      await ref
                          .read(applicationRepositoryProvider)
                          .updateStatus(application.id, status);
                      ref.read(incomingApplicationsProvider.notifier).refresh();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update status.'),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
  }

  Future<bool> _confirmTerminalStatus(
    BuildContext context,
    ApplicationStatus status,
  ) async {
    final actionLabel =
        status == ApplicationStatus.approved ? 'Approve' : 'Reject';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '$actionLabel Application',
          style: poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to ${actionLabel.toLowerCase()} the application for $applicantName? This decision is final.',
          style: openSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  status == ApplicationStatus.approved ? kPrimary : kError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ApplicantCredentialsCard extends StatelessWidget {
  const _ApplicantCredentialsCard({
    required this.profile,
    this.notes,
  });

  final StudentProfile profile;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.fullName,
            style: poppins(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _credentialRow(Icons.school_outlined, profile.course),
          if (profile.school != null && profile.school!.isNotEmpty)
            _credentialRow(Icons.account_balance_outlined, profile.school!),
          _credentialRow(
            Icons.timeline_rounded,
            'Year ${profile.yearLevel} · GPA ${profile.gpa.toStringAsFixed(1)}',
          ),
          _credentialRow(Icons.location_on_outlined, profile.region),
          if (notes != null && notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Applicant Note',
                    style: poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notes!,
                    style: openSans(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _credentialRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: openSans(fontSize: 13, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderStatusFilterBar extends StatelessWidget {
  const _ProviderStatusFilterBar({
    required this.counts,
    required this.totalCount,
    required this.selected,
    required this.onSelect,
  });

  final Map<ApplicationStatus, int> counts;
  final int totalCount;
  final ApplicationStatus? selected;
  final ValueChanged<ApplicationStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ProviderStatusFilterChip(
            key: const ValueKey('provider-filter-all'),
            label: 'All',
            count: totalCount,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final status in const [
            ApplicationStatus.submitted,
            ApplicationStatus.underReview,
            ApplicationStatus.approved,
            ApplicationStatus.rejected,
          ]) ...[
            const SizedBox(width: 8),
            _ProviderStatusFilterChip(
              key: ValueKey('provider-filter-${status.dbValue}'),
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

class _ProviderStatusFilterChip extends StatelessWidget {
  const _ProviderStatusFilterChip({
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
            style: openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
