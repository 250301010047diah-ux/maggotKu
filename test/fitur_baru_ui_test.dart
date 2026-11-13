import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/data/app_state.dart';
import 'package:maggotku/main.dart';
import 'package:maggotku/pages/budidaya_pages.dart';
import 'package:maggotku/pages/penjualan_pages.dart';
import 'package:maggotku/pages/stok_pages.dart';

Future<void> settle(WidgetTester t, [int steps = 15]) async {
  for (var i = 0; i < steps; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

AppState _dataContoh() {
  final s = AppState()
    ..onboardingDone = true
    ..loggedIn = true;
  final today = DateUtils.dateOnly(DateTime.now());
  s.saveKandang(null, 'Kandang A', 'Belakang', 50, '');
  s.saveBudidaya(
    null,
    'Batch Fresh',
    1,
    today.subtract(const Duration(days: 15)),
    3,
    null,
    '',
  );
  s.saveBudidaya(
    null,
    'Indukan A',
    1,
    today.subtract(const Duration(days: 26)),
    null,
    null,
    '',
    tujuan: 'perkawinan',
  );
  s.saveCatatan(false, null, 1, today, 5, '', 'Maggot segar');
  s.saveCatatan(false, null, 2, today, 30, '', 'Telur');
  s.olah(3, 1, today);
  return s;
}

Future<void> _scrollAll(WidgetTester t) async {
  await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
  await settle(t);
}

void main() {
  testWidgets('fitur stok, fase, absen & agenda rapi di layar HP', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final s = _dataContoh();
    await t.pumpWidget(MaggotKuApp(state: s));
    await settle(t);

    // Pop-up agenda muncul otomatis (sekali sehari)…
    expect(s.agenda(), isNotEmpty);
    expect(find.text('AGENDA HARI INI'), findsOneWidget);
    Navigator.of(t.element(find.text('AGENDA HARI INI'))).pop();
    await settle(t);
    // …lalu bisa dibuka lagi lewat lonceng.
    await t.tap(find.byIcon(Icons.notifications_active_rounded));
    await settle(t);
    expect(find.text('AGENDA HARI INI'), findsOneWidget);
    Navigator.of(t.element(find.text('AGENDA HARI INI'))).pop();
    await settle(t);

    // Tab Jual dengan grid stok.
    await t.tap(find.byIcon(Icons.payments_rounded).last);
    await settle(t);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await settle(t);
    expect(find.byType(StokGrid), findsOneWidget);

    // Halaman stok, olah, penyesuaian, form jual.
    final ctx = t.element(find.byType(StokGrid));
    for (final page in const [
      StokPage(),
      OlahPage(),
      PenyesuaianPage(),
      PenjualanFormPage(),
    ]) {
      Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => page));
      await settle(t);
      await _scrollAll(t);
      Navigator.of(ctx).pop();
      await settle(t);
    }

    // Detail batch perkawinan: timeline fase + absen foto.
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => BudidayaDetailPage(item: s.budidaya[1]),
      ),
    );
    await settle(t);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await settle(t);
    expect(find.text('Absen foto mingguan'), findsOneWidget);
    await _scrollAll(t);

    // Form budidaya dengan pilihan tujuan.
    Navigator.of(
      ctx,
    ).push(MaterialPageRoute(builder: (_) => const BudidayaFormPage()));
    await settle(t);
    await _scrollAll(t);
  });

  testWidgets('penjualan melebihi stok ditolak', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final s = _dataContoh(); // stok maggot segar = 5 − 3 (olah) = 2 kg
    expect(s.stok('Maggot segar'), 2);
    await t.pumpWidget(MaggotKuApp(state: s));
    await settle(t);
    final ctx = t.element(find.byType(Scaffold).first);
    Navigator.of(
      ctx,
    ).push(MaterialPageRoute(builder: (_) => const PenjualanFormPage()));
    await settle(t);
    await t.enterText(find.byType(TextFormField).at(0), 'Pak Budi');
    await t.enterText(find.byType(TextFormField).at(1), '5');
    await t.ensureVisible(find.text('Simpan Penjualan'));
    await settle(t, 3);
    await t.tap(find.text('Simpan Penjualan'));
    await settle(t);
    expect(find.text('Stok tinggal 2 kg'), findsOneWidget);
    expect(s.penjualan, isEmpty);

    // Jumlah sesuai stok → tersimpan & struk muncul.
    await t.enterText(find.byType(TextFormField).at(1), '2');
    await t.tap(find.text('Simpan Penjualan'));
    await settle(t);
    expect(s.penjualan.length, 1);
    expect(find.text('TRANSAKSI BERHASIL'), findsOneWidget);
    expect(find.text('Stok Maggot segar habis 📦'), findsOneWidget);
  });
}
