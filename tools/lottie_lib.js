// tools/lottie_lib.js
//
// Minimal helpers to emit Bodymovin 5.7 (Lottie) JSON shape layers.
// Everything is 2D (ddd: 0), filled vector shapes, no rasters/text/masks.

'use strict';

const EASE_IN_OUT = () => ({
  i: { x: [0.42], y: [0] },
  o: { x: [0.58], y: [1] },
});
const LINEAR = () => ({ i: { x: [0], y: [0] }, o: { x: [1], y: [1] } });

// Build an animated property object from a list of {t, v} keyframes.
// `dim` is 1 (scalar) or 2 (vector2). Adjacent duplicate values become holds.
function anim(frames, dim, ease = 'inout') {
  const norm = (v) => (dim === 1 ? [v] : v);
  const arr = (x) => Array(dim).fill(x);
  const easing = ease === 'linear' ? LINEAR() : EASE_IN_OUT();
  const ks = [];
  for (let i = 0; i < frames.length; i++) {
    const f = frames[i];
    const next = frames[i + 1];
    const isHold = next && next.v === f.v;
    const k = { t: f.t, s: norm(f.v) };
    if (next) {
      if (isHold) {
        k.h = 1;
      } else {
        k.o = { x: arr(easing.o.x[0]), y: arr(easing.o.y[0]) };
      }
    }
    if (i > 0) {
      k.i = { x: arr(easing.i.x[0]), y: arr(easing.i.y[0]) };
    }
    ks.push(k);
  }
  return { a: 1, k: ks };
}

function st(v) {
  return { a: 0, k: v };
}

function rectShape(name, w, h, x, y, r) {
  return {
    ty: 'rc',
    d: 1,
    s: st([w, h]),
    p: st([x, y]),
    r: st(r),
    nm: name,
    mn: 'ADBE Vector Shape - Rect',
    hd: false,
  };
}

function ellipseShape(name, sx, sy, x, y) {
  return {
    ty: 'el',
    d: 1,
    s: st([sx, sy]),
    p: st([x, y]),
    nm: name,
    mn: 'ADBE Vector Shape - Ellipse',
    hd: false,
  };
}

function fill(name, rgb, opacity = 100) {
  return {
    ty: 'fl',
    c: st([...rgb, 1]),
    o: st(opacity),
    r: 1,
    bm: 0,
    nm: name,
    mn: 'ADBE Vector Graphic - Fill',
    hd: false,
  };
}

function gradFill(name, stops, x1, y1, x2, y2) {
  // stops: array of [pos, [r,g,b], a]
  const k = [];
  for (const [pos, rgb, a] of stops) k.push(pos, rgb[0], rgb[1], rgb[2], a);
  return {
    ty: 'gf',
    o: st(100),
    r: 1,
    bm: 0,
    g: { p: stops.length, k: st(k) },
    s: st([x1, y1]),
    e: st([x2, y2]),
    t: 1,
    nm: name,
    mn: 'ADBE Vector Graphic - Grad Fill',
    hd: false,
  };
}

// A group with an optional transform. `ks` may contain animated p/s/r/o.
// opts.p / opts.s / opts.r can be static values or {anim: frames, dim}.
function group(name, items, opts = {}) {
  const {
    p = [0, 0],
    s = [100, 100],
    r = 0,
    o = 100,
    pAnim = null,
    sAnim = null,
    rAnim = null,
  } = opts;
  const ks = {};
  ks.o = st(o);
  ks.r = rAnim ? anim(rAnim, 1) : st(r);
  ks.p = pAnim ? anim(pAnim, 2) : st(p);
  ks.a = st([0, 0]);
  ks.s = sAnim ? anim(sAnim, 2) : st(s);
  ks.sk = st(0);
  ks.sa = st(0);
  return {
    ty: 'gr',
    it: [...items, { ty: 'tr', ...ks, nm: 'Transform' }],
    nm: name,
    np: items.length + 1,
    cix: 2,
    bm: 0,
    ix: 1,
    mn: 'ADBE Vector Group',
    hd: false,
  };
}

// Shape layer (ty 4). transforms: optional { pAnim, sAnim, rAnim, ... } for the
// layer-level transform (3-value arrays in Lottie).
function shapeLayer(name, ind, shapes, transform = {}, ip = 0, op = 510) {
  const { pAnim, sAnim, rAnim, oAnim, a = [0, 0] } = transform;
  const ks = {};
  ks.o = oAnim ? anim(oAnim, 1) : st(100);
  ks.r = rAnim ? anim(rAnim, 1) : st(0);
  ks.p = pAnim ? anim(pAnim, 2) : st(a);
  ks.a = st(a);
  ks.s = sAnim ? anim(sAnim, 2) : st([100, 100]);
  return {
    ddd: 0,
    ind,
    ty: 4,
    nm: name,
    sr: 1,
    ks,
    ao: 0,
    shapes,
    ip,
    op,
    st: 0,
    bm: 0,
  };
}

function hex(h) {
  return [
    parseInt(h.slice(0, 2), 16) / 255,
    parseInt(h.slice(2, 4), 16) / 255,
    parseInt(h.slice(4, 6), 16) / 255,
  ];
}

module.exports = { anim, st, rectShape, ellipseShape, fill, gradFill, group, shapeLayer, hex };
