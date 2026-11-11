import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { HTTPException } from 'hono/http-exception';

import type { AppConfig } from './config';
import type { AppEnv, Ctx } from './context';
import type { Db } from './db';
import { activity } from './routes/activity';
import { auth } from './routes/auth';
import { consent } from './routes/consent';
import { privacy } from './routes/privacy';
import { feed } from './routes/feed';
import { me } from './routes/me';
import { teams } from './routes/teams';
import { uploads } from './routes/uploads';

export interface Deps {
  db: Db;
  config: AppConfig;
}

/**
 * Builds the API. `resolve` supplies dependencies per request, because on
 * Cloudflare Workers bindings (env) are only available inside a request.
 */
export function createApp(resolve: (c: Ctx) => Deps) {
  const app = new Hono<AppEnv>();

  app.use('*', cors()); // the Flutter web build calls the API from another origin
  app.use('*', async (c, next) => {
    const deps = resolve(c);
    c.set('db', deps.db);
    c.set('config', deps.config);
    await next();
  });

  app.get('/health', (c) => c.json({ ok: true }));
  app.route('/auth', auth);
  app.route('/', privacy);
  app.route('/', consent);
  app.route('/me', me);
  app.route('/feed', feed);
  app.route('/teams', teams);
  app.route('/', activity);
  app.route('/', uploads);

  app.notFound((c) => c.json({ error: 'not_found', message: 'Not found.' }, 404));
  app.onError((err, c) => {
    if (err instanceof HTTPException) return err.getResponse();
    console.error(err);
    return c.json({ error: 'server_error', message: 'Something went wrong. Please try again.' }, 500);
  });

  return app;
}
