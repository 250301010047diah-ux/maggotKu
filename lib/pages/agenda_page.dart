import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'budidaya_pages.dart';
import 'catatan_pages.dart';
import 'stok_pakan_pages.dart';
import '../audio/app_sounds.dart';

String _hariIni() {
  final n = DateTime.now();
  return '${n.year}-${n.month}-${n.day}';
}

/// Tampilkan agenda otomatis sekali sehari (dipanggil saat Beranda dibuka).
void showAgendaSekaliSehari(BuildContext context) {
  final s = AppScope.of(context);
  if (s.agendaShownOn == _hariIni() || s.agenda().isEmpty) return;
  s.agendaShownOn = _hariIni();
  s.notifyListeners(); // simpan tanda sudah tampil hari ini
  showAgenda(context);
}

/// Lembar "Agenda hari ini".
Future<void> showAgenda(BuildContext context) {
  AppSounds.agenda();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AgendaSheet(),
  );
}

/// Tombol lonceng dengan titik merah bila ada tugas.
class AgendaBell extends StatelessWidget {
  const AgendaBell({super.key});

  @override
  Widget build(BuildContext context) {
    final n = AppScope.of(context).agenda().length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleButton(
          icon: n > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          onTap: () => showAgenda(context),
        ),
        if (n > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE5372B),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$n',
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AgendaSheet extends StatelessWidget {
  const _AgendaSheet();

  static const _style = {
    'panen': (Icons.agriculture_rounded, butter, 'Panen'),
    'fase': (Icons.autorenew_rounded, lavender, 'Fase'),
    'pakan': (Icons.restaurant_rounded, peach, 'Pakan'),
    'foto': (Icons.photo_camera_rounded, sky, 'Foto'),
    'stokpakan': (Icons.inventory_2_rounded, peach, 'Gudang'),
    'segar': (Icons.schedule_rounded, butter, 'Gudang'),
  };

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final items = s.agenda();
    return DraggableScrollableSheet(
      initialChildSize: items.isEmpty ? 0.5 : 0.75,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F4),
          borderRadius: BorderRadius.circular(32),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0x261C1C1E),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            DarkCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        eyebrow('Agenda hari ini', color: champagne),
                        gap(6),
                        Text(
                          items.isEmpty
                              ? 'Semua beres! 🎉'
                              : '${items.length} hal perlu dikerjakan',
                          style: const TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        gap(4),
                        Text(
                          items.isEmpty
                              ? 'Maggi senang, tidak ada tugas tertunda.'
                              : 'Ketuk tugas untuk langsung mengerjakannya.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Mascot(size: 76),
                ],
              ),
            ),
            gap(14),
            for (final (i, a) in items.indexed)
              FadeSlideIn(
                delay: i < 6 ? i : 6,
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  accent: a.urgent ? emeraldLight : null,
                  glow: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: () => _buka(context, a),
                  child: ActivityRow(
                    leading: IconBubble(
                      _style[a.kind]!.$1,
                      color: _style[a.kind]!.$2,
                      size: 42,
                    ),
                    title: a.title,
                    subtitle: a.subtitle,
                    trailing: _style[a.kind]!.$3,
                    trailingColor: a.urgent ? emeraldLight : muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _buka(BuildContext context, AgendaItem a) {
    Navigator.pop(context);
    final b = a.budidaya;
    final page = switch (a.kind) {
      // Tugas gudang pakan: catat pakan masuk / buang yang busuk.
      'stokpakan' => const PakanMasukPage(),
      'segar' => const PakanMasukPage(penyesuaian: true),
      'pakan' => CatatanFormPage(isPakan: true, initialBudidayaId: b!.id),
      'panen' => CatatanFormPage(isPakan: false, initialBudidayaId: b!.id),
      _ => BudidayaDetailPage(item: b!),
    };
    openPage(context, page);
  }
}
