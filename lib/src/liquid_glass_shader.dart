import 'dart:ui';

import 'liquid_glass_geometry.dart';

/// Loads and caches the liquid glass [FragmentProgram] and binds uniforms.
///
/// This is the only module that touches the `FragmentShader` API, so the
/// shader backend could be swapped for a native implementation later.
abstract final class LiquidGlassShader {
  static FragmentProgram? _program;
  static Future<FragmentProgram?>? _loading;

  /// Total number of float uniforms in shaders/liquid_glass.frag.
  static const int floatUniformCount = 20;

  static const Offset defaultLightDirection = Offset(-0.4472, -0.7154);

  /// Loads the program once and caches it globally.
  ///
  /// Resolves to `null` when the shader cannot be compiled (e.g. non-Impeller
  /// backends or test environments); callers should fall back to blur only.
  static Future<FragmentProgram?> load() {
    final cached = _program;
    if (cached != null) return Future.value(cached);
    return _loading ??= FragmentProgram.fromAsset('shaders/liquid_glass.frag')
        .then<FragmentProgram?>((program) => _program = program)
        .catchError((Object _) {
      _loading = null;
      return null;
    });
  }

  /// Whether the program has been loaded successfully.
  static bool get isLoaded => _program != null;

  /// Creates a fresh [FragmentShader] instance, or null when unavailable.
  ///
  /// Each widget keeps its own instance so uniform updates stay cheap
  /// (mutating floats on a retained shader instead of recreating it).
  static FragmentShader? createShader() => _program?.fragmentShader();

  /// Computes the uFlags bitfield (bit0 refraction, bit1 highlight,
  /// bit2 chromatic aberration).
  static double flags({
    required bool refractionEnabled,
    required bool highlightEnabled,
    required bool chromaticAberrationEnabled,
  }) {
    return (refractionEnabled ? 1 : 0).toDouble() +
        (highlightEnabled ? 2 : 0).toDouble() +
        (chromaticAberrationEnabled ? 4 : 0).toDouble();
  }

  /// Binds all float uniforms in shader declaration order.
  static void bind(
    FragmentShader shader, {
    required Size size,
    required double radius,
    required double refractionStrength,
    required double highlightIntensity,
    required Color tint,
    required bool refractionEnabled,
    required bool highlightEnabled,
    bool chromaticAberrationEnabled = false,
    double refractiveIndex = 1.5,
    double chromaticAberration = 0.15,
    Offset lightDirection = defaultLightDirection,
    double? thickness,
    Offset? touchPoint,
    double pressAmount = 0,
    Offset dragVelocity = Offset.zero,
  }) {
    var i = 0;
    // uSize
    shader.setFloat(i++, size.width);
    shader.setFloat(i++, size.height);
    // uRadius
    shader.setFloat(i++, radius);
    // uRefractionStrength
    shader.setFloat(i++, refractionStrength);
    // uHighlightIntensity
    shader.setFloat(i++, highlightIntensity);
    // uTint
    shader.setFloat(i++, tint.r);
    shader.setFloat(i++, tint.g);
    shader.setFloat(i++, tint.b);
    shader.setFloat(i++, tint.a);
    // uFlags (bit0 refraction, bit1 highlight, bit2 chromatic aberration)
    shader.setFloat(
        i++,
        flags(
          refractionEnabled: refractionEnabled,
          highlightEnabled: highlightEnabled,
          chromaticAberrationEnabled: chromaticAberrationEnabled,
        ));
    // uTouchPoint
    shader.setFloat(i++, touchPoint?.dx ?? 0);
    shader.setFloat(i++, touchPoint?.dy ?? 0);
    // uPressAmount
    shader.setFloat(i++, pressAmount);
    // uDragVelocity
    shader.setFloat(i++, dragVelocity.dx);
    shader.setFloat(i++, dragVelocity.dy);
    // uThickness — the bevel band width doubles as the hemisphere thickness.
    shader.setFloat(i++, thickness ?? LiquidGlassGeometry.edgeWidth(size));
    // uRefractiveIndex
    shader.setFloat(i++, refractiveIndex);
    // uChromaticAberration
    shader.setFloat(i++, chromaticAberration);
    // uLightDirection
    shader.setFloat(i++, lightDirection.dx);
    shader.setFloat(i++, lightDirection.dy);
    assert(i == floatUniformCount);
  }
}
