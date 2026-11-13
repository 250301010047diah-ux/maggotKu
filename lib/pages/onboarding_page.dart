import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_pages.dart';
import '../audio/app_sounds.dart';

class _Slide {
  const _Slide(this.tag, this.title, this.body, this.colors, this.chips);
  final String tag, title, body;
  final List<Color> colors;
  final List<(IconData, String)> chips;
}

const _slides = [
  _Slide(
    'Selamat datang',
    'Halo, aku Maggi!',
    'Teman kecilmu untuk mengelola budidaya maggot BSF — dari kandang sampai panen, semuanya rapi di satu tempat.',
    [Color(0xFFF7F6F4), Color(0xFFFFE9DA)],
    [
      (Icons.spa_rounded, 'Budidaya'),
      (Icons.warehouse_rounded, 'Kandang'),
      (Icons.eco_rounded, 'Ramah lingkungan'),
    ],
  ),
  _Slide(
    'Pantau',
    'Semua terpantau,\nsetiap hari',
    'Catat pakan dan panen dalam hitungan detik. Grafik cantik membantumu melihat perkembangan maggot.',
    [Color(0xFFF4F3F1), Color(0xFFEDEBE8)],
    [
      (Icons.bar_chart_rounded, 'Grafik'),
      (Icons.restaurant_rounded, 'Pakan'),
      (Icons.agriculture_rounded, 'Panen'),
    ],
  ),
  _Slide(
    'Bisnis',
    'Jual & lihat\nuntungmu tumbuh',
    'Kelola penjualan maggot dan kasgot, pantau pendapatan serta pembeli setiamu.',
    [Color(0xFFFFF1E7), Color(0xFFFFDCC6)],
    [
      (Icons.payments_rounded, 'Penjualan'),
      (Icons.trending_up_rounded, 'Pendapatan'),
      (Icons.people_alt_rounded, 'Pembeli'),
    ],
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.replay = false});

  /// true jika dibuka ulang dari halaman Akun.
  final bool replay;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _pc = PageController();
  double _page = 0;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _page = _pc.page ?? 0));
  }

  @override
  void dispose() {
    _pc.dispose();
    _float.dispose();
    super.dispose();
  }

  void _finish() {
    AppScope.of(context).onboardingDone = true;
    if (widget.replay) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _next() {
    AppSounds.onboarding();
    if (_page.round() >= _slides.length - 1) {
      _finish();
    } else {
      _pc.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _page.round().clamp(0, _slides.length - 1);
    final last = i == _slides.length - 1;
    final a = _page.floor().clamp(0, _slides.length - 1);
    final b = _page.ceil().clamp(0, _slides.length - 1);
    final t = _page - _page.floor();
    Color mix(int k) =>
        Color.lerp(_slides[a].colors[k], _slides[b].colors[k], t)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              mix(0).withValues(alpha: 0.9),
              mix(1).withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                child: Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: emerald, size: 22),
                    const SizedBox(width: 6),
                    const Text(
                      'MaggotKu',
                      style: TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: emerald,
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: last ? 0 : 1,
                      child: TextButton(
                        onPressed: last ? null : _finish,
                        child: const Text('Lewati'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _slides.length,
                  itemBuilder: (_, idx) => _SlideView(
                    slide: _slides[idx],
                    offset: _page - idx,
                    float: _float,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var j = 0; j < _slides.length; j++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: j == i ? 30 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: j == i
                                  ? emerald
                                  : emerald.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _next,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Row(
                          key: ValueKey(last),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(last ? 'Mulai Sekarang' : 'Lanjut'),
                            const SizedBox(width: 8),
                            Icon(
                              last
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.offset,
    required this.float,
  });
  final _Slide slide;
  final double offset;
  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    final o = offset.clamp(-1.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Transform.translate(
                  offset: Offset(-o * 140, 0),
                  child: Opacity(
                    opacity: (1 - o.abs()).clamp(0.0, 1.0),
                    child: _Illustration(slide: slide, float: float),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-o * 60, 0),
            child: Opacity(
              opacity: (1 - o.abs() * 1.6).clamp(0.0, 1.0),
              child: Column(
                children: [
                  Pill(
                    slide.tag.toUpperCase(),
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 31,
                      height: 1.1,
                      letterSpacing: -0.5,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.slide, required this.float});
  final _Slide slide;
  final Animation<double> float;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 310,
    child: AnimatedBuilder(
      animation: float,
      builder: (_, _) {
        final v = float.value * 2 * math.pi;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _circle(290, Colors.white.withValues(alpha: 0.32)),
            _circle(220, Colors.white.withValues(alpha: 0.55)),
            Transform.translate(
              offset: Offset(0, math.sin(v) * 6),
              child: const Mascot(size: 180),
            ),
            _chip(slide.chips[0], const Alignment(-1.0, -0.78), v),
            _chip(slide.chips[1], const Alignment(1.0, -0.15), v + 2),
            _chip(slide.chips[2], const Alignment(-0.8, 0.9), v + 4),
          ],
        );
      },
    ),
  );

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 40),
      ],
    ),
  );

  Widget _chip((IconData, String) c, Alignment al, double v) => Align(
    alignment: al,
    child: Transform.translate(
      offset: Offset(0, math.sin(v) * 9),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1C1C1E),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBubble(c.$1, size: 30),
            const SizedBox(width: 8),
            Text(
              c.$2,
              style: const TextStyle(
                fontFamily: headFont,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
