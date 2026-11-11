-- AI photo check results. A story only shows its photo publicly when the
-- check said it is safe to share (photo_key is left null otherwise).
alter table mission_completions
  add column photo_verified boolean,
  add column photo_feedback text;

alter table stories
  add column verified boolean not null default false;
