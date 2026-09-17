// lib/shared/widgets/save_draft_dialog.dart
//
// Exit-intent confirmation dialog shown when a student navigates away from
// an application flow with unsaved progress.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

enum SaveDraftExitAction {
  saveAsDraft,
  discard,
  cancel,
}

/// Prompts the student with "Save your progress?" and provides three options:
/// 1. Save as Draft (persists form state as draft and navigates away)
/// 2. Discard (exits without saving)
/// 3. Cancel (dismisses dialog and stays on the form)
Future<SaveDraftExitAction?> showSaveDraftExitDialog(BuildContext context) {
  return showDialog<SaveDraftExitAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Text(
        'Save your progress?',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: kNavyTrust,
        ),
      ),
      content: Text(
        'You have unsaved progress in your application. Would you like to save it as a draft so you can return to it later, or discard your progress?',
        style: GoogleFonts.openSans(
          fontSize: 14,
          color: const Color(0xFF404942),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('exit-dialog-cancel'),
          onPressed: () =>
              Navigator.of(dialogContext).pop(SaveDraftExitAction.cancel),
          child: Text(
            'Cancel',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF707971),
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('exit-dialog-discard'),
          onPressed: () =>
              Navigator.of(dialogContext).pop(SaveDraftExitAction.discard),
          child: Text(
            'Discard',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kError,
            ),
          ),
        ),
        ElevatedButton(
          key: const ValueKey('exit-dialog-save-draft'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () =>
              Navigator.of(dialogContext).pop(SaveDraftExitAction.saveAsDraft),
          child: Text(
            'Save as Draft',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
