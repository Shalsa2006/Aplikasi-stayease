// Helper respons & error yang konsisten: { success, message, data }
class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const ok = (res, data, message = 'OK', status = 200) =>
  res.status(status).json({ success: true, message, data });

// Membungkus handler async agar error otomatis diteruskan ke error handler
const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

const isValidDate = (s) => /^\d{4}-\d{2}-\d{2}$/.test(s) && !Number.isNaN(Date.parse(s));

const nightsBetween = (checkIn, checkOut) =>
  Math.round((Date.parse(checkOut) - Date.parse(checkIn)) / 86400000);

const todayStr = () => {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};

module.exports = { ApiError, ok, asyncHandler, isValidDate, nightsBetween, todayStr };
