import 'package:flutter/services.dart';

/// Use the shipped metrics instead of Flutter's Ahem test font for layout checks.
Future<void> loadAppFonts() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
  }
  await loader.load();
}
