/// Quality tiers for the liquid glass effect.
///
/// Quality only applies *multiplicative* degradation to the default
/// parameters; explicitly provided parameters always win over the
/// quality-tier defaults.
enum LiquidGlassQuality {
  /// Full effect: refraction + highlight + deformation, blur sigma as-is.
  high,

  /// blurSigma × 0.7, weak refraction, simplified highlight, deformation on.
  medium,

  /// blurSigma × 0.5, shader only applies the tint overlay
  /// (no refraction / highlight / deformation).
  low,
}

/// Maps [LiquidGlassQuality] tiers to concrete effect parameters.
abstract final class LiquidGlassQualityParams {
  static const double defaultBlurSigma = 12.0;
  static const double defaultRefractionStrength = 1.0;
  static const double defaultHighlightIntensity = 1.0;

  /// Multiplicative blur scale per tier.
  static double blurScale(LiquidGlassQuality quality) {
    return switch (quality) {
      LiquidGlassQuality.high => 1.0,
      LiquidGlassQuality.medium => 0.7,
      LiquidGlassQuality.low => 0.5,
    };
  }

  /// Multiplicative refraction scale per tier (low disables refraction).
  static double refractionScale(LiquidGlassQuality quality) {
    return switch (quality) {
      LiquidGlassQuality.high => 1.0,
      LiquidGlassQuality.medium => 0.5,
      LiquidGlassQuality.low => 0.0,
    };
  }

  /// Multiplicative highlight scale per tier (low disables highlights).
  static double highlightScale(LiquidGlassQuality quality) {
    return switch (quality) {
      LiquidGlassQuality.high => 1.0,
      LiquidGlassQuality.medium => 0.5,
      LiquidGlassQuality.low => 0.0,
    };
  }

  /// Effective blur sigma. An explicit value wins over the tier default.
  static double resolveBlurSigma(LiquidGlassQuality quality, double? explicit) {
    return explicit ?? defaultBlurSigma * blurScale(quality);
  }

  /// Effective refraction strength. An explicit value wins over the tier.
  static double resolveRefractionStrength(
      LiquidGlassQuality quality, double? explicit) {
    return explicit ?? defaultRefractionStrength * refractionScale(quality);
  }

  /// Effective highlight intensity. An explicit value wins over the tier.
  static double resolveHighlightIntensity(
      LiquidGlassQuality quality, double? explicit) {
    return explicit ?? defaultHighlightIntensity * highlightScale(quality);
  }

  /// Whether press/drag deformation runs at this tier (off for low).
  static bool deformationEnabled(LiquidGlassQuality quality) {
    return quality != LiquidGlassQuality.low;
  }
}
