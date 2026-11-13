import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Hari ke-berapa foto diambil, dihitung dari tanggal mulai budidaya.
int hariKe(Budidaya b, Foto f) {
  final d = DateUtils.dateOnly(
    f.tanggal,
  ).difference(DateUtils.dateOnly(b.mulai)).inDays;
  return d < 0 ? 0 : d;
}

/// Pilih sumber foto, salin ke folder aplikasi, lalu simpan.
Future<void> tambahFoto(BuildContext context, Budidaya b) async {
  final s = AppScope.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (c) => SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0x1F1C1C1E),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'Foto ${b.nama} • Hari ke-${b.umur}',
              style: const TextStyle(
                fontFamily: headFont,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Abadikan perkembangan maggotmu 📸',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 16),
            ActivityRow(
              onTap: () => Navigator.pop(c, ImageSource.camera),
              leading: const IconBubble(
                Icons.photo_camera_rounded,
                color: peach,
                size: 44,
              ),
              title: 'Ambil dari kamera',
              subtitle: 'Foto langsung kondisi kandang',
            ),
            const Divider(indent: 56),
            ActivityRow(
              onTap: () => Navigator.pop(c, ImageSource.gallery),
              leading: const IconBubble(
                Icons.photo_library_rounded,
                color: sky,
                size: 44,
              ),
              title: 'Pilih dari galeri',
              subtitle: 'Gunakan foto yang sudah ada',
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null) return;

  final XFile? picked;
  try {
    picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 82,
    );
  } catch (e) {
    if (context.mounted) toast(context, 'Gagal mengambil foto: $e');
    return;
  }
  if (picked == null || !context.mounted) return;

  var path = picked.path;
  if (!s.online) {
    // Mode demo: salin ke folder milik aplikasi supaya tetap ada
    // walaupun foto aslinya dihapus dari galeri.
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/foto_maggot');
    await folder.create(recursive: true);
    path = '${folder.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(path);
    if (!context.mounted) return;
  }
  // Online: file langsung di-upload ke server.
  final ok = await kirim(context, () => s.addFoto(b.id, path, DateTime.now()));
  if (ok && context.mounted) toast(context, 'Foto tersimpan di jurnal ✨');
}

/// Gambar foto dari server (URL) atau dari file di HP.
Widget fotoImage(String path, {BoxFit fit = BoxFit.cover, int? cacheWidth}) {
  Widget rusak(BuildContext _, Object _, StackTrace? _) => Container(
    color: const Color(0xFFE9E6E2),
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image_rounded, color: muted),
  );
  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: rusak,
      loadingBuilder: (_, child, p) => p == null
          ? child
          : Container(
              color: const Color(0xFFEDEBE8),
              alignment: Alignment.center,
              child: const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
    );
  }
  return Image.file(
    File(path),
    fit: fit,
    cacheWidth: cacheWidth,
    errorBuilder: rusak,
  );
}

/// Bagian "Jurnal foto" di detail budidaya: geser ke samping.
class JurnalFoto extends StatelessWidget {
  const JurnalFoto({super.key, required this.item});
  final Budidaya item;

  @override
  Widget build(BuildContext context) {
    final fotos = AppScope.of(context).fotoOf(item.id);
    return SizedBox(
      height: 168,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        children: [
          Pressable(
            onTap: () => tambahFoto(context, item),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                border: Border.all(color: const Color(0x1A1C1C1E), width: 1.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconBubble(
                    Icons.add_a_photo_rounded,
                    color: peach,
                    iconColor: emeraldLight,
                    size: 48,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tambah foto',
                    style: TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: ink,
                    ),
                  ),
                  Text(
                    'kamera / galeri',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
          ),
          for (final (i, f) in fotos.indexed) ...[
            const SizedBox(width: 12),
            Pressable(
              onTap: () => openPage(
                context,
                FotoViewerPage(budidaya: item, initialIndex: i),
              ),
              child: SizedBox(
                width: 124,
                child: FotoTile(
                  foto: f,
                  label: 'Hari ke-${hariKe(item, f)}',
                  sublabel: tanggalPendek(f.tanggal),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Foto dengan sudut membulat & label di bagian bawah.
class FotoTile extends StatelessWidget {
  const FotoTile({
    super.key,
    required this.foto,
    required this.label,
    this.sublabel,
    this.radius = 24,
  });
  final Foto foto;
  final String label;
  final String? sublabel;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Stack(
      fit: StackFit.expand,
      children: [
        fotoImage(foto.path, cacheWidth: 480),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0x99000000)],
              stops: [0.5, 1],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Colors.white,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Penampil foto layar penuh: geser, perbesar (cubit), dan hapus.
class FotoViewerPage extends StatefulWidget {
  const FotoViewerPage({
    super.key,
    required this.budidaya,
    required this.initialIndex,
  });
  final Budidaya budidaya;
  final int initialIndex;
  @override
  State<FotoViewerPage> createState() => _FotoViewerPageState();
}

class _FotoViewerPageState extends State<FotoViewerPage> {
  late final _pc = PageController(initialPage: widget.initialIndex);
  late int index = widget.initialIndex;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final fotos = s.fotoOf(widget.budidaya.id);
    if (fotos.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final i = index.clamp(0, fotos.length - 1);
    final f = fotos[i];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: fotos.length,
            onPageChanged: (v) => setState(() => index = v),
            itemBuilder: (_, k) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: fotoImage(fotos[k].path, fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleButton(
                    dark: true,
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.budidaya.nama} • Hari ke-${hariKe(widget.budidaya, f)}',
                          style: const TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${tanggalPanjang(f.tanggal)} • ${i + 1}/${fotos.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleButton(
                    dark: true,
                    icon: Icons.delete_outline_rounded,
                    onTap: () async {
                      if (await confirm(context, 'Hapus foto ini?') &&
                          context.mounted) {
                        final ok = await kirim(context, () => s.deleteFoto(f));
                        if (ok && fotos.length <= 1 && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
