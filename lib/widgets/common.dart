import 'package:flutter/material.dart';
import '../data/api.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import 'charts.dart';
import '../audio/app_sounds.dart';

// =====================================================================
// Navigasi, dialog & validasi
// =====================================================================
void openPage(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirm(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Mascot(mood: MaggotMood.sulky, size: 90),
        title: const Text('Yakin, nih?'),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ya, lanjut'),
          ),
        ],
      ),
    ) ??
    false;

/// Jalankan aksi simpan/hapus. Saat online menampilkan loading, dan bila
/// server menolak (mis. stok kurang / tidak ada internet) pesannya
/// ditampilkan. Mengembalikan true bila berhasil.
Future<bool> kirim(BuildContext context, Future<void> Function() action) async {
  final s = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  NavigatorState? nav;
  if (s.online) {
    nav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x331C1C1E),
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: SizedBox.square(
            dimension: 44,
            child: CircularProgressIndicator(strokeWidth: 3.5),
          ),
        ),
      ),
    );
  }
  try {
    await action();
    AppSounds.success();
    return true;
  } on ApiException catch (e) {
    AppSounds.warning();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  } finally {
    nav?.pop();
  }
}

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Wajib diisi' : null;
String? emailText(String? value) {
  if (requiredText(value) != null) return 'Email wajib diisi';
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!)
      ? null
      : 'Format email tidak valid';
}

String? positive(String? value) {
  final n = double.tryParse((value ?? '').replaceAll(',', '.'));
  return n == null || n <= 0 ? 'Masukkan angka lebih dari 0' : null;
}

double? number(String value) => double.tryParse(value.replaceAll(',', '.'));

Widget gap([double h = 12]) => SizedBox(height: h);

/// Teks kecil kapital berjarak lebar di atas judul.
Widget eyebrow(String text, {Color color = muted}) => Text(
  text.toUpperCase(),
  style: TextStyle(
    fontSize: 11,
    letterSpacing: 1.6,
    fontWeight: FontWeight.w600,
    color: color,
  ),
);

// =====================================================================
// Kerangka halaman
// =====================================================================
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.padding,
    this.onRefresh,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  /// Bila diisi, halaman bisa ditarik ke bawah untuk memuat ulang.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: padding ?? const EdgeInsets.fromLTRB(20, 8, 20, 130),
      children: children,
    );
    return SafeArea(
      bottom: false,
      child: onRefresh == null
          ? list
          : RefreshIndicator(
              color: emeraldLight,
              onRefresh: onRefresh!,
              child: list,
            ),
    );
  }
}

/// Judul besar untuk halaman tab.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.eyebrowText, this.trailing});
  final String title;
  final String? eyebrowText;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => FadeSlideIn(
    child: Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrowText != null) ...[
                  eyebrow(eyebrowText!),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    height: 1.05,
                    letterSpacing: -0.6,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// AppBar transparan dengan tombol kembali bulat.
PreferredSizeWidget elegantAppBar(
  BuildContext context,
  String title, {
  List<Widget> actions = const [],
}) => AppBar(
  automaticallyImplyLeading: false,
  leadingWidth: 68,
  leading: Navigator.of(context).canPop()
      ? Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: CircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.maybePop(context),
            ),
          ),
        )
      : null,
  title: Text(title),
  actions: [...actions, const SizedBox(width: 16)],
);

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 18,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: emeraldLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: headFont,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: ink,
            ),
          ),
        ),
        if (action != null)
          Pressable(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  action!,
                  style: const TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: emeraldLight,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: emeraldLight,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// =====================================================================
// Animasi
// =====================================================================
/// Muncul memudar sambil naik; [delay] = urutan (×70 ms).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.offset = 26,
  });
  final Widget child;
  final int delay;
  final double offset;
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _base = 560, _step = 70;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _base + widget.delay * _step),
  )..forward();
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay * _step / (_base + widget.delay * _step),
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _a.value,
      child: Transform.translate(
        offset: Offset(0, widget.offset * (1 - _a.value)),
        child: child,
      ),
    ),
  );
}

/// Membungkus widget agar sedikit mengecil saat ditekan.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// =====================================================================
// Kartu
// =====================================================================
/// Kartu terang bergaya "bevel": bingkai bergradasi (terang di atas,
/// abu hangat di bawah), permukaan putih-ke-krem, cahaya krem maggot
/// samar di pojok, bayangan dua lapis, dan garis aksen opsional.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.color,
    this.radius = 28,
    this.accent,
    this.glow = true,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding, margin;
  final Color? color;
  final double radius;

  /// Warna garis aksen tipis di sisi kiri (opsional).
  final Color? accent;

  /// Cahaya krem lembut di pojok kanan atas.
  final bool glow;

  static const _bevel = 1.2;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(_bevel),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3DFDA)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x1A1C1C1E),
              blurRadius: 28,
              spreadRadius: -6,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - _bevel),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              gradient: color == null
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF8F6F3)],
                    )
                  : null,
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                if (glow)
                  Positioned(
                    top: -70,
                    right: -70,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x40FFE0C6), Color(0x00FFE0C6)],
                        ),
                      ),
                    ),
                  ),
                if (accent != null)
                  Positioned(
                    left: 0,
                    top: 20,
                    bottom: 20,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

enum CardTone { warm, ink }

/// Kartu hero: gradasi oranye hangat (default) atau arang,
/// dengan cahaya lembut seperti kaca buram.
class DarkCard extends StatelessWidget {
  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.tone = CardTone.warm,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final warm = tone == CardTone.warm;
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: warm ? warmGradient : inkGradient,
          boxShadow: [
            BoxShadow(
              color: warm ? const Color(0x55F26B2A) : const Color(0x33000000),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Positioned(
                left: -80,
                top: -110,
                child: _glow(
                  280,
                  warm ? const Color(0x80FFE7D1) : const Color(0x1FFFFFFF),
                ),
              ),
              Positioned(
                right: -70,
                bottom: -110,
                child: _glow(
                  260,
                  warm ? const Color(0x66B8321A) : const Color(0x40EE6A2C),
                ),
              ),
              // garis kilap tipis di tepi atas
              Positioned(
                left: 24,
                right: 24,
                top: 0,
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: warm ? 0.35 : 0.12),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _glow(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

class HeroStat extends StatelessWidget {
  const HeroStat(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
      ],
    ),
  );
}

class HeroDivider extends StatelessWidget {
  const HeroDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    color: Colors.white.withValues(alpha: 0.14),
  );
}

/// Kartu statistik dengan ikon & tren mini.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final List<double>? trend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: inkGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const Spacer(),
            if (trend != null)
              SizedBox(width: 58, child: Sparkline(values: trend!))
            else if (onTap != null)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x1A1C1C1E)),
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 15,
                  color: ink,
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: headFont,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              height: 1.05,
              letterSpacing: -0.6,
              color: ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
      ],
    ),
  );
}

/// Baris aktivitas / transaksi.
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingColor = ink,
    this.trailingSub,
    this.trailingSubColor = muted,
    this.onTap,
  });
  final Widget leading;
  final String title, subtitle;
  final String? trailing, trailingSub;
  final Color trailingColor, trailingSubColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.98,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trailing!,
                  style: TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: trailingColor,
                  ),
                ),
                if (trailingSub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    trailingSub!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trailingSubColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

// =====================================================================
// Elemen kecil
// =====================================================================
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = const Color(0xFFFFEADF),
    this.textColor = const Color(0xFFC4501C),
    this.icon,
  });
  final String text;
  final Color color, textColor;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    ),
  );
}

class IconBubble extends StatelessWidget {
  const IconBubble(
    this.icon, {
    super.key,
    this.color = sage,
    this.iconColor = emerald,
    this.size = 44,
  });
  final IconData icon;
  final Color color, iconColor;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.34),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Icon(icon, size: size * 0.48, color: iconColor),
  );
}

class EmojiBubble extends StatelessWidget {
  const EmojiBubble(this.emoji, {super.key, this.color = sage, this.size = 44});
  final String emoji;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.34),
    ),
    child: Text(emoji, style: TextStyle(fontSize: size * 0.48)),
  );
}

class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = false,
    this.size = 44,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  final double size;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.9,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.94),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x141C1C1E),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: Icon(icon, size: size * 0.44, color: dark ? Colors.white : ink),
    ),
  );
}

/// Tombol pilihan berbentuk pil dengan indikator beranimasi.
class SegmentedPills extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.dark = false,
    this.expand = false,
  });
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final bool dark, expand;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: 0.10)
          : const Color(0x0F1C1C1E),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          _wrap(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: i == index
                      ? (dark ? champagne : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: i == index && !dark
                      ? const [
                          BoxShadow(
                            color: Color(0x1A1C1C1E),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  items[i],
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: headFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: i == index
                        ? emerald
                        : (dark ? Colors.white70 : muted),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _wrap(Widget w) => expand ? Expanded(child: w) : w;
}

/// Tombol aksi mengambang bergradasi.
class GradientFab extends StatelessWidget {
  const GradientFab({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
    this.lift = true,
  });
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  /// Naikkan di atas navigasi bawah yang mengambang.
  final bool lift;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: lift ? 92 : 0),
    child: Pressable(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.fromLTRB(8, 0, 22, 0),
        decoration: BoxDecoration(
          gradient: inkGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: emeraldLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: headFont,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// =====================================================================
// Maskot
// =====================================================================
enum MaggotMood { happy, sulky }

/// Maskot maggot beranimasi dari sprite sheet 4x2 (8 frame).
/// - happy: melambai & berkedip, berulang terus.
/// - sulky: ngambek, juga berulang terus.
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.mood = MaggotMood.happy, this.size = 120});
  final MaggotMood mood;
  final double size;

  static const _sheets = {
    MaggotMood.happy:
        'assets/images/image/Cream mascot waving and blinking.png',
    MaggotMood.sulky:
        'assets/images/image/Eight-frame sulky cream maggot animation.png',
  };

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  static const _cols = 4, _rows = 2, _frames = 8;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() => _c
    ..reset()
    ..repeat();

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _start();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final sheet = Image.asset(
      Mascot._sheets[widget.mood]!,
      width: size * _cols,
      height: size * _rows,
      fit: BoxFit.fill,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Center(
        child: Text('🐛', style: TextStyle(fontSize: size * 0.5)),
      ),
    );
    // Align menjaga "jendela" sprite tetap persegi walau induknya
    // memaksa lebar penuh (misalnya slot ikon dialog), supaya frame
    // tetangga tidak ikut terlihat.
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: size,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _c,
            child: sheet,
            builder: (_, child) {
              final f = (_c.value * _frames).floor().clamp(0, _frames - 1);
              final col = f % _cols, row = f ~/ _cols;
              return OverflowBox(
                minWidth: size * _cols,
                maxWidth: size * _cols,
                minHeight: size * _rows,
                maxHeight: size * _rows,
                alignment: Alignment(
                  -1 + 2 * col / (_cols - 1),
                  -1 + 2 * row / (_rows - 1),
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    child: Column(
      children: [
        const Mascot(mood: MaggotMood.sulky, size: 100),
        const SizedBox(height: 12),
        const Text(
          'Masih kosong nih',
          style: TextStyle(
            fontFamily: headFont,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 13),
        ),
      ],
    ),
  );
}

// =====================================================================
// Input
// =====================================================================
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Pressable(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onChanged(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x1A1C1C1E)),
        ),
        child: Row(
          children: [
            const IconBubble(Icons.calendar_month_rounded, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value == null ? 'Pilih tanggal' : tanggalPanjang(value!),
                    style: const TextStyle(
                      fontFamily: headFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: muted),
          ],
        ),
      ),
    ),
  );
}

/// Gaya teks dropdown agar sama dengan isian lain.
const dropdownStyle = TextStyle(fontFamily: bodyFont, fontSize: 15, color: ink);
