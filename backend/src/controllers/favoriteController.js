const pool = require('../config/db');
const { ApiError, ok, asyncHandler } = require('../utils/http');

// GET /api/favorites  -> daftar hotel yang disukai user
exports.list = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT h.*,
       (SELECT MIN(r.price_per_night) FROM rooms r WHERE r.hotel_id = h.id) AS min_price,
       (SELECT AVG(rv.rating) FROM reviews rv WHERE rv.hotel_id = h.id) AS rating,
       (SELECT COUNT(*) FROM reviews rv WHERE rv.hotel_id = h.id) AS review_count
     FROM favorites f JOIN hotels h ON h.id = f.hotel_id
     WHERE f.user_id = ?
     ORDER BY f.created_at DESC`, [req.user.id]);
  ok(res, rows.map((h) => ({
    ...h,
    facilities: h.facilities ? h.facilities.split(',').map((x) => x.trim()) : [],
    rating: h.rating !== null ? Number(Number(h.rating).toFixed(1)) : null,
    review_count: Number(h.review_count || 0),
    min_price: Number(h.min_price || 0),
  })));
});

// POST /api/hotels/:id/favorite
exports.add = asyncHandler(async (req, res) => {
  const [h] = await pool.query('SELECT id FROM hotels WHERE id = ?', [req.params.id]);
  if (!h.length) throw new ApiError(404, 'Hotel tidak ditemukan');
  await pool.query('INSERT IGNORE INTO favorites (user_id, hotel_id) VALUES (?, ?)', [req.user.id, req.params.id]);
  ok(res, { hotel_id: Number(req.params.id), is_favorite: true }, 'Ditambahkan ke Disukai', 201);
});

// DELETE /api/hotels/:id/favorite
exports.remove = asyncHandler(async (req, res) => {
  await pool.query('DELETE FROM favorites WHERE user_id = ? AND hotel_id = ?', [req.user.id, req.params.id]);
  ok(res, { hotel_id: Number(req.params.id), is_favorite: false }, 'Dihapus dari Disukai');
});
