import { createClaudePhotoChecker, type PhotoChecker } from './photo-check';
import type { Limiter } from './rate-limit';
import { deleteObject, loadObject } from './storage';

export interface StorageConfig {
  endpoint: string; // e.g. https://<account>.r2.cloudflarestorage.com
  bucket: string;
  region: string;
  accessKeyId: string;
  secretAccessKey: string;
}

export interface Mailer {
  send(to: string, subject: string, text: string): Promise<void>;
}

export interface AppConfig {
  /** Users younger than this need a parent's consent (default 13). */
  consentAge?: number;
  /** Contact address shown in the privacy policy. */
  privacyContact?: string;
  /** Rate limiter for /auth routes (Cloudflare binding); off when unset. */
  authLimiter?: Limiter;
  /** AI photo check (Claude vision); disabled when ANTHROPIC_API_KEY is unset. */
  photoChecker?: PhotoChecker;
  /** Deletes an uploaded photo (defaults to S3 storage). */
  deletePhoto?: (key: string) => Promise<void>;
  /** Loads an uploaded photo's bytes (defaults to S3 storage). */
  loadPhoto?: (key: string) => Promise<Uint8Array | null>;
  jwtSecret: string;
  accessTokenTtlSeconds: number;
  refreshTokenTtlDays: number;
  /** Deep link the reset email points to; `?token=` is appended. */
  passwordResetUrl: string;
  storage?: StorageConfig;
  mailer: Mailer;
  /** Injectable clock so tests can move between days. */
  now: () => Date;
}

export interface EnvVars {
  DATABASE_URL?: string;
  JWT_SECRET?: string;
  RESEND_API_KEY?: string;
  EMAIL_FROM?: string;
  PASSWORD_RESET_URL?: string;
  S3_ENDPOINT?: string;
  S3_BUCKET?: string;
  S3_REGION?: string;
  S3_ACCESS_KEY_ID?: string;
  S3_SECRET_ACCESS_KEY?: string;
  ANTHROPIC_API_KEY?: string;
  CONSENT_AGE?: string;
  PRIVACY_CONTACT_EMAIL?: string;
}

/** Sends via Resend when configured; otherwise logs (local development). */
export function mailerFromEnv(env: EnvVars): Mailer {
  if (env.RESEND_API_KEY && env.EMAIL_FROM) {
    return {
      async send(to, subject, text) {
        const res = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${env.RESEND_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ from: env.EMAIL_FROM, to, subject, text }),
        });
        if (!res.ok) throw new Error(`Email failed: ${res.status}`);
      },
    };
  }
  return {
    async send(to, subject, text) {
      console.log(`[dev mailer] to=${to} subject="${subject}"\n${text}`);
    },
  };
}

export function configFromEnv(env: EnvVars): AppConfig {
  if (!env.JWT_SECRET || env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must be set (32+ characters).');
  }
  const storage =
    env.S3_ENDPOINT && env.S3_BUCKET && env.S3_ACCESS_KEY_ID && env.S3_SECRET_ACCESS_KEY
      ? {
          endpoint: env.S3_ENDPOINT.replace(/\/$/, ''),
          bucket: env.S3_BUCKET,
          region: env.S3_REGION ?? 'auto',
          accessKeyId: env.S3_ACCESS_KEY_ID,
          secretAccessKey: env.S3_SECRET_ACCESS_KEY,
        }
      : undefined;
  return {
    consentAge: env.CONSENT_AGE ? Number(env.CONSENT_AGE) : 13,
    privacyContact: env.PRIVACY_CONTACT_EMAIL,
    photoChecker: env.ANTHROPIC_API_KEY ? createClaudePhotoChecker(env.ANTHROPIC_API_KEY) : undefined,
    loadPhoto: storage ? (key) => loadObject(storage, key) : undefined,
    deletePhoto: storage ? (key) => deleteObject(storage, key) : undefined,
    jwtSecret: env.JWT_SECRET,
    accessTokenTtlSeconds: 60 * 60,
    refreshTokenTtlDays: 60,
    passwordResetUrl: env.PASSWORD_RESET_URL ?? 'sdgjourney://password-reset',
    storage,
    mailer: mailerFromEnv(env),
    now: () => new Date(),
  };
}
