import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _warna = {
  'Sisa sayur': sage,
  'Ampas tahu': butter,
  'Kulit buah': peach,
  'Dedak': sky,
  'Bungkil sawit': lavender,
  'Lainnya': pink,
};

/// Pemilih jenis pakan berbentuk ubin 2 kolom (daftar tetap).
class JenisPakanPicker extends StatelessWidget {
  const JenisPakanPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        for (var r = 0; r < jenisPakanList.length; r += 2) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (
                var c = r;
                c < math.min(r + 2, jenisPakanList.length);
                c++
              ) ...[
                if (c > r) const SizedBox(width: 10),
                Expanded(child: _tile(s, jenisPakanList[c])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _tile(AppState s, String j) {
    final sel = j == selected;
    return Pressable(
      onTap: () => onChanged(j),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? emerald : const Color(0x0A1C1C1E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(jenisPakanEmoji[j]!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    j,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: sel ? Colors.white : ink,
                    ),
                  ),
                  Text(
                    'Stok ${kg(s.stokPakan(j))}',
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

/// Isi tab "Stok Pakan" di halaman Catatan.
class StokPakanView extends StatelessWidget {
  const StokPakanView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = DateTime.now();
    final awalBulan = DateTime(now.year, now.month);
    final belanja = s.biayaPakan(awalBulan, DateTime(now.year, now.month + 1));
    final harga = s.hargaPakanRata();
    final total = jenisPakanList.fold<double>(
      0,
      (a, j) => a + math.max(0, s.stokPakan(j)),
    );
    final lewat = s.pakanLewatSegar();

    // Riwayat gudang: masuk/penyesuaian (±) dan pemberian pakan (−).
    final riwayat =
        <
            ({
              DateTime t,
              String jenis,
              double j,
              String judul,
              String sub,
              MutasiPakan? m,
            })
          >[
            for (final m in s.mutasiPakan)
              (
                t: m.tanggal,
                jenis: m.jenis,
                j: m.jumlah,
                judul: m.tipe == 'masuk'
                    ? 'Pakan masuk • ${m.jenis}'
                    : 'Penyesuaian • ${m.jenis}',
                sub: [
                  if (m.harga != null) '${rupiah(m.harga!)}/kg',
                  if (m.keterangan.isNotEmpty) m.keterangan,
                ].join(' • '),
                m: m,
              ),
            for (final p in s.pakan)
              (
                t: p.tanggal,
                jenis: jenisPakanOf(p.jenis),
                j: -p.berat,
                judul: 'Diberikan • ${jenisPakanOf(p.jenis)}',
                sub: s.budidayaById(p.budidayaId)?.nama ?? '-',
                m: null,
              ),
          ]
          ..sort((a, b) => b.t.compareTo(a.t));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
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
                          eyebrow('Total stok pakan', color: champagne),
                          gap(6),
                          Text(
                            kg(total),
                            style: const TextStyle(
                              fontFamily: headFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Gudang bersama semua kandang',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('🏚️', style: TextStyle(fontSize: 40)),
                  ],
                ),
                gap(16),
                Row(
                  children: [
                    HeroStat('Belanja bulan ini', rupiahSingkat(belanja)),
                    const HeroDivider(),
                    HeroStat(
                      'Harga rata-rata',
                      harga == null ? '-' : '${rupiahSingkat(harga)}/kg',
                    ),
                    const HeroDivider(),
                    HeroStat('Perlu dicek', '${lewat.length}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        gap(14),
        FadeSlideIn(
          delay: 2,
          child: Row(
            children: [
              Expanded(
                child: _aksi(
                  context,
                  '📥',
                  'Pakan masuk',
                  'Beli / terima',
                  () => openPage(context, const PakanMasukPage()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _aksi(
                  context,
                  '⚖️',
                  'Penyesuaian',
                  'Busuk, stok awal…',
                  () => openPage(
                    context,
                    const PakanMasukPage(penyesuaian: true),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Stok per jenis'),
        for (final (i, j) in jenisPakanList.indexed)
          FadeSlideIn(delay: math.min(i, 5) + 3, child: _kartuJenis(s, j)),
        const SectionTitle('Riwayat gudang'),
        if (riwayat.isEmpty)
          const EmptyState(
            'Catat pakan masuk dulu supaya stok gudang terhitung.',
          )
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, r) in riwayat.take(60).indexed) ...[
                  if (i > 0) const Divider(indent: 56),
                  ActivityRow(
                    onTap: r.m == null ? null : () => _hapus(context, s, r.m!),
                    leading: EmojiBubble(
                      jenisPakanEmoji[r.jenis] ?? '📦',
                      color: _warna[r.jenis] ?? sage,
                      size: 42,
                    ),
                    title: r.judul,
                    subtitle: [
                      tanggalPendek(r.t),
                      if (r.sub.isNotEmpty) r.sub,
                    ].join(' • '),
                    trailing: '${r.j >= 0 ? '+' : '−'}${kg(r.j.abs())}',
                    trailingColor: r.j >= 0 ? forest : emeraldLight,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _hapus(BuildContext context, AppState s, MutasiPakan m) async {
    if (await confirm(context, 'Hapus catatan ${m.jenis} ${kg(m.jumlah)}?') &&
        context.mounted) {
      await kirim(context, () => s.deleteMutasiPakan(m));
    }
  }

  Widget _kartuJenis(AppState s, String j) {
    final stok = s.stokPakan(j);
    final hari = s.sisaHariPakan(j);
    final rata = s.pemakaianHarian(j);
    final hampir = hari != null && hari <= 2;
    final basi = s.pakanLewatSegar().where((x) => x.jenis == j).toList();
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      accent: hampir ? emeraldLight : (basi.isNotEmpty ? gold : null),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmojiBubble(jenisPakanEmoji[j]!, color: _warna[j]!, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j,
                      style: const TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ink,
                      ),
                    ),
                    Text(
                      rata > 0
                          ? 'Pakai ±${kg(double.parse(rata.toStringAsFixed(2)))}/hari'
                          : 'Belum dipakai 7 hari terakhir',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    kg(stok),
                    style: TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: stok < 0 ? emeraldLight : ink,
                    ),
                  ),
                  if (hari != null)
                    Text(
                      hari <= 0
                          ? 'Habis'
                          : 'cukup ±${hari < 1 ? '<1' : hari.floor()} hari',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: hampir ? emeraldLight : forest,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (hampir || basi.isNotEmpty) ...[
            gap(10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hampir)
                  const Pill('Hampir habis', icon: Icons.warning_amber_rounded),
                for (final b in basi)
                  Pill(
                    '${kg(b.sisa)} masuk ${b.umur} hari lalu, cek kesegaran',
                    color: butter,
                    textColor: ink,
                    icon: Icons.schedule_rounded,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _aksi(
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

/// Form pakan masuk / penyesuaian stok pakan.
class PakanMasukPage extends StatefulWidget {
  const PakanMasukPage({super.key, this.penyesuaian = false});
  final bool penyesuaian;
  @override
  State<PakanMasukPage> createState() => _PakanMasukPageState();
}

class _PakanMasukPageState extends State<PakanMasukPage> {
  static const _alasanTambah = ['Stok awal', 'Koreksi'];
  static const _alasanKurang = ['Busuk', 'Terbuang', 'Koreksi'];
  final key = GlobalKey<FormState>();
  final jumlah = TextEditingController();
  final harga = TextEditingController();
  String jenis = jenisPakanList.first;
  DateTime tanggal = DateTime.now();
  bool tambah = true;
  String alasan = 'Stok awal';

  @override
  void initState() {
    super.initState();
    jumlah.addListener(() => setState(() {}));
    harga.addListener(() => setState(() {}));
    if (widget.penyesuaian) alasan = 'Busuk';
    if (widget.penyesuaian) tambah = false;
  }

  @override
  void dispose() {
    jumlah.dispose();
    harga.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final stok = s.stokPakan(jenis);
    final adj = widget.penyesuaian;
    final n = number(jumlah.text) ?? 0;
    final h = number(harga.text);
    return Scaffold(
      appBar: elegantAppBar(
        context,
        adj ? 'Penyesuaian Stok Pakan' : 'Pakan Masuk',
      ),
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
                    adj
                        ? 'Ada pakan busuk atau mau isi stok awal? Catat di sini ⚖️'
                        : 'Gudang terisi lagi! Catat pakan yang datang 📥',
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
                      selected: jenis,
                      onChanged: (j) => setState(() => jenis = j),
                    ),
                    gap(16),
                    if (adj) ...[
                      SegmentedPills(
                        items: const ['＋ Tambah', '－ Kurangi'],
                        index: tambah ? 0 : 1,
                        expand: true,
                        onChanged: (i) => setState(() {
                          tambah = i == 0;
                          alasan =
                              (tambah ? _alasanTambah : _alasanKurang).first;
                        }),
                      ),
                      gap(12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a
                              in tambah ? _alasanTambah : _alasanKurang)
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
                    ],
                    TextFormField(
                      controller: jumlah,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Jumlah (kg)',
                        helperText: 'Stok sekarang: ${kg(stok)}',
                        prefixIcon: const Icon(Icons.scale_rounded),
                      ),
                      validator: (v) {
                        final e = positive(v);
                        if (e != null) return e;
                        if (adj && !tambah && number(v!)! > stok + 1e-9) {
                          return 'Tidak bisa melebihi stok (${kg(stok)})';
                        }
                        return null;
                      },
                    ),
                    if (!adj) ...[
                      gap(14),
                      TextFormField(
                        controller: harga,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Harga per kg (opsional)',
                          helperText: 'Kosongkan kalau pakan didapat gratis',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (v) =>
                            v != null && v.isNotEmpty && positive(v) != null
                            ? 'Masukkan harga lebih dari 0'
                            : null,
                      ),
                      if (h != null && n > 0) ...[
                        gap(10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sage,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Total belanja: ${rupiah(n * h)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: headFont,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ],
                    gap(14),
                    DateField(
                      label: adj ? 'Tanggal' : 'Tanggal pakan masuk',
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
                          () => s.addMutasiPakan(
                            jenis,
                            adj && !tambah ? -n : n,
                            adj ? 'penyesuaian' : 'masuk',
                            harga: adj ? null : h,
                            keterangan: adj ? alasan : '',
                            tanggal: tanggal,
                          ),
                        );
                        if (!ok || !context.mounted) return;
                        Navigator.pop(context);
                        m.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Stok $jenis jadi ${kg(s.stokPakan(jenis))} 📦',
                            ),
                          ),
                        );
                      },
                      child: Text(adj ? 'Simpan Penyesuaian' : 'Simpan'),
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
