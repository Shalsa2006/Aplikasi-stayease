// Membuat akun contoh (password di-hash dengan bcrypt) + pesanan & ulasan contoh
// supaya setiap hotel sudah punya rating.
// Jalankan setelah schema.sql diimpor:  npm run seed
require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('../src/config/db');

const users = [
  { name: 'Admin StayEase', email: 'admin@stayease.id', password: 'admin123', phone: '081200000001', role: 'admin' },
  { name: 'Budi Santoso', email: 'budi@mail.com', password: 'user123', phone: '081200000002', role: 'user' },
  { name: 'Siti Rahma', email: 'siti@mail.com', password: 'user123', phone: '081200000003', role: 'user' },
  { name: 'Andi Pratama', email: 'andi@mail.com', password: 'user123', phone: '081200000004', role: 'user' },
  { name: 'Rina Wulandari', email: 'rina@mail.com', password: 'user123', phone: '081200000005', role: 'user' },
  { name: 'Dewi Lestari', email: 'dewi@mail.com', password: 'user123', phone: '081200000006', role: 'user' },
];

const comments = {
  5: ['Luar biasa! Kamar bersih, staf sangat ramah.', 'Pemandangannya indah, pasti balik lagi.', 'Sarapannya enak dan lengkap, recommended!'],
  4: ['Nyaman dan lokasinya strategis.', 'Kamar rapi, check-in cepat. Worth it.', 'Bagus, hanya parkir agak sempit.'],
  3: ['Cukup oke untuk harganya.', 'Kamar bersih tapi AC agak berisik.'],
  2: ['WiFi sering putus, kamar mandi kurang bersih.'],
};

const pad = (n) => String(n).padStart(2, '0');
const dateStr = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

(async () => {
  try {
    for (const u of users) {
      const hash = await bcrypt.hash(u.password, 10);
      await pool.query(
        `INSERT INTO users (name, email, password, phone, role) VALUES (?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE name = VALUES(name), password = VALUES(password), role = VALUES(role)`,
        [u.name, u.email, hash, u.phone, u.role]
      );
      console.log(`✔ ${u.role.padEnd(5)} ${u.email} / ${u.password}`);
    }

    // Ulasan contoh hanya dibuat sekali (saat tabel reviews masih kosong)
    const [[{ total }]] = await pool.query('SELECT COUNT(*) AS total FROM reviews');
    if (Number(total) > 0) {
      console.log('• Ulasan contoh sudah ada, dilewati');
      return;
    }

    const [guests] = await pool.query("SELECT id, name, phone FROM users WHERE role = 'user' ORDER BY id");
    const [rooms] = await pool.query('SELECT id, hotel_id, price_per_night FROM rooms ORDER BY hotel_id, id');
    const firstRoomOfHotel = new Map();
    for (const r of rooms) if (!firstRoomOfHotel.has(r.hotel_id)) firstRoomOfHotel.set(r.hotel_id, r);

    let count = 0;
    let seq = 1;
    for (const [hotelId, room] of firstRoomOfHotel) {
      // 2–3 ulasan per hotel dari tamu yang berbeda
      const n = 2 + (hotelId % 2);
      for (let k = 0; k < n; k++) {
        const g = guests[(hotelId + k) % guests.length];
        const rating = [5, 4, 5, 3, 4, 5, 2, 4][(hotelId * 3 + k) % 8];
        const list = comments[rating];
        const checkIn = new Date();
        checkIn.setDate(checkIn.getDate() - (10 + hotelId + k * 7));
        const checkOut = new Date(checkIn);
        checkOut.setDate(checkOut.getDate() + 2);

        const code = `SE-DEMO${String(seq++).padStart(3, '0')}`;
        const [b] = await pool.query(
          `INSERT INTO bookings (booking_code, user_id, room_id, check_in, check_out, guests, rooms, nights, total_price,
             guest_name, guest_phone, status, paid_at, payment_method, payment_bank, va_number, service_fee, payment_amount, receipt_number)
           VALUES (?, ?, ?, ?, ?, 2, 1, 2, ?, ?, ?, 'completed', ?, 'va', 'BCA', ?, 4000, ?, ?)`,
          [code, g.id, room.id, dateStr(checkIn), dateStr(checkOut), room.price_per_night * 2, g.name, g.phone,
            `${dateStr(checkIn)} 10:00:00`, `39012${String(g.phone).slice(-4)}${String(100000 + seq)}`,
            room.price_per_night * 2 + 4000, `INV/DEMO/VA/${seq}`]
        );
        await pool.query('INSERT INTO reviews (booking_id, user_id, hotel_id, rating, comment) VALUES (?, ?, ?, ?, ?)',
          [b.insertId, g.id, hotelId, rating, list[(hotelId + k) % list.length]]);
        count++;
      }
    }
    console.log(`✔ ${count} pesanan selesai + ulasan contoh dibuat`);
  } catch (err) {
    console.error('Seed gagal:', err.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
})();
