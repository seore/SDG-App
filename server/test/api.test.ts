import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { createApp } from '../src/app';
import type { AppConfig } from '../src/config';
import { createLocalDb } from '../src/local-db';
import { missions } from '../src/rules';

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
    birth_year: 1990,
    accept_privacy: true,
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
      birth_year: 1990,
      accept_privacy: true,
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

describe('auth rate limiting', () => {
  it('blocks after the limit and keys login attempts by email', async () => {
    const { createApp } = await import('../src/app');
    const counts = new Map<string, number>();
    const limiter = {
      async limit({ key }: { key: string }) {
        counts.set(key, (counts.get(key) ?? 0) + 1);
        return { success: counts.get(key)! <= 3 };
      },
    };
    const limited = createApp(() => ({ db, config: { ...config, authLimiter: limiter } }));
    const login = (email: string) =>
      limited.request('/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password: 'wrong-password' }),
      });

    const statuses = [];
    for (let i = 0; i < 4; i++) statuses.push((await login('victim@example.com')).status);
    expect(statuses).toEqual([401, 401, 401, 429]);
    const blocked = (await (await login("VICTIM@example.com")).json()) as { error: string };
    expect(blocked.error).toBe('too_many_attempts');
    // A different account is unaffected.
    expect((await login('other@example.com')).status).toBe(401);
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

describe('weekly summary', () => {
  it('summarises the last 7 days only', async () => {
    const s = await newUser();
    const start = clock;
    try {
      clock = new Date(start.getTime() - 8 * 86_400_000); // outside the week
      await call('POST', '/missions/m_short_shower/complete', {}, s.access_token);
      clock = new Date(start.getTime() - 2 * 86_400_000);
      await call('POST', '/missions/m_short_shower/complete', {}, s.access_token);
      clock = start;
      await call('POST', '/missions/m_turn_off_tap/complete', {}, s.access_token);
      await call('POST', '/missions/m_walk_instead/complete', {}, s.access_token);
      await call('POST', '/games/complete', { game_id: 'quiz', score: 5, total: 10 }, s.access_token);

      const w = (await call('GET', '/me/weekly', undefined, s.access_token)).json;
      expect(w.missions).toBe(3);
      expect(w.active_days).toBe(2);
      expect(w.games).toBe(1);
      expect(w.xp).toBe(20 + 15 + 30 + 50);
      expect(w.top_sdgs[0]).toEqual({ sdg_number: 6, missions: 2 });
      expect(w.impact.water_l).toBe(52);
      expect(w.impact.co2_kg).toBeCloseTo(0.8);
    } finally {
      clock = start;
    }
  });
});

describe('teams', () => {
  it('creates a team, joins by code and tracks weekly progress', async () => {
    const teacher = await newUser();
    const pupil = await newUser();
    const created = await call('POST', '/teams', { name: 'Class 7B', weekly_target: 20 }, teacher.access_token);
    expect(created.status).toBe(201);
    expect(created.json.code).toMatch(/^[A-Z2-9]{6}$/);
    expect(created.json.members).toBe(1);
    expect(created.json.is_owner).toBe(true);

    const joined = await call('POST', '/teams/join', { code: created.json.code.toLowerCase() }, pupil.access_token);
    expect(joined.status).toBe(200);
    expect(joined.json.members).toBe(2);
    expect(joined.json.is_owner).toBe(false);
    // Joining twice is harmless.
    expect((await call('POST', '/teams/join', { code: created.json.code }, pupil.access_token)).json.members).toBe(2);

    await call('POST', '/missions/m_unplug/complete', {}, pupil.access_token);
    await call('POST', '/missions/m_read_20/complete', {}, pupil.access_token);
    await call('POST', '/missions/m_unplug/complete', {}, teacher.access_token);

    const list = await call('GET', '/teams', undefined, teacher.access_token);
    expect(list.json.teams[0].missions_this_week).toBe(3);

    const detail = await call('GET', `/teams/${created.json.id}`, undefined, pupil.access_token);
    expect(detail.json.leaderboard.map((m: any) => [m.missions, m.is_me])).toEqual([
      [2, true],
      [1, false],
    ]);
  });

  it('gives the team creator class insights and lets them remove members', async () => {
    const teacher = await newUser();
    const pupil = await newUser();
    const outsider = await newUser();
    const team = (await call('POST', '/teams', { name: 'Class 8A' }, teacher.access_token)).json;
    await call('POST', '/teams/join', { code: team.code }, pupil.access_token);

    await call('POST', '/me/lessons/6/read', {}, pupil.access_token);
    await call('POST', '/missions/m_short_shower/complete', {}, pupil.access_token);
    await call('POST', '/games/complete', {
      game_id: 'quiz', score: 1, total: 3,
      per_sdg: [{ sdg_number: 13, correct: 1, total: 3 }],
    }, pupil.access_token);

    // Only the creator sees insights; outsiders cannot tell the team exists.
    expect((await call('GET', `/teams/${team.id}/insights`, undefined, pupil.access_token)).status).toBe(403);
    expect((await call('GET', `/teams/${team.id}/insights`, undefined, outsider.access_token)).status).toBe(404);

    const res = await call('GET', `/teams/${team.id}/insights`, undefined, teacher.access_token);
    expect(res.status).toBe(200);
    const insights = res.json;
    expect(insights.totals).toMatchObject({ members: 2, active_this_week: 1, missions_this_week: 1, lessons_read: 1 });
    const p = insights.students.find((x: any) => x.user_id === pupil.user.id);
    expect(p).toMatchObject({ lessons_read: 1, quiz_correct: 1, quiz_total: 3, missions_this_week: 1, stars: 1 });
    expect(p.last_active).not.toBeNull();
    expect(insights.students.find((x: any) => x.is_me).last_active).toBeNull();
    expect(insights.goals).toHaveLength(17);
    expect(insights.goals[5]).toMatchObject({ sdg_number: 6, lessons_read: 1, missions: 1, average_stars: 0.5 });
    expect(insights.goals[12]).toMatchObject({ quiz_correct: 1, quiz_total: 3 });

    expect((await call('DELETE', `/teams/${team.id}/members/${teacher.user.id}`, undefined, pupil.access_token)).status).toBe(403);
    expect((await call('DELETE', `/teams/${team.id}/members/${teacher.user.id}`, undefined, teacher.access_token)).status).toBe(400);
    expect((await call('DELETE', `/teams/${team.id}/members/${pupil.user.id}`, undefined, teacher.access_token)).status).toBe(200);
    expect((await call('GET', `/teams/${team.id}`, undefined, pupil.access_token)).status).toBe(404);
  });

  it('rejects bad codes, hides other teams and cleans up empty teams', async () => {
    const a = await newUser();
    const b = await newUser();
    expect((await call('POST', '/teams/join', { code: 'ZZZZZZ' }, a.access_token)).status).toBe(404);
    expect((await call('POST', '/teams/join', { code: 'no' }, a.access_token)).status).toBe(400);

    const t = (await call('POST', '/teams', { name: 'Solo' }, a.access_token)).json;
    expect((await call('GET', `/teams/${t.id}`, undefined, b.access_token)).status).toBe(404);

    await call('POST', `/teams/${t.id}/leave`, {}, a.access_token);
    expect((await call('GET', '/teams', undefined, a.access_token)).json.teams).toEqual([]);
    expect((await call('POST', '/teams/join', { code: t.code }, b.access_token)).status).toBe(404);
  });

  it('limits how many teams one person can be in', async () => {
    const u = await newUser();
    for (let i = 0; i < 5; i++) {
      expect((await call('POST', '/teams', { name: `Team ${i}` }, u.access_token)).status).toBe(201);
    }
    expect((await call('POST', '/teams', { name: 'One too many' }, u.access_token)).status).toBe(409);
  });

  it('starts the week on Monday (UTC)', async () => {
    const { weekStart } = await import('../src/routes/teams');
    expect(weekStart(new Date('2026-03-10T12:00:00Z'))).toBe('2026-03-09'); // Tuesday
    expect(weekStart(new Date('2026-03-15T23:00:00Z'))).toBe('2026-03-09'); // Sunday
    expect(weekStart(new Date('2026-03-16T00:30:00Z'))).toBe('2026-03-16'); // Monday
  });
});

describe('account deletion', () => {
  it('requires the password and removes the user and their data', async () => {
    const { createApp } = await import('../src/app');
    const deleted: string[] = [];
    const app2 = createApp(() => ({
      db,
      config: { ...config, deletePhoto: async (k: string) => void deleted.push(k) },
    }));
    const req = (method: string, path: string, body?: unknown, token?: string) =>
      app2.request(path, {
        method,
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
        body: body === undefined ? undefined : JSON.stringify(body),
      });

    const s = await newUser();
    const email = `user${n}@example.com`;
    await call('POST', '/missions/m_unplug/complete', { photo_key: `mission-photos/${s.user.id}/a.jpg` }, s.access_token);
    const team = (await call('POST', '/teams', { name: 'Only me' }, s.access_token)).json;

    expect((await req('DELETE', '/me', { password: 'wrong-pass' }, s.access_token)).status).toBe(403);
    const ok = await req('DELETE', '/me', { password: 'secret123' }, s.access_token);
    expect(ok.status).toBe(200);
    // The mission photo is removed from storage too.
    expect(deleted).toEqual([`mission-photos/${s.user.id}/a.jpg`]);

    expect((await call('POST', '/auth/login', { email, password: 'secret123' })).status).toBe(401);
    expect((await call('POST', '/auth/refresh', { refresh_token: s.refresh_token })).status).toBe(401);
    const left = await db.query('select count(*)::int as n from mission_completions m join users u on u.id = m.user_id where u.email = $1', [email]);
    expect((left[0] as { n: number }).n).toBe(0);
    expect(await db.query('select 1 from teams where id = $1', [team.id])).toEqual([]);
  });
});

describe('learning path', () => {
  it('awards a star each for lesson, quiz accuracy and missions', async () => {
    const s = await newUser();
    const mastery = async () =>
      (await call('GET', '/me/mastery', undefined, s.access_token)).json.goals.find((g: any) => g.sdg_number === 6);

    expect((await mastery()).stars).toBe(0);
    expect((await call('POST', '/me/lessons/6/read', {}, s.access_token)).status).toBe(200);
    expect((await call('POST', '/me/lessons/99/read', {}, s.access_token)).status).toBe(404);
    expect((await mastery()).stars).toBe(1);

    await call('POST', '/games/complete', {
      game_id: 'quiz', score: 4, total: 5,
      per_sdg: [{ sdg_number: 6, correct: 2, total: 2 }, { sdg_number: 13, correct: 2, total: 3 }],
    }, s.access_token);
    const afterQuiz = await mastery();
    expect([afterQuiz.quiz_correct, afterQuiz.quiz_total, afterQuiz.stars]).toEqual([2, 2, 2]);

    await call('POST', '/missions/m_short_shower/complete', {}, s.access_token);
    await call('POST', '/missions/m_turn_off_tap/complete', {}, s.access_token);
    const full = await mastery();
    expect([full.missions, full.stars]).toEqual([2, 3]);

    const all = (await call('GET', '/me/mastery', undefined, s.access_token)).json;
    expect(all.goals).toHaveLength(17);
    expect(all.total_stars).toBe(3 + 0); // SDG 13 quiz was 2/3 (67%) – below 70%
  });

  it('ignores per-goal results that do not add up', async () => {
    const s = await newUser();
    await call('POST', '/games/complete', {
      game_id: 'quiz', score: 2, total: 2,
      per_sdg: [{ sdg_number: 1, correct: 9, total: 9 }],
    }, s.access_token);
    const g1 = (await call('GET', '/me/mastery', undefined, s.access_token)).json.goals[0];
    expect(g1.quiz_total).toBe(0);
  });
});

describe('achievements and monthly challenges', () => {
  it('reports lifetime stats and keeps the best streak', async () => {
    const s = await newUser();
    await call('POST', '/missions/m_short_shower/complete', {}, s.access_token);
    await call('POST', '/missions/m_unplug/complete', {}, s.access_token);
    await call('POST', '/games/complete', { game_id: 'quiz', score: 3, total: 3 }, s.access_token);
    await call('POST', '/games/complete', { game_id: 'trash_sort', score: 5, total: 10 }, s.access_token);
    await call('POST', '/me/lessons/6/read', {}, s.access_token);

    const stats = (await call('GET', '/me/stats', undefined, s.access_token)).json;
    expect(stats).toMatchObject({
      missions: 2,
      mission_goals: 2,
      games_played: 2,
      distinct_games: 2,
      quiz_rounds: 1,
      perfect_quizzes: 1,
      lessons_read: 1,
      teams: 0,
      streak: 1,
      best_streak: 1,
      challenges_completed: 0,
    });
    expect(stats.xp).toBeGreaterThan(0);
    expect(stats.challenge.target).toBeGreaterThan(0);
    expect(stats.challenge.sdgs.length).toBeGreaterThan(0);
  });

  it('counts theme missions this month and pays the reward once', async () => {
    const s = await newUser();
    const savedClock = clock;
    const first = (await call('GET', '/me/stats', undefined, s.access_token)).json.challenge;
    expect(first).toMatchObject({ progress: 0, completed: false, claimed: false });
    expect((await call('POST', '/me/challenge/claim', {}, s.access_token)).status).toBe(409);

    // Complete theme missions on several days (5 missions per day max).
    const themeMissions = [...missions.values()].filter((m) => first.sdgs.includes(m.sdgNumber));
    let done = 0;
    for (let day = 0; done < first.target && day < 31; day++) {
      clock = new Date(Date.parse(first.month + '-01T12:00:00Z') + day * 86_400_000);
      for (const m of themeMissions) {
        if (done >= first.target) break;
        const r = await call('POST', `/missions/${m.id}/complete`, {}, s.access_token);
        if (r.status === 200 && !r.json.capped) done++;
      }
    }
    const status = (await call('GET', '/me/stats', undefined, s.access_token)).json.challenge;
    expect(status).toMatchObject({ progress: first.target, completed: true, claimed: false });

    const claim = await call('POST', '/me/challenge/claim', {}, s.access_token);
    expect(claim.status).toBe(200);
    expect(claim.json.xp_earned).toBe(first.reward_xp);
    expect(claim.json.challenge.claimed).toBe(true);
    expect((await call('POST', '/me/challenge/claim', {}, s.access_token)).status).toBe(409);
    expect((await call('GET', '/me/stats', undefined, s.access_token)).json.challenges_completed).toBe(1);
    clock = savedClock;
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

  it('stores up to three focus SDGs', async () => {
    const s = await newUser();
    expect(s.user.focus_sdgs).toEqual([]);
    const upd = await call('PATCH', '/me', { focus_sdgs: [13, 6, 13] }, s.access_token);
    expect(upd.json.focus_sdgs).toEqual([13, 6]);
    expect((await call('PATCH', '/me', { focus_sdgs: [1, 2, 3, 4] }, s.access_token)).status).toBe(400);
    expect((await call('PATCH', '/me', { focus_sdgs: [18] }, s.access_token)).status).toBe(400);
    expect((await call('GET', '/me', undefined, s.access_token)).json.focus_sdgs).toEqual([13, 6]);
  });

  it('updates the username and validates shop packs', async () => {
    const s = await newUser();
    const upd = await call('PATCH', '/me', { username: 'Eco Hero' }, s.access_token);
    expect(upd.json.username).toBe('Eco Hero');

    // Rewards are earned, not bought: level 2 needs 100 XP.
    const locked = await call('POST', '/me/packs', { pack_id: 'cosmetic_eco_frame' }, s.access_token);
    expect(locked.status).toBe(403);
    expect(locked.json.message).toBe('Reach level 2 to unlock this.');
    for (const id of ['m_unplug', 'm_walk_instead', 'm_fan_not_ac', 'm_cleanup']) {
      await call('POST', `/missions/${id}/complete`, {}, s.access_token); // 20+30+25+30 = 105 XP
    }
    expect((await call('POST', '/me/packs', { pack_id: 'cosmetic_eco_frame' }, s.access_token)).status).toBe(201);
    expect((await call('POST', '/me/packs', { pack_id: 'cosmetic_gold_frame' }, s.access_token)).status).toBe(403);
    expect((await call('POST', '/me/packs', { pack_id: 'free_stuff' }, s.access_token)).status).toBe(400);
    expect((await call('GET', '/me/packs', undefined, s.access_token)).json.pack_ids).toEqual(['cosmetic_eco_frame']);
  });

  it('reports uploads as disabled when storage is not configured', async () => {
    const s = await newUser();
    expect((await call('POST', '/uploads/mission-photo', {}, s.access_token)).status).toBe(501);
  });
});
