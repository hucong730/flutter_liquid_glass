import 'dart:math' as math;
import 'dart:ui';

/// Geometry parameters for the rounded-rectangle SDF used by the shader.
///
/// These mirror the formulas in `shaders/liquid_glass.frag` so widget code
/// and tests can reason about the same numbers.
abstract final class LiquidGlassGeometry {
  static const double minEdgeWidth = 6.0;
  static const double maxEdgeWidth = 18.0;
  static const double edgeWidthFraction = 0.18;

  /// Width of the refraction/highlight edge band in px.
  static double edgeWidth(Size size) {
    final shortest = math.min(size.width, size.height);
    return (shortest * edgeWidthFraction).clamp(minEdgeWidth, maxEdgeWidth);
  }

  /// Corner radius clamped so it never exceeds half the shortest side.
  static double effectiveRadius(double radius, Size size) {
    return math.min(radius, math.min(size.width, size.height) / 2);
  }

  /// Signed distance to a rounded box centered at the origin.
  ///
  /// [p] is the point relative to the box center, [halfSize] the half
  /// extents of the box and [radius] the corner radius. Negative inside.
  static double sdRoundedBox(Offset p, Size halfSize, double radius) {
    final qx = p.dx.abs() - halfSize.width + radius;
    final qy = p.dy.abs() - halfSize.height + radius;
    final outside = math.sqrt(math.max(qx, 0.0) * math.max(qx, 0.0) +
        math.max(qy, 0.0) * math.max(qy, 0.0));
    final inside = math.min(math.max(qx, qy), 0.0);
    return outside + inside - radius;
  }

  /// 1 deep inside the edge band, 0 at or outside the edge.
  static double edgeHeight(double signedDistance, Size size) {
    final band = edgeWidth(size);
    final t = (-signedDistance / band).clamp(0.0, 1.0);
    // smoothstep(0, 1, t)
    return t * t * (3 - 2 * t);
  }
}
