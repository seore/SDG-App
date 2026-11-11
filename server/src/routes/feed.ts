import { Hono } from 'hono';

import { originOf, requireAuth, type AppEnv } from '../context';
import { coarse } from '../rules';

export const feed = new Hono<AppEnv>();
feed.use('*', requireAuth);

function iso(v: string | Date): string {
  return typeof v === 'string' ? new Date(v).toISOString() : v.toISOString();
}

/** Recent mission completions for the map and impact screens. */
feed.get('/completions', async (c) => {
  const rows = await c.get('db').query<{
    id: string;
    user_name: string;
    mission_id: string;
    mission_title: string;
    sdg_number: number;
    xp: number;
    lat: number | null;
    lng: number | null;
    created_at: string | Date;
    is_mine: boolean;
  }>(
    `select id, user_name, mission_id, mission_title, sdg_number, xp, lat, lng, created_at,
            (user_id = $1) as is_mine
       from mission_completions
      where created_at > now() - interval '90 days'
      order by created_at desc
      limit 500`,
    [c.get('userId')],
  );
  return c.json({
    completions: rows.map((r) => ({
      ...r,
      lat: coarse(r.lat),
      lng: coarse(r.lng),
      created_at: iso(r.created_at),
    })),
  });
});

/** Recent community stories. */
feed.get('/stories', async (c) => {
  const origin = originOf(c);
  const rows = await c.get('db').query<{
    id: string;
    user_name: string;
    message: string;
    sdg_number: number | null;
    photo_key: string | null;
    verified: boolean;
    created_at: string | Date;
  }>(
    `select id, user_name, message, sdg_number, photo_key, verified, created_at
       from stories order by created_at desc limit 100`,
  );
  return c.json({
    stories: rows.map(({ photo_key, ...r }) => ({
      ...r,
      photo_url: photo_key ? `${origin}/media/${photo_key}` : null,
      created_at: iso(r.created_at),
    })),
  });
});
