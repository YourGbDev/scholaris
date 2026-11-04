import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/theme/app_typography.dart';

void main() {
  test('all platforms and web universally resolve to bundled Geist', () {
    for (final isWeb in [true, false]) {
      for (final platform in TargetPlatform.values) {
        for (final size in [12.0, 20.0, 36.0]) {
          expect(
            AppTypography.resolveFontFamily(
              isWeb: isWeb,
              platform: platform,
              fontSize: size,
            ),
            'Geist',
          );
        }
      }
    }
  });
  test('all fifteen roles use exactly the approved semantic weights', () {
    final expected = <AppTextRole, FontWeight>{
      AppTextRole.display: FontWeight.w700,
      AppTextRole.screenTitle: FontWeight.w700,
      AppTextRole.metric: FontWeight.w700,
      AppTextRole.sectionTitle: FontWeight.w600,
      AppTextRole.cardTitle: FontWeight.w600,
      AppTextRole.button: FontWeight.w600,
      AppTextRole.bodyEmphasis: FontWeight.w500,
      AppTextRole.label: FontWeight.w500,
      AppTextRole.navigation: FontWeight.w500,
      AppTextRole.badge: FontWeight.w500,
      AppTextRole.subtitle: FontWeight.w400,
      AppTextRole.body: FontWeight.w400,
      AppTextRole.caption: FontWeight.w400,
      AppTextRole.input: FontWeight.w400,
      AppTextRole.placeholder: FontWeight.w400,
    };
    expect(expected.keys.toSet(), AppTextRole.values.toSet());
    for (final entry in expected.entries) {
      expect(AppTypography.style(entry.key).fontWeight, entry.value);
    }
  });
  test(
    'all native targets retain the same role weights and resolve to Geist',
    () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        for (final role in AppTextRole.values) {
          final style = AppTypography.style(role, fontSize: 16);
          expect(style.fontWeight, AppTypography.weightFor(role));
          expect(style.fontFamily, 'Geist');
          expect(
            AppTypography.resolveFontFamily(
              isWeb: true,
              platform: platform,
              fontSize: 28,
            ),
            'Geist',
          );
        }
      }
    },
  );
  test(
    'semantic application preserves existing geometry and text features',
    () {
      const base = TextStyle(
        fontFamily: 'OldFamily',
        fontSize: 13.5,
        height: 1.45,
        letterSpacing: -.15,
        wordSpacing: .2,
        color: Colors.green,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        decoration: TextDecoration.underline,
        fontFeatures: [FontFeature.tabularFigures()],
      );
      final actual = AppTypography.style(AppTextRole.caption, base: base);
      expect(actual.fontWeight, FontWeight.w400);
      expect(actual.fontFamily, 'Geist');
      expect(actual.fontSize, base.fontSize);
      expect(actual.height, base.height);
      expect(actual.letterSpacing, base.letterSpacing);
      expect(actual.wordSpacing, base.wordSpacing);
      expect(actual.color, base.color);
      expect(actual.decoration, base.decoration);
      expect(actual.fontStyle, base.fontStyle);
      expect(actual.fontFeatures, base.fontFeatures);
    },
  );
  test('styles resolve universal Geist family across platforms', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      AppTypography.style(AppTextRole.body, fontSize: 14).fontFamily,
      'Geist',
    );
    expect(
      AppTypography.style(AppTextRole.display, fontSize: 28).fontFamily,
      'Geist',
    );
    expect(AppTypography.style(AppTextRole.body).fontFamilyFallback, isEmpty);
  });
}
