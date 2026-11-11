import { Hono } from 'hono';
import { z } from 'zod';

import type { AppConfig } from '../config';
import { apiError, originOf, requireAuth, type AppEnv, type Ctx } from '../context';
import { randomToken, sha256 } from '../crypto';
import type { Db } from '../db';

/** Minimum age (in years) that doesn't need parental consent. */
export function consentAge(config: AppConfig): number {
  return config.consentAge ?? 13;
}

/**
 * Youngest age someone born in [birthYear] can be today. Using the lower
 * bound means anyone who *might* be under the threshold is treated as such.
 */
export function minimumAge(birthYear: number, now: Date): number {
  return now.getUTCFullYear() - birthYear - 1;
}

export function needsParentalConsent(birthYear: number, config: AppConfig): boolean {
  return minimumAge(birthYear, config.now()) < consentAge(config);
}

/** Creates a consent token and emails the parent a link to approve. */
export async function requestParentalConsent(
  c: Ctx,
  db: Db,
  user: { id: string; username: string },
  parentEmail: string,
): Promise<void> {
  const config = c.get('config');
  const token = randomToken();
  await db.query(
    `update users set parent_email = $2, consent_token_hash = $3,
            consent_requested_at = now(), consent_status = 'pending'
      where id = $1`,
    [user.id, parentEmail, await sha256(token)],
  );
  const link = `${originOf(c)}/consent/${token}`;
  await config.mailer.send(
    parentEmail,
    `Your child wants to join SDG Journey`,
    `Hello,

Someone using the name "${user.username}" has signed up for SDG Journey, an app that helps young people learn about the UN Sustainable Development Goals through small daily actions, lessons and games.

Because they told us they are under ${consentAge(config)}, we need a parent or guardian's permission before they can share anything with other users (stories, photos, map location or class teams). Until then they can only learn and play privately.

Review what the app collects and approve or decline here:
${link}

If you don't recognise this, you can decline and the account will be deleted.

– The SDG Journey team`,
  );
}

const page = (title: string, body: string) => `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  body{font-family:-apple-system,system-ui,sans-serif;max-width:620px;margin:0 auto;padding:24px;color:#101828;line-height:1.55;background:#f6f7f9}
  .card{background:#fff;border:1px solid #e4e7ec;border-radius:16px;padding:24px}
  h1{font-size:22px;margin-top:0} li{margin:4px 0} .muted{color:#667085;font-size:14px}
  button{font:inherit;font-weight:600;border-radius:12px;padding:12px 18px;border:0;cursor:pointer;margin:6px 8px 0 0}
  .ok{background:#0F766E;color:#fff} .no{background:#fff;color:#b42318;border:1px solid #fda29b}
</style></head><body><div class="card">${body}</div></body></html>`;

function escapeHtml(s: string) {
  return s.replace(/[&<>"']/g, (ch) => `&#${ch.charCodeAt(0)};`);
}

export const consent = new Hono<AppEnv>();

/** Page the parent opens from the email. */
consent.get('/consent/:token', async (c) => {
  const [user] = await c.get('db').query<{ username: string; consent_status: string }>(
    'select username, consent_status from users where consent_token_hash = $1',
    [await sha256(c.req.param('token'))],
  );
  if (!user) {
    return c.html(page('Link not valid', '<h1>This link is no longer valid</h1><p>It may have been used already, or the account was deleted.</p>'), 404);
  }
  if (user.consent_status === 'granted') {
    return c.html(page('Already approved', `<h1>Already approved</h1><p>${escapeHtml(user.username)} already has your permission. Thank you!</p>`));
  }
  const name = escapeHtml(user.username);
  return c.html(
    page(
      'Parental consent – SDG Journey',
      `<h1>Allow ${name} to use SDG Journey?</h1>
      <p>SDG Journey helps young people learn about the UN Sustainable Development Goals through small daily actions, lessons and games.</p>
      <p><strong>What we collect:</strong></p>
      <ul>
        <li>Email address, username and birth year</li>
        <li>Missions completed, quiz and game scores</li>
        <li>If allowed: optional mission photos (checked automatically; faces and personal details are never shown publicly) and an approximate location (rounded to about 1&nbsp;km) for the community map</li>
      </ul>
      <p><strong>What approving allows:</strong> showing ${name}'s username, completed missions and checked photos to other users, and joining class or friend teams.</p>
      <p class="muted">We don't show adverts or sell data. You can ask us to delete the account at any time, and ${name} can delete it from the app. Read the full <a href="/privacy">privacy policy</a>.</p>
      <form method="post"><button class="ok" name="decision" value="approve">Approve</button>
      <button class="no" name="decision" value="decline">Decline and delete the account</button></form>`,
    ),
  );
});

consent.post('/consent/:token', async (c) => {
  const db = c.get('db');
  const form = await c.req.parseBody();
  const decision = form['decision'];
  const tokenHash = await sha256(c.req.param('token'));
  const [user] = await db.query<{ id: string; username: string }>(
    'select id, username from users where consent_token_hash = $1',
    [tokenHash],
  );
  if (!user) return c.html(page('Link not valid', '<h1>This link is no longer valid</h1>'), 404);

  if (decision === 'decline') {
    await db.query('delete from users where id = $1', [user.id]);
    return c.html(page('Account deleted', '<h1>Account deleted</h1><p>The account and its data have been deleted. Thank you for letting us know.</p>'));
  }
  await db.query(
    `update users set consent_status = 'granted', consent_granted_at = now() where id = $1`,
    [user.id],
  );
  return c.html(
    page('Approved', `<h1>Thank you!</h1><p>${escapeHtml(user.username)} can now share stories and join teams in SDG Journey.</p>`),
  );
});

/** Resend the consent email, optionally to a corrected parent address. */
consent.post('/me/consent/resend', requireAuth, async (c) => {
  const body = z
    .object({ parent_email: z.string().trim().toLowerCase().email().max(254).optional() })
    .safeParse(await c.req.json().catch(() => ({})));
  if (!body.success) throw apiError(400, 'invalid_input', "Enter your parent's email address.");
  const db = c.get('db');
  const [user] = await db.query<{ id: string; username: string; email: string; consent_status: string; parent_email: string | null }>(
    'select id, username, email, consent_status, parent_email from users where id = $1',
    [c.get('userId')],
  );
  if (!user || user.consent_status !== 'pending') {
    throw apiError(400, 'not_pending', 'No parent approval is needed.');
  }
  const parentEmail = body.data.parent_email ?? user.parent_email;
  if (!parentEmail || parentEmail === user.email.toLowerCase()) {
    throw apiError(400, 'invalid_parent_email', "Use your parent's email, not your own.");
  }
  await requestParentalConsent(c, db, user, parentEmail);
  return c.json({ ok: true });
});

/** Throws if the signed-in user still needs a parent's approval. */
export async function assertConsent(c: Ctx): Promise<void> {
  const [row] = await c
    .get('db')
    .query<{ consent_status: string }>('select consent_status from users where id = $1', [c.get('userId')]);
  if (row?.consent_status === 'pending') {
    throw apiError(403, 'consent_required', 'A parent needs to approve your account before you can do this.');
  }
}

/** True if the user may share things with others (stories, map, photos). */
export async function canShare(db: Db, userId: string): Promise<boolean> {
  const [row] = await db.query<{ consent_status: string }>('select consent_status from users where id = $1', [userId]);
  return row?.consent_status !== 'pending';
}
