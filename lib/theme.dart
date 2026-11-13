import 'package:flutter/material.dart';

// ============ Palet "Soft Minimal • Maggot Cream & Ember" ============
// Netral lembut + arang untuk elemen utama + oranye hangat sebagai aksen,
// krem maggot sebagai sentuhan khas.
const ink = Color(0xFF1C1C1E); // teks utama
const muted = Color(0xFF8A8A8F); // teks sekunder
const emerald = Color(0xFF232325); // arang: tombol, navigasi, teks aktif
const emeraldLight = Color(0xFFEE6A2C); // aksen oranye ember
const forest = Color(0xFF2E9E6B); // hijau sukses
const mint = Color(0xFFFFFFFF); // teks positif di atas kartu hero
const champagne = Color(0xFFFFE7D1); // krem maggot
const coral = Color(0xFF3A3A3D); // aksen kedua (arang lembut)
const lavender = Color(0xFFF1EFF8);
const butter = Color(0xFFFFF5E4);

// Latar ikon: netral hangat yang sangat lembut
const sage = Color(0xFFF1F4F1);
const gold = Color(0xFFFFD166);
const peach = Color(0xFFFFEFE5);
const pink = Color(0xFFFBEFF1);
const sky = Color(0xFFF0F2F6);
const cream = Color(0xFFF5F4F2);
const sky2 = Color(0xFFB9B9BE);
const pink2 = Color(0xFFDCD6D0);

/// Gradasi hero hangat (oranye ember).
const warmGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFA978), Color(0xFFF26B2A), Color(0xFFD8431F)],
  stops: [0, 0.5, 1],
);

/// Gradasi arang untuk kartu gelap & tombol utama.
const inkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF3B3B3E), Color(0xFF242426), Color(0xFF161617)],
  stops: [0, 0.55, 1],
);

// Font: Nunito untuk judul & angka, DM Sans untuk teks biasa.
const headFont = 'Nunito';
const bodyFont = 'DMSans';

TextTheme _textTheme() {
  final t = ThemeData(
    useMaterial3: true,
    fontFamily: bodyFont,
  ).textTheme.apply(bodyColor: ink, displayColor: ink);
  TextStyle? h(TextStyle? s) =>
      s?.copyWith(fontFamily: headFont, fontWeight: FontWeight.w700);
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
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final outA = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: ReverseAnimation(outA),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.95).animate(outA),
        child: FadeTransition(
          opacity: inA,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(inA),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(inA),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(18),
  borderSide: BorderSide(color: c, width: w),
);

final appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: bodyFont,
  textTheme: _textTheme(),
  scaffoldBackgroundColor: Colors.transparent,
  colorScheme: ColorScheme.fromSeed(
    seedColor: forest,
    primary: emerald,
    secondary: champagne,
    surface: Colors.white,
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
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    labelStyle: const TextStyle(color: muted, fontSize: 14),
    hintStyle: const TextStyle(color: muted, fontSize: 14),
    floatingLabelStyle: const TextStyle(
      color: emerald,
      fontWeight: FontWeight.w600,
    ),
    prefixIconColor: muted,
    suffixIconColor: muted,
    border: _border(const Color(0x0D000000)),
    enabledBorder: _border(const Color(0x0D000000)),
    focusedBorder: _border(emeraldLight, 1.6),
    errorBorder: _border(const Color(0xFFD9534F)),
    focusedErrorBorder: _border(const Color(0xFFD9534F), 1.6),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: emerald,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size.fromHeight(56),
      textStyle: const TextStyle(
        fontFamily: headFont,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      shape: const StadiumBorder(),
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
      shape: const StadiumBorder(),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: emerald,
      backgroundColor: Colors.white,
      minimumSize: const Size.fromHeight(56),
      side: const BorderSide(color: Color(0x0F000000)),
      textStyle: const TextStyle(
        fontFamily: headFont,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      shape: const StadiumBorder(),
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
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: emerald,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontFamily: bodyFont,
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
      color: ink,
    ),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: emerald,
    headerForegroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0x121C1C1E), space: 1),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: emeraldLight),
);
