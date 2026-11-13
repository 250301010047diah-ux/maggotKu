# MaggotKu

Frontend Flutter untuk mencatat kandang, kelompok budidaya, pakan, dan panen. Seluruh label aplikasi menggunakan bahasa Indonesia.

Baru belajar coding? Mulai dari [panduan belajar MaggotKu](PANDUAN_BELAJAR_MAGGOTKU.md). Panduan itu menjelaskan alur aplikasi, fungsi setiap folder, cara data disimpan, dan latihan bertahap dari nol.

## Menjalankan

1. Pasang Flutter SDK dan Android Studio/Android SDK.
2. Buka folder proyek ini di terminal.
3. Jalankan `flutter pub get`.
4. Jalankan emulator Android atau hubungkan HP dengan USB debugging.
5. Jalankan `flutter run`.
6. Pada halaman login, pilih **Masuk mode demo**.

## Catatan demo

Mode demo dimulai dengan data kosong dan menyimpan perubahan di HP melalui `SharedPreferences`; data tetap ada saat aplikasi dibuka ulang pada pemasangan yang sama. Login dan pendaftaran memakai API di `server/`, sedangkan akun menyimpan data utama di MySQL. Salinan terakhir data akun juga disimpan di HP untuk ditampilkan saat koneksi gagal. Pemulihan password belum terhubung ke layanan pengiriman email.

Pemeriksaan: `flutter analyze` dan `flutter test`.
