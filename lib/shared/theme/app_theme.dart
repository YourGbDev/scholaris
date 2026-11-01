// lib/shared/theme/app_theme.dart
//
// Centralized Scholaris design tokens derived directly from the Stitch
// Academic Momentum design specifications (`academic_momentum/DESIGN.md`).
//
// Typography:
// - Bundled Geist Sans on every platform; explicit weights 400–800.
// - Legacy font helpers share the same family to preserve existing call sites.

import 'package:flutter/material.dart';
import 'app_font.dart';
import 'app_motion.dart';
export 'app_font.dart';

// --- Stitch Color Tokens ----------------------------------------------------

// Primary: Institutional Authority & Bridge Green
const Color kPrimary = Color(0xFF0F4D2E); // Core Bridge Green
const Color kPrimaryDark = Color(0xFF00351C);
const Color kPrimaryContainer = Color(0xFF0F4D2E); // Core Bridge Green
const Color kOnPrimary = Color(0xFFFFFFFF);
const Color kOnPrimaryContainer = Color(0xFF82BD95);
const Color kInversePrimary = Color(0xFF98D4AB);
const Color kPrimaryFixed = Color(0xFFB3F1C6);
const Color kPrimaryFixedDim = Color(0xFF98D4AB);
const Color kOnPrimaryFixed = Color(0xFF002110);
const Color kOnPrimaryFixedVariant = Color(0xFF145131);

// Secondary: Navy Trust & Structural Stability
const Color kSecondary = Color(0xFF436084);
const Color kOnSecondary = Color(0xFFFFFFFF);
const Color kSecondaryContainer = Color(0xFFB6D4FE);
const Color kOnSecondaryContainer = Color(0xFF3F5B7F);
const Color kSecondaryFixed = Color(0xFFD2E4FF);
const Color kSecondaryFixedDim = Color(0xFFABC9F2);
const Color kOnSecondaryFixed = Color(0xFF001C38);
const Color kOnSecondaryFixedVariant = Color(0xFF2B486B);
const Color kNavyTrust = Color(0xFF1B3A5C);

// Tertiary & Accent: Golden Opportunity (Achievement & Grants)
const Color kTertiary = Color(0xFF3C2A00);
const Color kOnTertiary = Color(0xFFFFFFFF);
const Color kTertiaryContainer = Color(0xFF583F00);
const Color kOnTertiaryContainer = Color(0xFFE1A604);
const Color kTertiaryFixed = Color(0xFFFFDEA3);
const Color kTertiaryFixedDim = Color(0xFFFABC28);
const Color kOnTertiaryFixed = Color(0xFF261900);
const Color kOnTertiaryFixedVariant = Color(0xFF5D4200);
const Color kAccent = Color(0xFFF1B41E); // Golden Opportunity

// Alert & Urgency: Coral Connect & Error
const Color kCoralConnect = Color(0xFFFF6F59);
const Color kError = Color(0xFFBA1A1A);
const Color kOnError = Color(0xFFFFFFFF);
const Color kErrorContainer = Color(0xFFFFDAD6);
const Color kOnErrorContainer = Color(0xFF93000A);
const Color kErrorSoft = Color(0x14BA1A1A);
const Color kPrimarySoft = Color(0x140F4D2E);

// Surfaces & Neutrals
const Color kBackground = Color(0xFFF8FAF8);
// Calmer student browsing canvas; other roles keep their existing surfaces.
const Color kStudentCanvas = Color(0xFFF3F6F3);
const Color kSurface = Color(0xFFFFFFFF);
const Color kSurfaceDim = Color(0xFFD4DAEA);
const Color kSurfaceBright = Color(0xFFFFFFFF);
const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color kSurfaceContainerLow = Color(0xFFF1F3FF);
const Color kSurfaceContainer = Color(0xFFE8EEFF);
const Color kSurfaceContainerHigh = Color(0xFFE3E8F9);
const Color kSurfaceContainerHighest = Color(0xFFDDE2F3);
const Color kSurfaceWarm = Color(0xFFFFFFFF);
const Color kSurfaceCard = Color(0xFFFFFFFF);

// Content & Outlines
const Color kOnSurface = Color(0xFF161C27);
const Color kOnSurfaceVariant = Color(0xFF404942);
const Color kInverseSurface = Color(0xFF2A303D);
const Color kInverseOnSurface = Color(0xFFECF0FF);
const Color kOutline = Color(0xFF707971);
const Color kOutlineVariant = Color(0xFFC0C9C0);
const Color kBorderLight = Color(0xFFE2E8E5);
const Color kPrimaryLight = Color(0xFFB3F1C6);

const Color kTextPrimary = Color(0xFF111827);
const Color kTextSecondary = Color(0xFF404942);
// Substantial gray supporting copy, distinct from headings and status colors.
const Color kTextSupporting = Color(0xFF64748B);

// Informational benefit/qualification tags, separate from status and filter colors.
const Color kScholarshipTagBackground = Color(0xFFEAEAEA);
const Color kScholarshipTagForeground = Color(0xFF374151);

// Backward-compatible alias tokens
const Color kLumiGold = Color(0xFFFABC28);
const Color kLumiSoftOrange = Color(0xFFFFB74D);
const Color kWarmCream = Color(0xFFF1F3FF);
const Color kWarmCreamBorder = Color(0xFFE3E8F9);
const Color kMatchGoldSoft = Color(0x28FABC28);
const Color kMatchGoldBorder = Color(0x66FABC28);
const Color kMatchGoldText = Color(0xFF5D4200);

// --- Shape & Elevation Tokens -----------------------------------------------

const double kRadiusInput = 12.0;
const double kRadiusCard = 26.0;
const double kRadiusCardFeatured = kRadiusCard;
const double kSpaceMd = 24.0;

const Color kCardShadow = Color(0x0A1B3A5C);

/// Faint neutral outline shared by the soft content-card surfaces.
const BorderSide kHairlineBorderSide = BorderSide(
  color: Color(0x0A161C27),
  width: 0.5,
);

const Border kCardBorderCrisp = Border.fromBorderSide(kHairlineBorderSide);

/// Shared soft elevation, matching the scholarship program cards.
const List<BoxShadow> kCardElevationCrisp = [
  BoxShadow(
    color: Color(0x050F172A),
    blurRadius: 16,
    offset: Offset(0, 4),
  ),
];

/// Default for full-size content cards; status borders can override the border.
const BoxDecoration kSoftCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(kRadiusCard)),
  border: kCardBorderCrisp,
  boxShadow: kCardElevationCrisp,
);

const LinearGradient kHeroSurface = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F4D2E), Color(0xFF1B3A5C)],
);

// --- Typography Helpers -----------------------------------------------------

FontWeight _geistWeight(FontWeight requested) {
  if (requested.value > 800) return FontWeight.w800;
  if (requested.value < 400) return FontWeight.w400;
  return requested;
}

TextStyle appGreeting({double fontSize = 32}) => geist(
  fontSize: fontSize, fontWeight: FontWeight.w800,
  letterSpacing: -1.0, height: 1.12, color: const Color(0xFF0F172A),
);

/// Strong title/action roles; smaller medium labels keep their hierarchy.
FontWeight appTitleWeight(FontWeight requested, double fontSize) =>
    requested.value >= 700 || (fontSize >= 14 && requested.value >= 600)
        ? FontWeight.w800 : requested;

TextStyle appHeading({required double fontSize, Color? color}) => geist(
  fontSize: fontSize, fontWeight: FontWeight.w800,
  letterSpacing: fontSize >= 24 ? -.8 : -.6,
  height: 1.15, color: color ?? const Color(0xFF0F172A),
);

TextStyle appCardTitle({double fontSize = 17}) => geist(
  fontSize: fontSize, fontWeight: FontWeight.w800,
  letterSpacing: -.35, height: 1.25, color: const Color(0xFF0F172A),
);

TextStyle appSupporting({double fontSize = 14, Color? color}) => geist(
  fontSize: fontSize, fontWeight: FontWeight.w600,
  letterSpacing: -.1, height: 1.4, color: color ?? kTextSupporting,
);

TextStyle appAmount({double fontSize = 24}) => geist(
  fontSize: fontSize, fontWeight: FontWeight.w800,
  letterSpacing: -.5, height: 1.15, color: kPrimary,
);

TextStyle appStatusLabel({Color? color}) => geist(
  fontSize: 12, fontWeight: FontWeight.w600,
  letterSpacing: -.15, height: 1.25, color: color,
);

TextStyle appAttributeLabel() => geist(
  fontSize: 11.5, fontWeight: FontWeight.w700,
  letterSpacing: -.1, height: 1.3, color: kScholarshipTagForeground,
);

TextStyle appOverline() => geist(
  fontSize: 11, fontWeight: FontWeight.w600,
  letterSpacing: .6, height: 1.3, color: kTextSupporting,
);

/// Legacy helper name; selects bundled Geist without platform or network font switching.
TextStyle geist({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
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
}) => (textStyle ?? const TextStyle()).copyWith(
  fontFamily: kAppFontFamily,
  color: color,
  backgroundColor: backgroundColor,
  fontSize: fontSize,
  fontWeight: _geistWeight(fontWeight ?? textStyle?.fontWeight ?? FontWeight.w400),
  fontStyle: fontStyle,
  letterSpacing: letterSpacing ?? textStyle?.letterSpacing ?? -.1,
  wordSpacing: wordSpacing,
  textBaseline: textBaseline,
  height: height ?? textStyle?.height ?? 1.4,
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



/// Compatibility helper; headings and labels use the shared Geist family.
/// Tight tracking and leading distinguish titles from supporting copy.
TextStyle outfit({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
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
}) => geist(
  textStyle: textStyle ?? const TextStyle(fontFamilyFallback: ['Roboto']),
  color: color,
  backgroundColor: backgroundColor,
  fontSize: fontSize,
  fontWeight: appTitleWeight(fontWeight ?? textStyle?.fontWeight ?? FontWeight.w600, fontSize ?? textStyle?.fontSize ?? 14),
  fontStyle: fontStyle,
  letterSpacing: letterSpacing ?? (fontSize != null && fontSize >= 18 ? -.6 : -.3),
  wordSpacing: wordSpacing,
  textBaseline: textBaseline,
  height: height ?? 1.25,
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

/// Compatibility helper; body copy uses the shared Geist family.
/// Supporting copy keeps the fuller semibold weight and current tracking.
TextStyle openSans({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
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
}) => geist(
  textStyle: textStyle ?? const TextStyle(fontFamilyFallback: ['Roboto']),
  color: color,
  backgroundColor: backgroundColor,
  fontSize: fontSize,
  fontWeight: fontWeight ?? textStyle?.fontWeight ?? FontWeight.w600,
  fontStyle: fontStyle,
  letterSpacing: letterSpacing ?? -.1,
  wordSpacing: wordSpacing,
  textBaseline: textBaseline,
  height: height ?? 1.4,
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

/// Compatibility helper; wordmarks and headers use the shared Geist face.
TextStyle poppins({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
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
}) => geist(
  textStyle: textStyle ?? const TextStyle(fontFamilyFallback: ['Roboto']),
  color: color,
  backgroundColor: backgroundColor,
  fontSize: fontSize,
  fontWeight: appTitleWeight(fontWeight ?? textStyle?.fontWeight ?? FontWeight.w700, fontSize ?? textStyle?.fontSize ?? 14),
  fontStyle: fontStyle,
  letterSpacing: letterSpacing ?? -.6,
  wordSpacing: wordSpacing,
  textBaseline: textBaseline,
  height: height ?? 1.2,
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

/// Institutional font for Admin & Provider consoles.
TextStyle inter({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
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
}) => geist(
  textStyle: textStyle ?? const TextStyle(fontFamilyFallback: ['Roboto']),
  color: color,
  backgroundColor: backgroundColor,
  fontSize: fontSize,
  fontWeight: fontWeight ?? textStyle?.fontWeight ?? FontWeight.w500,
  fontStyle: fontStyle,
  letterSpacing: letterSpacing ?? -.1,
  wordSpacing: wordSpacing,
  textBaseline: textBaseline,
  height: height ?? 1.4,
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

// --- ThemeData --------------------------------------------------------------

ThemeData scholarisTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kPrimaryContainer,
    primary: kPrimaryContainer,
    onPrimary: kOnPrimary,
    secondary: kSecondary,
    onSecondary: kOnSecondary,
    tertiary: kAccent,
    error: kError,
    onError: kOnError,
    surface: kSurfaceContainerLowest,
    onSurface: kOnSurface,
  );

  final baseTextTheme = TextTheme(
    displayLarge: appGreeting(fontSize: 36),
    displayMedium: appGreeting(fontSize: 32),
    displaySmall: appGreeting(),
    headlineLarge: appHeading(fontSize: 28),
    headlineMedium: appHeading(fontSize: 24),
    headlineSmall: appHeading(fontSize: 20),
    titleLarge: appHeading(fontSize: 18),
    titleMedium: appCardTitle(fontSize: 16),
    bodyLarge: geist(fontSize: 16, fontWeight: FontWeight.w500, color: kTextSupporting),
    bodyMedium: geist(fontSize: 14, fontWeight: FontWeight.w500, color: kTextSupporting),
    bodySmall: geist(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSupporting),
    labelLarge: outfit(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: geist(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: -.1),
    labelSmall: appOverline(),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kBackground,
    fontFamily: kAppFontFamily,
    textTheme: baseTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: kSurfaceContainerLowest,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: appHeading(fontSize: 18, color: kOnSurface),
      iconTheme: const IconThemeData(color: kOnSurface),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryContainer,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusInput),
        ),
        textStyle: outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
        borderSide: const BorderSide(color: kBorderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
        borderSide: const BorderSide(color: kBorderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
        borderSide: const BorderSide(color: kPrimaryContainer, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
        borderSide: const BorderSide(color: kError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
        borderSide: const BorderSide(color: kError, width: 1.5),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ScholarisPageTransitionsBuilder(),
        TargetPlatform.iOS: ScholarisPageTransitionsBuilder(),
        TargetPlatform.linux: ScholarisPageTransitionsBuilder(),
        TargetPlatform.macOS: ScholarisPageTransitionsBuilder(),
        TargetPlatform.windows: ScholarisPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kOnSurface,
      contentTextStyle: openSans(color: Colors.white, fontSize: 13, letterSpacing: -.1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: kSurfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: kSurfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadiusCard)),
        side: kHairlineBorderSide,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSurfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
