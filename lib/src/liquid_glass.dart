import 'dart:ui';

import 'package:flutter/material.dart';

import 'liquid_glass_controller.dart';
import 'liquid_glass_shader.dart';
import 'quality.dart';

/// Core liquid glass container.
///
/// Renders [child] behind two nested backdrop filters clipped to the same
/// rounded rect: an inner engine blur, and an outer custom shader that adds
/// refraction, fresnel edge highlights, tint and press/drag deformation.
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.tint = const Color(0x14FFFFFF),
    this.refractionStrength,
    this.highlightIntensity,
    this.blurSigma,
    this.interactive = true,
    this.controller,
    this.quality = LiquidGlassQuality.high,
    this.padding,
    this.onTap,
    this.refractiveIndex = 1.5,
    this.chromaticAberration = 0.15,
    this.lightDirection = const Offset(-0.4472, -0.7154),
  });

  final Widget child;

  /// Corner radius of the glass shape in px.
  final double borderRadius;

  /// Translucent tint overlay (defaults to 8% white).
  final Color tint;

  /// Refraction strength 0..2. Null uses the quality-tier default.
  final double? refractionStrength;

  /// Edge highlight intensity 0..2. Null uses the quality-tier default.
  final double? highlightIntensity;

  /// Backdrop blur sigma. Null uses the quality-tier default.
  final double? blurSigma;

  /// Whether press/drag deformation gestures are handled.
  final bool interactive;

  /// External deformation state; an internal one is created when null.
  final LiquidGlassController? controller;

  /// Performance tier; only scales defaults, explicit parameters win.
  final LiquidGlassQuality quality;

  /// Padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Index of refraction of the simulated glass (1.5 ≈ real glass).
  final double refractiveIndex;

  /// RGB channel split along the refraction displacement. Applied on the
  /// high quality tier only; 0 disables.
  final double chromaticAberration;

  /// 2D direction the edge light comes from (normalized in the shader).
  final Offset lightDirection;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  LiquidGlassController? _ownedController;
  FragmentShader? _shader;

  LiquidGlassController get _effectiveController =>
      widget.controller ?? (_ownedController ??= LiquidGlassController());

  bool get _deformationEnabled =>
      widget.interactive &&
      LiquidGlassQualityParams.deformationEnabled(widget.quality);

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_onControllerChanged);
    LiquidGlassShader.load().then((_) {
      if (!mounted || !LiquidGlassShader.isLoaded) return;
      setState(() => _shader = LiquidGlassShader.createShader());
    });
  }

  @override
  void didUpdateWidget(LiquidGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController)
          ?.removeListener(_onControllerChanged);
      _effectiveController.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);
    _ownedController?.dispose();
    _ownedController = null;
    super.dispose();
  }

  void _handlePress(Offset position) {
    if (_deformationEnabled) _effectiveController.press(position);
  }

  void _handleDragMove(PointerMoveEvent event) {
    if (_deformationEnabled) {
      _effectiveController.updateDrag(event.delta, event.localPosition);
    }
  }

  void _handleRelease() {
    if (_deformationEnabled) _effectiveController.release();
  }

  @override
  Widget build(BuildContext context) {
    final blurSigma =
        LiquidGlassQualityParams.resolveBlurSigma(widget.quality, widget.blurSigma);
    final refractionStrength =
        LiquidGlassQualityParams.resolveRefractionStrength(
            widget.quality, widget.refractionStrength);
    final highlightIntensity =
        LiquidGlassQualityParams.resolveHighlightIntensity(
            widget.quality, widget.highlightIntensity);
    final controller = _effectiveController;

    Widget content = widget.child;
    final padding = widget.padding;
    if (padding != null) content = Padding(padding: padding, child: content);

    // Inner layer: engine blur of the backdrop.
    content = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: content,
    );

    // Outer layer: custom shader sampling the blurred backdrop.
    // Gracefully degrades to blur-only until/unless the shader compiles, and
    // on backends where shader image filters are unsupported (non-Impeller).
    final shader = ImageFilter.isShaderFilterSupported ? _shader : null;
    if (shader != null) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.width > 0 && size.height > 0) {
            LiquidGlassShader.bind(
              shader,
              size: size,
              radius: widget.borderRadius,
              refractionStrength: refractionStrength,
              highlightIntensity: highlightIntensity,
              tint: widget.tint,
              refractionEnabled: refractionStrength > 0,
              highlightEnabled: highlightIntensity > 0,
              chromaticAberrationEnabled:
                  widget.quality == LiquidGlassQuality.high &&
                      refractionStrength > 0 &&
                      widget.chromaticAberration > 0,
              refractiveIndex: widget.refractiveIndex,
              chromaticAberration: widget.chromaticAberration,
              lightDirection: widget.lightDirection,
              touchPoint: controller.touchPoint,
              pressAmount: controller.pressAmount,
              dragVelocity: controller.dragVelocity,
            );
          }
          return BackdropFilter(
            filter: ImageFilter.shader(shader),
            child: content,
          );
        },
      );
    }

    Widget result = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: content,
      ),
    );

    if (widget.interactive) {
      // Raw pointer events give immediate press feedback; tap gestures go
      // through the arena (TapGestureRecognizer defers onTapDown since
      // Flutter 3.35, so it can't drive press feedback).
      result = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _handlePress(e.localPosition),
        onPointerMove: _handleDragMove,
        onPointerUp: (_) => _handleRelease(),
        onPointerCancel: (_) => _handleRelease(),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          child: result,
        ),
      );
    }

    return result;
  }
}
