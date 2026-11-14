const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { ApiError, ok, asyncHandler } = require('../utils/http');

const signToken = (user) =>
  jwt.sign({ id: user.id, email: user.email, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

const publicUser = ({ password, ...rest }) => rest;

exports.register = asyncHandler(async (req, res) => {
  const { name, email, password, phone } = req.body;
  if (!name || !email || !password) throw new ApiError(400, 'Nama, email, dan password wajib diisi');
  if (!/^\S+@\S+\.\S+$/.test(email)) throw new ApiError(400, 'Format email tidak valid');
  if (password.length < 6) throw new ApiError(400, 'Password minimal 6 karakter');

  const [exist] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
  if (exist.length) throw new ApiError(409, 'Email sudah terdaftar');

  const hash = await bcrypt.hash(password, 10);
  const [result] = await pool.query(
    'INSERT INTO users (name, email, password, phone) VALUES (?, ?, ?, ?)',
    [name.trim(), email.toLowerCase(), hash, phone || null]
  );
  const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [result.insertId]);
  const user = rows[0];
  ok(res, { token: signToken(user), user: publicUser(user) }, 'Registrasi berhasil', 201);
});

exports.login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) throw new ApiError(400, 'Email dan password wajib diisi');

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
  const user = rows[0];
  if (!user || !(await bcrypt.compare(password, user.password))) {
    throw new ApiError(401, 'Email atau password salah');
  }
  ok(res, { token: signToken(user), user: publicUser(user) }, 'Login berhasil');
});

exports.me = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    'SELECT id, name, email, phone, role, created_at FROM users WHERE id = ?',
    [req.user.id]
  );
  if (!rows.length) throw new ApiError(404, 'User tidak ditemukan');
  ok(res, rows[0]);
});

exports.updateMe = asyncHandler(async (req, res) => {
  const { name, phone, password } = req.body;
  if (!name) throw new ApiError(400, 'Nama wajib diisi');
  if (password) {
    if (password.length < 6) throw new ApiError(400, 'Password minimal 6 karakter');
    const hash = await bcrypt.hash(password, 10);
    await pool.query('UPDATE users SET name = ?, phone = ?, password = ? WHERE id = ?', [name, phone || null, hash, req.user.id]);
  } else {
    await pool.query('UPDATE users SET name = ?, phone = ? WHERE id = ?', [name, phone || null, req.user.id]);
  }
  const [rows] = await pool.query('SELECT id, name, email, phone, role, created_at FROM users WHERE id = ?', [req.user.id]);
  ok(res, rows[0], 'Profil diperbarui');
});
