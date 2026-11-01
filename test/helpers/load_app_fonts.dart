import 'package:flutter/services.dart';

/// Use the shipped metrics instead of Flutter's Ahem test font for layout checks.
Future<void> loadAppFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final weight in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/open_runde/OpenRunde-$weight.otf'));
  }
  await loader.load();
}
