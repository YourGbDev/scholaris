// tools/generate_ceremony.js
//
// Generates assets/animations/scholaris_ceremony.json — the Scholaris opening
// ceremony Lottie (400x800 @60fps, 510 frames, plays once).
//
// Emotional brief: "That graduate could be YOU." A calm indoor graduation: a
// graduate receives a diploma, holds the moment, then throws the cap toward the
// camera, which occludes the frame for the transition into the app.
//
// Run: node tools/generate_ceremony.js

'use strict';

const { anim, st, rectShape, ellipseShape, fill, gradFill, group, shapeLayer, hex } = require('./lottie_lib');

// ---------------------------------------------------------------- palette ---
const C = {
  bgTop: hex('F8F3E9'),
  bgBot: hex('EEE3CE'),
  arch: hex('EADFC7'),
  curtain: hex('D9CCB0'),
  curtainFold: hex('CDBE9F'),
  stageTop: hex('E6D9BA'),
  stageFace: hex('D9C9A6'),
  stageEdge: hex('F4EDD9'),
  aud: hex('4A453C'),
  gradRobe: hex('2F2E29'),
  gradStole: hex('0F4D2E'),
  gold: hex('C9A227'),
  goldLight: hex('E3B23C'),
  facRobe: hex('7C7668'),
  skinGrad: hex('E4B791'),
  skinFac: hex('D9A87F'),
  hairGrad: hex('3A3128'),
  hairFac: hex('6E675C'),
  cap: hex('2B2A26'),
  capTop: hex('3B3A33'),
  shadow: hex('2B2822'),
  eye: hex('2B2622'),
};

const F = { OP: 510 };

// ------------------------------------------------------------------ layers ---
// Lottie `layers` arrays are TOP-FIRST (first element = topmost layer), so we
// build them in render order: cap on top, scene beneath, background at bottom.
const layers = [];

// ================= LAYER 1 : background (static) ==========================
{
  const shapes = [
    rectShape('bgRect', 400, 800, 200, 400, 0),
    gradFill('bgGrad', [[0, C.bgTop, 1], [1, C.bgBot, 1]], 200, 0, 200, 800),
  ];
  layers.push(shapeLayer('background', 1, shapes, { a: [200, 400] }, 0, F.OP));
}

// ================= LAYER 2 : scene (animated push-in) =====================
{
  const scene = [];

  // `shapes` array is TOP-FIRST (first = topmost), so push from top to bottom
  // Diploma (topmost) first, then graduate, faculty, applause, audience,
  // stage, curtains, backdrop (bottommost).

  // ---- diploma -----------------------------------------------------------
  scene.push(diplomaGroup());

  // ---- graduate ----------------------------------------------------------
  scene.push(graduateGroup());

  // ---- faculty -----------------------------------------------------------
  scene.push(facultyGroup());

  // ---- audience reaction hands (very subtle applause) --------------------
  scene.push(
    group('applause', [
      rectShape('handA', 12, 24, 120, 0, 6),
      fill('handAFill', C.aud, 78),
      rectShape('handB', 12, 24, 280, 0, 6),
      fill('handBFill', C.aud, 78),
    ], {
      pAnim: [
        { t: 0, v: [0, 0] },
        { t: 324, v: [0, 0] },
        { t: 348, v: [0, -10] },
        { t: 372, v: [0, -3] },
        { t: 420, v: [0, -10] },
        { t: 510, v: [0, -10] },
      ],
      oAnim: [
        { t: 0, v: 0 },
        { t: 324, v: 0 },
        { t: 348, v: 100 },
        { t: 510, v: 100 },
      ],
    }),
  );

  // ---- audience silhouettes (behind the graduate) -------------------------
  {
    const heads = [];
    const backRow = [64, 108, 152, 196, 244, 288, 332];
    const frontRow = [80, 126, 172, 228, 274, 320];
    backRow.forEach((x, i) => {
      heads.push(ellipseShape(`ab${i}`, 20, 22, x, 470));
      heads.push(fill(`abf${i}`, C.aud, 55));
      heads.push(rectShape(`abs${i}`, 24, 15, x, 484, 7));
      heads.push(fill(`absf${i}`, C.aud, 45));
    });
    frontRow.forEach((x, i) => {
      heads.push(ellipseShape(`af${i}`, 23, 25, x, 505));
      heads.push(fill(`aff${i}`, C.aud, 62));
      heads.push(rectShape(`afs${i}`, 26, 16, x, 522, 8));
      heads.push(fill(`afsf${i}`, C.aud, 50));
    });
    scene.push(group('audience', heads, {}));
  }

  // ---- stage -------------------------------------------------------------
  scene.push(
    group('stage', [
      rectShape('stage', 400, 150, 200, 715, 24),
      fill('stageFill', C.stageFace),
      rectShape('stageTop', 400, 20, 200, 650, 10),
      fill('stageTopFill', C.stageTop),
      rectShape('stageEdge', 400, 6, 200, 641, 3),
      fill('stageEdgeFill', C.stageEdge, 80),
      rectShape('goldTrim', 340, 7, 200, 786, 3),
      fill('goldTrimFill', C.gold, 40),
    ], {}),
  );

  // ---- curtains ----------------------------------------------------------
  scene.push(
    group('curtainL', [
      rectShape('curL', 50, 800, 25, 400, 16),
      fill('curLFill', C.curtain),
      rectShape('foldL1', 7, 780, 40, 400, 3),
      fill('foldL1Fill', C.curtainFold, 70),
    ], {}),
  );
  scene.push(
    group('curtainR', [
      rectShape('curR', 50, 800, 375, 400, 16),
      fill('curRFill', C.curtain),
      rectShape('foldR1', 7, 780, 360, 400, 3),
      fill('foldR1Fill', C.curtainFold, 70),
    ], {}),
  );

  // ---- backdrop arch -----------------------------------------------------
  scene.push(
    group('backdrop', [
      rectShape('arch', 360, 520, 200, 300, 150),
      fill('archFill', C.arch, 60),
    ], {}),
  );

  // scene-level camera push-in (very subtle, toward the graduate)
  const sceneT = {
    a: [200, 470],
    pAnim: [
      { t: 0, v: [200, 470] },
      { t: 24, v: [200, 470] },
      { t: 510, v: [200, 478] },
    ],
    sAnim: [
      { t: 0, v: [100, 100] },
      { t: 24, v: [100, 100] },
      { t: 510, v: [112, 112] },
    ],
  };
  layers.push(shapeLayer('scene', 2, scene, sceneT, 0, F.OP));
}

// ================= LAYER 3 : graduation cap (flies to camera) =============
layers.push(capLayer());

// ------------------------------------------------------------------ output ---
// `layers` must be TOP-FIRST: cap (top), then scene, then background (bottom).
layers.reverse();
const out = {
  v: '5.7.4',
  fr: 60,
  ip: 0,
  op: F.OP,
  w: 400,
  h: 800,
  nm: 'Scholaris Opening Ceremony',
  ddd: 0,
  assets: [],
  layers,
  markers: [],
};

const fs = require('fs');
const path = require('path');
const target = path.join(__dirname, '..', 'assets', 'animations', 'scholaris_ceremony.json');
fs.writeFileSync(target, JSON.stringify(out));
console.log('wrote', target, (fs.statSync(target).size / 1024).toFixed(1) + ' KB');

// ---------------------------------------------------------------- builders ---
function facultyGroup() {
  // Faculty on the right; walks in, hands the diploma, steps back.
  const arm = group('facArm', [
    rectShape('facArmCap', 16, 64, 0, 32, 8),
    fill('facArmCapFill', C.facRobe),
    ellipseShape('facHand', 19, 19, 0, 72),
    fill('facHandFill', C.skinFac),
  ], {
    p: [-52, -208],
    pAnim: [
      { t: 0, v: [-52, -208] },
      { t: 108, v: [-52, -208] },
      { t: 144, v: [-66, -212] },
      { t: 192, v: [-74, -216] },
      { t: 222, v: [-58, -212] },
      { t: 510, v: [-58, -212] },
    ],
    rAnim: [
      { t: 0, v: 10 },
      { t: 108, v: 10 },
      { t: 144, v: 34 },
      { t: 192, v: 58 },
      { t: 222, v: 24 },
      { t: 510, v: 24 },
    ],
  });

  const body = group('facBody', [
    rectShape('facRobe', 92, 228, 0, -112, 32),
    fill('facRobeFill', C.facRobe),
    rectShape('facStole', 18, 208, 0, -116, 7),
    fill('facStoleFill', C.gradStole, 92),
    rectShape('facCollar', 26, 11, 0, -198, 5),
    fill('facCollarFill', C.gradStole),
  ], {
    pAnim: [
      { t: 0, v: [0, 0] },
      { t: 108, v: [0, 0] },
      { t: 144, v: [0, -1] },
      { t: 156, v: [0, 0] },
      { t: 168, v: [0, -1] },
      { t: 180, v: [0, 0] },
      { t: 192, v: [0, 0] },
      { t: 222, v: [0, 0] },
      { t: 510, v: [0, 0] },
    ],
  });

  const head = group('facHead', [
    ellipseShape('facHead', 70, 74, 0, 0),
    fill('facHeadFill', C.skinFac),
    ellipseShape('facHair', 68, 40, 0, -16),
    fill('facHairFill', C.hairFac),
    ellipseShape('facEyeL', 5, 7, -9, -2),
    fill('facEyeLFill', C.eye, 85),
    ellipseShape('facEyeR', 5, 7, 9, -2),
    fill('facEyeRFill', C.eye, 85),
  ], {
    p: [0, -272],
    rAnim: [
      { t: 0, v: 0 },
      { t: 108, v: 2 },
      { t: 144, v: 0 },
      { t: 192, v: 0 },
      { t: 222, v: 3 },
      { t: 510, v: 3 },
    ],
  });

  return group('faculty', [body, head, arm], {
    pAnim: [
      { t: 0, v: [312, 690] },
      { t: 108, v: [312, 690] },
      { t: 144, v: [296, 690] },
      { t: 192, v: [296, 690] },
      { t: 222, v: [304, 690] },
      { t: 510, v: [304, 690] },
    ],
  });
}

function graduateGroup() {
  // Graduate centre stage (feet at 200,690).

  const leftArm = group('gradLeftArm', [
    rectShape('gradLeftArmCap', 18, 68, 0, 34, 9),
    fill('gradLeftArmFill', C.gradRobe),
    ellipseShape('gradLeftHand', 20, 20, 0, 74),
    fill('gradLeftHandFill', C.skinGrad),
  ], {
    p: [-46, -215],
    rAnim: [
      { t: 0, v: 12 },
      { t: 336, v: 12 },
      { t: 348, v: -52 },
      { t: 372, v: -56 },
      { t: 510, v: -56 },
    ],
  });

  const rightArm = group('gradRightArm', [
    rectShape('gradRightArmCap', 18, 68, 0, 34, 9),
    fill('gradRightArmFill', C.gradRobe),
    ellipseShape('gradRightHand', 20, 20, 0, 74),
    fill('gradRightHandFill', C.skinGrad),
  ], {
    p: [46, -215],
    pAnim: [
      { t: 0, v: [46, -215] },
      { t: 144, v: [46, -215] },
      { t: 192, v: [56, -210] },
      { t: 222, v: [53, -212] },
      { t: 252, v: [49, -214] },
      { t: 288, v: [46, -212] },
      { t: 336, v: [49, -212] },
      { t: 348, v: [56, -210] },
      { t: 372, v: [53, -235] },
      { t: 408, v: [48, -232] },
      { t: 456, v: [53, -224] },
      { t: 510, v: [49, -215] },
    ],
    rAnim: [
      { t: 0, v: -10 },
      { t: 144, v: -10 },
      { t: 192, v: -46 },
      { t: 222, v: -40 },
      { t: 252, v: -92 },
      { t: 288, v: -150 },
      { t: 336, v: -150 },
      { t: 348, v: -20 },
      { t: 372, v: -170 },
      { t: 408, v: -180 },
      { t: 456, v: -165 },
      { t: 510, v: -18 },
    ],
  });

  const body = group('gradBody', [
    rectShape('gradRobe', 100, 240, 0, -120, 34),
    fill('gradRobeFill', C.gradRobe),
    rectShape('gradStole', 20, 220, 0, -125, 8),
    fill('gradStoleFill', C.gradStole),
    rectShape('gradTrim', 28, 12, 0, -205, 5),
    fill('gradTrimFill', C.gold, 90),
    rectShape('gradHem', 78, 7, 0, -8, 3),
    fill('gradHemFill', C.gold, 55),
  ], {
    pAnim: [
      { t: 0, v: [0, 0] },
      { t: 192, v: [0, 0] },
      { t: 222, v: [0, 2] },
      { t: 252, v: [0, 2] },
      { t: 510, v: [0, 2] },
    ],
    sAnim: [
      { t: 0, v: [100, 100] },
      { t: 288, v: [100, 100] },
      { t: 312, v: [100, 100.8] },
      { t: 336, v: [100, 100] },
      { t: 360, v: [100, 100.6] },
      { t: 384, v: [100, 100] },
      { t: 510, v: [100, 100] },
    ],
  });

  const head = group('gradHead', [
    ellipseShape('gradHead', 78, 82, 0, 0),
    fill('gradHeadFill', C.skinGrad),
    ellipseShape('gradHair', 76, 44, 0, -17),
    fill('gradHairFill', C.hairGrad),
    ellipseShape('gradEyeL', 5, 7, -11, -2),
    fill('gradEyeLFill', C.eye, 85),
    ellipseShape('gradEyeR', 5, 7, 11, -2),
    fill('gradEyeRFill', C.eye, 85),
  ], {
    p: [0, -285],
    rAnim: [
      { t: 0, v: 0 },
      { t: 222, v: 0 },
      { t: 252, v: -10 },
      { t: 336, v: -10 },
      { t: 372, v: -6 },
      { t: 510, v: -6 },
    ],
    pAnim: [
      { t: 0, v: [0, -285] },
      { t: 222, v: [0, -285] },
      { t: 252, v: [0, -282] },
      { t: 510, v: [0, -282] },
    ],
  });

  const shadow = group('gradShadow', [
    ellipseShape('gradShadow', 96, 14, 0, 4),
    fill('gradShadowFill', C.shadow, 15),
  ], {});

  return group('graduate', [shadow, leftArm, body, head, rightArm], {
    pAnim: [
      { t: 0, v: [200, 690] },
      { t: 192, v: [200, 690] },
      { t: 222, v: [199, 690] },
      { t: 510, v: [199, 690] },
    ],
  });
}

function diplomaGroup() {
  const it = [
    rectShape('dip', 20, 58, 0, 0, 5),
    fill('dipFill', hex('F7F0DD')),
    rectShape('dipBand', 20, 18, 0, -16, 3),
    fill('dipBandFill', C.gold),
    rectShape('dipBand2', 20, 18, 0, 20, 3),
    fill('dipBand2Fill', C.gold, 70),
    rectShape('dipSeal', 9, 9, 0, -24, 4),
    fill('dipSealFill', C.gradStole),
  ];

  return group('diploma', it, {
    pAnim: [
      { t: 0, v: [285, 545] },
      { t: 108, v: [276, 542] },
      { t: 144, v: [266, 535] },
      { t: 192, v: [256, 528] },
      { t: 222, v: [238, 508] },
      { t: 252, v: [230, 470] },
      { t: 288, v: [222, 385] },
      { t: 336, v: [222, 385] },
      { t: 348, v: [222, 400] },
      { t: 372, v: [206, 520] },
      { t: 510, v: [206, 520] },
    ],
    rAnim: [
      { t: 0, v: -14 },
      { t: 108, v: -14 },
      { t: 144, v: -8 },
      { t: 192, v: 8 },
      { t: 222, v: -16 },
      { t: 252, v: -6 },
      { t: 288, v: -2 },
      { t: 348, v: -2 },
      { t: 372, v: -30 },
      { t: 510, v: -20 },
    ],
    sAnim: [
      { t: 0, v: [100, 100] },
      { t: 288, v: [100, 100] },
      { t: 336, v: [106, 106] },
      { t: 348, v: [106, 106] },
      { t: 372, v: [100, 100] },
      { t: 510, v: [100, 100] },
    ],
  });
}

function capLayer() {
  // Cap drawn as a diamond mortarboard (rotated rounded square) so that at high
  // scale it fully occludes the 400x800 frame. Origin at the cap centre.
  const it = [
    group('skull', [
      ellipseShape('skull', 72, 48, 0, 18),
      fill('skullFill', C.cap),
    ], {}),
    group('board', [
      rectShape('boardTop', 68, 68, 0, -2, 10),
      fill('boardTopFill', C.capTop),
      rectShape('board', 68, 68, 0, 0, 10),
      fill('boardFill', C.cap),
    ], { r: 45 }),
    group('tassel', [
      rectShape('tasselStr', 3, 24, 36, 20, 1.5),
      fill('tasselStrFill', C.goldLight),
      ellipseShape('tassel', 13, 13, 39, 33),
      fill('tasselFill', C.goldLight),
    ], { r: 18 }),
    ellipseShape('btn', 11, 11, 0, -2),
    fill('btnFill', C.goldLight),
  ];

  const pAnim = [
    { t: 0, v: [200, 356] },
    { t: 222, v: [200, 358] },
    { t: 252, v: [200, 359] },
    { t: 348, v: [200, 354] },
    { t: 372, v: [203, 285] },
    { t: 408, v: [207, 190] },
    { t: 456, v: [205, 118] },
    { t: 480, v: [202, 108] },
    { t: 509, v: [200, 400] },
    { t: 510, v: [200, 400] },
  ];
  const sAnim = [
    { t: 0, v: [100, 100] },
    { t: 348, v: [106, 106] },
    { t: 372, v: [112, 112] },
    { t: 408, v: [135, 135] },
    { t: 456, v: [300, 300] },
    { t: 480, v: [360, 360] },
    { t: 509, v: [1500, 1500] },
    { t: 510, v: [1500, 1500] },
  ];
  const rAnim = [
    { t: 0, v: 0 },
    { t: 222, v: 0 },
    { t: 252, v: -8 },
    { t: 348, v: -8 },
    { t: 372, v: -24 },
    { t: 408, v: -70 },
    { t: 456, v: -150 },
    { t: 480, v: -180 },
    { t: 509, v: -225 },
    { t: 510, v: -225 },
  ];

  const t = { a: [0, 0], pAnim, sAnim, rAnim };
  return shapeLayer('graduation_cap', 3, it, t, 0, F.OP);
}
