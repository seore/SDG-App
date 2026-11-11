-- Learning path: which lessons were read and per-goal quiz results.
create table lesson_reads (
  user_id     uuid not null references users (id) on delete cascade,
  sdg_number  smallint not null check (sdg_number between 1 and 17),
  read_at     timestamptz not null default now(),
  primary key (user_id, sdg_number)
);

create table quiz_sdg_results (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users (id) on delete cascade,
  sdg_number  smallint not null check (sdg_number between 1 and 17),
  correct     integer not null check (correct >= 0),
  total       integer not null check (total > 0 and correct <= total),
  created_at  timestamptz not null default now()
);
create index quiz_sdg_results_user_idx on quiz_sdg_results (user_id, sdg_number);
