## 0.0.2

- Add pub.dev topics metadata. No functional changes.

## 0.0.1

Initial release.

- `LiquidGlass` container: iOS 26-style liquid glass via `FragmentShader` +
  dual `BackdropFilter` (engine blur + custom refraction/highlight pass)
- Hemisphere bevel height field with true 3D normals, Snell refraction with
  light-path length, RGB chromatic dispersion, meniscus edge shading,
  luminance-preserving tint, content-adaptive strength, gated whiten
- Interaction: press dimple + touch-aligned edge glint, drag stretch,
  spring-back release; zero frame callbacks while idle
- `LiquidGlassQuality.high/medium/low` manual quality tiers
- Preset widgets: `LiquidGlassButton`, `LiquidGlassCard`,
  `LiquidGlassNavigationBar`
- `LiquidGlassController` for external/interactive control
- Example app with showcase of all widgets and custom parameter combos
