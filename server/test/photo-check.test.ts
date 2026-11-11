import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { createApp } from '../src/app';
import type { AppConfig } from '../src/config';
import { createLocalDb } from '../src/local-db';
import type { PhotoChecker, PhotoVerdict } from '../src/photo-check';

// The checker is faked: tests never call the real Claude API.
let nextVerdict: PhotoVerdict | null | 'throw' | 'hang' = null;
const calls: { missionTitle: string; bytes: number }[] = [];
const fakeChecker: PhotoChecker = {
  async check(input) {
    calls.push({ missionTitle: input.missionTitle, bytes: input.image.byteLength });
    if (nextVerdict === 'throw') throw new Error('boom');
    if (nextVerdict === 'hang') return new Promise(() => {});
    return nextVerdict;
  },
};

let db: Awaited<ReturnType<typeof createLocalDb>>;
const base: Omit<AppConfig, 'photoChecker'> = {
  jwtSecret: 'test-secret-test-secret-test-secret-123',
  accessTokenTtlSeconds: 3600,
  refreshTokenTtlDays: 60,
  passwordResetUrl: 'sdgjourney://password-reset',
  mailer: { send: async () => {} },
  now: () => new Date(),
  loadPhoto: async () => new Uint8Array([0xff, 0xd8, 0xff, 1, 2, 3]),
};
let withChecker: ReturnType<typeof createApp>;
let withoutChecker: ReturnType<typeof createApp>;

beforeAll(async () => {
  db = await createLocalDb();
  withChecker = createApp(() => ({ db, config: { ...base, photoChecker: fakeChecker } }));
  withoutChecker = createApp(() => ({ db, config: { ...base } }));
});
afterAll(() => db.close());

let n = 0;
async function call(app: ReturnType<typeof createApp>, method: string, path: string, body?: unknown, token?: string) {
  const res = await app.request(path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: res.status, json: (await res.json()) as any };
}

async function user(app = withChecker) {
  n++;
  const res = await call(app, 'POST', '/auth/signup', {
    email: `photo${n}@example.com`,
    password: 'secret123',
    username: `photo${n}`,
    birth_year: 1990,
    accept_privacy: true,
  });
  return { token: res.json.access_token as string, key: `mission-photos/${res.json.user.id}/p${n}.jpg` };
}

async function latestStory(app: ReturnType<typeof createApp>, token: string) {
  return (await call(app, 'GET', '/feed/stories', undefined, token)).json.stories[0];
}

const ok = (over: Partial<PhotoVerdict> = {}): PhotoVerdict => ({
  matches: true,
  confidence: 'high',
  safe_to_share: true,
  feedback: 'Great job using a reusable bottle!',
  ...over,
});

describe('AI photo check', () => {
  it('verifies a matching, safe photo: +5 XP, public and marked verified', async () => {
    const u = await user();
    nextVerdict = ok();
    const res = await call(withChecker, 'POST', '/missions/m_reusable_bottle/complete', { photo_key: u.key }, u.token);
    expect(res.status).toBe(200);
    expect(res.json.xp_earned).toBe(20 + 5);
    expect(res.json.photo_check).toEqual({
      matches: true,
      safe_to_share: true,
      verified: true,
      bonus_xp: 5,
      feedback: 'Great job using a reusable bottle!',
    });
    expect(calls.at(-1)).toEqual({ missionTitle: 'Use a Reusable Bottle', bytes: 6 });

    const story = await latestStory(withChecker, u.token);
    expect(story.verified).toBe(true);
    expect(story.photo_url).toContain(u.key);
  });

  it('keeps unsafe photos private and never penalises', async () => {
    const u = await user();
    nextVerdict = ok({ safe_to_share: false, feedback: 'Nice work! We will keep this photo private.' });
    const res = await call(withChecker, 'POST', '/missions/m_reusable_bottle/complete', { photo_key: u.key }, u.token);
    expect(res.json.xp_earned).toBe(20);
    expect(res.json.photo_check.verified).toBe(false);
    const story = await latestStory(withChecker, u.token);
    expect(story.photo_url).toBeNull();
    expect(story.verified).toBe(false);
  });

  it('gives no bonus when the photo does not match, but still completes', async () => {
    const u = await user();
    nextVerdict = ok({ matches: false, confidence: 'low', feedback: 'Keep going – try a photo of the bottle next time.' });
    const res = await call(withChecker, 'POST', '/missions/m_reusable_bottle/complete', { photo_key: u.key }, u.token);
    expect(res.status).toBe(200);
    expect(res.json.xp_earned).toBe(20);
    expect(res.json.photo_check.matches).toBe(false);
  });

  it('completes normally and keeps the photo private if the check fails', async () => {
    for (const outcome of ['throw', null] as const) {
      const u = await user();
      nextVerdict = outcome;
      const res = await call(withChecker, 'POST', '/missions/m_reusable_bottle/complete', { photo_key: u.key }, u.token);
      expect(res.status).toBe(200);
      expect(res.json.xp_earned).toBe(20);
      expect(res.json.photo_check).toBeNull();
      expect((await latestStory(withChecker, u.token)).photo_url).toBeNull();
    }
  });

  it('ignores photo keys that belong to someone else', async () => {
    const u = await user();
    const before = calls.length;
    nextVerdict = ok();
    const res = await call(
      withChecker,
      'POST',
      '/missions/m_reusable_bottle/complete',
      { photo_key: 'mission-photos/someone-else/x.jpg' },
      u.token,
    );
    expect(res.json.photo_check).toBeNull();
    expect(calls.length).toBe(before);
  });

  it('keeps photos private when no checker is configured', async () => {
    const u = await user(withoutChecker);
    const res = await call(withoutChecker, 'POST', '/missions/m_reusable_bottle/complete', { photo_key: u.key }, u.token);
    expect(res.json.photo_check).toBeNull();
    expect((await latestStory(withoutChecker, u.token)).photo_url).toBeNull();
  });
});

describe('checkWithTimeout', () => {
  it('returns null when the check takes too long', async () => {
    const { checkWithTimeout } = await import('../src/photo-check');
    nextVerdict = 'hang';
    const result = await checkWithTimeout(
      fakeChecker,
      { image: new Uint8Array([1]), mediaType: 'image/jpeg', missionTitle: 't', missionDescription: 'd' },
      50,
    );
    expect(result).toBeNull();
  });
});
