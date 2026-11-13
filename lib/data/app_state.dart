import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'models.dart';

abstract class MaggotRepository {
  List<Kandang> get kandang;
  List<Budidaya> get budidaya;
  List<Catatan> get pakan;
  List<Catatan> get panen;
  List<Penjualan> get penjualan;
  List<Foto> get foto;
  List<Mutasi> get mutasi;
  List<MutasiPakan> get mutasiPakan;
}

class LocalRepository implements MaggotRepository {
  /// [demo] = true mengisi data contoh; default kosong.
  LocalRepository({bool demo = false}) {
    if (!demo) return;
    final now = DateTime.now();
    kandang.addAll([
      Kandang(1, 'Kandang A', 'Halaman belakang', 50, ''),
      Kandang(2, 'Kandang B', 'Samping rumah', 40, ''),
      Kandang(3, 'Kandang C', 'Kebun utama', null, ''),
    ]);
    budidaya.addAll([
      Budidaya(
        1,
        'Budidaya 01',
        1,
        now.subtract(const Duration(days: 12)),
        5,
        now.add(const Duration(days: 10)),
        '',
        false,
      ),
      Budidaya(
        2,
        'Budidaya 02',
        2,
        now.subtract(const Duration(days: 8)),
        4,
        null,
        '',
        false,
      ),
      Budidaya(
        3,
        'Budidaya 03',
        1,
        now.subtract(const Duration(days: 30)),
        6,
        null,
        '',
        true,
      ),
    ]);

    // Contoh pakan 7 hari terakhir supaya grafik terlihat hidup.
    const jenis = ['Sisa sayur', 'Ampas tahu', 'Kulit buah', 'Dedak'];
    const beratPakan = [1.8, 2.2, 1.5, 2.8, 2.0, 3.1, 2.5];
    var id = 1;
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      pakan.add(Catatan(id++, 1, d, beratPakan[6 - i], '', jenis[i % 4]));
      if (i.isEven) {
        pakan.add(Catatan(id++, 2, d, 1.2, '', jenis[(i + 1) % 4]));
      }
    }
    pakan.add(
      Catatan(
        id++,
        3,
        now.subtract(const Duration(days: 14)),
        3,
        '',
        'Sisa sayur',
      ),
    );
    panen.addAll([
      Catatan(1, 3, now.subtract(const Duration(days: 5)), 2.4, ''),
      Catatan(2, 3, now.subtract(const Duration(days: 3)), 4, ''),
      Catatan(3, 1, now.subtract(const Duration(days: 1)), 1.2, ''),
      Catatan(4, 1, now, 1.8, ''),
    ]);

    // Contoh penjualan 2 minggu terakhir.
    const pembeli = [
      'Pak Budi',
      'Bu Sari',
      'Toko Ikan Jaya',
      'Peternak Lele Asri',
      'Pak Darto',
    ];
    // (hari lalu, pembeli, produk, berat)
    const data = [
      (13, 0, 0, 5.0),
      (12, 2, 1, 1.5),
      (10, 1, 0, 3.0),
      (9, 3, 3, 20.0),
      (8, 0, 0, 4.0),
      (6, 2, 2, 2.0),
      (5, 4, 0, 6.0),
      (4, 3, 3, 25.0),
      (3, 1, 1, 1.0),
      (2, 2, 0, 7.5),
      (1, 0, 2, 3.0),
      (0, 3, 0, 5.0),
    ];
    for (final (i, d) in data.indexed) {
      final produk = const [
        'Maggot segar',
        'Maggot kering',
        'Pupa',
        'Kasgot (pupuk)',
      ][d.$3];
      penjualan.add(
        Penjualan(
          i + 1,
          now.subtract(Duration(days: d.$1)),
          pembeli[d.$2],
          produk,
          d.$4,
          hargaDefault[produk]!,
          lunas: d.$1 != 0 && d.$1 != 3,
        ),
      );
    }
  }
  @override
  final List<Kandang> kandang = [];
  @override
  final List<Budidaya> budidaya = [];
  @override
  final List<Catatan> pakan = [];
  @override
  final List<Catatan> panen = [];
  @override
  final List<Penjualan> penjualan = [];
  @override
  final List<Foto> foto = [];
  @override
  final List<Mutasi> mutasi = [];
  @override
  final List<MutasiPakan> mutasiPakan = [];
}

/// Satu tugas di agenda hari ini.
class AgendaItem {
  const AgendaItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.budidaya,
    this.urgent = false,
  });

  /// 'pakan' | 'panen' | 'fase' | 'foto' | 'stokpakan' | 'segar'
  final String kind;
  final String title, subtitle;

  /// null untuk tugas gudang pakan (tidak terikat batch).
  final Budidaya? budidaya;
  final bool urgent;
}

class AppState extends ChangeNotifier {
  AppState([this._prefs, this._client]);

  /// Penyimpanan lokal tanpa server (hanya dipakai test otomatis).
  static const _demoKey = 'maggotku_data_v1';

  /// Salinan data akun online (supaya tetap tampil saat sinyal putus).
  static const _onlineKey = 'maggotku_online_v1';
  static const _tokenKey = 'maggotku_token';

  /// Tempat penyimpanan di HP. null = tidak disimpan (dipakai di test).
  final SharedPreferences? _prefs;

  /// Klien HTTP (bisa diganti server tiruan saat test).
  final http.Client? _client;

  /// Muat data tersimpan dari HP.
  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(prefs);
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      state.api = Api(token);
      state._restore(prefs.getString(_onlineKey));
    } else {
      // Tanpa token (belum login / bekas mode demo yang sudah dihapus):
      // data lama tetap dibaca, tapi status login hanya sah dengan token.
      state._restore(prefs.getString(_demoKey));
    }
    return state;
  }

  final MaggotRepository repository = LocalRepository();
  String nama = 'Yume';
  String email = 'yume@contoh.com';
  String farmName = '';

  /// Terhubung ke API (login akun). null = belum login.
  Api? api;
  bool get online => api != null;

  /// Dipanggil bila sesi login habis (token kedaluwarsa).
  VoidCallback? onSessionExpired;

  // =================== Akun & sinkronisasi ===================
  Api _newApi([String? token]) => Api(token, client: _client);

  void _applyUser(Map<String, dynamic> u) {
    nama = u['name'] as String? ?? nama;
    email = u['email'] as String? ?? email;
    farmName = u['farm_name'] as String? ?? '';
  }

  void _clearData() {
    for (final l in <List<dynamic>>[
      kandang,
      budidaya,
      pakan,
      panen,
      penjualan,
      foto,
      mutasi,
      mutasiPakan,
    ]) {
      l.clear();
    }
  }

  /// Masuk dengan akun sungguhan.
  Future<void> login(String email, String password) async {
    final j = await _newApi().post('/auth/login', {
      'email': email,
      'password': password,
    });
    await _mulaiSesi(j as Map<String, dynamic>);
  }

  /// Daftar akun baru, langsung masuk.
  Future<void> register(
    String nama,
    String email,
    String password,
    String farm,
  ) async {
    final j = await _newApi().post('/auth/register', {
      'name': nama,
      'email': email,
      'password': password,
      'farm_name': farm,
    });
    await _mulaiSesi(j as Map<String, dynamic>);
  }

  Future<void> _mulaiSesi(Map<String, dynamic> j) async {
    api = _newApi(j['token'] as String);
    await _prefs?.setString(_tokenKey, api!.token!);
    _clearData();
    _applyUser(j['user'] as Map<String, dynamic>);
    _loggedIn = true;
    agendaShownOn = '';
    notifyListeners();
    try {
      await syncAll();
    } catch (_) {
      // Data akan dicoba diambil lagi saat Beranda dibuka.
    }
  }

  /// Keluar. Salinan data akun dihapus dari HP.
  Future<void> logout() async {
    // Status diubah seketika (sinkron) supaya tidak ada jeda di mana
    // aplikasi masih menganggap pengguna login.
    final wasOnline = online;
    if (wasOnline) {
      api = null;
      _clearData();
      nama = 'Yume';
      email = 'yume@contoh.com';
      farmName = '';
    }
    _loggedIn = false;
    notifyListeners();
    if (wasOnline) {
      await _prefs?.remove(_tokenKey);
      await _prefs?.remove(_onlineKey);
    }
  }

  /// Ambil semua data akun dari server.
  Future<void> syncAll() async {
    final a = api;
    if (a == null) return;
    try {
      final r = await Future.wait([
        a.get('/me'),
        a.get('/kandang'),
        a.get('/budidaya'),
        a.get('/pakan'),
        a.get('/panen'),
        a.get('/penjualan'),
        a.get('/mutasi'),
        a.get('/foto'),
        a.get('/mutasi-pakan'),
      ]);
      List<T> rows<T>(int i, T Function(Map<String, dynamic>) f) => [
        for (final e in (r[i]['data'] as List)) f(e as Map<String, dynamic>),
      ];
      _applyUser(r[0]['data'] as Map<String, dynamic>);
      final k = rows(1, kandangApi), b = rows(2, budidayaApi);
      final pk = rows(3, pakanApi), pn = rows(4, panenApi);
      final pj = rows(5, penjualanApi), m = rows(6, mutasiApi);
      final f = rows(7, fotoApi), mp = rows(8, mutasiPakanApi);
      _clearData();
      kandang.addAll(k.reversed);
      budidaya.addAll(b.reversed);
      pakan.addAll(pk.reversed);
      panen.addAll(pn.reversed);
      penjualan.addAll(pj.reversed);
      mutasi.addAll(m.reversed);
      foto.addAll(f);
      mutasiPakan.addAll(mp.reversed);
      notifyListeners();
    } on ApiException catch (e) {
      _cek401(e);
      rethrow;
    }
  }

  void _cek401(ApiException e) {
    if (e.status == 401 && online) {
      logout();
      onSessionExpired?.call();
    }
  }

  /// Jalankan permintaan ke API; sesi habis → keluar otomatis.
  Future<T> _remote<T>(Future<T> Function(Api a) f) async {
    try {
      return await f(api!);
    } on ApiException catch (e) {
      _cek401(e);
      rethrow;
    }
  }

  Map<String, dynamic> _data(dynamic j) =>
      (j as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  bool _loggedIn = false, _onboardingDone = false;
  bool get loggedIn => _loggedIn;
  set loggedIn(bool v) {
    _loggedIn = v;
    _persist();
  }

  bool get onboardingDone => _onboardingDone;
  set onboardingDone(bool v) {
    _onboardingDone = v;
    _persist();
  }

  List<Foto> get foto => repository.foto;
  List<Mutasi> get mutasi => repository.mutasi;
  List<MutasiPakan> get mutasiPakan => repository.mutasiPakan;

  // =================== Stok pakan (gudang bersama) ===================
  /// Stok pakan (kg) = pakan masuk ± penyesuaian − pakan diberikan.
  double stokPakan(String jenis) {
    var v = 0.0;
    for (final m in mutasiPakan) {
      if (m.jenis == jenis) v += m.jumlah;
    }
    for (final p in pakan) {
      if (jenisPakanOf(p.jenis) == jenis) v -= p.berat;
    }
    return (v * 1000).roundToDouble() / 1000;
  }

  /// Rata-rata pemakaian per hari selama [hari] hari terakhir (kg/hari).
  double pemakaianHarian(String jenis, {int hari = 7, DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final dari = today.subtract(Duration(days: hari - 1));
    var total = 0.0;
    for (final p in pakan) {
      if (jenisPakanOf(p.jenis) == jenis &&
          !DateUtils.dateOnly(p.tanggal).isBefore(dari)) {
        total += p.berat;
      }
    }
    return total / hari;
  }

  /// Perkiraan stok cukup untuk berapa hari lagi (null = belum dipakai).
  double? sisaHariPakan(String jenis, {DateTime? now}) {
    final rata = pemakaianHarian(jenis, now: now);
    if (rata <= 0) return null;
    final stok = stokPakan(jenis);
    return stok <= 0 ? 0 : stok / rata;
  }

  /// Kiriman pakan yang belum habis dan sudah melewati batas segar,
  /// dihitung FIFO (yang masuk duluan dipakai duluan).
  List<({String jenis, double sisa, DateTime masuk, int umur})>
  pakanLewatSegar([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final out = <({String jenis, double sisa, DateTime masuk, int umur})>[];
    for (final jenis in jenisPakanList) {
      // Total yang sudah berkurang: dipakai + penyesuaian minus.
      var terpakai = 0.0;
      for (final p in pakan) {
        if (jenisPakanOf(p.jenis) == jenis) terpakai += p.berat;
      }
      for (final m in mutasiPakan) {
        if (m.jenis == jenis && m.jumlah < 0) terpakai += -m.jumlah;
      }
      final masuk =
          mutasiPakan.where((m) => m.jenis == jenis && m.jumlah > 0).toList()
            ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
      for (final m in masuk) {
        final pakai = terpakai >= m.jumlah ? m.jumlah : terpakai;
        terpakai -= pakai;
        final sisa = m.jumlah - pakai;
        if (sisa <= 0.0005) continue;
        final umur = today.difference(DateUtils.dateOnly(m.tanggal)).inDays;
        if (umur >= (batasSegarPakan[jenis] ?? 7)) {
          out.add((jenis: jenis, sisa: sisa, masuk: m.tanggal, umur: umur));
        }
      }
    }
    return out;
  }

  /// Belanja pakan (Rp) dalam rentang tanggal [dari, sampai).
  double biayaPakan(DateTime dari, DateTime sampai) => mutasiPakan
      .where((m) => !m.tanggal.isBefore(dari) && m.tanggal.isBefore(sampai))
      .fold(0, (s, m) => s + m.biaya);

  /// Harga rata-rata pakan per kg dari pembelian 90 hari terakhir
  /// (null = belum ada pembelian berharga).
  double? hargaPakanRata([DateTime? now]) {
    final dari = (now ?? DateTime.now()).subtract(const Duration(days: 90));
    var kg = 0.0, rp = 0.0;
    for (final m in mutasiPakan) {
      if (m.harga != null && m.jumlah > 0 && m.tanggal.isAfter(dari)) {
        kg += m.jumlah;
        rp += m.biaya;
      }
    }
    return kg == 0 ? null : rp / kg;
  }

  Future<void> addMutasiPakan(
    String jenis,
    double jumlah,
    String tipe, {
    double? harga,
    String keterangan = '',
    DateTime? tanggal,
  }) async {
    final t = tanggal ?? DateTime.now();
    if (online) {
      final j = await _remote(
        (a) => a.post('/mutasi-pakan', {
          'tanggal': apiDate(t),
          'jenis': jenis,
          'jumlah': jumlah,
          'tipe': tipe,
          'harga': harga,
          'keterangan': keterangan,
        }),
      );
      mutasiPakan.add(mutasiPakanApi(_data(j)));
      notifyListeners();
      return;
    }
    mutasiPakan.add(
      MutasiPakan(
        _next(mutasiPakan),
        t,
        jenis,
        jumlah,
        tipe,
        harga: harga,
        keterangan: keterangan,
      ),
    );
    notifyListeners();
  }

  Future<void> deleteMutasiPakan(MutasiPakan m) async {
    if (online) await _remote((a) => a.delete('/mutasi-pakan/${m.id}'));
    mutasiPakan.remove(m);
    notifyListeners();
  }

  /// Tugas gudang pakan untuk agenda: hampir habis & lewat segar.
  List<AgendaItem> _agendaGudang(DateTime today) {
    final out = <AgendaItem>[];
    for (final jenis in jenisPakanList) {
      final hari = sisaHariPakan(jenis, now: today);
      if (hari == null || hari > 2) continue;
      final stok = stokPakan(jenis);
      out.add(
        AgendaItem(
          kind: 'stokpakan',
          urgent: true,
          title: stok <= 0
              ? 'Stok $jenis habis'
              : '$jenis tinggal ${kg(stok)}, cukup ±${hari < 1 ? 'kurang dari 1' : hari.floor()} hari',
          subtitle:
              'Pemakaian rata-rata ${kg(pemakaianHarian(jenis, now: today))}/hari • catat pakan masuk',
        ),
      );
    }
    for (final s in pakanLewatSegar(today)) {
      out.add(
        AgendaItem(
          kind: 'segar',
          title: 'Cek kesegaran ${s.jenis}',
          subtitle:
              '${kg(s.sisa)} masuk ${s.umur} hari lalu belum habis • batas segar ${batasSegarPakan[s.jenis]} hari',
        ),
      );
    }
    return out;
  }

  /// Tanggal terakhir pop-up agenda ditampilkan (sekali sehari).
  String agendaShownOn = '';

  // =================== Stok ===================
  /// Produk sebuah catatan panen (catatan lama tanpa jenis = maggot segar).
  String produkOf(Catatan panenItem) =>
      panenItem.jenis.isEmpty ? 'Maggot segar' : panenItem.jenis;

  /// Stok saat ini = panen + mutasi − penjualan.
  double stok(String produk) {
    var v = 0.0;
    for (final c in panen) {
      if (produkOf(c) == produk) v += c.berat;
    }
    for (final m in mutasi) {
      if (m.produk == produk) v += m.jumlah;
    }
    for (final j in penjualan) {
      if (j.produk == produk) v -= j.berat;
    }
    return (v * 1000).roundToDouble() / 1000;
  }

  Future<void> addMutasi(
    String produk,
    double jumlah,
    String jenis,
    String ket, [
    DateTime? tanggal,
  ]) async {
    if (online) {
      final j = await _remote(
        (a) => a.post('/mutasi', {
          'tanggal': apiDate(tanggal ?? DateTime.now()),
          'produk': produk,
          'jumlah': jumlah,
          'jenis': jenis,
          'keterangan': ket,
        }),
      );
      mutasi.add(mutasiApi(_data(j)));
      notifyListeners();
      return;
    }
    mutasi.add(
      Mutasi(
        _next(mutasi),
        tanggal ?? DateTime.now(),
        produk,
        jumlah,
        jenis,
        ket,
      ),
    );
    notifyListeners();
  }

  /// Olah maggot fresh menjadi maggot kering.
  Future<void> olah(double fresh, double kering, DateTime tanggal) async {
    if (online) {
      await _remote(
        (a) => a.post('/olah', {
          'fresh': fresh,
          'kering': kering,
          'tanggal': apiDate(tanggal),
        }),
      );
      await _refreshMutasi();
      return;
    }
    final ket =
        'Olah ${qty('Maggot segar', fresh)} fresh → '
        '${qty('Maggot kering', kering)} kering';
    mutasi.add(
      Mutasi(_next(mutasi), tanggal, 'Maggot segar', -fresh, 'olah', ket),
    );
    mutasi.add(
      Mutasi(_next(mutasi), tanggal, 'Maggot kering', kering, 'olah', ket),
    );
    notifyListeners();
  }

  // =================== Agenda hari ini ===================
  List<AgendaItem> agenda([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final out = <AgendaItem>[];
    for (final b in budidaya.where((e) => !e.selesai)) {
      // Panen: H-3 sampai hari H, atau sudah lewat estimasi.
      final sisa = DateUtils.dateOnly(b.estimasiPanen).difference(today).inDays;
      if (sisa <= 3) {
        out.add(
          AgendaItem(
            kind: 'panen',
            budidaya: b,
            urgent: sisa <= 1,
            title: sisa > 1
                ? '${b.nama} panen $sisa hari lagi'
                : sisa == 1
                ? '${b.nama} panen besok'
                : sisa == 0
                ? '${b.nama} waktunya panen hari ini!'
                : '${b.nama} lewat ${-sisa} hari dari estimasi panen',
            subtitle:
                '${tujuanLabel[b.tujuan]} • estimasi ${tanggalPanjang(b.estimasiPanen)}',
          ),
        );
      }
      // Pergantian fase batch perkawinan (hari ini atau kemarin).
      if (b.tujuan == 'perkawinan') {
        for (final f in faseKawin.skip(1)) {
          final mulaiFase = DateTime(
            b.mulai.year,
            b.mulai.month,
            b.mulai.day + f.$2,
          );
          final d = today.difference(mulaiFase).inDays;
          if (d >= 0 && d <= 1) {
            out.add(
              AgendaItem(
                kind: 'fase',
                budidaya: b,
                title: '${b.nama} masuk fase ${f.$1} ${f.$3}',
                subtitle: _petunjukFase[f.$1] ?? '',
              ),
            );
          }
        }
      }
      // Pakan: lewati bila hari ini sudah dicatat.
      if (b.butuhPakan &&
          !pakan.any(
            (p) =>
                p.budidayaId == b.id && DateUtils.isSameDay(p.tanggal, today),
          )) {
        out.add(
          AgendaItem(
            kind: 'pakan',
            budidaya: b,
            title: 'Waktunya kasih makan ${b.nama}',
            subtitle: 'Belum ada catatan pakan hari ini',
          ),
        );
      }
      // Absen foto mingguan.
      final minggu = mingguFoto(b);
      final bolong = minggu.where((m) => m == false).length;
      if (minggu.isNotEmpty && minggu.last == null) {
        out.add(
          AgendaItem(
            kind: 'foto',
            budidaya: b,
            title: 'Absen foto ${b.nama} minggu ke-${minggu.length}',
            subtitle: bolong > 0
                ? 'Belum ada foto minggu ini • $bolong minggu bolong'
                : 'Belum ada foto minggu ini',
          ),
        );
      } else if (bolong > 0) {
        out.add(
          AgendaItem(
            kind: 'foto',
            budidaya: b,
            title: '${b.nama}: $bolong minggu tanpa foto',
            subtitle: 'Absen foto mingguan ada yang bolong',
          ),
        );
      }
    }
    out.addAll(_agendaGudang(today));
    const order = {
      'panen': 0,
      'stokpakan': 1,
      'segar': 2,
      'fase': 3,
      'pakan': 4,
      'foto': 5,
    };
    out.sort((a, b) => order[a.kind]!.compareTo(order[b.kind]!));
    return out;
  }

  static const _petunjukFase = {
    'Pupa':
        'Larva menghitam lalu diam & keras. Pindahkan ke wadah gelap & kering.',
    'Lalat & kawin': 'Lalat mulai keluar, pastikan kandang kawin siap.',
    'Bertelur': 'Pasang media bertelur (kayu/kardus berlubang).',
  };

  /// Status absen foto per minggu sejak mulai:
  /// true = ada foto, false = bolong (minggu sudah lewat),
  /// null = minggu berjalan & belum ada foto.
  List<bool?> mingguFoto(Budidaya b, [DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final start = DateUtils.dateOnly(b.mulai);
    final hari = today.difference(start).inDays;
    if (hari < 0) return const [];
    final weeks = hari ~/ 7 + 1;
    final fotos = fotoOf(b.id);
    return [
      for (var w = 0; w < weeks; w++)
        () {
          final ada = fotos.any((f) {
            final h = DateUtils.dateOnly(f.tanggal).difference(start).inDays;
            return h >= w * 7 && h < w * 7 + 7;
          });
          if (ada) return true;
          return w == weeks - 1 ? null : false;
        }(),
    ];
  }

  /// Setiap perubahan data otomatis disimpan.
  @override
  void notifyListeners() {
    super.notifyListeners();
    _persist();
  }

  void _persist() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(
      online ? _onlineKey : _demoKey,
      jsonEncode({
        'nama': nama,
        'email': email,
        'farmName': farmName,
        'loggedIn': _loggedIn,
        'onboardingDone': _onboardingDone,
        'kandang': [for (final e in kandang) e.toJson()],
        'budidaya': [for (final e in budidaya) e.toJson()],
        'pakan': [for (final e in pakan) e.toJson()],
        'panen': [for (final e in panen) e.toJson()],
        'penjualan': [for (final e in penjualan) e.toJson()],
        'foto': [for (final e in foto) e.toJson()],
        'mutasi': [for (final e in mutasi) e.toJson()],
        'mutasiPakan': [for (final e in mutasiPakan) e.toJson()],
        'agendaShownOn': agendaShownOn,
      }),
    );
  }

  void _restore(String? raw) {
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      List<T> list<T>(String k, T Function(Map<String, dynamic>) f) => [
        for (final e in (j[k] as List? ?? const []))
          f(e as Map<String, dynamic>),
      ];
      nama = j['nama'] as String? ?? nama;
      email = j['email'] as String? ?? email;
      farmName = j['farmName'] as String? ?? farmName;
      // Login hanya sah bila ada token akun (mode demo sudah dihapus).
      _loggedIn = online;
      _onboardingDone = j['onboardingDone'] as bool? ?? false;
      kandang
        ..clear()
        ..addAll(list('kandang', Kandang.fromJson));
      budidaya
        ..clear()
        ..addAll(list('budidaya', Budidaya.fromJson));
      pakan
        ..clear()
        ..addAll(list('pakan', Catatan.fromJson));
      panen
        ..clear()
        ..addAll(list('panen', Catatan.fromJson));
      penjualan
        ..clear()
        ..addAll(list('penjualan', Penjualan.fromJson));
      foto
        ..clear()
        ..addAll(list('foto', Foto.fromJson));
      mutasi
        ..clear()
        ..addAll(list('mutasi', Mutasi.fromJson));
      mutasiPakan
        ..clear()
        ..addAll(list('mutasiPakan', MutasiPakan.fromJson));
      agendaShownOn = j['agendaShownOn'] as String? ?? '';
    } catch (e) {
      debugPrint('Gagal memuat data tersimpan: $e');
    }
  }

  /// Foto milik satu budidaya, terbaru dulu.
  List<Foto> fotoOf(int budidayaId) =>
      foto.where((f) => f.budidayaId == budidayaId).toList()
        ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

  /// Simpan foto. Online: file di [path] di-upload ke server.
  Future<void> addFoto(int budidayaId, String path, DateTime tanggal) async {
    if (online) {
      final j = await _remote(
        (a) => a.upload('/foto', path, {
          'budidaya_id': '$budidayaId',
          'tanggal': apiDate(tanggal),
        }),
      );
      foto.add(fotoApi(_data(j)));
      notifyListeners();
      return;
    }
    foto.add(Foto(_next(foto), budidayaId, path, tanggal));
    notifyListeners();
  }

  Future<void> deleteFoto(Foto f) async {
    if (online) {
      await _remote((a) => a.delete('/foto/${f.id}'));
      foto.remove(f);
      notifyListeners();
      return;
    }
    foto.remove(f);
    try {
      final file = File(f.path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
    notifyListeners();
  }

  List<Kandang> get kandang => repository.kandang;
  List<Budidaya> get budidaya => repository.budidaya;
  List<Catatan> get pakan => repository.pakan;
  List<Catatan> get panen => repository.panen;
  List<Penjualan> get penjualan => repository.penjualan;
  int _next(List<dynamic> list) =>
      list.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
  Kandang? kandangById(int id) {
    for (final e in kandang) {
      if (e.id == id) return e;
    }
    return null;
  }

  Budidaya? budidayaById(int id) {
    for (final e in budidaya) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> _refreshMutasi() async {
    final j = await _remote((a) => a.get('/mutasi'));
    mutasi
      ..clear()
      ..addAll([
        for (final e in ((j as Map)['data'] as List).reversed)
          mutasiApi(e as Map<String, dynamic>),
      ]);
    notifyListeners();
  }

  Future<void> saveKandang(
    Kandang? old,
    String nama,
    String lokasi,
    double? kapasitas,
    String catatan,
  ) async {
    if (online) {
      final body = {
        'nama': nama,
        'lokasi': lokasi,
        'kapasitas': kapasitas,
        'catatan': catatan,
      };
      final j = await _remote(
        (a) => old == null
            ? a.post('/kandang', body)
            : a.put('/kandang/${old.id}', body),
      );
      final k = kandangApi(_data(j));
      if (old == null) {
        kandang.add(k);
      } else {
        old
          ..nama = k.nama
          ..lokasi = k.lokasi
          ..kapasitas = k.kapasitas
          ..catatan = k.catatan;
      }
      notifyListeners();
      return;
    }
    if (old == null) {
      kandang.add(Kandang(_next(kandang), nama, lokasi, kapasitas, catatan));
    } else {
      old.nama = nama;
      old.lokasi = lokasi;
      old.kapasitas = kapasitas;
      old.catatan = catatan;
    }
    notifyListeners();
  }

  void _salinBudidaya(Budidaya to, Budidaya from) => to
    ..nama = from.nama
    ..kandangId = from.kandangId
    ..mulai = from.mulai
    ..beratAwal = from.beratAwal
    ..perkiraanPanen = from.perkiraanPanen
    ..catatan = from.catatan
    ..selesai = from.selesai
    ..tujuan = from.tujuan;

  Future<void> saveBudidaya(
    Budidaya? old,
    String nama,
    int kandangId,
    DateTime mulai,
    double? berat,
    DateTime? perkiraan,
    String catatan, {
    String tujuan = 'fresh',
    double telurGram = 0,
  }) async {
    if (online) {
      final body = {
        'kandang_id': kandangId,
        'nama': nama,
        'tujuan': tujuan,
        'mulai': apiDate(mulai),
        'berat_awal': berat,
        'perkiraan_panen': perkiraan == null ? null : apiDate(perkiraan),
        'catatan': catatan,
        if (old == null && telurGram > 0) 'telur_gram': telurGram,
      };
      final j = await _remote(
        (a) => old == null
            ? a.post('/budidaya', body)
            : a.put('/budidaya/${old.id}', body),
      );
      final b = budidayaApi(_data(j));
      if (old == null) {
        budidaya.add(b);
      } else {
        _salinBudidaya(old, b);
      }
      notifyListeners();
      if (old == null && telurGram > 0) await _refreshMutasi();
      return;
    }
    if (old == null) {
      final b = Budidaya(
        _next(budidaya),
        nama,
        kandangId,
        mulai,
        berat,
        perkiraan,
        catatan,
        false,
        tujuan: tujuan,
      );
      budidaya.add(b);
      // Telur yang ditebar diambil dari stok.
      if (telurGram > 0) {
        mutasi.add(
          Mutasi(
            _next(mutasi),
            mulai,
            'Telur',
            -telurGram,
            'tebar',
            'Ditebar ke $nama',
          ),
        );
      }
    } else {
      old.nama = nama;
      old.kandangId = kandangId;
      old.mulai = mulai;
      old.beratAwal = berat;
      old.perkiraanPanen = perkiraan;
      old.catatan = catatan;
      old.tujuan = tujuan;
    }
    notifyListeners();
  }

  Future<void> saveCatatan(
    bool isPakan,
    Catatan? old,
    int budidayaId,
    DateTime date,
    double berat,
    String catatan,
    String jenis,
  ) async {
    final list = isPakan ? pakan : panen;
    if (online) {
      final path = isPakan ? '/pakan' : '/panen';
      final body = {
        'budidaya_id': budidayaId,
        'tanggal': apiDate(date),
        'catatan': catatan,
        if (isPakan) ...{'jenis': jenis, 'berat': berat},
        if (!isPakan) ...{
          'produk': jenis.isEmpty ? 'Maggot segar' : jenis,
          'jumlah': berat,
        },
      };
      final j = await _remote(
        (a) =>
            old == null ? a.post(path, body) : a.put('$path/${old.id}', body),
      );
      final c = isPakan ? pakanApi(_data(j)) : panenApi(_data(j));
      if (old == null) {
        list.add(c);
      } else {
        old
          ..budidayaId = c.budidayaId
          ..tanggal = c.tanggal
          ..berat = c.berat
          ..catatan = c.catatan
          ..jenis = c.jenis;
      }
      notifyListeners();
      return;
    }
    if (old == null) {
      list.add(Catatan(_next(list), budidayaId, date, berat, catatan, jenis));
    } else {
      old.budidayaId = budidayaId;
      old.tanggal = date;
      old.berat = berat;
      old.catatan = catatan;
      old.jenis = jenis;
    }
    notifyListeners();
  }

  Future<void> deleteCatatan(bool isPakan, Catatan item) async {
    if (online) {
      await _remote(
        (a) => a.delete('${isPakan ? '/pakan' : '/panen'}/${item.id}'),
      );
    }
    (isPakan ? pakan : panen).remove(item);
    notifyListeners();
  }

  Future<void> savePenjualan(
    Penjualan? old, {
    required DateTime tanggal,
    required String pembeli,
    required String produk,
    required double berat,
    required double harga,
    required bool lunas,
    required String catatan,
  }) async {
    if (online) {
      final body = {
        'tanggal': apiDate(tanggal),
        'pembeli': pembeli,
        'produk': produk,
        'jumlah': berat,
        'harga': harga,
        'lunas': lunas,
        'catatan': catatan,
      };
      final j = await _remote(
        (a) => old == null
            ? a.post('/penjualan', body)
            : a.put('/penjualan/${old.id}', body),
      );
      final p = penjualanApi(_data(j));
      if (old == null) {
        penjualan.add(p);
      } else {
        old
          ..tanggal = p.tanggal
          ..pembeli = p.pembeli
          ..produk = p.produk
          ..berat = p.berat
          ..harga = p.harga
          ..lunas = p.lunas
          ..catatan = p.catatan;
      }
      notifyListeners();
      return;
    }
    if (old == null) {
      penjualan.add(
        Penjualan(
          _next(penjualan),
          tanggal,
          pembeli,
          produk,
          berat,
          harga,
          lunas: lunas,
          catatan: catatan,
        ),
      );
    } else {
      old
        ..tanggal = tanggal
        ..pembeli = pembeli
        ..produk = produk
        ..berat = berat
        ..harga = harga
        ..lunas = lunas
        ..catatan = catatan;
    }
    notifyListeners();
  }

  Future<void> deletePenjualan(Penjualan item) async {
    if (online) await _remote((a) => a.delete('/penjualan/${item.id}'));
    penjualan.remove(item);
    notifyListeners();
  }

  Future<void> finish(Budidaya item) async {
    if (online) {
      await _remote((a) => a.put('/budidaya/${item.id}', {'selesai': true}));
    }
    item.selesai = true;
    notifyListeners();
  }

  Future<void> updateProfile(String n, String e, [String? farm]) async {
    if (online) {
      final j = await _remote(
        (a) => a.put('/me', {'name': n, 'email': e, 'farm_name': ?farm}),
      );
      _applyUser(_data(j));
      notifyListeners();
      return;
    }
    nama = n;
    email = e;
    if (farm != null) farmName = farm;
    notifyListeners();
  }

  /// Ganti password akun (hanya online).
  Future<void> changePassword(String lama, String baru) async {
    await _remote(
      (a) => a.put('/me', {'current_password': lama, 'password': baru}),
    );
  }

  /// Total berat (kg). Telur (gram) tidak ikut dijumlah agar satuan
  /// tidak tercampur.
  double total(Iterable<Catatan> items) =>
      items.fold(0, (sum, e) => sum + kgOf(e));

  double kgOf(Catatan e) => e.jenis == 'Telur' ? 0 : e.berat;

  double pendapatan(Iterable<Penjualan> items) =>
      items.fold(0, (sum, e) => sum + e.total);

  /// Jumlah [value] per hari untuk [days] hari terakhir (lama → hari ini).
  List<double> dailyBy<T>(
    Iterable<T> items,
    DateTime Function(T) date,
    double Function(T) value, {
    int days = 7,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());
    final out = List<double>.filled(days, 0);
    for (final e in items) {
      final diff = today.difference(DateUtils.dateOnly(date(e))).inDays;
      if (diff >= 0 && diff < days) out[days - 1 - diff] += value(e);
    }
    return out;
  }

  /// Total berat catatan per hari.
  List<double> daily(Iterable<Catatan> items, {int days = 7}) =>
      dailyBy(items, (e) => e.tanggal, (e) => e.berat, days: days);

  List<MapEntry<String, double>> _group<T>(
    Iterable<T> items,
    String Function(T) key,
    double Function(T) value,
  ) {
    final m = <String, double>{};
    for (final e in items) {
      final k = key(e);
      m[k] = (m[k] ?? 0) + value(e);
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Total pakan per jenis, terbesar dulu.
  List<MapEntry<String, double>> pakanPerJenis() => _group(
    pakan,
    (e) => e.jenis.isEmpty ? 'Lainnya' : e.jenis,
    (e) => e.berat,
  );

  List<MapEntry<String, double>> pendapatanPerProduk(
    Iterable<Penjualan> items,
  ) => _group(items, (e) => e.produk, (e) => e.total);

  List<MapEntry<String, double>> topPembeli(Iterable<Penjualan> items) =>
      _group(items, (e) => e.pembeli, (e) => e.total);
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
