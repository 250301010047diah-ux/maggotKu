import 'package:flutter/material.dart';

/// Latar minimalis: kertas hangat, pola titik halus, cahaya ember samar,
/// dan ilustrasi daun/kompos tipis di bawah sebagai unsur maggot.
class CuteBackground extends StatelessWidget {
  const CuteBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6F5F1), Color(0xFFECEAE4)],
            ),
          ),
        ),
      ),
      const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      // cahaya ember di pojok kanan atas
      Positioned(
        top: -180,
        right: -160,
        child: _glow(440, const Color(0x33FF5A1F)),
      ),
      // cahaya krem maggot di kiri tengah
      Positioned(
        top: 320,
        left: -200,
        child: _glow(400, const Color(0x55FFE3C7)),
      ),
      // ilustrasi kompos & daun, sangat samar
      Positioned.fill(
        child: Opacity(
          opacity: 0.18,
          child: Image.asset(
            'assets/images/image/Soft sage foliage on ivory.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
      child,
    ],
  );

  static Widget _glow(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x0F0F0F11);
    const step = 22.0;
    for (var y = step; y < size.height * 0.45; y += step) {
      final fade = 1 - y / (size.height * 0.45);
      p.color = Color.fromRGBO(15, 15, 17, 0.07 * fade);
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
