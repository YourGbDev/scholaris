import 'package:flutter/services.dart';

/// Use the shipped metrics instead of Flutter's Ahem test font for layout checks.
Future<void> loadAppFonts() async {
  final loader = FontLoader('Geist');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/geist/Geist-$weight.ttf'));
  }
  await loader.load();
}
