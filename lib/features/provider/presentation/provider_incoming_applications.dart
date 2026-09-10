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

class ProviderIncomingApplications extends ConsumerWidget {
  const ProviderIncomingApplications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(incomingApplicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

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

                return scholarshipsAsync.when(
                  loading: () => const LoadingView(),
                  error: (_, _) => ErrorView(
                    message: 'Could not load scholarship details.',
                    onRetry: () => ref.invalidate(scholarshipsProvider),
                  ),
                  data: (all) {
                    final byId = <String, Scholarship>{
                      for (final s in all) s.id: s,
                    };
                    return _ApplicantNameBuilder(
                      applications: applications,
                      byId: byId,
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

/// Resolves each applicant's display name through a provider-scoped lookup and
/// renders the list. Kept as a separate widget so the applicant-name fetch can
/// be awaited once from here rather than re-reading per row.
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
        final nameByUserId = <String, String>{};
        if (profiles != null) {
          for (var i = 0; i < applicantIds.length; i++) {
            final profile = profiles[i];
            nameByUserId[applicantIds[i]] =
                profile?.fullName ?? 'Applicant';
          }
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          itemCount: applications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, i) => _IncomingApplicationRow(
            application: applications[i],
            scholarship: byId[applications[i].scholarshipId],
            applicantName:
                nameByUserId[applications[i].userId] ?? 'Applicant',
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
  });

  final Application application;
  final Scholarship? scholarship;
  final String applicantName;

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
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Update Application Status',
                  style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
                ),
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
                    try {
                      await ref
                          .read(applicationRepositoryProvider)
                          .updateStatus(application.id, status);
                      ref.read(incomingApplicationsProvider.notifier).refresh();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update status.')),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
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
