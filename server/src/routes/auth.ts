import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import { z } from 'zod';

import { apiError, type AppEnv, type Ctx } from '../context';
import { hashPassword, randomToken, sha256, verifyPassword } from '../crypto';
import { loadUser, toProfile, type UserRow } from '../profile';
import { authRateLimit } from '../rate-limit';
import { needsParentalConsent, requestParentalConsent } from './consent';

const email = z.string().trim().toLowerCase().email().max(254);
const password = z.string().min(6).max(200);
const username = z.string().trim().min(2).max(24);

async function issueSession(c: Ctx, user: UserRow) {
  const { db, ...rest } = { db: c.get('db'), ...c.get('config') };
  const now = rest.now();
  // JWT expiry is checked against the real clock by the JWT library, so use
  // real time here; `now()` (injectable) only drives day-based rules.
  const nowSec = Math.floor(Date.now() / 1000);

  const accessToken = await sign(
    { sub: user.id, typ: 'access', iat: nowSec, exp: nowSec + rest.accessTokenTtlSeconds },
    rest.jwtSecret,
    'HS256',
  );
  const refreshToken = randomToken();
  const expires = new Date(now.getTime() + rest.refreshTokenTtlDays * 86_400_000);
  await db.query('insert into sessions (user_id, token_hash, expires_at) values ($1, $2, $3)', [
    user.id,
    await sha256(refreshToken),
    expires.toISOString(),
  ]);

  return {
    access_token: accessToken,
    refresh_token: refreshToken,
    expires_in: rest.accessTokenTtlSeconds,
    user: toProfile(user, now),
  };
}

export const auth = new Hono<AppEnv>();
auth.use('*', authRateLimit);

auth.post('/signup', async (c) => {
  const config = c.get('config');
  const thisYear = config.now().getUTCFullYear();
  const body = z
    .object({
      email,
      password,
      username,
      birth_year: z.number().int().min(thisYear - 120).max(thisYear),
      parent_email: email.optional(),
      accept_privacy: z.literal(true),
    })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) {
    const missing = body.error.issues.map((i) => i.path[0]);
    if (missing.includes('accept_privacy')) {
      throw apiError(400, 'privacy_not_accepted', 'Please agree to the privacy policy to continue.');
    }
    if (missing.includes('birth_year')) {
      throw apiError(400, 'invalid_birth_year', 'Enter the year you were born.');
    }
    throw apiError(400, 'invalid_input', 'Check your username, email and password.');
  }

  const childNeedsConsent = needsParentalConsent(body.data.birth_year, config);
  if (childNeedsConsent) {
    if (!body.data.parent_email) {
      throw apiError(400, 'parent_email_required', "Enter a parent or guardian's email so they can approve your account.");
    }
    if (body.data.parent_email === body.data.email) {
      throw apiError(400, 'invalid_parent_email', "Use your parent's email, not your own.");
    }
  }

  const db = c.get('db');
  const exists = await db.query('select 1 from users where lower(email) = $1', [body.data.email]);
  if (exists.length) {
    throw apiError(409, 'email_taken', 'An account with this email already exists. Try logging in.');
  }

  const [user] = await db.query<UserRow>(
    `insert into users (email, password_hash, username, birth_year, privacy_accepted_at)
     values ($1, $2, $3, $4, now())
     returning id, email, username, xp, streak, last_active_on, avatar_url, active_avatar_frame,
               focus_sdgs, consent_status`,
    [body.data.email, await hashPassword(body.data.password), body.data.username, body.data.birth_year],
  );
  if (childNeedsConsent) {
    await requestParentalConsent(c, db, user!, body.data.parent_email!);
    user!.consent_status = 'pending';
  }
  return c.json(await issueSession(c, user!), 201);
});

auth.post('/login', async (c) => {
  const body = z
    .object({ email, password: z.string().max(200) })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Enter your email and password.');

  const [row] = await c
    .get('db')
    .query<UserRow & { password_hash: string }>(
      `select id, email, username, xp, streak, last_active_on, avatar_url, active_avatar_frame,
              focus_sdgs, consent_status, password_hash
         from users where lower(email) = $1`,
      [body.data.email],
    );
  // Same message either way so emails can't be probed.
  if (!row || !(await verifyPassword(body.data.password, row.password_hash))) {
    throw apiError(401, 'invalid_credentials', 'Incorrect email or password.');
  }
  return c.json(await issueSession(c, row));
});

auth.post('/refresh', async (c) => {
  const body = z
    .object({ refresh_token: z.string().min(10) })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Missing refresh token.');

  const db = c.get('db');
  const now = c.get('config').now();
  // Rotate: the old refresh token is consumed whatever happens next.
  const [session] = await db.query<{ user_id: string; expires_at: string | Date }>(
    'delete from sessions where token_hash = $1 returning user_id, expires_at',
    [await sha256(body.data.refresh_token)],
  );
  if (!session || new Date(session.expires_at) < now) {
    throw apiError(401, 'invalid_token', 'Your session has expired. Sign in again.');
  }
  const user = await loadUser(db, session.user_id);
  if (!user) throw apiError(401, 'invalid_token', 'Your session has expired. Sign in again.');
  return c.json(await issueSession(c, user));
});

auth.post('/logout', async (c) => {
  const body = await c.req.json().catch(() => ({}));
  if (typeof body?.refresh_token === 'string') {
    await c
      .get('db')
      .query('delete from sessions where token_hash = $1', [await sha256(body.refresh_token)]);
  }
  return c.json({ ok: true });
});

auth.post('/forgot-password', async (c) => {
  const body = z.object({ email }).safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Enter a valid email.');

  const { db, ...config } = { db: c.get('db'), ...c.get('config') };
  const [user] = await db.query<{ id: string; email: string }>(
    'select id, email from users where lower(email) = $1',
    [body.data.email],
  );
  // Always respond the same way so this can't be used to find accounts.
  if (user) {
    const token = randomToken();
    const expires = new Date(config.now().getTime() + 30 * 60_000);
    await db.query(
      'insert into password_resets (token_hash, user_id, expires_at) values ($1, $2, $3)',
      [await sha256(token), user.id, expires.toISOString()],
    );
    const link = `${config.passwordResetUrl}?token=${token}`;
    await config.mailer.send(
      user.email,
      'Reset your SDG Journey password',
      `Tap the link below on your phone to choose a new password. It expires in 30 minutes.\n\n${link}\n\nIf you didn't ask for this, you can ignore this email.`,
    );
  }
  return c.json({ ok: true });
});

auth.post('/reset-password', async (c) => {
  const body = z
    .object({ token: z.string().min(10), password })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Use at least 6 characters.');

  const db = c.get('db');
  const now = c.get('config').now();
  const [reset] = await db.query<{ user_id: string }>(
    `update password_resets set used_at = $2
      where token_hash = $1 and used_at is null and expires_at > $2
      returning user_id`,
    [await sha256(body.data.token), now.toISOString()],
  );
  if (!reset) {
    throw apiError(400, 'invalid_token', 'This reset link has expired. Request a new one.');
  }
  await db.query('update users set password_hash = $2 where id = $1', [
    reset.user_id,
    await hashPassword(body.data.password),
  ]);
  // Sign out everywhere after a password change.
  await db.query('delete from sessions where user_id = $1', [reset.user_id]);
  return c.json({ ok: true });
});
