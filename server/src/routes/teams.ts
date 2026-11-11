import { Hono } from 'hono';
import { z } from 'zod';

import { apiError, requireAuth, type AppEnv } from '../context';
import type { Db } from '../db';
import { utcDay } from '../rules';
import { assertConsent } from './consent';
import { masteryFor } from './learning';

export const MAX_TEAMS_PER_USER = 5;

// No 0/O/1/I so codes are easy to read aloud and copy from a board.
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function newCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(6));
  return [...bytes].map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join('');
}

/** Monday (UTC) of the week containing [now]. */
export function weekStart(now: Date): string {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const day = (d.getUTCDay() + 6) % 7; // 0 = Monday
  d.setUTCDate(d.getUTCDate() - day);
  return utcDay(d);
}

type Num = string | number | null;

async function teamSummaries(db: Db, userId: string, from: string, onlyTeamId?: string) {
  const rows = await db.query<{
    id: string;
    name: string;
    code: string;
    weekly_target: number;
    members: Num;
    missions: Num;
    is_owner: boolean;
  }>(
    `select t.id, t.name, t.code, t.weekly_target,
            (select count(*) from team_members m where m.team_id = t.id) as members,
            (select count(*) from mission_completions c
               join team_members m on m.user_id = c.user_id and m.team_id = t.id
              where c.completed_on >= $2::date) as missions,
            (t.created_by = $1) as is_owner
       from teams t
       join team_members me on me.team_id = t.id and me.user_id = $1
      where ($3::uuid is null or t.id = $3::uuid)
      order by me.joined_at`,
    [userId, from, onlyTeamId ?? null],
  );
  return rows.map((r) => ({
    id: r.id,
    name: r.name,
    code: r.code,
    weekly_target: r.weekly_target,
    members: Number(r.members),
    missions_this_week: Number(r.missions),
    is_owner: Boolean(r.is_owner),
  }));
}

export const teams = new Hono<AppEnv>();
teams.use('*', requireAuth);

teams.get('/', async (c) => {
  const from = weekStart(c.get('config').now());
  return c.json({ week_start: from, teams: await teamSummaries(c.get('db'), c.get('userId'), from) });
});

teams.post('/', async (c) => {
  await assertConsent(c);
  const body = z
    .object({
      name: z.string().trim().min(2).max(40),
      weekly_target: z.number().int().min(5).max(5000).optional(),
    })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_input', 'Give your team a name (2–40 characters).');

  const db = c.get('db');
  const userId = c.get('userId');
  const [{ count }] = (await db.query<{ count: Num }>(
    'select count(*) as count from team_members where user_id = $1',
    [userId],
  )) as [{ count: Num }];
  if (Number(count) >= MAX_TEAMS_PER_USER) {
    throw apiError(409, 'team_limit', `You can be in up to ${MAX_TEAMS_PER_USER} teams.`);
  }

  // Retry on the (very unlikely) chance of a code collision.
  for (let attempt = 0; attempt < 5; attempt++) {
    const rows = await db.query<{ id: string }>(
      `insert into teams (name, code, weekly_target, created_by) values ($1, $2, $3, $4)
       on conflict (code) do nothing returning id`,
      [body.data.name, newCode(), body.data.weekly_target ?? 50, userId],
    );
    if (rows.length) {
      await db.query('insert into team_members (team_id, user_id) values ($1, $2)', [rows[0]!.id, userId]);
      const from = weekStart(c.get('config').now());
      const [team] = await teamSummaries(db, userId, from, rows[0]!.id);
      return c.json(team, 201);
    }
  }
  throw apiError(409, 'try_again', 'Could not create the team. Please try again.');
});

teams.post('/join', async (c) => {
  await assertConsent(c);
  const body = z
    .object({ code: z.string().trim().toUpperCase().regex(/^[A-Z0-9]{6}$/) })
    .safeParse(await c.req.json().catch(() => null));
  if (!body.success) throw apiError(400, 'invalid_code', 'Team codes are 6 letters and numbers.');

  const db = c.get('db');
  const userId = c.get('userId');
  const [team] = await db.query<{ id: string }>('select id from teams where code = $1', [body.data.code]);
  if (!team) throw apiError(404, 'team_not_found', 'No team has that code. Check it and try again.');

  const already = await db.query('select 1 from team_members where team_id = $1 and user_id = $2', [
    team.id,
    userId,
  ]);
  if (!already.length) {
    const [{ count }] = (await db.query<{ count: Num }>(
      'select count(*) as count from team_members where user_id = $1',
      [userId],
    )) as [{ count: Num }];
    if (Number(count) >= MAX_TEAMS_PER_USER) {
      throw apiError(409, 'team_limit', `You can be in up to ${MAX_TEAMS_PER_USER} teams.`);
    }
    await db.query('insert into team_members (team_id, user_id) values ($1, $2)', [team.id, userId]);
  }
  const from = weekStart(c.get('config').now());
  const [summary] = await teamSummaries(db, userId, from, team.id);
  return c.json(summary);
});

teams.get('/:id', async (c) => {
  const id = c.req.param('id');
  if (!z.string().uuid().safeParse(id).success) throw apiError(404, 'team_not_found', 'Team not found.');
  const db = c.get('db');
  const userId = c.get('userId');
  const from = weekStart(c.get('config').now());
  const [team] = await teamSummaries(db, userId, from, id);
  if (!team) throw apiError(404, 'team_not_found', 'Team not found.');

  const members = await db.query<{ username: string; missions: Num; xp: Num; is_me: boolean }>(
    `select u.username,
            count(c.id) as missions,
            coalesce(sum(c.xp), 0) as xp,
            (u.id = $3) as is_me
       from team_members m
       join users u on u.id = m.user_id
       left join mission_completions c on c.user_id = u.id and c.completed_on >= $2::date
      where m.team_id = $1
      group by u.id, u.username
      order by count(c.id) desc, coalesce(sum(c.xp), 0) desc, u.username`,
    [id, from, userId],
  );
  return c.json({
    ...team,
    week_start: from,
    leaderboard: members.map((m) => ({
      username: m.username,
      missions: Number(m.missions),
      xp: Number(m.xp),
      is_me: Boolean(m.is_me),
    })),
  });
});

teams.post('/:id/leave', async (c) => {
  const id = c.req.param('id');
  if (!z.string().uuid().safeParse(id).success) throw apiError(404, 'team_not_found', 'Team not found.');
  const db = c.get('db');
  await db.query('delete from team_members where team_id = $1 and user_id = $2', [id, c.get('userId')]);
  // Remove empty teams.
  await db.query(
    'delete from teams where id = $1 and not exists (select 1 from team_members where team_id = $1)',
    [id],
  );
  return c.json({ ok: true });
});

/** Loads the team if the user created it; otherwise 404 (members) or 403. */
async function requireOwner(db: Db, teamId: string, userId: string) {
  if (!z.string().uuid().safeParse(teamId).success) throw apiError(404, 'team_not_found', 'Team not found.');
  const [team] = await db.query<{ created_by: string | null; is_member: boolean }>(
    `select t.created_by,
            exists (select 1 from team_members m where m.team_id = t.id and m.user_id = $2) as is_member
       from teams t where t.id = $1`,
    [teamId, userId],
  );
  if (!team || !team.is_member) throw apiError(404, 'team_not_found', 'Team not found.');
  if (team.created_by !== userId) throw apiError(403, 'not_team_owner', 'Only the person who created the team can do this.');
}

/** Class insights for the team's creator (e.g. a teacher). */
teams.get('/:id/insights', async (c) => {
  const id = c.req.param('id');
  const db = c.get('db');
  const userId = c.get('userId');
  await requireOwner(db, id, userId);
  const from = weekStart(c.get('config').now());

  const members = await db.query<{
    user_id: string;
    username: string;
    missions_week: Num;
    last_active: string | Date | null;
  }>(
    `select u.id as user_id, u.username,
            (select count(*) from mission_completions c
              where c.user_id = u.id and c.completed_on >= $2::date) as missions_week,
            greatest(
              (select max(created_at) from mission_completions where user_id = u.id),
              (select max(created_at) from game_sessions where user_id = u.id),
              (select max(read_at) from lesson_reads where user_id = u.id)
            ) as last_active
       from team_members m
       join users u on u.id = m.user_id
      where m.team_id = $1
      order by lower(u.username)`,
    [id, from],
  );
  const mastery = await masteryFor(
    db,
    members.map((m) => m.user_id),
  );

  const students = members.map((m) => {
    const goals = mastery.get(m.user_id) ?? [];
    const sum = (f: (g: (typeof goals)[number]) => number) => goals.reduce((s, g) => s + f(g), 0);
    const last = m.last_active == null ? null : new Date(m.last_active);
    return {
      user_id: m.user_id,
      username: m.username,
      is_me: m.user_id === userId,
      missions_this_week: Number(m.missions_week),
      lessons_read: sum((g) => Number(g.lesson_read)),
      quiz_correct: sum((g) => g.quiz_correct),
      quiz_total: sum((g) => g.quiz_total),
      stars: sum((g) => g.stars),
      last_active: last ? last.toISOString() : null,
    };
  });

  const n = Math.max(students.length, 1);
  const goals = Array.from({ length: 17 }, (_, i) => {
    const sdg = i + 1;
    const all = members.map((m) => mastery.get(m.user_id)?.[i]).filter((g) => g != null);
    return {
      sdg_number: sdg,
      lessons_read: all.filter((g) => g.lesson_read).length,
      quiz_correct: all.reduce((s, g) => s + g.quiz_correct, 0),
      quiz_total: all.reduce((s, g) => s + g.quiz_total, 0),
      missions: all.reduce((s, g) => s + g.missions, 0),
      average_stars: Math.round((all.reduce((s, g) => s + g.stars, 0) / n) * 10) / 10,
    };
  });

  return c.json({
    team_id: id,
    week_start: from,
    totals: {
      members: students.length,
      active_this_week: students.filter((s) => s.last_active && s.last_active.slice(0, 10) >= from).length,
      missions_this_week: students.reduce((s, m) => s + m.missions_this_week, 0),
      lessons_read: students.reduce((s, m) => s + m.lessons_read, 0),
    },
    students,
    goals,
  });
});

/** The team's creator can remove a member (e.g. someone who joined by mistake). */
teams.delete('/:id/members/:userId', async (c) => {
  const id = c.req.param('id');
  const member = c.req.param('userId');
  const db = c.get('db');
  const userId = c.get('userId');
  await requireOwner(db, id, userId);
  if (member === userId) throw apiError(400, 'cannot_remove_self', 'Use "Leave team" to leave your own team.');
  if (!z.string().uuid().safeParse(member).success) throw apiError(404, 'member_not_found', 'Member not found.');
  await db.query('delete from team_members where team_id = $1 and user_id = $2', [id, member]);
  return c.json({ ok: true });
});
