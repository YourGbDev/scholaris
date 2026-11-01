import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_theme.dart';

void main() {
  test('all platforms use bundled Geist without a native font switch', () {
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(kAppFontFamily, 'Geist');
      expect(scholarisTheme().textTheme.bodyMedium!.fontFamily, 'Geist');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('greeting, section and card roles use the approved tight Geist scale', () {
    expect(appGreeting().fontWeight, FontWeight.w800);
    expect(appGreeting().letterSpacing, -1.0);
    expect(appGreeting().height, 1.12);
    expect(appGreeting().color, const Color(0xFF0F172A));
    expect(appHeading(fontSize: 24).fontWeight, FontWeight.w800);
    expect(appHeading(fontSize: 24).letterSpacing, -.8);
    expect(appCardTitle().fontSize, 17);
    expect(appCardTitle().fontWeight, FontWeight.w800);
    expect(appCardTitle().letterSpacing, -.35);
    expect(appCardTitle().height, 1.25);
    expect(outfit(fontSize: 18, fontWeight: FontWeight.w600).fontWeight, FontWeight.w800);
    expect(outfit(fontSize: 12, fontWeight: FontWeight.w500).fontWeight, FontWeight.w500);
    expect(orgHeadline().fontWeight, FontWeight.w800);
    expect(seqHeadlineSm().fontWeight, FontWeight.w800);
  });

  test('supporting copy uses the approved fuller semibold weight', () {
    final body = appSupporting();
    expect(body.fontSize, 14);
    expect(body.fontWeight, FontWeight.w600);
    expect(scholarisTheme().textTheme.bodyMedium!.fontWeight, FontWeight.w500);
    expect(body.letterSpacing, -.1);
    expect(body.height, 1.4);
    expect(body.color, const Color(0xFF64748B));
    expect(openSans(fontSize: 14, fontWeight: FontWeight.w600).fontWeight, FontWeight.w600);
    expect(geist(fontWeight: FontWeight.w900).fontWeight, FontWeight.w800);
    expect(appAmount().letterSpacing, -.5);
    expect(openSans().fontWeight, FontWeight.w600);
    expect(openSans(fontWeight: FontWeight.w400).fontWeight, FontWeight.w400);
    expect(openSans(fontWeight: FontWeight.w700).fontWeight, FontWeight.w700);
    expect(orgBody().fontWeight, FontWeight.w600);
    expect(orgBody().letterSpacing, -.1);
    expect(seqBodyLg().fontWeight, FontWeight.w600);
    expect(seqBodyMd().fontWeight, FontWeight.w600);
    expect(appAttributeLabel().fontWeight, FontWeight.w700);
    expect(seqBodySm().fontSize, 13);
    expect(seqBodySm().fontWeight, FontWeight.w600);
    expect(seqBodySm().letterSpacing, -.1);
    expect(seqBodySm().height, 1.4);
    expect(seqBodySm().color, const Color(0xFF64748B));
  });
}
