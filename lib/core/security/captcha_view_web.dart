import 'dart:convert';

import 'captcha_mobile_protocol.dart';

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget createCaptchaView({
  required String siteKey,
  required String nonce,
  required void Function(String) onToken,
}) => _WebCaptcha(siteKey: siteKey, nonce: nonce, onToken: onToken);

bool _registered = false;

class _WebCaptcha extends StatefulWidget {
  const _WebCaptcha({
    required this.siteKey,
    required this.nonce,
    required this.onToken,
  });
  final String siteKey;
  final String nonce;
  final void Function(String) onToken;
  @override
  State<_WebCaptcha> createState() => _WebCaptchaState();
}

class _WebCaptchaState extends State<_WebCaptcha> {
  web.HTMLIFrameElement? _frame;
  late final JSFunction _listener;
  bool _failed = false;
  bool _ready = false;
  bool _delivered = false;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory('scholaris-captcha', (
        int id, {
        Object? params,
      }) {
        final values = params as Map;
        final uri = Uri.base
            .resolve('/captcha_challenge.html')
            .replace(
              queryParameters: {
                'key': values['key'] as String,
                'nonce': values['nonce'] as String,
              },
            );
        return web.HTMLIFrameElement()
          ..src = uri.toString()
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%';
      });
      _registered = true;
    }
    _listener = ((web.Event raw) {
      final event = raw as web.MessageEvent;
      if (event.origin != web.window.location.origin ||
          _frame == null ||
          event.source != _frame!.contentWindow ||
          _delivered ||
          _failed) {
        return;
      }
      try {
        final data = jsonDecode((event.data as JSString).toDart);
        if (data is! Map || data['nonce'] != widget.nonce) return;
        if (captchaMobileReady((event.data as JSString).toDart, widget.nonce)) {
          if (mounted) setState(() => _ready = true);
          return;
        }
        final token = data['token'];
        if (token is String && token.isNotEmpty) {
          _delivered = true;
          widget.onToken(token);
        } else if (data['error'] == true && mounted) {
          setState(() => _failed = true);
        }
      } catch (_) {}
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _failed
      ? const Center(
          child: Text('Security check could not load. Cancel and try again.'),
        )
      : Stack(
          fit: StackFit.expand,
          children: [
            HtmlElementView(
              viewType: 'scholaris-captcha',
              creationParams: {'key': widget.siteKey, 'nonce': widget.nonce},
              onPlatformViewCreated: (id) => _frame =
                  ui_web.platformViewRegistry.getViewById(id)
                      as web.HTMLIFrameElement,
            ),
            if (!_ready)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
}
