import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart' show kBorderLight;

// Operational surfaces stay neutral; brand actions and real status colors are separate.
const kWorkspaceSubtle = Color(0xFFF6F6F6);
const kWorkspaceSelected = Color(0xFF25282A);
const kWorkspaceInk = Color(0xFF202428);
const kWorkspaceMuted = Color(0xFF62666B);
const kWorkspaceBorder = kBorderLight;

ThemeData workspaceTheme(ThemeData base) => base.copyWith(
  scaffoldBackgroundColor: Colors.white,
  colorScheme: base.colorScheme.copyWith(
    surface: Colors.white,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: kWorkspaceSubtle,
    surfaceContainer: const Color(0xFFF0F0F0),
    surfaceContainerHigh: const Color(0xFFEAEAEA),
    surfaceContainerHighest: const Color(0xFFE3E3E3),
    surfaceTint: Colors.transparent,
    primaryContainer: kWorkspaceSubtle,
    onPrimaryContainer: kWorkspaceInk,
    secondaryContainer: kWorkspaceSubtle,
    onSecondaryContainer: kWorkspaceInk,
    tertiaryContainer: kWorkspaceSubtle,
    onTertiaryContainer: kWorkspaceInk,
    outlineVariant: kWorkspaceBorder,
  ),
  inputDecorationTheme: base.inputDecorationTheme.copyWith(
    fillColor: kWorkspaceSubtle,
  ),
  chipTheme: base.chipTheme.copyWith(
    backgroundColor: Colors.white,
    selectedColor: kWorkspaceSelected,
    secondarySelectedColor: kWorkspaceSelected,
    disabledColor: kWorkspaceSubtle,
    color: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? kWorkspaceSubtle
          : states.contains(WidgetState.selected)
          ? kWorkspaceSelected
          : Colors.white,
    ),
    labelStyle:
        AppTypography.style(
          AppTextRole.badge,
          fontSize: 12,
          height: 1.4,
          letterSpacing: 0,
        ).copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? kWorkspaceMuted
                : states.contains(WidgetState.selected)
                ? Colors.white
                : kWorkspaceInk,
          ),
        ),
    secondaryLabelStyle: AppTypography.style(
      AppTextRole.badge,
      fontSize: 12,
      color: Colors.white,
      height: 1.4,
      letterSpacing: 0,
    ),
    checkmarkColor: Colors.white,
    side: WidgetStateBorderSide.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.selected)
            ? kWorkspaceSelected
            : kWorkspaceBorder,
      ),
    ),
    elevation: 0,
    pressElevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
  ),
);
