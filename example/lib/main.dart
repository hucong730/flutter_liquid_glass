import 'package:flutter/material.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() => runApp(const ShowcaseApp());

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ShowcasePage(),
    );
  }
}

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  LiquidGlassQuality _quality = LiquidGlassQuality.high;
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fixed grid backdrop; the colorful section panels scroll above it,
          // so the floating navigation bar keeps refracting new content.
          const Positioned.fill(child: _GridBackground()),
          ListView(
            padding: const EdgeInsets.only(top: 132, bottom: 140),
            children: [
              const _Header(),
              _CardSection(quality: _quality),
              _ButtonSection(quality: _quality),
              _RefractionSection(quality: _quality),
              _SharedControllerSection(quality: _quality),
              _StaticGlassSection(quality: _quality),
            ],
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

          // Navigation bar floats above the scrolling content.
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liquid Glass Showcase',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Scroll to watch refraction and blur react to the moving content.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// A titled section with a colorful gradient panel behind the demo widgets.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.colors,
    required this.child,
    this.striped = false,
  });

  final String title;
  final String description;
  final List<Color> colors;
  final Widget child;

  /// Paint high-contrast stripes behind the demo so refraction is obvious.
  final bool striped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  if (striped)
                    Positioned.fill(child: CustomPaint(painter: _StripesPainter())),
                  Padding(padding: const EdgeInsets.all(24), child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.quality});

  final LiquidGlassQuality quality;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'LiquidGlassCard',
      description:
          'A non-interactive glass card. The variant below uses wider corners '
          'and a drop shadow behind the glass.',
      colors: const [Color(0xFF4776E6), Color(0xFF8E54E9)],
      child: Column(
        children: [
          LiquidGlassCard(
            quality: quality,
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Default card — 20 px corners, no shadow.',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LiquidGlassCard(
            quality: quality,
            borderRadius: 36,
            tint: const Color(0x3390CAF9),
            shadow: const [
              BoxShadow(
                  color: Colors.black38,
                  blurRadius: 24,
                  offset: Offset(0, 10)),
            ],
            child: const Row(
              children: [
                Icon(Icons.style, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Variant — 36 px corners, blue tint, drop shadow.',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonSection extends StatefulWidget {
  const _ButtonSection({required this.quality});

  final LiquidGlassQuality quality;

  @override
  State<_ButtonSection> createState() => _ButtonSectionState();
}

class _ButtonSectionState extends State<_ButtonSection> {
  int _pressCount = 0;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'LiquidGlassButton',
      description:
          'Interactive glass buttons. Press and hold to feel the dimple, '
          'release to watch the spring-back.',
      colors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LiquidGlassButton(
                quality: widget.quality,
                onPressed: () => setState(() => _pressCount++),
                child: const Text(
                  'Press me',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
              ),
              // Variant: the preset button fixes its corner radius at 24, so
              // this pill uses the core LiquidGlass container directly.
              LiquidGlass(
                quality: widget.quality,
                borderRadius: 40,
                tint: const Color(0x1AFFFFFF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                onTap: () => setState(() => _pressCount++),
                child: const Text(
                  'Pill variant (40 px corners)',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Tapped $_pressCount times',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RefractionSection extends StatelessWidget {
  const _RefractionSection({required this.quality});

  final LiquidGlassQuality quality;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Custom parameters',
      description:
          'Core LiquidGlass containers with different refractionStrength, '
          'tint, borderRadius and highlightIntensity side by side.',
      colors: const [Color(0xFFFC466B), Color(0xFF3F5EFB)],
      striped: true,
      child: Column(
        children: [
          Row(
            children: [
              for (final (label, strength) in [
                ('Weak 0.25', 0.25),
                ('Default 1.0', 1.0),
                ('Strong 2.0', 2.0),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: LiquidGlass(
                      quality: quality,
                      interactive: false,
                      refractionStrength: strength,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final (label, tint) in [
                ('White 8%', const Color(0x14FFFFFF)),
                ('Blue 20%', const Color(0x332196F3)),
                ('Amber 20%', const Color(0x33FFC107)),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: LiquidGlass(
                      quality: quality,
                      interactive: false,
                      tint: tint,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: LiquidGlass(
                    quality: quality,
                    interactive: false,
                    borderRadius: 8,
                    highlightIntensity: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: const Text(
                      'Radius 8, highlight 0',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: LiquidGlass(
                    quality: quality,
                    interactive: false,
                    borderRadius: 32,
                    highlightIntensity: 2,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: const Text(
                      'Radius 32, highlight 2',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SharedControllerSection extends StatefulWidget {
  const _SharedControllerSection({required this.quality});

  final LiquidGlassQuality quality;

  @override
  State<_SharedControllerSection> createState() =>
      _SharedControllerSectionState();
}

class _SharedControllerSectionState extends State<_SharedControllerSection> {
  final LiquidGlassController _shared = LiquidGlassController();

  @override
  void dispose() {
    _shared.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'External LiquidGlassController',
      description:
          'Both chips share one controller. Hold the pad below (or drag on '
          'it) to deform them in sync.',
      colors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final label in ['Chip A', 'Chip B'])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LiquidGlass(
                    quality: widget.quality,
                    interactive: false,
                    controller: _shared,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Text(
                      label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Listener(
            onPointerDown: (e) => _shared.press(e.localPosition),
            onPointerMove: (e) =>
                _shared.updateDrag(e.delta, e.localPosition),
            onPointerUp: (_) => _shared.release(),
            onPointerCancel: (_) => _shared.release(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'PRESS & HOLD HERE',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticGlassSection extends StatelessWidget {
  const _StaticGlassSection({required this.quality});

  final LiquidGlassQuality quality;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Static display glass',
      description:
          'interactive: false — no gestures, no deformation, pure looks.',
      colors: const [Color(0xFF654EA3), Color(0xFFEAAFC8)],
      child: Center(
        child: LiquidGlass(
          quality: quality,
          interactive: false,
          borderRadius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ac_unit, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Just here to look pretty',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
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

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x2EFFFFFF);
    const step = 24.0;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint
        ..strokeWidth = 8);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => false;
}
