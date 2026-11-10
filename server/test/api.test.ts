import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { createApp } from '../src/app';
import type { AppConfig } from '../src/config';
import { createLocalDb } from '../src/local-db';

// One in-memory Postgres for the file; each test uses its own user.
let db: Awaited<ReturnType<typeof createLocalDb>>;
let clock = new Date('2026-03-10T12:00:00Z');
const sentEmails: { to: string; text: string }[] = [];

const config: AppConfig = {
  jwtSecret: 'test-secret-test-secret-test-secret-123',
  accessTokenTtlSeconds: 3600,
  refreshTokenTtlDays: 60,
  passwordResetUrl: 'sdgjourney://password-reset',
  mailer: { send: async (to, _s, text) => void sentEmails.push({ to, text }) },
  now: () => clock,
};

let app: ReturnType<typeof createApp>;

beforeAll(async () => {
  db = await createLocalDb();
  app = createApp(() => ({ db, config }));
});
afterAll(() => db.close());

let n = 0;
async function call(method: string, path: string, body?: unknown, token?: string) {
  const res = await app.request(path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: res.status, json: (await res.json()) as any };
}

async function newUser() {
  n++;
  const res = await call('POST', '/auth/signup', {
    email: `User${n}@Example.com`,
    password: 'secret123',
    username: `user${n}`,
  });
  expect(res.status).toBe(201);
  return res.json as { access_token: string; refresh_token: string; user: any };
}

describe('auth', () => {
  it('signs up, logs in case-insensitively and rejects bad passwords', async () => {
    const s = await newUser();
    expect(s.user.xp).toBe(0);
    expect(s.user.email).toBe(`user${n}@example.com`);

    const dup = await call('POST', '/auth/signup', {
      email: `USER${n}@example.com`,
      password: 'secret123',
      username: 'dupe',
    });
    expect(dup.status).toBe(409);

    expect((await call('POST', '/auth/login', { email: `user${n}@EXAMPLE.com`, password: 'secret123' })).status).toBe(200);
    const bad = await call('POST', '/auth/login', { email: `user${n}@example.com`, password: 'nope-nope' });
    expect(bad.status).toBe(401);
    expect(bad.json.message).toBe('Incorrect email or password.');
  });

  it('validates sign-up input', async () => {
    const res = await call('POST', '/auth/signup', { email: 'not-an-email', password: '1', username: 'x' });
    expect(res.status).toBe(400);
  });

  it('rotates refresh tokens and rejects reuse', async () => {
    const s = await newUser();
    const first = await call('POST', '/auth/refresh', { refresh_token: s.refresh_token });
    expect(first.status).toBe(200);
    expect(first.json.refresh_token).not.toBe(s.refresh_token);
    const reuse = await call('POST', '/auth/refresh', { refresh_token: s.refresh_token });
    expect(reuse.status).toBe(401);
  });

  it('requires a valid access token', async () => {
    expect((await call('GET', '/me')).status).toBe(401);
    expect((await call('GET', '/me', undefined, 'garbage')).status).toBe(401);
  });

  it('resets a password via the emailed link and signs out other sessions', async () => {
    const s = await newUser();
    const email = `user${n}@example.com`;
    expect((await call('POST', '/auth/forgot-password', { email })).status).toBe(200);
    // Unknown emails get the same response (no account probing).
    expect((await call('POST', '/auth/forgot-password', { email: 'nobody@example.com' })).status).toBe(200);

    const mail = sentEmails.find((m) => m.to === email)!;
    const token = /token=([0-9a-f]+)/.exec(mail.text)![1];

    expect((await call('POST', '/auth/reset-password', { token, password: 'newpass99' })).status).toBe(200);
    expect((await call('POST', '/auth/reset-password', { token, password: 'again999' })).status).toBe(400);
    expect((await call('POST', '/auth/login', { email, password: 'newpass99' })).status).toBe(200);
    expect((await call('POST', '/auth/refresh', { refresh_token: s.refresh_token })).status).toBe(401);
  });
});

describe('missions', () => {
  it('awards catalog XP once per mission per day', async () => {
    const s = await newUser();
    const done = await call('POST', '/missions/m_unplug/complete', { lat: 51.50735, lng: -0.12776 }, s.access_token);
    expect(done.status).toBe(200);
    expect(done.json.xp_earned).toBe(20);
    expect(done.json.profile.xp).toBe(20);
    expect(done.json.streak).toBe(1);

    const again = await call('POST', '/missions/m_unplug/complete', {}, s.access_token);
    expect(again.status).toBe(409);

    const today = await call('GET', '/me/completions/today', undefined, s.access_token);
    expect(today.json.mission_ids).toEqual(['m_unplug']);
  });

  it('rejects unknown missions', async () => {
    const s = await newUser();
    expect((await call('POST', '/missions/m_fake/complete', {}, s.access_token)).status).toBe(404);
  });

  it('caps completions at 5 per day', async () => {
    const s = await newUser();
    const ids = ['m_unplug', 'm_lights_off_evening', 'm_walk_instead', 'm_fan_not_ac', 'm_reusable_bottle', 'm_trash_sorter'];
    const results = [];
    for (const id of ids) results.push((await call('POST', `/missions/${id}/complete`, {}, s.access_token)).status);
    expect(results).toEqual([200, 200, 200, 200, 200, 429]);
  });

  it('builds a streak across days and pays the 3-day bonus', async () => {
    const s = await newUser();
    const start = clock;
    try {
      const day = (d: number) => (clock = new Date(start.getTime() + d * 86_400_000));
      day(0);
      expect((await call('POST', '/missions/m_unplug/complete', {}, s.access_token)).json.streak).toBe(1);
      day(1);
      expect((await call('POST', '/missions/m_unplug/complete', {}, s.access_token)).json.streak).toBe(2);
      day(2);
      const third = await call('POST', '/missions/m_unplug/complete', {}, s.access_token);
      expect(third.json.streak).toBe(3);
      expect(third.json.streak_bonus).toBe(5);
      expect(third.json.profile.xp).toBe(20 * 3 + 5);

      // Skipping a day shows the streak as broken, then restarts it.
      day(4);
      expect((await call('GET', '/me', undefined, s.access_token)).json.streak).toBe(0);
      expect((await call('POST', '/missions/m_unplug/complete', {}, s.access_token)).json.streak).toBe(1);
    } finally {
      clock = start;
    }
  });
});

describe('games', () => {
  it('computes XP on the server and caps rewarded plays per day', async () => {
    const s = await newUser();
    const play = () => call('POST', '/games/complete', { game_id: 'quiz', score: 7, total: 10, sdg_number: 6 }, s.access_token);
    const xp = [];
    for (let i = 0; i < 4; i++) xp.push((await play()).json.xp_earned);
    expect(xp).toEqual([70, 70, 70, 0]);

    const summary = await call('GET', '/me/quiz-summary', undefined, s.access_token);
    expect(summary.json.attempts).toBe(4);
    expect(Math.round(summary.json.average_percent)).toBe(70);
  });

  it('rejects impossible scores and unknown games', async () => {
    const s = await newUser();
    expect((await call('POST', '/games/complete', { game_id: 'quiz', score: 11, total: 10 }, s.access_token)).status).toBe(400);
    expect((await call('POST', '/games/complete', { game_id: 'quiz', score: 5, total: 999 }, s.access_token)).status).toBe(400);
    expect((await call('POST', '/games/complete', { game_id: 'hack', score: 1, total: 1 }, s.access_token)).status).toBe(404);
  });

  it('applies the city rule (2x score, min 10, max 80)', async () => {
    const s = await newUser();
    expect((await call('POST', '/games/complete', { game_id: 'city_fix', score: 2, total: 40 }, s.access_token)).json.xp_earned).toBe(10);
    expect((await call('POST', '/games/complete', { game_id: 'city_fix', score: 40, total: 40 }, s.access_token)).json.xp_earned).toBe(80);
  });
});

describe('impact', () => {
  it('records each mission\'s impact and sums it for you and the community', async () => {
    const a = await newUser();
    const b = await newUser();
    const before = (await call('GET', '/me/impact', undefined, a.access_token)).json;
    const done = await call('POST', '/missions/m_short_shower/complete', {}, a.access_token);
    expect(done.json.impact).toEqual({ metric: 'water_l', amount: 40 });
    await call('POST', '/missions/m_turn_off_tap/complete', {}, a.access_token);
    await call('POST', '/missions/m_short_shower/complete', {}, b.access_token);

    const mine = (await call('GET', '/me/impact', undefined, a.access_token)).json;
    expect(mine.mine.water_l).toEqual({ amount: 52, actions: 2 });
    const prevCommunity = before.community.water_l?.amount ?? 0;
    expect(mine.community.water_l.amount).toBe(prevCommunity + 92);
  });

  it('gives every mission a known impact metric', async () => {
    const { missions, impactMetrics } = await import('../src/rules');
    for (const m of missions.values()) {
      expect(impactMetrics.has(m.impact!.metric), m.id).toBe(true);
      expect(m.impact!.amount, m.id).toBeGreaterThan(0);
    }
  });
});

describe('feeds and profile', () => {
  it('marks your own completions and coarsens locations', async () => {
    const a = await newUser();
    const b = await newUser();
    await call('POST', '/missions/m_walk_instead/complete', { lat: 51.507351, lng: -0.127758 }, a.access_token);

    const forA = await call('GET', '/feed/completions', undefined, a.access_token);
    const row = forA.json.completions.find((r: any) => r.mission_id === 'm_walk_instead' && r.is_mine);
    expect(row).toBeTruthy();
    expect(row.lat).toBe(51.51);
    expect(row.lng).toBe(-0.13);
    expect(row).not.toHaveProperty('user_id');

    const forB = await call('GET', '/feed/completions', undefined, b.access_token);
    expect(forB.json.completions.some((r: any) => r.is_mine)).toBe(false);

    const stories = await call('GET', '/feed/stories', undefined, b.access_token);
    expect(stories.json.stories[0].message).toBe('Completed: Walk or Cycle Instead');
  });

  it('updates the username and validates shop packs', async () => {
    const s = await newUser();
    const upd = await call('PATCH', '/me', { username: 'Eco Hero' }, s.access_token);
    expect(upd.json.username).toBe('Eco Hero');

    expect((await call('POST', '/me/packs', { pack_id: 'cosmetic_gold_frame' }, s.access_token)).status).toBe(201);
    expect((await call('POST', '/me/packs', { pack_id: 'free_stuff' }, s.access_token)).status).toBe(400);
    expect((await call('GET', '/me/packs', undefined, s.access_token)).json.pack_ids).toEqual(['cosmetic_gold_frame']);
  });

  it('reports uploads as disabled when storage is not configured', async () => {
    const s = await newUser();
    expect((await call('POST', '/uploads/mission-photo', {}, s.access_token)).status).toBe(501);
  });
});
