// lib/features/applications/presentation/widgets/document_upload_sheet.dart
//
// Document upload bottom sheet modal allowing students to attach verified files
// (transcripts, indigency certificates, etc.) to an existing scholarship application.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../../scholarships/providers/scholarships_provider.dart';
import '../../providers/application_document_provider.dart';
import '../../providers/applications_provider.dart';

Future<void> showDocumentUploadSheet(
  BuildContext context, {
  String? preselectedApplicationId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DocumentUploadSheet(
      preselectedApplicationId: preselectedApplicationId,
    ),
  );
}

class DocumentUploadSheet extends ConsumerStatefulWidget {
  const DocumentUploadSheet({
    super.key,
    this.preselectedApplicationId,
  });

  final String? preselectedApplicationId;

  @override
  ConsumerState<DocumentUploadSheet> createState() =>
      _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends ConsumerState<DocumentUploadSheet> {
  String? _selectedApplicationId;
  String _selectedDocumentType = 'transcript';
  PlatformFile? _pickedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  String? _uploadError;

  final List<({String key, String label, IconData icon})> _docTypes = const [
    (
      key: 'transcript',
      label: 'Academic Transcript',
      icon: Icons.school_outlined,
    ),
    (
      key: 'certificate_of_indigency',
      label: 'Cert. of Indigency',
      icon: Icons.family_restroom_outlined,
    ),
    (
      key: 'certificate_of_grades',
      label: 'True Copy of Grades',
      icon: Icons.grade_outlined,
    ),
    (
      key: 'recommendation_letter',
      label: 'Recommendation Letter',
      icon: Icons.mail_outline_rounded,
    ),
    (
      key: 'enrollment_certificate',
      label: 'Cert. of Registration (COR)',
      icon: Icons.assignment_turned_in_outlined,
    ),
    (
      key: 'id_document',
      label: 'Student / Valid ID',
      icon: Icons.badge_outlined,
    ),
    (
      key: 'other',
      label: 'Other Supporting Document',
      icon: Icons.attach_file_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedApplicationId = widget.preselectedApplicationId;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        HapticFeedback.lightImpact();
        final file = result.files.first;
        setState(() {
          _pickedFile = file;
          _fileBytes = file.bytes;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() => _uploadError = 'Could not select file: $e');
    }
  }

  Future<void> _submitUpload() async {
    if (_selectedApplicationId == null) {
      HapticFeedback.vibrate();
      setState(() => _uploadError = 'Please select a scholarship application.');
      return;
    }
    if (_pickedFile == null || _fileBytes == null) {
      HapticFeedback.vibrate();
      setState(() => _uploadError = 'Please choose a document file to upload.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final ext = _pickedFile!.extension?.toLowerCase() ?? '';
      String mime = 'application/octet-stream';
      if (ext == 'pdf') {
        mime = 'application/pdf';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mime = 'image/jpeg';
      } else if (ext == 'png') {
        mime = 'image/png';
      } else if (ext == 'docx') {
        mime =
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      }

      await ref
          .read(applicationDocumentsProvider(_selectedApplicationId!).notifier)
          .uploadDocument(
            documentType: _selectedDocumentType,
            fileName: _pickedFile!.name,
            fileBytes: _fileBytes!,
            mimeType: mime,
          );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      showScholarisToast(
        context,
        message: 'Document uploaded successfully.',
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      HapticFeedback.vibrate();
      setState(() {
        _isUploading = false;
        _uploadError = 'Upload failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final appsAsync = ref.watch(applicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: mediaQuery.viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const AppleBouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058BC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: Color(0xFF0058BC),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Application Document',
                        style: outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF161C27),
                        ),
                      ),
                      Text(
                        'Attach verified proof to an active grant submission',
                        style: openSans(
                          fontSize: 12,
                          color: const Color(0xFF707971),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step 1: Select Application
            Text(
              '1. SELECT SCHOLARSHIP APPLICATION',
              style: outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFF707971),
              ),
            ),
            const SizedBox(height: 8),
            appsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load applications: $e',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
              data: (apps) {
                if (apps.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F3F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No active scholarship applications found. Start an application first to upload documents.',
                      style: openSans(
                        fontSize: 12.5,
                        color: const Color(0xFF404942),
                      ),
                    ),
                  );
                }

                final scholarships = scholarshipsAsync.valueOrNull ?? [];
                // Set default if not set yet
                if (_selectedApplicationId == null && apps.isNotEmpty) {
                  _selectedApplicationId = apps.first.id;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedApplicationId,
                      items: apps.map((app) {
                        final sch = scholarships
                            .cast<Scholarship?>()
                            .firstWhere(
                              (s) => s?.id == app.scholarshipId,
                              orElse: () => null,
                            );
                        final title = sch?.title ?? 'Application (${app.status.dbValue})';
                        return DropdownMenuItem<String>(
                          value: app.id,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF161C27),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedApplicationId = val);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Step 2: Document Type
            Text(
              '2. SELECT DOCUMENT TYPE',
              style: outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFF707971),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _docTypes.map((dt) {
                final isSelected = _selectedDocumentType == dt.key;
                return PressableScale(
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          dt.icon,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF404942),
                        ),
                        const SizedBox(width: 5),
                        Text(dt.label),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F4D2E),
                    backgroundColor: const Color(0xFFF4F3F8),
                    labelStyle: outfit(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? Colors.white : const Color(0xFF404942),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0F4D2E)
                          : const Color(0xFFE2E8F3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDocumentType = dt.key);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Step 3: Choose File
            Text(
              '3. CHOOSE FILE',
              style: outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFF707971),
              ),
            ),
            const SizedBox(height: 8),
            PressableScale(
              child: InkWell(
                onTap: _isUploading ? null : _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pickedFile != null
                          ? const Color(0xFF0F4D2E)
                          : const Color(0xFFE2E8F3),
                      width: _pickedFile != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _pickedFile != null
                              ? const Color(0xFFDCF3E5)
                              : const Color(0xFFEEEDF3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _pickedFile != null
                              ? Icons.description_rounded
                              : Icons.folder_open_rounded,
                          color: _pickedFile != null
                              ? const Color(0xFF0F4D2E)
                              : const Color(0xFF707971),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFile?.name ?? 'Tap to select document file',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF161C27),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _pickedFile != null
                                  ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB • ${_pickedFile!.extension?.toUpperCase() ?? "FILE"}'
                                  : 'Supported: PDF, JPG, PNG, DOCX (Max 15MB)',
                              style: openSans(
                                fontSize: 11.5,
                                color: const Color(0xFF707971),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _pickedFile != null
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: _pickedFile != null
                            ? const Color(0xFF0F4D2E)
                            : const Color(0xFF707971),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_uploadError != null) ...[
              const SizedBox(height: 12),
              Text(
                _uploadError!,
                style: openSans(
                  fontSize: 12,
                  color: const Color(0xFFBA1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Submit Button
            PressableScale(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4D2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _isUploading ? null : _submitUpload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined, size: 20),
                label: Text(
                  _isUploading ? 'Uploading Document...' : 'Upload Document',
                  style: outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
