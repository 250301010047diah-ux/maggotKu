import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

const biayaGlyph = {
  'Bibit/telur': Icons.egg_outlined,
  'Tenaga kerja': Icons.person_rounded,
  'Listrik & air': Icons.bolt_rounded,
  'Peralatan': Icons.inventory_2_rounded,
  'Transport': Icons.rocket_launch_rounded,
  'Lainnya': Icons.receipt_long_rounded,
};
const _warna = [emeraldLight, coral, Color(0xFFFFA36B), sky2, pink2, gold];

// =====================================================================
// Halaman biaya & laba bersih
// =====================================================================
class BiayaPage extends StatefulWidget {
  const BiayaPage({super.key});
  @override
  State<BiayaPage> createState() => _BiayaPageState();
}

class _BiayaPageState extends State<BiayaPage> {
  /// 0 = bulan ini, 1 = bulan lalu.
  int bulan = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = DateTime.now();
    final dari = DateTime(now.year, now.month - bulan);
    final sampai = DateTime(now.year, now.month - bulan + 1);
    bool dalam(DateTime d) => !d.isBefore(dari) && d.isBefore(sampai);

    final omzet = s.pendapatan(s.penjualan.where((e) => dalam(e.tanggal)));
    final pakan = s.biayaPakan(dari, sampai);
    final lain = s.biayaLain(dari, sampai);
    final laba = omzet - pakan - lain;
    final items = s.biaya.where((e) => dalam(e.tanggal)).toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    final perKat = <String, double>{};
    for (final e in items) {
      perKat[e.kategori] = (perKat[e.kategori] ?? 0) + e.jumlah;
    }
    if (pakan > 0) perKat['Belanja pakan'] = pakan;
    final seg = perKat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      floatingActionButton: GradientFab(
        label: 'Catat Biaya',
        lift: false,
        onTap: () => openPage(context, const BiayaFormPage()),
      ),
      appBar: elegantAppBar(context, 'Biaya & Laba'),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          FadeSlideIn(
            child: DarkCard(
              tone: laba >= 0 ? CardTone.ink : CardTone.warm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: eyebrow('Laba bersih', color: champagne)),
                      SegmentedPills(
                        items: const ['Bln ini', 'Lalu'],
                        index: bulan,
                        dark: true,
                        onChanged: (i) => setState(() => bulan = i),
                      ),
                    ],
                  ),
                  gap(10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RollingText(
                      rupiah(laba),
                      style: const TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 36,
                        letterSpacing: -1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  gap(4),
                  Text(
                    laba >= 0
                        ? 'Untung ${omzet == 0 ? '' : '${(laba / omzet * 100).toStringAsFixed(0)}% dari omzet'}'
                        : 'Biaya lebih besar dari penjualan',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white70,
                    ),
                  ),
                  gap(18),
                  _Waterfall(omzet: omzet, pakan: pakan, lain: lain),
                  gap(16),
                  Row(
                    children: [
                      HeroStat('Omzet', rupiahSingkat(omzet)),
                      const HeroDivider(),
                      HeroStat('Pakan', rupiahSingkat(pakan)),
                      const HeroDivider(),
                      HeroStat('Biaya lain', rupiahSingkat(lain)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (seg.isNotEmpty) ...[
            const SectionTitle('Ke mana uangnya?'),
            FadeSlideIn(
              delay: 1,
              child: GlassCard(
                child: DonutChart(
                  centerTitle: rupiahSingkat(pakan + lain),
                  centerSubtitle: 'total biaya',
                  segments: [
                    for (var i = 0; i < seg.length && i < 6; i++)
                      (
                        label: seg[i].key,
                        value: seg[i].value,
                        color: _warna[i],
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SectionTitle('Riwayat biaya'),
          if (items.isEmpty)
            const EmptyState(
              'Belum ada biaya di bulan ini. Catat bibit, listrik, tenaga, dll.',
            )
          else
            FadeSlideIn(
              delay: 2,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final (i, e) in items.indexed) ...[
                      if (i > 0) const Divider(indent: 56),
                      ActivityRow(
                        onTap: () => openPage(context, BiayaFormPage(item: e)),
                        leading: IconBubble(
                          biayaGlyph[e.kategori] ?? Icons.receipt_long_rounded,
                          color: peach,
                          size: 44,
                        ),
                        title: e.keterangan.isEmpty ? e.kategori : e.keterangan,
                        subtitle:
                            '${e.kategori} • ${s.budidayaById(e.budidayaId ?? -1)?.nama ?? 'Umum'} • ${tanggalPendek(e.tanggal)}',
                        trailing: '−${rupiahSingkat(e.jumlah)}',
                        trailingColor: danger,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Batang air terjun mini: omzet → pakan → biaya lain → laba.
class _Waterfall extends StatelessWidget {
  const _Waterfall({
    required this.omzet,
    required this.pakan,
    required this.lain,
  });
  final double omzet, pakan, lain;

  @override
  Widget build(BuildContext context) {
    final max = [omzet, pakan + lain, 1.0].reduce((a, b) => a > b ? a : b);
    Widget bar(String label, double v, Color c, int i) => Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v / max),
        duration: Duration(milliseconds: 900 + i * 150),
        curve: Curves.easeOutBack,
        builder: (_, f, _) => Column(
          children: [
            SizedBox(
              height: 64,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: f.clamp(0.04, 1),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            gap(6),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
    final laba = omzet - pakan - lain;
    return Row(
      children: [
        bar('Omzet', omzet, Colors.white, 0),
        bar('Pakan', pakan, emeraldLight, 1),
        bar('Lain', lain, const Color(0xFFFFA36B), 2),
        bar('Laba', laba.abs(), laba >= 0 ? lime : danger, 3),
      ],
    );
  }
}

// =====================================================================
// Form biaya
// =====================================================================
class BiayaFormPage extends StatefulWidget {
  const BiayaFormPage({super.key, this.item, this.initialBudidayaId});
  final Biaya? item;
  final int? initialBudidayaId;
  @override
  State<BiayaFormPage> createState() => _BiayaFormPageState();
}

class _BiayaFormPageState extends State<BiayaFormPage> {
  final key = GlobalKey<FormState>();
  late final jumlah = TextEditingController(
    text: widget.item == null ? '' : widget.item!.jumlah.round().toString(),
  );
  late final ket = TextEditingController(text: widget.item?.keterangan);
  late String kategori = widget.item?.kategori ?? biayaKategoriList.first;
  late int? budidayaId = widget.item?.budidayaId ?? widget.initialBudidayaId;
  late DateTime tanggal = widget.item?.tanggal ?? DateTime.now();

  @override
  void dispose() {
    jumlah.dispose();
    ket.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!key.currentState!.validate()) return;
    final s = AppScope.of(context);
    final ok = await kirim(
      context,
      () => s.saveBiaya(
        widget.item,
        tanggal: tanggal,
        kategori: kategori,
        jumlah: number(jumlah.text)!,
        budidayaId: budidayaId,
        keterangan: ket.text.trim(),
      ),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final s = AppScope.of(context);
    if (await confirm(context, 'Hapus biaya ini?') &&
        mounted &&
        await kirim(context, () => s.deleteBiaya(widget.item!)) &&
        mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final n = number(jumlah.text) ?? 0;
    return Scaffold(
      appBar: elegantAppBar(
        context,
        widget.item == null ? 'Catat Biaya' : 'Edit Biaya',
        actions: [
          if (widget.item != null)
            CircleButton(icon: Icons.delete_outline_rounded, onTap: _delete),
        ],
      ),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          FadeSlideIn(
            child: DarkCard(
              tone: CardTone.ink,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        eyebrow('Pengeluaran', color: champagne),
                        gap(6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RollingText(
                            rupiah(n),
                            style: const TextStyle(
                              fontFamily: headFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                              letterSpacing: -1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        gap(4),
                        Text(
                          kategori,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: emeraldLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: AppIcon(
                        biayaGlyph[kategori]!,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          gap(16),
          FadeSlideIn(
            delay: 1,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Label('Kategori'),
                    gap(10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in biayaKategoriList)
                          ChoiceTile(
                            label: k,
                            icon: biayaGlyph[k]!,
                            selected: k == kategori,
                            onTap: () => setState(() => kategori = k),
                          ),
                      ],
                    ),
                    gap(18),
                    TextFormField(
                      controller: jumlah,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Jumlah (Rp)',
                        prefixIcon: AppIcon(Icons.payments_outlined),
                      ),
                      validator: positive,
                    ),
                    gap(14),
                    DropdownButtonFormField<int?>(
                      initialValue: budidayaId,
                      isExpanded: true,
                      style: dropdownStyle,
                      borderRadius: BorderRadius.circular(18),
                      decoration: const InputDecoration(
                        labelText: 'Untuk siklus',
                        prefixIcon: AppIcon(Icons.spa_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Umum (tidak terikat siklus)'),
                        ),
                        for (final b in s.budidaya)
                          DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              '${b.nama}${b.selesai ? ' (selesai)' : ''}',
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => budidayaId = v),
                    ),
                    gap(14),
                    DateField(
                      label: 'Tanggal',
                      value: tanggal,
                      onChanged: (v) => setState(() => tanggal = v),
                    ),
                    TextFormField(
                      controller: ket,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan (opsional)',
                        prefixIcon: AppIcon(Icons.notes_rounded),
                      ),
                    ),
                    gap(22),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Simpan Biaya'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: headFont,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      color: ink,
    ),
  );
}

/// Ubin pilihan kecil: ikon + teks, tinta saat terpilih.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.92,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? emerald : const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? emerald : hairline),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x40FF5A1F),
                  blurRadius: 14,
                  spreadRadius: -4,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(
              icon,
              size: 17,
              color: selected ? emeraldLight : ink,
              accent: selected ? emeraldLight.withValues(alpha: 0.3) : null,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: selected ? Colors.white : ink,
            ),
          ),
        ],
      ),
    ),
  );
}

// =====================================================================
// Rapor satu siklus
// =====================================================================
class RaporCard extends StatelessWidget {
  const RaporCard({super.key, required this.item});
  final Budidaya item;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.rapor(item);
    final modal = r.biayaPakan + r.biayaLain;
    final perKg = r.panenKg > 0 ? modal / r.panenKg : null;

    Widget stat(String label, String value, {Color color = ink}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: headFont,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.5,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );

    // Nilai FCR: makin kecil makin efisien (pakan basah ±3–5 umum).
    final fcrBagus = r.fcr != null && r.fcr! <= 4;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                Icons.assessment_rounded,
                color: champagne,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.selesai ? 'Rapor akhir' : 'Rapor sementara',
                      style: const TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ink,
                      ),
                    ),
                    Text(
                      '${r.durasi} hari • ${tanggalPendek(item.mulai)} → ${item.tanggalSelesai == null ? (item.selesai ? 'selesai' : 'sekarang') : tanggalPendek(item.tanggalSelesai!)}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              if (r.fcr != null)
                Pill(
                  'FCR ${r.fcr!.toStringAsFixed(1)}',
                  color: fcrBagus ? sage : peach,
                  textColor: fcrBagus ? forest : const Color(0xFFC8400E),
                  icon: fcrBagus
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                ),
            ],
          ),
          gap(16),
          Row(
            children: [
              stat('Pakan', kg(r.pakanKg)),
              stat('Panen', kg(r.panenKg), color: forest),
              if (r.telurG > 0) stat('Telur', '${r.telurG.round()} g'),
            ],
          ),
          gap(14),
          Row(
            children: [
              stat('Biaya pakan', rupiahSingkat(r.biayaPakan)),
              stat('Biaya lain', rupiahSingkat(r.biayaLain)),
              stat(
                'Modal /kg',
                perKg == null ? '–' : rupiahSingkat(perKg),
                color: emeraldLight,
              ),
            ],
          ),
          if (!r.hargaPakanLengkap && r.pakanKg > 0) ...[
            gap(14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: butter,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  AppIcon(Icons.warning_amber_rounded, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sebagian catatan pakan belum punya harga, jadi biaya pakan bisa lebih kecil dari aslinya.',
                      style: TextStyle(fontSize: 12, color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
