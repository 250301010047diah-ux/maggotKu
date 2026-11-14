import 'package:flutter/material.dart';

// ============ Palet "Ink & Ember" ============
// Tegas & minimalis: tinta hitam pekat, kertas hangat, satu aksen ember
// yang menyala. Krem maggot sebagai sentuhan khas.
const ink = Color(0xFF0F0F11); // teks utama
const muted = Color(0xFF76757B); // teks sekunder
const emerald = Color(0xFF111113); // tinta: tombol, navigasi, teks aktif
const emeraldLight = Color(0xFFFF5A1F); // aksen ember
const forest = Color(0xFF13A065); // hijau sukses
const mint = Color(0xFFFFFFFF); // teks positif di atas kartu hero
const champagne = Color(0xFFFFE3C7); // krem maggot
const coral = Color(0xFF2B2B30); // aksen kedua (tinta lembut)
const lavender = Color(0xFFEFEDFB);
const butter = Color(0xFFFFF2D6);
const danger = Color(0xFFE5383B);
const lime = Color(0xFFD8F25C); // sorotan kecil (badge "baru", dsb.)

/// Garis tipis kartu.
const hairline = Color(0x14000000);

// Latar ikon: tint lembut
const sage = Color(0xFFE9F5EE);
const gold = Color(0xFFFFC53D);
const peach = Color(0xFFFFE9DE);
const pink = Color(0xFFFCE8EC);
const sky = Color(0xFFE8EEF8);
const cream = Color(0xFFF4F2EE);
const sky2 = Color(0xFFB7B8C0);
const pink2 = Color(0xFFDAD3CB);

/// Gradasi hero ember.
const warmGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFF8A3D), Color(0xFFFF5A1F), Color(0xFFE23D12)],
  stops: [0, 0.5, 1],
);

/// Gradasi tinta untuk kartu gelap & tombol utama.
const inkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2A2A2F), Color(0xFF151518), Color(0xFF0A0A0B)],
  stops: [0, 0.55, 1],
);

// Font: DM Sans untuk semua — geometris & tegas.
const headFont = 'DMSans';
const bodyFont = 'DMSans';

TextTheme _textTheme() {
  final t = ThemeData(
    useMaterial3: true,
    fontFamily: bodyFont,
  ).textTheme.apply(bodyColor: ink, displayColor: ink);
  TextStyle? h(TextStyle? s) => s?.copyWith(
    fontFamily: headFont,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  return t.copyWith(
    displayLarge: h(t.displayLarge),
    displayMedium: h(t.displayMedium),
    displaySmall: h(t.displaySmall),
    headlineLarge: h(t.headlineLarge),
    headlineMedium: h(t.headlineMedium),
    headlineSmall: h(t.headlineSmall),
    titleLarge: h(t.titleLarge),
    titleMedium: h(t.titleMedium),
    titleSmall: h(t.titleSmall),
  );
}

/// Transisi halaman: halaman baru naik + memudar masuk,
/// halaman lama sedikit mengecil + memudar keluar.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final inA = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    );
    final outA = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.4).animate(outA),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.94).animate(outA),
        child: FadeTransition(
          opacity: inA,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(inA),
            child: child,
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: BorderSide(color: c, width: w),
);

final appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: bodyFont,
  textTheme: _textTheme(),
  scaffoldBackgroundColor: Colors.transparent,
  colorScheme: ColorScheme.fromSeed(
    seedColor: emeraldLight,
    primary: emerald,
    secondary: emeraldLight,
    surface: Colors.white,
    error: danger,
  ),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      for (final p in TargetPlatform.values)
        p: const SmoothPageTransitionsBuilder(),
    },
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: ink,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: headFont,
      color: ink,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF7F6F3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    labelStyle: const TextStyle(color: muted, fontSize: 14),
    hintStyle: const TextStyle(color: muted, fontSize: 14),
    floatingLabelStyle: const TextStyle(
      color: ink,
      fontWeight: FontWeight.w700,
    ),
    prefixIconColor: ink,
    suffixIconColor: muted,
    border: _border(hairline),
    enabledBorder: _border(hairline),
    focusedBorder: _border(ink, 1.8),
    errorBorder: _border(danger),
    focusedErrorBorder: _border(danger, 1.8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: emerald,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size.fromHeight(58),
      textStyle: const TextStyle(
        fontFamily: headFont,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: emerald,
      foregroundColor: Colors.white,
      minimumSize: const Size(64, 48),
      textStyle: const TextStyle(
        fontFamily: headFont,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      backgroundColor: Colors.white,
      minimumSize: const Size.fromHeight(58),
      side: const BorderSide(color: ink, width: 1.4),
      textStyle: const TextStyle(
        fontFamily: headFont,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: emeraldLight,
      textStyle: const TextStyle(
        fontFamily: headFont,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: const WidgetStatePropertyAll(Colors.white),
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? ink : const Color(0xFFD9D7D2),
    ),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: emerald,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontFamily: bodyFont,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    titleTextStyle: const TextStyle(
      fontFamily: headFont,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      letterSpacing: -0.3,
      color: ink,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: emerald,
    headerForegroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  ),
  dividerTheme: const DividerThemeData(color: hairline, space: 1),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: emeraldLight),
);
