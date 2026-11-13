# API MaggotKu — panduan pasang di cPanel

## 1. Ganti password database (wajib)
Password lama sempat tertulis di kode, jadi anggap sudah bocor.
cPanel → **MySQL® Databases** → *Current Users* → `appsmobi_user_mobile`
→ **Change Password** → buat password baru yang kuat.

## 2. Buat tabel
phpMyAdmin → pilih database **appsmobi_db_maggot** → tab **SQL**
→ tempel seluruh isi `schema.sql` → **Go**.
Tabel `users` yang sudah ada (beserta akunnya) tidak diubah.

> Kalau muncul error *"Failed to open the referenced table"* atau
> *"incompatible"* pada foreign key: buka tabel `users` → Structure,
> pastikan kolom `id` bertipe `INT` (bukan `INT UNSIGNED`/`BIGINT`).
> Kalau berbeda, kabari — tipe `user_id` di schema tinggal disamakan.

## 3. Upload file API
Upload ke folder aplikasi Node yang sekarang (yang melayani `/api-maggot`):
- `app.js` (ganti yang lama)
- `package.json` (ganti yang lama)

**Jangan** upload folder `node_modules`. Folder `uploads/` dibuat otomatis.

## 4. Environment Variables
cPanel → **Setup Node.js App** → pilih aplikasinya → *Environment variables*:

| Nama | Isi |
|---|---|
| `DB_USER` | `appsmobi_user_mobile` |
| `DB_PASS` | password **baru** dari langkah 1 |
| `DB_NAME` | `appsmobi_db_maggot` |
| `JWT_SECRET` | teks acak panjang (min. 32 karakter), mis. hasil https://generate-secret.vercel.app/64 — jangan dibagikan |
| `PUBLIC_URL` | `https://appsmobiledeveloper.my.id/api-maggot` |

Lalu klik **Run NPM Install**, kemudian **Restart**.

## 5. Cek
Buka https://appsmobiledeveloper.my.id/api-maggot/test → harus muncul
`"database": "ok"`.

---

## Daftar endpoint
Semua (kecuali register, login, test) wajib header
`Authorization: Bearer <token>` dari hasil login.

| Method | Path | Keterangan |
|---|---|---|
| POST | `/auth/register` | `{name, email, password, farm_name?}` → `{token, user}` |
| POST | `/auth/login` | `{email, password}` → `{token, user}` |
| GET / PUT | `/me` | profil sendiri; ganti password wajib `current_password` |
| GET POST PUT DELETE | `/kandang` | `{nama, lokasi, kapasitas?, catatan?}` |
| GET POST PUT DELETE | `/budidaya` | `{kandang_id, nama, tujuan: fresh/kering/perkawinan, mulai, berat_awal?, perkiraan_panen?, catatan?, selesai?}`; POST boleh `telur_gram` (mengurangi stok telur) |
| GET POST PUT DELETE | `/pakan` | `{budidaya_id, tanggal, jenis, berat, catatan?}` |
| GET POST PUT DELETE | `/panen` | `{budidaya_id, tanggal, produk, jumlah, catatan?}` |
| GET POST PUT DELETE | `/penjualan` | `{tanggal, pembeli, produk, jumlah, harga, lunas?, catatan?}` |
| GET POST PUT DELETE | `/mutasi` | penyesuaian stok `{tanggal, produk, jumlah(±), keterangan?}` |
| GET | `/stok` | stok per produk |
| POST | `/olah` | `{fresh, kering, tanggal?}` maggot fresh → kering |
| GET / POST / DELETE | `/foto` | upload `multipart/form-data`: `foto` (file), `budidaya_id`, `tanggal?` |

- Filter daftar: mis. `/panen?budidaya_id=3`, `/penjualan?lunas=false`.
- Produk: `Maggot segar`, `Maggot kering`, `Pupa`, `Telur` (gram), `Kasgot (pupuk)`.
- Tanggal: `YYYY-MM-DD` atau `YYYY-MM-DDTHH:MM:SS`.
- Stok dihitung dari panen + mutasi − penjualan. Server menolak perubahan
  yang membuat stok minus (jual melebihi stok, hapus panen yang sudah terjual).
- Endpoint lama `/register` & `/login` tetap jalan. `/users` & `/profile/:id`
  **dihapus** karena membuka data semua pengguna tanpa login.
