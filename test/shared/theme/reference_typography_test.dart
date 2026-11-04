import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_theme.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

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
}
