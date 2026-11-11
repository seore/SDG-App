// Node entry point for local development (`npm run dev`).
// Uses Neon when DATABASE_URL is set, otherwise an embedded local Postgres.
import { existsSync } from 'node:fs';

import { serve } from '@hono/node-server';

import { createApp } from './app';
import { configFromEnv, type EnvVars } from './config';
import { neonDb, type Db } from './db';
import { createLocalDb } from './local-db';

if (existsSync('.env')) process.loadEnvFile('.env');
const env = process.env as EnvVars;

if (!env.JWT_SECRET) {
  env.JWT_SECRET = 'local-development-secret-change-me-0123456789';
  console.warn('JWT_SECRET not set – using an insecure development secret.');
}

let db: Db;
if (env.DATABASE_URL) {
  db = neonDb(env.DATABASE_URL);
  console.log('Using Neon (DATABASE_URL). Run `npm run migrate` after schema changes.');
} else {
  db = await createLocalDb('.data/pglite');
  console.log('DATABASE_URL not set – using local embedded Postgres in .data/pglite');
}

const config = configFromEnv(env);
const app = createApp(() => ({ db, config }));
const port = Number(process.env.PORT ?? 8787);

serve({ fetch: app.fetch, port, hostname: '0.0.0.0' }, () => {
  console.log(`SDG Journey API listening on http://localhost:${port}`);
});
