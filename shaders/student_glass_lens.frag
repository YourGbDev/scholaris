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
  float edge = 1.0 - smoothstep(0.0, 12.0, -distanceToEdge);
  vec2 normal = normalize((p - halfSize) / max(halfSize, vec2(1.0)) + vec2(0.0001));
  vec2 uv = (p - normal * edge * uStrength) / uInputSize;
  #ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
  #endif
  fragColor = texture(uBackdrop, clamp(uv, vec2(0.001), vec2(0.999)));
}
