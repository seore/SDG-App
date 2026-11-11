// Server-side reward rules. The app only reports what happened; the server
// decides how much XP that is worth, so a modified client can't award itself
// arbitrary XP.

import catalog from '../../goalquest/assets/content/missions.json';

export interface MissionDef {
  id: string;
  title: string;
  description: string;
  sdgNumber: number;
  sdg: string;
  xp: number;
  /** Rough real-world impact estimate for one completion. */
  /** `basis` states the assumptions behind the estimate. */
  impact?: { metric: string; amount: number; basis?: string } | null;
}

export const impactMetrics = new Set([
  'co2_kg',
  'water_l',
  'plastic_items',
  'waste_items',
  'food_kg',
  'people_reached',
  'learning_minutes',
  'active_minutes',
  'nature',
]);

export const missions: ReadonlyMap<string, MissionDef> = new Map(
  (catalog.missions as MissionDef[]).map((m) => [m.id, m]),
);

/** Extra XP when the AI photo check confirms the mission (never a penalty). */
export const PHOTO_VERIFIED_BONUS_XP = 5;

/** Matches the five daily missions shown in the app. */
export const MAX_MISSIONS_PER_DAY = 5;

/** Plays per game per day that still earn XP (later plays are recorded, unrewarded). */
export const REWARDED_PLAYS_PER_GAME_PER_DAY = 3;

export interface GameRule {
  sdgNumber: number;
  /** Highest plausible `total` for a round of this game. */
  maxTotal: number;
  xpFor(score: number, total: number): number;
}

const perCorrect =
  (xp: number) =>
  (score: number): number =>
    score * xp;

export const games: Record<string, GameRule> = {
  quiz: { sdgNumber: 4, maxTotal: 20, xpFor: perCorrect(10) },
  sdg_match: { sdgNumber: 4, maxTotal: 17, xpFor: perCorrect(8) },
  water_guardian: { sdgNumber: 6, maxTotal: 10, xpFor: perCorrect(10) },
  trash_sort: { sdgNumber: 12, maxTotal: 20, xpFor: perCorrect(5) },
  // City score is 0–40; XP is 2× the score, between 10 and 80.
  city_fix: {
    sdgNumber: 11,
    maxTotal: 40,
    xpFor: (score) => Math.min(80, Math.max(10, score * 2)),
  },
};

/** Rewards are earned through play, never bought. */
export type Unlock = { type: 'level'; value: number } | { type: 'streak'; value: number };

export const packUnlocks: Record<string, Unlock> = {
  cosmetic_eco_frame: { type: 'level', value: 2 },
  cosmetic_heart_badge: { type: 'streak', value: 3 },
  cosmetic_ocean_frame: { type: 'level', value: 3 },
  dlc_trash_advanced: { type: 'level', value: 4 },
  cosmetic_sunrise_frame: { type: 'level', value: 5 },
  cosmetic_star_badge: { type: 'streak', value: 7 },
  dlc_water_city: { type: 'level', value: 6 },
  cosmetic_lightning_frame: { type: 'level', value: 8 },
  cosmetic_gold_frame: { type: 'level', value: 12 },
};

export const shopPackIds = new Set(Object.keys(packUnlocks));

/** Same maths as the app's LevelInfo: 100 XP per level, starting at 1. */
export function levelFor(xp: number): number {
  return Math.floor(xp / 100) + 1;
}

export function meetsUnlock(unlock: Unlock, stats: { xp: number; streak: number }): boolean {
  return unlock.type === 'level' ? levelFor(stats.xp) >= unlock.value : stats.streak >= unlock.value;
}

/** UTC calendar day as YYYY-MM-DD. */
export function utcDay(d: Date): string {
  return d.toISOString().slice(0, 10);
}

/** A streak is only "alive" if the user was active today or yesterday. */
export function effectiveStreak(streak: number, lastActiveOn: string | null, today: string): number {
  if (!lastActiveOn) return 0;
  const diffDays = (Date.parse(today) - Date.parse(lastActiveOn)) / 86_400_000;
  return diffDays <= 1 ? streak : 0;
}

/** Round coordinates to ~1 km so exact locations (often homes) aren't public. */
export function coarse(coord: number | null): number | null {
  return coord == null ? null : Math.round(coord * 100) / 100;
}
