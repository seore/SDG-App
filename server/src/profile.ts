import type { Db } from './db';
import { effectiveStreak, utcDay } from './rules';

export interface UserRow {
  id: string;
  email: string;
  username: string;
  xp: number;
  streak: number;
  last_active_on: string | Date | null;
  avatar_url: string | null;
  active_avatar_frame: string | null;
}

function dayString(v: string | Date | null): string | null {
  if (v == null) return null;
  return typeof v === 'string' ? v.slice(0, 10) : utcDay(v);
}

/** Public shape of the signed-in user's profile (snake_case, like before). */
export function toProfile(u: UserRow, now: Date) {
  const lastActive = dayString(u.last_active_on);
  return {
    id: u.id,
    email: u.email,
    username: u.username,
    xp: u.xp,
    streak: effectiveStreak(u.streak, lastActive, utcDay(now)),
    last_active_on: lastActive,
    avatar_url: u.avatar_url,
    active_avatar_frame: u.active_avatar_frame,
  };
}

export async function loadUser(db: Db, id: string): Promise<UserRow | undefined> {
  const [u] = await db.query<UserRow>(
    `select id, email, username, xp, streak, last_active_on, avatar_url, active_avatar_frame
       from users where id = $1`,
    [id],
  );
  return u;
}

export interface AwardRow {
  xp_before: number;
  xp_after: number;
  streak: number;
  bonus: number;
}

export async function awardXp(db: Db, userId: string, amount: number, today: string) {
  const [row] = await db.query<AwardRow>('select * from award_xp($1, $2, $3::date)', [
    userId,
    amount,
    today,
  ]);
  return row!;
}
