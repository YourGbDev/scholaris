import 'package:flutter/material.dart';

import '../../../scholarships/models/scholarship.dart';
import '../org/org_provider_theme.dart';
import 'org_metric_count.dart';

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
          Container(
            width: double.infinity,
            decoration: _surface,
            child: scholarships.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No scholarship programs yet',
                          style: orgHeadline(fontSize: 17),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a program to define eligibility, requirements, and deadlines.',
                          style: orgBody(
                            fontSize: 14,
                            color: kOrgTextSecondary,
                          ),
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
                              Text(s.title, style: orgHeadline(fontSize: 16)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: s.isActive ? kOrgBadgeApprovedBg : const Color(0xFFF2F3F1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s.isActive ? 'Active' : 'Closed',
                                      style: orgLabel(
                                        color: s.isActive
                                            ? kOrgPrimary
                                            : kOrgTextSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${s.formattedAmount} ${s.formattedFrequency}',
                                    style: orgBody(
                                      fontSize: 13,
                                      color: kOrgTextSecondary,
                                    ),
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
              style: orgBody(fontSize: 14, color: kOrgTextSecondary),
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
                          style: orgHeadline(fontSize: 21, color: kOrgPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: orgLabel(fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          MaterialLocalizations.of(context)
                              .formatFullDate(s.deadline),
                          style: orgBody(
                            fontSize: 12,
                            color: kOrgTextSecondary,
                          ),
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
          Text('Workspace', style: orgHeadline(fontSize: 18)),
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
                            style: orgHeadline(fontSize: compact ? 28 : 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name.trim().isEmpty
                                ? 'Scholarship administration'
                                : name,
                            style: orgBody(
                              fontSize: 15,
                              color: kOrgTextSecondary,
                            ),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: kOrgBorder),
                      bottom: BorderSide(color: kOrgBorder),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _metric(
                          'Applications received',
                          applicationCount,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metric('Decisions recorded', decidedCount),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metric(
                          'Active programs',
                          scholarships.where((s) => s.isActive).length,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2E6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE5D4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingCount == 0
                            ? 'No applications awaiting review'
                            : '$pendingCount ${pendingCount == 1 ? 'application' : 'applications'} awaiting review',
                        style: orgHeadline(
                          fontSize: compact ? 20 : 23,
                          color: kOrgPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pendingCount == 0
                            ? 'Submitted applications will appear in your review queue.'
                            : 'Review submitted requirements and record your team’s decision.',
                        style: orgBody(fontSize: 14, color: kOrgTextSecondary),
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

  BoxDecoration get _surface => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: kOrgBorder),
    borderRadius: BorderRadius.circular(12),
  );
  Widget _metric(String label, int count) => SizedBox(
    width: 190,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrgMetricCount(motionId: 'overview.$label', targetValue: count, style: orgHeadline(fontSize: 28)),
        const SizedBox(height: 6),
        Text(label, style: orgBody(fontSize: 13, color: kOrgTextSecondary)),
      ],
    ),
  );
  Widget _sectionHeading(String title, [Widget? action]) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 16,
    runSpacing: 4,
    children: [
      Text(title, style: orgHeadline(fontSize: 19)),
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
      title: Text(title, style: orgLabel(fontSize: 13)),
      subtitle: Text(
        description,
        style: orgBody(fontSize: 12, color: kOrgTextSecondary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: action,
    ),
  );
}
