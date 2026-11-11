import { Hono } from 'hono';

import { apiError, requireAuth, type AppEnv } from '../context';
import type { Db } from '../db';

/** Quiz accuracy needed for the quiz star, and how many answers count. */
export const QUIZ_STAR_ACCURACY = 0.7;
export const QUIZ_STAR_MIN_ANSWERS = 2;
/** Missions of a goal needed for the action star. */
export const MISSION_STAR_COUNT = 2;

export interface GoalMastery {
  sdg_number: number;
  lesson_read: boolean;
  quiz_correct: number;
  quiz_total: number;
  missions: number;
  stars: number; // 0–3
}

type Num = string | number | null;

export async function masteryFor(db: Db, userIds: string[]): Promise<Map<string, GoalMastery[]>> {
  const [lessons, quiz, missions] = await Promise.all([
    db.query<{ user_id: string; sdg_number: number }>(
      'select user_id, sdg_number from lesson_reads where user_id = any($1::uuid[])',
      [userIds],
    ),
    db.query<{ user_id: string; sdg_number: number; correct: Num; total: Num }>(
      `select user_id, sdg_number, sum(correct) as correct, sum(total) as total
         from quiz_sdg_results where user_id = any($1::uuid[])
        group by user_id, sdg_number`,
      [userIds],
    ),
    db.query<{ user_id: string; sdg_number: number; n: Num }>(
      `select user_id, sdg_number, count(*) as n from mission_completions
        where user_id = any($1::uuid[]) group by user_id, sdg_number`,
      [userIds],
    ),
  ]);

  const out = new Map<string, GoalMastery[]>();
  for (const id of userIds) {
    const goals: GoalMastery[] = [];
    for (let sdg = 1; sdg <= 17; sdg++) {
      const read = lessons.some((l) => l.user_id === id && Number(l.sdg_number) === sdg);
      const q = quiz.find((r) => r.user_id === id && Number(r.sdg_number) === sdg);
      const m = missions.find((r) => r.user_id === id && Number(r.sdg_number) === sdg);
      const correct = Number(q?.correct ?? 0);
      const total = Number(q?.total ?? 0);
      const missionCount = Number(m?.n ?? 0);
      const quizStar = total >= QUIZ_STAR_MIN_ANSWERS && correct / total >= QUIZ_STAR_ACCURACY;
      goals.push({
        sdg_number: sdg,
        lesson_read: read,
        quiz_correct: correct,
        quiz_total: total,
        missions: missionCount,
        stars: Number(read) + Number(quizStar) + Number(missionCount >= MISSION_STAR_COUNT),
      });
    }
    out.set(id, goals);
  }
  return out;
}

export const learning = new Hono<AppEnv>();
learning.use('*', requireAuth);

learning.post('/me/lessons/:sdg/read', async (c) => {
  const sdg = Number(c.req.param('sdg'));
  if (!Number.isInteger(sdg) || sdg < 1 || sdg > 17) throw apiError(404, 'unknown_goal', 'That goal does not exist.');
  await c
    .get('db')
    .query('insert into lesson_reads (user_id, sdg_number) values ($1, $2) on conflict do nothing', [
      c.get('userId'),
      sdg,
    ]);
  return c.json({ ok: true });
});

learning.get('/me/mastery', async (c) => {
  const userId = c.get('userId');
  const goals = (await masteryFor(c.get('db'), [userId])).get(userId)!;
  return c.json({ goals, total_stars: goals.reduce((s, g) => s + g.stars, 0), max_stars: 51 });
});
