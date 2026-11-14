import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'penjualan_pages.dart';

/// Kirim tagihan lewat WhatsApp. Tanpa nomor HP → bagikan teks biasa.
Future<void> tagihWa(
  BuildContext context,
  String nama,
  String hp,
  List<Penjualan> items,
) async {
  final s = AppScope.of(context);
  final teks = s.pesanTagih(nama, items);
  final no = nomorWa(hp);
  if (no != null) {
    final uri = Uri.parse(
      'https://wa.me/$no?text=${Uri.encodeComponent(teks)}',
    );
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
  }
  await SharePlus.instance.share(ShareParams(text: teks));
}

Future<void> telepon(String hp) async {
  final d = hp.replaceAll(RegExp(r'[^0-9+]'), '');
  if (d.isEmpty) return;
  try {
    await launchUrl(Uri.parse('tel:$d'));
  } catch (_) {}
}

/// Warna & label umur piutang.
({Color bg, Color fg, String label}) umurPiutang(int hari) => hari >= 30
    ? (bg: const Color(0xFFFFE1E1), fg: danger, label: '$hari hari • macet')
    : hari >= 14
    ? (bg: peach, fg: const Color(0xFFC8400E), label: '$hari hari')
    : (bg: sage, fg: forest, label: hari == 0 ? 'hari ini' : '$hari hari');

// =====================================================================
// Daftar pembeli & piutang
// =====================================================================
class PembeliPage extends StatefulWidget {
  const PembeliPage({super.key});
  @override
  State<PembeliPage> createState() => _PembeliPageState();
}

class _PembeliPageState extends State<PembeliPage> {
  String cari = '';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final piutang = s.piutang();
    final total = piutang.fold<double>(0, (a, e) => a + e.total);
    final nota = piutang.fold<int>(0, (a, e) => a + e.items.length);
    final macet = piutang.where((e) => e.umur >= 30).length;
    final daftar =
        s.pembeli
            .where(
              (p) =>
                  cari.isEmpty ||
                  p.nama.toLowerCase().contains(cari.toLowerCase()),
            )
            .toList()
          ..sort(
            (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
          );

    return Scaffold(
      appBar: elegantAppBar(context, 'Pembeli & Piutang'),
      floatingActionButton: GradientFab(
        label: 'Pembeli Baru',
        lift: false,
        onTap: () => openPage(context, const PembeliFormPage()),
      ),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          FadeSlideIn(
            child: DarkCard(
              tone: total > 0 ? CardTone.warm : CardTone.ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            eyebrow('Total piutang', color: champagne),
                            gap(8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: RollingText(
                                rupiah(total),
                                style: const TextStyle(
                                  fontFamily: headFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 34,
                                  letterSpacing: -1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            gap(6),
                            Text(
                              total == 0
                                  ? 'Semua pembeli sudah lunas 🎉'
                                  : 'Belum dibayar oleh ${piutang.length} pembeli',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Mascot(
                        size: 82,
                        mood: macet > 0 ? MaggotMood.sulky : MaggotMood.happy,
                      ),
                    ],
                  ),
                  gap(16),
                  Row(
                    children: [
                      HeroStat('Pembeli', '${s.pembeli.length}'),
                      const HeroDivider(),
                      HeroStat('Nota', '$nota'),
                      const HeroDivider(),
                      HeroStat('Macet ≥30h', '$macet'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---------- Piutang ----------
          if (piutang.isNotEmpty) ...[
            const SectionTitle('Perlu ditagih'),
            for (final (i, p) in piutang.indexed)
              FadeSlideIn(
                delay: 1 + i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PiutangCard(
                    nama: p.nama,
                    pembeli: p.pembeli,
                    total: p.total,
                    umur: p.umur,
                    items: p.items,
                  ),
                ),
              ),
          ],

          // ---------- Daftar ----------
          const SectionTitle('Daftar pembeli'),
          if (s.pembeli.length > 5) ...[
            TextField(
              onChanged: (v) => setState(() => cari = v),
              decoration: const InputDecoration(
                hintText: 'Cari pembeli…',
                prefixIcon: AppIcon(Icons.search_rounded),
              ),
            ),
            gap(12),
          ],
          if (daftar.isEmpty)
            const EmptyState(
              'Simpan pembeli tetap supaya catat penjualan lebih cepat & bisa tagih via WhatsApp.',
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
                    for (final (i, p) in daftar.indexed) ...[
                      if (i > 0) const Divider(indent: 58),
                      _PembeliRow(p: p),
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

class _PembeliRow extends StatelessWidget {
  const _PembeliRow({required this.p});
  final Pembeli p;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final tx = s.penjualanOf(p);
    final utang = s.pendapatan(tx.where((e) => !e.lunas));
    return ActivityRow(
      onTap: () => openPage(context, PembeliDetailPage(pembeli: p)),
      leading: Avatar(nama: p.nama),
      title: p.nama,
      subtitle: [
        if (p.noHp.isNotEmpty) p.noHp,
        '${tx.length} transaksi',
      ].join(' • '),
      trailing: rupiahSingkat(s.pendapatan(tx)),
      trailingSub: utang > 0 ? 'Utang ${rupiahSingkat(utang)}' : 'Lunas',
      trailingSubColor: utang > 0 ? emeraldLight : forest,
    );
  }
}

/// Bulatan inisial nama dengan warna tetap per nama.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.nama, this.size = 44});
  final String nama;
  final double size;
  static const _bg = [peach, sage, sky, butter, lavender, pink];

  @override
  Widget build(BuildContext context) {
    final parts = nama.trim().split(RegExp(r'\s+'));
    final ini = parts.isEmpty || parts.first.isEmpty
        ? '?'
        : (parts.length == 1
                  ? parts.first.substring(0, 1)
                  : '${parts[0][0]}${parts[1][0]}')
              .toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _bg[nama.hashCode.abs() % _bg.length],
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: hairline),
      ),
      child: Text(
        ini,
        style: TextStyle(
          fontFamily: headFont,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
          letterSpacing: -0.5,
          color: ink,
        ),
      ),
    );
  }
}

/// Kartu piutang satu pembeli: total, umur, nota, & tombol aksi.
class PiutangCard extends StatelessWidget {
  const PiutangCard({
    super.key,
    required this.nama,
    required this.pembeli,
    required this.total,
    required this.umur,
    required this.items,
  });
  final String nama;
  final Pembeli? pembeli;
  final double total;
  final int umur;
  final List<Penjualan> items;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final u = umurPiutang(umur);
    return GlassCard(
      accent: u.fg,
      onTap: pembeli == null
          ? null
          : () => openPage(context, PembeliDetailPage(pembeli: pembeli!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(nama: nama),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        letterSpacing: -0.3,
                        color: ink,
                      ),
                    ),
                    Text(
                      '${items.length} nota sejak ${tanggalPendek(items.first.tanggal)}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rupiah(total),
                    style: const TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.4,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Pill(
                    u.label,
                    color: u.bg,
                    textColor: u.fg,
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                ],
              ),
            ],
          ),
          gap(14),
          Row(
            children: [
              Expanded(
                child: _Btn(
                  label: 'Tagih WA',
                  icon: Icons.chat_rounded,
                  dark: true,
                  onTap: () =>
                      tagihWa(context, nama, pembeli?.noHp ?? '', items),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Btn(
                  label: 'Lunasi',
                  icon: Icons.check_rounded,
                  onTap: () async {
                    if (!await confirm(
                          context,
                          'Tandai ${items.length} nota $nama (${rupiah(total)}) sudah lunas?',
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    await kirim(context, () async {
                      for (final e in [...items]) {
                        await s.tandaiLunas(e);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.dark = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.94,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: dark ? emerald : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? emerald : ink, width: 1.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon, size: 18, color: dark ? emeraldLight : ink),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: dark ? Colors.white : ink,
            ),
          ),
        ],
      ),
    ),
  );
}

// =====================================================================
// Detail pembeli
// =====================================================================
class PembeliDetailPage extends StatelessWidget {
  const PembeliDetailPage({super.key, required this.pembeli});
  final Pembeli pembeli;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = pembeli;
    final tx = s.penjualanOf(p);
    final belum = tx.where((e) => !e.lunas).toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
    final utang = s.pendapatan(belum);
    final umur = belum.isEmpty ? 0 : belum.first.umurPiutang;

    return Scaffold(
      appBar: elegantAppBar(
        context,
        'Pembeli',
        actions: [
          CircleButton(
            icon: Icons.edit_rounded,
            onTap: () => openPage(context, PembeliFormPage(item: p)),
          ),
        ],
      ),
      floatingActionButton: GradientFab(
        label: 'Jual ke ${p.nama.split(' ').first}',
        lift: false,
        onTap: () => openPage(context, PenjualanFormPage(initialPembeli: p)),
      ),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          FadeSlideIn(
            child: DarkCard(
              tone: CardTone.ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Avatar(nama: p.nama, size: 58),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nama,
                              style: const TextStyle(
                                fontFamily: headFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                letterSpacing: -0.6,
                                color: Colors.white,
                              ),
                            ),
                            if (p.noHp.isNotEmpty || p.alamat.isNotEmpty)
                              Text(
                                [
                                  p.noHp,
                                  p.alamat,
                                ].where((e) => e.isNotEmpty).join(' • '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  gap(18),
                  Row(
                    children: [
                      HeroStat('Belanja', rupiahSingkat(s.pendapatan(tx))),
                      const HeroDivider(),
                      HeroStat('Transaksi', '${tx.length}'),
                      const HeroDivider(),
                      HeroStat('Utang', rupiahSingkat(utang)),
                    ],
                  ),
                  if (p.noHp.isNotEmpty || utang > 0) ...[
                    gap(16),
                    Row(
                      children: [
                        if (utang > 0)
                          Expanded(
                            child: _HeroBtn(
                              label: 'Tagih ${rupiahSingkat(utang)}',
                              icon: Icons.chat_rounded,
                              primary: true,
                              onTap: () =>
                                  tagihWa(context, p.nama, p.noHp, belum),
                            ),
                          ),
                        if (utang > 0 && p.noHp.isNotEmpty)
                          const SizedBox(width: 8),
                        if (p.noHp.isNotEmpty)
                          Expanded(
                            child: _HeroBtn(
                              label: 'Telepon',
                              icon: Icons.phone_rounded,
                              onTap: () => telepon(p.noHp),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (utang > 0) ...[
            gap(12),
            FadeSlideIn(
              delay: 1,
              child: GlassCard(
                accent: umurPiutang(umur).fg,
                child: Row(
                  children: [
                    const IconBubble(
                      Icons.account_balance_wallet_rounded,
                      color: peach,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${belum.length} nota belum lunas, tertua ${umurPiutang(umur).label}.',
                        style: const TextStyle(
                          fontFamily: headFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (p.catatan.isNotEmpty) ...[
            gap(12),
            Text(p.catatan, style: const TextStyle(color: muted, fontSize: 13)),
          ],
          const SectionTitle('Riwayat transaksi'),
          if (tx.isEmpty)
            const EmptyState('Belum ada transaksi dengan pembeli ini.')
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
                    for (final (i, e) in tx.indexed) ...[
                      if (i > 0) const Divider(indent: 56),
                      LunasRow(item: e),
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

class _HeroBtn extends StatelessWidget {
  const _HeroBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.94,
    child: Container(
      height: 46,
      decoration: BoxDecoration(
        color: primary ? emeraldLight : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: headFont,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Baris transaksi dengan tombol cepat tandai lunas.
class LunasRow extends StatelessWidget {
  const LunasRow({super.key, required this.item});
  final Penjualan item;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final e = item;
    return Row(
      children: [
        Expanded(
          child: ActivityRow(
            onTap: () => openPage(context, PenjualanFormPage(item: e)),
            leading: EmojiBubble(
              produkEmoji[e.produk] ?? '🐛',
              color: e.lunas ? sage : peach,
              size: 42,
            ),
            title: '${e.produk} • ${qty(e.produk, e.berat)}',
            subtitle: e.lunas
                ? '${tanggalPendek(e.tanggal)} • lunas${e.tanggalLunas == null ? '' : ' ${tanggalPendek(e.tanggalLunas!)}'}'
                : '${tanggalPendek(e.tanggal)} • ${umurPiutang(e.umurPiutang).label}',
            trailing: rupiahSingkat(e.total),
          ),
        ),
        const SizedBox(width: 8),
        Pressable(
          onTap: () => kirim(context, () => s.tandaiLunas(e, !e.lunas)),
          scale: 0.85,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: e.lunas ? forest : Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: e.lunas ? forest : ink, width: 1.4),
            ),
            child: Center(
              child: AppIcon(
                e.lunas ? Icons.check_rounded : Icons.hourglass_bottom_rounded,
                size: 16,
                color: e.lunas ? Colors.white : ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Form pembeli
// =====================================================================
class PembeliFormPage extends StatefulWidget {
  const PembeliFormPage({super.key, this.item, this.namaAwal});
  final Pembeli? item;

  /// Nama bawaan saat dibuat dari form penjualan.
  final String? namaAwal;
  @override
  State<PembeliFormPage> createState() => _PembeliFormPageState();
}

class _PembeliFormPageState extends State<PembeliFormPage> {
  final key = GlobalKey<FormState>();
  late final nama = TextEditingController(
    text: widget.item?.nama ?? widget.namaAwal,
  );
  late final hp = TextEditingController(text: widget.item?.noHp);
  late final alamat = TextEditingController(text: widget.item?.alamat);
  late final catatan = TextEditingController(text: widget.item?.catatan);

  @override
  void dispose() {
    nama.dispose();
    hp.dispose();
    alamat.dispose();
    catatan.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!key.currentState!.validate()) return;
    final s = AppScope.of(context);
    Pembeli? hasil;
    final ok = await kirim(context, () async {
      hasil = await s.savePembeli(
        widget.item,
        nama: nama.text.trim(),
        noHp: hp.text.trim(),
        alamat: alamat.text.trim(),
        catatan: catatan.text.trim(),
      );
    });
    if (ok && mounted) Navigator.pop(context, hasil);
  }

  Future<void> _delete() async {
    final s = AppScope.of(context);
    if (await confirm(
          context,
          'Hapus ${widget.item!.nama}? Riwayat penjualan tetap tersimpan.',
        ) &&
        mounted &&
        await kirim(context, () => s.deletePembeli(widget.item!)) &&
        mounted) {
      Navigator.of(context)
        ..pop()
        ..maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: elegantAppBar(
      context,
      widget.item == null ? 'Pembeli Baru' : 'Edit Pembeli',
      actions: [
        if (widget.item != null)
          CircleButton(icon: Icons.delete_outline_rounded, onTap: _delete),
      ],
    ),
    body: PageBody(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        FadeSlideIn(
          child: Row(
            children: [
              const Mascot(size: 80),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pembeli tetap bikin catat jualan lebih cepat & tagih utang tinggal sekali klik 💬',
                  style: TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
                  TextFormField(
                    controller: nama,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama pembeli',
                      prefixIcon: AppIcon(Icons.person_outline_rounded),
                    ),
                    validator: requiredText,
                  ),
                  gap(14),
                  TextFormField(
                    controller: hp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. HP / WhatsApp (opsional)',
                      hintText: '08xx',
                      prefixIcon: AppIcon(Icons.phone_rounded),
                    ),
                  ),
                  gap(14),
                  TextFormField(
                    controller: alamat,
                    decoration: const InputDecoration(
                      labelText: 'Alamat (opsional)',
                      prefixIcon: AppIcon(Icons.location_on_outlined),
                    ),
                  ),
                  gap(14),
                  TextFormField(
                    controller: catatan,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      prefixIcon: AppIcon(Icons.notes_rounded),
                    ),
                  ),
                  gap(22),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Simpan Pembeli'),
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
