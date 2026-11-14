const pool = require('../config/db');
const { ApiError, ok, asyncHandler, isValidDate, nightsBetween } = require('../utils/http');

// Statuses yang "memakan" kamar
const ACTIVE = "('pending','paid')";

const mapHotel = (h) => ({
  ...h,
  facilities: h.facilities ? h.facilities.split(',').map((f) => f.trim()) : [],
  rating: h.rating !== null && h.rating !== undefined ? Number(Number(h.rating).toFixed(1)) : null,
  review_count: Number(h.review_count || 0),
  min_price: h.min_price !== undefined ? Number(h.min_price) : undefined,
});

// GET /api/hotels?q=&city=&min_price=&max_price=&guests=&sort=price_asc|price_desc|rating
exports.list = asyncHandler(async (req, res) => {
  // include_empty=1 -> hotel yang belum punya kamar ikut tampil (untuk admin)
  const { q, city, min_price, max_price, guests, sort } = req.query;
  const where = [];
  const params = [];

  if (q) { where.push('(h.name LIKE ? OR h.city LIKE ? OR h.address LIKE ?)'); params.push(`%${q}%`, `%${q}%`, `%${q}%`); }
  if (city) { where.push('h.city = ?'); params.push(city); }

  const having = [];
  if (min_price) { having.push('min_price >= ?'); }
  if (max_price) { having.push('min_price <= ?'); }

  const roomFilter = guests ? 'AND r.capacity >= ?' : '';
  const orderBy = { price_asc: 'min_price ASC', price_desc: 'min_price DESC', rating: 'rating DESC' }[sort] || 'h.id ASC';

  const sql = `
    SELECT h.*,
      (SELECT MIN(r.price_per_night) FROM rooms r WHERE r.hotel_id = h.id ${roomFilter}) AS min_price,
      (SELECT AVG(rv.rating) FROM reviews rv WHERE rv.hotel_id = h.id) AS rating,
      (SELECT COUNT(*) FROM reviews rv WHERE rv.hotel_id = h.id) AS review_count
    FROM hotels h
    ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
    HAVING ${req.query.include_empty ? '1=1' : 'min_price IS NOT NULL'} ${having.length ? 'AND ' + having.join(' AND ') : ''}
    ORDER BY ${orderBy}`;

  const finalParams = [...(guests ? [Number(guests)] : []), ...params];
  if (min_price) finalParams.push(Number(min_price));
  if (max_price) finalParams.push(Number(max_price));

  const [rows] = await pool.query(sql, finalParams);
  ok(res, rows.map(mapHotel));
});

// GET /api/hotels/cities
exports.cities = asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT city, COUNT(*) AS total FROM hotels GROUP BY city ORDER BY city');
  ok(res, rows);
});

// GET /api/hotels/:id?check_in=&check_out=  (ketersediaan per kamar ikut dihitung jika tanggal dikirim)
exports.detail = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { check_in, check_out } = req.query;

  const [hotels] = await pool.query(
    `SELECT h.*,
       (SELECT AVG(rating) FROM reviews WHERE hotel_id = h.id) AS rating,
       (SELECT COUNT(*) FROM reviews WHERE hotel_id = h.id) AS review_count
     FROM hotels h WHERE h.id = ?`, [id]);
  if (!hotels.length) throw new ApiError(404, 'Hotel tidak ditemukan');

  let rooms;
  if (check_in && check_out && isValidDate(check_in) && isValidDate(check_out) && check_out > check_in) {
    [rooms] = await pool.query(
      `SELECT r.*, r.total_rooms - (
          SELECT COALESCE(SUM(b.rooms), 0) FROM bookings b
          WHERE b.room_id = r.id AND b.status IN ${ACTIVE}
            AND b.check_in < ? AND b.check_out > ?
        ) AS available
       FROM rooms r WHERE r.hotel_id = ? ORDER BY r.price_per_night`,
      [check_out, check_in, id]);
  } else {
    [rooms] = await pool.query('SELECT r.*, NULL AS available FROM rooms r WHERE r.hotel_id = ? ORDER BY r.price_per_night', [id]);
  }

  const [reviews] = await pool.query(
    `SELECT rv.id, rv.rating, rv.comment, rv.created_at, u.name AS user_name
     FROM reviews rv JOIN users u ON u.id = rv.user_id
     WHERE rv.hotel_id = ? ORDER BY rv.created_at DESC LIMIT 20`, [id]);

  // Jumlah ulasan per bintang (untuk grafik rating di aplikasi)
  const [dist] = await pool.query('SELECT rating, COUNT(*) AS total FROM reviews WHERE hotel_id = ? GROUP BY rating', [id]);
  const rating_breakdown = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  for (const d of dist) rating_breakdown[d.rating] = Number(d.total);

  ok(res, {
    ...mapHotel(hotels[0]),
    rating_breakdown,
    rooms: rooms.map((r) => ({ ...r, available: r.available === null ? null : Math.max(0, Number(r.available)) })),
    reviews,
  });
});

// GET /api/rooms/:id/availability?check_in=&check_out=
exports.roomAvailability = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { check_in, check_out } = req.query;
  if (!isValidDate(check_in) || !isValidDate(check_out) || check_out <= check_in) {
    throw new ApiError(400, 'Tanggal check-in/check-out tidak valid');
  }
  const [rooms] = await pool.query('SELECT * FROM rooms WHERE id = ?', [id]);
  if (!rooms.length) throw new ApiError(404, 'Kamar tidak ditemukan');
  const room = rooms[0];

  const [[{ used }]] = await pool.query(
    `SELECT COALESCE(SUM(rooms), 0) AS used FROM bookings
     WHERE room_id = ? AND status IN ${ACTIVE} AND check_in < ? AND check_out > ?`,
    [id, check_out, check_in]);

  const nights = nightsBetween(check_in, check_out);
  const available = Math.max(0, room.total_rooms - Number(used));
  ok(res, { room_id: room.id, check_in, check_out, nights, available, is_available: available > 0, total_price: nights * room.price_per_night });
});

// POST /api/hotels/:id/reviews  { booking_id, rating, comment }
exports.addReview = asyncHandler(async (req, res) => {
  const hotelId = Number(req.params.id);
  const { booking_id, rating, comment } = req.body;
  const r = Number(rating);
  if (!booking_id || !(r >= 1 && r <= 5)) throw new ApiError(400, 'booking_id dan rating (1-5) wajib diisi');

  const [rows] = await pool.query(
    `SELECT b.*, rm.hotel_id FROM bookings b JOIN rooms rm ON rm.id = b.room_id
     WHERE b.id = ? AND b.user_id = ?`, [booking_id, req.user.id]);
  const booking = rows[0];
  if (!booking || booking.hotel_id !== hotelId) throw new ApiError(404, 'Booking tidak ditemukan untuk hotel ini');
  if (!['paid', 'completed'].includes(booking.status)) throw new ApiError(400, 'Ulasan hanya untuk booking yang sudah dibayar');

  try {
    await pool.query('INSERT INTO reviews (booking_id, user_id, hotel_id, rating, comment) VALUES (?, ?, ?, ?, ?)',
      [booking_id, req.user.id, hotelId, r, comment || null]);
  } catch (e) {
    if (e.code === 'ER_DUP_ENTRY') throw new ApiError(409, 'Booking ini sudah diberi ulasan');
    throw e;
  }
  ok(res, null, 'Terima kasih atas ulasan Anda', 201);
});

// GET /api/reviews/me  -> ulasan yang pernah ditulis user
exports.myReviews = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT rv.id, rv.rating, rv.comment, rv.created_at, rv.hotel_id, rv.booking_id,
            h.name AS hotel_name, h.city AS hotel_city, h.image_url AS hotel_image, r.type AS room_type
     FROM reviews rv
     JOIN hotels h ON h.id = rv.hotel_id
     JOIN bookings b ON b.id = rv.booking_id
     JOIN rooms r ON r.id = b.room_id
     WHERE rv.user_id = ? ORDER BY rv.created_at DESC`, [req.user.id]);
  ok(res, rows);
});
