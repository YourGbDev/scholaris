import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget createCaptchaView({required String siteKey, required String nonce, required void Function(String) onToken}) =>
    _NativeCaptcha(siteKey: siteKey, nonce: nonce, onToken: onToken);

class _NativeCaptcha extends StatefulWidget {
  const _NativeCaptcha({required this.siteKey, required this.nonce, required this.onToken});
  final String siteKey;
  final String nonce;
  final void Function(String) onToken;
  @override
  State<_NativeCaptcha> createState() => _NativeCaptchaState();
}

class _NativeCaptchaState extends State<_NativeCaptcha> {
  static const _pageUrl = String.fromEnvironment('SCHOLARIS_CAPTCHA_PAGE_URL');
  WebViewController? _controller;
  bool _failed = false;
  bool _delivered = false;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.macOS) {
      _init();
    } else {
      _failed = true;
    }
  }

  Future<void> _init() async {
    try {
      final base = Uri.tryParse(_pageUrl);
      if (base == null || base.scheme != 'https' || base.host.isEmpty || base.userInfo.isNotEmpty || base.hasQuery || base.hasFragment) {
        throw StateError('A hosted HTTPS CAPTCHA page is required.');
      }
      final page = base.replace(queryParameters: {'key': widget.siteKey, 'nonce': widget.nonce});
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.addJavaScriptChannel('ScholarisCaptcha', onMessageReceived: (message) {
        try {
          final data = jsonDecode(message.message);
          if (data is! Map || data['nonce'] != widget.nonce || _delivered) return;
          final token = data['token'];
          if (token is String && token.isNotEmpty) {
            _delivered = true;
            widget.onToken(token);
          } else if (data['error'] == true && mounted) {
            setState(() => _failed = true);
          }
        } catch (_) {}
      });
      await controller.setNavigationDelegate(NavigationDelegate(onNavigationRequest: (request) {
        final target = Uri.tryParse(request.url);
        if (!request.isMainFrame || (target != null && target.scheme == base.scheme && target.host == base.host && target.port == base.port && target.path == base.path)) return NavigationDecision.navigate;
        return NavigationDecision.prevent;
      }));
      await controller.loadRequest(page);
      if (mounted) setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => _failed
      ? const Center(child: Text('Security check could not load. Cancel and try again.'))
      : _controller == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _controller!);
}
