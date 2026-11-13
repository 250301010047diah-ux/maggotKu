import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/widgets/charts.dart';

void main() {
  final now = DateTime(2026, 11, 12, 15, 30);

  test('daysBack: 30 kelompok harian, terakhir hari ini', () {
    final b = daysBack(30, now);
    expect(b.length, 30);
    expect(b.last.start, DateTime(2026, 11, 12));
    expect(b.last.label, 'Hari ini');
    expect(b.first.start, DateTime(2026, 10, 14));
  });

  test('weeksBack: 13 minggu berurutan tanpa celah', () {
    final b = weeksBack(13, now);
    expect(b.length, 13);
    expect(b.last.end, DateTime(2026, 11, 13));
    for (var i = 1; i < b.length; i++) {
      expect(b[i].start, b[i - 1].end);
    }
  });

  test('monthsBack: 12 bulan, melewati pergantian tahun', () {
    final b = monthsBack(12, now);
    expect(b.first.start, DateTime(2025, 12, 1));
    expect(b.last.start, DateTime(2026, 11, 1));
    expect(b.last.label, 'Nov');
  });

  test('thisMonth & thisYear', () {
    expect(thisMonth(now).length, 12);
    expect(thisYear(now).length, 11);
  });

  test('sumBuckets menjumlahkan ke kelompok yang benar', () {
    final b = monthsBack(3, now); // Sep, Okt, Nov
    final data = [
      (DateTime(2026, 9, 30, 23), 1.0),
      (DateTime(2026, 10, 1), 2.0),
      (DateTime(2026, 11, 12, 10), 3.0),
      (DateTime(2026, 8, 31), 99.0), // di luar rentang
    ];
    final out = sumBuckets(data, (e) => e.$1, (e) => e.$2, b);
    expect(out, [1.0, 2.0, 3.0]);
  });
}
