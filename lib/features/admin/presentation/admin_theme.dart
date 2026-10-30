// lib/features/admin/presentation/admin_theme.dart
//
// Operational design system tokens for the Admin Portal.
// Apple Design DNA pass: clean squircles, #F5F5F7 sidebar, #0F4D2E active fill,
// pure white active typography, subtle hairline borders, and responsive elevation.

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

// --- Color Palette -----------------------------------------------------------

/// Neutral canvas behind the white administration panels.
const Color kAdminSurface = Color(0xFFFAFAFA);

/// Primary operational green — nav active fill (#0F4D2E), primary CTAs, active highlights.
const Color kAdminBridgeGreen = Color(0xFF0F4D2E);

/// Navy Trust — structural dark header text and brand accents.
const Color kAdminNavyTrust = Color(0xFF1B3A5C);

/// Golden Opportunity — strictly reserved for pending / needs-attention states.
const Color kAdminGoldenOpportunity = Color(0xFFF1B41E);

/// Coral Connect — strictly reserved for rejected / critical / inactive states.
const Color kAdminCoralConnect = Color(0xFFFF6F59);

/// Subtle hairline divider / table border color.
const Color kAdminHairline = Color(0xFFE8E8E8);

/// Dark text for primary content (#1A1B1F).
const Color kAdminTextPrimary = Color(0xFF1A1B1F);

/// Muted secondary text for labels and captions (#5E6D66 / #707971).
const Color kAdminTextSecondary = Color(0xFF5E6D66);

/// White sidebar surface, matching the provider workspace.
const Color kAdminSidebarBackground = Color(0xFFFFFFFF);

/// Active navigation item background (#0F4D2E).
const Color kAdminActiveNavBackground = Color(0xFF0F4D2E);

/// Active navigation item text/icon color (#FFFFFF).
const Color kAdminActiveNavText = Color(0xFFFFFFFF);

/// Inactive navigation item text color (#404942).
const Color kAdminInactiveNavText = Color(0xFF404942);

// --- Border Radius Tokens ----------------------------------------------------

/// Apple squircle card radius for stat tiles, content panels, and tables.
const BorderRadius kAdminCardRadius = BorderRadius.all(Radius.circular(26));

/// Squircle alias for explicit Apple design references.
const BorderRadius kAdminSquircleRadius = kAdminCardRadius;

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
    color: Color(0x06000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  ),
];

/// Matches the provider workspace's light, single-surface cards.
const BoxDecoration kAdminCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: kAdminCardRadius,
  border: Border.fromBorderSide(BorderSide(color: kAdminHairline)),
  boxShadow: kAdminCardShadow,
);

// --- Typography Helpers ------------------------------------------------------

TextStyle adminHeaderStyle({
  double fontSize = 18,
  FontWeight fontWeight = FontWeight.w600,
  Color color = kAdminNavyTrust,
}) =>
    geist(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle adminLabelStyle({
  double fontSize = 13.5,
  FontWeight fontWeight = FontWeight.w500,
  Color color = kAdminTextSecondary,
}) =>
    geist(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle adminBodyStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = kAdminTextPrimary,
}) =>
    geist(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

/// Compatibility helper; counts, metrics, timestamps, and IDs use Geist Sans.
TextStyle adminDataMono({
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.w500,
  Color color = kAdminTextPrimary,
}) =>
    geist(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

/// Tabular figures helper for numeric typography (prevents digit horizontal jittering).
TextStyle seqTabularFigures(TextStyle base) => base.copyWith(
      fontFeatures: [
        ...?base.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );

/// Geist Sans pill container helper for IDs, hashes, and IP addresses.
Widget adminIdPill(String idText) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text(
        idText,
        style: adminDataMono(fontSize: 11, color: kSeqOnSurfaceVariant),
      ),
    );

// =============================================================================
// Sequoia Apple Design System Tokens (from scholaris_sequoia/DESIGN.md)
// =============================================================================

const Color kSeqSurface = kAdminSurface;
const Color kSeqSurfaceDim = Color(0xFFDADADA);
const Color kSeqSurfaceBright = kAdminSurface;
const Color kSeqSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color kSeqSurfaceContainerLow = Color(0xFFF5F5F5);
const Color kSeqSurfaceContainer = Color(0xFFF0F0F0);
const Color kSeqSurfaceContainerHigh = Color(0xFFEAEAEA);
const Color kSeqSurfaceContainerHighest = Color(0xFFE3E3E3);
const Color kSeqOnSurface = Color(0xFF1A1B1F);
const Color kSeqOnSurfaceVariant = Color(0xFF404942);
const Color kSeqOutline = Color(0xFF5A625B);
const Color kSeqOutlineVariant = Color(0xFFC0C9C0);
const Color kSeqPrimary = Color(0xFF00351C);
const Color kSeqPrimaryContainer = Color(0xFF0F4D2E);
const Color kSeqOnPrimary = Color(0xFFFFFFFF);
const Color kSeqOnPrimaryContainer = Color(0xFF82BD95);
const Color kSeqPrimaryFixed = Color(0xFFB3F1C6);
const Color kSeqPrimaryFixedDim = Color(0xFF98D4AB);
const Color kSeqOnPrimaryFixed = Color(0xFF002110);
const Color kSeqOnPrimaryFixedVariant = Color(0xFF145131);
const Color kSeqSecondary = Color(0xFF0058BC);
const Color kSeqSecondaryContainer = Color(0xFF0070EB);
const Color kSeqOnSecondary = Color(0xFFFFFFFF);
const Color kSeqSecondaryFixed = Color(0xFFD8E2FF);
const Color kSeqSecondaryFixedDim = Color(0xFFADC6FF);
const Color kSeqOnSecondaryFixed = Color(0xFF001A41);
const Color kSeqOnSecondaryFixedVariant = Color(0xFF004493);
const Color kSeqTertiary = Color(0xFF442600);
const Color kSeqTertiaryFixed = Color(0xFFFFDDBB);
const Color kSeqTertiaryFixedDim = Color(0xFFFFB868);
const Color kSeqOnTertiaryFixed = Color(0xFF2B1700);
const Color kSeqOnTertiaryFixedVariant = Color(0xFF673D00);
const Color kSeqTertiaryContainer = Color(0xFF623A00);
const Color kSeqOnTertiaryContainer = Color(0xFFF99A00);
const Color kSeqError = Color(0xFFBA1A1A);
const Color kSeqOnError = Color(0xFFFFFFFF);
const Color kSeqErrorContainer = Color(0xFFFFDAD6);
const Color kSeqOnErrorContainer = Color(0xFF93000A);

// Sequoia Typography (Inter)
TextStyle seqDisplay({
  FontWeight fontWeight = FontWeight.w700,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 40,
      height: 48 / 40,
      letterSpacing: -0.022 * 40,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqHeadlineLg({
  FontWeight fontWeight = FontWeight.w600,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 32,
      height: 38 / 32,
      letterSpacing: -0.021 * 32,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqHeadlineMd({
  FontWeight fontWeight = FontWeight.w600,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 24,
      height: 30 / 24,
      letterSpacing: -0.019 * 24,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqHeadlineSm({
  FontWeight fontWeight = FontWeight.w600,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 19,
      height: 24 / 19,
      letterSpacing: -0.015 * 19,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqBodyLg({
  FontWeight fontWeight = FontWeight.w400,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: -0.011 * 16,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqBodyMd({
  FontWeight fontWeight = FontWeight.w400,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: -0.006 * 14,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqBodySm({
  FontWeight fontWeight = FontWeight.w400,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqLabelLg({
  FontWeight fontWeight = FontWeight.w500,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 14,
      height: 18 / 14,
      letterSpacing: -0.008 * 14,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqLabelMd({
  FontWeight fontWeight = FontWeight.w500,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: -0.002 * 12,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle seqLabelSm({
  FontWeight fontWeight = FontWeight.w600,
  Color color = kSeqOnSurface,
}) =>
    geist(
      fontSize: 10,
      height: 12 / 10,
      letterSpacing: 0.03 * 10,
      fontWeight: fontWeight,
      color: color,
    );

