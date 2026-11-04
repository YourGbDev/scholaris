import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/student_profile.dart';
import '../services/matching_power_service.dart';

/// Shows the saved and missing profile details without implying eligibility.
Future<void> showMatchingPowerSheet(
  BuildContext context,
  StudentProfile? profile,
) {
  final report = MatchingPowerService.evaluate(profile);
  return showAppleSpringModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusCard)),
    ),
    builder: (sheetContext) => MatchingPowerSheet(report: report),
  );
}

class MatchingPowerSheet extends StatelessWidget {
  const MatchingPowerSheet({super.key, required this.report});
  final MatchingPowerReport report;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final firstIncomplete = report.items.cast<MatchingPowerItem?>().firstWhere(
      (item) => item != null && !item.isComplete,
      orElse: () => null,
    );
    return Container(
      key: const ValueKey('matching-power-sheet'),
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
      padding: EdgeInsets.fromLTRB(20, 8, 20, mediaQuery.padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile completeness',
                  style: AppTypography.style(
                    AppTextRole.sectionTitle,
                    fontSize: 17,
                    color: kTextPrimary,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: kTextSecondary),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              physics: const AppleBouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${report.completedCount} of ${report.totalCount} details provided',
                          style: AppTypography.style(
                            AppTextRole.caption,
                            fontSize: 12,
                            color: kTextSecondary,
                            height: 1.4,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CountUpAnimation(
                        key: const ValueKey('matching-power-score-badge'),
                        targetValue: report.percentage,
                        suffix: '%',
                        style: AppTypography.style(
                          AppTextRole.metric,
                          fontSize: 13,
                          color: kPrimary,
                          height: 1.4,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      key: const ValueKey('matching-power-progress-bar'),
                      value: report.ratio,
                      minHeight: 4,
                      backgroundColor: kStudentDivider,
                      valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    report.isFullyComplete
                        ? 'Your profile details are complete. Keep them up to date.'
                        : 'Add your missing details to keep your profile up to date.',
                    style: AppTypography.style(
                      AppTextRole.body,
                      fontSize: 12,
                      color: kTextSecondary,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Completeness does not guarantee scholarship eligibility.',
                    style: AppTypography.style(
                      AppTextRole.caption,
                      fontSize: 12,
                      color: kTextSecondary,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Profile details',
                    style: AppTypography.style(
                      AppTextRole.sectionTitle,
                      fontSize: 13,
                      color: kTextPrimary,
                      height: 1.4,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in report.items) ...[
                    InkWell(
                      key: ValueKey('matching-power-item-${item.id}'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(item.routeTarget);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.isComplete
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 20,
                              color: item.isComplete
                                  ? kPrimary
                                  : kTextSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTypography.style(
                                      AppTextRole.cardTitle,
                                      fontSize: 13,
                                      color: kTextPrimary,
                                      height: 1.4,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    style: AppTypography.style(
                                      AppTextRole.subtitle,
                                      fontSize: 12,
                                      color: kTextSecondary,
                                      height: 1.4,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.isComplete
                                        ? 'Provided'
                                        : 'Missing details',
                                    style: AppTypography.style(
                                      AppTextRole.badge,
                                      fontSize: 11,
                                      color: kTextSecondary,
                                      height: 1.4,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: kTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (item != report.items.last)
                      const Divider(height: 1, color: kStudentDivider),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const ValueKey('matching-power-cta-button'),
            onPressed: () {
              Navigator.of(context).pop();
              if (firstIncomplete != null) {
                context.go(firstIncomplete.routeTarget);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: kPrimary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              firstIncomplete == null ? 'Done' : 'Add missing details',
              style: AppTypography.style(
                AppTextRole.button,
                fontSize: 13,
                color: kPrimary,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
