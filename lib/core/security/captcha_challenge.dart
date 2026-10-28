import 'dart:math';

import 'package:flutter/material.dart';

import 'captcha_gate.dart';
import 'captcha_view_stub.dart'
    if (dart.library.io) 'captcha_view_native.dart'
    if (dart.library.js_interop) 'captcha_view_web.dart';

const captchaEnabled = bool.fromEnvironment('SCHOLARIS_CAPTCHA_ENABLED');
const captchaSiteKey = String.fromEnvironment('SCHOLARIS_CAPTCHA_SITE_KEY');

Future<CaptchaResult> acquireCaptcha(BuildContext context) {
  return CaptchaGate(
    enabled: captchaEnabled,
    siteKey: captchaSiteKey,
    challenge: (siteKey) {
      final random = Random.secure();
      final nonce = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Security check'),
          content: SizedBox(
            width: 360,
            height: 180,
            child: createCaptchaView(
              siteKey: siteKey,
              nonce: nonce,
              onToken: (token) => Navigator.of(dialogContext).pop(token),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel'))],
        );
      },
      );
    },
  ).acquire();
}
