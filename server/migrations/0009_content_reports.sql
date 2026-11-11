-- Problems people (often teachers) report with lessons, missions, quiz
-- questions and targets, for the content team to review.
create table content_reports (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references users (id) on delete set null,
  content_type  text not null check (content_type in ('lesson', 'mission', 'quiz', 'target', 'impact')),
  content_id    text not null check (char_length(content_id) between 1 and 80),
  reason        text not null check (reason in ('inaccurate', 'out_of_date', 'unclear', 'not_age_appropriate', 'other')),
  message       text check (char_length(message) <= 1000),
  status        text not null default 'open' check (status in ('open', 'fixed', 'dismissed')),
  created_at    timestamptz not null default now()
);
create index content_reports_open_idx on content_reports (status, created_at desc);
create index content_reports_user_idx on content_reports (user_id, created_at desc);
