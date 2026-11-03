// Run explicitly with: flutter test tools/prepare_mascot_palette.dart
// Asset preparation, not part of the automated test suite.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<(ui.Image, Uint8List)> read(String path) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return (
    frame.image,
    (await frame.image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!
        .buffer
        .asUint8List(),
  );
}

bool green(Uint8List p, int i) =>
    p[i + 3] > 240 &&
    p[i + 1] > p[i] * 1.2 &&
    p[i + 1] > p[i + 2] * 1.04 &&
    p[i + 1] - p[i] > 8;
double light(Uint8List p, int i) =>
    .2126 * p[i] + .7152 * p[i + 1] + .0722 * p[i + 2];

void main() {
  test(
    'prepare matching emerald palette without changing skin, trim or alpha',
    () async {
      final (reference, palette) = await read(
        'assets/mascots/greetings/ari.png',
      );
      final colors = <int>[];
      for (var i = 0; i < palette.length; i += 16) {
        if (green(palette, i)) colors.add(i);
      }
      colors.sort((a, b) => light(palette, a).compareTo(light(palette, b)));
      expect(colors, isNotEmpty);
      for (final path in [
        'assets/mascots/greetings/ariel.png',
        'assets/mascots/onboarding/discover.png',
        'assets/mascots/onboarding/match.png',
        'assets/mascots/onboarding/track.png',
        'assets/mascots/onboarding/companion.png',
      ]) {
        final (image, pixels) = await read(path);
        final indices = <int>[];
        for (var i = 0; i < pixels.length; i += 4) {
          if (green(pixels, i)) indices.add(i);
        }
        indices.sort((a, b) => light(pixels, a).compareTo(light(pixels, b)));
        for (var rank = 0; rank < indices.length; rank++) {
          final i = indices[rank];
          final j =
              colors[(rank / (indices.length - 1) * (colors.length - 1))
                  .round()];
          pixels[i] = palette[j];
          pixels[i + 1] = palette[j + 1];
          pixels[i + 2] = palette[j + 2];
        }
        final decoded = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          pixels,
          image.width,
          image.height,
          ui.PixelFormat.rgba8888,
          decoded.complete,
        );
        final result = await decoded.future;
        await File(path).writeAsBytes(
          (await result.toByteData(format: ui.ImageByteFormat.png))!.buffer
              .asUint8List(),
        );
        image.dispose();
        result.dispose();
        // ignore: avoid_print
        print('Aligned $path: ${indices.length} green pixels');
      }
      reference.dispose();
    },
  );
}
