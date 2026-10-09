import 'package:flutter/material.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  LiquidGlassQuality _quality = LiquidGlassQuality.high;
  int _navIndex = 0;

  static const _gradients = [
    [Color(0xFFFF5F6D), Color(0xFFFFC371)],
    [Color(0xFF4776E6), Color(0xFF8E54E9)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFF654EA3), Color(0xFFEAAFC8)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scrolling colorful gradient + grid background.
          CustomPaint(
            painter: _GridPainter(),
            size: Size.infinite,
          ),
          ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 240),
            itemCount: 12,
            itemBuilder: (context, i) {
              final colors = _gradients[i % _gradients.length];
              return Container(
                height: 140,
                margin: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              );
            },
          ),

          // Quality switch.
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SegmentedButton<LiquidGlassQuality>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white70,
                    selectedForegroundColor: Colors.white,
                  ),
                  segments: const [
                    ButtonSegment(
                        value: LiquidGlassQuality.high, label: Text('High')),
                    ButtonSegment(
                        value: LiquidGlassQuality.medium,
                        label: Text('Medium')),
                    ButtonSegment(
                        value: LiquidGlassQuality.low, label: Text('Low')),
                  ],
                  selected: {_quality},
                  onSelectionChanged: (s) =>
                      setState(() => _quality = s.first),
                ),
              ),
            ),
          ),

          // Card.
          Positioned(
            top: 140,
            left: 32,
            right: 32,
            child: LiquidGlassCard(
              quality: _quality,
              shadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
              ],
              child: const Text(
                'LiquidGlassCard\n滚动背景透过玻璃产生折射与高光',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // Button.
          Align(
            alignment: const Alignment(0, 0.55),
            child: LiquidGlassButton(
              quality: _quality,
              onPressed: () {},
              child: const Text(
                '按住我试试',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Navigation bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: LiquidGlassNavigationBar(
                quality: _quality,
                currentIndex: _navIndex,
                onItemSelected: (i) => setState(() => _navIndex = i),
                items: const [
                  Icon(Icons.home_rounded, color: Colors.white),
                  Icon(Icons.search_rounded, color: Colors.white),
                  Icon(Icons.favorite_rounded, color: Colors.white),
                  Icon(Icons.person_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF202028));
    final paint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    const step = 48.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
