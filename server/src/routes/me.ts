import { Hono } from 'hono';
import { z } from 'zod';

import { apiError, requireAuth, type AppEnv } from '../context';
import { loadUser, toProfile, type UserRow } from '../profile';
import { shopPackIds, utcDay } from '../rules';

export const me = new Hono<AppEnv>();
me.use('*', requireAuth);

me.get('/', async (c) => {
  const user = await loadUser(c.get('db'), c.get('userId'));
  if (!user) throw apiError(401, 'invalid_token', 'Your account no longer exists.');
  return c.json(toProfile(user, c.get('config').now()));
});

me.patch('/', async (c) => {
  const body = z
    .object({
      username: z.string().trim().min(2).max(24).optional(),
      avatar_url: z.string().url().max(500).nullable().optional(),
      active_avatar_frame: z.string().max(64).nullable().optional(),
    })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Check your profile details.');

  const sets: string[] = [];
  const params: unknown[] = [c.get('userId')];
  for (const [key, value] of Object.entries(body.data)) {
    if (value === undefined) continue;
    params.push(value);
    sets.push(`${key} = $${params.length}`);
  }
  if (sets.length) {
    await c.get('db').query(`update users set ${sets.join(', ')} where id = $1`, params);
  }
  const user = (await loadUser(c.get('db'), c.get('userId'))) as UserRow;
  return c.json(toProfile(user, c.get('config').now()));
});

/** Mission ids completed today (UTC). */
me.get('/completions/today', async (c) => {
  const rows = await c
    .get('db')
    .query<{ mission_id: string }>(
      'select mission_id from mission_completions where user_id = $1 and completed_on = $2::date',
      [c.get('userId'), utcDay(c.get('config').now())],
    );
  return c.json({ mission_ids: rows.map((r) => r.mission_id) });
});

me.get('/quiz-summary', async (c) => {
  const [row] = await c.get('db').query<{
    attempts: string | number;
    avg_percent: string | number | null;
    total_xp: string | number | null;
  }>(
    `select count(*) as attempts,
            avg(score::float / total_questions * 100) as avg_percent,
            sum(xp_earned) as total_xp
       from quiz_attempts where user_id = $1`,
    [c.get('userId')],
  );
  return c.json({
    attempts: Number(row?.attempts ?? 0),
    average_percent: Number(row?.avg_percent ?? 0),
    total_xp: Number(row?.total_xp ?? 0),
  });
});

me.get('/packs', async (c) => {
  const rows = await c
    .get('db')
    .query<{ pack_id: string }>('select pack_id from user_owned_packs where user_id = $1', [
      c.get('userId'),
    ]);
  return c.json({ pack_ids: rows.map((r) => r.pack_id) });
});

// NOTE: purchases are still simulated (no payment provider yet), as before.
me.post('/packs', async (c) => {
  const body = z.object({ pack_id: z.string() }).safeParse(await c.req.json().catch(() => null));
  if (!body.success || !shopPackIds.has(body.data.pack_id)) {
    throw apiError(400, 'unknown_pack', 'That item is not in the shop.');
  }
  await c
    .get('db')
    .query(
      'insert into user_owned_packs (user_id, pack_id) values ($1, $2) on conflict do nothing',
      [c.get('userId'), body.data.pack_id],
    );
  return c.json({ ok: true }, 201);
});
