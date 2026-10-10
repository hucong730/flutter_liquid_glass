import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_fx/src/liquid_glass_shader.dart';

void main() {
  test('shader program loads and binds without error', () async {
    final program = await LiquidGlassShader.load();
    expect(program, isNotNull,
        reason: 'FragmentProgram failed to compile/load');
    final shader = LiquidGlassShader.createShader();
    expect(shader, isNotNull);
    LiquidGlassShader.bind(
      shader!,
      size: const Size(100, 50),
      radius: 20,
      refractionStrength: 1,
      highlightIntensity: 1,
      tint: const Color(0x14FFFFFF),
      refractionEnabled: true,
      highlightEnabled: true,
      chromaticAberrationEnabled: true,
    );
    // The shader declares exactly [LiquidGlassShader.floatUniformCount]
    // float uniforms; writing past the end must throw.
    expect(() => shader.setFloat(LiquidGlassShader.floatUniformCount, 0),
        throwsA(anything));
  });

  test('flags bitfield: bit0 refraction, bit1 highlight, bit2 chromatic', () {
    expect(
        LiquidGlassShader.flags(
            refractionEnabled: false,
            highlightEnabled: false,
            chromaticAberrationEnabled: false),
        0.0);
    expect(
        LiquidGlassShader.flags(
            refractionEnabled: true,
            highlightEnabled: false,
            chromaticAberrationEnabled: false),
        1.0);
    expect(
        LiquidGlassShader.flags(
            refractionEnabled: false,
            highlightEnabled: true,
            chromaticAberrationEnabled: false),
        2.0);
    expect(
        LiquidGlassShader.flags(
            refractionEnabled: true,
            highlightEnabled: true,
            chromaticAberrationEnabled: true),
        7.0);
  });
}
