const jwt = require('jsonwebtoken');
const { ApiError } = require('../utils/http');

// Memastikan request membawa header: Authorization: Bearer <token>
function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(new ApiError(401, 'Token tidak ditemukan, silakan login'));
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    next(new ApiError(401, 'Token tidak valid atau kedaluwarsa'));
  }
}

function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') return next(new ApiError(403, 'Akses khusus admin'));
  next();
}

module.exports = { authenticate, requireAdmin };
