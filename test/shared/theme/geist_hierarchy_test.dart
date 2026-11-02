import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_theme.dart';

void main() {
  test('base theme shares the approved title hierarchy across roles', () {
    final theme = scholarisTheme();
    expect(theme.textTheme.titleLarge!.fontWeight, FontWeight.w700);
    expect(theme.textTheme.titleMedium!.fontWeight, FontWeight.w700);
    expect(theme.textTheme.titleMedium!.height, 1.3);
    expect(theme.textTheme.displaySmall!.fontSize, 24);
    expect(theme.appBarTheme.titleTextStyle!.fontWeight, FontWeight.w700);
  });
  test('all platforms use bundled Geist without a native font switch', () {
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(kAppFontFamily, 'Geist');
      expect(scholarisTheme().textTheme.bodyMedium!.fontFamily, 'Geist');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('student roles distinguish headings, titles and supporting text', () {
    expect(appGreeting().fontSize, 20);
    expect(appGreeting().fontWeight, FontWeight.w700);
    expect(appGreeting().letterSpacing, -.4);
    expect(appGreeting().height, 1.2);
    expect(appGreeting().color, kPrimary);
    expect(appHeading(fontSize: 20).fontWeight, FontWeight.w700);
    expect(appHeading(fontSize: 20).height, 1.25);
    expect(appCardTitle().fontSize, 15);
    expect(appCardTitle().fontWeight, FontWeight.w700);
    expect(appCardTitle().height, 1.3);
    expect(kRadiusCard, 26);
    // Explicit weights remain explicit; helper names do not promote them.
    expect(
      outfit(fontSize: 18, fontWeight: FontWeight.w600).fontWeight,
      FontWeight.w600,
    );
    expect(
      outfit(fontSize: 12, fontWeight: FontWeight.w500).fontWeight,
      FontWeight.w500,
    );
    expect(orgHeadline().fontWeight, FontWeight.w700);
    expect(seqHeadlineSm().fontWeight, FontWeight.w700);
  });

  test(
    'supporting metadata recedes while explicit prose weights remain intact',
    () {
      final body = appSupporting();
      expect(body.fontSize, 13);
      expect(body.fontWeight, FontWeight.w500);
      expect(
        scholarisTheme().textTheme.bodyMedium!.fontWeight,
        FontWeight.w400,
      );
      expect(body.letterSpacing, 0);
      expect(body.height, 1.4);
      expect(body.color, kTextSupporting);
      expect(
        openSans(fontSize: 14, fontWeight: FontWeight.w600).fontWeight,
        FontWeight.w600,
      );
      expect(geist(fontWeight: FontWeight.w900).fontWeight, FontWeight.w800);
      expect(appAmount().fontSize, 18);
      expect(appAmount().fontWeight, FontWeight.w700);
      expect(openSans().fontWeight, FontWeight.w400);
      expect(openSans(fontWeight: FontWeight.w400).fontWeight, FontWeight.w400);
      expect(openSans(fontWeight: FontWeight.w700).fontWeight, FontWeight.w700);
      expect(orgBody().fontWeight, FontWeight.w400);
      expect(orgBody().letterSpacing, 0);
      expect(seqBodyLg().fontWeight, FontWeight.w400);
      expect(seqBodyMd().fontWeight, FontWeight.w400);
      expect(appAttributeLabel().fontWeight, FontWeight.w500);
      expect(seqBodySm().fontSize, 13);
      expect(seqBodySm().fontWeight, FontWeight.w400);
      expect(seqBodySm().letterSpacing, 0);
      expect(seqBodySm().height, 1.4);
      expect(seqBodySm().color, kTextSupporting);
    },
  );
}
