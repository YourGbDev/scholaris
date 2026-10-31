import 'dart:io';
import 'dart:async';

import '../../../shared/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'captcha_mobile_protocol.dart';

const _challengePage = String.fromEnvironment('SCHOLARIS_CAPTCHA_PAGE_URL');

Widget createCaptchaView({
  required String siteKey,
  required String nonce,
  required void Function(String) onToken,
}) {
  if (!Platform.isIOS && !Platform.isAndroid) {
    return const Center(
      child: Text('Security checks are unavailable on this device.'),
    );
  }
  return _NativeCaptcha(siteKey: siteKey, nonce: nonce, onToken: onToken);
}

class _NativeCaptcha extends StatefulWidget {
  const _NativeCaptcha({
    required this.siteKey,
    required this.nonce,
    required this.onToken,
  });
  final String siteKey;
  final String nonce;
  final void Function(String) onToken;

  @override
  State<_NativeCaptcha> createState() => _NativeCaptchaState();
}

class _NativeCaptchaState extends State<_NativeCaptcha> {
  WebViewController? _controller;
  bool _failed = false;
  bool _ready = false;
  Timer? _legacyReveal;
  bool _delivered = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final uri = captchaMobileUri(
        _challengePage,
        widget.siteKey,
        widget.nonce,
      );
      final controller = WebViewController();
      await controller.setBackgroundColor(Colors.white);
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.addJavaScriptChannel(
        'ScholarisCaptcha',
        onMessageReceived: (message) {
          if (!mounted || _failed || _delivered) return;
          if (captchaMobileReady(message.message, widget.nonce)) {
            _legacyReveal?.cancel();
            setState(() => _ready = true);
            return;
          }
          if (captchaMobileFailed(message.message, widget.nonce) && mounted) {
            setState(() => _failed = true);
            return;
          }
          final token = captchaMobileToken(message.message, widget.nonce);
          if (token != null && !_delivered && mounted) {
            _delivered = true;
            widget.onToken(token);
          }
        },
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            try {
              final version = await controller.runJavaScriptReturningResult(
                "document.querySelector('meta[name=scholaris-captcha-version]')?.content || ''",
              );
              if (!mounted ||
                  _delivered ||
                  _failed ||
                  version.toString().replaceAll('"', '') == '2') {
                return;
              }
              // shortcut: old hosted pages have no ready event; reveal after document load.
              // Remove this presentation-only fallback after hosted v2 is deployed everywhere.
              _legacyReveal = Timer(const Duration(milliseconds: 350), () {
                if (mounted && !_failed && !_delivered) {
                  setState(() => _ready = true);
                }
              });
            } catch (_) {
              if (mounted && !_delivered) setState(() => _failed = true);
            }
          },
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (!request.isMainFrame ||
                (target != null &&
                    target.scheme == uri.scheme &&
                    target.host == uri.host &&
                    target.port == uri.port &&
                    target.path == uri.path)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted && !_delivered) {
              setState(() => _failed = true);
            }
          },
        ),
      );
      await controller.loadRequest(uri);
      if (mounted) setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _legacyReveal?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text('Security check could not load. Cancel and try again.'),
      );
    }
    final controller = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller != null) WebViewWidget(controller: controller),
        if (!_ready)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!MediaQuery.disableAnimationsOf(context))
                      const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(height: 12),
                    Text(
                      'Loading security check…',
                      style: geist(fontSize: 14, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
