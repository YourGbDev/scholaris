import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_theme.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

void main() {
  test('all five bundled Geist fonts declare unified family name Geist for iOS CoreText', () async {
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final data = await rootBundle.load('assets/fonts/geist/Geist-$weight.ttf');
      final bytes = data.buffer.asByteData();
      final numTables = bytes.getUint16(4);
      int nameOffset = 0;
      for (int i = 0; i < numTables; i++) {
        final tag = String.fromCharCodes([
          bytes.getUint8(12 + i * 16),
          bytes.getUint8(12 + i * 16 + 1),
          bytes.getUint8(12 + i * 16 + 2),
          bytes.getUint8(12 + i * 16 + 3),
        ]);
        if (tag == 'name') {
          nameOffset = bytes.getUint32(12 + i * 16 + 8);
          break;
        }
      }
      expect(nameOffset, greaterThan(0));
      final count = bytes.getUint16(nameOffset + 2);
      final stringOffset = nameOffset + bytes.getUint16(nameOffset + 4);
      String? familyName;
      for (int i = 0; i < count; i++) {
        final rec = nameOffset + 6 + i * 12;
        final nameID = bytes.getUint16(rec + 6);
        if (nameID == 1) {
          final len = bytes.getUint16(rec + 8);
          final off = bytes.getUint16(rec + 10);
          final strBytes = Uint8List.view(data.buffer, stringOffset + off, len);
          final chars = <int>[];
          for (int j = 0; j < len; j += 2) {
            chars.add((strBytes[j] << 8) | strBytes[j + 1]);
          }
          familyName = String.fromCharCodes(chars);
          break;
        }
      }
      expect(familyName, 'Geist', reason: 'Font Geist-$weight.ttf must have nameID 1 equal to Geist for CoreText');
    }
  });

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
