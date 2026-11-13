import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/data/app_state.dart';

void main() {
  test('data contoh punya relasi valid dan tanggal relatif', () {
    final repo = LocalRepository(demo: true);
    expect(repo.kandang.length, 3);
    expect(repo.budidaya.length, 3);
    expect(repo.pakan, isNotEmpty);
    expect(repo.panen, isNotEmpty);
    for (final group in repo.budidaya) {
      expect(repo.kandang.any((k) => k.id == group.kandangId), isTrue);
    }
    for (final record in [...repo.pakan, ...repo.panen]) {
      expect(repo.budidaya.any((b) => b.id == record.budidayaId), isTrue);
      expect(record.berat, greaterThan(0));
    }
    expect(
      repo.pakan.any((e) => DateUtils.isSameDay(e.tanggal, DateTime.now())),
      isTrue,
    );
  });

  test('tambah/edit kandang dan budidaya menjaga relasi dan ID', () {
    final s = AppState();
    s.saveKandang(null, 'Kandang uji', 'Kebun', 25, '');
    final k = s.kandang.single;
    s.saveBudidaya(null, 'Batch uji', k.id, DateTime.now(), 2, null, '');
    final b = s.budidaya.single;
    expect(s.kandangById(b.kandangId), same(k));
    s.saveKandang(k, 'Kandang baru', 'Kebun', 30, '');
    s.saveBudidaya(b, 'Batch baru', k.id, b.mulai, 3, null, '');
    expect(s.kandang.length, 1);
    expect(s.budidaya.length, 1);
    expect(s.kandangById(b.kandangId)?.nama, 'Kandang baru');
    expect(s.budidayaById(b.id)?.nama, 'Batch baru');
  });

  test('pakan/panen tambah edit hapus mengubah total dan grafik harian', () {
    final s = AppState();
    s.saveKandang(null, 'A', 'Kebun', null, '');
    s.saveBudidaya(
      null,
      'B',
      s.kandang.single.id,
      DateTime.now(),
      null,
      null,
      '',
    );
    final id = s.budidaya.single.id;
    final today = DateTime.now();
    s.saveCatatan(true, null, id, today, 1.5, '', 'Sisa sayur');
    s.saveCatatan(true, null, id, today, 2.25, '', 'Ampas tahu');
    s.saveCatatan(false, null, id, today, 0.75, '', '');
    expect(s.total(s.pakan), 3.75);
    expect(s.daily(s.pakan).last, 3.75);
    expect(s.pakanPerJenis().length, 2);
    expect(s.total(s.panen), 0.75);
    s.saveCatatan(true, s.pakan.first, id, today, 2.5, '', 'Sisa sayur');
    expect(s.total(s.pakan), 4.75);
    expect(s.daily(s.pakan).last, 4.75);
    s.deleteCatatan(true, s.pakan.last);
    expect(s.total(s.pakan), 2.5);
    expect(s.pakanPerJenis().single.key, 'Sisa sayur');
    expect(s.total(s.panen), 0.75);
  });

  test('panen tidak otomatis menyelesaikan budidaya', () {
    final s = AppState();
    s.saveKandang(null, 'A', 'Kebun', null, '');
    s.saveBudidaya(
      null,
      'B',
      s.kandang.single.id,
      DateTime.now(),
      null,
      null,
      '',
    );
    final b = s.budidaya.single;
    s.saveCatatan(false, null, b.id, DateTime.now(), 1, '', '');
    expect(b.selesai, isFalse);
    s.finish(b);
    expect(b.selesai, isTrue);
    expect(s.panen.single.budidayaId, b.id);
  });
}
