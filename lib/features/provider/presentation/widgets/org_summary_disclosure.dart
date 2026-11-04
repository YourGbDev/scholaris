import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_motion.dart';
import '../org/org_provider_theme.dart';

/// Secondary reporting stays available without displacing the working list.
class OrgSummaryDisclosure extends StatelessWidget {
  const OrgSummaryDisclosure({
    super.key,
    required this.title,
    required this.summary,
    required this.child,
  });
  final String title, summary;
  final Widget child;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    childrenPadding: const EdgeInsets.only(top: 12, bottom: 16),
    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
    shape: const Border(bottom: BorderSide(color: kOrgBorder)),
    collapsedShape: const Border(bottom: BorderSide(color: kOrgBorder)),
    iconColor: kOrgPrimary,
    collapsedIconColor: kOrgTextSecondary,
    expansionAnimationStyle: AnimationStyle(
      duration: isReducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
    ),
    title: Text(
      title,
      style: AppTypography.style(
        AppTextRole.cardTitle,
        fontSize: 13,
        color: kOrgPrimary,
        height: 1.3,
        letterSpacing: 0,
      ),
    ),
    subtitle: Text(
      summary,
      style: AppTypography.style(
        AppTextRole.body,
        fontSize: 13,
        color: kOrgTextSecondary,
        height: 1.4,
        letterSpacing: 0,
      ),
    ),
    children: [child],
  );
}
