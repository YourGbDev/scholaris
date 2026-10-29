import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/admin/presentation/admin_analytics_provider.dart';
import '../../features/admin/presentation/admin_theme.dart' show kAdminCardDecoration;
import '../../features/provider/repositories/support_concern_repository.dart';
import '../../features/safety/data/safety_report_repository.dart';
import '../../features/safety/models/safety_report.dart';
import '../../features/scholarships/providers/scholarships_provider.dart';
import '../../shared/theme/app_motion.dart';
import '../models/safety_report_presentation.dart';
import 'support_concerns_screen.dart';

class ReportsSafetyScreen extends ConsumerStatefulWidget {
  const ReportsSafetyScreen({super.key});
  @override
  ConsumerState<ReportsSafetyScreen> createState() =>
      _ReportsSafetyScreenState();
}

class _ReportsSafetyScreenState extends ConsumerState<ReportsSafetyScreen> {
  String _search = '', _filter = 'Unresolved', _provider = '';

  void _support() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Payment & support')),
            body: const SupportConcernsScreen(),
          ),
        ),
      );

  void _openSafetyReviewDialog(BuildContext parentCtx, String reportId) {
    final noteController = TextEditingController();
    String selectedStatus = 'under_review';
    String? error;
    bool saving = false;

    showDialog<void>(
      context: parentCtx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Update report status'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select review outcome:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'under_review',
                        child: Text('Under review'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Resolved'),
                      ),
                      DropdownMenuItem(
                        value: 'dismissed',
                        child: Text('Dismissed'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Review explanation note (required, 10–1000 characters):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Explain the inquiry findings, registrar verification, or resolution for this report.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Color(0xFF93000A),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (saving) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dlgCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F4D2E),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final note = noteController.text.trim();
                      if (note.length < 10 || note.length > 1000) {
                        setDlgState(
                          () => error =
                              'A review explanation between 10 and 1000 characters is required.',
                        );
                        return;
                      }
                      setDlgState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await ref
                            .read(adminSafetyReportsProvider.notifier)
                            .review(
                              reportId: reportId,
                              status: selectedStatus,
                              note: note,
                            );
                        if (!context.mounted) return;
                        Navigator.pop(dlgCtx);
                        ScaffoldMessenger.of(parentCtx).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Safety report updated to ${selectedStatus.replaceAll('_', ' ')}.',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        setDlgState(() {
                          saving = false;
                          error = 'Failed to record review: $e';
                        });
                      }
                    },
              child: const Text('Confirm decision'),
            ),
          ],
        ),
      ),
    );
  }

  void _detail(SafetyReportGroup group) => showDialog<void>(
        animationStyle: isReducedMotion(context)
            ? AnimationStyle.noAnimation
            : null,
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(group.scholarshipTitle),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(group.providerName),
                  if (group.providerId != null)
                    SelectableText('Provider ID: ${group.providerId}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Private admin review. Counts indicate review priorities, not findings of wrongdoing.',
                  ),
                  for (final row in group.reports) ...[
                    const Divider(height: 32),
                    Text(
                      _categoryLabels[row['category']] ??
                          supportConcernCategories[row['category']] ??
                          'Support concern',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    Text(
                      'Status: ${row['status']?.toString().replaceAll('_', ' ') ?? 'Unavailable'}',
                    ),
                    Text('Reported: ${_date(safetyReportDate(row))}'),
                    Text(
                      'Relationship: ${_relationshipLabels[row['relationship']] ?? 'Not recorded'}',
                    ),
                    SelectableText(
                      'Application: ${row['application_id'] ?? 'Direct scholarship concern (no application)'}',
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      row['description']?.toString() ??
                          'Description unavailable',
                    ),
                    if (row['resolution_note'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Latest update: ${row['resolution_note']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (row['evidence'] is List &&
                        (row['evidence'] as List).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Attached evidence:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      for (final ev in (row['evidence'] as List)) ...[
                        Builder(
                          builder: (btnCtx) {
                            final fileName = ev is SafetyReportEvidence
                                ? ev.fileName
                                : (ev is Map ? ev['file_name'] : 'Evidence file');
                            final filePath = ev is SafetyReportEvidence
                                ? ev.filePath
                                : (ev is Map ? ev['file_path'] : '');
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.attach_file, size: 16),
                                label: Text(fileName.toString()),
                                onPressed: filePath == null ||
                                        filePath.toString().isEmpty
                                    ? null
                                    : () async {
                                        try {
                                          final repo = ref.read(
                                            safetyReportRepositoryProvider,
                                          );
                                          final url = await repo
                                              .getEvidenceSignedUrl(
                                            filePath.toString(),
                                          );
                                          await launchUrl(
                                            Uri.parse(url),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Could not open evidence: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                    if (row['is_safety_report'] == true &&
                        row['id'] != null &&
                        !['resolved', 'dismissed'].contains(row['status'])) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: const Text('Update report status'),
                        onPressed: () => _openSafetyReviewDialog(
                          ctx,
                          row['id'].toString(),
                        ),
                      ),
                    ],
                  ],
                  const Divider(height: 32),
                  const Text(
                    'Relationships are shown only when recorded. Student reports and attached evidence are strictly confidential to authorized administrators.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _support();
              },
              child: const Text('Open supported review'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final safetyReportsAsync = ref.watch(adminSafetyReportsProvider);
    final concerns = ref.watch(supportConcernsProvider(null));
    final apps = ref.watch(adminAllApplicationsProvider);
    final programs = ref.watch(scholarshipsProvider);

    final failed = safetyReportsAsync.hasError ||
        concerns.hasError ||
        apps.hasError ||
        programs.hasError;
    final loading = safetyReportsAsync.isLoading ||
        concerns.isLoading ||
        apps.isLoading ||
        programs.isLoading;

    // Combine safety reports from migration 0032 with legacy support concerns
    final List<Map<String, dynamic>> combinedRows = [];
    if (safetyReportsAsync.hasValue) {
      for (final report in safetyReportsAsync.requireValue) {
        combinedRows.add({
          'id': report.id,
          'scholarship_id': report.scholarshipId,
          'provider_id': report.providerId,
          'reporter_id': report.reporterId,
          'category': report.category,
          'relationship': report.relationship,
          'description': report.description,
          'status': report.status,
          'resolution_note': report.resolutionNote,
          'created_at': report.createdAt?.toIso8601String(),
          'scholarship_title': report.scholarshipTitle,
          'is_safety_report': true,
          'evidence': report.evidence,
        });
      }
    }
    if (concerns.hasValue) {
      combinedRows.addAll(concerns.requireValue);
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Reports & safety',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF0F4D2E),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Review private student concerns by scholarship. One serious report deserves attention. Report volume does not establish wrongdoing or trigger penalties.',
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _support,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Payment & support'),
          ),
        ),
        const Text(
          'Provider payment correction requests stay in Payment & support and are excluded from this queue.',
        ),
        const SizedBox(height: 24),
        if (failed) ...[
          const Text('Reports could not be loaded.'),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                ref.invalidate(adminSafetyReportsProvider);
                ref.invalidate(supportConcernsProvider(null));
                ref.invalidate(adminAllApplicationsProvider);
                ref.invalidate(scholarshipsProvider);
              },
              child: const Text('Try again'),
            ),
          ),
        ] else if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ..._queue(
            groupSafetyReports(
              combinedRows,
              apps.requireValue,
              programs.requireValue,
            ),
          ),
      ],
    );
  }

  List<Widget> _queue(List<SafetyReportGroup> groups) {
    final providerIds = groups
        .map((g) => g.providerId)
        .whereType<String>()
        .toSet();
    final effectiveProvider = providerIds.contains(_provider) ? _provider : '';
    final filtered = groups.where((g) {
      final query =
          '${g.scholarshipTitle} ${g.providerName} ${g.providerId ?? ''}'
              .toLowerCase();
      return query.contains(_search.toLowerCase()) &&
          (effectiveProvider.isEmpty || g.providerId == effectiveProvider) &&
          (_filter == 'All' ||
              (_filter == 'Urgent' ? g.urgent : g.openReports > 0));
    }).toList();
    return [
      TextField(
        decoration: const InputDecoration(
          labelText: 'Search scholarship or provider',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in ['Unresolved', 'Urgent', 'All'])
            ChoiceChip(
              label: Text(label),
              selected: _filter == label,
              onSelected: (_) => setState(() => _filter = label),
            ),
        ],
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: ValueKey(effectiveProvider),
        initialValue: effectiveProvider,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Provider'),
        items: [
          const DropdownMenuItem(value: '', child: Text('All providers')),
          for (final id in providerIds)
            DropdownMenuItem(
              value: id,
              child: Text(
                '${groups.firstWhere((g) => g.providerId == id).providerName} · $id',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (v) => setState(() => _provider = v ?? ''),
      ),
      const SizedBox(height: 24),
      if (filtered.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: kAdminCardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 24,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No reports match these filters.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2939),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try clearing your search query or selecting a different review status.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF667085),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      for (final g in filtered)
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (g.urgent)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Needs urgent review',
                      style: TextStyle(
                        color: Color(0xFF9A3412),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  g.scholarshipTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(g.providerName),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${g.totalReports} report${g.totalReports == 1 ? '' : 's'}',
                    ),
                    Text(
                      '${g.distinctReporters} distinct reporter${g.distinctReporters == 1 ? '' : 's'}',
                    ),
                    Text('${g.openReports} unresolved'),
                    Text(
                      '${g.recentDistinctReporters} distinct reporter${g.recentDistinctReporters == 1 ? '' : 's'} in 24h',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Oldest unresolved: ${_date(g.oldestOpenAt)}'),
                if (g.recentDistinctReporters >= 3)
                  const Text('Multiple reporters · review priority'),
                if (g.scholarshipId == null || g.providerId == null)
                  const Text(
                    'Incomplete context. Related records may be unavailable.',
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _detail(g),
                  child: const Text('View reports'),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 12),
      const Text(
        'Student safety reports and evidence are securely isolated and accessible only to authorized administrators.',
      ),
    ];
  }

  static const _categoryLabels = {
    'unsafe_meetup': 'Unsafe meetup request',
    'unsafe_request': 'Unsafe meetup request',
    'harassment': 'Harassment',
    'threat': 'Threat or coercion',
    'fraud': 'Suspected fraud',
    'release_fee': 'Demand for fee',
    'payment_problem': 'Payment problem',
    'payment_not_received': 'Payment problem',
    'other': 'Other concern',
  };
  static const _relationshipLabels = {
    'experienced': 'First-hand experience',
    'first_hand': 'First-hand experience',
    'witnessed': 'Witnessed incident',
    'told': 'Someone told the reporter',
  };
  static String _date(DateTime? value) => value == null
      ? 'Unavailable'
      : value.toLocal().toString().substring(0, 16);
}
