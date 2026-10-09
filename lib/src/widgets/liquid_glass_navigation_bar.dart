import 'package:flutter/material.dart';

import '../liquid_glass.dart';
import '../quality.dart';

/// Prebuilt capsule-shaped liquid glass navigation bar.
///
/// The glass itself is non-interactive (no deformation); item taps are
/// reported through [onItemSelected].
class LiquidGlassNavigationBar extends StatelessWidget {
  const LiquidGlassNavigationBar({
    super.key,
    required this.items,
    this.currentIndex = 0,
    this.onItemSelected,
    this.height = 64,
    this.tint = const Color(0x14FFFFFF),
    this.refractionStrength,
    this.highlightIntensity,
    this.blurSigma,
    this.quality = LiquidGlassQuality.high,
    this.selectedItemBackground = const Color(0x2EFFFFFF),
    this.itemPadding =
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  });

  /// Item widgets, typically icons or icon+label columns.
  final List<Widget> items;

  /// Index of the highlighted item.
  final int currentIndex;

  /// Called when an item is tapped.
  final ValueChanged<int>? onItemSelected;

  /// Bar height; the capsule corner radius is half of this.
  final double height;
  final Color tint;
  final double? refractionStrength;
  final double? highlightIntensity;
  final double? blurSigma;
  final LiquidGlassQuality quality;

  /// Background capsule color of the selected item.
  final Color selectedItemBackground;

  /// Padding inside each item.
  final EdgeInsetsGeometry itemPadding;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: height / 2,
      interactive: false,
      padding: const EdgeInsets.all(6),
      tint: tint,
      refractionStrength: refractionStrength,
      highlightIntensity: highlightIntensity,
      blurSigma: blurSigma,
      quality: quality,
      child: SizedBox(
        height: height - 12,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onItemSelected?.call(i),
                child: Container(
                  padding: itemPadding,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular((height - 12) / 2),
                    color: i == currentIndex
                        ? selectedItemBackground
                        : const Color(0x00000000),
                  ),
                  child: items[i],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
