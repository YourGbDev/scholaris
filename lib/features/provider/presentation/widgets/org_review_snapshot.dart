import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../org/org_provider_theme.dart';

class OrgReviewSnapshot extends StatelessWidget {
  const OrgReviewSnapshot({
    super.key,
    required this.total,
    required this.pending,
    required this.decided,
    required this.onReview,
    this.onAnalytics,
  });
  final int total, pending, decided;
  final VoidCallback onReview;
  final VoidCallback? onAnalytics;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 620;
      final progress = total == 0 ? 0.0 : (decided / total).clamp(0.0, 1.0);
      final narrative = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLICATION REVIEW',
            style: AppTypography.style(
              AppTextRole.label,
              fontSize: 10,
              color: const Color(0xFFD2E3CE),
              letterSpacing: 1.4,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            pending == 0
                ? 'No applications awaiting review'
                : '$pending ${pending == 1 ? 'application' : 'applications'}\nawaiting review',
            style: AppTypography.style(
              AppTextRole.cardTitle,
              fontSize: 17,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            total == 0 ? 'Submitted applications will appear here.' : 'Review submitted requirements and record your team’s decision.',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 14,
              color: const Color(0xFFD2E3CE),
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kOrgPrimary,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: onReview,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Review applications'),
              ),
              if (onAnalytics != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: onAnalytics,
                  icon: const Icon(Icons.insights_outlined, size: 18),
                  label: const Text('View analytics'),
                ),
            ],
          ),
        ],
      );
      final chart = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '$decided decisions recorded across $total applications',
            child: SizedBox(
              width: 128,
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      color: const Color(0xFFC7DCA4),
                      backgroundColor: const Color(0xFF356244),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$decided / $total',
                        style: AppTypography.style(
                          AppTextRole.metric,
                          fontSize: 24,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'decisions recorded',
                        style: AppTypography.style(
                          AppTextRole.label,
                          fontSize: 11,
                          color: const Color(0xFFD2E3CE),
                          height: 1.4,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Recorded application decisions',
            style: AppTypography.style(
              AppTextRole.label,
              fontSize: 12,
              color: const Color(0xFFD2E3CE),
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
        ],
      );
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 24 : 32),
        decoration: BoxDecoration(
          color: kOrgPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  narrative,
                  const SizedBox(height: 28),
                  Center(child: chart),
                ],
              )
            : Row(
                children: [
                  Expanded(child: narrative),
                  const SizedBox(width: 32),
                  chart,
                ],
              ),
      );
    },
  );
}
