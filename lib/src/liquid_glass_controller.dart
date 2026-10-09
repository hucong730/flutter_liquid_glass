import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Holds the press/drag deformation state for a [LiquidGlass] widget and
/// animates the spring-back on release.
///
/// Gestures feed [press] / [updateDrag]; [release] starts a spring that
/// decays [pressAmount] back to 0. The shader never sees animation logic,
/// only the resulting uniform values.
///
/// While idle (no touch, spring settled) the controller produces no frame
/// callbacks and the deformation uniforms stay 0.
class LiquidGlassController extends ChangeNotifier {
  LiquidGlassController({SpringDescription? spring})
      : _spring = spring ??
            const SpringDescription(mass: 1, stiffness: 300, damping: 26);

  final SpringDescription _spring;

  double _pressAmount = 0;
  Offset? _touchPoint;
  Offset _dragVelocity = Offset.zero;

  Ticker? _ticker;
  SpringSimulation? _springSimulation;

  /// 0 when idle, 1 while fully pressed. Springs back to 0 on [release].
  double get pressAmount => _pressAmount;

  /// Touch point in widget-local px, null while idle.
  Offset? get touchPoint => _touchPoint;

  /// Latest drag offset in px (drives the viscous stretch deformation).
  Offset get dragVelocity => _dragVelocity;

  /// Whether the spring animation is currently running.
  bool get isAnimating => _ticker?.isActive ?? false;

  /// Begin a press at [at] (widget-local px).
  void press(Offset at) {
    _stopSpring();
    _touchPoint = at;
    _pressAmount = 1;
    _dragVelocity = Offset.zero;
    notifyListeners();
  }

  /// Update the drag deformation while moving.
  void updateDrag(Offset velocity, [Offset? at]) {
    _dragVelocity = velocity;
    if (at != null) _touchPoint = at;
    notifyListeners();
  }

  /// Release the press; the press amount springs back to 0.
  void release() {
    _dragVelocity = Offset.zero;
    notifyListeners();
    if (_pressAmount <= 0) {
      _pressAmount = 0;
      _touchPoint = null;
      return;
    }
    _springSimulation = SpringSimulation(_spring, _pressAmount, 0, 0);
    _ticker ??= Ticker(_onSpringTick);
    _ticker!.start();
  }

  void _onSpringTick(Duration elapsed) {
    final sim = _springSimulation;
    if (sim == null) return;
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _pressAmount = sim.x(seconds).clamp(0.0, 1.0);
    if (sim.isDone(seconds)) {
      _pressAmount = 0;
      _touchPoint = null;
      _stopSpring();
    }
    notifyListeners();
  }

  void _stopSpring() {
    _springSimulation = null;
    _ticker?.stop();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }
}
