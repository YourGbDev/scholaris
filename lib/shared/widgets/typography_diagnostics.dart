import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Read-only evidence from the device; never changes accessibility preferences.
void showTypographyDiagnostics(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Typography check', style: appHeading(fontSize: 20)),
      content: const SizedBox(width: 420, child: TypographyDiagnostics()),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    ),
  );
}

class TypographyDiagnostics extends StatelessWidget {
  const TypographyDiagnostics({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const version = String.fromEnvironment('FLUTTER_BUILD_NAME', defaultValue: 'unknown');
    const build = String.fromEnvironment('FLUTTER_BUILD_NUMBER', defaultValue: 'unknown');
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnostic: type-probe-1', style: appSupporting(fontSize: 12)),
          Text('Build: $version+$build', style: appSupporting(fontSize: 12)),
          Text('Platform: ${kIsWeb ? 'web' : defaultTargetPlatform.name}', style: appSupporting(fontSize: 12)),
          Text('Family requested: $kAppFontFamily', style: appSupporting(fontSize: 12)),
          Text('Runtime bold text: ${media.boldText}', style: appSupporting(fontSize: 12)),
          Text('Text scale at 16px: ${media.textScaler.scale(16).toStringAsFixed(1)}px', style: appSupporting(fontSize: 12)),
          Text('Viewport: ${media.size.width.round()} × ${media.size.height.round()}', style: appSupporting(fontSize: 12)),
          const SizedBox(height: 16),
          Text('Standard app text', style: appCardTitle(fontSize: 15)),
          for (final weight in [FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800])
            Text('Geist ${weight.value} • Scholarship',
              key: ValueKey('diagnostic-standard-${weight.value}'),
              style: geist(fontSize: 16, fontWeight: weight),
            ),
          const SizedBox(height: 16),
          Text('Direct font control', style: appCardTitle(fontSize: 15)),
          // Diagnostic only: compare the same font below Text's runtime override.
          // Keep device scaling, direction and glyph fallback; not a product fix.
          for (final weight in [FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800])
            RichText(
              key: ValueKey('diagnostic-direct-${weight.value}'),
              textScaler: media.textScaler,
              textDirection: Directionality.of(context),
              text: TextSpan(text: 'Geist ${weight.value} • Scholarship',
                style: geist(fontSize: 16, fontWeight: weight, color: kTextPrimary)),
            ),
          const SizedBox(height: 12),
          Text('These are requested weights. A screenshot compares their appearance; this panel cannot identify the final native font face.',
            style: appSupporting(fontSize: 12)),
        ],
      ),
    );
  }
}
