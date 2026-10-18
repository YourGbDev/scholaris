import { readFile } from 'node:fs/promises';
import { runInNewContext } from 'node:vm';
import { webcrypto } from 'node:crypto';
import assert from 'node:assert/strict';

const source = await readFile(new URL('../web/tab_scoped_auth.js', import.meta.url), 'utf8');
function tab() {
  const window = {BroadcastChannel: class { constructor(name) { this.name = name; } }};
  runInNewContext(source, {window, crypto: webcrypto, Uint32Array});
  return window;
}
const a=tab(), b=tab();
const channel='sb-yqwbarzxpduzmtrxnrbm-auth-token';
assert.notEqual(new a.BroadcastChannel(channel).name, new b.BroadcastChannel(channel).name);
assert.equal(new a.BroadcastChannel(channel).name, new a.BroadcastChannel(channel).name);
assert.equal(new a.BroadcastChannel('application-updates').name, 'application-updates');
runInNewContext(source, {window: {}}); // Browsers without BroadcastChannel remain supported.
console.log('PASS auth broadcast isolated across tabs, consistent within a tab; other channels unchanged; unsupported browser handled');
