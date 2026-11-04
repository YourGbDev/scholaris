import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';

const html = await readFile(new URL('../web/captcha_challenge.html', import.meta.url), 'utf8');
const script = html.match(/<script>\s*([\s\S]*?)<\/script>/)?.[1];
assert.ok(script, 'Challenge page script must exist');
for (const [width, expected] of [[240, 'compact'], [299, 'compact'], [300, 'normal'], [360, 'normal']]) {
  let options; const messages = [];
  const container = { clientWidth: width };
  const context = {
    URLSearchParams, location: { search: '?key=test-key&nonce=0123456789abcdef0123456789abcdef', origin: 'https://example.test' },
    document: { getElementById: () => container },
    window: { turnstile: {}, parent: { postMessage(message) { messages.push(JSON.parse(message)); } } },
    turnstile: { render: (_, value) => { options = value; } },
    setTimeout: () => 1, clearTimeout() {}, JSON,
  };
  vm.runInNewContext(script, context);
  assert.equal(options.theme, 'light');
  assert.ok(messages.some(m=>m.ready===true && !m.token));
  options.callback('verified-token'); options.callback('duplicate-token'); options['error-callback']();
  assert.equal(messages.filter(m=>m.token).length,1);
  assert.equal(messages.filter(m=>m.error).length,0);
  assert.equal(options.size, expected, `Wrong widget size for ${width}px`);
  assert.equal(typeof options.callback, 'function');
  assert.equal(typeof options['error-callback'], 'function');
}
console.log('PASS: challenge selects compact or normal size for available width and retains callbacks');
