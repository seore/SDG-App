import { AwsClient } from 'aws4fetch';
import { Hono } from 'hono';

import type { StorageConfig } from '../config';
import { apiError, requireAuth, type AppEnv } from '../context';
import { randomToken } from '../crypto';

// Works with any S3-compatible store: Neon Object Storage, Cloudflare R2, S3.

function client(s: StorageConfig) {
  return new AwsClient({
    accessKeyId: s.accessKeyId,
    secretAccessKey: s.secretAccessKey,
    service: 's3',
    region: s.region,
  });
}

function objectUrl(s: StorageConfig, key: string) {
  return `${s.endpoint}/${s.bucket}/${key.split('/').map(encodeURIComponent).join('/')}`;
}

export const uploads = new Hono<AppEnv>();

/** Returns a short-lived URL the app PUTs the JPEG to directly. */
uploads.post('/uploads/mission-photo', requireAuth, async (c) => {
  const storage = c.get('config').storage;
  if (!storage) throw apiError(501, 'storage_disabled', 'Photo uploads are not set up yet.');

  const key = `mission-photos/${c.get('userId')}/${randomToken(12)}.jpg`;
  const url = new URL(objectUrl(storage, key));
  url.searchParams.set('X-Amz-Expires', '600');
  const signed = await client(storage).sign(
    new Request(url, { method: 'PUT', headers: { 'Content-Type': 'image/jpeg' } }),
    { aws: { signQuery: true } },
  );
  return c.json({ upload_url: signed.url, key, content_type: 'image/jpeg' });
});

/** Serves stored photos. Keys are random, so they're not guessable. */
uploads.get('/media/:key{.+}', async (c) => {
  const storage = c.get('config').storage;
  const key = c.req.param('key');
  if (!storage || !key.startsWith('mission-photos/') || key.includes('..')) {
    throw apiError(404, 'not_found', 'Not found.');
  }
  const res = await client(storage).fetch(objectUrl(storage, key));
  if (!res.ok) throw apiError(404, 'not_found', 'Not found.');
  return new Response(res.body, {
    headers: {
      'Content-Type': res.headers.get('Content-Type') ?? 'image/jpeg',
      'Cache-Control': 'public, max-age=86400, immutable',
    },
  });
});
