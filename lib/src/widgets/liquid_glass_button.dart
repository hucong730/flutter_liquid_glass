import 'package:flutter/material.dart';

import '../liquid_glass.dart';
import '../liquid_glass_controller.dart';
import '../quality.dart';

/// Prebuilt liquid glass button: interactive, 24px corners, press feedback.
class LiquidGlassButton extends StatelessWidget {
  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.tint = const Color(0x14FFFFFF),
    this.refractionStrength,
    this.highlightIntensity,
    this.blurSigma,
    this.quality = LiquidGlassQuality.high,
    this.controller,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final double? refractionStrength;
  final double? highlightIntensity;
  final double? blurSigma;
  final LiquidGlassQuality quality;
  final LiquidGlassController? controller;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: 24,
      interactive: true,
      onTap: onPressed,
      padding: padding,
      tint: tint,
      refractionStrength: refractionStrength,
      highlightIntensity: highlightIntensity,
      blurSigma: blurSigma,
      quality: quality,
      controller: controller,
      child: child,
    );
  }
}
