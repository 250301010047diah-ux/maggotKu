import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/data/app_state.dart';
import 'package:maggotku/pages/biaya_pages.dart';
import 'package:maggotku/pages/pembeli_pages.dart';
import 'package:maggotku/pages/penjualan_pages.dart';
import 'package:maggotku/theme.dart';

Future<void> settle(WidgetTester t, [int steps = 12]) async {
  for (var i = 0; i < steps; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('halaman pembeli, piutang & biaya rapi di layar HP', (t) async {
    t.view.physicalSize = const Size(360, 740);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final s = AppState();
    final budi = await s.savePembeli(
      null,
      nama: 'Pak Budi Santoso dari Pasar Induk',
      noHp: '081234567890',
      alamat: 'Jl. Panjang sekali nomor 123',
    );
    await s.savePenjualan(
      null,
      tanggal: DateTime.now().subtract(const Duration(days: 40)),
      pembeli: budi.nama,
      produk: 'Maggot kering',
      berat: 12.5,
      harga: 45000,
      lunas: false,
      catatan: '',
      pembeliId: budi.id,
    );
    await s.saveBiaya(
      null,
      tanggal: DateTime.now(),
      kategori: 'Tenaga kerja',
      jumlah: 150000,
      keterangan: 'Upah harian',
    );

    for (final page in <Widget>[
      const PembeliPage(),
      PembeliDetailPage(pembeli: budi),
      const PembeliFormPage(),
      const BiayaPage(),
      const BiayaFormPage(),
      PenjualanFormPage(initialPembeli: budi),
      const PenjualanPage(),
    ]) {
      await t.pumpWidget(
        AppScope(
          state: s,
          child: MaterialApp(theme: appTheme, home: page),
        ),
      );
      await settle(t);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await settle(t);
      expect(t.takeException(), isNull, reason: '${page.runtimeType}');
    }

    // Tandai lunas dari detail pembeli.
    await t.pumpWidget(
      AppScope(
        state: s,
        child: MaterialApp(
          theme: appTheme,
          home: PembeliDetailPage(pembeli: budi),
        ),
      ),
    );
    await settle(t);
    expect(find.textContaining('Tagih'), findsWidgets);
  });
}
