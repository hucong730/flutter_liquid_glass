import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  group('state machine (no ticking required)', () {
    test('press sets pressAmount and touchPoint', () {
      final c = LiquidGlassController();
      addTearDown(c.dispose);
      var notified = 0;
      c.addListener(() => notified++);

      c.press(const Offset(10, 20));

      expect(c.pressAmount, 1.0);
      expect(c.touchPoint, const Offset(10, 20));
      expect(c.dragVelocity, Offset.zero);
      expect(notified, 1);
    });

    test('updateDrag sets velocity and optional touch point', () {
      final c = LiquidGlassController();
      addTearDown(c.dispose);

      c.updateDrag(const Offset(3, -4), const Offset(5, 6));

      expect(c.dragVelocity, const Offset(3, -4));
      expect(c.touchPoint, const Offset(5, 6));
    });

    test('release from idle does not start the spring', () {
      final c = LiquidGlassController();
      addTearDown(c.dispose);

      c.release();

      expect(c.pressAmount, 0.0);
      expect(c.touchPoint, isNull);
      expect(c.isAnimating, isFalse);
    });
  });

  group('spring release', () {
    testWidgets('release springs pressAmount back to 0 and stops ticking',
        (tester) async {
      final c = LiquidGlassController();
      addTearDown(c.dispose);

      c.press(const Offset(10, 10));
      expect(c.pressAmount, 1.0);

      c.release();
      expect(c.isAnimating, isTrue);

      var sawDecay = false;
      for (var i = 0; i < 120 && c.isAnimating; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (c.pressAmount < 1.0) sawDecay = true;
      }

      expect(sawDecay, isTrue);
      expect(c.pressAmount, 0.0);
      expect(c.touchPoint, isNull);
      expect(c.isAnimating, isFalse);
    });

    testWidgets('no frame callbacks while idle', (tester) async {
      final c = LiquidGlassController();
      addTearDown(c.dispose);
      var notified = 0;
      c.addListener(() => notified++);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(notified, 0);
      expect(c.isAnimating, isFalse);
    });
  });
}
