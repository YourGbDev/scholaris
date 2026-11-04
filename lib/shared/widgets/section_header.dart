// lib/shared/widgets/section_header.dart
//
// Shared section heading for scrollable Scholaris surfaces. Renders a Poppins
// title with an optional gold count badge (used by the Discover dashboard and
// matches list). Extracted from the Discover screen so every section header
// shares the same typography, spacing and accent.

import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
  });

  /// The section title.
  final String title;

  /// Optional count rendered in the gold badge. When null the badge is hidden.
  final int? count;

  /// Optional trailing action (e.g. a "See all" link), right-aligned. The
  /// pattern comes from the reference dashboard templates' title rows:
  /// title-left, action-right.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: AppTypography.style(
              AppTextRole.sectionTitle,
              fontSize: 17,
              height: 1.25,
              letterSpacing: -0.15,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: kAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTypography.style(
                AppTextRole.badge,
                fontSize: 13,
                color: kMatchGoldText,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}
