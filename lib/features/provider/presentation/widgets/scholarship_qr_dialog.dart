// lib/features/provider/presentation/widgets/scholarship_qr_dialog.dart
//
// Provider modal dialog generating and displaying a shareable QR code for a published
// scholarship using the canonical `scholaris://scholarships/{id}` URI scheme.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../../scholarships/models/scholarship.dart';

Future<void> showScholarshipQrDialog(
  BuildContext context,
  Scholarship scholarship,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _ScholarshipQrDialog(scholarship: scholarship),
  );
}

class _ScholarshipQrDialog extends StatefulWidget {
  const _ScholarshipQrDialog({required this.scholarship});

  final Scholarship scholarship;

  @override
  State<_ScholarshipQrDialog> createState() => _ScholarshipQrDialogState();
}

class _ScholarshipQrDialogState extends State<_ScholarshipQrDialog> {
  bool _copied = false;

  String get _qrPayload =>
      'scholaris://scholarships/${widget.scholarship.id}';

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _qrPayload));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scholarship;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scholarship QR Code',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF161C27),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            fontSize: 12.5,
                            color: const Color(0xFF707971),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QR Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F3)),
                ),
                child: QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F4D2E),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF00351C),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // URI Payload badge & Copy Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _qrPayload,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: const Color(0xFF404942),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    PressableScale(
                      child: InkWell(
                        onTap: _copyToClipboard,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _copied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                size: 14,
                                color: _copied
                                    ? const Color(0xFF0F4D2E)
                                    : const Color(0xFF0058BC),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _copied ? 'Copied' : 'Copy',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _copied
                                      ? const Color(0xFF0F4D2E)
                                      : const Color(0xFF0058BC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Students can scan this code with the Scholaris student app to open criteria and apply directly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: const Color(0xFF707971),
                ),
              ),
              const SizedBox(height: 16),

              // Done CTA Button
              SizedBox(
                width: double.infinity,
                child: PressableScale(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4D2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Done',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
