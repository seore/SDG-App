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
      focus_sdgs: z
        .array(z.number().int().min(1).max(17))
        .max(3)
        .transform((a) => [...new Set(a)])
        .optional(),
    })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Check your profile details.');

  const sets: string[] = [];
  const params: unknown[] = [c.get('userId')];
  for (const [key, value] of Object.entries(body.data)) {
    if (value === undefined) continue;
    params.push(value);
    const cast = key === 'focus_sdgs' ? '::smallint[]' : '';
    sets.push(`${key} = $${params.length}${cast}`);
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

/** Estimated real-world impact: the user's totals and the whole community's. */
me.get('/impact', async (c) => {
  type Row = { impact_metric: string; total: string | number; actions: string | number };
  const sum = (rows: Row[]) =>
    Object.fromEntries(
      rows.map((r) => [r.impact_metric, { amount: Number(r.total), actions: Number(r.actions) }]),
    );
  const db = c.get('db');
  const select = `select impact_metric, sum(impact_amount) as total, count(*) as actions
                    from mission_completions
                   where impact_metric is not null`;
  const [mine, community] = await Promise.all([
    db.query<Row>(`${select} and user_id = $1 group by impact_metric`, [c.get('userId')]),
    db.query<Row>(`${select} group by impact_metric`),
  ]);
  return c.json({ mine: sum(mine), community: sum(community) });
});

/** Last 7 days (including today, UTC) for the shareable weekly summary. */
me.get('/weekly', async (c) => {
  const db = c.get('db');
  const userId = c.get('userId');
  const now = c.get('config').now();
  const today = utcDay(now);
  const from = utcDay(new Date(now.getTime() - 6 * 86_400_000));

  type Num = string | number | null;
  const [[missions], [games], bySdg, impact, user] = await Promise.all([
    db.query<{ count: Num; xp: Num; days: Num }>(
      `select count(*) as count, coalesce(sum(xp), 0) as xp,
              count(distinct completed_on) as days
         from mission_completions
        where user_id = $1 and completed_on between $2::date and $3::date`,
      [userId, from, today],
    ),
    db.query<{ count: Num; xp: Num }>(
      `select count(*) as count, coalesce(sum(xp_earned), 0) as xp
         from game_sessions
        where user_id = $1 and played_on between $2::date and $3::date`,
      [userId, from, today],
    ),
    db.query<{ sdg_number: number; count: Num }>(
      `select sdg_number, count(*) as count
         from mission_completions
        where user_id = $1 and completed_on between $2::date and $3::date
        group by sdg_number order by count(*) desc, sdg_number limit 3`,
      [userId, from, today],
    ),
    db.query<{ impact_metric: string; total: Num }>(
      `select impact_metric, sum(impact_amount) as total
         from mission_completions
        where user_id = $1 and impact_metric is not null
          and completed_on between $2::date and $3::date
        group by impact_metric`,
      [userId, from, today],
    ),
    loadUser(db, userId),
  ]);

  return c.json({
    from,
    to: today,
    missions: Number(missions?.count ?? 0),
    active_days: Number(missions?.days ?? 0),
    games: Number(games?.count ?? 0),
    xp: Number(missions?.xp ?? 0) + Number(games?.xp ?? 0),
    streak: user ? toProfile(user, now).streak : 0,
    top_sdgs: bySdg.map((r) => ({ sdg_number: Number(r.sdg_number), missions: Number(r.count) })),
    impact: Object.fromEntries(impact.map((r) => [r.impact_metric, Number(r.total)])),
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
