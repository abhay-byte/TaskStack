'use strict';
require('dotenv').config();
const pool = require('./pool');
const fs   = require('fs');
const path = require('path');

// Incremental migrations that are safe to re-run (idempotent)
const MIGRATIONS = [
  // v1: fix color_argb overflow — INT is signed 32-bit, ARGB values are unsigned 32-bit
  `ALTER TABLE tasks ALTER COLUMN color_argb TYPE BIGINT`,
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
        // Ignore "already correct type" errors
        if (err.message.includes('cannot be cast') || err.message.includes('does not exist')) {
          console.warn(`⚠️  Skipped migration (already applied?): ${err.message}`);
        } else {
          throw err;
        }
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

