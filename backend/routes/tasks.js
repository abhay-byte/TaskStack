'use strict';
const { Router } = require('express');
const { z } = require('zod');
const pool = require('../db/pool');
const { requireAuth: verifyToken } = require('../middleware/auth');

const router = Router();
router.use(verifyToken);

// ─── Validation schemas ────────────────────────────────────────────────────────

const goalSchema = z.object({
    id: z.string().min(1),
    title: z.string().min(1).max(200),
    type: z.enum(['project', 'habit', 'noTime']).default('project'),
    duration_hours: z.number().int().positive().nullable().optional(),
    created_at: z.string().datetime(),
    updated_at: z.string().datetime(),
});

const taskSchema = z.object({
    id: z.string().min(1),
    title: z.string().min(1).max(300),
    description: z.string().nullable().optional(),
    purpose: z.string().nullable().optional(),
    icon_id: z.string().nullable().optional(),
    color_argb: z.number().nullable().optional(),
    tags_json: z.string().default('[]'),
    start_minutes: z.number().int().nullable().optional(),
    duration_minutes: z.number().int().nullable().optional(),
    recurrence_type: z.string().default('none'),
    recurrence_rule: z.string().nullable().optional(),
    repeat_interval_minutes: z.number().int().nullable().optional(),
    notification_enabled: z.boolean().default(true),
    notification_offset_minutes: z.number().int().default(5),
    status: z.enum(['pending', 'done']).default('pending'),
    completed_at: z.string().datetime().nullable().optional(),
    task_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    graphic_image: z.string().nullable().optional(),
    parent_task_id: z.string().nullable().optional(),
    goal_id: z.string().nullable().optional(),
    created_at: z.string().datetime(),
    updated_at: z.string().datetime(),
});

// ─── GOALS ────────────────────────────────────────────────────────────────────

// GET /tasks/goals  — all goals for the authenticated user
router.get('/goals', async (req, res, next) => {
    try {
        const since = req.query.since;
        let query = 'SELECT * FROM goals WHERE user_id = $1';
        const params = [req.user.sub];
        if (since) {
            query += ' AND updated_at > $2';
            params.push(since);
        }
        query += ' ORDER BY created_at DESC';
        const { rows } = await pool.query(query, params);
        res.json(rows);
    } catch (err) {
        next(err);
    }
});

// POST /tasks/goals/bulk  — upsert array of goals (last-write-wins on updated_at)
router.post('/goals/bulk', async (req, res, next) => {
    try {
        const parsed = z.array(goalSchema).safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

        const goals = parsed.data;
        if (goals.length === 0) return res.json({ upserted: 0 });

        // Build a multi-row upsert
        const values = [];
        const placeholders = goals.map((g, i) => {
            const base = i * 7;
            values.push(g.id, req.user.sub, g.title, g.type, g.duration_hours ?? null, g.created_at, g.updated_at);
            return `($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6}, $${base + 7})`;
        });

        const sql = `
      INSERT INTO goals (id, user_id, title, type, duration_hours, created_at, updated_at)
      VALUES ${placeholders.join(', ')}
      ON CONFLICT (id) DO UPDATE SET
        title          = EXCLUDED.title,
        type           = EXCLUDED.type,
        duration_hours = EXCLUDED.duration_hours,
        updated_at     = EXCLUDED.updated_at
      WHERE EXCLUDED.updated_at > goals.updated_at
    `;
        await pool.query(sql, values);
        res.json({ upserted: goals.length });
    } catch (err) {
        next(err);
    }
});

// DELETE /tasks/goals/:id
router.delete('/goals/:id', async (req, res, next) => {
    try {
        const result = await pool.query(
            'DELETE FROM goals WHERE id = $1 AND user_id = $2',
            [req.params.id, req.user.sub],
        );
        if (result.rowCount === 0) return res.status(404).json({ error: 'Goal not found.' });
        res.json({ deleted: true });
    } catch (err) {
        next(err);
    }
});

// ─── TASKS ────────────────────────────────────────────────────────────────────

// GET /tasks  — all tasks for authenticated user, optional ?since=<ISO8601>
router.get('/', async (req, res, next) => {
    try {
        const since = req.query.since;
        let query = 'SELECT * FROM tasks WHERE user_id = $1';
        const params = [req.user.sub];
        if (since) {
            query += ' AND updated_at > $2';
            params.push(since);
        }
        query += ' ORDER BY task_date DESC, created_at DESC';
        const { rows } = await pool.query(query, params);
        res.json(rows);
    } catch (err) {
        next(err);
    }
});

// POST /tasks/bulk  — upsert array of tasks (last-write-wins on updated_at)
router.post('/bulk', async (req, res, next) => {
    try {
        const parsed = z.array(taskSchema).safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

        const tasks = parsed.data;
        if (tasks.length === 0) return res.json({ upserted: 0 });

        const values = [];
        const placeholders = tasks.map((t, i) => {
            const base = i * 23;
            values.push(
                t.id, req.user.sub, t.title, t.description ?? null, t.purpose ?? null,
                t.icon_id ?? null, t.color_argb ?? null, t.tags_json,
                t.start_minutes ?? null, t.duration_minutes ?? null,
                t.recurrence_type, t.recurrence_rule ?? null, t.repeat_interval_minutes ?? null,
                t.notification_enabled, t.notification_offset_minutes,
                t.status, t.completed_at ?? null, t.task_date,
                t.graphic_image ?? null, t.parent_task_id ?? null, t.goal_id ?? null,
                t.created_at, t.updated_at,
            );
            const p = (n) => `$${base + n}`;
            return `(${p(1)},${p(2)},${p(3)},${p(4)},${p(5)},${p(6)},${p(7)},${p(8)},${p(9)},${p(10)},${p(11)},${p(12)},${p(13)},${p(14)},${p(15)},${p(16)},${p(17)},${p(18)},${p(19)},${p(20)},${p(21)},${p(22)},${p(23)})`;
        });

        const sql = `
      INSERT INTO tasks (
        id, user_id, title, description, purpose, icon_id, color_argb, tags_json,
        start_minutes, duration_minutes, recurrence_type, recurrence_rule,
        repeat_interval_minutes, notification_enabled, notification_offset_minutes,
        status, completed_at, task_date, graphic_image, parent_task_id, goal_id, created_at, updated_at
      ) VALUES ${placeholders.join(', ')}
      ON CONFLICT (id) DO UPDATE SET
        title                       = EXCLUDED.title,
        description                 = EXCLUDED.description,
        purpose                     = EXCLUDED.purpose,
        icon_id                     = EXCLUDED.icon_id,
        color_argb                  = EXCLUDED.color_argb,
        tags_json                   = EXCLUDED.tags_json,
        start_minutes               = EXCLUDED.start_minutes,
        duration_minutes            = EXCLUDED.duration_minutes,
        recurrence_type             = EXCLUDED.recurrence_type,
        recurrence_rule             = EXCLUDED.recurrence_rule,
        repeat_interval_minutes     = EXCLUDED.repeat_interval_minutes,
        notification_enabled        = EXCLUDED.notification_enabled,
        notification_offset_minutes = EXCLUDED.notification_offset_minutes,
        status                      = EXCLUDED.status,
        completed_at                = EXCLUDED.completed_at,
        task_date                   = EXCLUDED.task_date,
        graphic_image               = EXCLUDED.graphic_image,
        parent_task_id              = EXCLUDED.parent_task_id,
        goal_id                     = EXCLUDED.goal_id,
        updated_at                  = EXCLUDED.updated_at
      WHERE EXCLUDED.updated_at > tasks.updated_at
    `;
        await pool.query(sql, values);
        res.json({ upserted: tasks.length });
    } catch (err) {
        next(err);
    }
});

// DELETE /tasks/:id
router.delete('/:id', async (req, res, next) => {
    try {
        const result = await pool.query(
            'DELETE FROM tasks WHERE id = $1 AND user_id = $2',
            [req.params.id, req.user.sub],
        );
        if (result.rowCount === 0) return res.status(404).json({ error: 'Task not found.' });
        res.json({ deleted: true });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
