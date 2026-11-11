import { Hono } from 'hono';

import { CHALLENGE_REWARD_XP, CHALLENGE_TARGET, challengeFor } from '../challenges';
import { apiError, requireAuth, type AppEnv } from '../context';
import type { Db } from '../db';
import { awardXp, loadUser, toProfile } from '../profile';
import { utcDay } from '../rules';
import { masteryFor } from './learning';

type Num = string | number | null;

async function challengeStatus(db: Db, userId: string, now: Date) {
  const { key, start, end, challenge } = challengeFor(now);
  const [row] = await db.query<{ progress: Num; claimed: boolean }>(
    `select (select count(*) from mission_completions
              where user_id = $1 and completed_on >= $2::date and completed_on < $3::date
                and sdg_number = any($4::smallint[])) as progress,
            exists (select 1 from challenge_claims where user_id = $1 and month = $5) as claimed`,
    [userId, start, end, challenge.sdgs, key],
  );
  const progress = Number(row?.progress ?? 0);
  return {
    month: key,
    id: challenge.id,
    title: challenge.title,
    sdgs: challenge.sdgs,
    target: CHALLENGE_TARGET,
    reward_xp: CHALLENGE_REWARD_XP,
    progress,
    completed: progress >= CHALLENGE_TARGET,
    claimed: Boolean(row?.claimed),
    ends_on: end,
  };
}

export const stats = new Hono<AppEnv>();
stats.use('*', requireAuth);

/** Lifetime counters the app turns into achievements, plus this month's challenge. */
stats.get('/me/stats', async (c) => {
  const db = c.get('db');
  const userId = c.get('userId');
  const [row] = await db.query<Record<string, Num>>(
    `select u.xp, u.streak, u.best_streak,
            (select count(*) from mission_completions where user_id = $1) as missions,
            (select count(distinct sdg_number) from mission_completions where user_id = $1) as mission_goals,
            (select count(*) from mission_completions where user_id = $1 and photo_verified) as verified_photos,
            (select count(*) from stories where user_id = $1) as stories,
            (select count(*) from game_sessions where user_id = $1) as games_played,
            (select count(distinct game_id) from game_sessions where user_id = $1) as distinct_games,
            (select count(*) from quiz_attempts where user_id = $1) as quiz_rounds,
            (select count(*) from quiz_attempts
              where user_id = $1 and score = total_questions and total_questions >= 3) as perfect_quizzes,
            (select count(*) from lesson_reads where user_id = $1) as lessons_read,
            (select count(*) from team_members where user_id = $1) as teams,
            (select count(*) from challenge_claims where user_id = $1) as challenges_completed
       from users u where u.id = $1`,
    [userId],
  );
  if (!row) throw apiError(401, 'invalid_token', 'Your account no longer exists.');
  const goals = (await masteryFor(db, [userId])).get(userId)!;
  const counters = Object.fromEntries(Object.entries(row).map(([k, v]) => [k, Number(v ?? 0)]));
  return c.json({
    ...counters,
    best_streak: Math.max(counters.best_streak ?? 0, counters.streak ?? 0),
    stars: goals.reduce((s, g) => s + g.stars, 0),
    goals_mastered: goals.filter((g) => g.stars === 3).length,
    challenge: await challengeStatus(db, userId, c.get('config').now()),
  });
});

/** Claims this month's challenge reward once the target is reached. */
stats.post('/me/challenge/claim', async (c) => {
  const db = c.get('db');
  const userId = c.get('userId');
  const now = c.get('config').now();
  const status = await challengeStatus(db, userId, now);
  if (!status.completed) {
    throw apiError(409, 'challenge_incomplete', `Complete ${status.target} ${status.title} missions first.`);
  }
  const inserted = await db.query(
    `insert into challenge_claims (user_id, month, challenge, xp) values ($1, $2, $3, $4)
     on conflict do nothing returning month`,
    [userId, status.month, status.id, CHALLENGE_REWARD_XP],
  );
  if (!inserted.length) throw apiError(409, 'already_claimed', 'You already claimed this month’s reward.');
  const award = await awardXp(db, userId, CHALLENGE_REWARD_XP, utcDay(now));
  const user = await loadUser(db, userId);
  return c.json({
    xp_earned: CHALLENGE_REWARD_XP,
    streak_bonus: award.bonus,
    streak: award.streak,
    xp_before: award.xp_before,
    xp_after: award.xp_after,
    capped: false,
    profile: toProfile(user!, now),
    challenge: { ...status, claimed: true },
  });
});
