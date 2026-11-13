import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'stok_pages.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

const _produkColor = produkColor;
const _chartColors = [emeraldLight, coral, Color(0xFFF7A77A), sky2, pink2];

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});
  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  int range = 1; // 0: 7 hari, 1: 30 hari, 2: semua

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final days = const [7, 30, 0][range];
    final items =
        s.penjualan
            .where(
              (e) =>
                  days == 0 ||
                  today.difference(DateUtils.dateOnly(e.tanggal)).inDays < days,
            )
            .toList()
          ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    final total = s.pendapatan(items);
    final chartDays = days == 0 ? 30 : days;
    final series = s.dailyBy(
      s.penjualan,
      (e) => e.tanggal,
      (e) => e.total,
      days: chartDays,
    );
    final labels = chartDays == 7
        ? last7Labels(now)
        : lastNLabels(chartDays, now);
    // Telur dijual per gram, jadi tidak ikut dihitung dalam kg.
    final perKg = items.where((e) => satuan(e.produk) == 'kg');
    final kgTerjual = perKg.fold<double>(0, (a, e) => a + e.berat);
    final rata = kgTerjual == 0 ? 0.0 : s.pendapatan(perKg) / kgTerjual;
    final piutang = s.pendapatan(items.where((e) => !e.lunas));
    final perProduk = s.pendapatanPerProduk(items);
    final pembeli = s.topPembeli(items);

    return Scaffold(
      floatingActionButton: GradientFab(
        label: 'Catat Penjualan',
        onTap: () => openPage(context, const PenjualanFormPage()),
      ),
      body: PageBody(
        children: [
          const PageHeader(
            'Penjualan',
            eyebrowText: 'Bisnis maggotmu',
            trailing: Mascot(size: 64),
          ),

          // ---------- Hero ----------
          FadeSlideIn(
            child: DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: eyebrow('Total pendapatan', color: champagne),
                      ),
                      SegmentedPills(
                        items: const ['7H', '30H', 'Semua'],
                        index: range,
                        dark: true,
                        onChanged: (i) => setState(() => range = i),
                      ),
                    ],
                  ),
                  gap(10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: FittedBox(
                      key: ValueKey(total),
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rupiah(total),
                        style: const TextStyle(
                          fontFamily: headFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 34,
                          letterSpacing: -0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  gap(4),
                  Text(
                    '${items.length} transaksi • ${kg(kgTerjual)} terjual',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white60,
                    ),
                  ),
                  gap(12),
                  LineAreaChart(
                    values: series,
                    labels: labels,
                    color: champagne,
                    height: 150,
                    dark: true,
                    format: rupiahSingkat,
                  ),
                ],
              ),
            ),
          ),
          gap(14),

          // ---------- KPI ----------
          FadeSlideIn(
            delay: 1,
            child: Row(
              children: [
                Expanded(
                  child: KpiCard(
                    label: 'Rata-rata per kg',
                    value: rupiahSingkat(rata),
                    icon: Icons.sell_rounded,
                    color: sage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label: 'Belum lunas',
                    value: rupiahSingkat(piutang),
                    icon: Icons.hourglass_bottom_rounded,
                    color: peach,
                  ),
                ),
              ],
            ),
          ),

          // ---------- Stok ----------
          SectionTitle(
            'Stok',
            action: 'Kelola',
            onAction: () => openPage(context, const StokPage()),
          ),
          const FadeSlideIn(delay: 2, child: StokGrid()),

          // ---------- Produk ----------
          if (perProduk.isNotEmpty) ...[
            const SectionTitle('Produk terlaris'),
            FadeSlideIn(
              delay: 2,
              child: GlassCard(
                child: DonutChart(
                  centerTitle: rupiahSingkat(total),
                  centerSubtitle: 'pendapatan',
                  segments: [
                    for (var i = 0; i < perProduk.length && i < 5; i++)
                      (
                        label: perProduk[i].key,
                        value: perProduk[i].value,
                        color: _chartColors[i],
                      ),
                  ],
                ),
              ),
            ),
          ],

          // ---------- Pembeli ----------
          if (pembeli.isNotEmpty) ...[
            const SectionTitle('Pembeli setia'),
            FadeSlideIn(
              delay: 3,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    for (final (i, p) in pembeli.take(4).indexed)
                      _BuyerRow(
                        rank: i + 1,
                        name: p.key,
                        value: p.value,
                        max: pembeli.first.value,
                      ),
                  ],
                ),
              ),
            ),
          ],

          // ---------- Transaksi ----------
          const SectionTitle('Riwayat transaksi'),
          if (items.isEmpty)
            const EmptyState('Belum ada penjualan pada periode ini.')
          else
            FadeSlideIn(
              delay: 4,
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
                        onTap: () =>
                            openPage(context, PenjualanFormPage(item: e)),
                        leading: EmojiBubble(
                          produkEmoji[e.produk] ?? '🐛',
                          color: _produkColor[e.produk] ?? sage,
                          size: 44,
                        ),
                        title: e.pembeli,
                        subtitle:
                            '${e.produk} • ${qty(e.produk, e.berat)} • ${tanggalPendek(e.tanggal)}',
                        trailing: rupiah(e.total),
                        trailingSub: e.lunas ? 'Lunas' : 'Belum lunas',
                        trailingSubColor: e.lunas ? forest : emeraldLight,
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

class _BuyerRow extends StatelessWidget {
  const _BuyerRow({
    required this.rank,
    required this.name,
    required this.value,
    required this.max,
  });
  final int rank;
  final String name;
  final double value, max;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rank == 1 ? champagne : const Color(0x0F1C1C1E),
          ),
          child: Text(
            rank == 1 ? '👑' : '$rank',
            style: const TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: max == 0 ? 0 : value / max),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 7,
                    backgroundColor: const Color(0x0F1C1C1E),
                    color: rank == 1 ? const Color(0xFFC9A227) : emeraldLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text(
          rupiahSingkat(value),
          style: const TextStyle(
            fontFamily: headFont,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: ink,
          ),
        ),
      ],
    ),
  );
}

// =====================================================================
// Form penjualan
// =====================================================================
class PenjualanFormPage extends StatefulWidget {
  const PenjualanFormPage({super.key, this.item});
  final Penjualan? item;
  @override
  State<PenjualanFormPage> createState() => _PenjualanFormPageState();
}

class _PenjualanFormPageState extends State<PenjualanFormPage> {
  final key = GlobalKey<FormState>();
  late final pembeli = TextEditingController(text: widget.item?.pembeli);
  late final berat = TextEditingController(
    text: widget.item == null ? '' : _num(widget.item!.berat),
  );
  late final harga = TextEditingController(
    text: _num(widget.item?.harga ?? hargaDefault[produkList.first]!),
  );
  late final catatan = TextEditingController(text: widget.item?.catatan);
  late String produk = widget.item?.produk ?? produkList.first;
  late DateTime tanggal = widget.item?.tanggal ?? DateTime.now();
  late bool lunas = widget.item?.lunas ?? true;

  static String _num(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  @override
  void initState() {
    super.initState();
    berat.addListener(_refresh);
    harga.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    pembeli.dispose();
    berat.dispose();
    harga.dispose();
    catatan.dispose();
    super.dispose();
  }

  /// Stok yang boleh dijual. Saat edit, jumlah transaksi lama
  /// dikembalikan dulu ke stok.
  double _tersedia(String p) {
    final s = AppScope.of(context);
    final old = widget.item;
    return s.stok(p) + (old != null && old.produk == p ? old.berat : 0);
  }

  Future<void> _save() async {
    if (!key.currentState!.validate()) return;
    final s = AppScope.of(context);
    final nav = Navigator.of(context);
    final ok = await kirim(
      context,
      () => s.savePenjualan(
        widget.item,
        tanggal: tanggal,
        pembeli: pembeli.text.trim(),
        produk: produk,
        berat: number(berat.text)!,
        harga: number(harga.text)!,
        lunas: lunas,
        catatan: catatan.text.trim(),
      ),
    );
    if (!ok || !mounted) return;
    final saved = widget.item ?? s.penjualan.last;
    nav.pop();
    showStruk(nav.context, saved, s.stok(produk));
  }

  Future<void> _delete() async {
    final s = AppScope.of(context);
    if (await confirm(context, 'Hapus transaksi ini?') &&
        mounted &&
        await kirim(context, () => s.deletePenjualan(widget.item!)) &&
        mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = number(berat.text) ?? 0;
    final h = number(harga.text) ?? 0;
    return Scaffold(
      appBar: elegantAppBar(
        context,
        widget.item == null ? 'Catat Penjualan' : 'Edit Penjualan',
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
                        eyebrow('Total transaksi', color: champagne),
                        gap(6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rupiah(b * h),
                            style: const TextStyle(
                              fontFamily: headFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        gap(4),
                        Text(
                          '${qty(produk, b)} × ${rupiah(h)}/${satuan(produk)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Mascot(size: 82),
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
                    const Text(
                      'Produk',
                      style: TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ink,
                      ),
                    ),
                    gap(10),
                    ProdukPicker(
                      items: produkList,
                      selected: produk,
                      caption: (p) => 'Stok ${qty(p, _tersedia(p))}',
                      onChanged: (p) => setState(() {
                        produk = p;
                        harga.text = _num(hargaDefault[p]!);
                        key.currentState?.validate();
                      }),
                    ),
                    gap(18),
                    TextFormField(
                      controller: pembeli,
                      decoration: const InputDecoration(
                        labelText: 'Nama pembeli',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: requiredText,
                    ),
                    gap(14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: berat,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Jumlah (${satuan(produk)})',
                              prefixIcon: const Icon(Icons.scale_rounded),
                            ),
                            validator: (v) {
                              final e = positive(v);
                              if (e != null) return e;
                              final ada = _tersedia(produk);
                              if (number(v!)! > ada + 1e-9) {
                                return ada <= 0
                                    ? 'Stok habis'
                                    : 'Stok tinggal ${qty(produk, ada)}';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: harga,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Harga/${satuan(produk)}',
                              prefixIcon: const Icon(Icons.payments_outlined),
                            ),
                            validator: positive,
                          ),
                        ),
                      ],
                    ),
                    gap(14),
                    DateField(
                      label: 'Tanggal penjualan',
                      value: tanggal,
                      onChanged: (v) => setState(() => tanggal = v),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: lunas ? sage : peach,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          IconBubble(
                            lunas
                                ? Icons.verified_rounded
                                : Icons.hourglass_bottom_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sudah lunas',
                                  style: TextStyle(
                                    fontFamily: headFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: ink,
                                  ),
                                ),
                                Text(
                                  lunas
                                      ? 'Pembayaran sudah diterima'
                                      : 'Masih tercatat sebagai piutang',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: lunas,
                            activeTrackColor: emeraldLight,
                            onChanged: (v) => setState(() => lunas = v),
                          ),
                        ],
                      ),
                    ),
                    gap(14),
                    TextFormField(
                      controller: catatan,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    gap(22),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Simpan Penjualan'),
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

/// Pop-up struk setelah transaksi tersimpan (di dalam aplikasi).
Future<void> showStruk(BuildContext context, Penjualan p, double sisaStok) {
  final u = satuan(p.produk);
  final teks = StringBuffer()
    ..writeln('🧾 *Struk MaggotKu*')
    ..writeln(tanggalPanjang(p.tanggal))
    ..writeln()
    ..writeln('Pembeli : ${p.pembeli}')
    ..writeln('Produk  : ${p.produk}')
    ..writeln('Jumlah  : ${qty(p.produk, p.berat)} × ${rupiah(p.harga)}/$u')
    ..writeln('Total   : *${rupiah(p.total)}*')
    ..writeln('Status  : ${p.lunas ? 'LUNAS ✅' : 'BELUM LUNAS ⏳'}')
    ..writeln()
    ..write('Terima kasih sudah berbelanja 🐛');

  Widget row(String a, String b, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(a, style: const TextStyle(fontSize: 13, color: muted)),
        const Spacer(),
        Flexible(
          child: Text(
            b,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: bold ? headFont : bodyFont,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: bold ? 16 : 13.5,
              color: ink,
            ),
          ),
        ),
      ],
    ),
  );

  return showDialog<void>(
    context: context,
    builder: (c) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DarkCard(
            child: Column(
              children: [
                const Mascot(size: 86),
                gap(6),
                eyebrow('Transaksi berhasil', color: champagne),
                gap(6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rupiah(p.total),
                    style: const TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                gap(8),
                Pill(
                  p.lunas ? 'Lunas' : 'Belum lunas',
                  color: Colors.white.withValues(alpha: 0.16),
                  textColor: Colors.white,
                  icon: p.lunas
                      ? Icons.verified_rounded
                      : Icons.hourglass_bottom_rounded,
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  row('Pembeli', p.pembeli),
                  row('Produk', '${produkEmoji[p.produk] ?? ''} ${p.produk}'),
                  row(
                    'Jumlah',
                    '${qty(p.produk, p.berat)} × ${rupiah(p.harga)}/$u',
                  ),
                  row('Tanggal', tanggalPanjang(p.tanggal)),
                  const Divider(height: 18),
                  row('Total', rupiah(p.total), bold: true),
                  gap(10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sisaStok <= 0 ? peach : sage,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      sisaStok <= 0
                          ? 'Stok ${p.produk} habis 📦'
                          : 'Sisa stok ${p.produk}: ${qty(p.produk, sisaStok)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: ink,
                      ),
                    ),
                  ),
                  gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(text: teks.toString()),
                          ),
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Bagikan'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Selesai'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
