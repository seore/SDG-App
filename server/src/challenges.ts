import calendar from '../../goalquest/assets/content/monthly_challenges.json';

export interface MonthlyChallenge {
  month: number;
  id: string;
  title: string;
  sdgs: number[];
  observance: string | null;
  blurb: string;
}

export const CHALLENGE_TARGET = calendar.target_missions;
export const CHALLENGE_REWARD_XP = calendar.reward_xp;

/** The challenge for [now]'s UTC month, and its "YYYY-MM" key. */
export function challengeFor(now: Date): { key: string; start: string; end: string; challenge: MonthlyChallenge } {
  const y = now.getUTCFullYear();
  const m = now.getUTCMonth() + 1;
  const challenge = (calendar.months as MonthlyChallenge[]).find((c) => c.month === m)!;
  const pad = (n: number) => String(n).padStart(2, '0');
  const next = m === 12 ? `${y + 1}-01-01` : `${y}-${pad(m + 1)}-01`;
  return { key: `${y}-${pad(m)}`, start: `${y}-${pad(m)}-01`, end: next, challenge };
}
