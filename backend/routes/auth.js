'use strict';
const express    = require('express');
const bcrypt     = require('bcrypt');
const jwt        = require('jsonwebtoken');
const { z }      = require('zod');
const pool       = require('../db/pool');
const { requireAuth } = require('../middleware/auth');

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

// GET /auth/delete-account  — public info page (no auth required)
// Linked from Google Play Store as the account-deletion URL.
router.get('/delete-account', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Delete Your TaskStack Account</title>
  <style>
    body{font-family:system-ui,sans-serif;max-width:640px;margin:40px auto;padding:0 20px;color:#1a1a1a;line-height:1.6}
    h1{color:#c0392b}h2{color:#333;margin-top:2rem}
    ul{padding-left:1.4rem}li{margin-bottom:.5rem}
    .warn{background:#fff3cd;border-left:4px solid #f0ad4e;padding:12px 16px;border-radius:4px}
    .steps{background:#f0f4ff;border-left:4px solid #4a6cf7;padding:12px 16px;border-radius:4px}
    footer{margin-top:3rem;font-size:.85rem;color:#666}
  </style>
</head>
<body>
  <h1>Delete Your TaskStack Account</h1>
  <p>You can permanently delete your TaskStack account and all associated data at any time, directly from within the app or by contacting us.</p>

  <h2>How to Delete Your Account In-App</h2>
  <div class="steps">
    <ol>
      <li>Open the <strong>TaskStack</strong> app and sign in.</li>
      <li>Tap the <strong>Settings</strong> tab (bottom navigation bar).</li>
      <li>Scroll to the bottom and tap <strong>"Delete Account"</strong>.</li>
      <li>Confirm the deletion in the dialog that appears.</li>
    </ol>
  </div>

  <h2>What Data Is Deleted</h2>
  <ul>
    <li>Your account profile (username, email, display name, bio, avatar).</li>
    <li>All your tasks and goals stored on our servers.</li>
    <li>Your group memberships and any pending invites.</li>
  </ul>

  <h2>What Data Is Retained</h2>
  <ul>
    <li>Local task data stored on your device is <strong>not</strong> affected and must be cleared manually via your device settings.</li>
    <li>Aggregate, anonymised analytics data (if any) that cannot be linked back to you.</li>
  </ul>

  <div class="warn">
    <strong>⚠ This action is irreversible.</strong> All cloud data is permanently deleted immediately with no recovery period.
  </div>

  <h2>Alternative: Contact Us</h2>
  <p>If you cannot access the app, email us at <a href="mailto:abhay02delhi@gmail.com">abhay02delhi@gmail.com</a> with the subject <em>"Account Deletion Request"</em> and include your registered email address. We will process your request within 7 days.</p>

  <footer>TaskStack &mdash; developed by abhay-byte &bull; <a href="https://taskstack-api.onrender.com">taskstack-api.onrender.com</a></footer>
</body>
</html>`);
});

// DELETE /auth/account — permanently delete the authenticated user + all data
router.delete('/account', requireAuth, async (req, res) => {
  const userId = req.user.id;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // Delete in dependency order (tasks, goals, group memberships, invites, then user)
    await client.query('DELETE FROM tasks  WHERE user_id = $1', [userId]);
    await client.query('DELETE FROM goals  WHERE user_id = $1', [userId]);
    await client.query('DELETE FROM group_members WHERE user_id = $1', [userId]);
    await client.query('DELETE FROM invites WHERE invitee_id = $1 OR inviter_id = $1', [userId]);
    await client.query('DELETE FROM users  WHERE id = $1', [userId]);
    await client.query('COMMIT');
    return res.json({ deleted: true });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Delete account error:', err);
    return res.status(500).json({ error: 'Failed to delete account. Please try again.' });
  } finally {
    client.release();
  }
});

module.exports = router;
