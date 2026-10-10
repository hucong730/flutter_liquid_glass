import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_fx/src/quality.dart';

void main() {
  group('LiquidGlassQuality scales', () {
    test('blur scale per tier', () {
      expect(LiquidGlassQualityParams.blurScale(LiquidGlassQuality.high), 1.0);
      expect(
          LiquidGlassQualityParams.blurScale(LiquidGlassQuality.medium), 0.7);
      expect(LiquidGlassQualityParams.blurScale(LiquidGlassQuality.low), 0.5);
    });

    test('refraction scale per tier', () {
      expect(
          LiquidGlassQualityParams.refractionScale(LiquidGlassQuality.high),
          1.0);
      expect(
          LiquidGlassQualityParams.refractionScale(LiquidGlassQuality.medium),
          0.5);
      expect(LiquidGlassQualityParams.refractionScale(LiquidGlassQuality.low),
          0.0);
    });

    test('highlight scale per tier', () {
      expect(
          LiquidGlassQualityParams.highlightScale(LiquidGlassQuality.high),
          1.0);
      expect(
          LiquidGlassQualityParams.highlightScale(LiquidGlassQuality.medium),
          0.5);
      expect(LiquidGlassQualityParams.highlightScale(LiquidGlassQuality.low),
          0.0);
    });
  });

  group('resolution', () {
    test('defaults follow the tier multiplicatively', () {
      expect(
          LiquidGlassQualityParams.resolveBlurSigma(
              LiquidGlassQuality.high, null),
          12.0);
      expect(
          LiquidGlassQualityParams.resolveBlurSigma(
              LiquidGlassQuality.medium, null),
          closeTo(8.4, 1e-9));
      expect(
          LiquidGlassQualityParams.resolveBlurSigma(
              LiquidGlassQuality.low, null),
          6.0);
      expect(
          LiquidGlassQualityParams.resolveRefractionStrength(
              LiquidGlassQuality.low, null),
          0.0);
      expect(
          LiquidGlassQualityParams.resolveHighlightIntensity(
              LiquidGlassQuality.medium, null),
          0.5);
    });

    test('explicit parameters win over tier defaults', () {
      expect(
          LiquidGlassQualityParams.resolveBlurSigma(
              LiquidGlassQuality.low, 20),
          20.0);
      expect(
          LiquidGlassQualityParams.resolveRefractionStrength(
              LiquidGlassQuality.low, 1.5),
          1.5);
      expect(
          LiquidGlassQualityParams.resolveHighlightIntensity(
              LiquidGlassQuality.low, 2),
          2.0);
    });
  });

  group('deformation', () {
    test('enabled for high/medium, disabled for low', () {
      expect(
          LiquidGlassQualityParams.deformationEnabled(LiquidGlassQuality.high),
          isTrue);
      expect(
          LiquidGlassQualityParams.deformationEnabled(
              LiquidGlassQuality.medium),
          isTrue);
      expect(
          LiquidGlassQualityParams.deformationEnabled(LiquidGlassQuality.low),
          isFalse);
    });
  });
}
