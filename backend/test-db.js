const { Client } = require('pg');
require('dotenv').config();

const client = new Client({
  connectionString: process.env.DATABASE_URL.split('?')[0], // strip all query params
  ssl: { rejectUnauthorized: false }
});

async function run() {
  console.log('Connecting...');
  try {
    await client.connect();
    console.log('Connected!');
    const res = await client.query('SELECT NOW()');
    console.log('Time:', res.rows[0].now);
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

run();
