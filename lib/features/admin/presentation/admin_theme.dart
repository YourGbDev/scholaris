// lib/features/admin/presentation/admin_theme.dart
//
// Operational design system tokens for the Admin Portal.
// Apple Design DNA pass: clean squircles, #F5F5F7 sidebar, #0F4D2E active fill,
// pure white active typography, subtle hairline borders, and responsive elevation.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Color Palette -----------------------------------------------------------

/// Light Apple canvas background (#FAF9FE)
const Color kAdminSurface = Color(0xFFFAF9FE);

/// Primary operational green — nav active fill (#0F4D2E), primary CTAs, active highlights.
const Color kAdminBridgeGreen = Color(0xFF0F4D2E);

/// Navy Trust — structural dark header text and brand accents.
const Color kAdminNavyTrust = Color(0xFF1B3A5C);

/// Golden Opportunity — strictly reserved for pending / needs-attention states.
const Color kAdminGoldenOpportunity = Color(0xFFF1B41E);

/// Coral Connect — strictly reserved for rejected / critical / inactive states.
const Color kAdminCoralConnect = Color(0xFFFF6F59);

/// Subtle hairline divider / table border color.
const Color kAdminHairline = Color(0xFFE4E7EC);

/// Dark text for primary content (#1A1B1F).
const Color kAdminTextPrimary = Color(0xFF1A1B1F);

/// Muted secondary text for labels and captions (#5E6D66 / #707971).
const Color kAdminTextSecondary = Color(0xFF5E6D66);

/// Apple Light Sidebar background (#F5F5F7).
const Color kAdminSidebarBackground = Color(0xFFF5F5F7);

/// Active navigation item background (#0F4D2E).
const Color kAdminActiveNavBackground = Color(0xFF0F4D2E);

/// Active navigation item text/icon color (#FFFFFF).
const Color kAdminActiveNavText = Color(0xFFFFFFFF);

/// Inactive navigation item text color (#404942).
const Color kAdminInactiveNavText = Color(0xFF404942);

// --- Border Radius Tokens ----------------------------------------------------

/// Apple squircle card radius for stat tiles, content panels, and tables.
const BorderRadius kAdminCardRadius = BorderRadius.all(Radius.circular(16));

/// Squircle alias for explicit Apple design references.
const BorderRadius kAdminSquircleRadius = BorderRadius.all(Radius.circular(16));

/// Sharp structural radius for dense inner data sub-cells.
const BorderRadius kAdminTableRadius = BorderRadius.all(Radius.circular(8));

/// Soft radius for chrome elements (sidebar nav targets, dialogs, buttons).
const BorderRadius kAdminChromeRadius = BorderRadius.all(Radius.circular(10));

/// Pill/tag radius for filter chips, tags, and status badges.
const BorderRadius kAdminPillRadius = BorderRadius.all(Radius.circular(20));

// --- Shadows -----------------------------------------------------------------

/// Subtle Apple card shadow.
const List<BoxShadow> kAdminCardShadow = [
  BoxShadow(
    color: Color(0x08000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
];

// --- Typography Helpers ------------------------------------------------------

TextStyle adminHeaderStyle({
  double fontSize = 18,
  FontWeight fontWeight = FontWeight.w600,
  Color color = kAdminNavyTrust,
}) =>
    GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle adminLabelStyle({
  double fontSize = 13.5,
  FontWeight fontWeight = FontWeight.w500,
  Color color = kAdminTextSecondary,
}) =>
    GoogleFonts.openSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle adminBodyStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = kAdminTextPrimary,
}) =>
    GoogleFonts.openSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

/// Monospace font reserved exclusively for counts, quantitative metrics, timestamps, and IDs.
TextStyle adminDataMono({
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.w500,
  Color color = kAdminTextPrimary,
}) =>
    GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
