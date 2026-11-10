import { Hono } from 'hono';
import { z } from 'zod';

import { apiError, requireAuth, type AppEnv } from '../context';
import { awardXp, loadUser, toProfile } from '../profile';
import {
  games,
  MAX_MISSIONS_PER_DAY,
  missions,
  REWARDED_PLAYS_PER_GAME_PER_DAY,
  utcDay,
} from '../rules';

export const activity = new Hono<AppEnv>();
activity.use('*', requireAuth);

/** Photo keys must belong to the caller (see uploads.ts). */
function ownsKey(key: string, userId: string) {
  return key.startsWith(`mission-photos/${userId}/`) && !key.includes('..');
}

activity.post('/missions/:id/complete', async (c) => {
  const mission = missions.get(c.req.param('id'));
  if (!mission) throw apiError(404, 'unknown_mission', 'That mission does not exist.');

  const body = z
    .object({
      lat: z.number().min(-90).max(90).nullable().optional(),
      lng: z.number().min(-180).max(180).nullable().optional(),
      photo_key: z.string().max(200).nullable().optional(),
    })
    .safeParse(await c.req.json().catch(() => ({})));
  if (!body.success) throw apiError(400, 'invalid_input', 'Invalid mission details.');

  const db = c.get('db');
  const userId = c.get('userId');
  const now = c.get('config').now();
  const today = utcDay(now);
  const photoKey =
    body.data.photo_key && ownsKey(body.data.photo_key, userId) ? body.data.photo_key : null;

  const [{ count }] = (await db.query<{ count: string | number }>(
    'select count(*) as count from mission_completions where user_id = $1 and completed_on = $2::date',
    [userId, today],
  )) as [{ count: string | number }];
  if (Number(count) >= MAX_MISSIONS_PER_DAY) {
    throw apiError(429, 'daily_limit', `You've completed ${MAX_MISSIONS_PER_DAY} missions today. Come back tomorrow!`);
  }

  const user = await loadUser(db, userId);
  if (!user) throw apiError(401, 'invalid_token', 'Your account no longer exists.');

  // The unique (user, mission, day) constraint makes double-submits a no-op.
  const inserted = await db.query(
    `insert into mission_completions
       (user_id, user_name, mission_id, mission_title, sdg_number, xp, lat, lng, photo_key, completed_on)
     values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::date)
     on conflict (user_id, mission_id, completed_on) do nothing
     returning id`,
    [
      userId,
      user.username,
      mission.id,
      mission.title,
      mission.sdgNumber,
      mission.xp,
      body.data.lat ?? null,
      body.data.lng ?? null,
      photoKey,
      today,
    ],
  );
  if (!inserted.length) {
    throw apiError(409, 'already_completed', 'You already completed this mission today.');
  }

  await db.query(
    'insert into stories (user_id, user_name, message, sdg_number, photo_key) values ($1, $2, $3, $4, $5)',
    [userId, user.username, `Completed: ${mission.title}`, mission.sdgNumber, photoKey],
  );

  const award = await awardXp(db, userId, mission.xp, today);
  const updated = await loadUser(db, userId);
  return c.json({
    xp_earned: mission.xp,
    streak_bonus: award.bonus,
    streak: award.streak,
    xp_before: award.xp_before,
    xp_after: award.xp_after,
    capped: false,
    profile: toProfile(updated!, now),
  });
});

activity.post('/games/complete', async (c) => {
  const body = z
    .object({
      game_id: z.string(),
      score: z.number().int().min(0),
      total: z.number().int().min(1),
      sdg_number: z.number().int().min(1).max(17).optional(),
    })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Invalid game result.');

  const rule = games[body.data.game_id];
  if (!rule) throw apiError(404, 'unknown_game', 'That game does not exist.');
  const { score, total } = body.data;
  if (total > rule.maxTotal || score > total) {
    throw apiError(400, 'invalid_score', 'That score is not possible.');
  }

  const db = c.get('db');
  const userId = c.get('userId');
  const now = c.get('config').now();
  const today = utcDay(now);

  const [{ plays }] = (await db.query<{ plays: string | number }>(
    `select count(*) as plays from game_sessions
      where user_id = $1 and game_id = $2 and played_on = $3::date and xp_earned > 0`,
    [userId, body.data.game_id, today],
  )) as [{ plays: string | number }];
  const capped = Number(plays) >= REWARDED_PLAYS_PER_GAME_PER_DAY;
  const xp = capped ? 0 : rule.xpFor(score, total);

  await db.query(
    `insert into game_sessions (user_id, game_id, sdg_number, score, total, xp_earned, played_on)
     values ($1, $2, $3, $4, $5, $6, $7::date)`,
    [userId, body.data.game_id, rule.sdgNumber, score, total, xp, today],
  );
  if (body.data.game_id === 'quiz') {
    await db.query(
      `insert into quiz_attempts (user_id, sdg_number, score, total_questions, xp_earned)
       values ($1, $2, $3, $4, $5)`,
      [userId, body.data.sdg_number ?? rule.sdgNumber, score, total, xp],
    );
  }

  const award = await awardXp(db, userId, xp, today);
  const updated = await loadUser(db, userId);
  return c.json({
    xp_earned: xp,
    streak_bonus: award.bonus,
    streak: award.streak,
    xp_before: award.xp_before,
    xp_after: award.xp_after,
    capped,
    profile: toProfile(updated!, now),
  });
});
