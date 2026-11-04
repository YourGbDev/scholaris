import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Read-only evidence from the device; never changes accessibility preferences.
void showTypographyDiagnostics(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
        'Typography check',
        style: AppTypography.style(
          AppTextRole.screenTitle,
          fontSize: 20,
          height: 1.25,
          color: kTextPrimary,
          letterSpacing: -0.3,
        ),
      ),
      content: const SizedBox(width: 420, child: TypographyDiagnostics()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class TypographyDiagnostics extends StatelessWidget {
  const TypographyDiagnostics({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const version = String.fromEnvironment(
      'FLUTTER_BUILD_NAME',
      defaultValue: 'unknown',
    );
    const build = String.fromEnvironment(
      'FLUTTER_BUILD_NUMBER',
      defaultValue: 'unknown',
    );
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnostic: type-probe-1',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 12,
              height: 1.4,
              color: kTextSupporting,
              letterSpacing: 0,
            ),
          ),
          Text(
            'Build: $version+$build',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 12,
              height: 1.4,
              color: kTextSupporting,
              letterSpacing: 0,
            ),
          ),
          Text(
            'Platform: ${kIsWeb ? 'web' : defaultTargetPlatform.name}',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 12,
              height: 1.4,
              color: kTextSupporting,
              letterSpacing: 0,
            ),
          ),
          Text(
            'Family requested: ${AppTypography.familyFor(16)}',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 12,
              height: 1.4,
              color: kTextSupporting,
              letterSpacing: 0,
            ),
          ),
          Text(
            'Runtime bold text: ${media.boldText}',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 12,
              height: 1.4,
              color: kTextSupporting,
              letterSpacing: 0,
            ),
          ),
          Text(
            'Text scale at 16px: ${media.textScaler.scale(16).toStringAsFixed(1)}px',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 12,
              height: 1.4,
              color: kTextSupporting,
              letterSpacing: 0,
            ),
          ),
          Text(
            'Viewport: ${media.size.width.round()} × ${media.size.height.round()}',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 12,
              height: 1.4,
              color: kTextSupporting,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Standard app text',
            style: AppTypography.style(
              AppTextRole.cardTitle,
              fontSize: 15,
              height: 1.3,
              color: kTextPrimary,
              letterSpacing: -.15,
            ),
          ),
          for (final role in [
            AppTextRole.body,
            AppTextRole.label,
            AppTextRole.button,
            AppTextRole.screenTitle,
          ])
            Text(
              '${AppTypography.familyFor(16)} ${AppTypography.weightFor(role).value} • Scholarship',
              key: ValueKey(
                'diagnostic-standard-${AppTypography.weightFor(role).value}',
              ),
              style: AppTypography.style(
                role,
                fontSize: 16,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Direct font control',
            style: AppTypography.style(
              AppTextRole.cardTitle,
              fontSize: 15,
              height: 1.3,
              color: kTextPrimary,
              letterSpacing: -.15,
            ),
          ),
          // Diagnostic only: compare the same font below Text's runtime override.
          // Keep device scaling, direction and glyph fallback; not a product fix.
          for (final role in [
            AppTextRole.body,
            AppTextRole.label,
            AppTextRole.button,
            AppTextRole.screenTitle,
          ])
            RichText(
              key: ValueKey(
                'diagnostic-direct-${AppTypography.weightFor(role).value}',
              ),
              textScaler: media.textScaler,
              textDirection: Directionality.of(context),
              text: TextSpan(
                text:
                    '${AppTypography.familyFor(16)} ${AppTypography.weightFor(role).value} • Scholarship',
                style: AppTypography.style(
                  role,
                  fontSize: 16,
                  color: kTextPrimary,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'These are requested weights. A screenshot compares their appearance; this panel cannot identify the final native font face.',
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 12,
              height: 1.4,
              color: kTextSupporting,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
