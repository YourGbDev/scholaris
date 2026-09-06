const j = require('../assets/animations/scholaris_ceremony.json');
const bytes = Buffer.byteLength(JSON.stringify(j));
console.log('file KB:', (bytes / 1024).toFixed(1));
console.log('fps:', j.fr, 'frames:', j.ip + '-' + j.op, 'duration:', (j.op / j.fr).toFixed(2) + 's');
console.log('w/h:', j.w, 'x', j.h);
console.log('layers:', j.layers.length);
console.log('assets (should be 0):', j.assets.length);
const s = JSON.stringify(j);
const banned = {
  raster: s.includes('"ty":2'),
  text: s.includes('"ty":5'),
  image: s.includes('"ty":3'),
  mask: /"ty":28/.test(s) || /"ty":29/.test(s),
};
console.log('banned feature scan:', JSON.stringify(banned));
console.log('v:', j.v);
// Count total keyframes
let kfCount = 0;
function countKF(obj) {
  if (obj && typeof obj === 'object') {
    if (obj.a === 1 && Array.isArray(obj.k)) kfCount += obj.k.length;
    for (const v of Object.values(obj)) countKF(v);
  }
}
countKF(j);
console.log('total keyframe entries:', kfCount);