import 'package:scholaris/shared/theme/app_motion.dart' show opticalTracking, opticalLeading;
import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../../scholarships/models/scholarship.dart';
import '../org/org_provider_theme.dart';
import 'org_metric_count.dart';
import 'provider_overview_card.dart';

/// Organization overview: orient, show the next task, then reveal program detail.
class OrgOverviewWorkspace extends StatelessWidget {
  const OrgOverviewWorkspace({
    super.key,
    required this.name,
    required this.scholarships,
    required this.applicationCount,
    required this.pendingCount,
    required this.decidedCount,
    required this.onApplications,
    required this.onScholarships,
    this.onAnalytics,
    this.onTeam,
    this.onActivity,
  });
  final String name;
  final List<Scholarship> scholarships;
  final int applicationCount, pendingCount, decidedCount;
  final VoidCallback onApplications, onScholarships;
  final VoidCallback? onAnalytics, onTeam, onActivity;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 760;
      final deadlines =
          scholarships
              .where(
                (s) =>
                    s.isActive &&
                    !s.deadline.isBefore(DateUtils.dateOnly(DateTime.now())),
              )
              .toList()
            ..sort((a, b) => a.deadline.compareTo(b.deadline));
      final programs = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Scholarship programs',
            TextButton(
              onPressed: onScholarships,
              child: const Text('Manage scholarships'),
            ),
          ),
          const SizedBox(height: 12),
          ProviderOverviewCard(
            padding: EdgeInsets.zero,
            child: scholarships.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No scholarship programs yet',
                          style: AppTypography.style(AppTextRole.cardTitle, fontSize: 17, color: kOrgTextPrimary, letterSpacing: opticalTracking(17), height: opticalLeading(17, isBody: false)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a program to define eligibility, requirements, and deadlines.',
                          style: AppTypography.style(AppTextRole.body, fontSize: 14, color: kOrgTextSecondary, letterSpacing: opticalTracking(14), height: ((14) <= 16 ? 1.45 : opticalLeading(14, isBody: true))),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final s in scholarships) ...[
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title, style: AppTypography.style(AppTextRole.cardTitle, fontSize: 16, color: kOrgTextPrimary, letterSpacing: opticalTracking(16), height: opticalLeading(16, isBody: false))),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: s.isActive
                                          ? kOrgBadgeApprovedBg
                                          : const Color(0xFFF2F3F1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s.isActive ? 'Active' : 'Closed',
                                      style: AppTypography.style(AppTextRole.badge, color: s.isActive ? kOrgPrimary : kOrgTextSecondary, fontSize: 11.5, letterSpacing: opticalTracking(11.5), height: opticalLeading(11.5, isBody: false)),
                                    ),
                                  ),
                                  Text(
                                    '${s.formattedAmount} ${s.formattedFrequency}',
                                    style: AppTypography.style(AppTextRole.metric, fontSize: 13, color: kOrgTextSecondary, letterSpacing: opticalTracking(13), height: ((13) <= 16 ? 1.45 : opticalLeading(13, isBody: true))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (s != scholarships.last)
                          const Divider(height: 1, color: kOrgBorder),
                      ],
                    ],
                  ),
          ),
        ],
      );
      final secondary = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Upcoming deadlines'),
          const SizedBox(height: 24),
          if (deadlines.isEmpty)
            Text(
              'No upcoming deadlines for active programs.',
              style: AppTypography.style(AppTextRole.caption, fontSize: 14, color: kOrgTextSecondary, letterSpacing: opticalTracking(14), height: ((14) <= 16 ? 1.45 : opticalLeading(14, isBody: true))),
            ),
          for (final s in deadlines.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: kOrgPrimary,
                        ),
                        Text(
                          '${s.deadline.day}',
                          style: AppTypography.style(AppTextRole.caption, fontSize: 21, color: kOrgPrimary, letterSpacing: opticalTracking(21), height: opticalLeading(21, isBody: false)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: AppTypography.style(AppTextRole.bodyEmphasis, fontSize: 13, color: kOrgTextSecondary, letterSpacing: opticalTracking(13), height: opticalLeading(13, isBody: false))),
                        const SizedBox(height: 6),
                        Text(
                          MaterialLocalizations.of(context)
                              .formatFullDate(s.deadline),
                          style: AppTypography.style(AppTextRole.caption, fontSize: 12, color: kOrgTextSecondary, letterSpacing: opticalTracking(12), height: ((12) <= 16 ? 1.45 : opticalLeading(12, isBody: true))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Divider(color: kOrgBorder),
          const SizedBox(height: 20),
          Text('Workspace', style: AppTypography.style(AppTextRole.screenTitle, fontSize: 18, color: kOrgTextPrimary, letterSpacing: opticalTracking(18), height: opticalLeading(18, isBody: false))),
          const SizedBox(height: 12),
          if (onTeam != null)
            _workspaceAction(
              Icons.group_outlined,
              'Manage reviewers',
              'Team roles and review assignments',
              onTeam!,
            ),
          if (onActivity != null)
            _workspaceAction(
              Icons.history_rounded,
              'View activity',
              'Recorded organization actions',
              onActivity!,
            ),
        ],
      );
      return SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 20 : 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Organization overview',
                            style: AppTypography.style(AppTextRole.screenTitle, fontSize: compact ? 28 : 32, color: kOrgTextPrimary, letterSpacing: opticalTracking(compact ? 28 : 32), height: opticalLeading(compact ? 28 : 32, isBody: false)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name.trim().isEmpty
                                ? 'Scholarship administration'
                                : name,
                            style: AppTypography.style(AppTextRole.subtitle, fontSize: 15, color: kOrgTextSecondary, letterSpacing: opticalTracking(15), height: ((15) <= 16 ? 1.45 : opticalLeading(15, isBody: true))),
                          ),
                        ],
                      ),
                      if (onAnalytics != null)
                        OutlinedButton.icon(
                          onPressed: onAnalytics,
                          icon: const Icon(Icons.insights_outlined, size: 18),
                          label: const Text('View analytics'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, metricsBox) => Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final metric in [
                        _metric('Applications received', applicationCount),
                        _metric('Decisions recorded', decidedCount),
                        _metric(
                          'Active programs',
                          scholarships.where((s) => s.isActive).length,
                        ),
                      ])
                        SizedBox(
                          width: compact
                              ? metricsBox.maxWidth
                              : (metricsBox.maxWidth - 32) / 3,
                          child: metric,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ProviderOverviewCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingCount == 0
                            ? 'No applications awaiting review'
                            : '$pendingCount ${pendingCount == 1 ? 'application' : 'applications'} awaiting review',
                        style: AppTypography.style(AppTextRole.cardTitle, fontSize: compact ? 20 : 23, color: kOrgPrimary, letterSpacing: opticalTracking(compact ? 20 : 23), height: opticalLeading(compact ? 20 : 23, isBody: false)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pendingCount == 0
                            ? 'Submitted applications will appear in your review queue.'
                            : 'Review submitted requirements and record your team’s decision.',
                        style: AppTypography.style(AppTextRole.body, fontSize: 14, color: kOrgTextSecondary, letterSpacing: opticalTracking(14), height: ((14) <= 16 ? 1.45 : opticalLeading(14, isBody: true))),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: onApplications,
                        style: FilledButton.styleFrom(
                          backgroundColor: kOrgPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(
                          pendingCount == 0
                              ? 'View applications'
                              : 'Review applications',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                if (compact) ...[
                  programs,
                  const SizedBox(height: 32),
                  secondary,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: programs),
                      const SizedBox(width: 40),
                      Expanded(child: secondary),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _metric(String label, int count) => ProviderOverviewCard(
    heading: Text(
      label,
      style: AppTypography.style(AppTextRole.label, fontSize: 13, color: kOrgTextSecondary, letterSpacing: opticalTracking(13), height: ((13) <= 16 ? 1.45 : opticalLeading(13, isBody: true))),
    ),
    child: OrgMetricCount(
      motionId: 'overview.$label',
      targetValue: count,
      style: AppTypography.style(AppTextRole.metric, fontSize: 28, color: kOrgTextPrimary, letterSpacing: opticalTracking(28), height: opticalLeading(28, isBody: false)),
    ),
  );
  Widget _sectionHeading(String title, [Widget? action]) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 16,
    runSpacing: 4,
    children: [
      Text(title, style: AppTypography.style(AppTextRole.sectionTitle, fontSize: 19, color: kOrgTextPrimary, letterSpacing: opticalTracking(19), height: opticalLeading(19, isBody: false))),
      ?action,
    ],
  );
  Widget _workspaceAction(
    IconData icon,
    String title,
    String description,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: kOrgTextSecondary, size: 20),
      title: Text(title, style: AppTypography.style(AppTextRole.button, fontSize: 13, color: kOrgTextSecondary, letterSpacing: opticalTracking(13), height: opticalLeading(13, isBody: false))),
      subtitle: Text(
        description,
        style: AppTypography.style(AppTextRole.body, fontSize: 12, color: kOrgTextSecondary, letterSpacing: opticalTracking(12), height: ((12) <= 16 ? 1.45 : opticalLeading(12, isBody: true))),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: action,
    ),
  );
}
