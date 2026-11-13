import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'budidaya_pages.dart';

class KandangListPage extends StatefulWidget {
  const KandangListPage({super.key});
  @override
  State<KandangListPage> createState() => _KandangListPageState();
}

class _KandangListPageState extends State<KandangListPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final items = s.kandang
        .where(
          (e) => '${e.nama} ${e.lokasi}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: elegantAppBar(context, 'Kandang'),
      floatingActionButton: GradientFab(
        label: 'Tambah Kandang',
        lift: false,
        onTap: () => openPage(context, const KandangFormPage()),
      ),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          FadeSlideIn(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari kandang atau lokasi…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          gap(16),
          if (items.isEmpty)
            const EmptyState('Kandang tidak ditemukan.')
          else
            for (final (i, e) in items.indexed)
              FadeSlideIn(
                key: ValueKey(e.id),
                delay: math.min(i, 6) + 1,
                child: _KandangCard(item: e),
              ),
        ],
      ),
    );
  }
}

class _KandangCard extends StatelessWidget {
  const _KandangCard({required this.item});
  final Kandang item;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final e = item;
    final related = s.budidaya.where((b) => b.kandangId == e.id).toList();
    final aktif = related.where((b) => !b.selesai).toList();
    final muatan = aktif.fold<double>(0, (a, b) => a + (b.beratAwal ?? 0));
    final kap = e.kapasitas;
    final ratio = kap == null || kap == 0
        ? null
        : (muatan / kap).clamp(0.0, 1.0);

    return GlassCard(
      accent: aktif.isEmpty ? sky2 : emeraldLight,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EmojiBubble('🏡', color: sky, size: 50),
              const SizedBox(width: 12),
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
                            e.lokasi,
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
              CircleButton(
                icon: Icons.edit_rounded,
                size: 40,
                onTap: () => openPage(context, KandangFormPage(item: e)),
              ),
            ],
          ),
          gap(16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kapasitas terpakai',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
              Text(
                ratio == null ? 'Tanpa batas' : '${kg(muatan)} / ${kg(kap!)}',
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: ink,
                ),
              ),
            ],
          ),
          gap(8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio ?? 0),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: const Color(0x0F1C1C1E),
                color: (ratio ?? 0) > 0.85 ? emeraldLight : forest,
              ),
            ),
          ),
          gap(14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill('${aktif.length} siklus aktif', icon: Icons.spa_rounded),
              for (final b in related)
                Pressable(
                  onTap: () => openPage(context, BudidayaDetailPage(item: b)),
                  child: Pill(
                    b.nama,
                    color: b.selesai ? peach : const Color(0x0F1C1C1E),
                    textColor: ink,
                    icon: Icons.arrow_outward_rounded,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class KandangFormPage extends StatefulWidget {
  const KandangFormPage({super.key, this.item});
  final Kandang? item;
  @override
  State<KandangFormPage> createState() => _KandangFormPageState();
}

class _KandangFormPageState extends State<KandangFormPage> {
  final key = GlobalKey<FormState>();
  late final nama = TextEditingController(text: widget.item?.nama);
  late final lokasi = TextEditingController(text: widget.item?.lokasi);
  late final kapasitas = TextEditingController(
    text: widget.item?.kapasitas?.toString() ?? '',
  );
  late final catatan = TextEditingController(text: widget.item?.catatan);
  @override
  void dispose() {
    nama.dispose();
    lokasi.dispose();
    kapasitas.dispose();
    catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: elegantAppBar(
      context,
      widget.item == null ? 'Tambah Kandang' : 'Edit Kandang',
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
                      ? 'Rumah baru untuk maggot-maggotmu 🏡'
                      : 'Perbarui info kandangmu ✏️',
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
                      labelText: 'Nama atau kode kandang',
                      prefixIcon: Icon(Icons.warehouse_outlined),
                    ),
                    validator: requiredText,
                  ),
                  gap(14),
                  TextFormField(
                    controller: lokasi,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: requiredText,
                  ),
                  gap(14),
                  TextFormField(
                    controller: kapasitas,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Kapasitas (kg, opsional)',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (v) =>
                        v != null && v.isNotEmpty && positive(v) != null
                        ? 'Masukkan kapasitas lebih dari 0'
                        : null,
                  ),
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
                      final s = AppScope.of(context);
                      final ok = await kirim(
                        context,
                        () => s.saveKandang(
                          widget.item,
                          nama.text.trim(),
                          lokasi.text.trim(),
                          kapasitas.text.isEmpty
                              ? null
                              : number(kapasitas.text),
                          catatan.text.trim(),
                        ),
                      );
                      if (ok && context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Simpan Kandang'),
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
