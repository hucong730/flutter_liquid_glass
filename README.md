# liquid_glass_fx

A pure-Dart Flutter package that renders iOS 26-style **liquid glass** using a
`FragmentShader` (GLSL, compiled by Impeller) and a dual-`BackdropFilter`
pipeline: refraction lensing, edge highlights, background blur, plus
press/drag deformation with spring-back.

The default visual style is "clear glass": strong lens refraction, light blur,
and a bright directional edge rim.

## Rendering pipeline

Inside a rounded-rect clip, two backdrop filters are nested:

1. Inner `BackdropFilter(ImageFilter.blur)` — background blur handled by the
   engine (Impeller's downsample-optimized blur).
2. Outer `BackdropFilter(ImageFilter.shader)` — samples the already-blurred
   backdrop and applies refraction UV displacement (hemisphere bevel height
   field, true 3D normals, Snell refraction with light-path length), RGB
   chromatic dispersion, edge highlights (meniscus shading + directional rim),
   luminance-preserving tint, and press/drag deformation.

## Usage

```dart
import 'package:liquid_glass_fx/liquid_glass_fx.dart';

LiquidGlass(
  borderRadius: 20,
  quality: LiquidGlassQuality.high,
  child: Text('Hello glass'),
)

LiquidGlassButton(onPressed: () {}, child: Text('OK'))

LiquidGlassCard(child: ...)

LiquidGlassNavigationBar(
  items: [Icon(Icons.home), Icon(Icons.search), Icon(Icons.person)],
  currentIndex: _index,
  onItemSelected: (i) => setState(() => _index = i),
)
```

Interactive deformation (press dimple, touch-aligned edge glint, drag
stretch) is enabled by default on `LiquidGlass` / `LiquidGlassButton`.
Use `LiquidGlassController` to drive it externally or link multiple surfaces.

## Quality tiers

`LiquidGlassQuality` applies multiplicative downgrades only; explicitly passed
parameters always win over tier defaults.

| Tier | blur sigma | refraction | highlight | dispersion | deformation |
|---|---|---|---|---|---|
| high | ×1.0 | full | full | on | on |
| medium | ×0.7 | weak (×0.5) | simplified (×0.5) | off | on |
| low | ×0.5 | off | off | off | off (shader does tint only, ~1 texture fetch) |

Recommended: `high` on flagship devices, `medium` on mid-range Android, `low`
for low-end Android or very large (near-fullscreen) glass with high blur sigma.

## Known limitations

- Requires Impeller runtime-effect compilation. On Skia fallback targets
  (some old Android devices, web) the shader may fail to compile; the widget
  then degrades gracefully to blur only.
- Large fullscreen glass + high blur sigma is expensive on low-end Android —
  use the `low` tier.
- Golden tests do not run real Impeller shaders; verify visuals on device
  with the `example/` app.
