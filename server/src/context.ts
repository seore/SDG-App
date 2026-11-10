import type { Context, MiddlewareHandler } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { verify } from 'hono/jwt';

import type { AppConfig } from './config';
import type { Db } from './db';

export type AppEnv = {
  Variables: {
    db: Db;
    config: AppConfig;
    userId: string;
  };
};

export type Ctx = Context<AppEnv>;

export function apiError(status: 400 | 401 | 403 | 404 | 409 | 429 | 501, code: string, message: string) {
  return new HTTPException(status, {
    res: new Response(JSON.stringify({ error: code, message }), {
      status,
      headers: { 'Content-Type': 'application/json' },
    }),
  });
}

/** Requires a valid access token; sets `userId`. */
export const requireAuth: MiddlewareHandler<AppEnv> = async (c, next) => {
  const header = c.req.header('Authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw apiError(401, 'unauthorized', 'Sign in to continue.');
  try {
    const payload = await verify(token, c.get('config').jwtSecret, 'HS256');
    if (payload.typ !== 'access' || typeof payload.sub !== 'string') throw new Error();
    c.set('userId', payload.sub);
  } catch {
    throw apiError(401, 'invalid_token', 'Your session has expired. Sign in again.');
  }
  await next();
};

/** Base URL of this API, used to build absolute media URLs. */
export function originOf(c: Ctx): string {
  return new URL(c.req.url).origin;
}
