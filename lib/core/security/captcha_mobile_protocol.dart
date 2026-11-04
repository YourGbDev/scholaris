import 'dart:convert';

Uri captchaMobileUri(String page, String key, String nonce) {
  final uri = Uri.tryParse(page);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    throw ArgumentError('A valid HTTPS CAPTCHA page is required.');
  }
  return uri.replace(
    queryParameters: {...uri.queryParameters, 'key': key, 'nonce': nonce},
  );
}

String? captchaMobileToken(String message, String nonce) {
  try {
    final data = jsonDecode(message);
    if (data is! Map ||
        data['nonce'] != nonce ||
        data['error'] == true ||
        data['token'] is! String) {
      return null;
    }
    final token = (data['token'] as String).trim();
    return token.isEmpty ? null : token;
  } catch (_) {
    return null;
  }
}

bool captchaMobileFailed(String message, String nonce) {
  try {
    final data = jsonDecode(message);
    return data is Map && data['nonce'] == nonce && data['error'] == true;
  } catch (_) {
    return false;
  }
}

bool captchaMobileReady(String message, String nonce) {
  try {
    final data = jsonDecode(message);
    return data is Map &&
        data['nonce'] == nonce &&
        data['ready'] == true &&
        data['error'] != true;
  } catch (_) {
    return false;
  }
}
