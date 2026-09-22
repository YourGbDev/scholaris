// lib/features/profile/presentation/matching_power_sheet.dart
//
// Bottom sheet modal displaying an itemized diagnostic breakdown of the student's
// profile matching power, highlighting completed vs missing criteria and offering
// direct navigation to complete missing details.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/mascot_pose_view.dart';
import '../models/student_profile.dart';
import '../services/matching_power_service.dart';

/// Shows the Matching Power Diagnostics bottom sheet modal.
Future<void> showMatchingPowerSheet(
  BuildContext context,
  StudentProfile? profile,
) {
  final report = MatchingPowerService.evaluate(profile);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => MatchingPowerSheet(report: report),
  );
}

class MatchingPowerSheet extends StatelessWidget {
  const MatchingPowerSheet({
    super.key,
    required this.report,
  });

  final MatchingPowerReport report;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isComplete = report.isFullyComplete;
    final accentColor = isComplete ? kPrimary : kAccent;

    // First incomplete item to route to
    final firstIncomplete = report.items.cast<MatchingPowerItem?>().firstWhere(
          (i) => i != null && !i.isComplete,
          orElse: () => null,
        );

    return Container(
      key: const ValueKey('matching-power-sheet'),
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, mediaQuery.padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title & close
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matching Power Diagnostics',
                      style: poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${report.completedCount} of ${report.totalCount} criteria optimized',
                      style: openSans(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Overview Score Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimarySoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Profile Matching Power',
                      style: poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      key: const ValueKey('matching-power-score-badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${report.percentage}%',
                        style: poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isComplete ? kPrimary : kMatchGoldText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    key: const ValueKey('matching-power-progress-bar'),
                    value: report.ratio,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  report.advice,
                  style: openSans(
                    fontSize: 12,
                    color: kPrimary,
                    height: 1.35,
                  ),
                ),
                if (isComplete) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const MascotPoseView(
                          pose: MascotPose.celebrating,
                          height: 84,
                          width: 84,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '100% Matching Power!',
                                style: poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your profile is fully optimized for all Philippine scholarships and government grants.',
                                style: openSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF404942),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Criteria Breakdown',
            style: poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Diagnostic Items List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: report.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final item = report.items[index];
                final done = item.isComplete;

                return InkWell(
                  key: ValueKey('matching-power-item-${item.id}'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go(item.routeTarget);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: done
                                 ? kPrimary.withValues(alpha: 0.12)
                                : kAccent.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            done
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 16,
                            color: done ? kPrimary : kMatchGoldText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    done ? 'Verified' : 'Action needed',
                                    style: openSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: done ? kPrimary : kMatchGoldText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: openSans(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.impactHint,
                                style: openSans(
                                  fontSize: 11,
                                  color: done ? Colors.black45 : kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Primary Action CTA Button
          ElevatedButton(
            key: const ValueKey('matching-power-cta-button'),
            onPressed: () {
              Navigator.of(context).pop();
              if (firstIncomplete != null) {
                context.go(firstIncomplete.routeTarget);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isComplete ? kPrimary : kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusCard),
              ),
            ),
            child: Text(
              isComplete
                  ? 'Great Job! Return to Discover'
                  : 'Complete Missing Details',
              style: poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
