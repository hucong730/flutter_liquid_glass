import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/src/liquid_glass_geometry.dart';

void main() {
  group('edgeWidth', () {
    test('scales with shortest side and clamps', () {
      expect(LiquidGlassGeometry.edgeWidth(const Size(100, 100)), 18.0);
      expect(LiquidGlassGeometry.edgeWidth(const Size(20, 200)), 6.0);
      expect(LiquidGlassGeometry.edgeWidth(const Size(50, 50)), 9.0);
    });
  });

  group('effectiveRadius', () {
    test('clamps to half the shortest side', () {
      expect(LiquidGlassGeometry.effectiveRadius(20, const Size(200, 100)),
          20.0);
      expect(LiquidGlassGeometry.effectiveRadius(80, const Size(200, 100)),
          50.0);
    });
  });

  group('sdRoundedBox', () {
    const half = Size(50, 50);

    test('negative inside, zero on edge, positive outside', () {
      expect(
          LiquidGlassGeometry.sdRoundedBox(Offset.zero, half, 10),
          lessThan(0));
      expect(
          LiquidGlassGeometry.sdRoundedBox(const Offset(50, 0), half, 10),
          closeTo(0, 1e-9));
      expect(
          LiquidGlassGeometry.sdRoundedBox(const Offset(60, 0), half, 10),
          closeTo(10, 1e-9));
    });

    test('corner distance is exact for a sharp corner sample', () {
      // Outside the corner arc the distance is euclidean to the arc center.
      final d = LiquidGlassGeometry.sdRoundedBox(
          const Offset(50, 50), half, 10);
      expect(d, closeTo(10 * 1.41421356 - 10, 1e-6));
    });
  });

  group('edgeHeight', () {
    const size = Size(100, 100); // edgeWidth = 18

    test('0 at the edge, 1 deep inside', () {
      expect(LiquidGlassGeometry.edgeHeight(0, size), 0.0);
      expect(LiquidGlassGeometry.edgeHeight(5, size), 0.0);
      expect(LiquidGlassGeometry.edgeHeight(-18, size), 1.0);
      expect(LiquidGlassGeometry.edgeHeight(-100, size), 1.0);
    });

    test('monotonic through the band', () {
      final a = LiquidGlassGeometry.edgeHeight(-4, size);
      final b = LiquidGlassGeometry.edgeHeight(-9, size);
      final c = LiquidGlassGeometry.edgeHeight(-14, size);
      expect(a, lessThan(b));
      expect(b, lessThan(c));
    });
  });
}
