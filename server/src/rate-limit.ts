import type { MiddlewareHandler } from 'hono';

import { apiError, type AppEnv } from './context';

/**
 * Matches Cloudflare's Rate Limiting binding (`RateLimit`), so tests and the
 * Node dev server can supply their own implementation.
 */
export interface Limiter {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

/**
 * Limits auth requests to slow down password guessing and sign-up spam.
 *
 * Keys follow Cloudflare's advice to prefer stable identifiers over IPs:
 * login / forgot-password are keyed by the email being tried, reset by the
 * token; only sign-up (no identifier yet) falls back to the client IP.
 */
export const authRateLimit: MiddlewareHandler<AppEnv> = async (c, next) => {
  const limiter = c.get('config').authLimiter;
  if (!limiter || c.req.method !== 'POST') return next();

  const path = new URL(c.req.url).pathname;
  // Hono caches the parsed body, so the route can read it again.
  const body = (await c.req.json().catch(() => null)) as Record<string, unknown> | null;
  const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : null;
  const token = typeof body?.token === 'string' ? body.token : null;
  const ip = c.req.header('CF-Connecting-IP') ?? c.req.header('X-Forwarded-For') ?? 'unknown';

  let key: string | null = null;
  if (path.endsWith('/login') || path.endsWith('/forgot-password')) key = email && `${path}:${email}`;
  else if (path.endsWith('/reset-password')) key = token && `${path}:${token}`;
  else if (path.endsWith('/signup')) key = `${path}:${ip}`;

  if (key) {
    const { success } = await limiter.limit({ key });
    if (!success) {
      throw apiError(429, 'too_many_attempts', 'Too many attempts. Please wait a minute and try again.');
    }
  }
  await next();
};
