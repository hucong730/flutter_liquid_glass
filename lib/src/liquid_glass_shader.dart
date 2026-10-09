import 'dart:ui';

/// Loads and caches the liquid glass [FragmentProgram] and binds uniforms.
///
/// This is the only module that touches the `FragmentShader` API, so the
/// shader backend could be swapped for a native implementation later.
abstract final class LiquidGlassShader {
  static FragmentProgram? _program;
  static Future<FragmentProgram?>? _loading;

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
    // uFlags (bit0 refraction, bit1 highlight)
    shader.setFloat(i++,
        (refractionEnabled ? 1 : 0).toDouble() + (highlightEnabled ? 2 : 0).toDouble());
    // uTouchPoint
    shader.setFloat(i++, touchPoint?.dx ?? 0);
    shader.setFloat(i++, touchPoint?.dy ?? 0);
    // uPressAmount
    shader.setFloat(i++, pressAmount);
    // uDragVelocity
    shader.setFloat(i++, dragVelocity.dx);
    shader.setFloat(i++, dragVelocity.dy);
  }
}
