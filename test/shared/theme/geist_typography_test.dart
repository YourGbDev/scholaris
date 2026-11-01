import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_theme.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('all five Geist weights are bundled and load without fetching', () async {
    final fonts = FontLoader('Geist');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final data = await rootBundle.load('assets/fonts/geist/Geist-$weight.ttf');
      expect(data.lengthInBytes, greaterThan(10000), reason: weight);
      fonts.addFont(Future.value(data));
    }
    await fonts.load();
  });

  testWidgets('admin and provider reference pills use bundled Geist offline', (
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
      expect(label.style!.fontFamily, 'Geist', reason: reference);
    }
    expect(tester.takeException(), isNull);
  });

  test('shared helpers and all theme text roles select the Geist family', () {
    for (final style in [geist(), outfit(), openSans(), poppins()]) {
      expect(style.fontFamily, 'Geist');
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
      expect(style?.fontFamily, 'Geist');
    }
  });

  test('Geist adapters use role tracking and explicit overrides', () {
    for (final style in [
      openSans(fontSize: 12), poppins(fontSize: 28), inter(fontSize: 24),
      orgHeadline(fontSize: 24), orgBody(), orgLabel(),
    ]) {
      expect(style.letterSpacing, lessThan(0));
    }
    expect(orgHeadline(fontSize: 24).height, 1.2);
    expect(openSans(letterSpacing: 1.2).letterSpacing, 1.2);
    expect(orgHeadline(height: 1.5, letterSpacing: .5).height, 1.5);
  });
}
