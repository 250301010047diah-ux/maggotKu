import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/data/app_state.dart';
import 'package:maggotku/data/models.dart';

AppState _base() {
  final s = AppState();
  s.saveKandang(null, 'Kandang A', 'Belakang', 50, '');
  return s;
}

void main() {
  test('stok = panen + mutasi − penjualan, per produk', () {
    final s = _base();
    s.saveBudidaya(null, 'B1', 1, DateTime(2026, 11, 1), null, null, '');
    s.saveCatatan(
      false,
      null,
      1,
      DateTime(2026, 11, 10),
      5,
      '',
      'Maggot segar',
    );
    s.saveCatatan(
      false,
      null,
      1,
      DateTime(2026, 11, 10),
      12,
      '',
      'Kasgot (pupuk)',
    );
    s.saveCatatan(
      false,
      null,
      1,
      DateTime(2026, 11, 10),
      2,
      '',
      '',
    ); // lama → segar
    expect(s.stok('Maggot segar'), 7);
    expect(s.stok('Kasgot (pupuk)'), 12);

    s.savePenjualan(
      null,
      tanggal: DateTime(2026, 11, 11),
      pembeli: 'Pak Budi',
      produk: 'Maggot segar',
      berat: 3,
      harga: 8000,
      lunas: true,
      catatan: '',
    );
    expect(s.stok('Maggot segar'), 4);

    s.addMutasi('Kasgot (pupuk)', -2, 'penyesuaian', 'Rusak');
    expect(s.stok('Kasgot (pupuk)'), 10);
  });

  test('olah: fresh berkurang, kering bertambah', () {
    final s = _base();
    s.addMutasi('Maggot segar', 6, 'penyesuaian', 'Stok awal');
    s.olah(3, 1, DateTime(2026, 11, 12));
    expect(s.stok('Maggot segar'), 3);
    expect(s.stok('Maggot kering'), 1);
  });

  test('telur ditebar ke batch baru mengurangi stok telur (gram)', () {
    final s = _base();
    s.addMutasi('Telur', 50, 'penyesuaian', 'Stok awal');
    s.saveBudidaya(
      null,
      'Batch Telur',
      1,
      DateTime(2026, 11, 12),
      null,
      null,
      '',
      telurGram: 20,
    );
    expect(s.stok('Telur'), 30);
    expect(qty('Telur', 30), '30 g');
  });

  test('telur tidak ikut dijumlah sebagai kg', () {
    final s = _base();
    s.saveBudidaya(null, 'B1', 1, DateTime(2026, 11, 1), null, null, '');
    s.saveCatatan(
      false,
      null,
      1,
      DateTime(2026, 11, 10),
      2,
      '',
      'Maggot segar',
    );
    s.saveCatatan(false, null, 1, DateTime(2026, 11, 10), 40, '', 'Telur');
    expect(s.total(s.panen), 2);
  });

  test('estimasi panen mengikuti tujuan siklus', () {
    final mulai = DateTime(2026, 11, 1);
    Budidaya b(String t) =>
        Budidaya(1, 'x', 1, mulai, null, null, '', false, tujuan: t);
    expect(b('fresh').estimasiPanen, DateTime(2026, 11, 17));
    expect(b('kering').estimasiPanen, DateTime(2026, 11, 19));
    expect(b('perkawinan').estimasiPanen, DateTime(2026, 12, 11));
  });

  test('batch perkawinan berhenti butuh pakan setelah jadi pupa', () {
    final now = DateTime.now();
    final larva = Budidaya(
      1,
      'A',
      1,
      now.subtract(const Duration(days: 5)),
      null,
      null,
      '',
      false,
      tujuan: 'perkawinan',
    );
    final pupa = Budidaya(
      2,
      'B',
      1,
      now.subtract(const Duration(days: 27)),
      null,
      null,
      '',
      false,
      tujuan: 'perkawinan',
    );
    expect(larva.butuhPakan, isTrue);
    expect(faseKawin[pupa.faseIndex].$1, 'Pupa');
    expect(pupa.butuhPakan, isFalse);
  });

  test('agenda: pakan hilang setelah dicatat, panen H-1 muncul', () {
    final s = _base();
    final today = DateUtils.dateOnly(DateTime.now());
    s.saveBudidaya(
      null,
      'B1',
      1,
      today.subtract(const Duration(days: 15)), // fresh: panen hari ke-16
      null,
      null,
      '',
    );
    var kinds = s.agenda().map((a) => a.kind).toList();
    expect(kinds, containsAll(['panen', 'pakan', 'foto']));
    expect(
      s.agenda().firstWhere((a) => a.kind == 'panen').title,
      contains('besok'),
    );

    s.saveCatatan(true, null, 1, DateTime.now(), 2, '', 'Sisa sayur');
    kinds = s.agenda().map((a) => a.kind).toList();
    expect(kinds, isNot(contains('pakan')));
  });

  test('absen foto: minggu lewat tanpa foto = bolong', () {
    final s = _base();
    final today = DateUtils.dateOnly(DateTime.now());
    s.saveBudidaya(
      null,
      'B1',
      1,
      today.subtract(const Duration(days: 15)), // minggu ke-3 berjalan
      null,
      null,
      '',
    );
    s.addFoto(1, '/x/1.jpg', today.subtract(const Duration(days: 13)));
    final m = s.mingguFoto(s.budidaya.first);
    expect(m, [true, false, null]);
  });
}
