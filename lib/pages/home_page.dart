import 'package:flutter/material.dart';
import '../data/api.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'agenda_page.dart';
import 'auth_pages.dart';
import 'budidaya_pages.dart';
import 'catatan_pages.dart';
import 'kalkulator_page.dart';
import 'kandang_pages.dart';
import 'onboarding_page.dart';
import 'penjualan_pages.dart';

/// Tab yang sedang aktif; bisa diubah dari halaman mana pun.
final homeTab = ValueNotifier<int>(0);

/// Ambil ulang semua data dari server. [diam] = tidak menampilkan pesan
/// sukses (dipakai saat aplikasi dibuka).
Future<void> sinkronkan(BuildContext context, {bool diam = false}) async {
  final s = AppScope.of(context);
  if (!s.online) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await s.syncAll();
    if (!diam) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Data sudah yang terbaru ✨')),
      );
    }
  } on ApiException catch (e) {
    if (e.status == 401) return; // sudah diarahkan ke Login
    messenger.showSnackBar(
      SnackBar(content: Text('${e.message} Menampilkan data terakhir.')),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int index = 0;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  static const _pages = [
    DashboardPage(),
    BudidayaListPage(),
    CatatanPage(),
    PenjualanPage(),
    AccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    homeTab.value = 0;
    homeTab.addListener(_onTab);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Ambil data terbaru dari server (akun online).
      await sinkronkan(context, diam: true);
      // Pop-up agenda hari ini, sekali sehari saat aplikasi dibuka.
      if (mounted) showAgendaSekaliSehari(context);
    });
  }

  void _onTab() {
    if (homeTab.value == index) return;
    setState(() => index = homeTab.value);
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    homeTab.removeListener(_onTab);
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: AnimatedBuilder(
      animation: _fade,
      child: IndexedStack(index: index, children: _pages),
      builder: (_, child) {
        final v = Curves.easeOutCubic.transform(_fade.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - v)),
            child: child,
          ),
        );
      },
    ),
    bottomNavigationBar: ElegantNavBar(
      index: index,
      onTap: (v) => homeTab.value = v,
    ),
  );
}

/// Navigasi bawah mengambang: kapsul emerald, tab aktif melebar.
class ElegantNavBar extends StatelessWidget {
  const ElegantNavBar({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Beranda'),
    (Icons.spa_rounded, 'Budidaya'),
    (Icons.edit_note_rounded, 'Catatan'),
    (Icons.payments_rounded, 'Jual'),
    (Icons.person_rounded, 'Akun'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B3B3E), Color(0xFF1C1C1E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0x40000000),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (_, box) {
          final sel = box.maxWidth * 0.34;
          final other = (box.maxWidth - sel) / (_items.length - 1);
          return Row(
            children: [
              for (final (i, it) in _items.indexed)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    width: i == index ? sel : other,
                    height: 54,
                    decoration: BoxDecoration(
                      color: i == index ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRect(
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              it.$1,
                              size: 22,
                              color: i == index
                                  ? emerald
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                            if (i == index) ...[
                              const SizedBox(width: 6),
                              Text(
                                it.$2,
                                style: const TextStyle(
                                  fontFamily: headFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: emerald,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

// =====================================================================
// Beranda
// =====================================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _Event {
  const _Event(
    this.date,
    this.title,
    this.subtitle,
    this.amount,
    this.icon,
    this.color,
    this.amountColor,
  );
  final DateTime date;
  final String title, subtitle, amount;
  final IconData icon;
  final Color color, amountColor;
}

class _DashboardPageState extends State<DashboardPage> {
  int chart = 0; // 0 pakan, 1 panen, 2 jual
  int periode = 0; // 0 minggu ini, 1 bulan ini, 2 tahun ini

  static const _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _donutColors = [
    emeraldLight,
    coral,
    Color(0xFFF7A77A),
    sky2,
    pink2,
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = DateTime.now();
    bool sameMonth(DateTime d, DateTime m) =>
        d.year == m.year && d.month == m.month;

    final today = s.pakan.where((e) => DateUtils.isSameDay(e.tanggal, now));
    final panenBulan = s.panen.where((e) => sameMonth(e.tanggal, now));
    final jualBulan = s.penjualan
        .where((e) => sameMonth(e.tanggal, now))
        .toList();
    final pendapatan = s.pendapatan(jualBulan);
    final lalu = DateTime(now.year, now.month - 1);
    final pendapatanLalu = s.pendapatan(
      s.penjualan.where((e) => sameMonth(e.tanggal, lalu)),
    );
    final delta = pendapatanLalu == 0
        ? null
        : (pendapatan - pendapatanLalu) / pendapatanLalu * 100;
    final piutang = s.pendapatan(jualBulan.where((e) => !e.lunas));
    final kgTerjual = jualBulan
        .where((e) => satuan(e.produk) == 'kg')
        .fold<double>(0, (a, e) => a + e.berat);

    final rev14 = s.dailyBy(
      s.penjualan,
      (e) => e.tanggal,
      (e) => e.total,
      days: 14,
    );
    final pakan7 = s.daily(s.pakan);
    final panen7 = s.daily(s.panen);
    // Statistik: minggu (7 hari, harian), bulan ini (harian), tahun ini (bulanan)
    final buckets = switch (periode) {
      0 => daysBack(7, now),
      1 => thisMonth(now),
      _ => thisYear(now),
    };
    final week = switch (chart) {
      0 => sumBuckets(s.pakan, (e) => e.tanggal, (e) => e.berat, buckets),
      1 => sumBuckets(s.panen, (e) => e.tanggal, s.kgOf, buckets),
      _ => sumBuckets(s.penjualan, (e) => e.tanggal, (e) => e.total, buckets),
    };
    final weekTotal = week.fold<double>(0, (a, b) => a + b);
    final aktif = s.budidaya.where((e) => !e.selesai).toList();
    final jenis = s.pakanPerJenis();

    String nama(int id) => s.budidayaById(id)?.nama ?? 'Kelompok tidak ada';
    final events = <_Event>[
      for (final e in s.pakan)
        _Event(
          e.tanggal,
          'Pakan${e.jenis.isEmpty ? '' : ' • ${e.jenis}'}',
          nama(e.budidayaId),
          kg(e.berat),
          Icons.restaurant_rounded,
          peach,
          ink,
        ),
      for (final e in s.panen)
        _Event(
          e.tanggal,
          'Panen • ${s.produkOf(e)}',
          nama(e.budidayaId),
          '+${qty(s.produkOf(e), e.berat)}',
          Icons.agriculture_rounded,
          butter,
          emeraldLight,
        ),
      for (final e in s.penjualan)
        _Event(
          e.tanggal,
          'Terjual • ${e.produk}',
          e.pembeli,
          '+${rupiahSingkat(e.total)}',
          Icons.payments_rounded,
          sage,
          emeraldLight,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      body: PageBody(
        onRefresh: s.online ? () => sinkronkan(context) : null,
        children: [
          // ---------- Sapaan ----------
          FadeSlideIn(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        eyebrow(
                          '${_hari[now.weekday - 1]}, ${tanggalPanjang(now)}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Halo, ${s.nama} 👋',
                          style: const TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 27,
                            letterSpacing: -0.4,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleButton(
                    icon: Icons.warehouse_rounded,
                    onTap: () => openPage(context, const KandangListPage()),
                  ),
                  const SizedBox(width: 10),
                  const AgendaBell(),
                ],
              ),
            ),
          ),

          // ---------- Hero pendapatan ----------
          FadeSlideIn(
            delay: 1,
            child: DarkCard(
              onTap: () => homeTab.value = 3,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            eyebrow('Pendapatan bulan ini', color: champagne),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                rupiah(pendapatan),
                                style: const TextStyle(
                                  fontFamily: headFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 32,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Pill(
                              delta == null
                                  ? '${jualBulan.length} transaksi bulan ini'
                                  : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}% dari bulan lalu',
                              color: Colors.white.withValues(alpha: 0.12),
                              textColor: mint,
                              icon: delta != null && delta < 0
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                            ),
                          ],
                        ),
                      ),
                      const Mascot(size: 90),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LineAreaChart(
                    values: rev14,
                    color: champagne,
                    height: 96,
                    dark: true,
                    format: rupiahSingkat,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      HeroStat('Transaksi', '${jualBulan.length}'),
                      const HeroDivider(),
                      HeroStat('Terjual', kg(kgTerjual)),
                      const HeroDivider(),
                      HeroStat('Belum lunas', rupiahSingkat(piutang)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          gap(14),

          // ---------- KPI ----------
          FadeSlideIn(
            delay: 2,
            child: Row(
              children: [
                Expanded(
                  child: KpiCard(
                    label: 'Budidaya aktif',
                    value: '${aktif.length}',
                    icon: Icons.spa_rounded,
                    color: sage,
                    onTap: () => homeTab.value = 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label: 'Pakan hari ini',
                    value: kg(s.total(today)),
                    icon: Icons.restaurant_rounded,
                    color: peach,
                    trend: pakan7,
                  ),
                ),
              ],
            ),
          ),
          gap(12),
          FadeSlideIn(
            delay: 3,
            child: Row(
              children: [
                Expanded(
                  child: KpiCard(
                    label: 'Panen bulan ini',
                    value: kg(s.total(panenBulan)),
                    icon: Icons.agriculture_rounded,
                    color: butter,
                    trend: panen7,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label: 'Jumlah kandang',
                    value: '${s.kandang.length}',
                    icon: Icons.warehouse_rounded,
                    color: sky,
                    onTap: () => openPage(context, const KandangListPage()),
                  ),
                ),
              ],
            ),
          ),

          // ---------- Kalkulator ----------
          gap(14),
          FadeSlideIn(
            delay: 4,
            child: DarkCard(
              tone: CardTone.ink,
              onTap: () => openPage(context, const KalkulatorPage()),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        eyebrow('Bioconversion & ROI Engine', color: mint),
                        gap(10),
                        const Text(
                          'Kalkulator Biokonversi & Profit',
                          style: TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                        gap(6),
                        const Text(
                          'Simulasi rasio konversi pakan (FCR), hasil panen maggot fresh, pupuk kasgot, dan proyeksi omzet.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: emeraldLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Grafik mingguan ----------
          const SectionTitle('Statistik'),
          FadeSlideIn(
            delay: 4,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${const ['Total pakan', 'Total panen', 'Total penjualan'][chart]} ${const ['minggu ini', 'bulan ini', 'tahun ini'][periode]}',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ),
                      SegmentedPills(
                        items: const ['Minggu', 'Bulan', 'Tahun'],
                        index: periode,
                        onChanged: (i) => setState(() => periode = i),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(a),
                        child: c,
                      ),
                    ),
                    child: Text(
                      chart == 2 ? rupiah(weekTotal) : kg(weekTotal),
                      key: ValueKey('$chart-$periode-$weekTotal'),
                      style: const TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        color: ink,
                      ),
                    ),
                  ),
                  gap(14),
                  SegmentedPills(
                    items: const ['Pakan', 'Panen', 'Jual'],
                    index: chart,
                    expand: true,
                    onChanged: (i) => setState(() => chart = i),
                  ),
                  gap(18),
                  PeriodChart(
                    buckets: buckets,
                    values: week,
                    height: 170,
                    color: const [emeraldLight, forest, coral][chart],
                    format: chart == 2 ? rupiahSingkat : kg,
                  ),
                ],
              ),
            ),
          ),

          // ---------- Budidaya berjalan ----------
          SectionTitle(
            'Budidaya berjalan',
            action: 'Lihat semua',
            onAction: () => homeTab.value = 1,
          ),
          if (aktif.isEmpty)
            const EmptyState('Belum ada budidaya yang berjalan.')
          else
            FadeSlideIn(
              delay: 5,
              child: SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: const BouncingScrollPhysics(),
                  itemCount: aktif.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final b = aktif[i];
                    return SizedBox(
                      width: 250,
                      child: GlassCard(
                        onTap: () =>
                            openPage(context, BudidayaDetailPage(item: b)),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ProgressRing(
                              value: b.progress,
                              size: 66,
                              child: Text(
                                '${(b.progress * 100).round()}%',
                                style: const TextStyle(
                                  fontFamily: headFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.nama,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: headFont,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    s.kandangById(b.kandangId)?.nama ?? '-',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Pill(
                                    'Hari ke-${b.umur}',
                                    icon: Icons.schedule_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ---------- Aksi cepat ----------
          const SectionTitle('Aksi cepat'),
          FadeSlideIn(
            delay: 6,
            child: Row(
              children: [
                _quick(
                  Icons.restaurant_rounded,
                  'Pakan',
                  peach,
                  () => openPage(context, const CatatanFormPage(isPakan: true)),
                ),
                _quick(
                  Icons.agriculture_rounded,
                  'Panen',
                  butter,
                  () =>
                      openPage(context, const CatatanFormPage(isPakan: false)),
                ),
                _quick(
                  Icons.point_of_sale_rounded,
                  'Jual',
                  sage,
                  () => openPage(context, const PenjualanFormPage()),
                ),
                _quick(
                  Icons.warehouse_rounded,
                  'Kandang',
                  sky,
                  () => openPage(context, const KandangListPage()),
                ),
              ],
            ),
          ),

          // ---------- Donat ----------
          if (jenis.isNotEmpty) ...[
            const SectionTitle('Menu favorit maggot'),
            FadeSlideIn(
              delay: 7,
              child: GlassCard(
                child: DonutChart(
                  centerTitle: kg(s.total(s.pakan)),
                  centerSubtitle: 'total pakan',
                  segments: [
                    for (var i = 0; i < jenis.length && i < 5; i++)
                      (
                        label: jenis[i].key,
                        value: jenis[i].value,
                        color: _donutColors[i],
                      ),
                  ],
                ),
              ),
            ),
          ],

          // ---------- Aktivitas ----------
          const SectionTitle('Aktivitas terbaru'),
          if (events.isEmpty)
            const EmptyState('Belum ada aktivitas.')
          else
            FadeSlideIn(
              delay: 8,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final (i, e) in events.take(6).indexed) ...[
                      if (i > 0) const Divider(indent: 54),
                      ActivityRow(
                        leading: IconBubble(e.icon, color: e.color, size: 42),
                        title: e.title,
                        subtitle: e.subtitle,
                        trailing: e.amount,
                        trailingColor: e.amountColor,
                        trailingSub: tanggalPendek(e.date),
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

  Widget _quick(IconData icon, String label, Color color, VoidCallback onTap) =>
      Expanded(
        child: Pressable(
          onTap: onTap,
          scale: 0.92,
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x141C1C1E),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, color: emerald, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      );
}

// =====================================================================
// Akun
// =====================================================================
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      body: PageBody(
        children: [
          const PageHeader('Akun', eyebrowText: 'Profil kamu'),
          FadeSlideIn(
            child: DarkCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Mascot(size: 78),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nama,
                          style: const TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Pill(
                              s.farmName.isNotEmpty
                                  ? s.farmName
                                  : 'Peternak Maggot',
                              color: champagne,
                              textColor: emerald,
                              icon: Icons.workspace_premium_rounded,
                            ),
                            Pill(
                              'Akun online',
                              color: Colors.white.withValues(alpha: 0.18),
                              textColor: Colors.white,
                              icon: Icons.cloud_done_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
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
                _mini(
                  'Kandang',
                  '${s.kandang.length}',
                  Icons.warehouse_rounded,
                  sky,
                ),
                const SizedBox(width: 10),
                _mini(
                  'Siklus',
                  '${s.budidaya.length}',
                  Icons.spa_rounded,
                  sage,
                ),
                const SizedBox(width: 10),
                _mini(
                  'Transaksi',
                  '${s.penjualan.length}',
                  Icons.receipt_long_rounded,
                  peach,
                ),
              ],
            ),
          ),
          const SectionTitle('Pengaturan'),
          FadeSlideIn(
            delay: 2,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _menu(
                    Icons.edit_rounded,
                    sage,
                    'Edit profil',
                    'Ubah nama & email',
                    () => _edit(context, s),
                  ),
                  const Divider(indent: 56),
                  _menu(
                    Icons.lock_rounded,
                    peach,
                    'Ubah password',
                    'Simulasi keamanan akun',
                    () => openPage(context, const ResetPage()),
                  ),
                  const Divider(indent: 56),
                  _menu(
                    Icons.warehouse_rounded,
                    sky,
                    'Kelola kandang',
                    '${s.kandang.length} kandang terdaftar',
                    () => openPage(context, const KandangListPage()),
                  ),
                  const Divider(indent: 56),
                  _menu(
                    Icons.calculate_rounded,
                    butter,
                    'Kalkulator profit',
                    'Simulasi FCR, kasgot & omzet',
                    () => openPage(context, const KalkulatorPage()),
                  ),
                  const Divider(indent: 56),
                  _menu(
                    Icons.auto_awesome_rounded,
                    lavender,
                    'Lihat pengenalan',
                    'Tur singkat bersama Maggi',
                    () => openPage(context, const OnboardingPage(replay: true)),
                  ),
                ],
              ),
            ),
          ),
          gap(22),
          FadeSlideIn(
            delay: 3,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (await confirm(context, 'Keluar dari akun ${s.email}?') &&
                    context.mounted) {
                  await s.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
            ),
          ),
          gap(14),
          const Text(
            'Data akunmu tersimpan aman di server MaggotKu dan tetap ada walau ganti HP.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(icon, color: color, size: 36),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: headFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 21,
                  color: ink,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 11, color: muted)),
            ],
          ),
        ),
      );

  Widget _menu(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ActivityRow(
    onTap: onTap,
    leading: IconBubble(icon, color: color, size: 42),
    title: title,
    subtitle: subtitle,
    trailing: '›',
    trailingColor: muted,
  );

  void _edit(BuildContext context, AppState s) {
    final n = TextEditingController(text: s.nama),
        e = TextEditingController(text: s.email),
        f = TextEditingController(text: s.farmName);
    final key = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Mascot(size: 80),
        title: const Text('Edit profil'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: n,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: requiredText,
              ),
              gap(),
              TextFormField(
                controller: f,
                decoration: const InputDecoration(
                  labelText: 'Nama peternakan',
                  prefixIcon: Icon(Icons.agriculture_outlined),
                ),
              ),
              gap(),
              TextFormField(
                controller: e,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: emailText,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              final ok = await kirim(
                c,
                () => s.updateProfile(
                  n.text.trim(),
                  e.text.trim(),
                  f.text.trim(),
                ),
              );
              if (ok && c.mounted) Navigator.pop(c);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
