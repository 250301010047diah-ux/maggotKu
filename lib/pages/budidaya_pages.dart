import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'catatan_pages.dart';
import 'foto_pages.dart';
import 'kandang_pages.dart';

class BudidayaListPage extends StatefulWidget {
  const BudidayaListPage({super.key});
  @override
  State<BudidayaListPage> createState() => _BudidayaListPageState();
}

class _BudidayaListPageState extends State<BudidayaListPage> {
  int filter = 0; // 0 semua, 1 aktif, 2 selesai
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final items = s.budidaya
        .where((e) => filter == 0 || (filter == 1 ? !e.selesai : e.selesai))
        .toList();
    final berjalan = s.budidaya.where((e) => !e.selesai).length;
    return Scaffold(
      floatingActionButton: GradientFab(
        label: 'Mulai Budidaya',
        onTap: () => s.kandang.isEmpty
            ? openPage(context, const KandangFormPage())
            : openPage(context, const BudidayaFormPage()),
      ),
      body: PageBody(
        children: [
          PageHeader(
            'Budidaya',
            eyebrowText: 'Siklus pemeliharaan',
            trailing: CircleButton(
              icon: Icons.warehouse_rounded,
              onTap: () => openPage(context, const KandangListPage()),
            ),
          ),
          FadeSlideIn(
            child: Row(
              children: [
                _summary('Berjalan', berjalan, emeraldLight),
                const SizedBox(width: 10),
                _summary('Selesai', s.budidaya.length - berjalan, coral),
                const SizedBox(width: 10),
                _summary('Kandang', s.kandang.length, sky2),
              ],
            ),
          ),
          gap(18),
          FadeSlideIn(
            delay: 1,
            child: SegmentedPills(
              items: const ['Semua', 'Aktif', 'Selesai'],
              index: filter,
              expand: true,
              onChanged: (i) => setState(() => filter = i),
            ),
          ),
          gap(16),
          if (items.isEmpty)
            const EmptyState('Belum ada budidaya pada filter ini.')
          else
            for (final (i, e) in items.indexed)
              FadeSlideIn(
                key: ValueKey('$filter-${e.id}'),
                delay: math.min(i, 6) + 2,
                child: _BudidayaCard(item: e),
              ),
        ],
      ),
    );
  }

  Widget _summary(String label, int value, Color color) => Expanded(
    child: GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: ink,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BudidayaCard extends StatelessWidget {
  const _BudidayaCard({required this.item});
  final Budidaya item;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final e = item;
    final fotos = s.fotoOf(e.id);
    return GlassCard(
      accent: e.selesai ? forest : emeraldLight,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => openPage(context, BudidayaDetailPage(item: e)),
      child: Column(
        children: [
          if (fotos.isNotEmpty) ...[
            SizedBox(
              height: 130,
              width: double.infinity,
              child: FotoTile(
                foto: fotos.first,
                radius: 20,
                label: 'Foto terbaru • Hari ke-${hariKe(e, fotos.first)}',
                sublabel: '${fotos.length} foto di jurnal',
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              ProgressRing(
                value: e.progress,
                size: 60,
                stroke: 6,
                color: e.selesai ? coral : emeraldLight,
                child: Text(
                  '${(e.progress * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.nama,
                      style: const TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: muted,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${s.kandangById(e.kandangId)?.nama ?? 'Kandang tidak ada'} • ${tujuanEmoji[e.tujuan]} ${tujuanLabel[e.tujuan]}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Pill(
                e.selesai ? 'Selesai' : 'Aktif',
                color: e.selesai ? peach : sage,
                textColor: e.selesai ? const Color(0xFFB4533A) : emerald,
                icon: e.selesai
                    ? Icons.check_circle_rounded
                    : Icons.fiber_manual_record_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x0A1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _info(Icons.event_rounded, 'Mulai', tanggalPendek(e.mulai)),
                _info(Icons.schedule_rounded, 'Umur', '${e.umur} hari'),
                _info(
                  Icons.agriculture_rounded,
                  'Target panen',
                  e.perkiraanPanen == null
                      ? '-'
                      : tanggalPendek(e.perkiraanPanen!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: muted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
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

class BudidayaFormPage extends StatefulWidget {
  const BudidayaFormPage({super.key, this.item});
  final Budidaya? item;
  @override
  State<BudidayaFormPage> createState() => _BudidayaFormPageState();
}

class _BudidayaFormPageState extends State<BudidayaFormPage> {
  final key = GlobalKey<FormState>();
  late final nama = TextEditingController(text: widget.item?.nama);
  late final berat = TextEditingController(
    text: widget.item?.beratAwal?.toString() ?? '',
  );
  late final catatan = TextEditingController(text: widget.item?.catatan);
  late int? kandangId = widget.item?.kandangId;
  late DateTime mulai = widget.item?.mulai ?? DateTime.now();
  late DateTime? perkiraan = widget.item?.perkiraanPanen;
  late String tujuan = widget.item?.tujuan ?? 'fresh';
  final telur = TextEditingController();

  /// Estimasi otomatis sesuai tujuan; null perkiraan = pakai otomatis.
  DateTime get _estimasi =>
      DateTime(mulai.year, mulai.month, mulai.day + tujuanHari[tujuan]!);

  @override
  void dispose() {
    nama.dispose();
    berat.dispose();
    catatan.dispose();
    telur.dispose();
    super.dispose();
  }

  Widget _tujuanTile(String t) {
    final sel = t == tujuan;
    return Pressable(
      onTap: () => setState(() => tujuan = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: sel ? emerald : const Color(0x0A1C1C1E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(tujuanEmoji[t]!, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tujuanSingkat[t]!,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: sel ? Colors.white : ink,
                ),
              ),
            ),
            Text(
              '±${tujuanHari[t]} hari',
              style: TextStyle(
                fontSize: 11,
                color: sel ? Colors.white70 : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: elegantAppBar(
        context,
        widget.item == null ? 'Mulai Budidaya' : 'Edit Budidaya',
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
                    widget.item == null
                        ? 'Siklus baru, semangat baru! Isi detailnya ya ✨'
                        : 'Perbarui detail siklus budidayamu ✏️',
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
                    TextFormField(
                      controller: nama,
                      decoration: const InputDecoration(
                        labelText: 'Nama kelompok',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: requiredText,
                    ),
                    gap(16),
                    const Text(
                      'Tujuan siklus',
                      style: TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ink,
                      ),
                    ),
                    gap(10),
                    Row(
                      children: [
                        for (final (i, t) in tujuanList.indexed) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: _tujuanTile(t)),
                        ],
                      ],
                    ),
                    gap(10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: peach,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${tujuanEmoji[tujuan]} ${tujuanKeterangan[tujuan]}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: ink,
                        ),
                      ),
                    ),
                    gap(16),
                    DropdownButtonFormField<int>(
                      initialValue: kandangId,
                      isExpanded: true,
                      style: dropdownStyle,
                      borderRadius: BorderRadius.circular(18),
                      decoration: const InputDecoration(
                        labelText: 'Kandang',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                      items: s.kandang
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.nama),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => kandangId = v),
                      validator: (v) => v == null ? 'Pilih kandang' : null,
                    ),
                    gap(14),
                    DateField(
                      label: 'Tanggal tebar telur / baby maggot',
                      value: mulai,
                      onChanged: (v) => setState(() => mulai = v),
                    ),
                    TextFormField(
                      controller: berat,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Berat awal (kg, opsional)',
                        prefixIcon: Icon(Icons.scale_rounded),
                      ),
                      validator: (v) =>
                          v != null && v.isNotEmpty && positive(v) != null
                          ? 'Masukkan berat lebih dari 0'
                          : null,
                    ),
                    if (widget.item == null) ...[
                      gap(14),
                      TextFormField(
                        controller: telur,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Telur ditebar dari stok (gram, opsional)',
                          helperText:
                              'Stok telur: ${qty('Telur', s.stok('Telur'))}',
                          prefixIcon: const Icon(Icons.egg_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final e = positive(v);
                          if (e != null) return e;
                          final ada = s.stok('Telur');
                          if (number(v)! > ada + 1e-9) {
                            return 'Stok telur hanya ${qty('Telur', ada)}';
                          }
                          return null;
                        },
                      ),
                    ],
                    gap(14),
                    DateField(
                      label: perkiraan == null
                          ? 'Perkiraan panen (otomatis)'
                          : 'Perkiraan panen (manual)',
                      value: perkiraan ?? _estimasi,
                      onChanged: (v) => setState(() => perkiraan = v),
                    ),
                    if (perkiraan != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => perkiraan = null),
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'Pakai estimasi otomatis (${tanggalPendek(_estimasi)})',
                          ),
                        ),
                      ),
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
                        if (perkiraan != null &&
                            DateUtils.dateOnly(
                              perkiraan!,
                            ).isBefore(DateUtils.dateOnly(mulai))) {
                          toast(
                            context,
                            'Perkiraan panen harus setelah tanggal mulai.',
                          );
                          return;
                        }
                        final ok = await kirim(
                          context,
                          () => s.saveBudidaya(
                            widget.item,
                            nama.text.trim(),
                            kandangId!,
                            mulai,
                            berat.text.isEmpty ? null : number(berat.text),
                            perkiraan,
                            catatan.text.trim(),
                            tujuan: tujuan,
                            telurGram: number(telur.text) ?? 0,
                          ),
                        );
                        if (ok && context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Simpan Budidaya'),
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

/// Absen foto mingguan: ✅ ada foto, ✕ bolong, ⏳ minggu berjalan.
class _AbsenFoto extends StatelessWidget {
  const _AbsenFoto({required this.item});
  final Budidaya item;

  @override
  Widget build(BuildContext context) {
    final minggu = AppScope.of(context).mingguFoto(item);
    if (minggu.isEmpty) return const SizedBox.shrink();
    final bolong = minggu.where((m) => m == false).length;
    return GlassCard(
      glow: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Absen foto mingguan',
                  style: TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: ink,
                  ),
                ),
              ),
              Pill(
                bolong == 0 ? 'Lengkap' : '$bolong bolong',
                color: bolong == 0 ? sage : peach,
                textColor: bolong == 0 ? forest : emeraldLight,
                icon: bolong == 0
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
              ),
            ],
          ),
          gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, m) in minggu.indexed)
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: switch (m) {
                      true => sage,
                      false => peach,
                      null => const Color(0x0A1C1C1E),
                    },
                    borderRadius: BorderRadius.circular(14),
                    border: m == null
                        ? Border.all(color: const Color(0x331C1C1E))
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        switch (m) {
                          true => '✅',
                          false => '✕',
                          null => '⏳',
                        },
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: m == false ? emeraldLight : ink,
                        ),
                      ),
                      Text(
                        'M${i + 1}',
                        style: const TextStyle(
                          fontFamily: headFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Timeline fase batch perkawinan.
class _FaseTimeline extends StatelessWidget {
  const _FaseTimeline({required this.item});
  final Budidaya item;

  @override
  Widget build(BuildContext context) {
    final now = item.faseIndex;
    return GlassCard(
      glow: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          for (final (i, f) in faseKawin.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < now
                                ? forest
                                : i == now
                                ? emeraldLight
                                : const Color(0x141C1C1E),
                          ),
                          child: Icon(
                            i < now ? Icons.check_rounded : Icons.circle,
                            size: i < now ? 14 : 7,
                            color: i <= now ? Colors.white : muted,
                          ),
                        ),
                        if (i < faseKawin.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: i < now ? forest : const Color(0x141C1C1E),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Text(f.$3, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.$1,
                                  style: TextStyle(
                                    fontFamily: headFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: i <= now ? ink : muted,
                                  ),
                                ),
                                Text(
                                  'Hari ke-${f.$2} • ${tanggalPendek(DateTime(item.mulai.year, item.mulai.month, item.mulai.day + f.$2))}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i == now && !item.selesai) const Pill('Sekarang'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class BudidayaDetailPage extends StatelessWidget {
  const BudidayaDetailPage({super.key, required this.item});
  final Budidaya item;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final feeds = s.pakan.where((e) => e.budidayaId == item.id).toList();
    final harvests = s.panen.where((e) => e.budidayaId == item.id).toList();
    final history = [
      for (final e in feeds) (e, true),
      for (final e in harvests) (e, false),
    ]..sort((a, b) => b.$1.tanggal.compareTo(a.$1.tanggal));
    final pct = (item.progress * 100).round();

    return Scaffold(
      appBar: elegantAppBar(
        context,
        'Detail Budidaya',
        actions: [
          CircleButton(
            icon: Icons.edit_rounded,
            onTap: () => openPage(context, BudidayaFormPage(item: item)),
          ),
        ],
      ),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          FadeSlideIn(
            child: DarkCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Pill(
                              item.selesai ? 'Selesai' : 'Sedang berjalan',
                              color: Colors.white.withValues(alpha: 0.12),
                              textColor: mint,
                              icon: item.selesai
                                  ? Icons.check_circle_rounded
                                  : Icons.bolt_rounded,
                            ),
                            gap(10),
                            Text(
                              item.nama,
                              style: const TextStyle(
                                fontFamily: headFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 26,
                                color: Colors.white,
                              ),
                            ),
                            gap(4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Colors.white60,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${s.kandangById(item.kandangId)?.nama ?? 'Kandang tidak ada'} • ${tujuanLabel[item.tujuan]}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ProgressRing(
                        value: item.progress,
                        size: 88,
                        stroke: 8,
                        color: champagne,
                        trackColor: Colors.white.withValues(alpha: 0.12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                fontFamily: headFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'progres',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  gap(20),
                  Row(
                    children: [
                      HeroStat('Umur', '${item.umur} hari'),
                      const HeroDivider(),
                      HeroStat('Total pakan', kg(s.total(feeds))),
                      const HeroDivider(),
                      HeroStat('Total panen', kg(s.total(harvests))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          gap(14),
          FadeSlideIn(
            delay: 1,
            child: Row(
              children: [
                Expanded(
                  child: _action(
                    'Catat Pakan',
                    Icons.restaurant_rounded,
                    peach,
                    () => openPage(
                      context,
                      CatatanFormPage(
                        isPakan: true,
                        initialBudidayaId: item.id,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _action(
                    'Catat Panen',
                    Icons.agriculture_rounded,
                    butter,
                    () => openPage(
                      context,
                      CatatanFormPage(
                        isPakan: false,
                        initialBudidayaId: item.id,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.tujuan == 'perkawinan') ...[
            const SectionTitle('Fase perkawinan'),
            FadeSlideIn(delay: 2, child: _FaseTimeline(item: item)),
          ],
          SectionTitle(
            'Jurnal foto',
            action: s.fotoOf(item.id).isEmpty
                ? null
                : '${s.fotoOf(item.id).length} foto',
          ),
          FadeSlideIn(delay: 2, child: _AbsenFoto(item: item)),
          gap(12),
          FadeSlideIn(delay: 2, child: JurnalFoto(item: item)),
          const SectionTitle('Pakan 7 hari terakhir'),
          FadeSlideIn(
            delay: 2,
            child: GlassCard(
              child: WeeklyBarChart(
                height: 160,
                values: s.daily(feeds),
                labels: last7Labels(),
                color: emeraldLight,
              ),
            ),
          ),
          const SectionTitle('Riwayat'),
          if (history.isEmpty)
            const EmptyState('Belum ada catatan pakan atau panen.')
          else
            FadeSlideIn(
              delay: 3,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final (i, h) in history.indexed) ...[
                      if (i > 0) const Divider(indent: 54),
                      ActivityRow(
                        leading: IconBubble(
                          h.$2
                              ? Icons.restaurant_rounded
                              : Icons.agriculture_rounded,
                          color: h.$2 ? peach : butter,
                          size: 42,
                        ),
                        title: h.$2
                            ? 'Pakan${h.$1.jenis.isEmpty ? '' : ' • ${h.$1.jenis}'}'
                            : 'Panen',
                        subtitle: tanggalPanjang(h.$1.tanggal),
                        trailing: '${h.$2 ? '' : '+'}${kg(h.$1.berat)}',
                        trailingColor: h.$2 ? ink : emeraldLight,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (!item.selesai) ...[
            gap(22),
            OutlinedButton.icon(
              onPressed: () async {
                if (await confirm(
                      context,
                      'Selesaikan ${item.nama}? Riwayat tetap tersimpan.',
                    ) &&
                    context.mounted) {
                  await kirim(context, () => s.finish(item));
                }
              },
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Selesaikan Budidaya'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        IconBubble(icon, color: color, size: 40),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: ink,
            ),
          ),
        ),
      ],
    ),
  );
}
