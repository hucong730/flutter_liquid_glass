import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red, Colors.blue]),
            ),
          ),
          Center(child: child),
        ],
      ),
    ),
  );
}

void main() {
  group('LiquidGlass structure', () {
    testWidgets('builds clip, repaint boundary and backdrop blur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const LiquidGlass(child: Text('glass'))),
      );

      expect(find.text('glass'), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
      // The fragment shader cannot compile in the test environment, so only
      // the inner blur backdrop filter is present.
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('interactive adds a gesture detector, non-interactive not',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const LiquidGlass(interactive: true, child: Text('a'))),
      );
      expect(
        find.descendant(
          of: find.byType(LiquidGlass),
          matching: find.byType(GestureDetector),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrap(const LiquidGlass(interactive: false, child: Text('b'))),
      );
      expect(
        find.descendant(
          of: find.byType(LiquidGlass),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('onTap fires', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(LiquidGlass(onTap: () => tapped++, child: const Text('tap'))),
      );
      await tester.tap(find.byType(LiquidGlass));
      expect(tapped, 1);
      // Let the release spring settle so no ticker is left active.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('gesture -> controller', () {
    testWidgets('press/move/release drives the provided controller',
        (tester) async {
      final controller = LiquidGlassController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(LiquidGlass(controller: controller, child: const Text('g'))),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LiquidGlass)),
      );
      await tester.pump();
      expect(controller.pressAmount, 1.0);
      expect(controller.touchPoint, isNotNull);

      await gesture.moveBy(const Offset(12, 4));
      await tester.pump();
      expect(controller.dragVelocity, isNot(Offset.zero));

      await gesture.up();
      expect(controller.isAnimating, isTrue);

      for (var i = 0; i < 120 && controller.isAnimating; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(controller.pressAmount, 0.0);
    });

    testWidgets('low quality disables deformation gestures', (tester) async {
      final controller = LiquidGlassController();
      addTearDown(controller.dispose);
      var tapped = false;
      await tester.pumpWidget(
        _wrap(LiquidGlass(
          quality: LiquidGlassQuality.low,
          controller: controller,
          onTap: () => tapped = true,
          child: const Text('g'),
        )),
      );

      await tester.tap(find.byType(LiquidGlass));
      await tester.pump();

      expect(tapped, isTrue);
      expect(controller.pressAmount, 0.0);
      expect(controller.touchPoint, isNull);
    });
  });

  group('preset widgets', () {
    testWidgets('LiquidGlassButton is interactive with 24px corners and taps',
        (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _wrap(LiquidGlassButton(
          onPressed: () => pressed++,
          child: const Text('ok'),
        )),
      );

      final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
      expect(glass.interactive, isTrue);
      expect(glass.borderRadius, 24);

      await tester.tap(find.byType(LiquidGlassButton));
      expect(pressed, 1);
      // Let the release spring settle so no ticker is left active.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('LiquidGlassCard is non-interactive with 20px corners',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const LiquidGlassCard(child: Text('card'))),
      );

      final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
      expect(glass.interactive, isFalse);
      expect(glass.borderRadius, 20);
    });

    testWidgets('LiquidGlassCard paints optional shadow', (tester) async {
      await tester.pumpWidget(
        _wrap(const LiquidGlassCard(
          shadow: [BoxShadow(blurRadius: 20)],
          child: Text('card'),
        )),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(LiquidGlassCard),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, hasLength(1));
    });

    testWidgets('LiquidGlassNavigationBar builds items and reports taps',
        (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        _wrap(LiquidGlassNavigationBar(
          items: const [Icon(Icons.home), Icon(Icons.search)],
          currentIndex: 1,
          onItemSelected: (i) => selected = i,
        )),
      );

      final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
      expect(glass.interactive, isFalse);
      expect(glass.borderRadius, 32); // capsule: height 64 / 2
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.byIcon(Icons.home));
      expect(selected, 0);
    });
  });
}
