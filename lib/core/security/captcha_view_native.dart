import 'package:flutter/material.dart';

Widget createCaptchaView({required String siteKey, required String nonce, required void Function(String) onToken}) =>
    const Center(child: Text('Security checks are unavailable on this device.'));
