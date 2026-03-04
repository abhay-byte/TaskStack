'use strict';
const express = require('express');
const pool    = require('../db/pool');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// GET /invites — Check my pending invites
router.get('/', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT i.id, i.status, i.created_at,
              g.id AS group_id, g.name AS group_name,
              u.id AS inviter_id, u.username AS inviter_username
       FROM group_invites i
       JOIN groups g ON i.group_id = g.id
       JOIN users u ON i.invited_by = u.id
       WHERE i.invited_user_id = $1 AND i.status = 'pending'
       ORDER BY i.created_at DESC`,
      [req.user.id],
    );
    return res.json(rows);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// POST /invites/:id/accept
router.post('/:id/accept', requireAuth, async (req, res) => {
  const inviteId = req.params.id;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Fetch and lock invite
    const { rows: inviteRows } = await client.query(
      `SELECT group_id FROM group_invites
       WHERE id = $1 AND invited_user_id = $2 AND status = 'pending'
       FOR UPDATE`,
      [inviteId, req.user.id],
    );

    if (inviteRows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Invite not found, expired, or already processed.' });
    }

    const groupId = inviteRows[0].group_id;

    // Check if already a member somehow
    const { rows: memberRows } = await client.query(
      'SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2',
      [groupId, req.user.id],
    );

    if (memberRows.length === 0) {
      // Add member
      await client.query(
        `INSERT INTO group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`,
        [groupId, req.user.id],
      );
    }

    // Mark accepted
    await client.query(
      `UPDATE group_invites SET status = 'accepted' WHERE id = $1`,
      [inviteId],
    );

    await client.query('COMMIT');
    return res.json({ success: true, group_id: groupId });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
});

// POST /invites/:id/reject
router.post('/:id/reject', requireAuth, async (req, res) => {
  const inviteId = req.params.id;
  try {
    const { rowCount } = await pool.query(
      `UPDATE group_invites 
       SET status = 'rejected' 
       WHERE id = $1 AND invited_user_id = $2 AND status = 'pending'`,
      [inviteId, req.user.id],
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Invite not found or already processed.' });
    }

    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

module.exports = router;
