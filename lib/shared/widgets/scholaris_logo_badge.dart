// lib/shared/widgets/scholaris_logo_badge.dart
//
// The Scholaris brand mark: a circular badge with a graduation-cap glyph on
// the soft primary tint. Used on the splash, intro and login surfaces; the
// identical widget appears in all three so brand recognition carries through
// the first-run journey.
//
// Optional [heroTag]: when set, the badge participates in a [Hero] flight so
// the mark can appear to lift from one screen into the next (intro → login).
// Hero tags must be unique per screen — wrap the same tag only once per
// subtree. When [heroTag] is null the badge is a plain widget with no Hero
// involvement, so embedding it in scrollables or repeated lists stays safe.

import 'package:flutter/material.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

/// Standard badge diameter across surfaces.
const double kLogoBadgeSize = 96;

/// Shared [Hero] tag for the logo flight between the intro and login screens.
/// Only one badge per screen may carry this tag.
const String kScholarisLogoHeroTag = 'scholaris-logo-badge';

class ScholarisLogoBadge extends StatelessWidget {
  const ScholarisLogoBadge({
    super.key,
    this.heroTag,
    this.size = kLogoBadgeSize,
  });

  /// When non-null, wraps the badge in a [Hero] with this tag.
  final Object? heroTag;

  /// Badge diameter; the glyph scales proportionally.
  final double size;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: kPrimarySoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.school, size: size * 0.46, color: kPrimary),
    );

    if (heroTag == null) return badge;
    return Hero(tag: heroTag!, child: badge);
  }
}
