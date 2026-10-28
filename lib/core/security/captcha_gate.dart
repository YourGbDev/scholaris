class CaptchaResult {
  const CaptchaResult({required this.allowed, this.token});
  final bool allowed;
  final String? token;
}

class CaptchaGate {
  const CaptchaGate({required this.enabled, required this.siteKey, required this.challenge});
  final bool enabled;
  final String siteKey;
  final Future<String?> Function(String siteKey) challenge;

  Future<CaptchaResult> acquire() async {
    if (!enabled) return const CaptchaResult(allowed: true);
    final key = siteKey.trim();
    if (key.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(key)) {
      throw StateError('CAPTCHA is enabled but its site key is not configured.');
    }
    final token = (await challenge(key))?.trim();
    if (token == null || token.isEmpty) return const CaptchaResult(allowed: false);
    return CaptchaResult(allowed: true, token: token);
  }
}
