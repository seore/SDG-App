import { AwsClient } from 'aws4fetch';

import type { StorageConfig } from './config';

// Works with any S3-compatible store: Neon Object Storage, Cloudflare R2, S3.

export function storageClient(s: StorageConfig) {
  return new AwsClient({
    accessKeyId: s.accessKeyId,
    secretAccessKey: s.secretAccessKey,
    service: 's3',
    region: s.region,
  });
}

export function objectUrl(s: StorageConfig, key: string) {
  return `${s.endpoint}/${s.bucket}/${key.split('/').map(encodeURIComponent).join('/')}`;
}

export async function loadObject(s: StorageConfig, key: string): Promise<Uint8Array | null> {
  const res = await storageClient(s).fetch(objectUrl(s, key));
  if (!res.ok) return null;
  return new Uint8Array(await res.arrayBuffer());
}
