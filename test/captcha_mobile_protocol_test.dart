import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/core/security/captcha_mobile_protocol.dart';

void main() {
  test('readiness is nonce bound and never authorizes authentication', () {
    expect(
      captchaMobileReady('{"nonce":"active","ready":true}', 'active'),
      isTrue,
    );
    expect(
      captchaMobileReady('{"nonce":"other","ready":true}', 'active'),
      isFalse,
    );
    expect(
      captchaMobileToken('{"nonce":"active","ready":true}', 'active'),
      isNull,
    );
    expect(
      captchaMobileReady(
        '{"nonce":"active","ready":true,"error":true}',
        'active',
      ),
      isFalse,
    );
  });
  test('requires a hosted HTTPS challenge page', () {
    expect(
      () => captchaMobileUri('http://localhost/challenge', 'key', 'nonce'),
      throwsArgumentError,
    );
    expect(
      captchaMobileUri(
        'https://example.test/captcha_challenge.html',
        'key',
        'nonce',
      ).queryParameters,
      {'key': 'key', 'nonce': 'nonce'},
    );
  });
  test('accepts only a non-empty token bound to the active nonce', () {
    expect(
      captchaMobileToken('{"nonce":"other","token":"abc"}', 'active'),
      isNull,
    );
    expect(
      captchaMobileToken('{"nonce":"active","token":" "}', 'active'),
      isNull,
    );
    expect(captchaMobileToken('invalid json', 'active'), isNull);
    expect(
      captchaMobileToken('{"nonce":"active","token":"abc"}', 'active'),
      'abc',
    );
    expect(
      captchaMobileToken(
        '{"nonce":"active","token":"abc","error":true}',
        'active',
      ),
      isNull,
    );
  });
  test('only a matching challenge can signal failure', () {
    expect(
      captchaMobileFailed('{"nonce":"other","error":true}', 'active'),
      isFalse,
    );
    expect(
      captchaMobileFailed('{"nonce":"active","error":true}', 'active'),
      isTrue,
    );
  });
}
