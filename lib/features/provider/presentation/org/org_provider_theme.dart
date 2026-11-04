// lib/features/provider/presentation/org/org_provider_theme.dart
//
// Institutional design tokens for Scholaris Provider Console
// White workspace and sidebar, #0F4D2E active fill,
// pure white active typography, subtle hairline borders, and responsive elevation.

import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
export 'package:scholaris/shared/theme/workspace_theme.dart';

// Brand & Institutional Colors
const kOrgPrimary = Color(0xFF0F4D2E); // Bridge Green
const kOrgPrimaryDark = Color(0xFF00351C);
const kOrgSidebarDark = Color(0xFF0A321E); // Legacy reference
const kOrgSidebarLight = Color(0xFFFFFFFF);
const kOrgActiveNavBg = Color(0xFF0F4D2E); // Active navigation fill
const kOrgActiveNavText = Color(0xFFFFFFFF); // Pure white active text/icon
const kOrgInactiveNavText = Color(0xFF44484C); // Inactive dark gray nav text
const kOrgAccentGold = Color(0xFFF1B41E); // Golden Opportunity
const kOrgAccentGoldContainer = Color(0xFFFEBF2C);
const kOrgCivicNavy = Color(0xFF1B3A5C); // Data series & tertiary
const kOrgCanvas = Colors.white;
const kOrgSurfaceWhite = Color(0xFFFFFFFF);
const kOrgBorder = kBorderLight;
const kOrgHairline = kBorderLight;
const kOrgBorderDark = Color(0xFFD1D5DB);
const kOrgTextPrimary = Color(0xFF111827);
const kOrgTextSecondary = Color(0xFF62666B);
const kOrgTextMuted = Color(0xFF62666B);
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
const BorderRadius kOrgCardRadius = BorderRadius.all(
  Radius.circular(kRadiusCard),
);
const BorderRadius kOrgChromeRadius = BorderRadius.all(Radius.circular(10));
const BorderRadius kOrgPillRadius = BorderRadius.all(Radius.circular(20));

// Shadows
const List<BoxShadow> kOrgCardShadow = kCardElevationCrisp;

// Typography Helpers for the shared semantic hierarchy

/// Tabular figures helper for numeric typography (prevents digit horizontal jittering).
TextStyle orgTabularFigures(TextStyle base) => base.copyWith(
  fontFeatures: [...?base.fontFeatures, const FontFeature.tabularFigures()],
);

/// Shared rounded pill container helper for IDs, hashes, and reference codes.
Widget orgIdPill(String idText) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
  decoration: BoxDecoration(
    color: const Color(0xFFF6F6F6),
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: kOrgHairline),
  ),
  child: Text(
    idText,
    style: AppTypography.style(
      AppTextRole.caption,
      fontSize: 11,
      color: kOrgTextSecondary,
      height: 1.4,
      letterSpacing: 0,
    ),
  ),
);
