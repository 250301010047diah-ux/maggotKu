import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'stok_pages.dart';
import 'stok_pakan_pages.dart';

/// Tab Catatan: pakan & panen dalam satu halaman.
class CatatanPage extends StatefulWidget {
  const CatatanPage({super.key});
  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  bool isPakan = true;

  /// Tab ketiga: stok pakan di gudang.
  bool gudang = false;
  int? selected;
  int range = 0; // 0: 1 bulan, 1: 3 bulan, 2: 1 tahun

  static const _rangeLabel = ['1 bulan', '3 bulan', '1 tahun'];

  bool get _filtered => selected != null;

  void _resetFilter() => setState(() => selected = null);

  /// Kelompok waktu grafik sesuai rentang:
  /// harian (1 bulan), mingguan (3 bulan), bulanan (1 tahun).
  List<Bucket> get _buckets => switch (range) {
    0 => daysBack(30),
    1 => weeksBack(13),
    _ => monthsBack(12),
  };

  Widget _pilihMode() => SegmentedPills(
    items: const ['🥬 Pakan', '🧺 Panen', '🏚️ Stok Pakan'],
    index: gudang ? 2 : (isPakan ? 0 : 1),
    expand: true,
    onChanged: (i) => setState(() {
      gudang = i == 2;
      if (i < 2) isPakan = i == 0;
      selected = null;
    }),
  );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (gudang) {
      return Scaffold(
        floatingActionButton: GradientFab(
          label: 'Pakan Masuk',
          onTap: () => openPage(context, const PakanMasukPage()),
        ),
        body: PageBody(
          children: [
            const PageHeader('Catatan', eyebrowText: 'Stok pakan di gudang'),
            FadeSlideIn(child: _pilihMode()),
            gap(16),
            const StokPakanView(),
          ],
        ),
      );
    }
    final label = isPakan ? 'pakan' : 'panen';
    final buckets = _buckets;
    final from = buckets.first.start;
    final items =
        (isPakan ? s.pakan : s.panen)
            .where(
              (e) =>
                  (selected == null || e.budidayaId == selected) &&
                  !e.tanggal.isBefore(from),
            )
            .toList()
          ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    final series = sumBuckets(items, (e) => e.tanggal, s.kgOf, buckets);

    return Scaffold(
      floatingActionButton: GradientFab(
        label: isPakan ? 'Tambah Pakan' : 'Catat Panen',
        onTap: () async {
          if (s.budidaya.isEmpty) {
            toast(context, 'Buat kelompok budidaya terlebih dahulu.');
            return;
          }
          final messenger = ScaffoldMessenger.of(context);
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CatatanFormPage(isPakan: isPakan),
            ),
          );
          if (saved != true || !mounted || !_filtered) return;
          _resetFilter();
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Tersimpan! Filter direset supaya catatan baru terlihat ✨',
              ),
            ),
          );
        },
      ),
      body: PageBody(
        children: [
          const PageHeader('Catatan', eyebrowText: 'Pakan & panen harian'),
          FadeSlideIn(child: _pilihMode()),
          gap(10),
          FadeSlideIn(
            child: SegmentedPills(
              items: const ['1 Bulan', '3 Bulan', '1 Tahun'],
              index: range,
              expand: true,
              onChanged: (i) => setState(() => range = i),
            ),
          ),
          gap(16),
          FadeSlideIn(
            key: ValueKey('hero$isPakan$range'),
            delay: 1,
            child: DarkCard(
              tone: CardTone.ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            eyebrow(
                              'Total $label • ${_rangeLabel[range]}',
                              color: champagne,
                            ),
                            gap(6),
                            Text(
                              kg(s.total(items)),
                              style: const TextStyle(
                                fontFamily: headFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${items.length} catatan • ${const ['per hari', 'per minggu', 'per bulan'][range]}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isPakan ? '🥬' : '🧺',
                        style: const TextStyle(fontSize: 44),
                      ),
                    ],
                  ),
                  gap(14),
                  PeriodChart(
                    height: 150,
                    dark: true,
                    buckets: buckets,
                    values: series,
                    color: isPakan ? emeraldLight : champagne,
                  ),
                ],
              ),
            ),
          ),
          gap(18),
          FadeSlideIn(
            delay: 2,
            child: DropdownButtonFormField<int?>(
              key: ValueKey('filter$isPakan$selected'),
              initialValue: selected,
              isExpanded: true,
              style: dropdownStyle,
              borderRadius: BorderRadius.circular(18),
              decoration: const InputDecoration(
                labelText: 'Filter kelompok',
                prefixIcon: Icon(Icons.filter_list_rounded),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Semua kelompok'),
                ),
                ...s.budidaya.map(
                  (e) =>
                      DropdownMenuItem<int?>(value: e.id, child: Text(e.nama)),
                ),
              ],
              onChanged: (v) => setState(() => selected = v),
            ),
          ),
          SectionTitle('Riwayat $label'),
          if (items.isEmpty) ...[
            EmptyState(
              _filtered
                  ? 'Tidak ada catatan $label untuk kelompok ini dalam ${_rangeLabel[range]} terakhir.'
                  : 'Belum ada catatan $label dalam ${_rangeLabel[range]} terakhir. Tekan tombol tambah di bawah.',
            ),
            if (_filtered) ...[
              gap(12),
              OutlinedButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Reset filter'),
              ),
            ],
          ] else
            for (final (i, e) in items.indexed)
              FadeSlideIn(
                key: ValueKey('$isPakan-${e.id}'),
                delay: math.min(i, 6) + 3,
                child: _CatatanCard(item: e, isPakan: isPakan),
              ),
        ],
      ),
    );
  }
}

class _CatatanCard extends StatelessWidget {
  const _CatatanCard({required this.item, required this.isPakan});
  final Catatan item;
  final bool isPakan;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final e = item;
    return GlassCard(
      accent: isPakan ? emeraldLight : forest,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                IconBubble(
                  isPakan
                      ? Icons.restaurant_rounded
                      : Icons.agriculture_rounded,
                  color: isPakan ? peach : butter,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.budidayaById(e.budidayaId)?.nama ??
                            'Kelompok tidak ada',
                        style: const TextStyle(
                          fontFamily: headFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          color: ink,
                        ),
                      ),
                      Text(
                        isPakan
                            ? '${tanggalPanjang(e.tanggal)}${e.jenis.isNotEmpty ? ' • ${e.jenis}' : ''}'
                            : '${tanggalPanjang(e.tanggal)} • ${produkEmoji[s.produkOf(e)] ?? ''} ${s.produkOf(e)}',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  isPakan ? kg(e.berat) : qty(s.produkOf(e), e.berat),
                  style: const TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: emeraldLight,
                  ),
                ),
              ],
            ),
          ),
          if (e.catatan.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12, right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x0A1C1C1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(e.catatan, style: const TextStyle(fontSize: 13)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => openPage(
                  context,
                  CatatanFormPage(isPakan: isPakan, item: e),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC0503A),
                ),
                onPressed: () async {
                  if (!isPakan && s.stok(s.produkOf(e)) - e.berat < -1e-9) {
                    toast(
                      context,
                      'Tidak bisa dihapus: hasil panen ini sudah terjual/diolah.',
                    );
                    return;
                  }
                  if (await confirm(context, 'Hapus catatan ini?') &&
                      context.mounted) {
                    await kirim(context, () => s.deleteCatatan(isPakan, e));
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CatatanFormPage extends StatefulWidget {
  const CatatanFormPage({
    super.key,
    required this.isPakan,
    this.item,
    this.initialBudidayaId,
  });
  final bool isPakan;
  final Catatan? item;
  final int? initialBudidayaId;
  @override
  State<CatatanFormPage> createState() => _CatatanFormPageState();
}

class _CatatanFormPageState extends State<CatatanFormPage> {
  final key = GlobalKey<FormState>();
  late final jenis = TextEditingController(text: widget.item?.jenis);

  /// Jenis pakan terpilih (daftar tetap).
  late String? jenisPakan = widget.item == null
      ? null
      : jenisPakanOf(widget.item!.jenis);

  /// Peringatan (tidak memblokir) bila pakan melebihi stok gudang.
  String? _kurangStok(AppState s) {
    if (!widget.isPakan || jenisPakan == null) return null;
    final b = number(berat.text) ?? 0;
    final old = widget.item;
    final ada =
        s.stokPakan(jenisPakan!) +
        (old != null && jenisPakanOf(old.jenis) == jenisPakan ? old.berat : 0);
    if (b <= ada + 1e-9) return null;
    return ada <= 0
        ? '⚠️ Stok ${jenisPakan!} di gudang kosong. Tetap bisa disimpan, '
              'tapi jangan lupa catat pakan masuknya.'
        : '⚠️ Stok ${jenisPakan!} di gudang tinggal ${kg(ada)}. Tetap bisa '
              'disimpan, tapi jangan lupa catat pakan masuknya.';
  }

  late final berat = TextEditingController(text: widget.item?.berat.toString());
  late final catatan = TextEditingController(text: widget.item?.catatan);
  late int? budidayaId = widget.item?.budidayaId ?? widget.initialBudidayaId;
  late DateTime date = widget.item?.tanggal ?? DateTime.now();

  /// Produk hasil panen (hanya untuk catatan panen).
  late String produk = widget.item != null
      ? (widget.item!.jenis.isEmpty ? 'Maggot segar' : widget.item!.jenis)
      : _produkBawaan(budidayaId);

  String _produkBawaan(int? id) {
    final b = id == null ? null : AppScope.of(context).budidayaById(id);
    return tujuanProduk[b?.tujuan] ?? 'Maggot segar';
  }

  /// Saat edit panen: hasil yang sudah terjual/diolah tidak boleh
  /// membuat stok jadi minus.
  String? _cekStokEdit(double baru) {
    final old = widget.item;
    if (widget.isPakan || old == null) return null;
    final s = AppScope.of(context);
    final oldProduk = s.produkOf(old);
    final sisa =
        s.stok(oldProduk) - old.berat + (produk == oldProduk ? baru : 0);
    if (sisa < -1e-9) {
      final terpakai = old.berat - s.stok(oldProduk);
      return 'Sudah terjual/diolah ${qty(oldProduk, terpakai)}, '
          'minimal ${qty(oldProduk, terpakai)}';
    }
    return null;
  }

  @override
  void dispose() {
    jenis.dispose();
    berat.dispose();
    catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final title = widget.isPakan ? 'Pakan' : 'Panen';
    final verb = widget.item == null
        ? (widget.isPakan ? 'Tambah' : 'Catat')
        : 'Edit';
    return Scaffold(
      appBar: elegantAppBar(context, '$verb $title'),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          FadeSlideIn(
            child: Row(
              children: [
                const Mascot(size: 84),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isPakan
                        ? 'Maggi lapar nih! Catat makanannya hari ini 🥬'
                        : 'Yeay, waktunya panen! Catat hasilnya 🧺',
                    style: const TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.35,
                      color: ink,
                    ),
                  ),
                ),
              ],
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
                    DropdownButtonFormField<int>(
                      initialValue: budidayaId,
                      isExpanded: true,
                      style: dropdownStyle,
                      borderRadius: BorderRadius.circular(18),
                      decoration: const InputDecoration(
                        labelText: 'Kelompok budidaya',
                        prefixIcon: Icon(Icons.spa_outlined),
                      ),
                      items: s.budidaya
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.nama),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        budidayaId = v;
                        if (!widget.isPakan && widget.item == null) {
                          produk = _produkBawaan(v);
                        }
                      }),
                      validator: (v) =>
                          v == null ? 'Pilih kelompok budidaya' : null,
                    ),
                    if (!widget.isPakan) ...[
                      gap(16),
                      const Text(
                        'Apa yang dipanen?',
                        style: TextStyle(
                          fontFamily: headFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ink,
                        ),
                      ),
                      gap(10),
                      ProdukPicker(
                        items: produkPanen,
                        selected: produk,
                        caption: (p) => 'Stok ${qty(p, s.stok(p))}',
                        onChanged: (p) => setState(() => produk = p),
                      ),
                      gap(8),
                      const Text(
                        'Maggot kering didapat dari menu Stok → Olah.',
                        style: TextStyle(fontSize: 11.5, color: muted),
                      ),
                    ],
                    gap(14),
                    DateField(
                      label: widget.isPakan
                          ? 'Tanggal pemberian pakan'
                          : 'Tanggal panen',
                      value: date,
                      onChanged: (v) => setState(() => date = v),
                    ),
                    if (widget.isPakan) ...[
                      const Text(
                        'Jenis pakan',
                        style: TextStyle(
                          fontFamily: headFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ink,
                        ),
                      ),
                      gap(10),
                      JenisPakanPicker(
                        selected: jenisPakan,
                        onChanged: (j) => setState(() => jenisPakan = j),
                      ),
                      gap(14),
                    ],
                    TextFormField(
                      controller: berat,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.isPakan
                            ? 'Berat (kg)'
                            : 'Jumlah (${satuan(produk)})',
                        prefixIcon: const Icon(Icons.scale_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          positive(v) ?? _cekStokEdit(number(v!)!),
                    ),
                    if (_kurangStok(s) case final pesan?) ...[
                      gap(8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: peach,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          pesan,
                          style: const TextStyle(fontSize: 12.5, color: ink),
                        ),
                      ),
                    ],
                    gap(14),
                    TextFormField(
                      controller: catatan,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    gap(22),
                    ElevatedButton(
                      onPressed: () async {
                        if (!key.currentState!.validate()) return;
                        if (widget.isPakan && jenisPakan == null) {
                          toast(context, 'Pilih jenis pakan dulu ya.');
                          return;
                        }
                        final ok = await kirim(
                          context,
                          () => s.saveCatatan(
                            widget.isPakan,
                            widget.item,
                            budidayaId!,
                            date,
                            number(berat.text)!,
                            catatan.text.trim(),
                            widget.isPakan ? jenisPakan! : produk,
                          ),
                        );
                        if (ok && context.mounted) Navigator.pop(context, true);
                      },
                      child: Text('Simpan $title'),
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
