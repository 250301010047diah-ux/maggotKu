import 'dart:math' as math;
import 'package:flutter/material.dart';

// =====================================================================
// MaggotKu Glyphs — ikon buatan sendiri.
// Gaya: garis tegas 2px (grid 24), ujung membulat, dengan isian duotone
// lembut. Semua digambar dengan CustomPainter, jadi tajam di ukuran apa
// pun dan tidak butuh file font/gambar.
//
// [AppIcon] bisa langsung menggantikan [Icon]: ikon Material yang sudah
// punya pasangan glyph akan digambar ulang, sisanya tetap pakai Material.
// =====================================================================

/// Kanvas glyph: grid 24×24.
class _G {
  _G(this.c, this.color, this.accent, double scale)
    : s = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      f = Paint()..color = accent,
      solid = Paint()..color = color {
    c.scale(scale);
  }
  final Canvas c;
  final Color color, accent;
  final Paint s, f, solid;

  void line(double x1, double y1, double x2, double y2) =>
      c.drawLine(Offset(x1, y1), Offset(x2, y2), s);

  void poly(List<double> p, {bool close = false, bool fill = false}) {
    final path = Path()..moveTo(p[0], p[1]);
    for (var i = 2; i < p.length; i += 2) {
      path.lineTo(p[i], p[i + 1]);
    }
    if (close) path.close();
    if (fill) c.drawPath(path, f);
    c.drawPath(path, s);
  }

  void rr(
    double l,
    double t,
    double r,
    double b,
    double rad, {
    bool fill = false,
  }) {
    final rect = RRect.fromLTRBR(l, t, r, b, Radius.circular(rad));
    if (fill) c.drawRRect(rect, f);
    c.drawRRect(rect, s);
  }

  void circle(double x, double y, double r, {bool fill = false}) {
    if (fill) c.drawCircle(Offset(x, y), r, f);
    c.drawCircle(Offset(x, y), r, s);
  }

  void dot(double x, double y, [double r = 1.3]) =>
      c.drawCircle(Offset(x, y), r, solid);

  void arc(double x, double y, double r, double start, double sweep) =>
      c.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: r),
        start,
        sweep,
        false,
        s,
      );

  void path(Path p, {bool fill = false}) {
    if (fill) c.drawPath(p, f);
    c.drawPath(p, s);
  }

  void fillPath(Path p) => c.drawPath(p, f);
  void solidPath(Path p) => c.drawPath(p, solid);
}

typedef _Draw = void Function(_G g);

/// Daftar glyph MaggotKu.
enum Glyph {
  home,
  sprout,
  feed,
  harvest,
  barn,
  coin,
  notebook,
  user,
  users,
  scale,
  clock,
  hourglass,
  receipt,
  pencil,
  mail,
  badge,
  trendUp,
  trendDown,
  lock,
  pin,
  trash,
  bolt,
  warning,
  camera,
  gallery,
  box,
  calculator,
  cycle,
  sparkle,
  arrowOut,
  arrowRight,
  chevronLeft,
  chevronDown,
  bell,
  bellRing,
  logout,
  plus,
  search,
  calendar,
  egg,
  chart,
  flag,
  filter,
  check,
  eye,
  eyeOff,
  sun,
  cloudCheck,
  crown,
  rocket,
  basket,
  share,
  image,
  dot,
  chat,
  wallet,
  phone,
  report,
  maggot,
  tag,
}

extension GlyphPaint on Glyph {
  _Draw get _draw => _glyphs[this]!;
}

final Map<Glyph, _Draw> _glyphs = {
  Glyph.home: (g) {
    g.poly([3.5, 11, 12, 3.8, 20.5, 11], fill: false);
    g.path(
      Path()
        ..moveTo(5.5, 9.6)
        ..lineTo(5.5, 19)
        ..quadraticBezierTo(5.5, 20.5, 7, 20.5)
        ..lineTo(17, 20.5)
        ..quadraticBezierTo(18.5, 20.5, 18.5, 19)
        ..lineTo(18.5, 9.6),
      fill: true,
    );
    g.rr(10, 14, 14, 20.5, 1.6);
  },
  Glyph.sprout: (g) {
    final l = Path()
      ..moveTo(12, 13)
      ..cubicTo(12, 8, 8.5, 5, 3.5, 5)
      ..cubicTo(3.5, 10, 7, 13, 12, 13)
      ..close();
    final r = Path()
      ..moveTo(12, 11)
      ..cubicTo(12, 6.5, 15, 3.5, 20.5, 3.5)
      ..cubicTo(20.5, 8.5, 17, 11, 12, 11)
      ..close();
    g.path(l, fill: true);
    g.path(r, fill: true);
    g.line(12, 11, 12, 20.5);
    g.line(8, 20.5, 16, 20.5);
  },
  Glyph.feed: (g) {
    // mangkuk + daun
    g.path(
      Path()
        ..moveTo(3, 12.5)
        ..lineTo(21, 12.5)
        ..cubicTo(21, 17.5, 17, 20.5, 12, 20.5)
        ..cubicTo(7, 20.5, 3, 17.5, 3, 12.5)
        ..close(),
      fill: true,
    );
    g.path(
      Path()
        ..moveTo(9, 12.5)
        ..cubicTo(8, 8, 10, 4.5, 14.5, 3.5)
        ..cubicTo(15.5, 8, 13.5, 11, 9, 12.5),
    );
    g.line(15, 12.5, 18.5, 7.5);
  },
  Glyph.harvest: (g) {
    // keranjang panen dengan maggot melengkung
    g.path(
      Path()
        ..moveTo(3, 10.5)
        ..lineTo(21, 10.5)
        ..lineTo(19.2, 19)
        ..quadraticBezierTo(18.9, 20.5, 17.4, 20.5)
        ..lineTo(6.6, 20.5)
        ..quadraticBezierTo(5.1, 20.5, 4.8, 19)
        ..close(),
      fill: true,
    );
    g.line(9, 14, 9, 17);
    g.line(15, 14, 15, 17);
    g.arc(12, 9, 4.6, math.pi * 1.05, math.pi * 0.9);
    g.dot(16.2, 7.2, 1.1);
  },
  Glyph.barn: (g) {
    g.poly([3, 10, 12, 3.5, 21, 10], fill: false);
    g.rr(5, 9, 19, 20.5, 1.5, fill: true);
    g.rr(9, 13, 15, 20.5, 0.8);
    g.line(9, 13, 15, 20.5);
    g.line(15, 13, 9, 20.5);
  },
  Glyph.coin: (g) {
    g.rr(2.5, 6, 21.5, 18, 3, fill: true);
    g.circle(12, 12, 3);
    g.dot(6, 12, 1.1);
    g.dot(18, 12, 1.1);
  },
  Glyph.notebook: (g) {
    g.rr(4.5, 3, 17.5, 21, 2.5, fill: true);
    g.line(8.5, 3, 8.5, 21);
    g.line(11.5, 8, 14.5, 8);
    g.line(11.5, 12, 14.5, 12);
    g.path(
      Path()
        ..moveTo(19.5, 9)
        ..lineTo(19.5, 17)
        ..lineTo(20.8, 19.2),
    );
  },
  Glyph.user: (g) {
    g.circle(12, 8, 4, fill: true);
    g.path(
      Path()
        ..moveTo(4, 20.5)
        ..cubicTo(4, 16, 7.5, 13.5, 12, 13.5)
        ..cubicTo(16.5, 13.5, 20, 16, 20, 20.5),
    );
  },
  Glyph.users: (g) {
    g.circle(9, 8.5, 3.6, fill: true);
    g.path(
      Path()
        ..moveTo(2.5, 20)
        ..cubicTo(2.5, 16, 5.5, 13.8, 9, 13.8)
        ..cubicTo(12.5, 13.8, 15.5, 16, 15.5, 20),
    );
    g.arc(16, 8.5, 3, -math.pi * 0.5, math.pi * 0.95);
    g.path(
      Path()
        ..moveTo(17.5, 14)
        ..cubicTo(19.8, 14.6, 21.5, 16.6, 21.5, 20),
    );
  },
  Glyph.scale: (g) {
    g.circle(12, 6, 2.4);
    g.path(
      Path()
        ..moveTo(6.5, 9.5)
        ..lineTo(17.5, 9.5)
        ..lineTo(20.5, 20.5)
        ..lineTo(3.5, 20.5)
        ..close(),
      fill: true,
    );
    g.line(10, 15, 14, 15);
  },
  Glyph.clock: (g) {
    g.circle(12, 12, 9, fill: true);
    g.poly([12, 7, 12, 12, 15.5, 14]);
  },
  Glyph.hourglass: (g) {
    g.line(5.5, 3, 18.5, 3);
    g.line(5.5, 21, 18.5, 21);
    g.path(
      Path()
        ..moveTo(7, 3)
        ..cubicTo(7, 8, 12, 9.5, 12, 12)
        ..cubicTo(12, 14.5, 7, 16, 7, 21),
    );
    g.path(
      Path()
        ..moveTo(17, 3)
        ..cubicTo(17, 8, 12, 9.5, 12, 12)
        ..cubicTo(12, 14.5, 17, 16, 17, 21),
    );
    g.fillPath(
      Path()
        ..moveTo(8.5, 21)
        ..cubicTo(9, 18, 12, 16.5, 12, 16.5)
        ..cubicTo(12, 16.5, 15, 18, 15.5, 21)
        ..close(),
    );
  },
  Glyph.receipt: (g) {
    g.poly(
      [
        5,
        3,
        19,
        3,
        19,
        21,
        16.7,
        19.5,
        14.3,
        21,
        12,
        19.5,
        9.7,
        21,
        7.3,
        19.5,
        5,
        21,
      ],
      close: true,
      fill: true,
    );
    g.line(8.5, 8, 15.5, 8);
    g.line(8.5, 12, 15.5, 12);
    g.line(8.5, 16, 12, 16);
  },
  Glyph.pencil: (g) {
    g.poly(
      [4, 20, 4.8, 15.8, 15.5, 5, 19, 8.5, 8.2, 19.2],
      close: true,
      fill: true,
    );
    g.line(13, 7.5, 16.5, 11);
    g.line(4, 20, 9, 20);
  },
  Glyph.mail: (g) {
    g.rr(3, 5, 21, 19, 3, fill: true);
    g.poly([3.5, 7, 12, 13, 20.5, 7]);
  },
  Glyph.badge: (g) {
    final p = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 - math.pi / 2;
      final r = i.isEven ? 9.5 : 7.8;
      final o = Offset(12 + r * math.cos(a), 12 + r * math.sin(a));
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    p.close();
    g.path(p, fill: true);
    g.poly([8.3, 12.2, 10.9, 14.8, 15.8, 9.6]);
  },
  Glyph.trendUp: (g) {
    g.poly([3, 17, 9, 11, 13, 14.5, 21, 6.5]);
    g.poly([15.5, 6.5, 21, 6.5, 21, 12]);
  },
  Glyph.trendDown: (g) {
    g.poly([3, 7, 9, 13, 13, 9.5, 21, 17.5]);
    g.poly([15.5, 17.5, 21, 17.5, 21, 12]);
  },
  Glyph.lock: (g) {
    g.rr(4.5, 10, 19.5, 21, 3, fill: true);
    g.path(
      Path()
        ..moveTo(8, 10)
        ..lineTo(8, 7.5)
        ..arcToPoint(const Offset(16, 7.5), radius: const Radius.circular(4))
        ..lineTo(16, 10),
    );
    g.line(12, 14.3, 12, 16.7);
  },
  Glyph.pin: (g) {
    g.path(
      Path()
        ..moveTo(12, 21.5)
        ..cubicTo(12, 21.5, 4.5, 14.8, 4.5, 9.5)
        ..arcToPoint(
          const Offset(19.5, 9.5),
          radius: const Radius.circular(7.5),
        )
        ..cubicTo(19.5, 14.8, 12, 21.5, 12, 21.5)
        ..close(),
      fill: true,
    );
    g.circle(12, 9.5, 2.6);
  },
  Glyph.trash: (g) {
    g.line(3.5, 6.5, 20.5, 6.5);
    g.poly([9, 6.5, 9.8, 3.5, 14.2, 3.5, 15, 6.5]);
    g.path(
      Path()
        ..moveTo(5.5, 6.5)
        ..lineTo(6.6, 19.2)
        ..quadraticBezierTo(6.8, 21, 8.6, 21)
        ..lineTo(15.4, 21)
        ..quadraticBezierTo(17.2, 21, 17.4, 19.2)
        ..lineTo(18.5, 6.5),
      fill: true,
    );
    g.line(10, 10.5, 10, 16.5);
    g.line(14, 10.5, 14, 16.5);
  },
  Glyph.bolt: (g) {
    g.poly(
      [13.5, 2.5, 4.5, 13.5, 11.5, 13.5, 10.5, 21.5, 19.5, 10.5, 12.5, 10.5],
      close: true,
      fill: true,
    );
  },
  Glyph.warning: (g) {
    g.path(
      Path()
        ..moveTo(10.3, 4)
        ..quadraticBezierTo(12, 1.2, 13.7, 4)
        ..lineTo(21.2, 17.4)
        ..quadraticBezierTo(22.6, 20.5, 19.5, 20.5)
        ..lineTo(4.5, 20.5)
        ..quadraticBezierTo(1.4, 20.5, 2.8, 17.4)
        ..close(),
      fill: true,
    );
    g.line(12, 9, 12, 13.5);
    g.dot(12, 17, 1.25);
  },
  Glyph.camera: (g) {
    g.path(
      Path()
        ..moveTo(3, 9)
        ..quadraticBezierTo(3, 7, 5, 7)
        ..lineTo(7.5, 7)
        ..lineTo(9, 4.5)
        ..lineTo(15, 4.5)
        ..lineTo(16.5, 7)
        ..lineTo(19, 7)
        ..quadraticBezierTo(21, 7, 21, 9)
        ..lineTo(21, 18)
        ..quadraticBezierTo(21, 20, 19, 20)
        ..lineTo(5, 20)
        ..quadraticBezierTo(3, 20, 3, 18)
        ..close(),
      fill: true,
    );
    g.circle(12, 13.2, 3.6);
  },
  Glyph.gallery: (g) {
    g.rr(3, 6, 18, 21, 2.5, fill: true);
    g.path(
      Path()
        ..moveTo(6.5, 3)
        ..lineTo(19, 3)
        ..quadraticBezierTo(21, 3, 21, 5)
        ..lineTo(21, 17.5),
    );
    g.poly([3.5, 18, 8, 13.5, 11, 16.5, 13, 14.5, 17.5, 19]);
    g.dot(13.5, 10, 1.3);
  },
  Glyph.box: (g) {
    g.poly(
      [12, 2.8, 20.5, 7.3, 20.5, 16.7, 12, 21.2, 3.5, 16.7, 3.5, 7.3],
      close: true,
      fill: true,
    );
    g.poly([3.8, 7.5, 12, 12, 20.2, 7.5]);
    g.line(12, 12, 12, 21);
    g.line(7.8, 5.1, 16.2, 9.6);
  },
  Glyph.calculator: (g) {
    g.rr(5, 2.5, 19, 21.5, 3, fill: true);
    g.rr(8, 5.5, 16, 9.5, 1);
    g.dot(9, 13.5);
    g.dot(12, 13.5);
    g.dot(15, 13.5);
    g.dot(9, 17.5);
    g.dot(12, 17.5);
    g.dot(15, 17.5);
  },
  Glyph.cycle: (g) {
    g.arc(12, 12, 8, -math.pi * 0.95, math.pi * 0.85);
    g.arc(12, 12, 8, math.pi * 0.05, math.pi * 0.85);
    g.poly([17.5, 3.6, 18.8, 6.6, 15.8, 7.6]);
    g.poly([6.5, 20.4, 5.2, 17.4, 8.2, 16.4]);
  },
  Glyph.sparkle: (g) {
    Path star(double x, double y, double r) => Path()
      ..moveTo(x, y - r)
      ..quadraticBezierTo(x, y, x + r, y)
      ..quadraticBezierTo(x, y, x, y + r)
      ..quadraticBezierTo(x, y, x - r, y)
      ..quadraticBezierTo(x, y, x, y - r)
      ..close();
    g.path(star(10, 13, 8), fill: true);
    g.path(star(18.5, 5.5, 3));
  },
  Glyph.arrowOut: (g) {
    g.line(6, 18, 18, 6);
    g.poly([8.5, 6, 18, 6, 18, 15.5]);
  },
  Glyph.arrowRight: (g) {
    g.line(4, 12, 20, 12);
    g.poly([14, 6, 20, 12, 14, 18]);
  },
  Glyph.chevronLeft: (g) {
    g.s.strokeWidth = 2.5;
    g.poly([15, 4.5, 7.5, 12, 15, 19.5]);
  },
  Glyph.chevronDown: (g) {
    g.poly([6, 9.5, 12, 15.5, 18, 9.5]);
  },
  Glyph.bell: (g) {
    g.path(
      Path()
        ..moveTo(4, 17.5)
        ..lineTo(20, 17.5)
        ..cubicTo(18.3, 16, 18, 14, 18, 10.5)
        ..cubicTo(18, 6.6, 15.4, 4, 12, 4)
        ..cubicTo(8.6, 4, 6, 6.6, 6, 10.5)
        ..cubicTo(6, 14, 5.7, 16, 4, 17.5)
        ..close(),
      fill: true,
    );
    g.arc(12, 19.6, 2.2, 0, math.pi);
  },
  Glyph.bellRing: (g) {
    _glyphs[Glyph.bell]!(g);
    g.arc(12, 10.5, 10, -math.pi * 0.95, math.pi * 0.2);
    g.arc(12, 10.5, 10, -math.pi * 0.25, math.pi * 0.2);
  },
  Glyph.logout: (g) {
    g.path(
      Path()
        ..moveTo(10, 3.5)
        ..lineTo(6, 3.5)
        ..quadraticBezierTo(4, 3.5, 4, 5.5)
        ..lineTo(4, 18.5)
        ..quadraticBezierTo(4, 20.5, 6, 20.5)
        ..lineTo(10, 20.5),
    );
    g.line(9.5, 12, 20.5, 12);
    g.poly([16, 7.5, 20.5, 12, 16, 16.5]);
  },
  Glyph.plus: (g) {
    g.s.strokeWidth = 2.6;
    g.line(12, 4.5, 12, 19.5);
    g.line(4.5, 12, 19.5, 12);
  },
  Glyph.search: (g) {
    g.circle(10.5, 10.5, 6.5, fill: true);
    g.line(15.5, 15.5, 20.5, 20.5);
  },
  Glyph.calendar: (g) {
    g.rr(3, 5, 21, 21, 3, fill: true);
    g.line(3.5, 10, 20.5, 10);
    g.line(8, 3, 8, 7);
    g.line(16, 3, 16, 7);
    g.dot(8, 14.5);
    g.dot(12, 14.5);
    g.dot(16, 14.5);
    g.dot(8, 17.8);
    g.dot(12, 17.8);
  },
  Glyph.egg: (g) {
    g.path(
      Path()
        ..moveTo(12, 3)
        ..cubicTo(16.5, 3, 19.5, 10, 19.5, 14)
        ..cubicTo(19.5, 18.5, 16.2, 21, 12, 21)
        ..cubicTo(7.8, 21, 4.5, 18.5, 4.5, 14)
        ..cubicTo(4.5, 10, 7.5, 3, 12, 3)
        ..close(),
      fill: true,
    );
    g.arc(12, 14.5, 3.6, math.pi * 0.55, math.pi * 0.6);
  },
  Glyph.chart: (g) {
    g.rr(3.5, 12, 8, 20.5, 1.4, fill: true);
    g.rr(9.75, 4, 14.25, 20.5, 1.4, fill: true);
    g.rr(16, 8.5, 20.5, 20.5, 1.4, fill: true);
  },
  Glyph.flag: (g) {
    g.line(5, 21, 5, 3.5);
    g.path(
      Path()
        ..moveTo(5, 4)
        ..cubicTo(9, 2, 12, 6, 19.5, 4)
        ..lineTo(19.5, 13.5)
        ..cubicTo(12, 15.5, 9, 11.5, 5, 13.5),
      fill: true,
    );
  },
  Glyph.filter: (g) {
    g.poly(
      [3.5, 4.5, 20.5, 4.5, 14, 12.5, 14, 19, 10, 21, 10, 12.5],
      close: true,
      fill: true,
    );
  },
  Glyph.check: (g) {
    g.s.strokeWidth = 2.6;
    g.poly([4.5, 12.5, 9.5, 17.5, 19.5, 6.5]);
  },
  Glyph.eye: (g) {
    g.path(
      Path()
        ..moveTo(2.5, 12)
        ..cubicTo(5, 7, 8.5, 5, 12, 5)
        ..cubicTo(15.5, 5, 19, 7, 21.5, 12)
        ..cubicTo(19, 17, 15.5, 19, 12, 19)
        ..cubicTo(8.5, 19, 5, 17, 2.5, 12)
        ..close(),
      fill: true,
    );
    g.circle(12, 12, 3);
  },
  Glyph.eyeOff: (g) {
    _glyphs[Glyph.eye]!(g);
    g.line(4, 3.5, 20, 20.5);
  },
  Glyph.sun: (g) {
    g.circle(12, 12, 4.3, fill: true);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      g.line(
        12 + 7.3 * math.cos(a),
        12 + 7.3 * math.sin(a),
        12 + 9.6 * math.cos(a),
        12 + 9.6 * math.sin(a),
      );
    }
  },
  Glyph.cloudCheck: (g) {
    g.path(
      Path()
        ..moveTo(7, 19)
        ..cubicTo(4.2, 19, 2.5, 17, 2.5, 14.6)
        ..cubicTo(2.5, 12.2, 4.4, 10.4, 6.6, 10.4)
        ..cubicTo(7.4, 7, 9.8, 5, 13, 5)
        ..cubicTo(16.8, 5, 19.5, 7.8, 19.5, 11.2)
        ..cubicTo(21, 11.8, 21.8, 13.4, 21.8, 15)
        ..cubicTo(21.8, 17.3, 20, 19, 17.6, 19)
        ..close(),
      fill: true,
    );
    g.poly([9, 13, 11.3, 15.3, 15.5, 11]);
  },
  Glyph.crown: (g) {
    g.poly(
      [3.5, 7.5, 8, 12, 12, 4.5, 16, 12, 20.5, 7.5, 18.5, 18, 5.5, 18],
      close: true,
      fill: true,
    );
    g.line(6, 21, 18, 21);
  },
  Glyph.rocket: (g) {
    g.path(
      Path()
        ..moveTo(12, 2.5)
        ..cubicTo(16, 5.5, 16.5, 10, 15.5, 16)
        ..lineTo(8.5, 16)
        ..cubicTo(7.5, 10, 8, 5.5, 12, 2.5)
        ..close(),
      fill: true,
    );
    g.circle(12, 9, 1.8);
    g.poly([8.5, 12.5, 5.5, 15.5, 5.5, 18, 8.8, 16]);
    g.poly([15.5, 12.5, 18.5, 15.5, 18.5, 18, 15.2, 16]);
    g.line(10.5, 19, 10.5, 21);
    g.line(13.5, 19, 13.5, 21);
  },
  Glyph.basket: (g) {
    g.poly([7.5, 9.5, 11, 3.5]);
    g.poly([16.5, 9.5, 13, 3.5]);
    g.path(
      Path()
        ..moveTo(2.5, 9.5)
        ..lineTo(21.5, 9.5)
        ..lineTo(19.3, 19)
        ..quadraticBezierTo(19, 20.5, 17.4, 20.5)
        ..lineTo(6.6, 20.5)
        ..quadraticBezierTo(5, 20.5, 4.7, 19)
        ..close(),
      fill: true,
    );
    g.line(9.5, 13, 9.5, 17);
    g.line(14.5, 13, 14.5, 17);
  },
  Glyph.share: (g) {
    g.path(
      Path()
        ..moveTo(8, 9)
        ..lineTo(6.5, 9)
        ..quadraticBezierTo(4.5, 9, 4.5, 11)
        ..lineTo(4.5, 19)
        ..quadraticBezierTo(4.5, 21, 6.5, 21)
        ..lineTo(17.5, 21)
        ..quadraticBezierTo(19.5, 21, 19.5, 19)
        ..lineTo(19.5, 11)
        ..quadraticBezierTo(19.5, 9, 17.5, 9)
        ..lineTo(16, 9),
      fill: true,
    );
    g.line(12, 3, 12, 14.5);
    g.poly([8, 6.8, 12, 2.8, 16, 6.8]);
  },
  Glyph.image: (g) {
    g.rr(3, 4, 21, 20, 3, fill: true);
    g.poly([3.5, 17, 9, 11.5, 13, 15.5, 15.5, 13, 20.5, 18]);
    g.circle(15.5, 8.5, 1.6);
  },
  Glyph.dot: (g) {
    g.dot(12, 12, 6);
  },
  Glyph.chat: (g) {
    g.path(
      Path()
        ..moveTo(12, 3)
        ..cubicTo(17, 3, 21, 6.6, 21, 11.3)
        ..cubicTo(21, 16, 17, 19.6, 12, 19.6)
        ..cubicTo(10.6, 19.6, 9.3, 19.3, 8.1, 18.8)
        ..lineTo(3.5, 20.5)
        ..lineTo(4.9, 16.4)
        ..cubicTo(3.7, 15, 3, 13.2, 3, 11.3)
        ..cubicTo(3, 6.6, 7, 3, 12, 3)
        ..close(),
      fill: true,
    );
    g.dot(8.3, 11.3);
    g.dot(12, 11.3);
    g.dot(15.7, 11.3);
  },
  Glyph.wallet: (g) {
    g.path(
      Path()
        ..moveTo(18, 7)
        ..lineTo(18, 5)
        ..quadraticBezierTo(18, 3.5, 16.5, 3.8)
        ..lineTo(5, 6.5)
        ..quadraticBezierTo(3, 7, 3, 9),
    );
    g.rr(3, 7, 21, 20.5, 3, fill: true);
    g.rr(15, 11.5, 21, 16, 2);
    g.dot(17.6, 13.75, 1.1);
  },
  Glyph.phone: (g) {
    g.path(
      Path()
        ..moveTo(5, 3.5)
        ..lineTo(8.8, 3.5)
        ..lineTo(10.4, 8.2)
        ..lineTo(8.2, 9.8)
        ..cubicTo(9.3, 12.2, 11.8, 14.7, 14.2, 15.8)
        ..lineTo(15.8, 13.6)
        ..lineTo(20.5, 15.2)
        ..lineTo(20.5, 19)
        ..quadraticBezierTo(20.5, 20.5, 19, 20.5)
        ..cubicTo(10.7, 20, 4, 13.3, 3.5, 5)
        ..quadraticBezierTo(3.5, 3.5, 5, 3.5)
        ..close(),
      fill: true,
    );
  },
  Glyph.report: (g) {
    g.rr(4.5, 3, 19.5, 21, 2.5, fill: true);
    g.rr(8.5, 1.8, 15.5, 4.8, 1.2);
    g.poly([8, 16, 10.5, 12.5, 13, 14.5, 16, 10]);
  },
  Glyph.maggot: (g) {
    // larva BSF: tubuh bersegmen melengkung
    final body = Path()
      ..moveTo(4.5, 16.5)
      ..cubicTo(3, 11, 7, 5.5, 12.5, 5.5)
      ..cubicTo(17.5, 5.5, 21, 9, 20.5, 13)
      ..cubicTo(20.2, 15.5, 18, 16.8, 16, 16)
      ..cubicTo(14.5, 15.4, 14.3, 13.6, 13, 13)
      ..cubicTo(11, 12.2, 9, 14, 8.6, 16.6)
      ..cubicTo(8.3, 18.6, 5.2, 19, 4.5, 16.5)
      ..close();
    g.path(body, fill: true);
    g.arc(12.5, 12, 3.6, -math.pi * 0.95, math.pi * 0.55);
    g.dot(17.8, 10.3, 1.1);
  },
  Glyph.tag: (g) {
    g.poly(
      [3.5, 3.5, 11.5, 3.5, 20.5, 12.5, 12.5, 20.5, 3.5, 11.5],
      close: true,
      fill: true,
    );
    g.circle(8, 8, 1.6);
  },
};

/// Pemetaan ikon Material lama → glyph MaggotKu.
final Map<IconData, Glyph> _material = {
  Icons.home_rounded: Glyph.home,
  Icons.spa_rounded: Glyph.sprout,
  Icons.spa_outlined: Glyph.sprout,
  Icons.eco_rounded: Glyph.sprout,
  Icons.grass_rounded: Glyph.sprout,
  Icons.local_florist_rounded: Glyph.sprout,
  Icons.restaurant_rounded: Glyph.feed,
  Icons.agriculture_rounded: Glyph.harvest,
  Icons.agriculture_outlined: Glyph.barn,
  Icons.warehouse_rounded: Glyph.barn,
  Icons.warehouse_outlined: Glyph.barn,
  Icons.payments_rounded: Glyph.coin,
  Icons.payments_outlined: Glyph.coin,
  Icons.point_of_sale_rounded: Glyph.coin,
  Icons.sell_rounded: Glyph.tag,
  Icons.label_outline_rounded: Glyph.tag,
  Icons.edit_note_rounded: Glyph.notebook,
  Icons.person_rounded: Glyph.user,
  Icons.person_outline_rounded: Glyph.user,
  Icons.people_alt_rounded: Glyph.users,
  Icons.scale_rounded: Glyph.scale,
  Icons.schedule_rounded: Glyph.clock,
  Icons.lock_clock_outlined: Glyph.clock,
  Icons.hourglass_bottom_rounded: Glyph.hourglass,
  Icons.notes_rounded: Glyph.receipt,
  Icons.receipt_long_rounded: Glyph.receipt,
  Icons.edit_rounded: Glyph.pencil,
  Icons.alternate_email_rounded: Glyph.mail,
  Icons.verified_rounded: Glyph.badge,
  Icons.verified_user_outlined: Glyph.badge,
  Icons.check_circle_rounded: Glyph.badge,
  Icons.trending_up_rounded: Glyph.trendUp,
  Icons.trending_down_rounded: Glyph.trendDown,
  Icons.lock_outline_rounded: Glyph.lock,
  Icons.lock_rounded: Glyph.lock,
  Icons.location_on_rounded: Glyph.pin,
  Icons.location_on_outlined: Glyph.pin,
  Icons.delete_outline_rounded: Glyph.trash,
  Icons.bolt_rounded: Glyph.bolt,
  Icons.warning_amber_rounded: Glyph.warning,
  Icons.photo_camera_rounded: Glyph.camera,
  Icons.add_a_photo_rounded: Glyph.camera,
  Icons.photo_library_rounded: Glyph.gallery,
  Icons.inventory_2_outlined: Glyph.box,
  Icons.inventory_2_rounded: Glyph.box,
  Icons.calculate_rounded: Glyph.calculator,
  Icons.autorenew_rounded: Glyph.cycle,
  Icons.recycling_rounded: Glyph.cycle,
  Icons.auto_awesome_rounded: Glyph.sparkle,
  Icons.arrow_outward_rounded: Glyph.arrowOut,
  Icons.arrow_forward_rounded: Glyph.arrowRight,
  Icons.arrow_back_ios_new_rounded: Glyph.chevronLeft,
  Icons.expand_more_rounded: Glyph.chevronDown,
  Icons.notifications_none_rounded: Glyph.bell,
  Icons.notifications_active_rounded: Glyph.bellRing,
  Icons.logout_rounded: Glyph.logout,
  Icons.add_rounded: Glyph.plus,
  Icons.search_rounded: Glyph.search,
  Icons.calendar_month_rounded: Glyph.calendar,
  Icons.event_rounded: Glyph.calendar,
  Icons.egg_outlined: Glyph.egg,
  Icons.pie_chart_rounded: Glyph.chart,
  Icons.bar_chart_rounded: Glyph.chart,
  Icons.flag_rounded: Glyph.flag,
  Icons.filter_list_rounded: Glyph.filter,
  Icons.filter_alt_off_rounded: Glyph.filter,
  Icons.check_rounded: Glyph.check,
  Icons.visibility_rounded: Glyph.eye,
  Icons.visibility_off_rounded: Glyph.eyeOff,
  Icons.wb_sunny_rounded: Glyph.sun,
  Icons.cloud_done_rounded: Glyph.cloudCheck,
  Icons.workspace_premium_rounded: Glyph.crown,
  Icons.rocket_launch_rounded: Glyph.rocket,
  Icons.shopping_basket_rounded: Glyph.basket,
  Icons.ios_share_rounded: Glyph.share,
  Icons.broken_image_rounded: Glyph.image,
  Icons.circle: Glyph.dot,
  Icons.fiber_manual_record_rounded: Glyph.dot,
  // dipakai halaman baru
  Icons.chat_rounded: Glyph.chat,
  Icons.account_balance_wallet_rounded: Glyph.wallet,
  Icons.phone_rounded: Glyph.phone,
  Icons.assessment_rounded: Glyph.report,
  Icons.bug_report_rounded: Glyph.maggot,
  Icons.groups_rounded: Glyph.users,
};

/// Glyph pasangan untuk ikon Material (null = belum ada).
Glyph? glyphOf(IconData icon) => _material[icon];

/// Ikon MaggotKu. Pakai seperti [Icon]: `AppIcon(Icons.spa_rounded)`
/// atau langsung glyph: `AppIcon.glyph(Glyph.maggot)`.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.accent,
    this.semanticLabel,
  }) : glyph = null;

  const AppIcon.glyph(
    Glyph this.glyph, {
    super.key,
    this.size,
    this.color,
    this.accent,
    this.semanticLabel,
  }) : icon = null;

  final IconData? icon;
  final Glyph? glyph;
  final double? size;
  final Color? color;

  /// Warna isian duotone (bawaan: [color] transparan 22%).
  final Color? accent;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final g = glyph ?? glyphOf(icon!);
    final theme = IconTheme.of(context);
    final sz = size ?? theme.size ?? 24;
    final c = color ?? theme.color ?? const Color(0xFF111113);
    if (g == null) {
      return Icon(icon, size: sz, color: c, semanticLabel: semanticLabel);
    }
    return Semantics(
      label: semanticLabel,
      child: SizedBox.square(
        dimension: sz,
        child: CustomPaint(
          painter: _GlyphPainter(
            g,
            c,
            accent ?? c.withValues(alpha: c.a * 0.22),
          ),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color, this.accent);
  final Glyph glyph;
  final Color color, accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    glyph._draw(_G(canvas, color, accent, size.shortestSide / 24));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.accent != accent;
}
