import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Roles describe meaning, independently of screen, size, color or platform.
enum AppTextRole {
  display,
  screenTitle,
  sectionTitle,
  cardTitle,
  subtitle,
  body,
  bodyEmphasis,
  label,
  caption,
  button,
  navigation,
  metric,
  badge,
  input,
  placeholder,
}

/// The single authority for app-owned font families and default role weights.
abstract final class AppTypography {
  /// The universal typography family across all platforms and environments.
  static const String kUniversalFontFamily = 'Geist';

  static String resolveFontFamily({
    required bool isWeb,
    required TargetPlatform platform,
    double? fontSize,
  }) => kUniversalFontFamily;

  static String familyFor(double? fontSize) => resolveFontFamily(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    fontSize: fontSize,
  );

  // Missing glyphs and emoji continue through Flutter's platform fallback.
  static List<String> get fallback => const [];

  static FontWeight weightFor(AppTextRole role) => switch (role) {
    AppTextRole.display ||
    AppTextRole.screenTitle ||
    AppTextRole.metric => FontWeight.w700,
    AppTextRole.sectionTitle ||
    AppTextRole.cardTitle ||
    AppTextRole.button => FontWeight.w600,
    AppTextRole.bodyEmphasis ||
    AppTextRole.label ||
    AppTextRole.navigation ||
    AppTextRole.badge => FontWeight.w500,
    AppTextRole.subtitle ||
    AppTextRole.body ||
    AppTextRole.caption ||
    AppTextRole.input ||
    AppTextRole.placeholder => FontWeight.w400,
  };

  /// Fill even the Material slots that individual screens don't override.
  static TextTheme textTheme(TextTheme base) => base.copyWith(
    displayLarge: style(AppTextRole.display, base: base.displayLarge),
    displayMedium: style(AppTextRole.display, base: base.displayMedium),
    displaySmall: style(AppTextRole.display, base: base.displaySmall),
    headlineLarge: style(AppTextRole.screenTitle, base: base.headlineLarge),
    headlineMedium: style(AppTextRole.sectionTitle, base: base.headlineMedium),
    headlineSmall: style(AppTextRole.sectionTitle, base: base.headlineSmall),
    titleLarge: style(AppTextRole.screenTitle, base: base.titleLarge),
    titleMedium: style(AppTextRole.cardTitle, base: base.titleMedium),
    titleSmall: style(AppTextRole.cardTitle, base: base.titleSmall),
    bodyLarge: style(AppTextRole.body, base: base.bodyLarge),
    bodyMedium: style(AppTextRole.body, base: base.bodyMedium),
    bodySmall: style(AppTextRole.caption, base: base.bodySmall),
    labelLarge: style(AppTextRole.label, base: base.labelLarge),
    labelMedium: style(AppTextRole.label, base: base.labelMedium),
    labelSmall: style(AppTextRole.label, base: base.labelSmall),
  );

  /// Apply semantics while retaining the caller's existing visual geometry.
  /// No fontWeight/fontFamily argument: changes to those belong in this file.
  static TextStyle style(
    AppTextRole role, {
    TextStyle? base,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) => (base ?? const TextStyle()).copyWith(
    fontFamily: familyFor(fontSize ?? base?.fontSize),
    fontFamilyFallback: fallback,
    fontWeight: weightFor(role),
    color: color,
    backgroundColor: backgroundColor,
    fontSize: fontSize,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    height: height,
    locale: locale,
    foreground: foreground,
    background: background,
    shadows: shadows,
    fontFeatures: fontFeatures,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
  );
}
