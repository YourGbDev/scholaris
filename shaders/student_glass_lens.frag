#include <flutter/runtime_effect.glsl>
uniform vec2 uInputSize;
uniform vec2 uSurfaceSize;
uniform float uRadius;
uniform float uStrength;
uniform sampler2D uBackdrop;
out vec4 fragColor;

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 halfSize = uSurfaceSize * 0.5;
  float radius = min(uRadius, min(halfSize.x, halfSize.y));
  vec2 q = abs(p - halfSize) - halfSize + vec2(radius);
  float distanceToEdge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
  // Restrict bending to the inner perimeter; the center stays readable.
  float edge = 1.0 - smoothstep(0.0, uStrength * 2.0, -distanceToEdge);
  // A localized vertical magnification matrix stretches the actual backdrop
  // in the 10 logical-pixel rim while leaving the core coordinates unchanged.
  vec2 samplePoint = p;
  samplePoint.y = halfSize.y + (p.y - halfSize.y) / (1.0 + 0.10 * edge);
  vec2 uv = samplePoint / uInputSize;
  #ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
  #endif
  fragColor = texture(uBackdrop, clamp(uv, vec2(0.001), vec2(0.999)));
}
