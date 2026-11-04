// lib/shared/widgets/logout_confirmation_dialog.dart
//
// Shared confirmation dialog guarding sign-out actions across the application
// (Profile tab, Account settings, Provider console, and Admin portal).

import 'package:scholaris/shared/theme/app_motion.dart' show opticalTracking, opticalLeading;
import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

/// Displays a confirmation dialog asking the user if they are sure they want to log out.
/// Returns `true` if the user confirmed "Log Out", `false` if cancelled or dismissed.
Future<bool> showLogoutConfirmationDialog(
  BuildContext context, {
  String message = 'Are you sure you want to log out?',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Text(
        'Log out',
        style: AppTypography.style(AppTextRole.sectionTitle, fontSize: 18, color: kNavyTrust, letterSpacing: opticalTracking(18), height: opticalLeading(18, isBody: false)),
      ),
      content: Text(
        message,
        style: AppTypography.style(AppTextRole.body, fontSize: 14, color: const Color(0xFF404944), height: 1.4, letterSpacing: opticalTracking(14)),
      ),
      actions: [
        TextButton(
          key: const ValueKey('logout-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.style(AppTextRole.button, fontSize: 14, color: const Color(0xFF707971), letterSpacing: opticalTracking(14), height: opticalLeading(14, isBody: false)),
          ),
        ),
        TextButton(
          key: const ValueKey('logout-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'Log Out',
            style: AppTypography.style(AppTextRole.button, fontSize: 14, color: kError, letterSpacing: opticalTracking(14), height: opticalLeading(14, isBody: false)),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
