// lib/features/applications/presentation/application_status_chip.dart
//
// Renders an application's lifecycle status as a clear, color-coded chip so
// the student can see at a glance where each application stands. Presentation
// metadata (label, colors, icon) is centralized in [ApplicationStatusUi] so the
// tracking surface and any future surface share one consistent rendering.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

/// Per-status presentation metadata for the supported application lifecycle
/// statuses.
class ApplicationStatusUi {
  const ApplicationStatusUi({
    required this.label,
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData icon;

  static ApplicationStatusUi of(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return const ApplicationStatusUi(
          label: 'Draft',
          foreground: Color(0xFF5F6368),
          background: Color(0xFFE9EAEE),
          icon: Icons.edit_outlined,
        );
      case ApplicationStatus.submitted:
        return const ApplicationStatusUi(
          label: 'Submitted',
          foreground: Color(0xFF1A73E8),
          background: Color(0xFFE8F0FE),
          icon: Icons.send_rounded,
        );
      case ApplicationStatus.underReview:
        return const ApplicationStatusUi(
          label: 'Under review',
          foreground: Color(0xFF8A5B00),
          background: Color(0xFFFFF3D6),
          icon: Icons.schedule_rounded,
        );
      case ApplicationStatus.approved:
        return const ApplicationStatusUi(
          label: 'Approved',
          foreground: kPrimary,
          background: Color(0xFFE8F2EC),
          icon: Icons.check_circle_rounded,
        );
      case ApplicationStatus.rejected:
        return const ApplicationStatusUi(
          label: 'Rejected',
          foreground: kError,
          background: Color(0xFFFCE8E6),
          icon: Icons.cancel_outlined,
        );
    }
  }
}

class ApplicationStatusChip extends StatelessWidget {
  const ApplicationStatusChip({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final ui = ApplicationStatusUi.of(status);
    return Semantics(
      label: 'Status: ${ui.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ui.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ui.icon, size: 14, color: ui.foreground),
            const SizedBox(width: 5),
            Text(
              ui.label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ui.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
