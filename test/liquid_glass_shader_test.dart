import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/src/liquid_glass_shader.dart';

void main() {
  test('shader program loads and binds without error', () async {
    final program = await LiquidGlassShader.load();
    expect(program, isNotNull, reason: 'FragmentProgram failed to compile/load');
    final shader = LiquidGlassShader.createShader();
    expect(shader, isNotNull);
    LiquidGlassShader.bind(shader!,
        size: const Size(100, 50),
        radius: 20,
        refractionStrength: 1,
        highlightIntensity: 1,
        tint: const Color(0x14FFFFFF),
        refractionEnabled: true,
        highlightEnabled: true);
  });
}
