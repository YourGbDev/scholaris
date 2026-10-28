import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/core/security/captcha_gate.dart';

void main() {
  test('disabled CAPTCHA allows authentication without opening a challenge', () async {
    var calls = 0;
    final result = await CaptchaGate(enabled: false, siteKey: '', challenge: (_) async { calls++; return 'token'; }).acquire();
    expect(result.allowed, isTrue);
    expect(result.token, isNull);
    expect(calls, 0);
  });

  test('enabled CAPTCHA refuses a missing key before allowing authentication', () async {
    var calls = 0;
    await expectLater(CaptchaGate(enabled: true, siteKey: '', challenge: (_) async { calls++; return 'token'; }).acquire(), throwsStateError);
    expect(calls, 0);
  });

  test('canceled or empty challenges do not authorize an authentication request', () async {
    final canceled = await CaptchaGate(enabled: true, siteKey: 'site-key', challenge: (_) async => null).acquire();
    final empty = await CaptchaGate(enabled: true, siteKey: 'site-key', challenge: (_) async => ' ').acquire();
    expect(canceled.allowed, isFalse);
    expect(empty.allowed, isFalse);
  });

  test('each request obtains its own verified challenge token', () async {
    var calls = 0;
    final gate = CaptchaGate(enabled: true, siteKey: 'site-key', challenge: (_) async => 'token-${++calls}');
    final first = await gate.acquire();
    final second = await gate.acquire();
    expect(first.token, 'token-1');
    expect(second.token, 'token-2');
  });
}
