// lib/features/admin/presentation/admin_theme.dart
//
// Operational design system tokens for the Admin Portal.
// Control room, not brochure — dense tables, hairline rules, disciplined status signaling.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Color Palette -----------------------------------------------------------

/// Cool green-tinted near-white surface distinct from the consumer student surface (#FAFAF8).
const Color kAdminSurface = Color(0xFFF5F7F6);

/// Primary operational green — nav items, active tab highlights, and primary actions.
const Color kAdminBridgeGreen = Color(0xFF0F4D2E);

/// Navy Trust — structural chrome, sidebar borders, table rules, and dark header text.
const Color kAdminNavyTrust = Color(0xFF1B3A5C);

/// Golden Opportunity — strictly reserved for pending / needs-attention states.
const Color kAdminGoldenOpportunity = Color(0xFFF1B41E);

/// Coral Connect — strictly reserved for rejected / critical / inactive states.
const Color kAdminCoralConnect = Color(0xFFFF6F59);

/// Subtle hairline divider / table border color derived from Navy Trust.
const Color kAdminHairline = Color(0xFFE2E7E5);

/// Dark text for primary content.
const Color kAdminTextPrimary = Color(0xFF1B2A23);

/// Muted secondary text for labels and captions.
const Color kAdminTextSecondary = Color(0xFF5E6D66);

/// Sidebar background.
const Color kAdminSidebarBackground = Color(0xFFFFFFFF);

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
  double fontSize = 13,
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
