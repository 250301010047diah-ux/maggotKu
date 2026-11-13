import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

typedef ValueFormat = String Function(double v);

String _kgFmt(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} kg';

// =====================================================================
// Grafik batang 7 hari — batang tumbuh bergantian dengan efek pantul.
// =====================================================================
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.height = 170,
    this.format = _kgFmt,
    this.dark = false,
  });
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final ValueFormat format;
  final bool dark;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(Object.hash(Object.hashAll(values), color)),
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 1100),
    builder: (_, t, _) => SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _BarPainter(this, t)),
    ),
  );
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.c, this.t);
  final WeeklyBarChart c;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 22.0, topPad = 36.0;
    final values = c.values;
    final chartH = size.height - labelH - topPad;
    final maxV = values.fold<double>(0, math.max);
    final slot = size.width / values.length;
    final barW = math.min(22.0, slot * 0.5);
    _grid(canvas, size, topPad, chartH, c.dark);

    final maxIndex = maxV == 0 ? -1 : values.lastIndexOf(maxV);
    var maxTop = Offset.zero;
    final n = values.length;
    // jeda antar batang menyesuaikan jumlah batang (total 0.42 dari animasi)
    final stagger = n <= 1 ? 0.0 : 0.42 / (n - 1);
    // label dijarangkan bila batangnya banyak
    final step = n <= 8 ? 1 : (n / 6).ceil();
    for (var i = 0; i < values.length; i++) {
      final cx = slot * i + slot / 2;
      final lt = ((t - i * stagger) / 0.58).clamp(0.0, 1.0);
      final e = Curves.easeOutBack.transform(lt);
      final h = maxV == 0 ? 0.0 : chartH * values[i] / maxV * e;
      final highlight = i == values.length - 1 || i == maxIndex;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barW / 2, topPad, barW, chartH),
          Radius.circular(barW / 2),
        ),
        Paint()
          ..color = (c.dark ? Colors.white : c.color).withValues(alpha: 0.08),
      );
      if (h > 0.5) {
        final rect = Rect.fromLTWH(cx - barW / 2, topPad + chartH - h, barW, h);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(barW / 2)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: highlight
                  ? [c.color, Color.lerp(c.color, Colors.white, 0.3)!]
                  : [
                      c.color.withValues(alpha: 0.5),
                      c.color.withValues(alpha: 0.22),
                    ],
            ).createShader(rect),
        );
      }
      if (i == maxIndex) maxTop = Offset(cx, topPad + chartH - h);

      final isToday = i == values.length - 1;
      final showLabel = isToday || (i % step == 0 && (n - 1 - i) >= step * 0.6);
      if (showLabel) {
        _text(
          canvas,
          c.labels[i],
          Offset(cx, size.height - labelH + 5),
          TextStyle(
            fontFamily: isToday ? headFont : bodyFont,
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            color: c.dark
                ? (isToday ? Colors.white : Colors.white60)
                : (isToday ? ink : muted),
          ),
          clampTo: size.width,
        );
      }
    }
    if (maxIndex >= 0 && t > 0.8) {
      _tooltip(
        canvas,
        size,
        c.format(values[maxIndex]),
        maxTop,
        c.dark,
        ((t - 0.8) / 0.2).clamp(0.0, 1.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.t != t ||
      old.c.values != c.values ||
      old.c.color != c.color ||
      old.c.dark != c.dark;
}

// =====================================================================
// Grafik garis area halus (kurva) dengan gradasi & titik bercahaya.
// =====================================================================
class LineAreaChart extends StatelessWidget {
  const LineAreaChart({
    super.key,
    required this.values,
    required this.color,
    this.labels,
    this.height = 150,
    this.dark = false,
    this.format = _kgFmt,
    this.compact = false,
  });
  final List<double> values;
  final List<String>? labels;
  final Color color;
  final double height;
  final bool dark, compact;
  final ValueFormat format;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(Object.hash(Object.hashAll(values), color, values.length)),
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: compact ? 900 : 1400),
    curve: Curves.easeInOutCubic,
    builder: (_, t, _) => SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LinePainter(this, t)),
    ),
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.c, this.t);
  final LineAreaChart c;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final n = c.values.length;
    if (n == 0) return;
    final hasLabels = c.labels != null && !c.compact;
    final top = c.compact ? 4.0 : 34.0;
    final bottom = size.height - (hasLabels ? 22 : 4);
    final h = bottom - top;
    var maxV = c.values.fold<double>(0, math.max);
    if (maxV == 0) maxV = 1;
    final padX = c.compact ? 3.0 : 8.0;
    double xAt(int i) =>
        n == 1 ? size.width / 2 : padX + i * (size.width - padX * 2) / (n - 1);
    final pts = [
      for (var i = 0; i < n; i++)
        Offset(xAt(i), bottom - c.values[i] / maxV * h),
    ];
    if (!c.compact) _grid(canvas, size, top, h, c.dark);

    final line = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < n; i++) {
      final p = pts[i - 1], q = pts[i];
      final mx = (p.dx + q.dx) / 2;
      line.cubicTo(mx, p.dy, mx, q.dy, q.dx, q.dy);
    }
    final area = Path.from(line)
      ..lineTo(pts.last.dx, bottom)
      ..lineTo(pts.first.dx, bottom)
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.color.withValues(alpha: c.dark ? 0.38 : 0.3),
            c.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTRB(0, top, size.width, bottom)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.compact ? 2 : 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c.color,
    );
    canvas.restore();

    if (t > 0.97) {
      final p = pts.last;
      canvas.drawCircle(
        p,
        c.compact ? 5 : 10,
        Paint()..color = c.color.withValues(alpha: 0.25),
      );
      if (!c.compact) {
        canvas.drawCircle(p, 5.5, Paint()..color = Colors.white);
      }
      canvas.drawCircle(p, c.compact ? 2.6 : 3.5, Paint()..color = c.color);
    }

    if (!c.compact && t > 0.85) {
      final maxI = c.values.lastIndexOf(c.values.fold<double>(0, math.max));
      if (c.values[maxI] > 0) {
        _tooltip(
          canvas,
          size,
          c.format(c.values[maxI]),
          pts[maxI],
          c.dark,
          ((t - 0.85) / 0.15).clamp(0.0, 1.0),
        );
      }
    }

    if (hasLabels) {
      final step = n <= 7 ? 1 : (n / 5).ceil();
      for (var i = 0; i < n; i++) {
        final isLast = i == n - 1;
        if (!isLast && (i % step != 0 || n - 1 - i < step * 0.6)) continue;
        _text(
          canvas,
          c.labels![i],
          Offset(pts[i].dx, size.height - 17),
          TextStyle(
            fontFamily: isLast ? headFont : bodyFont,
            fontSize: 10.5,
            fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
            color: c.dark
                ? (isLast ? Colors.white : Colors.white60)
                : (isLast ? ink : muted),
          ),
          clampTo: size.width,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.t != t || old.c.values != c.values || old.c.color != c.color;
}

/// Garis tren mini untuk kartu statistik.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.color = emeraldLight,
    this.height = 28,
  });
  final List<double> values;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => LineAreaChart(
    values: values,
    color: color,
    height: height,
    compact: true,
  );
}

// =====================================================================
// Cincin progres.
// =====================================================================
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.stroke = 7,
    this.color = emeraldLight,
    this.trackColor,
    this.child,
  });
  final double value, size, stroke;
  final Color color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
    duration: const Duration(milliseconds: 1300),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (_, v, ch) => SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          v,
          stroke,
          color,
          trackColor ?? color.withValues(alpha: 0.14),
        ),
        child: Center(child: ch),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color, this.track);
  final double v, stroke;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    if (v > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * v,
        false,
        p..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.v != v || old.color != color;
}

// =====================================================================
// Grafik donat dengan legenda.
// =====================================================================
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.centerTitle,
    required this.centerSubtitle,
  });
  final List<({String label, double value, Color color})> segments;
  final String centerTitle, centerSubtitle;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (s, e) => s + e.value);
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, t, _) => SizedBox.square(
            dimension: 128,
            child: CustomPaint(
              painter: _DonutPainter(segments, t),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          centerTitle,
                          style: const TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: ink,
                          ),
                        ),
                      ),
                      Text(
                        centerSubtitle,
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in segments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: ink),
                        ),
                      ),
                      Text(
                        total == 0
                            ? '0%'
                            : '${(s.value / total * 100).round()}%',
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
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, this.t);
  final List<({String label, double value, Color color})> segments;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final arc = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ink.withValues(alpha: 0.05),
    );
    final total = segments.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return;
    const gapRad = 0.09;
    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = (s.value / total) * math.pi * 2 * t;
      if (sweep > gapRad) {
        canvas.drawArc(
          arc,
          start + gapRad / 2,
          sweep - gapRad,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = s.color,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.t != t;
}

// =====================================================================
// Helper gambar.
// =====================================================================
void _grid(Canvas canvas, Size size, double top, double h, bool dark) {
  final p = Paint()
    ..color = (dark ? Colors.white : ink).withValues(alpha: dark ? 0.1 : 0.06)
    ..strokeWidth = 1;
  for (var i = 0; i <= 2; i++) {
    final y = top + h * i / 2;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), p);
    }
  }
}

void _text(
  Canvas canvas,
  String s,
  Offset center,
  TextStyle style, {
  double? clampTo,
}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  var x = center.dx - tp.width / 2;
  if (clampTo != null) x = x.clamp(0.0, math.max(0.0, clampTo - tp.width));
  tp.paint(canvas, Offset(x, center.dy));
}

/// Gelembung label di atas titik [anchor].
void _tooltip(
  Canvas canvas,
  Size size,
  String text,
  Offset anchor,
  bool dark,
  double alpha,
) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: headFont,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: (dark ? emerald : Colors.white).withValues(alpha: alpha),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = tp.width + 16, h = tp.height + 8;
  final cx = anchor.dx.clamp(w / 2, math.max(w / 2, size.width - w / 2));
  final y = math.max(0.0, anchor.dy - h - 10);
  final bg = Paint()
    ..color = (dark ? Colors.white : emerald).withValues(alpha: alpha);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w / 2, y, w, h),
      const Radius.circular(9),
    ),
    bg,
  );
  final tri = Path()
    ..moveTo(anchor.dx - 5, y + h - 0.5)
    ..lineTo(anchor.dx + 5, y + h - 0.5)
    ..lineTo(anchor.dx, y + h + 5)
    ..close();
  canvas.drawPath(tri, bg);
  tp.paint(canvas, Offset(cx - tp.width / 2, y + 4));
}

const _days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

// =====================================================================
// Pengelompokan per periode (harian / mingguan / bulanan)
// =====================================================================
/// Satu kelompok waktu [start, end) beserta labelnya.
class Bucket {
  const Bucket(this.start, this.end, this.label);
  final DateTime start, end;
  final String label;
}

DateTime _today(DateTime? now) => DateUtils.dateOnly(now ?? DateTime.now());

/// [n] hari terakhir, per hari.
List<Bucket> daysBack(int n, [DateTime? now]) {
  final t = _today(now);
  return [
    for (var i = n - 1; i >= 0; i--)
      Bucket(
        DateTime(t.year, t.month, t.day - i),
        DateTime(t.year, t.month, t.day - i + 1),
        i == 0
            ? 'Hari ini'
            : n <= 7
            ? _days[DateTime(t.year, t.month, t.day - i).weekday % 7]
            : '${DateTime(t.year, t.month, t.day - i).day}/${DateTime(t.year, t.month, t.day - i).month}',
      ),
  ];
}

/// [n] minggu terakhir (blok 7 hari yang berakhir hari ini).
List<Bucket> weeksBack(int n, [DateTime? now]) {
  final t = _today(now);
  return [
    for (var k = 0; k < n; k++)
      () {
        final start = DateTime(t.year, t.month, t.day + 1 - 7 * (n - k));
        return Bucket(
          start,
          DateTime(start.year, start.month, start.day + 7),
          k == n - 1 ? 'Kini' : '${start.day}/${start.month}',
        );
      }(),
  ];
}

/// [n] bulan kalender terakhir, termasuk bulan ini.
List<Bucket> monthsBack(int n, [DateTime? now]) {
  final t = _today(now);
  return [
    for (var k = 0; k < n; k++)
      () {
        final m = DateTime(t.year, t.month - (n - 1 - k), 1);
        return Bucket(m, DateTime(m.year, m.month + 1, 1), _bulan[m.month - 1]);
      }(),
  ];
}

/// Tanggal 1 bulan ini sampai hari ini, per hari.
List<Bucket> thisMonth([DateTime? now]) {
  final t = _today(now);
  return [
    for (var d = 1; d <= t.day; d++)
      Bucket(
        DateTime(t.year, t.month, d),
        DateTime(t.year, t.month, d + 1),
        d == t.day ? 'Hari ini' : '$d',
      ),
  ];
}

/// Januari sampai bulan ini, per bulan.
List<Bucket> thisYear([DateTime? now]) {
  final t = _today(now);
  return [
    for (var m = 1; m <= t.month; m++)
      Bucket(DateTime(t.year, m, 1), DateTime(t.year, m + 1, 1), _bulan[m - 1]),
  ];
}

/// Jumlahkan [value] tiap item ke kelompok waktunya.
List<double> sumBuckets<T>(
  Iterable<T> items,
  DateTime Function(T) date,
  double Function(T) value,
  List<Bucket> buckets,
) {
  final out = List<double>.filled(buckets.length, 0);
  for (final e in items) {
    final d = date(e);
    for (var i = 0; i < buckets.length; i++) {
      if (!d.isBefore(buckets[i].start) && d.isBefore(buckets[i].end)) {
        out[i] += value(e);
        break;
      }
    }
  }
  return out;
}

/// Grafik yang otomatis memilih bentuk: garis bila titiknya banyak
/// (>14, misal harian sebulan), batang bila sedikit.
class PeriodChart extends StatelessWidget {
  const PeriodChart({
    super.key,
    required this.buckets,
    required this.values,
    required this.color,
    this.dark = false,
    this.format = _kgFmt,
    this.height = 160,
  });
  final List<Bucket> buckets;
  final List<double> values;
  final Color color;
  final bool dark;
  final ValueFormat format;
  final double height;

  @override
  Widget build(BuildContext context) {
    final labels = [for (final b in buckets) b.label];
    return values.length > 14
        ? LineAreaChart(
            values: values,
            labels: labels,
            color: color,
            height: height,
            dark: dark,
            format: format,
          )
        : WeeklyBarChart(
            values: values,
            labels: labels,
            color: color,
            height: height,
            dark: dark,
            format: format,
          );
  }
}

/// Label hari 7 hari terakhir, yang terakhir "Hari ini".
List<String> last7Labels([DateTime? now]) {
  final n = DateUtils.dateOnly(now ?? DateTime.now());
  return [
    for (var i = 6; i >= 0; i--)
      i == 0 ? 'Hari ini' : _days[n.subtract(Duration(days: i)).weekday % 7],
  ];
}

/// Label tanggal (d/m) untuk [count] hari terakhir.
List<String> lastNLabels(int count, [DateTime? now]) {
  final n = DateUtils.dateOnly(now ?? DateTime.now());
  return [
    for (var i = count - 1; i >= 0; i--)
      i == 0
          ? 'Hari ini'
          : () {
              final d = n.subtract(Duration(days: i));
              return '${d.day}/${d.month}';
            }(),
  ];
}
