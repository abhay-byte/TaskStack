'use strict';
require('dotenv').config();
const bcrypt = require('bcrypt');
const pool   = require('./pool');

const SEED_USER = {
  username:    'testuser',
  email:       'test@taskstack.dev',
  password:    'Test1234!',
  displayName: 'Test User',
};

async function seed() {
  try {
    const hash = await bcrypt.hash(SEED_USER.password, 10);
    const { rows } = await pool.query(
      `INSERT INTO users (username, email, password_hash, display_name)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash
       RETURNING id, username, email`,
      [SEED_USER.username, SEED_USER.email, hash, SEED_USER.displayName],
    );
    console.log('✅ Seed user ready:', rows[0]);
  } catch (err) {
    console.error('❌ Seed failed:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

seed();
