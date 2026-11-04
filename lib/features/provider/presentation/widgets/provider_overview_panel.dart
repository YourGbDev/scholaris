import 'package:scholaris/shared/theme/app_motion.dart' show opticalTracking, opticalLeading;
import 'package:scholaris/shared/theme/app_typography.dart';
import 'individual_support_summary.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../../providers/provider_sub_role_provider.dart';
import '../org/org_provider_theme.dart';
import 'org_overview_workspace.dart';
import 'org_metric_count.dart';
import 'provider_overview_card.dart';

/// Uses the existing provider-scoped repositories; no new writes or permissions.
class ProviderOverview extends ConsumerWidget {
  const ProviderOverview({
    super.key,
    required this.individual,
    required this.onApplications,
    required this.onScholarships,
    this.onTeam,
    this.onActivity,
    this.onAnalytics,
    this.onSupport,
    this.onPendingApplications,
  });
  final bool individual;
  final VoidCallback onApplications;
  final VoidCallback onScholarships;
  final VoidCallback? onTeam;
  final VoidCallback? onActivity;
  final VoidCallback? onAnalytics;
  final VoidCallback? onSupport;
  final VoidCallback? onPendingApplications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholarships = ref.watch(providerScholarshipsProvider);
    final applications = ref.watch(incomingApplicationsProvider);
    final identity = ref.watch(providerSubRoleProvider);
    if (scholarships.isLoading || applications.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (scholarships.hasError || applications.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your workspace could not load.',
                style: AppTypography.style(AppTextRole.cardTitle, fontSize: 20, color: kOrgTextPrimary, letterSpacing: opticalTracking(20), height: opticalLeading(20, isBody: false)),
              ),
              const SizedBox(height: 12),
              const Text('Check your connection and try again.'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(providerScholarshipsProvider);
                  ref.invalidate(incomingApplicationsProvider);
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final apps = applications.valueOrNull ?? [];
    final pending = apps
        .where(
          (a) =>
              a.status == ApplicationStatus.submitted ||
              a.status == ApplicationStatus.underReview,
        )
        .length;
    return ProviderOverviewPanel(
      name: identity.name,
      individual: individual,
      scholarships: scholarships.valueOrNull ?? [],
      applicationCount: apps
          .where((a) => a.status != ApplicationStatus.draft)
          .length,
      decidedCount: apps
          .where(
            (a) => [
              ApplicationStatus.approved,
              ApplicationStatus.rejected,
              ApplicationStatus.awarded,
            ].contains(a.status),
          )
          .length,
      pendingCount: pending,
      onApplications: onApplications,
      onScholarships: onScholarships,
      onTeam: onTeam,
      onActivity: onActivity,
      onAnalytics: onAnalytics,
      onSupport: onSupport,
      onPendingApplications: onPendingApplications,
    );
  }
}

class ProviderOverviewPanel extends StatelessWidget {
  const ProviderOverviewPanel({
    super.key,
    required this.name,
    required this.individual,
    required this.scholarships,
    required this.applicationCount,
    required this.pendingCount,
    required this.onApplications,
    required this.onScholarships,
    this.onTeam,
    this.onActivity,
    this.onAnalytics,
    this.onSupport,
    this.onPendingApplications,
    this.decidedCount = 0,
  });
  final String name;
  final bool individual;
  final List<Scholarship> scholarships;
  final int applicationCount;
  final int pendingCount;
  final VoidCallback onApplications;
  final VoidCallback onScholarships;
  final VoidCallback? onTeam;
  final VoidCallback? onActivity;
  final VoidCallback? onAnalytics;
  final VoidCallback? onSupport;
  final VoidCallback? onPendingApplications;
  final int decidedCount;

  @override
  Widget build(BuildContext context) {
    if (!individual) {
      return OrgOverviewWorkspace(
        name: name,
        scholarships: scholarships,
        applicationCount: applicationCount,
        pendingCount: pendingCount,
        decidedCount: decidedCount,
        onApplications: onApplications,
        onScholarships: onScholarships,
        onAnalytics: onAnalytics,
        onTeam: onTeam,
        onActivity: onActivity,
      );
    }
    final firstName = name.trim().isEmpty
        ? 'there'
        : name.trim().split(RegExp(r'\s+')).first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final hasActiveScholarship = scholarships.any((s) => s.isActive);
        final heroCard = Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 18 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFE1F1E5),
                    child: Icon(
                      Icons.school_rounded,
                      size: 19,
                      color: kOrgPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pendingCount > 0
                          ? 'APPLICATIONS TO REVIEW'
                          : hasActiveScholarship
                          ? 'YOUR IMPACT'
                          : 'GET STARTED',
                      style: AppTypography.style(AppTextRole.badge, fontSize: 11, color: kOrgPrimary, letterSpacing: 1, height: opticalLeading(11, isBody: false)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pendingCount > 0
                    ? '$pendingCount ${pendingCount == 1 ? 'application' : 'applications'} to review'
                    : hasActiveScholarship
                    ? 'You’re all caught up'
                    : 'Start your first scholarship',
                style: AppTypography.style(AppTextRole.cardTitle, fontSize: compact ? 20 : 23, color: kOrgPrimary, letterSpacing: opticalTracking(compact ? 20 : 23), height: opticalLeading(compact ? 20 : 23, isBody: false)),
              ),
              const SizedBox(height: 6),
              Text(
                pendingCount == 0
                    ? hasActiveScholarship
                          ? 'There are no applications awaiting review.'
                          : 'Visit your scholarships to create an opportunity for students.'
                    : '$pendingCount ${pendingCount == 1 ? 'application needs' : 'applications need'} a closer look. Take them one at a time.',
                style: AppTypography.style(AppTextRole.body, fontSize: 14, color: kOrgTextSecondary, letterSpacing: opticalTracking(14), height: ((14) <= 16 ? 1.45 : opticalLeading(14, isBody: true))),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: pendingCount == 0
                    ? onScholarships
                    : (onPendingApplications ?? onApplications),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  pendingCount == 0
                      ? 'View scholarships'
                      : 'Review applications',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: kOrgPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                ),
              ),
            ],
          ),
        );
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 20 : 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    individual
                        ? 'YOUR INDIVIDUAL PROVIDER WORKSPACE'
                        : 'YOUR ORGANIZATION WORKSPACE',
                    style: AppTypography.style(AppTextRole.label, fontSize: 10, color: kOrgTextSecondary, letterSpacing: 1.6, height: opticalLeading(10, isBody: false)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    individual
                        ? 'Hi, $firstName — a little support. A new beginning.'
                        : 'Organization overview',
                    style: AppTypography.style(AppTextRole.screenTitle, fontSize: compact ? 24 : 28, color: kOrgPrimary, letterSpacing: opticalTracking(compact ? 24 : 28), height: opticalLeading(compact ? 24 : 28, isBody: false)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F7EF),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFDDE5D4)),
                      image: compact
                          ? null
                          : const DecorationImage(
                              image: AssetImage(
                                'assets/images/provider_hero_illustration.png',
                              ),
                              fit: BoxFit.cover,
                              alignment: Alignment.topLeft,
                            ),
                    ),
                    child: compact
                        ? Column(
                            children: [
                              Image.asset(
                                'assets/images/provider_hero_illustration.png',
                                fit: BoxFit.cover,
                                excludeFromSemantics: true,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                child: heroCard,
                              ),
                            ],
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 300),
                            child: Row(
                              children: [
                                const Expanded(flex: 4, child: SizedBox()),
                                Expanded(
                                  flex: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: heroCard,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _metric(
                        'Active scholarships',
                        scholarships.where((s) => s.isActive).length,
                        compact,
                        constraints.maxWidth.clamp(0, 1280).toDouble(),
                        onScholarships,
                      ),
                      _metric(
                        'Applications received',
                        applicationCount,
                        compact,
                        constraints.maxWidth.clamp(0, 1280).toDouble(),
                        onApplications,
                      ),
                      _metric(
                        'Awaiting review',
                        pendingCount,
                        compact,
                        constraints.maxWidth.clamp(0, 1280).toDouble(),
                        onPendingApplications ?? onApplications,
                      ),
                    ],
                  ),
                  if (individual && onSupport != null) ...[
                    const SizedBox(height: 24),
                    IndividualSupportSummary(onOpen: onSupport!),
                  ],
                  if (!individual) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (onTeam != null)
                          OutlinedButton.icon(
                            onPressed: onTeam,
                            icon: const Icon(Icons.group_outlined, size: 18),
                            label: const Text('Manage reviewers'),
                          ),
                        if (onActivity != null)
                          OutlinedButton.icon(
                            onPressed: onActivity,
                            icon: const Icon(Icons.history_rounded, size: 18),
                            label: const Text('View activity'),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 36),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      Text(
                        'Your scholarship programs',
                        style: AppTypography.style(AppTextRole.sectionTitle, fontSize: 21, color: kOrgTextPrimary, letterSpacing: opticalTracking(21), height: opticalLeading(21, isBody: false)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kOrgPrimary,
                        ),
                        onPressed: onScholarships,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Manage scholarships'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (scholarships.isEmpty)
                    ProviderOverviewCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your first opportunity starts here.',
                            style: AppTypography.style(AppTextRole.cardTitle, fontSize: 18, color: kOrgTextPrimary, letterSpacing: opticalTracking(18), height: opticalLeading(18, isBody: false)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set your support, requirements, and application deadline in your scholarship workspace.',
                            style: AppTypography.style(AppTextRole.caption, color: kOrgTextSecondary, fontSize: 13.5, letterSpacing: opticalTracking(13.5), height: ((13.5) <= 16 ? 1.45 : opticalLeading(13.5, isBody: true))),
                          ),
                        ],
                      ),
                    )
                  else
                    ...scholarships.map(
                      (scholarship) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProviderOverviewCard(
                          padding: const EdgeInsets.all(22),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scholarship.title,
                                      style: AppTypography.style(AppTextRole.cardTitle, fontSize: 16, color: kOrgTextPrimary, letterSpacing: opticalTracking(16), height: opticalLeading(16, isBody: false)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${scholarship.formattedAmount} ${scholarship.formattedFrequency}',
                                      style: AppTypography.style(AppTextRole.metric, color: kOrgTextSecondary, fontSize: 13.5, letterSpacing: opticalTracking(13.5), height: ((13.5) <= 16 ? 1.45 : opticalLeading(13.5, isBody: true))),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: scholarship.isActive
                                      ? kOrgBadgeApprovedBg
                                      : const Color(0xFFF2F3F1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  scholarship.isActive ? 'Active' : 'Closed',
                                  style: AppTypography.style(AppTextRole.badge, color: scholarship.isActive ? kOrgPrimary : kOrgTextSecondary, fontSize: 11.5, letterSpacing: opticalTracking(11.5), height: opticalLeading(11.5, isBody: false)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    individual
                        ? 'Clear criteria. Thoughtful reviews. Decisions made by people.'
                        : 'Application and program information reflects recorded activity.',
                    style: AppTypography.style(AppTextRole.body, fontSize: 12, color: kOrgTextSecondary, letterSpacing: opticalTracking(12), height: ((12) <= 16 ? 1.45 : opticalLeading(12, isBody: true))),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metric(
    String label,
    int value,
    bool compact,
    double width,
    VoidCallback onTap,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        width: compact ? double.infinity : (width - 112) / 3,
        child: ProviderOverviewCard(
          heading: Text(
            label,
            style: AppTypography.style(AppTextRole.label, fontSize: 12, color: kOrgTextSecondary, letterSpacing: opticalTracking(12), height: ((12) <= 16 ? 1.45 : opticalLeading(12, isBody: true))),
          ),
          child: OrgMetricCount(
            motionId: 'individual-overview.$label',
            targetValue: value,
            style: AppTypography.style(AppTextRole.metric, fontSize: 30, color: kOrgTextPrimary, letterSpacing: opticalTracking(30), height: opticalLeading(30, isBody: false)),
          ),
        ),
      ),
    ),
  );
}
