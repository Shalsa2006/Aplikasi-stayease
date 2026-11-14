const pool = require('../config/db');
const { ApiError, ok, asyncHandler, isValidDate, nightsBetween, todayStr } = require('../utils/http');

const generateCode = () => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let s = '';
  for (let i = 0; i < 6; i++) s += chars[Math.floor(Math.random() * chars.length)];
  return `SE-${s}`;
};

const BOOKING_SELECT = `
  SELECT b.*, r.type AS room_type, r.price_per_night, r.image_url AS room_image,
         h.id AS hotel_id, h.name AS hotel_name, h.city AS hotel_city, h.address AS hotel_address,
         h.image_url AS hotel_image,
         (SELECT COUNT(*) FROM reviews rv WHERE rv.booking_id = b.id) AS has_review
  FROM bookings b
  JOIN rooms r  ON r.id = b.room_id
  JOIN hotels h ON h.id = r.hotel_id`;

const mapBooking = (b) => ({ ...b, has_review: Number(b.has_review) > 0 });

// POST /api/bookings
exports.create = asyncHandler(async (req, res) => {
  const { room_id, check_in, check_out, guests = 1, rooms: roomQty = 1, guest_name, guest_phone, notes } = req.body;
  const qty = Number(roomQty);
  if (!Number.isInteger(qty) || qty < 1 || qty > 10) throw new ApiError(400, 'Jumlah kamar harus 1 - 10');

  if (!room_id || !guest_name || !guest_phone) throw new ApiError(400, 'room_id, nama tamu, dan no. HP wajib diisi');
  if (!isValidDate(check_in) || !isValidDate(check_out)) throw new ApiError(400, 'Format tanggal harus YYYY-MM-DD');
  if (check_in < todayStr()) throw new ApiError(400, 'Tanggal check-in tidak boleh di masa lalu');
  if (check_out <= check_in) throw new ApiError(400, 'Check-out harus setelah check-in');
  const nights = nightsBetween(check_in, check_out);
  if (nights > 30) throw new ApiError(400, 'Maksimal menginap 30 malam');

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Kunci baris kamar agar dua pemesanan bersamaan tidak melebihi stok (mencegah overbooking)
    const [rooms] = await conn.query('SELECT * FROM rooms WHERE id = ? FOR UPDATE', [room_id]);
    const room = rooms[0];
    if (!room) throw new ApiError(404, 'Kamar tidak ditemukan');
    if (Number(guests) > room.capacity * qty) {
      throw new ApiError(400, `${qty} kamar maksimal untuk ${room.capacity * qty} orang`);
    }

    const [[{ used }]] = await conn.query(
      `SELECT COALESCE(SUM(rooms), 0) AS used FROM bookings
       WHERE room_id = ? AND status IN ('pending','paid') AND check_in < ? AND check_out > ?`,
      [room_id, check_out, check_in]);
    const left = room.total_rooms - Number(used);
    if (left < qty) {
      throw new ApiError(409, left <= 0 ? 'Maaf, kamar sudah penuh pada tanggal tersebut' : `Maaf, hanya tersisa ${left} kamar`);
    }

    // Total otomatis = harga per malam x jumlah malam x jumlah kamar
    const total = nights * room.price_per_night * qty;
    const [result] = await conn.query(
      `INSERT INTO bookings (booking_code, user_id, room_id, check_in, check_out, guests, rooms, nights, total_price, guest_name, guest_phone, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [generateCode(), req.user.id, room_id, check_in, check_out, Number(guests), qty, nights, total, guest_name, guest_phone, notes || null]);

    await conn.commit();
    const [rows] = await pool.query(`${BOOKING_SELECT} WHERE b.id = ?`, [result.insertId]);
    ok(res, mapBooking(rows[0]), 'Pemesanan berhasil dibuat, silakan lakukan pembayaran', 201);
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
});

// GET /api/bookings?status=
exports.myBookings = asyncHandler(async (req, res) => {
  const params = [req.user.id];
  let filter = '';
  if (req.query.status) { filter = 'AND b.status = ?'; params.push(req.query.status); }
  const [rows] = await pool.query(`${BOOKING_SELECT} WHERE b.user_id = ? ${filter} ORDER BY b.created_at DESC`, params);
  ok(res, rows.map(mapBooking));
});

const findOwned = async (id, user) => {
  const [rows] = await pool.query(`${BOOKING_SELECT} WHERE b.id = ?`, [id]);
  const b = rows[0];
  if (!b || (b.user_id !== user.id && user.role !== 'admin')) throw new ApiError(404, 'Booking tidak ditemukan');
  return b;
};

// GET /api/bookings/:id
exports.detail = asyncHandler(async (req, res) => {
  ok(res, mapBooking(await findOwned(req.params.id, req.user)));
});

// ---------- PEMBAYARAN (simulasi) ----------
// Biaya layanan: VA flat Rp 4.000, QRIS 0,7% (MDR) dibulatkan ke atas.
const BANKS = { BCA: '39012', BNI: '8810', BRI: '26215', MANDIRI: '89508' };
const serviceFee = (method, total) => (method === 'va' ? 4000 : Math.ceil(total * 0.007));

const randomDigits = (n) => Array.from({ length: n }, () => Math.floor(Math.random() * 10)).join('');

// POST /api/bookings/:id/payment  { method: 'va' | 'qris', bank?: 'BCA'|'BNI'|'BRI'|'MANDIRI' }
// Membuat tagihan: nomor Virtual Account atau kode QRIS + jumlah yang harus dibayar (berlaku 24 jam).
exports.createPayment = asyncHandler(async (req, res) => {
  const b = await findOwned(req.params.id, req.user);
  if (b.status !== 'pending') throw new ApiError(400, `Booking berstatus ${b.status}, tidak bisa dibayar`);

  const method = String(req.body.method || '').toLowerCase();
  if (!['va', 'qris'].includes(method)) throw new ApiError(400, "Metode harus 'va' atau 'qris'");

  let bank = null;
  let vaNumber = null;
  let qrisRef = null;
  if (method === 'va') {
    bank = String(req.body.bank || '').toUpperCase();
    if (!BANKS[bank]) throw new ApiError(400, 'Bank harus BCA, BNI, BRI, atau MANDIRI');
    // Nomor VA = kode perusahaan bank + 4 digit akhir no. HP + 6 digit acak
    const phoneTail = String(b.guest_phone).replace(/\D/g, '').slice(-4).padStart(4, '0');
    vaNumber = `${BANKS[bank]}${phoneTail}${randomDigits(6)}`;
  } else {
    qrisRef = `QRIS${Date.now()}${randomDigits(4)}`;
  }

  const fee = serviceFee(method, b.total_price);
  await pool.query(
    `UPDATE bookings SET payment_method = ?, payment_bank = ?, va_number = ?, qris_ref = ?,
       service_fee = ?, payment_amount = ?, payment_expires_at = DATE_ADD(NOW(), INTERVAL 24 HOUR)
     WHERE id = ?`,
    [method, bank, vaNumber, qrisRef, fee, b.total_price + fee, b.id]);
  ok(res, mapBooking(await findOwned(b.id, req.user)), 'Tagihan pembayaran dibuat');
});

// PATCH /api/bookings/:id/pay  (simulasi: anggap uang sudah masuk, lalu terbitkan bukti pembayaran)
exports.pay = asyncHandler(async (req, res) => {
  const b = await findOwned(req.params.id, req.user);
  if (b.status !== 'pending') throw new ApiError(400, `Booking berstatus ${b.status}, tidak bisa dibayar`);
  if (!b.payment_method) throw new ApiError(400, 'Pilih metode pembayaran terlebih dahulu');
  if (b.payment_expires_at && new Date(b.payment_expires_at) < new Date()) {
    throw new ApiError(400, 'Tagihan sudah kedaluwarsa, silakan buat tagihan baru');
  }

  const d = new Date();
  const ymd = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
  const receipt = `INV/${ymd}/${b.payment_method.toUpperCase()}/${b.id}${randomDigits(4)}`;
  await pool.query("UPDATE bookings SET status = 'paid', paid_at = NOW(), receipt_number = ? WHERE id = ?", [receipt, b.id]);
  ok(res, mapBooking(await findOwned(b.id, req.user)), 'Pembayaran berhasil');
});

// PATCH /api/bookings/:id/cancel
exports.cancel = asyncHandler(async (req, res) => {
  const b = await findOwned(req.params.id, req.user);
  if (!['pending', 'paid'].includes(b.status)) throw new ApiError(400, 'Booking ini tidak dapat dibatalkan');
  if (b.check_in <= todayStr()) throw new ApiError(400, 'Pembatalan hanya bisa sebelum tanggal check-in');
  await pool.query("UPDATE bookings SET status = 'cancelled' WHERE id = ?", [b.id]);
  ok(res, mapBooking(await findOwned(b.id, req.user)), 'Booking dibatalkan');
});
