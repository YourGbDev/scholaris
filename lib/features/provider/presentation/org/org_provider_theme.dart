// lib/features/provider/presentation/org/org_provider_theme.dart
//
// Institutional design tokens for Scholaris Provider Console
// Apple Design DNA pass: clean squircles, #F5F5F7 sidebar, #0F4D2E active fill,
// pure white active typography, subtle hairline borders, and responsive elevation.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Brand & Institutional Colors
const kOrgPrimary = Color(0xFF0F4D2E); // Bridge Green
const kOrgPrimaryDark = Color(0xFF00351C);
const kOrgSidebarDark = Color(0xFF0A321E); // Legacy reference
const kOrgSidebarLight = Color(0xFFF5F5F7); // Apple Light Sidebar
const kOrgActiveNavBg = Color(0xFF0F4D2E); // Active navigation fill
const kOrgActiveNavText = Color(0xFFFFFFFF); // Pure white active text/icon
const kOrgInactiveNavText = Color(0xFF404942); // Inactive dark gray nav text
const kOrgAccentGold = Color(0xFFF1B41E); // Golden Opportunity
const kOrgAccentGoldContainer = Color(0xFFFEBF2C);
const kOrgCivicNavy = Color(0xFF1B3A5C); // Data series & tertiary
const kOrgCanvas = Color(0xFFFAF9FE); // Light Apple canvas
const kOrgSurfaceWhite = Color(0xFFFFFFFF);
const kOrgBorder = Color(0xFFE5E7EB);
const kOrgHairline = Color(0xFFE4E7EC);
const kOrgBorderDark = Color(0xFFD1D5DB);
const kOrgTextPrimary = Color(0xFF1A1C1B);
const kOrgTextSecondary = Color(0xFF5A645C);
const kOrgTextMuted = Color(0xFF707971);
const kOrgError = Color(0xFFBA1A1A);
const kOrgSuccess = Color(0xFF27C93F);

// Status Badge Colors (DESIGN.md micro-padded badges)
const kOrgBadgeApprovedBg = Color(0xFFE7F3EC);
const kOrgBadgeApprovedText = Color(0xFF0F4D2E);
const kOrgBadgeApprovedBorder = Color(0xFFC4E2D1);

const kOrgBadgePendingBg = Color(0xFFFEF7E6);
const kOrgBadgePendingText = Color(0xFF8F6400);
const kOrgBadgePendingBorder = Color(0xFFFCDFA0);

const kOrgBadgeReviewBg = Color(0xFFE8EEF5);
const kOrgBadgeReviewText = Color(0xFF1B3A5C);
const kOrgBadgeReviewBorder = Color(0xFFC5D5E8);

const kOrgBadgeRejectedBg = Color(0xFFFFEBE8);
const kOrgBadgeRejectedText = Color(0xFFC53320);
const kOrgBadgeRejectedBorder = Color(0xFFFFC2BA);

// Border Radius Tokens (Apple Squircle Pass)
const BorderRadius kOrgSquircleRadius = BorderRadius.all(Radius.circular(16));
const BorderRadius kOrgCardRadius = BorderRadius.all(Radius.circular(16));
const BorderRadius kOrgChromeRadius = BorderRadius.all(Radius.circular(10));
const BorderRadius kOrgPillRadius = BorderRadius.all(Radius.circular(20));

// Shadows
const List<BoxShadow> kOrgCardShadow = [
  BoxShadow(
    color: Color(0x08000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
];

// Typography Helpers
TextStyle orgHeadline({
  double fontSize = 18,
  FontWeight fontWeight = FontWeight.w700,
  Color color = kOrgTextPrimary,
  double? letterSpacing,
}) =>
    GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.2,
    );

TextStyle orgBody({
  double fontSize = 13.5,
  FontWeight fontWeight = FontWeight.w400,
  Color color = kOrgTextPrimary,
  double height = 1.4,
}) =>
    GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );

TextStyle orgLabel({
  double fontSize = 11.5,
  FontWeight fontWeight = FontWeight.w600,
  Color color = kOrgTextSecondary,
  double? letterSpacing,
}) =>
    GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0.02,
    );
