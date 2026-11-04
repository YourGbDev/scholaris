import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/dev/provider_preview/main.dart' as preview;
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final individual in [true, false]) {
    testWidgets(
      'provider filters use neutral selected surfaces: individual=$individual',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          preview.buildApp(individualPreview: individual),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Applications').first);
        await tester.pumpAndSettle();
        final chip = find
            .byWidgetPredicate((w) => w is ChoiceChip || w is FilterChip)
            .first;
        final theme = Theme.of(tester.element(chip)).chipTheme;
        final selected =
            theme.color?.resolve({WidgetState.selected}) ?? theme.selectedColor;
        expect(selected, const Color(0xFF25282A));
        expect(theme.backgroundColor, Colors.white);
        if (individual) {
          final gradePanels = tester
              .widgetList<Container>(
                find.ancestor(
                  of: find.text('GWA 1.30'),
                  matching: find.byType(Container),
                ),
              )
              .where((w) => w.decoration is BoxDecoration);
          expect(
            (gradePanels.first.decoration! as BoxDecoration).color,
            const Color(0xFFF6F6F6),
          );
        }

        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('support guidance is a neutral content panel', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(preview.buildApp(individualPreview: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budget & support').first);
    await tester.pumpAndSettle();
    final panels = tester
        .widgetList<Container>(
          find.ancestor(
            of: find.text('Safer ways to support students'),
            matching: find.byType(Container),
          ),
        )
        .where((w) => w.decoration is BoxDecoration);
    expect((panels.first.decoration! as BoxDecoration).color, Colors.white);
    expect(tester.takeException(), isNull);
  });
  test(
    'admin canvas is white while meaningful status colors remain distinct',
    () {
      expect(kAdminSurface, Colors.white);
      expect(kOrgBadgeRejectedText, isNot(kOrgBadgeApprovedText));
      expect(kOrgBadgePendingText, isNot(kOrgBadgeApprovedText));
      expect(kSeqError, isNot(kAdminBridgeGreen));
    },
  );
}
