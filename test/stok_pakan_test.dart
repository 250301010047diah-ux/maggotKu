import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/data/app_state.dart';
import 'package:maggotku/main.dart';
import 'package:maggotku/pages/stok_pakan_pages.dart';

DateTime hariLalu(int n) =>
    DateUtils.dateOnly(DateTime.now()).subtract(Duration(days: n));

/// Satu kandang + satu batch aktif, siap dicatat pakannya.
AppState siapkan() {
  final s = AppState();
  s.saveKandang(null, 'Kandang A', 'Belakang', 50, '');
  s.saveBudidaya(null, 'Batch 1', 1, hariLalu(5), null, null, '');
  return s;
}

void main() {
  test('stok pakan = masuk ± penyesuaian − diberikan', () {
    final s = siapkan();
    s.addMutasiPakan('Ampas tahu', 20, 'masuk', harga: 1500);
    s.addMutasiPakan('Ampas tahu', -2, 'penyesuaian', keterangan: 'Busuk');
    s.saveCatatan(true, null, 1, DateTime.now(), 5, '', 'Ampas tahu');
    expect(s.stokPakan('Ampas tahu'), 13);
    expect(s.stokPakan('Dedak'), 0);
  });

  test('jenis pakan lama yang diketik bebas masuk ke "Lainnya"', () {
    final s = siapkan();
    s.addMutasiPakan('Lainnya', 10, 'masuk');
    s.saveCatatan(true, null, 1, DateTime.now(), 4, '', 'daun pepaya');
    expect(s.stokPakan('Lainnya'), 6);
  });

  test('pemakaian rata-rata & perkiraan sisa hari', () {
    final s = siapkan();
    s.addMutasiPakan('Sisa sayur', 30, 'masuk', tanggal: hariLalu(7));
    for (var i = 0; i < 7; i++) {
      s.saveCatatan(true, null, 1, hariLalu(i), 2, '', 'Sisa sayur');
    }
    expect(s.pemakaianHarian('Sisa sayur'), 2);
    expect(s.stokPakan('Sisa sayur'), 16);
    expect(s.sisaHariPakan('Sisa sayur'), 8);
    expect(s.sisaHariPakan('Dedak'), isNull); // belum pernah dipakai
  });

  test('agenda: hampir habis bila cukup ≤ 2 hari', () {
    final s = siapkan();
    s.addMutasiPakan('Dedak', 10, 'masuk', tanggal: hariLalu(6));
    for (var i = 0; i < 7; i++) {
      s.saveCatatan(true, null, 1, hariLalu(i), 1, '', 'Dedak');
    }
    // stok 3 kg, pakai 1 kg/hari → cukup 3 hari: belum diperingatkan
    expect(s.agenda().where((a) => a.kind == 'stokpakan'), isEmpty);
    s.saveCatatan(true, null, 1, DateTime.now(), 1.5, '', 'Dedak');
    // stok 1,5 kg, pakai ±1,2 kg/hari → cukup ±1 hari
    final a = s.agenda().firstWhere((a) => a.kind == 'stokpakan');
    expect(a.title, contains('Dedak tinggal'));
    expect(a.budidaya, isNull);
  });

  test('kesegaran: kiriman lama yang belum habis diperingatkan (FIFO)', () {
    final s = siapkan();
    // Batas segar ampas tahu 2 hari.
    s.addMutasiPakan('Ampas tahu', 10, 'masuk', tanggal: hariLalu(4));
    s.addMutasiPakan('Ampas tahu', 10, 'masuk', tanggal: hariLalu(0));
    s.saveCatatan(true, null, 1, hariLalu(1), 6, '', 'Ampas tahu');
    final basi = s.pakanLewatSegar();
    expect(basi.length, 1);
    expect(basi.single.sisa, 4); // 10 − 6 dari kiriman pertama
    expect(basi.single.umur, 4);
    expect(s.agenda().any((a) => a.kind == 'segar'), isTrue);

    // Sisa kiriman lama dibuang → peringatan hilang.
    s.addMutasiPakan('Ampas tahu', -4, 'penyesuaian', keterangan: 'Busuk');
    expect(s.pakanLewatSegar(), isEmpty);
  });

  test('biaya pakan bulan ini & harga rata-rata per kg', () {
    final s = siapkan();
    s.addMutasiPakan('Ampas tahu', 10, 'masuk', harga: 1000);
    s.addMutasiPakan('Dedak', 10, 'masuk', harga: 3000);
    s.addMutasiPakan('Sisa sayur', 50, 'masuk'); // gratis, tanpa harga
    final now = DateTime.now();
    expect(
      s.biayaPakan(
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      ),
      40000,
    );
    expect(s.hargaPakanRata(), 2000);
  });

  testWidgets('tab Stok Pakan & form pakan masuk tampil rapi di HP', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final s = siapkan()
      ..onboardingDone = true
      ..loggedIn = true;
    s.addMutasiPakan(
      'Ampas tahu',
      10,
      'masuk',
      harga: 1500,
      tanggal: hariLalu(4),
    );
    s.saveCatatan(true, null, 1, DateTime.now(), 9, '', 'Ampas tahu');
    await t.pumpWidget(MaggotKuApp(state: s));
    for (var i = 0; i < 15; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // Tutup pop-up agenda harian bila muncul.
    if (find.text('AGENDA HARI INI').evaluate().isNotEmpty) {
      Navigator.of(t.element(find.text('AGENDA HARI INI'))).pop();
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    await t.tap(find.byIcon(Icons.edit_note_rounded).last);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.text('🏚️ Stok Pakan'));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(StokPakanView), findsOneWidget);
    expect(find.text('Hampir habis'), findsWidgets);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    final ctx = t.element(find.byType(StokPakanView));
    Navigator.of(
      ctx,
    ).push(MaterialPageRoute(builder: (_) => const PakanMasukPage()));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  });
}
