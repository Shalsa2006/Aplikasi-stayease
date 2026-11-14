const pool = require('../config/db');
const { ApiError, ok, asyncHandler, isValidDate, todayStr } = require('../utils/http');

const HOTEL_FIELDS = ['name', 'city', 'address', 'description', 'star', 'image_url', 'facilities', 'latitude', 'longitude'];
const ROOM_FIELDS = ['hotel_id', 'type', 'description', 'price_per_night', 'capacity', 'total_rooms', 'image_url'];

const pick = (body, fields) => {
  const out = {};
  for (const f of fields) if (body[f] !== undefined) out[f] = Array.isArray(body[f]) ? body[f].join(',') : body[f];
  return out;
};

// ----- Hotels -----
exports.createHotel = asyncHandler(async (req, res) => {
  const data = pick(req.body, HOTEL_FIELDS);
  if (!data.name || !data.city || !data.address) throw new ApiError(400, 'name, city, address wajib diisi');
  const [r] = await pool.query('INSERT INTO hotels SET ?', [data]);
  ok(res, { id: r.insertId, ...data }, 'Hotel ditambahkan', 201);
});

exports.updateHotel = asyncHandler(async (req, res) => {
  const data = pick(req.body, HOTEL_FIELDS);
  if (!Object.keys(data).length) throw new ApiError(400, 'Tidak ada data yang diubah');
  const [r] = await pool.query('UPDATE hotels SET ? WHERE id = ?', [data, req.params.id]);
  if (!r.affectedRows) throw new ApiError(404, 'Hotel tidak ditemukan');
  ok(res, null, 'Hotel diperbarui');
});

exports.deleteHotel = asyncHandler(async (req, res) => {
  const [r] = await pool.query('DELETE FROM hotels WHERE id = ?', [req.params.id]);
  if (!r.affectedRows) throw new ApiError(404, 'Hotel tidak ditemukan');
  ok(res, null, 'Hotel dihapus');
});

// ----- Rooms -----
exports.createRoom = asyncHandler(async (req, res) => {
  const data = pick(req.body, ROOM_FIELDS);
  if (!data.hotel_id || !data.type || !data.price_per_night) throw new ApiError(400, 'hotel_id, type, price_per_night wajib diisi');
  const [r] = await pool.query('INSERT INTO rooms SET ?', [data]);
  ok(res, { id: r.insertId, ...data }, 'Kamar ditambahkan', 201);
});

exports.updateRoom = asyncHandler(async (req, res) => {
  const data = pick(req.body, ROOM_FIELDS);
  if (!Object.keys(data).length) throw new ApiError(400, 'Tidak ada data yang diubah');
  const [r] = await pool.query('UPDATE rooms SET ? WHERE id = ?', [data, req.params.id]);
  if (!r.affectedRows) throw new ApiError(404, 'Kamar tidak ditemukan');
  ok(res, null, 'Kamar diperbarui');
});

exports.deleteRoom = asyncHandler(async (req, res) => {
  const [r] = await pool.query('DELETE FROM rooms WHERE id = ?', [req.params.id]);
  if (!r.affectedRows) throw new ApiError(404, 'Kamar tidak ditemukan');
  ok(res, null, 'Kamar dihapus');
});

// ----- Bookings & dashboard -----
const ADMIN_BOOKING_SELECT = `
  SELECT b.*, u.name AS user_name, u.email AS user_email,
         r.type AS room_type, r.price_per_night, r.image_url AS room_image, r.total_rooms,
         h.id AS hotel_id, h.name AS hotel_name, h.city AS hotel_city, h.address AS hotel_address, h.image_url AS hotel_image,
         (SELECT COUNT(*) FROM reviews rv WHERE rv.booking_id = b.id) AS has_review
  FROM bookings b
  JOIN users u ON u.id = b.user_id
  JOIN rooms r ON r.id = b.room_id
  JOIN hotels h ON h.id = r.hotel_id`;

const mapAdminBooking = (b) => ({ ...b, has_review: Number(b.has_review) > 0 });

// GET /api/admin/bookings?status=&q=&hotel_id=
exports.allBookings = asyncHandler(async (req, res) => {
  const { status, q, hotel_id } = req.query;
  const where = [];
  const params = [];
  if (status) { where.push('b.status = ?'); params.push(status); }
  if (hotel_id) { where.push('h.id = ?'); params.push(hotel_id); }
  if (q) {
    where.push('(b.booking_code LIKE ? OR b.guest_name LIKE ? OR u.email LIKE ? OR h.name LIKE ?)');
    params.push(`%${q}%`, `%${q}%`, `%${q}%`, `%${q}%`);
  }
  const [rows] = await pool.query(
    `${ADMIN_BOOKING_SELECT} ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY b.created_at DESC LIMIT 300`,
    params);
  ok(res, rows.map(mapAdminBooking));
});

exports.updateBookingStatus = asyncHandler(async (req, res) => {
  const { status } = req.body;
  if (!['pending', 'paid', 'cancelled', 'completed'].includes(status)) throw new ApiError(400, 'Status tidak valid');
  const [r] = await pool.query(
    "UPDATE bookings SET status = ?, paid_at = IF(? = 'paid' AND paid_at IS NULL, NOW(), paid_at) WHERE id = ?",
    [status, status, req.params.id]);
  if (!r.affectedRows) throw new ApiError(404, 'Booking tidak ditemukan');
  const [rows] = await pool.query(`${ADMIN_BOOKING_SELECT} WHERE b.id = ?`, [req.params.id]);
  ok(res, mapAdminBooking(rows[0]), 'Status booking diperbarui');
});

// GET /api/admin/rooms/booked?date=YYYY-MM-DD
// Kamar yang terpesan pada tanggal tertentu (booking pending/paid yang menginap di malam itu)
exports.bookedRooms = asyncHandler(async (req, res) => {
  const date = isValidDate(req.query.date) ? req.query.date : todayStr();
  const [rooms] = await pool.query(
    `SELECT r.id, r.type, r.total_rooms, r.price_per_night, r.image_url,
            h.id AS hotel_id, h.name AS hotel_name, h.city AS hotel_city
     FROM rooms r JOIN hotels h ON h.id = r.hotel_id
     ORDER BY h.city, h.name, r.price_per_night`);
  const [bookings] = await pool.query(
    `SELECT b.id, b.booking_code, b.room_id, b.rooms, b.guests, b.guest_name, b.guest_phone,
            b.check_in, b.check_out, b.status, u.email AS user_email
     FROM bookings b JOIN users u ON u.id = b.user_id
     WHERE b.status IN ('pending','paid') AND b.check_in <= ? AND b.check_out > ?
     ORDER BY b.check_in`, [date, date]);

  const byRoom = new Map();
  for (const b of bookings) {
    if (!byRoom.has(b.room_id)) byRoom.set(b.room_id, []);
    byRoom.get(b.room_id).push(b);
  }
  const data = rooms.map((r) => {
    const list = byRoom.get(r.id) || [];
    const booked = list.reduce((sum, b) => sum + Number(b.rooms), 0);
    return { ...r, booked, available: Math.max(0, r.total_rooms - booked), bookings: list };
  });
  const totalRooms = data.reduce((s2, r) => s2 + r.total_rooms, 0);
  const totalBooked = data.reduce((s2, r) => s2 + r.booked, 0);
  ok(res, { date, total_rooms: totalRooms, total_booked: totalBooked, rooms: data });
});

// GET /api/admin/reviews?rating=
exports.allReviews = asyncHandler(async (req, res) => {
  const params = [];
  let filter = '';
  if (req.query.rating) { filter = 'WHERE rv.rating = ?'; params.push(Number(req.query.rating)); }
  const [rows] = await pool.query(
    `SELECT rv.id, rv.rating, rv.comment, rv.created_at, rv.hotel_id,
            u.name AS user_name, u.email AS user_email, h.name AS hotel_name, h.city AS hotel_city,
            b.booking_code, r.type AS room_type
     FROM reviews rv
     JOIN users u ON u.id = rv.user_id
     JOIN hotels h ON h.id = rv.hotel_id
     JOIN bookings b ON b.id = rv.booking_id
     JOIN rooms r ON r.id = b.room_id
     ${filter}
     ORDER BY rv.created_at DESC LIMIT 300`, params);
  ok(res, rows);
});

// DELETE /api/admin/reviews/:id
exports.deleteReview = asyncHandler(async (req, res) => {
  const [r] = await pool.query('DELETE FROM reviews WHERE id = ?', [req.params.id]);
  if (!r.affectedRows) throw new ApiError(404, 'Ulasan tidak ditemukan');
  ok(res, null, 'Ulasan dihapus');
});

exports.stats = asyncHandler(async (req, res) => {
  const today = todayStr();
  const [[s]] = await pool.query(`
    SELECT
      (SELECT COUNT(*) FROM hotels) AS hotels,
      (SELECT COUNT(*) FROM rooms) AS room_types,
      (SELECT COALESCE(SUM(total_rooms),0) FROM rooms) AS total_rooms,
      (SELECT COUNT(*) FROM users WHERE role = 'user') AS users,
      (SELECT COUNT(*) FROM bookings) AS bookings,
      (SELECT COUNT(*) FROM bookings WHERE status = 'pending') AS pending,
      (SELECT COUNT(*) FROM bookings WHERE status = 'paid') AS paid,
      (SELECT COALESCE(SUM(COALESCE(payment_amount,total_price)),0) FROM bookings WHERE status IN ('paid','completed')) AS revenue,
      (SELECT COALESCE(SUM(rooms),0) FROM bookings WHERE status IN ('pending','paid') AND check_in <= ? AND check_out > ?) AS booked_today,
      (SELECT COUNT(*) FROM reviews) AS reviews,
      (SELECT AVG(rating) FROM reviews) AS avg_rating`, [today, today]);
  const [recent] = await pool.query(`${ADMIN_BOOKING_SELECT} ORDER BY b.created_at DESC LIMIT 5`);
  const [cities] = await pool.query(
    `SELECT h.city, COUNT(DISTINCT h.id) AS hotels, COUNT(b.id) AS bookings
     FROM hotels h LEFT JOIN rooms r ON r.hotel_id = h.id
     LEFT JOIN bookings b ON b.room_id = r.id AND b.status IN ('paid','completed')
     GROUP BY h.city ORDER BY bookings DESC, h.city`);
  const num = (v) => Number(v || 0);
  ok(res, {
    hotels: num(s.hotels), room_types: num(s.room_types), total_rooms: num(s.total_rooms), users: num(s.users),
    bookings: num(s.bookings), pending: num(s.pending), paid: num(s.paid), revenue: num(s.revenue),
    booked_today: num(s.booked_today), reviews: num(s.reviews),
    avg_rating: s.avg_rating === null ? null : Number(Number(s.avg_rating).toFixed(1)),
    cities: cities.map((c) => ({ city: c.city, hotels: num(c.hotels), bookings: num(c.bookings) })),
    recent_bookings: recent.map(mapAdminBooking),
  });
});
