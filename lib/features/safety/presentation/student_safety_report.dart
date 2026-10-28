// lib/features/safety/presentation/student_safety_report.dart
//
// Student safety reporting interface.
// Confidential scholarship-level safety reports independent of applications.
// Fully compliant with RA 10173 student privacy protections.

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/safety_report_repository.dart';

class StudentSafetyReportButton extends ConsumerWidget {
  const StudentSafetyReportButton({
    super.key,
    required this.scholarshipId,
    required this.scholarshipTitle,
    this.isIconOnly = false,
  });

  final String scholarshipId;
  final String scholarshipTitle;
  final bool isIconOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isIconOnly) {
      return IconButton(
        tooltip: 'Report safety or integrity concern',
        icon: const Icon(
          Icons.shield_outlined,
          size: 22,
          color: Color(0xFF555D58),
        ),
        onPressed: () => _openDialog(context),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF93000A),
        side: const BorderSide(color: Color(0xFFFFDAD6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.shield_outlined, size: 18),
      label: const Text('Report concern'),
      onPressed: () => _openDialog(context),
    );
  }

  void _openDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => StudentSafetyReportDialog(
        scholarshipId: scholarshipId,
        scholarshipTitle: scholarshipTitle,
      ),
    );
  }
}

class StudentSafetyReportDialog extends ConsumerStatefulWidget {
  const StudentSafetyReportDialog({
    super.key,
    required this.scholarshipId,
    required this.scholarshipTitle,
    this.initialAttachments,
  });

  final String scholarshipId;
  final String scholarshipTitle;
  final List<({String name, Uint8List bytes, int size})>? initialAttachments;

  @override
  ConsumerState<StudentSafetyReportDialog> createState() =>
      _StudentSafetyReportDialogState();
}

class _StudentSafetyReportDialogState
    extends ConsumerState<StudentSafetyReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'fraud';
  String _selectedRelationship = 'experienced';
  DateTime? _incidentDate;
  bool _submitting = false;
  String? _errorMessage;
  bool _submitted = false;
  String? _persistedReportId;
  int _seq = 0;
  final Set<String> _attachedIds = {};
  final List<({String id, String name, Uint8List bytes, int size})> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialAttachments != null) {
      for (final a in widget.initialAttachments!) {
        _attachedFiles.add((
          id: 'att_${++_seq}',
          name: a.name,
          bytes: a.bytes,
          size: a.size,
        ));
      }
    }
  }

  static const _categories = [
    MapEntry('fraud', 'Fraud or scam'),
    MapEntry('unsafe_meetup', 'Unsafe or private meetup'),
    MapEntry('harassment', 'Harassment or misconduct'),
    MapEntry('threat', 'Threat or intimidation'),
    MapEntry('release_fee', 'Demand for fee or payment'),
    MapEntry('payment_problem', 'Delayed or unreleased stipend'),
    MapEntry('other', 'Other concern'),
  ];

  static const _relationships = [
    MapEntry('experienced', 'It happened to me (first-hand)'),
    MapEntry('witnessed', 'I saw or witnessed it'),
    MapEntry('told', 'I was told about it by someone else'),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    if (_attachedFiles.length >= 3) {
      setState(() => _errorMessage = 'Maximum of 3 evidence files allowed.');
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          if (file.size > 5 * 1024 * 1024) {
            setState(() =>
                _errorMessage = 'File "${file.name}" exceeds 5 MB limit.');
            return;
          }
          setState(() {
            _errorMessage = null;
            _attachedFiles.add(
              (id: 'att_${++_seq}', name: file.name, bytes: file.bytes!, size: file.size),
            );
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not select file: $e');
    }
  }

  Future<void> _pickIncidentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(safetyReportRepositoryProvider);
      final String reportId;
      if (_persistedReportId != null) {
        reportId = _persistedReportId!;
      } else {
        reportId = await repo.submitReport(
          scholarshipId: widget.scholarshipId,
          category: _selectedCategory,
          relationship: _selectedRelationship,
          description: _descriptionController.text.trim(),
          incidentOn: _incidentDate,
        );
        _persistedReportId = reportId;

        // Invalidate history immediately upon report persistence
        final userId = ref.read(currentUserIdProvider);
        if (userId != null) {
          ref.invalidate(studentSafetyReportsProvider(userId));
        }
        ref.invalidate(adminSafetyReportsProvider);
      }

      for (final file in _attachedFiles) {
        if (_attachedIds.contains(file.id)) continue;
        await repo.attachEvidence(
          reportId: reportId,
          bytes: file.bytes,
          fileName: file.name,
          attachmentKey: file.id,
        );
        _attachedIds.add(file.id);
      }

      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.invalidate(studentSafetyReportsProvider(userId));
      }
      ref.invalidate(adminSafetyReportsProvider);

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      final userId = ref.read(currentUserIdProvider);
      if (userId != null && _persistedReportId != null) {
        ref.invalidate(studentSafetyReportsProvider(userId));
      }
      if (_persistedReportId != null) {
        ref.invalidate(adminSafetyReportsProvider);
      }
      setState(() {
        _submitting = false;
        final msg = e.toString();
        if (_persistedReportId != null) {
          _errorMessage =
              'Report recorded, but evidence upload failed. Tap "Retry Evidence Upload" to complete attaching files.';
        } else if (msg.contains('Daily report submission limit')) {
          _errorMessage =
              'You have reached the daily report limit (5 reports per 24 hours). If you need immediate assistance, contact support.';
        } else if (msg.contains('one_open_safety_report') ||
            msg.contains('duplicate')) {
          _errorMessage =
              'You already have an active report for this scholarship and category. Our platform team is reviewing it.';
        } else {
          _errorMessage =
              'Could not submit report. Your draft has been preserved. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF0F4D2E)),
            SizedBox(width: 8),
            Text('Report submitted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you for reporting this concern regarding "${widget.scholarshipTitle}".',
            ),
            const SizedBox(height: 12),
            const Text(
              'Your report is kept strictly confidential. Platform administrators will review your concern. Scholarship providers never receive your identity, report text, or notes.',
              style: TextStyle(color: Color(0xFF555D58), fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F4D2E),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF93000A)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Report safety or integrity concern',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.scholarshipTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: Color(0xFF555D58),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 18, color: Color(0xFF0F4D2E)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Strictly confidential. Reviewed by platform safety administrators only. Providers cannot view reports.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0F4D2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Concern category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c.key,
                            child: Text(c.value, style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: _submitting || _persistedReportId != null
                      ? null
                      : (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                ),
                const SizedBox(height: 16),
                const Text(
                  'How are you connected to this concern?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRelationship,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _relationships
                      .map((r) => DropdownMenuItem(
                            value: r.key,
                            child: Text(r.value, style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: _submitting || _persistedReportId != null
                      ? null
                      : (val) {
                          if (val != null) setState(() => _selectedRelationship = val);
                        },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Incident date (optional)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    TextButton.icon(
                      onPressed: _submitting || _persistedReportId != null
                          ? null
                          : _pickIncidentDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(
                        _incidentDate != null
                            ? _incidentDate!.toIso8601String().substring(0, 10)
                            : 'Select date',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Description of concern',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  readOnly: _submitting || _persistedReportId != null,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        'Please describe what occurred in detail. Minimum 10 characters.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 10) {
                      return 'Please provide at least 10 characters describing the issue.';
                    }
                    if (val.trim().length > 2000) {
                      return 'Description cannot exceed 2000 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Evidence files (optional, up to 3)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _submitting || _attachedFiles.length >= 3
                          ? null
                          : _pickEvidence,
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: const Text(
                        'Add file',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (_attachedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < _attachedFiles.length; i++)
                        Chip(
                          avatar: _attachedIds.contains(_attachedFiles[i].id)
                              ? const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0F4D2E))
                              : null,
                          label: Text(
                            _attachedFiles[i].name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: _attachedIds.contains(_attachedFiles[i].id)
                              ? null
                              : const Icon(Icons.close, size: 14),
                          onDeleted: (_submitting || _attachedIds.contains(_attachedFiles[i].id))
                              ? null
                              : () =>
                                  setState(() => _attachedFiles.removeAt(i)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('View your report history'),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog<void>(
                        context: context,
                        builder: (_) =>
                            const StudentSafetyReportHistoryDialog(),
                      );
                    },
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFF93000A),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_submitting) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, _persistedReportId != null),
          child: Text(_persistedReportId != null ? 'Close' : 'Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF93000A),
          ),
          onPressed: _submitting ? null : _submit,
          child: Text(_persistedReportId != null ? 'Retry Evidence Upload' : 'Submit report'),
        ),
      ],
    );
  }
}

class StudentSafetyReportHistoryDialog extends ConsumerWidget {
  const StudentSafetyReportHistoryDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return AlertDialog(
        title: const Text('Report history'),
        content: const Text('Please sign in to view your report history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    final reportsAsync = ref.watch(studentSafetyReportsProvider(userId));

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.history, color: Color(0xFF0F4D2E)),
          SizedBox(width: 8),
          Text('Your safety reports'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: reportsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your report history.'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(studentSafetyReportsProvider(userId)),
                child: const Text('Try again'),
              ),
            ],
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'You have not submitted any safety reports.',
                    style: TextStyle(color: Color(0xFF555D58)),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: reports.length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (ctx, index) {
                final r = reports[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            r.scholarshipTitle ?? 'Scholarship concern',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: r.isResolved
                                ? const Color(0xFFE8F5E9)
                                : r.isDismissed
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            r.status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: r.isResolved
                                  ? const Color(0xFF2E7D32)
                                  : r.isDismissed
                                      ? const Color(0xFF616161)
                                      : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${r.categoryLabel} · ${r.relationshipLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF555D58),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (r.resolutionNote != null &&
                        r.resolutionNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEAECF0)),
                        ),
                        child: Text(
                          'Update from safety team: ${r.resolutionNote}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
