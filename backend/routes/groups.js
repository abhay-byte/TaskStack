'use strict';
const express = require('express');
const { z }   = require('zod');
const QRCode  = require('qrcode');
const pool    = require('../db/pool');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

const CreateGroupSchema = z.object({
  name:        z.string().min(1).max(100),
  description: z.string().max(500).optional(),
});

// GET /groups — list my groups
router.get('/', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT g.id, g.name, g.description, g.invite_code, g.created_at, gm.role, gm.joined_at
       FROM groups g
       JOIN group_members gm ON g.id = gm.group_id
       WHERE gm.user_id = $1
       ORDER BY g.created_at DESC`,
      [req.user.id],
    );
    return res.json(rows);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// POST /groups — create a group
router.post('/', requireAuth, async (req, res) => {
  const parsed = CreateGroupSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const { name, description } = parsed.data;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Insert group
    const { rows } = await client.query(
      `INSERT INTO groups (name, description, created_by)
       VALUES ($1, $2, $3)
       RETURNING id, name, description, invite_code, created_at`,
      [name, description, req.user.id],
    );
    const group = rows[0];

    // Add creator as owner
    await client.query(
      `INSERT INTO group_members (group_id, user_id, role)
       VALUES ($1, $2, 'owner')`,
      [group.id, req.user.id],
    );

    await client.query('COMMIT');
    return res.status(201).json(group);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
});

// GET /groups/:id — get group details + members
router.get('/:id', requireAuth, async (req, res) => {
  const groupId = req.params.id;
  try {
    // Ensure user is member
    const { rows: membership } = await pool.query(
      'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2',
      [groupId, req.user.id],
    );
    if (membership.length === 0) return res.status(403).json({ error: 'Not a member of this group.' });

    // Get group
    const { rows: groupRows } = await pool.query(
      'SELECT id, name, description, invite_code, created_at FROM groups WHERE id = $1',
      [groupId],
    );
    const group = groupRows[0];

    // Get members
    const { rows: members } = await pool.query(
      `SELECT u.id, u.username, u.display_name, u.avatar_url, gm.role, gm.joined_at
       FROM group_members gm
       JOIN users u ON gm.user_id = u.id
       WHERE gm.group_id = $1
       ORDER BY gm.joined_at ASC`,
      [groupId],
    );

    group.members = members;
    return res.json(group);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// GET /groups/:id/qr — Generate QR code image (base64) for invite_code
router.get('/:id/qr', requireAuth, async (req, res) => {
  const groupId = req.params.id;
  try {
    const { rows } = await pool.query(
      `SELECT g.invite_code 
       FROM groups g 
       JOIN group_members gm ON g.id = gm.group_id 
       WHERE g.id = $1 AND gm.user_id = $2`,
      [groupId, req.user.id],
    );
    if (rows.length === 0) return res.status(403).json({ error: 'Not a member.' });

    const code = rows[0].invite_code;
    const qrDataUrl = await QRCode.toDataURL(`taskstack://join?code=${code}`, {
      errorCorrectionLevel: 'M',
      margin: 2,
    });
    
    return res.json({ invite_code: code, qr_base64: qrDataUrl });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// POST /groups/join — Join via invite_code
router.post('/join', requireAuth, async (req, res) => {
  const inviteCode = req.body.invite_code;
  if (!inviteCode) return res.status(400).json({ error: 'invite_code is required.' });

  try {
    const { rows: groupRows } = await pool.query('SELECT id FROM groups WHERE invite_code = $1', [inviteCode]);
    if (groupRows.length === 0) return res.status(404).json({ error: 'Invalid invite code.' });
    
    const groupId = groupRows[0].id;

    // Check if already member
    const { rows: memberRows } = await pool.query('SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2', [groupId, req.user.id]);
    if (memberRows.length > 0) return res.status(400).json({ error: 'Already a member.' });

    // Join
    await pool.query(
      `INSERT INTO group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`,
      [groupId, req.user.id],
    );

    return res.json({ success: true, group_id: groupId });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

// POST /groups/:id/invite — Invite someone by username
router.post('/:id/invite', requireAuth, async (req, res) => {
  const groupId = req.params.id;
  const targetUsername = req.body.username;
  
  if (!targetUsername) return res.status(400).json({ error: 'username is required.' });

  try {
    // Check if sender is member
    const { rows: senderRole } = await pool.query('SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2', [groupId, req.user.id]);
    if (senderRole.length === 0) return res.status(403).json({ error: 'You are not a member.' });

    // Find target user
    const { rows: targetUsers } = await pool.query('SELECT id FROM users WHERE username = $1', [targetUsername]);
    if (targetUsers.length === 0) return res.status(404).json({ error: 'User not found.' });
    const targetUserId = targetUsers[0].id;

    // Prevent self-invite
    if (targetUserId === req.user.id) return res.status(400).json({ error: 'Cannot invite yourself.' });

    // Check if already in group
    const { rows: existingMember } = await pool.query('SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2', [groupId, targetUserId]);
    if (existingMember.length > 0) return res.status(400).json({ error: 'User is already a member.' });

    // Insert invite
    const { rows: invite } = await pool.query(
      `INSERT INTO group_invites (group_id, invited_by, invited_user_id)
       VALUES ($1, $2, $3)
       RETURNING id, status, created_at`,
      [groupId, req.user.id, targetUserId]
    );

    return res.status(201).json(invite[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Invite already pending.' });
    console.error(err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

module.exports = router;
