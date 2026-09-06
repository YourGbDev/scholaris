// lib/shared/widgets/section_header.dart
//
// Shared section heading for scrollable Scholaris surfaces. Renders a Poppins
// title with an optional gold count badge (used by the Discover dashboard and
// matches list). Extracted from the Discover screen so every section header
// shares the same typography, spacing and accent.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
  });

  /// The section title.
  final String title;

  /// Optional count rendered in the gold badge. When null the badge is hidden.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
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
              style: poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
