// Applies migrations/*.sql to the database in DATABASE_URL (e.g. Neon).
import { existsSync } from 'node:fs';

import pg from 'pg';

import { migrate } from '../src/migrate-core';

if (existsSync('.env')) process.loadEnvFile('.env');
const url = process.env.DATABASE_URL;
if (!url) {
  console.error('Set DATABASE_URL (your Neon connection string) in server/.env first.');
  process.exit(1);
}

const client = new pg.Client({ connectionString: url });
await client.connect();
try {
  const applied = await migrate({
    exec: async (sql) => {
      await client.query(sql);
    },
    query: async (text, params) => (await client.query(text, params)).rows,
  });
  console.log(applied.length ? `Applied: ${applied.join(', ')}` : 'Database is up to date.');
} finally {
  await client.end();
}
