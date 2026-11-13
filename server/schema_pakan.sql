-- =====================================================================
-- Tambahan: STOK PAKAN (gudang bersama)
-- Jalankan sekali di phpMyAdmin: database appsmobi_db_maggot → tab SQL
-- → tempel isi file ini → Go. Aman dijalankan ulang.
-- Pakan keluar = tabel `pakan` (catatan pemberian pakan) yang sudah ada.
-- =====================================================================
SET NAMES utf8mb4;

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
