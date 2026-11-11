import { mkdirSync } from 'node:fs';

import { PGlite } from '@electric-sql/pglite';

import type { Db } from './db';
import { migrate } from './migrate-core';

/**
 * Embedded Postgres (PGlite) for local development and tests – no install,
 * no password. `dataDir` persists between runs; omit it for in-memory.
 */
export async function createLocalDb(dataDir?: string): Promise<Db & { close(): Promise<void> }> {
  if (dataDir) mkdirSync(dataDir, { recursive: true });
  const pg = new PGlite(dataDir);
  await migrate({
    exec: async (sql) => {
      await pg.exec(sql);
    },
    query: async (text, params) => (await pg.query(text, params)).rows as never,
  });
  return {
    query: async <T>(text: string, params: unknown[] = []) =>
      (await pg.query(text, params)).rows as T[],
    close: () => pg.close(),
  };
}
