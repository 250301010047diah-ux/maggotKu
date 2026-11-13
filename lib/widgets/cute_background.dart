import 'package:flutter/material.dart';

/// Latar minimalis: abu-abu hangat yang lembut, cahaya oranye samar,
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
              colors: [Color(0xFFF7F6F4), Color(0xFFEDEBE8)],
            ),
          ),
        ),
      ),
      // cahaya hangat di pojok kanan atas
      Positioned(
        top: -160,
        right: -140,
        child: _glow(420, const Color(0x40FFB088)),
      ),
      // cahaya krem maggot di kiri tengah
      Positioned(
        top: 300,
        left: -180,
        child: _glow(380, const Color(0x55FFE7D1)),
      ),
      // ilustrasi kompos & daun, sangat samar
      Positioned.fill(
        child: Opacity(
          opacity: 0.28,
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
