import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/data/app_state.dart';
import 'package:maggotku/data/models.dart';

void main() {
  test('nomor HP diubah ke format wa.me', () {
    expect(nomorWa('0812-3456-7890'), '6281234567890');
    expect(nomorWa('+62 812 345'), '62812345');
    expect(nomorWa('812345'), '62812345');
    expect(nomorWa(''), isNull);
  });

  test('piutang dikelompokkan per pembeli & bisa dilunasi', () async {
    final s = AppState();
    final budi = await s.savePembeli(null, nama: 'Pak Budi', noHp: '0812');
    final lama = DateTime.now().subtract(const Duration(days: 20));
    for (final (tgl, nama, id, lunas) in [
      (lama, 'Pak Budi', budi.id, false),
      (DateTime.now(), 'Pak Budi', budi.id, false),
      (DateTime.now(), 'Bu Sari', null, false),
      (DateTime.now(), 'Bu Sari', null, true),
    ]) {
      await s.savePenjualan(
        null,
        tanggal: tgl,
        pembeli: nama,
        produk: 'Maggot segar',
        berat: 2,
        harga: 10000,
        lunas: lunas,
        catatan: '',
        pembeliId: id,
      );
    }

    final p = s.piutang();
    expect(p.map((e) => e.nama), ['Pak Budi', 'Bu Sari']);
    expect(p.first.total, 40000);
    expect(p.first.umur, 20);
    expect(p.first.pembeli, same(budi));
    expect(s.pesanTagih('Pak Budi', p.first.items), contains('Rp 40.000'));

    // Piutang ≥14 hari muncul di agenda.
    expect(s.agenda().where((a) => a.kind == 'tagih').map((a) => a.title), [
      'Tagih Pak Budi Rp 40.000',
    ]);

    for (final e in [...p.first.items]) {
      await s.tandaiLunas(e);
    }
    expect(s.piutang().map((e) => e.nama), ['Bu Sari']);
    expect(s.penjualan.first.tanggalLunas, isNotNull);
  });

  test('ganti nama pembeli ikut mengubah riwayat penjualan', () async {
    final s = AppState();
    final b = await s.savePembeli(null, nama: 'Pak Bud');
    await s.savePenjualan(
      null,
      tanggal: DateTime.now(),
      pembeli: 'Pak Bud',
      produk: 'Pupa',
      berat: 1,
      harga: 15000,
      lunas: true,
      catatan: '',
      pembeliId: b.id,
    );
    await s.savePembeli(b, nama: 'Pak Budi');
    expect(s.penjualan.single.pembeli, 'Pak Budi');
    expect(s.penjualanOf(b), hasLength(1));

    await s.deletePembeli(b);
    expect(s.penjualan.single.pembeliId, isNull);
  });

  test('rapor siklus: biaya pakan beku, biaya lain & FCR', () async {
    final s = AppState();
    await s.saveKandang(null, 'A', 'Belakang', null, '');
    await s.saveBudidaya(
      null,
      'Batch 1',
      1,
      DateTime.now().subtract(const Duration(days: 10)),
      null,
      null,
      '',
    );
    final b = s.budidaya.single;
    // Harga bawaan diambil dari rata-rata pembelian pakan.
    await s.addMutasiPakan('Ampas tahu', 100, 'masuk', harga: 500);
    await s.saveCatatan(true, null, b.id, DateTime.now(), 8, '', 'Ampas tahu');
    await s.saveCatatan(
      true,
      null,
      b.id,
      DateTime.now(),
      4,
      '',
      'Dedak',
      hargaPerKg: 2000,
    );
    await s.saveCatatan(
      false,
      null,
      b.id,
      DateTime.now(),
      3,
      '',
      'Maggot segar',
    );
    await s.saveBiaya(
      null,
      tanggal: DateTime.now(),
      kategori: 'Bibit/telur',
      jumlah: 25000,
      budidayaId: b.id,
    );
    await s.saveBiaya(
      null,
      tanggal: DateTime.now(),
      kategori: 'Listrik & air',
      jumlah: 10000,
    );

    final r = s.rapor(b);
    expect(s.pakan.first.hargaPerKg, 500);
    expect(r.pakanKg, 12);
    expect(r.biayaPakan, 8 * 500 + 4 * 2000);
    expect(r.biayaLain, 25000); // biaya umum tidak masuk siklus
    expect(r.fcr, 4);
    expect(r.durasi, 10);
    expect(r.hargaPakanLengkap, isTrue);

    final now = DateTime.now();
    expect(
      s.biayaLain(
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      ),
      35000,
    );

    await s.finish(b);
    expect(b.selesai, isTrue);
    expect(b.tanggalSelesai, isNotNull);
  });

  test('data baru ikut tersimpan & dimuat ulang (JSON)', () {
    final p = Penjualan(
      1,
      DateTime(2026, 11, 1),
      'Pak Budi',
      'Pupa',
      1,
      15000,
      lunas: true,
      pembeliId: 7,
      tanggalLunas: DateTime(2026, 11, 3),
    );
    final q = Penjualan.fromJson(p.toJson());
    expect(q.pembeliId, 7);
    expect(q.tanggalLunas, DateTime(2026, 11, 3));

    final b = Biaya.fromJson(
      Biaya(
        2,
        DateTime(2026, 11, 2),
        'Transport',
        5000,
        budidayaId: 3,
      ).toJson(),
    );
    expect((b.kategori, b.jumlah, b.budidayaId), ('Transport', 5000, 3));

    final api = penjualanApi({
      'id': 1,
      'tanggal': '2026-11-01 00:00:00',
      'pembeli': 'X',
      'produk': 'Pupa',
      'jumlah': 1,
      'harga': 1000,
      'lunas': true,
      'pembeli_id': 4,
      'tanggal_lunas': '2026-11-02 10:00:00',
    });
    expect(api.pembeliId, 4);
    expect(api.tanggalLunas, DateTime(2026, 11, 2, 10));
  });
}
