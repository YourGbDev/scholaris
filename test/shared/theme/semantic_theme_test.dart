import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/theme/app_typography.dart';

void main() {
  test(
    'typography keeps navigation state colors and dialog content colors',
    () {
      final theme = scholarisTheme();
      final labels = theme.navigationBarTheme.labelTextStyle!;
      expect(
        labels.resolve({WidgetState.selected})!.color,
        theme.colorScheme.onSurface,
      );
      expect(labels.resolve({})!.color, theme.colorScheme.onSurfaceVariant);
      expect(
        labels.resolve({WidgetState.disabled})!.color,
        theme.colorScheme.onSurfaceVariant.withValues(alpha: .38),
      );
      expect(
        theme.dialogTheme.contentTextStyle!.color,
        theme.textTheme.bodyMedium!.color,
      );
    },
  );
  test(
    'implicit controls receive semantic action, input and navigation styles',
    () {
      final theme = scholarisTheme();
      const states = <WidgetState>{};
      expect(
        theme.textButtonTheme.style!.textStyle!.resolve(states)!.fontWeight,
        AppTypography.weightFor(AppTextRole.button),
      );
      expect(
        theme.outlinedButtonTheme.style!.textStyle!.resolve(states)!.fontWeight,
        AppTypography.weightFor(AppTextRole.button),
      );
      expect(
        theme.filledButtonTheme.style!.textStyle!.resolve(states)!.fontWeight,
        AppTypography.weightFor(AppTextRole.button),
      );
      expect(
        theme.inputDecorationTheme.labelStyle!.fontWeight,
        AppTypography.weightFor(AppTextRole.label),
      );
      expect(
        theme.inputDecorationTheme.hintStyle!.fontWeight,
        AppTypography.weightFor(AppTextRole.placeholder),
      );
      expect(
        theme.navigationBarTheme.labelTextStyle!.resolve(states)!.fontWeight,
        AppTypography.weightFor(AppTextRole.navigation),
      );
      expect(
        theme.bottomNavigationBarTheme.selectedLabelStyle!.fontWeight,
        AppTypography.weightFor(AppTextRole.navigation),
      );
    },
  );
  test('all Material text slots have the approved semantic hierarchy', () {
    final text = scholarisTheme().textTheme;
    expect(text.displayMedium!.fontWeight, FontWeight.w700);
    expect(text.displaySmall!.fontWeight, FontWeight.w700);
    expect(text.titleLarge!.fontWeight, FontWeight.w700);
    expect(text.titleSmall!.fontWeight, FontWeight.w600);
    expect(text.labelSmall!.fontWeight, FontWeight.w500);
    expect(text.bodyMedium!.fontWeight, FontWeight.w400);
    expect(text.bodyMedium!.fontSize, 14);
    expect(text.bodyMedium!.height, 1.45);
  });
  test(
    'preview themes keep custom button dimensions and all actions semibold',
    () {
      final base = ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 52)),
        ),
      );
      final theme = applyScholarisTypography(base);
      final style = theme.elevatedButtonTheme.style!;
      expect(style.textStyle!.resolve({})!.fontWeight, FontWeight.w600);
      expect(style.minimumSize!.resolve({}), const Size(120, 52));
      expect(
        scholarisTheme().elevatedButtonTheme.style!.textStyle!
            .resolve({})!
            .fontSize,
        16,
      );
    },
  );
}
