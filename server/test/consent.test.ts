import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { createApp } from '../src/app';
import type { AppConfig } from '../src/config';
import { createLocalDb } from '../src/local-db';
import { minimumAge } from '../src/routes/consent';

let db: Awaited<ReturnType<typeof createLocalDb>>;
const mail: { to: string; text: string }[] = [];
const now = new Date('2026-06-01T12:00:00Z');
const config: AppConfig = {
  jwtSecret: 'test-secret-test-secret-test-secret-123',
  accessTokenTtlSeconds: 3600,
  refreshTokenTtlDays: 60,
  passwordResetUrl: 'sdgjourney://password-reset',
  mailer: { send: async (to, _s, text) => void mail.push({ to, text }) },
  now: () => now,
  consentAge: 13,
  privacyContact: 'hello@sdgjourney.example',
};
let app: ReturnType<typeof createApp>;

beforeAll(async () => {
  db = await createLocalDb();
  app = createApp(() => ({ db, config }));
});
afterAll(() => db.close());

async function call(method: string, path: string, body?: unknown, token?: string) {
  const res = await app.request(path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json: any = null;
  try {
    json = JSON.parse(text);
  } catch {
    /* html */
  }
  return { status: res.status, json, text };
}

let n = 0;
const signup = (extra: Record<string, unknown>) => {
  n++;
  return call('POST', '/auth/signup', {
    email: `kid${n}@example.com`,
    password: 'secret123',
    username: `kid${n}`,
    accept_privacy: true,
    ...extra,
  });
};

function tokenFrom(text: string) {
  return /\/consent\/([0-9a-f]+)/.exec(text)![1]!;
}

describe('age check and parental consent', () => {
  it('treats ambiguous birth years as the younger age', () => {
    expect(minimumAge(2013, now)).toBe(12); // could be 12 or 13 in 2026
    expect(minimumAge(2012, now)).toBe(13);
  });

  it('requires the privacy policy and a birth year', async () => {
    expect((await signup({ birth_year: 1990, accept_privacy: false })).json.error).toBe('privacy_not_accepted');
    expect((await signup({})).json.error).toBe('invalid_birth_year');
  });

  it('adults need no consent', async () => {
    const res = await signup({ birth_year: 2000 });
    expect(res.status).toBe(201);
    expect(res.json.user.consent_status).toBe('not_required');
  });

  it('under-13s must give a parent email that is not their own', async () => {
    expect((await signup({ birth_year: 2014 })).json.error).toBe('parent_email_required');
    n++;
    const same = await call('POST', '/auth/signup', {
      email: `kid${n}@example.com`, password: 'secret123', username: `kid${n}`,
      birth_year: 2014, accept_privacy: true, parent_email: `kid${n}@example.com`,
    });
    expect(same.json.error).toBe('invalid_parent_email');
  });

  it('pending children can play privately but not share; approval unlocks sharing', async () => {
    const res = await signup({ birth_year: 2015, parent_email: 'parent@example.com' });
    expect(res.status).toBe(201);
    expect(res.json.user.consent_status).toBe('pending');
    const token = res.json.access_token;

    const email = mail.find((m) => m.to === 'parent@example.com')!;
    expect(email.text).toContain('under 13');
    const consentToken = tokenFrom(email.text);

    // Missions still count, but nothing is shared.
    const done = await call('POST', '/missions/m_walk_instead/complete', { lat: 51.5, lng: -0.1 }, token);
    expect(done.status).toBe(200);
    expect(done.json.xp_earned).toBe(30);
    const feed = await call('GET', '/feed/completions', undefined, token);
    const mine = feed.json.completions.find((c: any) => c.is_mine);
    expect(mine.lat).toBeNull();
    const stories = await call('GET', '/feed/stories', undefined, token);
    expect(stories.json.stories.some((s: any) => s.user_name === res.json.user.username)).toBe(false);
    expect((await call('POST', '/teams', { name: 'My class' }, token)).json.error).toBe('consent_required');

    // Parent opens the page and approves.
    const pageRes = await app.request(`/consent/${consentToken}`);
    expect(pageRes.status).toBe(200);
    expect(await pageRes.text()).toContain('Approve');
    const approve = await app.request(`/consent/${consentToken}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'decision=approve',
    });
    expect(await approve.text()).toContain('Thank you');

    expect((await call('GET', '/me', undefined, token)).json.consent_status).toBe('granted');
    expect((await call('POST', '/teams', { name: 'My class' }, token)).status).toBe(201);
  });

  it('a parent can decline, which deletes the account', async () => {
    const res = await signup({ birth_year: 2016, parent_email: 'parent2@example.com' });
    const consentToken = tokenFrom(mail.find((m) => m.to === 'parent2@example.com')!.text);
    const decline = await app.request(`/consent/${consentToken}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'decision=decline',
    });
    expect(await decline.text()).toContain('Account deleted');
    expect((await call('GET', '/me', undefined, res.json.access_token)).status).toBe(401);
    expect((await app.request(`/consent/${consentToken}`)).status).toBe(404);
  });

  it('can resend the request to a corrected parent email', async () => {
    const res = await signup({ birth_year: 2015, parent_email: 'typo@example.com' });
    const resend = await call('POST', '/me/consent/resend', { parent_email: 'Real.Parent@example.com' }, res.json.access_token);
    expect(resend.status).toBe(200);
    expect(mail.at(-1)!.to).toBe('real.parent@example.com');
  });

  it('serves a privacy policy with the contact address', async () => {
    const res = await app.request('/privacy');
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).toContain('hello@sdgjourney.example');
    expect(html).toContain('under 13');
  });
});
