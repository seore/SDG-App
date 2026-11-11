import { neon } from '@neondatabase/serverless';

/** Minimal database interface shared by Neon (prod), pg and PGlite (dev/tests). */
export interface Db {
  query<T = Record<string, unknown>>(text: string, params?: unknown[]): Promise<T[]>;
}

/** Neon over HTTP – works on Cloudflare Workers and Node. */
export function neonDb(databaseUrl: string): Db {
  const sql = neon(databaseUrl);
  return {
    query: async <T>(text: string, params: unknown[] = []) =>
      (await sql.query(text, params)) as T[],
  };
}
