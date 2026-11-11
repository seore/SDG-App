import { Hono } from 'hono';
import { z } from 'zod';

import { apiError, requireAuth, type AppEnv } from '../context';
import { checkWithTimeout, type PhotoVerdict } from '../photo-check';
import { canShare } from './consent';
import { awardXp, loadUser, toProfile } from '../profile';
import {
  games,
  MAX_MISSIONS_PER_DAY,
  PHOTO_VERIFIED_BONUS_XP,
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
  // Until a parent approves, nothing is shared: no photo, location or story.
  const sharing = await canShare(db, userId);
  const photoKey =
    sharing && body.data.photo_key && ownsKey(body.data.photo_key, userId) ? body.data.photo_key : null;

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
       (user_id, user_name, mission_id, mission_title, sdg_number, xp, lat, lng, photo_key,
        completed_on, impact_metric, impact_amount)
     values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::date, $11, $12)
     on conflict (user_id, mission_id, completed_on) do nothing
     returning id`,
    [
      userId,
      user.username,
      mission.id,
      mission.title,
      mission.sdgNumber,
      mission.xp,
      sharing ? body.data.lat ?? null : null,
      sharing ? body.data.lng ?? null : null,
      photoKey,
      today,
      mission.impact?.metric ?? null,
      mission.impact?.amount ?? 0,
    ],
  );
  if (!inserted.length) {
    throw apiError(409, 'already_completed', 'You already completed this mission today.');
  }

  // AI photo check (optional). Never blocks completion: on any failure the
  // mission still counts and the photo simply stays private.
  const config = c.get('config');
  let verdict: PhotoVerdict | null = null;
  if (photoKey && config.photoChecker && config.loadPhoto) {
    const image = await config.loadPhoto(photoKey).catch(() => null);
    if (image) {
      verdict = await checkWithTimeout(config.photoChecker, {
        image,
        mediaType: 'image/jpeg',
        missionTitle: mission.title,
        missionDescription: mission.description,
      });
    }
  }
  const verified = !!verdict && verdict.matches && verdict.safe_to_share;
  const bonusXp = verified ? PHOTO_VERIFIED_BONUS_XP : 0;
  if (verdict) {
    await db.query(
      `update mission_completions set photo_verified = $2, photo_feedback = $3
        where id = $1`,
      [(inserted[0] as { id: string }).id, verified, verdict.feedback],
    );
  }

  // Photos are only shown publicly once checked as safe to share.
  if (sharing) await db.query(
    'insert into stories (user_id, user_name, message, sdg_number, photo_key, verified) values ($1, $2, $3, $4, $5, $6)',
    [
      userId,
      user.username,
      `Completed: ${mission.title}`,
      mission.sdgNumber,
      verdict?.safe_to_share ? photoKey : null,
      verified,
    ],
  );

  const award = await awardXp(db, userId, mission.xp + bonusXp, today);
  const updated = await loadUser(db, userId);
  return c.json({
    xp_earned: mission.xp + bonusXp,
    streak_bonus: award.bonus,
    streak: award.streak,
    xp_before: award.xp_before,
    xp_after: award.xp_after,
    capped: false,
    impact: mission.impact ?? null,
    photo_check: verdict
      ? {
          matches: verdict.matches,
          safe_to_share: verdict.safe_to_share,
          verified,
          bonus_xp: bonusXp,
          feedback: verdict.feedback,
        }
      : null,
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
