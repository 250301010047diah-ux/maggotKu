import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/data/app_state.dart';
import 'package:maggotku/main.dart';
import 'package:maggotku/pages/home_page.dart';
import 'package:maggotku/pages/kalkulator_page.dart';
import 'package:maggotku/widgets/charts.dart';
import 'package:maggotku/widgets/common.dart';

// Maskot & grafik beranimasi berulang, jadi pakai pump berdurasi.
Future<void> settle(WidgetTester t, [int steps = 15]) async {
  for (var i = 0; i < steps; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Buka aplikasi dalam keadaan sudah login (tanpa server).
Future<void> bukaSudahLogin(WidgetTester t) async {
  await t.pumpWidget(MaggotKuApp(state: AppState()..loggedIn = true));
  await settle(t);
}

Future<void> skipOnboarding(WidgetTester t) async {
  await t.tap(find.text('Lewati'));
  await settle(t);
}

void main() {
  testWidgets('onboarding bisa digeser sampai tombol mulai', (tester) async {
    await tester.pumpWidget(const MaggotKuApp());
    expect(find.text('Halo, aku Maggi!'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await settle(tester);
    await tester.tap(find.text('Lanjut'));
    await settle(tester);
    expect(find.text('Mulai Sekarang'), findsOneWidget);
    await tester.tap(find.text('Mulai Sekarang'));
    await settle(tester);
    // Halaman Login: hanya akun, tanpa mode demo.
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.textContaining('mode demo'), findsNothing);
  });

  testWidgets('sudah login langsung ke dashboard', (tester) async {
    await bukaSudahLogin(tester);
    expect(find.textContaining('Halo,'), findsOneWidget);
    expect(find.text('BUDIDAYA AKTIF'), findsOneWidget);
    expect(find.byType(LineAreaChart), findsWidgets);
    expect(find.byType(ElegantNavBar), findsOneWidget);

    // pindah ke tab penjualan
    await tester.tap(find.byIcon(Icons.payments_rounded).last);
    await settle(tester);
    expect(find.text('Penjualan'), findsWidgets);
  });

  testWidgets('semua tab tampil rapi di layar HP', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await bukaSudahLogin(tester);
    for (final icon in [
      Icons.spa_rounded,
      Icons.edit_note_rounded,
      Icons.payments_rounded,
      Icons.person_rounded,
      Icons.home_rounded,
    ]) {
      await tester.tap(find.byIcon(icon).last);
      await settle(tester);
      // gulir sampai bawah supaya semua kartu ikut dirender
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await settle(tester);
    }
    expect(find.byType(ElegantNavBar), findsOneWidget);
  });

  testWidgets('kalkulator terbuka & menghitung', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await bukaSudahLogin(tester);
    await tester.ensureVisible(find.text('Kalkulator Biokonversi & Profit'));
    await settle(tester, 3);
    await tester.tap(find.text('Kalkulator Biokonversi & Profit'));
    await settle(tester);
    expect(find.byType(KalkulatorPage), findsOneWidget);
    // 100 kg pakan × 18% = 18 kg maggot
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -450));
    await settle(tester);
    expect(find.text('18 kg'), findsWidgets);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 450));
    await settle(tester);
    await tester.ensureVisible(find.text('Pakai data saya'));
    await settle(tester, 3);
    await tester.tap(find.text('Pakai data saya'));
    await settle(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await settle(tester);
  });

  testWidgets('maggot ngambek kalau isian login salah', (tester) async {
    await tester.pumpWidget(const MaggotKuApp());
    await skipOnboarding(tester);
    Mascot mascot() => tester.widget<Mascot>(find.byType(Mascot).first);
    expect(mascot().mood, MaggotMood.happy);

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await settle(tester);
    expect(mascot().mood, MaggotMood.sulky);

    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await settle(tester);
    expect(mascot().mood, MaggotMood.happy);
  });
}
