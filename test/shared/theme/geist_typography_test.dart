import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_theme.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('all four Open Runde weights are bundled and load without fetching', () async {
    final fonts = FontLoader('OpenRunde');
    for (final weight in ['Regular', 'Medium', 'Semibold', 'Bold']) {
      final data = await rootBundle.load('assets/fonts/open_runde/OpenRunde-$weight.otf');
      expect(data.lengthInBytes, greaterThan(300000), reason: weight);
      fonts.addFont(Future.value(data));
    }
    await fonts.load();
  });

  testWidgets('admin and provider reference pills use bundled Open Runde offline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: scholarisTheme(),
        home: Scaffold(
          body: Column(
            children: [adminIdPill('ADMIN-123'), orgIdPill('ORG-456')],
          ),
        ),
      ),
    );

    for (final reference in ['ADMIN-123', 'ORG-456']) {
      final label = tester.widget<Text>(find.text(reference));
      expect(label.style!.fontFamily, 'OpenRunde', reason: reference);
    }
    expect(tester.takeException(), isNull);
  });

  test('shared helpers and all theme text roles select the rounded family', () {
    for (final style in [geist(), outfit(), openSans(), poppins()]) {
      expect(style.fontFamily, 'OpenRunde');
    }
    final theme = scholarisTheme();
    for (final style in [
      theme.textTheme.displayLarge,
      theme.textTheme.headlineLarge,
      theme.textTheme.titleMedium,
      theme.textTheme.bodyLarge,
      theme.textTheme.bodyMedium,
      theme.textTheme.labelLarge,
      theme.appBarTheme.titleTextStyle,
    ]) {
      expect(style?.fontFamily, 'OpenRunde');
    }
  });

  test('rounded adapters preserve natural tracking and explicit overrides', () {
    for (final style in [
      openSans(fontSize: 12), poppins(fontSize: 28), inter(fontSize: 24),
      orgHeadline(fontSize: 24), orgBody(), orgLabel(),
    ]) {
      expect(style.letterSpacing, 0);
    }
    expect(orgHeadline(fontSize: 24).height, 1.3);
    expect(openSans(letterSpacing: 1.2).letterSpacing, 1.2);
    expect(orgHeadline(height: 1.5, letterSpacing: .5).height, 1.5);
  });
}
