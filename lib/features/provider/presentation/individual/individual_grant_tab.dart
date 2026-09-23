// lib/features/provider/presentation/individual/individual_grant_tab.dart
//
// 1–2 Grant Manager for Individual Benefactors.
// Simplified from the corporate multi-program portfolio into a lightweight,
// personal scholarship grant overview.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../org/org_provider_theme.dart';
import '../scholarship_form_screen.dart';

class IndividualGrantTab extends ConsumerWidget {
  const IndividualGrantTab({super.key});

  void _openCreateScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const ScholarshipFormScreen(),
      ),
    );
  }

  void _openEditScreen(BuildContext context, Scholarship scholarship) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => ScholarshipFormScreen(
          scholarshipId: scholarship.id,
          initialScholarship: scholarship,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholarshipsAsync = ref.watch(providerScholarshipsProvider);
    final incomingAppsAsync = ref.watch(incomingApplicationsProvider);

    return Container(
      color: kOrgCanvas,
      child: scholarshipsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: kOrgPrimary),
        ),
        error: (err, _) => Center(
          child: Text('Error loading grants: $err',
              style: orgBody(color: kOrgError)),
        ),
        data: (scholarships) {
          final apps = incomingAppsAsync.valueOrNull ?? [];

          return RefreshIndicator(
            color: kOrgPrimary,
            onRefresh: () async {
              ref.invalidate(providerScholarshipsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Sponsored Grants',
                            style: orgHeadline(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(
                          'Your active personal scholarship funds and student quota.',
                          style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded,
                          color: kOrgPrimary, size: 28),
                      tooltip: 'Sponsor Another Grant',
                      onPressed: () => _openCreateScreen(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (scholarships.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: kOrgSurfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kOrgBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.school_outlined,
                            size: 40, color: kOrgTextMuted),
                        const SizedBox(height: 8),
                        Text('No grants published yet',
                            style: orgHeadline(fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          'Publish your first student grant opportunity to begin supporting scholars.',
                          style: orgBody(
                              fontSize: 12, color: kOrgTextSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kOrgPrimary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _openCreateScreen(context),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Create Grant Opportunity'),
                        ),
                      ],
                    ),
                  )
                else
                  ...scholarships.map((s) {
                    final targetApps =
                        apps.where((a) => a.scholarshipId == s.id).toList();
                    final approvedCount = targetApps
                        .where((a) =>
                            a.status == ApplicationStatus.approved ||
                            a.status == ApplicationStatus.awarded)
                        .length;
                    final totalSlots = s.slots ?? 1;
                    final fillRatio = totalSlots > 0
                        ? (approvedCount / totalSlots).clamp(0.0, 1.0)
                        : 0.0;

                    final daysLeft = s.deadline.difference(DateTime.now()).inDays;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kOrgSurfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kOrgBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kOrgBadgeApprovedBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Active Grant',
                                    style: orgLabel(
                                        fontSize: 10,
                                        color: kOrgBadgeApprovedText)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 16, color: kOrgTextMuted),
                                onPressed: () => _openEditScreen(context, s),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(s.title, style: orgHeadline(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            s.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: orgBody(
                                fontSize: 12, color: kOrgTextSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GRANT STIPEND',
                                      style: orgLabel(
                                          fontSize: 9, color: kOrgTextMuted)),
                                  Text(
                                    s.slots != null
                                        ? '₱50,000 / Sem'
                                        : 'Full Grant',
                                    style: orgHeadline(
                                        fontSize: 16, color: kOrgPrimary),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('SCHOLAR CAPACITY',
                                      style: orgLabel(
                                          fontSize: 9, color: kOrgTextMuted)),
                                  Text(
                                    '$approvedCount / $totalSlots Slot${totalSlots == 1 ? '' : 's'}',
                                    style: orgHeadline(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fillRatio,
                              minHeight: 6,
                              backgroundColor: kOrgCanvas,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  kOrgPrimary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GWA ≤ ${s.minGpa.toStringAsFixed(2)} requirement',
                                style: orgBody(
                                    fontSize: 11, color: kOrgTextSecondary),
                              ),
                              if (daysLeft >= 0)
                                Text(
                                  '$daysLeft days left',
                                  style: orgLabel(
                                      fontSize: 10, color: kOrgPrimary),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
