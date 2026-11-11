import { Hono } from 'hono';
import { z } from 'zod';

import { apiError, requireAuth, type AppEnv } from '../context';

/** Reports one person can send per day, to keep the review queue useful. */
export const MAX_REPORTS_PER_DAY = 20;

export const content = new Hono<AppEnv>();
content.use('*', requireAuth);

/**
 * Flags a problem with a piece of content. Reviewed by the content team
 * (see goalquest/docs/content_review.md).
 */
content.post('/content/reports', async (c) => {
  const body = z
    .object({
      content_type: z.enum(['lesson', 'mission', 'quiz', 'target', 'impact']),
      content_id: z.string().trim().min(1).max(80),
      reason: z.enum(['inaccurate', 'out_of_date', 'unclear', 'not_age_appropriate', 'other']),
      message: z.string().trim().max(1000).optional(),
    })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Choose what is wrong and try again.');

  const db = c.get('db');
  const userId = c.get('userId');
  const since = new Date(c.get('config').now().getTime() - 86_400_000).toISOString();
  const [{ n }] = (await db.query<{ n: string | number }>(
    'select count(*) as n from content_reports where user_id = $1 and created_at > $2::timestamptz',
    [userId, since],
  )) as [{ n: string | number }];
  if (Number(n) >= MAX_REPORTS_PER_DAY) {
    throw apiError(429, 'too_many_reports', 'Thanks! You have sent a lot of reports today. Please try again tomorrow.');
  }

  await db.query(
    `insert into content_reports (user_id, content_type, content_id, reason, message)
     values ($1, $2, $3, $4, $5)`,
    [userId, body.data.content_type, body.data.content_id, body.data.reason, body.data.message || null],
  );
  return c.json({ ok: true }, 201);
});
