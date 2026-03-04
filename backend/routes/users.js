'use strict';
const express = require('express');
const { z }   = require('zod');
const pool    = require('../db/pool');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

const UpdateSchema = z.object({
  displayName: z.string().max(60).optional(),
  bio:         z.string().max(280).optional(),
  avatarUrl:   z.string().url().optional().nullable(),
  isPublic:    z.boolean().optional(),
});

// GET /users/me
router.get('/me', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, username, email, display_name, bio, avatar_url, is_public, created_at
       FROM users WHERE id = $1`,
      [req.user.id],
    );
    if (!rows[0]) return res.status(404).json({ error: 'User not found.' });
    return res.json(rows[0]);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// PUT /users/me
router.put('/me', requireAuth, async (req, res) => {
  const parsed = UpdateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const { displayName, bio, avatarUrl, isPublic } = parsed.data;
  try {
    const { rows } = await pool.query(
      `UPDATE users
       SET display_name = COALESCE($1, display_name),
           bio          = COALESCE($2, bio),
           avatar_url   = COALESCE($3, avatar_url),
           is_public    = COALESCE($4, is_public)
       WHERE id = $5
       RETURNING id, username, email, display_name, bio, avatar_url, is_public, created_at`,
      [displayName, bio, avatarUrl, isPublic, req.user.id],
    );
    return res.json(rows[0]);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// GET /users/:id — visible if profile is public OR requester is in same group
router.get('/:id', requireAuth, async (req, res) => {
  const targetId = req.params.id;
  try {
    // Fetch target user
    const { rows } = await pool.query(
      `SELECT id, username, display_name, bio, avatar_url, is_public, created_at
       FROM users WHERE id = $1`,
      [targetId],
    );
    const target = rows[0];
    if (!target) return res.status(404).json({ error: 'User not found.' });

    // Owner can always see themselves
    if (targetId === req.user.id) return res.json(target);

    // Public profile: always visible
    if (target.is_public) return res.json(target);

    // Check shared group membership
    const { rows: shared } = await pool.query(
      `SELECT 1 FROM group_members gm1
       JOIN group_members gm2 ON gm1.group_id = gm2.group_id
       WHERE gm1.user_id = $1 AND gm2.user_id = $2
       LIMIT 1`,
      [req.user.id, targetId],
    );
    if (shared.length > 0) return res.json(target);

    return res.status(403).json({ error: 'Profile is private.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

module.exports = router;
