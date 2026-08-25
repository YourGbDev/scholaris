// lib/shared/theme/app_theme.dart
//
// Centralized Scholaris design tokens. Every screen derives its look from
// this theme so the app stays visually consistent as features grow. Screens
// should read from these constants rather than hardcoding colors/fonts.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Brand palette ----------------------------------------------------------

/// Primary brand green — used for actions, emphasis and the wordmark.
const Color kPrimary = Color(0xFF0F4D2E);

/// Accent gold — progress, highlights, urgency cues.
const Color kAccent = Color(0xFFF1B41E);

/// App background (warm off-white).
const Color kBackground = Color(0xFFFAFAF8);

/// Error / destructive color.
const Color kError = Color(0xFFB3261E);

/// Soft green tint used for focus rings and subtle surfaces.
const Color kPrimarySoft = Color(0x140F4D2E);

// --- Shape tokens -----------------------------------------------------------

/// Standard radius for inputs, buttons and small surfaces.
const double kRadiusInput = 12.0;

/// Radius for cards and elevated surfaces.
const double kRadiusCard = 16.0;

// --- Typography helpers -----------------------------------------------------

TextStyle poppins({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w500,
  Color? color,
  double? height,
}) =>
    GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );

TextStyle openSans({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
}) =>
    GoogleFonts.openSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );

/// Builds the Scholaris [ThemeData] used by the root [MaterialApp].
ThemeData scholarisTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    primary: kPrimary,
    secondary: kAccent,
    error: kError,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kBackground,
    fontFamily: GoogleFonts.openSans().fontFamily,
    textTheme: TextTheme(
      displaySmall: poppins(fontSize: 40, fontWeight: FontWeight.w700),
      headlineMedium: poppins(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: poppins(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: poppins(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: openSans(fontSize: 14),
      bodySmall: openSans(fontSize: 12),
      labelLarge: poppins(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: poppins(fontSize: 18, fontWeight: FontWeight.w600),
      iconTheme: const IconThemeData(color: kPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusInput),
        ),
        textStyle: poppins(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        side: const BorderSide(color: kPrimary),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusInput),
        ),
        textStyle: poppins(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: openSans(color: Colors.black54),
      helperStyle: openSans(color: Colors.black45, fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kPrimarySoft,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
        poppins(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: openSans(),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusInput),
      ),
    ),
  );
}
