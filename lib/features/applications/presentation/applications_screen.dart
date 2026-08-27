// lib/features/applications/presentation/applications_screen.dart
//
// "My Applications" — the student's dedicated tracking surface. It lists only
// the currently authenticated user's applications (via [applicationsProvider],
// which is strictly user-scoped) with the associated scholarship information
// (amount, deadline, provider) resolved from the existing scholarship data
// layer, and each application's status rendered as a clear chip.
//
// This is a tracking surface only: it never lets the student edit their own
// status. Tapping an application opens the existing scholarship detail screen
// for reference.
//
// States: loading, error (with retry), empty (no applications yet), and the
// populated list. Uses the shared ResponsiveContainer and Loading/Empty/Error
// views so it stays consistent on narrow and wide screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'application_status_chip.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('My Applications')),
      body: ResponsiveContainer(
        child: applicationsAsync.when(
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
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: applications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _ApplicationCard(
                    application: applications[i],
                    scholarship: byId[applications[i].scholarshipId],
                  ),
                );
              },
            );
          },
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
      button: scholarshipKnown,
      label: scholarshipKnown
          ? 'View ${scholarship!.name}'
          : 'Application for an unavailable scholarship',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusCard),
          onTap: scholarshipKnown ? () => _openDetail(context) : null,
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

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScholarshipDetailScreen(
          scholarshipId: scholarship!.id,
          initial: scholarship,
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
