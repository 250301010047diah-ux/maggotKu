import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/data/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('data & foto tetap ada setelah aplikasi dibuka ulang', () async {
    SharedPreferences.setMockInitialValues({});

    final a = await AppState.load();
    expect(a.kandang, isEmpty);
    a.onboardingDone = true;
    a.loggedIn = true;
    a.saveKandang(null, 'Kandang A', 'Belakang', 50, '');
    a.saveBudidaya(null, 'Batch 1', 1, DateTime(2026, 11, 1), 2, null, '');
    a.saveCatatan(false, null, 1, DateTime(2026, 11, 10), 1.5, '', '');
    a.savePenjualan(
      null,
      tanggal: DateTime(2026, 11, 11),
      pembeli: 'Pak Budi',
      produk: 'Maggot segar',
      berat: 3,
      harga: 8000,
      lunas: false,
      catatan: '',
    );
    a.addFoto(1, '/data/foto_maggot/1.jpg', DateTime(2026, 11, 12));
    a.updateProfile('Abih', 'abih@contoh.com');

    // "Buka ulang" aplikasi: muat dari penyimpanan yang sama.
    final b = await AppState.load();
    expect(b.onboardingDone, isTrue);
    // Tanpa token akun (mode demo sudah dihapus) → harus login lagi.
    expect(b.loggedIn, isFalse);
    expect(b.nama, 'Abih');
    expect(b.kandang.single.nama, 'Kandang A');
    expect(b.budidaya.single.nama, 'Batch 1');
    expect(b.panen.single.berat, 1.5);
    expect(b.penjualan.single.lunas, isFalse);
    expect(b.penjualan.single.total, 24000);
    expect(b.fotoOf(1).single.path, '/data/foto_maggot/1.jpg');
  });

  test('data lama berisi "Prepupa" dipindah ke maggot segar', () async {
    SharedPreferences.setMockInitialValues({
      'maggotku_data_v1': jsonEncode({
        'onboardingDone': true,
        'kandang': [
          {'id': 1, 'nama': 'A', 'lokasi': 'x', 'catatan': ''},
        ],
        'budidaya': [
          {
            'id': 1,
            'nama': 'B1',
            'kandangId': 1,
            'mulai': '2026-11-01T00:00:00.000',
            'tujuan': 'prepupa',
          },
        ],
        'panen': [
          {
            'id': 1,
            'budidayaId': 1,
            'tanggal': '2026-11-10T00:00:00.000',
            'berat': 4,
            'jenis': 'Prepupa',
          },
        ],
        'penjualan': [
          {
            'id': 1,
            'tanggal': '2026-11-11T00:00:00.000',
            'pembeli': 'Pak Budi',
            'produk': 'Prepupa',
            'berat': 1,
            'harga': 12000,
          },
        ],
      }),
    });
    final s = await AppState.load();
    expect(s.budidaya.single.tujuan, 'fresh');
    expect(s.produkOf(s.panen.single), 'Maggot segar');
    expect(s.penjualan.single.produk, 'Maggot segar');
    expect(s.stok('Maggot segar'), 3);
  });

  test('data rusak tidak membuat aplikasi crash', () async {
    SharedPreferences.setMockInitialValues({'maggotku_data_v1': '{rusak'});
    final s = await AppState.load();
    expect(s.kandang, isEmpty);
  });
}
