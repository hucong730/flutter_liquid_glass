#include <flutter/runtime_effect.glsl>

// Liquid glass backdrop shader.
//
// The first sampler uniform is bound to the (already blurred) backdrop when
// the shader is used via ImageFilter.shader inside a BackdropFilter.
uniform sampler2D uBackdrop;

// Uniform order matters: liquid_glass_shader.dart binds floats in exactly
// this declaration order (samplers are indexed separately).
uniform vec2 uSize;               // filter coverage size in px
uniform float uRadius;            // corner radius in px
uniform float uRefractionStrength;// 0..2
uniform float uHighlightIntensity;// 0..2
uniform vec4 uTint;               // premultiplied-style rgba tint
uniform float uFlags;             // bit0: refraction on, bit1: highlight on
uniform vec2 uTouchPoint;         // px, top-left origin
uniform float uPressAmount;       // 0..1
uniform vec2 uDragVelocity;       // per-frame drag offset in px

layout(location = 0) out vec4 fragColor;

const float kRefractPixels = 10.0; // max UV shift at full height/strength
const float kPressDepth = 10.0;    // SDF dent depth at full press
const float kPressSigma = 45.0;    // gaussian radius of the press dent
const float kDragStretch = 0.25;   // drag offset -> shape stretch factor

float sdRoundedBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Four-point central difference gradient of the rounded-box SDF.
vec2 sdRoundedBoxGrad(vec2 p, vec2 b, float r) {
  const float e = 0.75;
  float dx = sdRoundedBox(p + vec2(e, 0.0), b, r) -
             sdRoundedBox(p - vec2(e, 0.0), b, r);
  float dy = sdRoundedBox(p + vec2(0.0, e), b, r) -
             sdRoundedBox(p - vec2(0.0, e), b, r);
  return vec2(dx, dy) / (2.0 * e);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uSize;
  vec2 halfSize = uSize * 0.5;
  float radius = min(uRadius, min(halfSize.x, halfSize.y));

  // Drag deformation: stretch the shape along the drag direction.
  vec2 p = fragCoord - halfSize - uDragVelocity * kDragStretch;

  float d = sdRoundedBox(p, halfSize, radius);

  // Press deformation: radial gaussian dent around the touch point.
  if (uPressAmount > 0.001) {
    vec2 delta = fragCoord - uTouchPoint;
    float g = exp(-dot(delta, delta) / (2.0 * kPressSigma * kPressSigma));
    d -= uPressAmount * g * kPressDepth;
  }

  float flags = floor(uFlags + 0.5);
  bool refractionOn = mod(flags, 2.0) > 0.5;
  bool highlightOn = mod(floor(flags * 0.5), 2.0) > 0.5;

  // Edge band: d in [-edgeWidth, 0]. height is 1 deep inside, 0 at the edge.
  float shortest = min(uSize.x, uSize.y);
  float edgeWidth = clamp(shortest * 0.18, 6.0, 18.0);
  float height = 1.0 - smoothstep(-edgeWidth, 0.0, d);

  vec2 sampleUV = uv;
  if (refractionOn && uRefractionStrength > 0.001) {
    vec2 grad = sdRoundedBoxGrad(p, halfSize, radius);
    float gradLen = length(grad);
    vec2 normal = gradLen > 1e-4 ? grad / gradLen : vec2(0.0);
    sampleUV = (fragCoord + normal * height * uRefractionStrength * kRefractPixels) / uSize;
  }
  vec3 color = texture(uBackdrop, sampleUV).rgb;

  // Fresnel edge highlight weighted by a fixed light direction (top-left).
  if (highlightOn && uHighlightIntensity > 0.001) {
    vec2 grad = sdRoundedBoxGrad(p, halfSize, radius);
    float gradLen = length(grad);
    vec2 normal = gradLen > 1e-4 ? grad / gradLen : vec2(0.0, -1.0);
    float fresnel = pow(clamp(1.0 - height, 0.0, 1.0), 2.0);
    vec2 lightDir = normalize(vec2(-0.45, -0.89));
    float lightWeight = pow(clamp(dot(normal, lightDir) * 0.5 + 0.5, 0.0, 1.0), 3.0);
    color += vec3(fresnel * lightWeight * uHighlightIntensity * 0.5);
  }

  // Tint overlay.
  color = mix(color, uTint.rgb, clamp(uTint.a, 0.0, 1.0));

  // Slight saturation boost.
  float luma = dot(color, vec3(0.299, 0.587, 0.114));
  color = clamp(mix(vec3(luma), color, 1.06), 0.0, 1.0);

  fragColor = vec4(color, 1.0);
}
