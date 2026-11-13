// Helper JSON
DateTime _dt(Object? v) => DateTime.parse(v as String);
DateTime? _dtn(Object? v) => v == null ? null : DateTime.parse(v as String);
double _d(Object? v) => (v as num).toDouble();
double? _dn(Object? v) => v == null ? null : (v as num).toDouble();

/// Data lama: produk "Prepupa" sudah dihapus dan digabung ke maggot segar.
String _produkLama(String p) => p == 'Prepupa' ? 'Maggot segar' : p;

class Kandang {
  Kandang(this.id, this.nama, this.lokasi, this.kapasitas, this.catatan);
  final int id;
  String nama, lokasi, catatan;
  double? kapasitas;

  Map<String, Object?> toJson() => {
    'id': id,
    'nama': nama,
    'lokasi': lokasi,
    'kapasitas': kapasitas,
    'catatan': catatan,
  };
  factory Kandang.fromJson(Map<String, dynamic> j) => Kandang(
    j['id'] as int,
    j['nama'] as String,
    j['lokasi'] as String,
    _dn(j['kapasitas']),
    j['catatan'] as String? ?? '',
  );
}

/// Foto perkembangan maggot pada satu siklus budidaya.
class Foto {
  Foto(this.id, this.budidayaId, this.path, this.tanggal, [this.catatan = '']);
  final int id;
  int budidayaId;
  String path, catatan;
  DateTime tanggal;

  Map<String, Object?> toJson() => {
    'id': id,
    'budidayaId': budidayaId,
    'path': path,
    'tanggal': tanggal.toIso8601String(),
    'catatan': catatan,
  };
  factory Foto.fromJson(Map<String, dynamic> j) => Foto(
    j['id'] as int,
    j['budidayaId'] as int,
    j['path'] as String,
    _dt(j['tanggal']),
    j['catatan'] as String? ?? '',
  );
}

class Budidaya {
  Budidaya(
    this.id,
    this.nama,
    this.kandangId,
    this.mulai,
    this.beratAwal,
    this.perkiraanPanen,
    this.catatan,
    this.selesai, {
    this.tujuan = 'fresh',
  });
  final int id;
  String nama, catatan;
  int kandangId;
  DateTime mulai;
  double? beratAwal;
  DateTime? perkiraanPanen;
  bool selesai;

  /// Tujuan siklus: lihat [tujuanList].
  String tujuan;

  Map<String, Object?> toJson() => {
    'id': id,
    'nama': nama,
    'kandangId': kandangId,
    'mulai': mulai.toIso8601String(),
    'beratAwal': beratAwal,
    'perkiraanPanen': perkiraanPanen?.toIso8601String(),
    'catatan': catatan,
    'selesai': selesai,
    'tujuan': tujuan,
  };
  factory Budidaya.fromJson(Map<String, dynamic> j) => Budidaya(
    j['id'] as int,
    j['nama'] as String,
    j['kandangId'] as int,
    _dt(j['mulai']),
    _dn(j['beratAwal']),
    _dtn(j['perkiraanPanen']),
    j['catatan'] as String? ?? '',
    j['selesai'] as bool? ?? false,
    // tujuan "prepupa" sudah dihapus → jadi maggot fresh
    tujuan: switch (j['tujuan'] as String?) {
      final t? when tujuanList.contains(t) => t,
      _ => 'fresh',
    },
  );
}

// =====================================================================
// Tujuan siklus & estimasi waktu (perkiraan umum BSF, dihitung dari
// tanggal tebar telur / baby maggot). Bisa disesuaikan per batch.
// =====================================================================
const tujuanList = ['fresh', 'kering', 'perkawinan'];
const tujuanLabel = {
  'fresh': 'Maggot fresh',
  'kering': 'Maggot kering',
  'perkawinan': 'Perkawinan (telur)',
};

/// Nama pendek untuk ubin pilihan.
const tujuanSingkat = {
  'fresh': 'Fresh',
  'kering': 'Kering',
  'perkawinan': 'Perkawinan',
};
const tujuanEmoji = {'fresh': '🐛', 'kering': '🌾', 'perkawinan': '🦋'};

/// Estimasi hari panen per tujuan.
const tujuanHari = {'fresh': 16, 'kering': 18, 'perkawinan': 40};
const tujuanKeterangan = {
  'fresh': 'Panen larva ±hari ke-14–18, saat masih krem & aktif makan.',
  'kering': 'Panen larva ±hari ke-16–18, lalu dijemur/olah jadi kering.',
  'perkawinan':
      'Larva → pupa (±21, menghitam lalu diam & keras) → lalat (±35) → bertelur (±38–42).',
};

/// Produk panen bawaan per tujuan.
const tujuanProduk = {
  'fresh': 'Maggot segar',
  'kering': 'Maggot segar',
  'perkawinan': 'Telur',
};

/// Fase batch perkawinan: (nama, mulai hari ke-, emoji, butuh pakan).
const faseKawin = [
  ('Larva', 0, '🐛', true),
  ('Pupa', 21, '🟫', false),
  ('Lalat & kawin', 35, '🦋', false),
  ('Bertelur', 38, '🥚', false),
];

extension BudidayaX on Budidaya {
  /// Umur siklus dalam hari.
  int get umur {
    final d = DateTime.now().difference(mulai).inDays;
    return d < 0 ? 0 : d;
  }

  /// Perkiraan panen: manual bila diisi, kalau tidak sesuai tujuan.
  DateTime get estimasiPanen =>
      perkiraanPanen ??
      DateTime(mulai.year, mulai.month, mulai.day + (tujuanHari[tujuan] ?? 16));

  /// Indeks fase saat ini (hanya untuk batch perkawinan).
  int get faseIndex {
    var i = 0;
    for (var k = 0; k < faseKawin.length; k++) {
      if (umur >= faseKawin[k].$2) i = k;
    }
    return i;
  }

  /// Masih perlu diberi pakan? (pupa & lalat tidak makan)
  bool get butuhPakan =>
      !selesai && (tujuan != 'perkawinan' || faseKawin[faseIndex].$4);

  /// Progres 0..1 menuju perkiraan panen.
  double get progress {
    if (selesai) return 1;
    final end = estimasiPanen;
    final total = end.difference(mulai).inHours;
    if (total <= 0) return 1;
    final v = DateTime.now().difference(mulai).inHours / total;
    return v < 0 ? 0 : (v > 1 ? 1 : v);
  }
}

class Catatan {
  Catatan(
    this.id,
    this.budidayaId,
    this.tanggal,
    this.berat,
    this.catatan, [
    this.jenis = '',
  ]);
  final int id;
  int budidayaId;
  DateTime tanggal;
  double berat;
  String catatan, jenis;

  Map<String, Object?> toJson() => {
    'id': id,
    'budidayaId': budidayaId,
    'tanggal': tanggal.toIso8601String(),
    'berat': berat,
    'catatan': catatan,
    'jenis': jenis,
  };
  factory Catatan.fromJson(Map<String, dynamic> j) => Catatan(
    j['id'] as int,
    j['budidayaId'] as int,
    _dt(j['tanggal']),
    _d(j['berat']),
    j['catatan'] as String? ?? '',
    _produkLama(j['jenis'] as String? ?? ''),
  );
}

class Penjualan {
  Penjualan(
    this.id,
    this.tanggal,
    this.pembeli,
    this.produk,
    this.berat,
    this.harga, {
    this.lunas = true,
    this.catatan = '',
  });
  final int id;
  DateTime tanggal;
  String pembeli, produk, catatan;
  double berat, harga;
  bool lunas;
  double get total => berat * harga;

  Map<String, Object?> toJson() => {
    'id': id,
    'tanggal': tanggal.toIso8601String(),
    'pembeli': pembeli,
    'produk': produk,
    'berat': berat,
    'harga': harga,
    'lunas': lunas,
    'catatan': catatan,
  };
  factory Penjualan.fromJson(Map<String, dynamic> j) => Penjualan(
    j['id'] as int,
    _dt(j['tanggal']),
    j['pembeli'] as String,
    _produkLama(j['produk'] as String),
    _d(j['berat']),
    _d(j['harga']),
    lunas: j['lunas'] as bool? ?? true,
    catatan: j['catatan'] as String? ?? '',
  );
}

/// Perubahan stok di luar panen & penjualan:
/// penyesuaian (stok awal, rusak, susut…), olah (fresh → kering),
/// dan tebar (telur dipakai untuk batch baru).
class Mutasi {
  Mutasi(
    this.id,
    this.tanggal,
    this.produk,
    this.jumlah,
    this.jenis,
    this.keterangan,
  );
  final int id;
  DateTime tanggal;
  String produk, jenis, keterangan;

  /// Positif = stok bertambah, negatif = berkurang.
  double jumlah;

  Map<String, Object?> toJson() => {
    'id': id,
    'tanggal': tanggal.toIso8601String(),
    'produk': produk,
    'jumlah': jumlah,
    'jenis': jenis,
    'keterangan': keterangan,
  };
  factory Mutasi.fromJson(Map<String, dynamic> j) => Mutasi(
    j['id'] as int,
    _dt(j['tanggal']),
    _produkLama(j['produk'] as String),
    _d(j['jumlah']),
    j['jenis'] as String? ?? 'penyesuaian',
    j['keterangan'] as String? ?? '',
  );
}

const produkList = [
  'Maggot segar',
  'Maggot kering',
  'Pupa',
  'Telur',
  'Kasgot (pupuk)',
];

/// Produk yang bisa dipanen langsung. Maggot kering harus lewat "Olah".
const produkPanen = ['Maggot segar', 'Pupa', 'Telur', 'Kasgot (pupuk)'];

const produkEmoji = {
  'Maggot segar': '🐛',
  'Maggot kering': '🌾',
  'Pupa': '🟫',
  'Telur': '🥚',
  'Kasgot (pupuk)': '🌱',
};

/// Satuan produk: telur dalam gram, lainnya kg.
String satuan(String produk) => produk == 'Telur' ? 'g' : 'kg';

/// Format jumlah + satuan, mis. "2,5 kg" atau "40 g".
String qty(String produk, num n) =>
    '${n.toStringAsFixed(n % 1 == 0 ? 0 : 2)} ${satuan(produk)}';

const hargaDefault = <String, double>{
  'Maggot segar': 8000,
  'Pupa': 15000,
  'Telur': 8000, // per gram
  'Maggot kering': 45000,
  'Kasgot (pupuk)': 2000,
};

const _bln = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String tanggal(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String tanggalPanjang(DateTime d) => '${d.day} ${_bln[d.month - 1]} ${d.year}';
String tanggalPendek(DateTime d) => '${d.day} ${_bln[d.month - 1]}';
String kg(num n) => '${n.toStringAsFixed(n % 1 == 0 ? 0 : 2)} kg';

String rupiah(num n) {
  final s = n.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}Rp $b';
}

String rupiahSingkat(num n) {
  final a = n.abs();
  if (a >= 1e6) {
    final v = n / 1e6;
    return 'Rp ${v.toStringAsFixed(v % 1 == 0 ? 0 : 1).replaceAll('.', ',')} jt';
  }
  if (a >= 1e3) return 'Rp ${(n / 1e3).round()} rb';
  return rupiah(n);
}

// =====================================================================
// Pemetaan data dari API (nama kolom snake_case).
// =====================================================================
Kandang kandangApi(Map<String, dynamic> j) => Kandang(
  j['id'] as int,
  j['nama'] as String,
  j['lokasi'] as String,
  _dn(j['kapasitas']),
  j['catatan'] as String? ?? '',
);

Budidaya budidayaApi(Map<String, dynamic> j) => Budidaya(
  j['id'] as int,
  j['nama'] as String,
  j['kandang_id'] as int,
  _dt(j['mulai']),
  _dn(j['berat_awal']),
  _dtn(j['perkiraan_panen']),
  j['catatan'] as String? ?? '',
  j['selesai'] == true || j['selesai'] == 1,
  tujuan: tujuanList.contains(j['tujuan']) ? j['tujuan'] as String : 'fresh',
);

Catatan pakanApi(Map<String, dynamic> j) => Catatan(
  j['id'] as int,
  j['budidaya_id'] as int,
  _dt(j['tanggal']),
  _d(j['berat']),
  j['catatan'] as String? ?? '',
  j['jenis'] as String? ?? '',
);

/// Panen: kolom produk & jumlah disimpan di jenis & berat.
Catatan panenApi(Map<String, dynamic> j) => Catatan(
  j['id'] as int,
  j['budidaya_id'] as int,
  _dt(j['tanggal']),
  _d(j['jumlah']),
  j['catatan'] as String? ?? '',
  j['produk'] as String,
);

Penjualan penjualanApi(Map<String, dynamic> j) => Penjualan(
  j['id'] as int,
  _dt(j['tanggal']),
  j['pembeli'] as String,
  j['produk'] as String,
  _d(j['jumlah']),
  _d(j['harga']),
  lunas: j['lunas'] == true || j['lunas'] == 1,
  catatan: j['catatan'] as String? ?? '',
);

Mutasi mutasiApi(Map<String, dynamic> j) => Mutasi(
  j['id'] as int,
  _dt(j['tanggal']),
  j['produk'] as String,
  _d(j['jumlah']),
  j['jenis'] as String? ?? 'penyesuaian',
  j['keterangan'] as String? ?? '',
);

/// Foto dari server: path berisi URL.
Foto fotoApi(Map<String, dynamic> j) => Foto(
  j['id'] as int,
  j['budidaya_id'] as int,
  j['url'] as String,
  _dt(j['tanggal']),
  j['catatan'] as String? ?? '',
);

// =====================================================================
// Stok pakan (gudang bersama)
// =====================================================================

/// Jenis pakan yang boleh dipakai (daftar tetap, supaya stok tidak pecah
/// karena salah ketik).
const jenisPakanList = [
  'Sisa sayur',
  'Ampas tahu',
  'Kulit buah',
  'Dedak',
  'Bungkil sawit',
  'Lainnya',
];

const jenisPakanEmoji = {
  'Sisa sayur': '🥬',
  'Ampas tahu': '🫘',
  'Kulit buah': '🍌',
  'Dedak': '🌾',
  'Bungkil sawit': '🌴',
  'Lainnya': '📦',
};

/// Batas segar (hari) per jenis pakan. Perkiraan umum; sesuaikan dengan
/// kondisi gudangmu.
const batasSegarPakan = {
  'Sisa sayur': 3,
  'Ampas tahu': 2,
  'Kulit buah': 3,
  'Dedak': 30,
  'Bungkil sawit': 30,
  'Lainnya': 7,
};

/// Jenis pakan lama (diketik bebas) yang tidak ada di daftar → "Lainnya".
String jenisPakanOf(String jenis) =>
    jenisPakanList.contains(jenis) ? jenis : 'Lainnya';

/// Pakan masuk ke gudang, atau penyesuaian stok pakan (busuk, stok awal…).
/// Pakan keluar = catatan pemberian pakan.
class MutasiPakan {
  MutasiPakan(
    this.id,
    this.tanggal,
    this.jenis,
    this.jumlah,
    this.tipe, {
    this.harga,
    this.keterangan = '',
  });
  final int id;
  DateTime tanggal;
  String jenis;

  /// kg. Positif = masuk, negatif = berkurang (busuk/terbuang).
  double jumlah;

  /// 'masuk' | 'penyesuaian'
  String tipe;

  /// Harga per kg (opsional, hanya untuk pakan masuk yang dibeli).
  double? harga;
  String keterangan;

  double get biaya => harga == null || jumlah <= 0 ? 0 : jumlah * harga!;

  Map<String, Object?> toJson() => {
    'id': id,
    'tanggal': tanggal.toIso8601String(),
    'jenis': jenis,
    'jumlah': jumlah,
    'tipe': tipe,
    'harga': harga,
    'keterangan': keterangan,
  };
  factory MutasiPakan.fromJson(Map<String, dynamic> j) => MutasiPakan(
    j['id'] as int,
    _dt(j['tanggal']),
    jenisPakanOf(j['jenis'] as String),
    _d(j['jumlah']),
    j['tipe'] as String? ?? 'masuk',
    harga: _dn(j['harga']),
    keterangan: j['keterangan'] as String? ?? '',
  );
}

MutasiPakan mutasiPakanApi(Map<String, dynamic> j) => MutasiPakan.fromJson(j);
