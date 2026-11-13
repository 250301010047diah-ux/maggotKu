import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

const produkColor = {
  'Maggot segar': sage,
  'Maggot kering': butter,
  'Pupa': pink,
  'Telur': lavender,
  'Kasgot (pupuk)': sky,
};

/// Pemilih produk berbentuk ubin 2 kolom.
class ProdukPicker extends StatelessWidget {
  const ProdukPicker({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.caption,
  });
  final List<String> items;
  final String selected;
  final ValueChanged<String> onChanged;

  /// Teks kecil di bawah nama produk (mis. stok atau harga).
  final String Function(String produk)? caption;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var r = 0; r < items.length; r += 2) ...[
        if (r > 0) const SizedBox(height: 10),
        Row(
          children: [
            for (var c = r; c < math.min(r + 2, items.length); c++) ...[
              if (c > r) const SizedBox(width: 10),
              Expanded(child: _tile(items[c])),
            ],
            if (r + 1 >= items.length) ...[
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ],
        ),
      ],
    ],
  );

  Widget _tile(String p) {
    final sel = p == selected;
    return Pressable(
      onTap: () => onChanged(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? emerald : const Color(0x0A1C1C1E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(produkEmoji[p] ?? '🐛', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: sel ? Colors.white : ink,
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption!(p),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: sel ? Colors.white70 : muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu ringkas stok 6 produk (dipakai di tab Jual).
class StokGrid extends StatelessWidget {
  const StokGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        for (var r = 0; r < produkList.length; r += 3) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var c = r; c < r + 3; c++) ...[
                if (c > r) const SizedBox(width: 10),
                Expanded(
                  child: c < produkList.length
                      ? _cell(s, produkList[c])
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _cell(AppState s, String p) {
    final v = s.stok(p);
    return GlassCard(
      glow: false,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiBubble(produkEmoji[p] ?? '🐛', color: produkColor[p]!, size: 32),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              qty(p, v),
              style: TextStyle(
                fontFamily: headFont,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: v <= 0 ? muted : ink,
              ),
            ),
          ),
          Text(
            p,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: muted),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Halaman Stok
// =====================================================================
class StokPage extends StatelessWidget {
  const StokPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    // Riwayat pergerakan stok: panen (+), penjualan (−), mutasi (±).
    final riwayat =
        <({DateTime t, String produk, double j, String judul, String sub})>[
          for (final c in s.panen)
            (
              t: c.tanggal,
              produk: s.produkOf(c),
              j: c.berat,
              judul: 'Panen ${s.produkOf(c)}',
              sub: s.budidayaById(c.budidayaId)?.nama ?? '-',
            ),
          for (final p in s.penjualan)
            (
              t: p.tanggal,
              produk: p.produk,
              j: -p.berat,
              judul: 'Terjual • ${p.produk}',
              sub: p.pembeli,
            ),
          for (final m in s.mutasi)
            (
              t: m.tanggal,
              produk: m.produk,
              j: m.jumlah,
              judul: switch (m.jenis) {
                'olah' => 'Olah • ${m.produk}',
                'tebar' => 'Telur ditebar',
                _ => 'Penyesuaian • ${m.produk}',
              },
              sub: m.keterangan,
            ),
        ]..sort((a, b) => b.t.compareTo(a.t));

    return Scaffold(
      appBar: elegantAppBar(context, 'Stok'),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const FadeSlideIn(child: StokGrid()),
          gap(14),
          FadeSlideIn(
            delay: 1,
            child: Row(
              children: [
                Expanded(
                  child: _action(
                    context,
                    '🌾',
                    'Olah',
                    'Fresh → kering',
                    () => openPage(context, const OlahPage()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _action(
                    context,
                    '⚖️',
                    'Penyesuaian',
                    'Stok awal, rusak…',
                    () => openPage(context, const PenyesuaianPage()),
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Riwayat stok'),
          if (riwayat.isEmpty)
            const EmptyState(
              'Stok bertambah dari catat panen, olah, atau penyesuaian.',
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
                    for (final (i, r) in riwayat.take(60).indexed) ...[
                      if (i > 0) const Divider(indent: 56),
                      ActivityRow(
                        leading: EmojiBubble(
                          produkEmoji[r.produk] ?? '🐛',
                          color: produkColor[r.produk] ?? sage,
                          size: 42,
                        ),
                        title: r.judul,
                        subtitle: '${tanggalPendek(r.t)} • ${r.sub}',
                        trailing:
                            '${r.j >= 0 ? '+' : '−'}${qty(r.produk, r.j.abs())}',
                        trailingColor: r.j >= 0 ? forest : emeraldLight,
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

  Widget _action(
    BuildContext context,
    String emoji,
    String title,
    String sub,
    VoidCallback onTap,
  ) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        EmojiBubble(emoji, color: peach, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ink,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// =====================================================================
// Olah: maggot fresh → maggot kering
// =====================================================================
class OlahPage extends StatefulWidget {
  const OlahPage({super.key});
  @override
  State<OlahPage> createState() => _OlahPageState();
}

class _OlahPageState extends State<OlahPage> {
  final key = GlobalKey<FormState>();
  final fresh = TextEditingController();
  final kering = TextEditingController();
  DateTime tanggal = DateTime.now();
  bool _keringManual = false;

  /// Perkiraan umum: kadar air larva tinggi, 1 kg kering ≈ 3 kg fresh.
  static const _rasio = 3.0;

  @override
  void initState() {
    super.initState();
    fresh.addListener(() {
      if (_keringManual) return;
      final f = number(fresh.text);
      kering.text = f == null ? '' : (f / _rasio).toStringAsFixed(2);
      setState(() {});
    });
  }

  @override
  void dispose() {
    fresh.dispose();
    kering.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final stokFresh = s.stok('Maggot segar');
    return Scaffold(
      appBar: elegantAppBar(context, 'Olah Maggot'),
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
                        eyebrow('Stok maggot fresh', color: champagne),
                        gap(6),
                        Text(
                          qty('Maggot segar', stokFresh),
                          style: const TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                        gap(4),
                        const Text(
                          'Maggot kering hanya bisa didapat dari olahan maggot fresh.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text('🐛 → 🌾', style: TextStyle(fontSize: 26)),
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
                    TextFormField(
                      controller: fresh,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Maggot fresh yang diolah (kg)',
                        prefixIcon: Icon(Icons.scale_rounded),
                      ),
                      validator: (v) {
                        final e = positive(v);
                        if (e != null) return e;
                        if (number(v!)! > stokFresh + 1e-9) {
                          return 'Stok fresh hanya ${qty('Maggot segar', stokFresh)}';
                        }
                        return null;
                      },
                    ),
                    gap(14),
                    TextFormField(
                      controller: kering,
                      onChanged: (_) => _keringManual = true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Hasil maggot kering (kg)',
                        helperText:
                            'Otomatis ±1/3 dari berat fresh, bisa diubah',
                        prefixIcon: Icon(Icons.wb_sunny_rounded),
                      ),
                      validator: (v) {
                        final e = positive(v);
                        if (e != null) return e;
                        final f = number(fresh.text) ?? 0;
                        if (number(v!)! > f) {
                          return 'Hasil kering tidak bisa melebihi berat fresh';
                        }
                        return null;
                      },
                    ),
                    gap(14),
                    DateField(
                      label: 'Tanggal olah',
                      value: tanggal,
                      onChanged: (v) => setState(() => tanggal = v),
                    ),
                    gap(8),
                    ElevatedButton(
                      onPressed: () async {
                        if (!key.currentState!.validate()) return;
                        final m = ScaffoldMessenger.of(context);
                        final ok = await kirim(
                          context,
                          () => s.olah(
                            number(fresh.text)!,
                            number(kering.text)!,
                            tanggal,
                          ),
                        );
                        if (!ok || !context.mounted) return;
                        Navigator.pop(context);
                        m.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Olahan tersimpan, stok diperbarui 🌾',
                            ),
                          ),
                        );
                      },
                      child: const Text('Simpan Olahan'),
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

// =====================================================================
// Penyesuaian stok
// =====================================================================
class PenyesuaianPage extends StatefulWidget {
  const PenyesuaianPage({super.key});
  @override
  State<PenyesuaianPage> createState() => _PenyesuaianPageState();
}

class _PenyesuaianPageState extends State<PenyesuaianPage> {
  static const _alasanTambah = ['Stok awal', 'Koreksi', 'Lainnya'];
  static const _alasanKurang = [
    'Rusak',
    'Susut',
    'Dipakai sendiri',
    'Koreksi',
    'Lainnya',
  ];
  final key = GlobalKey<FormState>();
  final jumlah = TextEditingController();
  String produk = produkList.first;
  bool tambah = true;
  String alasan = 'Stok awal';
  DateTime tanggal = DateTime.now();

  @override
  void dispose() {
    jumlah.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final stokNow = s.stok(produk);
    final alasanList = tambah ? _alasanTambah : _alasanKurang;
    return Scaffold(
      appBar: elegantAppBar(context, 'Penyesuaian Stok'),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          FadeSlideIn(
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
                      caption: (p) => 'Stok ${qty(p, s.stok(p))}',
                      onChanged: (p) => setState(() => produk = p),
                    ),
                    gap(16),
                    SegmentedPills(
                      items: const ['＋ Tambah', '－ Kurangi'],
                      index: tambah ? 0 : 1,
                      expand: true,
                      onChanged: (i) => setState(() {
                        tambah = i == 0;
                        alasan = (tambah ? _alasanTambah : _alasanKurang).first;
                      }),
                    ),
                    gap(14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in alasanList)
                          Pressable(
                            onTap: () => setState(() => alasan = a),
                            child: Pill(
                              a,
                              color: alasan == a
                                  ? emerald
                                  : const Color(0x0F1C1C1E),
                              textColor: alasan == a ? Colors.white : ink,
                            ),
                          ),
                      ],
                    ),
                    gap(14),
                    TextFormField(
                      controller: jumlah,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Jumlah (${satuan(produk)})',
                        helperText: 'Stok sekarang: ${qty(produk, stokNow)}',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) {
                        final e = positive(v);
                        if (e != null) return e;
                        if (!tambah && number(v!)! > stokNow + 1e-9) {
                          return 'Tidak bisa melebihi stok (${qty(produk, stokNow)})';
                        }
                        return null;
                      },
                    ),
                    gap(14),
                    DateField(
                      label: 'Tanggal',
                      value: tanggal,
                      onChanged: (v) => setState(() => tanggal = v),
                    ),
                    gap(8),
                    ElevatedButton(
                      onPressed: () async {
                        if (!key.currentState!.validate()) return;
                        final n = number(jumlah.text)!;
                        final m = ScaffoldMessenger.of(context);
                        final ok = await kirim(
                          context,
                          () => s.addMutasi(
                            produk,
                            tambah ? n : -n,
                            'penyesuaian',
                            alasan,
                            tanggal,
                          ),
                        );
                        if (!ok || !context.mounted) return;
                        Navigator.pop(context);
                        m.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Stok $produk ${tambah ? 'ditambah' : 'dikurangi'} ${qty(produk, n)}',
                            ),
                          ),
                        );
                      },
                      child: const Text('Simpan Penyesuaian'),
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
