// lib/shared/widgets/logout_confirmation_dialog.dart
//
// Shared confirmation dialog guarding sign-out actions across the application
// (Profile tab, Account settings, Provider console, and Admin portal).

import 'package:flutter/material.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

/// Displays a confirmation dialog asking the user if they are sure they want to log out.
/// Returns `true` if the user confirmed "Log Out", `false` if cancelled or dismissed.
Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Text(
        'Log out',
        style: poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kNavyTrust,
        ),
      ),
      content: Text(
        'Are you sure you want to log out?',
        style: openSans(
          fontSize: 14,
          color: const Color(0xFF404944),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('logout-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Cancel',
            style: poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF707971),
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('logout-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'Log Out',
            style: poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kError,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
