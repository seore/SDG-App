// Web Crypto only, so this runs on both Cloudflare Workers and Node.

const enc = new TextEncoder();
// Cloudflare Workers caps PBKDF2 at 100k iterations.
const ITERATIONS = 100_000;

function toHex(buf: ArrayBuffer | Uint8Array): string {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function fromHex(hex: string): Uint8Array {
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) out[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  return out;
}

async function pbkdf2(password: string, salt: Uint8Array, iterations: number): Promise<string> {
  const key = await crypto.subtle.importKey('raw', enc.encode(password), 'PBKDF2', false, [
    'deriveBits',
  ]);
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations },
    key,
    256,
  );
  return toHex(bits);
}

/** Format: pbkdf2$<iterations>$<saltHex>$<hashHex> */
export async function hashPassword(password: string): Promise<string> {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  return `pbkdf2$${ITERATIONS}$${toHex(salt)}$${await pbkdf2(password, salt, ITERATIONS)}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [scheme, iter, saltHex, hashHex] = stored.split('$');
  if (scheme !== 'pbkdf2' || !iter || !saltHex || !hashHex) return false;
  const candidate = await pbkdf2(password, fromHex(saltHex), Number(iter));
  // Constant-time comparison.
  if (candidate.length !== hashHex.length) return false;
  let diff = 0;
  for (let i = 0; i < candidate.length; i++) diff |= candidate.charCodeAt(i) ^ hashHex.charCodeAt(i);
  return diff === 0;
}

export function randomToken(bytes = 32): string {
  return toHex(crypto.getRandomValues(new Uint8Array(bytes)));
}

export async function sha256(value: string): Promise<string> {
  return toHex(await crypto.subtle.digest('SHA-256', enc.encode(value)));
}
