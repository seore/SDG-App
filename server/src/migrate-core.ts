import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

/** Anything that can run multi-statement SQL and simple queries. */
export interface MigrationTarget {
  exec(sql: string): Promise<void>;
  query<T = Record<string, unknown>>(text: string, params?: unknown[]): Promise<T[]>;
}

const migrationsDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'migrations');

export function loadMigrations() {
  return readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort()
    .map((name) => ({ name, sql: readFileSync(join(migrationsDir, name), 'utf8') }));
}

/** Applies pending migrations in order; returns the names applied. */
export async function migrate(target: MigrationTarget): Promise<string[]> {
  await target.exec(
    'create table if not exists schema_migrations (name text primary key, applied_at timestamptz not null default now())',
  );
  const done = new Set(
    (await target.query<{ name: string }>('select name from schema_migrations')).map((r) => r.name),
  );
  const applied: string[] = [];
  for (const m of loadMigrations()) {
    if (done.has(m.name)) continue;
    await target.exec(`begin;\n${m.sql}\ninsert into schema_migrations (name) values ('${m.name}');\ncommit;`);
    applied.push(m.name);
  }
  return applied;
}
