-- SDG Journey schema (Neon / Postgres 16+).
-- Applied by `npm run migrate`; each file runs once and is recorded in
-- schema_migrations.

create table users (
  id                  uuid primary key default gen_random_uuid(),
  email               text not null,
  password_hash       text not null,
  username            text not null check (char_length(username) between 2 and 24),
  xp                  integer not null default 0 check (xp >= 0),
  streak              integer not null default 0 check (streak >= 0),
  last_active_on      date,
  avatar_url          text,
  active_avatar_frame text,
  created_at          timestamptz not null default now()
);
create unique index users_email_key on users (lower(email));

-- Refresh tokens (only a SHA-256 hash is stored).
create table sessions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users (id) on delete cascade,
  token_hash  text not null unique,
  expires_at  timestamptz not null,
  created_at  timestamptz not null default now()
);
create index sessions_user_idx on sessions (user_id);

create table password_resets (
  token_hash  text primary key,
  user_id     uuid not null references users (id) on delete cascade,
  expires_at  timestamptz not null,
  used_at     timestamptz
);

create table mission_completions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references users (id) on delete cascade,
  user_name     text not null,
  mission_id    text not null,
  mission_title text not null,
  sdg_number    smallint not null check (sdg_number between 1 and 17),
  xp            integer not null check (xp >= 0),
  lat           double precision,
  lng           double precision,
  photo_key     text,
  completed_on  date not null,
  created_at    timestamptz not null default now(),
  -- A mission can be completed (and rewarded) once per day.
  unique (user_id, mission_id, completed_on)
);
create index mission_completions_recent_idx on mission_completions (created_at desc);
create index mission_completions_user_day_idx on mission_completions (user_id, completed_on);

create table stories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users (id) on delete cascade,
  user_name   text not null,
  message     text not null check (char_length(message) <= 500),
  sdg_number  smallint check (sdg_number between 1 and 17),
  photo_key   text,
  created_at  timestamptz not null default now()
);
create index stories_recent_idx on stories (created_at desc);

create table quiz_attempts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references users (id) on delete cascade,
  sdg_number      smallint not null,
  score           integer not null check (score >= 0),
  total_questions integer not null check (total_questions > 0),
  xp_earned       integer not null default 0,
  created_at      timestamptz not null default now()
);
create index quiz_attempts_user_idx on quiz_attempts (user_id);

create table game_sessions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users (id) on delete cascade,
  game_id     text not null,
  sdg_number  smallint,
  score       integer not null default 0,
  total       integer not null default 0,
  xp_earned   integer not null default 0,
  played_on   date not null,
  created_at  timestamptz not null default now()
);
create index game_sessions_user_day_idx on game_sessions (user_id, game_id, played_on);

create table user_owned_packs (
  user_id     uuid not null references users (id) on delete cascade,
  pack_id     text not null,
  created_at  timestamptz not null default now(),
  primary key (user_id, pack_id)
);

-- Awards XP and updates the streak atomically. The streak bonus mirrors the
-- original app rules (3+ days: +5, 7+: +10, 14+: +20) and only applies when
-- something is actually earned.
create function award_xp(p_user uuid, p_amount integer, p_today date)
returns table (xp_before integer, xp_after integer, streak integer, bonus integer)
language plpgsql
as $$
declare
  u          users%rowtype;
  new_streak integer;
  b          integer := 0;
begin
  select * into u from users where id = p_user for update;
  if not found then
    raise exception 'user % not found', p_user;
  end if;

  if u.last_active_on is null then
    new_streak := 1;
  elsif u.last_active_on = p_today then
    new_streak := greatest(u.streak, 1);
  elsif u.last_active_on = p_today - 1 then
    new_streak := u.streak + 1;
  else
    new_streak := 1;
  end if;

  if p_amount > 0 then
    if new_streak >= 14 then b := 20;
    elsif new_streak >= 7 then b := 10;
    elsif new_streak >= 3 then b := 5;
    end if;
  end if;

  update users
     set xp = u.xp + greatest(p_amount, 0) + b,
         streak = new_streak,
         last_active_on = p_today
   where id = p_user;

  return query select u.xp, u.xp + greatest(p_amount, 0) + b, new_streak, b;
end;
$$;
