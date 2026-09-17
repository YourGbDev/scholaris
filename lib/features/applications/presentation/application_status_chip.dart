// lib/features/applications/presentation/application_status_chip.dart
//
// Renders an application's lifecycle status as a clear, color-coded chip matching
// the Stitch design system. Presentation metadata (label, colors, icon) is centralized
// in [ApplicationStatusUi] so the tracking surface and any future surface share one
// consistent rendering.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';

/// Per-status presentation metadata for the supported application lifecycle statuses.
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
          foreground: Color(0xFF5D4200),
          background: Color(0xFFFFDEA3),
          icon: Icons.edit_note_rounded,
        );
      case ApplicationStatus.submitted:
        return const ApplicationStatusUi(
          label: 'Submitted',
          foreground: Color(0xFF1B3A5C),
          background: Color(0xFFD2E4FF),
          icon: Icons.send_rounded,
        );
      case ApplicationStatus.underReview:
        return const ApplicationStatusUi(
          label: 'Under review',
          foreground: Color(0xFF001C38),
          background: Color(0xFFD2E4FF),
          icon: Icons.schedule_rounded,
        );
      case ApplicationStatus.approved:
        return const ApplicationStatusUi(
          label: 'Approved',
          foreground: Color(0xFF145131),
          background: Color(0xFFB3F1C6),
          icon: Icons.celebration_rounded,
        );
      case ApplicationStatus.rejected:
        return const ApplicationStatusUi(
          label: 'Rejected',
          foreground: Color(0xFFBA1A1A),
          background: Color(0xFFFFDAD6),
          icon: Icons.cancel_outlined,
        );
      case ApplicationStatus.withdrawn:
        return const ApplicationStatusUi(
          label: 'Withdrawn',
          foreground: Color(0xFF5F6368),
          background: Color(0xFFE9EAEE),
          icon: Icons.unsubscribe_rounded,
        );
      case ApplicationStatus.awarded:
        return const ApplicationStatusUi(
          label: 'Awarded',
          foreground: Color(0xFF145131),
          background: Color(0xFFB3F1C6),
          icon: Icons.workspace_premium_rounded,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: ui.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == ApplicationStatus.underReview) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: ui.foreground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ] else ...[
              Icon(ui.icon, size: 13, color: ui.foreground),
              const SizedBox(width: 4),
            ],
            Text(
              ui.label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: ui.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
