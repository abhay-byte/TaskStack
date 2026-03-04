'use strict';
const express  = require('express');
const bcrypt   = require('bcrypt');
const jwt      = require('jsonwebtoken');
const { z }    = require('zod');
const pool     = require('../db/pool');

const router = express.Router();

const RegisterSchema = z.object({
  username:    z.string().min(3).max(30).regex(/^[a-zA-Z0-9_]+$/),
  email:       z.string().email(),
  password:    z.string().min(8).max(128),
  displayName: z.string().max(60).optional(),
});

const LoginSchema = z.object({
  email:    z.string().email(),
  password: z.string(),
});

function signToken(user) {
  return jwt.sign(
    { sub: user.id, username: user.username, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: '7d' },
  );
}

// POST /auth/register
router.post('/register', async (req, res) => {
  const parsed = RegisterSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { username, email, password, displayName } = parsed.data;

  try {
    const hash = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS || '12', 10));

    const result = await pool.query(
      `INSERT INTO users (username, email, password_hash, display_name)
       VALUES ($1, $2, $3, $4)
       RETURNING id, username, email, display_name, is_public, created_at`,
      [username, email, hash, displayName ?? username],
    );

    const user = result.rows[0];
    return res.status(201).json({ token: signToken(user), user: sanitize(user) });
  } catch (err) {
    if (err.code === '23505') {
      const field = err.constraint?.includes('email') ? 'email' : 'username';
      return res.status(409).json({ error: `${field} already taken.` });
    }
    console.error('Register error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// POST /auth/login
router.post('/login', async (req, res) => {
  const parsed = LoginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { email, password } = parsed.data;

  try {
    const result = await pool.query(
      'SELECT id, username, email, password_hash, display_name, is_public, created_at FROM users WHERE email = $1',
      [email],
    );

    const user = result.rows[0];
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    return res.json({ token: signToken(user), user: sanitize(user) });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// Strip password_hash before sending to client
function sanitize(u) {
  const { password_hash, ...safe } = u;
  return safe;
}

module.exports = router;
