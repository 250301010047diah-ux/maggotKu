import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/api.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import 'charts.dart';
import 'glyphs.dart';
import '../audio/app_sounds.dart';

export 'glyphs.dart';

// =====================================================================
// Navigasi, dialog & validasi
// =====================================================================
void openPage(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirm(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Mascot(mood: MaggotMood.sulky, size: 90),
        title: const Text('Yakin, nih?'),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ya, lanjut'),
          ),
        ],
      ),
    ) ??
    false;

/// Jalankan aksi simpan/hapus. Saat online menampilkan loading, dan bila
/// server menolak (mis. stok kurang / tidak ada internet) pesannya
/// ditampilkan. Mengembalikan true bila berhasil.
Future<bool> kirim(BuildContext context, Future<void> Function() action) async {
  final s = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  NavigatorState? nav;
  if (s.online) {
    nav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x590F0F11),
      builder: (_) =>
          const PopScope(canPop: false, child: Center(child: _Loader())),
    );
  }
  try {
    await action();
    AppSounds.success();
    return true;
  } on ApiException catch (e) {
    AppSounds.warning();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  } finally {
    nav?.pop();
  }
}

/// Loader: kotak tinta dengan cincin ember berputar.
class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => Container(
    width: 76,
    height: 76,
    decoration: BoxDecoration(
      color: emerald,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 30,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: const Center(
      child: SizedBox.square(
        dimension: 34,
        child: CircularProgressIndicator(
          strokeWidth: 3.5,
          strokeCap: StrokeCap.round,
          color: emeraldLight,
        ),
      ),
    ),
  );
}

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Wajib diisi' : null;
String? emailText(String? value) {
  if (requiredText(value) != null) return 'Email wajib diisi';
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!)
      ? null
      : 'Format email tidak valid';
}

String? positive(String? value) {
  final n = double.tryParse((value ?? '').replaceAll(',', '.'));
  return n == null || n <= 0 ? 'Masukkan angka lebih dari 0' : null;
}

double? number(String value) => double.tryParse(value.replaceAll(',', '.'));

Widget gap([double h = 12]) => SizedBox(height: h);

/// Teks kecil kapital berjarak lebar di atas judul.
Widget eyebrow(String text, {Color color = muted}) => Text(
  text.toUpperCase(),
  style: TextStyle(
    fontSize: 10.5,
    letterSpacing: 1.8,
    fontWeight: FontWeight.w700,
    color: color,
  ),
);

// =====================================================================
// Kerangka halaman
// =====================================================================
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.padding,
    this.onRefresh,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  /// Bila diisi, halaman bisa ditarik ke bawah untuk memuat ulang.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: padding ?? const EdgeInsets.fromLTRB(20, 8, 20, 130),
      children: children,
    );
    return SafeArea(
      bottom: false,
      child: onRefresh == null
          ? list
          : RefreshIndicator(
              color: emeraldLight,
              backgroundColor: emerald,
              onRefresh: onRefresh!,
              child: list,
            ),
    );
  }
}

/// Judul besar untuk halaman tab.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.eyebrowText, this.trailing});
  final String title;
  final String? eyebrowText;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => FadeSlideIn(
    child: Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrowText != null) ...[
                  Row(
                    children: [
                      const _PulseDot(),
                      const SizedBox(width: 8),
                      eyebrow(eyebrowText!),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 36,
                    height: 1,
                    letterSpacing: -1.4,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// Titik ember berdenyut (penanda "hidup").
class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 14,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 6 + 8 * _c.value,
            height: 6 + 8 * _c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emeraldLight.withValues(alpha: 0.35 * (1 - _c.value)),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: emeraldLight,
            ),
          ),
        ],
      ),
    ),
  );
}

/// AppBar transparan dengan tombol kembali bulat.
PreferredSizeWidget elegantAppBar(
  BuildContext context,
  String title, {
  List<Widget> actions = const [],
}) => AppBar(
  automaticallyImplyLeading: false,
  leadingWidth: 68,
  leading: Navigator.of(context).canPop()
      ? Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: CircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.maybePop(context),
            ),
          ),
        )
      : null,
  title: Text(title),
  actions: [...actions, const SizedBox(width: 16)],
);

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 30, bottom: 14),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: emeraldLight,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: headFont,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: ink,
            ),
          ),
        ),
        if (action != null)
          Pressable(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              decoration: BoxDecoration(
                color: emerald,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    action!,
                    style: const TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const AppIcon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: emeraldLight,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

// =====================================================================
// Animasi
// =====================================================================
/// Muncul memudar sambil naik & membesar sedikit; [delay] = urutan (×70 ms).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.offset = 30,
  });
  final Widget child;
  final int delay;
  final double offset;
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _base = 680, _step = 70;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _base + widget.delay * _step),
  )..forward();
  late final _start = widget.delay * _step / (_base + widget.delay * _step);
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Interval(_start, 1, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _s = CurvedAnimation(
    parent: _c,
    curve: Interval(_start, 1, curve: Curves.easeOutBack),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _a.value.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, widget.offset * (1 - _a.value)),
        child: Transform.scale(
          scale: 0.94 + 0.06 * _s.value,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    ),
  );
}

/// Membungkus widget agar sedikit mengecil saat ditekan.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 110 : 420),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Kartu yang miring 3D ke arah jari, dengan sorotan cahaya di titik
/// sentuh, lalu memantul kembali saat dilepas.
class TiltPress extends StatefulWidget {
  const TiltPress({
    super.key,
    required this.child,
    required this.radius,
    this.onTap,
    this.spotlight = const Color(0x33FF5A1F),
  });
  final Widget child;
  final double radius;
  final VoidCallback? onTap;
  final Color spotlight;
  @override
  State<TiltPress> createState() => _TiltPressState();
}

class _TiltPressState extends State<TiltPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Offset _pos = Offset.zero; // -1..1

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 620),
    );
  }
  Offset _px = Offset.zero;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(TapDownDetails d) {
    final box = context.size ?? Size.zero;
    if (box.isEmpty) return;
    setState(() {
      _px = d.localPosition;
      _pos = Offset(
        (d.localPosition.dx / box.width) * 2 - 1,
        (d.localPosition.dy / box.height) * 2 - 1,
      );
    });
    _c.forward();
  }

  void _up() => _c.reverse();

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final v = _c.status == AnimationStatus.reverse
              ? Curves.elasticOut.transform(_c.value)
              : Curves.easeOut.transform(_c.value);
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-_pos.dy * 0.09 * v)
            ..rotateY(_pos.dx * 0.09 * v);
          final sc = 1 - 0.025 * v;
          m.multiply(Matrix4.diagonal3Values(sc, sc, 1));
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                child!,
                if (_c.value > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.radius),
                        child: CustomPaint(
                          painter: _SpotPainter(
                            _px,
                            widget.spotlight.withValues(
                              alpha: widget.spotlight.a * _c.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SpotPainter extends CustomPainter {
  _SpotPainter(this.at, this.color);
  final Offset at;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.longestSide * 0.7;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_SpotPainter o) => o.at != at || o.color != color;
}

/// Animasi berulang bersama (satu ticker untuk satu kartu).
mixin _Loop<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  Duration get loopDuration;
  late final AnimationController loop;

  @override
  void initState() {
    super.initState();
    loop = AnimationController(vsync: this, duration: loopDuration)..repeat();
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

// =====================================================================
// Kartu
// =====================================================================
/// Kartu terang: permukaan putih bersih, garis tipis tegas, bayangan
/// lembut. Saat disentuh miring 3D + sorotan ember mengikuti jari.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.color,
    this.radius = 24,
    this.accent,
    this.glow = true,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding, margin;
  final Color? color;
  final double radius;

  /// Warna garis aksen tipis di sisi kiri (opsional).
  final Color? accent;

  /// Kilau tipis di tepi atas.
  final bool glow;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: TiltPress(
      onTap: onTap,
      radius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x140F0F11),
              blurRadius: 24,
              spreadRadius: -8,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              if (glow)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 1.2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00FF5A1F),
                          Color(0x66FF5A1F),
                          Color(0x00FF5A1F),
                        ],
                      ),
                    ),
                  ),
                ),
              if (accent != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: accent),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

enum CardTone { warm, ink }

/// Kartu hero yang "hidup": bingkai gradasi berputar, bola cahaya yang
/// melayang, kilau yang menyapu, dan pola titik halus.
class DarkCard extends StatefulWidget {
  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.tone = CardTone.warm,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final CardTone tone;

  @override
  State<DarkCard> createState() => _DarkCardState();
}

class _DarkCardState extends State<DarkCard>
    with SingleTickerProviderStateMixin, _Loop {
  @override
  Duration get loopDuration => const Duration(seconds: 7);

  static const _r = 30.0;

  @override
  Widget build(BuildContext context) {
    final warm = widget.tone == CardTone.warm;
    return TiltPress(
      onTap: widget.onTap,
      radius: _r,
      spotlight: const Color(0x40FFFFFF),
      child: AnimatedBuilder(
        animation: loop,
        builder: (_, child) {
          final t = loop.value * 2 * math.pi;
          return CustomPaint(
            foregroundPainter: _SpinBorderPainter(
              loop.value,
              _r,
              warm
                  ? const [
                      Color(0x00FFFFFF),
                      Color(0xCCFFFFFF),
                      Color(0x00FFFFFF),
                      Color(0x00FFFFFF),
                    ]
                  : const [
                      Color(0x00FF5A1F),
                      Color(0xFFFF5A1F),
                      Color(0xFFFFE3C7),
                      Color(0x00FF5A1F),
                    ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_r),
                gradient: warm ? warmGradient : inkGradient,
                boxShadow: [
                  BoxShadow(
                    color: warm
                        ? const Color(0x66FF5A1F)
                        : const Color(0x40000000),
                    blurRadius: 36,
                    spreadRadius: -6,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_r),
                child: Stack(
                  children: [
                    // pola titik halus
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DotGridPainter(
                          warm
                              ? const Color(0x1AFFFFFF)
                              : const Color(0x12FFFFFF),
                        ),
                      ),
                    ),
                    // bola cahaya melayang
                    Positioned(
                      left: -90 + 30 * math.cos(t),
                      top: -120 + 24 * math.sin(t),
                      child: _glow(
                        280,
                        warm
                            ? const Color(0x80FFD7B0)
                            : const Color(0x55FF5A1F),
                      ),
                    ),
                    Positioned(
                      right: -80 + 26 * math.sin(t),
                      bottom: -130 + 30 * math.cos(t),
                      child: _glow(
                        280,
                        warm
                            ? const Color(0x80B4260A)
                            : const Color(0x33FFE3C7),
                      ),
                    ),
                    // kilau menyapu
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _ShinePainter(loop.value)),
                      ),
                    ),
                    child!,
                  ],
                ),
              ),
            ),
          );
        },
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );
  }

  static Widget _glow(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

class _SpinBorderPainter extends CustomPainter {
  _SpinBorderPainter(this.t, this.radius, this.colors);
  final double t, radius;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = SweepGradient(
          colors: colors,
          stops: const [0, 0.12, 0.3, 1],
          transform: GradientRotation(t * 2 * math.pi),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SpinBorderPainter o) => o.t != t;
}

class _ShinePainter extends CustomPainter {
  _ShinePainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    // Menyapu di 35% awal siklus, sisanya diam.
    final p = (t / 0.35);
    if (p > 1) return;
    final x = -size.width * 0.6 + p * size.width * 2.2;
    final rect = Rect.fromLTWH(x, 0, size.width * 0.45, size.height);
    canvas.save();
    canvas.transform(
      (Matrix4.identity()
            ..translateByDouble(rect.center.dx, rect.center.dy, 0, 1)
            ..rotateZ(0.35)
            ..translateByDouble(-rect.center.dx, -rect.center.dy, 0, 1))
          .storage,
    );
    canvas.drawRect(
      rect.inflate(size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00FFFFFF), Color(0x26FFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShinePainter o) => o.t != t;
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const step = 16.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        // memudar ke kiri bawah
        if (x / size.width + (1 - y / size.height) < 0.9) continue;
        canvas.drawCircle(Offset(x, y), 0.9, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter o) => o.color != color;
}

class HeroStat extends StatelessWidget {
  const HeroStat(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: Colors.white60,
          ),
        ),
      ],
    ),
  );
}

class HeroDivider extends StatelessWidget {
  const HeroDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    color: Colors.white.withValues(alpha: 0.16),
  );
}

/// Teks angka yang "berguling" masuk saat nilainya berubah.
class RollingText extends StatelessWidget {
  const RollingText(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 420),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (c, a) => ClipRect(
      child: FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.6),
            end: Offset.zero,
          ).animate(a),
          child: c,
        ),
      ),
    ),
    child: Text(text, key: ValueKey(text), style: style),
  );
}

/// Kartu statistik: ubin ikon tinta + glyph ember, angka besar yang
/// berguling masuk, tren mini, dan garis ember yang tumbuh.
class KpiCard extends StatefulWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final List<double>? trend;
  final VoidCallback? onTap;

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard>
    with SingleTickerProviderStateMixin, _Loop {
  @override
  Duration get loopDuration => const Duration(seconds: 4);

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: widget.onTap,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // ubin ikon dengan cincin ember yang berdenyut
            AnimatedBuilder(
              animation: loop,
              builder: (_, child) {
                final v = Curves.easeOut.transform(
                  (loop.value * 2).clamp(0, 1),
                );
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 42 + 12 * v,
                      height: 42 + 12 * v,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15 + 4 * v),
                        border: Border.all(
                          color: emeraldLight.withValues(alpha: 0.35 * (1 - v)),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child!,
                  ],
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: inkGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: AppIcon(
                    widget.icon,
                    size: 22,
                    color: emeraldLight,
                    accent: widget.color.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (widget.trend != null)
              SizedBox(width: 58, child: Sparkline(values: widget.trend!))
            else if (widget.onTap != null)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ink, width: 1.3),
                ),
                child: const Center(
                  child: AppIcon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: ink,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RollingText(
            widget.value,
            style: const TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              height: 1.05,
              letterSpacing: -1,
              color: ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: muted,
          ),
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => FractionallySizedBox(
            widthFactor: 0.15 + 0.25 * v,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: emeraldLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Baris aktivitas / transaksi.
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingColor = ink,
    this.trailingSub,
    this.trailingSubColor = muted,
    this.onTap,
  });
  final Widget leading;
  final String title, subtitle;
  final String? trailing, trailingSub;
  final Color trailingColor, trailingSubColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.97,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trailing!,
                  style: TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                    color: trailingColor,
                  ),
                ),
                if (trailingSub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    trailingSub!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trailingSubColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

// =====================================================================
// Elemen kecil
// =====================================================================
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = const Color(0xFFFFE6DA),
    this.textColor = const Color(0xFFC8400E),
    this.icon,
  });
  final String text;
  final Color color, textColor;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppIcon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ],
    ),
  );
}

class IconBubble extends StatelessWidget {
  const IconBubble(
    this.icon, {
    super.key,
    this.color = sage,
    this.iconColor = emerald,
    this.size = 44,
  });
  final IconData icon;
  final Color color, iconColor;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.32),
      border: Border.all(color: hairline),
    ),
    child: Center(
      child: AppIcon(
        icon,
        size: size * 0.5,
        color: iconColor,
        accent: emeraldLight.withValues(alpha: 0.35),
      ),
    ),
  );
}

class EmojiBubble extends StatelessWidget {
  const EmojiBubble(this.emoji, {super.key, this.color = sage, this.size = 44});
  final String emoji;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.32),
      border: Border.all(color: hairline),
    ),
    child: Text(emoji, style: TextStyle(fontSize: size * 0.46)),
  );
}

class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = false,
    this.size = 44,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  final double size;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.86,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.36),
        color: dark ? Colors.white.withValues(alpha: 0.14) : Colors.white,
        border: dark ? null : Border.all(color: hairline),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x120F0F11),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: Center(
        child: AppIcon(
          icon,
          size: size * 0.46,
          color: dark ? Colors.white : ink,
          accent: emeraldLight.withValues(alpha: 0.4),
        ),
      ),
    ),
  );
}

/// Tombol pilihan dengan indikator tinta yang meluncur.
class SegmentedPills extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.dark = false,
    this.expand = false,
  });
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final bool dark, expand;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFF1EFEB),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          _wrap(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: i == index
                      ? (dark ? Colors.white : emerald)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: i == index && !dark
                      ? const [
                          BoxShadow(
                            color: Color(0x330F0F11),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  items[i],
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: i == index
                        ? (dark ? emerald : Colors.white)
                        : (dark ? Colors.white70 : muted),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _wrap(Widget w) => expand ? Expanded(child: w) : w;
}

/// Tombol aksi mengambang: kapsul tinta + bulatan ember berdenyut.
class GradientFab extends StatefulWidget {
  const GradientFab({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
    this.lift = true,
  });
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  /// Naikkan di atas navigasi bawah yang mengambang.
  final bool lift;

  @override
  State<GradientFab> createState() => _GradientFabState();
}

class _GradientFabState extends State<GradientFab>
    with SingleTickerProviderStateMixin, _Loop {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1800);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: widget.lift ? 92 : 0),
    child: Pressable(
      onTap: widget.onTap,
      scale: 0.92,
      child: Container(
        height: 58,
        padding: const EdgeInsets.fromLTRB(8, 0, 22, 0),
        decoration: BoxDecoration(
          gradient: inkGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: Color(0x33FF5A1F),
              blurRadius: 24,
              spreadRadius: -6,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: loop,
              builder: (_, child) {
                final v = Curves.easeOut.transform(loop.value);
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42 + 14 * v,
                      height: 42 + 14 * v,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14 + 5 * v),
                        color: emeraldLight.withValues(alpha: 0.4 * (1 - v)),
                      ),
                    ),
                    Transform.rotate(
                      angle: math.sin(loop.value * 2 * math.pi) * 0.08,
                      child: child,
                    ),
                  ],
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: emeraldLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: AppIcon(widget.icon, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: headFont,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// =====================================================================
// Maskot
// =====================================================================
enum MaggotMood { happy, sulky }

/// Maskot maggot beranimasi dari sprite sheet 4x2 (8 frame).
/// - happy: melambai & berkedip, berulang terus.
/// - sulky: ngambek, juga berulang terus.
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.mood = MaggotMood.happy, this.size = 120});
  final MaggotMood mood;
  final double size;

  static const _sheets = {
    MaggotMood.happy:
        'assets/images/image/Cream mascot waving and blinking.png',
    MaggotMood.sulky:
        'assets/images/image/Eight-frame sulky cream maggot animation.png',
  };

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  static const _cols = 4, _rows = 2, _frames = 8;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() => _c
    ..reset()
    ..repeat();

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _start();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final sheet = Image.asset(
      Mascot._sheets[widget.mood]!,
      width: size * _cols,
      height: size * _rows,
      fit: BoxFit.fill,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Center(
        child: AppIcon.glyph(
          Glyph.maggot,
          size: size * 0.5,
          color: emeraldLight,
        ),
      ),
    );
    // Align menjaga "jendela" sprite tetap persegi walau induknya
    // memaksa lebar penuh (misalnya slot ikon dialog), supaya frame
    // tetangga tidak ikut terlihat.
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: size,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _c,
            child: sheet,
            builder: (_, child) {
              final f = (_c.value * _frames).floor().clamp(0, _frames - 1);
              final col = f % _cols, row = f ~/ _cols;
              return OverflowBox(
                minWidth: size * _cols,
                maxWidth: size * _cols,
                minHeight: size * _rows,
                maxHeight: size * _rows,
                alignment: Alignment(
                  -1 + 2 * col / (_cols - 1),
                  -1 + 2 * row / (_rows - 1),
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedBorderPainter(),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          const Mascot(mood: MaggotMood.sulky, size: 96),
          const SizedBox(height: 12),
          const Text(
            'Masih kosong nih',
            style: TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.3,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      const Radius.circular(24),
    );
    canvas.drawRRect(rr, Paint()..color = const Color(0x99FFFFFF));
    final path = Path()..addRRect(rr);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x330F0F11);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

// =====================================================================
// Input
// =====================================================================
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Pressable(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onChanged(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hairline),
        ),
        child: Row(
          children: [
            const IconBubble(
              Icons.calendar_month_rounded,
              size: 38,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value == null ? 'Pilih tanggal' : tanggalPanjang(value!),
                    style: const TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            const AppIcon(Icons.expand_more_rounded, color: muted),
          ],
        ),
      ),
    ),
  );
}

/// Gaya teks dropdown agar sama dengan isian lain.
const dropdownStyle = TextStyle(fontFamily: bodyFont, fontSize: 15, color: ink);
