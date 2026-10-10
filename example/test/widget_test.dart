import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';
import 'package:liquid_glass_example/main.dart';

void main() {
  testWidgets('showcase builds every section and tracks quality',
      (tester) async {
    await tester.pumpWidget(const ShowcaseApp());

    ScrollPosition scrollPosition() =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    // Deterministically jump the lazy ListView until [finder] is built.
    Future<void> scrollUntilFound(Finder finder) async {
      final pos = scrollPosition();
      while (finder.evaluate().isEmpty &&
          pos.pixels < pos.maxScrollExtent) {
        pos.jumpTo(pos.pixels + 400);
        await tester.pump();
      }
      expect(finder.evaluate().isNotEmpty, isTrue,
          reason: '$finder not found after scrolling the whole list');
    }

    // Always-on overlays.
    expect(find.byType(LiquidGlassNavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    // Card section is inside the initial viewport.
    expect(find.text('LiquidGlassCard'), findsOneWidget);
    expect(find.byType(LiquidGlassCard), findsNWidgets(2));

    // Button section: center it on screen, then exercise the counter.
    await scrollUntilFound(find.byType(LiquidGlassButton));
    var pos = scrollPosition();
    pos.jumpTo(pos.pixels +
        tester.getCenter(find.byType(LiquidGlassButton)).dy -
        300);
    await tester.pump();
    expect(find.text('Tapped 0 times'), findsOneWidget);
    await tester.tap(find.byType(LiquidGlassButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Tapped 1 times'), findsOneWidget);

    // Custom parameters section.
    await scrollUntilFound(find.text('Strong 2.0'));
    expect(find.text('Custom parameters'), findsOneWidget);
    expect(find.text('Weak 0.25'), findsOneWidget);
    expect(find.text('Amber 20%'), findsOneWidget);
    expect(find.text('Radius 32, highlight 2'), findsOneWidget);

    // Shared controller section.
    await scrollUntilFound(find.text('PRESS & HOLD HERE'));
    expect(find.text('External LiquidGlassController'), findsOneWidget);
    expect(find.text('Chip A'), findsOneWidget);
    expect(find.text('Chip B'), findsOneWidget);

    // Static glass section.
    await scrollUntilFound(find.text('Just here to look pretty'));
    expect(find.text('Static display glass'), findsOneWidget);

    // Quality switch propagates to all components.
    await tester.tap(find.text('Low'));
    await tester.pump();
    final navBar = tester.widget<LiquidGlassNavigationBar>(
        find.byType(LiquidGlassNavigationBar));
    expect(navBar.quality, LiquidGlassQuality.low);

    // Navigation bar selection.
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    final navBar2 = tester.widget<LiquidGlassNavigationBar>(
        find.byType(LiquidGlassNavigationBar));
    expect(navBar2.currentIndex, 1);
  });
}
