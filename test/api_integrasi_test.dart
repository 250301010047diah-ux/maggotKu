import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maggotku/data/api.dart';
import 'package:maggotku/data/app_state.dart';
import 'package:maggotku/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Server tiruan yang meniru perilaku API MaggotKu (server/app.js):
/// token Bearer, data per user, aturan stok, olah, tebar & upload foto.
class FakeServer {
  final users = <Map<String, dynamic>>[
    {
      'id': 1,
      'name': 'Peternak Uji',
      'email': 'uji@contoh.com',
      'password': 'rahasia123',
      'farm_name': 'Kebun Uji',
    },
  ];
  final t = <String, List<Map<String, dynamic>>>{
    'kandang': [],
    'budidaya': [],
    'pakan': [],
    'panen': [],
    'penjualan': [],
    'mutasi': [],
    'foto': [],
    'mutasi-pakan': [],
  };
  final log = <String>[];
  int _id = 100;
  bool tokenKedaluwarsa = false;

  late final http.Client client = MockClient(_handle);

  static const produk = [
    'Maggot segar',
    'Maggot kering',
    'Pupa',
    'Telur',
    'Kasgot (pupuk)',
  ];

  Map<String, double> stok(int uid) {
    final m = {for (final p in produk) p: 0.0};
    for (final r in t['panen']!.where((r) => r['user_id'] == uid)) {
      m[r['produk']] = m[r['produk']]! + (r['jumlah'] as num);
    }
    for (final r in t['mutasi']!.where((r) => r['user_id'] == uid)) {
      m[r['produk']] = m[r['produk']]! + (r['jumlah'] as num);
    }
    for (final r in t['penjualan']!.where((r) => r['user_id'] == uid)) {
      m[r['produk']] = m[r['produk']]! - (r['jumlah'] as num);
    }
    return m;
  }

  http.Response _json(int status, Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Map<String, dynamic> _out(Map<String, dynamic> r) =>
      Map.of(r)..remove('user_id');

  Map<String, dynamic> _user(Map<String, dynamic> u) => {
    'id': u['id'],
    'name': u['name'],
    'email': u['email'],
    'farm_name': u['farm_name'],
  };

  Map<String, dynamic> tambah(String tabel, int uid, Map<String, dynamic> d) {
    final row = {'id': _id++, 'user_id': uid, ...d};
    t[tabel]!.add(row);
    return row;
  }

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api-maggot', '');
    log.add('${req.method} $path');
    final isJson = (req.headers['content-type'] ?? '').contains('json');
    final body = isJson && req.body.isNotEmpty
        ? jsonDecode(req.body) as Map<String, dynamic>
        : <String, dynamic>{};

    // ---------- auth ----------
    if (path == '/auth/login') {
      final u = users.where((u) => u['email'] == body['email']).firstOrNull;
      if (u == null || u['password'] != body['password']) {
        return _json(400, {'error': 'Email atau password salah'});
      }
      return _json(200, {'token': 'tok-${u['id']}', 'user': _user(u)});
    }
    if (path == '/auth/register') {
      if (users.any((u) => u['email'] == body['email'])) {
        return _json(400, {'error': 'Email sudah terdaftar'});
      }
      final u = {
        'id': users.length + 1,
        'name': body['name'],
        'email': body['email'],
        'password': body['password'],
        'farm_name': body['farm_name'] ?? '',
      };
      users.add(u);
      return _json(201, {'token': 'tok-${u['id']}', 'user': _user(u)});
    }

    final auth = req.headers['authorization'] ?? '';
    if (!auth.startsWith('Bearer tok-') || tokenKedaluwarsa) {
      return _json(401, {'error': 'Sesi berakhir, silakan login lagi'});
    }
    final uid = int.parse(auth.substring('Bearer tok-'.length));
    final me = users.firstWhere((u) => u['id'] == uid);

    if (path == '/me') {
      if (req.method == 'PUT') {
        if (body.containsKey('password') &&
            body['current_password'] != me['password']) {
          return _json(400, {'error': 'Password lama salah'});
        }
        if (body['password'] != null) me['password'] = body['password'];
        for (final k in ['name', 'email', 'farm_name']) {
          if (body[k] != null) me[k] = body[k];
        }
      }
      return _json(200, {'data': _user(me)});
    }

    // ---------- olah ----------
    if (path == '/olah') {
      final fresh = (body['fresh'] as num).toDouble();
      if (stok(uid)['Maggot segar']! < fresh) {
        return _json(400, {
          'error':
              'Stok Maggot segar tidak cukup (tersisa '
              '${stok(uid)['Maggot segar']} kg)',
        });
      }
      tambah('mutasi', uid, {
        'tanggal': body['tanggal'],
        'produk': 'Maggot segar',
        'jumlah': -fresh,
        'jenis': 'olah',
        'keterangan': 'Olah',
      });
      tambah('mutasi', uid, {
        'tanggal': body['tanggal'],
        'produk': 'Maggot kering',
        'jumlah': body['kering'],
        'jenis': 'olah',
        'keterangan': 'Olah',
      });
      return _json(201, {'message': 'ok', 'data': stok(uid)});
    }

    // ---------- foto (multipart) ----------
    if (path == '/foto' && req.method == 'POST') {
      final raw = latin1.decode(req.bodyBytes);
      final bid = RegExp(r'name="budidaya_id"\r\n\r\n(\d+)').firstMatch(raw);
      // Header multipart tidak peka huruf besar/kecil (seperti multer).
      if (!raw.toLowerCase().contains('content-type: image/jpeg') ||
          bid == null) {
        return _json(400, {'error': 'File foto wajib'});
      }
      final row = tambah('foto', uid, {
        'budidaya_id': int.parse(bid.group(1)!),
        'file': 'abc.jpg',
        'tanggal': '2026-11-12 10:00:00',
        'catatan': '',
      });
      return _json(201, {
        'data': {..._out(row), 'url': 'https://contoh/uploads/abc.jpg'},
      });
    }

    // ---------- CRUD ----------
    final seg = path.split('/').where((s) => s.isNotEmpty).toList();
    final tabel = seg.first;
    if (!t.containsKey(tabel)) return _json(404, {'error': 'Route'});
    final rows = t[tabel]!;
    final id = seg.length > 1 ? int.parse(seg[1]) : null;

    if (req.method == 'GET') {
      final mine = rows.where((r) => r['user_id'] == uid).map(_out);
      if (tabel == 'foto') {
        return _json(200, {
          'data': [
            for (final f in mine) {...f, 'url': 'https://contoh/${f['file']}'},
          ],
        });
      }
      return _json(200, {'data': mine.toList().reversed.toList()});
    }

    if (req.method == 'POST') {
      final sebelum = stok(uid);
      final d = Map<String, dynamic>.of(body)..remove('telur_gram');
      if (tabel == 'budidaya') d['selesai'] = false;
      if (tabel == 'penjualan') d['lunas'] ??= true;
      final row = tambah(tabel, uid, d);
      if (tabel == 'budidaya' && (body['telur_gram'] ?? 0) > 0) {
        tambah('mutasi', uid, {
          'tanggal': body['mulai'],
          'produk': 'Telur',
          'jumlah': -(body['telur_gram'] as num),
          'jenis': 'tebar',
          'keterangan': 'Ditebar ke ${body['nama']}',
        });
      }
      // Aturan stok: perubahan tidak boleh membuat stok minus.
      final sesudah = stok(uid);
      for (final p in produk) {
        if (sesudah[p]! < 0 && sesudah[p]! < sebelum[p]!) {
          rows.remove(row);
          t['mutasi']!.removeWhere(
            (m) =>
                m['jenis'] == 'tebar' &&
                m['keterangan'] == 'Ditebar ke ${body['nama']}',
          );
          return _json(400, {
            'error':
                'Stok $p tidak cukup (tersisa ${sebelum[p]} '
                '${p == 'Telur' ? 'g' : 'kg'})',
          });
        }
      }
      return _json(201, {'data': _out(row)});
    }

    final row = rows.where((r) => r['id'] == id && r['user_id'] == uid);
    if (row.isEmpty) return _json(404, {'error': 'Data tidak ditemukan'});
    if (req.method == 'PUT') {
      row.first.addAll(body);
      return _json(200, {'data': _out(row.first)});
    }
    if (req.method == 'DELETE') {
      rows.remove(row.first);
      return _json(200, {'message': 'Data dihapus'});
    }
    return _json(405, {'error': 'Method'});
  }
}

/// Isi server dengan data akun uji.
void isiData(FakeServer f) {
  final k = f.tambah('kandang', 1, {
    'nama': 'Kandang Server',
    'lokasi': 'Belakang',
    'kapasitas': 50,
    'catatan': null,
  });
  final b = f.tambah('budidaya', 1, {
    'kandang_id': k['id'],
    'nama': 'Batch Server',
    'tujuan': 'perkawinan',
    'mulai': '2026-11-01 00:00:00',
    'berat_awal': 2.5,
    'perkiraan_panen': null,
    'catatan': '',
    'selesai': false,
  });
  f.tambah('panen', 1, {
    'budidaya_id': b['id'],
    'tanggal': '2026-11-10 08:00:00',
    'produk': 'Maggot segar',
    'jumlah': 5,
    'catatan': '',
  });
  f.tambah('mutasi', 1, {
    'tanggal': '2026-11-10 08:00:00',
    'produk': 'Telur',
    'jumlah': 50,
    'jenis': 'penyesuaian',
    'keterangan': 'Stok awal',
  });
  f.tambah('penjualan', 1, {
    'tanggal': '2026-11-11 09:00:00',
    'pembeli': 'Pak Budi',
    'produk': 'Maggot segar',
    'jumlah': 2,
    'harga': 8000,
    'lunas': false,
    'catatan': '',
  });
}

Future<void> settle(WidgetTester t, [int steps = 15]) async {
  for (var i = 0; i < steps; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeServer server;
  late AppState s;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = FakeServer();
    isiData(server);
    s = AppState(await SharedPreferences.getInstance(), server.client);
  });

  test('login → data server termuat & stok dihitung sama', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    expect(s.online, isTrue);
    expect(s.loggedIn, isTrue);
    expect(s.nama, 'Peternak Uji');
    expect(s.farmName, 'Kebun Uji');
    expect(s.kandang.single.nama, 'Kandang Server');
    expect(s.budidaya.single.tujuan, 'perkawinan');
    expect(s.budidaya.single.beratAwal, 2.5);
    expect(s.panen.single.jenis, 'Maggot segar');
    expect(s.penjualan.single.lunas, isFalse);
    expect(s.stok('Maggot segar'), server.stok(1)['Maggot segar']);
    expect(s.stok('Maggot segar'), 3);
    expect(s.stok('Telur'), 50);
  });

  test('login salah menampilkan pesan dari server', () async {
    await expectLater(
      s.login('uji@contoh.com', 'salah'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'pesan',
          'Email atau password salah',
        ),
      ),
    );
    expect(s.online, isFalse);
  });

  test('simpan kandang, budidaya, pakan & panen terkirim ke server', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    await s.saveKandang(null, 'Kandang Baru', 'Samping', null, '');
    final k = s.kandang.last;
    expect(k.id, greaterThanOrEqualTo(100));
    expect(server.t['kandang']!.last['nama'], 'Kandang Baru');

    await s.saveBudidaya(
      null,
      'Batch Baru',
      k.id,
      DateTime(2026, 11, 12),
      null,
      null,
      '',
      tujuan: 'kering',
    );
    final b = s.budidaya.last;
    expect(server.t['budidaya']!.last['tujuan'], 'kering');
    expect(server.t['budidaya']!.last['mulai'], '2026-11-12T00:00:00');

    await s.saveCatatan(
      true,
      null,
      b.id,
      DateTime(2026, 11, 12),
      2,
      '',
      'Ampas tahu',
    );
    expect(server.t['pakan']!.last['jenis'], 'Ampas tahu');

    await s.saveCatatan(
      false,
      null,
      b.id,
      DateTime(2026, 11, 12),
      4,
      '',
      'Kasgot (pupuk)',
    );
    expect(server.t['panen']!.last['produk'], 'Kasgot (pupuk)');
    expect(server.t['panen']!.last['jumlah'], 4);
    expect(s.stok('Kasgot (pupuk)'), 4);

    // Edit memakai PUT ke id yang sama.
    await s.saveKandang(k, 'Kandang Diubah', 'Samping', 30, '');
    expect(server.log, contains('PUT /kandang/${k.id}'));
    expect(k.nama, 'Kandang Diubah');
  });

  test(
    'penjualan melebihi stok ditolak server, data lokal tidak berubah',
    () async {
      await s.login('uji@contoh.com', 'rahasia123');
      final jumlahAwal = s.penjualan.length;
      await expectLater(
        s.savePenjualan(
          null,
          tanggal: DateTime(2026, 11, 12),
          pembeli: 'Bu Sari',
          produk: 'Maggot segar',
          berat: 10,
          harga: 8000,
          lunas: true,
          catatan: '',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'pesan',
            contains('Stok'),
          ),
        ),
      );
      expect(s.penjualan.length, jumlahAwal);
      expect(s.stok('Maggot segar'), 3);
    },
  );

  test('olah & tebar telur memperbarui stok dari server', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    await s.olah(3, 1, DateTime(2026, 11, 12));
    expect(s.stok('Maggot segar'), 0);
    expect(s.stok('Maggot kering'), 1);

    await s.saveBudidaya(
      null,
      'Indukan B',
      s.kandang.first.id,
      DateTime(2026, 11, 12),
      null,
      null,
      '',
      tujuan: 'perkawinan',
      telurGram: 20,
    );
    expect(s.stok('Telur'), 30);
  });

  test('upload & hapus foto', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    final f = File('${Directory.systemTemp.path}/maggot_uji.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
    final b = s.budidaya.first;
    await s.addFoto(b.id, f.path, DateTime(2026, 11, 12));
    final foto = s.fotoOf(b.id).single;
    expect(foto.path, startsWith('https://'));
    await s.deleteFoto(foto);
    expect(s.fotoOf(b.id), isEmpty);
    expect(server.log, contains('DELETE /foto/${foto.id}'));
  });

  test('pakan masuk terkirim ke server & stok pakan terhitung', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    await s.addMutasiPakan('Ampas tahu', 12, 'masuk', harga: 1500);
    final row = server.t['mutasi-pakan']!.single;
    expect(row['jenis'], 'Ampas tahu');
    expect(row['jumlah'], 12);
    expect(row['harga'], 1500);
    expect(row['tipe'], 'masuk');
    await s.saveCatatan(
      true,
      null,
      s.budidaya.first.id,
      DateTime.now(),
      5,
      '',
      'Ampas tahu',
    );
    expect(s.stokPakan('Ampas tahu'), 7);
    // Sinkron ulang dari server → hasilnya tetap sama.
    await s.syncAll();
    expect(s.stokPakan('Ampas tahu'), 7);
    expect(s.hargaPakanRata(), 1500);
  });

  test('ganti password: password lama salah ditolak', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    await expectLater(
      s.changePassword('keliru', 'baru123'),
      throwsA(isA<ApiException>()),
    );
    await s.changePassword('rahasia123', 'baru123');
    expect(server.users.first['password'], 'baru123');
  });

  test('sesi habis (401) → keluar otomatis', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    var dipanggil = false;
    s.onSessionExpired = () => dipanggil = true;
    server.tokenKedaluwarsa = true;
    await expectLater(
      s.saveKandang(null, 'X', 'Y', null, ''),
      throwsA(isA<ApiException>()),
    );
    expect(dipanggil, isTrue);
    expect(s.online, isFalse);
    expect(s.loggedIn, isFalse);
  });

  test('keluar akun menghapus data akun dari HP', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    expect(s.kandang, isNotEmpty);
    await s.logout();
    expect(s.online, isFalse);
    expect(s.loggedIn, isFalse);
    expect(s.kandang, isEmpty);
    expect(s.penjualan, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('maggotku_token'), isNull);
    // Buka ulang aplikasi → kembali ke Login.
    expect((await AppState.load()).loggedIn, isFalse);
  });

  test('bekas mode demo (tanpa token) diarahkan ke Login', () async {
    SharedPreferences.setMockInitialValues({
      'maggotku_data_v1': '{"loggedIn": true, "kandang": []}',
    });
    final buka = await AppState.load();
    expect(buka.loggedIn, isFalse);
    expect(buka.online, isFalse);
  });

  test('token tersimpan: buka ulang aplikasi tetap login', () async {
    await s.login('uji@contoh.com', 'rahasia123');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('maggotku_token'), 'tok-1');
    final buka = await AppState.load();
    expect(buka.online, isTrue);
    expect(buka.loggedIn, isTrue);
    expect(buka.kandang.single.nama, 'Kandang Server');
  });

  testWidgets('UI: login dari layar Login lalu masuk Beranda', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = AppState(null, server.client);
    await tester.pumpWidget(MaggotKuApp(state: app));
    await tester.tap(find.text('Lewati'));
    await settle(tester);

    // Password salah → maggot ngambek & pesan server tampil.
    await tester.enterText(find.byType(TextFormField).at(0), 'uji@contoh.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'salah');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await settle(tester);
    expect(find.text('Email atau password salah'), findsOneWidget);
    expect(app.loggedIn, isFalse);

    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.text('Masuk'));
    await settle(tester, 25);
    expect(app.online, isTrue);
    expect(find.textContaining('Halo, Peternak Uji'), findsOneWidget);
  });
}
