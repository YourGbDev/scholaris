// lib/shared/theme/app_theme.dart
//
// Centralized Scholaris design tokens derived directly from the Stitch
// Academic Momentum design specifications (`academic_momentum/DESIGN.md`).
//
// Typography:
// - Display, Headlines, Titles, Labels: Outfit
// - Body Copy & Analytical Reading: Open Sans
// - Brand Wordmark: Poppins Bold

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_motion.dart';

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
const Color kBackground = Color(0xFFF9F9FF);
const Color kSurface = Color(0xFFF9F9FF);
const Color kSurfaceDim = Color(0xFFD4DAEA);
const Color kSurfaceBright = Color(0xFFF9F9FF);
const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color kSurfaceContainerLow = Color(0xFFF1F3FF);
const Color kSurfaceContainer = Color(0xFFE8EEFF);
const Color kSurfaceContainerHigh = Color(0xFFE3E8F9);
const Color kSurfaceContainerHighest = Color(0xFFDDE2F3);
const Color kSurfaceWarm = Color(0xFFF9F9FF);
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

const Color kTextPrimary = Color(0xFF161C27);
const Color kTextSecondary = Color(0xFF404942);

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
const double kRadiusCard = 16.0;
const double kRadiusCardFeatured = 24.0;
const double kSpaceMd = 24.0;

const Color kCardShadow = Color(0x0A1B3A5C);

const LinearGradient kHeroSurface = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F4D2E), Color(0xFF1B3A5C)],
);

// --- Typography Helpers -----------------------------------------------------

/// Primary geometric font for headlines, metrics, pills, buttons, and titles.
TextStyle outfit({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
}) => GoogleFonts.outfit(
  textStyle: const TextStyle(fontFamilyFallback: ['Roboto']),
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
  decoration: decoration,
);

/// Humanist font for body copy, eligibility descriptions, and analytical text.
TextStyle openSans({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
}) => GoogleFonts.openSans(
  textStyle: const TextStyle(fontFamilyFallback: ['Roboto']),
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
  decoration: decoration,
);

/// Preserved helper for brand wordmarks and headers.
TextStyle poppins({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w700,
  Color? color,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
}) => GoogleFonts.poppins(
  textStyle: const TextStyle(fontFamilyFallback: ['Roboto']),
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
  decoration: decoration,
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

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kBackground,
    fontFamily: GoogleFonts.openSans().fontFamily,
    textTheme: TextTheme(
      displayLarge: outfit(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.02),
      headlineLarge: outfit(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.015),
      headlineMedium: outfit(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.01),
      headlineSmall: outfit(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: outfit(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: openSans(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: openSans(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: openSans(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: outfit(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.01),
      labelMedium: outfit(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.02),
      labelSmall: outfit(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.04),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kSurfaceContainerLowest,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: outfit(fontSize: 18, fontWeight: FontWeight.w700, color: kOnSurface),
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
      contentTextStyle: openSans(color: Colors.white, fontSize: 13),
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
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSurfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
