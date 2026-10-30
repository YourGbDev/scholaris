import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../applications/presentation/widgets/document_upload_sheet.dart';
import '../../../scholarships/presentation/scholarship_qr_scanner_screen.dart';

enum StudentQuickAction { scan, upload }

/// Retains the existing entry point while presenting a compact menu above the dock.
Future<void> showStudentActionSheet(
  BuildContext context, {
  double bottomOffset = 100,
}) async {
  final action = await showGeneralDialog<StudentQuickAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close quick actions',
    barrierColor: Colors.transparent,
    transitionDuration: isReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 160),
    pageBuilder: (menuContext, _, _) => SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(
              right: 16,
              left: 16,
              bottom: math.min(bottomOffset, constraints.maxHeight * .45),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 320,
                maxHeight: math.max(
                  80,
                  constraints.maxHeight -
                      math.min(bottomOffset, constraints.maxHeight * .45) -
                      16,
                ),
              ),
              child: const StudentActionSheet(),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
  if (!context.mounted || action == null) return;
  HapticFeedback.lightImpact();
  switch (action) {
    case StudentQuickAction.scan:
      ScholarshipQrScannerScreen.show(context);
    case StudentQuickAction.upload:
      showDocumentUploadSheet(context);
  }
}

class StudentActionSheet extends StatelessWidget {
  const StudentActionSheet({super.key, this.onSelect});
  final ValueChanged<StudentQuickAction>? onSelect;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 8,
    shadowColor: const Color(0x20000000),
    borderRadius: BorderRadius.circular(26),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Quick Actions',
                    style: geist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF59635D),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close quick actions',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _action(
                    context,
                    StudentQuickAction.scan,
                    Icons.qr_code_scanner_rounded,
                    'Scan scholarship QR',
                    'Open a scholarship from its QR code.',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                  ),
                  _action(
                    context,
                    StudentQuickAction.upload,
                    Icons.upload_file_outlined,
                    'Upload document',
                    'Add a document for your applications.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _action(
    BuildContext context,
    StudentQuickAction action,
    IconData icon,
    String title,
    String subtitle,
  ) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => onSelect != null
        ? onSelect!(action)
        : Navigator.of(context).pop(action),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4EE),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: geist(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kOnSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: geist(
                    fontSize: 14,
                    height: 1.4,
                    color: const Color(0xFF59635D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
