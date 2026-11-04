// Capture the offline student preview with matched viewport/content settings.
// node tools/capture_typography_web.mjs before|after
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {spawn} from 'node:child_process';

const phase = process.argv[2];
if (!['before', 'after'].includes(phase)) throw Error('Expected before or after');
const root = path.resolve(`build/typography-${phase}`);
const output = path.resolve(`docs/reports/2026-11-04-typography/${phase}`);
fs.mkdirSync(output, {recursive: true});
const types = {'.js': 'text/javascript', '.html': 'text/html', '.json': 'application/json', '.wasm': 'application/wasm', '.ttf': 'font/ttf', '.png': 'image/png'};
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  let file = path.resolve(root, `.${decodeURIComponent(url.pathname)}`);
  if (!file.startsWith(root + path.sep) && file !== root) {res.writeHead(403).end(); return;}
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(root, 'index.html');
  res.setHeader('Content-Type', types[path.extname(file)] ?? 'application/octet-stream');
  fs.createReadStream(file).pipe(res);
});
await new Promise(r => server.listen(5074, '127.0.0.1', r));
const chrome = spawn('C:/Program Files/Google/Chrome/Application/chrome.exe', [
  '--headless=new', '--remote-debugging-port=9254',
  `--user-data-dir=${path.resolve('scratch/typography/chrome-' + phase)}`,
  '--no-first-run', '--no-default-browser-check', 'about:blank',
], {stdio: 'ignore'});
const sleep = ms => new Promise(r => setTimeout(r, ms));
let ws;
try {
  let pages;
  for (let n = 0; n < 30; n++) {
    try {pages = await (await fetch('http://127.0.0.1:9254/json/list')).json(); if(pages.length) break;} catch {}
    await sleep(300);
  }
  ws = new WebSocket(pages.find(page => page.type === 'page' && page.url === 'about:blank').webSocketDebuggerUrl);
  await new Promise(r => ws.onopen = r);
  let sequence = 0;
  const pending = new Map();
  const errors = [];
  const fontResponses = new Map();
  ws.onmessage = event => {
    const message = JSON.parse(event.data);
    if (message.id) {
      const job = pending.get(message.id); pending.delete(message.id);
      if (message.error) job.reject(message.error); else job.resolve(message.result);
    } else if (message.method === 'Network.responseReceived' &&
      /\/fonts\/(?:inter|geist)\//.test(message.params.response.url)) {
      const response = message.params.response;
      fontResponses.set(response.url, {url: response.url, status: response.status});
    } else if (message.method === 'Runtime.exceptionThrown' ||
      (message.method === 'Runtime.consoleAPICalled' && message.params.type === 'error')) errors.push(message);
  };
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++sequence; pending.set(id, {resolve, reject});
    ws.send(JSON.stringify({id, method, params}));
  });
  await send('Runtime.enable');
  await send('Page.enable');
  await send('Network.enable');
  await send('Page.addScriptToEvaluateOnNewDocument', {source: "if(location.origin==='http://127.0.0.1:5074') localStorage.setItem('flutter.student_tour_v1_local-preview-student','true');"});
  const manifest = [];
  for (const [name, route, width, height, scale] of [
    ['home', '/', 390, 844, 1], ['discover', '/?tab=1', 390, 844, 1],
    ['tracker', '/?tab=2', 390, 844, 1], ['profile', '/?tab=3', 390, 844, 1],
    ['detail', '/#/scholarship/sch-dost', 390, 844, 1],
    ['home-narrow', '/', 320, 844, 1], ['home-large-text', '/', 320, 844, 2],
  ]) {
    await send('Emulation.setDeviceMetricsOverride', {width, height, deviceScaleFactor: 1, mobile: false});
    const base = new URL(route, 'http://127.0.0.1:5074');
    base.searchParams.set('width', width); base.searchParams.set('height', height);
    base.searchParams.set('scale', scale); base.searchParams.set('motion', 'off');
    await send('Page.navigate', {url: base.href});
    await sleep(5500);
    const {data} = await send('Page.captureScreenshot', {format: 'png'});
    const filename = `web-${name}-${width}.png`;
    fs.writeFileSync(path.join(output, filename), Buffer.from(data, 'base64'));
    manifest.push({filename, url: base.href, width, height, scale});
    console.log(filename);
  }
  fs.writeFileSync(path.join(output, 'web-capture.json'), JSON.stringify({phase, manifest, fontResponses: [...fontResponses.values()], errors}, null, 2));
  if(errors.length) {console.error(`${errors.length} browser errors; see manifest`); process.exitCode = 1;}
} finally {ws?.close(); chrome.kill(); server.close();}
