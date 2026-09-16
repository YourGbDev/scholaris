// lib/shared/widgets/scholaris_logo.dart
//
// The official Scholaris brand header logo:
// A solid Bridge Green (#0F4D2E) rounded-square badge with a white graduation
// cap icon, paired with the Scholaris wordmark in Poppins Bold.
// Used consistently across every screen.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScholarisLogo extends StatelessWidget {
  const ScholarisLogo({
    super.key,
    this.badgeSize = 34.0,
    this.iconSize = 20.0,
    this.fontSize = 22.0,
    this.badgeRadius = 8.0,
    this.showWordmark = true,
    this.textColor,
    this.compact = false,
  });

  /// The dimension (width/height) of the rounded-square badge.
  final double badgeSize;

  /// The size of the graduation cap icon.
  final double iconSize;

  /// Font size of the Scholaris wordmark.
  final double fontSize;

  /// Corner radius of the badge.
  final double badgeRadius;

  /// Whether to show the Scholaris text next to the badge.
  final bool showWordmark;

  /// Wordmark text color (defaults to kPrimary).
  final Color? textColor;

  /// Compact header presentation variant.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effectiveBadgeSize = compact ? 28.0 : badgeSize;
    final effectiveIconSize = compact ? 16.0 : iconSize;
    final effectiveFontSize = compact ? 18.0 : fontSize;
    final effectiveRadius = compact ? 7.0 : badgeRadius;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: effectiveBadgeSize,
          height: effectiveBadgeSize,
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(effectiveRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F4D2E),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.school_rounded,
            size: effectiveIconSize,
            color: Colors.white,
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Scholaris',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: poppins(
                fontSize: effectiveFontSize,
                fontWeight: FontWeight.bold,
                color: textColor ?? kPrimary,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
