// =====================================================================
// API MaggotKu
// Semua rahasia (password DB, JWT secret) dibaca dari Environment
// Variables di cPanel → Setup Node.js App. JANGAN ditulis di file ini.
// =====================================================================
const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const env = process.env;
const JWT_SECRET = env.JWT_SECRET;
const PUBLIC_URL = (env.PUBLIC_URL ||
  'https://appsmobiledeveloper.my.id/api-maggot').replace(/\/$/, '');

if (!JWT_SECRET || !env.DB_USER || !env.DB_PASS) {
  console.error('❌ ENV belum lengkap: DB_USER, DB_PASS, JWT_SECRET wajib diisi');
}

process.on('uncaughtException', (err) => console.error('❌ UNCAUGHT:', err));
process.on('unhandledRejection', (err) => console.error('❌ REJECTION:', err));

const app = express();
console.log('🐛 API MAGGOT START...');

// Hosting meneruskan request dengan awalan /api-maggot → buang awalannya.
app.use((req, res, next) => {
  if (req.url.startsWith('/api-maggot')) {
    req.url = req.url.replace('/api-maggot', '') || '/';
  }
  next();
});
app.use(express.json({ limit: '1mb' }));

// =====================================================================
// DATABASE
// =====================================================================
const db = mysql.createPool({
  host: env.DB_HOST || 'localhost',
  user: env.DB_USER,
  password: env.DB_PASS,
  database: env.DB_NAME || 'appsmobi_db_maggot',
  waitForConnections: true,
  connectionLimit: 10,
  dateStrings: true, // tanggal dikirim apa adanya, tanpa geser zona waktu
  decimalNumbers: true, // DECIMAL → number
});

db.getConnection()
  .then((c) => {
    console.log('✅ DATABASE CONNECTED');
    c.release();
  })
  .catch((e) => console.error('❌ DB ERROR:', e.message));

// =====================================================================
// KONSTANTA (harus sama dengan aplikasi)
// =====================================================================
const PRODUK = ['Maggot segar', 'Maggot kering', 'Pupa', 'Telur', 'Kasgot (pupuk)'];
const PRODUK_PANEN = ['Maggot segar', 'Pupa', 'Telur', 'Kasgot (pupuk)'];
const TUJUAN = ['fresh', 'kering', 'perkawinan'];
const MUTASI_JENIS = ['penyesuaian', 'olah', 'tebar'];
const JENIS_PAKAN = ['Sisa sayur', 'Ampas tahu', 'Kulit buah', 'Dedak', 'Bungkil sawit', 'Lainnya'];
const satuan = (p) => (p === 'Telur' ? 'g' : 'kg');

// =====================================================================
// HELPER
// =====================================================================
class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}
const wrap = (fn) => (req, res, next) => fn(req, res, next).catch(next);

const pad = (n) => String(n).padStart(2, '0');
const nowStr = () => {
  const d = new Date();
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
};

/** "2026-11-12", "2026-11-12T10:00:00.000" → "2026-11-12 10:00:00" */
const DT = /^\d{4}-\d{2}-\d{2}([ T]\d{2}:\d{2}(:\d{2}(\.\d+)?)?)?$/;
function toDt(v) {
  if (typeof v !== 'string' || !DT.test(v)) return undefined;
  const s = v.replace('T', ' ').slice(0, 19);
  if (s.length === 10) return `${s} 00:00:00`;
  if (s.length === 16) return `${s}:00`;
  return s;
}

/**
 * Validasi body sesuai spesifikasi kolom.
 * partial = true untuk PUT (kolom yang tidak dikirim dibiarkan).
 */
function parseBody(body, spec, partial = false) {
  const out = {};
  for (const [k, f] of Object.entries(spec)) {
    let v = body ? body[k] : undefined;
    if (v === undefined && partial) continue;
    if (v === undefined || v === null || v === '') {
      if (f.required) throw new HttpError(400, `${f.label || k} wajib diisi`);
      out[k] = f.default !== undefined ? f.default
        : f.type === 'bool' ? 0 : f.type === 'str' ? '' : null;
      continue;
    }
    switch (f.type) {
      case 'str':
        if (typeof v !== 'string') throw new HttpError(400, `${k} harus teks`);
        v = v.trim();
        if (f.required && !v) throw new HttpError(400, `${f.label || k} wajib diisi`);
        if (v.length > (f.max || 255)) throw new HttpError(400, `${k} terlalu panjang`);
        break;
      case 'num':
        v = Number(v);
        if (!Number.isFinite(v)) throw new HttpError(400, `${k} harus angka`);
        if (f.positive && v <= 0) throw new HttpError(400, `${k} harus lebih dari 0`);
        if (f.nonzero && v === 0) throw new HttpError(400, `${k} tidak boleh 0`);
        break;
      case 'int':
        v = Number(v);
        if (!Number.isInteger(v)) throw new HttpError(400, `${k} tidak valid`);
        break;
      case 'date':
        v = toDt(v);
        if (!v) throw new HttpError(400, `${k} harus tanggal (YYYY-MM-DD)`);
        break;
      case 'bool':
        v = v === true || v === 1 || v === '1' || v === 'true' ? 1 : 0;
        break;
      case 'enum':
        if (!f.values.includes(v)) {
          throw new HttpError(400, `${k} harus salah satu: ${f.values.join(', ')}`);
        }
        break;
    }
    out[k] = v;
  }
  return out;
}

/** Pastikan id relasi (kandang_id, budidaya_id) milik user ini. */
async function cekRelasi(conn, userId, spec, data) {
  for (const [k, f] of Object.entries(spec)) {
    if (!f.ref || data[k] == null) continue;
    const [rows] = await conn.query(
      `SELECT id FROM ${f.ref} WHERE id = ? AND user_id = ?`,
      [data[k], userId],
    );
    if (!rows.length) throw new HttpError(400, `${f.ref} tidak ditemukan`);
  }
}

// =====================================================================
// STOK = panen + mutasi − penjualan (dihitung, bukan disimpan)
// =====================================================================
async function stokMap(conn, userId) {
  const [rows] = await conn.query(
    `SELECT produk, ROUND(SUM(j), 3) AS stok FROM (
       SELECT produk, jumlah AS j FROM panen WHERE user_id = ?
       UNION ALL SELECT produk, jumlah FROM mutasi_stok WHERE user_id = ?
       UNION ALL SELECT produk, -jumlah FROM penjualan WHERE user_id = ?
     ) t GROUP BY produk`,
    [userId, userId, userId],
  );
  const map = Object.fromEntries(PRODUK.map((p) => [p, 0]));
  for (const r of rows) map[r.produk] = Number(r.stok);
  return map;
}

/**
 * Jalankan perubahan data dalam transaksi.
 * cekStok = true: data user dikunci (antre per user), lalu ditolak bila
 * perubahan membuat stok suatu produk turun di bawah 0.
 */
async function tx(userId, cekStok, fn) {
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();
    let before;
    if (cekStok) {
      await conn.query('SELECT id FROM users WHERE id = ? FOR UPDATE', [userId]);
      before = await stokMap(conn, userId);
    }
    const result = await fn(conn);
    if (cekStok) {
      const after = await stokMap(conn, userId);
      for (const p of PRODUK) {
        if (after[p] < -0.0005 && after[p] < before[p] - 0.0005) {
          const sisa = Math.max(before[p], 0);
          throw new HttpError(400, `Stok ${p} tidak cukup (tersisa ${sisa} ${satuan(p)})`);
        }
      }
    }
    await conn.commit();
    return result;
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}

// =====================================================================
// AUTH (JWT)
// =====================================================================
function sign(userId) {
  if (!JWT_SECRET) {
    throw new HttpError(500, 'Server belum dikonfigurasi: JWT_SECRET belum diisi');
  }
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: '30d' });
}

function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Silakan login dulu' });
  try {
    req.userId = jwt.verify(token, JWT_SECRET).sub;
    next();
  } catch {
    res.status(401).json({ error: 'Sesi berakhir, silakan login lagi' });
  }
}

// Batasi percobaan login: maks 10 kali gagal / 15 menit per IP+email.
const loginGagal = new Map();
const LIMIT = 10;
const JEDA = 15 * 60 * 1000;
function cekLimit(key) {
  const r = loginGagal.get(key);
  if (r && r.sampai > Date.now() && r.n >= LIMIT) {
    throw new HttpError(429, 'Terlalu banyak percobaan. Coba lagi 15 menit lagi.');
  }
}
function catatGagal(key) {
  const r = loginGagal.get(key);
  if (!r || r.sampai < Date.now()) loginGagal.set(key, { n: 1, sampai: Date.now() + JEDA });
  else r.n += 1;
}

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const publicUser = (u) => ({
  id: u.id,
  name: u.name,
  email: u.email,
  farm_name: u.farm_name,
  photo_url: u.photo_url || null,
  created_at: u.created_at,
});

const register = wrap(async (req, res) => {
  const d = parseBody(req.body, {
    name: { type: 'str', required: true, max: 100, label: 'Nama' },
    email: { type: 'str', required: true, max: 150, label: 'Email' },
    password: { type: 'str', required: true, max: 100, label: 'Password' },
    farm_name: { type: 'str', max: 150 },
  });
  d.email = d.email.toLowerCase();
  if (!EMAIL.test(d.email)) throw new HttpError(400, 'Format email tidak valid');
  if (d.password.length < 6) throw new HttpError(400, 'Password minimal 6 karakter');

  const [ada] = await db.query('SELECT id FROM users WHERE email = ?', [d.email]);
  if (ada.length) throw new HttpError(400, 'Email sudah terdaftar');

  const hash = await bcrypt.hash(d.password, 10);
  const [r] = await db.query(
    'INSERT INTO users (name, email, password, farm_name) VALUES (?, ?, ?, ?)',
    [d.name, d.email, hash, d.farm_name || ''],
  );
  const [[u]] = await db.query('SELECT * FROM users WHERE id = ?', [r.insertId]);
  res.status(201).json({ message: 'Register berhasil', token: sign(u.id), user: publicUser(u) });
});

const login = wrap(async (req, res) => {
  const email = String(req.body?.email || '').trim().toLowerCase();
  const password = String(req.body?.password || '');
  if (!email || !password) throw new HttpError(400, 'Email & password wajib diisi');

  const key = `${req.ip}|${email}`;
  cekLimit(key);
  const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
  const u = rows[0];
  if (!u || !(await bcrypt.compare(password, u.password))) {
    catatGagal(key);
    // Pesan disamakan agar tidak membocorkan email mana yang terdaftar.
    throw new HttpError(400, 'Email atau password salah');
  }
  loginGagal.delete(key);
  res.json({ message: 'Login berhasil', token: sign(u.id), user: publicUser(u) });
});

app.post('/auth/register', register);
app.post('/auth/login', login);
// Alamat lama tetap jalan
app.post('/register', register);
app.post('/login', login);

app.get('/me', auth, wrap(async (req, res) => {
  const [[u]] = await db.query('SELECT * FROM users WHERE id = ?', [req.userId]);
  if (!u) throw new HttpError(404, 'User tidak ditemukan');
  res.json({ data: publicUser(u) });
}));

app.put('/me', auth, wrap(async (req, res) => {
  const d = parseBody(req.body, {
    name: { type: 'str', max: 100 },
    email: { type: 'str', max: 150 },
    farm_name: { type: 'str', max: 150 },
    password: { type: 'str', max: 100 },
    current_password: { type: 'str', max: 100 },
  }, true);
  const [[u]] = await db.query('SELECT * FROM users WHERE id = ?', [req.userId]);
  if (!u) throw new HttpError(404, 'User tidak ditemukan');

  const set = {};
  if (d.name) set.name = d.name;
  if (d.farm_name !== undefined) set.farm_name = d.farm_name;
  if (d.email) {
    const email = d.email.toLowerCase();
    if (!EMAIL.test(email)) throw new HttpError(400, 'Format email tidak valid');
    const [ada] = await db.query(
      'SELECT id FROM users WHERE email = ? AND id <> ?', [email, u.id],
    );
    if (ada.length) throw new HttpError(400, 'Email sudah dipakai akun lain');
    set.email = email;
  }
  if (d.password) {
    // Ganti password wajib menyertakan password lama.
    if (!d.current_password || !(await bcrypt.compare(d.current_password, u.password))) {
      throw new HttpError(400, 'Password lama salah');
    }
    if (d.password.length < 6) throw new HttpError(400, 'Password minimal 6 karakter');
    set.password = await bcrypt.hash(d.password, 10);
  }
  if (Object.keys(set).length) {
    await db.query('UPDATE users SET ?, updated_at = NOW() WHERE id = ?', [set, u.id]);
  }
  const [[baru]] = await db.query('SELECT * FROM users WHERE id = ?', [u.id]);
  res.json({ message: 'Profil diperbarui', data: publicUser(baru) });
}));

// =====================================================================
// CRUD DATA BUDIDAYA
// =====================================================================
const catatan = { type: 'str', max: 1000 };
const RES = {
  kandang: {
    spec: {
      nama: { type: 'str', required: true, max: 100, label: 'Nama kandang' },
      lokasi: { type: 'str', required: true, max: 150, label: 'Lokasi' },
      kapasitas: { type: 'num' },
      catatan,
    },
  },
  budidaya: {
    spec: {
      kandang_id: { type: 'int', required: true, ref: 'kandang', label: 'Kandang' },
      nama: { type: 'str', required: true, max: 100, label: 'Nama batch' },
      tujuan: { type: 'enum', values: TUJUAN, default: 'fresh' },
      mulai: { type: 'date', required: true, label: 'Tanggal mulai' },
      berat_awal: { type: 'num' },
      perkiraan_panen: { type: 'date' },
      catatan,
      selesai: { type: 'bool' },
    },
    bools: ['selesai'],
    filter: ['kandang_id', 'selesai'],
    cekStok: true, // bisa mengurangi stok telur (tebar)
    // POST boleh menyertakan telur_gram → stok telur berkurang.
    async afterCreate(conn, userId, id, body, data) {
      const g = Number(body?.telur_gram || 0);
      if (g > 0) {
        await conn.query('INSERT INTO mutasi_stok SET ?', {
          user_id: userId,
          tanggal: data.mulai,
          produk: 'Telur',
          jumlah: -g,
          jenis: 'tebar',
          keterangan: `Ditebar ke ${data.nama}`,
        });
      }
    },
  },
  pakan: {
    spec: {
      budidaya_id: { type: 'int', required: true, ref: 'budidaya', label: 'Batch' },
      tanggal: { type: 'date', required: true, label: 'Tanggal' },
      jenis: { type: 'enum', values: JENIS_PAKAN, required: true, label: 'Jenis pakan' },
      berat: { type: 'num', required: true, positive: true, label: 'Berat' },
      catatan,
    },
    filter: ['budidaya_id'],
  },
  panen: {
    spec: {
      budidaya_id: { type: 'int', required: true, ref: 'budidaya', label: 'Batch' },
      tanggal: { type: 'date', required: true, label: 'Tanggal' },
      produk: { type: 'enum', values: PRODUK_PANEN, required: true, label: 'Produk' },
      jumlah: { type: 'num', required: true, positive: true, label: 'Jumlah' },
      catatan,
    },
    filter: ['budidaya_id', 'produk'],
    cekStok: true, // edit/hapus panen yang sudah terjual ditolak
  },
  penjualan: {
    spec: {
      tanggal: { type: 'date', required: true, label: 'Tanggal' },
      pembeli: { type: 'str', required: true, max: 100, label: 'Pembeli' },
      produk: { type: 'enum', values: PRODUK, required: true, label: 'Produk' },
      jumlah: { type: 'num', required: true, positive: true, label: 'Jumlah' },
      harga: { type: 'num', required: true, positive: true, label: 'Harga' },
      lunas: { type: 'bool', default: 1 },
      catatan,
    },
    bools: ['lunas'],
    filter: ['produk', 'lunas'],
    cekStok: true, // tidak bisa menjual melebihi stok
  },
  // Stok pakan gudang: pakan masuk (+) & penyesuaian (busuk −, stok awal +).
  // Pakan keluar = catatan /pakan. Kurang stok tidak diblokir (aplikasi
  // hanya memberi peringatan), sesuai keputusan pemilik usaha.
  'mutasi-pakan': {
    table: 'mutasi_pakan',
    spec: {
      tanggal: { type: 'date', required: true, label: 'Tanggal' },
      jenis: { type: 'enum', values: JENIS_PAKAN, required: true, label: 'Jenis pakan' },
      jumlah: { type: 'num', required: true, nonzero: true, label: 'Jumlah' },
      tipe: { type: 'enum', values: ['masuk', 'penyesuaian'], default: 'masuk' },
      harga: { type: 'num' },
      keterangan: { type: 'str', max: 255 },
    },
    filter: ['jenis', 'tipe'],
    check(d) {
      if (d.tipe === 'masuk' && d.jumlah !== undefined && d.jumlah <= 0) {
        throw new HttpError(400, 'Jumlah pakan masuk harus lebih dari 0');
      }
      if (d.harga != null && d.harga < 0) throw new HttpError(400, 'Harga tidak boleh minus');
    },
  },
  mutasi: {
    table: 'mutasi_stok',
    spec: {
      tanggal: { type: 'date', required: true, label: 'Tanggal' },
      produk: { type: 'enum', values: PRODUK, required: true, label: 'Produk' },
      jumlah: { type: 'num', required: true, nonzero: true, label: 'Jumlah' },
      jenis: { type: 'enum', values: MUTASI_JENIS, default: 'penyesuaian' },
      keterangan: { type: 'str', max: 255 },
    },
    filter: ['produk', 'jenis'],
    cekStok: true,
  },
};

function keluar(row, r) {
  if (!row) return row;
  const o = { ...row };
  delete o.user_id;
  for (const b of r.bools || []) o[b] = !!o[b];
  return o;
}

for (const [name, r] of Object.entries(RES)) {
  const table = r.table || name;

  // Daftar (bisa difilter, mis. /panen?budidaya_id=3)
  app.get(`/${name}`, auth, wrap(async (req, res) => {
    let sql = `SELECT * FROM ${table} WHERE user_id = ?`;
    const p = [req.userId];
    for (const f of r.filter || []) {
      if (req.query[f] !== undefined) {
        sql += ` AND ${f} = ?`;
        p.push(req.query[f] === 'true' ? 1 : req.query[f] === 'false' ? 0 : req.query[f]);
      }
    }
    sql += ' ORDER BY id DESC';
    const [rows] = await db.query(sql, p);
    res.json({ data: rows.map((x) => keluar(x, r)) });
  }));

  app.get(`/${name}/:id`, auth, wrap(async (req, res) => {
    const [[row]] = await db.query(
      `SELECT * FROM ${table} WHERE id = ? AND user_id = ?`, [req.params.id, req.userId],
    );
    if (!row) throw new HttpError(404, 'Data tidak ditemukan');
    res.json({ data: keluar(row, r) });
  }));

  app.post(`/${name}`, auth, wrap(async (req, res) => {
    const data = parseBody(req.body, r.spec);
    if (r.check) r.check(data);
    const row = await tx(req.userId, r.cekStok, async (conn) => {
      await cekRelasi(conn, req.userId, r.spec, data);
      const [ins] = await conn.query(`INSERT INTO ${table} SET ?`, {
        ...data, user_id: req.userId,
      });
      if (r.afterCreate) await r.afterCreate(conn, req.userId, ins.insertId, req.body, data);
      const [[baru]] = await conn.query(`SELECT * FROM ${table} WHERE id = ?`, [ins.insertId]);
      return baru;
    });
    res.status(201).json({ data: keluar(row, r) });
  }));

  app.put(`/${name}/:id`, auth, wrap(async (req, res) => {
    const data = parseBody(req.body, r.spec, true);
    if (r.check) r.check(data);
    const row = await tx(req.userId, r.cekStok, async (conn) => {
      const [[lama]] = await conn.query(
        `SELECT id FROM ${table} WHERE id = ? AND user_id = ?`, [req.params.id, req.userId],
      );
      if (!lama) throw new HttpError(404, 'Data tidak ditemukan');
      await cekRelasi(conn, req.userId, r.spec, data);
      if (Object.keys(data).length) {
        await conn.query(`UPDATE ${table} SET ? WHERE id = ?`, [data, req.params.id]);
      }
      const [[baru]] = await conn.query(`SELECT * FROM ${table} WHERE id = ?`, [req.params.id]);
      return baru;
    });
    res.json({ data: keluar(row, r) });
  }));

  app.delete(`/${name}/:id`, auth, wrap(async (req, res) => {
    let fileFoto = [];
    await tx(req.userId, r.cekStok || name === 'budidaya', async (conn) => {
      const [[lama]] = await conn.query(
        `SELECT id FROM ${table} WHERE id = ? AND user_id = ?`, [req.params.id, req.userId],
      );
      if (!lama) throw new HttpError(404, 'Data tidak ditemukan');
      if (name === 'budidaya') {
        const [f] = await conn.query('SELECT file FROM foto WHERE budidaya_id = ?', [lama.id]);
        fileFoto = f.map((x) => x.file);
      }
      await conn.query(`DELETE FROM ${table} WHERE id = ?`, [lama.id]);
    });
    fileFoto.forEach(hapusFile);
    res.json({ message: 'Data dihapus' });
  }));
}

// =====================================================================
// STOK & OLAH
// =====================================================================
app.get('/stok', auth, wrap(async (req, res) => {
  const map = await stokMap(db, req.userId);
  res.json({
    data: PRODUK.map((p) => ({ produk: p, stok: map[p], satuan: satuan(p) })),
  });
}));

// Olah maggot fresh → maggot kering (dua mutasi sekaligus)
app.post('/olah', auth, wrap(async (req, res) => {
  const d = parseBody(req.body, {
    fresh: { type: 'num', required: true, positive: true, label: 'Berat fresh' },
    kering: { type: 'num', required: true, positive: true, label: 'Hasil kering' },
    tanggal: { type: 'date', default: nowStr() },
  });
  if (d.kering > d.fresh) throw new HttpError(400, 'Hasil kering tidak bisa melebihi berat fresh');
  const ket = `Olah ${d.fresh} kg fresh → ${d.kering} kg kering`;
  await tx(req.userId, true, async (conn) => {
    await conn.query('INSERT INTO mutasi_stok SET ?', {
      user_id: req.userId, tanggal: d.tanggal, produk: 'Maggot segar',
      jumlah: -d.fresh, jenis: 'olah', keterangan: ket,
    });
    await conn.query('INSERT INTO mutasi_stok SET ?', {
      user_id: req.userId, tanggal: d.tanggal, produk: 'Maggot kering',
      jumlah: d.kering, jenis: 'olah', keterangan: ket,
    });
  });
  res.status(201).json({ message: ket, data: await stokMap(db, req.userId) });
}));

// =====================================================================
// FOTO (upload ke folder uploads/)
// =====================================================================
const UPLOAD_DIR = path.join(__dirname, 'uploads');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });
const EXT = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' };

const upload = multer({
  storage: multer.diskStorage({
    destination: UPLOAD_DIR,
    filename: (req, file, cb) =>
      cb(null, crypto.randomBytes(16).toString('hex') + EXT[file.mimetype]),
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => cb(null, !!EXT[file.mimetype]),
});

function hapusFile(name) {
  if (!name || name.includes('/') || name.includes('\\')) return;
  fs.unlink(path.join(UPLOAD_DIR, name), () => {});
}
const fotoKeluar = (f) => {
  const o = { ...f, url: `${PUBLIC_URL}/uploads/${f.file}` };
  delete o.user_id;
  return o;
};

// Nama file acak & panjang, jadi tidak bisa ditebak.
app.use('/uploads', express.static(UPLOAD_DIR, { maxAge: '30d', index: false }));

app.post('/foto', auth, upload.single('foto'), wrap(async (req, res) => {
  if (!req.file) throw new HttpError(400, 'File foto wajib (jpg/png/webp, maks 5 MB)');
  try {
    const d = parseBody(req.body, {
      budidaya_id: { type: 'int', required: true, ref: 'budidaya', label: 'Batch' },
      tanggal: { type: 'date', default: nowStr() },
      catatan: { type: 'str', max: 255 },
    });
    await cekRelasi(db, req.userId, { budidaya_id: { ref: 'budidaya' } }, d);
    const [ins] = await db.query('INSERT INTO foto SET ?', {
      ...d, user_id: req.userId, file: req.file.filename,
    });
    const [[f]] = await db.query('SELECT * FROM foto WHERE id = ?', [ins.insertId]);
    res.status(201).json({ data: fotoKeluar(f) });
  } catch (e) {
    hapusFile(req.file.filename);
    throw e;
  }
}));

app.get('/foto', auth, wrap(async (req, res) => {
  let sql = 'SELECT * FROM foto WHERE user_id = ?';
  const p = [req.userId];
  if (req.query.budidaya_id) {
    sql += ' AND budidaya_id = ?';
    p.push(req.query.budidaya_id);
  }
  const [rows] = await db.query(`${sql} ORDER BY tanggal DESC, id DESC`, p);
  res.json({ data: rows.map(fotoKeluar) });
}));

app.delete('/foto/:id', auth, wrap(async (req, res) => {
  const [[f]] = await db.query(
    'SELECT * FROM foto WHERE id = ? AND user_id = ?', [req.params.id, req.userId],
  );
  if (!f) throw new HttpError(404, 'Foto tidak ditemukan');
  await db.query('DELETE FROM foto WHERE id = ?', [f.id]);
  hapusFile(f.file);
  res.json({ message: 'Foto dihapus' });
}));

// =====================================================================
// CEK SERVER
// =====================================================================
app.get('/', (req, res) => res.send('API MAGGOT 🐛'));

app.get('/test', wrap(async (req, res) => {
  let database = 'ok';
  let stokPakan = 'ok';
  try {
    await db.query('SELECT 1');
    try {
      await db.query('SELECT 1 FROM mutasi_pakan LIMIT 1');
    } catch {
      stokPakan = 'tabel mutasi_pakan belum dibuat (jalankan schema_pakan.sql)';
    }
  } catch {
    database = 'error';
  }
  res.json({
    message: 'Halo dari API maggot 🐛',
    database,
    jwt: JWT_SECRET && JWT_SECRET.length >= 16 ? 'ok' : 'JWT_SECRET belum diisi / terlalu pendek',
    stokPakan,
    waktu: new Date(),
  });
}));

// =====================================================================
// FALLBACK & ERROR
// =====================================================================
app.use((req, res) => {
  res.status(404).json({ error: 'Route tidak ditemukan', path: req.url });
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
  if (err instanceof multer.MulterError) {
    return res.status(400).json({
      error: err.code === 'LIMIT_FILE_SIZE' ? 'Ukuran foto maksimal 5 MB' : err.message,
    });
  }
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Format JSON tidak valid' });
  }
  if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.code === 'ER_ROW_IS_REFERENCED') {
    return res.status(400).json({
      error: 'Data masih dipakai data lain (mis. kandang yang masih punya batch)',
    });
  }
  console.error('❌ ERROR:', err);
  res.status(500).json({ error: 'Terjadi kesalahan di server' });
});

app.listen(env.PORT || 3000, '0.0.0.0', () => {
  console.log(`✅ SERVER RUNNING ON PORT ${env.PORT || 3000}`);
});
