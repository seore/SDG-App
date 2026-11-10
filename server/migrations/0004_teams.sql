-- Team challenges: classes or friend groups with a shared weekly target.
create table teams (
  id             uuid primary key default gen_random_uuid(),
  name           text not null check (char_length(name) between 2 and 40),
  -- Short code people type to join, e.g. a teacher writes it on the board.
  code           text not null unique check (code ~ '^[A-Z2-9]{6}$'),
  weekly_target  integer not null default 50 check (weekly_target between 5 and 5000),
  created_by     uuid references users (id) on delete set null,
  created_at     timestamptz not null default now()
);

create table team_members (
  team_id    uuid not null references teams (id) on delete cascade,
  user_id    uuid not null references users (id) on delete cascade,
  joined_at  timestamptz not null default now(),
  primary key (team_id, user_id)
);
create index team_members_user_idx on team_members (user_id);
