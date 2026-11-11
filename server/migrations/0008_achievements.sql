-- Best streak ever, so streak achievements stay earned after a streak ends.
alter table users add column best_streak integer not null default 0 check (best_streak >= 0);
update users set best_streak = streak;

create function track_best_streak() returns trigger language plpgsql as $$
begin
  if new.streak > new.best_streak then
    new.best_streak := new.streak;
  end if;
  return new;
end;
$$;

create trigger users_best_streak
  before update of streak on users
  for each row execute function track_best_streak();

-- Monthly themed challenges: one reward claim per user per month.
create table challenge_claims (
  user_id    uuid not null references users (id) on delete cascade,
  month      text not null check (month ~ '^\d{4}-\d{2}$'),
  challenge  text not null,
  xp         integer not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, month)
);
