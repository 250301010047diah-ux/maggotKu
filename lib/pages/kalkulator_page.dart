import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

/// Efisiensi biokonversi acuan (% berat maggot segar dari berat pakan).
/// Angka perkiraan umum — sebaiknya disesuaikan dengan data kandang sendiri.
const _presetEfisiensi = {
  'Sisa sayur': 15.0,
  'Ampas tahu': 22.0,
  'Kulit buah': 13.0,
  'Dedak': 18.0,
  'Campuran': 18.0,
};

class KalkulatorPage extends StatefulWidget {
  const KalkulatorPage({super.key});
  @override
  State<KalkulatorPage> createState() => _KalkulatorPageState();
}

class _KalkulatorPageState extends State<KalkulatorPage> {
  String jenis = 'Campuran';
  double pakan = 100; // kg per siklus
  double efisiensi = 18; // %
  double kasgotPct = 35; // % residu jadi kasgot
  double hargaMaggot = hargaDefault['Maggot segar']!;
  double hargaKasgot = hargaDefault['Kasgot (pupuk)']!;
  double biayaPakan = 300; // Rp per kg
  bool _hargaDariData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Biaya pakan bawaan = harga rata-rata pembelian pakan (90 hari).
    if (!_hargaDariData) {
      final h = AppScope.of(context).hargaPakanRata();
      if (h != null) {
        biayaPakan = h.clamp(0, 2000).roundToDouble();
        _hargaDariData = true;
      }
    }
  }

  double operasional = 50000; // Rp per siklus
  double siklus = 2; // per bulan

  void _pakaiData(AppState s) {
    final now = DateTime.now();
    bool recent(DateTime d) => now.difference(d).inDays < 30;
    final p = s.total(s.pakan.where((e) => recent(e.tanggal)));
    final h = s.total(s.panen.where((e) => recent(e.tanggal)));
    if (p <= 0) {
      toast(context, 'Belum ada catatan pakan 30 hari terakhir.');
      return;
    }
    setState(() {
      pakan = p.clamp(10, 1000).toDouble();
      if (h > 0) efisiensi = (h / p * 100).clamp(5, 30).toDouble();
      final harga = s.hargaPakanRata();
      if (harga != null) biayaPakan = harga.clamp(0, 2000).roundToDouble();
      jenis = '';
    });
    toast(context, 'Memakai data 30 hari: pakan ${kg(p)}, panen ${kg(h)} 📊');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    // ---------- Perhitungan ----------
    final maggot = pakan * efisiensi / 100;
    final kasgot = pakan * kasgotPct / 100;
    final terurai = math.max(0.0, pakan - maggot - kasgot);
    final fcr = maggot == 0 ? 0.0 : pakan / maggot;
    final reduksi = pakan == 0 ? 0.0 : (1 - kasgot / pakan) * 100;
    final omzetMaggot = maggot * hargaMaggot;
    final omzetKasgot = kasgot * hargaKasgot;
    final omzet = omzetMaggot + omzetKasgot;
    final biaya = pakan * biayaPakan + operasional;
    final profit = omzet - biaya;
    final margin = omzet == 0 ? 0.0 : profit / omzet * 100;
    final roi = biaya == 0 ? 0.0 : profit / biaya * 100;
    final bulanan = profit * siklus;
    final untung = profit >= 0;

    return Scaffold(
      appBar: elegantAppBar(context, 'Kalkulator'),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ---------- Hero ----------
          FadeSlideIn(
            child: DarkCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        eyebrow('Bioconversion & ROI Engine', color: mint),
                        gap(10),
                        const Text(
                          'Kalkulator Biokonversi & Profit',
                          style: TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                        gap(8),
                        const Text(
                          'Simulasi rasio konversi pakan (FCR), hasil panen maggot fresh, pupuk kasgot, dan proyeksi omzet.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Mascot(
                    mood: untung ? MaggotMood.happy : MaggotMood.sulky,
                    size: 84,
                  ),
                ],
              ),
            ),
          ),

          // ---------- Bahan baku ----------
          SectionTitle(
            'Bahan baku',
            action: 'Pakai data saya',
            onAction: () => _pakaiData(s),
          ),
          FadeSlideIn(
            delay: 1,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jenis pakan',
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                  gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final j in _presetEfisiensi.keys)
                        Pressable(
                          onTap: () => setState(() {
                            jenis = j;
                            efisiensi = _presetEfisiensi[j]!;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: jenis == j
                                  ? emerald
                                  : const Color(0x0F1C1C1E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              j,
                              style: TextStyle(
                                fontFamily: headFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: jenis == j ? Colors.white : ink,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  gap(18),
                  _SliderField(
                    label: 'Pakan per siklus',
                    icon: Icons.restaurant_rounded,
                    color: peach,
                    value: pakan,
                    min: 10,
                    max: 1000,
                    divisions: 99,
                    display: kg(pakan.round()),
                    onChanged: (v) => setState(() => pakan = v),
                  ),
                  _SliderField(
                    label: 'Efisiensi biokonversi',
                    icon: Icons.bolt_rounded,
                    value: efisiensi,
                    min: 5,
                    max: 30,
                    divisions: 50,
                    display: '${efisiensi.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      efisiensi = v;
                      jenis = '';
                    }),
                  ),
                  _SliderField(
                    label: 'Residu jadi kasgot',
                    icon: Icons.grass_rounded,
                    color: sky,
                    value: kasgotPct,
                    min: 10,
                    max: 60,
                    divisions: 50,
                    display: '${kasgotPct.round()}%',
                    onChanged: (v) => setState(() => kasgotPct = v),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Hasil biokonversi ----------
          const SectionTitle('Hasil biokonversi'),
          FadeSlideIn(
            delay: 2,
            child: Row(
              children: [
                _ResultTile(
                  emoji: '🐛',
                  color: sage,
                  label: 'Maggot fresh',
                  value: maggot,
                  format: kg,
                ),
                const SizedBox(width: 10),
                _ResultTile(
                  emoji: '🌱',
                  color: butter,
                  label: 'Pupuk kasgot',
                  value: kasgot,
                  format: kg,
                ),
                const SizedBox(width: 10),
                _ResultTile(
                  emoji: '⚖️',
                  color: lavender,
                  label: 'FCR',
                  value: fcr,
                  format: (v) => v.toStringAsFixed(2),
                ),
              ],
            ),
          ),
          gap(12),
          FadeSlideIn(
            delay: 3,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Neraca massa',
                          style: TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: ink,
                          ),
                        ),
                      ),
                      Pill(
                        'Reduksi sampah ${reduksi.toStringAsFixed(0)}%',
                        icon: Icons.recycling_rounded,
                      ),
                    ],
                  ),
                  gap(14),
                  _MassBar(maggot: maggot, kasgot: kasgot, terurai: terurai),
                  gap(14),
                  Text(
                    'FCR ${fcr.toStringAsFixed(2)} artinya butuh ${fcr.toStringAsFixed(1)} kg pakan untuk menghasilkan 1 kg maggot fresh. Makin kecil, makin efisien.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Harga & biaya ----------
          const SectionTitle('Harga & biaya'),
          FadeSlideIn(
            delay: 4,
            child: GlassCard(
              child: Column(
                children: [
                  _SliderField(
                    label: 'Harga maggot fresh /kg',
                    icon: Icons.sell_rounded,
                    value: hargaMaggot,
                    min: 3000,
                    max: 20000,
                    divisions: 34,
                    display: rupiah(hargaMaggot),
                    onChanged: (v) => setState(() => hargaMaggot = v),
                  ),
                  _SliderField(
                    label: 'Harga kasgot /kg',
                    icon: Icons.local_florist_rounded,
                    color: butter,
                    value: hargaKasgot,
                    min: 500,
                    max: 5000,
                    divisions: 18,
                    display: rupiah(hargaKasgot),
                    onChanged: (v) => setState(() => hargaKasgot = v),
                  ),
                  _SliderField(
                    label: _hargaDariData
                        ? 'Biaya pakan /kg (dari pembelianmu)'
                        : 'Biaya pakan /kg',
                    icon: Icons.shopping_basket_rounded,
                    color: peach,
                    value: biayaPakan,
                    min: 0,
                    max: 2000,
                    divisions: 40,
                    display: rupiah(biayaPakan),
                    onChanged: (v) => setState(() => biayaPakan = v),
                  ),
                  _SliderField(
                    label: 'Operasional /siklus',
                    icon: Icons.bolt_rounded,
                    color: pink,
                    value: operasional,
                    min: 0,
                    max: 500000,
                    divisions: 50,
                    display: rupiahSingkat(operasional),
                    onChanged: (v) => setState(() => operasional = v),
                  ),
                  _SliderField(
                    label: 'Siklus per bulan',
                    icon: Icons.autorenew_rounded,
                    color: sky,
                    value: siklus,
                    min: 1,
                    max: 4,
                    divisions: 3,
                    display: '${siklus.round()}×',
                    onChanged: (v) => setState(() => siklus = v),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Proyeksi ----------
          const SectionTitle('Proyeksi profit'),
          FadeSlideIn(
            delay: 5,
            child: DarkCard(
              tone: CardTone.ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  eyebrow('Profit per siklus', color: champagne),
                  gap(8),
                  _Count(
                    value: profit,
                    format: rupiah,
                    style: TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      letterSpacing: -0.5,
                      color: untung ? Colors.white : const Color(0xFFFFB08A),
                    ),
                  ),
                  gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pill(
                        'Margin ${margin.toStringAsFixed(0)}%',
                        color: Colors.white.withValues(alpha: 0.12),
                        textColor: untung ? mint : const Color(0xFFFFB4A2),
                        icon: Icons.pie_chart_rounded,
                      ),
                      Pill(
                        'ROI ${roi.toStringAsFixed(0)}%',
                        color: Colors.white.withValues(alpha: 0.12),
                        textColor: untung ? mint : const Color(0xFFFFB4A2),
                        icon: untung
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                      ),
                    ],
                  ),
                  gap(18),
                  Row(
                    children: [
                      HeroStat('Omzet/bulan', rupiahSingkat(omzet * siklus)),
                      const HeroDivider(),
                      HeroStat('Biaya/bulan', rupiahSingkat(biaya * siklus)),
                      const HeroDivider(),
                      HeroStat('Profit/tahun', rupiahSingkat(bulanan * 12)),
                    ],
                  ),
                  gap(18),
                  if (bulanan > 0) ...[
                    eyebrow('Akumulasi profit 12 bulan', color: Colors.white60),
                    gap(4),
                    LineAreaChart(
                      values: [for (var m = 1; m <= 12; m++) bulanan * m],
                      labels: [for (var m = 1; m <= 12; m++) 'Bln $m'],
                      color: champagne,
                      height: 150,
                      dark: true,
                      format: rupiahSingkat,
                    ),
                  ] else
                    Row(
                      children: [
                        const Mascot(mood: MaggotMood.sulky, size: 68),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Masih rugi nih. Coba naikkan harga jual, tingkatkan efisiensi, atau tekan biaya pakan.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (omzet > 0) ...[
            const SectionTitle('Komposisi omzet'),
            FadeSlideIn(
              delay: 6,
              child: GlassCard(
                child: DonutChart(
                  centerTitle: rupiahSingkat(omzet),
                  centerSubtitle: 'omzet/siklus',
                  segments: [
                    (
                      label: 'Maggot fresh',
                      value: omzetMaggot,
                      color: emeraldLight,
                    ),
                    (label: 'Pupuk kasgot', value: omzetKasgot, color: coral),
                  ],
                ),
              ),
            ),
          ],
          gap(16),
          const Text(
            'Hasil ini simulasi. Angka efisiensi acuan bersifat perkiraan, jadi sesuaikan dengan data kandangmu sendiri.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Komponen kalkulator
// =====================================================================
class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
    this.color = sage,
  });
  final String label, display;
  final IconData icon;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Column(
      children: [
        Row(
          children: [
            IconBubble(icon, color: color, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: emerald,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                display,
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: emeraldLight,
            inactiveTrackColor: const Color(0x141C1C1E),
            thumbColor: emerald,
            overlayColor: emerald.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

/// Angka yang menghitung naik/turun dengan halus saat berubah.
class _Count extends StatelessWidget {
  const _Count({
    required this.value,
    required this.format,
    required this.style,
  });
  final double value;
  final String Function(double) format;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value),
    duration: const Duration(milliseconds: 550),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(format(v), style: style),
    ),
  );
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.emoji,
    required this.color,
    required this.label,
    required this.value,
    required this.format,
  });
  final String emoji, label;
  final Color color;
  final double value;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiBubble(emoji, color: color, size: 36),
          const SizedBox(height: 10),
          _Count(
            value: value,
            format: format,
            style: const TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: ink,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    ),
  );
}

/// Bar bertumpuk: maggot / kasgot / terurai.
class _MassBar extends StatelessWidget {
  const _MassBar({
    required this.maggot,
    required this.kasgot,
    required this.terurai,
  });
  final double maggot, kasgot, terurai;

  @override
  Widget build(BuildContext context) {
    final total = maggot + kasgot + terurai;
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 18,
            child: LayoutBuilder(
              builder: (_, box) => Row(
                children: [
                  _seg(maggot / total * box.maxWidth, emeraldLight),
                  _seg(kasgot / total * box.maxWidth, coral),
                  Expanded(child: Container(color: const Color(0x1F1C1C1E))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _legend(emeraldLight, 'Maggot', kg(maggot)),
            _legend(coral, 'Kasgot', kg(kasgot)),
            _legend(const Color(0x441C1C1E), 'Terurai/uap', kg(terurai)),
          ],
        ),
      ],
    );
  }

  Widget _seg(double w, Color c) => AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
    width: w,
    color: c,
  );

  Widget _legend(Color c, String label, String value) => Expanded(
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: ink,
                ),
              ),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
