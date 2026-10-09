import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';
import 'package:liquid_glass_example/main.dart';

void main() {
  testWidgets('demo app builds all three glass widgets', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.byType(LiquidGlassButton), findsOneWidget);
    expect(find.byType(LiquidGlassCard), findsOneWidget);
    expect(find.byType(LiquidGlassNavigationBar), findsOneWidget);

    // Quality switch flips the tier.
    await tester.tap(find.text('Low'));
    await tester.pump();
    final card = tester.widget<LiquidGlassCard>(find.byType(LiquidGlassCard));
    expect(card.quality, LiquidGlassQuality.low);
  });
}
