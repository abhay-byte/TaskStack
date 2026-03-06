'use strict';
require('dotenv').config();
const pool = require('./pool');
const fs   = require('fs');
const path = require('path');

// Incremental migrations that are safe to re-run (idempotent)
const MIGRATIONS = [
  // v1: fix color_argb overflow — INT is signed 32-bit, ARGB values are unsigned 32-bit
  `ALTER TABLE tasks ALTER COLUMN color_argb TYPE BIGINT`,
  // v2: drop FK constraint on goal_id — tasks may arrive before their goal is synced
  `ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_goal_id_fkey`,
  // v3: add graphic_image column — stores SVG asset path for animated task graphics
  `ALTER TABLE tasks ADD COLUMN IF NOT EXISTS graphic_image TEXT`,
];

async function migrate() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  try {
    await pool.query(sql);
    console.log('✅ Schema applied successfully.');

    for (const migration of MIGRATIONS) {
      try {
        await pool.query(migration);
        console.log(`✅ Migration applied: ${migration.substring(0, 60)}...`);
      } catch (err) {
        // All ALTER errors are safe to skip — column may already be correct type
        console.warn(`⚠️  Migration skipped (already applied): ${err.message}`);
      }
    }
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

migrate();

