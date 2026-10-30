import 'package:flutter/material.dart';

import '../../features/account/presentation/account_settings_screen.dart';
import '../../features/dashboard/presentation/widgets/student_notifications_sheet.dart';
import '../theme/app_theme.dart';

/// Shared header shortcuts; Profile remains a top-level dock destination.
class StudentHeaderActions extends StatelessWidget {
  const StudentHeaderActions({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'Notifications',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.notifications_none_rounded, color: kPrimary, size: 24),
            onPressed: () => showStudentNotificationsSheet(context),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Settings',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.settings_outlined, color: kPrimary, size: 24),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AccountSettingsScreen())),
          ),
        ]),
      ),
    ),
  );
}
