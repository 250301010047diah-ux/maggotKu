-- =====================================================================
-- Database MaggotKu
-- Jalankan sekali di phpMyAdmin: pilih database appsmobi_db_maggot
-- → tab SQL → tempel seluruh isi file ini → Go.
-- Aman dijalankan ulang (IF NOT EXISTS). Tabel users yang sudah ada
-- beserta isinya TIDAK diubah.
-- =====================================================================
SET NAMES utf8mb4;

-- Sudah ada di database-mu; baris ini hanya untuk instalasi baru.
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  farm_name VARCHAR(150) NOT NULL DEFAULT '',
  photo_url VARCHAR(255) NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Kandang
CREATE TABLE IF NOT EXISTS kandang (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  nama VARCHAR(100) NOT NULL,
  lokasi VARCHAR(150) NOT NULL,
  kapasitas DECIMAL(10,2) NULL,
  catatan TEXT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_kandang_user (user_id),
  CONSTRAINT fk_kandang_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Budidaya / batch. Kandang yang masih punya batch tidak bisa dihapus.
CREATE TABLE IF NOT EXISTS budidaya (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  kandang_id INT NOT NULL,
  nama VARCHAR(100) NOT NULL,
  tujuan ENUM('fresh','kering','perkawinan') NOT NULL DEFAULT 'fresh',
  mulai DATETIME NOT NULL,
  berat_awal DECIMAL(10,2) NULL,
  perkiraan_panen DATETIME NULL,
  catatan TEXT NULL,
  selesai TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_budidaya_user (user_id),
  CONSTRAINT fk_budidaya_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_budidaya_kandang FOREIGN KEY (kandang_id)
    REFERENCES kandang(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Catatan pakan (kg)
CREATE TABLE IF NOT EXISTS pakan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  budidaya_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  jenis VARCHAR(100) NOT NULL,
  berat DECIMAL(10,3) NOT NULL,
  catatan TEXT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pakan_user (user_id, tanggal),
  CONSTRAINT fk_pakan_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_pakan_budidaya FOREIGN KEY (budidaya_id)
    REFERENCES budidaya(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Catatan panen: satu produk per catatan. Telur dalam gram, lainnya kg.
-- Maggot kering tidak dipanen langsung (harus lewat olah).
CREATE TABLE IF NOT EXISTS panen (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  budidaya_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  produk ENUM('Maggot segar','Pupa','Telur','Kasgot (pupuk)') NOT NULL,
  jumlah DECIMAL(12,3) NOT NULL,
  catatan TEXT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_panen_user (user_id, produk),
  CONSTRAINT fk_panen_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_panen_budidaya FOREIGN KEY (budidaya_id)
    REFERENCES budidaya(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Penjualan
CREATE TABLE IF NOT EXISTS penjualan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  pembeli VARCHAR(100) NOT NULL,
  produk ENUM('Maggot segar','Maggot kering','Pupa','Telur','Kasgot (pupuk)') NOT NULL,
  jumlah DECIMAL(12,3) NOT NULL,
  harga DECIMAL(14,2) NOT NULL,
  lunas TINYINT(1) NOT NULL DEFAULT 1,
  catatan TEXT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_penjualan_user (user_id, produk),
  CONSTRAINT fk_penjualan_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Mutasi stok di luar panen & penjualan.
-- jumlah positif = stok bertambah, negatif = berkurang.
CREATE TABLE IF NOT EXISTS mutasi_stok (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  produk ENUM('Maggot segar','Maggot kering','Pupa','Telur','Kasgot (pupuk)') NOT NULL,
  jumlah DECIMAL(12,3) NOT NULL,
  jenis ENUM('penyesuaian','olah','tebar') NOT NULL DEFAULT 'penyesuaian',
  keterangan VARCHAR(255) NOT NULL DEFAULT '',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_mutasi_user (user_id, produk),
  CONSTRAINT fk_mutasi_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Jurnal foto perkembangan (file disimpan di folder uploads/ API)
CREATE TABLE IF NOT EXISTS foto (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  budidaya_id INT NOT NULL,
  file VARCHAR(100) NOT NULL,
  tanggal DATETIME NOT NULL,
  catatan VARCHAR(255) NOT NULL DEFAULT '',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_foto_budidaya (user_id, budidaya_id),
  CONSTRAINT fk_foto_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_foto_budidaya FOREIGN KEY (budidaya_id)
    REFERENCES budidaya(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Stok pakan (gudang bersama) — sama dengan schema_pakan.sql
CREATE TABLE IF NOT EXISTS mutasi_pakan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  jenis ENUM('Sisa sayur','Ampas tahu','Kulit buah','Dedak','Bungkil sawit','Lainnya') NOT NULL,
  -- kg. Positif = masuk / stok awal, negatif = busuk / terbuang.
  jumlah DECIMAL(10,3) NOT NULL,
  tipe ENUM('masuk','penyesuaian') NOT NULL DEFAULT 'masuk',
  -- Harga per kg (hanya untuk pakan yang dibeli).
  harga DECIMAL(14,2) NULL,
  keterangan VARCHAR(255) NOT NULL DEFAULT '',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_mutasi_pakan_user (user_id, jenis),
  CONSTRAINT fk_mutasi_pakan_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
