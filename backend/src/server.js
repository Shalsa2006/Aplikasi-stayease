require('dotenv').config();
const app = require('./app');
const pool = require('./config/db');

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    await pool.query('SELECT 1');
    console.log('✔ Terhubung ke database MySQL (Laragon)');
  } catch (err) {
    console.error('✖ Gagal konek database. Pastikan MySQL Laragon sudah "Start All" dan schema.sql sudah diimpor.');
    console.error('  ', err.message);
  }
  // 0.0.0.0 agar bisa diakses dari HP/emulator di jaringan yang sama
  app.listen(PORT, '0.0.0.0', () => console.log(`🚀 StayEase API berjalan di http://localhost:${PORT}`));
})();
