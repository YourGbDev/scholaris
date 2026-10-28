import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../providers/provider_scholarships_provider.dart';
import 'org_provider_theme.dart';
import '../widgets/org_metric_count.dart';

/// Submission cohorts, rather than a historical funnel inferred from current status.
List<Application> reviewCohort(
  List<Application> apps, {
  required DateTime now,
  int? days,
  String? scholarshipId,
}) => apps.where((a) {
  if (a.status == ApplicationStatus.draft) return false;
  if (scholarshipId != null && a.scholarshipId != scholarshipId) return false;
  if (days == null) return true;
  final date = a.appliedAt;
  return date != null &&
      !date.isBefore(now.subtract(Duration(days: days))) &&
      !date.isAfter(now);
}).toList();

double? averageDecisionDays(List<Application> apps) {
  final durations = apps
      .where(
        (a) =>
            [
              ApplicationStatus.approved,
              ApplicationStatus.rejected,
              ApplicationStatus.awarded,
            ].contains(a.status) &&
            a.appliedAt != null &&
            a.decidedAt != null &&
            !a.decidedAt!.isBefore(a.appliedAt!),
      )
      .map((a) => a.decidedAt!.difference(a.appliedAt!).inMinutes / 1440)
      .toList();
  return durations.isEmpty
      ? null
      : durations.reduce((a, b) => a + b) / durations.length;
}

class OrgReviewAnalyticsTab extends ConsumerWidget {
  const OrgReviewAnalyticsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(incomingApplicationsProvider);
    final programs = ref.watch(providerScholarshipsProvider);
    if (apps.isLoading || programs.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (apps.hasError || programs.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Analytics could not load. Check your connection.'),
            TextButton(
              onPressed: () {
                ref.invalidate(incomingApplicationsProvider);
                ref.invalidate(providerScholarshipsProvider);
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    return ReviewAnalyticsPanel(
      applications: apps.valueOrNull ?? [],
      scholarships: programs.valueOrNull ?? [],
    );
  }
}

class ReviewAnalyticsPanel extends StatefulWidget {
  const ReviewAnalyticsPanel({
    super.key,
    required this.applications,
    required this.scholarships,
  });
  final List<Application> applications;
  final List<Scholarship> scholarships;
  @override
  State<ReviewAnalyticsPanel> createState() => _ReviewAnalyticsPanelState();
}

class _ReviewAnalyticsPanelState extends State<ReviewAnalyticsPanel> {
  int _days = 0;
  String? _program;
  static const labels = {
    ApplicationStatus.submitted: 'Submitted',
    ApplicationStatus.underReview: 'Under review',
    ApplicationStatus.approved: 'Approved',
    ApplicationStatus.awarded: 'Awarded',
    ApplicationStatus.rejected: 'Not selected',
    ApplicationStatus.withdrawn: 'Withdrawn',
  };
  @override
  Widget build(BuildContext context) {
    final selected = widget.scholarships.any((s) => s.id == _program)
        ? _program
        : null;
    final cohort = reviewCohort(
      widget.applications,
      now: DateTime.now(),
      days: _days == 0 ? null : _days,
      scholarshipId: selected,
    );
    final counts = {
      for (final status in labels.keys)
        status: cohort.where((a) => a.status == status).length,
    };
    final decisionDays = averageDecisionDays(cohort);
    final programs = widget.scholarships
        .where((s) => selected == null || s.id == selected)
        .toList();
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 650;
        return SingleChildScrollView(
          padding: EdgeInsets.all(narrow ? 20 : 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORGANIZATION REPORTING',
                    style: orgLabel(fontSize: 10, letterSpacing: 1.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Application analytics',
                    style: orgHeadline(
                      fontSize: narrow ? 28 : 34,
                      color: kOrgPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Monitor application status, compare programs, and track review progress.',
                    style: orgBody(color: kOrgTextSecondary),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _days,
                          decoration: const InputDecoration(
                            labelText: 'Submitted within',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('All time')),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('Last 30 days'),
                            ),
                            DropdownMenuItem(
                              value: 90,
                              child: Text('Last 90 days'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _days = value ?? 0),
                        ),
                      ),
                      SizedBox(
                        width: narrow ? box.maxWidth - 40 : 280,
                        child: DropdownButtonFormField<String>(
                          initialValue: selected ?? '',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Scholarship program',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All programs'),
                            ),
                            ...widget.scholarships.map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => _program = value == '' ? null : value,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copy report (CSV)'),
                        onPressed: () async {
                          final rows = [
                            'Metric,Count',
                            'Program id,${selected ?? 'All programs'}',
                            'Submission window,${_days == 0 ? 'All time' : 'Last $_days days'}',
                            'Applications,${cohort.length}',
                            ...labels.entries.map(
                              (e) => '${e.value},${counts[e.key]}',
                            ),
                            'Average decision days,${decisionDays?.toStringAsFixed(1) ?? 'Not available'}',
                          ];
                          await Clipboard.setData(
                            ClipboardData(text: rows.join('\r\n')),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Summary copied as CSV. Paste it into your spreadsheet.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _summary('Applications', '${cohort.length}'),
                      _summary(
                        'Awaiting review',
                        '${counts[ApplicationStatus.submitted]! + counts[ApplicationStatus.underReview]!}',
                      ),
                      _summary(
                        'Approved / awarded',
                        '${counts[ApplicationStatus.approved]! + counts[ApplicationStatus.awarded]!}',
                      ),
                      _summary(
                        'Average decision time',
                        decisionDays == null
                            ? 'Not available'
                            : '${decisionDays.toStringAsFixed(1)} days',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _surface(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Where applications stand',
                          style: orgHeadline(fontSize: 21),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cohort.isEmpty
                              ? 'No submitted applications in this selection.'
                              : 'Current status of ${cohort.length} ${cohort.length == 1 ? 'application' : 'applications'} in this submission cohort.',
                          style: orgBody(color: kOrgTextSecondary),
                        ),
                        const SizedBox(height: 24),
                        ...labels.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.value, style: orgBody()),
                                    Text('${counts[e.key]}', style: orgLabel()),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Semantics(
                                  label:
                                      '${e.value}: ${counts[e.key]} of ${cohort.length} applications',
                                  child: LinearProgressIndicator(
                                    value: cohort.isEmpty
                                        ? 0
                                        : counts[e.key]! / cohort.length,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                    color: e.key == ApplicationStatus.rejected
                                        ? const Color(0xFF87684A)
                                        : kOrgPrimary,
                                    backgroundColor: const Color(0xFFEDF0E9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Program comparison',
                    style: orgHeadline(fontSize: 21),
                  ),
                  const SizedBox(height: 16),
                  if (programs.isEmpty)
                    const Text(
                      'Create a scholarship program to start comparing intake.',
                    ),
                  ...programs.map((s) {
                    final apps = cohort
                        .where((a) => a.scholarshipId == s.id)
                        .toList();
                    final approved = apps
                        .where(
                          (a) =>
                              a.status == ApplicationStatus.approved ||
                              a.status == ApplicationStatus.awarded,
                        )
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _surface(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title, style: orgHeadline(fontSize: 17)),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 28,
                              runSpacing: 12,
                              children: [
                                Text('${apps.length} applications'),
                                Text('$approved approved / awarded'),
                                Text(
                                  '${s.slots?.toString() ?? 'Unspecified'} total slots',
                                ),
                                Text('${s.formattedAmount} · ${s.frequency}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(
                    'Drafts are excluded. Date filters use submission time; undated applications appear only in All time. Decision time uses recorded submission and decision timestamps. Scholarship values describe offered support, not money disbursed.',
                    style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summary(String label, String value) => SizedBox(
    width: 195,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: orgBody(fontSize: 13, color: kOrgTextSecondary)),
        const SizedBox(height: 8),
        if (int.tryParse(value) case final int count)
          OrgMetricCount(motionId: 'review-analytics.$label', targetValue: count, style: orgHeadline(fontSize: 26, color: kOrgPrimary))
        else Text(value, style: orgHeadline(fontSize: 26, color: kOrgPrimary)),
      ],
    ),
  );
  Widget _surface(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: kOrgBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}
