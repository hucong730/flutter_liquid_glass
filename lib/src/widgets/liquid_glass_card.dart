import 'package:flutter/material.dart';

import '../liquid_glass.dart';
import '../quality.dart';

/// Prebuilt liquid glass card: non-interactive, 20px corners, optional shadow.
class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tint = const Color(0x14FFFFFF),
    this.refractionStrength,
    this.highlightIntensity,
    this.blurSigma,
    this.quality = LiquidGlassQuality.high,
    this.borderRadius = 20,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final double? refractionStrength;
  final double? highlightIntensity;
  final double? blurSigma;
  final LiquidGlassQuality quality;
  final double borderRadius;

  /// Optional drop shadow painted behind the glass.
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlass(
      borderRadius: borderRadius,
      interactive: false,
      padding: padding,
      tint: tint,
      refractionStrength: refractionStrength,
      highlightIntensity: highlightIntensity,
      blurSigma: blurSigma,
      quality: quality,
      child: child,
    );
    final shadow = this.shadow;
    if (shadow == null) return glass;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow,
      ),
      child: glass,
    );
  }
}
