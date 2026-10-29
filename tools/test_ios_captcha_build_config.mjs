import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';

const workflow = await readFile(new URL('../.github/workflows/build_ios.yml', import.meta.url), 'utf8');
const expression = workflow.match(/SCHOLARIS_CAPTCHA_ENABLED=\$\{\{\s*(.*?)\s*\}\}/)?.[1];
assert.ok(expression, 'The iOS build must set its CAPTCHA flag');
const defaultValue = workflow.match(/captcha_enabled:[\s\S]*?default:\s*(true|false)/)?.[1] === 'true';
for (const [eventName, input, expected] of [
  ['push', undefined, true],
  ['workflow_dispatch', defaultValue, true],
  ['workflow_dispatch', true, true],
  ['workflow_dispatch', 'true', true],
  ['workflow_dispatch', false, false],
  ['workflow_dispatch', 'false', false],
]) {
  const actual = vm.runInNewContext(expression, {
    github: {event_name: eventName},
    inputs: {captcha_enabled: input},
  });
  assert.equal(actual, expected, `Unexpected CAPTCHA setting for ${eventName}/${input}`);
}
console.log('PASS: push builds and default manual builds enable CAPTCHA; explicit manual settings are respected');
