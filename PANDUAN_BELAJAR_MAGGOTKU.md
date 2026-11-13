# Belajar Membaca dan Membuat Aplikasi MaggotKu dari Nol

Panduan ini untuk kamu yang belum pernah menulis kode. Tujuannya bukan menghafal semua file, melainkan memahami **apa yang terjadi ketika sebuah tombol ditekan**, **ke mana data pergi**, dan **bagaimana menambah fitur kecil dengan aman**. Bacalah berurutan. Kamu boleh mencoba setiap langkah sebelum lanjut.

> **Acuan:** kode yang ada di folder proyek ini pada 13 November 2026. Beberapa keterangan di `README.md` lama sudah tidak cocok dengan kode sekarang. Misalnya, data mode demo sekarang tersimpan di HP dan mode demo baru mulai dengan data kosong.

## 1. Aplikasi ini sebenarnya terdiri dari apa?

MaggotKu adalah aplikasi Android yang dibuat dengan **Flutter**. Bahasa pemrogramannya **Dart**. Aplikasi dapat dipakai dalam dua cara:

| Cara memakai | Tempat data utama | Perlu internet? | Saat aplikasi ditutup |
|---|---|---|---|
| Mode demo | Penyimpanan aplikasi di HP (`SharedPreferences`) | Tidak | Data tetap ada di HP yang sama |
| Akun | Database MySQL melalui server API | Ya untuk mengambil dan mengubah data | Data akun tetap di server; salinan terakhir juga ada di HP |

Salinan data akun di HP dipakai untuk **menampilkan data terakhir** saat koneksi bermasalah. Perubahan akun **tidak otomatis masuk antrean offline** untuk dikirim nanti: menyimpan perubahan akun tetap membutuhkan server.

Bayangkan tiga bagian:

```text
Layar Flutter (form, tombol, daftar)
          ↓ memanggil
AppState (data yang sedang dipakai + aturan aplikasi)
          ├─ mode demo → SharedPreferences di HP
          └─ akun → Api → server Express/Node.js → MySQL
```

**Layar** adalah yang dilihat pengguna. **AppState** menyimpan data yang sedang ditampilkan dan menyediakan fungsi seperti `saveKandang()`. **API** adalah pintu komunikasi antara aplikasi dan server. **Database** menyimpan data akun di tabel.

## 2. Mulai dari pengalaman pengguna

Jalankan aplikasi dan amati alur berikut:

1. Saat belum masuk, pengguna melihat halaman pengenalan, lalu halaman masuk.
2. Memilih **Masuk mode demo** membuka Beranda tanpa membuat akun. Pada pemasangan baru, daftar data masih kosong. Tambahkan kandang sendiri untuk belajar.
3. Memakai akun menjalankan login ke server. Server mengirim **token**, yaitu tanda bahwa akun sudah berhasil masuk.
4. Beranda mempunyai lima tab utama: **Beranda, Budidaya, Catatan, Jual, Akun**. Fitur lain seperti kandang, stok, kalkulator, foto, dan agenda dibuka dari halaman terkait.
5. Saat data diubah, layar yang menggunakan data itu diperbarui. Pada mode demo, perubahan disimpan di HP. Pada akun, perubahan dikirim ke server dahulu.

Urutan pekerjaan budidaya yang masuk akal adalah **buat kandang → buat batch budidaya → catat pakan dan foto → catat panen → lihat stok → catat penjualan**. “Batch” berarti satu kelompok/siklus budidaya, misalnya “Budidaya November”.

## 3. Peta folder: baca yang penting dulu

| Lokasi | Fungsi | Kapan dibaca |
|---|---|---|
| [`lib/main.dart`](lib/main.dart) | Titik awal aplikasi; memilih halaman pertama | Pertama |
| [`lib/data/models.dart`](lib/data/models.dart) | Bentuk data: kandang, budidaya, catatan, penjualan, foto, mutasi | Kedua |
| [`lib/data/app_state.dart`](lib/data/app_state.dart) | Data aktif, simpan/ubah data, stok, agenda, penyimpanan HP, sinkronisasi | Ketiga; baca sedikit demi sedikit |
| [`lib/data/api.dart`](lib/data/api.dart) | Mengirim permintaan HTTP ke server dan mengolah jawabannya | Saat belajar mode akun |
| [`lib/pages/`](lib/pages/) | Semua halaman yang dilihat pengguna | Pilih satu halaman yang ingin dipahami |
| [`lib/widgets/`](lib/widgets/) dan [`lib/theme.dart`](lib/theme.dart) | Komponen tampilan bersama, grafik, warna, gaya | Saat ingin mengubah tampilan |
| [`server/app.js`](server/app.js) | Server Node.js: login, validasi, operasi data, stok, upload foto | Setelah alur aplikasi jelas |
| [`server/schema.sql`](server/schema.sql) | Bentuk tabel MySQL dan hubungan antar tabel | Saat belajar database |
| [`test/`](test/) | Pemeriksaan otomatis beberapa aturan dan tampilan | Saat ingin memeriksa perubahan |
| [`pubspec.yaml`](pubspec.yaml) | Daftar paket Flutter, font, dan aset | Saat menambah paket/aset |

Folder `android/` berisi pengaturan Android. Untuk belajar alur fitur, kamu belum perlu membacanya.

**Cara membaca kode tanpa kewalahan:** mulai dari nama fungsi yang dipanggil tombol. Cari nama itu di proyek, lalu ikuti ke `AppState`, kemudian ke `Api` dan server jika fungsi tersebut berjalan online. Kamu tidak perlu membaca ribuan baris secara berurutan.

## 4. Bekal bahasa Dart dalam 10 menit

Contoh kecil berikut mewakili banyak kode di proyek:

```dart
final nama = 'Kandang A';           // teks yang tidak diganti
double berat = 2.5;                // angka desimal yang bisa diganti
bool selesai = false;              // benar atau salah
List<String> produk = ['Pupa'];    // daftar teks

double hitungTotal(double jumlah, double harga) {
  return jumlah * harga;
}
```

Arti tanda yang sering muncul:

| Tanda/istilah | Arti sederhana |
|---|---|
| `String`, `double`, `int`, `bool` | Jenis nilai: teks, desimal, bilangan bulat, benar/salah |
| `List<Kandang>` | Daftar berisi objek `Kandang` |
| `class Kandang` | Cetakan untuk satu data kandang |
| `final` | Variabelnya tidak diarahkan ulang ke nilai/objek lain; isi objek masih bisa berubah |
| `const` | Nilai tetap yang sudah diketahui saat kode dibuat |
| `?` pada `double?` | Nilainya boleh kosong (`null`) |
| `if (...)` | Jalankan kode hanya jika syarat benar |
| `for (...)` | Ulangi pekerjaan |
| `Future<void>` | Pekerjaan yang mungkin selesai nanti, misalnya menyimpan lewat internet |
| `await` | Tunggu pekerjaan tadi selesai sebelum lanjut |
| `return` | Kembalikan hasil dari fungsi |

Misalnya `Kandang` di `models.dart` mempunyai `id`, `nama`, `lokasi`, `kapasitas`, dan `catatan`. Satu objek `Kandang` mewakili **satu baris data**. `List<Kandang>` mewakili banyak baris. Kamu bisa membayangkan daftar ini seperti tabel kecil di memori aplikasi.

## 5. Apa itu widget dan `setState`?

Di Flutter, bagian layar disebut **widget**: teks, tombol, kolom, kartu, bahkan satu halaman. Fungsi `build()` menyusun widget menjadi tampilan. Ketika nilai berubah, tampilan perlu dibuat ulang agar nilai baru terlihat.

Ada dua jenis perubahan yang perlu dibedakan:

- **Perubahan kecil milik satu halaman**, misalnya tab filter yang dipilih atau isi slider kalkulator. Halaman biasanya memanggil `setState(() { ... })` agar dirinya digambar ulang.
- **Perubahan data bersama**, misalnya kandang baru yang harus tampak di beberapa halaman. `AppState` memanggil `notifyListeners()`. Halaman yang membaca `AppScope.of(context)` akan mengikuti perubahan itu.

`Navigator.push(...)` membuka halaman baru. `Navigator.pop(...)` kembali ke halaman sebelumnya. Ini seperti menumpuk dan melepas kartu halaman.

## 6. Ikuti satu fitur nyata: menyimpan kandang

Ini alur paling baik untuk memahami aplikasi. Coba buka formulir **Tambah Kandang** sambil melihat file terkait.

1. Di [`lib/pages/kandang_pages.dart`](lib/pages/kandang_pages.dart), `KandangFormPage` membuat kolom nama, lokasi, kapasitas, dan catatan. `TextEditingController` menyimpan teks yang sedang diketik.
2. Tombol **Simpan Kandang** memeriksa isian formulir dengan `validate()`. Nama dan lokasi wajib diisi; kapasitas, bila diisi, harus positif.
3. Tombol memanggil `s.saveKandang(...)`, dengan `s` berasal dari `AppScope.of(context)`.
4. Di [`lib/data/app_state.dart`](lib/data/app_state.dart), `saveKandang()` memeriksa apakah aplikasi sedang `online`.
5. **Mode demo:** fungsi menambah objek `Kandang` ke daftar lokal. **Akun:** fungsi mengirim `POST /kandang` ke server dan menambahkan jawaban server ke daftar lokal. Jika sedang mengedit, permintaannya `PUT /kandang/:id`.
6. Fungsi memanggil `notifyListeners()`. Daftar kandang yang terlihat pengguna ikut diperbarui; fungsi `_persist()` menyimpan salinan data ke HP.
7. Jika berhasil, formulir ditutup dan pengguna melihat daftar yang telah berubah.

```text
Ketuk Simpan
  → validasi formulir
  → AppState.saveKandang(...)
     → demo: ubah daftar di HP
     → akun: kirim ke API, server menulis ke MySQL
  → notifyListeners()
  → layar memperlihatkan data baru
```

Ini pola yang berulang pada fitur budidaya, pakan, panen, dan penjualan. Mulailah dengan memahami **satu** alur ini.

## 7. Mode demo: bagaimana data tetap ada?

Pada pembukaan aplikasi, `main()` memanggil `AppState.load()`. Fungsi ini mengambil data tersimpan melalui `SharedPreferences`, lalu membuat `AppState` berisi data tersebut. Ketika data berubah, `notifyListeners()` memanggil `_persist()`. `_persist()` mengubah objek menjadi teks **JSON** dan menyimpannya di penyimpanan aplikasi HP.

JSON adalah format teks yang mudah dikirim dan disimpan. Bentuk sederhananya:

```json
{"id": 1, "nama": "Kandang A", "lokasi": "Belakang rumah"}
```

Di [`lib/data/models.dart`](lib/data/models.dart), `toJson()` mengubah objek menjadi data JSON; `fromJson()` membangunnya kembali saat aplikasi dibuka. Data demo berada pada HP dan instalasi aplikasi tersebut, sehingga jangan menganggapnya sebagai cadangan di server. Menghapus data aplikasi atau memasang ulang dapat menghilangkannya.

`LocalRepository` memang punya pilihan membuat data contoh (`demo: true`), tetapi `AppState` saat ini memakai `LocalRepository()` tanpa pilihan itu. Artinya **mode demo baru kosong**, bukan otomatis berisi kandang contoh.

## 8. Mode akun: perjalanan data sampai database

Ketika pengguna masuk, [`lib/pages/auth_pages.dart`](lib/pages/auth_pages.dart) memanggil `AppState.login()`. Fungsi itu mengirim email dan password melalui [`lib/data/api.dart`](lib/data/api.dart) ke `POST /auth/login`. Server di [`server/app.js`](server/app.js) memeriksa akun, lalu mengirim token dan profil. Aplikasi menyimpan token agar permintaan berikutnya bisa menyertakan header `Authorization: Bearer <token>`.

Contoh perjalanan saat menambah kandang:

```text
Flutter: saveKandang()
  → HTTP POST /kandang dengan JSON
  → server memeriksa token dan isian
  → server menulis baris baru ke tabel MySQL `kandang`
  → server mengirim JSON data kandang baru
  → Flutter mengubah JSON menjadi objek Kandang
  → daftar dan layar diperbarui
```

**HTTP** adalah cara aplikasi meminta sesuatu ke server. Empat kata kerja yang banyak dipakai di sini:

| Kata kerja | Maksud | Contoh |
|---|---|---|
| `GET` | Ambil data | `GET /kandang` |
| `POST` | Buat data baru | `POST /kandang` |
| `PUT` | Ubah data yang ada | `PUT /kandang/1` |
| `DELETE` | Hapus data | `DELETE /foto/1` |

Server menggunakan **Express** untuk menerima permintaan dan **MySQL** untuk menyimpan data. Struktur tabel ada di [`server/schema.sql`](server/schema.sql): `users`, `kandang`, `budidaya`, `pakan`, `panen`, `penjualan`, `mutasi_stok`, dan `foto`. Kolom `user_id` menghubungkan data dengan pemilik akun. `kandang_id` menghubungkan satu batch dengan kandangnya; `budidaya_id` menghubungkan pakan, panen, dan foto dengan batch.

`AppState.syncAll()` mengambil data akun dari beberapa endpoint ketika pengguna masuk atau membuka Beranda. Saat server tidak bisa dihubungi, aplikasi masih bisa menampilkan salinan terakhir. Saat token tidak berlaku lagi, aplikasi mengarahkan pengguna kembali ke halaman masuk.

**Password database dan `JWT_SECRET` hanya untuk server.** Jangan menaruhnya di kode Flutter karena aplikasi yang dipasang di HP dapat diperiksa orang lain. Cara menyiapkan server hosting dijelaskan terpisah di [`server/README.md`](server/README.md); kamu belum perlu melakukannya untuk belajar dengan mode demo.

## 9. Aturan bisnis: mengapa stok tidak punya satu tabel angka saja?

Stok dihitung dari riwayat kejadian:

```text
stok suatu produk = total panen + total mutasi stok − total penjualan
```

Contoh **Maggot segar**: panen 10 kg, penyesuaian +2 kg, dijual 3 kg. Stoknya `10 + 2 − 3 = 9 kg`. Fungsi `stok(produk)` di `AppState` menghitung angka untuk layar. Server mempunyai perhitungan yang sama dan memeriksa stok sebelum menyimpan perubahan akun yang dapat menguranginya.

**Mutasi** adalah catatan penambahan/pengurangan stok di luar panen dan penjualan. Contohnya stok awal, penyusutan, telur yang dipakai untuk batch baru, dan proses olah. Mengolah 5 kg maggot segar menjadi 1 kg maggot kering mencatat **dua** mutasi: `−5 kg` segar dan `+1 kg` kering. Telur memakai satuan **gram**, sedangkan produk lain memakai **kg**. Karena itu total berat telur tidak boleh dicampur begitu saja ke total kg.

Di mode akun, server menolak perubahan yang membuat stok turun di bawah nol, misalnya menjual lebih banyak daripada stok. Di mode demo, jangan menganggap pemeriksaan server itu tersedia: data tidak dikirim ke server. Formulir mungkin punya validasi sendiri, tetapi aturannya perlu dilihat per fitur.

## 10. Fitur yang hanya menghitung, bukan menyimpan

Tidak setiap layar menulis data. **Agenda** dibuat dari batch aktif, tanggal perkiraan panen, catatan pakan hari ini, dan foto mingguan. Fungsi `agenda()` dan `mingguFoto()` ada di `AppState`. Isi agenda berubah ketika data dasar berubah atau waktu berganti.

**Kalkulator** di [`lib/pages/kalkulator_page.dart`](lib/pages/kalkulator_page.dart) menghitung simulasi dari angka masukan, seperti jumlah pakan, perkiraan efisiensi, harga, dan biaya. Contohnya `hasil maggot = pakan × efisiensi / 100`. Hasil kalkulator adalah **perkiraan**, bukan catatan panen otomatis dan bukan jaminan hasil budidaya. Tombol memakai data 30 hari mengambil angka dari catatan yang ada untuk mengisi sebagian asumsi.

## 11. Cara menjalankan proyek untuk belajar

Di komputer Windows, pasang **Flutter SDK** dan **Android Studio/Android SDK**, lalu siapkan emulator Android atau HP dengan USB debugging. Buka PowerShell di folder proyek `C:\projek apps\maggot` dan jalankan:

```powershell
flutter doctor
flutter pub get
flutter devices
flutter run
```

`flutter doctor` memeriksa lingkungan, `flutter pub get` mengambil paket dari `pubspec.yaml`, `flutter devices` menampilkan perangkat yang tersedia, dan `flutter run` menjalankan aplikasi. Setelah aplikasi terbuka, pilih **Masuk mode demo**. Server lokal **tidak diperlukan** untuk langkah belajar ini.

Untuk pemeriksaan kode, gunakan:

```powershell
flutter analyze
flutter test
```

`flutter analyze` mencari masalah kode yang dapat dideteksi tanpa menjalankan aplikasi. `flutter test` menjalankan pengujian dalam folder `test/`. Jika perintah gagal karena perangkat atau SDK, periksa keluaran `flutter doctor` dahulu.

## 12. Latihan bertahap yang aman

Lakukan satu latihan, jalankan aplikasi, lalu lihat akibatnya. Simpan salinan file sebelum mengubah kode jika belum memakai Git.

1. **Tanpa mengubah kode:** jalankan mode demo. Buat satu kandang, tutup aplikasi, buka lagi. Amati bahwa kandang tetap ada. Cari `saveKandang`, `notifyListeners`, `_persist`, dan `_restore` di `app_state.dart`.
2. **Ubah teks saja:** di `kandang_pages.dart`, cari judul atau teks penjelas pada formulir kandang. Ubah satu kalimat. Jalankan ulang dan lihat bagian layar yang berubah. Ini memperlihatkan hubungan antara kode widget dan tampilan.
3. **Ikuti data:** buat satu batch budidaya yang memakai kandang tadi. Cari `saveBudidaya()` dan temukan `kandangId`. Jelaskan dengan kata sendiri: mengapa batch perlu ID kandang?
4. **Hitung manual:** catat panen Maggot segar 2 kg, lalu jual 0,5 kg. Sebelum melihat layar Stok, tebak hasilnya. Cari fungsi `stok()` dan cocokkan jawabannya: **1,5 kg**.
5. **Latihan membaca online tanpa mengubah server:** cari `savePenjualan()` di `app_state.dart`, lalu cocokkan nama field yang dikirim dengan `penjualan` di `server/app.js` dan `server/schema.sql`.

Kalau latihan 1–4 sudah jelas, kamu sudah memahami fondasi aplikasi ini: **form → fungsi → data → penyimpanan → layar baru**.

## 13. Saat ingin membuat fitur baru

Pakai urutan berpikir ini sebelum mengetik kode:

1. **Tentukan kebutuhan pengguna.** Contoh: “Saya ingin mencatat pengeluaran listrik per bulan.”
2. **Tentukan bentuk data.** Perlu tanggal, jumlah rupiah, dan keterangan? Buat modelnya.
3. **Tentukan tempat simpan.** Mode demo memerlukan serialisasi JSON di HP. Jika fitur harus ada di akun, tambahkan tabel/endpoint server dan cara sinkronisasinya juga.
4. **Tentukan halaman dan aksi.** Di mana daftar ditampilkan? Form apa yang harus diisi? Apa yang terjadi saat Simpan ditekan?
5. **Tentukan aturan.** Kolom wajib, angka boleh nol atau tidak, data terkait akun/batch yang mana?
6. **Coba alur lengkap.** Buat data, tutup dan buka aplikasi, ubah, lalu periksa tampilan. Untuk fitur akun, periksa juga saat server gagal dan saat akun lain masuk.

Jangan mulai dari warna tombol atau tabel database saja. Mulai dari **satu tindakan pengguna** dan telusuri seluruh perjalanannya.

## 14. Kamus singkat

| Istilah | Arti di proyek ini |
|---|---|
| Frontend | Bagian Flutter yang dilihat dan dipakai di HP |
| Backend / server | Program Node.js yang menerima permintaan akun |
| API / endpoint | Alamat dan aturan untuk berkomunikasi dengan server, misalnya `POST /kandang` |
| Database | Kumpulan tabel MySQL tempat data akun disimpan |
| Model | Bentuk satu jenis data, misalnya `Kandang` |
| State | Data yang sedang dipakai untuk menampilkan layar |
| Widget | Potongan tampilan Flutter |
| Validasi | Pemeriksaan bahwa masukan memenuhi aturan |
| JSON | Format teks untuk menyimpan atau mengirim data terstruktur |
| Token | Tanda login yang disertakan pada permintaan akun |
| Sinkronisasi | Mengambil data terbaru dari server untuk memperbarui data di aplikasi |
| `id` | Nomor unik untuk mengenali satu data |

## Urutan belajar setelah panduan ini

Baca dan coba kode secara berurutan: **`main.dart` → model `Kandang` → `KandangFormPage` → `AppState.saveKandang()` → `AppState._persist()` → `Api.post()` → route kandang di `server/app.js`**. Setiap kali bingung, kembali ke pertanyaan sederhana: **“Data apa yang berubah, siapa yang mengubahnya, dan disimpan di mana?”**
