// lib/features/provider/presentation/widgets/provider_verification_banner.dart
//
// Persistent Verification Status Banner for Provider Consoles.
// Appears at the top of the provider shells without blocking access.

import 'package:scholaris/shared/theme/app_theme.dart';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/provider_verification_repository.dart';
import '../../models/provider_verification.dart';
import '../../providers/provider_verification_provider.dart';
import '../../../../shared/theme/app_motion.dart';

class ProviderVerificationBanner extends ConsumerWidget {
  const ProviderVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationAsync = ref.watch(currentUserVerificationProvider);

    return verificationAsync.when(
      data: (verification) {
        if (verification == null || verification.status == 'approved') {
          return const SizedBox.shrink();
        }

        if (verification.status == 'changes_requested') {
          final note = verification.reviewNote?.trim().isNotEmpty == true
              ? ': "${verification.reviewNote!.trim()}"'
              : '';
          return _buildBanner(
            status: 'changes_requested',
            title: 'Accreditation Status: Updates Requested',
            message:
                'The administrator requested changes to your accreditation$note. Please update your documentation and resubmit.',
            context: context,
            onUpdateDocuments: () =>
                _openResubmitDialog(context, ref, verification),
          );
        }

        if (verification.status == 'rejected') {
          final note = verification.reviewNote?.trim().isNotEmpty == true
              ? ': "${verification.reviewNote!.trim()}"'
              : '';
          return _buildBanner(
            status: 'rejected',
            title: 'Accreditation Status: Revisions Requested',
            message:
                'The committee noted$note. You can update your documentation to resume review.',
            context: context,
            onUpdateDocuments: () =>
                _openResubmitDialog(context, ref, verification),
          );
        }

        // Pending
        return _buildBanner(
          status: 'pending',
          title: 'Accreditation Status: Verification Pending',
          message:
              'Your submission from ${_formatDate(verification.submittedAt)} is under review by the Scholaris accreditation committee.',
          context: context,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return 'recently';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildBanner({
    required String status,
    required String title,
    required String message,
    required BuildContext context,
    VoidCallback? onUpdateDocuments,
  }) {
    final isRejected = status == 'rejected';
    final isPending = status == 'pending';

    final Color bgColor = isRejected
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final Color borderColor = isRejected
        ? const Color(0xFFFECACA)
        : const Color(0xFFFDE68A);
    final Color iconColor = isRejected
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final Color titleColor = isRejected
        ? const Color(0xFF991B1B)
        : const Color(0xFF92400E);
    final Color bodyColor = isRejected
        ? const Color(0xFFB91C1C)
        : const Color(0xFFB45309);

    final icon = isRejected
        ? Icons.error_outline_rounded
        : Icons.hourglass_top_rounded;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: geist(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: geist(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: bodyColor,
                    height: 1.35,
                  ),
                ),
                if ((isRejected || status == 'changes_requested') &&
                    onUpdateDocuments != null) ...[
                  const SizedBox(height: 8),
                  PressableScale(
                    scale: 0.98,
                    child: OutlinedButton.icon(
                      onPressed: onUpdateDocuments,
                      icon: const Icon(Icons.upload_file_rounded, size: 14),
                      label: const Text('Update Documents & Resubmit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF991B1B),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        textStyle: geist(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF92400E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'PENDING',
                style: geist(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openResubmitDialog(
    BuildContext context,
    WidgetRef ref,
    ProviderVerification verification,
  ) {
    showDialog<void>(
      animationStyle:
          isReducedMotion(context) ? AnimationStyle.noAnimation : null,
      context: context,
      builder: (dlgCtx) => _ProviderResubmitDialog(
        verification: verification,
        onResubmitted: () {
          ref.invalidate(currentUserVerificationProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification resubmitted. Your documents are now pending review.',
              ),
            ),
          );
        },
      ),
    );
  }
}

typedef _ProviderResubmitDialog = ProviderResubmitDialog;

class ProviderResubmitDialog extends ConsumerStatefulWidget {
  const ProviderResubmitDialog({
    super.key,
    required this.verification,
    required this.onResubmitted,
    this.initialSecFile,
    this.initialBirFile,
    this.initialBoardFile,
    this.initialGovIdFile,
    this.initialSelfieFile,
  });

  final ProviderVerification verification;
  final VoidCallback onResubmitted;
  final ({Uint8List bytes, String name})? initialSecFile;
  final ({Uint8List bytes, String name})? initialBirFile;
  final ({Uint8List bytes, String name})? initialBoardFile;
  final ({Uint8List bytes, String name})? initialGovIdFile;
  final ({Uint8List bytes, String name})? initialSelfieFile;

  @override
  ConsumerState<ProviderResubmitDialog> createState() =>
      _ProviderResubmitDialogState();
}

class _ProviderResubmitDialogState
    extends ConsumerState<ProviderResubmitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _idOrRegController;
  late final TextEditingController _detailController;
  bool _submitting = false;
  String? _error;

  Uint8List? _secBytes;
  String? _secName;
  Uint8List? _birBytes;
  String? _birName;
  Uint8List? _boardBytes;
  String? _boardName;

  Uint8List? _govIdBytes;
  String? _govIdName;
  Uint8List? _selfieBytes;
  String? _selfieName;

  @override
  void initState() {
    super.initState();
    final v = widget.verification;
    final isOrg = v.providerType == 'organization';
    _nameController = TextEditingController(
      text: isOrg ? (v.orgName ?? '') : (v.fullName ?? ''),
    );
    _idOrRegController = TextEditingController(
      text: isOrg ? (v.regNumber ?? '') : (v.govIdNumber ?? ''),
    );
    _detailController = TextEditingController(
      text: isOrg ? (v.repPosition ?? '') : (v.sourceOfFunds ?? ''),
    );

    if (widget.initialSecFile != null) {
      _secBytes = widget.initialSecFile!.bytes;
      _secName = widget.initialSecFile!.name;
    }
    if (widget.initialBirFile != null) {
      _birBytes = widget.initialBirFile!.bytes;
      _birName = widget.initialBirFile!.name;
    }
    if (widget.initialBoardFile != null) {
      _boardBytes = widget.initialBoardFile!.bytes;
      _boardName = widget.initialBoardFile!.name;
    }
    if (widget.initialGovIdFile != null) {
      _govIdBytes = widget.initialGovIdFile!.bytes;
      _govIdName = widget.initialGovIdFile!.name;
    }
    if (widget.initialSelfieFile != null) {
      _selfieBytes = widget.initialSelfieFile!.bytes;
      _selfieName = widget.initialSelfieFile!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idOrRegController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument({
    required Function(Uint8List bytes, String name) onPicked,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          setState(() => _error = 'Could not read file data. Please try another file.');
          return;
        }
        final err = ProviderVerificationRepository.validateFile(
          fileName: file.name,
          byteLength: file.bytes!.length,
        );
        if (err != null) {
          setState(() => _error = err);
          return;
        }
        setState(() {
          onPicked(file.bytes!, file.name);
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to select file: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(providerVerificationRepositoryProvider);
      final userId = widget.verification.userId;
      final isOrg = widget.verification.providerType == 'organization';

      String? secPath;
      if (_secBytes != null) {
        secPath = await repo.uploadDocument(
          userId: userId,
          docType: 'sec_certificate',
          bytes: _secBytes!,
          fileName: _secName ?? 'sec_cert.pdf',
        );
      }

      String? birPath;
      if (_birBytes != null) {
        birPath = await repo.uploadDocument(
          userId: userId,
          docType: 'bir_2303',
          bytes: _birBytes!,
          fileName: _birName ?? 'bir_2303.pdf',
        );
      }

      String? boardPath;
      if (_boardBytes != null) {
        boardPath = await repo.uploadDocument(
          userId: userId,
          docType: 'board_resolution',
          bytes: _boardBytes!,
          fileName: _boardName ?? 'board_resolution.pdf',
        );
      }

      String? govIdPath;
      if (_govIdBytes != null) {
        govIdPath = await repo.uploadDocument(
          userId: userId,
          docType: 'gov_id_front',
          bytes: _govIdBytes!,
          fileName: _govIdName ?? 'gov_id.jpg',
        );
      }

      String? selfiePath;
      if (_selfieBytes != null) {
        selfiePath = await repo.uploadDocument(
          userId: userId,
          docType: 'selfie_with_id',
          bytes: _selfieBytes!,
          fileName: _selfieName ?? 'selfie.jpg',
        );
      }

      final payload = <String, dynamic>{
        if (isOrg) ...{
          'org_name': _nameController.text.trim(),
          'reg_number': _idOrRegController.text.trim(),
          'rep_position': _detailController.text.trim(),
        } else ...{
          'full_name': _nameController.text.trim(),
          'gov_id_number': _idOrRegController.text.trim(),
          'source_of_funds': _detailController.text.trim(),
        },
      };

      if (secPath != null) payload['sec_cert_path'] = secPath;
      if (birPath != null) payload['bir_2303_path'] = birPath;
      if (boardPath != null) payload['board_resolution_path'] = boardPath;
      if (govIdPath != null) payload['gov_id_front_path'] = govIdPath;
      if (selfiePath != null) payload['selfie_id_path'] = selfiePath;

      await repo.resubmitVerification(payload);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onResubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Resubmission failed: $e';
        });
      }
    }
  }

  Widget _buildDocRow({
    required String label,
    required String? selectedName,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (selectedName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0F4D2E)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          selectedName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0F4D2E)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (selectedName != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Remove',
              onPressed: _submitting ? null : onClear,
            )
          else
            OutlinedButton.icon(
              onPressed: _submitting ? null : onPick,
              icon: const Icon(Icons.upload_file, size: 14),
              label: const Text('Upload new', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOrg = widget.verification.providerType == 'organization';
    final note = widget.verification.reviewNote?.trim();

    return AlertDialog(
      title: const Text('Update Documentation & Resubmit'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note != null && note.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECDCA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reviewer feedback:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF912018),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB42318),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Please correct your information below. Once submitted, your accreditation application will return to pending review.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF475467)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isOrg ? 'Organization Name' : 'Full Name',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _idOrRegController,
                  decoration: InputDecoration(
                    labelText:
                        isOrg ? 'SEC / DTI Registration Number' : 'ID Number',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _detailController,
                  decoration: InputDecoration(
                    labelText: isOrg
                        ? 'Representative Position / Designation'
                        : 'Source of Funds',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Replacement documents (optional unless requested)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF344054),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select replacement files to update your accreditation dossier. Existing files will be preserved if not replaced.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                ),
                const SizedBox(height: 12),
                if (isOrg) ...[
                  _buildDocRow(
                    label: 'SEC / DTI Registration Certificate',
                    selectedName: _secName,
                    onPick: () => _pickDocument(onPicked: (b, n) {
                      _secBytes = b;
                      _secName = n;
                    }),
                    onClear: () => setState(() {
                      _secBytes = null;
                      _secName = null;
                    }),
                  ),
                  _buildDocRow(
                    label: 'BIR Certificate of Registration (Form 2303)',
                    selectedName: _birName,
                    onPick: () => _pickDocument(onPicked: (b, n) {
                      _birBytes = b;
                      _birName = n;
                    }),
                    onClear: () => setState(() {
                      _birBytes = null;
                      _birName = null;
                    }),
                  ),
                  _buildDocRow(
                    label: 'Board Resolution / Secretary Certificate (Optional)',
                    selectedName: _boardName,
                    onPick: () => _pickDocument(onPicked: (b, n) {
                      _boardBytes = b;
                      _boardName = n;
                    }),
                    onClear: () => setState(() {
                      _boardBytes = null;
                      _boardName = null;
                    }),
                  ),
                ] else ...[
                  _buildDocRow(
                    label: 'Government-Issued Photo ID',
                    selectedName: _govIdName,
                    onPick: () => _pickDocument(onPicked: (b, n) {
                      _govIdBytes = b;
                      _govIdName = n;
                    }),
                    onClear: () => setState(() {
                      _govIdBytes = null;
                      _govIdName = null;
                    }),
                  ),
                  _buildDocRow(
                    label: 'Selfie with ID (Optional)',
                    selectedName: _selfieName,
                    onPick: () => _pickDocument(onPicked: (b, n) {
                      _selfieBytes = b;
                      _selfieName = n;
                    }),
                    onClear: () => setState(() {
                      _selfieBytes = null;
                      _selfieName = null;
                    }),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 16),
          label: Text(_submitting ? 'Submitting…' : 'Resubmit for Review'),
        ),
      ],
    );
  }
}
