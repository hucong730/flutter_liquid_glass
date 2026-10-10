#include <flutter/runtime_effect.glsl>

// Liquid glass backdrop shader.
//
// The first sampler uniform is bound to the (already blurred) backdrop when
// the shader is used via ImageFilter.shader inside a BackdropFilter.
uniform sampler2D uBackdrop;

// Uniform order matters: liquid_glass_shader.dart binds floats in exactly
// this declaration order (samplers are indexed separately).
uniform vec2 uSize;                // filter coverage size in px
uniform float uRadius;             // corner radius in px
uniform float uRefractionStrength; // 0..2 artist multiplier
uniform float uHighlightIntensity; // 0..2
uniform vec4 uTint;                // rgba glass tint
uniform float uFlags;              // bit0: refraction, bit1: highlight, bit2: chromatic aberration
uniform vec2 uTouchPoint;          // px, top-left origin (filter-local)
uniform float uPressAmount;        // 0..1
uniform vec2 uDragVelocity;        // per-frame drag offset in px
uniform float uThickness;          // bevel thickness t in px (hemisphere profile)
uniform float uRefractiveIndex;    // ~1.5 for glass
uniform float uChromaticAberration;// 0 = off, ~0.15 subtle RGB split
uniform vec2 uLightDirection;      // normalized-ish 2D light direction

layout(location = 0) out vec4 fragColor;

// ITU-R Rec.709 luma weights (render.glsl LUMA_WEIGHTS).
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

const float kBaseHeightFactor = 1.5; // flat-slab base height = t * this
const float kRefractScale = 0.5;     // tames Snell displacement to taste
const float kWhiten = 0.12;          // luminance-gated whiten strength
const float kMeniscus = 0.30;        // edge absorption strength
const float kFresnel = 0.12;         // rim luminosity ramp strength
const float kRimLobe = 0.5;          // directional specular lobe strength
const float kPressDepth = 10.0;      // SDF dent depth at full press
const float kPressSigma = 45.0;      // gaussian radius of the press field
const float kPressLens = 0.22;       // radial UV pull toward the touch point
const float kPressDarken = 0.12;     // shading at the dent center
const float kDragStretch = 0.25;     // drag offset -> shape stretch factor
const float kDragLens = 0.35;        // interior content lag while dragging

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

// Manual bilinear filtering. Impeller binds the implicit BackdropFilter
// sampler as Nearest-Neighbor (Flutter issue #139887), so continuous
// sub-pixel refraction shifts would snap to integer texels and stair-step
// on high-contrast background edges.
// Ported from liquid_glass_render.frag:180-212 (the fallback-colour branch
// is dropped — this pipeline has no PlatformView fallback).
vec4 textureBilinear(vec2 uv) {
  vec2 invSize = 1.0 / uSize;
  vec2 px = uv * uSize - 0.5;
  vec2 f = fract(px);
  vec2 p0 = clamp(floor(px), vec2(0.0), uSize - 1.0);
  vec2 p1 = clamp(p0 + vec2(1.0, 0.0), vec2(0.0), uSize - 1.0);
  vec2 p2 = clamp(p0 + vec2(0.0, 1.0), vec2(0.0), uSize - 1.0);
  vec2 p3 = clamp(p0 + vec2(1.0, 1.0), vec2(0.0), uSize - 1.0);

  vec4 c0 = texture(uBackdrop, (p0 + 0.5) * invSize);
  vec4 c1 = texture(uBackdrop, (p1 + 0.5) * invSize);
  vec4 c2 = texture(uBackdrop, (p2 + 0.5) * invSize);
  vec4 c3 = texture(uBackdrop, (p3 + 0.5) * invSize);

  return mix(mix(c0, c1, f.x), mix(c2, c3, f.x), f.y);
}

// Luminance-preserving glass tint: chromatic glass shifts hue while keeping
// backdrop brightness; achromatic glass alpha-blends directly. Chroma-weighted
// branchless blend of both paths.
// Ported from render.glsl:75-97 (bodyMode parameter dropped — always the
// adaptive dual-path model).
vec3 applyGlassColor(vec3 liquid, vec4 glass) {
  vec3 directMix = mix(liquid, glass.rgb, glass.a);

  float backdropLuma = dot(liquid, LUMA);
  float glassLuma = dot(glass.rgb, LUMA);
  vec3 shifted = clamp(glass.rgb + (backdropLuma - glassLuma), 0.0, 1.0);

  float chroma = max(max(glass.r, glass.g), glass.b) -
                 min(min(glass.r, glass.g), glass.b);
  float chromaWeight = clamp(chroma * 8.0, 0.0, 1.0);

  vec3 luminosityMix = mix(liquid, shifted, glass.a);
  return mix(directMix, luminosityMix, chromaWeight);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 invSize = 1.0 / uSize;
  vec2 halfSize = uSize * 0.5;
  float radius = min(uRadius, min(halfSize.x, halfSize.y));
  float t = clamp(uThickness, 1.0, min(halfSize.x, halfSize.y));

  // Drag deformation: stretch the shape along the drag direction (existing).
  vec2 p = fragCoord - halfSize - uDragVelocity * kDragStretch;

  float d = sdRoundedBox(p, halfSize, radius);

  // Press field: radial gaussian around the touch point. The dent feeds the
  // SDF, so it shows up naturally in the hemisphere normal model below.
  vec2 pressDelta = fragCoord - uTouchPoint;
  float pressG = 0.0;
  if (uPressAmount > 0.001) {
    pressG = exp(-dot(pressDelta, pressDelta) / (2.0 * kPressSigma * kPressSigma));
    d -= uPressAmount * pressG * kPressDepth;
  }

  float flags = floor(uFlags + 0.5);
  bool refractionOn = mod(flags, 2.0) > 0.5;
  bool highlightOn = mod(floor(flags * 0.5), 2.0) > 0.5;
  bool chromaOn = mod(floor(flags * 0.25), 2.0) > 0.5;

  // Hemisphere bevel -> true 3D surface normal.
  // Ported from liquid_glass_geometry_blended.frag:113-119: n_cos runs 1 at
  // the rim to 0 on the flat face, so normal.xy = grad * n_cos and
  // normal.z = n_sin give a unit hemispherical normal (no normalize needed
  // when gradN is unit length).
  vec2 grad = sdRoundedBoxGrad(p, halfSize, radius);
  float gradLen = length(grad);
  vec2 gradN = gradLen > 1e-4 ? grad / gradLen : vec2(0.0, 1.0);
  float nCos = clamp((t + d) / t, 0.0, 1.0);
  float nSin = sqrt(max(0.0, 1.0 - nCos * nCos));
  vec3 normal = vec3(gradN * nCos, nSin);

  // Circular-arc thickness profile: 0 at the rim, rising to t at the bevel's
  // inner edge, saturating at t on the flat face.
  // Ported from liquid_glass_geometry_blended.frag:126-128.
  float x = t + d;
  float height = x <= 0.0 ? t : sqrt(max(0.0, t * t - x * x));

  // True Snell refraction with propagation distance through the slab.
  // Ported from liquid_glass_render.frag:379-403 (paraxial-lens branch and
  // DPR rescale dropped — single-shape pipeline, logical px).
  vec2 displacement = vec2(0.0);
  if (refractionOn && uRefractionStrength > 0.001) {
    vec3 refr = refract(vec3(0.0, 0.0, -1.0), normal,
                        1.0 / max(uRefractiveIndex, 1.001));
    float travel = (height + t * kBaseHeightFactor) / max(0.001, abs(refr.z));
    displacement = refr.xy * travel * (uRefractionStrength * kRefractScale);
  }

  // Press lens: pull samples radially toward the touch point (existing).
  if (uPressAmount > 0.001) {
    displacement -= pressDelta * pressG * uPressAmount * kPressLens;
  }
  // Drag lag: the liquid interior trails the drag direction (existing).
  displacement -= uDragVelocity * kDragLens * (height / t);

  // Clamp the reach so rim pixels never sample content far outside the
  // shape's own footprint (would smear distant bright text into the rim).
  // Ported from liquid_glass_render.frag:418-422.
  float maxReach = 0.5 * min(uSize.x, uSize.y);
  float reach = length(displacement);
  if (reach > maxReach) {
    displacement *= maxReach / reach;
  }

  // Backdrop sampling. RGB chromatic aberration splits the channels along
  // the displacement vector; high quality tier only.
  // Ported from liquid_glass_render.frag:565-579, upgraded to the manual
  // bilinear sampler above.
  vec2 baseUV = fragCoord * invSize;
  vec4 bgSample;
  if (chromaOn && uChromaticAberration > 0.001) {
    float disp = uChromaticAberration * 0.5;
    float r = textureBilinear(baseUV + displacement * (1.0 + disp) * invSize).r;
    vec4 g = textureBilinear(baseUV + displacement * invSize);
    float b = textureBilinear(baseUV + displacement * (1.0 - disp) * invSize).b;
    bgSample = vec4(r, g.g, b, g.a);
  } else {
    bgSample = textureBilinear(baseUV + displacement * invSize);
  }

  // BackdropFilter delivers premultiplied RGBA; un-premultiply before the
  // colour math (on opaque backdrops this is a no-op).
  // Ported from liquid_glass_render.frag:581-589.
  vec3 color = bgSample.a > 0.001 ? bgSample.rgb / bgSample.a : bgSample.rgb;

  // Content-adaptive strength: dark backdrops get richer glass, bright ones
  // subtler. Ported from liquid_glass_render.frag:628-629.
  float adaptive = mix(1.2, 0.8, dot(color, LUMA));

  // Press shading: slight darkening at the dent center (existing).
  if (uPressAmount > 0.001) {
    color *= 1.0 - pressG * uPressAmount * kPressDarken;
  }

  // Luminance-preserving tint + adaptive tint weight.
  // Adaptive modulation ported from liquid_glass_render.frag:646-649.
  color = applyGlassColor(color, uTint);
  color = mix(color, uTint.rgb, uTint.a * 0.12 * (adaptive - 1.0));

  // Adaptive saturation (liquid_glass_render.frag:636-637 via render.glsl
  // applySaturation, Rec.709 luma).
  float satLuma = dot(color, LUMA);
  color = clamp(mix(vec3(satLuma), color, 1.06 * adaptive), 0.0, 1.0);

  // Luminance-gated whiten: lifts bright content toward white, protects
  // darks. Ported from liquid_glass_render.frag:673-681 (strength is a
  // constant here, gate always on).
  float whitenGate = smoothstep(0.40, 0.80, dot(color, LUMA));
  color = mix(color, vec3(1.0), kWhiten * whitenGate);

  vec2 lightDir = normalize(uLightDirection);

  if (highlightOn && uHighlightIntensity > 0.001) {
    // Meniscus darkening: hemisphere thickness profile absorbs light at the
    // rim, modulated by direction — lit side 0.6x, shadow side 1.4x.
    // Ported from liquid_glass_render.frag:725-741 (rimThickness == nCos in
    // this single-shape model: 1 at the rim, 0 on the flat face).
    float litness = dot(gradN, lightDir);
    float dirScale = mix(1.4, 0.6, litness * 0.5 + 0.5);
    float absorption =
        1.0 - sqrt(nCos) * kMeniscus * dirScale * uHighlightIntensity;
    color *= max(absorption, 0.0);

    // Fresnel rim luminosity: (1 - normal.z) ramps up at grazing angles,
    // gated to the bevel band by nCos.
    // Simplified from liquid_glass_render.frag:834-869 (rimBase term only).
    color += vec3((1.0 - nSin) * nCos * kFresnel * uHighlightIntensity);

    // Directional specular lobe along the light axis.
    float lobe = clamp(dot(gradN, lightDir) * 0.5 + 0.5, 0.0, 1.0);
    color += vec3(nCos * nCos * lobe * lobe * lobe * kRimLobe *
                  uHighlightIntensity);

    // Touch specular glint: a tight edge-aligned lobe (dot^6 via multiplies,
    // no pow) that lights only the rim nearest the touch point, with
    // distance falloff. Replaces the old gaussian press ring.
    // Ported from liquid_glass_render.frag:800-830 (DPR scaling and
    // highlight-colour mix simplified to an additive white glint).
    if (uPressAmount > 0.001) {
      vec2 toFrag = fragCoord - uTouchPoint;
      float touchDist = length(toFrag);
      float touchRadius = max(120.0, min(uSize.x, uSize.y) * 1.5);
      float distFactor = 1.0 - smoothstep(0.0, touchRadius, touchDist);
      if (distFactor > 0.001 && touchDist > 1.0) {
        vec2 touchDir = toFrag / touchDist;
        float rimTouchDot = max(0.0, dot(gradN, touchDir));
        float rtd2 = rimTouchDot * rimTouchDot;
        float tSpec = rtd2 * rtd2 * rtd2 * distFactor; // dot^6
        float bright = tSpec * uPressAmount * uHighlightIntensity * 2.5;
        bright = bright / (1.0 + bright); // Reinhard compress
        color += vec3(bright * nCos);
      }
    }
  }

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
