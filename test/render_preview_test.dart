// Render preview tool: rasterizes the real liquid_glass.frag against a
// synthetic backdrop and writes PNGs to build/preview/ for human review.
//
// Run with: flutter test test/render_preview_test.dart
//
// The pipeline mirrors production: the backdrop is first blurred with the
// engine's ImageFilter.blur (our inner BackdropFilter), then the blurred
// image is bound as sampler 0 of the fragment shader and uniforms are bound
// through LiquidGlassShader.bind — the same code path the widgets use.
//
// Layout: two blur-strength rows. Top row blur sigma 6 (logical) so
// refraction bending of the grid/bars is clearly visible; bottom row blur
// sigma 12 (logical), the production default.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_fx/src/liquid_glass_shader.dart';

// Logical scene is 800x600 rendered at 2x -> 1600x1200 physical pixels.
// All coordinates below are physical (logical * kScale).
const double kScale = 2.0;
const double kSceneW = 1600;
const double kSceneH = 1200;
const double kBlockW = 640; // 320 logical
const double kBlockH = 240; // 120 logical
const double kRadius = 48; // 24 logical
const double kRowSplitY = 440; // top row uses light blur, bottom heavy blur

/// Gradient base + saturated shapes + fine grid + text-like bars.
ui.Picture _recordBackdrop() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Multi-colour gradient base.
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, kSceneW, kSceneH),
    ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset.zero,
        const ui.Offset(kSceneW, kSceneH),
        const [
          ui.Color(0xFF1B2651),
          ui.Color(0xFF6A3FA0),
          ui.Color(0xFF0E7C66),
        ],
        const [0.0, 0.5, 1.0],
      ),
  );

  // Saturated circles.
  for (final (center, radius, color) in [
    (const ui.Offset(300, 280), 180.0, const ui.Color(0xFFE53935)),
    (const ui.Offset(1150, 260), 150.0, const ui.Color(0xFFFFD54F)),
    (const ui.Offset(520, 700), 160.0, const ui.Color(0xFF43A047)),
    (const ui.Offset(1330, 920), 170.0, const ui.Color(0xFFD81B60)),
    (const ui.Offset(1180, 640), 110.0, const ui.Color(0xFF00ACC1)),
  ]) {
    canvas.drawCircle(center, radius, ui.Paint()..color = color);
  }

  // Long white "text" bars crossing both glass rows.
  final whiteBar = ui.Paint()..color = const ui.Color(0xE6FFFFFF);
  for (final (y, w) in [
    (200.0, 1420.0),
    (260.0, 1100.0),
    (320.0, 1300.0),
    (580.0, 1400.0),
    (640.0, 1050.0),
    (700.0, 1260.0),
  ]) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(90, y, w, 26), const ui.Radius.circular(13)),
      whiteBar,
    );
  }

  // A light panel with dark "text" bars (exercises the whiten gate).
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(80, 900, 620, 240),
        const ui.Radius.circular(24)),
    ui.Paint()..color = const ui.Color(0xE8F5F5F5),
  );
  final darkBar = ui.Paint()..color = const ui.Color(0xFF263238);
  for (var i = 0; i < 3; i++) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(120, 940.0 + i * 56, i.isEven ? 520 : 380, 26),
          const ui.Radius.circular(13)),
      darkBar,
    );
  }

  // Fine white grid on top of everything.
  final grid = ui.Paint()
    ..color = const ui.Color(0x99FFFFFF)
    ..strokeWidth = 4;
  for (var x = 0.0; x <= kSceneW; x += 80) {
    canvas.drawLine(ui.Offset(x, 0), ui.Offset(x, kSceneH), grid);
  }
  for (var y = 0.0; y <= kSceneH; y += 80) {
    canvas.drawLine(ui.Offset(0, y), ui.Offset(kSceneW, y), grid);
  }

  return recorder.endRecording();
}

Future<ui.Image> _blurred(ui.Image src, double sigma) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImage(
      src,
      ui.Offset.zero,
      ui.Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
  return recorder.endRecording().toImage(src.width, src.height);
}

/// Crops [rect] out of [src] into a standalone image (mirrors how a
/// BackdropFilter hands the shader a texture local to the filter's bounds).
Future<ui.Image> _crop(ui.Image src, ui.Rect rect) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
      src, rect, ui.Offset.zero & rect.size, ui.Paint());
  return recorder
      .endRecording()
      .toImage(rect.width.round(), rect.height.round());
}

class _GlassSpec {
  const _GlassSpec(
    this.rect, {
    this.refractionStrength = 1.0,
    this.thickness,
    this.pressAmount = 0,
    this.touchPoint,
  });

  final ui.Rect rect;
  final double refractionStrength;
  final double? thickness;
  final double pressAmount;
  final ui.Offset? touchPoint;
}

void main() {
  test('render preview PNGs', () async {
    final program = await LiquidGlassShader.load();
    expect(program, isNotNull, reason: 'shader failed to compile');

    // 1. Backdrop -> engine blur, two strengths by row.
    final scene =
        await _recordBackdrop().toImage(kSceneW.round(), kSceneH.round());
    final blurredLight =
        await _blurred(scene, 6 * kScale); // top row: sigma 6 logical
    final blurredHeavy =
        await _blurred(scene, 12 * kScale); // bottom row: sigma 12 logical

    // 2. Glass blocks: default / strong refraction / thin bevel / pressed.
    const blocksTop = [
      _GlassSpec(ui.Rect.fromLTWH(80, 140, kBlockW, kBlockH)),
      _GlassSpec(ui.Rect.fromLTWH(880, 140, kBlockW, kBlockH),
          refractionStrength: 2.0),
    ];
    const blocksBottom = [
      _GlassSpec(ui.Rect.fromLTWH(80, 520, kBlockW, kBlockH), thickness: 12),
      _GlassSpec(ui.Rect.fromLTWH(880, 520, kBlockW, kBlockH),
          pressAmount: 0.8, touchPoint: ui.Offset(160, 180)),
    ];

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const splitRect = ui.Rect.fromLTWH(0, 0, kSceneW, kRowSplitY);
    canvas.drawImageRect(blurredLight, splitRect, splitRect, ui.Paint());
    const bottomRect =
        ui.Rect.fromLTWH(0, kRowSplitY, kSceneW, kSceneH - kRowSplitY);
    canvas.drawImageRect(blurredHeavy, bottomRect, bottomRect, ui.Paint());

    Future<void> paintGlass(ui.Image row, _GlassSpec block) async {
      final shader = program!.fragmentShader();
      final crop = await _crop(row, block.rect);
      shader.setImageSampler(0, crop);
      LiquidGlassShader.bind(
        shader,
        size: block.rect.size,
        radius: kRadius,
        refractionStrength: block.refractionStrength,
        highlightIntensity: 1.0,
        tint: const ui.Color(0x14FFFFFF),
        refractionEnabled: true,
        highlightEnabled: true,
        chromaticAberrationEnabled: true,
        thickness: block.thickness,
        touchPoint: block.touchPoint,
        pressAmount: block.pressAmount,
      );
      canvas.save();
      canvas.translate(block.rect.left, block.rect.top);
      canvas.drawRect(ui.Offset.zero & block.rect.size,
          ui.Paint()..shader = shader);
      canvas.restore();
    }

    for (final block in blocksTop) {
      await paintGlass(blurredLight, block);
    }
    for (final block in blocksBottom) {
      await paintGlass(blurredHeavy, block);
    }

    // 3. Encode and write.
    final image = await recorder
        .endRecording()
        .toImage(kSceneW.round(), kSceneH.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final file = File('build/preview/liquid_glass_preview.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    expect(file.lengthSync(), greaterThan(10000),
        reason: 'PNG suspiciously small — shader output may be blank');
  });
}
