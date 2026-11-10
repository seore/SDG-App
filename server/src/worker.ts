// Cloudflare Workers entry point (`npm run dev:worker` / `npm run deploy`).
import { createApp } from './app';
import { configFromEnv, type EnvVars } from './config';
import { neonDb } from './db';

const app = createApp((c) => {
  const env = c.env as unknown as EnvVars;
  if (!env.DATABASE_URL) throw new Error('DATABASE_URL is not set.');
  return { db: neonDb(env.DATABASE_URL), config: configFromEnv(env) };
});

export default app;
