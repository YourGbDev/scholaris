import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'captcha_mobile_protocol.dart';

const _challengePage = String.fromEnvironment('SCHOLARIS_CAPTCHA_PAGE_URL');

Widget createCaptchaView({required String siteKey, required String nonce, required void Function(String) onToken}) {
  if (!Platform.isIOS && !Platform.isAndroid) {
    return const Center(child: Text('Security checks are unavailable on this device.'));
  }
  return _NativeCaptcha(siteKey: siteKey, nonce: nonce, onToken: onToken);
}

class _NativeCaptcha extends StatefulWidget {
  const _NativeCaptcha({required this.siteKey, required this.nonce, required this.onToken});
  final String siteKey;
  final String nonce;
  final void Function(String) onToken;

  @override
  State<_NativeCaptcha> createState() => _NativeCaptchaState();
}

class _NativeCaptchaState extends State<_NativeCaptcha> {
  WebViewController? _controller;
  bool _failed = false;
  bool _delivered = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final uri = captchaMobileUri(_challengePage, widget.siteKey, widget.nonce);
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.addJavaScriptChannel('ScholarisCaptcha', onMessageReceived: (message) {
        if (captchaMobileFailed(message.message, widget.nonce) && mounted) {
          setState(() => _failed = true);
          return;
        }
        final token = captchaMobileToken(message.message, widget.nonce);
        if (token != null && !_delivered && mounted) {
          _delivered = true;
          widget.onToken(token);
        }
      });
      await controller.setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final target = Uri.tryParse(request.url);
          if (!request.isMainFrame || (target != null && target.scheme == uri.scheme && target.host == uri.host && target.port == uri.port && target.path == uri.path)) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) setState(() => _failed = true);
        },
      ));
      await controller.loadRequest(uri);
      if (mounted) setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const Center(child: Text('Security check could not load. Cancel and try again.'));
    final controller = _controller;
    if (controller == null) return const Center(child: CircularProgressIndicator());
    return WebViewWidget(controller: controller);
  }
}
