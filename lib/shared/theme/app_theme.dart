// lib/shared/theme/app_theme.dart
//
// Centralized Scholaris design tokens derived directly from the Stitch
// Academic Momentum design specifications (`academic_momentum/DESIGN.md`).
//
// Typography:
// - Platform-adaptive families and semantic roles live in app_typography.dart.

import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

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
const Color kBackground = Color(0xFFF8FAF8);
// Student pages and quiet nested surfaces use neutral whites and grays.
const Color kStudentCanvas = Color(0xFFFFFFFF);
const Color kStudentSurfaceSubtle = Color(0xFFF6F6F6);
const Color kStudentDivider = Color(0xFFE8E8E8);
const Color kSurface = Color(0xFFFFFFFF);
const Color kSurfaceDim = Color(0xFFD9DFDB);
const Color kSurfaceBright = Color(0xFFFFFFFF);
const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color kSurfaceContainerLow = Color(0xFFF5F7F5);
const Color kSurfaceContainer = Color(0xFFEEF1EE);
const Color kSurfaceContainerHigh = Color(0xFFE6EBE7);
const Color kSurfaceContainerHighest = Color(0xFFDDE3DE);
const Color kSurfaceWarm = Color(0xFFFFFFFF);
const Color kSurfaceCard = Color(0xFFFFFFFF);

// Content & Outlines
const Color kOnSurface = Color(0xFF161C27);
const Color kOnSurfaceVariant = Color(0xFF404942);
const Color kInverseSurface = Color(0xFF2A303D);
const Color kInverseOnSurface = Color(0xFFECF0FF);
const Color kOutline = Color(0xFF707971);
const Color kOutlineVariant = Color(0xFFC0C9C0);
const Color kBorderLight = Color(0xFFE2E4E3);
const Color kPrimaryLight = Color(0xFFB3F1C6);

const Color kTextPrimary = Color(0xFF111827);
const Color kTextSecondary = Color(0xFF404942);
// Substantial gray supporting copy, distinct from headings and status colors.
const Color kTextSupporting = Color(0xFF626C65);

// Informational benefit/qualification tags, separate from status and filter colors.
const Color kScholarshipTagBackground = Color(0xFFEAEAEA);
const Color kScholarshipTagForeground = Color(0xFF374151);

// Backward-compatible alias tokens
const Color kLumiGold = Color(0xFFFABC28);
const Color kLumiSoftOrange = Color(0xFFFFB74D);
const Color kWarmCream = Color(0xFFF5F7F5);
const Color kWarmCreamBorder = Color(0xFFE6EBE7);
const Color kMatchGoldSoft = Color(0x28FABC28);
const Color kMatchGoldBorder = Color(0x66FABC28);
const Color kMatchGoldText = Color(0xFF5D4200);

// --- Shape & Elevation Tokens -----------------------------------------------

const double kRadiusInput = 12.0;
const double kRadiusCard = 26.0;
const double kRadiusCardFeatured = kRadiusCard;
const double kSpaceMd = 24.0;

const Color kCardShadow = Color(0x0A1B3A5C);

/// Neutral outline that keeps white cards distinct on a white canvas.
const BorderSide kHairlineBorderSide = BorderSide(
  color: Color(0xFFE2E4E3),
  width: 0.75,
);

const Border kCardBorderCrisp = Border.fromBorderSide(kHairlineBorderSide);

/// Shared soft elevation, matching the scholarship program cards.
const List<BoxShadow> kCardElevationCrisp = [
  BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4)),
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

/// Honor each component's title/label weight; never promote all text to extra-bold.

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

  // Shared hierarchy for all roles; surfaces may refine size, never font family.
  final baseTextTheme = TextTheme(
    displayLarge: AppTypography.style(
      AppTextRole.screenTitle,
      fontSize: 32,
      height: 1.25,
      color: kTextPrimary,
      letterSpacing: -0.6,
    ),
    displayMedium: AppTypography.style(
      AppTextRole.screenTitle,
      fontSize: 28,
      height: 1.25,
      color: kTextPrimary,
      letterSpacing: -0.6,
    ),
    displaySmall: AppTypography.style(
      AppTextRole.screenTitle,
      fontSize: 24,
      height: 1.25,
      color: kTextPrimary,
      letterSpacing: -0.3,
    ),
    headlineLarge: AppTypography.style(
      AppTextRole.screenTitle,
      fontSize: 24,
      height: 1.25,
      color: kTextPrimary,
      letterSpacing: -0.3,
    ),
    headlineMedium: AppTypography.style(
      AppTextRole.screenTitle,
      fontSize: 22,
      height: 1.25,
      color: kTextPrimary,
      letterSpacing: -0.3,
    ),
    headlineSmall: AppTypography.style(
      AppTextRole.screenTitle,
      fontSize: 20,
      height: 1.25,
      color: kTextPrimary,
      letterSpacing: -0.3,
    ),
    titleLarge: AppTypography.style(
      AppTextRole.screenTitle,
      fontSize: 17,
      height: 1.25,
      color: kTextPrimary,
      letterSpacing: -0.15,
    ),
    titleMedium: AppTypography.style(
      AppTextRole.cardTitle,
      fontSize: 15,
      height: 1.3,
      color: kTextPrimary,
      letterSpacing: -.15,
    ),
    bodyLarge: AppTypography.style(
      AppTextRole.body,
      fontSize: 14,
      color: kTextSecondary,
      height: 1.4,
      letterSpacing: 0,
    ),
    bodyMedium: AppTypography.style(
      AppTextRole.body,
      fontSize: 13,
      color: kTextSecondary,
      height: 1.4,
      letterSpacing: 0,
    ),
    bodySmall: AppTypography.style(
      AppTextRole.caption,
      fontSize: 12,
      color: kTextSecondary,
      height: 1.4,
      letterSpacing: 0,
    ),
    labelLarge: AppTypography.style(
      AppTextRole.button,
      fontSize: 13,
      height: 1.25,
      letterSpacing: 0,
    ),
    labelMedium: AppTypography.style(
      AppTextRole.label,
      fontSize: 12,
      letterSpacing: -.1,
      height: 1.4,
    ),
    labelSmall: AppTypography.style(
      AppTextRole.label,
      fontSize: 11,
      height: 1.3,
      color: kTextSupporting,
      letterSpacing: .6,
    ),
  );

  return applyScholarisTypography(ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kBackground,
    fontFamily: AppTypography.familyFor(14),
    textTheme: baseTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: kSurfaceContainerLowest,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.style(
        AppTextRole.screenTitle,
        fontSize: 18,
        color: kOnSurface,
        height: 1.25,
        letterSpacing: -0.15,
      ),
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
        textStyle: AppTypography.style(
          AppTextRole.button,
          fontSize: 13,
          height: 1.25,
          letterSpacing: 0,
        ),
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
      contentTextStyle: AppTypography.style(
        AppTextRole.body,
        color: Colors.white,
        fontSize: 13,
        letterSpacing: -.1,
        height: 1.4,
      ),
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
  ));
}

ThemeData applyScholarisTypography(ThemeData theme) {
  final text = AppTypography.textTheme(theme.textTheme);
  final action = AppTypography.style(AppTextRole.button, base: text.labelLarge);
  final navigation = AppTypography.style(
    AppTextRole.navigation,
    base: text.labelMedium,
  );
  ButtonStyle actions(ButtonStyle? existing) =>
      (existing ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.style(
            AppTextRole.button,
            base: existing?.textStyle?.resolve(states) ?? action,
          ),
        ),
      );
  return theme.copyWith(
    textTheme: text,
    primaryTextTheme: AppTypography.textTheme(theme.primaryTextTheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: actions(theme.elevatedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: actions(theme.textButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: actions(theme.outlinedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: actions(theme.filledButtonTheme.style),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      labelStyle: AppTypography.style(
        AppTextRole.label,
        base: theme.inputDecorationTheme.labelStyle,
      ),
      floatingLabelStyle: AppTypography.style(
        AppTextRole.label,
        base: theme.inputDecorationTheme.floatingLabelStyle,
      ),
      hintStyle: AppTypography.style(
        AppTextRole.placeholder,
        base: theme.inputDecorationTheme.hintStyle,
      ),
      helperStyle: AppTypography.style(
        AppTextRole.caption,
        base: theme.inputDecorationTheme.helperStyle,
      ),
      errorStyle: AppTypography.style(
        AppTextRole.caption,
        base: theme.inputDecorationTheme.errorStyle,
      ),
    ),
    navigationBarTheme: theme.navigationBarTheme.copyWith(
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTypography.style(
          AppTextRole.navigation,
          base:
              theme.navigationBarTheme.labelTextStyle?.resolve(states) ??
              navigation.copyWith(
                color: states.contains(WidgetState.disabled)
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: .38)
                    : states.contains(WidgetState.selected)
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    ),
    navigationRailTheme: theme.navigationRailTheme.copyWith(
      selectedLabelTextStyle: AppTypography.style(
        AppTextRole.navigation,
        base: theme.navigationRailTheme.selectedLabelTextStyle ?? navigation,
      ),
      unselectedLabelTextStyle: AppTypography.style(
        AppTextRole.navigation,
        base: theme.navigationRailTheme.unselectedLabelTextStyle ?? navigation,
      ),
    ),
    bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
      selectedLabelStyle: AppTypography.style(
        AppTextRole.navigation,
        base: theme.bottomNavigationBarTheme.selectedLabelStyle,
      ),
      unselectedLabelStyle: AppTypography.style(
        AppTextRole.navigation,
        base: theme.bottomNavigationBarTheme.unselectedLabelStyle,
      ),
    ),
    tabBarTheme: theme.tabBarTheme.copyWith(
      labelStyle: AppTypography.style(
        AppTextRole.navigation,
        base: theme.tabBarTheme.labelStyle ?? text.titleSmall,
      ),
      unselectedLabelStyle: AppTypography.style(
        AppTextRole.navigation,
        base: theme.tabBarTheme.unselectedLabelStyle ?? text.titleSmall,
      ),
    ),
    chipTheme: theme.chipTheme.copyWith(
      labelStyle: AppTypography.style(
        AppTextRole.badge,
        base: theme.chipTheme.labelStyle ?? text.labelLarge,
      ),
    ),
    dialogTheme: theme.dialogTheme.copyWith(
      titleTextStyle: AppTypography.style(
        AppTextRole.sectionTitle,
        base: theme.dialogTheme.titleTextStyle ?? text.headlineSmall,
      ),
      contentTextStyle: AppTypography.style(
        AppTextRole.body,
        base: theme.dialogTheme.contentTextStyle ?? text.bodyMedium,
      ),
    ),
  );
}
